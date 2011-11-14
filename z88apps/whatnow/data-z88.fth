\ wn-data-z88
CR .( WhatNow? - Z88-specific data)

TASK: drawer

32768 0 POOL gacpool

\ We make an allocation of 1421 bytes first, so we know fixed far addresses
\ Because of problems with FREEing we're currently allocating a fixed amount
\ at startup, and only FREEALLing at application exit...

1421 CONSTANT farsize
1    CONSTANT farhi
2    CONSTANT obj-table  \ pointers to objects (512 bytes)
514  CONSTANT linebufs   \ 8x91 char buffer (728 bytes)
1242 CONSTANT udgdefs    \ UDGs (1+9*maxudgs = 181 bytes)
1423 CONSTANT vocalloc   \ vocabulary (space required varies)

26624 CONSTANT maxfar
