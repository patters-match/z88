; *************************************************************************************
; Installer/Bootstrap/Packages (c) Garry Lancaster 1998-2011
;
; Installer/Bootstrap/Packages is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by the Free Software
; Foundation; either version 2, or (at your option) any later version.
; Installer/Bootstrap/Packages is distributed in the hope that it will be useful, but
; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
; FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with
; Installer/Bootstrap/Packages; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
; *************************************************************************************

; Bootstrap auto-booting Popdown
; v1.02 18/9/99 GWL
;   Added package-handling code installation
;   Added support for Flash EPROMs with application/file partitions
; v1.03 21/1/00 GWL
;   Added initial feature settings
; v1.04 16/2/00 GWL
;   Added package-booting facility; fixed "safe" page protection
; v1.05 23/2/00 GWL
;   Added "P" key for bypassing package-code installation (for Dom!)
; v1.06 29/4/01 GWL
;   Added initialisation of call substitutions provided by Packages
; v1.07 11/5/11 GWL
;   Removed use of booted.yes file, since substitution of OS_NQ,AIn now
;   prevents us being booted except at a reset (assuming OZPlus hasn't
;   been turned off).


        module  bootstrap

if BANK3E
        defc    appl_bank=$3e
else
        defc    appl_bank=$3f
endif

        defc    unsafe=24
        defc    scratch=$1ffe-unsafe
        defc    workparams=$1ffe-unsafe

        xref    slottype,slotprot,protsafe,in_tokens
        xref    instpcode,regsubs
        xref    getozver

        xdef    bootstrap_dor

include "director.def"
include "dor.def"
include "fileio.def"
include "memory.def"
include "error.def"
include "stdio.def"
include "packages.def"

; Application DOR

.bootstrap_dor
        defb    0,0,0                           ; links to parent, brother, son
        defb    0,0,0
        defb    0,0,0
        defb    $83                             ; DOR type - application
        defb    indorend-indorstart
.indorstart
        defb    '@'                             ; key to info section
        defb    ininfend-ininfstart
.ininfstart
        defw    0
        defb    '0'                             ; application key - disabled
        defb    0                               ; no bad app memory
        defw    0                               ; overhead
        defw    unsafe                          ; unsafe workspace
        defw    0                               ; safe workspace
        defw    bootentry                       ; entry point
        defb    0                               ; bank bindings
        defb    0
        defb    0
        defb    appl_bank
        defb    at_popd+at_good+at_boot         ; good popdown, autoboot
        defb    0                               ; no caps lock
.ininfend
        defb    'H'                             ; key to help section
        defb    inhlpend-inhlpstart
.inhlpstart
        defw    bootstrap_dor                   ; no topics
        defb    appl_bank
        defw    bootstrap_dor                   ; no commands
        defb    appl_bank
        defw    in_help
        defb    appl_bank
        defw    in_tokens
        defb    appl_bank
.inhlpend
        defb    'N'                             ; key to name section
        defb    innamend-innamstart
.innamstart
        defm    "Bootstrap",0
.innamend
        defb    $ff
.indorend

; Help entries

.in_help
        defb    $7f
        defm    "An autoboot",$86,$82,$7f
        defm    "v1.07",$85,$7f
        defm    $84,$7f,$7f
        defm    "After reset, executes BOOTSTRAP.CLI file located",$7f
        defm    $87,"any RAM, EPROM, ROM/EPROM or FLASH device",$7f
        defb    0

; The main entry point

.bootentry
        jp      bootstart
        scf
        ret

; First we re-protect any installed RAM applications

.bootstart
        call    getozver                        ; check for compatible OZ version
        jr      nz,ozcompatible
        xor     a                               ; exit silently if not
        call_oz(os_bye)
.ozcompatible
        ld      iy,workparams
        ld      (iy+3),3                        ; start with slot 3
.psltlp
        call    slottype                        ; get type
        bit     0,(iy+2)
        call    nz,protsafe                     ; protect safe page in a RAM slot
        ld      a,(iy+2)
        cp      3
        call    z,slotprot                      ; protect a RAM/ROM slot
        dec     (iy+3)
        jr      nz,psltlp

; Now deal with package-handling issues

        ld      bc,$efb2
        in      a,(c)
        and     @00000001                       ; check for "P" pressed
        jr      z,bypasspkgs                    ; skip this section if so

        call    instpcode                       ; install package-handling
        ld      b,@11111111
        ld      c,@00000000
        call_pkg(pkg_feat)                      ; reset all features
        ld      b,@00000011
        ld      c,@00000011
        call_pkg(pkg_feat)                      ; set int.chain & ozplus
        call    regsubs                         ; register our call substitutions
        call_pkg(pkg_boot)                      ; autoboot any packages that want it

; Now the actual Bootstrap.cli section

.bypasspkgs
        ld      hl,msg_bootfile
        ld      bc,unsafe
        ld      de,scratch
        ld      a,op_in
        call_oz(gn_opf)                         ; try to open bootstrap file in RAM
        jr      c,doeprom                       ; move on if can't
        call_oz(gn_cl)                          ; close file again
.doboot
        ld      hl,msg_doboot
        ld      de,scratch
        ld      bc,msgs_end-msg_doboot
        push    bc
        push    de
        ldir
        pop     hl
        pop     bc
        call_oz(dc_icl)                         ; invoke CLI
.doexit
        xor     a
        call_oz(os_bye)                         ; done!
.doerror2
        push    af
        call_oz(gn_cl)                          ; try to close file
        pop     af
.doerror
        call_oz(os_bye)                         ; display error box & exit

; EPROM/Flash EPROM/ROMEPROM reading routines

.noteprom
        ld      a,(scratch)
        add     a,$40                           ; next slot mask
        jr      z,doexit                        ; exit if tried all slots
        jr      nextslot
.doeprom
        ld      a,$40                           ; slot 1 mask
.nextslot
        ld      (scratch),a                     ; save it
        or      $3f                             ; top bank of slot
        ld      b,a
        ld      hl,$3ffe
        call_oz(gn_rbe)
        cp      'o'
        jr      nz,romeprom
        inc     hl
        call_oz(gn_rbe)
        cp      'z'
        jr      nz,noteprom
.iseprom
        ld      hl,0
        ld      b,0                             ; set offset 0 into EPROM
.nextfile
        call    get_byte
        cp      msgs_end-msg_bootname-1         ; check length
        ld      c,a                             ; save filename length
        jp      nz,skip1
        ld      de,msg_bootname                 ; name to check for
.checkfname
        call    get_byte
        ex      de,hl
        cp      (hl)
        ex      de,hl
        jp      nz,skip2                        ; move on if names differ
        inc     de
        dec     c
        jr      nz,checkfname

; At this point we have found a file with the correct name & must place it
; in the default RAM device.

        call    get_byte
        ld      e,a
        call    get_byte
        ld      d,a
        call    get_byte
        ld      c,a                             ; CDE=filelength
        call    inc_bhl                         ; BHL points to file body
        push    bc                              ; save registers
        push    de
        push    hl
        ld      hl,msg_bootname
        ld      bc,unsafe-1
        ld      de,scratch+1
        ld      a,op_out
        call_oz(gn_opf)                         ; try to create file
        jr      c,doerror                       ; go if error
        pop     hl                              ; restore regs
        pop     de
        pop     bc
.savefile
        call    get_byte                        ; get next byte
        call_oz(os_pb)                          ; save to file
        jr      c,doerror2                      ; close file and exit if error
        push    hl
        ex      de,hl
        ld      de,1
        and     a
        sbc     hl,de                           ; subtract 1 from CDE
        ex      de,hl
        pop     hl
        ld      a,c
        sbc     a,0
        ld      c,a
        or      d
        or      e
        jr      nz,savefile                     ; back for more bytes
        call_oz(gn_cl)                          ; close file
        jp      doboot                          ; now we've created a file, execute it

; Here we check if a ROM/EPROM card or partitioned Flash card is present

.romeprom
        cp      'O'
        jp      nz,noteprom                     ; back if not ROM at top
        inc     hl
        call_oz(gn_rbe)
        cp      'Z'
        jp      nz,noteprom
        ld      hl,$3ff6                        ; address for ROM/EPROM identifier
        call_oz(gn_rbe)
        cp      'o'
        jp      nz,partition                    ; could be partitioned Flash
        inc     hl
        call_oz(gn_rbe)
        cp      'z'
        jp      nz,partition
        jp      iseprom                         ; if ROM/EPROM, go to process it

; Here we test for a partitioned Flash EPROM card

.partition
        ld      hl,$3ffc
        call_oz(gn_rbe)                         ; get size of application part in banks
        ld      l,a
        ld      a,b
        sub     l
        inc     a                               ; A=lowest bank of application part
        and     @11111100                       ; Flash is in blocks of 4 banks
        dec     a                               ; A=highest bank of possible file part
        ld      b,a
        ld      hl,$3ffe
        call_oz(gn_rbe)
        cp      'o'
        jp      nz,noteprom
        inc     hl
        call_oz(gn_rbe)
        cp      'z'
        jp      nz,noteprom
        jp      iseprom                         ; if partitioned Flash, go to process it

; Here we skip a non-matching file

.skip1
        cp      $ff                             ; is this a null entry?
        jp      z,noteprom                      ; if so, try next slot
        call    get_byte
.skip2
        dec     c
        jr      z,skipfile                      ; move on if have skipped filename
        call    inc_bhl
        jr      skip2
.skipfile
        call    get_byte
        ld      e,a
        call    get_byte
        ld      d,a
        call    get_byte
        ld      c,a
        call    inc_bhl                         ; BHL points to file start, CDE=length
        call    add_cde                         ; skip body of file
        jp      nextfile                        ; back for next file

; Subroutine to get byte from BHL in EPROM into A, and increment BHL
; Call at inc_bhl just to increment the pointer

.get_byte
        push    bc
        push    hl
        xor     a
        sla     h
        rl      a
        sla     h
        rl      a                               ; A=2 high bits of HL
        srl     h
        srl     h                               ; HL=offset within bank
        sla     b
        sla     b
        or      b                               ; A=bank
        and     $3f                             ; restrict to valid bank number
        ld      c,a
        ld      a,(scratch)                     ; get slot mask
        or      c
        ld      b,a
        call_oz(gn_rbe)                         ; read byte
        pop     hl                              ; restore offset
        pop     bc 
.inc_bhl
        inc     l                               ; increment BHL
        ret     nz
        inc     h
        ret     nz
        inc     b
        ret

; Subroutine to add CDE to pointer BHL

.add_cde
        ld      a,l
        add     a,e                             ; add low bytes
        ld      l,a
        ld      a,h
        adc     a,d                             ; add middle bytes
        ld      h,a
        ld      a,b
        adc     a,c                             ; add high bytes
        ld      b,a
        ret

; CLI instructions and filenames

.msg_doboot
        defm    ".*"
.msg_bootfile
        defm    ":*/"
.msg_bootname
        defm    "/bootstrap.cli",0
.msgs_end

