-------------------------------------------------------------------------------------
FlashStore compilation notes
-------------------------------------------------------------------------------------

To compile the FlashStore application, execute the following:

1) Select the directory holding the FlashStore files as the current directory.
2) Execute:
                makeapp.bat (DOS/Windows command line script)
                makeapp.sh  (UNIX/LINUX shell script)

   This will create the executable file "fsapp.bin", "romhdr.bin" and create
   the "flashstore.epr" card file.

-------------------------------------------------------------------------------------

If you need to fetch and compile a previous release, you have to load the sources into
this directory from another location in the SVN repository. This is called to
switch in SVN terms.

The latest development release (trunk) is always located in SVN at URL:
        https://z88.svn.sourceforge.net/svnroot/z88/trunk/z88apps/flashstore

To get a milestone release into the current FlashStore working copy source directory on
your filing system, which you then can compile, you do the following on the command
line (DOS or Unix shell):

svn switch https://z88.svn.sourceforge.net/svnroot/z88/tags/z88apps/flashstore/<version>

(The "svn" command is only available if you have installed the Subversion client on
your operating system)

If you're using TortoiseSVN on Windows Explorer, simply right-click inside the
current directory (with the FlashStore sources), choose "TortoiseSVN" in the pop-up menu,
then select the "Switch" command and enter the tag url.


*************************************************************************************
* The following compilable releases are available (shown as complete tag URL's):    *
*                                                                                   *
*      https://z88.svn.sourceforge.net/svnroot/z88/tags/z88apps/flashstore/V1.7     *
*      https://z88.svn.sourceforge.net/svnroot/z88/tags/z88apps/flashstore/V1.8     *
*      https://z88.svn.sourceforge.net/svnroot/z88/tags/z88apps/flashstore/V1.8.1   *
*      https://z88.svn.sourceforge.net/svnroot/z88/tags/z88apps/flashstore/V1.8.2   *
*                                                                                   *
*************************************************************************************

Remember to switch back to the main development trunk, if that's what you had originally
checked out from SVN in your current directory:

      svn switch https://z88.svn.sourceforge.net/svnroot/z88/trunk/z88apps/flashstore
