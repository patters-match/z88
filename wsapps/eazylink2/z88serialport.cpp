/*********************************************************************************************
 EazyLink2 - Fast Client/Server Z88 File Management
 (C) Gunther Strube (gstrube@gmail.com)

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
    char _synchEazyLinkProtocol[] = { 1, 1, 2 };
    char _escEsc[] = { 27, 27 };
    char _escB[] = { 27, 'B' };
    char _escN[] = { 27, 'N' };
    char _escE[] = { 27, 'E' };
    char _escF[] = { 27, 'F' };
    char _escZ[] = { 27, 'Z' };
    char _helloCmd[] = { 27, 'a' };
    char _quitCmd[] = { 27, 'q' };
    char _devicesCmd[] = { 27, 'h' };
    char _directoriesCmd[] = { 27, 'd' };
    char _filesCmd[] = { 27, 'n' };
    char _transOnCmd[] = { 27, 't' };
    char _transOffCmd[] = { 27, 'T' };
    char _lfConvOnCmd[] =  { 27, 'c' };
    char _lfConvOffCmd[] = { 27, 'C' };
    char _reloadTraTableCmd[] = { 27, 'z' };
    char _versionCmd[] =  { 27, 'v' };
    char _ramDefaultCmd[] = { 27, 'g' };
    char _fileExistCmd[] = { 27, 'f' };
    char _fileDateStampCmd[] = { 27, 'u' };
    char _setFileTimeStampCmd[] = { 27, 'U' };
    char _fileSizeCmd[]= { 27, 'x' };
    char _getZ88TimeCmd[] = { 27, 'e' };
    char _setZ88TimeCmd[] = { 27, 'p' };
    char _createDirCmd[] = { 27, 'y' };
    char _deleteFileDirCmd[] = { 27, 'r' };
    char _renameFileDirCmd[] = { 27, 'w' };
    char _freeMemoryCmd[] = { 27, 'm' };
    char _freeMemDevCmd[] = { 27, 'M' };
    char _receiveFilesCmd[] = { 27, 's' };
    char _sendFilesCmd[] = { 27, 'b' };
    char _crc32FileCmd[] = { 27, 'i' };
    char _devInfoCmd[] = { 27, 'O' };

    // Initialize ESC command constants
    synchEazyLinkProtocol = QByteArray( _synchEazyLinkProtocol, 3); // EazyLink Synchronize protocol
    escEsc = QByteArray( _escEsc, 2);
    escB = QByteArray( _escB, 2);
    escN = QByteArray( _escN, 2);
    escE = QByteArray( _escE, 2);
    escF = QByteArray( _escF, 2);
    escZ = QByteArray( _escZ, 2);
    helloCmd = QByteArray( _helloCmd , 2);                      // EazyLink V4.4 Hello
    quitCmd = QByteArray( _quitCmd, 2);                         // EazyLink V4.4 Quit
    devicesCmd = QByteArray( _devicesCmd, 2);                   // EazyLink V4.4 Device
    directoriesCmd = QByteArray( _directoriesCmd, 2);           // EazyLink V4.4 Directory
    filesCmd = QByteArray( _filesCmd, 2);                       // EazyLink V4.4 Files
    receiveFilesCmd = QByteArray( _receiveFilesCmd, 2);         // EazyLink V4.4 Receive one or more files from Z88
    sendFilesCmd = QByteArray( _sendFilesCmd, 2);               // EazyLink V4.4 Send one or more files from Z88
    transOnCmd = QByteArray( _transOnCmd , 2);                  // EazyLink V4.4 Translation ON
    transOffCmd = QByteArray( _transOffCmd, 2);                 // EazyLink V4.4 Translation OFF
    lfConvOnCmd = QByteArray( _lfConvOnCmd, 2);                 // EazyLink V4.4 Linefeed Conversion ON
    lfConvOffCmd = QByteArray( _lfConvOffCmd, 2);               // EazyLink V4.4 Linefeed Conversion OFF
    versionCmd = QByteArray( _versionCmd, 2);                   // EazyLink V4.5 EazyLink Server Version and protocol level
    fileExistCmd = QByteArray( _fileExistCmd, 2);               // EazyLink V4.5 File exists
    fileDateStampCmd = QByteArray( _fileDateStampCmd, 2);       // EazyLink V4.5 Get create and update date stamp of Z88 file
    setFileTimeStampCmd = QByteArray( _setFileTimeStampCmd, 2); // EazyLink V4.5 Set create and update date stamp of Z88 file
    fileSizeCmd = QByteArray( _fileSizeCmd, 2);                 // EazyLink V4.5 Get file size
    reloadTraTableCmd = QByteArray( _reloadTraTableCmd, 2);     // EazyLink V4.6 Reload Translation Table
    deleteFileDirCmd = QByteArray( _deleteFileDirCmd, 2);       // EazyLink V4.6 Delete file/dir on Z88.
    ramDefaultCmd = QByteArray( _ramDefaultCmd, 2);             // EazyLink V4.7 Get Z88 RAM defaults
    createDirCmd = QByteArray( _createDirCmd, 2);               // EazyLink V4.7 Create directory path on Z88
    renameFileDirCmd = QByteArray( _renameFileDirCmd, 2);       // EazyLink V4.7 Rename file/directory on Z88
    getZ88TimeCmd = QByteArray( _getZ88TimeCmd, 2);             // EazyLink V4.8 Get Z88 system Date/Time
    setZ88TimeCmd = QByteArray( _setZ88TimeCmd, 2);             // EazyLink V4.8 Set Z88 System Clock using PC system time
    freeMemoryCmd = QByteArray( _freeMemoryCmd, 2);             // EazyLink V4.8 Get free memory for all RAM cards
    freeMemDevCmd = QByteArray( _freeMemDevCmd, 2);             // EazyLink V5.0 Get free memory for specific device
    crc32FileCmd = QByteArray( _crc32FileCmd, 2);               // EazyLink V5.2 Get CRC-32 of specified Z88 file
    devInfoCmd = QByteArray( _devInfoCmd, 2);                   // EazyLink V5.2 Get Device Information

    transmitting = portOpenStatus = z88AvailableStatus = false;

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

bool Z88SerialPort::isZ88Available()
{
    return z88AvailableStatus;
}

bool Z88SerialPort::sendAsciiPortNameString(bool fullPath)
{
    QString pname(portName);

    /**
      * If not fullpath requested, then strip the Path
      */
    if(!fullPath){
        int idx = portName.lastIndexOf("/");
        if(idx >=0){
            pname = portName.mid(idx+1);
        }
    }

    QByteArray frm;
    QByteArray obuf;
    obuf.append(QChar(12));
    obuf.append(QChar(12));
    obuf.append(QChar(7));

    obuf += "Serial Port Found!!!\r\n";
    /**
      * Draw a fram around the device name
      */
    obuf.append(frm.fill('*', 4 + pname.size()));
    obuf += "\r\n* " + pname  + " *\r\n";
    obuf.append(frm.fill('*', 4 + pname.size()));
    obuf += "\r\n";

    return (port.write(obuf, obuf.size()) == obuf.size());
}

void Z88SerialPort::close()
{
    if (portOpenStatus == true) {
        // close connection if currently open...
        port.close();
        portOpenStatus = false;
    }

    z88AvailableStatus = false;
}


/*****************************************************************************
 *      EazyLink Server V4.4
 *      Send a 'hello' to the Z88 and return true if Yes, or false if No
 *****************************************************************************/
bool Z88SerialPort::helloZ88()
{

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

    QByteArray directoriesCmdPath = directoriesCmd;
    directoriesCmdPath.append(path);
    directoriesCmdPath.append(escZ);

    if ( sendCommand(directoriesCmdPath) == true) {
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
QList<QByteArray> Z88SerialPort::getFilenames(const QString &path, bool &retc)
{
    QList<QByteArray> filenamesList;

    QByteArray filesCmdPath = filesCmd;
    filesCmdPath.append(path);
    filesCmdPath.append(escZ);
    if ( sendCommand(filesCmdPath) == true) {
        if (transmitting == true) {
            qDebug() << "getFilenames(): Transmission already ongoing with Z88 - aborting...";
            retc = false;
        } else {
            // receive device elements into list
            retc = receiveListItems(filenamesList);
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
    if ( sendCommand(lfConvOnCmd) == true) {
        return true;  // Z88 now has linefeed conversion enabled
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
    if ( sendCommand(lfConvOffCmd) == true) {
        return true;  // Z88 now has linefeed conversion disabled
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
    if ( sendCommand(reloadTraTableCmd) == true) {
        return true;  // Z88 now has reload translation table.
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
bool Z88SerialPort::isFileAvailable(const QString &filename)
{
    QByteArray fileExistCmdRequest = fileExistCmd;
    fileExistCmdRequest.append(filename);
    fileExistCmdRequest.append(escZ);

    if ( sendCommand(fileExistCmdRequest) == true) {
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
    QList<QByteArray> dateStampList;

    QByteArray fileDateStampCmdRequest = fileDateStampCmd;
    fileDateStampCmdRequest.append(filename);
    fileDateStampCmdRequest.append(escZ);
    if ( sendCommand(fileDateStampCmdRequest) == true) {
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
    QList<QByteArray> fileSizeList;
    QByteArray fileSizeString;

    QByteArray fileSizeCmdRequest = fileSizeCmd;
    fileSizeCmdRequest.append(filename);
    fileSizeCmdRequest.append(escZ);
    if ( sendCommand(fileSizeCmdRequest) == true) {
        if (transmitting == true) {
            qDebug() << "getFileSize(): Transmission already ongoing with Z88 - aborting...";
        } else {
            // receive file size into list
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
 *      Set Z88 system Date/Time, if time difference between
 *      Z88 and Desktop is bigger than 30 seconds
 *
 *      Returns true, if Desktop time has been synchronized to Z88
 *      Returns false, if time was not necessary to be set or there was a communication error
 *****************************************************************************/
bool Z88SerialPort::syncZ88Time()
{
    QList<QByteArray> z88TimeList = getZ88Time();

    if(z88TimeList.count()==2) {
        QDateTime z88Dt = QDateTime::fromString(
                    QString(z88TimeList[0].data()).append(z88TimeList[1].data()),
                    "dd/MM/yyyyhh:mm:ss");

        int timeDiff = QDateTime::currentDateTime().secsTo(z88Dt);
        timeDiff = ( timeDiff < 0 ? -timeDiff : timeDiff );

        if (timeDiff > 30)
            return setZ88Time();
    }

    return false;
}


/*****************************************************************************
 *      EazyLink Server V4.8
 *      Set Z88 System Clock using PC system time
 *****************************************************************************/
bool Z88SerialPort::setZ88Time()
{    
    QDateTime dt = QDateTime::currentDateTime();

    QByteArray setZ88TimeCmdRequest = setZ88TimeCmd;
    setZ88TimeCmdRequest.append(dt.toString("dd/MM/yyyy"));
    setZ88TimeCmdRequest.append(escN);
    setZ88TimeCmdRequest.append(dt.toString("hh:mm:ss"));
    setZ88TimeCmdRequest.append(escZ);

    if ( sendCommand(setZ88TimeCmdRequest) == true) {
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
    QByteArray setFileTimeStampCmdRequest = setFileTimeStampCmd;

    setFileTimeStampCmdRequest.append(filename);
    setFileTimeStampCmdRequest.append(escN);
    setFileTimeStampCmdRequest.append(createDate);
    setFileTimeStampCmdRequest.append(escN);
    setFileTimeStampCmdRequest.append(updateDate);
    setFileTimeStampCmdRequest.append(escZ);

    if ( sendCommand(setFileTimeStampCmdRequest) == true) {
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
bool Z88SerialPort::createDir(const QString &pathName)
{
    QByteArray createDirCmdRequest = createDirCmd;
    createDirCmdRequest.append(pathName);
    createDirCmdRequest.append(escZ);

    if ( sendCommand(createDirCmdRequest) == true) {
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
bool Z88SerialPort::deleteFileDir(const QString &filename)
{
    QByteArray deleteFileDirCmdRequest = deleteFileDirCmd;
    deleteFileDirCmdRequest.append(filename);
    deleteFileDirCmdRequest.append(escZ);

    if ( sendCommand(deleteFileDirCmdRequest) == true) {
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
bool Z88SerialPort::renameFileDir(const QString &pathName, const QString &fileName)
{
    QByteArray renameFileDirCmdRequest = renameFileDirCmd;
    renameFileDirCmdRequest.append(pathName);  // filename (with explicit path)
    renameFileDirCmdRequest.append(escN);
    renameFileDirCmdRequest.append(fileName);  // short filename (12+3, without path)
    renameFileDirCmdRequest.append(escZ);

    if ( sendCommand(renameFileDirCmdRequest) == true) {
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
    QByteArray freeMemDevCmdRequest = freeMemDevCmd;
    QList<QByteArray> freeMemoryList;
    QByteArray freeMemoryString;

    freeMemDevCmdRequest.append(device);
    freeMemDevCmdRequest.append(escZ);

    if ( sendCommand(freeMemDevCmdRequest) == true) {
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
bool Z88SerialPort::impExpSendFile(const QString &z88Filename, const QString hostFilename)
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
Z88SerialPort::retcode Z88SerialPort::receiveFiles(const QString &z88Filenames, const QString &hostPath, const QString &destFspec, bool destisDir)
{
    QByteArray receiveFilesCmdRequest = receiveFilesCmd;
    QByteArray z88Filename, remoteFile;
    unsigned char byte;

    if (transmitting == true) {
        qDebug() << "receiveFiles(): Transmission already ongoing with Z88 - aborting...";
    } else {
        receiveFilesCmdRequest.append(z88Filenames);
        receiveFilesCmdRequest.append(escZ);

        if ( sendCommand(receiveFilesCmdRequest) == true) {
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

                        QString hostFilename = hostPath;

                        if(destisDir){
//                            hostFilename.append((z88Filename.constData()+6));
                            hostFilename.append('/');
                            hostFilename.append(destFspec);
                        }

                        QFile hostFile(hostFilename);
                        QString tfile = hostFilename + ".xfer";


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
                                                        hostFile.rename(tfile);
                                                        hostFile.rename(hostFilename);
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
bool Z88SerialPort::impExpReceiveFiles(const QString &hostPath)
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

        QString hostFilename = QString(hostPath).append((z88Filename.constData()+6));
        QFile hostFile(hostFilename);
        QString tfile = hostFilename + ".xfer";

        emit impExpRecFilename(hostFilename);

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
                                        /**
                                          * Work Around for QT bug
                                          */
                                        hostFile.rename(tfile);
                                        hostFile.rename(hostFilename);

                                        emit impExpRecFile_Done(hostFilename);

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
bool Z88SerialPort::sendFile(const QString &z88Filename, QString hostFilename)
{
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


/*****************************************************************************
 *      EazyLink Server V5.2, protocol level 06
 *      Get CRC-32 of Z88 file
 *****************************************************************************/
QByteArray Z88SerialPort::getFileCrc32(const QString &filename)
{
    QList<QByteArray> fileSizeList;
    QByteArray fileCrc32String;

    QByteArray crc32FileCmdRequest = crc32FileCmd;
    crc32FileCmdRequest.append(filename);
    crc32FileCmdRequest.append(escZ);
    if ( sendCommand(crc32FileCmdRequest) == true) {
        if (transmitting == true) {
            qDebug() << "getFileCrc32(): Transmission already ongoing with Z88 - aborting...";
        } else {
            QTime timeout = QTime::currentTime().addSecs(10);
            while(QTime::currentTime() < timeout) {
                // wait max 10 secs for a response, because CRC-32 might take some time for 32K+ files
                if (port.bytesAvailable() > 0)
                    break;
            }

            // receive crc-32 into list
            receiveListItems(fileSizeList);
            transmitting = false;

            if (fileSizeList.count() > 0) {
                fileCrc32String = fileSizeList.at(0); // the "list" has only one item...
            }
        }
    }

    return fileCrc32String;
}


/*****************************************************************************
 *      EazyLink Server V5.2, protocol level 06
 *      Get Device Information; free memory / total size, returned in list
 *****************************************************************************/
QList<QByteArray> Z88SerialPort::getDeviceInfo(const QString &device)
{
    QList<QByteArray> infoList;

    QByteArray devInfoCmdPath = devInfoCmd;
    devInfoCmdPath.append(device);
    devInfoCmdPath.append(escZ);

    if ( sendCommand(devInfoCmdPath) == true) {
        if (transmitting == true) {
            qDebug() << "getDeviceinfo(): Transmission already ongoing with Z88 - aborting...";
        } else {
            // receive device information elements into list
            // first element is free memory in byte, second element is device sice in Kb
            // if device was not found, an empty list is returned.
            receiveListItems(infoList);
            transmitting = false;
        }
    }

    return infoList;
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
    if (portOpenStatus == true) {
        if (transmitting == true) {
            qDebug() << "synchronize(): Transmission already ongoing with Z88 - aborting synchronization...";
        } else {
            transmitting = true;

            if (port.write(synchEazyLinkProtocol) != synchEazyLinkProtocol.length()) {
                qDebug() << "synchronize(): Unable to synchronize with Z88!";
                port.clearLastError();

                transmitting = false;
            }

            QByteArray synchresponse = port.read(3);
            transmitting = false;

            if ( synchresponse.count() != 3) {
                qDebug() << "synchronize(): Bad synchronize response from Z88: [" << synchresponse << "] " << synchresponse.count() << " bytes";
                port.clearLastError();
            } else {
                if (synchresponse.at(2) == 2)
                    return true;        // synch response correct received from Z88
            }
        }
    }

    // synch from Z88 didn't arrive
    z88AvailableStatus = false;
    return false;
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
                z88AvailableStatus = true;

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
bool Z88SerialPort::sendFilename(const QString &fileName)
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
bool Z88SerialPort::receiveListItems(QList<QByteArray> &list)
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
                            return true;                     // end of items - exit

                        default:
                            return false;                     // illegal escape command - abort
                    }
                    break;

                default:
                    item.append(byte);   // new byte collected in current item
            }

        } else {
            // receiveing data stream has stopped...
            return false;
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
