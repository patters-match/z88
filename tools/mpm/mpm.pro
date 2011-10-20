#-------------------------------------------------
#
# Qt-Creator Project for MPM
#
#-------------------------------------------------

TEMPLATE  = app
CONFIG    += console
QT -= gui core

DESTDIR   = ../mpm
TARGET = mpm

DEFINES += MPM_Z80
win32 {
        DEFINES += WIN32
}

!win32 {
        DEFINES += UNIX
}

QMAKE_LINK = $$QMAKE_LINK_C

HEADERS  += asmdrctv.h config.h datastructs.h exprprsr.h modules.h pass.h z80_prsline.h \
            avltree.h crc32.h errors.h libraries.h options.h symtables.h z80_relocate.h

SOURCES  += main.c asmdrctv.c crc32.c exprprsr.c options.c symtables.c z80_instr.c \
            z80_relocate.c avltree.c errors.c libraries.c modules.c pass.c z80_asmdrctv.c z80_prsline.c
