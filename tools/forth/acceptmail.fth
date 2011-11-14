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

CR .( Loading filename handler...)
\ Filename handling via ACCEPT

: bss
   0 ?DO  8 EMIT  LOOP ;

\ A mail handler

: NAME  0" NAME" ;

: rinput ( ..in accept..: a u -- )
   2>R  bss  OVER SPACES  SWAP bss  OVER 2R>
   ROT UMIN 2DUP TYPE >R OVER R@ CMOVE R> TUCK ;

: fmail
   NAME CHECKMAIL IF  1- rinput  THEN ;

\ A filename requester, uses mail handler if flag is true

: getfname ( f -- a u )
   IF  ['] fmail IS (ACC_MAIL)  THEN
   PAD DUP 80 ACCEPT CR
   ['] NOOP IS (ACC_MAIL) ;
