
     xlib createfilename

if unix | msdos
     include "fileio.def"
     include "dor.def"
     include "error.def"
     include "memory.def"
else
     include ":*//fileio.def"
     include ":*//dor.def"
     include ":*//error.def"
     include ":*//memory.def"
endif



; ******************************************************************************
;
;    Create filename and directory path.
;
;    Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
; Try to create the specified filename using OP_OUT. If a directory path is
; specified, it will automatically be created if not defined in the filing
; system.
;
; The filename must not contain wildcards (standard convention). However if a
; RAM device is not specified, it will automatically be included (the current)
; into the filename.
;
; The buffer of the filename must have space to get itself expanded with a
; device name (additional 6 bytes).
;
; The filename pointer may not point in segment 2, since GN_FEX is unreliable
; in that segment.
;
; The routine deletes an existing file without warning.
;
; in:     bhl = pointer to null-terminated filename, (b = 0, means local)
;
; out, if successful:
;         ix = file handle
;         fc = 0, file (and directory) successfully created
;         (hl) = filename may have been expanded
;
; out, if failed:
;         fc = 1, unable to create file (directory)
;         a = error code:
;              RC_IVF, Invalid filename
;              RC_USE, File already in use
;
;    registers changed after return:
;         ..bcdehl/..iy  same
;         af....../ix..  different
;
.createfilename     push bc                       ; preserve original BC
                    push de                       ; preserve original DE
                    push hl                       ; preserve original HL
                    push iy                       ; preserve original IY

                    push hl
                    pop  iy                       ; IY points at start of filename
                    inc  b
                    dec  b
                    jr   z, local_filename        ; pointer to filename is local

                         ld   a,h
                         and  @11000000
                         rlca
                         rlca
                         ld   c,a                      ; MS_Sx
                         call_oz(os_mpb)               ; page filename into segment
                         push bc                       ; preserve old bank binding
                         call createfile
                         pop  bc
                         push af                       ; preserve error status...
                         call_oz(os_mpb)               ; restore previous bank binding
                         pop  af
                         jr   exit_createflnm

.local_filename          call createfile

.exit_createflnm    pop  iy
                    pop  hl
                    pop  de
                    pop  bc
                    ret


; ******************************************************************************
;
;    Create the filename
;
;    IN:  HL = pointer to filename
;
.createfile         ld   d,h
                    ld   e,l
                    xor  a
                    ld   bc,255
                    cpir                          ; find null-terminator
                    dec  hl
                    ex   de,hl
                    sbc  hl,de                    ; length = end - start
                    ld   c,6
                    add  hl,bc
                    ld   c,l                      ; length of buffer + 6 (max. length 255 bytes)

.openfile           push iy                       ; c = length of buffer
                    pop  hl
                    ld   d,h                      ; hl = pointer to filename
                    ld   e,l                      ; de = pointer to output
                    ld   a, OP_OUT
                    call_oz(gn_opf)
                    ret  nc                       ; file created successfully, return...
                    cp   RC_ONF
                    jr   z, createdir             ; if error != RC_ONF
                         scf                           return error
                         ret

.createdir          call_oz(gn_fex)               ; first expand filename
                    ret  c                        ; invalid filename
                    ld   l,a
                    ld   a, RC_IVF                ; pre-load Fc = 1 & A = RC_IVF, if errors
                    scf
                    bit  7,l                      ; wildcards were used...
                    ret  nz
                    bit  1,l
                    ret  z                        ; filename not specified...

                    cp   a                        ; fc = 0
                    dec  b                        ; deduct filename segment
                    dec  b                        ; deduct device name segment
                    ex   de,hl                    ; hl points at null-terminator
                    call createpath               ; create directory path...
                    jr   nc, openfile             ; then try to create file again...
                    ret                           ; couldn't create directory, return...


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
.createpath         ld   a, '/'
.find_separator     cp   (hl)
                    jr   z, found_separator       ; directory separator found at (hl)
                    dec  hl
                    jr   find_separator

.found_separator    ld   (hl),0                   ; null-terminate directory path segment (level)
                    dec  b
                    push hl
                    call nz, createpath           ; if (pathlevel != 0) createpath(pathlevel, sep)
                    pop  hl
                    ret  c                        ; sub-path couldn't be created...
                    call mkdir
                    ld   (hl),'/'                 ; restore directory separator
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
