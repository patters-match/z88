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

#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QMessageBox>
#include <QProgressDialog>
#include <QFileSystemModel>

#include "commthread.h"
#include "z88storageviewer.h"
#include "desktop_view.h"

QT_BEGIN_NAMESPACE
class QAction;
class QActionGroup;
class QLabel;
class QMenu;
QT_END_NAMESPACE

/* Forward decl */
class Z88SerialPort;

namespace Ui {
    class MainWindow;
}

/**
  * The Main UI window Class.
  */
class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit MainWindow(Z88SerialPort &sport, QWidget *parent = 0);
    ~MainWindow();

    Z88SerialPort &get_serialDev(){ return m_sport;}

    CommThread &get_comThread(){return m_cthread;}

    bool isTransferFromZ88();

    void setDesktopDirLabel(const QString &path);
    void setZ88DirLabel(const QString &path);


private slots:
    void AboutEazylink();
    void selSerialPort();
    void Z88Quit_EzLink();
    void helloZ88();
    void ByteTrans();
    void CRLFTrans();
    void ReloadTranslation();
    void SetZ88Clock();
    void getZ88Clock();
    void getZ88Info();
    void ReloadZ88View();
    void TransferFiles();
    void AbortCmd();
    void LoadingDeskList(const bool &aborted);
    void refreshSelectedZ88DeviceView();

    void ImpExp_sendfile();

    /**
      * I/O Thread Call-backs
      */
private slots:
    void enableCmds(bool ena, bool com_isOpen);
    void commOpen_result(const QString &dev_name, const QString &short_name, bool success);
    void cmdStatus(const QString &msg);
    void cmdProgress(const QString &title, int curVal, int total);
    void boolCmd_result(const QString &cmdName, bool success);
    void Z88Info_result(QList<QByteArray> *infolist);
    void Z88SelectionChanged(int count);
    void DeskTopSelectionChanged(int count);
    void PromptReceiveSpec(const QString &src_name, const QString &dst_name, bool *prompt_again);
    void PromptSendSpec(const QString &src_name, const QString &dst_name, bool *prompt_again);

protected:
    bool openSelSerialDialog();

    void StartSending(QList<DeskTop_Selection> &desk_selections, QList<Z88_Selection> &z88_selections);
    void StartReceiving(QList<Z88_Selection> &z88_selections, QList<DeskTop_Selection> &deskSelList);

private:
    /**
     * The Main window
     */
    Ui::MainWindow *ui;

    /**
      * The Command Status label on the Bottom of the main Form
      */
    QLabel *m_StatusLabel;

    /**
      * The Progress Dialog Box.
      */
    QProgressDialog *m_cmdProgress;

    /**
      * The Z88 Storage Viewer Container
      */
    Z88StorageViewer *m_Z88StorageView;

    QFileSystemModel *m_DeskFileSystem;

    Desktop_View *m_DeskTopTreeView;

    QList<Z88_Selection> m_z88Selections;

    /**
     * The Serial port device
     */
    Z88SerialPort &m_sport;

    /**
     * The Communications Thread.
     */
    CommThread m_cthread;

    /**
      * The Number of Succesfull commands executed
      */
    int m_cmdSuccessCount;

    int m_Z88SelectionCount;
    int m_DeskSelectionCount;

    /**
      * private method to set up connections for Signals.
      */
    void createActions();

    void setupDeskView();

    /**
      * Method to display a Communication error dialog Box
      */
    bool DisplayCommError(const QString &title, const QString &msg);

    bool enaTransferButton();

};
#endif // MAINWINDOW_H
