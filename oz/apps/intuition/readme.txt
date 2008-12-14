; **************************************************************************************************
; This file is part of Intuition.
;
; Intuition is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation; either version 2, or
; (at your option) any later version.
; Intuition is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with Intuition;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
;***************************************************************************************************

Debugger compilation notes

All ".asm" use a tabulator distance of 5 spaces.

To compile the debugger application and executable files, execute the following:

1) Select the directory holding the debugger files as the current directory.

2) There are several versions of the debugger:

        1) The "Intuition" application for 32K card:

                execute 'make.debugapp.bat' (Windows/DOS) or 'make.debugapp.sh' (Unix/Linux)

                This will create a 2 x 16K image files that may be blown on a Z88 Eprom or Flash Card.
                A 32K 'intuition.epr' file is also made to be used for the Z88 emulator.

        2) The debugger executable files for application card debugging:

                1) The debugger for segment 0 (upper 8K = 2000h):
                   This version is made of two separate 8K executable, both to be joined in a 16K file
                   (identified as a bank). The first (lower) half is located in offset 0000h of the bank,
                   the second half is to be placed in the upper half, offset 2000h, of the bank.

                   execute 'make.debugS00.bat' (Windows/DOS) or 'make.debugS00.sh' (Unix/Linux)

                   The script will combine the two executable files; "debug0a.bin"
                   and "debug0b.bin into a complete 16K file, 'debugS00.bin' that is to be executed
                   in upper 8K half of segment 2.

                   The debugger for segment 0 (upper 8K) must be located in an even bank number,
                   and is executed at address 2000h. The segment 0 version of the debugger allowes
                   you to monitor operating system calls

                2) The debugger for segment 1 (4000h):

                   execute 'make.debugS01.bat' (Windows/DOS) or 'make.debugS01.sh' (Unix/Linux)

                        This will create the "debugS01.bin" file.
                        The debugger is executed at address 4000h.

                2) The debugger for segment 2 (8000h):

                   execute 'make.debugS02.bat' (Windows/DOS) or 'make.debugS02.sh' (Unix/Linux)

                        This will create the "debugS02.bin" file.
                        The debugger is executed at address 8000h.
