/*
 * FileArea.java
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
package net.sourceforge.z88.filecard;

import java.util.Random;

import net.sourceforge.z88.AmdFlashBank;
import net.sourceforge.z88.Bank;
import net.sourceforge.z88.EpromBank;
import net.sourceforge.z88.IntelFlashBank;
import net.sourceforge.z88.Memory;
import net.sourceforge.z88.datastructures.ApplicationCardHeader;
import net.sourceforge.z88.datastructures.SlotInfo;

/**
 * Management of files in File Area of inserted card in a slot.
 */
public class FileArea {
	/** reference to available memory hardware and functionality */
	private Memory memory = null;

	/** Utility Class to get slot information */
	private SlotInfo slotinfo = null;

	public FileArea() {
		memory = Memory.getInstance();
		slotinfo = SlotInfo.getInstance();
	}

	/**
	 * Create/reformat a file area in a specified slot. Return <b>true </b> if a
	 * file area was formatted/created. A file area can only be created on Eprom
	 * or Flash Cards.
	 * 
	 * The slot hardware will be evaluated and use the right sub type and
	 * position of the File Header. For Flash Cards, the header will be
	 * positioned on 64K boundaries, for conventional Eproms, the first
	 * available free 16K bank.
	 * 
	 * If a card is empty, all memory will be claimed for the file area. If a
	 * slot contains an application area, the file area will be placed below the
	 * application area, if there's room on the card. If a file header is found,
	 * only the file area will be re-formatted (header is left untouched).
	 * 
	 * The complete file area will be formatted with FF's from the bottom of the
	 * card up until the File Area header.
	 * 
	 * @param slotNo
	 * @return <b>true</b> if file area was formatted/created, otherwise
	 *         <b>false</b>
	 */
	public boolean createFileArea(final int slotNo) {
		int bottomBankNo = slotNo << 6;

		// get bottom bank of slot to determine card type...
		Bank bank = memory.getBank(bottomBankNo);
		if ((bank instanceof EpromBank == true)
				| (bank instanceof AmdFlashBank == true)
				| (bank instanceof IntelFlashBank == true)) {

			int fileHdrBank = slotinfo.getFileHeaderBank(slotNo);
			if (fileHdrBank != -1) {
				// file header found somewhere on card.
				// format file area from bottom bank, upwards until header...
				formatFileArea(bottomBankNo, fileHdrBank);
			} else {
				if (slotinfo.isApplicationCard(slotNo) == true) {
					ApplicationCardHeader appCrdHdr = new ApplicationCardHeader(slotNo);
					if (bank instanceof EpromBank == true) {
						if (memory.getCardSize(slotNo) == appCrdHdr.getAppAreaSize()) {
							return false; // there is no room for a file area on Eprom
						} else {
							// format file area just below application area...
							int topFileAreaBank = bottomBankNo +
									(memory.getCardSize(slotNo) - appCrdHdr.getAppAreaSize() - 1);
							formatFileArea(bottomBankNo, topFileAreaBank);
							createFileHeader(topFileAreaBank);
						}
					} else {
						// check if app area moves into bottom 64K sector... 
						if (memory.getCardSize(slotNo) - appCrdHdr.getAppAreaSize() < 4)
							return false; // there is no room for a file area on a flash card...
						
						// create file area of 64K sector size...
						int fileAreaSize = memory.getCardSize(slotNo) - appCrdHdr.getAppAreaSize();
						fileAreaSize -= (fileAreaSize % 4);
						int topFileAreaBank = bottomBankNo + fileAreaSize-1;

						formatFileArea(bottomBankNo, topFileAreaBank);
						createFileHeader(topFileAreaBank);						
					}
				} else {
					// empty card, write file header at top of card...
					formatFileArea(bottomBankNo, bottomBankNo
							+ memory.getCardSize(slotNo) - 1);
					createFileHeader(bottomBankNo + memory.getCardSize(slotNo) - 1);
				}
			}

			return true;
		} else {
			// A file area can't be created on a Ram card or in an empty slot...
			return false;
		}
	}

	/**
	 * Format file area with FF's, beginning from bottom of card, until bank of
	 * file header.
	 * 
	 * @param bottomBank
	 *            the starting bank of the file area
	 * @param topBank
	 *            the top bank of the file area including the header at $3FC0
	 */
	private void formatFileArea(int bottomBank, int topBank) {
		// format file area from bottom bank, upwards...
		do {
			for (int offset = 0; offset < 0x4000; offset++)
				memory.setByte(offset, bottomBank, 0xFF);
		} while (bottomBank++ < topBank);

		// top bank is only formatted until file header...
		for (int offset = 0; offset < 0x3FC0; offset++)
			memory.setByte(offset, bottomBank, 0xFF);
	}

	/**
	 * Write a file header in one of the external slots (1-3) at specified
	 * absolute bank ($40-$FF), offset $3FC0-$3FFF. A file header can only be
	 * written on Eprom or Flash Cards. <b>false </b> is returned if the slot
	 * was empty or contained a Ram card.
	 * 
	 * @param bankNo
	 * @return <b>true </b> if file header was created, otherwise <b>false </b>
	 */
	public static boolean createFileHeader(int bankNo) {
		Memory memory = Memory.getInstance();
		Random generator = new Random();
		int slotNo = (bankNo & 0xC0) >> 6;

		Bank bank = memory.getBank(bankNo);
		if ((bank instanceof EpromBank == true)
				| (bank instanceof AmdFlashBank == true)
				| (bank instanceof IntelFlashBank == true)) {

			for (int offset = 0x3FC0; offset < 0x3FF7; offset++)
				memory.setByte(offset, bankNo, 0);

			memory.setByte(0x3FF7, bankNo, 0x01);
			memory.setByte(0x3FF8, bankNo, generator.nextInt(255));
			memory.setByte(0x3FF9, bankNo, generator.nextInt(255));
			memory.setByte(0x3FFA, bankNo, generator.nextInt(255));
			memory.setByte(0x3FFB, bankNo, generator.nextInt(255));

			// size of file area is from bank of header downwards to bottom of
			// card.
			int fileAreaSize = (bankNo & (memory.getCardSize(slotNo) - 1)) + 1;
			memory.setByte(0x3FFC, bankNo, fileAreaSize);

			if ((bank instanceof EpromBank == true)
					& (memory.getCardSize(slotNo) == 2))
				memory.setByte(0x3FFD, bankNo, 0x7E); // a 32K Eprom was
													  // identified...
			else
				memory.setByte(0x3FFD, bankNo, 0x7C); // all other cards get $7C

			memory.setByte(0x3FFE, bankNo, 'o');
			memory.setByte(0x3FFF, bankNo, 'z');

			return true;
		} else {
			// header can't be written to Ram cards or empty slots..
			return false;
		}
	}
}