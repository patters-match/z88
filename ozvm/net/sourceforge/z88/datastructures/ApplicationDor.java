/*
 * ApplicationDor.java
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
 * @author <A HREF="mailto:gbs@users.sourceforge.net">Gunther Strube</A>
 * $Id$
 *
 */
package net.sourceforge.z88.datastructures;

import net.sourceforge.z88.Memory;

/**
 * Get Application DOR Information.
 */
public class ApplicationDor {

	/** reference to available memory hardware and functionality */
	private Memory memory = null;

	/**
	 * extended address pointer to next Application DOR
	 */
	private int nextApp;

	/**
	 * Application Key Letter.
	 */
	private char keyLetter;

	/**
	 * Contiguous RAM size required
	 */
	private int ramSize;

	/**
	 * Unsafe (ie. not preserved over pre-emption) workspace size
	 */
	private int unsafeWorkspace;

	/**
	 * Safe (ie. preserved over pre-emption) workspace size
	 */
	private int safeWorkspace;

	/**
	 * The entry is expanded to include the bank number that is 
	 * referred to by the logical address, so that it easy to set 
	 * a breakpoint just when the application is entered by OZ. 
	 */
	private int entryPoint;

	/**
	 * Desired binding of Segment 0 on entry
	 */
	private int segment0Bank;

	/**
	 * Desired binding of Segment 1 on entry
	 */
	private int segment1Bank;

	/**
	 * Desired binding of Segment 2 on entry
	 */
	private int segment2Bank;

	/**
	 * Desired binding of Segment 3 on entry
	 */
	private int segment3Bank;

	/**
	 * Application type byte 1
	 */
	private int appType1;

	/**
	 * Application type byte 2
	 */
	private int appType2;

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

	/**
	 * extended address pointer to MTH token base
	 */
	private int tokens;

	/**
	 * Application name that is listed in the Index, eg. "PipeDream".
	 */
	private String appName;

	public ApplicationDor(int extAddress) {
		int bank = extAddress >> 16; // the absolute bank number of this DOR
		int slotMask = bank & 0xC0;  // the slot mask to be used for relative DOR
									 // pointers
		int offset = extAddress & 0xFFFF;
		
		memory = Memory.getInstance();

		offset += 3; // Next Application DOR pointer (absolute)
		
		nextApp = (memory.getByte(offset + 2, bank) << 16)
				| (memory.getByte(offset + 1, bank) << 8)
				| memory.getByte(offset, bank);
		if (nextApp != 0)
			nextApp |= (slotMask << 16);	// Insert slot mask only for real pointers...  
					
		offset += (3 + 3 + 6); // point at key letter
		keyLetter = (char) memory.getByte(offset++, bank);
		ramSize = memory.getByte(offset++, bank);

		offset += 2; // point at unsafe workspace (skip environment estimate
					 // overhead)
		unsafeWorkspace = memory.getByte(offset + 1, bank) << 8
				| memory.getByte(offset, bank);

		offset += 2; // point at safe workspace
		safeWorkspace = memory.getByte(offset + 1, bank) << 8
				| memory.getByte(offset, bank);

		offset += 2; // entry point
		entryPoint = memory.getByte(offset + 1, bank) << 8
				| memory.getByte(offset, bank);

		offset += 2;
		segment0Bank = (memory.getByte(offset, bank) != 0) ? slotMask
				| memory.getByte(offset, bank) : 0;
		offset++;
		segment1Bank = (memory.getByte(offset, bank) != 0) ? slotMask
				| memory.getByte(offset, bank) : 0;
		offset++;
		segment2Bank = (memory.getByte(offset, bank) != 0) ? slotMask
				| memory.getByte(offset, bank) : 0;
		offset++;
		segment3Bank = (memory.getByte(offset, bank) != 0) ? slotMask
				| memory.getByte(offset, bank) : 0;
		
		// Extend the entry address with the bank that contains the code 
		// to be executed.
		switch( (entryPoint & 0xC000) >> 14 ) {
			case 0:
				entryPoint |= ( (segment0Bank & 0xFF) << 16);
				break;
			case 1:
				entryPoint |= ( (segment1Bank & 0xFF) << 16);
				break;
			case 2:
				entryPoint |= ( (segment2Bank & 0xFF) << 16);
				break;
			case 3:
				entryPoint |= ( (segment3Bank & 0xFF) << 16);
				break;		
		}
		
		offset++;
		appType1 = memory.getByte(offset++, bank);
		appType2 = memory.getByte(offset++, bank);

		offset += 2;
		topics = ((memory.getByte(offset + 2, bank) | slotMask) << 16)
				| (memory.getByte(offset + 1, bank) << 8)
				| memory.getByte(offset, bank);
		offset += 3;
		commands = ((memory.getByte(offset + 2, bank) | slotMask) << 16)
				| (memory.getByte(offset + 1, bank) << 8)
				| memory.getByte(offset, bank);
		offset += 3;
		help = ((memory.getByte(offset + 2, bank) | slotMask) << 16)
				| (memory.getByte(offset + 1, bank) << 8)
				| memory.getByte(offset, bank);
		offset += 3;
		tokens = ((memory.getByte(offset + 2, bank) | slotMask) << 16)
				| (memory.getByte(offset + 1, bank) << 8)
				| memory.getByte(offset, bank);
		
		offset += 4;
		int nameLength = memory.getByte(offset++, bank) - 1;	// exclude null-terminator of name
		StringBuffer bufName = new StringBuffer(32);
		for (int c = 0; c < nameLength; c++)
			bufName.append((char) memory.getByte(offset++, bank));
		appName = bufName.toString();
	}

	/**
	 * @return Returns the name of the application/popdown (as displayed in
	 *         Index).
	 */
	public String getAppName() {
		return appName;
	}

	/**
	 * @return Returns the appType1.
	 */
	public int getAppType1() {
		return appType1;
	}

	/**
	 * @return Returns the appType2.
	 */
	public int getAppType2() {
		return appType2;
	}

	/**
	 * @return Returns the pointer the MTH command definitions.
	 */
	public int getCommands() {
		return commands;
	}

	/**
	 * The entry is expanded to include the bank number that is 
	 * referred to by the logical address, so that it easy to set 
	 * a breakpoint just when the application is entered by OZ. 
	 * 
	 * @return Returns the locigal address of the entryPoint (typically in
	 *         segment 3).
	 */
	public int getEntryPoint() {
		return entryPoint;
	}

	/**
	 * @return Returns the base pointer the MTH help pages.
	 */
	public int getHelp() {
		return help;
	}

	/**
	 * @return Returns the application/popdown keyLetter.
	 */
	public char getKeyLetter() {
		return keyLetter;
	}

	/**
	 * @return Returns the pointer to next Application DOR
	 */
	public int getNextApp() {
		return nextApp;
	}

	/**
	 * @return Returns the Contiguous RAM size in 256 byte pages (for Bad apps).
	 */
	public int getRamSize() {
		return ramSize;
	}

	/**
	 * @return Returns the size of application safe workspace.
	 */
	public int getSafeWorkspace() {
		return safeWorkspace;
	}

	/**
	 * @return Returns the segment0Bank.
	 */
	public int getSegment0BankBinding() {
		return segment0Bank;
	}

	/**
	 * @return Returns the segment1Bank.
	 */
	public int getSegment1BankBinding() {
		return segment1Bank;
	}

	/**
	 * @return Returns the segment2Bank.
	 */
	public int getSegment2BankBinding() {
		return segment2Bank;
	}

	/**
	 * @return Returns the segment3Bank.
	 */
	public int getSegment3BankBinding() {
		return segment3Bank;
	}

	/**
	 * @return Returns the pointer the MTH topic token base.
	 */
	public int getTokens() {
		return tokens;
	}

	/**
	 * @return Returns the pointer the MTH topic definitions.
	 */
	public int getTopics() {
		return topics;
	}

	/**
	 * @return Returns the size of application unsafe workspace.
	 */
	public int getUnsafeWorkspace() {
		return unsafeWorkspace;
	}
}