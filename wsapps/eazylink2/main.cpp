#include <QtGui/QApplication>
#include <QtCore/QTextStream>
#include "mainwindow.h"
#include "z88serialport.h"

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    MainWindow w;
    Z88SerialPort p;

    if ( p.open("/dev/ttyUSB0") == true ) {
        p.helloZ88();
        p.close();
    }
    w.show();

    return a.exec();
}
