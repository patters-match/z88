/*
 * RomBank.java
 * This file is part of MakeApp.
 *
 * MakeApp is free software; you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation;
 * either version 2, or (at your option) any later version.
 * MakeApp is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 * without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * You should have received a copy of the GNU General Public License along with MakeApp;
 * see the file COPYING. If not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *
 * @author <A HREF="mailto:gbs@users.sourceforge.net">Gunther Strube</A>
 *
 */

package net.sourceforge.z88.tools;

/**
 * This class represents the 16Kb ROM Bank. The characteristics of a ROM bank is
 * chip memory that can be read at all times and never written (Read Only Memory).
 */
public class RomBank extends Bank {

	private String bankFileName;

	public RomBank() {
		super(-1);

		initBank();
	}

	public RomBank(int BankNo) {
		super(BankNo);

		initBank();
	}

	/**
	 * Initialize empty bank with FF's
	 *
	 */
	private void initBank() {
		for (int b = 0; b < Bank.SIZE; b++)
			setByte(b, 0xFF);
	}

	/**
	 * Validate if bank contents is not altered,
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

	public String getBankFileName() {
		return bankFileName;
	}

	/**
	 * Name the filename of the bank according to RomCombiner and
	 * Z88 Card architecture rules (top bank of card is identified as 63,
	 * which is assigned to filename extension).
	 *
	 * @param fileName
	 * @param bankNo
	 */
	public void setBankFileName(String fileName) {
		if (fileName.indexOf(".") > 0) {
			bankFileName = fileName.substring(0, fileName.indexOf("."));
			bankFileName = bankFileName + "." + Integer.toString(getBankNo());
		} else {
			bankFileName = fileName + "." + Integer.toString(getBankNo());
		}
	}

	/**
	 * Check if this bank contains an OZ ROM header.
	 *
	 * @return
	 */
	public boolean containsOzRomHeader() {
		if ( getByte(0x3FFB) == 0x81 & getByte(0x3FFE) == 'O' & getByte(0x3FFF) == 'Z')
			return true;
		else
			return false;
	}

	/**
	 * Check if this bank contains an Application card header.
	 *
	 * @return
	 */
	public boolean containsAppHeader() {
		if ( getByte(0x3FFB) == 0x80 & getByte(0x3FFE) == 'O' & getByte(0x3FFF) == 'Z')
			return true;
		else
			return false;
	}

	/**
	 * Return offset to first DOR in 16K application bank
	 *
	 * @return -1, if no Application card header was recognized
	 */
	public int getAppDorOffset() {
		if ( containsAppHeader() == false )
			return -1;
		else {
			// return bank offset to DOR
			return ((getByte(0x3fc7) << 8) & 0x3f00) | (getByte(0x3fc6) & 0xff);
		}
	}
}
