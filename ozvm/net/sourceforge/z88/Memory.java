/*
 * Memory.java
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
 * This class represents the 4Mb addressable memory model in the Z88, comprised 
 * of 16K memory blocks or banks of memory. The
 * characteristics of a bank can be that it's part of a Ram card (or the
 * internal memory of the Z88), an Eprom card or a 1MB Flash Card.
 * 
 * Further, the memory I/O characteristics of the bank can change if it
 * is located inside slot 3 and Eprom Programming is enabled in Blink
 * (the VPP Pin is enabled on the chip that is inserted in slot 3):
 * Depending on the bank type, all memory I/O will behave as the specified
 * hardware (U/V Eproms or Flash Card) when VPP is set (by the Blink).
 * 
 * Databus access to bank is byte-wide (8 bits, Z80 hardware). Therefore, the Blink
 * is responsible for reading 16bit values and getting cross bank boundary
 * words (lower byte at BankX, offset 3FFFh and high byte at BankY, offset 0000h).
 */
public final class Memory {
	/** A bank contains 16384 bytes */
	public static final int BANKSIZE = 16384; 
	
	/**
	 * The Z88 memory organisation.
	 * Array for 256 x 16K banks = 4Mb memory
	 */
	private Bank memory[];

	/**
	 * Null bank. This is used in for unassigned banks,
	 * ie. when a card slot is empty in the Z88
	 * The contents of this bank contains 0xFF and is
	 * write-protected (just as an empty bank in an Eprom).
	 */
	private Bank nullBank;
	
	public Memory() {
		memory = new Bank[256]; // The Z88 memory addresses 256 banks = 4MB!		

		nullBank = new Bank(Bank.VOID);
		for (int bank = 0; bank < memory.length; bank++)
			memory[bank] = nullBank;
	}

	/**
	 * Create a new Bank instance of type VOID, RAM, ROM, EPROM or FLASH. 
	 *
	 * @return Memory.Bank
	 */
	public final Bank createBank(int type) {
		return new Memory.Bank(type); 
	}
	
	/**
	 * Get Bank, referenced by it's number [0-255] in the BLINK memory model
	 *
	 * @return Bank
	 */
	public final Bank getBank(final int bankNo) {
		return memory[bankNo & 0xFF];
	}

	/**
	 * Install Bank entity into memory model (0-255).
	 *
	 * @param bank
	 * @param bankNo
	 */
	public final void setBank(final Bank bank, final int bankNo) {
		memory[bankNo & 0xFF] = bank;
	}
	
	/**
	 * Check if slot is empty (ie. no cards inserted)
	 *
	 * @param slotNo
	 * @return true, if slot is empty
	 */
	public final boolean isSlotEmpty(final int slotNo) {
		// convert slot number to top bank number of specified slot
		// if top bank of slot is of type NullBank, then we know it's empty...
		return memory[(((slotNo & 3) << 6) | 0x3F)] == nullBank;
	}
	
	public final class Bank {
		public static final int VOID = 0; // This bank represent an empty space (no card inserted in slot)
		public static final int RAM = 1; // 32Kb, 128Kb, 512Kb, 1Mb
		public static final int ROM = 2; // 128Kb, read-only
		public static final int EPROM_32KB = 3; // U/V Erasable 32Kb EPROM
		public static final int EPROM_128KB = 4; // U/V Erasable 128Kb/256Kb EPROM
		public static final int FLASH = 5; // 1Mb EEPROM (Flash) 
	
		private int type;
		private int bankMem[];
		private boolean vppPin = false; 
	
		public Bank() {
			type = Bank.RAM;
			bankMem = new int[BANKSIZE]; // all default memory cells are 0.
		}
	
		public Bank(int banktype) {
			type = banktype;
			bankMem = new int[BANKSIZE];
	
			if (type != Bank.RAM) {
				for (int i = 0; i < bankMem.length; i++)
					bankMem[i] = 0xFF; // empty Eprom or Flash stores FF's
			}
		}
	
		/**
		 * Get Bank type, ie. identify the type of card that is inserted into
		 * a particular slot.
		 * 
		 * @return type of Bank (type of Card) (VOID, RAM, ROM, EPROM, FLASH)  
		 */
		public int getType() {
			return type;
		}
	
		/**
		 * Set Bank type, ie. set the identify of the card that is inserted into
		 * a particular slot. This method must be used with equal types for all
		 * banks in particular slot (that defines the card).
		 * 
		 * @param type (type of Card) (VOID, RAM, ROM, EPROM, FLASH)  
		 */
		public void setType(int type) {
			this.type = type;
		}
		
		/**
		 * Read byte from bank. <addr> is a 16bit word
		 * that points into the 16K address space of the bank.
		 *
		 * On the Z88, the 64K is split into 4 sections of 16K segments.
		 * Any of the 256 16K banks can be bound into the address space
		 * on the Z88. Bank 0 is special, however.
		 * 
		 * Read behaviour from bank depends on Eprom Programming mode (Vpp).
		 *  
		 * Please refer to hardware section of the Developer's Notes.
		 */
		public final int readByte(final int addr) {
			// TODO insert logic here for Vpp programming...		
			return bankMem[addr & 0x3FFF];
		}
	
		/**
		 * Write byte to bank. <addr> is a 16bit word
		 * that points into the 16K address space of the bank.
		 *
		 * On the Z88, the 64K is split into 4 sections of 16K segments.
		 * Any of the 256 16K banks can be bound into the address space
		 * on the Z88. Bank 0 is special, however.
		 * 
		 * Write behaviour to bank depends on Eprom Programming mode (Vpp) 
		 * 
		 * Please refer to hardware section of the Developer's Notes.
		 */
		public final void writeByte(final int addr, final int b) {
			// TODO insert logic here for Vpp programming...
			if (type == Bank.RAM) {
				bankMem[addr & 0x3FFF] = b & 0xFF;
			}
		}
	
		/**
		 * Get byte from bank, always. 
		 * 
		 * NB: Internal method: Only used by OZvm debug command line!
		 * This method overrides all memory charateristics as defined
		 * by the Blink hardware that is managing the Z88 virtual memory. 
		 * 
		 * @param addr is a 16bit word that points into the 16K address space of the bank.
		 * @param b is the byte to be "set" at specific address
		 * 
		 */
		public final int getByte(final int addr) {
			return bankMem[addr & 0x3FFF];
		}
		
		/**
		 * Write byte to bank, always. 
		 * 
		 * NB: Internal method: Only used by OZvm debug command line!
		 * This method overrides all memory charateristics as defined
		 * by the Blink hardware that is managing the Z88 virtual memory 
		 * (except when this bank represents an empty space).
		 * 
		 * @param addr is a 16bit word that points into the 16K address space of the bank.
		 * @param b is the byte to be "set" at specific address
		 * 
		 */
		public final void setByte(final int addr, final int b) {
			if (type != Bank.VOID) bankMem[addr & 0x3FFF] = b & 0xFF;
		}
		
		/**
		 * Load bytes from buffer array of block.length to bank offset, onwards.
		 * Naturally, loading is only allowed inside 16Kb boundary.
		 */
		public void loadBytes(byte[] block, int offset) {
			offset %= BANKSIZE; // stay within boundary..
			int length =
				(offset + block.length) > BANKSIZE
					? BANKSIZE - offset
					: block.length;
	
			int bufidx = 0;
			while (length-- > 0)
				bankMem[offset++] = block[bufidx++] & 0xFF;
		}
		
		/**
		 * Check if Eprom or Flash Card VPP Pin is enabled
		 * (all banks of a card in slot 3 reflects this state).  
		 * 
		 * @return Returns the VPP pin status of this bank's chip.
		 */
		public final boolean isVppPinEnabled() {
			return vppPin;
		}
	
		/**
		 * Set the Eprom or Flash Card programming mode, by enabling the
		 * VPP pin on the Eprom chip.
		 * 
		 * This mode will only be called by the Blink hardware, when
		 * Z80 request OUT instructions executes the COM.VPP Blink register.
		 * 
		 * (this call has no effect if the Bank is part of a Ram Card or
		 * represent an empty space in any slot)
		 * 
		 * @param vpp The VPP pin state to set for this chip.
		 */
		public final void setVppPin(final boolean vpp) {
			if (type != Bank.RAM & type != Bank.ROM & type != Bank.VOID) this.vppPin = vpp;
		}
	} /* Bank */
} /* Memory */
