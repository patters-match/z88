:: *************************************************************************************
::
:: WhatNow? compile script for Linux/Unix/MAC OSX
:: WhatNow?, (c) Garry Lancaster, 2001
::
:: WhatNow? is free software; you can redistribute it and/or modify it
:: under the terms of the GNU General Public License as published by the Free Software
:: Foundation; either version 2, or (at your option) any later version.
:: WhatNow? is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
:: without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
:: PARTICULAR PURPOSE. See the GNU General Public License for more details.
:: You should have received a copy of the GNU General Public License along with WhatNow?;
:: see the file COPYING. If not, write to the Free Software Foundation,
:: Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
::
:: *************************************************************************************

del *.ap? *.6? *.epr

:: Build RAM-installable versions using the CamelForth Application Generation tools.
call ..\..\tools\forth\makeforthapp.bat -f makeapp.fth -f actions.fth -f appl-z88.fth -f constants.fth -f database.fth -f data.fth -f data-z88.fth -f dialogs.fth -f errors.fth -f files.fth -f game.fth -f markers.fth -f messages.fth -f objects.fth -f output.fth -f parser.fth -f pictures.fth -f process.fth -f rooms.fth -f whatnow.dor -f whatnow.fth -f whatnow.scr -f wn-z88.fth -f zxscreen.fth

:: Create a 32K standalone Rom Card with WhatNow?
call makeapp.bat -f whatnow-std.loadmap

:: Create a 16K client Rom Card with WhatNow?
call makeapp.bat -f whatnow-cli.loadmap

