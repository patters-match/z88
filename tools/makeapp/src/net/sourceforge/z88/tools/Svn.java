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

import java.io.File;
import org.tmatesoft.svn.core.SVNException;
import org.tmatesoft.svn.core.wc.SVNClientManager;
import org.tmatesoft.svn.core.wc.SVNRevision;
import org.tmatesoft.svn.core.wc.SVNStatus;
import org.tmatesoft.svn.core.wc.SVNStatusClient;

/**
 * Fetch latest Subversion revision number from current working directory,
 * scanning all sub folders and their .svn workspace directory inside the
 * 'entries' file.
 */
public class Svn {

	private File currentWorkingDir;        
        private SVNClientManager clientManager;

	public Svn(File cwd) {
		currentWorkingDir = cwd;
                clientManager = SVNClientManager.newInstance();
	}

	/**
	 * Fetch latest Subversion revision number from current working directory
         * using TMate's SVNKit library..
	 * 
	 * If no .svn workspace directory is found, "0" is returned.
	 * 
	 * @return
	 */
	public String getLatestRevision() {
            try {
                // return Integer.toString(scanForLatestSvnRevision(currentWorkingDir));
                SVNStatusClient stClient = clientManager.getStatusClient();
                SVNStatus status = stClient.doStatus(currentWorkingDir, false);
                SVNRevision rev = status.getCommittedRevision();
                return Long.toString(rev.getNumber());
            } catch (SVNException ex) {
                return "0";
            }
	}
}
