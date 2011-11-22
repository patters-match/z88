/*
 * FileAreaHeader.java
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
 * @author <A HREF="mailto:gstrube@gmail.com">Gunther Strube</A>
 *
 */
package com.jira.cambridgez88.ozvm.datastructures;

import com.jira.cambridgez88.ozvm.Memory;
import com.jira.cambridgez88.ozvm.Z88;

/**
 * Get File Area Header Information at absolute bank, offset $3FC0-$3FFF.
 * This class simply reads the available contents of memory, passively.
 * 
 * Please use SlotInfo.isFileHeader(bankNo) to ensure that a File header exists
 * before using this functionality. 
 */
public class FileAreaHeader {
	/** reference to available memory hardware and functionality */
	private Memory memory;
	
	private int randomId;
	private int size;
	private int subtype;
	private int bankHdr;
	
	/**
	 * Read File Header memory content of absolute bankNo, offset $3FC0 - $3FFF.
	 *  
	 * @param bankNo
	 */
	public FileAreaHeader(int bankNo) {
		memory = Z88.getInstance().getMemory();
					
		randomId = (memory.getByte(0x3FF8, bankNo) << 24) | 
					memory.getByte(0x3FF9, bankNo) << 16 |
					memory.getByte(0x3FFA, bankNo) << 8 | 
					memory.getByte(0x3FFB, bankNo);
		
		size = memory.getByte(0x3FFC, bankNo);  // Size of file area in 16K banks
		subtype = memory.getByte(0x3FFD, bankNo);
		bankHdr = bankNo;
	}
	
	/**
	 * @return the random ID of the File Header.
	 */
	public int getRandomId() {
		return randomId;
	}
	
	/**
	 * @return the sub type of the card ($7E for 32K cards, $7C for 128K or larger).
	 */
	public int getSubtype() {
		return subtype;
	}
	
	/**
	 * @return the size of the file area in 16K banks.
	 */
	public int getSize() {
		return size;
	}
	
	/**
	 * @return the (absolute) bank number of the file area header.
	 */
	public int getBankNo() {
		return bankHdr;
	}

}
