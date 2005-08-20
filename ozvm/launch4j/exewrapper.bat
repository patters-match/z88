:: --------------------------------------------------------------------------
:: This BAT file automatically creates the EXE wrapper of the z88.jar file,
:: located in the parent directory. Call this BAT file in the same directory
:: as the launch4j-ozvm.xml configuration file.
::
:: Before calling this script, add install directory of Launch4Jc.exe to
:: your PATH environment variable. The "launch4j-ozvm.xml" must be used
:: with Launch4J 2.0RC3 or newer.
:: --------------------------------------------------------------------------

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
:: create the EXE wrapper in parent directory
launch4jc.exe %cd%\launch4j-ozvm.xml
:: --------------------------------------------------------------------------