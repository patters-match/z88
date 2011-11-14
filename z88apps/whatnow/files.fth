\ wn-files
CR .( WhatNow? - File handling)

: escack
    1 OS_ESC DROP  0 INACC? C!
    exc-esc THROW ;

: usemail ( m l a p -- m l' a p' )
    0" NAME" CHECKMAIL
    IF  1- 2>R 0 ?DO  8 EMIT  LOOP
        OVER SPACES
        SWAP   0 ?DO  8 EMIT  LOOP
        OVER 2R> ROT UMIN 2DUP TYPE >R
        OVER R@ CMOVE R> TUCK
    THEN ;

: getfname ( c-addr1 -- [c-addr2 n] flag )
    wtitle !
    TRUE TO dialog?
    ['] (redraw) >BODY @ >R
    ['] fnamebox IS (redraw)  ['] usemail IS (ACC_MAIL)
    fnamebox
    5 OS_ESC DROP
    PAD 80 ['] ACCEPT CATCH
    6 OS_ESC DROP
    R> IS (redraw)  ['] NOOP IS (ACC_MAIL)
    FALSE TO dialog?  
    IF  2DROP FALSE
    ELSE  PAD SWAP TRUE
    THEN ;   
  
: load/save ( fileid -- flag )
    >R
    markers 32 R@ xferdata
    counters 128 R@ xferdata OR
    ['] room >BODY 2 R@ xferdata OR
    stre 2 R@ xferdata OR
    R>
    256 0 DO  I SWAP >R
              >object? 0= IF  DROP PAD  THEN
              2 R@ xferdata OR
              R>
          LOOP
    DROP ;

: savegame
    0" Save game position" getfname
    IF  S" Saving..." flashy
        ['] WRITE-FILE IS xferdata
        R/W CREATE-FILE ?DUP 0=
        IF  DUP load/save SWAP CLOSE-FILE OR
        ELSE  NIP
        THEN
        IF  S" Save error" errpopup  THEN
    THEN
    redraw ;

: readdata ( addr n fileid -- flag )
    OVER >R
    READ-FILE
    SWAP R> <> OR ;

: loading ( c-addr n -- fileid flag )
    S" Loading..." flashy
    R/O OPEN-FILE 0= ;

: notfound ( x -- )
    DROP S" File not found" errpopup
    redraw ;

: loadgame
    0" Load game position" getfname
    IF  ['] readdata IS xferdata
        loading
        IF  DUP load/save SWAP CLOSE-FILE OR
            IF  S" Load error" errpopup
                redraw exc-exit THROW
            THEN
            linelen empty-output
            room goto
            exc-wait THROW
        ELSE  notfound
        THEN
    ELSE  redraw
    THEN ;

: 0>S ( c-addr -- c-addr u )
    DUP 256 0 SCAN NIP 256 SWAP - ;

: >ext ( -- c-addr )
    0PAD 0>S
    2DUP [CHAR] . SCAN NIP
    IF  BEGIN
          2DUP [CHAR] . SCAN ?DUP
        WHILE
          1- SWAP CHAR+ SWAP 2SWAP 2DROP
        REPEAT  2DROP 1-
    ELSE  +
    THEN ;

: append ( c-addr1 c-addr2 u -- c-addr3 )
    >R OVER R@ CMOVE R> + ;

: nameit
    0PAD 0>S
    BEGIN  2DUP [CHAR] / SCAN ?DUP
    WHILE  1- SWAP CHAR+ SWAP 2SWAP 2DROP
    REPEAT
    DROP 2DUP [CHAR] . SCAN NIP - *NAME ; 

: erasegac
    gac-data gacsize CELL+ ERASE ;

: defudgs
    udgdefs farhi C@L
    udgdefs OVER 1+ CHARS +
    SWAP 0 ?DO  DUP farhi udgbuf >FAR 8 CMOVEL
                udgbuf I 64 + DEFUDG
                8 CHARS +
           LOOP
    DROP
    udgdefs 1+ farhi udgbuf >FAR maxudgs CMOVEL ;

: getudgs
    FALSE TO gotudgs?
    >ext S" .udg" append 0 SWAP C!
    0PAD 0>S R/O OPEN-FILE
    IF  DROP
    ELSE  DUP gac-data maxudgs 9 * 1+ ROT READ-FILE 0=
          SWAP gac-data C@ 9 * 1+ = AND
          IF  TRUE TO gotudgs?
              gac-data >FAR udgdefs farhi maxudgs 9 * 1+ CMOVEL
              defudgs
          THEN
          CLOSE-FILE DROP
    THEN ;

: load-adv
    0" Load GAC datafile" getfname
    IF  0 0 *NAME loading
        IF  TO snapid
            getudgs erasegac 0 0 HOLE 2!
            gac-data gacsize snapid READ-FILE 2DROP
            ['] convert-gac CATCH snapid CLOSE-FILE DROP THROW
            nameit exc-open THROW
        ELSE  notfound
        THEN
    ELSE  redraw
    THEN ;

: writeerr ( ior fileid|0 -- )
    SWAP
    IF  snapid CLOSE-FILE DROP
        ?DUP IF  CLOSE-FILE DROP  THEN
        0 TO errortype
        ABORT" Error writing file"
    ELSE  DROP  THEN ;

: creategac ( -- fileid )
    >ext S" .gac" append
    ext# 1 > IF  ext# [CHAR] 0 + OVER 1- C!  THEN
    0 SWAP C!
    0PAD 0>S R/W CREATE-FILE 0 writeerr ;

: readgac ( Dpos offset -- Dpos )
    0 2OVER D+ snapid REPOSITION-FILE DROP
    erasegac
    gac-data gacsize snapid READ-FILE 2DROP ;

: size? ( gacstart gacend -- gacsize flag )
    >R >R gac-free R@ -
    gac-free R> 26 + U< gac-free R> U> OR 0= ;

: writegac ( Dpos size offset -- Dpos' )
    SWAP >R M+ 2DUP snapid REPOSITION-FILE DROP
    R@ M+ R>
    ext# 1+ TO ext# creategac >R
    BEGIN  gac-data OVER gacsize UMIN
           2DUP snapid READ-FILE NIP R@ writeerr
           TUCK R@ WRITE-FILE R@ writeerr
           - ?DUP 0=
    UNTIL
    R> CLOSE-FILE 0 writeerr ;

: extgac ( Dpos addr u -- Dpos' )
    S" Extracting..." flashy
    DROP gac-data - M+
    826 readgac 
    TRUE TO zx? 42271 65535 size?
    IF  826 writegac
    ELSE  DROP
	  7924 readgac
	  FALSE TO zx? 16384 41723 size?
          IF  7924 writegac
          ELSE  DROP
                8 M+
          THEN
    THEN
    S" Searching..." flashy ;

: extract
    0" Extract GAC datafile" getfname
    IF  R/O OPEN-FILE 0=
	IF  TO snapid  0 TO ext#
            0 0
            S" Searching..." flashy
	    BEGIN
              erasegac
              2DUP snapid REPOSITION-FILE DROP
              gac-data gacsize snapid READ-FILE DROP
            WHILE
              gac-data gacsize punctab 8 SEARCH
              IF  extgac  ELSE  2DROP gacsize 8 - M+  THEN
            REPEAT
            2DROP
	    snapid CLOSE-FILE DROP
            S" GACs extracted: " ext# respopup
            redraw         
        ELSE  notfound
        THEN
    ELSE  redraw
    THEN ;

