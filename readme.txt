----------------------------------------------------------------------
Introduction
----------------------------------------------------------------------

Welcome to the Z88 development Subversion repository! The place to get
the latest software for Z88 applications, workstation tools and various
utilities. The repository directory file layout has been designed to be
self-contained as much as possible so that once you check out the main
development trunk you will be able to compile all Z88 native software
and run the Z88 emulator within the directory structure of the
repository. Further, you can easily copy or move the complete directory
structure to another media and carry on working, including getting new
updates from Subversion or committing changes back to the repository.



----------------------------------------------------------------------
Basic requirements
----------------------------------------------------------------------

The cross platform tools, scripts and other Z88 software to be compiled
into executable form supports Linux/Mac OS X/Unix and the Windows
operating systems.

The first requirement is to checkout the Subversion trunk (main
development or HEAD in CVS terms) you need to have a Subversion client
installed on your preferred operating system. Please refer to the
documentation on Sourceforge (http://sourceforge.net/svn/?group_id=69038),
http://subversion.tigris.org or online book http://svnbook.red-bean.com.

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

The third requirement on your operating system is Sun's Java Development
Kit (and runtime) V1.4 or newer. Several command line tools (which is
part of the tool chain to develop Z88 applications) and the Z88 emulator
(virtual Z88 hardware and debugging environment) are implemented in
Java. Get your JDK from http://java.sun.com for Windows or Linux
operating systems. Alternatively, get a free JDK for Linux from
Blackdown: http://www.blackdown.org/
Java V1.4 (or newer) is bundled by default on Mac OS X.

There's an extra feature for Windows users which enables you to create
an EXE program out of an executable Jar (it is a Java JAR file wrapper).
OZvm - the Z88 emulator, gives you the option to also make an EXE program.
If you want to do the EXE thing, then install the Launch4J software
which you can get from http://launch4j.sourceforge.net.



----------------------------------------------------------------------
Getting started with Subversion and a quick tour of the repository layout
----------------------------------------------------------------------

To get the complete main development tree of all source files and
documentation in the Subversion repository, you simply check out the
/trunk directory to a locally preferred place on your workstation hard
drive:

svn co https://svn.sourceforge.net/svnroot/z88/trunk

(the above example uses the command line client tool, available on all
supported operating systems by official Subversion project)

There are myriads of other Subversion clients out there to use. The most
known tools are TortoiseSVN (http://tortoisesvn.tigris.org/, Windows
Explorer Gui Shell integration), SubClipse (http://subclipse.tigris.org,
Eclipse IDE plugin, similar to the CVS integration). There's a nice
list of clients here: http://subversion.tigris.org/links.html

Once you've got yourself the latest snapshot of the repository, you
will get the following directory structure with lots of files in it:

/documentation
     /devnotes      Z88 Developers Notes, html files.
     /servman       Z88 Service Manual, html files
     /userguide     Z88 User Guide (4th edition, in progress)

/oz                 Z88 ROM, OZ V4.1 (in development)
     /sysdef        OZ system manifests, used by Z88 assembler sources
     /bankX         The 128K ROM organisation

/stdlib             Standard library routines for Z88 applications

/tools              Developer tools for asm development, Z88 emulator
     /dzasm         Reverse engineer Z80 binaries into assembler source
     /fontbitmap    Generate asm source for ROM fonts & token table
     /makeapp       Binary loader to make Z88 ROM & Application Cards
     /mpm           Z80/Z88 Cross Module Assembler & Linker
     /ozvm          Z88 Virtual Machine & Debugger

/wsapps             Generic workstation Z88 related applications
     z88transfer    EazyLink Client by Sergio Costas (requires Python)

/www                http://z88.sf.net web site (in progress)

/z88apps            Z88 Applications & popdowns (Z80 source code)
     /debugapp      An empty popdown for OZvm debugging (load/run code)
     /eazylink      EazyLink popdown & PcLink II emulation
     /epfetch       File Eprom Management
     /flashstore    Rakewell Flash Card File Management
     /flashstest    Rakewell Flash Card testing popdown
     /fview         Simple Ascii File Viewer popdown.
     /intuition     Z88 Application Debugger/Disassembler
     /romcombiner   BBC BASIC utility to combine applications to card.
     /romupdate     BBC BASIC utility to update/add apps to Flash Cards
     /wavplay       Play polyphonic sounds on Z88 Loudspeaker
     /zdis          Z80 disassembler
     /zmonitor      View Z88 memory (RAM/ROM)
     /Zprom         Blow code to UV Eprom / Flash Cards



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
Compiling the Z80 assembler tool chain (Mpm & MakeApp)
----------------------------------------------------------------------

All Z88 applications and popdowns, especially the Z88 ROM (OZ), are
implemented using native Z80 machine code (Zilog Z80 assembly language).
All Z80 assembler source code is provided in *.asm files and needs to
be compiled using the Z80 Cross Module Assembler, Mpm. Usually, several
compiled binaries are combined into a single binary file, using MakeApp.

-- Compiling Mpm --

Mpm is developed in the C programming language. The source code in the
/tools/mpm is provided with make files for different C compilers.
On Linux and Mac OS X, the GCC compiler is easily installed on the
accompanying CD's (or from a download repository). For Windows, you
need to download and install a free C compiler. Please refer to basic
requirements section above.

Use your favorite C compiler on your platform with these supplied make
files:

cd <z88 project>/tools/mpm

make -f makefile.z80.borlandccp55.win32  [Borland C++ V5.5 on Windows]
or
make -f makefile.z80.gcc.win32 [using MinGW or Cygwin GCC on Windows]
or
make -f makefile.z80.gcc.unix [using GCC on GCC/Linux/Mac OS X/Unix]


-- Compiling MakeApp --

MakeApp, a binary file combiner, is a java program which needs a Sun
Java 1.4 Development Kit (or newer) installed to get compiled. MakeApp
is found together with Mpm in most Z88 application compile scripts.
The resulting binary is a makeapp.jar file, which is executed with the
java -jar makeapp.jar command. To compile MakeApp the JDK 1.4 Java
compiler tool, javac, must be available to the command shell.

For all operating system platforms, the PATH environment variable
must be set to the <jdk install>/bin folder. In Windows you define the
PATH environment variable as follows:

    Control Panel -> "System" -> Advanced -> System Variables
    Click on "Path", then append <jdk install>\bin to line.

Generally for Unixes, you add the <jdk install>\bin path to your shell
environment init scripts, for example in the .bash_profile file for
BASH. To test the availablity of the java compiler, just type

    javac -version

This will display the version and the compile options to the console.
You're now ready compile MakeApp:

    cd <z88 project>/tools/makeapp
    makejar.bat (Windows) or ./makejar.sh (Unix)



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

Build the standard.lib file using makelib.bat (or makelib.sh) script
before executing make scripts inside the Z88 application directories.

For each Z88 application (or popdown), change to the current directory
of that project, then execute the makeapp (or similar script name) for
your operating system platform. For example, to compile FlashStore:

    cd <z88 project>/z88apps/flashstore
    makeapp.bat (or ./makeapp.sh)



----------------------------------------------------------------------
Compiling Z88 Virtual Machine, OZvm
----------------------------------------------------------------------

You can use the Z88 emulated machine, OZvm, to run the Z88 applications
available in /z88apps, and even work at processor single step level to
debug the Z88 applications and OZ rom (located in /oz).

OZvm is a Java application and needs the Java Runtime Environment to run.
Please refer to above sections for getting java installed and especially
the java compiler, javac.

To get OZvm compiled into an executable program on your operating system,
execute the makejar script:

    cd <z88 project>/tools/ozvm
    makejar.bat (or ./makejar.sh)

This will create the z88.jar executable Java file. Run OZvm with

    java -jar z88.jar

Windows users may create an EXE program out of the z88.jar file (a Java
JAR file wrapper). You need to install Launch4J
(http://launch4j.sourceforge.net/), and edit your PATH environment
variable to include the <launch4j install directory>. Once you have
compiled the OZvm and produced a z88.jar file, change directory to

    cd <z88 project>\tools\ozvm\launch4j
    exewrapper.bat

this will create an z88.exe file in the parent directory where the
z88.jar file is located.



----------------------------------------------------------------------
Last edited: $Id$
----------------------------------------------------------------------