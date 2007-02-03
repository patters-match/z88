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

If you need to get & compile a previous release, you have to load the sources into
this directory from another location in the SVN repository. This is called to
switch to another location in SVN terms.

The latest development release is always located in SVN at:
        https://z88.svn.sourceforge.net/svnroot/z88/trunk/z88apps/eazylink

To get another release into the current EazyLink working copy source directory on your
filing system, which you then can compile, you do the following on the command line
(DOS or Unix shell):

svn switch https://z88.svn.sourceforge.net/svnroot/z88/tags/z88apps/eazylink/<version>

If you're using TortoiseSVN on Windows Explorer, simply right-click inside the
current directory (with the EazyLink sources), choose "TortoiseSVN" in the pop-up menu,
then select the "Switch" command and enter the tags url.

The following releases are available (shown as complete tag URL's):

        https://z88.svn.sourceforge.net/svnroot/z88/tags/z88apps/eazylink/V5.0.4

Remember to switch back to the main development trunk, if that's what you had originally
checked out from SVN:

        svn switch https://z88.svn.sourceforge.net/svnroot/z88/trunk/z88apps/eazylink
