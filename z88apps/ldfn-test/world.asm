; **************************************************************************************************
; 2nd part of Hello World proof of concept for relocatable code that is executed via extcall
;
; Implemented by G.Strube, gstrube@gmail.com, Jan 2018
; ***************************************************************************************************

module World

include "stdio.def"

org 0

; ---------------------------------------------------------------------------------------------------
; this rather elaborate example of complex pointers is simply to test the relocation step
; the code runs in RAM, allocated & loaded by ldfn library.
; ---------------------------------------------------------------------------------------------------

.entry
        call    initvars
        ld      hl,(hellostrptr)
        call    dispmsg
        ld      hl,(worldstrptr)
        call    dispmsg
        oz      OS_Nln
        ret

.initvars
        ld      hl, hellostr
        ld      (hellostrptr),hl
        ld      hl, worldstr
        ld      (worldstrptr),hl
        ret
.dispmsg
        oz      OS_Sout
        ret

.hellostrptr  defw 0
.worldstrptr  defw 0

.hellostr
        defm    "Hello ",0
.worldstr
        defm    "World ",0
