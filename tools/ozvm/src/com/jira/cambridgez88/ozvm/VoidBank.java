/*
 * VoidBank.java
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

package net.sourceforge.z88;

import java.util.Random;

/** 
 * This class represents 16Kb addressable nothingness! It is the emulation of 
 * the Blink hardware in an empty slot. Reading a byte from an empty slot returns
 * random data. Writing a byte to an empty slot has no effect.
 */
public final class VoidBank extends Bank {
	private Random generator;

	public VoidBank() {
		super();		
		
		generator = new Random();
	}

	/**
	 * Read byte from RAM bank. <addr> is a 16bit word that points into 
	 * the 16K address space of the bank.
	 */
	public final int readByte(final int addr) {
		return this.getByte(addr);
	}

	/**
	 * Write byte <b> to <addr> that is a 16bit word
	 * that points into the 16K address space of an empty slot.
	 * 
	 * The CPU write cycle has no effect.
	 */
	public void writeByte(final int addr, final int b) {
		// no effect
	}

	/**
	 * Reading a byte to an empty slot returns random 8bit data. 
	 * 
	 * @param addr is a 16bit word that points into the 16K address space of the bank.
	 * 
	 */
	public int getByte(final int addr) {
	    return generator.nextInt(255); // return random 8bit data		
	}
	
	/**
	 * Writing a byte to an empty slot has no effect. 
	 * 
	 * @param addr is a 16bit word that points into the 16K address space of the bank.
	 * @param b is the byte to be "set" at specific address (here, no effect)
	 */
	public void setByte(final int addr, final int b) {
		// no effect
	}

	/**
	 * A void bank is per definition empty (it contains random data from databus)
	 */
	public boolean isEmpty() {
		return true;
	}
}
