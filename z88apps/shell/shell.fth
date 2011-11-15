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

CR .( Loading Shell...)

ROM2 NS

\ Data

RAM HERE \ used up by init

0 VALUE plen
0 VALUE chdl
CREATE orghelp 3   ALLOT
CREATE fname   256 ALLOT
CREATE mymail  128 ALLOT
CREATE bindir  256 ALLOT
CREATE mandir  256 ALLOT
CREATE scratch 512 ALLOT
CREATE vtmp 11 CELLS ALLOT
CREATE history 81 16 CHARS * ALLOT
VARIABLE histcur	\ current input line number
VARIABLE histptr	\ number of last line looked at

HERE ROM2 \ used up by init

HEX
1FFE 100 - CONSTANT SPAD
3DD CONSTANT helpptr
4D1 CONSTANT seg1
\ Manpage must be in seg1, 1K is required with 256 bytes lost to OZ bug.
8000 500 - CONSTANT manpage
DECIMAL

1 CONSTANT binex

\ String handling

: S! ( a1 u a2 -- )
   2DUP C! CHAR+ SWAP CMOVE ;

: S+ ( a1 u1 a2 u2 -- a3 u3 )
   2SWAP >R scratch R@ CMOVE TUCK scratch R@ + SWAP CMOVE R> + scratch SWAP ;

: 0>S ( a -- a u )
   DUP 255 0 SCAN DROP OVER - ;

\ Misc

: NUNARY   0 BASE ! ;
: .D       BASE @ SWAP DECIMAL . BASE ! ;
: wins     1 0 90 8 0" Shell"  1 OPENTITLED ;

\ Parameter handling

: /IN ( n -- )
   >IN @ + >IN ! ;

: TAIL ( -- a u )
   SOURCE >IN @ /STRING ;

: BLSKIP ( "<bbb>word" -- "word" )
   BEGIN  TAIL 0<> SWAP C@ BL 1+ < AND  WHILE  1 /IN  REPEAT ;

: oparam  ( "word" -- a u )
   BLSKIP BL PARSE ;

: param ( "word" -- a +u )
   oparam DUP 0= IF  CR ." Missing parameter" ABORT  THEN ;

: 0param ( "word" -- 0a )
   param S>0 ;

: getn ( "n" -- n f )
   BASE @ DECIMAL 0 0 oparam >NUMBER >R 2DROP SWAP BASE ! R> ;

: nparam ( "n" -- n )
   getn ABORT" Invalid number" ;

: >PAD ( a u -- PAD u )
   TUCK PAD SWAP CMOVE PAD SWAP ;

: word! ( "word" a u -- )
   BL WORD COUNT ROT UMIN ROT S! ;

: none> ( a1 u1 a2 u2 -- a' u' )
   2OVER NIP 0= IF  2SWAP  THEN 2DROP ;

: wild ( xt a u -- )
   S>0 >EXPL D/N ROT DOWILD ;

: /? ( c -- f )
   DUP [CHAR] / = SWAP [CHAR] \ = OR ;

: l/? ( a u -- a u f )
   OVER C@ /? OVER 0<> AND ;

: curdir ( -- a u )
   DIR OS_NQ 2DUP 1- + C@ /? 0= OVER 0= OR IF 2DUP + [CHAR] / SWAP C! 1+ THEN ;

: path+ ( a1 u1 -- a2 u2 )
   DEV OS_NQ >PAD curdir S+ 2SWAP S+ ;

: .ozerr ( ior -- )
   CR NEGATE 256 + .OZERR ;

: .err ( ior | 0 -- )
   ?DUP IF  .ozerr  THEN ;

: !err! ( ior | 0 -- )
   ?DUP IF  .ozerr ABORT  THEN ;

: end
   TAIL -TRAILING NIP
   IF  CR ." Too many parameters" ABORT  THEN ;

: dortype ( 0a -- t )
   D/N OPEN-WILD DUP WILD NIP NIP SWAP CLOSE-WILD ;

: Stype ( a u -- a u t )
   2DUP S>0 >EXPL dortype ;

: dir? ( t -- f )
   D_DIR = ;

: file? ( t -- f )
   D_FIL = ;

: fs? ( t -- f )
   DUP dir? SWAP file? OR ;

: +seg ( a u -- a' u' )
   2DUP [CHAR] / SCAN 2SWAP [CHAR] \ SCAN ROT 2DUP >
   IF  DROP ROT DROP  ELSE  NIP NIP  THEN ;

: >name ( a u -- a' u' )
   BEGIN  2DUP +seg DUP  WHILE  1 /STRING 2SWAP 2DROP  REPEAT 2DROP ;

: .prompt
   CR 0 0 path+ DUP plen - DUP 0> IF  /STRING  ELSE  DROP  THEN TYPE ." > " ;

: setplen ( n -- )
   0 MAX 255 MIN TO plen ;

: refname
   0 0 path+ *NAME ;

: valdev   DEV OS_NQ S>0 dortype D_DEV <> IF  0" :ram.0" DEV OS_SP  THEN ;
: valdir   DIR OS_NQ S>0 >EXPL dortype D_DIR <> IF  0" /" DIR OS_SP  THEN ;

: dir+ ( c u a -- c' u' )
   >R OVER C@ DUP [CHAR] : = OVER [CHAR] \ = OR OVER [CHAR] / = OR
   SWAP [CHAR] . = OR 0= IF  R@ COUNT 2SWAP S+  THEN R> DROP ;

\ Helpers for FORTH scripts

' (PKGERR) >BODY CELL+ DUP
: vsave ( a -- )
   LATEST OVER 3 CELLS CMOVE  3 CELLS + LITERAL SWAP 8 CELLS CMOVE ;

: vload ( a -- )
   DUP LATEST 3 CELLS CMOVE  3 CELLS + LITERAL 8 CELLS CMOVE ;

\ Ensure command fits in workspace (we have up to manpage available,
\ minus 256 for parsing and breathing space)

: cmdsize ( u -- )
   HERE + 31232 U> IF  -263 !err!  THEN ;

\ Internal commands

: (cp) ( a1 u1 a2 u2 -- ior )
   2SWAP R/O OPEN-FILE !err!
   ROT ROT W/O CREATE-FILE ?DUP IF CLOSE-FILE DROP !err! THEN SWAP
   BEGIN  2DUP scratch 512 ROT READ-FILE !err! >R
          scratch R@ ROT WRITE-FILE !err! R> 0=
   UNTIL  CLOSE-FILE SWAP CLOSE-FILE OR ;

: (rm) ( t -- )
   >R param end Stype DUP R> = SWAP 0= OR
   IF  DELETE-FILE .err  ELSE  TRUE ABORT" Wrong object type"  THEN ;

: (cd) ( a u -- f )
   OVER C@ /? OVER 1 = AND >R 2DUP S>0 >EXPL dortype dir? R> OR
   IF S>0 DIR OS_SP FALSE ELSE 2DROP TRUE THEN refname ;

: (man) ( a u -- )
   manpage 1024 ERASE mandir dir+ R/O OPEN-FILE IF  DROP EXIT  THEN
   >R manpage 1023 R@ READ-FILE 2DROP R> CLOSE-FILE DROP ;

VOCABULARY internal
ALSO internal DEFINITIONS

: exit   end BYE ;
: cls    end PAGE ;
: pwd    end CR 0 0 path+ TYPE ;
: path   end CR ." bin=" bindir COUNT TYPE CR ." man=" mandir COUNT TYPE ;
: prompt nparam end setplen ;
: chdev
   0param end DUP dortype D_DEV <> ABORT" Invalid device"
   DEV OS_SP valdir refname ;
: chdir
   param end l/? 0= IF  curdir 2SWAP S+  THEN (cd) ABORT" Invalid directory" ;
: cd     chdir ;
: up     end curdir 1- 2DUP >name NIP - >PAD (cd) DROP ;

:NONAME ( a u t -- ) 
  DUP dir? IF  [CHAR] B ESET  THEN
  fs? IF  >name TUCK TYPE 18 SWAP - SPACES  ELSE  2DROP  THEN
  [CHAR] B ECLR ;
: ls     LITERAL oparam end CR S" *" none> wild ;
: dir    ls ;

: mkdir  param end NEWDIR OPEN-FILE !err! CLOSE-DOR ;
: md     mkdir ;
: rm     D_FIL (rm) ;
: rmdir  D_DIR (rm) ;
: rd     rmdir ;

:NONAME ( a u t -- )  
  fs? IF  CR 2DUP >name TYPE DELETE-FILE .err  ELSE  2DROP  THEN ;
: mrm    LITERAL param end wild ;

: ren    param param end RENAME-FILE .err ;
: cp     param param end (cp) .err ;
: mv     param 2DUP param end (cp) !err! DELETE-FILE .err ;
: cli    TAIL DUP /IN *CLI ;
: mark   param end S>0 >EXPL 0>S 2DUP mymail S! CHAR+ NAME ROT ROT SENDMAIL ;
: cmds   end BASE @ DECIMAL WORDS BASE ! ;

: man
   oparam end DUP
   IF  (man) manpage C@
       IF  manpage helpptr ! seg1 C@ helpptr CELL+ C!
           CR ." Manpage installed" EXIT
       THEN
   ELSE  2DROP  THEN
   orghelp helpptr 3 CMOVE CR ." No manpage" ;

ONLY FORTH DEFINITIONS

VOCABULARY hidden
ALSO hidden DEFINITIONS

: bernice  end ONLY FORTH ALSO hidden ALSO internal DECIMAL ;   \ a back door!
: shell    end ONLY hidden ALSO internal NUNARY ;
DEFER extern

ONLY FORTH DEFINITIONS ALSO hidden

\ External command handling

VOCABULARY batch

: preexec ( -- i*x )
   GET-ORDER GET-CURRENT BASE @ DP @ vtmp vsave
   vtmp 11 FOR  DUP @ SWAP CELL+  STEP  DROP
   ['] NOOP IS extern  ALSO batch ;

: postexec ( i*x -- )
   vtmp 11 CELLS + 11 FOR  1 CELLS - TUCK !  STEP  DROP
   vtmp vload DP ! BASE ! SET-CURRENT SET-ORDER
   ['] NOOP IS extern ;

: stack? ( depth -- )
   >R DEPTH R> - ?DUP 0= IF  EXIT  THEN
   DUP 0> IF  CR ." Stack overflow!" 7 EMIT FOR  NIP  STEP EXIT  THEN
   CR ." Stack underflow!" 7 EMIT NEGATE FOR  0 SWAP  STEP ;

: paranoid ( c u xt -- f )
   DEPTH >R CATCH DUP IF  NIP NIP  THEN R> 2 - stack? ;

: include ( c u -- f )
   ['] INCLUDED paranoid ;

: eval ( c u -- f )
   ['] EVALUATE paranoid ;

: exec ( c u -- )
   2>R preexec 2R>
   2DUP BL SCAN DUP >R 2SWAP R> - bindir dir+ include
   DUP binex = IF  DROP 0  THEN
   IF  2DROP CR ." Bad command"
   ELSE  S" extern" 2SWAP S+ eval DROP
   THEN
   postexec ;

ALSO batch DEFINITIONS
: !forth   ALSO FORTH DECIMAL ;
: !bin025
   8 S>D SOURCE-ID REPOSITION-FILE !err!
   scratch 4 SOURCE-ID READ-FILE !err! DROP
   HERE scratch @ DUP cmdsize DUP ALLOT
   SOURCE-ID READ-FILE !err! scratch @ <> IF  ABORT  THEN
   scratch CELL+ @ IS extern 
   binex THROW ;
: rem      POSTPONE \ ;
: echo     CR POSTPONE .( ;
: call     TAIL DUP /IN exec ;
ONLY FORTH DEFINITIONS ALSO hidden

\ Compile

ALSO internal DEFINITIONS

: compile
   param param end  W/O CREATE-FILE !err! TO chdl HERE >R
   2>R preexec 2R> include
   IF  chdl CLOSE-FILE R> 2DROP CR ." Compile error" postexec EXIT  THEN
   13 scratch C! HERE R@ - DUP scratch CHAR+ ! CR ." Cmdsize: " .D
   ['] extern >BODY @ scratch CHAR+ CELL+ !
   S" !bin025" chdl WRITE-FILE  scratch 2 CELLS CHAR+ chdl WRITE-FILE OR
   R@ HERE R> - chdl WRITE-FILE OR  chdl CLOSE-FILE OR >R
   postexec R> IF  CR ." Error writing file"  THEN ;

: ecmds  end S" ls " bindir COUNT S+ S" *" S+ EVALUATE ;

ONLY FORTH DEFINITIONS

\ Config file handling

VOCABULARY config
ALSO config DEFINITIONS

: bin  ( "dir" -- )  bindir 255 word! ;
: man  ( "dir" -- )  mandir 255 word! ;
: device  ( "dev" -- ) oparam S>0 DEV OS_SP ;
: dir  ( "dir" -- )  oparam S>0 DIR OS_SP ;
: prompt ( "n" -- )  getn IF  -13 THROW  THEN setplen ;
: \  POSTPONE \ ; 

ONLY FORTH DEFINITIONS ALSO hidden

: initcfg
   16 setplen
   S" :ram.0/bin/" bindir S!
   S" :ram.0/man/" mandir S! ;

: getcfg
   initcfg BASE @ GET-ORDER NUNARY
   ONLY config S" :ram.0/shell.cfg" include
   valdev valdir >R SET-ORDER BASE ! R> -13 = ABORT" Error in config file" ;


\ Commandline & input

: comkeys ( evt -- )
   DUP 384 = IF  BYE  THEN
       385 = IF  getcfg  THEN ;

: >hist ( n -- a )
   15 AND 81 * history + ;

: replace ( n -- )
   histptr +!  histptr @ >hist COUNT rinput ;

: mark@
   >R 2DUP TUCK SWAP R@ /STRING R> OVER >R >R ROT R@
   NAME CHECKMAIL IF  1-  ELSE  mymail COUNT  THEN  2DUP mymail S!
   S+ 2SWAP S+ R> ROT ROT rinput R@ bss R> - ;

: acckeys ( evt -- )
   DUP 511 = IF  DROP -1 replace EXIT  THEN
   DUP 510 = IF  DROP  1 replace EXIT  THEN
   DUP 386 = IF  DROP mark@ EXIT  THEN
   comkeys ;

: hist! ( a u -- )
   histcur @ >hist S!  1 histcur +! ;

: getline ( -- a u )
   histcur @ histptr !  ['] acckeys IS (ACC_EVT)
   TIB DUP 80 ACCEPT
   2DUP hist!  ['] comkeys IS (ACC_EVT) ;


\ Top-level

( a1 a2 -- ) : init
   [ OVER ] LITERAL [ SWAP - ] LITERAL ERASE RAM NS
   getcfg wins ONLY hidden ALSO internal NUNARY
   ['] NOOP IS extern
   helpptr orghelp 3 CMOVE refname ;

: doline
   .prompt getline 2DUP eval
   DUP  -2 = IF  CR ABORT"S 2@ TYPE  THEN
       -13 = IF  exec  ELSE  2DROP  THEN ;

: Shell
   init BEGIN  doline  AGAIN ;

' BYE     IS (RC_QUIT)
' wins    IS (RC_DRAW)
' comkeys IS (KEY)
' comkeys IS (ACC_EVT)
' Shell   IS (COLD)

ONLY FORTH DEFINITIONS
RAM NS
