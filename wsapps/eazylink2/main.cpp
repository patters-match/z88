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

#include <QCoreApplication>
#include <QtGui/QApplication>
#include <QtCore/QTime>
#include <QtCore/QTextStream>
#include <QSplashScreen>

#include "mainwindow.h"
#include "z88serialport.h"

int main(int argc, char *argv[])
{
    QCoreApplication::setApplicationVersion("1.0 alpha1");
    QCoreApplication::setOrganizationDomain("cambridgez88.jira.com");

    QApplication a(argc, argv);
    Z88SerialPort p;
    MainWindow w(p);

#if 0
    if ( p.open() == true ) {
        QTime timeout;
        bool rc;
        bool connected = false;

        while(!connected){
            for(int retry_cnt=1; retry_cnt < 3; retry_cnt++){
                qDebug() << "Trying to Connect to Z88..." << endl;

                rc = p.helloZ88();

                // Give EazyLink time to switch to hardware handshaking on the serial port..
                timeout = QTime::currentTime().addSecs(1);
                while(QTime::currentTime() < timeout) {};

                if(rc){
                    connected = true;
                    break;
                }
                qDebug() << "Connection attempt:" << retry_cnt << "Failed!" << endl;
            }

            if(!rc){
                p.close();
                QMessageBox::StandardButton reply;
                reply = QMessageBox::critical(NULL, QString("Communication Error."),
                                                    "Failed to Communicate with the Z88. "
                                                    "Please check connection, and make sure "
                                                    "you are running the EazyLink Client on the Z88.",
                                                    QMessageBox::Abort | QMessageBox::Retry);
                if(reply == QMessageBox::Abort){
                    exit(-1);
                }
                p.open();
            }
        }

        qDebug() << "Z88 EazyLink version / protocol = " << p.getEazyLinkZ88Version();
        qDebug() << "Z88 current time = " << p.getZ88Time();
        qDebug() << "Synch Z88 time using PC time (if necessary): " << p.syncZ88Time();
        qDebug() << "Z88 current time = " << p.getZ88Time();
        qDebug() << "Z88 Free Memory = " << p.getZ88FreeMem();
        qDebug() << "Z88 Free Memory for :RAM.1 = " << p.getZ88DeviceFreeMem("1");
        qDebug() << "Z88 Devices = " << p.getDevices();
        qDebug() << "Z88 RAM Defaults = " << p.getRamDefaults();
        qDebug() << "Z88 RAM Directories for :RAM.1 = " << p.getDirectories(":RAM.0//*");
        //qDebug() << "Z88 Files in RAM.1/dir1 = " << p.getFilenames(":RAM.0/dir1/*");
        //qDebug() << "Z88 Files in RAM.1 = " << p.getFilenames(":RAM.0//*");
        //qDebug() << "Z88 Files in EPR.3 = " << p.getFilenames(":EPR.3");

        qDebug() << "Date stamps of ':RAM.0/Readme.txt' = " << p.getFileDateStamps(":RAM.0/Readme.txt");
        qDebug() << "Set timestamps of ':RAM.0/Readme.txt' = 01/09/1999 09:05:01 01/10/2011 18:05:17: "
                 << p.setFileDateStamps(":RAM.0/Readme.txt", "01/09/1999 09:05:01", "01/10/2011 18:05:17");
        qDebug() << "File size of ':RAM.0/Readme.txt' = " << p.getFileSize(":RAM.0/Readme.txt");

        qDebug() << "Creating directory ':RAM.1/tempdir1/tempdir2': " << p.createDir(":RAM.1/tempdir1/tempdir2");
        qDebug() << "Rename directory ':RAM.1/tempdir1/tempdir2' to 'tempdir3': " << p.renameFileDir(":RAM.1/tempdir1/tempdir2", "tempdir3");
        qDebug() << "Deleting directory ':RAM.1/tempdir1/tempdir3': " << p.deleteFileDir(":RAM.1/tempdir1/tempdir3");

        qDebug() << "Deleting directory ':RAM.1/tempdir1': " << p.deleteFileDir(":RAM.1/tempdir1");

//        qDebug() << p.sendFile(":RAM.0/romupdate.bas", "/home/gbs/z88/z88apps/romupdate/romupdate.bas");
//        qDebug() << p.sendFile(":RAM.0/romupdate.crc", "/home/gbs/z88/z88apps/romupdate/romupdate.crc");
//        qDebug() << p.receiveFiles(":RAM.0/*", "/home/gbs");

      //  /Users/oernohaz/files/z88/forever-201
  //      qDebug() << p.sendFile(":RAM.1/forever.62", "/Users/oernohaz/files/z88/forever-201/forever.62");
  //      qDebug() << p.sendFile(":RAM.1/forever.63", "/Users/oernohaz/files/z88/forever-201/forever.63");
  //      qDebug() << p.sendFile(":RAM.1/zetriz.63", "/Users/oernohaz/files/z88/bitbucket/z88/z88apps/zetriz/zetriz.63");

        //qDebug() << p.sendFile(":RAM.1/romupdate.cfg", "/Users/oernohaz/files/z88/bitbucket/z88/z88apps/romupdate/romupdate.cfg");
       // qDebug() << p.receiveFiles(":RAM.1/*", "/Users/oernohaz/files/z88/bitbucket/z88/rx_dir");
      //  qDebug() << p.impExpSendFile(":RAM.1/romupdate.txt", "/Users/oernohaz/files/z88/bitbucket/z88/z88apps/romupdate/readme.txt");
        // qDebug() << p.impExpReceiveFiles("/home/gbs");

       // p.quitZ88();

        p.close();
    }
#endif

    w.show();
    return a.exec();
}
