     xlib CreateDirectory

; **************************************************************************************************
; This file is part of the Z88 Standard Library.
;
; The Z88 Standard Library is free software; you can redistribute it and/or modify it under 
; the terms of the GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; The Z88 Standard Library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with FlashStore;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
; 
; $Id$  
;
;***************************************************************************************************

     include "fileio.def"
     include "dor.def"
     include "error.def"
     include "memory.def"



; ******************************************************************************
;
; Create Directory Path.
;
; The directory name must not contain wildcards (standard convention).
; However if a RAM device is not specified, it will automatically be included
; (the current) into the directory name.
;
; The buffer of the directory name must have space enough to get itself expanded
; with a device name (additional 6 bytes).
;
; The filename pointer may not point in segment 2, since GN_FEX is unreliable
; in that segment.
;
; in:     bhl = pointer to null-terminated directory path name, (b = 0, means local)
;
; out, if successful:
;         fc = 0, directory successfully created
;         (hl) = filename may have been expanded
;
; out, if failed:
;         fc = 1, unable to create directory
;         a = error code:
;              RC_IVF, Invalid directory path name
;              RC_USE, Directory in use
;              RC_EXIS, Directory already exists
;
;    registers changed after return:
;         ..bcdehl/..iy  same
;         af....../ix..  different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1997
; ----------------------------------------------------------------------
;
.CreateDirectory    push bc                       ; preserve original BC
                    push de                       ; preserve original DE
                    push hl                       ; preserve original HL
                    push iy                       ; preserve original IY

                    push hl
                    pop  iy                       ; IY points at start of filename
                    inc  b
                    dec  b
                    jr   z, local_dir             ; pointer to filename is local

                         ld   a,h
                         and  @11000000
                         rlca
                         rlca
                         ld   c,a                      ; MS_Sx
                         call_oz(os_mpb)               ; page filename into segment
                         push bc                       ; preserve old bank binding
                         call createdir
                         pop  bc
                         push af                       ; preserve error status...
                         call_oz(os_mpb)               ; restore previous bank binding
                         pop  af
                         jr   exit_createdir

.local_dir               call createdir

.exit_createdir     pop  iy
                    pop  hl
                    pop  de
                    pop  bc
                    ret


; ******************************************************************************
;
;    Create the filename
;
;    IN:  HL = pointer to directory path
;
.createdir          ld   b,0                      ; filename available in address space
                    ld   d,h                      ; HL points at start of filename
                    ld   e,l                      ; DE points at scratch buffer
                    ld   a, OP_DOR
                    call_oz(gn_opf)               ; try to open directory path (DOR record)...
                    jr   c, try_create            ; an error occurred (presumably not found)
                         ld   a, dr_fre                ; directory was opened!
                         call_oz(os_dor)               ; free dor handle
                         ld   a, RC_EXIS
                         scf                           ; return "directory already created!"
                         ret
.try_create         push hl
                    xor  a
                    ld   bc,255
                    cpir                          ; find null-terminator
                    ld   a,255
                    inc  c
                    sub  c
                    add  a,6
                    ld   c,a                      ; length of buffer + 6 (max. length 255 bytes)
                    pop  hl

                    ld   d,h                      ; B = 0, C = length of buffer
                    ld   e,l                      ; DE points at output buffer...
                    call_oz(gn_fex)               ; first expand filename
                    ret  c                        ; invalid filename

                                                  ; name expanded successfully,
                                                  ; DE points at null-terminator
                    ld   l,a
                    ld   a, RC_IVF                ; pre-load Fc = 1 & A = RC_IVF, if errors
                    scf
                    bit  7,l                      ; wildcards were used...
                    ret  nz
                    bit  1,l
                    ret  z                        ; filename not specified...

                    cp   a                        ; fc = 0
                    ex   de,hl                    ; hl points at null-terminator
                    call createpath               ; create directory path...
                    ret


; ******************************************************************************
;
;    create directory sub-paths, recursively.
;
; in:     hl = pointer to null-terminator
;         b = number of directory path segments (levels) to create
;         c = length of filename
;
; out:    fc = 0, directory path created successfully, otherwise fc = 1
;

.createpath         push hl
                    ld   d,(hl)                   ; preserve separator/null
                    ld   (hl),0                   ; this segment is en of path
                    push de
                    dec  b
                    ld   a,1                      ; only dev & root directory left..
                    cp   b
                    call nz, find_separator       ; more than one sub directory
                    call nz, createpath
                    call mkdir                    ; now create this sub directory
                    pop  de
                    pop  hl
                    ld   (hl),d                   ; restore separator/null
                    ret

.find_separator     push af                       ; scan for end of previous segment
.find_sep_loop      ld   a, '/'
                    cp   (hl)
                    jr   z, found_separator       ; directory separator found at (hl)
                    dec  hl
                    jr   find_sep_loop
.found_separator    pop  af                       ; HL points at segment separator
                    ret

.mkdir              push bc                       ; preserve current level in B
                    push hl                       ; preserve length of scratch buffer in C
                    push iy                       ; preserve pointer to current separator
                    pop  hl
                    ld   b,0                      ; local pointer (filename always paged in)
                    ld   d,h                      ; HL points at start of filename
                    ld   e,l                      ; DE points at scratch buffer
                    ld   a, OP_DIR
                    call_oz(gn_opf)               ; mkdir pathname (returns DOR handle)
                    jr   nc, exit_mkdir
                    cp   RC_USE
                    jr   z, quit_mkdir            ; in use (it exists)...
                    cp   RC_EXIS
                    jr   z, quit_mkdir            ; already created...
                    scf
                    jr   quit_mkdir               ; other error occurred
.exit_mkdir         ld   a, dr_fre
                    call_oz(os_dor)               ; free dor handle
.quit_mkdir         pop  hl
                    pop  bc
                    ret
