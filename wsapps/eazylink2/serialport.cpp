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

#include "serialport_p.h"

#include <QtCore/QFile>
#include <QtCore/QIODevice>
#include <QtCore/QMutex>
#include <QtCore/QStringList>
#include <QtCore/QThread>

#include <qdebug.h>

#include <stdio.h>

#ifndef Q_OS_WIN32
    #include <fcntl.h> // File control definitions
    #include <errno.h> // Error number definitions
    #include <sys/ioctl.h>
#endif // Q_OS_WIN32

/*******************************************************************************
    SerialPort - public methods
*******************************************************************************/

SerialPort::SerialPort(QObject *parent)
    : QIODevice(parent),
    d_ptr(new SerialPortPrivate(this))
{
    setOpenMode(QIODevice::NotOpen);
}

SerialPort::SerialPort(const QString &portName, QObject *parent)
    : QIODevice(parent),
    d_ptr(new SerialPortPrivate(this))
{
    setOpenMode(QIODevice::NotOpen);
    setPortName(portName);
}

SerialPort::SerialPort(const Settings &settings, QObject *parent)
    : QIODevice(parent),
    d_ptr(new SerialPortPrivate(this))
{
    setOpenMode(QIODevice::NotOpen);
    setBaudRate(settings.baudRate);
    setDataBits(settings.dataBits);
    setFlowControl(settings.flowControl);
    setParity(settings.parity);
    setStopBits(settings.stopBits);
    setTimeout(settings.timeout);
}

SerialPort::SerialPort(const QString &portName, const Settings &settings,
        QObject *parent)
    : QIODevice(parent),
    d_ptr(new SerialPortPrivate(this))
{
    setOpenMode(QIODevice::NotOpen);
    setPortName(portName);
    setBaudRate(settings.baudRate);
    setDataBits(settings.dataBits);
    setFlowControl(settings.flowControl);
    setParity(settings.parity);
    setStopBits(settings.stopBits);
    setTimeout(settings.timeout);
}

SerialPort::SerialPort(const SerialPort &serialPort)
    : QIODevice(serialPort.parent()),
    d_ptr(new SerialPortPrivate(this))
{
    Q_D(SerialPort);

    setOpenMode(serialPort.openMode());
    setPortName(serialPort.portName());
    setBaudRate(serialPort.baudRate());
    setDataBits(serialPort.dataBits());
    setFlowControl(serialPort.flowControl());
    setParity(serialPort.parity());
    setStopBits(serialPort.stopBits());
    setTimeout(serialPort.timeout());

    d->lastError = serialPort.lastError();

#ifdef Q_OS_WIN32
    memcpy(&d->commConfig, &serialPort.d_ptr->commConfig, sizeof(COMMCONFIG));
#else // Q_OS_WIN32
    memcpy(&d->commConfig, &serialPort.d_ptr->commConfig, sizeof(struct termios));
#endif // Q_OS_WIN32
}

SerialPort &SerialPort::operator=(const SerialPort &serialPort)
{
    Q_D(SerialPort);

    setParent(serialPort.parent());

    setOpenMode(serialPort.openMode());
    setPortName(serialPort.portName());
    setBaudRate(serialPort.baudRate());
    setDataBits(serialPort.dataBits());
    setFlowControl(serialPort.flowControl());
    setParity(serialPort.parity());
    setStopBits(serialPort.stopBits());
    setTimeout(serialPort.timeout());

    d->lastError = serialPort.lastError();

#ifdef Q_OS_WIN32
    memcpy(&d->commConfig, &serialPort.d_ptr->commConfig, sizeof(COMMCONFIG));
#else // Q_OS_WIN32
    memcpy(&d->commConfig, &serialPort.d_ptr->commConfig, sizeof(struct termios));
#endif // Q_OS_WIN32

    return *this;
}

SerialPort::~SerialPort()
{
    delete d_ptr;
    d_ptr = 0;
}

void SerialPort::setPortName(const QString &portName)
{
    Q_D(SerialPort);
    QMutexLocker(d->mutex);

    if (this->portName() != portName) {
        d->portName = portName;
        Q_EMIT portNameChanged(portName);
    }

#ifdef Q_OS_WIN32
    d->portName.prepend("\\\\.\\");
#endif // Q_OS_WIN32
}

QString SerialPort::portName() const
{
    Q_D(const SerialPort);
    QMutexLocker(d->mutex);

    QString portName = d->portName;
#ifdef Q_OS_WIN32
    portName.remove(QRegExp("\\\\.\\"));
#endif // Q_OS_WIN32
    return portName;
}

void SerialPort::setBaudRate(BaudRate baudRate)
{
    Q_D(SerialPort);
    QMutexLocker(d->mutex);

    if (d->settings.baudRate != baudRate) {
        d->settings.baudRate = baudRate;
        Q_EMIT baudRateChanged(baudRate);
    }

    if (!isOpen())
        return;

    const uint platformBaudRate = d->platformBaudRateHash[baudRate];

#ifdef Q_OS_WIN32
    d->commConfig.dcb.BaudRate = platformBaudRate;
    SetCommConfig(d->portHandle, &d->commConfig, sizeof(COMMCONFIG));
#else // Q_OS_WIN32
#ifdef CBAUD
    d->commConfig.c_cflag &= ~CBAUD;
    d->commConfig.c_cflag |= platformBaudRate;
#else // CBAUD
    cfsetispeed(&d->commConfig, platformBaudRate);
    cfsetospeed(&d->commConfig, platformBaudRate);
#endif // CBAUD
    tcsetattr(d->portHandle, TCSAFLUSH, &d->commConfig);
#endif // Q_OS_WIN32
}

SerialPort::BaudRate SerialPort::baudRate() const
{
    Q_D(const SerialPort);
    return d->settings.baudRate;
}

QList<SerialPort::BaudRate> SerialPort::supportedBaudRates() const
{
    Q_D(const SerialPort);
    return d->platformBaudRateHash.keys();
}

bool SerialPort::setBaudRateFromNumber(uint baudRate)
{
    Q_D(SerialPort);
    QMutexLocker(d->mutex);

    const BaudRate baudRateEnum = d->baudRate_NumberToEnum(baudRate);
    if (baudRateEnum == BaudRate_Invalid) {
        QStringList baudRates;
        QList<uint> supportedBaudRates = supportedBaudRatesAsNumber();
        qSort(supportedBaudRates.begin(), supportedBaudRates.end());
        Q_FOREACH(uint baudRate, supportedBaudRates) {
            baudRates << QString::number(baudRate);
        }
        d->lastError = InvalidSettingsError;
        return false;
    }

    setBaudRate(baudRateEnum);
    return true;
}

uint SerialPort::baudRateAsNumber() const
{
    Q_D(const SerialPort);
    return static_cast<uint>(d->settings.baudRate);
}

QList<uint> SerialPort::supportedBaudRatesAsNumber() const
{
    Q_D(const SerialPort);

    QList<uint> supportedBaudRates;
    const QList<BaudRate> keys = d->platformBaudRateHash.keys();
    Q_FOREACH(BaudRate baudRate, keys) {
        supportedBaudRates << d->baudRate_EnumToNumber(baudRate);
    }
    return supportedBaudRates;
}

void SerialPort::setDataBits(DataBits dataBits)
{
    Q_D(SerialPort);
    QMutexLocker(d->mutex);

    if (d->settings.stopBits == OneAndHalfStopBits
            && dataBits != FiveDataBits) {
        // d->warning("Only 8 data bits may be used with 1.5 stop bits");
        return;
    }
    else if (d->settings.stopBits == TwoStopBits
            && dataBits == FiveDataBits) {
        // d->warning("5 data bits cannot be used with 2 stop bits");
        return;
    }
#ifndef Q_OS_WIN32
    else if (d->settings.parity == SpaceParity
            && dataBits == EightDataBits) {
        // d->warning("8 data bits cannot be used with space parity");
        return;
    }
#endif // Q_OS_WIN32

    if (d->settings.dataBits != dataBits) {
        d->settings.dataBits = dataBits;
        Q_EMIT dataBitsChanged(dataBits);
    }

    if (!isOpen())
        return;

#ifdef Q_OS_WIN32
    switch (d->settings.dataBits) {
    case FiveDataBits:
        d->commConfig.dcb.ByteSize = 5;
        break;
    case SixDataBits:
        d->commConfig.dcb.ByteSize = 6;
        break;
    case SevenDataBits:
        d->commConfig.dcb.ByteSize = 7;
        break;
    case EightDataBits:
        d->commConfig.dcb.ByteSize = 8;
        break;
    }
    SetCommConfig(d->portHandle, &d->commConfig, sizeof(COMMCONFIG));
#else // Q_OS_WIN32
    switch (d->settings.dataBits) {
    case FiveDataBits:
        d->commConfig.c_cflag |= CS5;
        break;
    case SixDataBits:
        d->commConfig.c_cflag |= CS6;
        break;
    case SevenDataBits:
        d->commConfig.c_cflag |= CS7;
        break;
    case EightDataBits:
        d->commConfig.c_cflag |= CS8;
        break;
    }
    //Oscar d->commConfig.c_cflag &= ~CSIZE;
    tcsetattr(d->portHandle, TCSAFLUSH, &d->commConfig);
#endif // Q_OS_WIN32
}

SerialPort::DataBits SerialPort::dataBits() const
{
    Q_D(const SerialPort);
    return d->settings.dataBits;
}

void SerialPort::setParity(Parity parity)
{
    Q_D(SerialPort);
    QMutexLocker(d->mutex);

    if (parity == SpaceParity && d->settings.dataBits == EightDataBits) {
        /*
        d->portabilityWarning("Space parity is only supported in POSIX "
                "with 7 or fewer data bits");
        */
        return;
    }
    else if (parity == MarkParity) {
#ifdef Q_OS_WIN32
        // d->portabilityWarning("POSIX does not support mark parity");
#else // Q_OS_WIN32
        // d->warning("POSIX does not support mark parity");
        return;
#endif // Q_OS_WIN32
    }

    if (d->settings.parity != parity) {
        d->settings.parity = parity;
        Q_EMIT parityChanged(parity);
    }

    if (!isOpen())
        return;

#ifdef Q_OS_WIN32
    switch (d->settings.parity) {
    case NoParity:
        d->commConfig.dcb.fParity = FALSE;
        d->commConfig.dcb.Parity = NOPARITY;
        break;
    case OddParity:
        d->commConfig.dcb.fParity = TRUE;
        d->commConfig.dcb.Parity = ODDPARITY;
        break;
    case EvenParity:
        d->commConfig.dcb.fParity = TRUE;
        d->commConfig.dcb.Parity = EVENPARITY;
        break;
    case MarkParity:
        d->commConfig.dcb.fParity = TRUE;
        d->commConfig.dcb.Parity = MARKPARITY;
        break;
    case SpaceParity:
        d->commConfig.dcb.fParity = TRUE;
        d->commConfig.dcb.Parity = SPACEPARITY;
        break;
    }
    SetCommConfig(d->portHandle, &d->commConfig, sizeof(COMMCONFIG));
#else // Q_OS_WIN32
    switch (d->settings.parity) {
    case NoParity:
        d->commConfig.c_cflag &= ~PARENB;
        break;
    case OddParity:
        d->commConfig.c_cflag |= PARENB;
        d->commConfig.c_cflag |= PARODD;
        break;
    case EvenParity:
        d->commConfig.c_cflag |= PARENB;
        d->commConfig.c_cflag &= ~PARODD;
        break;
    case MarkParity:
        break;
    case SpaceParity:
        /*
        d->portabilityWarning("Space parity not directly supported, "
                "added an extra data bit to simulate it");
        */
        d->commConfig.c_cflag &= ~(PARENB | CSIZE);
        switch (d->settings.dataBits) {
        case FiveDataBits:
            d->settings.dataBits = SixDataBits;
            d->commConfig.c_cflag |= CS6;
            break;
        case SixDataBits:
            d->settings.dataBits = SevenDataBits;
            d->commConfig.c_cflag |= CS7;
            break;
        case SevenDataBits:
            d->settings.dataBits = EightDataBits;
            d->commConfig.c_cflag |= CS8;
            break;
        case EightDataBits:
            break;
        }
        break;
    }
    tcsetattr(d->portHandle, TCSAFLUSH, &d->commConfig);
#endif // Q_OS_WIN32
}

SerialPort::Parity SerialPort::parity() const
{
    Q_D(const SerialPort);
    return d->settings.parity;
}

void SerialPort::setStopBits(StopBits stopBits)
{
    Q_D(SerialPort);
    QMutexLocker(d->mutex);

    if (stopBits == TwoStopBits && d->settings.dataBits == FiveDataBits) {
        // d->warning("2 stop bits cannot be used with 5 data bits");
        return;
    }
    else if (stopBits == OneAndHalfStopBits) {
#ifdef Q_OS_WIN32
        // d->portabilityWarning("POSIX does not support 1.5 stop bits");
        if (d->settings.dataBits != FiveDataBits) {
            // d->warning("1.5 stop bits can only be used with 5 data bits");
            return;
        }
#else // Q_OS_WIN32
        // d->warning("POSIX does not support 1.5 stop bits");
        return;
#endif // Q_OS_WIN32
    }

    if (d->settings.stopBits != stopBits) {
        d->settings.stopBits = stopBits;
        Q_EMIT stopBitsChanged(stopBits);
    }

    if (!isOpen())
        return;

#ifdef Q_OS_WIN32
    switch (d->settings.stopBits) {
    case OneStopBit:
        d->commConfig.dcb.StopBits = ONESTOPBIT;
        break;
    case OneAndHalfStopBits:
        d->commConfig.dcb.StopBits = ONE5STOPBITS;
        break;
    case TwoStopBits:
        d->commConfig.dcb.StopBits = TWOSTOPBITS;
        break;
    }
    SetCommConfig(d->portHandle, &d->commConfig, sizeof(COMMCONFIG));
#else // Q_OS_WIN32
    switch (d->settings.stopBits) {
    case OneStopBit:
        d->commConfig.c_cflag &= ~CSTOPB;
        break;
    case OneAndHalfStopBits:
        break;
    case TwoStopBits:
        d->commConfig.c_cflag |= CSTOPB;
        break;
    }
    tcsetattr(d->portHandle, TCSAFLUSH, &d->commConfig);
#endif // Q_OS_WIN32
}

SerialPort::StopBits SerialPort::stopBits() const
{
    Q_D(const SerialPort);
    return d->settings.stopBits;
}

void SerialPort::setFlowControl(FlowControl flowControl)
{
    Q_D(SerialPort);
    QMutexLocker(d->mutex);

    if (d->settings.flowControl != flowControl) {
        d->settings.flowControl = flowControl;
        Q_EMIT flowControlChanged(flowControl);
    }

    if (!isOpen())
        return;

#ifdef Q_OS_WIN32
    switch (d->settings.flowControl) {
    case NoFlowControl:
        d->commConfig.dcb.fOutxCtsFlow = FALSE;
        d->commConfig.dcb.fRtsControl = RTS_CONTROL_DISABLE;
        d->commConfig.dcb.fInX = FALSE;
        d->commConfig.dcb.fOutX = FALSE;
        break;
    case XonXoffFlowControl:
        d->commConfig.dcb.fOutxCtsFlow = FALSE;
        d->commConfig.dcb.fRtsControl = RTS_CONTROL_DISABLE;
        d->commConfig.dcb.fInX = TRUE;
        d->commConfig.dcb.fOutX = TRUE;
        break;
    case HardwareFlowControl:
        d->commConfig.dcb.fOutxCtsFlow = TRUE;
        d->commConfig.dcb.fRtsControl = RTS_CONTROL_HANDSHAKE;
        d->commConfig.dcb.fInX = FALSE;
        d->commConfig.dcb.fOutX = FALSE;
        break;
    }
    SetCommConfig(d->portHandle, &d->commConfig, sizeof(COMMCONFIG));
#else // Q_OS_WIN32
    switch (d->settings.flowControl) {
    case NoFlowControl:
        d->commConfig.c_cflag &= ~CRTSCTS;
        d->commConfig.c_iflag &= ~(IXON | IXOFF | IXANY);
        break;
    case XonXoffFlowControl:
        d->commConfig.c_cflag &= ~CRTSCTS;
        d->commConfig.c_iflag |= IXON | IXOFF | IXANY;
        break;
    case HardwareFlowControl:
        d->commConfig.c_cflag |= CRTSCTS;
        d->commConfig.c_iflag &= ~(IXON | IXOFF | IXANY);
        break;
    }
    tcsetattr(d->portHandle, TCSAFLUSH, &d->commConfig);
#endif // Q_OS_WIN32
}

SerialPort::FlowControl SerialPort::flowControl() const
{
    Q_D(const SerialPort);
    return d->settings.flowControl;
}

void SerialPort::setTimeout(ulong ms)
{
    Q_D(SerialPort);
    QMutexLocker(d->mutex);

    d->settings.timeout = ms;

    if (!isOpen())
        return;

#ifdef Q_OS_WIN32
    d->timeout.ReadIntervalTimeout = MAXDWORD;
    d->timeout.ReadTotalTimeoutMultiplier = ms;
    d->timeout.ReadTotalTimeoutConstant = 0;
    d->timeout.WriteTotalTimeoutMultiplier = ms;
    d->timeout.WriteTotalTimeoutConstant = 0;
    SetCommTimeouts(d->portHandle, &d->timeout);
#else // Q_OS_WIN32
    d->timeout.tv_sec  = ms / 1000;
    d->timeout.tv_usec = ms % 1000;
    tcgetattr(d->portHandle, &d->commConfig);
    d->commConfig.c_cc[VTIME] = ms / 100;
    tcsetattr(d->portHandle, TCSAFLUSH, &d->commConfig);
#endif // Q_OS_WIN32
}

ulong SerialPort::timeout() const
{
    Q_D(const SerialPort);
    return d->settings.timeout;
}

void SerialPort::setAutoFlushOnWrite(bool enabled)
{
    Q_D(SerialPort);
    QMutexLocker(d->mutex);

    if (d->autoFlushOnWrite == enabled)
        return;
    d->autoFlushOnWrite = enabled;
    Q_EMIT autoFlushOnWriteChanged(enabled);
}

bool SerialPort::autoFlushOnWrite() const
{
    Q_D(const SerialPort);
    return d->autoFlushOnWrite;
}

SerialPort::Settings SerialPort::settings() const
{
    Q_D(const SerialPort);
    return d->settings;
}

SerialPort::LineStatus SerialPort::lineStatus() const
{
    Q_D(const SerialPort);
    QMutexLocker(d->mutex);

    LineStatus status = NoLineState;

    if (!isOpen())
        return status;

    ulong tmp = 0;
#ifdef Q_OS_WIN32
    if (GetCommModemStatus(d->portHandle, &tmp)) {
        if (tmp & MS_CTS_ON) status |= CtsLineState;
        if (tmp & MS_DSR_ON) status |= DsrLineState;
        if (tmp & MS_RING_ON) status |= RiLineState;
        if (tmp & MS_RLSD_ON) status |= DcdLineState;
    }
#else // Q_OS_WIN32
    if (0 == ioctl(d->portHandle, TIOCMGET, &tmp)) {
        if (tmp & TIOCM_CTS) status |= CtsLineState;
        if (tmp & TIOCM_DSR) status |= DsrLineState;
        if (tmp & TIOCM_RI) status |= RiLineState;
        if (tmp & TIOCM_CD) status |= DcdLineState;
        if (tmp & TIOCM_DTR) status |= DtrLineState;
        if (tmp & TIOCM_RTS) status |= RtsLineState;
        if (tmp & TIOCM_ST) status |= StLineState;
        if (tmp & TIOCM_SR) status |= SrLineState;
    }
#endif // Q_OS_WIN32

    return status;
}

bool SerialPort::DSR() const
{
    Q_D(const SerialPort);
    QMutexLocker(d->mutex);

    LineStatus status = lineStatus();
    return status.testFlag(DsrLineState);
}

void SerialPort::setDTR(bool value)
{
    Q_D(SerialPort);
    QMutexLocker(d->mutex);

    if (!isOpen())
        return;

#ifdef Q_OS_WIN32
    EscapeCommFunction(d->portHandle, (value) ? SETDTR : CLRDTR);
#else // Q_OS_WIN32
    int status;
    ioctl(d->portHandle, TIOCMGET, &status);
    if (value)
        status |= TIOCM_DTR;
    else
        status &= ~TIOCM_DTR;
    ioctl(d->portHandle, TIOCMSET, &status);
#endif // Q_OS_WIN32
}

bool SerialPort::CTS() const
{
    Q_D(const SerialPort);
    QMutexLocker(d->mutex);

    const LineStatus status = lineStatus();
    return status.testFlag(CtsLineState);
}

void SerialPort::setRTS(bool value)
{
    Q_D(SerialPort);
    QMutexLocker(d->mutex);

    if (!isOpen())
        return;

#ifdef Q_OS_WIN32
    EscapeCommFunction(d->portHandle, (value) ? SETRTS : CLRRTS);
#else // Q_OS_WIN32
    int status;
    ioctl(d->portHandle, TIOCMGET, &status);
    if (value)
        status |= TIOCM_RTS;
    else
        status &= ~TIOCM_RTS;
    ioctl(d->portHandle, TIOCMSET, &status);
#endif // Q_OS_WIN32
}

void SerialPort::flush()
{
    Q_D(SerialPort);
    QMutexLocker(d->mutex);

    if (!isOpen())
        return;

#ifdef Q_OS_WIN32
    FlushFileBuffers(d->portHandle);
#else // Q_OS_WIN32
    tcdrain(d->portHandle);
#endif // Q_OS_WIN32
}

void SerialPort::purge()
{
    Q_D(SerialPort);
    QMutexLocker(d->mutex);

    if (!isOpen())
        return;

#ifdef Q_OS_WIN32
    const int flags =
        PURGE_TXABORT | PURGE_TXCLEAR | PURGE_RXABORT | PURGE_RXCLEAR;
    PurgeComm(d->portHandle, flags);
#else // Q_OS_WIN32
    tcflush(d->portHandle, TCIOFLUSH);
#endif // Q_OS_WIN32
}

SerialPort::Error SerialPort::lastError() const
{
    Q_D(const SerialPort);
    return d->lastError;
}

void SerialPort::clearLastError()
{
    Q_D(SerialPort);
    d->lastError = NoError;
}

/*******************************************************************************
    SerialPort - public methods - override QIODevice methods
*******************************************************************************/

bool SerialPort::isSequential() const
{
    return true;
}

bool SerialPort::open(OpenMode mode)
{
    Q_D(SerialPort);
    QMutexLocker(d->mutex);

    if (mode == QIODevice::NotOpen)
        return isOpen();

    if (isOpen())
        return true;

    if (portName().isEmpty())
        return false;

#ifdef Q_OS_WIN32
    d->portHandle = CreateFileA(d->portName.toLocal8Bit(), GENERIC_READ
            | GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL,
            OPEN_EXISTING, 0, NULL);
    if (d->portHandle == INVALID_HANDLE_VALUE) {
        d->lastError = OpenFailedError;
        return false;
    }

    QIODevice::open(mode | QIODevice::Unbuffered);

    ulong commConfigSize = sizeof(COMMCONFIG);
    d->commConfig.dwSize = commConfigSize;

    GetCommConfig(d->portHandle, &d->commConfig, &commConfigSize);
    GetCommState(d->portHandle, &(d->commConfig.dcb));

    d->commConfig.dcb.fBinary = TRUE;
    d->commConfig.dcb.fInX = FALSE;
    d->commConfig.dcb.fOutX = FALSE;
    d->commConfig.dcb.fAbortOnError = FALSE;
    d->commConfig.dcb.fNull = FALSE;

    SetCommConfig(d->portHandle, &d->commConfig, sizeof(COMMCONFIG));
#else // Q_OS_WIN32

    /**
     * Open the Serial Device In Non-Blocking, unbuffered mode, Otherwise the Program hangs forever
     * If the port doesnt see a CTS Signal
     */
    d->portHandle = ::open(d->portName.toLocal8Bit(), O_RDWR | O_NOCTTY | O_NONBLOCK |O_SYNC);
    if (d->portHandle == INVALID_HANDLE_VALUE) {
        d->lastError = OpenFailedError;
        m_errno = errno;
        return false;
    }
    /**
      * Send a dummy message to work DTR
      */
    ::write(d->portHandle,"hello",5);

    /**
     * Close and Re-open the Port. This Seems to Wake up the Z88
     */
    ::close(d->portHandle);

    d->portHandle = ::open(d->portName.toLocal8Bit(), O_RDWR | O_NOCTTY | O_NONBLOCK |O_SYNC);

    QIODevice::open(mode | QIODevice::Unbuffered);

    tcgetattr(d->portHandle, &d->commConfig);

    d->commConfig.c_cflag |= CREAD | CLOCAL | HUPCL;
    d->commConfig.c_lflag &=
        ~(ICANON | ECHO | ECHOE | ECHOK | ECHONL | ISIG);
    d->commConfig.c_iflag &=
        ~(INPCK | IGNPAR | PARMRK | ISTRIP | ICRNL | IXANY);
    d->commConfig.c_oflag &= ~OPOST;

    d->commConfig.c_cc[VMIN] = 0;
    d->commConfig.c_cc[VINTR] = _POSIX_VDISABLE;
    d->commConfig.c_cc[VQUIT] = _POSIX_VDISABLE;
    d->commConfig.c_cc[VSTART] = _POSIX_VDISABLE;
    d->commConfig.c_cc[VSTOP] = _POSIX_VDISABLE;
    d->commConfig.c_cc[VSUSP] = _POSIX_VDISABLE;

    tcsetattr(d->portHandle, TCSAFLUSH, &d->commConfig);
#endif

    setBaudRate(d->settings.baudRate);
    setDataBits(d->settings.dataBits);
    setFlowControl(d->settings.flowControl);
    setParity(d->settings.parity);
    setStopBits(d->settings.stopBits);
    setTimeout(d->settings.timeout);
    return isOpen();
}

void SerialPort::close()
{
    Q_D(SerialPort);
    QMutexLocker(d->mutex);

    if (!isOpen())
        return;

    purge();

#ifdef Q_OS_WIN32
    CloseHandle(d->portHandle);
#else // Q_OS_WIN32
    ::close(d->portHandle);
#endif // Q_OS_WIN32

    d->portHandle = INVALID_HANDLE_VALUE;
    QIODevice::close();
}

qint64 SerialPort::size() const
{
    Q_D(const SerialPort);
    QMutexLocker(d->mutex);

    if (!isOpen())
        return 0;

    qint64 size = 0;

#ifdef Q_OS_WIN32
    COMSTAT stat;
    if (ClearCommError(d->portHandle, NULL, &stat))
        size = stat.cbInQue;
#else // Q_OS_WIN32
    int bytesQueued;
    if (ioctl(d->portHandle, FIONREAD, &bytesQueued) >= 0)
        size = bytesQueued;
#endif // Q_OS_WIN32

    return size;
}

qint64 SerialPort::bytesAvailable()
{
    Q_D(SerialPort);
    QMutexLocker(d->mutex);

    if (!isOpen())
        return 0;

    qint64 bytesAvailable;

#ifdef Q_OS_WIN32
    COMSTAT status;
    if (!ClearCommError(d->portHandle, NULL, &status))
        return 0;
    bytesAvailable = status.cbInQue;
#else // Q_OS_WIN32
    fd_set fileSet;
    FD_ZERO(&fileSet);
    FD_SET(d->portHandle, &fileSet);
    struct timeval timeoutCopy;
    memcpy(&timeoutCopy, &d->timeout, sizeof(struct timeval));
    const int n = select(d->portHandle + 1, &fileSet, 0, &fileSet, &d->timeout);
    memcpy(&d->timeout, &timeoutCopy, sizeof(struct timeval));
    if (n == 0) {
//        d->lastError = PortTimeoutError;
        return 0;
    }
    int bytesRead = 0;
    if (n == -1 || ioctl(d->portHandle, FIONREAD, &bytesRead) == -1)
        return 0;
    bytesAvailable = bytesRead;
#endif // Q_OS_WIN32

//    d->lastError = NoError;
    bytesAvailable += QIODevice::bytesAvailable();
    return bytesAvailable;
}

bool SerialPort::atEnd() const
{
    return (size() != 0);
}

void SerialPort::ungetChar(char)
{
    /*
    Q_D(SerialPort);
    d->warning("ungetChar() called on an unbuffered sequential device - "
            "operation is meaningless");
    */
}

/*******************************************************************************
    SerialPort - protected methods
*******************************************************************************/

qint64 SerialPort::readData(char *data, qint64 maxSize)
{
    Q_D(SerialPort);
    QMutexLocker(d->mutex);

    qint64 retVal = 0;

#ifdef Q_OS_WIN32
    int timeout = d->settings.timeout;
    while (bytesAvailable() < maxSize && timeout > 0) {
        Sleep(1);
        timeout--;
    }
    if (timeout == 0 && bytesAvailable() == 0) {
        d->lastError = SerialPort::PortTimeoutError;
        return -1;
    }
    COMSTAT comStat;
    BOOL success = ClearCommError(d->portHandle, NULL, &comStat);
    DWORD bytesRead = 0;
    success = success && ReadFile(d->portHandle, (void *)data, (DWORD)maxSize,
            &bytesRead, NULL);
    success = comStat.cbInQue <= 0 || (success && bytesRead > 0);
    if (!success) {
        d->lastError = ReadFailedError;
        return -1;
    }
    retVal = static_cast<qint64>(bytesRead);
#else // Q_OS_WIN32
    int timeout = d->settings.timeout;
    while (bytesAvailable() < maxSize && timeout > 0) {
        usleep(1000);
        timeout--;
    }
    if (timeout == 0 && bytesAvailable() == 0) {
        d->lastError = SerialPort::PortTimeoutError;
        return -1;
    }
    retVal = ::read(d->portHandle, (void*)data, (size_t)maxSize);
    if (retVal == -1)
        d->lastError = ReadFailedError;
#endif // Q_OS_WIN32

    return retVal;
}

qint64 SerialPort::writeData(const char *data, qint64 maxSize)
{
    Q_D(SerialPort);
    QMutexLocker(d->mutex);

    qint64 retVal = 0;

#ifdef Q_OS_WIN32
    DWORD bytesWritten;
    const BOOL success = WriteFile(d->portHandle, (void *)data, (DWORD)maxSize,
            &bytesWritten, NULL);
    if (!success)
        d->lastError = WriteFailedError;
    retVal = (success) ? static_cast<qint64>(bytesWritten) : -1;
#else // Q_OS_WIN32
    retVal = ::write(d->portHandle, (void *)data, static_cast<size_t>(maxSize));
    if (retVal == -1)
        d->lastError = WriteFailedError;
#endif // Q_OS_WIN32

    if (d->autoFlushOnWrite)
        flush();
    return retVal;
}

/*******************************************************************************
    SerialPortPrivate
*******************************************************************************/

SerialPortPrivate::SerialPortPrivate(SerialPort *q)
    : q_ptr(q),
    mutex(new QMutex(QMutex::Recursive)),
    autoFlushOnWrite(false),
    portHandle(INVALID_HANDLE_VALUE)
{
#ifdef Q_OS_WIN32
    platformBaudRateHash[SerialPort::BaudRate_110] = CBR_110;
    platformBaudRateHash[SerialPort::BaudRate_300] = CBR_300;
    platformBaudRateHash[SerialPort::BaudRate_600] = CBR_600;
    platformBaudRateHash[SerialPort::BaudRate_1200] = CBR_1200;
    platformBaudRateHash[SerialPort::BaudRate_2400] = CBR_2400;
    platformBaudRateHash[SerialPort::BaudRate_4800] = CBR_4800;
    platformBaudRateHash[SerialPort::BaudRate_9600] = CBR_9600;
    platformBaudRateHash[SerialPort::BaudRate_19200] = CBR_19200;
    platformBaudRateHash[SerialPort::BaudRate_38400] = CBR_38400;
    platformBaudRateHash[SerialPort::BaudRate_57600] = CBR_57600;
    platformBaudRateHash[SerialPort::BaudRate_115200] = CBR_115200;
#ifndef QTCOMMUNICATION_SERIALPORT_MULTIPLATFORM_BAUD_RATES_ONLY
    platformBaudRateHash[SerialPort::BaudRate_50] = CBR_110;
    platformBaudRateHash[SerialPort::BaudRate_75] = CBR_110;
    platformBaudRateHash[SerialPort::BaudRate_134] = CBR_110;
    platformBaudRateHash[SerialPort::BaudRate_150] = CBR_110;
    platformBaudRateHash[SerialPort::BaudRate_200] = CBR_110;
    platformBaudRateHash[SerialPort::BaudRate_1800] = CBR_1200;
    platformBaudRateHash[SerialPort::BaudRate_14400] = CBR_14400;
    platformBaudRateHash[SerialPort::BaudRate_56000] = CBR_56000;
    platformBaudRateHash[SerialPort::BaudRate_76800] = CBR_57600;
    platformBaudRateHash[SerialPort::BaudRate_128000] = CBR_128000;
    platformBaudRateHash[SerialPort::BaudRate_256000] = CBR_256000;
#endif // QTCOMMUNICATION_SERIALPORT_MULTIPLATFORM_BAUD_RATES_ONLY
#else // Q_OS_WIN32
    platformBaudRateHash[SerialPort::BaudRate_110] = B110;
    platformBaudRateHash[SerialPort::BaudRate_300] = B300;
    platformBaudRateHash[SerialPort::BaudRate_600] = B600;
    platformBaudRateHash[SerialPort::BaudRate_1200] = B1200;
    platformBaudRateHash[SerialPort::BaudRate_2400] = B2400;
    platformBaudRateHash[SerialPort::BaudRate_4800] = B4800;
    platformBaudRateHash[SerialPort::BaudRate_9600] = B9600;
    platformBaudRateHash[SerialPort::BaudRate_19200] = B19200;
    platformBaudRateHash[SerialPort::BaudRate_38400] = B38400;
    platformBaudRateHash[SerialPort::BaudRate_57600] = B57600;
    platformBaudRateHash[SerialPort::BaudRate_115200] = B115200;
#ifndef QTCOMMUNICATION_SERIALPORT_MULTIPLATFORM_BAUD_RATES_ONLY
    platformBaudRateHash[SerialPort::BaudRate_0] = B0;
    platformBaudRateHash[SerialPort::BaudRate_50] = B50;
    platformBaudRateHash[SerialPort::BaudRate_75] = B75;
    platformBaudRateHash[SerialPort::BaudRate_134] = B134;
    platformBaudRateHash[SerialPort::BaudRate_150] = B150;
    platformBaudRateHash[SerialPort::BaudRate_200] = B200;
    platformBaudRateHash[SerialPort::BaudRate_1800] = B1800;
    platformBaudRateHash[SerialPort::BaudRate_14400] = B9600;
    platformBaudRateHash[SerialPort::BaudRate_56000] = B38400;
#ifdef B76800
    platformBaudRateHash[SerialPort::BaudRate_76800] = B76800;
#else // B76800
    platformBaudRateHash[SerialPort::BaudRate_76800] = B57600;
#endif // B76800
    platformBaudRateHash[SerialPort::BaudRate_128000] = B115200;
    platformBaudRateHash[SerialPort::BaudRate_256000] = B115200;
#ifndef QTCOMMUNICATION_SERIALPORT_BAUD_RATES_UP_TO_256KBPS_ONLY
#ifndef Q_OS_MAC
    platformBaudRateHash[SerialPort::BaudRate_230400] = B230400;
    platformBaudRateHash[SerialPort::BaudRate_460800] = B460800;
    platformBaudRateHash[SerialPort::BaudRate_500000] = B500000;
    platformBaudRateHash[SerialPort::BaudRate_576000] = B576000;
    platformBaudRateHash[SerialPort::BaudRate_921600] = B921600;
    platformBaudRateHash[SerialPort::BaudRate_1000000] = B1000000;
    platformBaudRateHash[SerialPort::BaudRate_1152000] = B1152000;
    platformBaudRateHash[SerialPort::BaudRate_1500000] = B1500000;
    platformBaudRateHash[SerialPort::BaudRate_2000000] = B2000000;
    platformBaudRateHash[SerialPort::BaudRate_2500000] = B2500000;
    platformBaudRateHash[SerialPort::BaudRate_3000000] = B3000000;
    platformBaudRateHash[SerialPort::BaudRate_3500000] = B3500000;
    platformBaudRateHash[SerialPort::BaudRate_4000000] = B4000000;
#endif // Q_OS_MAC
#endif // QTCOMMUNICATION_SERIALPORT_BAUD_RATES_UP_TO_256KBPS_ONLY
#endif // QTCOMMUNICATION_SERIALPORT_MULTIPLATFORM_BAUD_RATES_ONLY
#endif // Q_OS_WIN32

#ifdef Q_OS_WIN32
    memset(&commConfig, 0, sizeof(COMMCONFIG));
    memset(&(commConfig.dcb), 0, sizeof(DCB));
    commConfig.dwSize = sizeof(COMMCONFIG);
    commConfig.dcb.DCBlength = sizeof(DCB);
#endif // Q_OS_WIN32

    portName.clear();
    settings.baudRate = SerialPort::BaudRate_19200;
    settings.dataBits = SerialPort::EightDataBits;
    settings.flowControl = SerialPort::NoFlowControl;
    settings.parity = SerialPort::NoParity;
    settings.stopBits = SerialPort::OneStopBit;
    settings.timeout = 500;
}

SerialPortPrivate::~SerialPortPrivate()
{
    Q_Q(SerialPort);

    if (q->isOpen())
        q->close();

    delete mutex;
    portHandle = INVALID_HANDLE_VALUE;
}

SerialPort::BaudRate SerialPortPrivate::baudRate_NumberToEnum(uint baudRate)
    const
{
    const SerialPort::BaudRate baudRateEnum =
        static_cast<SerialPort::BaudRate>(baudRate);
    if (platformBaudRateHash.keys().contains(baudRateEnum))
        return baudRateEnum;
    else
        return SerialPort::BaudRate_Invalid;
}

uint SerialPortPrivate::baudRate_EnumToNumber(SerialPort::BaudRate baudRate)
    const
{
    return static_cast<uint>(baudRate);
}




