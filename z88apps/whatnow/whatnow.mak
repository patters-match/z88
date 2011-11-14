\ Makefile for WhatNow?

S" whatnow.fth" INCLUDED
S" whatnow.scr" R/O OPEN-FILE THROW
DUP splash 2048 ROT READ-FILE THROW DROP
CLOSE-FILE THROW

S" :*//appgen.fth" INCLUDED
S" whatnow.dor" INCLUDED

S" wn-std" STANDALONE
S" wn-cli" CLIENT

CR .( WhatNow? successfully generated)
