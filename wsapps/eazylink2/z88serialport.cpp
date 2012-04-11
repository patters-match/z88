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
#include <errno.h>
#include <QtCore/QCoreApplication>
#include <QtCore/QEventLoop>
#include <QtCore/QList>
#include <QtCore/QDateTime>
#include <QtCore/QTime>
#include <QtCore/QFile>
#include <QtCore/QByteArray>
#include "z88serialport.h"


Z88SerialPort::Z88SerialPort()
{
    transmitting = portOpenStatus = false;
    escEsc = QByteArray( (char []) { 27, 27}, 2);
    escB = QByteArray( (char []) { 27, 'B'}, 2);
    escN = QByteArray( (char []) { 27, 'N'}, 2);
    escE = QByteArray( (char []) { 27, 'E'}, 2);
    escF = QByteArray( (char []) { 27, 'F'}, 2);
    escZ = QByteArray( (char []) { 27, 'Z'}, 2);

    // define some default serial port device names for the specific platform
#ifdef Q_OS_WIN32
    portName = "COM6";
#else
#ifdef Q_OS_MAC
    //QString portName = "/dev/tty.Bluetooth-Modem";
    //portName = "/dev/cu.Bluetooth-Modem";
    portName = "/dev/tty.USA19Hfa13P1.1"; ///dev/tty.USA19Hfd12P1.1";
#else
    portName = "/dev/ttyUSB0";
#endif
#endif

    qDebug() << "Defining default device: " << portName;
//AbortTransfer

}

Z88SerialPort::~Z88SerialPort()
{

}


bool Z88SerialPort::open()
{
    return open(portName); // use default serial port device name (or previously specified port name)
}


bool Z88SerialPort::openXonXoff()
{
    return openXonXoff(portName); // use default serial port device name (or previously specified port name)
}


bool Z88SerialPort::open(QString pName)
{
    if (portOpenStatus == true) {
        // close connection if currently open...
        port.close();
        portOpenStatus = false;
    }

    portName = pName;
    port = SerialPort(portName);

    if (!port.open(QIODevice::ReadWrite)) {
        qDebug() << "!!! Port" << port.portName() << "could not be opened!!!";
        qDebug() << "Error:" << port.lastError();
        portOpenStatus = false;
        return false;
    } else {
        portOpenStatus = true;
        port.setBaudRateFromNumber(9600);
        port.setDataBits(SerialPort::EightDataBits);
        port.setParity(SerialPort::NoParity);
        port.setStopBits(SerialPort::OneStopBit);
        port.setFlowControl(SerialPort::HardwareFlowControl);
        port.setAutoFlushOnWrite(true);
/*
        qDebug() << "SerialPort Settings:";
        qDebug() << "  Port name          :" << port.portName();
        qDebug() << "  Baud rate          :" << port.baudRate();
        qDebug() << "  Data bits          :" << port.dataBits();
        qDebug() << "  Parity             :" << port.parity();
        qDebug() << "  Stop bits          :" << port.stopBits();
        qDebug() << "  Flow control       :" << port.flowControl();
        qDebug() << "  Auto flush on write:" << port.autoFlushOnWrite();
        qDebug() << "  Status             :" << port.lineStatus();
        qDebug();
*/
        return true;
    }
}

QString Z88SerialPort::getLastErrorString()const
{
    return port.errorString();
}

int Z88SerialPort::getOpenErrno() const {
    return port.m_errno;
}

QString Z88SerialPort::getOpenErrorString() const {
    switch(port.m_errno){
    case EACCES:
        return "Access Denied";
        break;
    case EBUSY:
        return "Port in use";
    case ENODEV:
        return "Unsupported Device";
    default:
        return "Unknown Error";
    }
}

bool Z88SerialPort::openXonXoff(QString pName)
{
    if (portOpenStatus == true) {
        // close connection if currently open...
        port.close();
        portOpenStatus = false;
    }

    portName = pName;
    port = SerialPort(portName);

    if (!port.open(QIODevice::ReadWrite)) {
        qDebug() << "!!! Port" << port.portName() << "could not be opened!!!";
        qDebug() << "Error:" << port.lastError();
        portOpenStatus = false;
        return false;
    } else {
        portOpenStatus = true;

        port.setBaudRateFromNumber(9600);
        port.setDataBits(SerialPort::EightDataBits);
        port.setParity(SerialPort::NoParity);
        port.setStopBits(SerialPort::OneStopBit);
        port.setFlowControl(SerialPort::XonXoffFlowControl);
        port.setAutoFlushOnWrite(true);
/*
        qDebug() << "SerialPort Settings:";
        qDebug() << "  Port name          :" << port.portName();
        qDebug() << "  Baud rate          :" << port.baudRate();
        qDebug() << "  Data bits          :" << port.dataBits();
        qDebug() << "  Parity             :" << port.parity();
        qDebug() << "  Stop bits          :" << port.stopBits();
        qDebug() << "  Flow control       :" << port.flowControl();
        qDebug() << "  Auto flush on write:" << port.autoFlushOnWrite();
        qDebug() << "  Status             :" << port.lineStatus();
        qDebug();
*/
        return true;
    }
}


void Z88SerialPort::setPortName(QString pName)
{
    portName = pName;
}

bool Z88SerialPort::isOpen()
{
    return port.isOpen();
}

void Z88SerialPort::close()
{
    if (portOpenStatus == true) {
        // close connection if currently open...
        port.close();
        portOpenStatus = false;
    }
}


/*****************************************************************************
 *      EazyLink Server V4.4
 *      Send a 'hello' to the Z88 and return true if Yes, or false if No
 *****************************************************************************/
bool Z88SerialPort::helloZ88()
{
    QByteArray helloCmd = QByteArray( (char []) { 27, 'a'}, 2); // EazyLink V4.4 Hello Request Command

    if ( sendCommand(helloCmd) == true) {
        if (transmitting == true) {
            qDebug() << "helloZ88(): Transmission already ongoing with Z88 - aborting...";
        } else {
            QByteArray helloResponse = port.read(2);
            transmitting = false;

            if ( helloResponse.count() != 2) {
                qDebug() << "helloZ88(): Bad response from Z88!";
                port.clearLastError();
            } else {
                if (helloResponse.at(1) == 'Y') {
                    qDebug() << "helloZ88(): Z88 responded 'hello'!";
                    return true;        // hello response correctly received from Z88
                }
            }
        }
    }

    return false;
}


/*****************************************************************************
 *      EazyLink Server V4.4
 *      Send a 'quit' to the Z88 and return true if Z88 responded
 *****************************************************************************/
bool Z88SerialPort::quitZ88()
{
    QByteArray quitCmd = QByteArray( (char []) { 27, 'q'}, 2); // EazyLink V4.4 Quit Request Command

    if ( sendCommand(quitCmd) == true) {
        if (transmitting == true) {
            qDebug() << "quitZ88(): Transmission already ongoing with Z88 - aborting...";
        } else {
            QByteArray quitResponse = port.read(2);
            transmitting = false;

            if ( quitResponse.count() != 2) {
                qDebug() << "quitZ88(): Bad response from Z88!";
                port.clearLastError();
            } else {
                if (quitResponse.at(1) == 'Y') {
                    qDebug() << "quitZ88(): Z88 responded 'Goodbye'!";
                    return true;        // quit response correctly received from Z88
                }
            }
        }
    }

    return false;
}


/*****************************************************************************
 *      EazyLink Server V4.4
 *      Get Z88 devices.
 *****************************************************************************/
QList<QByteArray> Z88SerialPort::getDevices()
{
    QByteArray devicesCmd = QByteArray( (char []) { 27, 'h'}, 2); // EazyLink V4.4 Device Request Command
    QList<QByteArray> deviceList;

    if ( sendCommand(devicesCmd) == true) {
        if (transmitting == true) {
            qDebug() << "getDevices(): Transmission already ongoing with Z88 - aborting...";
        } else {
            // receive device elements into list
            receiveListItems(deviceList);
            transmitting = false;
        }
    }

    return deviceList;
}


/*****************************************************************************
 *      EazyLink Server V4.4
 *      Get directories in defined path, directories are returned in list
 *****************************************************************************/
QList<QByteArray> Z88SerialPort::getDirectories(const QString &path)
{
    QList<QByteArray> directoriesList;
    QByteArray directoriesCmd = QByteArray( (char []) { 27, 'd'}, 2);
    QByteArray escZ = QByteArray( (char []) { 27, 'Z'}, 2);

    directoriesCmd.append(path);
    directoriesCmd.append(escZ);
    if ( sendCommand(directoriesCmd) == true) {
        if (transmitting == true) {
            qDebug() << "getDirectories(): Transmission already ongoing with Z88 - aborting...";
        } else {
            // receive device elements into list
            receiveListItems(directoriesList);
            transmitting = false;
        }
    }

    return directoriesList;
}


/*****************************************************************************
 *      EazyLink Server V4.4
 *      Get filename in defined path, filenames are returned in list
 *****************************************************************************/
QList<QByteArray> Z88SerialPort::getFilenames(const QString &path)
{
    QByteArray filesCmd = QByteArray( (char []) { 27, 'n'}, 2);
    QByteArray escZ = QByteArray( (char []) { 27, 'Z'}, 2);
    QList<QByteArray> filenamesList;

    filesCmd.append(path);
    filesCmd.append(escZ);
    if ( sendCommand(filesCmd) == true) {
        if (transmitting == true) {
            qDebug() << "getFilenames(): Transmission already ongoing with Z88 - aborting...";
        } else {
            // receive device elements into list
            receiveListItems(filenamesList);
            transmitting = false;
        }
    }

    return filenamesList;
}


/*****************************************************************************
 *      EazyLink Server V4.4
 *      Enable translation mode during file transfer
 *****************************************************************************/
bool Z88SerialPort::translationOn()
{
    QByteArray transOnCmd = QByteArray( (char []) { 27, 't'}, 2);

    if ( sendCommand(transOnCmd) == true) {
        return true;  // Z88 now has translations enabled
    } else {
        return false;
    }
}


/*****************************************************************************
 *      EazyLink Server V4.4
 *      Disable translation mode during file transfer
 *****************************************************************************/
bool Z88SerialPort::translationOff()
{
    QByteArray transOffCmd = QByteArray( (char []) { 27, 'T'}, 2);

    if ( sendCommand(transOffCmd) == true) {
        return true;  // Z88 now has translations disabled
    } else {
        return false;
    }
}


/*****************************************************************************
 *      EazyLink Server V4.4
 *      Enable linefeed conversion mode during file transfer
 *****************************************************************************/
bool Z88SerialPort::linefeedConvOn()
{
    QByteArray lfConvOnCmd = QByteArray( (char []) { 27, 'c'}, 2);

    if ( sendCommand(lfConvOnCmd) == true) {
        return true;  // Z88 now has linefeed conversion enabled
    } else {
        return false;
    }
}


/*****************************************************************************
 *      EazyLink Server V4.6
 *      Remote updating of translation table
 *      (reload and install translation table from Z88 filing system)
 *****************************************************************************/
bool Z88SerialPort::reloadTranslationTable()
{
    QByteArray reloadTraTableCmd = QByteArray( (char []) { 27, 'z'}, 2);

    if ( sendCommand(reloadTraTableCmd) == true) {
        return true;  // Z88 now has reload translation table.
    } else {
        return false;
    }
}


/*****************************************************************************
 *      EazyLink Server V4.4
 *      Disable linefeed conversion mode during file transfer
 *****************************************************************************/
bool Z88SerialPort::linefeedConvOff()
{
    QByteArray lfConvOffCmd = QByteArray( (char []) { 27, 'C'}, 2);

    if ( sendCommand(lfConvOffCmd) == true) {
        return true;  // Z88 now has linefeed conversion disabled
    } else {
        return false;
    }
}


/*****************************************************************************
 *      EazyLink Server V4.5
 *      Get EazyLink Server (main) Version and protocol level
 *****************************************************************************/
QByteArray Z88SerialPort::getEazyLinkZ88Version()
{
    QByteArray versionCmd = QByteArray( (char []) { 27, 'v'}, 2);
    QByteArray versionString;
    QList<QByteArray> versionList;

    versionString.clear();

    if ( sendCommand(versionCmd) == true) {
        if (transmitting == true) {
            qDebug() << "getEazyLinkZ88Version(): Transmission already ongoing with Z88 - aborting...";
        } else {
            // receive version string
            receiveListItems(versionList);
            transmitting = false;

            if (versionList.count() > 0) {
                versionString = versionList.at(0); // the "list" has only one item...
            }
        }
    }

    return versionString;
}


/*****************************************************************************
 *      EazyLink Server V4.7
 *      Get Z88 RAM defaults
 *****************************************************************************/
QList<QByteArray> Z88SerialPort::getRamDefaults()
{
    QByteArray ramDefaultCmd = QByteArray( (char []) { 27, 'g'}, 2);
    QList<QByteArray> ramDefaultList;

    if ( sendCommand(ramDefaultCmd) == true) {
        if (transmitting == true) {
            qDebug() << "getRamDefaults(): Transmission already ongoing with Z88 - aborting...";
        } else {
            // receive device elements into list
            receiveListItems(ramDefaultList);
            transmitting = false;
        }
    }

    return ramDefaultList;
}


/*****************************************************************************
 *      EazyLink Server V4.5
 *      Respond ESC 'Y' if file exists on Z88 (return true)
 *****************************************************************************/
bool Z88SerialPort::isFileAvailable(QByteArray filename)
{
    QByteArray fileExistCmd = QByteArray( (char []) { 27, 'f'}, 2);
    QByteArray escZ = QByteArray( (char []) { 27, 'Z'}, 2);

    fileExistCmd.append(filename);
    fileExistCmd.append(escZ);
    if ( sendCommand(fileExistCmd) == true) {
        if (transmitting == true) {
            qDebug() << "isFileAvailable(): Transmission already ongoing with Z88 - aborting...";
        } else {
            QByteArray fileExistResponse = port.read(2);
            transmitting = false;

            if ( fileExistResponse.count() != 2) {
                qDebug() << "isFileAvailable(): Bad response from Z88!";
                port.clearLastError();
            } else {
                if (fileExistResponse.at(1) == 'Y') {
                    return true;        // Z88 responded that file exists
                }
            }
        }
    }

    return false; // no serial port communication or file not available..
}


/*****************************************************************************
 *      EazyLink Server V4.5
 *      Get create and update date stamp of Z88 file
 *****************************************************************************/
QList<QByteArray> Z88SerialPort::getFileDateStamps(const QString &filename)
{
    QByteArray fileDateStampCmd = QByteArray( (char []) { 27, 'u'}, 2);
    QByteArray escZ = QByteArray( (char []) { 27, 'Z'}, 2);
    QList<QByteArray> dateStampList;

    fileDateStampCmd.append(filename);
    fileDateStampCmd.append(escZ);
    if ( sendCommand(fileDateStampCmd) == true) {
        if (transmitting == true) {
            qDebug() << "getFileDateStamps(): Transmission already ongoing with Z88 - aborting...";
        } else {
            // receive date stamps into list
            receiveListItems(dateStampList);
            transmitting = false;
        }
    }

    return dateStampList;
}


/*****************************************************************************
 *      EazyLink Server V4.5
 *      Get size of Z88 file (in bytes)
 *****************************************************************************/
QByteArray Z88SerialPort::getFileSize(const QString &filename)
{
    QByteArray fileDateStampCmd = QByteArray( (char []) { 27, 'x'}, 2);
    QList<QByteArray> fileSizeList;
    QByteArray fileSizeString;

    fileDateStampCmd.append(filename);
    fileDateStampCmd.append(escZ);
    if ( sendCommand(fileDateStampCmd) == true) {
        if (transmitting == true) {
            qDebug() << "getFileSize(): Transmission already ongoing with Z88 - aborting...";
        } else {
            // receive date stamps into list
            receiveListItems(fileSizeList);
            transmitting = false;

            if (fileSizeList.count() > 0) {
                fileSizeString = fileSizeList.at(0); // the "list" has only one item...
            }

        }
    }

    return fileSizeString;
}


/*****************************************************************************
 *      EazyLink Server V4.8
 *      Get Z88 system Date/Time (Clock)
 *****************************************************************************/
QList<QByteArray> Z88SerialPort::getZ88Time()
{
    QByteArray getZ88TimeCmd = QByteArray( (char []) { 27, 'e'}, 2);
    QList<QByteArray> timeList;

    if ( sendCommand(getZ88TimeCmd) == true) {
        if (transmitting == true) {
            qDebug() << "getZ88Time(): Transmission already ongoing with Z88 - aborting...";
        } else {
            // receive time stamp into list
            receiveListItems(timeList);
            transmitting = false;
        }
    }

    return timeList;
}


/*****************************************************************************
 *      EazyLink Server V4.8
 *      Set Z88 System Clock using PC system time
 *****************************************************************************/
bool Z88SerialPort::setZ88Time()
{
    QByteArray setZ88TimeCmd = QByteArray( (char []) { 27, 'p'}, 2);
    QDateTime dt = QDateTime(QDateTime::currentDateTime());

    setZ88TimeCmd.append(dt.toString("dd/MM/yyyy"));
    setZ88TimeCmd.append(escN);
    setZ88TimeCmd.append(dt.toString("hh:mm:ss"));
    setZ88TimeCmd.append(escZ);

    if ( sendCommand(setZ88TimeCmd) == true) {
        if (transmitting == true) {
            qDebug() << "setZ88Time(): Transmission already ongoing with Z88 - aborting...";
        } else {
            QTime timeout = QTime::currentTime().addSecs(5);
            while(QTime::currentTime() < timeout) {
                // wait max 5 secs for a response, because Z88 uses some seconds to set it's clock...
                if (port.bytesAvailable() > 0)
                    break;
            }

            QByteArray setZ88TimeResponse = port.read(2);
            transmitting = false;

            if ( setZ88TimeResponse.count() != 2) {
                qDebug() << "setZ88Time(): Bad response from Z88!";
                port.clearLastError();
            } else {
                if (setZ88TimeResponse.at(1) == 'Y') {
                    return true;        // Z88 time was set
                }
            }
        }
    }

    return false;
}


/*****************************************************************************
 *      EazyLink Server V4.5
 *      Set create and update date stamp of Z88 file
 *****************************************************************************/
bool Z88SerialPort::setFileDateStamps(QByteArray filename, QByteArray createDate, QByteArray updateDate)
{
    QByteArray setFileTimeStampCmd = QByteArray( (char []) { 27, 'U'}, 2);

    setFileTimeStampCmd.append(filename);
    setFileTimeStampCmd.append(escN);
    setFileTimeStampCmd.append(createDate);
    setFileTimeStampCmd.append(escN);
    setFileTimeStampCmd.append(updateDate);
    setFileTimeStampCmd.append(escZ);

    if ( sendCommand(setFileTimeStampCmd) == true) {
        if (transmitting == true) {
            qDebug() << "setZ88Time(): Transmission already ongoing with Z88 - aborting...";
        } else {
            QTime timeout = QTime::currentTime().addSecs(5);
            while(QTime::currentTime() < timeout) {
                // wait max 5 secs for a response, because Z88 uses a little time to set the time stamps on the file
                if (port.bytesAvailable() > 0)
                    break;
            }

            QByteArray setFileTimeStampResponse = port.read(2);
            transmitting = false;

            if ( setFileTimeStampResponse.count() != 2) {
                qDebug() << "setFileDateStamps(): Bad response from Z88!";
                port.clearLastError();
            } else {
                if (setFileTimeStampResponse.at(1) == 'Y') {
                    return true;        // time stamps were set
                }
            }
        }
    }

    return false;
}


/*****************************************************************************
 *      EazyLink Server V4.7
 *      Create directory path on Z88.
 *****************************************************************************/
bool Z88SerialPort::createDir(QByteArray pathName)
{
    QByteArray createDirCmd = QByteArray( (char []) { 27, 'y'}, 2);

    createDirCmd.append(pathName);
    createDirCmd.append(escZ);

    if ( sendCommand(createDirCmd) == true) {
        if (transmitting == true) {
            qDebug() << "createDir(): Transmission already ongoing with Z88 - aborting...";
        } else {
            QTime timeout = QTime::currentTime().addSecs(5);
            while(QTime::currentTime() < timeout) {
                QCoreApplication::processEvents(QEventLoop::AllEvents, 100);
                // wait max 5 secs for a response, because Z88 can use some time creating a directory on the Z88
                if (port.bytesAvailable() > 0)
                    break;
            }

            QByteArray createDirResponse = port.read(2);
            transmitting = false;

            if ( createDirResponse.count() != 2) {
                qDebug() << "createDir(): Bad response from Z88!";
                port.clearLastError();
            } else {
                if (createDirResponse.at(1) == 'Y') {
                    return true;        // file/dir were created
                }
            }
        }
    }

    return false;
}


/*****************************************************************************
 *      EazyLink Server V4.6
 *      Delete file/dir on Z88.
 *****************************************************************************/
bool Z88SerialPort::deleteFileDir(QByteArray filename)
{
    QByteArray deleteFileDirCmd = QByteArray( (char []) { 27, 'r'}, 2);

    deleteFileDirCmd.append(filename);
    deleteFileDirCmd.append(escZ);

    if ( sendCommand(deleteFileDirCmd) == true) {
        if (transmitting == true) {
            qDebug() << "deleteFileDir(): Transmission already ongoing with Z88 - aborting...";
        } else {
            QTime timeout = QTime::currentTime().addSecs(30);
            while(QTime::currentTime() < timeout) {
                QCoreApplication::processEvents(QEventLoop::AllEvents, 100);
                // wait max 30 secs for a response, because Z88 can use quite a long time deleting a big file on the Z88
                if (port.bytesAvailable() > 0)
                    break;
            }

            QByteArray deleteFileDirResponse = port.read(2);
            transmitting = false;

            if ( deleteFileDirResponse.count() != 2) {
                qDebug() << "deleteFileDir(): Bad response from Z88!";
                port.clearLastError();
            } else {
                if (deleteFileDirResponse.at(1) == 'Y') {
                    return true;        // file/dir were deleted
                }
            }
        }
    }

    return false;
}


/*****************************************************************************
 *      EazyLink Server V4.7
 *      Rename file/directory on Z88.
 *****************************************************************************/
bool Z88SerialPort::renameFileDir(QByteArray pathName, QByteArray fileName)
{
    QByteArray renameFileDirCmd = QByteArray( (char []) { 27, 'w'}, 2);

    renameFileDirCmd.append(pathName);  // filename (with explicit path)
    renameFileDirCmd.append(escN);
    renameFileDirCmd.append(fileName);  // short filename (12+3, without path)
    renameFileDirCmd.append(escZ);

    if ( sendCommand(renameFileDirCmd) == true) {
        if (transmitting == true) {
            qDebug() << "renameFileDir(): Transmission already ongoing with Z88 - aborting...";
        } else {
            QTime timeout = QTime::currentTime().addSecs(5);
            while(QTime::currentTime() < timeout) {
                QCoreApplication::processEvents(QEventLoop::AllEvents, 100);
                // wait max 5 secs for a response, because Z88 can use some time renaming a file on the Z88
                if (port.bytesAvailable() > 0)
                    break;
            }

            QByteArray renameFileDirResponse = port.read(2);
            transmitting = false;

            if ( renameFileDirResponse.count() != 2) {
                qDebug() << "renameFileDir(): Bad response from Z88!";
                port.clearLastError();
            } else {
                if (renameFileDirResponse.at(1) == 'Y') {
                    return true;        // file/dir were renamed
                }
            }
        }
    }

    return false;
}


/*****************************************************************************
 *      EazyLink Server V4.8
 *      Get free memory for all RAM cards
 *****************************************************************************/
QByteArray Z88SerialPort::getZ88FreeMem()
{
    QByteArray freeMemoryCmd = QByteArray( (char []) { 27, 'm'}, 2);
    QList<QByteArray> freeMemoryList;
    QByteArray freeMemoryString;

    if ( sendCommand(freeMemoryCmd) == true) {
        if (transmitting == true) {
            qDebug() << "getZ88FreeMem(): Transmission already ongoing with Z88 - aborting...";
        } else {
            // receive free memory string into list
            receiveListItems(freeMemoryList);
            transmitting = false;

            if (freeMemoryList.count() > 0) {
                freeMemoryString = freeMemoryList.at(0); // the "list" has only one item...
            }

        }
    }

    return freeMemoryString;
}


/*****************************************************************************
 *      EazyLink Server V4.8
 *      Get free memory for specific device
 *****************************************************************************/
QByteArray Z88SerialPort::getZ88DeviceFreeMem(QByteArray device)
{
    QByteArray freeMemDevCmd = QByteArray( (char []) { 27, 'M'}, 2);
    QList<QByteArray> freeMemoryList;
    QByteArray freeMemoryString;

    freeMemDevCmd.append(device);
    freeMemDevCmd.append(escZ);

    if ( sendCommand(freeMemDevCmd) == true) {
        if (transmitting == true) {
            qDebug() << "getZ88DeviceFreeMem(): Transmission already ongoing with Z88 - aborting...";
        } else {
            // receive free memory string into list
            receiveListItems(freeMemoryList);
            transmitting = false;

            if (freeMemoryList.count() > 0) {
                freeMemoryString = freeMemoryList.at(0); // the "list" has only one item...
            }

        }
    }

    return freeMemoryString;
}


/*****************************************************************************
 *      Send a file to Z88 using Imp/Export protocol (Imp/Export popdown batch mode)
 *      Caller must ensure that the filename applies to Z88 standard
 *****************************************************************************/
bool Z88SerialPort::impExpSendFile(QByteArray z88Filename, QString hostFilename)
{
    QFile hostFile(hostFilename);
    QByteArray byte, escBSequence;

    if (hostFile.exists() == true) {
        if (transmitting == true) {
            qDebug() << "impExpSendFile(): Transmission already ongoing with Z88 - aborting...";
        } else {
            if (hostFile.open(QIODevice::ReadOnly) == true) {
                // qDebug() << "impExpSendFile(): Transmitting '" << hostFilename << "' file...";

                // file opened for read-only...
                if (sendFilename(z88Filename) == true) {
                    transmitting = true;

                    while (!hostFile.atEnd()) {
                        byte = hostFile.read(1);
                        if ( byte.count() == 1) {
                            // 7e not 7f
                            if (byte[0] < (char) 0x20 || byte[0] > (char) 0x7e) {
                                // send ESC B HEX sequence
                                escBSequence.clear();
                                escBSequence.append(escB);
                                escBSequence.append(byte.toHex());
                                if ( port.write(escBSequence) != escBSequence.length() ) {
                                    // not all bytes were transferred...
                                    qDebug() << "impExpSendFile(): ESC B xx not transmitted properly to Z88!";
                                    port.clearLastError();
                                    hostFile.close();
                                    transmitting = false;
                                    return false;
                                }
                            } else {
                                if ( port.write(byte) != byte.length() ) {
                                    qDebug() << "impExpSendFile(): Command not transmitted properly to Z88!";
                                    port.clearLastError();
                                    hostFile.close();
                                    transmitting = false;
                                    return false;
                                }
                            }
                        } else
                            break;
                    }
                }

                hostFile.close();
                port.write(escE);

                // file transmitted to Imp/Export popdown...
                transmitting = false;

                return true;
            } else {
                qDebug() << "impExpSendFile(): Couldn't open File for reading - aborting...";
            }
        }

    } else {
        qDebug() << "impExpSendFile(): File doesn't exist - aborting...";
    }

    return false;
}


/*****************************************************************************
 *      Receive one or more files from Z88 using EazyLink protocol
 *      Received files will be stored at <hostPath>
 *****************************************************************************/
Z88SerialPort::retcode Z88SerialPort::receiveFiles(const QString &z88Filenames, QString hostPath)
{
    QByteArray receiveFilesCmd = QByteArray( (char []) { 27, 's'}, 2);
    QByteArray z88Filename, remoteFile;
    unsigned char byte;

    if (transmitting == true) {
        qDebug() << "receiveFiles(): Transmission already ongoing with Z88 - aborting...";
    } else {
        receiveFilesCmd.append(z88Filenames);
        receiveFilesCmd.append(escZ);

        if ( sendCommand(receiveFilesCmd) == true) {
            if (transmitting == true) {
                qDebug() << "receiveFiles(): Transmission already ongoing with Z88 - aborting...";
            } else {
                // receive files from Z88...

                // wait a little to give Z88 time to find files...
                QTime timeout = QTime::currentTime().addSecs(5);
                while(QTime::currentTime() < timeout) {
                    if (port.bytesAvailable() > 0)
                        break;
                }

                if (port.bytesAvailable() > 0) {
                    while(1) {

                        /**
                          * Get the Filename from the Z88
                          */
                        retcode rc = receiveFilename(z88Filename);
                        switch(rc){
                            case rc_ok:
                                break;
                            case rc_done: //ESC Z
                                return rc_done;
                            case rc_timeout:
                            case rc_inv:
                            case rc_eof:
                            case rc_busy:
                                return rc;
                        }

                        QString hostFilename = QString(hostPath).append((z88Filename.constData()+6));
                        QFile hostFile(hostFilename);

                        if (hostFile.exists() == true) {
                            // automatically replace existing host file
                            hostFile.remove();
                        }

                        if (transmitting == true) {
                            // qDebug() << "receiveFiles(): Transmission already ongoing with Z88 - aborting...";
                            return rc_busy;
                        } else {
                            if (hostFile.open(QIODevice::WriteOnly) == true) {
                                qDebug() << "receiveFiles(): Receiving '" << z88Filename << "' to '" << hostFilename << "' file...";

                                remoteFile.clear();
                                // file opened for writing..
                                bool recievingFile = true;
                                while (recievingFile) {                                   
                                    if (getByte(byte) == true) {
                                        switch(byte) {
                                            case 27:
                                                getByte(byte);

                                                switch(byte) {
                                                    case 'E':
                                                        hostFile.write(remoteFile);     // write entire collected remote file contents to host file
                                                        hostFile.close();
                                                        recievingFile = false;
                                                        break;

                                                    case 27:
                                                        remoteFile.append( (char) 27);
                                                        break;

                                                    case 'Z':
                                                        return rc_done;                    // end of receive files z88 - exit

                                                    default:
                                                        recievingFile = false;
                                                        break;                          // illegal escape command - skip data...
                                                }
                                                break;

                                            default:
                                                remoteFile.append(byte);
                                        }
                                    } else {
                                        qDebug() << "get byte failed";
                                        // receiveing data stream has stopped...
                                        return rc_inv;
                                    }
                                }
                            } else {
                                qDebug() << "receiveFiles(): Couldn't open File '" << hostFilename << "' for writing - aborting...";
                            }
                        }
                    }
                }
            }
        }
    }

    return rc_inv;
}


/*****************************************************************************
 *      Receive one or more files from Z88 using Imp/Export protocol (Imp/Export popdown batch mode)
 *      Received files will be stored at <hostPath>
 *****************************************************************************/
bool Z88SerialPort::impExpReceiveFiles(QString hostPath)
{
    unsigned char byte;
    QByteArray z88Filename, remoteFile, hexBytes;

    while(1) {
        switch(receiveFilename(z88Filename)){
            case rc_ok:
                break;
            case rc_done: //ESC Z
                return true;
            case rc_timeout:
            case rc_inv:
            case rc_eof:
            case rc_busy:
                return false;
        }
        //if (receiveFilename(z88Filename) == false)
        //    // timeout or ESC Z received, exit waiting for files...
        //    return false;

        QString hostFilename = QString(hostPath).append((z88Filename.constData()+6));
        QFile hostFile(hostFilename);

        if (hostFile.exists() == true) {
            // automatically replace existing host file
            hostFile.remove();
        }

        if (transmitting == true) {
            // qDebug() << "impExpReceiveFiles(): Transmission already ongoing with Z88 - aborting...";
            return false;
        } else {
            if (hostFile.open(QIODevice::WriteOnly) == true) {
                qDebug() << "impExpReceiveFiles(): Receiving '" << z88Filename << "' to '" << hostFilename << "' file...";

                remoteFile.clear();
                // file opened for writing..
                bool recievingFile = true;
                while (recievingFile) {
                    if (getByte(byte) == true) {
                        switch(byte) {
                            case 27:
                                getByte(byte);
                                switch(byte) {
                                    case 'E':
                                        hostFile.write(remoteFile);     // write entire collected remote file contents to host file
                                        hostFile.close();
                                        recievingFile = false;
                                        break;

                                    case 'B':
                                        hexBytes = port.read(2);
                                        if ( hexBytes.count() == 2) {
                                            byte = xtod(hexBytes[1])*16 + xtod(hexBytes[0]);
                                        } else {
                                            byte = 0;
                                        }

                                        remoteFile.append(byte);
                                        break;

                                    case 'Z':
                                        return true;                    // end of receive files z88 - exit

                                    default:
                                        recievingFile = false;
                                        break;                          // illegal escape command - skip data...
                                }
                                break;

                            default:
                                remoteFile.append(byte);
                        }
                    } else {
                        // receiveing data stream has stopped...
                        return false;
                    }
                }
            } else {
                qDebug() << "impExpReceiveFiles(): Couldn't open File '" << hostFilename << "' for writing - aborting...";
            }
        }

    }

    return false;
}


/*****************************************************************************
 *      EazyLink Server V4.4
 *      Send a file to Z88 using EazyLink protocol
 *      Caller must ensure that the filename applies to Z88 standard
 *****************************************************************************/
bool Z88SerialPort::sendFile(QByteArray z88Filename, QString hostFilename)
{
    QByteArray sendFilesCmd = QByteArray( (char []) { 27, 'b'}, 2);
    QFile hostFile(hostFilename);
    QByteArray byte;

    if (hostFile.exists() == true) {
        if (transmitting == true) {
            qDebug() << "sendFile(): Transmission already ongoing with Z88 - aborting...";
        } else {
            if (hostFile.open(QIODevice::ReadOnly) == true) {
                // file opened for read-only...
                qDebug() << "sendFile(): Transmitting '" << hostFilename << "' file...";

                if ( sendCommand(sendFilesCmd) == false) {
                    qDebug() << "sendFile(): EazyLink send file command not acknowledged - aborting...";
                    hostFile.close();
                    return false;
                }

                if (sendFilename(z88Filename) == true) {
                    transmitting = true;

                    while (!hostFile.atEnd()) {
                        byte = hostFile.read(1);
                        if ( byte.count() == 1) {
                            if (byte[0] == (char) 27) {
                                // send ESC ESC sequence
                                if ( port.write(escEsc) != escEsc.length() ) {
                                    // not all bytes were transferred...
                                    qDebug() << "sendFile(): ESC ESC xx not transmitted properly to Z88!";
                                    port.clearLastError();
                                    hostFile.close();
                                    transmitting = false;
                                    return false;
                                }
                            } else {
                                if ( port.write(byte) != byte.length() ) {
                                    qDebug() << "sendFile(): Command not transmitted properly to Z88!";
                                    port.clearLastError();
                                    hostFile.close();
                                    transmitting = false;
                                    return false;
                                }
                            }
                        } else
                            break;
                    }
                }

                hostFile.close();
                port.write(escE);
                port.write(escZ); // End Of Batch - this function only sends a single file..

                // file transmitted to EazyLink popdown...
                transmitting = false;

                return true;
            } else {
                qDebug() << "sendFile(): Couldn't open File for reading - aborting...";
            }
        }

    } else {
        qDebug() << "sendFile(): File doesn't exist - aborting...";
    }

    return false;
}


/*********************************************************************************************************
 *      Private class methods
 ********************************************************************************************************/


/*****************************************************************************
 *      Get a byte from the Z88 serial port
 *****************************************************************************/
bool Z88SerialPort::getByte(unsigned char &byte)
{
    byte = 0; // by default no byte
    bool byteReceived = false;

    if (portOpenStatus == true) {
        if (transmitting == true) {
            qDebug() << "getByte(): Transmission already ongoing with Z88 - aborting receive byte...";
        } else {
            transmitting = true;
            QByteArray receivedByte = port.read(1);

            if ( receivedByte.count() != 1) {
                qDebug() << "getByte(): No byte received from Z88!";
                port.clearLastError();
            } else {
                byte = receivedByte.at(0);
                byteReceived = true;
            }

            transmitting = false;
        }
    }

    return byteReceived;
}


/*****************************************************************************
 *      Synchronize with Z88 before sending command
 *****************************************************************************/
bool Z88SerialPort::synchronize()
{
    QByteArray  synch = QByteArray( (char []) {1, 1, 2}, 3); // EazyLink Synchronize protocol

    if (portOpenStatus == true) {
        if (transmitting == true) {
            qDebug() << "synchronize(): Transmission already ongoing with Z88 - aborting synchronization...";
        } else {
            transmitting = true;

            if (port.write(synch) != synch.length()) {
                qDebug() << "synchronize(): Unable to synchronize with Z88!";
                port.clearLastError();

                transmitting = false;
            }

            QByteArray synchresponse = port.read(3);
            transmitting = false;

            if ( synchresponse.count() != 3) {
                qDebug() << "synchronize(): Bad synchronize response from Z88!";
                port.clearLastError();
            } else {
                if (synchresponse.at(2) == 2)
                    return true;        // synch response correct received from Z88
            }
        }
    }

    return false;       // synch from Z88 didn't arrive
}


/*****************************************************************************
 *      Send a command string to the Z88
 *****************************************************************************/
bool Z88SerialPort::sendCommand(QByteArray cmd)
{
    if ( synchronize() == true ) {
        if (transmitting == true) {
            qDebug() << "sendCommand(): Transmission already ongoing with Z88 - aborting...";
        } else {
            transmitting = true;

            if ( port.write(cmd) != cmd.length() ) {
                qDebug() << "sendCommand(): Command not transmitted properly to Z88!";
                port.clearLastError();

                transmitting = false;
            } else {
                // command transmitted correctly to Z88
                transmitting = false;
                return true;
            }
        }
    }

    return false;
}


/*****************************************************************************
 *      Receive an ESC N <fileName> ESC F from the Z88
 *      Built-in timeout of 30s if no filename is received
 *****************************************************************************/
Z88SerialPort::retcode Z88SerialPort::receiveFilename(QByteArray &fileName)
{
    unsigned char byte;

    if (transmitting == true) {
        qDebug() << "receiveFilename(): Transmission already ongoing with Z88 - aborting...";
    } else {

        while(1) {
            QTime timeout = QTime::currentTime().addSecs(30);
            while(QTime::currentTime() < timeout) {
                // wait max 30 secs for incoming filename...
                if (port.bytesAvailable() > 0)
                    break;                
            }

            if (QTime::currentTime() >= timeout)
                return rc_timeout; // timeout..

            if (getByte(byte) == true) {
                switch(byte) {
                    case 27:
                        getByte(byte);
                        switch(byte) {
                            case 'N':
                                if (fileName.length() > 0) {
                                    fileName.clear();               // get ready for a filename
                                }
                                break;

                            case 'F':
                                return rc_ok;                    // end of filename - exit

                            case 'Z':
                                return rc_done;                   // Batch End signaled from Imp/Export - exit

                            default:
                                return rc_inv;                   // illegal escape command - abort
                        }
                        break;

                    default:
                        fileName.append(byte);   // new byte collected in current filename
                }
            } else {
                // receiveing data stream has stopped...
                return rc_eof;
            }
        }
    }

    return rc_busy;
}


/*****************************************************************************
 *      Send a ESC N <fileName> ESC F to the Z88
 *****************************************************************************/
bool Z88SerialPort::sendFilename(QByteArray fileName)
{
    QByteArray filenameSequence;

    if (transmitting == true) {
        qDebug() << "sendFilename(): Transmission already ongoing with Z88 - aborting...";
    } else {
        transmitting = true;

        filenameSequence.append(escN);
        filenameSequence.append(fileName);
        filenameSequence.append(escF);

        if ( port.write(filenameSequence) != filenameSequence.length() ) {
            qDebug() << "sendFilename(): Command not transmitted properly to Z88!";
            port.clearLastError();

            transmitting = false;
        } else {
            // command transmitted correctly to Z88
            transmitting = false;
            return true;
        }
    }

    return false;
}


/*****************************************************************************
 *      Helper function to receive list items in the following format:
 *          ESC N ... [ESC N ...] ESC Z  {1 or more elements}
 *
 *          Get Z88 Devices
 *          Get Z88 Directories
 *          ...
 *****************************************************************************/
void Z88SerialPort::receiveListItems(QList<QByteArray> &list)
{
    unsigned char byte;
    QByteArray item;

    list.clear();

    while(1) {
        if (getByte(byte) == true) {
            switch(byte) {
                case 27:
                    getByte(byte);
                    switch(byte) {
                        case 'N':
                            if (item.length() > 0) {
                                list.append(item);          // Current item finished
                                item.clear();               // get ready for a new item (name)
                            }
                            break;

                        case 'Z':
                            if (item.length() > 0) {
                                list.append(item);
                            }
                            return;                     // end of items - exit

                        default:
                            return;                     // illegal escape command - abort
                    }
                    break;

                default:
                    item.append(byte);   // new byte collected in current item
            }

        } else {
            // receiveing data stream has stopped...
            return;
        }
    }
}


char Z88SerialPort::xtod(char c)
{
    if (c>='0' && c<='9') return c-'0';
    if (c>='A' && c<='F') return c-'A'+10;
    if (c>='a' && c<='f') return c-'a'+10;
    return c=0;        // not Hex digit
}
