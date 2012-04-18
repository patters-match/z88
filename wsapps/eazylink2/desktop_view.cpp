/*********************************************************************************************

 EazyLink2 - Fast Client/Server Z88 File Management
 (C) Gunther Strube (gstrube@gmail.com) & Oscar Ernohazy 2012

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

#include<QDebug>
#include<QEvent>
#include <QFileSystemWatcher>

#include "desktop_view.h"
#include "z88_devview.h"

/**
  * DeskTop Selection Constructor
  * @param fspec is the Fully qualified file path and name.
  * @param type is the type of entry. ie Dir or File.
  */
DeskTop_Selection::DeskTop_Selection(const QString &fspec, const QString &fname, entryType type)
  :m_fspec(fspec),
   m_fname(fname),
  m_type(type)
{
}

/**
  * Destop View Contstructor.
  * @parm parent is the Owner Qwidget
  */
Desktop_View::Desktop_View(CommThread &cthread, QWidget *parent) :
    QTreeView(parent),
    m_cthread(cthread),
    m_recurse(false)
{
    m_DeskFileSystem = new QFileSystemModel();

    m_DeskFileSystem->setRootPath(QDir::homePath());

    setModel(m_DeskFileSystem);

    setRootIndex(m_DeskFileSystem->index(QDir::homePath()));

    m_DeskFileSystem->setResolveSymlinks(true);

    connect(this, SIGNAL(clicked(const QModelIndex &)), this, SLOT(ItemSelectionChanged(const QModelIndex &)));

    connect(m_DeskFileSystem, SIGNAL(directoryLoaded(QString)), this, SLOT(DirLoaded(QString)));

    installEventFilter(this);
}

/**
  * Get a List of the selected file(s)
  * @return the list of filenames.
  */
QList<DeskTop_Selection> *Desktop_View::getSelection(bool recurse, bool cont)
{
    if(!recurse && m_recurse){
        return NULL;
    }

    /**
      * If Continuing a readlist, then use the initially selected list.
      * Otherwise get the current selection
      */
    if(!cont){
        m_ModelSelections = selectedIndexes();
    }

    const QModelIndexList &Selections(m_ModelSelections);

    m_Selections.clear();

    if(!Selections.isEmpty()){

        m_recurse = recurse;

        for(int count=0; count < Selections.count(); count+=3){
            const QModelIndex &idx(Selections[count]);

            DeskTop_Selection::entryType type = (m_DeskFileSystem->isDir(idx)) ?
                        DeskTop_Selection::type_Dir : DeskTop_Selection::type_File;

            if(recurse && type == DeskTop_Selection::type_Dir){
                if(!getSubdirFiles(idx)){
                    return NULL; // More to grab
                }
            }
            else{
                m_Selections.append(DeskTop_Selection(m_DeskFileSystem->filePath(idx), m_DeskFileSystem->fileName(idx), type));
            }
        }
    }
    else{
        m_Selections.append(DeskTop_Selection(m_DeskFileSystem->rootPath(), m_DeskFileSystem->rootPath(), DeskTop_Selection::type_Dir));
    }

    m_recurse = false;
    return &m_Selections;
}

/**
  * Build a directory tree below the Currently selected Directory.
  * @param z88Selections is the list of Source files and directories to be created.
  * @return true on success
  */
bool Desktop_View::mkDirectoryTree(const QList<Z88_Selection> &z88Selections)
{
    bool rc = false;

    if(!z88Selections.isEmpty()){
        /**
          * The root of the Desktop destination tree
          */
        QModelIndex desk_root;

        const QModelIndexList &deskSelections(selectedIndexes());

        if(deskSelections.isEmpty()){
            desk_root = m_DeskFileSystem->index(m_DeskFileSystem->rootPath(),0);
        }
        else{
            desk_root = deskSelections[0];
        }

        QListIterator<Z88_Selection> i(z88Selections);

        while(i.hasNext()){
            if(i.peekNext().getType() == Z88_DevView::type_Dir){
                rc = mkSubdir(i, desk_root);
                continue;
            }
            i.next();
        }
    }
    return rc;
}

/**
  * Make A Subdirectory on the host filesystem.
  * @param i is an interrator into the List of subdirectory names.
  * @param dst_root is the Base directory to in which to create directories.
  * @return false.
  */
bool Desktop_View::mkSubdir(QListIterator<Z88_Selection> &i, QModelIndex dst_root)
{
    QString curdir;
    bool rc = false;

    const Z88_Selection &z88sel(i.next());
    QString curpath(z88sel.getFspec());

    /**
     * Sanity Check
     */
    if(z88sel.getType() == Z88_DevView::type_Dir){

        QStringList pth;

        pth = curpath.split(QChar('/'),QString::SkipEmptyParts);

        if(pth.isEmpty()){
            return false;
        }

        curdir = pth[pth.count()-1];

        /**
          * Add a subdirectory to the Desktop Filesystem
          */
        dst_root = m_DeskFileSystem->mkdir(dst_root, curdir);

        while(i.hasNext()){
            if(i.peekNext().getType() == Z88_DevView::type_Dir){
                if(i.peekNext().getFspec().contains(curpath)){
                    mkSubdir(i, dst_root);
                    continue;
                }
                break;
            }
            i.next();
        }
    }
    return rc;
}

void Desktop_View::prependSubdirNames(QList<DeskTop_Selection> &desk_selections)
{
    QMutableListIterator<DeskTop_Selection> i(desk_selections);

    while(i.hasNext()){
       // qDebug() << "files=" << i.peekNext().getFspec() << "name=" << i.peekNext().getFname() << "type = " << i.peekNext().getType();
        if(i.peekNext().getType() == DeskTop_Selection::type_Dir){
            prependSubdirNames(i);
            continue;
        }
        i.next();
    }
}

void Desktop_View::prependSubdirNames(QMutableListIterator<DeskTop_Selection> &i)
{
    const DeskTop_Selection &desksel(i.next());
    QString curdir = desksel.getFname() + '/';

    QString curpath(desksel.getFspec());

    while(i.hasNext()){
        if(i.peekNext().getType() == DeskTop_Selection::type_Dir){
            if(i.peekNext().getFspec().contains(curpath)){
                i.peekNext().setSubdir(curdir);
                prependSubdirNames(i);
                continue;
            }
            break;
        }
        if(i.peekNext().getFspec().contains(curpath)){
            i.peekNext().setSubdir(curdir);
        }
        else{
            break;
        }
        i.next();
    }
}

bool Desktop_View::getSubdirFiles(const QModelIndex &idx)
{
    if(m_DeskFileSystem->isDir(idx)){
        if(m_DeskFileSystem->canFetchMore(idx)){
            m_DeskFileSystem->fetchMore(idx);
            return false;
        }
        m_Selections.append(DeskTop_Selection(m_DeskFileSystem->filePath(idx),
                                              m_DeskFileSystem->fileName(idx),
                                              DeskTop_Selection::type_Dir));
    }
    for(int x=0; x < m_DeskFileSystem->rowCount(idx); x++){
        if(m_DeskFileSystem->isDir(idx.child(x,0))){
            if(!getSubdirFiles(idx.child(x,0))){
                return false;
            }
        }
        else{
            m_Selections.append(DeskTop_Selection(m_DeskFileSystem->filePath(idx.child(x,0)),
                                                  m_DeskFileSystem->fileName(idx.child(x,0)),
                                                  DeskTop_Selection::type_File));
        }
    }
    return true;
}

/**
  * Items selected have changed call-back handler.
  */
void Desktop_View::ItemSelectionChanged(const QModelIndex &)
{
    const QModelIndexList &Selections(selectedIndexes());
    emit ItemSelectionChanged(Selections.count() / 3);
}

void Desktop_View::DirLoaded(const QString &path)
{
    if(m_recurse){

        QModelIndex midx = m_DeskFileSystem->index(path,0);

        for(int x=0; x < m_DeskFileSystem->rowCount(midx); x++){
            if(m_DeskFileSystem->isDir(midx.child(x,0)) &&
                    m_DeskFileSystem->canFetchMore(midx.child(x,0))){
                m_DeskFileSystem->fetchMore(midx.child(x,0));
                return;
            }
        }
        m_cthread.dirLoadComplete();
    }
}

void Desktop_View::DirLoadAborted()
{
    m_recurse = false;
}

/**
  * GUI Event handler,
  * @param obj is the object that had the change.
  * @param ev is the event that occured.
  * @return false.
  */
bool Desktop_View::eventFilter(QObject *, QEvent *ev)
{
    if(ev->type() == QEvent::KeyRelease || ev->type() == QEvent::Leave){
        const QModelIndexList &Selections(selectedIndexes());
        emit ItemSelectionChanged(Selections.count() / 3);
    }
    return false;
}
