/*********************************************************************************************

 EazyLink2 - Fast Client/Server Z88 File Management
 (C) Gunther Strube (gstrube@gmail.com) 2011
  & Oscar Ernohazy 2012

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

#ifndef COMMTHREAD_H
#define COMMTHREAD_H

#include <QThread>
#include <QMutex>
#include<QList>
#include <QWaitCondition>
#include <QProgressDialog>

#include "z88serialport.h"
#include "z88filespec.h"

class Z88_Selection;
class DeskTop_Selection;

/**
  * The Communicatons Thread class to allow background I/O with the Z88.
  * Inherits from the QThread Class.
  */
class CommThread : public QThread
{
    Q_OBJECT

public:
    CommThread(Z88SerialPort &port, QObject *parent = 0);

    ~CommThread();

    /**
      * The Thread Method
      */
    void run();

    /**
      * The Opcodes for Each command the CommThread Supports.
      */
    enum comOpcodes_t {
        OP_idle,                // Thread is idle. Must be in this state to start a new command.
        OP_openDevName,         // Open the Specified Serial Port using Hardware Flow Control.
        OP_openDevXonXoff,      // Open the Specified Serial Port with Xon / Xoff Flow control.
        OP_reopen,              // Re-init the Serial port, and optionally re-run the last command.
        OP_helloZ88,            // Send a Hello Message to the Z88.
        OP_quitZ88,             // Request the Z88 Should exit the Ez-link pulldown app.
        OP_byteTransON,         // Request the Z88 should enable Byte translation.
        OP_byteTransOFF,        // Request the Z88 Should disable the Byte Translation.
        OP_crlfTransON,         // Request the Z88 should enable auto cr/lf translation.
        OP_crlfTransOFF,        // Request the Z88 should turn off the auto cr/lf translation.
        OP_reloadTransTable,    // Request the Z88 reload its translation table.
        OP_setZ88Clock,         // Set the Z88 real time clock.
        OP_getZ88Clock,         // Read the Z88 real time clock.
        OP_getInfo,             // Read misc z88 device information.
        OP_getDevices,          // Read the Available z88 storage Devices.
        OP_getDirectories,      // Read the Dierectories on the selected device.
        OP_getFilenames,        // Read the File names from the selected device.
        OP_getZ88FileTree,      // Read the Entire File tree names from the z88.
        OP_initreceiveFiles,    // Init a new Receive file request from ther Z88.
        OP_receiveFiles,        // Start the Receive file(s) process.
        OP_receiveFile,         // Receive the specified file from the Z88.
        OP_receiveNext          // Skip the current file, and receive the next one. (user prompt to skip)
    };

    /**
     * Api Commands
     */
    void SetupAbortHandler(QProgressDialog *pd);
    void AbortCmd();
    bool close();
    bool reopen(bool redo_lastcmd);
    bool open(const QString &devname, const QString &short_name);
    bool openXonXoff(const QString &devname, const QString &short_name);
    bool helloZ88();
    bool quitZ88();
    bool ByteTrans(bool ena);
    bool CRLFTrans(bool ena);
    bool ReloadTranslation();
    bool setZ88Time();
    bool getZ88Time();
    bool getInfo();
    bool getDevices();
    bool getDirectories(const QString &devname);
    bool getFileNames(const QString &devname);
    bool getZ88FileSystemTree(bool ena_size = false, bool ena_date = false);
    bool receiveFiles(QList<Z88_Selection> *z88Selections, const QString &hostpath, bool prompt_usr = false);
    bool receiveFile(bool skip);

private slots:
    void CancelSignal();

signals:
    void enableCmds(bool ena, bool com_isOpen);
    void open_result(const QString &dev_name, const QString &short_name, bool success);
    void cmdStatus(const QString &msg);
    void cmdProgress(const QString &title, int curVal, int total);
    void boolCmd_result(const QString &cmdName, bool success);
    void Z88Info_result(QList<QByteArray> *infolist);
    void Z88Devices_result(QList<QByteArray> *devlist);
    void Z88Dir_result(const QString &devname, QList<QByteArray> *dirlist);
    void Z88FileSpeclist_result(const QString &devname, QList<Z88FileSpec> *filespeclist);
    void PromptReceiveSpec(const QString &src_name, const QString &dst_name, bool *Continue);

protected:
    void startCmd(const comOpcodes_t &op, bool ena_resume = true);
    comOpcodes_t _getDirectories(const QString &devname);
    comOpcodes_t _getFileNames(const QString &devname);

    /**
      * reference to the Z88 Lower-level command class.
      */
    Z88SerialPort &m_sport;

    /**
      * The Full path to the Serial tty Device.
      */
    QString m_devname;

    /**
      * The User readable Alias for the selected tty port.
      */
    QString m_shortname;

    /**
      * The Z88 Storage Devicename. Ie :RAM.1
      */
    QString m_z88devname;

    /**
      * The fully qualified storage device name.
      */
    QString m_z88devspec;

    /**
      * A Mutex to Lock interractions between the Serial thread, and the GUI.
      */
    QMutex m_mutex;

    /**
      * Thread Wait Condition class.
      */
    QWaitCondition m_cond;

    /**
     * The Current Operation Code
     */
    comOpcodes_t m_curOP;

    /**
     * The Last Operation Code
     */
    comOpcodes_t m_prevOP;

    /**
      * Operation flags
      */
    bool m_redo_lastCmd;
    bool m_enaFilesize;
    bool m_enaTimeDate;
    bool m_enaPromtUser;

    /**
      * The Current File transfer index in the list of files to transfer.
      */
    int m_xferFileprogress;

    /**
      * List of Z88 Files Selected to transfer.
      */
    QList<Z88_Selection>                *m_z88Selections;

    /**
      * The List of Desktop Files selected to transfer.
      */
    QList<DeskTop_Selection>            *m_deskSelections;

    /**
      * Iterators for the selection lists
      */
    QListIterator<Z88_Selection>        *m_z88Sel_itr;
    QListIterator<DeskTop_Selection>    *m_deskSel_itr;

    /**
      * The Destination Path for a transfer
      */
    QString                             m_destPath;

    /**
      * The Abort Flag, set to true, if user clicked abort
      */
    volatile bool m_abort;
};

#endif // COMMTHREAD_H
