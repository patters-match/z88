
Zprom compilation notes

There are three versions of Zprom, one containing just Zprom on its own and the other one contains Zprom and Flashtest, the two applications built in the same space of 32K. The third script is for building a RAM application edition of Zprom.

Running

makeapps.zprom+flashtest.bat/sh  - gives you both applications whilst
makeapp.bat/sh                   - gives you just Zprom
makeramapp.bat/sh                - builds Zprom as a RAM Application


*** BEFORE RUNNING THESE MAKE SURE YOU HAVE UPDATED THE STANDARD LIBRARY FILES (stdlib)

To compile the Zprom application, execute the following:

1) Select the directory holding the Zprom files as the current directory.
2) Execute:
                mpm -b -I<path to OZ definitions> -l<path/filename to standard library> @zprom

   This will create the executable file "zprom.bin". Please refer to
   "applic.def" for position of code in 32K application card.
