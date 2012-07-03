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

#include "mainwindow.h"
#include "commthread.h"
#include "z88filespec.h"
#include "desktop_view.h"
#include "z88_devview.h"
#include "prefrences_dlg.h"
#include "actionsettings.h"


/**
  * The Communications Thread Constructor.
  * @param port is a reference to the Z88 Serial port class to use for I/O.
  * @param parent is the owner QT Object.
  */
CommThread::CommThread(Z88SerialPort &port, MainWindow *parent)
  :QThread(parent),
   m_sport(port),
   m_curOP(OP_idle),
   m_prevOP(OP_idle),
   m_redo_lastCmd(false),
   m_enaFilesize(false),
   m_enaTimeDate(false),
   m_enaPromtUser(0),
   m_byteTranslation(false),
   m_linefeedConversion(false),
   m_xferFileprogress(0),
   m_z88Selections(NULL),
   m_z88RenDelSelections(NULL),
   m_deskSelections(NULL),
   m_z88Sel_itr(NULL),
   m_deskSel_itr(NULL),
   m_z88rendel_itr(NULL),
   m_mainWindow(parent),
   m_dest_isDir(false),
   m_runCnt(0),
   m_abort(false)
{

    connect(&m_sport,
            SIGNAL(impExpRecFilename(const QString &)),
            this,
            SLOT(impExpRecFilename(const QString &)) );

    connect(&m_sport,
            SIGNAL(impExpRecFile_Done(const QString &)),
            this,
            SLOT(impExpRecFile_Done(const QString &)) );
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

    if(m_curOP == OP_getZ88FileTree_dly){
        cmdStatus("Prepairing to Read Z88 File System");
        sleep(2);
        m_mutex.lock();
        m_curOP = OP_getZ88FileTree;
        m_mutex.unlock();
    }

    m_runCnt++;

    emit enableCmds(false, m_sport.isOpen());

    if(m_abort){
        cmdStatus("Command Aborted!");
        goto abort;
    }

    switch(m_curOP){
        case OP_idle:           // Comms Thread is Idle.
            break;
        case OP_reopen:         // Re-open the Serial port.
            m_curOP = OP_openDevName;
            run();
            if(m_redo_lastCmd && m_sport.isOpen()){
                m_curOP = m_prevOP;
                m_redo_lastCmd = false;
                run();
            }
            break;
        case OP_openDevName:    // Open the Specified Serial Device.
            msg = "Trying to Open Port ";
            msg += m_shortname;
            cmdStatus(msg);
            emit open_result(m_devname, m_shortname, m_sport.open(m_devname));
            break;
        case OP_openDevXonXoff: // Open the Serial Port for Xon/Xoff operation.
            msg = "Trying to Open Port ";
            msg += m_shortname;
            cmdStatus(msg);
            emit open_result(m_devname, m_shortname, m_sport.openXonXoff(m_devname));
            break;
        case OP_helloZ88:       // Send a Z88 Hello Command.
            cmdStatus("Sending Hello Z88");
            emit boolCmd_result("HelloZ88", m_sport.helloZ88());
            break;
        case OP_quitZ88:        // Request the Z88 Shutdown the Eazylink Pull-down.
        {
            if (m_sport.isZ88Available() == true) {
                cmdStatus("Sending Z88 Quit EasyLink");
                bool rc = m_sport.quitZ88();
                emit boolCmd_result("Z88 Quit EazyLink", rc);
                if(rc){
                    m_sport.close();
                }
            }
        }
        break;
        case OP_reloadTransTable:   // Reload the Z88 Translation Table
            cmdStatus("Sending Reload Translation Table");
            emit boolCmd_result("Reload Translation Table", m_sport.reloadTranslationTable());
            break;
        case OP_setZ88Clock:        // Set the Z88 Clock to the Desktop Time.
            cmdStatus("Syncing Z88 Clock to host Time");
            emit boolCmd_result("Z88 Clock Sync", m_sport.setZ88Time());
            break;
        case OP_getZ88Clock:        // Read the Z88 Real-time Clock.
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
                emit boolCmd_result("Reading Z88 Clock", false);
            }
        }
            break;
        case OP_getInfo:            // Read Misc Info from the Z88.
        {
            QList<QByteArray> *infolist = new QList<QByteArray>;
            cmdStatus("Reading Z88 Info.");

            infolist->append(m_sport.getEazyLinkZ88Version());
            if(infolist->count()!=1){
                emit boolCmd_result("Reading Z88 Version", false);
                break;
            }
            /**
              * Read Z88 Free memory
              */
            infolist->append(m_sport.getZ88FreeMem());

            if(infolist->count()!=2){
                emit boolCmd_result("Reading Z88 Free Memory", false);
                break;
            }
            emit boolCmd_result("Reading Z88 Info", true);

            infolist->append(m_sport.getDevices());
            emit Z88Info_result(infolist);
            break;
        }

        case OP_getDevices:         // Read the Available Z88 Storage Devices.
        {
            QList<QByteArray> *devlist = new QList<QByteArray>;
            cmdStatus("Searching for Z88 Storage Devices.");

            /**
              * Read Devices
              */
            devlist->append(m_sport.getDevices());
            emit Z88Devices_result(devlist);

            emit boolCmd_result("Reading Z88 Devices", !devlist->isEmpty());

            break;
        }
        case OP_getDirectories:     // Read the Directories available on the Z88 Device.
        {
            QList<QByteArray> *dirlist = new QList<QByteArray>;
            cmdStatus("Searching for Z88 Directories.");

            /**
              * Read Directories
              */
            dirlist->append(m_sport.getDirectories(m_z88devname));
            emit Z88Dir_result(m_z88devspec, dirlist);

            emit boolCmd_result("Reading Z88 Directories", !dirlist->isEmpty());
            break;
        }
        case OP_getDevInfo:     // Get the Free Space info for a device.
        {
            QList<QByteArray> *devInfolist = new QList<QByteArray>;

            devInfolist->append(m_sport.getDeviceInfo(m_z88devname.mid(0,6)));

            if(devInfolist->count() == nfo_max){
                emit Z88DevInfo_result(m_z88devname,
                                       devInfolist->at(dev_free).toLong(),
                                       devInfolist->at(dev_total).toLong() * BYTES_PER_K);
            }
            break;
        }
        case OP_getFilenames:       // Read the Filenames on the Z88 Storage Device.
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

            emit boolCmd_result("Reading Z88 Files", retc);
            break;
        }
        case OP_getZ88FileTree_dly:
            break;  // This should never happen
        case OP_getZ88FileTree:     // Get the entire Z88 File tree.
        {
            QList<QByteArray> *infolist = new QList<QByteArray>;
            cmdStatus("Reading Z88 Info.");

            infolist->append(m_sport.getEazyLinkZ88Version());
            if(infolist->count()!=1){
                emit boolCmd_result("Reading Z88 Version", false);
            }
            else{
                m_EzSvr_Version = infolist->first();
            }

            QList<QByteArray> *devlist = new QList<QByteArray>;
            cmdStatus("Reading Z88 File System");

            /**
              * Read Devices
              */
            devlist->append(m_sport.getDevices());
            emit Z88Devices_result(devlist);

            if(devlist->isEmpty()){
                emit boolCmd_result("Reading Z88 Devices", false);
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

                /**
                  * If Available, get the Free device space
                  */
                _getDevInfo(i.peekNext());

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
            emit boolCmd_result("Z88 Refresh", true);

            break;
        }
        case OP_initreceiveFiles:       // Start the Receive Files Process
        {
            delete m_z88Sel_itr;
            m_z88Sel_itr = new QListIterator<Z88_Selection> (*m_z88Selections);
            m_z88Sel_itr->toFront();
            m_xferFileprogress = 0;

            /** ensure that current translation mode is set on Z88 before actual transfer begins.. */
            if(!BYTE_TranslationEnable(m_byteTranslation = m_mainWindow->get_Prefs().get_Byte_Trans())){
                break;
            }

            /** ensure that current CRLF mode is also set ... */
            if(!CRLF_TranslationEnable(m_linefeedConversion = m_mainWindow->get_Prefs().get_CRLF_Trans())){
                break;
            }

            // drop through
        }

        case OP_receiveFiles:       // Receive files from the Z88
        {
            if(m_z88Sel_itr->hasNext()){

                const Z88_Selection &z88sel(m_z88Sel_itr->peekNext());
                QString srcname(z88sel.getFspec());
                QString dest = m_destPath + "/" + z88sel.getRelFspec();

                QString cmdLine;
                int action = m_mainWindow->get_Prefs().findAction(Action_Settings::ActKey_RX_FROMZ88,  dest, cmdLine );

                /**
                  * Skip the file Requested.
                  */
                if(action == 4){
                    m_curOP = OP_receiveNext;
                    run();
                    break;
                }

                /**
                  * Allow for User Expanded cmd line.
                  * Don't use cmd line with the Open On....
                  */
                if(action != Action_Settings::OPEN_WITH_ID){
                    dest = cmdLine;
                }

                if(shouldPromptUser(z88sel, dest)){
                    emit PromptReceiveSpec(srcname, dest, &m_enaPromtUser);
                    break;
                }

                m_curOP = OP_receiveFile;
                run();
            }
            emit cmdProgress("Done", -1, -1); // reset the progress dialog

            break;
        }
        case OP_receiveFile:        // Get the Specified file.
        {
            Z88SerialPort::retcode rc;
            QString cmdLine;
            int action;

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
                  * See if the File Already Exists and Skip the File if Needed.
                  */
                if((m_enaPromtUser & FILE_EXISTS) && (m_enaPromtUser & (NO_TO_OW_ALL))){
                    goto skip2;
                }

                cmdLine.clear();
                action = m_mainWindow->get_Prefs().findAction(Action_Settings::ActKey_RX_FROMZ88,  m_destPath + "/" + z88sel.getRelFspec(), cmdLine );

                if(action == 0){ // Receive Default
                    bool ena = m_mainWindow->get_Prefs().get_CRLF_Trans();

                    if(m_linefeedConversion != ena){
                        if(!CRLF_TranslationEnable(ena)){
                            break;
                        }
                        m_linefeedConversion = ena;
                    }

                    ena = m_mainWindow->get_Prefs().get_Byte_Trans();

                    if(m_byteTranslation != ena){
                        if(!BYTE_TranslationEnable(ena)){
                            break;
                        }
                        m_byteTranslation = ena;
                    }
                }
                else{
                    if(action == 2){ // Convert CRLF
                        if(!m_linefeedConversion){
                            if(!CRLF_TranslationEnable(true)){
                                break;
                            }
                        }
                        m_linefeedConversion = true;
                    }
                    else{
                        if(action == 3){ // RX Binary
                            if(m_linefeedConversion){
                                if(!CRLF_TranslationEnable(false)){
                                    break;
                                }
                            }
                            m_linefeedConversion = false;

                            if(m_byteTranslation){
                                if(!BYTE_TranslationEnable(false)){
                                    break;
                                }
                                m_byteTranslation = false;
                            }
                        }
                    }
                }

                /**
                  * Receive the file from Z88
                  */
                if(action != Action_Settings::OPEN_WITH_ID){
                    rc = m_sport.receiveFiles(srcname, m_destPath, cmdLine, m_dest_isDir);
                }
                else{
                    rc = m_sport.receiveFiles(srcname, m_destPath, z88sel.getRelFspec(), m_dest_isDir);
                }

                m_xferFileprogress++;

                /**
                  * Post RX Processing Action Handling
                  */
                action = m_mainWindow->get_Prefs().execActions(Action_Settings::ActKey_RX_FROMZ88,  m_destPath + "/" + z88sel.getRelFspec(), cmdLine );

                if(m_abort){
                    cmdStatus("Transfer Cancelled.");
                    break;
                }

                emit boolCmd_result("Transfer", (rc == Z88SerialPort::rc_done));

                if(rc != Z88SerialPort::rc_done){
                    qDebug() << "Transfer rc=" << rc;
                    break;
                }
skip2:
                if(m_z88Sel_itr->hasNext()){
                    const Z88_Selection &z88selnxt(m_z88Sel_itr->peekNext());
                    QString dest = m_destPath + "/" + z88selnxt.getRelFspec();

                    QString cmdLine;
                    int action = m_mainWindow->get_Prefs().findAction(Action_Settings::ActKey_RX_FROMZ88,  dest, cmdLine );

                    /**
                      * Skip the file Requested.
                      */
                    if(action == 4){
                        m_curOP = OP_receiveNext;
                        run();
                        break;
                    }

                    /**
                      * Allow for User Expanded cmd line.
                      * Don't use cmd line with the Open On....
                      */
                    if(action != Action_Settings::OPEN_WITH_ID){
                        dest = cmdLine;
                    }

                    if(shouldPromptUser(z88selnxt, dest)){
                        srcname = z88selnxt.getFspec();

                        emit PromptReceiveSpec(srcname, dest, &m_enaPromtUser);
                        break;
                    }
                }
                else{
                    emit boolCmd_result("File Transfer", true);
                }

            } while(m_z88Sel_itr->hasNext());

            emit cmdProgress("Done", -1, -1); // reset the progress dialog
            break;
        }
        case OP_receiveNext:        // Receive the Next File from the Z88.
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
        case OP_dirLoadDone:        // The Desktop Dir read is complete event.
            if(!m_abort){
                setState_Idle();
                emit DirLoadComplete(false);
                if(--m_runCnt <=0){
                    m_runCnt = 0;
                  //Oscar  emit enableCmds(true, m_sport.isOpen());
                }
                return;  // Don't re-enable commands here
            }
            break;
        case OP_initsendFiles:      // Start the Send Files to Z88 Process.
        {
            delete m_deskSel_itr;
            m_deskSel_itr = new QListIterator<DeskTop_Selection> (*m_deskSelections);
            m_deskSel_itr->toFront();
            m_xferFileprogress = 0;

            /** ensure that Z88 time is equal to desktop time, before transfering file to Z88 */
            if (m_mainWindow->get_Prefs().get_AutoSyncClock() && m_sport.syncZ88Time() == true){
                cmdStatus("Z88 Time has been synchronised with desktop time");
            }

            /** ensure that current translation mode is set on Z88 before actual transfer begins.. */
            if(!BYTE_TranslationEnable( m_byteTranslation = m_mainWindow->get_Prefs().get_Byte_Trans())){
                break;
            }

            /** ensure that current CRLF mode is also set ... */
            if(!CRLF_TranslationEnable( m_linefeedConversion = m_mainWindow->get_Prefs().get_CRLF_Trans())){
                break;
            }

            // drop through
        }
        case OP_sendFiles:          // Send Files to the Z88.
        {
            if(m_deskSel_itr->hasNext()){

                const DeskTop_Selection &desksel(m_deskSel_itr->peekNext());
                QString destFspec = m_destPath + desksel.getFname();
                QString srcname(desksel.getFspec());

                QString cmdLine;
                int action = m_mainWindow->get_Prefs().findAction(Action_Settings::ActKey_TX_TOZ88,  destFspec, cmdLine );

                /**
                  * Skip the file Requested.
                  */
                if(action == 4){  // Skip
                    m_curOP = OP_sendNext;
                    run();
                    break;
                }

                if(action != Action_Settings::OPEN_WITH_ID){
                    destFspec = cmdLine;
                }

                /**
                  * Prompt the User for transfer and / or for Overwrite
                  */
                if(shouldPromptUser(desksel, destFspec))
                {
                    emit PromptSendSpec(srcname, destFspec, &m_enaPromtUser);
                    break;
                }

                m_curOP = OP_sendFile;
                run();
            }
            emit cmdProgress("Done", -1, -1); // reset the progress dialog
            break;
        }
        case OP_sendFile:           // Send a File To the Z88.
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
                    if(!rc){
                        rc = !m_sport.isFileAvailable(destFspec);
                    }
                }
                else{
                    /**
                      * See if the File Already Exists and Skip the File if Needed.
                      */
                    if((m_enaPromtUser & FILE_EXISTS) && (m_enaPromtUser & (NO_TO_OW_ALL))){
                        goto skip1;
                    }

                    QString cmdLine;
                    int action = m_mainWindow->get_Prefs().findAction(Action_Settings::ActKey_TX_TOZ88,  destFspec, cmdLine );

                    if(action == 0){ // send Default
                        bool ena = m_mainWindow->get_Prefs().get_CRLF_Trans();

                        if(m_linefeedConversion != ena){
                            if(!CRLF_TranslationEnable(ena)){
                                break;
                            }
                            m_linefeedConversion = ena;
                        }

                        ena = m_mainWindow->get_Prefs().get_Byte_Trans();

                        if(m_byteTranslation != ena){
                            if(!BYTE_TranslationEnable(ena)){
                                break;
                            }
                            m_byteTranslation = ena;
                        }
                    }
                    else{
                        if(action == 2){ // Convert CRLF
                            if(!m_linefeedConversion){
                                if(!CRLF_TranslationEnable(true)){
                                    break;
                                }
                            }
                            m_linefeedConversion = true;
                        }
                        else{
                            if(action == 3){ // TX Binary
                                if(m_linefeedConversion){
                                    if(!CRLF_TranslationEnable(false)){
                                        break;
                                    }
                                }
                                m_linefeedConversion = false;

                                if(m_byteTranslation){
                                    if(!BYTE_TranslationEnable(false)){
                                        break;
                                    }
                                    m_byteTranslation = false;
                                }
                            }
                        }
                    }

                    if(action == Action_Settings::OPEN_WITH_ID){
                        qDebug() <<  "Open With [" << cmdLine <<  "] Not Implemented Yet.";
                    }
                    else{
                        if(!cmdLine.isEmpty()){
                            destFspec = cmdLine;
                        }
                    }

                    rc = m_sport.sendFile(destFspec, srcname);
                }

                if(m_abort){
                    cmdStatus("Transfer Cancelled.");
                    break;
                }

                emit boolCmd_result("Transfer", rc);

                if(!rc){
                    break;
                }
skip1:             
                m_xferFileprogress++;

                if(m_deskSel_itr->hasNext()){
                    const DeskTop_Selection &deskselnxt(m_deskSel_itr->peekNext());

                    QString destFspec = m_destPath + deskselnxt.getFname();

                    QString cmdLine;
                    int action = m_mainWindow->get_Prefs().findAction(Action_Settings::ActKey_TX_TOZ88,  destFspec, cmdLine );

                    /**
                      * Skip the file Requested.
                      */
                    if(action == 4){
                        m_curOP = OP_sendNext;
                        run();
                        break;
                    }

                    if(action == Action_Settings::OPEN_WITH_ID){
                        destFspec = cmdLine;
                    }

                    if(shouldPromptUser(deskselnxt, destFspec)){
                        srcname = deskselnxt.getFspec();
                        emit PromptSendSpec(srcname, destFspec, &m_enaPromtUser);
                        break;
                    }
                }
                else{
                    emit cmdProgress("Done", -1, -1); // reset the progress dialog

                    /**
                     * Refresh the Device view
                     */
                    emit refreshSelectedZ88DeviceView();

                    emit boolCmd_result("File Transfer", true);
                }

            } while(m_deskSel_itr->hasNext());

            emit cmdProgress("Done", -1, -1); // reset the progress dialog
            break;
        }
        case OP_sendNext:           // Send the Next File to the Z88.
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
            else{
                emit cmdProgress("Done", -1, -1); // reset the progress dialog

                /**
                 * Refresh the Device view
                 */
                 emit refreshSelectedZ88DeviceView();
            }

            break;
        }
        case OP_createDir:          // Create A Directory on the Z88
        {
            emit cmdStatus("Creating Directory " + m_z88devspec);

            bool rc;

            rc = m_sport.createDir(m_z88devspec);

            /**
              * Try to create a Directory, otherwise find out why it couldn't be created.
              */
            if(rc){
                /**
                 * Refresh the Device view
                 */
                emit refreshSelectedZ88DeviceView();
            }
            else{
                QList<QByteArray> dirs(m_sport.getDirectories(m_z88devspec));
                QListIterator<QByteArray> i(dirs);

                while(i.hasNext()){
                    if(QString(i.next()) == m_z88devspec){
                        QString msg("Directory " + m_z88devspec + " Already exists!");

                        emit cmdStatus(msg);
                        emit displayCritError("Cannot Create Directory.\n" + msg);
                        goto done;
                    }
                }
            }

            emit boolCmd_result("Make Directory", rc);
done:
            break;
        }
        case OP_initrenameDirFiles:     // Start the Rename dir or files on Z88 Process.
        {
            delete m_z88rendel_itr;
            m_z88rendel_itr = new QMutableListIterator<Z88_Selection> (*m_z88RenDelSelections);

            m_z88rendel_itr->toFront();
            // Drop Through
        }
        case OP_renameDirFiles:         // Rename Files or Directories on the Z88.
        {
            if(m_z88rendel_itr->hasNext()){
                emit PromptRename(m_z88rendel_itr);
            }

            break;
        }
        case OP_renameDirFile:          // Rename a File or Dir on the Z88.
        {
            bool rc = true;

            if(!m_destPath.isEmpty()){
                rc = m_sport.renameFileDir(m_z88devspec, m_destPath);

                if(rc){                 
                    emit renameZ88Item(&(m_z88rendel_itr->peekNext()), m_destPath);
                }
                else{
                    int idx = m_z88devspec.lastIndexOf('/');
                    if(idx > -1){
                        m_destPath = m_z88devspec.mid(0, idx) + '/' + m_destPath;
                    }

                    if(m_z88rendel_itr->peekNext().getType() == Z88_DevView::type_Dir){

                        QList<QByteArray> dirs(m_sport.getDirectories(m_destPath));
                        QListIterator<QByteArray> i(dirs);

                        while(i.hasNext()){
                            if(QString(i.next()) == m_destPath){
                                QString msg("Cannot Rename Directory.\n" + m_destPath + " Already exists!");
                                emit renameCmd_result(msg, rc);
                                break;
                            }
                        }
                    }
                    else{
                        /* Rename of File Failed */
                        if(m_sport.isFileAvailable(m_destPath)){
                            QString msg("Cannot Rename File.\n" + m_destPath + " Already exists!");
                            emit renameCmd_result(msg, rc);
                        }
                    }
                }
            }

            if(rc){
                m_z88rendel_itr->next();
                /**
                  * Do the Next one
                  */
                m_curOP = OP_renameDirFiles;
                run();
            }

            break;
        }
        case OP_initdelDirFiles:            // Start the Delete Files or Dirs on the z88 Process.
        {
            delete m_z88rendel_itr;
            m_z88rendel_itr = new QMutableListIterator<Z88_Selection> (*m_z88RenDelSelections);
            m_xferFileprogress = 0;
            m_z88rendel_itr->toFront();

            // Drop Through
        }
        case OP_delDirFiles:                // Delete files or Directories on the Z88.
        {
            if(m_z88rendel_itr->hasNext()){

                const Z88_Selection &z88sel(m_z88rendel_itr->peekNext());
                QString srcname(z88sel.getFspec());

                if(m_enaPromtUser & PROMPT_USER){
                    emit PromptDeleteSpec(srcname, (z88sel.getType() == Z88_DevView::type_Dir), &m_enaPromtUser);
                    break;
                }

                m_curOP = OP_delDirFile;
                run();
            }
            else{
                /**
                  * If Available, get the Free device space
                  */
                _getDevInfo(m_z88devspec);
            }

            emit cmdProgress("Done", -1, -1); // reset the progress dialog

            break;
        }
        case OP_delDirFile:                // Delete a Directory or File on the Z88.
        {
            if(!m_z88RenDelSelections){
                break;
            }

            do{
                if(m_abort){
                    cmdStatus("Delete Aborted..");
                    break;
                }

                QTreeWidgetItem *item(m_z88rendel_itr->peekNext().getQtreeItem());
                Z88_Selection z88sel(m_z88rendel_itr->next());
                QString srcname(z88sel.getFspec());

                QString msg = "Erasing ";
                msg += srcname;

                /**
                  * Update the Progress Bar
                  */
                emit cmdProgress(msg, m_xferFileprogress, m_z88RenDelSelections->count());

                qDebug() << "z88 erase:" << srcname;

                /**
                  * Request the delete of the file / dir
                  */
                bool rc = m_sport.deleteFileDir(srcname);

                m_xferFileprogress++;

                if(rc){
                    emit deleteZ88Item(item);
                }
                else{
                    bool retc;
                    /**
                      * See if the dir is empty
                      */
                    if(z88sel.getType() == Z88_DevView::type_Dir){
                        int cnt = m_sport.getFilenames(srcname + '*', retc).count();
                        if(!retc){
                            emit boolCmd_result("Delete " + srcname, false);
                            goto done2;
                        }
                        if(cnt > 0){
                            rc = true;
                        }
                    }
                    else{
                        int cnt = m_sport.getFilenames(srcname , retc).count();
                        if(!cnt || !retc){
                            emit boolCmd_result("Delete " + srcname, false);
                            goto done2;
                        }
                    }
                }

                if(!rc){
                    m_z88rendel_itr->previous();
                    emit PromptDeleteRetry(srcname, (z88sel.getType() == Z88_DevView::type_Dir));
                    goto done2;
                    break;
                }

                if((m_enaPromtUser & PROMPT_USER) && m_z88rendel_itr->hasNext()){
                    const Z88_Selection &z88selnxt(m_z88rendel_itr->peekNext());

                    srcname = z88selnxt.getFspec();
                    emit PromptDeleteSpec(srcname, (z88sel.getType() == Z88_DevView::type_Dir), &m_enaPromtUser);
                    goto done2;
                }

            }while(m_z88rendel_itr->hasNext());

            emit cmdProgress("Done", -1, -1); // reset the progress dialog         
done2:

            /**
              * If Available, get the Free device space
              */
            _getDevInfo(m_z88devspec);

            break;
        }
        case OP_delDirFileNext:         // Delete Next Z88 Dir or file.
        {
            /**
              * Skip the current file
              */
            if(m_z88rendel_itr->hasNext()){
                m_z88rendel_itr->next();
                m_xferFileprogress++;
            }

            /**
              * Delete the next file
              */
            if(m_z88rendel_itr->hasNext()){
                m_curOP = OP_delDirFiles;
                run();
            }
            else{
                /**
                  * If Available, get the Free device space
                  */
                _getDevInfo(m_z88devspec);
                emit cmdProgress("Done", -1, -1);
            }

            break;
        }
        case OP_refreshZ88View:         // Refresh the Z88 View
        {
            emit cmdProgress("Done", -1, -1);
            /**
              * If Available, get the Free device space
              */
            _getDevInfo(m_z88devspec);

            _getDirectories(m_z88devspec);
            run();
            _getFileNames(m_z88devspec);
            run();
        }
        case OP_impExpSendFiles:
        {
            int cnt = m_ImpExp_srcList.count();
            bool rc = true;

            if(cnt){
                for(int idx = 0; idx < cnt; idx++ ){
                    if(m_abort){
                        break;
                    }

                    QString msg = "Sending ";
                    msg += m_ImpExp_dstList[idx];

                    emit cmdStatus("Imp-Export Sending: " + m_ImpExp_srcList[idx]);
                    emit cmdProgress(msg, idx, cnt);
                  //  qDebug() << "dev=" << m_destPath << " src=" << m_ImpExp_srcList[idx] << " dst=" << m_ImpExp_dstList[idx];

                    if(!(rc = m_sport.impExpSendFile(m_destPath + m_ImpExp_dstList[idx], m_ImpExp_srcList[idx]))){
                        emit boolCmd_result("Imp-Export Send " + m_ImpExp_srcList[idx], false);
                        break;
                    }
                }
                if(rc){
                    emit boolCmd_result("Imp-Export Send", rc);
                }
                emit cmdProgress("done", -1, -1);
            }
            break;
        }
        case OP_impExpRecvFiles:
        {
            emit cmdStatus("Imp-Export Receiving into: " + m_destPath);

            bool rc = m_sport.impExpReceiveFiles(m_destPath);
            emit boolCmd_result("Imp-Export Receive", rc);
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

    if(--m_runCnt <=0){
        m_runCnt = 0;
        emit enableCmds(true, m_sport.isOpen());
    }

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
  * Imp-Export Protocol Receive File Start
  * @param fname is the File name that started.
  */
void CommThread::impExpRecFilename(const QString &fname)
{
    emit cmdStatus("Imp-Export receiving file: " + fname);
}

/**
  * Import Export Protocol Receive File Complete.
  * @param fname is the name of the Complete file.
  */
void CommThread::impExpRecFile_Done(const QString &fname)
{
    emit boolCmd_result("Imp-Export Receive " + fname, true);
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
  * @return true if communication thread is busy, else false.
  */
bool CommThread::isBusy()
{
    QMutexLocker locker(&m_mutex);

    /**
      * Make sure we are not running another command
      */
    if(m_curOP == OP_idle)
        return false;
    else
        return true;
}

/**
  * Method to test if the Communications Port is Open.
  * @return true if the port is open.
  */
bool CommThread::isOpen()
{
    QMutexLocker locker(&m_mutex);

    return m_sport.isOpen();
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
  * Refresh the Specified Z88 Device View.
  * @param devname is the name of the Z88 Sotrage device.
  */
bool CommThread::RefreshZ88DeviceView(const QString &devname)
{
    QMutexLocker locker(&m_mutex);

    /**
      * Make sure we are not running another command
      */
    if(m_curOP != OP_idle){
        qDebug() << "In RefreshZ88DeviceView but not Idle State=" << m_curOP;
        return false;
    }

    m_z88devspec = devname;

    startCmd(OP_refreshZ88View);

    return true;
}

/**
  * Create a Directory on the Z88.
  * @param dirname is the string name of the directory to create.
  * @return true if com thread isn't already busy.
  */
bool CommThread::mkDir(const QString &dirname)
{
        QMutexLocker locker(&m_mutex);

        /**
          * Make sure we are not running another command
          */
        if(m_curOP != OP_idle){
            return false;
        }

        m_z88devspec = dirname;

        startCmd(OP_createDir);

        return true;
}

/**
  * Rename a Z88 File or Directory.
  * @param oldname is the Current file or dir name.
  * @param newname is the New Name
  * @return true if the Comthread is not already busy.
  */
bool CommThread::renameFileDir(const QString &oldname, const QString &newname)
{
    QMutexLocker locker(&m_mutex);

    /**
      * Make sure we are not running another command
      */
    if(m_curOP != OP_idle){
        return false;
    }

    m_z88devspec = oldname;
    m_destPath = newname;

    startCmd(OP_renameDirFile);

    return true;
}

/**
  * Rename a list of Z88 Files or Directories.
  * z88Selections is a list of files or directories to rename.
  * @return true if the Comthread is not already busy.
  */
bool CommThread::renameFileDirectories(QList<Z88_Selection> *z88Selections)
{
    QMutexLocker locker(&m_mutex);

    /**
      * Make sure we are not running another command
      */
    if(m_curOP != OP_idle){
        return false;
    }

    m_z88RenDelSelections = z88Selections;

    startCmd(OP_initrenameDirFiles);

    return true;
}

/**
  * Retry Renaming a File or Directory, after an error.
  * @param next set this to true, to skip the current file or directory.
  * @return true if the com thread isn't already busy.
  */
bool CommThread::renameFileDirRety(bool next)
{
    QMutexLocker locker(&m_mutex);

    /**
      * Make sure we are not running another command
      */
    if(m_curOP != OP_idle){
        return false;
    }

    if(m_z88rendel_itr && m_z88rendel_itr->hasNext()){
        if(next){
            m_z88rendel_itr->next();
        }

        startCmd(OP_renameDirFiles);
    }
    return true;
}

/**
  * Delete a list of Files or Directories on the Z88.
  * @param z88Selections is the list of filenames or directories to delete.
  * @param prompt_usr set to true to prompt for each file or directory before deleting.
  * @return true if the Coms thread is not already busy.
  */
bool CommThread::deleteFileDirectories(QList<Z88_Selection> *z88Selections, uPrompt prompt_usr)
{
    QMutexLocker locker(&m_mutex);

    /**
      * Make sure we are not running another command
      */
    if(m_curOP != OP_idle){
        return false;
    }

    m_enaPromtUser = prompt_usr;
    m_z88RenDelSelections = z88Selections;

    /**
      * Save the Device Name from the First Entry
      */
    if(!m_z88RenDelSelections->isEmpty()){
        m_z88devspec = m_z88RenDelSelections->first().getFspec().mid(0,6);
    }

    startCmd(OP_initdelDirFiles);

    return true;
}

/**
  * Delete a File or Directory on the Z88.
  * @param next set to true to skip over the current file or dir.
  * @return true if the Coms thread is not already busy.
  */
bool CommThread::deleteFileDirectory(bool next)
{

    QMutexLocker locker(&m_mutex);

    /**
      * Make sure we are not running another command
      */
    if(m_curOP != OP_idle){
        return false;
    }

    if(next){
        startCmd(OP_delDirFileNext,false);
    }
    else{
        startCmd(OP_delDirFile,false);
    }

    return true;
}

bool CommThread::impExpSendFile(const QString &Z88_devname, const QStringList &z88Filenames, const QStringList &hostFilenames)
{
    QMutexLocker locker(&m_mutex);

    /**
      * Make sure we are not running another command
      */
    if(m_curOP != OP_idle){
        return false;
    }

    if(z88Filenames.count() != hostFilenames.count() || Z88_devname.isEmpty()){
        return false;
    }

    m_destPath = Z88_devname;
    m_ImpExp_dstList = z88Filenames;
    m_ImpExp_srcList = hostFilenames;

    startCmd(OP_impExpSendFiles);

    return true;
}

bool CommThread::impExpReceiveFiles(const QString &hostPath)
{
    QMutexLocker locker(&m_mutex);

    /**
      * Make sure we are not running another command
      */
    if(m_curOP != OP_idle){
        return false;
    }

    m_destPath = hostPath;

    startCmd(OP_impExpRecvFiles);

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
  * Read the Specified Device Information.
  * @param devname is the Device to Read info.
  * @return True if Serversupports this request, false otherwise
  */
bool CommThread::_getDevInfo(const QString &devname)
{
    /**
      * The First Version of The ExazyLink PUll-down that supports
      * Reading Device Info
      */
    if(m_EzSvr_Version >= "5.2-06"){
        m_z88devname = devname;
        m_z88devname += "//*";
        m_z88devspec = devname;

        m_curOP = OP_getDevInfo;
        run();

        return true;
    }
    return false;
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
    if(m_curOP != OP_idle && m_curOP != OP_getZ88FileTree_dly){
        return false;
    }

    comOpcodes_t op = OP_getZ88FileTree;

    if(m_enaFilesize != ena_size || m_enaTimeDate != ena_date){
        op = OP_getZ88FileTree_dly;
        m_enaFilesize = ena_size;
        m_enaTimeDate = ena_date;
    }

    if(m_curOP == OP_idle){
        startCmd(op);
    }

    return true;
}

/**
  * Retrieve a List of Files from the Z88.
  * @param z88Selections is a list of files to retreive.
  * @param hostpath is the fully qualified directory on the host to save the files.
  * @parm prompt_usr set to true, to poll user for each file.
  * @return true if communication thread was idle.
  */
bool CommThread::receiveFiles(QList<Z88_Selection> *z88Selections, const QString &destpath, bool dest_isDir, uPrompt prompt_usr)
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
  * @return true if the coms thread isn't already busy.
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

/**
  * A callback event from the Dir read thread built into the Desk view.
  * @return true if the coms thread isn't already busy.
  */
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

/**
  * Start the sending of a list of files from the Desktop to the Z88.
  * @param deskSelections is a list of files to transfer to the Z88.
  * @param destpath is the destination path on the Z88.
  * @param prompt_usr set to true on call to prompt before each file transfer.
  * @return true if the coms thread isn't already busy.
  */
bool CommThread::sendFiles(QList<DeskTop_Selection> *deskSelections, const QString &destpath, uPrompt prompt_usr)
{
    QMutexLocker locker(&m_mutex);

    /**
      * Make sure we are not running another command
      */
    if(m_curOP != OP_idle){
        return false;
    }

    delete m_deskSelections;

    m_deskSelections = deskSelections;
    m_enaPromtUser = prompt_usr;
    m_destPath = destpath;

    startCmd(OP_initsendFiles);

    return true;
}

/**
  * Send a File to the Z88.
  * @param skip set to true on call to skip the current entry.
  * @return true if the Comms thread isn't already busy.
  */
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

/**
  * Set the Current Opertation State to Idle.
  * @return the Current Opcode.
  */
CommThread::comOpcodes_t CommThread::setState_Idle()
{
    m_mutex.lock();
    comOpcodes_t curop = m_curOP;
    m_curOP = OP_idle;
    m_mutex.unlock();

    return curop;
}

/**
  * test to see if we should prompt the user for File Transfer
  * @param Source is the Desktop Source File.
  * @param destFspec is the Destination File on the Z88
  * @return true if A prompt is needed.
  */
bool CommThread::shouldPromptUser(const DeskTop_Selection &Source, const QString &destFspec)
{
    m_enaPromtUser &= ~FILE_EXISTS;

    if((m_enaPromtUser & NO_TO_OW_ALL) || !(m_enaPromtUser & YES_TO_OW_ALL) &&
        (Source.getType() == DeskTop_Selection::type_File))
    {
        if(m_sport.isFileAvailable(destFspec)){
            m_enaPromtUser |= FILE_EXISTS;
        }
    }

    return  (Source.getType() == DeskTop_Selection::type_File) &&
            ((m_enaPromtUser & PROMPT_USER) ||
            ((m_enaPromtUser & FILE_EXISTS) &&
             !(m_enaPromtUser & (NO_TO_OW_ALL | YES_TO_OW_ALL))) );
}

/**
  * Test to seeif we should Prompt for User file transfer
  * @parm Source is the Z88 Selection
  * @parm destFspec is the destination on the desktop
  * @return true is prompt is needed
  */
bool CommThread::shouldPromptUser(const Z88_Selection &Source, const QString &destFspec)
{
    m_enaPromtUser &= ~FILE_EXISTS;

    if((m_enaPromtUser & NO_TO_OW_ALL) || !(m_enaPromtUser & YES_TO_OW_ALL) &&
        (Source.getType() == Z88_DevView::type_File))
    {
        /**
          * Check to see if the file exists on Desktop
          */
        QFile ofile(destFspec);

        if(ofile.exists()){
            m_enaPromtUser |= FILE_EXISTS;
        }
    }

    return (Source.getType() == Z88_DevView::type_File) &&
            ((m_enaPromtUser & PROMPT_USER) ||
            ((m_enaPromtUser & FILE_EXISTS) &&
             !(m_enaPromtUser & (NO_TO_OW_ALL | YES_TO_OW_ALL))) );
}

bool CommThread::CRLF_TranslationEnable(bool ena)
{
    if (ena) {
        cmdStatus("Sending Enable CRLF Translation");
        if(!m_sport.linefeedConvOn()){
            emit boolCmd_result("CRLF Translation ON", false);
            return false;
        }
    } else {
        cmdStatus("Sending Disable CRLF Translation");
        if(!m_sport.linefeedConvOff()){
            emit boolCmd_result("CRLF Translation OFF", false);
            return false;
        }
    }

    return true;
}

bool CommThread::BYTE_TranslationEnable(bool ena)
{
    if (ena){
        cmdStatus("Sending Enable Byte Translation");
        if(!m_sport.translationOn()){
            emit boolCmd_result("Byte Translation ON", false);
            return false;
        }
    } else {
        cmdStatus("Sending Disable Byte Translation");
        if(!m_sport.translationOff()){
            emit boolCmd_result("Byte Translation OFF", false);
            return false;
        }
    }
    return true;
}
