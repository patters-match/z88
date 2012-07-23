/*********************************************************************************************

 EazyLink2 - Fast Client/Server Z88 File Management
 (C) Gunther Strube (gstrube@gmail.com) 2011
 Oscar Ernohazy 2012

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
#include <QSettings>
#include <QFile>
#include <QDir>
#include <QDebug>
#include <QTableWidget>
#include <QInputDialog>
#include <QFileDialog>
#include <QProcess>

#include "actionsettings.h"
#include "prefrences_dlg.h"
#include "ui_prefrences_dlg.h"
#include "commthread.h"

Prefrences_dlg::Prefrences_dlg(MainWindow *mw, CommThread *ct, QWidget *parent) :
    QDialog(parent),
    ui(new Ui::Prefrences_dlg),
    m_mainwinow(mw),
    m_cthread(ct),
    m_ActionSettings(NULL)
{
    ui->setupUi(this);

    connect(ui->Ui::Prefrences_dlg::buttonBox, SIGNAL(rejected()), this, SLOT(rejected()));
    connect(ui->Ui::Prefrences_dlg::buttonBox, SIGNAL(accepted()), this, SLOT(accepted()));
    connect(ui->Ui::Prefrences_dlg::RefreshBtn, SIGNAL(clicked()), this, SLOT(RefreshComsList()));
    connect(ui->Ui::Prefrences_dlg::tabWidget, SIGNAL(currentChanged(int)), this, SLOT(TabChanged(int)));
    connect(&m_InUse_Timer, SIGNAL(timeout()), this, SLOT(Poll_inuse()));

    RefreshComsList();

    /**
      * Init the Actions Pref Panel
      */
    Init_Actions();

    ReadCfg();
}
/**
  * Destructor
  */
Prefrences_dlg::~Prefrences_dlg()
{
    delete ui;
}

/**
  * Display the Preferences Dialog
  */
void Prefrences_dlg::Activate(TabName tab)
{
    /**
      * Save the Initial Values.
      */
    m_autoSyncClock = get_AutoSyncClock();
    m_Shutdown_exit = get_ShutdownEZ_OnExit();
    m_crlfTrans = get_CRLF_Trans();
    m_byteTrans = get_Byte_Trans();
    m_openPortonStart = get_PortOpenOnStart();
    m_Z88RefreshonStart = get_RefreshZ88OnStart();
    m_initDir_isRoot = get_initDir_IsRoot();

    if(m_cthread->isOpen()){
        m_origPortName = ui->Ui::Prefrences_dlg::SerialPortList->currentText();
    }
    else{
        m_origPortName = "";
    }

    /**
      * Don't allow serial port change is coms are busy
      */
    Poll_inuse();

    setModal(true);

    /**
      * Set the Tab to the specified tab,  default means Last tab.
      */
    if(tab != Default){
        ui->Ui::Prefrences_dlg::tabWidget->setCurrentIndex(tab);
    }

    show();
}

bool Prefrences_dlg::select_SerDevice(const QString &TabName)
{
    int idx = ui->Ui::Prefrences_dlg::SerialPortList->findText(TabName);
    if(idx > -1){
        ui->Ui::Prefrences_dlg::SerialPortList->setCurrentIndex(idx);
        m_PortName = ui->Ui::Prefrences_dlg::SerialPortList->currentText();
        return true;
    }
    return false;
}

void Prefrences_dlg::ReadCfg()
{
    QSettings settings(QSettings::UserScope, "z88", "EazyLink2");

    m_autoSyncClock = settings.value("AutoSynchronizeClock", true).toBool();
    m_Shutdown_exit = settings.value("ShutdownEazyLinkOnExit", true).toBool();
    m_crlfTrans = settings.value("DefaultLinefeedConversion", true).toBool();
    m_byteTrans = settings.value("DefaultByteTranslation", true).toBool();
    m_openPortonStart = settings.value("OpenSerialportOnStart", true).toBool();
    m_Z88RefreshonStart = settings.value("RefreshZ88panelOnStart", true).toBool();

    m_rootPath = settings.value("initDeskRoot", QDir::rootPath()).toString();
    m_initDir = settings.value("initDeskDir", QDir::homePath()).toString();
    m_initDir_isRoot = settings.value("InitDeskIsRoot", false).toBool();

    QString pname(settings.value("Serialport").toString());

    if(!pname.isEmpty()){
        select_SerDevice(pname);
    }

    restoreChecked();
}

void Prefrences_dlg::WriteCfg()
{
    QSettings settings(QSettings::UserScope, "z88", "EazyLink2");

    settings.setValue("AutoSynchronizeClock", m_autoSyncClock);
    settings.setValue("ShutdownEazyLinkOnExit", m_Shutdown_exit);
    settings.setValue("DefaultLinefeedConversion", m_crlfTrans);
    settings.setValue("DefaultByteTranslation", m_byteTrans);
    settings.setValue("OpenSerialportOnStart", m_openPortonStart);
    settings.setValue("RefreshZ88panelOnStart", m_Z88RefreshonStart);
    settings.setValue("Serialport", ui->Ui::Prefrences_dlg::SerialPortList->currentText());
    settings.setValue("InitDeskIsRoot", m_initDir_isRoot);

    /**
      * Save the Actions Table(s)
      */
    m_ActionSettings->save_ActionList(settings);
    // settings are stored on disk by QSettings destructor..
}

bool Prefrences_dlg::getSerialPort_Name(QString &portname, QString &shortname)
{
    if(!m_PortName.isEmpty()){
        portname = m_SportsAvail.get_fullportName(m_PortName);
        shortname = m_PortName;
        return true;
    }
    return false;
}

bool Prefrences_dlg::getInitDeskView(QString &rootPath, QString &initDir)
{
    if(m_rootPath.isEmpty() || m_initDir.isEmpty()){
        return false;
    }
    if(m_initDir_isRoot){
        rootPath = m_initDir;
    }
    else{
        rootPath = m_rootPath;
    }
    initDir = m_initDir;
    return true;
}

void Prefrences_dlg::setInitDeskView(const QString &rootPath, const QString &initDir)
{
    QSettings settings(QSettings::UserScope, "z88", "EazyLink2");

    m_rootPath = rootPath;
    m_initDir = initDir;
    settings.setValue("initDeskRoot", m_rootPath);
    settings.setValue("initDeskDir", m_initDir);
}

/**
  * Read the state of the Sync Time checkbox
  */
bool Prefrences_dlg::get_AutoSyncClock() const
{
    return ui->Ui::Prefrences_dlg::tmSync_cbox->isChecked();
}

/**
  * Read state of Shutdown eazylink on exit checkbox
  */
bool Prefrences_dlg::get_ShutdownEZ_OnExit() const
{
    return ui->Ui::Prefrences_dlg::ezQuit_cbox->isChecked();
}

bool Prefrences_dlg::get_CRLF_Trans() const
{
    return ui->Ui::Prefrences_dlg::lineFeed_trans->isChecked();
}

bool Prefrences_dlg::get_Byte_Trans() const
{
    return ui->Ui::Prefrences_dlg::byteMode_trans->isChecked();
}

bool Prefrences_dlg::get_PortOpenOnStart() const
{
    return ui->Ui::Prefrences_dlg::OpenPortOnStartup->isChecked();
}

bool Prefrences_dlg::get_RefreshZ88OnStart() const
{
    return ui->Ui::Prefrences_dlg::ldZ88TreeOnStart->isChecked();
}

bool Prefrences_dlg::get_initDir_IsRoot() const
{
    return ui->Ui::Prefrences_dlg::InitDir_isRoot->isChecked();
}

int Prefrences_dlg::findAction(const QString &ActionStr, const QString Fspec, QString &CmdLine)
{
    if(m_ActionSettings){
        return m_ActionSettings->findAction(ActionStr, Fspec, CmdLine);
    }
    return 0;
}

const ActionRule *Prefrences_dlg::findActionRule(const QString &ActionKey, const QString Fspec, QString &CmdLine)
{
    if(m_ActionSettings){
        return m_ActionSettings->findActionRule(ActionKey, Fspec, CmdLine);
    }
    return NULL;
}

/**
  * Execute the Action, including launching external app if needed
  */
const ActionRule *Prefrences_dlg::execActions(const QString &ActionStr, const QString Fspec, QString &CmdLine)
{    
    const ActionRule *arule = findActionRule(ActionStr, Fspec, CmdLine);

    if(arule && arule->m_RuleID == ActionRule::OPEN_WITH_EXT_APP){

        QStringList commandAndParameters = CmdLine.split(" ");

        if(commandAndParameters.count() < 1){
            return NULL;
        }

        QString exename(commandAndParameters.first());
        commandAndParameters.removeFirst();

        qDebug() << "Start :" << exename <<  commandAndParameters;
        QProcess *myProcess = new QProcess(this);

            // Start the QProcess instance.
        myProcess->start(exename, commandAndParameters);
    }

    return arule;
}

/**
  * Reset the Previous Values.
  */
void Prefrences_dlg::rejected()
{
    m_InUse_Timer.stop();

    /**
      * Refresh the Old Values
      */
    m_ActionSettings->reLoadActionRulesList();

    restoreChecked();
}

void Prefrences_dlg::accepted()
{
    m_InUse_Timer.stop();

    m_autoSyncClock = get_AutoSyncClock();
    m_Shutdown_exit = get_ShutdownEZ_OnExit();
    m_crlfTrans = get_CRLF_Trans();
    m_byteTrans = get_Byte_Trans();
    m_openPortonStart = get_PortOpenOnStart();
    m_Z88RefreshonStart = get_RefreshZ88OnStart();
    m_initDir_isRoot = get_initDir_IsRoot();

    m_PortName = ui->Ui::Prefrences_dlg::SerialPortList->currentText();

    if(m_origPortName != m_PortName){
        emit SerialPortSelChanged();
    }

    WriteCfg();
}

void Prefrences_dlg::RefreshComsList()
{
    QString cur_dev = ui->Ui::Prefrences_dlg::SerialPortList->currentText();

    ui->Ui::Prefrences_dlg::SerialPortList->clear();
    ui->Ui::Prefrences_dlg::SerialPortList->addItems(m_SportsAvail.get_portList());
    select_SerDevice(cur_dev);
}

/**
  * Preference tab changed.
  * @param idx is the index of the new tab
  */
void Prefrences_dlg::TabChanged(int idx)
{
    if(idx == Comms){
        /**
          * Don't allow com port change, if its busy
          */
        Poll_inuse();
    }
}

void Prefrences_dlg::restoreChecked()
{
    ui->Ui::Prefrences_dlg::tmSync_cbox->setChecked(m_autoSyncClock);
    ui->Ui::Prefrences_dlg::ezQuit_cbox->setChecked(m_Shutdown_exit);
    ui->Ui::Prefrences_dlg::lineFeed_trans->setChecked(m_crlfTrans);
    ui->Ui::Prefrences_dlg::byteMode_trans->setChecked(m_byteTrans);
    ui->Ui::Prefrences_dlg::OpenPortOnStartup->setChecked(m_openPortonStart);
    ui->Ui::Prefrences_dlg::ldZ88TreeOnStart->setChecked(m_Z88RefreshonStart);
    ui->Ui::Prefrences_dlg::InitDir_isRoot->setChecked(m_initDir_isRoot);

}

void Prefrences_dlg::Init_Actions()
{
    StringLList_t defaults;
    QStringList def_data;

    m_ActionSettings = new ActionSettings();
    ui->Ui::Prefrences_dlg::tabWidget->addTab(m_ActionSettings, "Actions");

    /**
      * Double Click HostFile Action
      */
    ActionRuleList_t avl1;
    avl1.append(ActionRule("Transfer to Z88","", ActionRule::TRANSFER_FILE));
    avl1.append(ActionRule("Open with...", "%P/%F", ActionRule::OPEN_WITH_EXT_APP));
    avl1.append(ActionRule("Ignore","", ActionRule::IGNORE));


    /**
      * Set up Defaults
      */
    def_data.append("*");        // Filename
    def_data.append("*");        // ext
    def_data.append(avl1[0]);    // action
    def_data.append("");         // args
    defaults.append(def_data);

    FileAction fa1(Action_Settings::ActKey_DBLCLK_HOSTFILE, "Double Click HostFile", avl1, defaults);
    m_ActionSettings->Append_FileAction(fa1);

    /**
      * Double Click Z88 File Action.
      */
    ActionRuleList_t avl2;
    avl2.append(ActionRule("Transfer to Desktop","", ActionRule::TRANSFER_FILE));
    avl2.append(ActionRule("Ignore","", ActionRule::IGNORE));

    /**
      * Set up Defaults
      */
    def_data.clear();
    defaults.clear();

    def_data.append("*");        // Filename
    def_data.append("*");        // ext
    def_data.append(avl2[0]);    // action
    def_data.append("");         // args
    defaults.append(def_data);

    FileAction fa2(Action_Settings::ActKey_DBLCLK_Z88FILE, "Double Click Z88 File", avl2, defaults);
    m_ActionSettings->Append_FileAction(fa2);

    /**
      * Receive From Z88 Action
      */
    ActionRuleList_t avl3;
    avl3.append(ActionRule("Receive Default", Action_Settings::DEFAULT_FILESPEC_ARGS, ActionRule::TRANSFER_FILE));
    avl3.append(ActionRule("Open with...", Action_Settings::DEFAULT_FULLFSPEC, ActionRule::OPEN_WITH_EXT_APP));
    avl3.append(ActionRule("Convert Linefeeds", Action_Settings::DEFAULT_FILESPEC_ARGS, ActionRule::CONVERT_CRLF));
    avl3.append(ActionRule("Receive Binary" , Action_Settings::DEFAULT_FILESPEC_ARGS, ActionRule::BINARY_MODE));
    avl3.append(ActionRule("Skip","", ActionRule::IGNORE));


    /**
      * Set up Defaults
      */
    def_data.clear();
    defaults.clear();

    /**
      * Defaults for text files
      */
    def_data.append("*");        // Filename
    def_data.append("txt");      // ext
    def_data.append(avl3[2]);    // action  Convert Line Feeds for txt files
    def_data.append(Action_Settings::DEFAULT_FILESPEC_ARGS);         // args
    defaults.append(def_data);

    /**
      * Defaults for ZIP files
      */
    def_data.clear();
    def_data.append("*");        // Filename
    def_data.append("zip");      // ext
    def_data.append(avl3[3]);    // action Receive Binary
    def_data.append(Action_Settings::DEFAULT_FILESPEC_ARGS);         // args
    defaults.append(def_data);

    /*
      * Defaults for All other files
      */
    def_data.clear();
    def_data.append("*");        // Filename
    def_data.append("*");        // ext
    def_data.append(avl3[0]);    // action - receive with default settings.
    def_data.append(Action_Settings::DEFAULT_FILESPEC_ARGS);         // args
    defaults.append(def_data);

    FileAction fa3(Action_Settings::ActKey_RX_FROMZ88, "Receive From Z88", avl3, defaults);
    m_ActionSettings->Append_FileAction(fa3);

    /**
      * Send to Z88 Action.
      */
    ActionRuleList_t avl4;
    avl4.append(ActionRule("Send Default", Action_Settings::DEFAULT_Z88_DESTSPEC, ActionRule::TRANSFER_FILE));
    avl4.append(ActionRule("Convert Linefeeds", Action_Settings::DEFAULT_Z88_DESTSPEC, ActionRule::CONVERT_CRLF));
    avl4.append(ActionRule("Send Binary" , Action_Settings::DEFAULT_Z88_DESTSPEC, ActionRule::BINARY_MODE));
    avl4.append(ActionRule("Skip","", ActionRule::IGNORE));

    /**
      * Set up Defaults
      */
    def_data.clear();
    defaults.clear();

    /**
      * Defaults for text files
      */
    def_data.append("*");        // Filename
    def_data.append("txt");      // ext
    def_data.append(avl4[1]);    // action  Convert Line Feeds for txt files
    def_data.append(Action_Settings::DEFAULT_Z88_DESTSPEC);         // args
    defaults.append(def_data);

    /**
      * Defaults for ZIP files
      */
    def_data.clear();
    def_data.append("*");        // Filename
    def_data.append("zip");      // ext
    def_data.append(avl4[2]);    // action Send Binary
    def_data.append(Action_Settings::DEFAULT_Z88_DESTSPEC);         // args
    defaults.append(def_data);

    def_data.clear();
    def_data.append("*");        // Filename
    def_data.append("*");        // ext
    def_data.append(avl4[0]);    // action Send Default
    def_data.append(Action_Settings::DEFAULT_Z88_DESTSPEC);         // args
    defaults.append(def_data);

    FileAction fa4(Action_Settings::ActKey_TX_TOZ88, "Send to Z88", avl4, defaults);
    m_ActionSettings->Append_FileAction(fa4);
}

void Prefrences_dlg::Poll_inuse()
{
    if(ui->Ui::Prefrences_dlg::tabWidget->currentIndex() == Comms){
        /**
          * Don't allow com port change, if it's busy
          */
        ui->Ui::Prefrences_dlg::SelSerialGrp->setEnabled(!m_cthread->isBusy());

        if(m_cthread->isBusy()){
            m_InUse_Timer.start(750);
            return;
        }
    }
    m_InUse_Timer.stop();
}
