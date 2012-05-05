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

#include <QListIterator>
#include<QIcon>
#include "z88_devview.h"

/**
  * the Z88 File Selection class constructor.
  * @param fspec is the file name.
  * @param type is the item type, dir or file.
  */
Z88_Selection::Z88_Selection(QString fspec, Z88_DevView::entryType type)
    :m_fspec(fspec),
    m_type(type)
{

}

/**
  * The Z88 Device View Class Constructor.
  * @param devname is the name of the Z88 Storage Device. ie :RAM.1
  * @param com_thread is the communications thread to use for I/O.
  * @param parent is the owner QWidget.
  */
Z88_DevView::Z88_DevView(const QString devname, CommThread &com_thread, QWidget *parent) :
    QTreeWidget(parent),
    m_cthread(com_thread),
    m_devname(devname),
    m_selChangeLock(false)
{
    setObjectName("Z88Tree");

    setColumnCount(4);

    QStringList hdrList;
    hdrList << "File or Directory" << "Size" << "Creation Date & Time" << "Modified Date & Time";

    setHeaderLabels(hdrList);
    setSortingEnabled (true);
    sortItems(0, Qt::AscendingOrder);
    setColumnWidth(0,200);
    setColumnWidth(1,68);
    setColumnWidth(2,163);
    setColumnWidth(3,163);


    setSelectionMode(QAbstractItemView::ExtendedSelection);
}

/**
  * Get the Z88 Device name, ie :RAM.1
  */
const QString &Z88_DevView::getDevname()
{
    return m_devname;
}

/**
  * Insert a Unique Z88 Filename or Directory names into the Tree view.
  * @param fspec_list is split list of a single file or dir, broken into parts.
  *  example a file :RAM.1/dir1/foo.txt would be 3 entries in the list ":RAM.1" "dir1" "foo.txt"
  * @param d_type is the type of entry, dir or file.
  * @param fsize is the Size of the file, or blank if not enabled.
  * @param fcreate_date is the File Creation date, or leave blank if not enabled.
  * @param fmod_date is the File Modified date, or leave blank if not enabled.
  * @return true on success.
  */
bool Z88_DevView::insertUniqueFspec(QStringList &fspec_list, entryType d_type,
                                    const QString &fsize, const QString &fcreate_date,
                                    const QString &fmod_date)
{
    QStringList entry;

    if(!fspec_list.isEmpty()){
        /**
         * Sanity Check to make sure the files belong in this device display
         */
        if(fspec_list[0] != m_devname){
            return false;
        }

        /**
          * Strip the Device name
          */
        fspec_list.removeFirst();

        if(!fspec_list.isEmpty()){
            QList<QTreeWidgetItem *> treeItem;
            treeItem = findItems(fspec_list[0], Qt::MatchExactly, 0);

            /**
              * If the Dir or file is not already in the tree
              */
            if(treeItem.isEmpty()){
                entry << fspec_list[0];

               /**
                 * Only Append Time and date of a file, not a dir
                 */
                if(fspec_list.count() == 1){
                    if(!fsize.isEmpty()){
                        entry << fsize;
                    }
                    else{
                        entry << " ";
                    }

                    if(!fcreate_date.isEmpty()){
                        entry << fcreate_date;
                    }
                    else{
                        entry << " ";
                    }

                    if(!fmod_date.isEmpty()){
                        entry << fmod_date;
                    }
                    else{
                        entry << " ";
                    }
                }
                QTreeWidgetItem *qt = new QTreeWidgetItem(entry, d_type);

                /**
                  * Set the Icon for the file type
                  */
                set_EntryIcon(qt, fspec_list[0], d_type);

                addTopLevelItem(qt);

                fspec_list.removeFirst();

                if(fspec_list.isEmpty()){
                    return true;
                }
                return insertFspecList(qt, fspec_list, d_type, fsize, fcreate_date, fmod_date);
            }

            /**
              * Parent dir exists
              */
            fspec_list.removeFirst();

            if(!fspec_list.isEmpty()){
                return insertFspecList(treeItem[0], fspec_list, d_type, fsize, fcreate_date, fmod_date);
            }
        }
    }
    return false;
}

/**
  * Insert a Z88 Filename or Directory names into the Tree view.
  * @param parent is the QTreeWidgetItem to inser the Child after.
  * @param fspec_list is split list of a single file or dir, broken into parts.
  *  example a file :RAM.1/dir1/foo.txt would be 3 entries in the list ":RAM.1" "dir1" "foo.txt"
  * @param d_type is the type of entry, dir or file.
  * @param fsize is the Size of the file, or blank if not enabled.
  * @param fcreate_date is the File Creation date, or leave blank if not enabled.
  * @param fmod_date is the File Modified date, or leave blank if not enabled.
  * @return true on success.
  */
bool Z88_DevView::insertFspecList(QTreeWidgetItem *parent, QStringList &fspec_list, entryType d_type,
                                  const QString &fsize, const QString &fcreate_date, const QString &fmod_date )
{
    QStringList entry;
    QTreeWidgetItem *qt;

    int count;
    if(!fspec_list.isEmpty()){

        count = parent->childCount();
        /**
          * Search all the Children Here for Duplicates
          */
        for(int idx = 0; idx < count; idx++){
            if(parent->child(idx)->text(0) == fspec_list[0]){
                fspec_list.removeFirst();

                if(fspec_list.isEmpty()){
                    return false;
                }
                return insertFspecList(parent->child(idx), fspec_list, d_type, fsize, fcreate_date, fmod_date);
            }
        }

        entry << fspec_list[0];

        /**
          * Only insert size and date for files.
          */
        if(fspec_list.count() == 1){
            if(!fsize.isEmpty()){
                entry << fsize;
            }
            else{
                entry << " ";
            }

            if(!fcreate_date.isEmpty()){
                entry << fcreate_date;
            }
            else{
                entry << " ";
            }

            if(!fmod_date.isEmpty()){
                entry << fmod_date;
            }
            else{
                entry << " ";
            }
        }

        qt = new QTreeWidgetItem(entry, d_type);

        /**
          * Set the Icon for the file type
          */
        set_EntryIcon(qt, fspec_list[0], d_type);

        parent->addChild(qt);

        fspec_list.removeFirst();

        if(fspec_list.isEmpty()){
            return true;
        }
        return insertFspecList(qt, fspec_list, d_type, fsize, fcreate_date, fmod_date);
    }
    return false;
}

/**
  * Get the Fully qualified file name for the specified Item
  * @param item is the QTreeWidgetItem
  * @paramfspec is filled in file spec class.
  * @return the File Spec
  */
const Z88_Selection &Z88_DevView::getItemFspec(QTreeWidgetItem *item, Z88_Selection &fspec)const
{
    QString fname;
    fspec.m_fspec = m_devname + "/";

    bool rootdev = false;

    if(item){
        fspec.m_type = (item->type() == type_File) ? type_File : type_Dir;
    }
    else{
        rootdev = true;
        fspec.m_type = Z88_DevView::type_Dir;
    }

    /**
      * Build the Full filename by backing up to the top of the tree
      */
    while(item){
        fname.prepend(item->text(0));
        item = item->parent();
        if(!item)break;
        fname.prepend("/");
    }
    fspec.m_fspec += fname;

    /**
      * If the Selection is just the Z88 Storage device root,
      * Don't append a trailing '/'
      */
    if(!rootdev && fspec.m_type == Z88_DevView::type_Dir ){
        fspec.m_fspec += "/";
    }
    return fspec;
}

/**
  * Get a list of Sub Items below the specified item entry.
  * @param item is the top level selection item.
  * @param selections is the list to be filled in.
  * @return the list of selections.
  */
const QList<Z88_Selection> &Z88_DevView::getItemChildren(QTreeWidgetItem *item, QString &parent, QList<Z88_Selection> &selections, bool depth_first = false) const
{
    QTreeWidgetItem *child;
    int childcount = item->childCount();


    for(int x=0; x < childcount; x++){
        child = item->child(x);

        QString par = parent + "/";
        par += child->text(0);

        Z88_Selection z88Selection;

        z88Selection.setRelFspec(par);

        getItemFspec(child, z88Selection);

        if(!depth_first) {
            selections.append(z88Selection);
        }

        if(child->childCount()){
            getItemChildren(child, par, selections);
        }

        if(depth_first) {
            selections.append(z88Selection);
        }

    }
    return selections;
}

/**
  * Add an Icon based on the file type.
  * @param qt is the q tree widget item.
  * @param fname is the file name
  * @param d_type is the type of entry, dir or file
  */
void Z88_DevView::set_EntryIcon(QTreeWidgetItem *qt, const QString &fname, entryType d_type)
{
    QString ext;

    int idx = fname.lastIndexOf('.');

    if(idx > -1){
        ext= fname.mid(idx + 1,3);
    }

    /**
      * Set the Icon for the file type
      */
    if(d_type == type_Dir){
        qt->setIcon(0,QIcon(":/images/folder_icon"));
    }
    else{
        if(!QString::compare(ext, "bin",Qt::CaseInsensitive )){
            qt->setIcon(0,QIcon(":/images/bin_icon"));
            return;
        }
        if(!QString::compare(ext, "epr",Qt::CaseInsensitive )){
            qt->setIcon(0,QIcon(":/images/bin_icon"));
            return;
        }
        if(ext >= "0" && ext <= "63"){
            qt->setIcon(0,QIcon(":/images/bin_icon"));
            return;
        }
        if(!QString::compare(ext, "bas",Qt::CaseInsensitive )){
            qt->setIcon(0,QIcon(":/images/bas_icon"));
            return;
        }
        if(!QString::compare(ext, "txt",Qt::CaseInsensitive )){
            qt->setIcon(0,QIcon(":/images/txt_icon"));
            return;
        }
        if(!QString::compare(ext, "zip",Qt::CaseInsensitive )){
            qt->setIcon(0,QIcon(":/images/zip_icon"));
            return;
        }
        if(!QString::compare(ext, "cli",Qt::CaseInsensitive )){
            qt->setIcon(0,QIcon(":/images/cli_icon"));
            return;
        }
        qt->setIcon(0,QIcon(":/images/file_icon"));
    }
}

/**
  * Get the List of selected Files and Directories.
  * @param recurse set to true to get all the sub files within selected directories.
  * @return the list of fully qualified file names and directories.
  */
QList<Z88_Selection> *Z88_DevView::getSelection(bool recurse)
{
    typedef QTreeWidgetItem * qti_p;

    /**
      * if No files are selected, then selectall
      */

    if(recurse && selectedItems().isEmpty()){
        m_selChangeLock = true;
        selectAll();
    }

    const QList<qti_p> &selections(selectedItems());
    Z88_Selection z88Selection;

    QListIterator<qti_p> i(selections);

    m_Selections.clear();

    if(!selections.isEmpty()){
        while(i.hasNext()){
            qti_p item(i.next());
            QString parent = item->text(0);
            z88Selection.setRelFspec(parent);
            getItemFspec(item, z88Selection);
            m_Selections.append(z88Selection);
            if(recurse){
                /**
                  * Recurse the Directory tree if any
                  */
                getItemChildren(item, parent, m_Selections);
            }
        }
    }
    else{
        /**
          * Nothing selected, so get the Device name
          */
        getItemFspec(NULL, z88Selection);
        m_Selections.append(z88Selection);
    }

    if(m_selChangeLock){
        clearSelection();
        m_selChangeLock = false;
    }

    return &m_Selections;
}

