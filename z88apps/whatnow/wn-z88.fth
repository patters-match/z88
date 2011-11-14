\ wn-z88
\ WhatNow? for Z88

CR .( Loading WhatNow?...)

ROM2 NS
S" zxscreen.fth" INCLUDED
S" constants.fth" INCLUDED
RAM
S" data.fth" INCLUDED
ROM2
S" data-z88.fth" INCLUDED
RAM
CR .( Space left in RAM region: ) 32512 HERE - .
ROM2
S" errors.fth" INCLUDED
S" dialogs.fth" INCLUDED
S" database.fth" INCLUDED
S" markers.fth" INCLUDED
S" output.fth" INCLUDED
S" messages.fth" INCLUDED
S" objects.fth" INCLUDED
S" pictures.fth" INCLUDED
S" rooms.fth" INCLUDED
S" files.fth" INCLUDED
S" actions.fth" INCLUDED
S" process.fth" INCLUDED
S" parser.fth" INCLUDED
S" game.fth" INCLUDED
S" appl-z88.fth" INCLUDED
RAM NS