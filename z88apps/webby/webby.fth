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

CR .( Loading Webby...)

ROM2 NS

\ Data

RAM HERE \ used up by init

DEFER out

0 VALUE sck
0 VALUE ohdl
0 VALUE ihdl
0 VALUE -ws?
0 VALUE indent
0 VALUE dialog?

VARIABLE port

CREATE c/type     256 ALLOT
CREATE c/len  2 CELLS ALLOT
CREATE uri    2 CELLS ALLOT
CREATE doc$   2 CELLS ALLOT
CREATE cachefname 256 ALLOT
CREATE homepage   256 ALLOT
CREATE inbuf     4096 ALLOT

TASK: t_http
TASK: t_html

HERE ROM2 \ used up by init

HEX 1FFE 100 - CONSTANT SPAD DECIMAL

\ Multitasking

\ : stop  STOP ;
\ : sleep SLEEP ;
\ : stop  #TASKS @ 2 = LINK TERM <> AND IF  SINGLE  THEN  STOP ;
\ : sleep SLEEP #TASKS @ 1 = LINK TERM = AND IF  SINGLE  THEN ;
\ : wake  MULTI WAKE ;

\ String handling

: ,S" ( "string" -- caddr )
   POSTPONE S" HERE OVER 1+ ALLOT 2DUP C! DUP >R 1+ SWAP CMOVE R> ;

: ,+S" ( caddr "string" -- caddr )
   HERE POSTPONE S" DUP >R ALLOT SWAP R@ CMOVE DUP C@ R> + OVER C! ;

: ,+C ( caddr c -- caddr )
   C, DUP C@ 1+ OVER C! ;

: S! ( caddr u daddr -- )
   2DUP C! CHAR+ SWAP CMOVE ;

: S/ ( caddr1 u1 c -- caddr2 u2 caddr3 u3 )
   SCAN ROT OVER - ROT ROT ;

\ Housekeeping

: tidyhttp
   sck  IF  sck DUP sock_abort sock_shutdown  0 TO sck  THEN
   ohdl IF  ohdl CLOSE-FILE DROP  0 TO ohdl  THEN
   t_http SLEEP ;

: tidyfile
   ihdl IF  ihdl CLOSE-FILE DROP  0 TO ihdl  THEN
   2 WINDOW t_html SLEEP ;

: goodbye
   tidyhttp tidyfile BYE ;

\ Errors & messages

,S" ZSock error"                        \ 16
,S" ZSock not found"                    \ 15
,S" Unable to open file"                \ 14
,S" File transferred"                   \ 13
,S" Transferring page..."               \ 12
,S" Waiting for reply..."               \ 11
,S" Sending HTTP request..."            \ 10
,S" Contacting host..."                 \ 9
,S" User abort"                         \ 8
,S" Error in config file"               \ 7
,S" Unknown host"                       \ 6
,S" Unable to create socket"            \ 5
,S" Excess data"                        \ 4
,S" Error writing to cache"             \ 3
,S" Error writing to socket"            \ 2
,S" Unsupported protocol"               \ 1
,S" Connection closed by remote host"  \ 0

CREATE msgtab  , , , , , , , , , , , , , , , , ,

: hmsg ( msg -- )
   PAGE CELLS msgtab + @ COUNT TYPE ;

: herr ( f err -- )
   SWAP IF  hmsg 7 EMIT tidyhttp STOP  ELSE  DROP  THEN ;

: zsock?
   PKGS? IF  zsock_id AYT? IF  EXIT  THEN  THEN  TRUE 15 herr ;

: nozsock ( pkgid -- )
   DROP 0 TO sck TRUE 15 herr ;

: badcall ( err -- )
   DROP TRUE 16 herr ;

: wins
   1 0 92 7  1 OPENWINDOW
   1 7 92 1  2 OPENWINDOW  1 EMIT S" 3+RW" TYPE PAGE ;

\ HTML entities & tags

: -ws  TRUE TO -ws? ;

WORDLIST CONSTANT ents
WORDLIST CONSTANT tags

FORTH-WORDLIST ents 2 SET-ORDER DEFINITIONS

: amp  [CHAR] & out -ws ;
: quot [CHAR] " out -ws ;
: lt   [CHAR] < out -ws ;
: gt   [CHAR] > out -ws ;

FORTH-WORDLIST tags 2 SET-ORDER DEFINITIONS

: body    PAGE  ['] EMIT IS out  0 TO indent ;
: /body   ['] DROP IS out ;
: br      13 out 10 out  FALSE TO -ws? ;
: b       [CHAR] B ESET ;
: /b      [CHAR] B ECLR ;
: i       [CHAR] G ESET ;
: /i      [CHAR] G ECLR ;
: tt      [CHAR] T ESET ;
: /tt     [CHAR] T ECLR ;
: code    tt ;
: /code   /tt ;
: samp    tt ;
: /samp   /tt ;
: kbd     tt ;
: /kbd    /tt ;
: var     i ;
: /var    /i ;
: em      i ;
: /em     /i ;
: strong  b ;
: /strong /b ;
: h4      br b ;
: /h4     /b br ;
: h5      h4 i ;
: /h5     /i /h4 ;
: h6      br i ;
: /h6     /i br ;
: h1      h4 [CHAR] R ESET ;
: /h1     [CHAR] R ECLR /h4 ;
: h2      h1 i ;
: /h2     /i /h1 ;
: h3      h6 [CHAR] R ESET ;
: /h3     [CHAR] R ECLR /h6 ;
: p       br indent 1+ FOR  BL out  STEP ;
: hr      br 91 FOR  1 out [CHAR] 2 out [CHAR] * out [CHAR] E out  STEP  br ;
: ul      indent 2 + TO indent ;
: /ul     indent 2 - 0 UMAX TO indent p ;
: li      p [CHAR] * out BL out ;
: a       [CHAR] U ESET ;
: /a      [CHAR] U ECLR ;

FORTH DEFINITIONS

\ HTML parsing

: hpause  2 WINDOW PAUSE 1 WINDOW ;

: cparse ( caddr u c -- caddr' u' caddr2 u2 TRUE | caddr u FALSE )
   >R 2DUP R> SCAN 2OVER BL SCAN NIP UMAX NIP
   DUP IF  DUP >R - 2DUP + R> 2SWAP TRUE  ELSE  DROP FALSE  THEN ;

: any ( u -- u' )
   OVER C@ out -ws  1 /STRING ;

: ws ( caddr u -- caddr' u' )
   1 /STRING -ws? IF  hpause BL out FALSE TO -ws?  THEN ;

\ Tag ignores attributes; individual tags using them should parse themselves
\ Because we might have partial tags and entities due to multitasking, the
\ transfer and rendering aspects, we need to ensure these are ignored until
\ fully transferred.

: tag ( caddr u -- caddr' u' )
   hpause  2DUP [CHAR] > SCAN NIP 0= IF  EXIT  THEN
   1 /STRING [CHAR] > cparse
   IF  2DUP >LOWER tags SEARCH-WORDLIST IF  EXECUTE  THEN  THEN
   [CHAR] > SCAN DUP IF 1 /STRING THEN ;
   
: endamp ( x x caddr' u' -- caddr'' u'' )
   DUP IF  OVER C@ [CHAR] ; = IF  1 /STRING  THEN  THEN  2SWAP 2DROP ;

: amp ( caddr u -- caddr' u' )
   hpause  2DUP [CHAR] ; SCAN 2OVER BL SCAN NIP OR NIP 0= IF  EXIT  THEN
   DUP 3 < IF  any EXIT  THEN
   2DUP 1 /STRING OVER DUP C@ [CHAR] # = SWAP CHAR+ C@ [CHAR] 0 - 10 U< AND
   IF  0 0 2SWAP 1 /STRING >NUMBER 2SWAP DROP out -ws endamp EXIT  THEN
   [CHAR] ; cparse
   IF  ents SEARCH-WORDLIST IF  EXECUTE endamp EXIT  THEN  THEN
   2DROP any ;

7 CONSTANT #chrs
CREATE chrs  CHAR < C, CHAR & C, BL C, 13 C, 10 C, 9 C, 0 C,
CREATE actions  ' any , ' hpause , ' ws DUP DUP DUP , , , , ' amp , ' tag ,

: hfill ( caddr u -- caddr' u' f )
   ihdl OVER 256 U< AND 
   IF  >R inbuf R@ CMOVE inbuf DUP R@ + 4095 R@ - ihdl READ-FILE DROP
       ?DUP IF  R> + TRUE  ELSE  R> DUP ohdl OR  THEN  0 2OVER + C!
   ELSE  DUP ihdl OR  THEN ;

: .html
   doc$ 2@  ['] DROP IS out  1 WINDOW
   BEGIN  hfill
   WHILE  OVER chrs #chrs ROT C@ SCAN NIP CELLS actions + @ EXECUTE
   REPEAT 2DROP tidyfile ; 

: htmlview ( caddr u -- )
   tidyfile R/O OPEN-FILE IF  DROP 14 hmsg 7 EMIT EXIT  THEN
   TO ihdl  0 0 doc$ 2!
   ['] .html t_html TASK!  t_html MULTI WAKE ;

\ HTTP header parsing

: hc@ ( sck caddr -- sck caddr )
   BEGIN  PAUSE GoTCP 2DUP 1 sock_read 0=
   WHILE  OVER sock_closed? 0 herr  REPEAT ;

: hline ( sck -- sck u )
   SPAD 255 FOR  BEGIN hc@ DUP C@ DUP 13 =
                 IF R> 2DROP hc@ SPAD - EXIT THEN
                 BL > UNTIL  1+
            STEP  SPAD - ;

: hfield ( u1 caddr u2 -- u1 FALSE | u1 caddr' TRUE )
   TUCK SPAD SWAP S= 0= >R 2DUP U> R> AND IF  SPAD + TRUE  ELSE  0=  THEN ;

: hparse
   11 hmsg sck S" text/html" c/type S!  -1 -1 c/len 2!
   BEGIN  SPAD 256 ERASE hline ?DUP  WHILE  SPAD OVER >LOWER
     S" content-length:" hfield IF  0 0 ROT 255 >NUMBER 2DROP c/len 2!  THEN
     S" content-type:"   hfield IF  2DUP SPAD - - c/type S!  THEN
   DROP  REPEAT DROP ;

\ URL Parsing

: protocol? ( caddr1 u1 caddr2 u2 -- caddr3 u3 flag )
   DUP >R SEARCH IF  R> /STRING TRUE  ELSE  R> 0=  THEN ;

: geturi ( -- caddr2 u2 caddr3 u3 caddr4 u4 )
   uri 2@
   S" file://" protocol? IF  htmlview tidyhttp STOP  THEN
   S" http://" protocol? DROP  S" ://" protocol? 1 herr
   2DUP [CHAR] / S/ DUP 0= IF  2DROP S" /"  THEN
   2DUP [CHAR] : S/ DUP 0= IF  2DROP S" :80"  THEN 
   0 0 2OVER 1 /STRING >NUMBER 2DROP DROP port ! ;

: host>ip ( caddr u -- Dip )
   S>0 DUP resolve 2DUP OR 0= IF  2DROP 0>ip  ELSE  ROT DROP  THEN ;

\ HTTP requesting

: sput ( caddr u -- )
   PAUSE GoTCP >R SPAD R@ CMOVE sck SPAD R@ sock_write R> <> 2 herr ;

,S" " 13 ,+C 10 ,+C ,+S" Accept-Encoding: " 13 ,+C 10 ,+C
,+S" Connection: close" 13 ,+C 10 ,+C 13 ,+C 10 ,+C
,S"  HTTP/1.0" 13 ,+C 10 ,+C ,+S" Host: "
,S" GET "

: GET ( caddr2 u2 caddr3 u3 caddr4 u4 -- )
   10 hmsg LITERAL COUNT sput 2SWAP sput LITERAL COUNT sput
   2SWAP sput sput LITERAL COUNT sput sck sock_flush ;

\ HTTP transfer

,S" >" 13 ,+C ,+S" Transfer interrupted!" 13 ,+C

: habort
   ohdl IF  [ SWAP ] LITERAL COUNT ohdl WRITE-FILE DROP  THEN
   8 hmsg 7 EMIT tidyhttp ; 

: hxfer ( Dsize -- )
   12 hmsg
   BEGIN  PAUSE GoTCP  sck sock_closed? 0 herr
          sck SPAD 2OVER IF  DROP 256  ELSE  256 UMIN  THEN sock_read
          ?DUP IF  SPAD OVER ohdl WRITE-FILE 3 herr 0 D-  THEN
   2DUP OR 0= UNTIL
   2DROP  sck sock_closed? 0= 4 herr ;

: gethttp
   geturi zsock? 2>R 2>R 2DUP host>ip 2DUP OR 0= 6 herr
   port @ 0 tcp sock_open DUP 0= 5 herr TO sck
   9 hmsg  BEGIN  PAUSE GoTCP sck sock_opened?  UNTIL  2R> 2R>
   GET hparse cachefname COUNT W/O CREATE-FILE 3 herr TO ohdl
   cachefname COUNT htmlview
   c/len 2@ hxfer 13 hmsg tidyhttp ;

: httpview ( caddr u -- )
   tidyhttp uri 2!
   ['] gethttp t_http TASK!  t_http MULTI WAKE ;

\ Config file handling

VOCABULARY config
ALSO config DEFINITIONS

: cachefile ( "fname" -- )  BL WORD COUNT 255 UMIN cachefname S! ;
: home ( "url" -- )  BL WORD COUNT 255 UMIN homepage S! ;
: \  POSTPONE \ ;

ONLY FORTH DEFINITIONS

: initcfg
   S" www.zxplus3e.plus.com/z88forever/" homepage S!
   S" cachy.htm" cachefname S! ;

: getcfg
   initcfg  0 BASE !
   ONLY config S" :ram.0/webby.cfg" ['] INCLUDED CATCH DUP IF  NIP NIP  THEN
   FORTH DECIMAL  -13 = 7 herr ;


\ Dialogs

: getfname ( f c1 u1 -- c2 u2 )
   TRUE TO dialog? 
   PAGE TYPE getfname
   FALSE TO dialog? ;


\ Top-level

:NONAME   \ 133=home
  tidyfile tidyhttp homepage COUNT httpview ;
' habort  \ 132=abort transfer
' getcfg  \ 131=reload config
' goodbye \ 130=quit
:NONAME   \ 129=load file
  tidyfile tidyhttp TRUE S" File: " getfname htmlview ;
:NONAME   \ 128=open page
  tidyfile tidyhttp FALSE S" URL: " getfname httpview ;

CREATE comkeytab , , , , , ,

: beep ( event -- )
   7 EMIT DROP ;

: comkeys ( event -- )
   dialog? IF  beep EXIT  THEN
   256 - DUP 127 U> OVER 134 U< AND
   IF  128 - 2* comkeytab + @ EXECUTE  ELSE  DROP  THEN ;

( startram endram -- ) : init
   [ OVER ] LITERAL [ SWAP - ] LITERAL ERASE
   wins getcfg ;

: browse
   BEGIN  KEY DUP BL = IF  SINGLE  THEN
          13 = #TASKS @ 1 > AND IF  MULTI  THEN
   AGAIN ;

: webby
   init
   ['] browse CATCH ." Unexpected error #" . 7 EMIT
   SINGLE TRUE TO dialog? KEY DROP goodbye ;

' goodbye IS (RC_QUIT)
' wins    IS (RC_DRAW)
' nozsock IS (RC_PNF)
' badcall IS (PKGERR)
' comkeys IS (KEY)
' beep    IS (ACC_EVT)
' webby   IS (COLD)

RAM NS
