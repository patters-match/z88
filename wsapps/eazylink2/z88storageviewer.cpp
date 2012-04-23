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

#include <qdebug.h>
#include<QEvent>

#include "z88storageviewer.h"

/**
  * The Z88 Stroage Viewer Class Constructor.
  * @parm com_thread is the communications thread to use for I/O
  * @param parent is the owning QWidget class.
  */
Z88StorageViewer::Z88StorageViewer(CommThread &com_thread, QWidget *parent) :
    QTabWidget(parent),
    m_cthread(com_thread)
{
    memset(&m_Ramdevices[0], 0, sizeof(m_Ramdevices));
    memset(&m_Eprdevices[0], 0, sizeof(m_Eprdevices));

    connect(&m_cthread,
            SIGNAL(Z88Devices_result(QList<QByteArray> *)),
            this,
            SLOT(Z88Devices_result(QList<QByteArray> *)));

    connect(&m_cthread,
            SIGNAL(Z88Dir_result(const QString &, QList<QByteArray> *)),
            this,
            SLOT(Z88Dir_result(const QString &, QList<QByteArray> *)));

    connect(&m_cthread,
            SIGNAL(Z88FileSpeclist_result(const QString &, QList<Z88FileSpec> *)),
            this,
            SLOT(Z88FileSpeclist_result(const QString &, QList<Z88FileSpec> *)));

    connect(this,SIGNAL(currentChanged(int)),this,SLOT(changedSelected_device(int)));

    installEventFilter(this);
}

/**
  * Start the thread to Get the Entire Tree of Filenames on the Z88
  * @param ena_fs set to true to enable reading file sizes.
  * @param ena_ts set to true to retreive file Dates also.
  * @return true on success.
  */
bool Z88StorageViewer::getFileTree(bool ena_fs, bool ena_ts)
{
    return m_cthread.getZ88FileSystemTree(ena_fs, ena_ts);
}

/**
  * Append a Unique Fully Qualified path/filename to the Tree View
  * @param filespec is the File Info Structure, with size and dates. ex ":RAM.1/dir1/file.txt"
  * @param d_type is the Type of entry. File or Dir.
  * @return the count of unique entries inserted
  */
int Z88StorageViewer::appendUniqueFile(const Z88FileSpec &filespec, Z88_DevView::entryType d_type)
{
    QStringList pth;
    int dnum;
    int cnt = 0;

    pth = filespec.getFilename().split(QChar('/'),QString::SkipEmptyParts);

    if(pth[0].size() == 6){
        QChar anum(pth[0].at(5));
        if(anum == '-'){
            dnum = 4;
        }
        else{
            dnum = anum.toAscii() - '0';
        }

        if(pth[0].contains("RAM")){
            if(m_Ramdevices[dnum]->insertUniqueFspec(pth,
                                                     d_type,
                                                     filespec.getFileSize(),
                                                     filespec.getFileCreateDate(),
                                                     filespec.getFileModDate()))
            {
                cnt++;
            }
            return cnt;
        }

        if(pth[0].contains("EPR")){
            if(m_Eprdevices[dnum]->insertUniqueFspec(pth,
                                                     d_type,
                                                     filespec.getFileSize(),
                                                     filespec.getFileCreateDate(),
                                                     filespec.getFileModDate()))
            {
                cnt++;
            }
        }
    }
    return cnt;
}

/**
  * get the Selected Device based on the tab selected.
  * @return a pointer to the Z88 View Object of the selected tab.
  */
Z88_DevView *Z88StorageViewer::getSelectedDevice()
{
    int idx = currentIndex();
    int dnum;
    QString devname;

    if(idx > -1){
        devname = tabText(idx);

        QChar anum(devname.at(5));
        if(anum == '-'){
            dnum = 4;
        }
        else{
            dnum = anum.toAscii() - '0';
        }

        if(devname.contains("RAM")){
            return m_Ramdevices[dnum];
        }

        if(devname.contains("EPR")){
            return m_Eprdevices[dnum];
        }
    }
    return NULL;
}

/**
  * Get all the Selected Files in for the Selected Device.
  * @param recurse set this to true to get a list of files in the selected subdirectories
  * @return a list of the Selected files and directories.
  */
QList<Z88_Selection> *Z88StorageViewer::getSelection(bool recurse)
{
    Z88_DevView *z88dev = getSelectedDevice();
    if(z88dev){
        if(!z88dev->isSelChangeLocked()){
            return z88dev->getSelection(recurse);
        }
    }
    return NULL;
}

/**
  * Get the name of the Selected Storage Device. ie :Ram.1
  * @return the filename of the Selected storage device.
  */
const QString &Z88StorageViewer::getSelectedDeviceName()
{
    static const QString none("None");
    Z88_DevView *dv = getSelectedDevice();
    return dv ?  dv->getDevname() : none;
}

/**
  * the Result call-back for retreiving available Z88 Storage Devices.
  * Gets called by the Comms Thread.
  * @param devlist is the list of devices available.
  */
void Z88StorageViewer::Z88Devices_result(QList<QByteArray> *devlist)
{
    /**
      * Clean Up Previous Entries if any
      */
    clear();

    for(int x = 0; x < DEVCNT; x++){
        if(m_Ramdevices[x]){
            delete m_Ramdevices[x];
            m_Ramdevices[x] = NULL;
        }
        if(m_Eprdevices[x]){
            delete m_Eprdevices[x];
            m_Eprdevices[x] = NULL;
        }
    }

    QListIterator<QByteArray> i(*devlist);

    while(i.hasNext()){
        QString devname(i.next());

        if(devname.size() == 6){
            int dnum = devname.at(5).toAscii();

            Z88_DevView *dview(NULL);

            if( devname.contains("RAM")){
                dview = new Z88_DevView(devname, m_cthread);

                if(dnum == '-'){
                    m_Ramdevices[4] = dview;
                }
                else{
                    m_Ramdevices[dnum - '0'] = dview;
                }
            }

            if( devname.contains("EPR")){
                dview = new Z88_DevView(devname, m_cthread);

                m_Eprdevices[dnum - '0'] = dview;
            }
            if(dview){
                connect(dview,SIGNAL(itemSelectionChanged()),this,SLOT(changedSelected_file()));
                connect(dview,SIGNAL(itemClicked( QTreeWidgetItem *, int )),
                        this,SLOT(	itemClicked ( QTreeWidgetItem *, int )));
            }
        }
    }

    /**
      * Display the Ram Devices First
      */
    for(int x = 0; x < DEVCNT; x++){
        if(m_Ramdevices[x]){
            addTab(m_Ramdevices[x], m_Ramdevices[x]->getDevname());
        }
    }

    /**
      * Next Display the Eprom Devices
      */
    for(int x = 0; x < DEVCNT; x++){
        if(m_Eprdevices[x]){
            addTab(m_Eprdevices[x], m_Eprdevices[x]->getDevname());
        }
    }
}

/**
  * The Result call-back from the Get Dir List command.
  * @param devname is the name of the device the directories are contained.
  * @param dirlist is the list of directories available on the storage device.
  */
void Z88StorageViewer::Z88Dir_result(const QString &devname, QList<QByteArray> *dirlist)
{
    QListIterator<QByteArray> i(*dirlist);

    while(i.hasNext()){
        QString dirname(i.next());

        if(dirname.contains(devname)){
            appendUniqueFile(Z88FileSpec(dirname), Z88_DevView::type_Dir);
        }
    }
}

/**
  * The Result call-back for the get Filenames command.
  * @param devname is the name of the device the directories are contained.
  * @param filespeclist is the List of files on the storage device.
  */
void Z88StorageViewer::Z88FileSpeclist_result(const QString &, QList<Z88FileSpec> *filespeclist)
{
    QListIterator<Z88FileSpec> i(*filespeclist);

    while(i.hasNext()){
        appendUniqueFile(Z88FileSpec(i.next()), Z88_DevView::type_File);
    }
}

/**
  * The Selected Device tab changed call-back.
  * @param index is the Tab index of the newly selected tab.
  */
void Z88StorageViewer::changedSelected_device(int)
{
    QList<Z88_Selection> *selections(getSelection(false));

    if(selections){
        emit ItemSelectionChanged(selections->count());
    }
}

/**
  * The Selected File(s) changed call-back event.
  * Called when the user selects or un-selects files in the tree view.
  */
void Z88StorageViewer::changedSelected_file()
{
    QList<Z88_Selection> *selections(getSelection(false));

    if(selections){
        emit ItemSelectionChanged(selections->count());
    }
}

/**
  * The Z88 File or Directory was selected or re-selected, so Process the enable/disable
  * Transfer button as if a new Selection was made.
  * @param item is the entry that was selected.
  * @param column is the selected column
  */
void Z88StorageViewer::itemClicked(QTreeWidgetItem *, int )
{
    changedSelected_file();
}

/**
  * The GUI Event Handler.
  * @param obj is the object that caused the event call-back.
  * @param ev is the event that occured.
  * @return false.
  */
bool Z88StorageViewer::eventFilter(QObject *, QEvent *ev)
{
    if(ev->type() == QEvent::KeyRelease || ev->type() == QEvent::Leave){
        QList<Z88_Selection> *selections(getSelection(false));

        if(selections){
            emit ItemSelectionChanged(selections->count());
        }
    }
    return false;
}



