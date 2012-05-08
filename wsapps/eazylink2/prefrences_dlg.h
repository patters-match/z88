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

#ifndef PREFRENCES_DLG_H
#define PREFRENCES_DLG_H

#include <QDialog>
#include <QTimer>
#include "serialportsavail.h"

namespace Ui {
    class Prefrences_dlg;
}

class MainWindow;
class CommThread;

class Prefrences_dlg : public QDialog
{
    Q_OBJECT
    
public:
    explicit Prefrences_dlg(const QString &fspec, MainWindow *mw, CommThread *ct,  QWidget *parent = 0);
    ~Prefrences_dlg();
    
    enum TabName{
        General,
        Translate,
        Comms,
        Default
    };

    void Activate(TabName tab = Default);
    bool select_SerDevice(const QString & TabName);

    bool ReadCfg(const QString &fspec);
    bool WriteCfg(const QString &fspec);
    bool getSerialPort_Name(QString &portname, QString &shortname);

    bool get_AutoSyncClock() const;
    bool get_ShutdownEZ_OnExit() const;
    bool get_CRLF_Trans() const;
    bool get_Byte_Trans() const;
    bool get_PortOpenOnStart() const;
    bool get_RefreshZ88OnStart() const;

private slots:
    void rejected();
    void accepted();
    void RefreshComsList();
    void TabChanged(int idx);
    void Poll_inuse();

signals:
    void SerialPortSelChanged();

private:
    void restoreChecked();

    Ui::Prefrences_dlg *ui;

    MainWindow *m_mainwinow;

    QString m_cfgFileName;

    SerialPortsAvail m_SportsAvail;

    QString m_PortName;
    QString m_origPortName;

    CommThread *m_cthread;

    QTimer m_InUse_Timer;

    bool m_autoSyncClock;
    bool m_Shutdown_exit;
    bool m_crlfTrans;
    bool m_byteTrans;
    bool m_openPortonStart;
    bool m_Z88RefreshonStart;

};

#endif // PREFRENCES_DLG_H
