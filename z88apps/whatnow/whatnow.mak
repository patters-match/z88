\ Makefile for WhatNow?

S" wn-z88.fth" INCLUDED
S" whatnow.scr" R/O OPEN-FILE THROW
DUP splash 2048 ROT READ-FILE THROW DROP
CLOSE-FILE THROW

CR .( Appgen...)
S" :*//appgen.fth" INCLUDED
S" whatnow.dor" INCLUDED

S" wn-std" STANDALONE
S" wn-cli" CLIENT

CR .( WhatNow? successfully generated)
