/*******************************************************************************

 Copyright (C) 2010 Tomáš Hanák <tomas.hanak@gmail.com>
 Reduced/edited for EazyLink2 by Gunther Strube <gstrube@gmail.com>

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

#ifndef QTCOMMUNICATION_SERIALPORT_H
#define QTCOMMUNICATION_SERIALPORT_H

#include <QtCore/QIODevice>

class SerialPortPrivate;

/**
  * The Serial Port Communications Class.
  * Inherits from QIODevice to Abstract the Host OS Differences.
  */
class SerialPort : public QIODevice
{
    Q_OBJECT
    Q_PROPERTY(QString portName
            READ portName WRITE setPortName NOTIFY portNameChanged)
    Q_PROPERTY(BaudRate baudRate
            READ baudRate WRITE setBaudRate NOTIFY baudRateChanged)
    Q_PROPERTY(DataBits dataBits
            READ dataBits WRITE setDataBits NOTIFY dataBitsChanged)
    Q_PROPERTY(Parity parity
            READ parity WRITE setParity NOTIFY parityChanged)
    Q_PROPERTY(StopBits stopBits
            READ stopBits WRITE setStopBits NOTIFY stopBitsChanged)
    Q_PROPERTY(FlowControl flowControl
            READ flowControl WRITE setFlowControl NOTIFY flowControlChanged)
    Q_PROPERTY(bool autoFlushOnWrite
            READ autoFlushOnWrite WRITE setAutoFlushOnWrite
            NOTIFY autoFlushOnWriteChanged)
    Q_PROPERTY(LineStatus lineStatus READ lineStatus)
    Q_PROPERTY(Error lastError READ lastError)
    Q_ENUMS(BaudRate)
    Q_ENUMS(DataBits)
    Q_ENUMS(Parity)
    Q_ENUMS(StopBits)
    Q_ENUMS(FlowControl)
    Q_ENUMS(LineState)
    Q_ENUMS(Error)

public:
    enum BaudRate {
        BaudRate_Invalid = -1,
        BaudRate_110 = 110,
        BaudRate_300 = 300,
        BaudRate_600 = 600,
        BaudRate_1200 = 1200,
        BaudRate_2400 = 2400,
        BaudRate_4800 = 4800,
        BaudRate_9600 = 9600,
        BaudRate_19200 = 19200,
        BaudRate_38400 = 38400,
        BaudRate_57600 = 57600,
        BaudRate_115200 = 115200,
#ifndef QTCOMMUNICATION_SERIALPORT_MULTIPLATFORM_BAUD_RATES_ONLY
#ifdef Q_OS_WIN32
        BaudRate_50 = BaudRate_110,
        BaudRate_75 = BaudRate_110,
        BaudRate_134 = BaudRate_110,
        BaudRate_150 = BaudRate_110,
        BaudRate_200 = BaudRate_110,
        BaudRate_1800 = BaudRate_1200,
        BaudRate_14400 = 14400,
        BaudRate_56000 = 56000,
        BaudRate_76800 = BaudRate_57600,
        BaudRate_128000 = 128000,
        BaudRate_230400 = BaudRate_128000,
        BaudRate_256000 = 256000,
#else // Q_OS_WIN32
        BaudRate_0 = 0, // Hang up
        BaudRate_50 = 50,
        BaudRate_75 = 75,
        BaudRate_134 = 134,
        BaudRate_150 = 150,
        BaudRate_200 = 200,
        BaudRate_1800 = 1800,
        BaudRate_14400 = BaudRate_9600,
        BaudRate_56000 = BaudRate_38400,
#ifdef B76800
        BaudRate_76800 = 76800,
#else // B76800
        BaudRate_76800 = BaudRate_57600,
#endif // B76800
        BaudRate_128000 = BaudRate_115200,
        BaudRate_230400 = 230400,
        BaudRate_256000 = BaudRate_115200,
#ifndef QTCOMMUNICATION_SERIALPORT_BAUD_RATES_UP_TO_256KBPS_ONLY
#ifndef Q_OS_MAC
        BaudRate_460800 = 460800,
        BaudRate_500000 = 500000,
        BaudRate_576000 = 576000,
        BaudRate_921600 = 921600,
        BaudRate_1000000 = 1000000,
        BaudRate_1152000 = 1152000,
        BaudRate_1500000 = 1500000,
        BaudRate_2000000 = 2000000,
        BaudRate_2500000 = 2500000,
        BaudRate_3000000 = 3000000,
        BaudRate_3500000 = 3500000,
        BaudRate_4000000 = 4000000,
#endif // Q_OS_MAC
#endif // QTCOMMUNICATION_SERIALPORT_BAUD_RATES_UP_TO_256KBPS_ONLY
#endif // Q_OS_WIN32
#endif // QTCOMMUNICATION_SERIALPORT_MULTIPLATFORM_BAUD_RATES_ONLY
    };

    enum DataBits {
        FiveDataBits = 5,
        SixDataBits = 6,
        SevenDataBits = 7,
        EightDataBits = 8
    };

    enum Parity {
        NoParity,
        OddParity,
        EvenParity,
        MarkParity, // WINDOWS only
        SpaceParity
    };

    enum StopBits {
        OneStopBit,
        OneAndHalfStopBits, // WINDOWS only
        TwoStopBits
    };

    enum FlowControl {
        NoFlowControl,
        HardwareFlowControl,
        XonXoffFlowControl
    };

    enum LineState {
        NoLineState = 0x00,
        CtsLineState = 0x01,
        DsrLineState = 0x02,
        DcdLineState = 0x04,
        RiLineState = 0x08,
        RtsLineState = 0x10,
        DtrLineState = 0x20,
        StLineState = 0x40,
        SrLineState = 0x80
    };
    Q_DECLARE_FLAGS(LineStatus, LineState);

    enum Error {
        NoError,
        OpenFailedError,
        ReadFailedError,
        WriteFailedError,
        PortTimeoutError,
        InvalidSettingsError
    };

    // Structure containing port settings
    struct Settings {
        BaudRate baudRate;
        DataBits dataBits;
        FlowControl flowControl;
        Parity parity;
        StopBits stopBits;
        ulong timeout;
    };

    int m_errno;

public:
    SerialPort(QObject *parent = 0);
    SerialPort(const QString &portName, QObject *parent = 0);
    SerialPort(const Settings &settings, QObject *parent = 0);
    SerialPort(const QString &portName, const Settings &settings, QObject
            *parent = 0);
    SerialPort(const SerialPort &serialPort);
    SerialPort &operator=(const SerialPort &serialPort);
    virtual ~SerialPort();

public:
    void setPortName(const QString &portName);
    QString portName() const;

    void setBaudRate(BaudRate baudRate);
    BaudRate baudRate() const;
    QList<BaudRate> supportedBaudRates() const;

    bool setBaudRateFromNumber(uint baudRate);
    uint baudRateAsNumber() const;
    QList<uint> supportedBaudRatesAsNumber() const;

    void setDataBits(DataBits dataBits);
    DataBits dataBits() const;

    void setParity(Parity parity);
    Parity parity() const;

    void setStopBits(StopBits stopBits);
    StopBits stopBits() const;

    void setFlowControl(FlowControl flowControl);
    FlowControl flowControl() const;

    void setTimeout(ulong ms);
    ulong timeout() const;

    void setAutoFlushOnWrite(bool enabled);
    bool autoFlushOnWrite() const;

    Settings settings() const;

    LineStatus lineStatus() const;
    bool DSR() const;
    void setDTR(bool value);
    bool CTS() const;
    void setRTS(bool value);

    void flush();
    void purge();

    Error lastError() const;
    void clearLastError();

public: // QIODevice
    virtual bool isSequential() const;

    virtual bool open(OpenMode mode);
    virtual void close();

    virtual qint64 size() const;
    virtual qint64 bytesAvailable();
    virtual bool atEnd() const;
    virtual void ungetChar(char c);

protected: // QIODevice
    virtual qint64 readData(char *data, qint64 maxSize);
    virtual qint64 writeData(const char *data, qint64 maxSize);

Q_SIGNALS:
    void portNameChanged(const QString &newPortName);
    void baudRateChanged(BaudRate newValue);
    void dataBitsChanged(DataBits newDataBits);
    void parityChanged(Parity newParity);
    void stopBitsChanged(StopBits newStopBits);
    void flowControlChanged(FlowControl newFlowControl);
    void autoFlushOnWriteChanged(bool newValue);

private:
    Q_DECLARE_PRIVATE(SerialPort);
    SerialPortPrivate *d_ptr;
};

#endif // QTCOMMUNICATION_SERIALPORT_H
