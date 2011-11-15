; *************************************************************************************
;
; Shell (c) Garry Lancaster, 2001-2002
;
; Shell is free software; you can redistribute it and/or modify it under
; the terms of the GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; Shell is distributed in the hope that it will be useful, but WITHOUT
; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
; PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with Shell;
; see the file COPYING. If not, write to the Free Software Foundation, Inc.,
; 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; *************************************************************************************

; An example external binary command for Shell, written in assembly

; First include the necessary header
include "shellbin.def"

include "stdio.def"

; Code entry point may be located anywhere, but must be called "entry"

.msg
        defm    13,10,"Simon says: ",0

.entry
        push    bc                              ; must preserve BC, DE, IX, IY
        push    de
        push    ix
        push    iy

        ld      hl,msg
        call_oz(gn_sop)

; The command line is *not* null-terminated, but it is permitted to modify
; any part of the command line including the following byte, so we can do
; this ourselves:

        ld      hl,(cmdlen)
        ld      de,(cmdaddr)
        add     hl,de
        ld      (hl),0                          ; add null-terminator

; The entire command line is provided, but the command name has been
; replaced by "extern" so isn't terribly useful. This is easily skipped
; using cmdptr:

        ld      hl,(cmdptr)
        add     hl,de                           ; HL=address of command tail

        call_oz(gn_sop)                         ; display command tail

; Before exiting back to Shell, it is *essential* to consume the
; command tail to prevent it from being parsed further. This is done
; by setting cmdptr equal to cmdlen (cmdlen and cmdaddr should not
; be modified):

        ld      hl,(cmdlen)
        ld      (cmdptr),hl                     ; consume command tail

; Finally, exit by restoring essential registers and jumping to "next":

        pop     iy                              ; restore registers
        pop     ix
        pop     de
        pop     bc

        jp      next                            ; terminate command

; A label called "end" must be placed at the end of the file

.end

