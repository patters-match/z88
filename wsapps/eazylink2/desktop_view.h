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
#ifndef DESKTOP_VIEW_H
#define DESKTOP_VIEW_H

#include <QTreeView>
#include <QFileSystemModel>
#include <QSystemSemaphore>
#include <QMutex>
#include<QMenu>

#include "commthread.h"
#include "prefrences_dlg.h"

/* Forward decl */
class DeskTop_Selection;
class Z88_Selection;
class MainWindow;
class Prefrences_dlg;

/**
  * The Desktop Viewer Class. Inherits from the QTreeView class.
  */
class Desktop_View : public QTreeView
{
    Q_OBJECT
public:
    explicit Desktop_View(CommThread &cthread, Prefrences_dlg *pref_dlg, MainWindow *parent = 0);

    QList<DeskTop_Selection> *getSelection(bool recurse, quint32 &sel_bytes, bool cont = false);
    QList<DeskTop_Selection> *getSelection(bool recurse, bool cont = false);

    bool mkDirectoryTree(const QList<Z88_Selection> &z88Selections );
    void prependSubdirNames(QList<DeskTop_Selection> &desk_selections);
    void DirLoadAborted();

    bool renameSelections();
    bool deleteSelections();
    void selectInitDir();
    void selectDrive();
    bool mkDir();

signals:
    void ItemSelectionChanged(int);
    void Trigger_Transfer();
    void CancelDirRead();

private slots:
    void ItemSelectionChanged(const QModelIndex &);
    void DirLoaded(const QString &);
    void ActionsMenuSel(QAction * act);
    void ItemDoubleClicked(const QModelIndex & index);

protected:
    /**
      * The GUI Event handler. handles mouse in/out etc.
      */
    bool eventFilter(QObject *, QEvent *ev);

    /**
      * Internal, create a sub-directory on Desktop method.
      */
    bool mkSubdir(QListIterator<Z88_Selection> &i, QModelIndex dst_root);
    void prependSubdirNames(QMutableListIterator<DeskTop_Selection> &i);

    bool getSubdirFiles(const QModelIndex &idx, quint32 &sel_size);
    bool delSubdirFiles(QListIterator<DeskTop_Selection> &i, int &ret);
    bool delFile(QListIterator<DeskTop_Selection> &i, int &ret);

    void deleteSubdirFiles(const QModelIndex &idx, int &ret);
    void deleteFile(const QModelIndex &idx, int &ret);

    void setInitViewPath(const QString &rootPath, const QString &directory);

private:
    /**
      * The QT File Model. Represents the Host Filesystem
      */
    QFileSystemModel *m_DeskFileSystem;

    /**
      * The list of selected Files on the Desktop View, once transfer operation is selected.
      */
    QList<DeskTop_Selection> m_Selections;

    /**
      * The Communications thread
      */
    CommThread &m_cthread;

    QModelIndexList m_ModelSelections;

    bool m_recurse;

    MainWindow *m_mainWindow;
    Prefrences_dlg *m_pref_dlg;

    QMenu      *m_qmenu;
    QAction    *m_actionRename;
    QAction    *m_actionDelete;
    QAction    *m_actionMkdir;
    QAction    *m_actionSetInitDir;
    QAction    *m_actionChgRoot;
};

/**
  * The Desktop Selected File Attribute container class.
  */
class DeskTop_Selection{

public:

    /**
      * The types of items that are selectable.
      */
    enum entryType{
        type_Dir,       // Item is a directory.
        type_File       // Item is a File.
    };

public:
    /**
      * Constructor
      */
    DeskTop_Selection(const QString &fspec, const QString &fname, entryType type = type_Dir);

    const QString &getFspec()const {return m_fspec;}
    const QString &getFname()const {return m_fname;}
    const entryType &getType()const{return m_type;}

    void setSubdir(const QString &subdir){m_fname.prepend(subdir);}

    void setFname(const QString &newname){m_fname = newname;}

    friend class Desktop_View;

protected:

    /**
      * Selection full path and name
      */
    QString m_fspec;

    /**
      * Selection file name
      */
    QString m_fname;

    /**
      * Selection type (dir or file)
      */
    entryType m_type;

};
#endif // DESKTOP_VIEW_H
