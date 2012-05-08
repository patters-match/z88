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
#include<QFile>
#include<QDebug>

#include "prefrences_dlg.h"
#include "ui_prefrences_dlg.h"
#include "commthread.h"

Prefrences_dlg::Prefrences_dlg(const QString &fspec, MainWindow *mw, CommThread *ct, QWidget *parent) :
    QDialog(parent),
    ui(new Ui::Prefrences_dlg),
    m_mainwinow(mw),
    m_cfgFileName(fspec),
    m_cthread(ct)
{
    ui->setupUi(this);

    connect(ui->Ui::Prefrences_dlg::buttonBox, SIGNAL(rejected()), this, SLOT(rejected()));
    connect(ui->Ui::Prefrences_dlg::buttonBox, SIGNAL(accepted()), this, SLOT(accepted()));
    connect(ui->Ui::Prefrences_dlg::RefreshBtn, SIGNAL(clicked()), this, SLOT(RefreshComsList()));
    connect(ui->Ui::Prefrences_dlg::tabWidget, SIGNAL(currentChanged(int)), this, SLOT(TabChanged(int)));
    connect(&m_InUse_Timer, SIGNAL(timeout()), this, SLOT(Poll_inuse()));

    RefreshComsList();

    ReadCfg(fspec);

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

//    ui->Ui::Prefrences_dlg::SelSerialGrp->setEnabled(!m_cthread->isBusy());

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

bool Prefrences_dlg::ReadCfg(const QString &fspec)
{
    QFile cfgFile(fspec);
    char port_fspec[300];

    char val[2];
    if(cfgFile.open(QIODevice::ReadOnly)){
        cfgFile.read(val, 1);
        if(cfgFile.error()) goto done;
        m_autoSyncClock = (*val == '1');

        cfgFile.read(val, 1);
        if(cfgFile.error()) goto done;
        m_Shutdown_exit = (*val == '1');

        cfgFile.read(val, 1);
        if(cfgFile.error()) goto done;
        m_crlfTrans = (*val == '1');

        cfgFile.read(val, 1);
        if(cfgFile.error()) goto done;
        m_byteTrans = (*val == '1');

        cfgFile.read(val, 1);
        if(cfgFile.error()) goto done;
        m_openPortonStart = (*val == '1');

        cfgFile.read(val, 1);
        if(cfgFile.error()) goto done;
        m_Z88RefreshonStart = (*val == '1');

        cfgFile.readLine(port_fspec, sizeof(port_fspec));
        if(cfgFile.error()) goto done;

        QString pname(port_fspec);

        if(!pname.isEmpty()){
            select_SerDevice(pname.mid(0, pname.size()-1));
#if 0
            int idx = ui->Ui::Prefrences_dlg::SerialPortList->findText(pname.mid(0, pname.size()-1));
            if(idx > -1){
                ui->Ui::Prefrences_dlg::SerialPortList->setCurrentIndex(idx);
                m_PortName = ui->Ui::Prefrences_dlg::SerialPortList->currentText();
            }
#endif
        }

        restoreChecked();
    }
    else{
done:
        cfgFile.close();
        return false;
    }

    cfgFile.close();
    return true;

}

bool Prefrences_dlg::WriteCfg(const QString &fspec)
{
    QFile cfgFile(fspec);

    qDebug() << "writing cfg:" << fspec;

    if(cfgFile.open(QIODevice::WriteOnly)){
        cfgFile.write(m_autoSyncClock ? "1" : "0");
        cfgFile.write(m_Shutdown_exit ? "1" : "0");
        cfgFile.write(m_crlfTrans ? "1" : "0");
        cfgFile.write(m_byteTrans ? "1" : "0");
        cfgFile.write(m_openPortonStart ? "1" : "0");
        cfgFile.write(m_Z88RefreshonStart ? "1" : "0");

        cfgFile.write(ui->Ui::Prefrences_dlg::SerialPortList->currentText().toAscii());
        cfgFile.write("\n");
    }
    else{
        return false;
    }
    cfgFile.close();

    return true;
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

/**
  * Reset the Previous Values.
  */
void Prefrences_dlg::rejected()
{
    m_InUse_Timer.stop();

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

    m_PortName = ui->Ui::Prefrences_dlg::SerialPortList->currentText();

    if(m_origPortName != m_PortName){
        emit SerialPortSelChanged();
    }

    if(!m_cfgFileName.isEmpty()){
        WriteCfg(m_cfgFileName);
    }
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

