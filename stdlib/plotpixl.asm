
     XLIB plotpixel

     LIB pixeladdress
     XREF COORDS

; ******************************************************************
;
; Plot pixel at (x,y) coordinate.
;
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
; The (0,0) origin is placed at the bottom left corner.
;
; in:  hl = (x,y) coordinate of pixel (h,l)
;
; registers changed after return:
;  ..bc..../ixiy same
;  af..dehl/.... different
;
.plotpixel          ld   a,l
                    cp   64
                    ret  nc                  ; y0 out of range

                    push bc
                    ld   (COORDS),hl
                    ld   a,l
                    xor  @00111111           ; (0,0) is hardware (0,63)
                    ld   l,a

                    call pixeladdress
                    ld   b,a
                    ld   a,1
                    jr   z, or_pixel         ; pixel is at bit 0...
.plot_position      rlca
                    djnz plot_position
.or_pixel           ex   de,hl
                    or   (hl)
                    ld   (hl),a
                    pop  bc
                    ret
