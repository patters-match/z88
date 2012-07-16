/*********************************************************************************************

 EazyLink2 - Fast Client/Server Z88 File Management
 (C) Gunther Strube (gstrube@gmail.com) 2011

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

#include <QDesktopServices>
#include <QUrl>
#include <QStringList>
#include <QInputDialog>
#include <QTreeView>
#include <QStatusBar>
#include <QLabel>
#include <QPushButton>
#include <QtCore/QTime>
#include <QDir>
#include <qdebug.h>

#include "mainwindow.h"
#include "ui_mainwindow.h"
#include "prefrences_dlg.h"

#include "z88serialport.h"
#include "serialportsavail.h"

/**
  * The mainWindow Constructor
  * @param sport is a reference to the Z88 Serial Port Class.
  * @param parent is the Owner of this Widget.
  */
MainWindow::MainWindow(Z88SerialPort &sport, QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow),
    m_prefsDialog(new Prefrences_dlg(this, &m_cthread, this)),
    m_StatusLabel(NULL),
    m_cmdProgress(new QProgressDialog("prog", "Abort", 0, 1, NULL)),
    m_Z88StorageView(NULL),
    m_DeskFileSystem(NULL),
    m_DeskTopTreeView(NULL),
    m_sport(sport),
    m_cthread(sport,this),
    m_cmdSuccessCount(0),
    m_Z88SelectionCount(-1),
    m_DeskSelectionCount(0),
    m_isTransfer(false)
{
    /**
      * Set up the Ui created by the QT Designer.
      */
    ui->setupUi(this);

    /**
      * Initially disable the Abort Button on the Lower Status Bar.
      */
    ui->Ui::MainWindow::CancelCmdBtn->setVisible(false);

    /**
      * Create the Status Bar and add it to the bottom of the main Form.
      */
    QStatusBar *sbar = new QStatusBar(this);
    m_StatusLabel = new QLabel();
    ui->Ui::MainWindow::horizontalLayout_2->addWidget(m_StatusLabel);
    ui->Ui::MainWindow::horizontalLayout_2->addWidget(sbar,0,Qt::AlignRight);

    /**
      * Create the Z88 Storage Device Tab View Object
      */
    m_Z88StorageView = new Z88StorageViewer(m_cthread, m_prefsDialog, this);
    ui->Ui::MainWindow::Z88Layout->addWidget(m_Z88StorageView);

    /**
      * Create and Configure the Desktop View
      */
    setupDeskView();

    /**
      * Connect the Signals To Slots
      */
    createActions();

    QString serialPortname;
    QString port_shortname;

    if(!m_prefsDialog->getSerialPort_Name(serialPortname, port_shortname)){
        m_prefsDialog->Activate(Prefrences_dlg::Comms);
    }

    if(m_prefsDialog->get_PortOpenOnStart() &&
            m_prefsDialog->getSerialPort_Name(serialPortname, port_shortname)){
        m_cthread.open(serialPortname, port_shortname);
    }
}

/**
  * The main window Destructor.
  */
MainWindow::~MainWindow()
{
    /**
      * request abort from the Current Comm Thread operation,
      * And wait for the thread to complete.
      */

    if (m_cthread.isBusy()) {
        m_cthread.AbortCmd();
    } else {
        if(m_prefsDialog->get_ShutdownEZ_OnExit()){
            // send a "quit" to Z88 EazyLink popdown, if Z88 communication exists..
            m_cthread.quitZ88();
        }
    }

    m_cthread.wait();

    delete ui;

    delete m_prefsDialog;
}

/**
  * Is the Tranfer from the Z88 or from the Desktop.
  * @return true is the transfer is from the Z88
  */
bool MainWindow::isTransferFromZ88()
{
    return (ui->Ui::MainWindow::centralWidget->focusWidget()->objectName() == "Z88Tree");
}

void MainWindow::setDesktopDirLabel(const QString &path)
{
    ui->Ui::MainWindow::DeskDir_label->setText(path);
}

void MainWindow::setZ88DirLabel(const QString &path)
{
    ui->Ui::MainWindow::Z88Dir_label->setText(path);
}

/**
  * Refresh the Currently selected Z88 Device View
  */
void MainWindow::refreshSelectedZ88DeviceView()
{
#ifdef Q_OS_WIN32
    QTime timeout = QTime::currentTime().addMSecs(500);
    while(QTime::currentTime() < timeout) {};
#endif
    m_Z88StorageView->refreshSelectedDeviceView();
}

void MainWindow::displayPrefs()
{
    m_prefsDialog->Activate(Prefrences_dlg::Default);
}

/**
  * Z88 Destination Drag And Drop Request
  * @param z88_dest is the detination dir on the Z88. (NOTE Should have 1 entry)
  * @param urlList is a string list of filenames and directories
  */
void MainWindow::Drop_Requested(QList<Z88_Selection> *z88_dest, QList<QUrl> *urlList)
{
    if(!z88_dest || !urlList){
        return;
    }

    cmdStatus("Reading Dropped Files...");

    quint32 sel_bytes = 0;

    /**
      * Get the Selected Destination from the Drop
      */
    m_isTransfer = true;
    QList<DeskTop_Selection> *deskSelList;
    deskSelList = m_DeskTopTreeView->getSelection(urlList, true, sel_bytes);

    m_z88Selections = *z88_dest;

    if(deskSelList){
        DeskTopSelectionChanged(deskSelList->count());
        if(!enaTransferButton(deskSelList)){
            cmdStatus("Invalid Drop Target.");
            return;
        }

        /**
          * Verify the files will fit
          */
        if(Verify_Z88Dest_SpaceAvail(sel_bytes)){
            StartSending(deskSelList, m_z88Selections);
        }
    }
}

/**
 * Create Menu Action and Signal Handlers for the main form
 */
void MainWindow::createActions()
{
    /**
     * The Exit Menu
     */
    connect(ui->Ui::MainWindow::actionExit, SIGNAL(triggered()), this, SLOT(close()));

    /**
     * The Settings->Serial Port Menu
     */
    ui->Ui::MainWindow::actionSerialPort->setStatusTip(tr("Select Serial connected to the Z88"));
    connect(ui->Ui::MainWindow::actionSerialPort, SIGNAL(triggered()), this, SLOT(selSerialPort()));

    ui->Ui::MainWindow::actionQuitEazyLink->setStatusTip(tr("Quit EazyLink Client on Z88"));
    connect(ui->Ui::MainWindow::actionQuitEazyLink, SIGNAL(triggered()), this, SLOT(Z88Quit_EzLink()));

    ui->Ui::MainWindow::actionQuitEazyLink->setStatusTip(tr("Quit EazyLink Client on Z88"));
    connect(ui->Ui::MainWindow::actionTransfer, SIGNAL(triggered()), this, SLOT(TransferFiles()));

    ui->Ui::MainWindow::actionEazyLink_Hello->setStatusTip(tr("Send HelloZ88"));
    connect(ui->Ui::MainWindow::actionEazyLink_Hello, SIGNAL(triggered()), this, SLOT(helloZ88()));

    ui->Ui::MainWindow::actionSend_files_to_Z88ImpExport->setStatusTip(tr("Send files to Z88 using the Imp-Export Pulldown"));
    connect(ui->Ui::MainWindow::actionSend_files_to_Z88ImpExport, SIGNAL(triggered()), this, SLOT(ImpExp_sendfile()));

    ui->Ui::MainWindow::actionReceive_files_from_Z88_Imp_Export_popdown->setStatusTip(tr("Send files to Z88 using the Imp-Export Pulldown"));
    connect(ui->Ui::MainWindow::actionReceive_files_from_Z88_Imp_Export_popdown, SIGNAL(triggered()), this, SLOT(ImpExp_receivefiles()));

    ui->Ui::MainWindow::actionHello->setStatusTip(tr("Send HelloZ88"));
    connect(ui->Ui::MainWindow::actionHello, SIGNAL(triggered()), this, SLOT(helloZ88()));

    connect(ui->Ui::MainWindow::actionReload_TransTable, SIGNAL(triggered()), this, SLOT(ReloadTranslation()));
    connect(ui->Ui::MainWindow::actionSet_Z88_Clock, SIGNAL(triggered()), this, SLOT(SetZ88Clock()));
    connect(ui->Ui::MainWindow::actionReadZ88_Clock, SIGNAL(triggered()), this, SLOT(getZ88Clock()));
    connect(ui->Ui::MainWindow::actionGet_Info, SIGNAL(triggered()), this, SLOT(getZ88Info()));

    ui->Ui::MainWindow::actionZ88Refresh->setStatusTip(tr("Refresh Z88 View"));
    connect(ui->Ui::MainWindow::actionZ88Refresh, SIGNAL(triggered()), this, SLOT(ReloadZ88View()));
    connect(ui->Ui::MainWindow::actionDisplayFileDate, SIGNAL(triggered()), this, SLOT(ReloadZ88View()));
    connect(ui->Ui::MainWindow::actionDisplayFileSize, SIGNAL(triggered()), this, SLOT(ReloadZ88View()));
    connect(ui->Ui::MainWindow::actionAbout, SIGNAL(triggered()), this, SLOT(AboutEazylink()));
    connect(ui->Ui::MainWindow::actionHelpContents, SIGNAL(triggered()), this, SLOT(UrlUserGuide()));

    connect(ui->Ui::MainWindow::CancelCmdBtn, SIGNAL(pressed()), this, SLOT(AbortCmd()));
    connect(ui->Ui::MainWindow::actionPreferences, SIGNAL(triggered()), this, SLOT(displayPrefs()));

    connect(m_Z88StorageView,  SIGNAL(ItemSelectionChanged(int)), this, SLOT(Z88SelectionChanged(int)));
    connect(m_DeskTopTreeView, SIGNAL(ItemSelectionChanged(int)), this, SLOT(DeskTopSelectionChanged(int)));
    connect(m_DeskTopTreeView, SIGNAL(CancelDirRead()), this, SLOT(enableCmds()));


    /**
      * Configure Communication Thread Events
      */
    connect(&m_cthread,
            SIGNAL(open_result(const QString &, const QString &,bool)),
            this,
            SLOT(commOpen_result(const QString&, const QString &, bool)));

    connect(&m_cthread,
            SIGNAL(enableCmds(bool, bool)),
            this,
            SLOT(enableCmds(bool, bool)));

    connect(&m_cthread,
            SIGNAL(cmdStatus(const QString &)),
            this,
            SLOT(cmdStatus(const QString &)));

    connect(&m_cthread,
            SIGNAL(renameCmd_result(const QString &, bool)),
            this,
            SLOT(renameCmd_result(const QString &, bool)));

    connect(&m_cthread,
            SIGNAL(renameZ88Item(Z88_Selection *, const QString &)),
            this,
            SLOT(renameZ88Item(Z88_Selection *, const QString &)));

    connect(&m_cthread,
            SIGNAL(cmdProgress(const QString &, int, int)),
            this,
            SLOT(cmdProgress(const QString &, int, int)));

    connect(&m_cthread,
            SIGNAL(boolCmd_result(const QString &, bool)),
            this,
            SLOT(boolCmd_result(const QString &, bool)));

    connect(&m_cthread,
            SIGNAL(displayCritError(const QString &)),
            this,
            SLOT(displayCritError(const QString &)));

    connect(&m_cthread,
            SIGNAL(Z88Info_result(QList<QByteArray> *)),
            this,
            SLOT(Z88Info_result(QList<QByteArray> *)));

    connect(&m_cthread,
            SIGNAL(PromptReceiveSpec(const QString &, const QString &,CommThread::uPrompt *)),
            this,
            SLOT(PromptReceiveSpec(const QString &, const QString &,CommThread::uPrompt *)));

    connect(&m_cthread,
            SIGNAL(PromptSendSpec(const QString &, const QString &,CommThread::uPrompt *)),
            this,
            SLOT(PromptSendSpec(const QString &, const QString &,CommThread::uPrompt  *)));

    connect(&m_cthread,
            SIGNAL(DirLoadComplete(const bool &)),
            this,
            SLOT(LoadingDeskList(const bool &)));

    connect(&m_cthread,
            SIGNAL(refreshSelectedZ88DeviceView()),
            this,
            SLOT(refreshSelectedZ88DeviceView()));

    connect(&m_cthread,
            SIGNAL(PromptRename(QMutableListIterator<Z88_Selection> *)),
            this,
            SLOT(PromptRename(QMutableListIterator<Z88_Selection> *)));

    connect(&m_cthread,
            SIGNAL(PromptDeleteSpec(const QString &, bool, CommThread::uPrompt *)),
            this,
            SLOT(PromptDeleteSpec(const QString &, bool, CommThread::uPrompt *)));

    connect(&m_cthread,
            SIGNAL(PromptDeleteRetry(const QString &, bool)),
            this,
            SLOT(PromptDeleteRetry(const QString &, bool)));

    connect(&m_cthread,
            SIGNAL(deleteZ88Item(QTreeWidgetItem *)),
            this,
            SLOT(deleteZ88Item(QTreeWidgetItem *)));

    /**
      * Pref panel events
      */
    connect(m_prefsDialog,
            SIGNAL(SerialPortSelChanged()),
            this,
            SLOT(SerialPortSelChanged()));

    connect( m_Z88StorageView,
             SIGNAL(Trigger_Transfer()),
             this,
             SLOT(Trigger_Transfer()));

    connect( m_DeskTopTreeView,
             SIGNAL(Trigger_Transfer()),
             this,
             SLOT(Trigger_Transfer()));

    connect( m_Z88StorageView,
             SIGNAL(Drop_Requested(QList<Z88_Selection>*,QList<QUrl>*)),
             this,
             SLOT(Drop_Requested(QList<Z88_Selection>*,QList<QUrl>*)));
}

/**
  * Create and Setup the Deskview Panel.
  */
void MainWindow::setupDeskView()
{
    m_DeskTopTreeView = new Desktop_View(m_cthread, m_prefsDialog, this);

    m_DeskTopTreeView->setAnimated(true);
    m_DeskTopTreeView->setIndentation(20);
    m_DeskTopTreeView->setSortingEnabled(true);

    m_DeskTopTreeView->setWindowTitle(QObject::tr("Desktop View"));
    m_DeskTopTreeView->setColumnWidth(0,200);

    m_DeskTopTreeView->hideColumn(2); // hide file type
    m_DeskTopTreeView->setSelectionMode(QAbstractItemView::ExtendedSelection);
    m_DeskTopTreeView->sortByColumn(0,Qt::AscendingOrder);
    m_DeskTopTreeView->setObjectName("DeskTopTree");
    ui->Ui::MainWindow::DeskTopLayout->addWidget(m_DeskTopTreeView);
}

/**
 * Display A Critical Error Message and Update the Status Bar.
 * @param title is the Caption to display
 * @param msg is the error message
 * @return true on retry requested or false for cancel
 */
bool MainWindow::DisplayCommError(const QString &title, const QString &msg)
{
    /**
     * Update the Status Text
     */
    m_StatusLabel->setText(msg);

    /**
     * Display Critical Error Dialog Box
     */
    QMessageBox::StandardButton reply;
    reply = QMessageBox::critical(this, title,
                                  msg,
                                  QMessageBox::Retry | QMessageBox::Cancel);

    return (reply == QMessageBox::Retry);
}

/**
 * Menu Bar Handlers.
 */
void MainWindow::selSerialPort()
{

    openSelSerialDialog();
}

void MainWindow::helloZ88()
{
    get_comThread().helloZ88();
}

void MainWindow::ReloadTranslation()
{
    get_comThread().ReloadTranslation();
}

void MainWindow::SetZ88Clock()
{
    get_comThread().setZ88Time();
}

void MainWindow::getZ88Clock()
{
    get_comThread().getZ88Time();
}

void MainWindow::getZ88Info()
{
    get_comThread().getInfo();
}

void MainWindow::ReloadZ88View()
{
    bool ena_filesizes = ui->Ui::MainWindow::actionDisplayFileSize->isChecked();
    bool ena_timeddate = ui->Ui::MainWindow::actionDisplayFileDate->isChecked();

    m_Z88StorageView->getFileTree(ena_filesizes, ena_timeddate);
}

/**
  * The User requested Abort of Command.
  */
void MainWindow::AbortCmd()
{
    m_cthread.AbortCmd();
}

/**
  * Send a file to the Z88 using the Imp-Exp pulldown app protocol.
  */
void MainWindow::ImpExp_sendfile()
{
    QString HelpMsg;
    HelpMsg += "1) Please make sure you have the following Z88 Settings:";
    HelpMsg += " Baud = 9600 and ";
    HelpMsg += " Parity = NONE. -- (Press []S on the Z88 to enter Panel). ";

    m_ImpExp_sendErrMsg.showMessage(HelpMsg, "IMPEXP_Send");

    HelpMsg = "2) On the Z88, Launch the Imp-Export Popdown -- (Press []X)  ";
    m_ImpExp_sendErrMsg.showMessage(HelpMsg, "IMPEXP_Send");

    HelpMsg = "3) On the Z88 Imp-Export Popdown, Select option 'b' and press 'Enter'.";
    m_ImpExp_sendErrMsg.showMessage(HelpMsg, "IMPEXP_Send");

    HelpMsg = "4) On the Desktop, select files to Send to the Z88.";
    m_ImpExp_sendErrMsg.showMessage(HelpMsg, "IMPEXP_Send");

    if(m_ImpExp_sendErrMsg.isVisible()){
        QFont qfont;
        qfont.setStyleHint(QFont::Courier);
        qfont.setBold(true);
        m_ImpExp_sendErrMsg.setFont(qfont);

        m_ImpExp_sendErrMsg.setWindowTitle("Imp-Export Help.");
        m_ImpExp_sendErrMsg.setMinimumSize(500,200);
        m_ImpExp_sendErrMsg.exec();
    }

    QFileDialog dialog(this);
    dialog.setFileMode(QFileDialog::ExistingFiles);

    dialog.setViewMode(QFileDialog::Detail);

    QStringList src_fileNames;

    QList<DeskTop_Selection> *deskSelList;
    deskSelList = m_DeskTopTreeView->getSelection(false);

    QFileInfo qf(deskSelList->first().getFspec());

    if(qf.isDir()){
        dialog.setDirectory(qf.filePath());
    }
    else{
        dialog.setDirectory(qf.dir());
        dialog.selectFile(qf.fileName());
    }

    if(dialog.exec()){
         src_fileNames = dialog.selectedFiles();
         StartImpExpSending(src_fileNames);
    }
}

/**
  * Imp-Export Protocol Receive Files Menu Handler
  */
void MainWindow::ImpExp_receivefiles()
{
    QString HelpMsg;
    HelpMsg += "1) Please make sure you have the following Z88 Settings:";
    HelpMsg += " Baud = 9600 and ";
    HelpMsg += " Parity = NONE. -- (Press []S on the Z88 to enter Panel). ";

    m_ImpExp_recvErrMsg.showMessage(HelpMsg, "IMPEXP_Rx");

    HelpMsg = "2) On the Z88, Launch the Imp-Export Popdown -- (Press []X)  ";
    m_ImpExp_recvErrMsg.showMessage(HelpMsg, "IMPEXP_Rx");

    HelpMsg = "3) On the Desktop, select Subdirectory to receive Z88 Files.";
    m_ImpExp_recvErrMsg.showMessage(HelpMsg, "IMPEXP_Rx");

    HelpMsg = "4) On the Z88 Imp-Export Popdown, Select option 's' and press 'Enter'.";
    HelpMsg += "Then Enter the Filename";
    m_ImpExp_recvErrMsg.showMessage(HelpMsg, "IMPEXP_Rx");

    if(m_ImpExp_recvErrMsg.isVisible()){
        QFont qfont;
        qfont.setStyleHint(QFont::Courier);
        qfont.setBold(true);
        m_ImpExp_recvErrMsg.setFont(qfont);

        m_ImpExp_recvErrMsg.setWindowTitle("Imp-Export Help.");
        m_ImpExp_recvErrMsg.setMinimumSize(500,200);
        m_ImpExp_recvErrMsg.exec();
    }

    QFileDialog dialog(this);
    dialog.setFileMode(QFileDialog::Directory);
    dialog.setViewMode(QFileDialog::List);

    QStringList src_fileNames;

    QList<DeskTop_Selection> *deskSelList;
    deskSelList = m_DeskTopTreeView->getSelection(false);

    QFileInfo qf(deskSelList->first().getFspec());

    if(qf.isDir()){
        dialog.setDirectory(qf.filePath());
    }
    else{
        dialog.setDirectory(qf.dir());
    }

    if(dialog.exec()){
         src_fileNames = dialog.selectedFiles();
         StartImpExpReceive(src_fileNames.first());
    }
}

void MainWindow::UrlUserGuide()
{
    QDesktopServices::openUrl(QUrl("https://cambridgez88.jira.com/wiki/x/noCD", QUrl::TolerantMode));
}

void MainWindow::AboutEazylink()
{
    QString msg("EazyLink2");
    msg += " - " + QCoreApplication::applicationVersion();
    msg += "\r\nApril-June 2012";
    msg += "\r\n(C) Gunther Strube & Oscar Ernohazy";

    QMessageBox::about(this, tr("EazyLink II"), msg);
}

/**
  * Request that the Z88 terminates the EzLink PopDown App.
  */
void MainWindow::Z88Quit_EzLink(){
    get_comThread().quitZ88();
}

/**
  * Enable / Dis-able the User interface Items, based on Communications status.
  * @param ena set to true to enable buttons, etc.
  * @param com_isOpen set to true if the serial port is open.
  */
void MainWindow::enableCmds(bool ena, bool com_isOpen)
{
    /**
      * Enable the Abort button While a command is running
      */
    ui->Ui::MainWindow::CancelCmdBtn->setVisible(!ena);

    /**
      * Enable / Disable menu bar items
      */
    ui->Ui::MainWindow::menuSettings->setEnabled(ena);
    ui->Ui::MainWindow::menuFile->setEnabled(ena);
    ui->Ui::MainWindow::actionSerialPort->setEnabled(ena);

    /**
      * Disable Z88 Menu and Command tool bar if comm port is not open
      */
    if(!com_isOpen){
        ena = false;
    }

    ui->Ui::MainWindow::menuZ88->setEnabled(ena);
    ui->Ui::MainWindow::toolBar->setEnabled(ena);
    ui->Ui::MainWindow::actionReload_TransTable->setEnabled(ena);
    ui->Ui::MainWindow::actionQuitEazyLink->setEnabled(ena);
    ui->Ui::MainWindow::actionEazyLink_Hello->setEnabled(ena);
    ui->Ui::MainWindow::actionReceive_files_from_Z88_Imp_Export_popdown->setEnabled(ena);
    ui->Ui::MainWindow::actionSend_files_to_Z88ImpExport->setEnabled(ena);
    ui->Ui::MainWindow::actionSet_Z88_Clock->setEnabled(ena);
    ui->Ui::MainWindow::actionReadZ88_Clock->setEnabled(ena);
    ui->Ui::MainWindow::actionGet_Info->setEnabled(ena);
}

void MainWindow::enableCmds()
{
    enableCmds(true, m_sport.isOpen());
}

/**
  * Create and Display a user Dialog prompting for the Serial port device to use.
  * @return true on success.
  */
bool MainWindow::openSelSerialDialog()
{
    m_prefsDialog->Activate(Prefrences_dlg::Comms);
#if 0
    SerialPortsAvail SportsAvail;
    bool ok;

    m_StatusLabel->clear();

    QString item = QInputDialog::getItem(this, "Open Serial Port",
                                          tr("Select Z88 Port:"), SportsAvail.get_portList(), 0, false, &ok);
    if (ok && !item.isEmpty()){

        /**
          * Try to opend the Serial Device Specified
          */
        ok = m_cthread.open(SportsAvail.get_fullportName(item), item);
    }
#endif
    return true;
}


/**
  * The Open Cummunications port result call-back event handler.
  * @param dev_name is the full Path and name of the Serial device opened.
  * @param short_name is the User alias to the Comm device, ie tty.keyspan1 etc.
  * @param success is the Result code from the Open request, true on success.
  */
void MainWindow::commOpen_result(const QString &, const QString &short_name, bool success)
{
    if(success){
        /**
         * Update the Status Text
         */
        QString msg;
        msg = "Connected on port ";
        msg += short_name;

        m_StatusLabel->setText(msg);

        if(m_prefsDialog->get_RefreshZ88OnStart()){
            ReloadZ88View();
        }
    }
    else{
        QString msg;
        msg =  "Failed to Open port: " + short_name;
        msg += ". Reason: (";
        msg += get_serialDev().getOpenErrorString();
        msg += ")";

        /**
          * Display an error, and allow user to re-select port
          * or Cancel
          */
        if(DisplayCommError("Comms Open Error", msg)){
            openSelSerialDialog();
       }
    }
}

/**
  * Update Command status bar.
  * @param msg is the Message to Display on the Status Bar.
  */
void MainWindow::cmdStatus(const QString &msg)
{
    /**
     * Update the Status Text
     */
    m_StatusLabel->setText(msg);
}

/**
  * The Generic command, pop-up Status / progress Dialog.
  * @param title is the Message to display describing the progress action.
  * @param curVal is the Current progress staus value, the dialog is created when curVal = 0.
  * @param total is the completed status value. The dialog disapears when curVal = total.
  */
void MainWindow::cmdProgress(const QString &title, int curVal, int total)
{
    if(total < 0){
        if(m_cmdProgress) m_cmdProgress->reset();
        /* re-sort (hack)*/
        // m_DeskTopTreeView->sortByColumn(1,Qt::AscendingOrder);
        // m_DeskTopTreeView->sortByColumn(0,Qt::AscendingOrder);
        return;
    }

    if(total){
        if(curVal == 0){
            delete m_cmdProgress;
            m_cmdProgress = new QProgressDialog(title, "Abort", 0, total+1, NULL);
            m_cmdProgress->show();

            /**
              * Setup the Comm thread Abort Signal handler
              */
            m_cthread.SetupAbortHandler(m_cmdProgress);
            m_cmdProgress->setWindowModality(Qt::WindowModal);
        }
        else{
            m_cmdProgress->setLabelText(title);
        }
        m_cmdProgress->setValue(curVal+1);
    }
}

/**
  * General Boolean Command Result handler.
  * @param cmdName is the description of the command that completed.
  * @param success is the Result value, True on success.
  */
void MainWindow::boolCmd_result(const QString &cmdName, bool success)
{
    /**
     * Update the Status Text
     */
    QString msg;
    msg = cmdName;
    msg += " Command ";
    msg += success ? "Succeeded." : "Failed!";

    m_StatusLabel->setText(msg);

    if(!success){
        msg += "\r\n";
        if(!m_cmdSuccessCount){
            msg += "Please check the serial connection, and make sure EasyLink is running on the Z88.\r\n";
        }
        msg += "Click \'retry\' to reset comm-link & try again.";

        QMessageBox::StandardButton reply;

        reply = QMessageBox::critical(this, tr("Command Error"),
                                       msg,
                                       QMessageBox::Abort | QMessageBox::Retry | QMessageBox::Ignore);

        switch(reply){
        case QMessageBox::Abort:
            m_cthread.close();
            break;
        case QMessageBox::Retry:
            m_cthread.reopen(true);
            break;
        case QMessageBox::Ignore:
            break;
        default:
            break;
        }
        m_cmdSuccessCount = 0;
    }
    else{
        m_cmdSuccessCount++;
    }
}

void MainWindow::displayCritError(const QString &errmsg)
{
    QMessageBox::critical(this, tr("Command Error"),
                                           errmsg,
                                           QMessageBox::Ok);
}

/**
  * Z88 Info Result Handler
  * @param infolist is the Result list of information from the Z88.
  */
void MainWindow::Z88Info_result(QList<QByteArray> *infolist)
{
    QString msg;

    int cnt = infolist->count();
    int idx = 0;

    if(idx < cnt){
        msg += "Z88 EazyLink Ver \t| ";
        msg += (*infolist)[idx];
        msg += "\r";
        idx++;
    }
    if(idx < cnt){
        msg += "Z88 Free Ram \t| ";
        msg += (*infolist)[idx];
        msg += "\r";
        idx++;
    }
    if(idx < cnt){
        QString csr;
        csr.setNum(cnt - idx);
        msg += "Avail Storage Devices\t| ";
        msg += csr;
        msg += "\r";
    }
    while(idx < cnt){
        msg += "Storage Device \t| ";
        msg += (*infolist)[idx];
        msg += "\r";
        idx++;
    }

    QMessageBox::information(this, "Z88 Info",
                                     msg,
                                     QMessageBox::Ok );
}

/**
  * The Z88 File Selections have Channged, Handler.
  * This routine Enables or disables the Transfer button based on the selected Files
  * on the Z88 and the desktop View.
  * @param count is the number of items selected on the Z88 View.
  */
void MainWindow::Z88SelectionChanged(int count)
{
    m_Z88SelectionCount = count;
    enaTransferButton();
}

/**
  * The DeskTop Selections have Channged Handler.
  * This routine Enables or disables the Transfer button based on the selected Files
  * on the Z88 and the desktop View.
  * @param count is the number of items selected on the Desk View.
  */
void MainWindow::DeskTopSelectionChanged(int count)
{
    m_DeskSelectionCount = count;
    enaTransferButton();
}

/**
  * Prompt the User to confirm filename receive.
  * @param src_name is the Source file name
  * @par dst_name is the destination filename.
  * @param prompt_again set this to false to stop prompting for the remaining files.
  */
void MainWindow::PromptReceiveSpec(const QString &src_name, const QString &dst_name, CommThread::uPrompt *prompt_again)
{
    QMessageBox msgBox;
    QString msg = "Copy ";
    msg += src_name;
    msg += " to ";
    msg += dst_name;

    msgBox.setText(msg);
    msgBox.setIcon(QMessageBox::Question);
    msgBox.setInformativeText("Transfer this file from Z88 to Desktop ?");
    msgBox.setStandardButtons(QMessageBox::Yes | QMessageBox::No |
                              QMessageBox::YesToAll | QMessageBox::Cancel);
    msgBox.setDefaultButton(QMessageBox::YesToAll);

    bool prompt_for_ow = (*prompt_again & CommThread::FILE_EXISTS) && !(*prompt_again & (CommThread::NO_TO_OW_ALL | CommThread::YES_TO_OW_ALL));

    if((*prompt_again & CommThread::PROMPT_USER)){
        switch(msgBox.exec()){
            case QMessageBox::YesToAll:
                *prompt_again &= ~(CommThread::PROMPT_USER);
                // drop through
            case QMessageBox::Yes:
                if(!prompt_for_ow){
                    m_cthread.receiveFile(false);
                }
                break;
            case  QMessageBox::No:
                m_cthread.receiveFile(true);
                return;
                break;
            case QMessageBox::Cancel:
                if(m_cmdProgress) m_cmdProgress->reset();
                return;
        }
    }

    /**
      * Prompt User For Over-Write Options
      */
    if(prompt_for_ow) {

        msg = "File Already Exists.\n";
        msg += dst_name;

        msgBox.setText(msg);
        msgBox.setInformativeText("Do you want to replace the file on the Desktop ?");
        msgBox.setStandardButtons(QMessageBox::Yes | QMessageBox::No |
                                  QMessageBox::YesToAll | QMessageBox::NoToAll | QMessageBox::Cancel);
        msgBox.setDefaultButton(QMessageBox::NoToAll);
        msgBox.setIcon(QMessageBox::Warning);

        switch(msgBox.exec()){
            case QMessageBox::YesToAll:
                *prompt_again |= (CommThread::YES_TO_OW_ALL);
                m_cthread.receiveFile(false);
                break;
            case QMessageBox::Yes:
                m_cthread.receiveFile(false);
                break;
            case QMessageBox::NoToAll:
                *prompt_again |= (CommThread::NO_TO_OW_ALL);
                m_cthread.receiveFile(true);
                break;
            case  QMessageBox::No:
                m_cthread.receiveFile(true);
                break;
            case QMessageBox::Cancel:
                if(m_cmdProgress) m_cmdProgress->reset();
                return;
        }
    }
}

void MainWindow::PromptSendSpec(const QString &src_name, const QString &dst_name, CommThread::uPrompt *prompt_again)
{
    QMessageBox msgBox;
    QString msg = "Copy ";
    msg += src_name;
    msg += " to ";
    msg += dst_name;

    msgBox.setText(msg);
    msgBox.setIcon(QMessageBox::Question);
    msgBox.setInformativeText("Transfer this file from Desktop to Z88 ?");
    msgBox.setStandardButtons(QMessageBox::Yes | QMessageBox::No |
                              QMessageBox::YesToAll | QMessageBox::Cancel);
    msgBox.setDefaultButton(QMessageBox::YesToAll);

    bool prompt_for_ow = (*prompt_again & CommThread::FILE_EXISTS) && !(*prompt_again & (CommThread::NO_TO_OW_ALL | CommThread::YES_TO_OW_ALL));

    /**
      * Prompt user for a File to the Z88
      */
    if((*prompt_again & CommThread::PROMPT_USER)){
        switch(msgBox.exec()){
            case QMessageBox::YesToAll:
                *prompt_again &= ~(CommThread::PROMPT_USER);
                // drop through
            case QMessageBox::Yes:
                if(!prompt_for_ow){
                    m_cthread.sendFile(false);
                }
                break;
            case  QMessageBox::No:
                m_cthread.sendFile(true);
                return;
                break;
            case QMessageBox::Cancel:
                if(m_cmdProgress) m_cmdProgress->reset();
                refreshSelectedZ88DeviceView();
                return;
        }
    }

    /**
      * Prompt User For Over-Write Options
      */
    if(prompt_for_ow) {

        msg = "File Already Exists.\n";
        msg += dst_name;

        msgBox.setText(msg);
        msgBox.setInformativeText("Do you want to replace the file on the Z88 ?");
        msgBox.setStandardButtons(QMessageBox::Yes | QMessageBox::No |
                                  QMessageBox::YesToAll | QMessageBox::NoToAll | QMessageBox::Cancel);
        msgBox.setDefaultButton(QMessageBox::NoToAll);
        msgBox.setIcon(QMessageBox::Warning);


        switch(msgBox.exec()){
            case QMessageBox::YesToAll:
                *prompt_again |= (CommThread::YES_TO_OW_ALL);
                m_cthread.sendFile(false);
                break;
            case QMessageBox::Yes:
                m_cthread.sendFile(false);
                break;
            case QMessageBox::NoToAll:
                *prompt_again |= (CommThread::NO_TO_OW_ALL);
                m_cthread.sendFile(true);
                break;
            case  QMessageBox::No:
                m_cthread.sendFile(true);
                break;
            case QMessageBox::Cancel:
                if(m_cmdProgress) m_cmdProgress->reset();
                refreshSelectedZ88DeviceView();
                return;
        }
    }
}

void MainWindow::PromptRename(QMutableListIterator<Z88_Selection> *i)
{
    if(i->hasNext()){
        bool ok;
        Z88_Selection z88sel(i->peekNext());

        const QString &ftype((z88sel.getType() == Z88_DevView::type_Dir) ?
                    "Rename Dir" : "Rename File");

        QString srcname(z88sel.getRelFspec());
        QString srcfspec(z88sel.getFspec());

        if(srcfspec.size() <=6){
            return;
        }

        if(z88sel.getType() == Z88_DevView::type_Dir){
            srcfspec = srcfspec.mid(0,srcfspec.size()-1);
        }

        bool name_ok(false);
        QString newname;

        while(!name_ok){
            newname = QInputDialog::getText(this,
                                            ftype,
                                            srcfspec,
                                            QLineEdit::Normal,
                                            srcname,
                                            &ok);

            if(ok){
                if(!newname.isEmpty() && newname != srcname){
                    if(!m_Z88StorageView->isValidFilename(newname, srcname)){
                        int ret = QMessageBox::critical(this, tr("Eazylink2"),
                                                               "Invalid Filename:\n" + newname,
                                                               QMessageBox::Abort | QMessageBox::Retry);
                        if(ret == QMessageBox::Abort){
                            return;
                        }
                        continue;
                    }
                }
                else{
                    newname = "";  // Same as current name
                }
                name_ok = true;
            }
            else{
                //refreshSelectedZ88DeviceView();
                return;
            }
        }

        m_cthread.renameFileDir(srcfspec, newname);
    }
}

void MainWindow::PromptDeleteSpec(const QString &src_name, bool isDir, CommThread::uPrompt *prompt_again)
{
    QMessageBox msgBox;
    QString msg = "Delete ";
    if(isDir){
        msg += "Directory:\n";
    }
    else{
        msg += "File:\n";
    }
    msg += src_name;

    msgBox.setText(msg);
    msgBox.setIcon(QMessageBox::Question);
    msgBox.setInformativeText("Permanently erase this from the Z88 ?");
    msgBox.setStandardButtons(QMessageBox::Yes | QMessageBox::No |
                              QMessageBox::YesToAll | QMessageBox::Cancel);
    msgBox.setDefaultButton(QMessageBox::No);

    switch(msgBox.exec()){
        case QMessageBox::YesToAll:          
            *prompt_again &= ~(CommThread::PROMPT_USER);
            // drop through
        case QMessageBox::Yes:
            m_cthread.deleteFileDirectory(false);
            break;
        case  QMessageBox::No:
            m_cthread.deleteFileDirectory(true);
            break;
        case QMessageBox::Cancel:
            if(m_cmdProgress) m_cmdProgress->reset();
            return;
    }
}

/**
  * Prompt user to retry A Failed Delete.
  * @param  filename is the name of the fialed delete file or dir.
  */
void MainWindow::PromptDeleteRetry(const QString &fspec, bool isDir)
{
    QMessageBox msgBox;

    QString msg("Could Not Delete ");
    QString etext("Make sure ");

    if(isDir){
        msg += "Directory:\n";
        etext += "its empty, and not in use.";
    }
    else{
        msg += "File:\n";
        etext += "its not in use.";
    }

    etext += "\nDo you want to Retry Delete?";
    msg += fspec;

    msgBox.setIcon(QMessageBox::Critical);
    msgBox.setText(msg);
    msgBox.setInformativeText(etext);
    msgBox.setStandardButtons(QMessageBox::Ignore | QMessageBox::Retry |
                               QMessageBox::Cancel);
    msgBox.setDefaultButton(QMessageBox::Ignore);

    switch(msgBox.exec()){

        case QMessageBox::Retry:
            m_cthread.deleteFileDirectory(false);
            break;
        case  QMessageBox::Ignore:
            m_cthread.deleteFileDirectory(true);
            break;
        case QMessageBox::Cancel:
            if(m_cmdProgress) m_cmdProgress->reset();
           // refreshSelectedZ88DeviceView();
            return;
    }
}

void MainWindow::renameCmd_result(const QString &msg, bool success)
{
    /**
     * Update the Status Text
     */
    m_StatusLabel->setText(msg);

    if(!success){
        QMessageBox::StandardButton reply;
        reply = QMessageBox::critical(this, tr("Eazylink2"),
                                       msg,
                                       QMessageBox::Abort | QMessageBox::Retry | QMessageBox::Ignore);
        switch(reply){
        case QMessageBox::Abort:
            break;
        case QMessageBox::Retry:
            m_cthread.renameFileDirRety(false);
            break;
        case QMessageBox::Ignore:
            m_cthread.renameFileDirRety(true);
            break;
        default:
            break;
        }
    }
}

/**
  * Rename of a File or directory Entry in the Z88 Display.
  * @param item is the QTreeItem to rename
  * @param newname is the new name to create.
  */
void MainWindow::renameZ88Item(Z88_Selection *item, const QString &newname)
{
    QString msg("Rename ");
    msg += (item->getType() == Z88_DevView::type_Dir) ? "Directory: " : "File: ";
    msg += item->getQtreeItem()->text(0);
    msg += " -> ";
    msg += newname;
    msg += " Success";

    item->getQtreeItem()->setText(0, newname);

    m_StatusLabel->setText(msg);
}

void MainWindow::deleteZ88Item(QTreeWidgetItem *item)
{
    QString msg("Delete ");
    msg += item->text(0);
    msg += " Success.";

    delete item;
    m_StatusLabel->setText(msg);

}

void MainWindow::SerialPortSelChanged()
{
    QString serialPortname;
    QString port_shortname;

    if(m_prefsDialog->getSerialPort_Name(serialPortname, port_shortname)){
        m_cthread.open(serialPortname, port_shortname);
    }
}

void MainWindow::Trigger_Transfer()
{
    if(enaTransferButton()){
        if(!m_cthread.isBusy()) {
            TransferFiles();
        }
    }
    else{
        cmdStatus("Invalid Drop Target.");
    }
}

/**
  * Validate and enable the Transfer button, based on the selected items in
  * both the z88 and Desktop frames.
  * @return true if the transfer button can be enabled.
  */
bool MainWindow::enaTransferButton()
{
    return enaTransferButton(m_DeskTopTreeView->getSelection(false));
}

bool MainWindow::enaTransferButton(QList<DeskTop_Selection> *dl)
{
    QList<DeskTop_Selection> DeskSelList;

    if(!dl){
        return false;
    }
    DeskSelList = *dl;

    QList<Z88_Selection> *z88SelList(m_Z88StorageView->getSelection(false));

    /**
      * Z88 is source
      */
    if(isTransferFromZ88()){
        if(!z88SelList || m_Z88SelectionCount <= 0 || m_DeskSelectionCount > 1){
            ui->Ui::MainWindow::actionTransfer->setEnabled(false);
            return false;
        }

        if((m_Z88SelectionCount > 1 || (*z88SelList)[0].getType() == Z88_DevView::type_Dir)
                && DeskSelList[0].getType() != DeskTop_Selection::type_Dir)
        {
            ui->Ui::MainWindow::actionTransfer->setEnabled(false);
            return false;
        }

        /**
          * Don't allow a copy of a blank Z88 Storage device
          */
        if(m_Z88SelectionCount == 1 && m_Z88StorageView->SelectedDevice_isEmpty()){
            ui->Ui::MainWindow::actionTransfer->setEnabled(false);
            return false;
        }

        ui->Ui::MainWindow::actionTransfer->setEnabled(true);
        ui->Ui::MainWindow::actionTransfer->setText("Transfer Z88 -> Desk");
    }
    else{
        /**
          * Desktop is Source
          */
        if(!m_DeskSelectionCount || m_Z88SelectionCount < 0 || m_Z88SelectionCount > 1){
            ui->Ui::MainWindow::actionTransfer->setEnabled(false);
            return false;
        }

        if(!z88SelList || ((m_DeskSelectionCount > 1 ||
                            DeskSelList[0].getType() == DeskTop_Selection::type_Dir)
                           && (*z88SelList)[0].getType() != Z88_DevView::type_Dir))
        {
            ui->Ui::MainWindow::actionTransfer->setEnabled(false);
            return false;
        }
        ui->Ui::MainWindow::actionTransfer->setEnabled(true);
        ui->Ui::MainWindow::actionTransfer->setText("Transfer Z88 <- Desk");
    }
    return true;
}


/**
  * Transfer Files Tool-bar command
  * Starts the file transfer process.
  */
void MainWindow::TransferFiles()
{
    /**
      * Read the User Selections from the Z88
      */
    QList<Z88_Selection> *z88selections;

    /**
      * Source is Z88, Destination Desktop
     */
    if(isTransferFromZ88()) {
        z88selections = m_Z88StorageView->getSelection(true);

        if(!z88selections){
            return;
        }

        m_z88Selections = *z88selections;

        /**
          * Get the Selected Destination from the Desktop Frame
          */
        QList<DeskTop_Selection> *deskSelList;
        deskSelList = m_DeskTopTreeView->getSelection(false);

        if(deskSelList){
            StartReceiving(m_z88Selections, *deskSelList);
        }
    }
    else{
        /**
          * Source is Desktop, Destination is Z88
          */
        z88selections = m_Z88StorageView->getSelection(false);

        if(!z88selections){
            return;
        }

        m_z88Selections = *z88selections;

        cmdStatus("Reading Source Files...");

        /**
          * Get the Selected Source File(s) from the Desktop
          */
        m_isTransfer = true;
        QList<DeskTop_Selection> *deskSelList;
        quint32 src_bytes = 0;
        deskSelList = m_DeskTopTreeView->getSelection(true, src_bytes);

        if(deskSelList){
            /**
              * Verify the files will fit HERE
              */
            if(Verify_Z88Dest_SpaceAvail(src_bytes)){
                StartSending(deskSelList, m_z88Selections);
            }
        }
    }
}

/**
  * Recursive Desktop Disk read of a directory finished.
  * @param aborted on call, set to true, if user has selected abort.
  */
void MainWindow::LoadingDeskList(const bool &aborted)
{
    if(aborted){
        m_DeskTopTreeView->DirLoadAborted();
        return;
    }

    quint32 sel_bytes = 0;

    QList<DeskTop_Selection> *deskSelList;
    deskSelList = m_DeskTopTreeView->getSelection(true, sel_bytes,  true);

    if(deskSelList){

        /**
          * If the reason for dirlist is a transfer vs a delete
          */
        if(m_isTransfer){
            m_isTransfer = false;

            enableCmds(true, m_sport.isOpen());

            DeskTopSelectionChanged(deskSelList->count());
            if(!enaTransferButton(deskSelList)){
                cmdStatus("Invalid Drop Target.");
                return;
            }

            /**
              * Verify the files will fit HERE
              */          
            if(Verify_Z88Dest_SpaceAvail(sel_bytes)){
                StartSending(deskSelList, m_z88Selections);
            }
        }
        else{
            m_DeskTopTreeView->deleteSelections();
        }
    }
}

/**
  * Removes the Filename form a fully qualified path string.
  * @param fspec is the filename + path to strip.
  */
static QString stripFname(const QString &fspec){
    int idx = fspec.lastIndexOf('/');
    if(idx > -1){
        return fspec.mid(0,idx);
    }
    return fspec;
}

/**
  * Test to see if a newname is a duplicate of a filename in the same directory,
  * @param selections is the list of selected files.
  * @param desk_sel is the File Selection that is being tested.
  * @param newname is the new name to check.
  * @return true if its a dupe. False if the newname is OK.
  */
static bool findDupes(const QList<DeskTop_Selection> &selections, DeskTop_Selection & desk_sel, const QString &newname){
    QListIterator<DeskTop_Selection> i(selections);

    while(i.hasNext()){
        const DeskTop_Selection &dsel(i.next());
        if(dsel.getFname() == newname && stripFname( dsel.getFspec()) == stripFname( desk_sel.getFspec())){
            return true;
        }
    }
    return false;
}

/**
  * Start the sending files from the Desktop to the Z88.
  * @param desk_selections is the list of files to transfer to the Z88.
  * @param z88_selections is the the destination Dir or Device on the Z88. NOTE: should only contain 1 entry.
  */
void MainWindow::StartSending(QList<DeskTop_Selection> *desk_selections, QList<Z88_Selection> &z88_selections)
{
    CommThread::uPrompt prompt4each = 0;

    QList<DeskTop_Selection> *ds = desk_selections;

    /**
      * Count the Number of Files to Send, ignore Directories,
      * Validate the file names.
      */
    int filecnt = 0;
    if(!ds->isEmpty()){

        QMutableListIterator<DeskTop_Selection> i(*ds);

        while(i.hasNext()){
            QString alt_name;
            DeskTop_Selection &dsel(i.next());
            bool name_inv = true;

            while(name_inv){
                if(!m_Z88StorageView->isValidFilename(dsel.getFname(), alt_name)){

                    bool ok;
                    QString newname;

                    newname = QInputDialog::getText(this,
                                                    "Source Filename Error:",
                                                    dsel.getFspec() + " is Invalid.\n" +
                                                    "\nPlease create a new name.",
                                                    QLineEdit::Normal,
                                                    alt_name,
                                                    &ok);

                    if(!ok || newname.isEmpty()){
                        return;
                    }

                    /**
                      * Name sure new filename isn't already being transfered.
                      */
                    if(findDupes(*ds, dsel, newname)){
                        QMessageBox::critical(this,
                                              tr("Duplicate Name:"),
                                              newname + " is already in the List."+
                                              "\nPlease create a unique name.",
                                              QMessageBox::Ok);
                        continue;
                    }
                    /**
                      * Rename the destination filename to the corrected one.
                      */
                    dsel.setFname(newname);
                }
                else{
                    name_inv = false;
                }
            }

            if(dsel.getType() == DeskTop_Selection::type_File){
                filecnt++;
            }
        }
    }
    else{
        return;
    }

    /**
      * Prompt user about Number of files and Dirs to transfer
      */
    QMessageBox msgBox;
    QString msg = "Transfer ";
    int dir_cnt(ds->count() - filecnt);

    if(filecnt){
        msg += QString("%1").arg(filecnt);
        msg += " file";
        if(filecnt > 1){
            msg += 's';
        }

        if(dir_cnt){
            msg += " and ";
        }
    }

    if(dir_cnt == 1){
        if(filecnt == 0){
            msg += "Empty ";
        }
        msg += QString("Directory ");
        msg +=  ds->first().getFname();
    }
    else{
        if(dir_cnt){
            msg += QString("%1").arg(dir_cnt);
            if(filecnt == 0){
                msg += " Empty";
            }
            msg += " Directories";
        }
        else{
            /**
              * If there is only one file, then display the filename
              */
            if(filecnt == 1){
                msg = "Transfer ";
                msg +=  ds->first().getFname();
            }
        }
    }

    msg += " to the Z88 ->";
    msg += z88_selections.first().getFspec();

    msgBox.setText(msg);
    msgBox.setIcon(QMessageBox::Question);
    if(filecnt > 1){
        msgBox.setInformativeText("Prompt for each file?");
        msgBox.setStandardButtons(QMessageBox::Yes | QMessageBox::No | QMessageBox::Cancel);
    }
    else{
        msgBox.setStandardButtons(QMessageBox::Ok | QMessageBox::Cancel);
    }
    msgBox.setDefaultButton(QMessageBox::Yes);

    switch(msgBox.exec()){
        case QMessageBox::Yes:
            prompt4each = CommThread::PROMPT_USER;
            break;
        case  QMessageBox::No:
            break;
        case QMessageBox::Cancel:
            cmdStatus("Transfer Cancelled.");
            return;
    }

    m_DeskTopTreeView->prependSubdirNames(*ds);

    m_cthread.sendFiles(ds, z88_selections[0].getFspec(), prompt4each);
}

void MainWindow::StartReceiving(QList<Z88_Selection> &z88_selections, QList<DeskTop_Selection> &deskSelList)
{
    CommThread::uPrompt prompt4each = 0;

    /**
      * Count the Number of Files to Receive, ignore Directories
      */
    int filecnt = 0;
    if(!z88_selections.isEmpty()){
        QListIterator<Z88_Selection> i(z88_selections);
        while(i.hasNext()){
            if(i.next().getType() == Z88_DevView::type_File){
                filecnt++;
            }
        }
    }
    else{
        return;
    }

    QMessageBox msgBox;
    QString msg = "Transfer ";

    int dir_cnt(z88_selections.count() - filecnt);

    if(filecnt){
        msg += QString("%1").arg(filecnt);
        msg += " file";
        if(filecnt > 1){
            msg += 's';
        }
        if(dir_cnt){
            msg += " and ";
        }
    }

    if(dir_cnt == 1){
        if(filecnt == 0){
            msg += "Empty ";
        }
        msg += QString("Directory ");
        msg +=  z88_selections.first().getFspec();
    }
    else{
        if(dir_cnt){
            msg += QString("%1").arg(dir_cnt);
            if(filecnt == 0){
                msg += " Empty";
            }
            msg += " Directories";
        }
    }
    msg += " from the Z88 -> ";

    msg += deskSelList.first().getFspec();

    msgBox.setText(msg);
    msgBox.setIcon(QMessageBox::Question);
    if(filecnt > 1){
        msgBox.setInformativeText("Prompt for each file?");
        msgBox.setStandardButtons(QMessageBox::Yes | QMessageBox::No | QMessageBox::Cancel);
    }
    else{
        msgBox.setStandardButtons(QMessageBox::Ok | QMessageBox::Cancel);
    }
    msgBox.setDefaultButton(QMessageBox::Yes);

    switch(msgBox.exec()){
        case QMessageBox::Yes:
            prompt4each = CommThread::PROMPT_USER;
            break;
        case  QMessageBox::No:
            break;
        case QMessageBox::Cancel:
            return;
    }

    /**
      * Create the Local Directory Structure for the files to be received
      */
    m_DeskTopTreeView->mkDirectoryTree(z88_selections);

    QMutableListIterator<Z88_Selection> i(z88_selections);

    /**
      * Remove all the Directory Entries
      */
    while(i.hasNext()){
        if(i.next().getType()==Z88_DevView::type_Dir){
            i.remove();
        }
    }
    bool dest_isDir = (deskSelList[0].getType() == DeskTop_Selection::type_Dir);
    m_cthread.receiveFiles(&z88_selections, deskSelList[0].getFspec(), dest_isDir, prompt4each);
}

void MainWindow::StartImpExpSending(const QStringList &src_fileNames)
{
    if(src_fileNames.isEmpty()){
        return;
    }

    QStringList dst_filenames;
    QListIterator<QString> i(src_fileNames);

    while(i.hasNext()){
        /**
          * Strip the Leading Path
          */
        QString fname(i.peekNext());
        int idx = fname.lastIndexOf(QDir::separator());

        if(idx >= 0){
            fname = fname.mid(idx+1);
        }

        /**
          * Validate the Filenames
          */
        QString sug;
        bool inv_name = true;

        while(inv_name){
            if(m_Z88StorageView->isValidFilename(fname, sug)){
                inv_name = false;
                dst_filenames.append(fname);
            }
            else{
                bool ok;
                QString newname;

                newname = QInputDialog::getText(this,
                                                "Source Filename Error:",
                                                fname + " is Invalid.\n" +
                                                "\nPlease create a new name.",
                                                QLineEdit::Normal,
                                                sug,
                                                &ok);

                if(!ok || newname.isEmpty()){
                    return;
                }
                fname = newname;
            }
        }
        i.next();
    }

    QStringList Z88Slots;

    Z88Slots.append("0");
    Z88Slots.append("1");
    Z88Slots.append("2");
    Z88Slots.append("3");

    bool ok;
    QString item = QInputDialog::getItem(this, "Eazylink2",
                                          tr("Select Z88 Dest Storage Slot:"), Z88Slots, 0, false, &ok);
    if (ok && !item.isEmpty()){
        QString devname = QString(":RAM.");
        devname += item.mid(0,1);
        devname += "/";
        m_cthread.impExpSendFile(devname, dst_filenames, src_fileNames);
    }

    return;
}

/**
  * Start the Imp-Export protocol Receive Process.
  * @param dst_dir is the Destinaton directory
  * @return true if the thread is not busy
  */
bool MainWindow::StartImpExpReceive(const QString &dst_dir)
{
    return m_cthread.impExpReceiveFiles(dst_dir);
}

/**
  * Verify the Destination has enough space
  * @param sel_bytes is the Number of bytes in the selection.
  * @return true if the files will fit, or user chose to ignore.
  */
bool MainWindow::Verify_Z88Dest_SpaceAvail(quint32 sel_bytes)
{

    quint32 freeSpace = 0;
    quint32 totSpace = 0;

    float overhead = 1.085;

    if(m_Z88StorageView->getSelectedDeviceFreeSpace(freeSpace, totSpace)){

        if(double (overhead * (sel_bytes)) > double(freeSpace)){

            QMessageBox msgBox;
            QString msg;

            msg = (sel_bytes > totSpace) ? "Selection Exceeds Device Size.\n" :
                                           "Selection may not fit.\n";

            msg += "Attempt to copy: ";
            msg += QLocale(QLocale::system()).toString(float(overhead * sel_bytes), 'f', 0);

            if(sel_bytes > totSpace){
                msg += " Bytes to Storage that is only: ";
                msg += QLocale(QLocale::system()).toString(float(totSpace), 'f', 0);
                msgBox.setStandardButtons(QMessageBox::Cancel);
                msgBox.setInformativeText("Please Select a Different Device.");
            }
            else{
                msg += " Bytes, but Free Space is only: ";
                msg += QLocale(QLocale::system()).toString(float(freeSpace), 'f', 0);
                msgBox.setStandardButtons(QMessageBox::Yes | QMessageBox::Cancel);
                msgBox.setInformativeText("Do you want to Continue anyway ?");
            }
            msg += " Bytes.";

            msgBox.setText(msg);
            msgBox.setIcon(QMessageBox::Critical);
            msgBox.setDefaultButton(QMessageBox::Cancel);

            switch(msgBox.exec()){
                case QMessageBox::Yes:
                    return true;

                default:
                    return false;
                    break;
            }
        }
    }

    /**
      * Size not avail, or there is space
      */
    return true;
}

