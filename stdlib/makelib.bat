:: *************************************************************************************
:: Z88 Standard Library Makefile for DOS/Windows
:: (C) Gunther Strube (gstrube@gmail.com) 1991-2014
::
:: This is free software; you can redistribute it and/or modify it under the terms of the
:: GNU General Public License as published by the Free Software Foundation;
:: either version 2, or (at your option) any later version.
:: The software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
:: without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
:: See the GNU General Public License for more details.
:: You should have received a copy of the GNU General Public License along with this software;
:: see the file COPYING. If not, write to the
:: Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
::
::
:: *************************************************************************************

:: Compile library routines into .obj files and generate the standard.lib file (to be
:: used by other applications that needs to statically link routines from this library).
::
:: The standard library is located in /stdlib
:: The OZ Manifests are located in /oz/def

@echo off

:: return version of Mpm to command line environment.
:: Only V1.5 or later of Mpm supports macros
mpm -version 2>nul >nul
if ERRORLEVEL 15 goto COMPILE_STDLIB
echo Mpm version is less than V1.5, Standard library compilation aborted.
echo Mpm displays the following:
mpm
goto END

:COMPILE_STDLIB
mpm -I..\oz\def -d -xstandard.lib @standard

:END