package net.sourceforge.z88;

import java.io.*;

/**
 * @author gstrube
 *
 * This class represents a 16K memory block or bank of memory
 * The characteristics of a bank can be that it's part of
 * a Ram card (or the internal memory of the Z88), an Eprom card
 * or a 1MB Flash Card.
 * 
 * $Id$
 */
public class Bank {
	public static final int RAM = 0;	// 32Kb, 128Kb, 512Kb, 1Mb
	public static final int EPROM = 1;	// 32Kb, 128Kb & 256Kb
	public static final int FLASH = 2;	// 1Mb Flash
		
	private int type;
	private int memory[];
	
	Bank() {
		type = 0;	// RAM
		memory = new int[16384];	// all default memory cells are 0.
	}
	
	Bank(int banktype) {
		type = banktype;
		memory = new int[16384];
		
		if (type != Bank.RAM) {
			for (int i=0; i<memory.length; i++)
				memory[i] = 0xFF;	// empty Eprom or Flash contain's FF's
		}
	}
	
	public int readByte(int offset) {
		return memory[0x3FFF & offset];
	}
	
	public void writeByte(int offset, int b) {
		if (type == Bank.RAM) 
			memory[0x3FFF & offset] = 0xFF & b;
	}
	
	public void loadBytes(InputStream is, int offset, int length ) throws Exception {
	}
}
