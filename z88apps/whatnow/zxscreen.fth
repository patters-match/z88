\ *************************************************************************************
\
\ WhatNow? (c) Garry Lancaster, 2001
\
\ WhatNow? is free software; you can redistribute it and/or modify it under
\ the terms of the GNU General Public License as published by the Free Software Foundation;
\ either version 2, or (at your option) any later version.
\ WhatNow? is distributed in the hope that it will be useful, but WITHOUT
\ ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
\ PARTICULAR PURPOSE.
\ See the GNU General Public License for more details.
\ You should have received a copy of the GNU General Public License along with WhatNow?;
\ see the file COPYING. If not, write to the Free Software Foundation, Inc.,
\ 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
\
\ *************************************************************************************

\ Code word to copy a ZX screen third to the map
\ Must be a proper "third", not just any old point in the screen
\ This relies on knowledge of the address of BASEGR, thus on a particular
\ version of CamelForth. Currently correct for v3.00.

CR .( Loading ZX Screen displayer...)

HEX
CODE zxscreen ( c-addr -- )        \ Copy third of ZX Screen to map
60 C,            \ ld      h,b
69 C,            \ ld      l,c       \ HL=ZX screen address
3A C, 04D3 ,     \ ld      a,($04D3)
47 C,            \ ld      b,a       \ B=original seg3 binding
3A C, 20FD ,     \ ld      a,(basegr+2)
A7 C,            \ and     a
28 C, 40 C,      \ jr      z,endzx   \ do nothing if no map
32 C, 04D3 ,     \ ld      ($04D3),a \ else bind to segment 3
D3 C, D3 C,      \ out     ($0D3),a
D5 C,            \ push    de        \ save IP and RP
DD C, E5 C,      \ push    ix
C5 C,            \ push    bc        \ save original seg3 binding
ED C, 5B C, 20FB , \ ld      de,(basegr)    \ get map address (seg2)
CB C, FA C,      \ set     7,d
CB C, F2 C,      \ set     6,d       \ convert to seg3
D5 C,            \ push    de
DD C, E1 C,      \ pop     ix        \ IX contains map address
06 C, 08 C,      \ ld      b,8       \ 8 lines to display
C5 C,            \ .lthirdloop     push    bc
E5 C,            \  push    hl
0E C, 20 C,      \  ld      c,32      \ 32 characters per line
11 C, 100 ,      \  ld      de,256    \ 32*8 bytes per line
E5 C,            \ .llineloop      push    hl
06 C, 08 C,      \ ld      b,8       \ 8 rows per character
7E C,            \ .lcharloop      ld      a,(hl)     \ copy a character
DD C, 77 C, 0 C, \ ld      (ix+0),a
19 C,            \  add     hl,de
DD C, 23 C,      \ inc     ix
10 C, F7 C,      \ djnz    lcharloop
E1 C,            \ pop     hl
23 C,            \ inc     hl
0D C,            \ dec     c
20 C, EF C,      \ jr      nz,llineloop
E1 C,            \ pop     hl
11 C, 20 ,       \ ld      de,32
19 C,            \ add     hl,de     \ start of next character line
C1 C,            \ pop     bc
10 C, E0 C,      \ djnz    lthirdloop
C1 C,            \ pop     bc
78 C,            \ ld      a,b
32 C, 04D3 ,     \ ld      ($04D3),a
D3 C, D3 C,      \ out     ($0D3),a  \ rebind segment 3
DD C, E1 C,      \ pop     ix        \ restore RP & IP
D1 C,            \ pop     de
C1 C,            \ .endzx pop   bc        \ get new TOS
NEXT
DECIMAL

