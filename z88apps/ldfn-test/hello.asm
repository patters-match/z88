; **************************************************************************************************
; 1st part of Hello World proof of concept is an Elf executable which loads & executes a
; relocatable function in memory
;
; Implemented by G.Strube, gstrube@gmail.com, Jan 2018
; ***************************************************************************************************

module Hello

lib ldfn

include "memory.def"
include "stdio.def"
include "error.def"

; zELF shell command definitions
include "hello.inc"

org EXEC_ORG


.entry
        ld      b,0
        ld      a, MM_MUL | MM_S3
        oz      OS_Mop                          ; get memory handle supplied to ldfn
        jr      c,err_hello

        ld      b,0                             ; B = 0, local filename
        ld      hl,fnfln
        call    ldfn                            ; return BHL = pointer to loaded relocatable function
        jr      c,ldfn_failed

        ld      a,b
        ld      (dsphello + 1),hl
        ld      (dsphello + 3),a                ; patch address of loaded function after RST 28H
        call    dsphello                        ; local -> far call
.ldfn_failed
        push    af
        oz      OS_Mcl                          ; release allocated function code memory
        pop     af
.err_hello
        jr      nc,exit_hello
        oz      Gn_Esp                          ; report RC error to Shell window, then exit command
        oz      OS_Bout
        oz      OS_Nln
.exit_hello
        ld      hl, 0                           ; SH_OK
        ret

.fnfln  defm "world.bin",0                      ; executable function code "world.bin"

; the API of dynamically loaded function call
.dsphello
        extcall 0,0                             ; far call (which will be patched with runtime allocated pointer)
        ret

; ------------------------------------------------------------------------------------------------------------
.WorkSpace