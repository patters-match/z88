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
			memory.getByte(0x3FFE, bankNo) == 'O' &
			memory.getByte(0x3FFF, bankNo) == 'Z')
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
		
		if (memory.getByte(0x3FF7, bankNo) == 0x01 &
			memory.getByte(0x3FFE, bankNo) == 'o' &
			memory.getByte(0x3FFF, bankNo) == 'z')
			return true;
		else
			return false;
	}
}
