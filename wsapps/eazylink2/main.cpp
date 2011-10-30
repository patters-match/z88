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

#include <QtGui/QApplication>
#include <QtCore/QTime>
#include <QtCore/QTextStream>
#include "mainwindow.h"
#include "z88serialport.h"

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    MainWindow w;
    Z88SerialPort p;

    if ( p.open() == true ) {

        p.helloZ88();

        // Give EazyLink time to switch to hardware handshaking on the serial port..
        QTime timeout = QTime::currentTime().addSecs(2);
        while(QTime::currentTime() < timeout);

        qDebug() << "Z88 EazyLink version / protocol = " << p.getEazyLinkZ88Version();
        qDebug() << "Z88 current time = " << p.getZ88Time();
        qDebug() << "Set Z88 time using PC time = " << p.setZ88Time();
        qDebug() << "Z88 current time = " << p.getZ88Time();
        qDebug() << "Z88 Free Memory = " << p.getZ88FreeMem();
        qDebug() << "Z88 Free Memory for :RAM.1 = " << p.getZ88DeviceFreeMem("1");
        qDebug() << "Z88 Devices = " << p.getDevices();
        qDebug() << "Z88 RAM Defaults = " << p.getRamDefaults();
        qDebug() << "Z88 RAM Directories for :RAM.1 = " << p.getDirectories(":RAM.1//*");
        qDebug() << "Z88 Files in EPR.3 = " << p.getFilenames(":EPR.3");
        qDebug() << "Date stamps of ':RAM.1/Readme.txt' = " << p.getFileDateStamps(":RAM.1/Readme.txt");
        qDebug() << "Set timestamps of ':RAM.1/Readme.txt' = 01/09/1999 09:05:01 01/10/2011 18:05:17: " <<
                  p.setFileDateStamps(":RAM.1/Readme.txt", "01/09/1999 09:05:01", "01/10/2011 18:05:17");
        qDebug() << "File size of ':RAM.1/Readme.txt' = " << p.getFileSize(":RAM.1/Readme.txt");
        qDebug() << "Creating directory ':RAM.1/tempdir1/tempdir2': " << p.createDir(":RAM.1/tempdir1/tempdir2");
        qDebug() << "Rename directory ':RAM.1/tempdir1/tempdir2' to 'tempdir3': " << p.renameFileDir(":RAM.1/tempdir1/tempdir2", "tempdir3");
        qDebug() << "Deleting directory ':RAM.1/tempdir1/tempdir3': " << p.deleteFileDir(":RAM.1/tempdir1/tempdir3");
        qDebug() << "Deleting directory ':RAM.1/tempdir1': " << p.deleteFileDir(":RAM.1/tempdir");

        qDebug() << p.sendFile(":RAM.0/romupdate.bas", "/home/gbs/z88/z88apps/romupdate/romupdate.bas");
        qDebug() << p.sendFile(":RAM.0/romupdate.crc", "/home/gbs/z88/z88apps/romupdate/romupdate.crc");

          // p.quitZ88();

        p.close();
    }

    // TO DO: Implement GUI!
    // w.show();
    // return a.exec();
    return 1;
}
