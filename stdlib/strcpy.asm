
     xlib strcpy
     lib read_byte, set_byte

; *******************************************************************************
;
;    Copy string (null-terminated) from extended address to extended address.
;
;    Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
;    Both pointers must be resident in segment 1.
;
;    IN:  BHL = pointer to source string
;         CDE = pointer to copy source string
;
;    OUT: None.
;
;    Registers changed after return:
;         AFBCDEHL/IXIY  same
;         ......../....  different
;
.strcpy             exx
                    push bc
                    push de
                    push hl                  ; preserve alternate registers
                    exx

                    push af
                    push bc
                    push de
                    push hl
                    push bc
                    push de
                    exx
                    pop  hl
                    pop  bc
                    ld   b,c                 ; destination pointer in alternate BHL
                    exx

.strcpy_loop        xor  a
                    call read_byte           ; get byte from source
                    inc  hl
                    ld   e,a
                    exx
                    ld   c,a
                    xor  a
                    call set_byte            ; and put byte to destination
                    inc  hl
                    exx
                    xor  a
                    cp   e                   ; copied null-terminator?
                    jr   nz, strcpy_loop     ; no, continue with next byte from source...

                    pop  hl
                    pop  de                  ; destination pointer restored
                    pop  bc                  ; source pointer restored
                    pop  af
                    exx
                    pop  hl
                    pop  de
                    pop  bc                  ; alternate registers restored
                    exx
                    ret
