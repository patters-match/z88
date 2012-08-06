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

#include <QCoreApplication>
#include <QtGui/QApplication>
#include <QtCore/QTime>
#include <QtCore/QTextStream>
#include <QSplashScreen>

#include "mainwindow.h"
#include "z88serialport.h"

int main(int argc, char *argv[])
{
    QCoreApplication::setApplicationVersion("1.0 beta 1a");
    QCoreApplication::setOrganizationDomain("cambridgez88.jira.com");

    QApplication a(argc, argv);
    Z88SerialPort p;
    MainWindow w(p);

    w.show();
    return a.exec();
}
