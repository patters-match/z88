#include <QtGui/QApplication>
#include <QtCore/QTextStream>
#include "mainwindow.h"
#include "z88serialport.h"

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    MainWindow w;
    Z88SerialPort p;

    if ( p.open() == true ) {
        p.helloZ88();
        p.getDevices();
        p.getDirectories(":RAM.1//*");
        p.getFilenames(":EPR.3");
        //p.quitZ88();
        p.close();
    }
    w.show();

    return a.exec();
}
