Cambridge Z88 Git Repository
GPL V2 software

    ZZZZZZZZZZZZZZZZZZZ     888888888          888888888     
    Z:::::::::::::::::Z   88:::::::::88      88:::::::::88   
    Z:::::::::::::::::Z 88:::::::::::::88  88:::::::::::::88 
    Z:::ZZZZZZZZ:::::Z 8::::::88888::::::88::::::88888::::::8
    ZZZZZ     Z:::::Z  8:::::8     8:::::88:::::8     8:::::8
            Z:::::Z    8:::::8     8:::::88:::::8     8:::::8
           Z:::::Z      8:::::88888:::::8  8:::::88888:::::8 
          Z:::::Z        8:::::::::::::8    8:::::::::::::8  
         Z:::::Z        8:::::88888:::::8  8:::::88888:::::8 
        Z:::::Z        8:::::8     8:::::88:::::8     8:::::8
       Z:::::Z         8:::::8     8:::::88:::::8     8:::::8
    ZZZ:::::Z     ZZZZZ8:::::8     8:::::88:::::8     8:::::8
    Z::::::ZZZZZZZZ:::Z8::::::88888::::::88::::::88888::::::8
    Z:::::::::::::::::Z 88:::::::::::::88  88:::::::::::::88 
    Z:::::::::::::::::Z   88:::::::::88      88:::::::::88   
    ZZZZZZZZZZZZZZZZZZZ     888888888          888888888    


----------------------------------------------------------------------
Introduction to Cambridge Z88 Git repository
----------------------------------------------------------------------

Welcome to the Z88 development repository! The place to get the latest
software for Cambridge Z88 applications and utilities.



----------------------------------------------------------------------
The Z88 project on the Internet
----------------------------------------------------------------------
https://cambridgez88.jira.com/wiki   (the welcome page and documentation)
https://cambridgez88.jira.com        (browse all projects and issues)



----------------------------------------------------------------------
The Z88 Project Git Repositories
----------------------------------------------------------------------
The main repository, z88.git, contains mostly Z88 Application source code.

Our other repositories refer to specific projects:

https://bitbucket.org/cambridge/oz (OZ - Z88 ROM)
https://bitbucket.org/cambridge/mpm (Mpm - Z80 Assember utility)
https://bitbucket.org/cambridge/z88card (Z88Card - Z88 AppCard Manager)
https://bitbucket.org/cambridge/ozvm (OZvm - Z88 Emulator)
https://bitbucket.org/cambridge/eazylink2 (Desktop Appl. to transfer files to Z88)

If you need write access to the repositories, drop us an email with
your user account name on bitbucket: cambridgez88@gmail.com



----------------------------------------------------------------------
Basic requirements
----------------------------------------------------------------------

The cross platform tools that is necessary to compile the Z88 software
into executable form to be run on the Cambridge Z88 are downloaded 
separately from our files area:
http://sourceforge.net/projects/z88/files/Z88%20Assembler%20Workbench%20Tools/

Tools to be installed on your desktop comoputer exists for Mac OS X, Linux 
and Windows.

The first requirement is to checkout the Git Master branch (main
development or HEAD in CVS terms) you need to have a Git client
installed on your preferred operating system. We recomment SmartGit
for cross-platform use, tortoisegit for Windows or SourceTree for Mac.

Note that the standard git command-line client must be available in
order for build revision information to be generated for OZ builds.

The 2nd requirement is to install the Cambridge Z88 emulator which enables
you to test your software, before actually uploading and running it on
the real machine. We provide Installers for the emulator here:

http://sourceforge.net/projects/z88/files/emulator



----------------------------------------------------------------------
Getting started with Git and a tour of the repository layout
----------------------------------------------------------------------

To get the complete main development tree of all source files and
documentation in the Git repository, you simply check out the repository
to a locally preferred place on your workstation file system:

Using HTTPS:
git clone https://bitbucket.org/cambridge/z88.git
(this is anonymous checkout only)

Using SSH:
git clone git@bitbucket.org:cambridge/z88.git

Read here how to use SSH with our bitbucket repositories:
https://confluence.atlassian.com/display/BITBUCKET/Using+the+SSH+protocol+with+bitbucket


There are myriads of other Git clients out there to use. They also
support submodule functionality.

Once you've got yourself the latest snapshot of the repository, you
will get the following directory structure with lots of files in it:

/bin
     /roms          This folder contains all known Z88 ROMS, used by OZvm
     z88.jar        Pre-installed Z88 emulator / debugger (needs JVM runtime installed)


/documentation
     /devnotes      Z88 Developers Notes (outdated - use online wiki!)
     /packages      Packages system, txt files (up to and including V4.0)
     /servman       Z88 Service Manual, html files
     /userguide     Z88 User Guide (outdated, use online wiki!)

/oz                 Z88 Operating definitions
     /def           OZ system manifests, used by Z88 application sources

/stdlib             Standard library routines for Z88 applications

/tools              Developer tools for asm development, Z88 emulator
     /dzasm         Reverse engineer Z80 binaries into assembler source
     /fontbitmap    Generate asm source for ROM fonts & token table
     /forth         Tools to generate CamelForth-based applications
     /jdk           Eclipse Java Compiler and the MakeJar utility
                    (these tools are used to compile executable Jar's
                    for OZvm, Z88Card and FontBitMap applications.

/wsapps             Generic workstation Z88 related applications
     z88transfer    EazyLink Client by Sergio Costas (requires Python installed)

/z88apps            Z88 Applications & popdowns (Z80 source code)
     /alarmsafe     Alarm archiving popdown utility
     /canvas        Art studio application
     /debugapp      An empty popdown for OZvm debugging (load/run code)
     /eazylink      EazyLink popdown & PcLink II emulation
     /epfetch       File Eprom Management
     /example_package An example package, with Tester application
     /flashstore    Rakewell Flash Card File Management
     /flashstest    Rakewell Flash Card testing popdown
     /forever       Compilation build of:
                    pdrom, zdis, zmonitor, fview, alarmsafe, lockup,
                    epfetch, freeram, installer, bootstrap & packages.
     /freeram       Small utility to display free RAM graphically
     /fview         Simple Ascii File Viewer popdown.
     /installer     Installer and Bootstrap popdowns, with Packages system.
     /intuition     Z88 Application Debugger/Disassembler
     /lockup        Password protection popdown utility
     /pdrom         4 applications by Richard Haw, released in 1989:
                    Z-Help, Z-Macro, Utilities, Graphics
     /pyramid       Puzzle Of The Pyramid game
     /romcombiner   BBC BASIC utility to combine applications to card.
     /romupdate     BBC BASIC utility to update/add apps to Flash Cards
     /shell         A Unix-like shell
     /uutools       UUtools utility with Mimetypes package (for uuencode/uudecode)
     /wavplay       Play polyphonic sounds on Z88 Loudspeaker
     /webby         A very simple text web browser
     /whatnow       Play adventure games written using Spectrum/Amstrad GAC
     /xymodem       Dennis Grönings XY-MODEM Z88 transfer client
     /z80asm        Z80 Module Assembler application
     /zdis          Z80 disassembler
     /zetriz        Tetris game in map area.
     /ziputils      UnZip & ZipUp applications for ZIP file management
     /zmonitor      View Z88 memory (RAM/ROM)
     /zprom         Blow code/data to UV Eprom / Flash Cards



----------------------------------------------------------------------
Configuring command line shell environment variables
----------------------------------------------------------------------

In order for the many compile scripts to function properly, two steps
must be made before following the next steps:

1) Ensure that the Z88 Assembler workbench tools are added to your 
   operating system PATH environment variable. This is to ensure that all
   executables will be found by the compile scripts, no matter where 
   you are located inside the project folders

In Windows you define the PATH environment variable as follows:

    Control Panel -> "System" -> Advanced -> System Variables
    Click on "Path", then append <Project Home>\bin to line.

Generally for Unixes, you add to the PATH env. variable in your shell
environment init scripts, for example in the .bash_profile file for
BASH.



----------------------------------------------------------------------
Z88 development project uses standard OS scripting facilities
----------------------------------------------------------------------

Scripts have been implemented to generate binaries for executable programs
and other binaries using the common scripting standard on Windows, Linux
and Mac OS X. For every program seen in the above directory structure one
or several scripts have been provided. All scripts for Windows are named
with a .bat filename extension. All scripts for Unix platforms uses the
.sh filename extension; Bash scripting has been chosen as the common
standard and should be working on most Unixes today. The general rule
for all scripts is to change to the current directory of the script and
then execute it from there, ie. in Windows, type

    cd <z88 project>\stdlib
    makelib.bat

or in a Unix operating system, type

    cd <z88 project>/stdlib
    ./makelib.sh

All base filenames of the scripts are the same, only the extension
differs, depending on which platform it is determined to be executed on.


----------------------------------------------------------------------
Compiling Z88 Applications & popdowns
----------------------------------------------------------------------

All Z88 application & popdowns are located inside the /z88apps directory.
The Z89 Assembler Workbench tools has to be available on your file system
and letting the PATH env. variable point to them.

Further, most Z88 applications projects link static functionality from the
Z88 standard library, located in /stdlib.

For each Z88 application (or popdown), change to the current directory
of that project, then execute the makeapp (or similar script name) for
your operating system platform. For example, to compile FlashStore:

    cd <z88 project>/z88apps/flashstore
    makeapp.bat (or ./makeapp.sh)

Each application script automatically builds the latest standard.lib file
before compiling the Z88 application that also statically links with
the standard library.

Small-C based applications (eg UUtools) require z88dk to be installed
on your system. This can be obtained for most platforms from www.z88dk.org.
Ubuntu users will find it can be installed directly from their package
manager.
