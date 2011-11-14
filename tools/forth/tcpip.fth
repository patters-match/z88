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

CR .( Loading TCP/IP words...)
\ Words for using TCP/IP with the ZSock package 

HEX 15 DECIMAL CONSTANT zsock_id
 6 CONSTANT tcp
17 CONSTANT udp

\ Some words for playing with IP addresses,
\ where written address is a.b.c.d

: ip>  ( Dip-addr -- a b c d )
   SPLIT ROT SPLIT ;

: >ip  ( a b c d -- Dip-addr )
   JOIN ROT ROT JOIN ;

\ The actual package calls

HEX

\ The busy-wait loop!

0 0 0 00 1615 PKGCALL GoTCP         ( -- )

\ Socket routines

2 3 0 00 0C15 PKGCALL sock_write    ( sck caddr u1 -- u2 )
2 2 0 01 0C15 PKGCALL sock_emit     ( c sck -- u )
0 1 0 03 0C15 PKGCALL sock_flush    ( sck -- )
2 3 0 04 0C15 PKGCALL sock_read     ( sck caddr u1 -- u2 )
0 1 0 05 0C15 PKGCALL sock_close    ( sck -- )
0 1 0 06 0C15 PKGCALL sock_abort    ( sck -- )
0 1 0 07 0C15 PKGCALL sock_shutdown ( sck -- )
2 1 0 08 0C15 PKGCALL sock_data?    ( sck -- u )
1 1 0 09 0C15 PKGCALL sock_opened?  ( sck -- 0 | 1 )
1 1 0 0A 0C15 PKGCALL sock_closed?  ( sck -- 0 | 1 )
2 5 0 0B 0C15 PKGCALL sock_listen   ( Dip port 0 prot--sck|0)
2 5 0 0C 0C15 PKGCALL sock_open     ( Dip port 0 prot--sck|0)
2 1 0 2C 0C15 PKGCALL sock_waitopen   ( sck -- 0 | 1 )
2 1 0 2E 0C15 PKGCALL sock_waitclose  ( sck -- 0 | 1 )

\ Name-resolution routines

4 1 0 12 0C15 PKGCALL (resolve)
: resolve  (resolve) SWAP ;           ( 0-addr -- Dip )
2 3 0 13 0C15 PKGCALL -resolve        ( Dip buffer -- f )
4 0 0 1D 0C15 PKGCALL (hostaddr)
: hostaddr  (hostaddr) SWAP ;         ( -- Dip)
0 1 0 1C 0C15 PKGCALL domain          ( buffer -- )
4 1 0 21 0C15 PKGCALL (0>ip)
: 0>ip  (0>ip) SWAP ;                 ( 0-addr -- Dip | D0 )
0 3 0 22 0C15 PKGCALL ip>0            ( Dip buffer -- )

\ Service & protocol lookups

2 1 0 14 0C15 PKGCALL service>port   ( 0-addr -- u )
0 2 0 15 0C15 PKGCALL port>service   ( u buffer -- )
1 1 0 16 0C15 PKGCALL port>proto     ( u -- n )
1 1 0 17 0C15 PKGCALL service>proto  ( 0-addr -- n )
2 1 0 18 0C15 PKGCALL name>proto     ( 0-addr -- u )
0 2 0 19 0C15 PKGCALL proto>name     ( u buffer -- )

DECIMAL

\ Unused ZSock Calls
\ ==================
\ The ZSock API contains many calls that we don't provide;
\ if you really want them, you can add them yourself.
\ They're mostly concerned with the overall implementation
\ of TCP/IP (which should be left to the ZSock app), daemons
\ and a few miscellaneous others (such as sock_puts, which
\ would not be very appropriate in Forth).
