/*
 * Mth.java
 * This	file is	part of	OZvm.
 *
 * OZvm	is free	software; you can redistribute it and/or modify	it under the terms of the
 * GNU General Public License as published by the Free Software	Foundation;
 * either version 2, or	(at your option) any later version.
 * OZvm	is distributed in the hope that	it will	be useful, but WITHOUT ANY WARRANTY;
 * without even	the implied warranty of	MERCHANTABILITY	or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * You should have received a copy of the GNU General Public License along with	OZvm;
 * see the file	COPYING. If not, write to the
 * Free	Software Foundation, Inc., 59 Temple Place - Suite 330,	Boston,	MA 02111-1307, USA.
 *
 * @author <A HREF="mailto:gstrube@gmail.com">Gunther Strube</A>
 *
 */
package com.jira.cambridgez88.ozvm.datastructures;

import com.jira.cambridgez88.ozvm.Memory;
import com.jira.cambridgez88.ozvm.Z88;

/**
 * This class represents a collection of data that is part of an
 * application DOR.
 */
public class Mth {

	/** reference to available memory hardware and functionality */
	private Memory memory;

	/**
	 * Slot mask of the MTH pointers
	 */
	private int slotMask;

	
	/**
	 * extended address pointer to MTH topic definitions
	 */
	private int topics;

	/**
	 * extended address pointer to MTH command definitions
	 */
	private int commands;

	/**
	 * extended address pointer to MTH help pages
	 */
	private int help;

	public Mth() {
		memory = Z88.getInstance().getMemory();
	}

	/**
	 * Create an MTH and populate it with data.. 
	 */
	public Mth(int topics, int commands, int help) {
		this();

		// the slot mask to be used for relative DOR
		// it's the same slot mask, whether for topics, commands or help..
		this.slotMask = (topics >> 16) & 0xC0;  
		
		this.topics = topics;
		this.commands = commands;
		this.help = help;		
	}

	public int getTopicsPtr() {
		return topics;
	}

	public void setTopicsPtr(int topics) {
		this.slotMask = (topics >> 16) & 0xC0;
		this.topics = topics;
	}

	public int getCommandsPtr() {
		return commands;
	}

	public void setCommandsPtr(int commands) {
		this.slotMask = (commands >> 16) & 0xC0;
		this.commands = commands;
	}

	public int getHelpPtr() {
		return help;
	}

	public void setHelpPtr(int help) {
		this.slotMask = (help >> 16) & 0xC0;
		this.help = help;
	}
}
