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

#include "desktop_view.h"
#include "z88_devview.h"

/**
  * DeskTop Selection Constructor
  * @param fspec is the Fully qualified file path and name.
  * @param type is the type of entry. ie Dir or File.
  */
DeskTop_Selection::DeskTop_Selection(QString fspec, DeskTop_Selection::entryType type)
  :m_fspec(fspec),
  m_type(type)
{
}

/**
  * Destop View Contstructor.
  * @parm parent is the Owner Qwidget
  */
Desktop_View::Desktop_View(QWidget *parent) :
    QTreeView(parent)
{
    m_DeskFileSystem = new QFileSystemModel();

    m_DeskFileSystem->setRootPath(QDir::homePath());

    setModel(m_DeskFileSystem);

    setRootIndex(m_DeskFileSystem->index(QDir::homePath()));

    m_DeskFileSystem->setResolveSymlinks(true);

    connect(this, SIGNAL(clicked(const QModelIndex &)), this, SLOT(ItemSelectionChanged(const QModelIndex &)));

    installEventFilter(this);

}

/**
  * Get a List of the selected file(s)
  * @return the list of filenames.
  */
QList<DeskTop_Selection> &Desktop_View::getSelection()
{

    const QModelIndexList &Selections(selectedIndexes());

    m_Selections.clear();

    if(!Selections.isEmpty()){

        QListIterator<QModelIndex> i(Selections);

        int count = Selections.count() / 3;

        while(count){
            const QModelIndex &idx(i.next());

            DeskTop_Selection::entryType type = (m_DeskFileSystem->isDir(idx)) ?
                        DeskTop_Selection::type_Dir : DeskTop_Selection::type_File;

            m_Selections.append(DeskTop_Selection(m_DeskFileSystem->filePath(idx), type));

            count--;
        }
    }
    else{
        m_Selections.append(DeskTop_Selection(m_DeskFileSystem->rootPath(), DeskTop_Selection::type_Dir));
    }

    return m_Selections;
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

        curdir = curpath.mid(1 + curpath.lastIndexOf('/'));

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

/**
  * Items selected have changed call-back handler.
  */
void Desktop_View::ItemSelectionChanged(const QModelIndex &)
{
    const QModelIndexList &Selections(selectedIndexes());
    emit ItemSelectionChanged(Selections.count() / 3);
}

/**
  * GUI Event handler,
  * @param obj is the object that had the change.
  * @param ev is the event that occured.
  * @return false.
  */
bool Desktop_View::eventFilter(QObject *obj, QEvent *ev)
{
    if(ev->type() == QEvent::KeyRelease || ev->type() == QEvent::Leave){
        const QModelIndexList &Selections(selectedIndexes());
        emit ItemSelectionChanged(Selections.count() / 3);
    }
    return false;
}
