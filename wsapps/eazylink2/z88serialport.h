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

#ifndef Z88SERIALPORT_H
#define Z88SERIALPORT_H

#include <QtCore/QTextStream>
#include <QtCore/QDebug>
#include "serialport.h"

class Z88SerialPort
{

public:
    Z88SerialPort();
    bool open();
    bool open(QString pName);
    bool openXonXoff();
    bool openXonXoff(QString pName);
    void close();
    void setPortName(QString pName);                                // define the serial port device name

    bool helloZ88();                                                // poll for "hello" to Z88
    bool quitZ88();                                                 // quit EazyLink popdown on Z88
    bool translationOn();                                           // enable byte translations during transfer
    bool translationOff();                                          // disable byte translations during transfer
    bool linefeedConvOn();                                          // enable linefeed conversions during transfer
    bool linefeedConvOff();                                         // disable linefeed conversions during transfer
    bool reloadTranslationTable();                                  // remote reload translation table on Z88 EazyLink popdown
    bool setZ88Time();                                              // set Z88 date/time using PC local time
    bool isFileAvailable(QByteArray fileName);                      // ask if file exists on Z88 filing system
    bool createDir(QByteArray pathName);                            // create directory on the Z88 filing system
    bool deleteFileDir(QByteArray fileName);                        // delete a file / directory on the Z88 filing system
    bool renameFileDir(QByteArray pathName, QByteArray fileName);   // rename a file / directory on the Z88 filing system
    bool setFileDateStamps(QByteArray fileName,
                           QByteArray createDate,
                           QByteArray updateDate);                  // set Create & Update date stamps of Z88 file
    bool sendFile(QByteArray z88Filename, QString hostFilename);    // send a file to Z88 using EazyLink protocol

    bool impExpSendFile(QByteArray z88Filename, QString hostFilename); // send a file to Z88 using Imp/Export protocol
    bool impExpReceiveFiles(QString hostPath);                      // receive Z88 files from Imp/Export popdown
    bool receiveFiles(QByteArray z88Filenames, QString hostpath);   // receive one or more files from Z88 to host using EazyLink protocol

    QByteArray getEazyLinkZ88Version();                             // receive string of EazyLink popdown version and protocol level
    QByteArray getZ88FreeMem();                                     // receive string of Z88 All Free Memory
    QByteArray getZ88DeviceFreeMem(QByteArray device);              // receive string of Free Memory from specific device
    QByteArray getFileSize(QByteArray fileName);                    // receive string of Z88 File size
    QList<QByteArray> getDevices();                                 // receive a list of Z88 Storage Devices
    QList<QByteArray> getZ88Time();                                 // receive string of current Z88 date & time
    QList<QByteArray> getRamDefaults();                             // receive default RAM & default Directory from Z88 Panel popdown
    QList<QByteArray> getDirectories(QByteArray path);              // receive a list of Z88 Directories in <path>
    QList<QByteArray> getFilenames(QByteArray path);                // receive a list of Z88 Filenames in <path>
    QList<QByteArray> getFileDateStamps(QByteArray fileName);       // receive Create & Update date stamps of Z88 file

private:
    SerialPort  port;                                       // the device handle
    bool        portOpenStatus;                             // status of opened port; true = opened, otherwise false for closed
    bool        transmitting;                               // a transmission is current ongoing
    QString     portName;                                   // the default platform serial port device name
    QByteArray  escEsc;                                     // ESC ESC constant
    QByteArray  escB;                                       // ESC B constant
    QByteArray  escN;                                       // ESC N constant
    QByteArray  escE;                                       // ESC E constant
    QByteArray  escF;                                       // ESC F constant
    QByteArray  escZ;                                       // ESC Z constant

    bool        getByte(unsigned char  &byte);              // Receive a byte from the Z88
    bool        synchronize();                              // Synchronize with Z88 before sending command
    bool        sendCommand(QByteArray cmd);                // Transmit ESC command to Z88
    bool        sendFilename(QByteArray filename);          // Transmit ESC N <filename> ESC F sequence to Z88
    bool        receiveFilename(QByteArray &fileName);      // Receive an ESC N <fileName> ESC F sequence from the Z88
    void        receiveListItems(QList<QByteArray> &list);  // Receive list of items (eg. devices, directories, filenames)
    char        xtod(char c);                               // hex to integer nibble function
};

#endif // Z88SERIALPORT_H
