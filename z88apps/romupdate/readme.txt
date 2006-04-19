Four files are required to run this program

romupdate.bas   - available here
romupdate.crc   - the crc of the romupdate program *SEE WARNING*
new_program.epr - This is the image of the file you wish to update
romupdate.cfg   - This file tells RomUpdate what to do.

ROMUPDATE.CFG

A configation file needs to be created to tell romupdate the name of 
the image it is to replace together with its checksum. Comments can 
be entered by using the semicolon (;) at the beginning of the line. 
Do not add any blank lines in this file. 

The checksum can be obtained by adding the updated file to a zip file 
generator (like WinZip). If you open the zipped file, next to the 
filename the CRC is displayed and then can be obtained.

In the example below the filename is written within the inverted commas
 ("new_program.epr"), followed by the checksum ($d3007c81), 
finally the pointer to application DOR which is normally $0000.

CFG.V1
; filename of 16K bank image, CRC (32bit), pointer to application DOR in 16K file image
"new_program.epr",$d3007c81,$0000

*WARNING* The romupdate crc number may be wrong. 
It is best to check and change the number if required.
