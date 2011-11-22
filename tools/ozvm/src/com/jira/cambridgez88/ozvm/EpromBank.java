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
 * @author <A HREF="mailto:gstrube@gmail.com">Gunther Strube</A>
 *
 */

package com.jira.cambridgez88.ozvm;

/** 
 * This class represents the 16Kb EPROM Bank. The characteristics of a EPROM bank is
 * chip memory that can be read at all times and only be written when the BLINK 
 * hardware has been properly setup for slot 3.
 */
public final class EpromBank extends Bank {
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
	 * @param ept the Eprom type (VPP32KB or VPP128KB) 
	 */
	public EpromBank(int ept) {		
		super(-1);		
		blink = Z88.getInstance().getBlink();
		eprType = ept;
		
		for (int i = 0; i < Bank.SIZE; i++) setByte(i, 0xFF); // empty Eprom contain FF's
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
	 * that points into the 16K address space of the Eprom bank.
	 * 
	 * Simple processor write byte has no effect on EPROM hardware.
	 * Writing (Eprom programming) requires Blink Hardware 
	 * management before a byte can successfully be written to
	 * the EPROM.
	 */
	public final void writeByte(final int addr, final int b) {
		int com = blink.getBlinkCom();
		int epr = blink.getBlinkEpr();
		
		if (((com & Blink.BM_COMLCDON) == 0) && ((com & Blink.BM_COMVPPON) != 0) && 
			((com & Blink.BM_COMPROGRAM) != 0) || ((com & Blink.BM_COMOVERP) != 0)) {
			// LCD turned off, VPP enabled and either programming or overprogramming enabled for slot 3...

			switch(eprType) {
				case VPP32KB:
					if (epr != 0x48) 
						return; // Epr setting doesn't fit; byte cannot be blown on 32K Eprom
					break;
					
				case VPP128KB:
					if (epr != 0x69) 
						return; // Epr setting doesn't fit; byte cannot be blown on 128K/256K Eprom
					break;
			}

			// blow byte according to Eprom hardware rule (Eprom memory bit pattern can be changed from 1 to 0)
			setByte(addr, b & getByte(addr));
		}
	}
	
	/**
	 * @return returns the type of Eprom (VPP32KB or VPP128KB) that this bank is part of.
	 */
	public int getEprType() {
		return eprType;
	}
	
	/**
	 * Validate if Eprom bank contents is not altered, 
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
}
