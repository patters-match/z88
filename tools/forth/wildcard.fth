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

CR .( Loading Wildcards...)

HEX

0 CONSTANT D/N       \ directories first, not full path
1 CONSTANT F/N       \ files first, not full path
2 CONSTANT D/P       \ directories first, return full path
3 CONSTANT F/P       \ files first, return full path

CODE OPEN-WILD ( 0-addr mode -- whndl | 0 )
  79 C,              \ ld a,c
  E1 C,              \ pop hl
  DD C, E5 C,        \ push ix
  06 C, 00 C,        \ ld b,0
  E7 C, 5209 ,       \ call_oz(gn_opw)
  30 C, 04 C,        \ jr nc,okay
  DD C, 21 C, 0000 , \ ld ix,0
  DD C, E3 C,        \ okay: ex (sp),ix
  C1 C,              \ pop bc
NEXT

CODE WILD ( whndl -- caddr u type )
  D5 C,              \ push de
  C5 C,              \ push bc
  DD C, E3 C,        \ ex (sp),ix
  11 C, 0PAD ,       \ ld de,0PAD
  0E C, FF C,        \ ld c,255
  E7 C, 5609 ,       \ call_oz(gn_wfn)
  DD C, E1 C,        \ pop ix
  D1 C,              \ pop de
  06 C, 00 C,        \ ld b,0
  30 C, 03 C,        \ jr nc,okay
  AF C,              \ xor a
  0E C, 01 C,        \ ld c,1
  21 C, 0PAD ,       \ okay: ld hl,0PAD
  E5 C,              \ push hl
  0B C,              \ dec bc
  C5 C,              \ push bc
  4F C,              \ ld c,a
NEXT

CODE CLOSE-WILD ( whndl -- )
  D5 C,              \ push de
  C5 C,              \ push bc
  DD C, E3 C,        \ ex (sp),ix
  E7 C, 5409 ,       \ call_oz(gn_wcl)
  DD C, E1 C,        \ pop ix
  D1 C,              \ pop de
  C1 C,              \ pop bc
NEXT

\ xt must have the following stack effects: ( caddr u type -- )

: DOWILD ( 0addr mode xt -- )
   >R OPEN-WILD ?DUP
   IF  BEGIN  DUP WILD ?DUP  WHILE  R@ EXECUTE  REPEAT 2DROP CLOSE-WILD  THEN
   R> DROP ;

\ DOR constants

11 CONSTANT D_FIL
12 CONSTANT D_DIR
13 CONSTANT D_APL
81 CONSTANT D_DEV
82 CONSTANT D_CHD
83 CONSTANT D_ROM

\ Special constants for use with OPEN-FILE

5 CONSTANT NEWDIR
6 CONSTANT OPDOR

\ DOR manipulation
\ Record types are:
\  CHAR N  Name
\  CHAR U  Update date
\  CHAR C  Create date
\  CHAR X  File extent (4 bytes)
\  CHAR A  Attributes (2 bytes)
\  CHAR H  Help type (12 bytes)
\  CHAR @  Information

CODE DOR@ ( hdl caddr type -- u|0 )
  41 C,              \ ld b,c
  0E C, FF C,        \ ld c,255
  E1 C,              \ pop hl
  DD C, E3 C,        \ ex (sp),ix
  D5 C,              \ push de
  EB C,              \ ex de,hl
  3E C, 09 C,        \ ld a,dr_rd
  E7 C, 87 C,        \ call_oz(os_dor)
  D1 C,              \ pop de
  DD C, E1 C,        \ pop ix
  06 C, 00 C,        \ ld b,0
  30 C, 01 C,        \ jr nc,okay
  48 C,              \ ld c,b  okay:
NEXT

CODE DOR! ( hdl caddr u type -- )
  41 C,              \ ld b,c
  E1 C,              \ pop hl
  4D C,              \ ld c,l
  E1 C,              \ pop hl
  DD C, E3 C,        \ ex (sp),ix
  D5 C,              \ push de
  EB C,              \ ex de,hl
  3E C, 0A C,        \ ld a,dr_wr
  E7 C, 87 C,        \ call_oz(os_dor)
  D1 C,              \ pop de
  DD C, E1 C,        \ pop ix
  C1 C,              \ pop bc
NEXT

CODE CLOSE-DOR ( hdl -- )
  C5 C,              \ push bc
  DD C, E3 C,        \ ex (sp),ix
  3E C, 05 C,        \ ld a,dr_fre
  E7 C, 87 C,        \ call_oz(os_dor)
  DD C, E1 C,        \ pop ix
  C1 C,              \ pop bc
NEXT

\ Explicit filenames

CODE >EXPL ( 0-addr -- 0-addr' )
  60 C,              \ ld h,b
  69 C,              \ ld l,c
  01 C, 0080 ,       \ ld bc,128
  D5 C,              \ push de
  11 C, 0PAD 80 + ,  \ ld de,0PAD+128
  E7 C, 5009 ,       \ call_oz(gn_fex)
  D1 C,              \ pop de
  01 C, 0PAD 80 + ,  \ ld bc,0PAD+128
NEXT

\ Current settings enquiries and changes

8C00 CONSTANT DEV
8C03 CONSTANT DIR
8C06 CONSTANT FNM

CODE OS_NQ ( reason -- caddr u )
  E7 C, 66 C,        \ call_oz(os_nq)
  D5 C,              \ push de
  11 C, 0PAD ,       \ ld de,0PAD
  0E C, 00 C,        \ ld c,0
  E7 C, 3E09 ,       \ loop: call_oz(gn_rbe)
  A7 C,              \ and a
  28 C, 06 C,        \ jr z,done
  12 C,              \ ld (de),a
  13 C,              \ inc de
  23 C,              \ inc hl
  0C C,              \ inc c
  20 C, F4 C,        \ jr nz,loop
  D1 C,              \ done: pop de
  21 C, 0PAD ,       \ ld hl,0PAD
  E5 C,              \ push hl
  06 C, 00 C,        \ ld b,0
NEXT

\ Note: always specify directory path with a leading / otherwise OS_NQ
\       will fail when reading it back

CODE OS_SP ( 0addr reason -- )
  E1 C,              \ pop hl
  E7 C, 69 C,        \ call_oz(os_sp)
  C1 C,              \ pop bc
NEXT

\ OZ errors

CODE .OZERR ( code -- )
  79 C,              \ ld a,c
  E7 C, 4C09 ,       \ call_oz(gn_esp)
  E7 C, 3C09 ,       \ call_oz(gn_soe)
  C1 C,              \ pop bc
NEXT

DECIMAL
   
