\ *************************************************************************************
\
\ Z88 Forth AppGen Tools (c) Garry Lancaster, 1999-2011
\
\ Z88 Forth AppGen Tools is free software; you can redistribute it and/or modify it under
\ the terms of the GNU General Public License as published by the Free Software Foundation;
\ either version 2, or (at your option) any later version.
\ Z88 Forth AppGen Tools is distributed in the hope that it will be useful, but WITHOUT
\ ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
\ PARTICULAR PURPOSE.
\ See the GNU General Public License for more details.
\ You should have received a copy of the GNU General Public License along with Z88
\ Forth AppGen Tools; see the file COPYING. If not, write to the
\ Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
\
\
\ *************************************************************************************

CR .( Loading map words...)

HEX
CODE getmap ( caddr -- )
  D5 C,         \ push de
  3A C, 04D3 ,  \ ld a,($04d3)
  F5 C,         \ push af
  3A C, GBASE 2 + , \ ld a,(basegr+2)
  A7 C,         \ and a
  28 C, 13 C,   \ jr z,done
  32 C, 04D3 ,  \ ld ($04d3),a
  D3 C, D3 C,   \ out ($d3),a
  2A C, GBASE , \ ld hl,(basegr)
  CB C, FC C,   \ set 7,h
  CB C, F4 C,   \ set 6,h
  50 C,         \ ld d,b
  59 C,         \ ld e,c
  01 C, 0800 ,  \ ld bc,2048
  ED C, B0 C,   \ ldir
  F1 C,         \ done: pop af
  32 C, 04D3 ,  \ ld ($04d3),a
  D3 C, D3 C,   \ out ($d3),a
  D1 C,         \ pop de
  C1 C,         \ pop bc
NEXT

CODE putmap ( caddr -- )
  D5 C,         \ push de
  3A C, 04D3 ,  \ ld a,($04d3)
  F5 C,         \ push af
  3A C, GBASE 2 + , \ ld a,(basegr+2)
  A7 C,         \ and a
  28 C, 14 C,   \ jr z,done
  32 C, 04D3 ,  \ ld ($04d3),a
  D3 C, D3 C,   \ out ($d3),a
  ED C, 5B C, GBASE , \ ld de,(basegr)
  CB C, FA C,   \ set 7,d
  CB C, F2 C,   \ set 6,d
  60 C,         \ ld h,b
  69 C,         \ ld l,c
  01 C, 0800 ,  \ ld bc,2048
  ED C, B0 C,   \ ldir
  F1 C,         \ done: pop af
  32 C, 04D3 ,  \ ld ($04d3),a
  D3 C, D3 C,   \ out ($d3),a
  D1 C,         \ pop de
  C1 C,         \ pop bc
NEXT
DECIMAL
