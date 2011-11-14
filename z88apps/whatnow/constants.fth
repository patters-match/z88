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

\ wn-constants.fth
CR .( WhatNow? - Constants)

255   CONSTANT it
32767 CONSTANT with
-4096 CONSTANT exc-end
-4097 CONSTANT exc-wait
-4098 CONSTANT exc-exit
-4099 CONSTANT exc-endinp
-4100 CONSTANT exc-esc
-4101 CONSTANT exc-close
-4102 CONSTANT exc-open
-4103 CONSTANT exc-badmem
-2    CONSTANT exc-error
256   CONSTANT #ptrs
90    CONSTANT maxlen
8     CONSTANT buflines
21000 CONSTANT gacsize
20    CONSTANT maxudgs
