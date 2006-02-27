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
Basic requisites
----------------------------------------------------------------------

The cross platform tools, scripts and other Z88 software to be compiled
into executable form supports Linux/Mac OSX/Unix and the Windows
operating systems.

The first requirement is to to checkout the Subversion trunk (main
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
files for Windows is also supported.

The third requirement on your operating system is Sun's Java Development
Kit (and runtime) V1.4 or newer. Several command line tools (which is
part of the tool chain to develop Z88 applications) and the Z88 emulator
(virtual Z88 hardware and debugging environment) are implemented in
Java. Get your JDK from http://java.sun.com for Windows or Linux
operating systems. Java V1.4 or newer is bundled by default on Mac OSX.



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
     /devnotes           Z88 Developers Notes, html files.
     /servman            Z88 Service Manual, html files
     /userguide          Z88 User Guide (4th edition, in progress)

/oz                      Z88 ROM, OZ V4.1 (in development)
     /sysdef             OZ system manifests, used by Z88 asm sources
     /bankX              the 128K ROM organisation

/stdlib                  Standard library routines for Z88 applications

/tools                   Developer tools for asm development, Z88 emulator
     /dzasm              Reverse engineer Z80 binaries into asm source
     /fontbitmap         Generate asm source for ROM fonts & token table
     /makeapp            Binary loader to make Z88 ROM & Application Cards
     /mpm                Z80/Z88 Cross Module Assembler & Linker
     /ozvm               Z88 Emulator & Debugger

/wsapps                  Generic workstation Z88 related applications
     z88transfer         EazyLink Client by Sergio Costas (Python program)

/www                     http://z88.sf.net web site (in progress)

/z88apps                 Z88 Applications & popdowns (Z80 source code)
     /debugapp           An empty popdown for OZvm debugging (load/run code)
     /eazylink           EazyLink popdown & PcLink II emulation
     /epfetch            File Eprom Management
     /flashstore         Rakewell Flash Card File Management
     /flashstest         Rakewell Flash Card testing popdown
     /fview              Simple Ascii File Viewer popdown.
     /intuition          Z88 Application Debugger/Disassembler
     /romcombiner        BBC BASIC utility to combine applications to card.
     /romupdate          BBC BASIC utility to update/add apps to Flash Cards
     /wavplay            Play polyphonic sounds on Z88 Loudspeaker
     /zdis               Z80 disassembler
     /zmonitor           View Z88 memory (RAM/ROM)
     /Zprom              Blow code to UV Eprom / Flash Cards



----------------------------------------------------------------------
Compiling OZvm into an executable program (jar file)
----------------------------------------------------------------------

OZvm (the Z88 emulator) is a Java binary application, an executable
JAR file, issued by a java -jar <filename.jar> command. Windows users
can also generate an EXE (jar wrapper) using Launch4J.



----------------------------------------------------------------------
Compiling the Z80 assembler tool chain
----------------------------------------------------------------------

All Z88 applications and popdowns, especially the Z88 ROM (OZ), are
implemented using Z80 machine code (Zilog Z80 assembly programming).


----------------------------------------------------------------------
Compiling Z88 ROM
----------------------------------------------------------------------



----------------------------------------------------------------------
Compiling Z88 Applications & popdowns
----------------------------------------------------------------------




----------------------------------------------------------------------
Last edited: $Id$
----------------------------------------------------------------------
