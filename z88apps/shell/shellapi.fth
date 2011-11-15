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

CR .( Generating shellapi.def...)

CONSTANT loadaddr

S" shellapi.def" W/O CREATE-FILE THROW VALUE deffile


: write ( a u -- )
   deffile WRITE-FILE ABORT" Error writing file" ;

: writeln ( a u -- )
   deffile WRITE-LINE ABORT" Error writing file" ;

: n/l ( -- )
   S" " writeln ;

: writedef ( a u x -- )
   S" defc shell_" write >R write S" =$" write
   R> 0 HEX <# # # # # #> DECIMAL writeln ;

: getver ( -- a )
   DOR-COMPILED 255 S" (c)" SEARCH 0= ABORT" Can't find (c)"
   DROP 5 CHARS - ;

getver CONSTANT ver

S" ; Shell API Definitions" writeln
S" ; Auto-generated for Shell v" write ver 4 writeln
n/l
S" verh"	ver C@			writedef
S" verm"	ver 2 CHARS + C@	writedef
S" verl"	ver 3 CHARS + C@	writedef
S" loadaddr"	loadaddr		writedef
S" headerlen"	12			writedef
n/l
S" next"	' NOOP CHAR+ @		writedef
S" cmdaddr"	>IN 1 CELLS -		writedef
S" cmdlen"	>IN 2 CELLS -		writedef
S" cmdptr"	>IN			writedef
n/l
S" ztos"	' 0>S			writedef
S" eval"	' eval			writedef
S" allocate"	' ALLOCATE		writedef
S" free"	' FREE			writedef
S" freeall"	' FREEALL		writedef
n/l
S" ; TEMPORARY - for v0.25 only!" writeln
n/l
S" also"	' ALSO			writedef
S" internal"	' internal		writedef
S" previous"	' PREVIOUS		writedef


deffile CLOSE-FILE THROW
