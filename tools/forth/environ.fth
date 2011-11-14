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

CR .( Loading environment variables...)
\ ANS Forth environment variables for Z88 CamelForth

 255  1 ENVVAR /COUNTED-STRING
  40  1 ENVVAR /HOLD
  88  1 ENVVAR /PAD
   8  1 ENVVAR ADDRESS-UNIT-BITS
 255  1 ENVVAR MAX-CHAR
32767 1 ENVVAR MAX-N
65535 1 ENVVAR MAX-U
65535 32767 2 ENVVAR MAX-D
65535 65535 2 ENVVAR MAX-UD
  64  1 ENVVAR RETURN-STACK-CELLS
 128  1 ENVVAR STACK-CELLS
TRUE  1 ENVVAR FLOORED

TRUE  1 ENVVAR CORE
FALSE 1 ENVVAR CORE-EXT
TRUE  1 ENVVAR BLOCK
TRUE  1 ENVVAR BLOCK-EXT
TRUE  1 ENVVAR EXCEPTION
TRUE  1 ENVVAR EXCEPTION-EXT
TRUE  1 ENVVAR FACILITY
TRUE  1 ENVVAR FACILITY-EXT
TRUE  1 ENVVAR FILE
TRUE  1 ENVVAR FILE-EXT
TRUE  1 ENVVAR SEARCH-ORDER
TRUE  1 ENVVAR SEARCH-ORDER-EXT
   8  1 ENVVAR WORDLISTS
TRUE  1 ENVVAR STRING
TRUE  1 ENVVAR STRING-EXT

