/*
 * Bank.java
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
 * $Id$  
 *
 */

package net.sourceforge.z88.tools;

import java.util.zip.CRC32;

/** 
 * This class represents the 16Kb Bank architecture. The characteristics of a bank can be 
 * that it's part of a Ram Card (external Card or internal RAM chip on motherboard), 
 * a Rom (internal chip on motherboard), an Eprom (internal chip on motherboard or as
 * part of an external Card) or a Flash Card.
 * 
 * On the Z88, the 64K is split into 4 sections of 16K segments. Any of the 256 addressable
 * 16K banks in the Z88 4Mb memory model can be bound into the address space of the Z80 
 * processor.
 * 
 * Please refer to hardware section of the Developer's Notes for a more detailed 
 * description.  
 */
public abstract class Bank {
	/** A bank contains 16384 bytes */
	public static final int SIZE = 16384; 

	private int bankNo;
	private byte bankMem[];
	
	public Bank() {
		this.bankNo = -1; // This bank is not assigned to the 4Mb memory model
	}

	/**
	 * Assign the bank to the 4Mb memory model.
	 * 
	 * @param bankNo
	 */	
	public Bank(int bankNo) {
		this.bankNo = bankNo;
		this.bankMem = new byte[Bank.SIZE];  // contents are default 0
	}
	
	/**
	 * Get byte from bank, always. 
	 * 
	 * NB: Internal method.
	 * This method overrides all memory characteristics as defined
	 * by the Blink hardware and various memory chip hardware. 
	 * 
	 * @param addr is a 16bit word that points into the 16K address space of the bank.
	 */
	public int getByte(final int addr) {
		return bankMem[addr & (Bank.SIZE-1)] & 0xFF;
	}
	
	/**
	 * Write byte to bank, always. 
	 * 
	 * NB: Internal method:
	 * This method overrides all memory characteristics as defined
	 * by the Blink hardware and various memory chip hardware. 
	 * 
	 * @param addr is a 16bit word that points into the 16K address space of the bank.
	 * @param b is the byte to be "set" at specific address
	 * 
	 */
	public void setByte(final int addr, final int b) {
		bankMem[addr & (Bank.SIZE-1)] = (byte) (b & 0xFF);
	}
	
	/**
	 * Load bytes from buffer array of block.length to bank offset, onwards.
	 * Naturally, loading is only allowed inside 16Kb boundary.
	 */
	public final void loadBytes(byte[] block, int offset) {
		offset %= Bank.SIZE; // stay within boundary..
		int length =
			(offset + block.length) > Bank.SIZE
				? Bank.SIZE - offset
				: block.length;

		int bufidx = 0;
		while (length-- > 0)
			bankMem[offset++] = (byte) (block[bufidx++] & 0xFF);
	}

	/**
	 * Dump bytes from bank into a byte array from bank offset, length.
	 * Parameters must stay within 16Kb boundary.
	 */
	public final byte[] dumpBytes(int offset, int length) {
		byte dump[] = new byte[length];
		int bufidx = 0;
		
		while (length-- > 0)
			dump[bufidx++] = bankMem[offset++];
		
		return dump;
	}
	
	/**
	 * Calculate a CRC32 of the bank contents.
	 * 
	 * @return
	 */
	public long getCRC32() {
		CRC32 crc = new CRC32();  		
		crc.update(bankMem);
		
		return crc.getValue();
	}
	
	/**
	 * Search for string pattern in bank.
	 * If found, return offset to start of found string, otherwise -1.
	 * 
	 * @param str
	 * @return offset of found string
	 */
	public int findString(String str) {
		byte strPattern[] = str.getBytes();
		boolean strFound = false; 
		
		for (int b=0; b<bankMem.length; b++) {
			if (bankMem[b] == strPattern[0] & (b+strPattern.length < bankMem.length )) {
				strFound = true;
				
				for (int i=1; i<strPattern.length; i++) {
					if (bankMem[b+i] != strPattern[i]) {
						strFound = false;
						break;
					}
				}
			}
			
			if (strFound == true)
				return b;
		}
		
		return -1;
	}
	
	
	/**
	 * Validate if card bank contents is not altered, 
	 * ie. only containing FF bytes for Eprom/Rom/Flash cards or
	 * 00 bytes for RAM cards.
	 *  
	 * @return true if all bytes in bank are 'empty'
	 */
	public abstract boolean isEmpty();
	
	/**
	 * @return the absolute bank number (0-255) where this bank is located in the 4Mb memory model
	 */
	public final int getBankNumber() {
		return bankNo;
	}
	
	/**
	 * Define the bank number (0-255) where this bank is located in the 4Mb memory model
	 */
	public final void setBankNumber(int bankNo) {
		this.bankNo = bankNo & 0xFF;
	}

	public int getBankNo() {
		return bankNo;
	}

	public void setBankNo(int bankNo) {
		this.bankNo = bankNo;
	}
} /* Bank */
