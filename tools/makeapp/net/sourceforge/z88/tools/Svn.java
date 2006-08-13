/*
 * Svn.java
 * This file is part of MakeApp.
 * 
 * MakeApp is free software; you can redistribute it and/or modify it under the terms of the 
 * GNU General Public License as published by the Free Software Foundation;
 * either version 2, or (at your option) any later version.
 * MakeApp is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 * without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * You should have received a copy of the GNU General Public License along with MakeApp;
 * see the file COPYING. If not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 * 
 * @author <A HREF="mailto:gbs@users.sourceforge.net">Gunther Strube</A>
 * $Id$  
 *
 */

package net.sourceforge.z88.tools;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;

/**
 * Fetch latest Subversion revision number from current 
 * working directory, scanning all sub folders and their .svn 
 * workspace directory inside the 'entries' file.
 */
public class Svn {
	private static final String svnRevisionWorkspaceFile = ".svn" + System.getProperty("file.separator") + "entries";
	private static final String svnRevisionSearchPattern = "committed-rev=";
	private File currentWorkingDir;
	
	public Svn(File cwd) {
		currentWorkingDir = cwd; 	
	}

	/**
	 * Fetch latest Subversion revision number from current working directory
	 * (and it's inherent sub directories) by scanning all ".svn/entries" file 
	 * and finding the latest revision number.
	 * 
	 * If no .svn workspace directory is found, "0" is returned.
	 * @return
	 */
	public String getLatestRevision() {
		return Integer.toString(scanForLatestSvnRevision(currentWorkingDir));
	}
	
	/**
	 * Scan current directiry and subdirectories for SVN revision numbers by 
	 * looking SVN data in embedded .svn workspace directory for SVN revision 
	 * data, and return the highest found revision number.
	 * 
	 * If no .svn directory is found in the specified directory, 0 is returned.
	 */ 
    private int scanForLatestSvnRevision(File dir) {
    	int latestRevisionNo = 0;
    	
        if (dir.isDirectory()) {
        	latestRevisionNo = getSvnRevisionFromDir(dir.getAbsolutePath()); 
        	
            String[] children = dir.list();
            for (int i=0; i<children.length; i++) {
            	if (children[i].compareTo(".svn") != 0) {
            		File child = new File(dir, children[i]);
            		if (child.isDirectory()) {
		            	int anotherRevisionNo = scanForLatestSvnRevision(child);
		            	if (latestRevisionNo < anotherRevisionNo)
		            		latestRevisionNo = anotherRevisionNo;
            		}
            	}
            }
        }
        
        return latestRevisionNo;
    }
    
	/**
	 * Fetch current Subversion revision number from specified directory
	 * (and it's inherent sub directories) by looking into the ".svn/entries" file and finding the line
	 * that contains the 'committed-rev="xxxx"' pattern where 'xxxx' is the latest revision number.
	 * 
	 * If the file wasn't found, return 0.
	 * @return
	 */
	private int getSvnRevisionFromDir(String cwd) {
		int latestRevisionNo = 0;
		
		try {
	        String str;

	        BufferedReader in = new BufferedReader(
	        		new FileReader(cwd + System.getProperty("file.separator") + svnRevisionWorkspaceFile));
	        while ((str = in.readLine()) != null) {
	        	int foundRevision = str.indexOf(svnRevisionSearchPattern);
	            if (foundRevision >= 0) {
	            	String revisionNo = str.substring(foundRevision+svnRevisionSearchPattern.length()+1);
	            	revisionNo = revisionNo.substring(0,revisionNo.length()-1);
	            	
	            	int newRevision = Integer.parseInt(revisionNo);
	            	if (latestRevisionNo < newRevision)
	            		latestRevisionNo = newRevision;
	            }
	        }
	        in.close();
	    } catch (IOException e) {
	    	// System.err.println("Couldn't open or read '" + cwd + System.getProperty("file.separator") + svnRevisionWorkspaceFile + "'");
	    }
	    
	    return latestRevisionNo;
	}
	
}
