package net.sourceforge.z88;

/**
 * @author <A HREF="mailto:gstrube@tiscali.dk">Gunther Strube</A>
 *
 * This class represents a 16K memory block or bank of memory
 * The characteristics of a bank can be that it's part of
 * a Ram card (or the internal memory of the Z88), an Eprom card
 * or a 1MB Flash Card.
 * 
 * $Id$
 */
public class Bank {
	public static final int RAM = 0;		// 32Kb, 128Kb, 512Kb, 1Mb
	public static final int ROM = 1;		// 128Kb 
	public static final int EPROM = 2;		// 32Kb, 128Kb & 256Kb
	public static final int FLASH = 3;		// 1Mb Flash
	public static final int SIZE = 16384;	// Always 16384 bytes in a bank
		
	private int type;
	private int memory[];
	
	Bank() {
		type = Bank.RAM;
		memory = new int[Bank.SIZE];	// all default memory cells are 0.
	}
	
	Bank(int banktype) {
		type = banktype;
		memory = new int[Bank.SIZE];
		
		if (type != Bank.RAM) {
			for (int i=0; i<memory.length; i++)
				memory[i] = 0xFF;	// empty Eprom or Flash stores FF's
		}
	}
	
	public int getType() {
		return type;
	}
	
	public int readByte(int offset) {
		return memory[0x3FFF & offset];
	}
	
	public void writeByte(int offset, int b) {
		if (type == Bank.RAM) 
			memory[0x3FFF & offset] = 0xFF & b;
	}
	
	/**
	 * Load bytes from buffer array of block.length
	 * to bank offset, onwards.
	 * Naturally, loading is only allowed inside 16Kb boundary.
	 */
	public void loadBytes(byte[] block, int offset) {
		offset %= Bank.SIZE;	// stay within boundary..
		int length = (offset+block.length) > Bank.SIZE ? Bank.SIZE-offset : block.length;

		int bufidx=0;
		while(length-- > 0)
			memory[offset++] = block[bufidx++] & 0xFF;
	}
}
