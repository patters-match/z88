/*
 * RomBank.java
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
 * This class represents the 16Kb ROM Bank. The characteristics of a ROM bank is
 * chip memory that can be read at all times and never written (Read Only Memory). 
 */
public final class RomBank extends Bank {
	
	/**
	 * Assign the Rom bank to the 4Mb memory model.
	 * 
	 * @param bankNo
	 */
	public RomBank() {		
		super(-1);		

		for (int i = 0; i < Bank.SIZE-1; i++) setByte(i, 0xFF); // empty Rom contain FF's
	}

	/**
	 * Read byte from Rom bank. <addr> is a 16bit word that points into 
	 * the 16K address space of the bank.
	 */
	public final int readByte(final int addr) {
		return getByte(addr);
	}

	/**
	 * Write byte <b> to Rom bank. <addr> is a 16bit word
	 * that points into the 16K address space of the RAM bank.
	 * 
	 * Writing to Rom has no effect.
	 */
	public final void writeByte(final int addr, final int b) {
		// No effect
	}
}
