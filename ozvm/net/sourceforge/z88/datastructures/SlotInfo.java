/*
 * SlotInfo.java
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

package net.sourceforge.z88.datastructures;

import net.sourceforge.z88.AmdFlashBank;
import net.sourceforge.z88.Bank;
import net.sourceforge.z88.EpromBank;
import net.sourceforge.z88.IntelFlashBank;
import net.sourceforge.z88.Memory;

/**
 * Information about what is available in a specified slot;
 * ROM's, Application Cards or File Cards - their contents returned
 * in various formats.
 */
public class SlotInfo {
	
	private static final class singletonContainer {
		static final SlotInfo singleton = new SlotInfo();  
	}
	
	public static SlotInfo getInstance() {
		return singletonContainer.singleton;
	}
	
	/** reference to available memory hardware and functionality */
	private Memory memory = null;
		
	/**
	 * Initialise slot information with getting access to
	 * the Z88 memory model
	 */
	private SlotInfo() {
		memory = Memory.getInstance();
	}

	/**
	 * Check if specified slot contains an Application Card ('OZ' watermark).
	 * 
	 * @return true if Application Card is available in slot, otherwise false
	 */
	public boolean isApplicationCard(final int slotNo) {
		int bankNo;
		
		// point to watermark in top bank of slot, offset 0x3Fxx
		if (slotNo == 0) 
			bankNo = bankNo = 0x1F;	// top bank of slot 0 512K ROM Area
		else
			bankNo = ((slotNo & 3) << 6) | 0x3F;
		
		if ( (memory.getByte(0x3FFB, bankNo) == 0x80 | memory.getByte(0x3FFB, bankNo) == 0x81) &
			memory.getByte(0x3FFE, bankNo) == 'O' & memory.getByte(0x3FFF, bankNo) == 'Z')
			return true;
		else
			return false;
	}

	/**
	 * Check if there's a File header available at absolute bank, offset $3FC0-$3FFF.
	 * 
	 * @param bankNo a bank number defining any bank in the external slots ($40 - $FF).
	 * @return true, if a file header was found, otherwise false. 
	 */
	public boolean isFileHeader(final int bankNo) {
		if (memory.getByte(0x3FF7, (bankNo & 0xFF)) == 0x01 &
			memory.getByte(0x3FFE, (bankNo & 0xFF)) == 'o' & 
			memory.getByte(0x3FFF, (bankNo & 0xFF)) == 'z')
			return true;
		else
			return false;
	}

	/**
	 * Return absolute bank number (part of specified slot) of found 
	 * File Header (placed at offset $3FC0-3FFF in bank) in inserted Eprom 
	 * or Flash Card of specified slot.
	 *  
	 * @param slotNo (1-3)
	 * @return bank number of found file header in slot, or -1 if no file header was found.
	 */
	public int getFileHeader(final int slotNo) {
		// start scan at bottom of card, then upwards...
		int bankNo = ((slotNo & 3) << 6) ; 
		Bank bank = memory.getBank(bankNo);
		
		if ( (bank instanceof EpromBank == true) | 
				(bank instanceof AmdFlashBank == true) |
				(bank instanceof IntelFlashBank == true) ) {
			
			for( int topBank=bankNo | (memory.getCardSize(slotNo)-1); 
				bankNo <= topBank; bankNo++) {
				if (isFileHeader(bankNo) == true) return bankNo;
			}
			return -1;	// reached top of bank, and no file header was found
		} else {
			return -1;	// File area not found in Ram cards or empty slots..
		}		
	}
	
	/**
	 * Check if specified slot contains a File Card ('oz' watermark at top of card).
	 * 
	 * @return true if Application card is available in slot, otherwise false
	 */
	public boolean isFileCard(final int slotNo) {
		// point to watermark in top bank of slot, offset 0x3Fxx
		int bankNo = ((slotNo & 3) << 6) | 0x3F;
		
		return isFileHeader(bankNo);
	}
}
