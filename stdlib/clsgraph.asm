
     XLIB cleargraphics

     XREF base_graphics


; ******************************************************************
;
;    Clear graphics area, i.e. reset all bits in graphics (map)
;    window of width L x 64 pixels.
;
;    Design & programming by Gunther Strube, Copyright (C) InterLogic 1995-98
;
; IN:
;    L = width of map area (modulus 8).
;
; OUT:
;    None.
;
;    Registers changed after return:
;         a.bcdehl/ixiy  same
;         .f....../....  different
;
.cleargraphics      push bc
                    push de
                    push hl

                    push af
                    ld   h,0
                    ld   a,@11111000         ; only width of modulus 8
                    and  l
                    ld   l,a
                    pop  af

                    add  hl,hl
                    add  hl,hl
                    add  hl,hl
                    dec  hl                  ; <width> * 64 / 8 - 1 bytes to clear..
                    ld   b,h
                    ld   c,l                 ; total of bytes to reset...

                    ld   hl,(base_graphics)  ; base of graphics area
                    ld   (hl),0
                    ld   d,h
                    ld   e,1                 ; de = base_graphics+1
                    ldir                     ; reset graphics window (2K)
                    pop  hl
                    pop  de
                    pop  bc
                    ret
