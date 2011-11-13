/*
 * IntelFlashBank.java
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
 *
 */

package net.sourceforge.z88;


/** 
 * This class represents the 16Kb Flash Memory Bank on an INTEL I28Fxxxx chip. 
 * The characteristics of a Flash Memory bank is chip memory that can be read at 
 * all times and only be written (and erased) using BLINK hardware in slot 3 in 
 * combination with Intel Flash Memory command sequenses (write byte to address cycles).
 * 
 * Block Erase/Program Suspend and Erase/Program Resume commands are not emulated.
 * Set Block Lock-bit, Set Master Lock-bit and Clear Block Lock-bits commands are
 * not emulated. 
 */
public class IntelFlashBank extends Bank {
	/** reference to Z88 memory model and API functionality */
	private Memory memory;
	
	/** Device Code for 512Kb memory, 8 x 64K erasable sectors, 32 x 16K banks */
	public static final int I28F004S5 = 0xA7;

	/** Device Code for 1Mb memory, 16 x 64K erasable sectors, 64 x 16K banks */
	public static final int I28F008S5 = 0xA6;

	/** Manufacturer Code for I28Fxxxx FlashFile Memory chips */
	public static final int MANUFACTURERCODE = 0x89;
		
	/** 
	 * Read Array Mode<p>
	 * True = Intel Flash Memory behaves like an Eprom, False = command mode
	 * 
	 * Read Array Mode state applies for the complete slot which this bank
	 * is part of.
	 */
	private boolean readArrayMode;
			
	/**
	 * The command code of the executing command.
	 * Is set to 0, when no command is executing (isCommandExecuting = false). 
	 */
	private int executingCommandCode;

	/**
	 * The Command Mode Status Register.
	 * Holds the status bits for success/failure when programming a byte
	 * or erasing a block.
	 *  
	 * Is set to 0, when no command is executing (isCommandExecuting = false). 
	 */
	private int statusRegister;
	
	/** 
	 * Access to the Z88 hardware & memory model (needed when the Erase command
	 * needs to erase a block; accessing the other banks besides this one) 
	 */
	private Blink blink;
	
	/** 
	 * The actual Intel Flash Memory Device Code of bottom bank of card
	 */
	private int deviceCode;

	/**
	 * Assign the Flash Memory bank to the 4Mb memory model.
	 * 
	 * @param b the Z88 Blink Hardware 
	 * @param bankNo the bank number (0-255) which this bank is assigned to
	 * @param the Flash Memory Device Code (I28F004S5 or I28F008S5) 
	 */
	public IntelFlashBank(int dc) {		
		super(-1);		
		blink = Z88.getInstance().getBlink();
		deviceCode = dc;

		memory = Z88.getInstance().getMemory();

		eraseBank(); // Flash Memory Bank is empty by default...

		// When a card is inserted into a slot, the Flash chip 
		// is always in Ready Array Mode by default
		readArrayMode = true;
	}
	
	/**
	 * Read byte from Flash Memory bank. <addr> is a 16bit word that points into 
	 * the 16K address space of the bank.
	 */
	public final int readByte(final int addr) {
		if (readArrayMode == true) 
			// The chip is in Read Array Mode, get byte data at address..
			return getByte(addr);	
		else
			// The chip is in Command Mode, get status of current command
			return getCommandStatus(addr);	
	}

	/**
	 * Write byte <b> to Flash Memory bank. <addr> is a 16bit word that points 
	 * into the 16K address space of the RAM bank.
	 * 
	 * Z80 processor write byte affects the behaviour of the Intel Flash Memory 
	 * chip (activating the accumulating Command Mode). Using processor write 
	 * cycle sequences the Flash Memory chip can be programmed with data and 
	 * get erased again in ALL available Z88 slots.
	 */
	public final void writeByte(final int addr, final int b) {
		processCommand(addr, b);
	}
	
	/**
	 * @return returns the Flash Memory Device Code 
	 * (I28F004S5 or I28F008S5) which for bottom bank of card.
	 */
	public final int getDeviceCode() {
		return deviceCode;
	}

	/**
	 * Erase the contents of this bank to FF's 
	 * (simulate the chip erase functionality).
	 */
	public void eraseBank() {
		for (int addr=0; addr < Bank.SIZE; addr++) 
			setByte(addr, 0xFF);
	}
		
	/**
	 * Fetch success/failure status or chip information from the 
	 * executing Flash Memory command.
	 * 
	 * @return command status information or device data
	 */
	private final int getCommandStatus(int addr) {
		addr &= 0x3FFF; // only bank offset range...
		
		switch(executingCommandCode) {
			case 0x10: // Byte Program Command
			case 0x40: // Byte Program Command
			case 0x70: // Read Status Register
			case 0xD0: // Block Erase Command
				return statusRegister;
				
			case 0x90: // Get Device Identification
				if ((getBankNumber() & 0x3F) == 0) {
					// Device and Manufacturer Code can only be  
					// fetched in bottom bank of card...
					switch(addr) {
						case 0: return MANUFACTURERCODE;	// 0000 = Manufacturer Code 
						case 1: return getDeviceCode();		// 0001 = Device Code
						default: return 0xFF;				// XXXX = Unknown behaviour...
					}
				} else
					return 0xFF;				// XXXX = Unknown behaviour...
					
			default: // unknown command! 
				return 0xFF;				
		}
	}
	
	/**
	 * Process each command cycle sent to the Command Decoder, and execute the
	 * parsed command, once it has been identified. If a command cycle is not
	 * recognized as being a part of a command (address/data) sequence, the 
	 * chip automatically returns to Read Array Mode. Equally, if a read cycle
	 * is performed against the Command Decoder while it is expecting a 
	 * command write cycle, the chip automatically returns to Read Array Mode.  
	 * 
	 * @param addr
	 * @param b
	 */
	private final void processCommand(int addr, final int b) {
		if (readArrayMode == true) {
			// get into command mode...
			readArrayMode = false;
			executingCommandCode = 0;
		}
		
		if (readArrayMode == false) {			
			if (executingCommandCode == 0x10 | executingCommandCode == 0x40) {
				// Byte Program Command, Part 2 (initial Byte Program command received), 
				// we've fetched the Byte Program Address & Data, programming will now begin...
				programByteAtAddress(addr, b);
				executingCommandCode = 0x70;
			} else {
				switch(b) {
					case 0x20:	// Erase Command, part 1  
						// wait for new sub command sequence for erase block
						executingCommandCode = 0x20; 
						break;						
						
					case 0x50: // Clear Status Register
						executingCommandCode = 0;
						// SR.7 = Ready, SR.5 = 0 (Block Erase OK), SR.4 = 0 (Program OK), SR.3 = 0 (VPP OK)
						statusRegister = 0x80; 
						break;
				
					case 0x70: // Read Status Register
						// The Read Cycle will return the status register...
						executingCommandCode = 0x70;					
						break;
						
					case 0x90:	// Chip Identification (get Manufacturer & Device Code) 
						executingCommandCode = 0x90; 
						break;
						
					case 0x10:					
					case 0x40:	// Byte Program Command, Part 1, get address and byte to program.. 
						executingCommandCode = 0x40;
						break;
						
					case 0xD0: // Block Erase Command (which this bank is part of), part 2 
						if (executingCommandCode == 0x20) {
							executingCommandCode = 0xD0;
							eraseBlockCommand(); // always success, if bank is in slot 3 and VPP enabled ...
						}
						break;					
	
					case 0xFF:	// Reset chip to Read Arrary Mode
						readArrayMode = true;
						executingCommandCode = 0;			
						break;
						
					default:
						// command was not identified; Either 2. part of a prev. command or unknown...
						readArrayMode = true;
						executingCommandCode = 0;									
				}				
			}
		}
	}	

	/**
	 * Blow Byte at address.
	 * 
	 * Verify that the byte to be blown follows the rule that only 0 bit 
	 * patterns can be programmed (converting 1 to 0 in the Flash Memory). 
	 * Flash memory bit patterns can only be converted from 0 to 1 by 
	 * erasing the memory...  
	 * 
	 * If the byte is successfully written, this method will signal success
	 * by establishing a read status, which the outside application polls 
	 * and acknowledges as successfully completed.
	 * 
	 * On Byte Write failure a similar read status data will signal failure. 
	 * The application must then signal back with forcing the chip back 
	 * into Read Array Mode. 
	 * 
	 * @param addr offset within bank
	 * @param b byte to be blown on Flash Memory
	 */
	private void programByteAtAddress(final int addr, final int b) {
		if ((getBankNumber() & 0xC0) != 0xC0 ) {
			// This bank is not part of slot 3...
			statusRegister = 0x98; // SR.7 = Ready, SR.4 = 1 (Program Error), SR.3 = 1 (no VPP)
			return;
		}
		if ((blink.getBlinkCom() & Blink.BM_COMVPPON) == 0) {
			// VPP pin is not enabled in slot 3 hardware...
			statusRegister = 0x98; // SR.7 = Ready, SR.4 = 1 (Program Error), SR.3 = 1 (no VPP)
			return;			
		}

		if ((b & getByte(addr)) == b) {
			// the byte can be blown (flash memory bit pattern can be changed from 1 to 0) 
			setByte(addr, b);
			
			// indicate success when application polls for read status cycles... 
			statusRegister = 0x80; // SR.7 = Ready, SR.4 = 0 (Program OK), SR.3 = 0 (VPP OK)
		} else {
			// the byte will break the rule that a 0 bit cannot be programmed 
			// to a 1, but only through a block erase.
			statusRegister = 0x90; // SR.7 = Ready, SR.4 = 1 (Program Error), SR.3 = 0 (VPP OK)
		}
	}

	/**
	 * Erase the Flash Memory Block which this bank is part of
	 * (An erase is only successful, if the card is in slot 3 AND Vpp is enabled.
	 */
	private void eraseBlockCommand() {
		// all known Intel Flash chips uses a 64K block architecture, so erase
		// the bottom bank of the current block and the next three following banks
		int bottomBankOfBlock = getBankNumber() & 0xFC;  // bottom bank of block

		if ((bottomBankOfBlock & 0xC0) != 0xC0 ) {
			// This bank is not part of slot 3...
			statusRegister = 0xA8; // SR.7 = Ready, SR.5 = 1 (Block Erase Error), SR.3 = 1 (no VPP)
			return;
		}
		if ((blink.getBlinkCom() & Blink.BM_COMVPPON) == 0) {
			// VPP pin is not enabled in slot hardware...
			statusRegister = 0xA8; // SR.7 = Ready, SR.5 = 1 (Block Erase Error), SR.3 = 1 (no VPP)
			return;			
		}

		for (int thisBank = bottomBankOfBlock; thisBank <= (bottomBankOfBlock+3); thisBank++) {
			IntelFlashBank b = (IntelFlashBank) memory.getBank(thisBank);
			b.eraseBank();
		} 
		
		// indicate success when application polls for read status cycles... 
		statusRegister = 0x80; // SR.7 = Ready, SR.5 = 0 (Block Erase OK), SR.4 = 0 (Program OK), SR.3 = 0 (VPP OK)
	}
	
	/**
	 * Validate if Flash card bank contents is not altered, 
	 * ie. only containing FF bytes.
	 *  
	 * @return true if all bytes in bank are FF
	 */
	public boolean isEmpty() {
		for (int b = 0; b < Bank.SIZE; b++) { 
			if (getByte(b) != 0xFF)
				return false;
		}
		
		return true;
	}	
}
