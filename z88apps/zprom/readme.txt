
Zprom compilation notes

There are two versions of Zprom, one containing just Zprom on its own and the other one contains Zprom and Flashtest, the two applications built in the same space of 32K.

Running

makeapps.zprom+flashtest.bat - gives you both applications whilst 
makeapp.bat                  - gives you just Zprom

*** BEFORE RUNNING THESE MAKE SURE YOU HAVE UPDATED THE STANDARD LIBRARY FILES (stdlib)

To compile the Zprom application, execute the following:

1) Select the directory holding the Zprom files as the current directory.
2) Execute:
                mpm -b -I<path to OZ definitions> -l<path/filename to standard library> @zprom

   This will create the executable file "zprom.bin". Please refer to
   "applic.h" for position of code in 32K application card.
