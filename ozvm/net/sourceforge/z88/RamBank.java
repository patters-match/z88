/*
 * RamBank.java
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
 * This class represents the 16Kb RAM Bank. The characteristics of a RAM bank is
 * that RAM chip memory can be read and written directly by the processor.
 */
public class RamBank extends Bank {
	/**
	 * Assign the Ram bank to the 4Mb memory model.
	 * 
	 * @param bankNo
	 */
	public RamBank() {
		super(-1);		
	}

	/**
	 * Read byte from RAM bank. <addr> is a 16bit word that points into 
	 * the 16K address space of the bank.
	 */
	public final int readByte(final int addr) {
		return getByte(addr);
	}

	/**
	 * Write byte <b> to RAM bank. <addr> is a 16bit word
	 * that points into the 16K address space of the RAM bank.
	 */
	public final void writeByte(final int addr, final int b) {
		setByte(addr, b);
	}
}
