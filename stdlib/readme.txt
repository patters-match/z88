Support libraries for FlashStore V1.6.x Application

                                                  Kopenhagen, 22nd March, 1999


The Z88 Flash Eprom Library has been released as "Open Source", inspired by
the GNU/Linux community. Both Thierry and I feel the time has come for this
library to get released to the public for the benfit of the future life 
of the Z88 community.

All routines are 100% tested and bug free, currently linked into the 
FlashStore V1.6.9 application.

This library is divided into sub libraries covering different aspects of the
Flash Eprom/File Eprom Management:

     FepStd         The core I/O routines to manipulate the hardware of the card.
     FepEpr         File Eprom Format routimes that write/format the Flash Eprom.
     EprStd         Standard File Eprom Format management routines.
     MmStd          Basic extended memory management support routines.
     Fstore         FlashStore ext. File Format (FS II) library (under development)

These libraries, and a few additional library routines fetched from InterLogic's 
own Standard Library, are the necessary components to compile the FlashStore 
Application.

All above libraries have been combined into a single library for convenience to
the compilation of FlashStore, named StdEpr. This library contains all necessary
routines to compile FlashStore. Feel free to include them into your own library.
This library has been pre-compiled for you, and stored as "StdEpr.lib".

You can compile the FlashStore Application using the following command line,
which identifies the library as part of the current directory where the
FlashStore source file would be stored ("fsapp.asm"):

     z80asm -a -istdepr fsapp

----------------------------------------------------------------------------------

The above libraries references are located in the following files, with the
"FileEpr.txt" as the main entry, describing the various parts of the library.
The other text files are references of the sub libraries:

     "EprStd.txt"   Standard File Eprom Format Library Reference.
     "FepStd.txt"   Core Level Flash Eprom Library Reference for Intel Flash Eprom
     "MmStd.txt"    Z88 Extended Memory Manipulation Library Reference
     "FStore.txt"   FlashStore File Format Library Reference

----------------------------------------------------------------------------------

We continue to improve FlashStore. Further development of the FlashStore Project 
by other Z88 enthusiastic developers are welcome.

* Contacting the authors *

You may reach either Gunther Strube or Thierry Peycru on the Internet, if you
have any suggestions or would like to participate:

     gbs@image.dk (Gunther Strube)
     tpeycru@club-internet.fr (Thierry Peycru)
