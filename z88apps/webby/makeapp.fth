\ *************************************************************************************
\
\ Webby (c) Garry Lancaster, 2001-2002
\
\ Webby is free software; you can redistribute it and/or modify it under
\ the terms of the GNU General Public License as published by the Free Software Foundation;
\ either version 2, or (at your option) any later version.
\ Webby is distributed in the hope that it will be useful, but WITHOUT
\ ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
\ PARTICULAR PURPOSE.
\ See the GNU General Public License for more details.
\ You should have received a copy of the GNU General Public License along with Webby;
\ see the file COPYING. If not, write to the Free Software Foundation, Inc.,
\ 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
\
\ *************************************************************************************

\ Makefile for Webby

ROM2 NS
S" :*//acceptmail.fth" INCLUDED
S" :*//tcpip.fth" INCLUDED
RAM NS

S" webby.fth" INCLUDED

S" :*//appgen.fth" INCLUDED
S" webby.dor" INCLUDED

S" webby-std" STANDALONE
S" webby-cli" CLIENT

CR .( Webby successfully generated)
