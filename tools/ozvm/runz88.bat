:: *************************************************************************************
:: Windows/DOS execute script for OZvm - the Z88 emulator.
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
::
:: ------------------------------------------------------------------------------------
:: Before executing this script, a Java Runtime environment 1.4 or later must have been
:: installed and the PATH environment variable set to the <jre install>/bin folder.
:: This usually performed automatically by the Installation software. In case this didn't
:: work set the PATH variable.
::
:: To test the availablity of command line java execution engine, just type "java -version".
:: This will display the version of the current JRE to your console window.
::
:: *************************************************************************************

java -jar z88.jar
