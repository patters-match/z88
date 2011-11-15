\ *************************************************************************************
\
\ Shell (c) Garry Lancaster, 2001-2002
\
\ Shell is free software; you can redistribute it and/or modify it under
\ the terms of the GNU General Public License as published by the Free Software Foundation;
\ either version 2, or (at your option) any later version.
\ Shell is distributed in the hope that it will be useful, but WITHOUT
\ ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
\ PARTICULAR PURPOSE.
\ See the GNU General Public License for more details.
\ You should have received a copy of the GNU General Public License along with Shell;
\ see the file COPYING. If not, write to the Free Software Foundation, Inc.,
\ 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
\
\ *************************************************************************************

\ Makefile for Shell

ROM2 NS

S" xfsblock.bin" R/O OPEN-FILE THROW  ( -- id )
DUP DUP FILE-SIZE THROW DROP     ( -- id id size )
HERE OVER ALLOT                  ( -- id id size addr )
SWAP ROT READ-FILE THROW DROP    ( -- id )
CLOSE-FILE THROW 
S" :*//wildcard.fth" INCLUDED
S" :*//acceptmail.fth" INCLUDED
RAM NS

S" shell.fth" INCLUDED
HERE				\ save load address for later

S" :*//appgen.fth" INCLUDED
S" shell.dor" INCLUDED
HEX C000 DEFAULT-DOR 6 + ! DECIMAL

HEX 3E DEFAULT-DOR 8 + C! DECIMAL
S" shell-std" STANDALONE
HEX 3F DEFAULT-DOR 8 + C! DECIMAL
S" shell-cli" CLIENT

S" shellapi.fth" INCLUDED

CR .( Shell successfully generated)
