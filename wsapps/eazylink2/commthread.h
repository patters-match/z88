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
#include<QTreeWidgetItem>

#include "z88serialport.h"
#include "z88filespec.h"

class Z88_Selection;
class DeskTop_Selection;
class MainWindow;
class ActionRule;

/**
  * The Communicatons Thread class to allow background I/O with the Z88.
  * Inherits from the QThread Class.
  */
class CommThread : public QThread
{
    Q_OBJECT

public:
    CommThread(Z88SerialPort &port, MainWindow *parent = 0);

    ~CommThread();

    /**
      * The Thread Method
      */
    void run();

protected:
    /**
      * The Opcodes for Each command the CommThread Supports.
      */
    enum comOpcodes_t {
        OP_idle,                // Thread is idle. Must be in this state to start a new command.
        OP_openDevName,         // Open the Specified Serial Port using Hardware Flow Control.
        OP_openDevXonXoff,      // Open the Specified Serial Port with Xon / Xoff Flow control.
        OP_openTestEzProto,     // Open the specified port and send a Hello Msg, wait, then close.
        OP_openTestAscii,       // Open the specified port and the port name, wait, then close.
        OP_reopen,              // Re-init the Serial port, and optionally re-run the last command.
        OP_helloZ88,            // Send a Hello Message to the Z88.
        OP_quitZ88,             // Request the Z88 Should exit the Ez-link pulldown app.
        OP_reloadTransTable,    // Request the Z88 reload its translation table.
        OP_setZ88Clock,         // Set the Z88 real time clock.
        OP_getZ88Clock,         // Read the Z88 real time clock.
        OP_getInfo,             // Read misc z88 device information.
        OP_getDevices,          // Read the Available z88 storage Devices.
        OP_getDirectories,      // Read the Dierectories on the selected device.
        OP_getFilenames,        // Read the File names from the selected device.
        OP_getDevInfo,          // Get the Device Size Info
        OP_getZ88FileTree,      // Read the Entire File tree names from the z88.
        OP_getZ88FileTree_dly,  // Read the Entire File tree after a delay.
        OP_initreceiveFiles,    // Init a new Receive file request from ther Z88.
        OP_receiveFiles,        // Start the Receive file(s) process.
        OP_receiveFile,         // Receive the specified file from the Z88.
        OP_receiveNext,         // Skip the current file, and receive the next one. (user prompt to skip)
        OP_dirLoadDone,         // Recursive Desktop Dir load complete
        OP_initsendFiles,       // Init a New Send  file request to the Z88
        OP_sendFiles,           // Start the Send file(s) Process
        OP_sendFile,            // Start the Specifed file to the Z88
        OP_sendNext,            // Skip the current file, and send the next one. (user prompt to skip)
        OP_createDir,           // Create A directory on the z88.
        OP_initrenameDirFiles,  // Init a New Rename Selections.
        OP_renameDirFiles,      // Start the Rename Files process.
        OP_renameDirFile,       // Rename A directory or file on the Z88
        OP_refreshZ88View,      // Refresh the Z88 device view.
        OP_initdelDirFiles,     // Init a New Delete Selections.
        OP_delDirFiles,         // Start the Delete Dir/Files process.
        OP_delDirFile,          // Delete A Directory of File on the Z88.
        OP_delDirFileNext,      // Skip the current file, and delete next one in selection.
        OP_impExpSendFiles,     // Send Files Over Imp-Export Pull-down Protocol to Z88.
        OP_impExpRecvFiles      // Receive Files Over Imp-Export Pull-down Protocol from Z88.

    };

public:

    /**
      * User Prompt State Flags.
      */
    typedef quint32 uPrompt;

    /**
      * Prompt User for files
      */
    static const uPrompt PROMPT_USER    = 0x1;
    /**
     * Over Write All
     */
    static const uPrompt YES_TO_OW_ALL  = 0x2;

    /**
      * No To over write all
      */
    static const uPrompt NO_TO_OW_ALL   = 0x4;

    /**
      * File Exists Flag
      */
    static const uPrompt FILE_EXISTS    = 0x20;

    /**
      * The Bytes per K In the DevInfo Usage.
      */
    static const quint32 BYTES_PER_K   = 1024;

    /**
     * Api Commands
     */
    void SetupAbortHandler(QProgressDialog *pd);
    void AbortCmd(const QString &msg = "Aborting current process...");
    bool isBusy();
    bool isOpen();
    bool close();
    bool reopen(bool redo_lastcmd);
    bool open(const QString &devname, const QString &short_name);
    bool openXonXoff(const QString &devname, const QString &short_name);
    bool scanForZ88(const QStringList &portList, bool EzLink = false);
    bool helloZ88();
    bool quitZ88();
    bool ReloadTranslation();
    bool setZ88Time();
    bool getZ88Time();
    bool getInfo();
    bool getDevices();
    bool getDirectories(const QString &devname);
    bool getFileNames(const QString &devname);
    bool getZ88FileSystemTree(bool ena_size = false, bool ena_date = false);
    bool receiveFiles(QList<Z88_Selection> *z88Selections, const QString &destpath, bool dest_isDir, uPrompt prompt_usr);
    bool receiveFile(bool skip);
    bool dirLoadComplete();
    bool sendFiles(QList<DeskTop_Selection> *deskSelections, const QString &destpath, uPrompt prompt_usr);
    bool sendFile(bool skip);
    bool RefreshZ88DeviceView(const QString &devname);
    bool mkDir(const QString &dirname);
    bool renameFileDirectories(QList<Z88_Selection> *z88Selections);
    bool renameFileDir(const QString &oldname, const QString &newname);
    bool renameFileDirRety(bool next);
    bool deleteFileDirectories(QList<Z88_Selection> *z88Selections, uPrompt prompt_usr);
    bool deleteFileDirectory(bool next);

    bool impExpSendFile(const QString &Z88_devname, const QStringList &z88Filenames, const QStringList &hostFilenames); // send a file to Z88 using Imp/Export protocol
    bool impExpReceiveFiles(const QString &hostPath);                      // receive Z88 files from Imp/Export popdown


private slots:
    void CancelSignal();
    void impExpRecFilename(const QString &fname);
    void impExpRecFile_Done(const QString &fname);

signals:
    void enableCmds(bool ena, bool com_isOpen);
    void open_result(const QString &dev_name, const QString &short_name, bool success);
    void openTest_Start(int portIdx);
    void openTest_result(int portIdx, bool success);
    void cmdStatus(const QString &msg);
    void cmdProgress(const QString &title, int curVal, int total);
    void boolCmd_result(const QString &cmdName, bool success);
    void displayCritError(const QString &errstr);
    void Z88Info_result(QList<QByteArray> *infolist);
    void Z88Devices_result(QList<QByteArray> *devlist);
    void Z88Dir_result(const QString &devname, QList<QByteArray> *dirlist);
    void Z88FileSpeclist_result(const QString &devname, QList<Z88FileSpec> *filespeclist);
    void PromptReceiveSpec(const QString &src_name, const QString &dst_name, CommThread::uPrompt *Continue);
    void PromptSendSpec(const QString &src_name, const QString &dst_name, CommThread::uPrompt *Continue);
    void DirLoadComplete(const bool &);
    void refreshSelectedZ88DeviceView();
    void PromptRename(QMutableListIterator<Z88_Selection> *item);
    void renameCmd_result(const QString &msg, bool success);
    void renameZ88Item(Z88_Selection *item, const QString &newname);
    void PromptDeleteSpec(const QString &src_name, bool isDir, CommThread::uPrompt *Continue);
    void PromptDeleteRetry(const QString &msg, bool isDir);
    void deleteZ88Item(QTreeWidgetItem *item);
    void Z88DevInfo_result(const QString &devname, unsigned int free, unsigned int total);

protected:
    void startCmd(const comOpcodes_t &op, bool ena_resume = true);
    comOpcodes_t setState_Idle();

    bool shouldPromptUser(const DeskTop_Selection &Source, const QString &destFspec);

    bool shouldPromptUser(const Z88_Selection &Source, const QString &destFspec);

    bool CRLF_TranslationEnable(bool ena);
    bool BYTE_TranslationEnable(bool ena);


    comOpcodes_t _getDirectories(const QString &devname);
    comOpcodes_t _getFileNames(const QString &devname);
    bool _getDevInfo(const QString &devname);

    void merge_relFspec(const QString &fname, const QString &relFspec, QString &result);

    enum devnfo {
        dev_free,
        dev_total,
        nfo_max
    };

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

    /**
      * Prompt user State flags
      */
    uPrompt m_enaPromtUser;

    /**
      * Translation / Conversion flags
      */
    bool m_byteTranslation;
    bool m_linefeedConversion;

    /**
      * The Current File transfer index in the list of files to transfer.
      */
    int m_xferFileprogress;

    /**
      * List of Z88 Files Selected to transfer.
      */
    QList<Z88_Selection>                *m_z88Selections;

    /**
      * List of Z88 Files Selected to transfer.
      */
    QList<Z88_Selection>                *m_z88RenDelSelections;

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
     * The Rename / Delete Item Iterator
     */
    QMutableListIterator<Z88_Selection> *m_z88rendel_itr;

    /**
      * The Destination Path for a transfer
      */
    QString                             m_destPath;

    QStringList                         m_ImpExp_srcList;

    QStringList                         m_ImpExp_dstList;

    QStringList                         m_PortScanList;

    /**
     * Pointer to the Main Window Form
     */
    MainWindow                          *m_mainWindow;

    /**
      * Flag to indicate current desktop transfer destination is
      * A Dir or a file.
      */
    bool                                m_dest_isDir;

    /**
      * Recursive thread Run count
      * Used to disable the Menu
      */
    int                                 m_runCnt;

    /**
      * The Z88 eazyLink Pull-down Version
      */
    QString m_EzSvr_Version;

    /**
      * The Abort Flag, set to true, if user clicked abort
      */
    volatile bool m_abort;
};

#endif // COMMTHREAD_H
