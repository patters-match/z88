/*
 * AmdFlashBank.java
 * This file is part of OZvm.
 * 
 * OZvm is free software; you can redistribute it and/or modify it under the terms of the 
 * GNU General Public License as published by the Free Software Foundation;
 * either version 2, or (at your option) any later version.
 * OZvm is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 * without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * You should have received a copy of the GNU General Public License along with OZvm;
 * see the file COPYING. If not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 * 
 * @author <A HREF="mailto:gbs@users.sourceforge.net">Gunther Strube</A>
 * $Id$  
 *
 */

package net.sourceforge.z88;

import java.util.Vector;

/** 
 * This class represents the 16Kb Flash Memory Bank on an AMD I29FxxxB chip. 
 * The characteristics of a Flash Memory bank is chip memory that can be read at 
 * all times and only be written (and erased) using a combination of AMD Flash 
 * command sequenses (write byte to address cycles), in ALL available slots on
 * the Z88.
 * 
 * The emulation of the AMD Flash Memory solely implements the chip command 
 * mode programming, since the Z88 Flash Cards only responds to those
 * command sequenses (and not the hardware pin manipulation). Erase Suspend and
 * Erase Resume commands are also not implemented. 
 * 
 * The essential emulation is implemented to respond to the Standard Flash Eprom 
 * Library (which implements all Flash chip manipulation, issuing commands 
 * on a bank, typically specified indirectly using the BHL Z80 registers). 
 */
public class AmdFlashBank extends Bank {
	
	/** Device Code for 128Kb memory, 8 x 16K erasable sectors, 8 x 16K banks */
	public static final int AM29F010B = 0x20;

	/** Device Code for 512Kb memory, 8 x 64K erasable sectors, 32 x 16K banks */
	public static final int AM29F040B = 0xA4;

	/** Device Code for 1Mb memory, 16 x 64K erasable sectors, 64 x 16K banks */
	public static final int AM29F080B = 0xD5;

	/** Manufacturer Code for AM29F0xxx Flash Memory chips */
	public static final int MANUFACTURERCODE = 0x01;
	
	/** 
	 * Read Array Mode<p>
	 * True = Amd Flash Memory behaves like an Eprom, False = command mode
	 * 
	 * Read Array Mode state applies for the complete slot which this bank
	 * is part of.
	 */
	private boolean readArrayMode = true;
	
	/**
	 * A command sequence consists of two unlock cycles, followed by a
	 * command code cycle. Each cycle consists of an address and a byte:
	 * first cycle is [0x555,0xAA], the second cycle is [0x2AA, 0x55]
	 * followed by the third cycle which is the command ('?') code 
	 * (the actual command will then be verified against known codes).
	 */
	private static final Integer commandSequence[] = 
		{new Integer(0x555), new Integer(0xAA), new Integer(0x2AA), new Integer(0x55), new Integer(0x555), new Integer('?')};
	
	/**
	 * The pending command sequense which is the template that is
	 * being validated against the incoming command cycles (the 
	 * processor write byte cycles)
	 */
	private CommandCycleStack commandSequense = null;
	
	/**
	 * Status of ongoing accumulation of Flash Memory command, [<b>true</b>]
	 * (ie. the individual cycles are accumulating and being verified as each cycle 
	 * is accumulated). A command sequense consists of three cycles; two unlock 
	 * cycles followed by the command code (The Erase commands consists of two 
	 * sections of three cycle command sequenses).
	 */
	private boolean isCommandAccumulating = false;
	
	/**
	 * Indicate if a command is being executed [<b>true</b>](Blow Byte, Erase Sector 
	 * or Auto-Select Mode command).  
	 */
	private boolean isCommandExecuting = false;
	
	/**
	 * The command code of the executing command.
	 * Is set to 0, when no command is executing (isCommandExecuting = false). 
	 */
	private int executingCommand = 0;

	/** 
	 * Access to the Z88 hardware & memory model (needed when the Erase command
	 * needs to erase a sector; accessing the other three banks besides this one) 
	 */
	private Blink blink;
	
	/** 
	 * The actual Flash Memory Device Code of this bank instance 
	 */
	private int deviceCode;
	
	/**
	 * Assign the Flash Memory bank to the 4Mb memory model.
	 * 
	 * @param b the Z88 Blink Hardware and memory model 
	 * @param bankNo the bank number (0-255) which this bank is assigned to
	 * @param dc the Flash Memory Device Code (AM29F010B, AM29F040B or AM29F080B) 
	 */
	public AmdFlashBank(Blink b, int dc) {
		super(-1);		
		blink = b;
		deviceCode = dc;
		
		for (int i = 0; i < Memory.BANKSIZE-1; i++) setByte(i, 0xFF); // empty Flash Memory contain FF's
        
		// When a card is inserted into a slot, the Flash chip is always in Ready Array Mode by default
		readArrayMode = true;
	}
		
	/**
	 * Read byte from Flash Memory bank. <addr> is a 16bit word that points into 
	 * the 16K address space of the bank.
	 */
	public final int readByte(final int addr) {
		if (readArrayMode == true) 
			return getByte(addr);	// The chip is in Read Array Mode, get byte data at address..
		else
			return getCommandStatus(addr);	// The chip is in Command Mode, get status of current command
	}

	/**
	 * Write byte <b> to Flash Memory bank. <addr> is a 16bit word that points 
	 * into the 16K address space of the RAM bank.
	 * 
	 * Z80 processor write byte affects the behaviour of the AMD Flash Memory 
	 * chip (activating the accumulating Command Mode). Using processor write 
	 * cycle sequenses the Flash Memory chip can be programmed with data and 
	 * get erased again in ALL available Z88 slots.
	 */
	public final void writeByte(final int addr, final int b) {
		evaluateCommand(addr, b);
	}
	
	/**
	 * @return returns the Flash Memory Device Code (AM29F010B, AM29F040B or AM29F080B) which this bank is part of.
	 */
	public final int getDeviceCode() {
		return deviceCode;
	}

	/**
	 * Define the Read Array Mode state for the AMD Flash Memory chip that is inserted into
	 * the current slot (which this bank is part of).<p>
	 * 
	 * @param rdam the Read Array Mode logical state; <b>true</b> = Read Array Mode, <b>false</b> = Command Mode
	 */
	private final void setSlotReadArrayMode(boolean rdam) {
		if (rdam == true) {
			if (readArrayMode == false) {
				// we're in Command Mode
				if (isCommandExecuting == false) {
					// Flash memory isn't executing an Erase or Blow Byte command...
					// (but a command is getting accumulated)
					readArrayMode = true; // abort command and set chip in Read Array Mode
					isCommandAccumulating = false;
					isCommandExecuting = false;
					executingCommand = 0;
					commandSequense = resetPendingCommand(); 
				}				
			}
		} else {
			if (readArrayMode == true) {
				commandSequense = resetPendingCommand();
				readArrayMode = false;
			}			
		}
	}
	
	
	/**
	 * Fetch success/failure status from executing Flash Memory command (Auto Select, Erase & Program).
	 * 
	 * @return command status information or device data
	 */
	private final int getCommandStatus(int addr) {
		if (isCommandAccumulating == true) {
			// A command is being accumulated (not yet executing)
			// a Read Cycle automatically aborts the pre Command Mode and resets to Read Array Mode
			setSlotReadArrayMode(true);
			return getByte(addr);			
		} else {
			if (isCommandExecuting == true) {
				// return status of Blow Byte, Erase or Auto Select Mode (get Manufacturer & Device Code)
				
				switch(executingCommand) {
					case 0x10: // Chip Erase Command
						return 0; // Not implemented yet
						
					case 0x30: // Sector Erase Command (which this bank is part of)
						return 0; // Not implemented yet
						
					case 0x90:	// Autoselect Command
						addr &= 0xFF;	// only preserve lower 8 bits of address
						switch(addr) {
							case 0: return MANUFACTURERCODE;	// XX00 = Manufacturer Code 
							case 1: return deviceCode;			// XX01 = Device Code
							default: return 0;					// XXXX = Unknown behaviour...
						}
						
					case 0xA0:	// Byte Program Command
						return 0; // Not implemented yet
						
					case 0:
					default:
						setSlotReadArrayMode(true);		// unknown command! Back to Read Array mode
						isCommandExecuting = false;
						return getByte(addr);				
				}
			} else {
				setSlotReadArrayMode(true);		// A command finished executing and we automatically get back to Read Array Mode
				return getByte(addr);	
			}
		}
	}
	
	private final void evaluateCommand(int addr, final int b) {
		if (b == 0xF0) {
			// Reset to Read Array Mode (and abort an accumulating command sequense, if ongoing...)
			// This command will be executed immediately, unless the Flash Memory has begun 
			// programming or erasing (Read Array Mode command will then be ignored).
			setSlotReadArrayMode(true);
		} else {
			if (isCommandExecuting == false) {
				// only accept other write cycles while accumulating a command (it's probably part of the command!)
				setSlotReadArrayMode(false); // any write cycle sets the Flash Memory in Command Mode...
				
				Integer cmdAddr = (Integer) commandSequense.pop();	// validate cycle against this address
				Integer cmd = (Integer) commandSequense.pop();		// validate cycle against this data

				if (cmd.intValue() == '?') {
					// we're reached the actual command code (Top of Stack reached)!
					if (executingCommand == 0xA0) {
						// we've fetched the Byte Program Address & Data
						isCommandAccumulating = false;
						isCommandExecuting = true;
					} else {
						switch(b) {
							case 0x10: // Chip Erase Command
								isCommandAccumulating = false;
								isCommandExecuting = true;
								executingCommand = 0x10;
								break;
								
							case 0x30: // Sector Erase Command (which this bank is part of)
								isCommandAccumulating = false;
								isCommandExecuting = true;
								executingCommand = 0x30;
								break;
								
							case 0x80:	// Erase Command, part 1  
								commandSequense = resetPendingCommand(); // add new sub command sequense for erase chip or sector...
								break;						
								
							case 0x90:	// Autoselect Command 
								isCommandAccumulating = false;
								isCommandExecuting = true;
								executingCommand = 0x90; 
								break;
								
							case 0xA0:	// Byte Program Command 
								executingCommand = 0xA0;
								commandSequense.push(new Integer('?'));	// and the Byte Program Data
								commandSequense.push(new Integer('?'));	// We still need the Byte Program Address  
								break;
								
							default:
								// command sequense was unknown! Immediately return to Read Array Mode...
								setSlotReadArrayMode(true);
						}
					}
				} else {
					addr &= 0x0FFF; // we're only interested in the three lowest hex digits in the unlock cycle address...
					
					if (addr == cmdAddr.intValue() & b == cmd.intValue())
						isCommandAccumulating = true; // only indicate accumulating command mode when command cycle match was found...
					else {
						// command sequense was unknown! Immediately return to Read Array Mode...
						setSlotReadArrayMode(true);
					}
				}				
			}
		}
	}	

	/**
	 * Return a complete 3 cycle command sequense that will be used to validate
	 * a new incoming command sequense from the outside world
	 */
	private CommandCycleStack resetPendingCommand() {
		CommandCycleStack pendCmd = new CommandCycleStack();
		
		// prepare a new command sequense
		for (int p=commandSequence.length-1; p>=0; p--) pendCmd.push(commandSequence[p]);
		
		return pendCmd;
	}
	
	/**
	 * Flash Memory Command Cycle LIFO Stack 
	 */
	private class CommandCycleStack {
		private Vector cmds;
		
		public CommandCycleStack() {
			cmds = new Vector(8);	// The stack never grows more than 3 command cycles * 2 = 6 elements
		}
		
		public Object push(Object cmdItem) {
			cmds.addElement(cmdItem);
			return cmdItem;
		}
		
		public Object pop() {
			int curStackSize = cmds.size();
			
			if (curStackSize == 0) {
				return null;
			} else {
				Object obj = cmds.elementAt(curStackSize - 1);
				cmds.removeElementAt(curStackSize - 1);

				return obj;
			}
		}
	}
}
