/*
 * Created on Jan 15, 2004
 *
 */
package net.sourceforge.z88;

import java.util.LinkedList;

/**
 * @author <A HREF="mailto:gstrube@tiscali.dk">Gunther Strube</A>
 * $Id$
 *  *
 * Manage a list of executed debug commands, so that the developer can
 * browse the command history at command input using <UP> or <DOWN> arrows. 
 */
public class CommandHistory {
	private LinkedList commands = null;
	private int currentCommandIndex = -1;
	
	/**
	 * 
	 */
	public CommandHistory() {
		commands = new LinkedList();
	}

	/**
	 * Add new debug command to start of history list, using LIFO principle.
	 * This string will be the first returned, when the list is being 
	 * browsed with the <UP> key from the debug command line.
	 * 
	 * If the new command string is identical to the newest item in the
	 * command history, then it will not be added to the history.
	 * 
	 * @param cmd The string from the current debug command line
	 */
	public void addCommand(String cmd) {
		if (cmd.length() == 0) return;	// don't add empty commands to history list.
		
		if (commands.isEmpty() == false) {
			currentCommandIndex = -1;	// always reset to point at start of list
			String theNewest = (String) commands.getFirst();
			if (theNewest.compareTo(cmd) == 0) {
				// don't add a duplicate command in history list
				return;
			} 
		}
		
		commands.addFirst(cmd);
		currentCommandIndex = -1;	// point at newest command in list
	}
	
	/**
	 * Get the previous command string in list.
	 * 
	 * @return prev. command string or null if list is empty ot at end of list
	 */
	public String browsePrevCommand() {
		String curCmd = null; 
		
		if (commands.isEmpty() == false) {
			if ( (currentCommandIndex+1) <= (commands.size()-1) ) ++currentCommandIndex;
			curCmd = (String) commands.get(currentCommandIndex);
		}
		
		return curCmd;		
	}

	/**
	 * Get the next command string in list.
	 * 
	 * @return next command string or null if list is empty or at start of list
	 */
	public String browseNextCommand() {
		String curCmd = null;
		 
		if (commands.isEmpty() == false) {
			if ( currentCommandIndex > 0) {
				if ( (currentCommandIndex-1) >= 0 ) --currentCommandIndex;
				curCmd = (String) commands.get(currentCommandIndex);
			}
		}
		
		return curCmd;		
	}	
}
