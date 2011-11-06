; *************************************************************************************
; Tester & Example Package (c) Garry Lancaster 2000-2011
;
; Tester & Example Package is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by the Free Software
; Foundation; either version 2, or (at your option) any later version.
; Tester & Example Package is distributed in the hope that it will be useful, but
; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
; FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with
; Tester & Example Package; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
; *************************************************************************************

; Example package
; 31/1/00 GWL
; 13/2/00 Added call substitution demo
; 16/2/00 Added autobooting demo
; 27/2/00 Modified for altered interrupt handling requirements
; 29/2/00 Modified for revised package structure
; 10/3/00 Added 2-byte call substitution (GN_DEL)

        module exampkg

include "packages.def"
include "error.def"
include "fileio.def"

include "exampkg.def"
include "exam_int.def"


; We need an XDEF of the address of the package information block; this
; will be linked into the "son" pointer of an application DOR, so that
; the package can be found by the system

        xdef    pkg_block


; The package information block

.pkg_block
        defb    $45                             ; Package ID (assigned by GWL)
        defm    "P"
        defb    $12                             ; highest routine number

        defw    call_inf                        ; exm_inf (00)
        defw    call_ayt                        ; exm_ayt (02)
        defw    call_bye                        ; exm_bye (04)
        defw    call_dat                        ; exm_dat (06)
        defw    call_exp                        ; exm_exp (08) - last standard required call

        defw    call_int                        ; exm_int (0a) - the first real call we provide
        defw    call_cset                       ; exm_cset (0c)
        defw    call_cget                       ; exm_cget (0e)
        defw    call_gb                         ; exm_gb (10)
        defw    call_del                        ; exm_del (12)


; Now some sample definitions for the standard package calls
; The "registers changed" by standard calls *must* be as laid out here!


; The static information call (xxx_inf)
; This is a very simple call, and unlikely to need changing much

; exm_inf
; IN:   -
; OUT:  Fc=0, success always
;       BHL=pointer to null-terminated package name
;       C=version of package-handling required
;       DE=package version code
; Registers changed after return:
;   ......../IXIY same
;   AFBCDEHL/.... different

.call_inf
        ld      a,(s3_copy)
        ld      b,a                             ; get the bank we're running from
        ld      hl,inf_mess                     ;  BHL points to package name
        ld      c,$01                           ; always say we need version 1.0
        ld      de,pversion                     ; version number of this package
        and     a                               ; success
        ret

.inf_mess
        defm    "Example",0


; The "are you there?" call
; For this package, the call is very simple since we don't need
; to setup any data area. However, for more complex packages, this
; call should:
;  1. Check if the data area is valid, returning Fc=0 if so
;  2. Set up the data area, returning Fc=0 if successful
;  3. If unable to setup data (resources not available), return Fc=1

; exm_ayt
; IN:   -
; OUT:  Fc=0, success always
; Registers changed after return:
;   A.BCDEHL/IXIY same
;   .F....../.... different

.call_ayt
        and      a                              ; Fc=0
        ret


; The terminate package call
; Again, this call is simple if the package has no data requirements,
; although we must remember to deregister any interrupts and call
; substitutions if there's any possibility they may be registered.
; For packages with data it should:
;  1. Check if any resources it provides are still in use by applications,
;     returning Fc=1 and A=rc_use if so
;  2. Deallocate resources obtained from OZ, and set the segment 0 bytes
;     it uses to zero
;  3. Return Fc=0 to indicate success

; exm_bye
; IN:   -
; OUT:  Fc=0 (succeed always)
; Registers changed after return:
;   ..BCDEHL/IXIY same
;   AF....../.... different

.call_bye
        ld      hl,exm_int
        call_pkg(pkg_intd)                      ; deregister our package interrupt
                                                ; if it has been registered
        ld      de,os_gb
        ld      bc,exm_gb
        call_pkg(pkg_ozcd)                      ; deregister our call substitutions
        ld      de,gn_del                       ; as well
        ld      bc,exm_del
        call_pkg(pkg_ozcd)
        and     a                               ; Fc=0, success
        ret


; The dynamic data information call
; With this call, the package returns information about the resources
; it is using, as follows:
;       CDE=bytes in use (excluding any permanently allocated in seg 0)
;       B=OZ file/memory/wildcard handles in use
;       A=this package's resources in use (optional; use 0 if not needed)

; In common with other calls that the package provides (but *not* the other
; standard calls), if the data used by the package is not set up (ie xxx_ayt
; has not been used, or failed), this call should return Fc=1 and A=rc_pnf

; exm_dat
; IN:   -
; OUT:  Fc=0, success always
;       Fz=1, package data already set up
;       CDE=bytes in use
;       B=file handles in use
;       A=package resource usage (unused)
; Registers changed after return:
;   ......HL/IXIY same
;   AFBCDE../.... different

.call_dat
        ld      bc,0
        ld      de,0                            ; no resources
        xor     a                               ; A=0, Fc=0, Fz=1
        ret


; The expansion call
; Currently, the only reason code supported is B=exp_boot, to which
; packages can reply with Fc=0 to indicate they wish to be auto-booted.
; If they don't require this facility, or a different reason code is in B,
; they should return Fc=1 and A=rc_unk (unknown request)
; Note that this call is always made when the package is uninstalled, so
; should not attempt to perform any operation except a simple reply to
; the request.

; exm_exp
; IN:   B=reason code;
;               exp_boot, autoboot enquiry
; OUT(success):
;       Fc=0, autoboot requested
; OUT(failure):
;       Fc=1
;       A=RC_UNK, unknown request
; Registers changed after return:
;   ..BCDEHL/IXIY same
;   AF....../.... different

.call_exp
        ld      a,b
        cp      exp_boot                        ; check for autoboot enquiry
        ret     z                               ; Fc=0 if so, we want to autoboot
        ld      a,rc_unk
        scf                                     ; else unknown request error
        ret



; Finally (at last!), here's the calls that our package is providing


; This call will be registered by an application as a "package interrupt",
; and simply increments its counter in the segment 0 area.
; As an interrupt call, it is permitted to corrupt AF and any alternate
; registers, but no main registers except IX. It must *always* exit
; with Fc=0.

; exm_int
; IN:   -
; OUT:  Fc=0 always
; Registers changed after return:
;   ..BCDEHL/..IY same
;   AF....../IX.. different

.call_int
        exx
        ld      hl,(mycounter)
        inc     hl
        ld      (mycounter),hl
        exx
        and     a                               ; Fc=0 always
        ret


; This call is used by an application to set the counter

; exm_cset
; IN:   BC=new counter value
; OUT:  Fc=0, success
; Registers changed after return:
;   A.BCDEHL/IXIY same
;   .F....../.... different

.call_cset
        ld      (mycounter),bc
        and     a                               ; Fc=0
        ret


; This call is used by an application to read the counter

; exm_cget
; IN:   -
; OUT:  Fc=0, success
;       BC=counter value
; Registers changed after return:
;   A...DEHL/IXIY same
;   .FBC..../.... different

.call_cget
        ld      bc,(mycounter)
        and     a                               ; Fc=0
        ret


; This call is used to replace the standard OS_GB call
; Luckily, this is a simple call and we don't need to worry about
; previous memory bindings; if we did, the original seg3 binding would
; be found on the stack at SP+11.
; Some substitutions may only want to occur in certain circumstances; if
; so they can back out by restoring all registers and exiting with 
; Fc=1 and A=rc_pnf

; exm_gb
; IN:   IX=handle
; OUT:  Fc=0, success
;       A=byte read
; Registers changed after return:
;   ..BCDEHL/IXIY same
;   AF....../.... different

.call_gb
        push    hl                              ; save registers
        push    de
        ld      hl,osgb_message
        ld      a,(gbcycler)
        and     $0f
        ld      e,a
        ld      d,0
        inc     a                               ; increment counter
        ld      (gbcycler),a
        add     hl,de
        ld      a,(hl)                          ; A=next byte in message
        pop     de
        pop     hl
        and     a                               ; Fc=0, success!
        ret

.osgb_message
        defm    "Isnt this fun?",13,10


; Similarly, this call replaces the standard GN_DEL call,
; just to prove that 2-byte call substitutions work as well!
; It just prevents any files from being deleted

; exm_del
; IN:   BHL=filename
; OUT:  Fc=1
;       A=rc_use, file is in use
; Registers changed after return:
;   ..BCDEHL/IXIY same
;   AF....../.... different

.call_del
        ld      a,rc_use
        scf
        ret

