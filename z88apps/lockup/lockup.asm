; *************************************************************************************
;
; Lockup - password protection popdown utility, (c) Garry Lancaster, 1998-2011
;
; Lockup is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; Lockup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with Lockup;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
;
; *************************************************************************************

        module  lockup

        defc    passlen=17
        defc    esc_code=$10
        defc    enter_code=$0f
        defc    del_code=$07

include "director.def"
include "dor.def"
include "stdio.def"
include "screen.def"

        defc    appl_bank=$3f                   ; default to top bank loading
        org     $c000

; Application DOR

.in_dor
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
        defb    'X'                             ; application key
        defb    0                               ; no bad app memory
        defw    0                               ; overhead
        defw    0                               ; unsafe workspace
        defw    passlen*2                       ; safe workspace
        defw    lockstart                       ; entry point
        defb    0                               ; bank bindings
        defb    0
        defb    0
        defb    appl_bank
        defb    at_popd+at_good                 ; good popdown
        defb    0                               ; no caps lock
.ininfend
        defb    'H'                             ; key to help section
        defb    inhlpend-inhlpstart
.inhlpstart
        defw    in_dor                          ; no topics
        defb    appl_bank
        defw    in_dor                          ; no commands
        defb    appl_bank
        defw    in_help
        defb    appl_bank
        defw    in_dor                          ; no tokens
        defb    appl_bank
.inhlpend
        defb    'N'                             ; key to name section
        defb    innamend-innamstart
.innamstart
        defm    "Lockup",0
.innamend
        defb    $ff
.indorend

; Help entries

.in_help
        defb    $7f
        defm    "A password-protection utility by Garry Lancaster",$7f
        defm    "v1.00 - 14th June 1998",$7f
        defm    $7f,$7f
        defm    "ESC turns off Z88 if in locked mode, "
        defm    "or exits if unlocked",$7f
        defb    0

; The main entry point

.lockstart
        jp      lockmain
        scf
        ret
.lockmain
        ld      hl,msg_lockwindow
        call_oz(gn_sop)                         ; display window
.unlocked
        ld      hl,msg_unlocked
        call_oz(gn_sop)                         ; show unlocked status
        ld      hl,msg_password
        call_oz(gn_sop)                         ; ask for password
        ld      de,$1ffe-passlen*2
        call    getpass                         ; get first password
        jr      c,die                           ; exit if ESC
        ld      hl,msg_confirm
        call_oz(gn_sop)                         ; ask to confirm
        ld      de,$1ffe-passlen
        call    getpass                         ; get confirmation
        jr      c,die                           ; exit if ESC
        ld      hl,$1ffe-passlen*2
        ld      de,$1ffe-passlen
        call    checkpass
        jr      z,locked                        ; move on if passwords match
        call    errormsg                        ; else say not
        jr      unlocked                        ; and restart
.die
        call_oz(os_pur)                         ; purge keyboard buffer
        xor     a
        call_oz(os_bye)                         ; quit popdown
.locked
        ld      hl,msg_locked
        call_oz(gn_sop)                         ; show "locked" message
        ld      hl,msg_password
        call_oz(gn_sop)                         ; ask for password
        ld      de,$1ffe-passlen
        call    getpass                         ; get password
        jr      c,switchoff                     ; turn off if ESC
        ld      hl,$1ffe-passlen*2
        ld      de,$1ffe-passlen
        call    checkpass
        jr      z,unlocked                      ; unlock system if correct
        call    errormsg                        ; else error
        jr      locked                          ; re-try
.switchoff
        call_oz(os_off)                         ; switch off machine
        jr      locked                          ; re-enter locked mode

; Subroutine to show error message

.errormsg
        ld      hl,msg_nomatch
        call_oz(gn_sop)                         ; else say so
        ld      bc,0
.delayloop
        dec     bc
        ld      a,b
        or      c
        jr      nz,delayloop
        ret

; Subroutine to get a key value in D ($ff=none)
; If Z flag not set, more than one key was pressed

.keyfind
        ld      bc,$feb2                        ; B=row, C=port
        ld      de,$ff47                        ; D=nokey, E=initial value 
.nextrow
        in      a,(c)
        cpl
        and     a
        jr      z,nopress
        inc     d
        ret     nz                              ; exit if already got key
        ld      h,a
        ld      a,e
.kloop
        sub     8                               ; build key value
        srl     h
        jr      nc,kloop
        ret     nz
        ld      d,a
.nopress
        dec     e
        rlc     b
        jr      c,nextrow
        cp      a
        ret

; Subroutine to get a single key value in A (may be $ff)

.getkey
        push    bc
        push    de
        push    hl
.retry 
        call    keyfind
        jr      nz,retry
        ld      a,d
        pop     hl
        pop     de
        pop     bc
        ret

; Subroutine to debounce keyboard and get a single keystroke

.debounce
        call    getkey
        inc     a
        jr      nz,debounce                     ; wait until no key pressed
.debounce2
        call    getkey
        inc     a
        jr      z,debounce2                     ; wait until key pressed
        dec     a                               ; reform value
        ret

; Subroutine to clear password buffer at DE (length passlen)

.clearpass
        push    de
        ld      h,d
        ld      l,e
        inc     de
        ld      (hl),$ff
        ld      bc,passlen-1
        ldir
        pop     de
        ret

; Subroutine to get a password (length passlen) to buffer DE
; On exit, Carry set if ESC pressed

.getpass
        call    clearpass
        ld      b,0                             ; no chars so far
.nextkey
        call    debounce
        cp      esc_code
        scf
        ret     z                               ; exit if ESC, with carry set
        cp      enter_code
        ret     z                               ; exit if ENTER
        cp      del_code
        jr      z,dodelete                      ; move on for delete
        ld      (de),a  ; store key
        inc     de
        inc     b
        ld      a,b
        cp      passlen
        jr      c,showstar                      ; okay if less than passlen chars
        dec     de                              ; else ignore
        dec     b
        ld      a,$ff
        ld      (de),a
        jr      nextkey
.showstar
        ld      a,'*'
        call_oz(os_out)
        jr      nextkey
.dodelete
        ld      a,b
        and     a
        jr      z,nextkey
        dec     b
        dec     de
        ld      a,$ff
        ld      (de),a
        ld      hl,msg_delstar
        call_oz(gn_sop)
        jr      nextkey

; Subroutine to check if passwords at HL and DE match
; Returns Z set if passwords match

.checkpass
        ld      b,passlen
.checkpass2
        ld      a,(de)
        cp      (hl)
        ret     nz                              ; exit if no match
        inc     de
        inc     hl
        djnz    checkpass2
        ret                                     ; exit with Z set for success

; Messages

.msg_delstar
        defb    8,32,8,0

.msg_lockwindow
        defm    1,"7#1",53,32,82,40,131
        defm    1,"2I1"
        defm    1,"4+TUR",1,"2JC",1,"3@",32,32
        defm    "Lockup v1.00 by Garry Lancaster"
        defm    1,"3@",32,32,1,"2A",83
        defm    1,"7#1",53,33,82,39,129
        defm    1,"2C1",0

.msg_unlocked
        defm    1,"2C1",13,10,1,"2JC"
        defm    "<<UNLOCKED - ESC to exit>>"
        defm    13,10,1,"2JN",0

.msg_locked
        defm    1,"2C1",13,10,1,"2JC"
        defm    "<<LOCKED - ESC to turn off>>"
        defm    13,10,1,"2JN",0

.msg_password
        defm    13,10,"   Enter password: ",0

.msg_confirm
        defm    13,10," Confirm password: ",0

.msg_nomatch
        defm    13,10,13,10,1,"2JC"
        defm    "Wrong password!",13,10,0

