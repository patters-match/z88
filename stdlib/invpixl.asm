
     XLIB invpixel

     LIB pixeladdress
     XREF COORDS

; ******************************************************************
;
; Inverse pixel at (x,y) coordinate
;
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
; in:  hl = (x,y) coordinate of pixel (h,l)
;
; registers changed after return:
;  ..bc..../ixiy same
;  af..dehl/.... different
;
.invpixel           ld   a,l
                    cp   64
                    ret  nc                  ; y0 out of range...

                    push bc
                    ld   (COORDS),hl         ; save new plot coordinate
                    ld   a,l
                    xor  @00111111           ; (0,0) is hardware (0,63)
                    ld   l,a
                    call pixeladdress
                    ld   b,a
                    ld   a,1
                    jr   z, xor_pixel
.inv_position       rlca
                    djnz inv_position
.xor_pixel          ex   de,hl
                    xor  (hl)
                    ld   (hl),a
                    pop  bc
                    ret
