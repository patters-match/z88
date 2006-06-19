:: *************************************************************************************
:: Windows compile script for FontBitMap - Z88 Font Bitmap Source Code Generator.
:: (C) Gunther Strube (gbs@users.sf.net) 2003-2006
::
:: FontBitMap is free software; you can redistribute it and/or modify it under the terms of the
:: GNU General Public License as published by the Free Software Foundation;
:: either version 2, or (at your option) any later version.
:: FontBitMap is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
:: without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
:: See the GNU General Public License for more details.
:: You should have received a copy of the GNU General Public License along with FontBitMap;
:: see the file COPYING. If not, write to the
:: Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
::
:: ------------------------------------------------------------------------------------
:: Before executing this script, a Java Development Kit 1.4 or later must have been
:: installed and the PATH environment variable set to the <jdk install>\bin folder.
:: (Control Panel -> "System" -> Advanced -> System Variables -> Click on "Path", then Edit)
::
:: To test the availablity of command line java compiler, just type "javac -version".
:: This will display the version and the compile options to your console window.
::
:: *************************************************************************************
@echo off

:: create a temporary dir for files to be included in the executable JAR file
mkdir ..\fontbitmap-builddir >nul

:: compile the java classes of the project
echo compiling java classes
java -jar ..\jdk\ecj.jar -d ..\fontbitmap-builddir -nowarn -g:none -source 1.4 -target 1.4 net

:: finally, build the executable jar
cd ..\fontbitmap-builddir >nul
jar cfm ../fontbitmap/fontbitmap.jar ../fontbitmap/META-INF/MANIFEST.MF . >nul

:: clean up the temp build stuff
cd ..\fontbitmap
rmdir /S /Q ..\fontbitmap-builddir >nul
echo fontbitmap.jar completed.
