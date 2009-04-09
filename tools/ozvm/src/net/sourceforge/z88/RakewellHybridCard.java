/*
 * RakewellHybridCard.java
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
 * $Id: AmdFlashBank.java 2189 2006-03-24 21:54:07Z gbs $
 *
 */
package net.sourceforge.z88;

/**
 * This class represents the Rakewell Hybrid Card, containing 2M RAM and 4Mb
 * Flash chips, all acessible using a latch register that Memory Bank on an AMD 29F032B chip,
 * added with the special hardware latch register functionality that handles the
 * extended Rakewell memory card.
 *
 * The characteristics of a Flash Memory bank is chip memory that can be read at
 * all times and only be written (and erased) using a combination of AMD Flash
 * command sequences (write byte to address cycles), in ALL available slots on
 * the Z88.
 *
 * The emulation of the AMD Flash Memory solely implements the chip command mode
 * programming, since the Z88 Flash Cards only responds to those command sequences
 * (and not the hardware pin manipulation). Erase Suspend and Erase Resume
 * commands are also not implemented.
 *
 * The essential emulation is implemented to respond to the Standard Flash Eprom
 * Library (which implements all Flash chip manipulation, issuing commands
 * on a bank, typically specified indirectly using the BHL Z80 registers).
 */
public class RakewellHybridCard {

    /**
     * The 4 x 512K Ram memory.
     */
    private RamBank[][] ram;

    /**
     * The 8 x 512K (4Mb) flash memory
     */
    private GenericAmdFlashBank[][] flash;

    /**
     * The slot number where this card is inserted (1 - 3).
     */
    private int slotNo;
	/**
	 * Access to the Z88 Memory Model
	 */
	private Memory memory;
    
    /**
     * To bind in another 512K block in lower 512K address space of slot
     * it is necessary to write to the FFFFFFh address 3 times, followed
     * by a 4th write.
     */
    private int latchRegisterActivateCounter;

    /**
     * The current binding of a 512K block in the lower 512K
     * address space of the 1Mb slot.
     */
    private int latchRegister;

    /**
     * This class represents the top 16Kb Flash Memory Bank on an AMD 29F032B chip,
     * added with the special hardware latch register functionality that handles the
     * extended Rakewell memory card.
     *
     * The characteristics of a Flash Memory bank is chip memory that can be read at
     * all times and only be written (and erased) using a combination of AMD Flash
     * command sequences (write byte to address cycles), in ALL available slots on
     * the Z88.
     *
     * The emulation of the AMD Flash Memory solely implements the chip command mode
     * programming, since the Z88 Flash Cards only responds to those command sequences
     * (and not the hardware pin manipulation). Erase Suspend and Erase Resume
     * commands are also not implemented.
     *
     * The essential emulation is implemented to respond to the Standard Flash Eprom
     * Library (which implements all Flash chip manipulation, issuing commands
     * on a bank, typically specified indirectly using the BHL Z80 registers).
     */
    private class AmdLatchBank extends GenericAmdFlashBank {

        /** Device Code for 4Mb memory, 64 x 64K erasable sectors, 256 x 16K banks */
        private static final int AM29F032B = 0x41;
        /**
         * The actual Flash Memory Device Code of this bank instance
         */
        private int deviceCode;

        /**
         * Constructor.
         * Initialize the Flash Memory bank that contains the Latch Register.
         */
        public AmdLatchBank() {
            super();

            deviceCode = AM29F032B;
        }

        /**
         * Write byte <b> to Flash Memory bank. <addr> is a 16bit word that points
         * into the 16K address space of the RAM bank.
         *
         * This method also manages the latch Register and manipulates the 512K
         * memory blocks to be assigned
         * Z80 processor write byte affects the behaviour of the AMD Flash Memory
         * chip (activating the accumulating Command Mode). Using processor write
         * cycle sequences the Flash Memory chip can be programmed with data and
         * get erased again in ALL available Z88 slots.
         */
        public void writeByte(final int addr, final int b) {
            if ( ((addr & 0x3FFF) == 0x3fff) & ((getBankNumber() & 0x3f) == 0x3f)) {
                // top address of card, update latch register counter,
                // or, if 4th consequetive write, then bind 512k memory block

                if (latchRegisterActivateCounter == 3) {
                    // 4th write reached - Latch register activated;
                    // execute 512K block binding of
                    // block B into lower 512K address space of card slot
                    // then, pass on the byte to the flash chip as well.
                    latchRegisterActivateCounter = 0;

                    latchRegister = b;
                    bind512kBlock();
                } else
                    latchRegisterActivateCounter++;
            }
            
            super.writeByte(addr, b);
        }

        /**
         * Read byte from Flash Memory bank. <addr> is a 16bit word that points into
         * the 16K address space of the bank.
         */
        public int readByte(final int addr) {
            /**
             *  A read of any address on the databus resets the Register counter.
             *  Here, in this virtual implementation, just look at the memory
             *  of the flash chip (should be sufficient).
             */
            latchRegisterActivateCounter = 0;

            return super.readByte(addr);
        }
        
        /**
         * @return the Flash Memory Device Code, AM29F032B
         * which this bank is part of.
         */
        public final int getDeviceCode() {
            return deviceCode;
        }

        /**
         * @return the Flash Memory Manufacturer Code
         *
         */
        public final int getManufacturerCode() {
            return AmdFlashBank.MANUFACTURERCODE;
        }
    }

    /**
     * Constructor. Initialize card dimensions; 2Mb Ram & 4Mb Flash
     */
    public RakewellHybridCard() {
        // access to Z88 memory model (4Mb)
        memory = Z88.getInstance().getMemory();	

        ram = new RamBank[4][512];
        flash = new AmdLatchBank[8][512];

        // initialize latch register counter
        latchRegisterActivateCounter = 0;

        // default 512K binding is first 512K block of 2Mb RAM
        // The default binding on the real card is unknown by Rakewell..
        // (it has to be explictly set by OZ on reset)
        latchRegister = 0;
    }

    /**
     * Bind a 512K block of memory into the lower 512K slot address space,
     * defined by the slot of the inserted card and the latch register.
     */
    private void bind512kBlock() {
        int blockNo;
        int slotBank = slotNo << 6; // convert slot number to bottom bank of slot

        // block numbers are divided in two; bit 7 enabled defines
        // blocks for flash (upper 64Mb), lower part for Ram

        if ((latchRegister & 0x80) == 0x80) {
            // bind a flash block into lower 512K slot address space
            // the flash chip is mirrored across the 64M (128 * 512K)

            // use the actual block number defined by the modulus
            // of the flash chip size
            blockNo = latchRegister % flash.length;
            for (int curBank = 0; curBank < flash[blockNo].length; curBank++) {
                // "insert" 16Kb flash bank of 512K block into Z88 memory
                memory.setBank(ram[blockNo][curBank], slotBank++);
            }
        } else {
            // bind a RAM block into lower 512K slot address space
            blockNo = latchRegister % ram.length;
            for (int curBank = 0; curBank < ram[blockNo].length; curBank++) {
                // "insert" 16Kb RAM bank of 512K block into Z88 memory
                memory.setBank(ram[blockNo][curBank], slotBank++);
            }
        }
    }

    public int getLatchRegister() {
        return latchRegister;
    }

    /**
     * Insert this card into an external slot 1-3, with default 512K block 0 of
     * 2Mb RAM in lower half of 1Mb slot address space, and top 512K block of
     * 4Mb Flash into upper half of 1Mb slot address space.
     */
    public void insertCard(int slot) {
        int slotBank;

        // remember slot number for latch register memory management
        slotNo = slot; 

        slotBank = slotNo << 6; // convert slot number to bottom bank of slot

        // using this method will preset the latch register to block 0 
        latchRegister = 0;

        // insert the default 512K RAM block into lower 512K slot address space
		for (int curBank = 0; curBank < ram[0].length; curBank++) {
			// "insert" 16Kb bank into Z88 memory
			memory.setBank(ram[latchRegister][curBank], slotBank++);
		}

        // insert the top 512K block of 4Mb Flash into upper 512K slot address space
        // this block is never be bound out by the card hardware..
		for (int curBank = 0; curBank < flash[7].length; curBank++) {
			// "insert" 16Kb bank into Z88 memory
			memory.setBank(flash[7][curBank], slotBank++);
		}
    }
}