
Zprom compilation notes

To compile the Zprom application, execute the following:

1) Select the directory holding the Zprom files as the current directory.
2) Execute:
                mpm -b -I<path to OZ definitions> -l<path/filename to standard library> @zprom

   This will create the executable file "zprom.bin". Please refer to
   "applic.h" for position of code in 32K application card.
