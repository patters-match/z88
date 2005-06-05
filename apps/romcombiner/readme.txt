RomCombiner is a collection of three files executable files:
'romcombiner.bas', 'romutil.bas' and 'romcombiner.bin'

The two BBC BASIC programs are created as follows:

1) Upload 'romcombiner.cli' and 'romutil.cli' to your Z88.

2) <>KILL all your active BBC BASIC applications so that no
no live BBC BASIC applications are listed in the INDEX
'Suspended Activities'.

3) Activate the Filer and execute the 'romcombiner.cli' file
with <>EX command (mark the file with TAB, then <>EX). The
file gets typed into the a new BBC BASIC application.
When completed, save the file as 'romcombiner.bas'. Go to INDEX
and <>KILL the BBC BASIC application.

4) Activate the Filer and execute the 'romutil.cli' file
with <>EX command (mark the file with TAB, then <>EX). The
file gets typed into the a new BBC BASIC application.
When completed, save the file as 'romutil.bas'.

5) Compile the machine code on your PC with the 'makebin.bat'
file. It will generate the 'romcombiner.bin' file, which
contains the functionality to erase/program flash cards and
program traditional 32K, 128K or 256K Eproms. Upload the
'romcombiner.bin' file to your Z88 in the same directory as
the two BBC BASIC programs.

6) Start a new BBC BASIC application with #B and RUN "romcombiner.bas"
Please refer to 'doc/romcombiner.txt' for instructions to use
RomCombiner.
