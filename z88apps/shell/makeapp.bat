:: *************************************************************************************
::
:: Shell compile script for Linux/Unix/MAC OSX
:: Shell (c) Garry Lancaster, 2001-2002
::
:: Shell is free software; you can redistribute it and/or modify it
:: under the terms of the GNU General Public License as published by the Free Software
:: Foundation; either version 2, or (at your option) any later version.
:: Shell is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
:: without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
:: PARTICULAR PURPOSE. See the GNU General Public License for more details.
:: You should have received a copy of the GNU General Public License along with Shell
:: see the file COPYING. If not, write to the Free Software Foundation,
:: Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
::
:: *************************************************************************************

del *.ap? *.6? *.epr

:: Build RAM-installable versions using the CamelForth Application Generation tools.
call ..\..\tools\forth\makeforthapp.bat -f makeapp.fth -f shell.fth -f shell.dor -f shellapi.fth -f xfsblock.bin

:: Create a 32K standalone Rom Card with Shell
z88card -f shell-std.loadmap

:: Create a 16K client Rom Card with Shell
z88card -f shell-cli.loadmap

