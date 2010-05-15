/*
 * ApplicationCardheader.java
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
import net.sourceforge.z88.Z88;

/**
 * Get Application Card Header Information for specified slot.
 */
public class ApplicationCardHeader {
	/** reference to available memory hardware and functionality */
	private Memory memory;

	/** Utility Class to get slot information */
	private SlotInfo slotinfo;

	private int cardId;
	private int countryCode;
	private int appAreaSize;

	public ApplicationCardHeader(int slotNo) {

		memory = Z88.getInstance().getMemory();
		slotinfo = SlotInfo.getInstance();

		if ((slotinfo.isOzRom(slotNo) == true) | (slotinfo.isApplicationCard(slotNo) == true)) {
			// top bank of card
			// !! check for slot 0
			int bankNo = ((slotNo & 3) << 6) | 0x3f;

			cardId = (memory.getByte(0x3FF9, bankNo) << 8) | memory.getByte(0x3FF8, bankNo);
			countryCode = memory.getByte(0x3FFA, bankNo);
			appAreaSize = memory.getByte(0x3FFC, bankNo);
			System.out.println("App/OZ hdr (bank " + bankNo + ") for slot " + slotNo + ": area size = " + appAreaSize);
		}
	}

	/**
	 * @return Returns the appAreaSize (0 if no Header was found).
	 */
	public int getAppAreaSize() {
		return appAreaSize;
	}

	/**
	 * @return Returns the cardId (0 if no Header was found).
	 */
	public int getCardId() {
		return cardId;
	}

	/**
	 * @return Returns the countryCode (0 if no Header was found).
	 */
	public int getCountryCode() {
		return countryCode;
	}
}
