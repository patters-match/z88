/*
 * EpromBank.java
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
 * This class represents the 16Kb EPROM Bank. The characteristics of a EPROM bank is
 * chip memory that can be read at all times and only be written when the BLINK 
 * hardware has been properly setup for slot 3.
 */
public class EpromBank extends Bank {
	/** The Blink hardware is capable of blowing a particular type of Eprom chip that is used in 32K Eprom Cards */
	public static final int VPP32KB = 0x7E;

	/** The Blink hardware is capable of blowing a particular type of Eprom chip that is used in 128K/256K Eprom Cards */
	public static final int VPP128KB = 0x7C;
	
	/** Access to the Z88 slot 3 hardware & memory model */
	private Blink blink;
	
	/** The actual Eprom type of this bank instance */
	private int eprType;
	
	/**
	 * Assign the Eprom bank to the 4Mb memory model.
	 * 
	 * @param b the Z88 Blink Hardware 
	 * @param bankNo the bank number (0-255) which this bank is assigned to
	 * @param ept the Eprom type (VPP32KB or VPP128KB) 
	 */
	public EpromBank(Blink b, int bankNo, int ept) {		
		super(bankNo);		
		blink = b;
		eprType = ept;
		
		for (int i = 0; i < Memory.BANKSIZE-1; i++) setByte(i, 0xFF); // empty Eprom contain FF's
	}

	/**
	 * Read byte from EPROM bank. <addr> is a 16bit word that points into 
	 * the 16K address space of the bank.
	 */
	public final int readByte(final int addr) {
		return getByte(addr);
	}

	/**
	 * Write byte <b> to EPROM bank. <addr> is a 16bit word
	 * that points into the 16K address space of the RAM bank.
	 * 
	 * Simple processor write byte has no effect on EPROM hardware.
	 * Writing (Eprom programming) requires Blink Hardware 
	 * management before a byte can successfully be written to
	 * the EPROM.
	 */
	public final void writeByte(final int addr, final int b) {
		// TODO Implement slot 3 hardware logic...
	}
	
	/**
	 * @return returns the type of Eprom (VPP32KB or VPP128KB) that this bank is part of.
	 */
	public int getEprType() {
		return eprType;
	}
}
