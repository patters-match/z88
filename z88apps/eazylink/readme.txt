-------------------------------------------------------------------------------------
EasyLink compilation notes
-------------------------------------------------------------------------------------

To compile the EasyLink (popdown) application, execute the following:

1) Select the directory holding the EasyLink files as the current directory.
2) Execute:
                make.eazylink.bat (DOS/Windows command line script)
                make.eazylink.sh (UNIX/LINUX shell script)

This will create the executable files "easylink.bin", "easylink.63" and "easylink.epr".

-------------------------------------------------------------------------------------

If you need to fetch and compile a previous release, you have to load the sources into
this directory from another location in the SVN repository. This is called to
switch in SVN terms.

The latest development release (trunk) is always located in SVN at URL:
        https://z88.svn.sourceforge.net/svnroot/z88/trunk/z88apps/eazylink

To get a milestone release into the current EazyLink working copy source directory on
your filing system, which you then can compile, you do the following on the command
line (DOS or Unix shell):

svn switch https://z88.svn.sourceforge.net/svnroot/z88/tags/z88apps/eazylink/<version>

(The "svn" command is only available if you have installed the Subversion client on
your operating system)

If you're using TortoiseSVN on Windows Explorer, simply right-click inside the
current directory (with the EazyLink sources), choose "TortoiseSVN" in the pop-up menu,
then select the "Switch" command and enter the tag url.


*************************************************************************************
* The following releases are available (shown as complete tag URL's):               *
*                                                                                   *
*      https://z88.svn.sourceforge.net/svnroot/z88/tags/z88apps/eazylink/V5.0.4     *
*      https://z88.svn.sourceforge.net/svnroot/z88/tags/z88apps/eazylink/V5.0.5     *
*                                                                                   *
*************************************************************************************

Remember to switch back to the main development trunk, if that's what you had originally
checked out from SVN in your current directory:

       svn switch https://z88.svn.sourceforge.net/svnroot/z88/trunk/z88apps/eazylink
