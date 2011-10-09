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
    bool helloZ88();                            // poll for "hello" to Z88

private:
    QByteArray  synch;                          // [1, 1, 2]
    QByteArray  helloCmd;                       // [ 27, 'a']

    SerialPort  port;                           // the device handle
    bool        portOpenStatus;                 // status of opened port; true = opened, otherwise false for closed
    bool        transmitting;                   // a transmission is current ongoing
    QString     portName;                       // the default platform serial port device name

    bool        synchronize();                  // Synchronize with Z88 before sending command
    bool        sendCommand(QByteArray cmd);    // Transmit ESC command to Z88
};

#endif // Z88SERIALPORT_H
