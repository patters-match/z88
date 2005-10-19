:: *************************************************************************************
:: Launch4J compile script to make a Windows EXE-cutable of the z88.jar (OZvm) file.
::
:: (C) Gunther Strube (gbs@users.sf.net) 2005
::
:: OZvm is free software; you can redistribute it and/or modify it under the terms of the
:: GNU General Public License as published by the Free Software Foundation;
:: either version 2, or (at your option) any later version.
:: OZvm is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
:: without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
:: See the GNU General Public License for more details.
:: You should have received a copy of the GNU General Public License along with OZvm;
:: see the file COPYING. If not, write to the
:: Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
::
:: $Id$
::
:: ------------------------------------------------------------------------------------
:: This BAT file automatically creates the EXE wrapper of the z88.jar file,
:: located in the parent directory. Call this BAT file in the \launch4j directory
:: (same as the launch4j-ozvm.xml configuration file).
::
:: Before calling this script, add install directory of Launch4Jc.exe to
:: your PATH environment variable. The "launch4j-ozvm.xml" must be used
:: with Launch4J 2.0RC3 or newer.
::
:: Launch4J can be downloaded from http://launch4j.sourceforge.net/
::
:: *************************************************************************************

:: --------------------------------------------------------------------------
:: some trickery to get current directory into a variable
@SET cd=
@SET promp$=%prompt%
@PROMPT SET cd$Q$P
@CALL>%temp%.\setdir.bat
@
% do not delete this line %
@ECHO off
PROMPT %promp$%
FOR %%c IN (CALL DEL) DO %%c %temp%.\setdir.bat
:: --------------------------------------------------------------------------

:: --------------------------------------------------------------------------
:: create the EXE wrapper in parent directory (the ozvm directory)
launch4jc.exe %cd%\launch4j-ozvm.xml
:: --------------------------------------------------------------------------