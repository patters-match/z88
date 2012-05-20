/*
 * ApplicationFrontDor.java
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
package com.jira.cambridgez88.ozvm.datastructures;

import com.jira.cambridgez88.ozvm.Memory;
import com.jira.cambridgez88.ozvm.Z88;

/**
 * Get Application Front DOR Information of specified slot. The Front DOR is
 * location at offset $3FC0 in the top bank of an external card, or at bank $1F
 * in slot 0.
 *
 * The contents of the location is read without interpretation. It is the
 * responsibility of the appication using this object to identify an application
 * card header before using this class to properly recieve valid pointers.
 */
public class ApplicationFrontDor {

    /**
     * reference to available memory hardware and functionality
     */
    private Memory memory;
    /**
     * Extended, absolute address pointer to first Application DOR on card
     * (relative pointer is only available in actual memory of the card)
     */
    private int firstApp;
    /**
     * Extended, absolute address pointer to Help Front DOR, or none (relative
     * pointer is only available in actual memory of the card)
     */
    private int helpDor;

    /**
     * Initialize this object with data read from specified slot
     *
     * @param slot
     */
    public ApplicationFrontDor(int slot) {
        int slotMask = (slot << 6) & 0xFF;  // the slot mask to be used for relative DOR references
        int bank;
        int offset = 0x3FC0;        // Always located at $1F3FC0 for slot 0 and at $3F3FC0 for slots 1-3

        slot &= 3;                  // only slot 0 - 3 allowed...

        if (slot == 0) {
            bank = 0x1F;            // top bank of ROM area in slot 0 is $1F (top bank of first 512Kb address space)
        } else {
            bank = (slotMask | 0x3F);   // top bank of slot 
        }
        memory = Z88.getInstance().getMemory();
        offset += 3;                // Point at the potential Help Front DOR pointer

        helpDor = ((memory.getByte(offset + 2, bank) | slotMask) << 16)
                | (memory.getByte(offset + 1, bank) << 8)
                | memory.getByte(offset, bank);

        offset += 3;                // Point at first Application DOR pointer
        firstApp = ((memory.getByte(offset + 2, bank) | slotMask) << 16)
                | (memory.getByte(offset + 1, bank) << 8)
                | memory.getByte(offset, bank);
    }

    /**
     * @return the pointer to the Help Front DOR on the card.
     */
    public int getHelpDor() {
        return helpDor;
    }

    /**
     * @return the pointer to the first application DOR on the card.
     */
    public int getFirstApplicationDor() {
        return firstApp;
    }
}