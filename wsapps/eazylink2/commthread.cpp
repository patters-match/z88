/*********************************************************************************************

 EazyLink2 - Fast Client/Server Z88 File Management
 (C) Gunther Strube (gstrube@gmail.com) & Oscar Ernohazy 2012

 EazyLink2 is free software; you can redistribute it and/or modify it under the terms of the
 GNU General Public License as published by the Free Software Foundation;
 either version 2, or (at your option) any later version.
 EazyLink2 is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 See the GNU General Public License for more details.
 You should have received a copy of the GNU General Public License along with EazyLink2;
 see the file COPYING. If not, write to the
 Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

**********************************************************************************************/

#include <qdebug.h>
#include <QListIterator>

#include "commthread.h"
#include "z88filespec.h"
#include "desktop_view.h"
#include "z88_devview.h"

/**
  * The Communications Thread Constructor.
  * @param port is a reference to the Z88 Serial port class to use for I/O.
  * @param parent is the owner QT Object.
  */
CommThread::CommThread(Z88SerialPort &port, QObject *parent)
  :QThread(parent),
   m_sport(port),
   m_curOP(OP_idle),
   m_prevOP(OP_idle),
   m_redo_lastCmd(false),
   m_enaFilesize(false),
   m_enaTimeDate(false),
   m_enaPromtUser(false),
   m_xferFileprogress(0),
   m_z88Selections(NULL),
   m_deskSelections(NULL),
   m_z88Sel_itr(NULL),
   m_deskSel_itr(NULL),
   m_abort(false)
{


}
/**
  * The Destructor
  */
CommThread::~CommThread()
{
}

/**
  * The Communications thread Method.
  */
void CommThread::run()
{
    QString msg;
    enableCmds(false, m_sport.isOpen());

    if(m_abort){
        cmdStatus("Command Aborted!");
        goto abort;
    }

    switch(m_curOP){
        case OP_idle:
            break;
        case OP_reopen:
            m_curOP = OP_openDevName;
            run();
            if(m_redo_lastCmd){
                m_curOP = m_prevOP;
                m_redo_lastCmd = false;
                run();
            }
            break;
        case OP_openDevName:
            msg = "Trying to Open Port ";
            msg += m_shortname;
            cmdStatus(msg);
            emit open_result(m_devname, m_shortname, m_sport.open(m_devname));
            break;
        case OP_openDevXonXoff:
            msg = "Trying to Open Port ";
            msg += m_shortname;
            cmdStatus(msg);
            emit open_result(m_devname, m_shortname, m_sport.openXonXoff(m_devname));
            break;
        case OP_helloZ88:
            cmdStatus("Sending Hello Z88");
            boolCmd_result("HelloZ88", m_sport.helloZ88());
            break;
        case OP_quitZ88:
        {
            cmdStatus("Sending Z88 Quit EasyLink");
            bool rc = m_sport.quitZ88();
            boolCmd_result("Z88 Quit EazyLink", rc);
            if(rc){
                m_sport.close();
            }
        }
            break;
        case OP_byteTransON:
            cmdStatus("Sending Enable Byte Translation");
            boolCmd_result("Byte Translation ON", m_sport.translationOn());
            break;
        case OP_byteTransOFF:
            cmdStatus("Sending Disable Byte Translation");
            boolCmd_result("Byte Translation OFF", m_sport.translationOff());
            break;
        case OP_crlfTransON:
            cmdStatus("Sending Enable CRLF Translation");
            boolCmd_result("CRLF Translation ON", m_sport.linefeedConvOn());
            break;
        case OP_crlfTransOFF:
            cmdStatus("Sending Disable CRLF Translation");
            boolCmd_result("CRLF Translation OFF", m_sport.linefeedConvOff());
            break;
        case OP_reloadTransTable:
            cmdStatus("Sending Reload Translation Table");
            boolCmd_result("Reload Translation Table", m_sport.reloadTranslationTable());
            break;
        case OP_setZ88Clock:
            cmdStatus("Syncing Z88 Clock to host Time");
            boolCmd_result("Z88 Clock Sync", m_sport.setZ88Time());
            break;
        case OP_getZ88Clock:
        {
            QList<QByteArray> tm_date;

            cmdStatus("Reading Z88 Clock");
            tm_date = m_sport.getZ88Time();
            if(tm_date.count()==2){
                msg = "Z88 Date and Time: ";
                msg += tm_date[0];
                msg += " - ";
                msg += tm_date[1];
                cmdStatus(msg);
            }
            else{
                boolCmd_result("Reading Z88 Clock", false);
            }
        }
            break;
        case OP_getInfo:
        {
            QList<QByteArray> *infolist = new QList<QByteArray>;
            cmdStatus("Reading Z88 Info.");

            infolist->append(m_sport.getEazyLinkZ88Version());
            if(infolist->count()!=1){
                boolCmd_result("Reading Z88 Version", false);
                break;
            }
            /**
              * Read Z88 Freememory
              */
            infolist->append(m_sport.getZ88FreeMem());

            if(infolist->count()!=2){
                boolCmd_result("Reading Z88 Free Memory", false);
                break;
            }
            boolCmd_result("Reading Z88 Info", true);

            infolist->append(m_sport.getDevices());
            emit Z88Info_result(infolist);
            break;
        }

        case OP_getDevices:
        {
            QList<QByteArray> *devlist = new QList<QByteArray>;
            cmdStatus("Searching for Z88 Storage Devices.");

            /**
              * Read Devices
              */
            devlist->append(m_sport.getDevices());
            emit Z88Devices_result(devlist);

            boolCmd_result("Reading Z88 Devices", !devlist->isEmpty());

            break;
        }
        case OP_getDirectories:
        {
            QList<QByteArray> *dirlist = new QList<QByteArray>;
            cmdStatus("Searching for Z88 Directories.");

            /**
              * Read Directories
              */
            dirlist->append(m_sport.getDirectories(m_z88devname));
            emit Z88Dir_result(m_z88devspec, dirlist);

            boolCmd_result("Reading Z88 Directories", !dirlist->isEmpty());
            break;
        }
        case OP_getFilenames:
        {
            bool retc = false;
            QList<QByteArray> *filelist = new QList<QByteArray>;
            cmdStatus("Reading Z88 Files...");

            /**
              * Read All Files Recursively
              */
            filelist->append(m_sport.getFilenames(m_z88devname, retc));

            QList<Z88FileSpec> *fileSpeclist = new QList<Z88FileSpec>;

            QListIterator<QByteArray> i(*filelist);

            int count = filelist->count();
            int idx = 0;
            int extmode = m_enaFilesize ? 1 : 0;
            extmode += m_enaTimeDate ? 1 : 0;

            QString msg = "Reading Z88 file ";
            if(m_enaFilesize){
                msg += "Size";
            }
            if(extmode > 1){
                msg += " & ";
            }
            if(m_enaTimeDate){
                msg += "Date";
            }
            msg += " info from ";
            msg += m_z88devname.mid(0,6);

            while(i.hasNext()){
                if(m_abort){
                    cmdStatus("Command Aborted!");
                    goto abort;
                }

                if(extmode && !m_abort){
                    emit cmdProgress(msg, idx, count);
                }

                idx ++;
                QString fname(i.next());
                QString fsize;
                QString fcdate;
                QString fmdate;

                /**
                  * If filesize is requested
                  */
                if(m_enaFilesize){
                    QString msg = QString("[%1] Reading File Size: (%2 of %3)").arg(fname.mid(0,6)).arg(idx).arg(count);

                    cmdStatus(msg);
                    fsize = m_sport.getFileSize(fname);
                }

                /**
                  * If time and date requested
                  * Read it from all devices except Eproms. (they don't seem to store time & date)
                  */
                if(m_enaTimeDate && !fname.contains("EPR")){
                    QString msg = QString("[%1] Reading File Date: (%2 of %3)").arg(fname.mid(0,6)).arg(idx).arg(count);

                    cmdStatus(msg);

                    QList<QByteArray> fileTD(m_sport.getFileDateStamps(fname));
                    if(fileTD.count() == 2){
                        fcdate = fileTD[0];
                        fmdate = fileTD[1];
                    }
                }

                fileSpeclist->append(Z88FileSpec(fname, fsize, fcdate, fmdate));
            }

            emit cmdProgress("Done", -1, -1); // reset the progress dialog
            emit Z88FileSpeclist_result(m_z88devspec, fileSpeclist);

            boolCmd_result("Reading Z88 Files", retc);
            break;
        }
        case OP_getZ88FileTree:
        {
            QList<QByteArray> *devlist = new QList<QByteArray>;
            cmdStatus("Reading Z88 File System");

            /**
              * Read Devices
              */
            devlist->append(m_sport.getDevices());
            emit Z88Devices_result(devlist);

            if(devlist->isEmpty()){
                boolCmd_result("Reading Z88 Devices", false);
                break;
            }

            /**
              * Read the Directories for each device
              */
            QListIterator<QByteArray> i(*devlist);      

            while(i.hasNext()){
                if(m_abort){
                    cmdStatus("Command Aborted!");
                    goto abort;
                }
                _getDirectories(i.next());
                run();
            }

            /**
              * Read the Files From the Device
              */
            i.toFront();

            while(i.hasNext()){
                if(m_abort){
                    cmdStatus("Command Aborted!");
                    goto abort;
                }
                _getFileNames(i.next());
                run();
            }
            boolCmd_result("Z88 Refresh", true);

            break;
        }
        case OP_initreceiveFiles:
        {
            delete m_z88Sel_itr;
            m_z88Sel_itr = new QListIterator<Z88_Selection> (*m_z88Selections);
            m_z88Sel_itr->toFront();
            m_xferFileprogress = 0;
            // drop through
        }
        case OP_receiveFiles:
        {
            if(m_z88Sel_itr->hasNext()){

                const Z88_Selection &z88sel(m_z88Sel_itr->peekNext());
                QString srcname(z88sel.getFspec());

                if(m_enaPromtUser){
                    QString dest = m_destPath + "/" + z88sel.getRelFspec();
                    emit PromptReceiveSpec(srcname, dest, &m_enaPromtUser);
                    break;
                }

                m_curOP = OP_receiveFile;
                run();
            }
            emit cmdProgress("Done", -1, -1); // reset the progress dialog

            break;
        }
        case OP_receiveFile:    // Get the Specified file.
        {
            do{
                if(m_abort){
                    cmdStatus("Transfer Aborted..");
                    break;
                }

                const Z88_Selection &z88sel(m_z88Sel_itr->next());
                QString srcname(z88sel.getFspec());

                QString msg = "Receiving ";
                msg += srcname;

                /**
                  * Update the Progress Bar
                  */
                emit cmdProgress(msg, m_xferFileprogress, m_z88Selections->count());

                msg += " to ";
                msg += m_destPath;
                cmdStatus(msg);

                /**
                  * Receive the file from Z88
                  */
                Z88SerialPort::retcode rc = m_sport.receiveFiles(srcname, m_destPath, z88sel.getRelFspec(), m_dest_isDir);
                m_xferFileprogress++;

                if(m_abort){
                    cmdStatus("Transfer Cancelled.");
                    break;
                }

                boolCmd_result("Transfer", (rc == Z88SerialPort::rc_done));

                if(rc != Z88SerialPort::rc_done){
                    break;
                }

                if(m_enaPromtUser && m_z88Sel_itr->hasNext()){
                    const Z88_Selection &z88selnxt(m_z88Sel_itr->peekNext());

                    srcname = z88selnxt.getFspec();
                    QString dest = m_destPath + "/" + z88selnxt.getRelFspec();

                    emit PromptReceiveSpec(srcname, dest, &m_enaPromtUser);
                    break;
                }
                else{
                    boolCmd_result("File Transfer", true);
                }

            } while(m_z88Sel_itr->hasNext());

            emit cmdProgress("Done", -1, -1); // reset the progress dialog
            break;
        }
        case OP_receiveNext:
        {
            /**
              * Skip the current file
              */
            if(m_z88Sel_itr->hasNext()){
                m_z88Sel_itr->next();
                m_xferFileprogress++;
            }

            /**
              * Receive the next file
              */
            if(m_z88Sel_itr->hasNext()){
                m_curOP = OP_receiveFiles;
                run();
            }
            emit cmdProgress("Done", -1, -1); // reset the progress dialog

            break;
        }
        case OP_dirLoadDone:
            if(!m_abort){
                m_mutex.lock();
                m_curOP = OP_idle;
                m_mutex.unlock();
                emit DirLoadComplete(false);
                return;  // Don't re-enable commands here
            }
            break;
        case OP_initsendFiles:
        {
            delete m_deskSel_itr;
            m_deskSel_itr = new QListIterator<DeskTop_Selection> (*m_deskSelections);
            m_deskSel_itr->toFront();
            m_xferFileprogress = 0;
            // drop through
        }
        case OP_sendFiles:
        {
            if(m_deskSel_itr->hasNext()){

                const DeskTop_Selection &desksel(m_deskSel_itr->peekNext());
                QString srcname(desksel.getFspec());

                if(m_enaPromtUser && (desksel.getType() == DeskTop_Selection::type_File)){
                    QString destFspec = m_destPath + desksel.getFname();
                    emit PromptSendSpec(srcname, destFspec, &m_enaPromtUser);
                    break;
                }

                m_curOP = OP_sendFile;
                run();
            }
            emit cmdProgress("Done", -1, -1); // reset the progress dialog
            break;
        }
        case OP_sendFile:
        {
            do{
                if(m_abort){
                    cmdStatus("Transfer Aborted..");
                    break;
                }

                const DeskTop_Selection &desksel(m_deskSel_itr->next());
                QString srcname(desksel.getFspec());

                QString msg = "Sending ";
                msg += srcname;

                /**
                  * Update the Progress Bar
                  */
                emit cmdProgress(msg, m_xferFileprogress, m_deskSelections->count());

                msg += " to ";
                msg += m_destPath;
                cmdStatus(msg);

                /**
                  * Send the file to Z88
                  */
                bool rc;
                QString destFspec = m_destPath + desksel.getFname();
                if(desksel.getType() == DeskTop_Selection::type_Dir){
                    rc = m_sport.createDir(destFspec);
                }
                else{
                    rc = m_sport.sendFile(destFspec, srcname);
                }

                m_xferFileprogress++;

                if(m_abort){
                    cmdStatus("Transfer Cancelled.");
                    break;
                }

                boolCmd_result("Transfer", rc);

                if(!rc){
                    break;
                }

                if(m_deskSel_itr->hasNext()){
                    const DeskTop_Selection &deskselnxt(m_deskSel_itr->peekNext());

                    if(m_enaPromtUser && (deskselnxt.getType() == DeskTop_Selection::type_File)){

                        srcname = deskselnxt.getFspec();
                        QString destFspec = m_destPath + deskselnxt.getFname();

                        emit PromptSendSpec(srcname, destFspec, &m_enaPromtUser);
                        break;
                    }
                }
                else{
                    boolCmd_result("File Transfer", true);
                }

            } while(m_deskSel_itr->hasNext());

            emit cmdProgress("Done", -1, -1); // reset the progress dialog
            break;
        }
        case OP_sendNext:
        {
            /**
              * Skip the current file
              */
            if(m_deskSel_itr->hasNext()){
                m_deskSel_itr->next();
                m_xferFileprogress++;
            }

            /**
              * Send the next file
              */
            if(m_deskSel_itr->hasNext()){
                m_curOP = OP_sendFiles;
                run();
            }
            emit cmdProgress("Done", -1, -1); // reset the progress dialog

            break;
        }
    }
abort:
    m_mutex.lock();
    if(m_curOP == OP_dirLoadDone){
        emit DirLoadComplete(true);
        m_abort = false;
    }
    m_curOP = OP_idle;
    m_mutex.unlock();

    emit enableCmds(true, m_sport.isOpen());

    return;
}

/**
  * Set up the Progress bar Abort Handler
  */
void CommThread::SetupAbortHandler(QProgressDialog *pd)
{
    connect(pd, SIGNAL(canceled()), this, SLOT(CancelSignal()) );
}

/**
  * The Slot that gets called when user clicks abort on the progress Dialog.
  */
void CommThread::CancelSignal()
{
    AbortCmd();
}

/**
  * The Slot that gets called when user hits abort button on the main form.
  */
void CommThread::AbortCmd()
{
    m_abort = true;
    cmdStatus("Aborting current process...");
}

/**
  * Close the Communications port.
  * @return true if communication thread was idle.
  */
bool CommThread::close()
{
    QMutexLocker locker(&m_mutex);

    /**
      * Make sure we are not running another command
      */
    if(m_curOP != OP_idle){
        return false;
    }

    m_sport.close();

    startCmd(OP_idle);

    return true;
}

/**
  * Re-init (open) the communications port, and optinally re-do the last command.
  * @param redo_lastcmd on call set to true to redo last command after open.
  * @return true if communication thread was idle.
  */
bool CommThread::reopen(bool redo_lastcmd)
{
    QMutexLocker locker(&m_mutex);

    /**
      * Make sure we are not running another command
      */
    if(m_curOP != OP_idle){
        return false;
    }

    if(m_devname.isEmpty() || m_shortname.isEmpty()){
        return false;
    }

    m_redo_lastCmd = redo_lastcmd;
    m_curOP = OP_reopen;

    /**
      * Disable the abort status
      */
    m_abort = false;

    /**
      * Start the Command Thread
      */
    if (!isRunning())
        start();
    else
        m_cond.wakeOne();

    return true;
}

/**
  * Open the Com port with Hardware flow control.
  * @param devname is the full device path to open. ie /dev/tty.Keyspan1
  * @param short_name is the user alias to the device.
  * @return true if communication thread was idle.
  */
bool CommThread::open(const QString &devname, const QString &short_name)
{
    QMutexLocker locker(&m_mutex);

    /**
      * Make sure we are not running another command
      */
    if(m_curOP != OP_idle){
        return false;
    }

    m_devname = devname;
    m_shortname = short_name;
    startCmd(OP_openDevName);

    return true;
}

/**
  * Open the Com port with Xon/Xoff flow control.
  * @param devname is the full device path to open. ie /dev/tty.Keyspan1
  * @param short_name is the user alias to the device.
  * @return true if communication thread was idle.
  */
bool CommThread::openXonXoff(const QString &devname, const QString &short_name)
{
    QMutexLocker locker(&m_mutex);

    /**
      * Make sure we are not running another command
      */
    if(m_curOP != OP_idle){
        return false;
    }

    m_devname = devname;
    m_shortname = short_name;
    startCmd(OP_openDevXonXoff);

    return true;
}

/**
  * Send Z88 Hello Command.
  * @return true if communication thread was idle.
  */
bool CommThread::helloZ88()
{
    QMutexLocker locker(&m_mutex);

    /**
      * Make sure we are not running another command
      */
    if(m_curOP != OP_idle){
        return false;
    }

    startCmd(OP_helloZ88);

    return true;
}

/**
  * Send Z88 ezlink Quit Command.
  * @return true if communication thread was idle.
  */
bool CommThread::quitZ88()
{
    QMutexLocker locker(&m_mutex);

    /**
      * Make sure we are not running another command
      */
    if(m_curOP != OP_idle){
        return false;
    }

    startCmd(OP_quitZ88);

    return true;
}

/**
  * Enable / Disable Byte Translation.
  * @param ena set to true to enable byte translation.
  * @return true if communication thread was idle.
  */
bool CommThread::ByteTrans(bool ena)
{
    QMutexLocker locker(&m_mutex);

    /**
      * Make sure we are not running another command
      */
    if(m_curOP != OP_idle){
        return false;
    }

    startCmd(ena ? OP_byteTransON : OP_byteTransOFF);

    return true;
}

/**
  * Enable CR / LF translation
  * @param ena set to true to enable.
  * @return true if communication thread was idle.
  */
bool CommThread::CRLFTrans(bool ena)
{
    QMutexLocker locker(&m_mutex);

    /**
      * Make sure we are not running another command
      */
    if(m_curOP != OP_idle){
        return false;
    }

    startCmd(ena ? OP_crlfTransON : OP_crlfTransOFF);

    return true;
}

/**
  * Reload Translation table command.
  * @return true if communication thread was idle.
  */
bool CommThread::ReloadTranslation()
{
    QMutexLocker locker(&m_mutex);

    /**
      * Make sure we are not running another command
      */
    if(m_curOP != OP_idle){
        return false;
    }

    startCmd(OP_reloadTransTable);

    return true;
}

/**
  * Set the Z88 Real time Clock to the Host computer time.
  * @return true if communication thread was idle.
  */
bool CommThread::setZ88Time()
{
    QMutexLocker locker(&m_mutex);

    /**
      * Make sure we are not running another command
      */
    if(m_curOP != OP_idle){
        return false;
    }

    startCmd(OP_setZ88Clock);

    return true;
}

/**
  * Get the Z88 Real Time Clock.
  * @return true if communication thread was idle.
  */
bool CommThread::getZ88Time()
{
    QMutexLocker locker(&m_mutex);

    /**
      * Make sure we are not running another command
      */
    if(m_curOP != OP_idle){
        return false;
    }

    startCmd(OP_getZ88Clock);

    return true;
}

/**
  * Read the Z88 Misc Information.
  * @return true if communication thread was idle.
  */
bool CommThread::getInfo()
{
    QMutexLocker locker(&m_mutex);

    /**
      * Make sure we are not running another command
      */
    if(m_curOP != OP_idle){
        return false;
    }

    startCmd(OP_getInfo);

    return true;
}

/**
  * Get a list of the Storage Devices on the Z88.
  * @return true if communication thread was idle.
  */
bool CommThread::getDevices()
{
    QMutexLocker locker(&m_mutex);

    /**
      * Make sure we are not running another command
      */
    if(m_curOP != OP_idle){
        return false;
    }

    startCmd(OP_getDevices);

    return true;
}

/**
  * private get Z88 Directories Method.
  * @param devname is the Z88 Storage device to read.
  * @return the OP code to get directories.
  */
CommThread::comOpcodes_t CommThread::_getDirectories(const QString &devname){
    m_z88devname = devname;
    m_z88devname += "//*";
    m_z88devspec = devname;

    return (m_curOP = OP_getDirectories);
}

/**
  * private: get the Z88 Files on the Specified Device.
  * @param devname is the device to read.
  * @return the OP code to get directories.
  */
CommThread::comOpcodes_t CommThread::_getFileNames(const QString &devname)
{
    m_z88devname = devname;
    m_z88devname += "//*";
    m_z88devspec = devname;

    return(m_curOP = OP_getFilenames);
}

/**
  * Get the Directories from the Specified Z88 Device.
  * @return true if communication thread was idle.
  */
bool CommThread::getDirectories(const QString &devname)
{
    QMutexLocker locker(&m_mutex);

    /**
      * Make sure we are not running another command
      */
    if(m_curOP != OP_idle){
        return false;
    }

    startCmd(_getDirectories(devname));

    return true;
}

/**
  * Get Filenames from the Specified Z88 Device.
  * @return true if communication thread was idle.
  */
bool CommThread::getFileNames(const QString &devname)
{
    QMutexLocker locker(&m_mutex);

    /**
      * Make sure we are not running another command
      */
    if(m_curOP != OP_idle){
        return false;
    }

    startCmd(_getFileNames(devname));

    return true;
}

/**
  * Retreive the Entire File tree of directories and File Names on the Specified Device.
  * @param ena_size set to true to retreive file sizes also.
  * @param ena_date set to true to retreive file dates also.
  * @return true if communication thread was idle.
  */
bool CommThread::getZ88FileSystemTree(bool ena_size, bool ena_date)
{
    QMutexLocker locker(&m_mutex);

    /**
      * Make sure we are not running another command
      */
    if(m_curOP != OP_idle){
        return false;
    }

    m_enaFilesize = ena_size;
    m_enaTimeDate = ena_date;

    startCmd(OP_getZ88FileTree);

    return true;
}

/**
  * Retrieve a List of Files from the Z88.
  * @param z88Selections is a list of files to retreive.
  * @param hostpath is the fully qualified directory on the host to save the files.
  * @parm prompt_usr set to true, to poll user for each file.
  * @return true if communication thread was idle.
  */
bool CommThread::receiveFiles(QList<Z88_Selection> *z88Selections, const QString &destpath, bool dest_isDir, bool prompt_usr)
{
    QMutexLocker locker(&m_mutex);

    /**
      * Make sure we are not running another command
      */
    if(m_curOP != OP_idle){
        return false;
    }

    m_z88Selections = z88Selections;
    m_enaPromtUser = prompt_usr;
    m_destPath = destpath;
    m_dest_isDir = dest_isDir;

    startCmd(OP_initreceiveFiles);

    return true;
}

/**
  * Receive the Next file in the Selection list.
  * NOTE: only call this after a call to receiveFiles()
  * @param skip set to true to skip over the next file in the list.
  */
bool CommThread::receiveFile(bool skip)
{
    QMutexLocker locker(&m_mutex);

    /**
      * Make sure we are not running another command
      */
    if(m_curOP != OP_idle){
        return false;
    }

    if(skip){
        startCmd(OP_receiveNext,false);
    }
    else{
        startCmd(OP_receiveFile,false);
    }
    return true;
}

bool CommThread::dirLoadComplete()
{
    QMutexLocker locker(&m_mutex);

    /**
      * Make sure we are not running another command
      */
    if(m_curOP != OP_idle){
        return false;
    }

    startCmd(OP_dirLoadDone, false);

    return true;
}

bool CommThread::sendFiles(QList<DeskTop_Selection> *deskSelections, const QString &destpath, bool prompt_usr)
{
    QMutexLocker locker(&m_mutex);

    /**
      * Make sure we are not running another command
      */
    if(m_curOP != OP_idle){
        return false;
    }

    m_deskSelections = deskSelections;
    m_enaPromtUser = prompt_usr;
    m_destPath = destpath;

    startCmd(OP_initsendFiles);

    return true;
}

bool CommThread::sendFile(bool skip)
{
    QMutexLocker locker(&m_mutex);

    /**
      * Make sure we are not running another command
      */
    if(m_curOP != OP_idle){
        return false;
    }

    if(skip){
        startCmd(OP_sendNext,false);
    }
    else{
        startCmd(OP_sendFile,false);
    }
    return true;
}

/**
  * Start a Command thread
  * @param op is the Command op code
  * @param ena_resume set to true to allow a failure to resume from this command.
  */
void CommThread::startCmd(const CommThread::comOpcodes_t &op, bool ena_resume)
{
    if(ena_resume){
        m_prevOP = op;
        /**
          * Disable the abort status
          */
        m_abort = false;
    }

    m_curOP = op;

    /**
      * Start the Command Thread
      */
    if (!isRunning())
        start();
    else
        m_cond.wakeOne();

}




