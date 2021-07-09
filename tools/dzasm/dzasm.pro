# ------------------------------------------------------------------------------
#
#   DDDDDDDDDDDDD            ZZZZZZZZZZZZZZZZ
#   DDDDDDDDDDDDDDD        ZZZZZZZZZZZZZZZZ
#   DDDD         DDDD               ZZZZZ
#   DDDD         DDDD             ZZZZZ
#   DDDD         DDDD           ZZZZZ             AAAAAA         SSSSSSSSSSS   MMMM       MMMM
#   DDDD         DDDD         ZZZZZ              AAAAAAAA      SSSS            MMMMMM   MMMMMM
#   DDDD         DDDD       ZZZZZ               AAAA  AAAA     SSSSSSSSSSS     MMMMMMMMMMMMMMM
#   DDDD         DDDD     ZZZZZ                AAAAAAAAAAAA      SSSSSSSSSSS   MMMM MMMMM MMMM
#   DDDDDDDDDDDDDDD     ZZZZZZZZZZZZZZZZZ     AAAA      AAAA           SSSSS   MMMM       MMMM
#   DDDDDDDDDDDDD     ZZZZZZZZZZZZZZZZZ      AAAA        AAAA  SSSSSSSSSSS     MMMM       MMMM
#
# Qt Creator Qmake compile project for the intelligent Z80 Disassembler, DZasm
# Use qmake mpm.pro, then make. Executable binary will be generated in
#   <Project Home>/bin
#
# Copyright (C) 1996-2012, Gunther Strube, hello@bits4fun.net
#
# DZasm is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the Free Software Foundation;
# either version 2, or (at your option) any later version.
# DZasm is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with DZasm;
# see the file COPYING.  If not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# ------------------------------------------------------------------------------

TEMPLATE  = app
CONFIG    += console
QT -= gui core

DESTDIR   = ../../bin
TARGET = dzasm

QMAKE_LINK = $$QMAKE_LINK_C

HEADERS  += dzasm.h avltree.h table.h
SOURCES  += main.c dz.c prscmds.c collect.c genasm.c parse.c areas.c avltree.c
