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
public final class Bank {
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
	
	/**
	 * The general Z80 System Read Byte.
	 *  
	 * @param offset
	 * @return int
	 */
	public final int readByte(final int offset) {
		return memory[0x3FFF & offset];
	}
	
	/**
	 * The general Z80 System Write Byte. 
	 * 
	 * This method ensures that only RAM can be changed; Eprom and Flash
	 * requires special logic (no yet implemented).
	 * 
	 * @param offset
	 * @param b
	 */
	public final void writeByte(final int offset, final int b) {
		if (type == Bank.RAM) 
			memory[0x3FFF & offset] = 0xFF & b;
	}

	/**
	 * The general Z80 System Read Word.
	 *  
	 * @param offset
	 * @return int
	 */
	public final int readWord(final int offset) {
		return memory[offset & 0x3FFF] << 8 | memory[(offset + 1) & 0x3FFF];
	}

	/**
	 * The general Z80 System Write Word.
	 *  
	 * @param offset
	 * @param w
	 */
	public final void writeWord(final int offset, final int w) {
		if (type == Bank.RAM) {
			memory[offset & 0x3FFF] = w & 0xFF;
			memory[(offset + 1) & 0x3FFF] = (w >>> 8) & 0xFF;
		}
	}

	/**
	 * Read Z80 instruction as a 4 byte entity, starting from offset, onwards.
	 * Z80 instructions varies between 1 and 4 bytes, but here a complete 4 byte
	 * sequence is cached, without knowing the actual length.
	 * 
	 * The instruction is returned as a 32bit integer for compactness, in low
	 * byte, high byte order, ie. lowest 8bit is the first byte, highest 8bit of
	 * 32bit integer is the 4th byte.
	 *  
	 * @param offset address offset in bank
	 * @return int
	 */
	public final int readInstruction(final int offset) {
		int instr = memory[(offset + 3) & 0x3FFF];
		instr = (instr << 8) | memory[(offset + 2) & 0x3FFF];
		instr = (instr << 8) | memory[(offset + 1) & 0x3FFF];
		instr = (instr << 8) | memory[offset & 0x3FFF];

		return instr; 
	}

	/**
	 * The "internal" write byte method to be used in
	 * the OZvm debugging environment, allowing complete
	 * write permission.
	 * 
	 * @param offset
	 * @param b
	 */
	public void setByte(final int offset, final int b) {
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
