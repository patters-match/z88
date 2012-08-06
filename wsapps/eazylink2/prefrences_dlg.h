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
#include <QComboBox>
#include "serialportsavail.h"

namespace Ui {
    class Prefrences_dlg;
}

class MainWindow;
class CommThread;
class QTableWidgetItem;
class ActionSettings;
class ActionRule;

class Prefrences_dlg : public QDialog
{
    Q_OBJECT
    
public:
    explicit Prefrences_dlg(MainWindow *mw, CommThread *ct,  QWidget *parent = 0);
    ~Prefrences_dlg();
    
    enum TabName{
        General,
        Translate,
        Comms,
        Actions,
        Default
    };

    enum ft_columns{
        ft_filename,
        ft_extension,
        ft_action,
        ft_columns
    };

    enum DblClk_Actions{
        Do_Nothing = 1001,
        Transfer,
        OpenFile
    };

    bool isSetupNeeded();

    void Activate(TabName tab = Default, bool s_portChanged = false);
    void ReadCfg();
    void WriteCfg();
    void WriteWizardCfg(const QString &shortname, bool use_Ezlink);

    CommThread *get_ComThread()const {return m_cthread;}

    bool select_SerDevice(const QString & TabName);
    bool select_SerDevice(const QString & TabName, QComboBox *cbox);

    bool getSerialPort_Names(QString &portname, QString &shortname);
    bool getSerialPort_Name(const QString &shortname, QString &portname);
    bool getInitDeskView(QString &rootPath, QString &initDir);
    void setInitDeskView(const QString &rootPath, const QString &initDir);

    bool get_AutoSyncClock() const;
    bool get_ShutdownEZ_OnExit() const;
    bool get_CRLF_Trans() const;
    bool get_Byte_Trans() const;
    bool get_PortOpenOnStart() const;
    bool get_RefreshZ88OnStart() const;
    bool get_initDir_IsRoot() const;

    int findAction(const QString &ActionStr, const QString Fspec, QString &CmdLine);
    const ActionRule *findActionRule(const QString &ActionKey, const QString Fspec, QString &CmdLine);

    const ActionRule * execActions(const QString &ActionStr, const QString Fspec, QString &CmdLine);

    void RefreshComsList(QComboBox *cbox);
    void RefreshComsList(QStringList &portList);

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

    void Init_Actions();

    Ui::Prefrences_dlg *ui;

    MainWindow *m_mainwinow;

    SerialPortsAvail m_SportsAvail;

    QString m_PortName;
    QString m_origPortName;
    QString m_rootPath;
    QString m_initDir;

    CommThread *m_cthread;
    ActionSettings *m_ActionSettings;

    QTimer m_InUse_Timer;

    QStringList m_ft_items;

    bool m_autoSyncClock;
    bool m_Shutdown_exit;
    bool m_crlfTrans;
    bool m_byteTrans;
    bool m_openPortonStart;
    bool m_Z88RefreshonStart;
    bool m_initDir_isRoot;

    friend class SetupWizard;
};

#endif // PREFRENCES_DLG_H
