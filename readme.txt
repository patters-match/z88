----------------------------------------------------------------------
Introduction to Z88 Workbench
----------------------------------------------------------------------

Welcome to the Z88 development repository! The place to get the latest
software for Z88 applications, workstation tools and various utilities.

The repository directory file layout has been designed to be self-
contained as much as possible so that once you check out the repository,
you will be able to compile all Z88 native software and run the Z88
emulator within the directory structure of the repository.

Further, you can easily copy or move the complete directory structure
to another media and carry on working, including getting new updates
from the Git repository or committing changes back to the repository
(if you have been granted write access).

Whether you have used our installer to provide this repository or
have downloaded the Git repository directly from bitbucket.org, this
readme should help you get an overview of what you have installed on
your desktop operating system.



----------------------------------------------------------------------
The Z88 project on the Internet
----------------------------------------------------------------------
https://cambridgez88.jira.com/wiki   (the welcome page and documentation)
https://cambridgez88.jira.com        (browse all projects and issues)
https://bitbucket.org/cambridge/z88  (main source code Git repository)



----------------------------------------------------------------------
Basic requirements
----------------------------------------------------------------------

The cross platform tools, scripts and other Z88 software to be compiled
into executable form supports Linux/Mac OS X/Unix and the Windows
operating systems.

The first requirement is to checkout the Git Master branch (main
development or HEAD in CVS terms) you need to have a Git client
installed on your preferred operating system. We recomment SmartGit
for cross-platform use, tortoisegit for Windows or SourceTree for Mac.

Note that the standard git command-line client must be available in
order for build revision information to be generated for OZ builds.

The second requirement on your operating system is an ANSI C compiler
installed and accessible from the command line shell. This is needed to
compile the Z80 Cross Assembler & linker, Mpm, which is needed for
development (and core tool) of Z88 applications and Z88 operating
system, OZ. Gnu C Compiler (GCC) Makefiles is available for easy
compilation on Windows and Unix environments. Borland CPP V5.5 make
files for Windows is also supported. Most Unixes have a C compiler pre-
installed - however, for Windows, you need to download and install a
free C compiler. Gnu C Compiler (GCC) can be downloaded from
http://www.mingw.org/ which generates native Win32 shell programs.
Alternatively, you can use Borlands CPP V5.5 (requires free registration)
from http://www.borland.com/downloads/download_cbuilder.html .

The third requirement on your operating system is Sun's Java Runtime
Environment V1.6 or newer. Several command line tools (which is
part of the tool chain to develop Z88 applications) and the Z88 emulator
(virtual Z88 hardware and debugging environment) are implemented in
Java. Get your JRE from http://java.sun.com. Java V1.6 JRE (or newer) is
bundled by default on Mac OS X.

There's an extra feature for Windows users which enables you to create
an EXE program out of an executable Jar (it is a Java JAR file wrapper).
OZvm - the Z88 emulator, gives you the option to also make an EXE program.
If you want to do the EXE thing, then install the Launch4J software
which you can get from http://launch4j.sourceforge.net.



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


The main z88 repository contains the OZ submodule, so you need to use two
more steps to get the rest of the source code:

git submodule init
git submodule update

(the above examples uses the command line client tool, available on all
supported operating systems by official Git project)

There are myriads of other Git clients out there to use. They also
support submodule functionality.

Once you've got yourself the latest snapshot of the repository, you
will get the following directory structure with lots of files in it:

/bin
     /roms          This folder contains all known Z88 ROMS, used by OZvm
     z88.jar        The Z88 emulator / debugger (needs JVM runtime installed)

     Executable binaries the needs to be compiled from Tool Git repositories are placed here:
     z88card        The Z88Card utility used by compilation scripts to
                    generate Z88 Application Card binaries.
     mpm            The Z80 assembler used to compile all Z80 sources
     dzasm          Utility to reverse-engineer Z80 binaries into source
                    code

/documentation
     /devnotes      Z88 Developers Notes (outdated - use online wiki!)
     /packages      Packages system, txt files (up to and including V4.0)
     /servman       Z88 Service Manual, html files
     /userguide     Z88 User Guide (outdated, use online wiki!)

/oz                 Z88 ROM, OZ V4.3+
                    (SUBMODULE - points to oz.git)

     /apps          The system applications; Index, PipeDream, Diary, etc.
     /dc            The DC_xx system calls
     /def           OZ system manifests, used by Z88 assembler sources
     /fp            The floating Poitn Package
     /gn            The GN_xx system calls
     /mth           Menu/Topic/Help data structures of system apps
     /os            The OZ kernel (drivers, file I/O, serial port etc)

/stdlib             Standard library routines for Z88 applications

/tools              Developer tools for asm development, Z88 emulator
     /dzasm         Reverse engineer Z80 binaries into assembler source
     /fontbitmap    Generate asm source for ROM fonts & token table
     /forth         Tools to generate CamelForth-based applications
     /jdk           Eclipse Java Compiler and the MakeJar utility
                    (these tools are used to compile executable Jar's
                    for OZvm, Z88Card and FontBitMap applications.

/wsapps             Generic workstation Z88 related applications
     z88transfer    EazyLink Client by Sergio Costas (requires Python)

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
The Z88 Project Git repositories
----------------------------------------------------------------------
The main repository, z88.git, contains mostly Z88 source code, and a
single submodule, OZ, that poitns to another Git repository. This repository
is regarded as an umbrella for work archived or referenced.

Currently, when working on a specific project, use a stand-alone Git:

https://bitbucket.org/cambridge/oz.git (OZ - Z88 ROM)
https://bitbucket.org/cambridge/mpm.git (Mpm - Z80 Assember utility)
https://bitbucket.org/cambridge/z88card.git (Z88Card - Z88 AppCard Manager)
https://bitbucket.org/cambridge/ozvm.git (OZvm - Z88 Emulator)
https://bitbucket.org/cambridge/eazylink2.git (New EazyLink2 Desktop Client)

If you need write access to the repositories, drop us an email with
your user account name on bitbucket: cambridgez88@gmail.com



----------------------------------------------------------------------
Configuring command line shell environment variables
----------------------------------------------------------------------

In order for the many compile scripts to function properly, two steps
must be made before following the next steps:

1) Add to your operating system PATH environment variable the
   <Project Home>/bin path. This is to ensure the all executables will
   be found, no matter where you are located inside the project folders

2) Create a new environment variable Z88WORKBENCH_HOME that points to
   the base location of the git repository you just checked out.
   This variable is also essential to many compile scripts used by their
   project.

In Windows you define the PATH environment variable as follows:

    Control Panel -> "System" -> Advanced -> System Variables
    Click on "Path", then append <Project Home>\bin to line.

Generally for Unixes, you add the <Project Home>/bin path to your shell
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
Compiling the Z80 assembler tool chain (Mpm & Z88Card)
----------------------------------------------------------------------

All Z88 applications and popdowns, especially the Z88 ROM (OZ), are
implemented using native Z80 machine code (Zilog Z80 assembly language).
All Z80 assembler source code is provided in *.asm files and needs to
be compiled using the Z80 Cross Module Assembler, Mpm. Usually, several
compiled binaries are combined into a single binary file, using Z88Card.

-- Compiling Mpm --

Mpm is developed in the C programming language. 

The source code is located in a separate Git repository and is provided 
with make files for different C compilers.

On Linux and Mac OS X, the GCC compiler is easily installed on the
accompanying CD's (or from a download repository). For Windows, you
need to download and install a free C compiler. Please refer to basic
requirements section above.

Use your favorite C compiler on your platform with these supplied make
files:

Check out the mpm-git repository, start a command shell and change
directory to you check-out location. Then

make -f makefile.z80.bcc.win32 [Borland C++ V5.5 on Windows]
or
make -f makefile.z80.gcc.win32 [using MinGW or Cygwin GCC on Windows]
or
nmake /f makefile.z80.msvc.win32 [using MS Visual Studio on Windows]
or
make -f makefile.z80.gcc.unix [using GCC on GCC/Linux/Mac OS X/Unix]
or
qmake mpm.pro; make [using Qt/Qt-Creator installed on Windows/Mac/Linux]

Copy the compiled binary to you main [Z88 project] / bin folder.


-- Compiling Z88Card --

Z88Card, a binary file combiner, is a Qt-based library executable program
to be compiled. Z88Card is found together with Mpm in most Z88 application
compile scripts. The resulting binary is a z88card executable file, 
just as Mpm.

To compile Z88Card you have to check-out the separate Git repository and 
install the Qt libraries and tools.
More information is described in the comments in each platform compile
script:

    compile-gcc-linux.sh         (qt 4.8+, make & gcc are installed your
                                  linux using native package manager)

    compile-qtsdk-linux.sh       (qt 4.8+ and tools,are installed from
                                  QtSDK for Linux - make & gcc are on linux)

    compile-mingw32-windows.bat  (qt 4.8+, mingw make & gcc are installed
                                  through the QtSDK for Windows)

    compile-qtsdk-macosx.sh      (qt 4.8+ and tools are installed from QtSDK
                                  for Mac OSX. Requires Xcode to be installed)

Copy the compiled binary to you main [Z88 project] / bin folder.


----------------------------------------------------------------------
Compiling Z88 ROM
----------------------------------------------------------------------

Before you can compile your own Z88 operating system ROM you need to
have compiled the Z80 assembler tool chain (see previous section).

More details about Z88 ROM compilation can be found in
    cd <z88 project>/oz/readme.txt



----------------------------------------------------------------------
Compiling Z88 Applications & popdowns
----------------------------------------------------------------------

All Z88 application & popdowns are located inside the /z88apps directory.
The Z80 assembler tool chain has to be compiled before you can make
Z88 binaries. Further, most Z88 applications projects link static
functionality from the Z88 standard library, located in /stdlib.

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



----------------------------------------------------------------------
Compiling Z88 Virtual Machine, OZvm
----------------------------------------------------------------------
The Z88 source code tree has provided latest z88.jar application.
----------------------------------------------------------------------

You can use the Z88 emulated machine, OZvm, to run the Z88 applications
available in /z88apps, and even work at processor single step level to
debug the Z88 applications and OZ rom (located in /oz).

OZvm is a Java application and needs the Java Runtime V1.4 Environment
to run. Please refer to above sections for getting java installed.

(If you want latest (possibly unstable) version, you have to 
checkout from the ozvm Git repository and compile from there.)

To get OZvm compiled into an executable program on your operating system,
execute the makejar script in your separate Git repo checkout:

    makejar.bat (or ./makejar.sh)

This will create the z88.jar executable Java file in <Project Home>/bin.
Run OZvm with

    cd <Project Home>/bin; java -jar z88.jar

Many scripts are integrated in the project that know the location of the
executable binary.

Windows users may create an EXE program (a Java JAR file wrapper).
You need to install Launch4J (http://launch4j.sourceforge.net/), and
edit your PATH environment variable to include the <launch4j install
directory>. The following script both compiles the Jar file and makes a
z88.exe program:

    makeexe.bat
