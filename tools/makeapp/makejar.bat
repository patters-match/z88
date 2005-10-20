:: *************************************************************************************
:: Windows compile script for MakeApp - the Z88 Application Card Generator.
:: (C) Gunther Strube (gbs@users.sf.net) 2005
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
javac -nowarn -g:none net/sourceforge/z88/tools/*.java

:: create a temporary dir for files to be included in the executable JAR file
mkdir ..\makeapp-builddir >nul

:: copy the all the application files (without hidden files)
echo building executable jar
xcopy net ..\makeapp-builddir\net /S /Y /I /Q >nul

:: JAR file only needs (compiled) class files
del /S /Q ..\makeapp-builddir\*.java >nul

:: finally, build the executable jar
cd ..\makeapp-builddir >nul
jar cfm ../makeapp/makeapp.jar ../makeapp/META-INF/MANIFEST.MF . >nul

:: clean up the temp build stuff
cd ..\makeapp
rmdir /S /Q ..\makeapp-builddir >nul
echo makeapp.jar completed.
