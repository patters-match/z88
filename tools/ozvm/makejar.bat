:: *************************************************************************************
:: Windows compile script for OZvm - the Z88 emulator.
:: (C) Gunther Strube (gbs@users.sf.net) 2003-2005
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
:: Before executing this script, a Java Development Kit 1.4 or later must have been
:: installed and the PATH environment variable set to the <jdk install>\bin folder.
:: (Control Panel -> "System" -> Advanced -> System Variables -> Click on "Path", then Edit)
::
:: To test the availablity of command line java compiler, just type "javac -version".
:: This will display the version and the compile options to your console window.
::
:: *************************************************************************************
@echo off

:: compile the java classes of the project
echo compiling java classes
javac -cp . -nowarn -g:none -source 1.4 -target 1.4 com/imagero/util/*.java
javac -cp . -nowarn -g:none -source 1.4 -target 1.4 net/sourceforge/z88/datastructures/*.java
javac -cp . -nowarn -g:none -source 1.4 -target 1.4 net/sourceforge/z88/filecard/*.java
javac -cp . -nowarn -g:none -source 1.4 -target 1.4 net/sourceforge/z88/screen/*.java
javac -cp . -nowarn -g:none -source 1.4 -target 1.4 net/sourceforge/z88/*.java

:: create a temporary dir for files to be included in the executable JAR file
mkdir ..\ozvm-builddir >nul

:: copy the application files to included in JAR (without hidden files)
echo building executable jar
xcopy com ..\ozvm-builddir\com /S /Y /I /Q >nul
xcopy net ..\ozvm-builddir\net /S /Y /I /Q >nul
xcopy pixel ..\ozvm-builddir\pixel /S /Y /I /Q >nul
xcopy .\ozvm-manual.html ..\ozvm-builddir /Q >nul
xcopy .\Z88.rom ..\ozvm-builddir /Q >nul

:: JAR file only needs (compiled) class files
del /S /Q ..\ozvm-builddir\*.java >nul

:: finally, build the executable jar
cd ..\ozvm-builddir >nul
jar cfm ../ozvm/z88.jar ../ozvm/META-INF/MANIFEST.MF . >nul

:: clean up the temp build stuff
cd ..\ozvm
rmdir /S /Q ..\ozvm-builddir >nul
echo z88.jar completed.
