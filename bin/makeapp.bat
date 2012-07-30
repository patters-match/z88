:: *************************************************************************************
:: DOS execute script and auto-compiler for MakeApp - the Z88 Application Card Generator.
:: (C) Gunther Strube (gstrube@gmail.com) 2006-2012
::
:: MakeApp is free software; you can redistribute it and/or modify it under the terms of the
:: GNU General Public License as published by the Free Software Foundation;
:: either version 2, or (at your option) any later version.
:: MakeApp is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
:: without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
:: See the GNU General Public License for more details.
:: You should have received a copy of the GNU General Public License along with MakeApp;
:: see the file COPYING. If not, write to the
:: Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
::
::
:: ------------------------------------------------------------------------------------
:: The purpose of this script is to poll for the existence of the makeapp.jar java
:: executable archive, and automatically execute it, if it exists. If not, it will
:: automatically be compiled, then executed, completely transparent to the calling script.
:: ------------------------------------------------------------------------------------
::
:: *************************************************************************************

:: --------------------------------------------------------------------------
:: remember the current path in from where this script is called in %cd% variable
@SET cd=
@SET promp$=%prompt%
@PROMPT SET cdQ$P
@CALL>%temp%.\setdir.bat
@
% do not delete this line %
@ECHO off
PROMPT %promp$%
FOR %%c IN (CALL DEL) DO %%c %temp%.\setdir.bat
:: --------------------------------------------------------------------------

:: remember the current path from where this script is called
set RETURN_PATH=%cd%

:: get the relative path to this script (to be used for change directory command)
set MAKEAPP_PATH=%Z88WORKBENCH_HOME%\tools\makeapp

:: define the '<path>\makeapp.jar' filename, based on this script name...
set MAKEAPP_JAR=%Z88WORKBENCH_HOME%\bin\makeapp.jar

if exist %MAKEAPP_JAR% goto EXECUTE_MAKEJAR
:: the makeapp.jar has not yet been compiled,
:: to compile it, change to /makeapp directory (temporarily)...
cd %MAKEAPP_PATH%

:: compile the makeapp.jar file, but suppress the output messages while compiling
:: (the outside calling script should be unaware of the compilation)
call makejar.bat >nul

:: now, return back to the original path from where this script was called...
cd %RETURN_PATH%

:EXECUTE_MAKEJAR

@ECHO on
:: execute the makeapp executable and supply the arguments that was assigned this script
java -jar "%MAKEAPP_JAR%" %*
