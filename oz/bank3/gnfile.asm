; -----------------------------------------------------------------------------
; Bank 3 @ S3           ROM offset $dd1a
;
; $Id$
; -----------------------------------------------------------------------------

        Module GNFile

        org $dd1a                               ; 441 bytes

        include "all.def"
        include "sysvar.def"

;       ----

xdef    GNCl
xdef    GNDel
xdef    GNOpf
xdef    GNRen

;       ----

xref    CompressFN              
xref    FreeDOR                 
xref    GetFsNodeDOR            
xref    GetOsf_BHL              
xref    GN_ret1a                
xref    IsSegSeparator          
xref    PutOsf_Err              

;       ----

;       open file/resource
;
;IN:    BHL=name, DE=buffer for explicit filename, C=buffer size,
;       A=mode
;         OP_IN : open for input
;         OP_OUT: open for output
;         OP_UP : open for update
;         OP_MEM: open memory
;         OP_DIR: create directory
;         OP_DOR: return DOR information
;OUT:   IX=handle, DE=end of name, B=#segments in name, C=#chars in name
;       Fc=1, A=error
;CHG:   AFBCDE../IX..


.GNOpf
        OZ      OS_Bix                          ; bind name in
        push    de

        ld      de, GnFnameBuf
        ld      c, 205
        OZ      GN_Fex                          ; expand a filename
        pop     de
        push    af
        OZ      OS_Box
        pop     af
        jp      c, opf_err                      ; bad name?

        bit     7, a                            ; if wildcards were used we
        jr      z, opf_1                        ; reject OP_DIR and OP_OUT
        ld      a, (iy+OSFrame_A)
        cp      OP_DIR
        jp      z, opf_errIvf
        cp      OP_OUT
        jp      z, opf_errIvf           

;       find first file matching wildcard string

        ld      a, 1                            ; backward scan
        ld      b, 0
        ld      hl, GnFnameBuf
        OZ      GN_Opw                          ; open wildcard handler
        jp      c, opf_err
        ld      de, GnFnameBuf                  ; !! ex de, hl
        ld      c, 205
        xor     a
        OZ      GN_Wfn                          ; get next match
        push    af
        OZ      GN_Wcl                          ; close handler
        pop     af
        jr      nc, opf_1                       ; no error? use found file
        cp      RC_Eof                          ; EOF -> object not found
        jp      nz, opf_err                     ; else return as-is
        jr      opf_errOnf

;       we have valid name in GnFnameBuf

.opf_1
        push    bc
        call    GetFsNodeDOR
        pop     bc
        ld      c, a                            ; remember type

        ld      a, (iy+OSFrame_A)
        jr      c, opf_8                        ; does not exist? ok

        cp      OP_DIR                          ; create dir? already exists
        jr      nz, opf_3
        ld      a, RC_Exis
.opf_2
        push    af
        call    FreeDOR
        pop     af
        jr      opf_err

.opf_3
        cp      OP_OUT                          ; write? allow char device and file
        jr      nz, opf_6
        ld      a, c
        cp      DM_CHD
        jr      z, opf_open                     ; write to char device? ok
        cp      DN_FIL
        jr      z, opf_5                        ; write to file? delete and continue
.opf_errFtm
        ld      a, RC_Ftm                       ; file type mismatch
        jr      opf_2

.opf_5
        OZ      OS_Del                          ; delete file
        jr      c, opf_err                      ; error?
        ld      a, OP_OUT
        jr      opf_8

.opf_6
        cp      OP_DOR                          ; get DOR?
        jr      nz, opf_7
        ld      (iy+OSFrame_A), c               ; return type
        jr      opf_name                                ; and name

;       file exists, OP_IN/OP_UP/OP_MEM

.opf_7
        ld      a, c                            ; allow char device and file
        cp      DM_CHD
        jr      z, opf_open
        cp      DN_FIL
        jr      z, opf_open
        jr      opf_errFtm

;       does not exist (or OP_OUT after delete)

.opf_8
        cp      OP_DIR                          ; allow create dir / write file
        jr      z, opf_10
        cp      OP_OUT
        jr      z, opf_10
.opf_errOnf
        ld      a, RC_Onf                       ; object not found
        jr      opf_err

;       get parent DOR

.opf_10
        dec     b                               ; go up one level if possible
        jr      nz, opf_11
        inc     b
.opf_11
        call    GetFsNodeDOR
        jr      c, opf_err                      ; parent not found?
        cp      DM_DEV                          ; allow dev/dir
        jr      z, opf_open
        cp      DN_DIR
        jr      nz, opf_errFtm
.opf_open
        ld      a, (iy+OSFrame_A)               ; OP_xxx
        inc     hl                              ; point to name
        OZ      OS_Op                           ; internal open
        jr      c, opf_err

.opf_name
        ld      b, 0
        ld      hl, GnFnameBuf
        call    CompressFN
        jr      opf_x

.opf_errIvf
        ld      a, RC_Ivf                       ; invalid filename
.opf_err
        call    PutOsf_Err
        ld      ix, 0
.opf_x
        ret

;       ----

;       close file
;
;IN:    IX=handle
;OUT:   IX=0
;       Fc=1, A=error
;
;CHG:   AF....../IX..

.GNCl
        OZ      OS_Cl                           ; pass it to OS_Cl
        jp      GN_ret1a

;       ----

;       rename file/directory
;
;IN:    BHL=old name, DE=new name
;OUT:   Fc=0
;       Fc=1, A=error
;CHG:   AF....../....

;       !! could move file if new name has path rename

.GNRen
        push    ix
        ld      hl, -17                         ; reserve space for new name
        add     hl, sp
        ld      sp, hl

        ex      de, hl                          ; bind in new name
        push    de
        OZ      OS_Bix                          ; Bind in extended address
        ex      (sp), hl                        ; ex (sp),de
        ex      de, hl
        ex      (sp), hl

        ld      b, 16
        ld      a, (hl)                         ; skip leading /\:
        call    IsSegSeparator                  ; !! this allows ':RAM.x' etc.
        jr      nz, ren_1
        inc     hl
        dec     b                               ; !! why?

.ren_1
        ld      a, (hl)                         ; copy name to stack buffer
        ld      (de), a
        inc     hl
        inc     de
        cp      $21
        jr      c, ren_2
        djnz    ren_1                           ; max 16 chars
.ren_2
        xor     a                               ; terminate
        ld      (de), a

        pop     de                              ; restore bindings
        OZ      OS_Box

        call    GetOsf_BHL                      ; bind in old name
        OZ      OS_Bix
        push    de

        push    hl
        ld      hl, 4
        add     hl, sp                          ; HL=new name
        ld      b, 0
        OZ      GN_Pfs                          ; parse it
        pop     hl
        jr      c, ren_errIvf                   ; bad name

        and     $fc
        jr      nz, ren_errIvf                  ; anything but name+extension?

        ld      de, GnFnameBuf
        ld      c, 205
        ld      a, OP_DOR
        OZ      GN_Opf                          ; open old file/dir
        ld      c, b                            ; #segments
        jr      c, ren_err                      ; not found
        cp      DN_FIL                          ; can only rename file/dir
        jr      z, ren_3
        cp      DN_DIR
        jr      nz, ren_errIvf                  ; !! RC_Ftm would be better
.ren_3
        ld      e, c
        dec     c
        jr      z, ren_errIvf                   ; only one segment?

        ld      hl, GnFnameBuf
        ld      b, 0
.ren_4
        OZ      GN_Pfs                          ; parse segment
        jr      c, ren_err                      ; bad?
        dec     c
        jr      nz, ren_4                       ; loop until all but last segments done

        inc     hl                              ; skip '/'
        ld      b, e
        ex      de, hl                          ; DE=destination
        ld      hl, 2                           ; HL=new name
        add     hl, sp
.ren_5
        ld      a, (hl)                         ; overwrite old name
        ld      (de), a
        inc     hl
        inc     de
        cp      $21
        jr      nc, ren_5

        push    ix
        call    GetFsNodeDOR                    ; try to find new file/dir
        jr      c, ren_6                        ; not found? ok
        ld      a, DR_FRE
        OZ      OS_Dor                          ; DOR interface
        pop     ix
        ld      a, RC_Exis                      ; object already exists
        jr      ren_err

.ren_6
        pop     ix                              ; restore old object DOR
        cp      RC_Onf                          ; object not found is ok
        jr      nz, ren_err                     ; otherwise error

        ld      hl, 2                           ; new name
        add     hl, sp
        OZ      OS_Ren                          ; file rename
        jr      ren_9

.ren_errIvf
        ld      a, RC_Ivf                       ; Invalid filename
.ren_err
        scf
.ren_9
        push    af
        push    ix                              ; !! use FreeDOR()
        pop     de
        ld      a, d
        or      e
        jr      z, ren_10
        ld      a, DR_FRE
        OZ      OS_Dor

.ren_10
        pop     af
        pop     de
        ex      af, af'                         ; need to remember Fc
        ld      hl, 17                          ; restore stack
        add     hl, sp
        ld      sp, hl
        ex      af, af'
        push    af
        OZ      OS_Box
        pop     af
        call    c, PutOsf_Err
        pop     ix
        ret

;       ----

;       delete file/directory
;
;IN:    BHL=filename
;OUT:   Fc=0
;       Fc=1, A=error
;
;CHG:   AF....../....

.GNDel
        push    ix
        OZ      OS_Bix                          ; bind name in
        push    de

        ld      de, GnFnameBuf
        ld      c, 205
        OZ      GN_Fex                          ; expand it
        jr      c, del_err                      ; bad name

        and     $80                             ; wildcards?
        jr      z, del_1
        scf                                     ; no wildcard delete
        ld      a, RC_Ivf
        jr      del_err

.del_1
        call    GetFsNodeDOR
        jr      c, del_err                      ; not found?
        cp      DN_FIL                          ; only delete files/dirs
        jr      z, del_2
        cp      DN_DIR
        jr      nz, del_3                       ; !! no error for others, tho
.del_2
        OZ      OS_Del
        jr      c, del_err
.del_3
        call    FreeDOR
.del_err
        call    c, PutOsf_Err
        pop     de
        OZ      OS_Box
        pop     ix
        ret
