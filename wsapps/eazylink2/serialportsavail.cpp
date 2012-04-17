/*********************************************************************************************
 EazyLink2 - Fast Client/Server Z88 File Management
 (C) Gunther Strube (gstrube@gmail.com) & Oscar Ernohazy 2012

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
#ifndef Q_OS_WINDOWS
#include <dirent.h>
#endif

#include "serialport.h"
#include "serialportsavail.h"

#ifdef Q_OS_WINDOWS
static const char *DEV_DIR_FSPEC("COM");
#else
static const char *DEV_DIR_FSPEC("/dev/");
#endif

#ifdef Q_OS_MAC
static const QString SER_DEV_MASK("tty.");
#endif
#ifdef Q_OS_LINUX
static const QString SER_DEV_MASK("ttyS");
static const QString SER_DEV_MASK_USB("ttyUSB");
#endif

/**
  * Default constructor.
  */
SerialPortsAvail::SerialPortsAvail()
{
}

/**
  * The Destructor
  */
SerialPortsAvail::~SerialPortsAvail(){}

#ifndef Q_OS_WINDOWS
/**
 * Obtain a list of available Serial ports on Unix
 * @return a list of serial port filenames.
 */
const QStringList&
SerialPortsAvail::get_portList()
{
    SerialPort port = SerialPort();
    QString devStr;

    /**
     * Fill the List with Serial port filenames
     */
    DIR *dirp = opendir(DEV_DIR_FSPEC);
    m_portlist.clear();
    m_portName.clear();

    if(!dirp){
        return m_portlist;
    }

    /**
     * Find all Matching device names
     */
    struct dirent *dp;

    while ((dp = readdir(dirp)) != NULL){
#ifdef Q_OS_LINUX
        if (dp->d_reclen){
#else
        if (dp->d_namlen){
#endif
            /**
             * Append the portname found
             */
            QString st(dp->d_name);
#ifdef Q_OS_LINUX
            if(st.contains(SER_DEV_MASK) || st.contains(SER_DEV_MASK_USB)){
#else
            if(st.contains(SER_DEV_MASK)){
#endif
                devStr.append(DEV_DIR_FSPEC);
                devStr.append(dp->d_name);
                port.setPortName(devStr);
                if (port.open(QIODevice::ReadWrite)) {
                    m_portlist << dp->d_name;
                    port.close();
                }
                devStr.clear();
            }
        }
    }

    closedir(dirp);

    if(!m_portlist.isEmpty()){
        m_portName = DEV_DIR_FSPEC + m_portlist.first();
    }
    return m_portlist;
}

#else

/**
 * Obtain a list of first 9 (COM1 to COM9) available Serial ports in Windows
 * @return a list of serial port filenames.
 */
const QStringList&
SerialPortsAvail::get_portList()
{
    SerialPort port = SerialPort();
    QString devStr;

    m_portlist.clear();
    m_portName.clear();

    for(int p=49; p<(49+8); p++){

            /**
             * Append the portname found
             */
                devStr.append(DEV_DIR_FSPEC);
                devStr.append(p);
                port.setPortName(devStr);
                if (port.open(QIODevice::ReadWrite)) {
                    if(!m_portlist.isEmpty()){
                        m_portName = devStr;
                    }

                    m_portlist << devStr;
                    port.close();
                }
                devStr.clear();
            }

    return m_portlist;
}
#endif


/**
  * The the name of the first port available in the list.
  * @return the name of the first port.
  */
const QString &
SerialPortsAvail::getfirst_portName() const
{
    return m_portName;
}

/**
  * get the Fully qualified port name of the First available port.
  * @return the filename of the first port, or the path /dev/ if none.
  */
const QString &
SerialPortsAvail::get_fullportName(const QString &devname)
{
#ifndef Q_OS_WINDOWS
    m_portName = DEV_DIR_FSPEC + devname;
#else
    m_portName = devname;
#endif

    return m_portName;
}
