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

package net.sourceforge.z88;

/**
 * Information about what is available in a specified slot;
 * ROM's, Application Cards or File Cards - their contents returned
 * in various formats.
 */
public class SlotInfo {
	
	/** reference to available memory hardware and functionality */
	private Memory memory = null;
	
	/**
	 * Initialise slot information with getting access to
	 * the Z88 memory model
	 */
	public SlotInfo(final Memory memory) {
		this.memory = memory;
	}

	/**
	 * Return the size of inserted Application- or File Card in 16K banks.
	 * If no card is available in specified slot, -1 is returned.
	 * 
	 * @return number of 16K banks in inserted Card
	 */
	public int getCardSize(final int slotno) {		
		if (isApplicationCard(slotno) == true || isFileCard(slotno) == true)
			// byte at 0x3FFC in top bank of slot defines total banks in card...
			return memory.getBank(((slotno & 3) << 6) | 0x3F).getByte(0x3FFC); 
		else 
			// no card available in slot...
			return -1;
	}

	/**
	 * Check if specified slot contains an Application Card ('OZ' watermark).
	 * 
	 * @return true if Application Card is available in slot, otherwise false
	 */
	public boolean isApplicationCard(final int slotno) {
		// point to watermark in top bank of slot, offset 0x3Fxx
		int bankNo = ((slotno & 3) << 6) | 0x3F;
		
		if (memory.getBank(bankNo).getByte(0x3FFB) == 0x80 &
			memory.getBank(bankNo).getByte(0x3FFE) == 'O' &
			memory.getBank(bankNo).getByte(0x3FFF) == 'Z')
			return true;
		else
			return false;
	}

	/**
	 * Check if specified slot contains a File Card ('oz' watermark).
	 * 
	 * @return true if Application card is available in slot, otherwise false
	 */
	public boolean isFileCard(final int slotno) {
		// point to watermark in top bank of slot, offset 0x3Fxx
		int bankNo = ((slotno & 3) << 6) | 0x3F;
		
		if (memory.getBank(bankNo).getByte(0x3FF7) == 0x01 &
			memory.getBank(bankNo).getByte(0x3FFE) == 'o' &
			memory.getBank(bankNo).getByte(0x3FFF) == 'z')
			return true;
		else
			return false;
	}

	/**
	 * Check if specified slot is empty;
	 * no Application, File or Ram Cards available.
	 * 
	 * @return true if slot is empty, otherwise false
	 */
	public boolean isSlotEmpty(final int slotno) {		
		return memory.isSlotEmpty(slotno);
	}
}
