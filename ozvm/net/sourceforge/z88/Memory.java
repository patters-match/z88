/*
 * Memory.java
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

/**
 * This class represents the 4Mb addressable memory model in the Z88, comprised 
 * of 16K memory blocks or banks of memory. The characteristics of a bank can be 
 * that it's part of a Ram card (or the internal memory of the Z88), 
 * an Eprom card or a 1MB Flash Card.
 * 
 * Further, the memory I/O characteristics of the bank can change if it
 * is located inside slot 3 and Eprom Programming is enabled in Blink
 * (the VPP Pin is enabled on the chip that is inserted in slot 3):
 * Depending on the bank type, all memory I/O will behave as the specified
 * hardware (U/V Eproms or Flash Card) when VPP is set (by the Blink).
 * 
 * Databus access to bank is 8 bits, Z80 hardware. Therefore, the Blink
 * is responsible for reading 16bit values and getting cross bank boundary
 * words (lower byte at BankX, offset 3FFFh and high byte at BankY, offset 0000h).
 */
public final class Memory {
	/** A bank contains 16384 bytes */
	public static final int BANKSIZE = 16384; 
	
	/**
	 * The Z88 memory organisation.
	 * Array for 256 x 16K banks = 4Mb memory
	 */
	private Bank memory[];

	/**
	 * Null bank. This is used in for unassigned banks,
	 * ie. when a card slot is empty in the Z88
	 * The contents of this bank contains 0xFF and is
	 * write-protected (just as an empty bank in an Eprom).
	 */
	private VoidBank nullBank;
	
	public Memory() {
		memory = new Bank[256]; // The Z88 memory addresses 256 banks = 4MB!		

		nullBank = new VoidBank();
		for (int bank = 0; bank < memory.length; bank++)
			memory[bank] = nullBank;
	}
	
	/**
	 * Get Bank, referenced by it's number [0-255] in the BLINK memory model
	 *
	 * @return Bank
	 */
	public final Bank getBank(final int bankNo) {
		return memory[bankNo & 0xFF];
	}

	/**
	 * Install Bank entity into memory model (0-255).
	 *
	 * @param bank
	 * @param bankNo
	 */
	public final void setBank(final Bank bank, final int bankNo) {
		bank.setBankNumber(bankNo);
		memory[bankNo & 0xFF] = bank;
	}

	/**
	 * Insert Card (RAM/ROM/EPROM) into Z88 memory system.
	 * Size is in modulus 16Kb.
	 * Slot 0 (1Mb): banks 00 - 1F (ROM, 512Kb), banks 20 - 3F (RAM, 512Kb)
	 * Slot 1 (1Mb): banks 40 - 7F (RAM or EPROM)
	 * Slot 2 (1Mb): banks 80 - BF (RAM or EPROM)
	 * Slot 3 (1Mb): banks C0 - FF (RAM or EPROM)
	 *
	 * @param card
	 * @param slot
	 */
	public void insertCard(Bank card[], int slot) {
		int totalSlotBanks, slotBank, curBank;

		if (slot == 0) {
			// Define bottom bank for ROM/RAM
			slotBank = (card[0] instanceof RamBank) ? 0x20: 0x00;
			totalSlotBanks = 32; // inserting RAM or ROM can be max 32 * 16Kb = 512Kb
		} else {
			slotBank = slot << 6; // convert slot number to bottom bank of slot
			totalSlotBanks = 64;  // slots 1 - 3 have 64 * 16Kb = 1Mb address space
		}

		for (curBank = 0; curBank < card.length; curBank++) {
			setBank(card[curBank], slotBank++);
			// "insert" 16Kb bank into Z88 memory
			--totalSlotBanks;
		}

		// - the bottom of the slot has been loaded with the Card.
		// Now, we need to fill the 1MB address space in the slot with the card.
		// Note, that most cards and the internal memory do not exploit
		// the full lMB addressing range, but only decode the lower address lines.
		// This means that memory will appear more than once within the lMB range.
		// The memory of a 32K card in slot 1 would appear at banks $40 and $41,
		// $42 and $43, ..., $7E and $7F. Alternatively a 128K EPROM in slot 3 would
		// appear at $C0 to $C7, $C8 to $CF, ..., $F8 to $FF.
		// This way of addressing is assumed by the system.
		// Note that the lowest and highest bank in an EPROM can always be addressed
		// by looking at the bank at the bottom of the 1MB address range and the bank
		// at the top respectively.
		while (totalSlotBanks > 0) {
			for (curBank = 0; curBank < card.length; curBank++) {
				memory[slotBank++] = card[curBank];
				// "shadow" card banks into remaining slot
				--totalSlotBanks;
			}
		}
	}

	/**
	 * Remove inserted card, ie. null'ify the banks for the specified slot.
	 *   
	 * @param slot (1-3)
	 */
	public void removeCard(int slot) {		
	}
	
	/**
	 * Check if slot is empty (ie. no cards inserted)
	 *
	 * @param slotNo
	 * @return true, if slot is empty
	 */
	public final boolean isSlotEmpty(final int slotNo) {
		// convert slot number to top bank number of specified slot
		// if top bank of slot is of type NullBank, then we know it's empty...
		return memory[(((slotNo & 3) << 6) | 0x3F)] == nullBank;
	}

	/**
	 * Scan available slots for Ram Cards, and reset them..
	 */
	public void resetRam() {
		for (int bankNo = 0; bankNo < memory.length; bankNo++) {
			if ( memory[bankNo] instanceof RamBank == true) {
				// reset ...
				for (int bankOffset = 0; bankOffset < Memory.BANKSIZE; bankOffset++) {
					memory[bankNo].setByte(bankOffset, 0);
				}
			}
		}
	}	
} /* Memory */
