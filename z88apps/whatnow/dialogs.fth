\ *************************************************************************************
\
\ WhatNow? (c) Garry Lancaster, 2001
\
\ WhatNow? is free software; you can redistribute it and/or modify it under
\ the terms of the GNU General Public License as published by the Free Software Foundation;
\ either version 2, or (at your option) any later version.
\ WhatNow? is distributed in the hope that it will be useful, but WITHOUT
\ ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
\ PARTICULAR PURPOSE.
\ See the GNU General Public License for more details.
\ You should have received a copy of the GNU General Public License along with WhatNow?;
\ see the file COPYING. If not, write to the Free Software Foundation, Inc.,
\ 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
\
\ *************************************************************************************

\ wn-dialogs
CR .( WhatNow? - Dialog handling)

: Y/N ( -- flag )
    BEGIN
      KEY
      DUP  [CHAR] Y <>     OVER [CHAR] y <> AND
      OVER [CHAR] N <> AND OVER [CHAR] n <> AND
    WHILE
      DROP
    REPEAT
    DUP [CHAR] Y = SWAP [CHAR] y = OR ;

: flashy ( c-addr n -- )
    PAGE CR
    [CHAR] C EALIGN
    [CHAR] R ESET [CHAR] F ESET
    [CHAR] C ECLR
    SPACE TYPE SPACE CR
    [CHAR] R ECLR [CHAR] F ECLR
    [CHAR] N EALIGN ;

: greywins
    SINGLE drawer SLEEP pics? IF  2 WINDOW GREY  THEN
    1 WINDOW GREY ;

: reswin ( c-addr -- )
    greywins
    >R 30 1 30 7 R> 3 OPENPOPUP
    [CHAR] C ECLR [CHAR] C EALIGN
    CR ;

: reswait
    CR CR
    [CHAR] F ESET [CHAR] B ESET
    ." Press "
    [ HEX ] E4 [ DECIMAL ] XCHAR 
    ."  to resume"
    [CHAR] F ECLR [CHAR] B ECLR
    [CHAR] N EALIGN ;

: dialog ( xt -- )
    ['] (redraw) >BODY @ >R
    IS (redraw)
    TRUE TO dialog?
    (redraw)
    BEGIN  KEY 27 =  UNTIL
    FALSE TO dialog?
    R> IS (redraw) ;

: disperr
    errornum
    CASE  0 OF ENDOF
          exc-error OF  0" ERROR!" reswin
                        ABORT"S 2@ SWAP TYPE
                        errortype
                        CASE 0 OF  ENDOF
                             1 OF  errordata U.  ENDOF
                             2 OF  procptr @ 1- gac-data - U.  ENDOF
                        ENDCASE
                        reswait
                    ENDOF
      0" ERROR!" reswin ." Unexpected error " DUP .
      reswait
    ENDCASE ;

: !error!
    ['] disperr dialog ;

: errpopup ( c-addr u -- )
    0 TO errortype
    exc-error TO errornum
    SWAP ABORT"S 2!
    !error! ;

: fnamebox
    greywins
    30 2 30 5 wtitle @ 3 OPENPOPUP
    CR SPACE ;

: resultbox
    0" Information" reswin
    CR ABORT"S 2@ SWAP TYPE errortype U.
    reswait ;
 
: respopup ( c-addr u x -- )
    TO errortype
    SWAP ABORT"S 2!
    ['] resultbox dialog ;

