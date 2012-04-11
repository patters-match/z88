#-------------------------------------------------
#
# Project created by QtCreator 2011-10-07T00:27:24
#
#-------------------------------------------------

QT       += core gui

TARGET = eazylink2
TEMPLATE = app


SOURCES += main.cpp\
        mainwindow.cpp\
        serialport.cpp \ 
    z88serialport.cpp \
    serialportsavail.cpp \
    commthread.cpp \
    z88_devview.cpp \
    z88storageviewer.cpp \
    z88filespec.cpp \
    desktop_view.cpp

HEADERS  += mainwindow.h\
         serialport.h\
         serialport_p.h \
    z88serialport.h \
    serialportsavail.h \
    commthread.h \
    z88_devview.h \
    z88storageviewer.h \
    z88filespec.h \
    desktop_view.h

FORMS    += mainwindow.ui
