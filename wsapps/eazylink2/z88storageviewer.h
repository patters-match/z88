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

#ifndef Z88STORAGEVIEWER_H
#define Z88STORAGEVIEWER_H

#include <QTabWidget>
#include "z88_devview.h"

class MainWindow;

static const int DEVCNT = 5;

/**
  * The Z88 Tabbed Storage Viewer.
  * This class handles displaying a tabbed view of the available storage devices on the Z88.
  * Inherits from the QTabWidget class, to resemble the Host OS file browser.
  */
class Z88StorageViewer : public QTabWidget
{
    Q_OBJECT
public:

    explicit Z88StorageViewer(CommThread &com_thread, MainWindow *parent = 0);
    
    bool getFileTree(bool ena_fs = false, bool ena_ts = false);
    int appendUniqueFile(const Z88FileSpec &filespec, Z88_DevView::entryType d_type);

    QList<Z88_Selection> *getSelection(bool recurse);
    const QString &getSelectedDeviceName();
    bool refreshSelectedDeviceView();

signals:
    void ItemSelectionChanged(int);
    
public slots:
    void Z88Devices_result(QList<QByteArray> *devlist);
    void Z88Dir_result(const QString &devname, QList<QByteArray> *dirlist);
    void Z88FileSpeclist_result(const QString &devname, QList<Z88FileSpec> *filespeclist);
    void changedSelected_device(int index);
    void changedSelected_file();
    void itemClicked ( QTreeWidgetItem * item, int column );

protected:

    /**
      * Get a pointer to the Selected device tab, file tree viewer.
      */
    Z88_DevView *getSelectedDevice();

    /**
      * User interface event Handler, ie mouse in, out, etc.
      */
    bool eventFilter(QObject *, QEvent *ev);

    /**
      * Ram Storage Devices
      */
    Z88_DevView *m_Ramdevices[DEVCNT];

    /**
      * Eprom Storage Devices
      */
    Z88_DevView *m_Eprdevices[DEVCNT];

    /**
      * The Communications Thread.
      */
    CommThread  &m_cthread;

    MainWindow *m_mainWindow;

};

#endif // Z88STORAGEVIEWER_H
