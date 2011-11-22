/*
 * StmFlashBank.java
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
 * @author <A HREF="mailto:gstrube@gmail.com">Gunther Strube</A>
 *
 */

package com.jira.cambridgez88.ozvm;

/**
 * This class represents the 16Kb Generic Flash Memory Bank on an ST Microelectronics
 * 29FxxxB/D series chip, which is compatible with AMD 29FxxxB series chips.
 *
 * The characteristics of a Flash Memory bank is chip memory that can be read at
 * all times and only be written (and erased) using a combination of STM Flash
 * command sequences (write byte to address cycles), in ALL available slots on
 * the Z88.
 *
 * The emulation of the STM Flash Memory inherits the AMD implementation of 
 * the chip. Please refer to GenericAmdFlashBank class for more information.
 */
public class StmFlashBank extends GenericAmdFlashBank {

	/** Device Code for 128Kb memory, 8 x 16K erasable sectors, 8 x 16K banks */
	public static final int ST29F010B = 0x20;

	/** Device Code for 512Kb memory, 8 x 64K erasable sectors, 32 x 16K banks */
	public static final int ST29F040B = 0xE2;

	/** Device Code for 1Mb memory, 16 x 64K erasable sectors, 64 x 16K banks */
	public static final int ST29F080D = 0xF1;

	/** Manufacturer Code for ST29F0xxx Flash Memory chips */
	public static final int MANUFACTURERCODE = 0x20;

	/**
	 * The actual Flash Memory Device Code of this bank instance
	 * (defined as ST29F010B, ST29F040B or ST29F080D).
	 */
	private int deviceCode;

	/**
	 * Constructor.
	 * Assign the Flash Memory bank to the 4Mb memory model.
	 *
	 * @param dc the Flash Memory Device Code (ST29F010B, ST29F040B or ST29F080D)
	 */
	public StmFlashBank(int dc) {
		super();

		deviceCode = dc;
	}

	/**
	 * @return the Flash Memory Device Code
	 * (ST29F010B, ST29F040B or ST29F080D) which this bank is part of.
	 */
	public final int getDeviceCode() {
		return deviceCode;
	}

	/**
	 * @return the Flash Memory Manufacturer Code
	 */
	public final int getManufacturerCode() {
		return MANUFACTURERCODE;
	}
}
