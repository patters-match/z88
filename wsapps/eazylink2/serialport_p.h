/*******************************************************************************

 Copyright (C) 2010 Tomáš Hanák <tomas.hanak@gmail.com>

 This file is part of Qt Communication Library.

 Qt Communication Library is free software: you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public License as published
 by the Free Software Foundation, either version 3 of the License, or (at your
 option) any later version.

 This program is distributed in the hope that it will be useful, but WITHOUT ANY
 WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
 PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public License along
 with this program. If not, see <http://www.gnu.org/licenses/>.

*******************************************************************************/

#ifndef QTCOMMUNICATION_SERIALPORT_P_H
#define QTCOMMUNICATION_SERIALPORT_P_H

#include "serialport.h"

#include <QtCore/QHash>
#include <QtCore/QString>

#ifdef Q_OS_WIN32
    #include <windows.h>
#else // Q_OS_WIN32
    #include <termios.h> // POSIX terminal control definitions
    #include <sys/time.h>
    typedef quint8 BYTE; // 8 bits
    typedef quint16 WORD; // 16 bits
    typedef quint32 DWORD; // 32 bits
    typedef int HANDLE; // File handler
    #define INVALID_HANDLE_VALUE (HANDLE)(-1)
#endif // Q_OS_WIN32

QT_BEGIN_NAMESPACE
class QFile;
class QMutex;
QT_END_NAMESPACE


class SerialPortPrivate
{
public:
    explicit SerialPortPrivate(SerialPort *q);
    virtual ~SerialPortPrivate();

private:
    SerialPort::BaudRate baudRate_NumberToEnum(uint baudRate) const;
    uint baudRate_EnumToNumber(SerialPort::BaudRate baudRate) const;

private:
    Q_DECLARE_PUBLIC(SerialPort);
    SerialPort *q_ptr;

private:
    QMutex *const mutex;
    QHash<SerialPort::BaudRate, uint> platformBaudRateHash;

    QString portName;
    SerialPort::Settings settings;
    bool autoFlushOnWrite;

    HANDLE portHandle;
    SerialPort::Error lastError;

#ifdef Q_OS_WIN32
    COMMCONFIG commConfig;
    COMMTIMEOUTS timeout;
#else // Q_OS_WIN32
    struct termios commConfig;
    struct timeval timeout;
#endif // Q_OS_WIN32
};

#endif // QTCOMMUNICATION_SERIALPORT_P_H
