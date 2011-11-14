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

CR .( Loading MIMEtypes words...)
\ Words for utilising the MIMEtypes package

HEX 1B DECIMAL CONSTANT mime_id
0 CONSTANT mode_uu
1 CONSTANT mode_b64

\ In these calls, "in" and "out" are filehandles,
\ "b" is the address of an 81 byte buffer (PAD will do),
\ and "m" is one of the constants mode_uu or mode_b64.
\ The returned code u is one of:
\  0=success, 1=incomplete file,
\  2=short line, 3=error writing output
\ (the encode function will only return 0 or 3)

HEX
2 4  0  00 0A1B  PKGCALL uudecode  ( in out b m -- u )
2 4  0  00 0C1B  PKGCALL uuencode  ( in out b m -- u )
DECIMAL

