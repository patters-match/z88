/*
 * IntelFlashBank.java
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
 * This class represents the 16Kb Flash Memory Bank on an INTEL I28Fxxxx chip. 
 * The characteristics of a Flash Memory bank is chip memory that can be read at 
 * all times and only be written (and erased) using BLINK hardware in slot 3 in 
 * combination with Intel Flash Memory command sequenses (write byte to address cycles).
 */
public class IntelFlashBank extends Bank {
	
	/** Device Code for 512Kb memory, 8 x 64K erasable sectors, 32 x 16K banks */
	public static final int I28F004S5 = 0xA7;

	/** Device Code for 1Mb memory, 16 x 64K erasable sectors, 64 x 16K banks */
	public static final int I28F008S5 = 0xA6;

	/** Manufacturer Code for I28Fxxxx FlashFile Memory chips */
	public static final int MANUFACTURERCODE = 0x89;
	
	/** Access to the Z88 slot 3 hardware & memory model */
	private Blink blink;
	
	/** The actual Flash Memory type of this bank instance */
	private int flashType;
	
	/**
	 * Assign the Flash Memory bank to the 4Mb memory model.
	 * 
	 * @param b the Z88 Blink Hardware 
	 * @param bankNo the bank number (0-255) which this bank is assigned to
	 * @param flt the Flash Memory type (I28F004S5 or I28F008S5) 
	 */
	public IntelFlashBank(Blink b, int flt) {		
		super(-1);		
		blink = b;
		flashType = flt;
		
		for (int i = 0; i < Memory.BANKSIZE-1; i++) setByte(i, 0xFF); // empty Flash Memory contain FF's
	}

	/**
	 * Read byte from Flash Memory bank. <addr> is a 16bit word that points into 
	 * the 16K address space of the bank.
	 */
	public final int readByte(final int addr) {
		// TODO Implement Flash Memory logic
		return getByte(addr);
	}

	/**
	 * Write byte <b> to Flash Memory bank. <addr> is a 16bit word
	 * that points into the 16K address space of the RAM bank.
	 * 
	 * Z80 processor write byte affects the behaviour of the Intel 
	 * FlashFile Memory chip. In combination with Slot 3 Blink Enable
	 * VPP and command sequenses using processor write cycles, the 
	 * FlashFile Memory chip can be programmed with data and get 
	 * erased again.
	 */
	public final void writeByte(final int addr, final int b) {
		// TODO Implement Flash Memory logic
	}
	
	/**
	 * @return returns the type of Flash Memory (I28F004S5 or I28F008S5) that this bank is part of.
	 */
	public int getFlashType() {
		return flashType;
	}
}
