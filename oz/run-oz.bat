:: **************************************************************************************************
:: Run Z88 emulator with latest build of OZ, pre-installed in slot 0 or 1
::
:: (C) Gunther Strube (gbs@users.sf.net) 2005-2008
::
:: This file is part of the Z88 operating system, OZ.     0000000000000000      ZZZZZZZZZZZZZZZZZZZ
::                                                       000000000000000000   ZZZZZZZZZZZZZZZZZZZ
:: OZ is free software; you can redistribute it and/    0000            0000              ZZZZZ
:: or modify it under the terms of the GNU General      0000            0000            ZZZZZ
:: Public License as published by the Free Software     0000            0000          ZZZZZ
:: Foundation; either version 2, or (at your option)    0000            0000        ZZZZZ
:: any later version. OZ is distributed in the hope     0000            0000      ZZZZZ
:: that it will be useful, but WITHOUT ANY WARRANTY;    0000            0000    ZZZZZ
:: without even the implied warranty of MERCHANTA-       000000000000000000   ZZZZZZZZZZZZZZZZZZZZ
:: BILITY or FITNESS FOR A PARTICULAR PURPOSE. See        0000000000000000  ZZZZZZZZZZZZZZZZZZZZ
:: the GNU General Public License for more details.
:: You should have received a copy of the GNU General Public License along with OZ; see the file
:: COPYING. If not, write to:
::                                  Free Software Foundation, Inc.
::                                  59 Temple Place-Suite 330,
::                                  Boston, MA 02111-1307, USA.
::
:: $Id$
:: ***************************************************************************************************

@echo off

if exist oz.bin goto RUN_SLOT0_OZ
if exist oz.epr goto RUN_SLOT1_OZ

:RUN_SLOT0_OZ
java -jar ..\tools\ozvm\z88.jar rom oz.bin
exit 0

:RUN_SLOT1_OZ
java -jar ..\tools\ozvm\z88.jar crd1 1024 29f oz.epr
exit 0
