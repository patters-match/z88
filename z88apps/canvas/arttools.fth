\ *************************************************************************************
\
\ Canvas (c) Garry Lancaster, 2001-2002
\
\ Canvas is free software; you can redistribute it and/or modify it under
\ the terms of the GNU General Public License as published by the Free Software Foundation;
\ either version 2, or (at your option) any later version.
\ Canvas is distributed in the hope that it will be useful, but WITHOUT
\ ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
\ PARTICULAR PURPOSE.
\ See the GNU General Public License for more details.
\ You should have received a copy of the GNU General Public License along with Canvas;
\ see the file COPYING. If not, write to the Free Software Foundation, Inc.,
\ 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
\
\ *************************************************************************************

CR .( Loading Canvas art tools...)

\ Brushes

CREATE brushes  2 BASE !
00000000 C, \ brush 0
00000000 C,
00011000 C,
00111100 C,
00111100 C,
00011000 C,
00000000 C,
00000000 C,

00011000 C, \ brush 1
00111100 C,
01111110 C,
11111111 C,
11111111 C,
01111110 C,
00111100 C,
00011000 C,
DECIMAL

\ Shading patterns

CREATE patterns
 238 C, 187 C, 238 C, 187 C, 238 C, 187 C, 238 C, 187 C,
 204 C,  51 C, 204 C,  51 C, 204 C,  51 C, 204 C,  51 C,
   0 C, 255 C,   0 C, 255 C,   0 C, 255 C,   0 C, 255 C,
 170 C, 170 C, 170 C, 170 C, 170 C, 170 C, 170 C, 170 C,
  37 C, 146 C,  37 C, 146 C,  37 C, 146 C,  37 C, 146 C,
  17 C,  68 C,  17 C,  68 C,  17 C,  68 C,  17 C,  68 C,
 243 C, 243 C, 243 C,   0 C,  63 C,  63 C,  63 C,   0 C,
  32 C, 112 C,  34 C,   7 C,  18 C,  56 C,  16 C,   0 C,

