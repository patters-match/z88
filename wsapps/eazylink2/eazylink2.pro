#-------------------------------------------------
#
# Qt Project for EazyLink II
#
#-------------------------------------------------

QT       += core gui

TARGET = eazylink2
TEMPLATE = app

SOURCES += main.cpp\
mainwindow.cpp\
serialport.cpp \
z88serialport.cpp \
commthread.cpp \
z88_devview.cpp \
z88storageviewer.cpp \
z88filespec.cpp \
desktop_view.cpp \
serialportsavail.cpp \
    prefrences_dlg.cpp

HEADERS += mainwindow.h\
serialport.h\
serialport_p.h \
z88serialport.h \
serialportsavail.h \
commthread.h \
z88_devview.h \
z88storageviewer.h \
z88filespec.h \
desktop_view.h \
    prefrences_dlg.h

FORMS    += mainwindow.ui \
    prefrences_dlg.ui

RESOURCES += \
    images.qrc
