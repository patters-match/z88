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
	 * Access to the Z88 Memory Model
	 */
	private Memory memory;

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
            super.writeByte(addr, b);
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
        flash = new AmdFlashBank[8][512];

        for (int i=0; i < 8; i++) {
            for (int j=0; j<512; j++) {
                flash[i][j] = new AmdFlashBank(AmdLatchBank.AM29F032B);
            }
        }

        /**
         * The top bank of the card contains the emulation
         * of the Latch register, which is receives input through
         * top address FFFFFh.
         */
        flash[7][511] = new AmdLatchBank();
    }
}