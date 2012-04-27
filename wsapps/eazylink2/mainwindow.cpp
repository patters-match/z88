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

#include <QStringList>
#include <QInputDialog>
#include <QTreeView>
#include <QStatusBar>
#include <QLabel>
#include <QPushButton>

#include <qdebug.h>

#include "mainwindow.h"
#include "ui_mainwindow.h"
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
    m_StatusLabel(NULL),
    m_cmdProgress(NULL),
    m_Z88StorageView(NULL),
    m_DeskFileSystem(NULL),
    m_DeskTopTreeView(NULL),
    m_sport(sport),
    m_cthread(sport,this),
    m_cmdSuccessCount(0),
    m_Z88SelectionCount(-1),
    m_DeskSelectionCount(0)
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
    m_Z88StorageView = new Z88StorageViewer(m_cthread, this);
    ui->Ui::MainWindow::Z88Layout->addWidget(m_Z88StorageView);

    /**
      * Create and Configure the Desktop View
      */
    setupDeskView();

    /**
      * Connect the Signals To Slots
      */
    createActions();

}

/**
  * The main window Destructor.
  */
MainWindow::~MainWindow()
{
    delete ui;
    /**
      * request abort from the Current Comm Thread operation,
      * And wait for the thread to complete.
      */
    m_cthread.AbortCmd();
    m_cthread.wait();
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

    ui->Ui::MainWindow::actionHello->setStatusTip(tr("Send HelloZ88"));
    connect(ui->Ui::MainWindow::actionHello, SIGNAL(triggered()), this, SLOT(helloZ88()));

    connect(ui->Ui::MainWindow::actionTranslateByte, SIGNAL(triggered()), this, SLOT(ByteTrans()));
    connect(ui->Ui::MainWindow::actionTranslateCRLF, SIGNAL(triggered()), this, SLOT(CRLFTrans()));
    connect(ui->Ui::MainWindow::actionReload_Table, SIGNAL(triggered()), this, SLOT(ReloadTranslation()));
    connect(ui->Ui::MainWindow::actionSet_Z88_Clock, SIGNAL(triggered()), this, SLOT(SetZ88Clock()));
    connect(ui->Ui::MainWindow::actionReadZ88_Clock, SIGNAL(triggered()), this, SLOT(getZ88Clock()));
    connect(ui->Ui::MainWindow::actionGet_Info, SIGNAL(triggered()), this, SLOT(getZ88Info()));

    ui->Ui::MainWindow::actionZ88Refresh->setStatusTip(tr("Refresh Z88 View"));
    connect(ui->Ui::MainWindow::actionZ88Refresh, SIGNAL(triggered()), this, SLOT(ReloadZ88View()));
    connect(ui->Ui::MainWindow::actionAbout, SIGNAL(triggered()), this, SLOT(AboutEazylink()));

    connect(ui->Ui::MainWindow::CancelCmdBtn, SIGNAL(pressed()), this, SLOT(AbortCmd()));

    connect(m_Z88StorageView,  SIGNAL(ItemSelectionChanged(int)), this, SLOT(Z88SelectionChanged(int)));
    connect(m_DeskTopTreeView, SIGNAL(ItemSelectionChanged(int)), this, SLOT(DeskTopSelectionChanged(int)));

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
            SIGNAL(cmdProgress(const QString &, int, int)),
            this,
            SLOT(cmdProgress(const QString &, int, int)));

    connect(&m_cthread,
            SIGNAL(boolCmd_result(const QString &, bool)),
            this,
            SLOT(boolCmd_result(const QString &, bool)));

    connect(&m_cthread,
            SIGNAL(Z88Info_result(QList<QByteArray> *)),
            this,
            SLOT(Z88Info_result(QList<QByteArray> *)));

    connect(&m_cthread,
            SIGNAL(PromptReceiveSpec(const QString &, const QString &,bool *)),
            this,
            SLOT(PromptReceiveSpec(const QString &, const QString &,bool *)));

    connect(&m_cthread,
            SIGNAL(PromptSendSpec(const QString &, const QString &,bool *)),
            this,
            SLOT(PromptSendSpec(const QString &, const QString &,bool *)));

    connect(&m_cthread,
            SIGNAL(DirLoadComplete(const bool &)),
            this,
            SLOT(LoadingDeskList(const bool &)));

}

/**
  * Create and Setup the Deskview Panel.
  */
void MainWindow::setupDeskView()
{
    m_DeskTopTreeView = new Desktop_View(m_cthread, this);

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

void MainWindow::ByteTrans()
{
    get_comThread().ByteTrans(ui->Ui::MainWindow::actionTranslateByte->isChecked());
}

void MainWindow::CRLFTrans()
{
    get_comThread().CRLFTrans(ui->Ui::MainWindow::actionTranslateCRLF->isChecked());
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

    // qDebug() << m_sport.impExpSendFile(":RAM.1/romupdate.txt", "/Users/oernohaz/files/z88/bitbucket/z88/z88apps/romupdate/readme.txt");
    //qDebug() << m_sport.sendFile(":RAM.1/DIRX/hello2.txt", "/Users/oernohaz/files/hello2.txt");

}

void MainWindow::AboutEazylink()
{
    QString msg("\tEazyLink2");
    msg += " - v1.00";
    msg += "\r\n\t    04.10.2012";
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
    ui->Ui::MainWindow::menu_Options->setEnabled(ena);
    ui->Ui::MainWindow::actionSerialPort->setEnabled(ena);

    /**
      * Disable Z88 Menu and Command tool bar if comm port is not open
      */
    if(!com_isOpen){
        ena = false;
    }
    ui->Ui::MainWindow::menuZ88->setEnabled(ena);
    ui->Ui::MainWindow::toolBar->setEnabled(ena);
    ui->Ui::MainWindow::menuTranslations->setEnabled(ena);
    ui->Ui::MainWindow::actionQuitEazyLink->setEnabled(ena);
    ui->Ui::MainWindow::actionEazyLink_Hello->setEnabled(ena);
    ui->Ui::MainWindow::actionReceive_files_from_Z88_Imp_Export_popdown->setEnabled(ena);
    ui->Ui::MainWindow::actionSend_files_to_Z88ImpExport->setEnabled(ena);
    ui->Ui::MainWindow::actionSet_Z88_Clock->setEnabled(ena);
    ui->Ui::MainWindow::actionReadZ88_Clock->setEnabled(ena);
    ui->Ui::MainWindow::actionGet_Info->setEnabled(ena);
}

/**
  * Create and Display a user Dialog prompting for the Serial port device to use.
  * @return true on success.
  */
bool MainWindow::openSelSerialDialog()
{
    SerialPortsAvail SportsAvail;
    bool ok;

    m_StatusLabel->clear();

    QString item = QInputDialog::getItem(this, "Open Serial Port",
                                          tr("Select Z88 Port:"), SportsAvail.get_portList(), 0, false, &ok);
    if (ok && !item.isEmpty()){

        /**
          * Try to opend the Serial Device Specified
          */
        ok = get_comThread().open(SportsAvail.get_fullportName(item), item);
    }
    return ok;
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
        return;
    }

    if(total){
        if(curVal == 0){
            m_cmdProgress = new QProgressDialog(title, "Abort", 0, total+1, NULL);
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
void MainWindow::PromptReceiveSpec(const QString &src_name, const QString &dst_name, bool *prompt_again)
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

    switch(msgBox.exec()){
        case QMessageBox::YesToAll:
            *prompt_again = false;
            // drop through
        case QMessageBox::Yes:
            m_cthread.receiveFile(false);
            break;
        case  QMessageBox::No:
            m_cthread.receiveFile(true);
            break;
        case QMessageBox::Cancel:
            if(m_cmdProgress) m_cmdProgress->reset();
        //cmdProgress("Cancelled", m_z88Selections.count()-1,m_z88Selections.count())
            return;
    }
}

void MainWindow::PromptSendSpec(const QString &src_name, const QString &dst_name, bool *prompt_again)
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

    switch(msgBox.exec()){
        case QMessageBox::YesToAll:
            *prompt_again = false;
            // drop through
        case QMessageBox::Yes:
            m_cthread.sendFile(false);
            break;
        case  QMessageBox::No:
            m_cthread.sendFile(true);
            break;
        case QMessageBox::Cancel:
            if(m_cmdProgress) m_cmdProgress->reset();
            return;
    }
}

/**
  * Validate and enable the Transfer button, based on the selected items in
  * both the z88 and Desktop frames.
  * @return true if the transfer button can be enabled.
  */
bool MainWindow::enaTransferButton()
{
    QList<DeskTop_Selection> *dl;
    QList<DeskTop_Selection> DeskSelList;
    dl = m_DeskTopTreeView->getSelection(false);

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

        enableCmds(false, m_sport.isOpen());
        cmdStatus("Reading Source Files...");

        /**
          * Get the Selected Source File(s) from the Desktop
          */
        QList<DeskTop_Selection> *deskSelList;
        deskSelList = m_DeskTopTreeView->getSelection(true);

        if(deskSelList){
            StartSending(*deskSelList, m_z88Selections);
        }
    }
}

void MainWindow::LoadingDeskList(const bool &aborted)
{
    if(aborted){
        m_DeskTopTreeView->DirLoadAborted();
        return;
    }

    QList<DeskTop_Selection> *deskSelList;
    deskSelList = m_DeskTopTreeView->getSelection(true, true);

    if(deskSelList){
        StartSending(*deskSelList, m_z88Selections);
    }
}

void MainWindow::StartSending(QList<DeskTop_Selection> &desk_selections, QList<Z88_Selection> &z88_selections)
{
    bool prompt4each = false;

    /**
      * Count the Number of Files to Send, ignore Directories
      */
    int filecnt = 0;
    if(!desk_selections.isEmpty()){
        QListIterator<DeskTop_Selection> i(desk_selections);
        while(i.hasNext()){
            if(i.next().getType() == DeskTop_Selection::type_File){
                filecnt++;
            }
        }
    }
    else{
        return;
    }

    QMessageBox msgBox;
    QString msg = "Transfer ";
    msg += QString("%1").arg(filecnt);
    msg += " file";
    if(filecnt > 1){
        msg += 's';
    }
    msg += " To Z88";

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
            prompt4each = true;
            break;
        case  QMessageBox::No:
            break;
        case QMessageBox::Cancel:
            cmdStatus("Transfer Cancelled.");
            enableCmds(true, m_sport.isOpen());
            return;
    }

    m_DeskTopTreeView->prependSubdirNames(desk_selections);

    QMutableListIterator<DeskTop_Selection> di(desk_selections);
    /**
      * Remove all the Directory Entries
      */
    while(di.hasNext()){
        qDebug() << "files=" << di.peekNext().getFspec() << "name=" << di.peekNext().getFname() << "type = " << di.peekNext().getType();
        if(di.next().getType()==DeskTop_Selection::type_Dir){
          //  di.remove();
        }
    }

    QListIterator<DeskTop_Selection> i(desk_selections);

    while(i.hasNext()){
        qDebug() << "desk files=" << i.next().getFspec();
    }

    qDebug() << "desk file count =" << desk_selections.count();

    boolCmd_result("File Transfer", true);

    enableCmds(true, m_sport.isOpen());

    m_cthread.sendFiles(&desk_selections, z88_selections[0].getFspec(), prompt4each);
}

void MainWindow::StartReceiving(QList<Z88_Selection> &z88_selections, QList<DeskTop_Selection> &deskSelList)
{
    bool prompt4each = false;

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
    msg += QString("%1").arg(filecnt);
    msg += " file";
    if(filecnt > 1){
        msg += 's';
    }
    msg += " From Z88";

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
            prompt4each = true;
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

