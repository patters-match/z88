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

        1) The "Intuition" application for 128K card:
          Change to DEFINE SEGMENT2 in "defs.h".
          
                mpm -b -i @debugapl

                This will create the executable files "debugapl.bin".
                Please refer to "applic.h" for position of code in 128K
                application card.

        2) The debugger executable files for application card debugging:

          Change to DEFINE INT_SEGM0, SEGMENT3 in "defs.h".
          
                1) The debugger for segment 0 (upper 8K = 2000h):
                   This version is made of two separate 8K executable, both
                   to be joined in a 16K file (identified as a bank). The
                   first (lower) half is to located in offset 0000h of the bank,
                   the second half is to be placed in the upper half, offset
                   2000h, of the bank.

                   The second half to be compiled:

                        mpm -b -g -i @debug0b

                        please note -g; this will generate a ".def" file.

                   Then the first half to compiled:

                        mpm -b -i @debug0a

                        please note that the previous ".def" file is read by
                        this compilation.

                   You will now have two executable files; "debug0a.bin"
                   and "debug0b.bin. Allocate a 16K memory block in your
                   operating system (or use Zprom buffer), then load
                   "debug0a.bin" at offset 0 and "debug0b.bin at offset 2000h".
                   Save the 16K block as "debug00.bin".

                   The debugger for segment 0 (upper 8K) must be located in an
                   even bank number, and is executed at address 2000h.
                   The segment 0 version of the debugger allowes you to monitor
                   operating system calls

                2) The debugger for segment 1 (4000h):
               Change to DEFINE SEGMENT3 in "defs.h".
               
                        mpm -b -i -r4000 @debug

                        This will create the "debug.bin" file. For convenience
                        please rename file as "debug01.bin".
                        The debugger is executed at address 4000h.

                3) The debugger for segment 2 (8000h):
               Change to DEFINE SEGMENT3 in "defs.h".
               
                        mpm -b -i -r8000 @debug

                        (If you have previuosly compiled for segment 1 then just
                        execute "mpm -a -i -r8000 @debug", this will just link
                        and address for segment 2)
                        This will create the "debug.bin" file. For convenience
                        please rename file as "debug02.bin".
                        The debugger is executed at address 8000h.
