/*
 * Bank.java
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

import com.jhe.hexed.JHexEditor;
import java.awt.event.WindowAdapter;
import java.util.zip.CRC32;
import javax.swing.JFrame;

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
public abstract class Bank extends WindowAdapter {
	/** A bank contains 16384 bytes */
	public static final int SIZE = 16384;

	private int bankNo;
	private int bankMem[];
    private boolean breakPoints[];
    private JFrame win;

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
		this.bankMem = new int[Bank.SIZE];  // contents are default 0        
        this.breakPoints = new boolean[Bank.SIZE]; // by default, no breakpoints are defined (false)
	}

	/**
	 * Read byte from bank. <addr> is a 16bit word that points into
	 * the 16K address space of the bank.<p>
	 * Behavior is dependent on hardware characteristics (RAM, EPROM, FLASH).
	 */
	public abstract int readByte(final int addr);

	/**
	 * Write byte to bank. <addr> is a 16bit word
	 * that points into the 16K address space of the bank.<p>
	 * Behavior is dependent on hardware characteristics (RAM, EPROM, FLASH).
	 */
	public abstract void writeByte(final int addr, final int b);

	/**
	 * Validate if card bank contents is not altered,
	 * ie. only containing FF bytes for Eprom/Rom/Flash cards or
	 * 00 bytes for RAM cards.
	 *
	 * @return true if all bytes in bank are 'empty'
	 */
	public abstract boolean isEmpty();

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
		return bankMem[addr & (Bank.SIZE-1)];
	}

	/**
	 * Check if breakpoint is defined for specified address
	 *
	 * @param addr is a 16bit word that points into the 16K address space of the bank.
	 * @return true if breakpoint is defined, otherwise false
	 */
	public boolean isBreakpoint(final int addr) {
		return breakPoints[addr & (Bank.SIZE-1)];
	}

	/**
	 * Set breakpoint for specified address
	 *
	 * @param addr is a 16bit word that points into the 16K address space of the bank.
	 */
	public void setBreakpoint(final int addr) {
		breakPoints[addr & (Bank.SIZE-1)] = true;
	}

	/**
	 * Clear breakpoint for specified address
	 *
	 * @param addr is a 16bit word that points into the 16K address space of the bank.
	 */
    public void clearBreakpoint(final int addr) {
		breakPoints[addr & (Bank.SIZE-1)] = false;
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
		bankMem[addr & (Bank.SIZE-1)] = b & 0xFF;
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
			bankMem[offset++] = block[bufidx++] & 0xFF;
	}

	/**
	 * Dump bytes from bank into a byte array from bank offset, length.
	 * Parameters must stay within 16Kb boundary.
	 */
	public final byte[] dumpBytes(int offset, int length) {
		byte dump[] = new byte[length];
		int bufidx = 0;

		while (length-- > 0)
			dump[bufidx++] = (byte) (bankMem[offset++] & 0xFF);

		return dump;
	}

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

	/**
	 * Calculate a CRC32 of the bank contents.
	 *
	 * @return
	 */
	public long getCRC32() {
                byte tempBank[] = dumpBytes(0, SIZE);
		CRC32 crc = new CRC32();
		crc.update(tempBank);

		return crc.getValue();
	}
        
        public void editMemory() {
            win=new JFrame();
            win.getContentPane().add(new JHexEditor(bankMem));
            win.addWindowListener(this);
            win.setTitle("Viewing Bank " + Dz.byteToHex(bankNo, true) + "    (press F5/SPACE to refresh contents)");
            win.pack();      
            win.show();
        }
        
} /* Bank */
