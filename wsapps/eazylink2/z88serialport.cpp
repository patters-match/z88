#include <QtCore/QList>
#include <QtCore/QByteArray>
#include "z88serialport.h"


Z88SerialPort::Z88SerialPort()
{
    transmitting = portOpenStatus = false;

    // define some default serial port device names for the specific platform
#ifdef Q_OS_WIN32
    portName = "COM6";
#else
#ifdef Q_OS_MAC
    //QString portName = "/dev/tty.Bluetooth-Modem";
    portName = "/dev/cu.Bluetooth-Modem";
#else
    portName = "/dev/ttyUSB0";
#endif
#endif

    qDebug() << "Defining default device: " << portName;
}


bool Z88SerialPort::open()
{
    return open(portName); // use default serial port device name (or previously specified port name)
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

    if (!port.open(QIODevice::ReadWrite | QIODevice::Text)) {
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

        return true;
    }
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
    char helloCmdSequense[] = {27, 'a'};
    QByteArray helloCmd = QByteArray( helloCmdSequense, 2); // EazyLink V4.4 Hello Request Command

    if ( sendCommand(helloCmd) == true) {
        if (transmitting == true) {
            qDebug() << "helloZ88(): Transmission already ongoing with Z88 - aborting...";
            return false;
        } else {
            QByteArray helloResponse = port.read(2);
            transmitting = false;

            if ( helloResponse.count() != 2) {
                qDebug() << "helloZ88(): Bad response from Z88!";
                qDebug() << "Error:" << port.lastError();
                port.clearLastError();

                return false;
            } else {
                if (helloResponse.at(1) == 'Y') {
                    qDebug() << "helloZ88(): Z88 responded 'hello'!";
                    return true;        // hello response correctly received from Z88
                } else
                    return false;       // hello response from Z88 not correct
            }
        }
    } else {
        return false;
    }
}


/*****************************************************************************
 *      EazyLink Server V4.4
 *      Send a 'quit' to the Z88 and return true if Z88 responded
 *****************************************************************************/
bool Z88SerialPort::quitZ88()
{
    char quitCmdSequense[] = {27, 'q'};
    QByteArray quitCmd = QByteArray( quitCmdSequense, 2); // EazyLink V4.4 Quit Request Command

    if ( sendCommand(quitCmd) == true) {
        if (transmitting == true) {
            qDebug() << "quitZ88(): Transmission already ongoing with Z88 - aborting...";
            return false;
        } else {
            QByteArray quitResponse = port.read(2);
            transmitting = false;

            if ( quitResponse.count() != 2) {
                qDebug() << "quitZ88(): Bad response from Z88!";
                qDebug() << "Error:" << port.lastError();
                port.clearLastError();

                return false;
            } else {
                if (quitResponse.at(1) == 'Y') {
                    qDebug() << "quitZ88(): Z88 responded 'Goodbye'!";
                    return true;        // quit response correctly received from Z88
                } else
                    return false;       // quit response from Z88 not correct
            }
        }
    } else {
        return false;
    }
}


/*****************************************************************************
 *      EazyLink Server V4.4
 *      Get Z88 devices.
 *****************************************************************************/
QList<QByteArray> Z88SerialPort::getDevices()
{
    char devicesCmdSequense[] = {27, 'h'};
    QByteArray devicesCmd = QByteArray( devicesCmdSequense, 2); // EazyLink V4.4 Device Request Command
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
 *      Synchronize with Z88 before sending command
 *****************************************************************************/
bool Z88SerialPort::synchronize()
{
    char        synchprotocol[] = {1,1,2};
    QByteArray  synch = QByteArray( synchprotocol, 3); // EazyLink Synchronize protocol

    if (portOpenStatus == false) {
        // signal no synchronisation accomplished
        return false;
    } else {
        if (transmitting == true) {
            qDebug() << "synchronize(): Transmission already ongoing with Z88 - aborting synchronization...";
            return false;
        } else {
            transmitting = true;

            if (port.write(synch) != synch.length()) {
                qDebug() << "synchronize(): Unable to synchronize with Z88!";
                qDebug() << "Error:" << port.lastError();
                port.clearLastError();

                transmitting = false;
                return false;
            }

            QByteArray synchresponse = port.read(3);
            transmitting = false;

            if ( synchresponse.count() != 3) {
                qDebug() << "synchronize(): Bad synchronize response from Z88!";
                qDebug() << "Error:" << port.lastError();
                port.clearLastError();

                return false;
            } else {
                if (synchresponse.at(2) == 2)
                    return true;        // synch response correct received from Z88
                else
                    return false;       // synch from Z88 didn't arrive
            }
        }
    }
}


/*****************************************************************************
 *      Send a command string to the Z88
 *****************************************************************************/
bool Z88SerialPort::sendCommand(QByteArray cmd)
{
    if ( synchronize() == true ) {
        if (transmitting == true) {
            qDebug() << "sendCommand(): Transmission already ongoing with Z88 - aborting...";
            return false;
        } else {
            transmitting = true;

            if ( port.write(cmd) != cmd.length() ) {
                qDebug() << "sendCommand(): Command not transmitted properly to Z88!";
                qDebug() << "Error:" << port.lastError();
                port.clearLastError();

                transmitting = false;
                return false;
            } else {
                // command transmitted correctly to Z88
                transmitting = false;
                return true;
            }
        }
    } else
        return false;
}


/*****************************************************************************
 *      Helper function to receive list items from
 *          Get Z88 Devices
 *          Get Z88 Directories
 *          ...
 *****************************************************************************/
void Z88SerialPort::receiveListItems(QList<QByteArray> &list)
{
}
