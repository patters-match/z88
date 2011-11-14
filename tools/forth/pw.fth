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

CR .( Loading multiprogramming-aware PW...)
\ A version of PW suitable for use with multiprogramming
\ Uses window 6

HERE HEX
01 C, 37 C, 23 C, 36 C, 16 C, 22 C, 29 C, 26 C, 80 C,
01 C, 32 C, 43 C, 36 C,
01 C, S" BPAGE WAIT" HERE OVER ALLOT SWAP CMOVE
01 C, CHAR B C, 0D C, 0A C,
BL C, BL C, BL C, 01 C, E0 C, 0D C, 0A C,
01 C, S" T CONTINUE   " HERE OVER ALLOT SWAP CMOVE
01 C, E4 C, 0D C, 0A C,
S"   RESUME" HERE OVER ALLOT SWAP CMOVE
DECIMAL
HERE OVER - SWAP        \ S: u caddr
HERE 4 ALLOT            \ S: u caddr b

:NONAME                 \ S: u caddr b xt
   PAGE [ OVER DUP 2 + ] LITERAL @ WINDOW
   LITERAL @ IS (RC_ESC)
   (RC_ESC) ;

: PW_M
   ['] (RC_ESC) >BODY @ [ OVER ] LITERAL !
   LITERAL IS (RC_ESC)
   WINDOW? [ DUP 2 + ] LITERAL ! 2DROP
   [ ROT ROT ] LITERAL LITERAL TYPE
   EKEY DROP PAGE [ DUP 2 + ] LITERAL @ WINDOW
   LITERAL @ IS (RC_ESC) ;

' PW_M IS PW

