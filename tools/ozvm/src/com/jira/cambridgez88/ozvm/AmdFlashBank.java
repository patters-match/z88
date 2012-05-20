/*
 * AmdFlashBank.java
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

/**
 * This class represents the 16Kb Generic Flash Memory Bank on an AMD 29FxxxB
 * chip.
 *
 * The characteristics of a Flash Memory bank is chip memory that can be read at
 * all times and only be written (and erased) using a combination of AMD Flash
 * command sequences (write byte to address cycles), in ALL available slots on
 * the Z88.
 *
 * The emulation of the AMD Flash Memory solely implements the chip command mode
 * programming, since the Z88 Flash Cards only responds to those command
 * sequences (and not the hardware pin manipulation). Erase Suspend and Erase
 * Resume commands are also not implemented.
 *
 * The essential emulation is implemented to respond to the Standard Flash Eprom
 * Library (which implements all Flash chip manipulation, issuing commands on a
 * bank, typically specified indirectly using the BHL Z80 registers).
 */
public class AmdFlashBank extends GenericAmdFlashBank {

    /**
     * Device Code for 128Kb memory, 8 x 16K erasable sectors, 8 x 16K banks
     */
    public static final int AM29F010B = 0x20;
    /**
     * Device Code for 512Kb memory, 8 x 64K erasable sectors, 32 x 16K banks
     */
    public static final int AM29F040B = 0xA4;
    /**
     * Device Code for 1Mb memory, 16 x 64K erasable sectors, 64 x 16K banks
     */
    public static final int AM29F080B = 0xD5;
    /**
     * Manufacturer Code for AM29F0xxx Flash Memory chips
     */
    public static final int MANUFACTURERCODE = 0x01;
    /**
     * The actual Flash Memory Device Code of this bank instance
     */
    private int deviceCode;

    /**
     * Constructor. Assign the Flash Memory bank to the 4Mb memory model.
     *
     * @param dc the Flash Memory Device Code (AM29F010B, AM29F040B or
     * AM29F080B)
     */
    public AmdFlashBank(int dc) {
        super();

        deviceCode = dc;
    }

    /**
     * @return the Flash Memory Device Code (AM29F010B, AM29F040B or AM29F080B)
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
        return MANUFACTURERCODE;
    }
}
