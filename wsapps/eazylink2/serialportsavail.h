/*********************************************************************************************

 EazyLink2 - Fast Client/Server Z88 File Management
 (C) Gunther Strube (gstrube@gmail.com) 2011
  & Oscar Ernohazy 2012

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
#ifndef SERIALPORTSAVAIL_H
#define SERIALPORTSAVAIL_H

#include <QStringList>

/**
  * Serial ports available container class.
  * Retreives the available serial ports on the Host machine.
  */
class SerialPortsAvail
{
public:
    SerialPortsAvail();
    ~SerialPortsAvail();

    const QStringList& get_portList();
    const QString &getfirst_portName() const;
    const QString &get_fullportName(const QString &portname);

protected:
    /**
      * The list of portnames
      */
    QStringList m_portlist;

    /**
      * The selected Port name
      */
    QString m_portName;
};

#endif // SERIALPORTSAVAIL_H
