# ------------------------------------------------------------------------------
#
# Qt-Creator Project for the MthToken.
#
# Copyright (C) 2016, Gunther Strube, hello@bits4fun.net
#
# Use qmake mthtoken.pro, then just make.
#
# MthToken is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the Free Software Foundation;
# either version 2, or (at your option) any later version.
# MthToken is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with MthToken;
# see the file COPYING.  If not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# ------------------------------------------------------------------------------

TEMPLATE = app

CONFIG += console

macx {
        # Don't create a Mac App bundle...
        CONFIG -= app_bundle
}

QT -= gui core

TARGET = mthtoken
DESTDIR = .
MOC_DIR = ../build/moc
RCC_DIR = ../build/rcc
unix:OBJECTS_DIR = ../build/o/unix
win32:OBJECTS_DIR = ../build/o/win32
macx:OBJECTS_DIR = ../build/o/mac

win32 {
        DEFINES += MSDOS
}

!win32 {
        DEFINES += UNIX
}

SOURCES  += mthtoken.c
