; *************************************************************************************
;
; AlarmSafe - Alarm archiving popdown utility, (c) Garry Lancaster, 1998-2011
;
; AlarmSafe is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; AlarmSafe is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with AlarmSafe;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
;
; *************************************************************************************

        module  alarmsafe

        defc    scratchlen=32
        defc    scratch2len=32
        defc    scratch=$1ffe-scratchlen
        defc    scratch2=scratch-scratch2len

include "director.def"
include "dor.def"
include "error.def"
include "fileio.def"
include "stdio.def"
include "alarm.def"
include "saverst.def"

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
        defb    'A'                             ; application key
        defb    0                               ; no bad app memory
        defw    0                               ; overhead
        defw    0                               ; unsafe workspace
        defw    scratchlen+scratch2len          ; safe workspace
        defw    asafestart                      ; entry point
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
        defm    "AlarmSafe",0
.innamend
        defb    $ff
.indorend

; Help entries

.in_help
        defb    $7f
        defm    "A popdown for saving & restoring alarms",$7f
        defm    "by Garry Lancaster",$7f
        defm    "v1.00 - 24th June 1998",$7f
        defm    $7f
        defb    0

; The main entry point

.asafestart
        jp      asafemain
        scf
        ret
.asafemain
        ld      ix,-1
        ld      a,fa_ptr
        ld      de,0
        call_oz(os_frm)                         ; check OZ version (in C)
        jr      nc,testozver
.badozver
        ld      a,rc_na                         ; exit with "Not Applicable" error
        call_oz(os_bye)
.testozver
        ld      a,c
        cp      $41                             ; Alarm layout changed from v4.1
        jr      nc,badozver                     ; so exit with v4.1+
        ld      hl,msg_asafewindow
        call_oz(gn_sop)                         ; display window
        ld      de,mail_name
        ld      b,0
        ld      hl,scratch
        ld      c,scratchlen
        ld      a,sr_rpd
        call_oz(os_sr)                          ; check for mail
        jp      nc,load_alarms2                 ; go straight to load file if in mailbox
.nomail
        ld      hl,msg_saveorload
        call_oz(gn_sop)                         ; ask whether to load or save
        ld      a,sc_ena
        call_oz(os_esc)                         ; enable escape detection
.dowhat
        call_oz(os_in)                          ; get a key
        jr      nc,no_keyerr
        cp      rc_quit
        jr      z,do_exit
        cp      rc_esc
        jr      nz,asafemain                    ; loop back unless rc_esc
.do_esc
        call_oz(os_esc)                         ; acknowledge escape
        jr      do_exit                         ; and exit
.no_keyerr
        cp      'l'
        jp      z,load_alarms
        cp      'L'
        jr      z,load_alarms
        cp      's'
        jr      z,save_alarms
        cp      'S'
        jr      nz,dowhat                       ; loop back if not L or S

; At this point we have been asked to save alarms.

.save_alarms
        call    get_filename    
        ld      b,0
        ld      hl,scratch
        ld      de,scratch2
        ld      c,scratch2len
        ld      a,op_out
        call_oz(gn_opf)                         ; attempt to create file
        jr      c,error2                        ; exit if error
        ld      a,'A'+128                       ; output alarm file signature
        call_oz(os_pb)
        jr      c,clerror
        ld      a,'S'+128
        call_oz(os_pb)
        jr      c,clerror
        ld      a,$20
        ld      ($04d1),a
        out     ($d1),a                         ; bind bank $20 to segment 1
        ld      hl,($4fa7)                      ; get address
        ld      a,($4fa9)                       ; and bank of first alarm block
        ld      b,a
.save_loop
        ld      a,b
        or      h
        or      l
        jr      z,save_end                      ; exit if no more
        ld      a,b
        ld      ($04d1),a
        out     ($d1),a                         ; bind bank to segment 1
        ld      a,h
        and     $3f
        or      $40                             ; mask address to segment 1
        ld      h,a
        push    hl                              ; save address
        inc     hl
        inc     hl
        inc     hl
        ld      de,0
        ld      bc,40
        call_oz(os_mv)                          ; write alarm block to file
        jr      c,clerror
        pop     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      b,(hl)
        ex      de,hl                           ; BHL contains link to next block
        jr      save_loop
.save_end
        call_oz(gn_cl)                          ; close file
        jr      c,error2
        ld      hl,msg_saved
.end_popd
        call_oz(gn_sop)                         ; state alarms saved
        call_oz(os_in)                          ; wait for a keypress
.do_exit
        xor     a
        call_oz(os_bye)                         ; and exit
.clerror
        push    af
        call_oz(gn_cl)                          ; try to close file
        pop     af
.error2
        call_oz(gn_err)                         ; display error box
        jr      do_exit

; At this point we have been asked to load alarms

.load_alarms
        call    get_filename    
.load_alarms2
        ld      b,0
        ld      hl,scratch
        ld      de,scratch2
        ld      c,scratch2len
        ld      a,op_in
        call_oz(gn_opf)                         ; attempt to open file
        jr      c,error2                        ; exit if error
        call_oz(os_gb)                          ; check file signature
        jr      c,clerror
        cp      'A'+128
        ld      a,rc_fail
        jr      nz,clerror
        call_oz(os_gb)
        jr      c,clerror
        cp      'S'+128
        ld      a,rc_fail
        jr      nz,clerror
.loadloop
        ld      hl,0
        ld      de,scratch2
        ld      bc,40
        call_oz(os_mv)                          ; get next alarm block from file
        jr      c,loaderr                       ; move on if error
        call_oz(gn_aab)                         ; allocate an alarm block
        jr      c,clerror
        push    bc                              ; save BHL
        push    hl
        ld      a,b
        ld      ($04d1),a
        out     ($d1),a                         ; bind in block
        ld      a,h
        and     $3f
        or      $40                             ; mask address to segment 1
        ld      h,a
        xor     a
        ld      (hl),a                          ; zeroise link
        inc     hl
        ld      (hl),a
        inc     hl
        ld      (hl),a
        inc     hl
        ld      de,scratch2
        ex      de,hl
        ld      bc,40
        ldir                                    ; copy data to alarm block
        pop     hl                              ; restore BHL
        pop     bc
        call_oz(gn_lab)                         ; link in (ignore errors if time is past)
        jr      loadloop                        ; back for more
.loaderr
        cp      rc_eof
        jr      nz,clerror                        ; exit if not EOF error 
        ld      hl,40
        and     a
        sbc     hl,bc
        ld      a,rc_fail
        jr      nz,clerror                        ; FAIL error if block partially loaded
        call_oz(gn_cl)                          ; close file
        jr      c,error2
        ld      hl,msg_loaded
        jp      end_popd

; Subroutine to get filename

.get_filename
        call_oz(os_out)                         ; display choice (L or S)       
        xor     a
.re_get
        ld      hl,msg_filename
        call_oz(gn_sop)
        ld      de,scratch
        ld      b,scratchlen
        call_oz(gn_sip)                         ; get input
        ret     nc                              ; exit if no error
        pop     bc                              ; get return address
        cp      rc_esc                          ; check for ESCape
        jp      z,do_esc
        cp      rc_quit                         ; check for KILL
        jp      z,do_exit
        cp      rc_susp
        jr      z,redraw
        cp      rc_draw
        jp      nz,error2                       ; exit with error if not SUSP/DRAW
.redraw
        push    bc                              ; restack return address
        ld      hl,msg_asafewindow
        call_oz(gn_sop)                         ; redraw window
        ld      a,1
        jr      re_get                          ; go back to get input again

; Messages

.msg_asafewindow
        defm    1,"7#1",53,32,82,40,131
        defm    1,"2I1"
        defm    1,"4+TUR",1,"2JC",1,"3@",32,32
        defm    "AlarmSafe v1.00 by Garry Lancaster"
        defm    1,"3@",32,32,1,"2A",83
        defm    1,"7#1",53,33,82,39,129
        defm    1,"2C1",1,"C",0

.msg_saveorload
        defm    13,10,1,"2+BS",1,"2-Bave or "
        defm    1,"2+BL",1,"2-Boad alarms? ",0

.msg_saved
        defm    13,10,13,10,"  ",1,"3+FR"
        defm    "Alarms saved - press a key to exit"
        defm    1,"4-FRC",7,7,0

.msg_loaded
        defm    13,10,13,10,"  ",1,"3+FR"
        defm    "Alarms loaded - press a key to exit"
        defm    1,"4-FRC",7,7,0

.msg_filename
        defm    13,10,13,10,"Filename: ",0

.mail_name
        defm    "NAME",0

