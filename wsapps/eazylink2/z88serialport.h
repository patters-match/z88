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
#include <QThread>
#include "serialport.h"

/**
  * The Z88 Serial port Communication Class.
  * Implements the various file transfer, and information set/get operations.
  */
class Z88SerialPort : public QObject
{
    Q_OBJECT

public:
    Z88SerialPort();
    ~Z88SerialPort();

    enum retcode{
        rc_ok,
        rc_done,
        rc_timeout,
        rc_inv,
        rc_eof,
        rc_busy
    };

    bool open();
    bool open(QString pName);
    bool openXonXoff();
    bool openXonXoff(QString pName);
    void close();
    void setPortName(QString pName);                                // define the serial port device name
    bool isOpen();                                                  // Return Port Open state.

    bool helloZ88();                                                // poll for "hello" to Z88
    bool quitZ88();                                                 // quit EazyLink popdown on Z88
    bool translationOn();                                           // enable byte translations during transfer
    bool translationOff();                                          // disable byte translations during transfer
    bool linefeedConvOn();                                          // enable linefeed conversions during transfer
    bool linefeedConvOff();                                         // disable linefeed conversions during transfer
    bool reloadTranslationTable();                                  // remote reload translation table on Z88 EazyLink popdown
    bool setZ88Time();                                              // set Z88 date/time using PC local time
    bool isFileAvailable(QByteArray fileName);                      // ask if file exists on Z88 filing system
    bool createDir(const QString &pathName);                            // create directory on the Z88 filing system
    bool deleteFileDir(QByteArray fileName);                        // delete a file / directory on the Z88 filing system
    bool renameFileDir(QByteArray pathName, QByteArray fileName);   // rename a file / directory on the Z88 filing system
    bool setFileDateStamps(QByteArray fileName,
                           QByteArray createDate,
                           QByteArray updateDate);                  // set Create & Update date stamps of Z88 file
    bool sendFile(const QString &z88Filename, QString hostFilename);    // send a file to Z88 using EazyLink protocol

    bool impExpSendFile(QByteArray z88Filename, QString hostFilename); // send a file to Z88 using Imp/Export protocol
    bool impExpReceiveFiles(QString hostPath);                      // receive Z88 files from Imp/Export popdown
    retcode receiveFiles(const QString &z88Filenames, const QString &hostpath, const QString &destFspec);   // receive one or more files from Z88 to host using EazyLink protocol

    QByteArray getEazyLinkZ88Version();                             // receive string of EazyLink popdown version and protocol level
    QByteArray getZ88FreeMem();                                     // receive string of Z88 All Free Memory
    QByteArray getZ88DeviceFreeMem(QByteArray device);              // receive string of Free Memory from specific device
    QByteArray getFileSize(const QString &fileName);                // receive string of Z88 File size
    QList<QByteArray> getDevices();                                 // receive a list of Z88 Storage Devices
    QList<QByteArray> getZ88Time();                                 // receive string of current Z88 date & time
    QList<QByteArray> getRamDefaults();                             // receive default RAM & default Directory from Z88 Panel popdown
    QList<QByteArray> getDirectories(const QString &path);          // receive a list of Z88 Directories in <path>
    QList<QByteArray> getFilenames(const QString &path, bool &retc);            // receive a list of Z88 Filenames in <path>
    QList<QByteArray> getFileDateStamps(const QString &fileName);   // receive Create & Update date stamps of Z88 file

    QString getLastErrorString()const;                              // Get the Last Port Error string.
    int     getOpenErrno() const;                                   // Get the port Open Error number.
    QString getOpenErrorString() const;                             // Get the port Open Error String.

private slots:

private:

    SerialPort port;                                        // the device handle
    bool       portOpenStatus;                              // status of opened port; true = opened, otherwise false for closed
    bool       transmitting;                                // a transmission is current ongoing
    QString    portName;                                    // the default platform serial port device name
    QByteArray synchEazyLinkProtocol;                       // 1,1,2    constant
    QByteArray escEsc;                                      // ESC ESC  constant
    QByteArray escB;                                        // ESC B    constant
    QByteArray escN;                                        // ESC N    constant
    QByteArray escE;                                        // ESC E    constant
    QByteArray escF;                                        // ESC F    constant
    QByteArray escZ;                                        // ESC Z    constant
    QByteArray helloCmd;                                    // ESC a    EazyLink V4.4 Hello
    QByteArray quitCmd;                                     // ESC q    EazyLink V4.4 Quit
    QByteArray devicesCmd;                                  // ESC h    EazyLink V4.4 Device
    QByteArray directoriesCmd;                              // ESC d    EazyLink V4.4 Directory
    QByteArray filesCmd;                                    // ESC n    EazyLink V4.4 Files
    QByteArray transOnCmd;                                  // ESC t    EazyLink V4.4 Translation ON
    QByteArray transOffCmd;                                 // ESC T    EazyLink V4.4 Translation OFF
    QByteArray lfConvOnCmd;                                 // ESC c    EazyLink V4.4 Linefeed Conversion ON
    QByteArray lfConvOffCmd;                                // ESC C    EazyLink V4.4 Linefeed Conversion OFF
    QByteArray receiveFilesCmd;                             // ESC s    EazyLink V4.4 Receive one or more files from Z88
    QByteArray sendFilesCmd;                                // ESC b    EazyLink V4.4 Send one or more files from Z88
    QByteArray fileExistCmd;                                // ESC f    EazyLink V4.5 File exists
    QByteArray fileSizeCmd;                                 // ESC x    EazyLink V4.5 Get file size
    QByteArray versionCmd;                                  // ESC v    EazyLink V4.5 EazyLink Server Version and protocol level
    QByteArray fileDateStampCmd;                            // ESC u    EazyLink V4.5 Get create and update date stamp of Z88 file
    QByteArray setFileTimeStampCmd;                         // ESC U    EazyLink V4.5 Set create and update date stamp of Z88 file
    QByteArray deleteFileDirCmd;                            // ESC r    EazyLink V4.6 Delete file/dir on Z88.
    QByteArray reloadTraTableCmd;                           // ESC z    EazyLink V4.6 Reload Translation Table
    QByteArray ramDefaultCmd;                               // ESC g    EazyLink V4.7 Get Z88 RAM defaults
    QByteArray renameFileDirCmd;                            // ESC w    EazyLink V4.7 Rename file/directory on Z88
    QByteArray createDirCmd;                                // ESC y    EazyLink V4.7 Create directory path on Z88
    QByteArray getZ88TimeCmd;                               // ESC e    EazyLink V4.8 Get Z88 system Date/Time
    QByteArray setZ88TimeCmd;                               // ESC p    EazyLink V4.8 Set Z88 System Clock using PC system time
    QByteArray freeMemoryCmd;                               // ESC m    EazyLink V4.8 Get free memory for all RAM cards
    QByteArray freeMemDevCmd;                               // ESC M    EazyLink V4.8 Get free memory for specific device

    bool        getByte(unsigned char  &byte);              // Receive a byte from the Z88
    bool        synchronize();                              // Synchronize with Z88 before sending command
    bool        sendCommand(QByteArray cmd);                // Transmit ESC command to Z88
    bool        sendFilename(const QString &filename);          // Transmit ESC N <filename> ESC F sequence to Z88
    retcode     receiveFilename(QByteArray &fileName);      // Receive an ESC N <fileName> ESC F sequence from the Z88
    bool receiveListItems(QList<QByteArray> &list);  // Receive list of items (eg. devices, directories, filenames)
    char        xtod(char c);                               // hex to integer nibble function
};

#endif // Z88SERIALPORT_H
