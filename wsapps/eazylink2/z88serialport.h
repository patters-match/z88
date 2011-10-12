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
    bool open(QString portName);
    void close();
    bool helloZ88();                                        // poll for "hello" to Z88
    bool quitZ88();                                         // quit EazyLink popdown on Z88
    QList<QByteArray> getDevices();                         // return a list of Z88 Storage Devices
    QList<QByteArray> getDirectories(QByteArray path);      // return a list of Z88 Directories in <path>
    QList<QByteArray> getFilenames(QByteArray path);        // return a list of Z88 Filenames in <path>

private:
    SerialPort  port;                                       // the device handle
    bool        portOpenStatus;                             // status of opened port; true = opened, otherwise false for closed
    bool        transmitting;                               // a transmission is current ongoing
    QString     portName;                                   // the default platform serial port device name

    bool        getByte(unsigned char  &byte);              // Receive a byte from the Z88
    bool        synchronize();                              // Synchronize with Z88 before sending command
    bool        sendCommand(QByteArray cmd);                // Transmit ESC command to Z88
    void        receiveListItems(QList<QByteArray> &list);  // Receive list of items (eg. devices, directories, filenames)
};

#endif // Z88SERIALPORT_H
