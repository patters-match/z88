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
#ifndef Z88_DEVVIEW_H
#define Z88_DEVVIEW_H

#include <QWidget>
#include <QTreeWidget>
#include <QBoxLayout>
#include "commthread.h"

class Z88_Selection;

/**
  * The Z88 Storage Device Tree View Class.
  * Inherits from QTreeWidget Class.
  */
class Z88_DevView : public QTreeWidget
{
    Q_OBJECT
public:
    explicit Z88_DevView(const QString devname, CommThread &com_thread, QWidget *parent = 0);
    
    const QString &getDevname();

    enum entryType{
        type_Dir = QTreeWidgetItem::UserType + 1,
        type_File
    };

    bool insertUniqueFspec(QStringList &fspec_list,
                           entryType d_type,
                           const QString &fsize,
                           const QString &fcreate_date,
                           const QString &fmod_date);

    QList<Z88_Selection> *getSelection(bool recurse);

    bool isSelChangeLocked(){return m_selChangeLock;}

    bool set_FreeSpace(uint32_t free_bytes);
    bool set_TotalSize(uint32_t total_bytes);

    bool get_FreeSpace(uint32_t &free_bytes, uint32_t &tot_size);
    bool get_TotalSize(uint32_t &total_bytes);

signals:
    
public slots:

protected:

    bool insertFspecList(QTreeWidgetItem *parent,
                         QStringList &fspec_list,
                         entryType d_type,
                         const QString &fsize,
                         const QString &fcreate_date,
                         const QString &fmod_date);

    const Z88_Selection &getItemFspec(QTreeWidgetItem *item, Z88_Selection &fspec) const;

    const QList<Z88_Selection> &getItemChildren(QTreeWidgetItem *item,
                                                const QString &parent, QList<Z88_Selection> &selections, bool depth_first)const;

    void set_EntryIcon(QTreeWidgetItem *qt, const QString &fname, entryType d_type);

    void SaveCollapseAll();

    void RestoreCollapseAll();

    /**
      * The Communications Thread.
      */
    CommThread &m_cthread;

    QString    m_devname;

    QList<Z88_Selection> m_Selections;

    QList<QTreeWidgetItem *> m_ExpandedList;

    static const uint32_t SZ_NOT_AVAIL = -1;

    uint32_t    m_devSize;

    uint32_t    m_devFree;

    /**
      * Flag to disable recursive events call-backs
      * when auto-selection of copying entire Storage
      * Device to the Desktop.
      */
    bool m_selChangeLock;
};

/**
  * The Z88 Selected File Attribute Class.
  * Container class to hold various attributes of a selected file on the Z88 View.
  */
class Z88_Selection{
public:
    Z88_Selection(QTreeWidgetItem *item, const QString &dev_name);

    const QString &getFspec()const {return m_fspec;}
    const Z88_DevView::entryType &getType() const{return m_type;}

    void setRelFspec(const QString &relfspec){m_relFspec = relfspec;}
    const QString &getRelFspec()const {return m_relFspec;}

    QTreeWidgetItem *getQtreeItem(){ return m_QtreeItem;}

    friend class Z88_DevView;

protected:

    const QString &setItemFspec(QTreeWidgetItem *item, const QString &devname);

    /**
      * Selection file spec
      */
    QString m_fspec;

    /**
      * The Relative File Spec
      */
    QString m_relFspec;

    /**
      * Selection type (dir or file)
      */
    Z88_DevView::entryType m_type;

    /**
      * Pointer to the QTreeItem in the Z88 View
      */
    QTreeWidgetItem *m_QtreeItem;

};

#endif // Z88_DEVVIEW_H
