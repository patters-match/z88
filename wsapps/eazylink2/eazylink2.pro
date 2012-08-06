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
    prefrences_dlg.cpp \
    actionsettings.cpp \
    setupwizard.cpp \
    setupwiz_intro.cpp \
    setupwiz_modeselect.cpp \
    setupwiz_serialselect.cpp \
    setupwiz_finalpage.cpp

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
    prefrences_dlg.h \
    actionsettings.h \
    setupwizard.h \
    setupwiz_intro.h \
    setupwiz_modeselect.h \
    setupwiz_serialselect.h \
    setupwiz_finalpage.h

FORMS    += mainwindow.ui \
    prefrences_dlg.ui \
    actionsettings.ui \
    setupwiz_intro.ui \
    setupwiz_modeselect.ui \
    setupwiz_serialselect.ui \
    setupwiz_finalpage.ui

RESOURCES += \
    images.qrc
