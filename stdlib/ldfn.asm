; **************************************************************************************************
; This file is part of the Z88 Standard Library.
;
; The Z88 Standard Library is free software; you can redistribute it and/or modify it under
; the terms of the GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; The Z88 Standard Library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with the
; Z88 Standard Library; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; ***************************************************************************************************

XLIB ldfn

LIB memcompare, fseek64k

include "memory.def"
include "fileio.def"
include "error.def"

defc sz_buf = 32
defc sz_relocfn = $49                           ; size of legacy relocation function (beginning of file)
defc sz_wm = 8


; workspace on system stack
defvars 0
    buf        ds.b sz_buf                      ; work buffer for various functionalities
    memhandle  ds.w 1
    sfsgm      ds.b 1                           ; safe segment specifier
    filehandle ds.w 1
    filesize   ds.w 1
    rlctblmhdl ds.w 1                           ; OS_Mop memory handle for relocation table in S0
    s0bnd      ds.b 1                           ; original S0 binding (before this function call)
    rlctblptr  ds.w 1                           ; pointer to memory of allocated/loaded relocation table (temporary) in S0
    rlctbltle  ds.w 1                           ; total elements in relocation table
    rlctblsz   ds.w 1                           ; size of relocation table
    rlcfnptr   ds.p 1                           ; pointer to memory of loaded (and relocated) function
    sz_ws
enddef


; ********************************************************************************************************************
; Load relocatable function into RAM memory and return pointer to it.
; Function is then executed via RST 28H (EXTCALL) by applicatiom.
; If relocatable function is not identified, Fc = 1, A = RC_Ftm (file type mismatch) is returned.
; Only works for OZ V5.0 and later. If this library is executed on OZ v4.x or earlier, Fc = 1, A = RC_Na is returned
;
; (relocation header is temporarily loaded - only function code is allocated, relocated and ext.pointer returned to it for S3)
;
; IN:
;     BHL = ext.pointer to filename, null-terminated
;     IX = (OS_Mop) memory handle
; OUT:
;     Fc  = 0
;       BHL = ext.pointer to loaded routine (HL = entry address of routine in S3)
;     Fc  = 1
;       A = RC_xxx error
;
;    Registers changed after return
;         ...CDE../IXIY same
;         AFB ..HL/.... different
;
.ldfn   push    iy
        push    ix
        push    de
        push    bc
        ld      iy,-sz_ws
        add     iy,sp                           ;
        ld      sp,iy                           ; make temporary workspace on stack

        ld      a,($04D0)
        ld      (iy + s0bnd),a                  ; remember current S0 bank binding
        ld      (iy + rlcfnptr+2),0             ; indicate no pointer to allocated function code

        ld      ix,$ffff
        ld      a,FA_PTR
        oz      OS_Frm
        jr      c,ldfn_ret
        ld      a,$50
        cp      c
        jr      z,cont_ldfn
        jr      c,cont_ldfn
        scf
        ld      a,RC_Na                         ; this functionality is not available for OZ V4.x and earlier
        jr      ldfn_ret

.cont_ldfn                                      ; functionality allowed to be executed, we're running in OZ V5.0 or later..
        push    ix
        pop     de
        ld      (iy+memhandle),e
        ld      (iy+memhandle+1),d              ; preserve memory handle for later

        call    open_fnfile
        jr      c,ldfn_ret                      ; file of function not found, abort...

        call    getsz_fnfile
        jr      c,ldfn_abort

        call    chkrelocwm
        jr      c,ldfn_abort                    ; I/O error, abort...
        jr      z, ldreloctbl                   ; Fz = 1, relocatable function accepted...
        scf
        ld      a,RC_Ftm
        jr      ldfn_abort                      ; Fz = 0, relocatable file not identified (close file and abort)

.ldreloctbl
        call    alloc_rlctbl                    ; allocate and load relocation table
        jr      c,ldfn_abort                    ; no room, abort function loading..

        call    alloc_fnc                       ; allocate and load function code
        jr      c,ldfn_abort

        call    reloc_fnc                       ; relocate addresses in load function code
        cp      a
        ld      l,(iy + rlcfnptr)
        ld      h,(iy + rlcfnptr+1)
        ld      b,(iy + rlcfnptr+2)             ; return BHL = pointer to loaded function code
        jr      ldfn_ret

.ldfn_abort
        call    close_fnfile                    ; close handle of original function file
.ldfn_ret
        ex      af,af'
        push    bc
        ld      b,(iy + s0bnd)
        ld      c,MS_S0
        rst     OZ_MPB                          ; restore original S0 bank binding
        pop     bc

        ld      iy,sz_ws
        add     iy,sp                           ;
        ld      sp,iy                           ; restore original stack
        ex      af,af'                          ; return AF status
        pop     de
        ld      c,e                             ; restored original C
        pop     de
        pop     ix
        pop     iy
        ret                                     ; return BHL = ext.address to loaded function.


; ********************************************************************************************************************
; Check watermark of relocatable code file (first 8 bytes)
;
; IN:
;    IX = file handle
;
; OUT:
;    Fz = 1, watermark identified
;
.chkrelocwm
        ld      bc,sz_wm
        push    iy
        pop     de
        call    ldblock
        ld      hl,relocfn_wm
        jp      memcompare                      ; compare strings at (DE) and (HL), return Fz = 1 if match


; ********************************************************************************************************************
; Load block of file data into memory buffer.
;
; IN:
;    BC = size of block to load from file
;    DE = local pointer to buffer
;    IX = file handle
;
.ldblock
        push    bc
        push    de
        ld      hl,0
        oz      OS_Mv
        pop     de
        pop     bc
        ret


; ********************************************************************************************************************
; Allocate memory and load relocation table of function file.
;
; 1. Read the 4 bytes from file offset $49 (total_elements & sizeof_table),
; 2. Allocate space for complete table (sizeof_table)
; 3. Load relocation table into allocated memory
;
; The relocation table header is placed right after relocator code, file position $49
; The format of the generated table is:
; [offset $49]
;    total_elements    ds.w 1
;    sizeof_table      ds.w 1
; [offset $4D]
;    patchpointer_0    ds.b 1  --+
;    patchpointer_1    ds.b 1    |
;    ....                        |  sizeof_table
;    ....                        |
;    patchpointer_n    ds.b 1  --+
;
;
; IN:
;    IX = file handle
;
; OUT:
;    Fc = 0,
;       HL = pointer to area in S0 (bound) containing relocation table
;    Fc = 1,
;       A = RC_Room, no space in memory to load relocation table
;       A = I/O error, problem reading from file
;
.alloc_rlctbl
        ld      hl,sz_relocfn
        call    fseek64k                        ; position file pointer at low byte of total_elements variable in file

        push    iy
        pop     hl
        ld      bc,rlctbltle
        add     hl,bc                           ; HL points to first low byte of 16bit variable [rlctblttl]
        ex      de,hl                           ; load total_elements and sizeof_table
        ld      c,4                             ; (4 bytes)
        call    ldblock                         ; installed into stack variables (IX file pointer is now 1st byte of relocation table)
        ret     c                               ; I/O error occurred

        push    ix                              ; preserve file handle
        ld      b,0
        ld      a, MM_MUL | MM_S0
        oz      OS_Mop                          ; get special memory handle for relocation table in S0
        jr      c,rlctbl_nohdl
        push    ix
        pop     bc
        ld      (iy + rlctblmhdl),c
        ld      (iy + rlctblmhdl+1),b           ; preserve temp. memory handle (will be released on exit

        ld      c,(iy + rlctblsz)
        ld      b,(iy + rlctblsz+1)             ; size of relocation table
        push    bc
        oz      OS_Mal                          ; allocate space for relocation table in S0
        jr      c,rlctbl_no_room
        ld      (iy + rlctblptr),l
        ld      (iy + rlctblptr+1),h
        rst     OZ_MPB                          ; bind allocated memory in HL of bank B into C = MS_S0 segment
                                                ; (old S0 binding is already registered)
        pop     bc                              ; length / size of relocation table to
        ex      de,hl                           ; load at DE
        pop     ix                              ; from file of function code
        call    ldblock
        ex      de,hl                           ; hl points to start of relocation table (if Fc = 0)
        ret
.rlctbl_no_room
        pop     bc
.rlctbl_nohdl
        pop     ix
        ret


; ********************************************************************************************************************
; Allocate memory and load code of function file.
;
.alloc_fnc
        ret


; ********************************************************************************************************************
.reloc_fnc
        ret


; ********************************************************************************************************************
.open_fnfile
        ld      c,sz_buf                        ; BHL points to filename
        push    iy
        pop     de                              ; point to exp.buffer (but not used)
        ld      a,OP_IN
        oz      GN_Opf
        ret     c
        push    ix
        pop     de
        ld      (iy+filehandle),e
        ld      (iy+filehandle+1),d             ; preserve file handle
        ret


; ********************************************************************************************************************
.getsz_fnfile
        ld      de,0
        ld      a, FA_EXT
        oz      OS_Frm
        ret     c
        ld      (iy+filesize),c
        ld      (iy+filesize+1),b               ; preserve total file size (always less than 16K, DE discarded)
        ret


; ********************************************************************************************************************
.close_fnfile
        push    af
        ld      e,(iy+filehandle)
        ld      d,(iy+filehandle+1)
        push    de
        pop     ix
        oz      GN_Cl
        pop     af
        ret


; ********************************************************************************************************************
; Watermark of relocation routine (first 8 bytes). This routine is standardized legacy code, always $49 length.
;
; 00000000  08          .relocator          ex   af,af'
; 00000001  D9                              exx
; 00000002  FD E5                           push iy
; 00000004  E1                              pop  hl
; 00000005  01 49 00                        ld   bc,$49
;
.relocfn_wm
        defb $08,$D9,$FD,$E5,$E1,$01,$49,$00