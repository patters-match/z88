
package net.sourceforge.z88;

import java.io.*;

/**
 * 
 * The "Heart" and blood stream of the Z88 (Z80 processor and RAM).
 * 
 * The Z88 class extends the Z80 class implementing the supporting hardware
 * emulation which was specific to the Z88. This includes the memory mapped
 * screen and the IO ports which were used to read the keyboard, the 4MB memory
 * model, the BLINK on/off. There is no sound support in this version.<P>
 *
 * @version 0.1
 * @author <A HREF="mailto:gstrube@tiscali.dk">Gunther Strube</A>
 *
 * @see OZvm
 * @see Z88
 *
 * $Id$
 *
 */

public class Z88 extends Z80 {

	private Blink blink;
	
    /**
     * The Z88 disassembly engine
     */
    private Dz dz;

    /**
     * Internal static buffer for runtime disassembly.
     */
    private static final StringBuffer dzBuffer = new StringBuffer(32);

    /**
     * The Z88 memory organisation.
     * Array for 256 x 16K banks = 4Mb memory
     */
    private Bank z88Memory[];

    /**
     * Null bank. This is used in for unassigned banks,
     * ie. when a card slot is empty in the Z88
     * The contents of this bank contains 0xFF and is
     * write-protected (just as an empty bank in an Eprom).
     */
    private Bank nullBank;

    /**
     * The container for the current loaded card entities
     * in the Z88 memory system for slot 0, 1, 2 and 3.
     *
     * Slot 0 will only keep a RAM Card in top 512K address space
     * The ROM "Card" is only loaded once at OZvm boot
     * and is never removed.
     */
    private Bank slotCards[][];

    /**
     * Constructor.
     * Initialize Z88 Hardware.
     */
    public Z88() throws Exception {
        // Z88 runs at 3.2768Mhz (the old spectrum was 3.5Mhz, a bit faster...)
        // This emulator runs at the speed it can get and provides external
        // interrupt signals each 10ms from BLINK to Z80 through INT pin
        super();

		blink = new Blink();	// initialize BLINK chip
        dz = new Dz(this);  	// the disassembly engine must know about the Z88 virtual machine

        // Initialize Z88 memory model
        
        z88Memory = new Bank[256];          // The Z88 memory addresses 256 banks = 4MB!
        nullBank = new Bank(Bank.EPROM);
        slotCards = new Bank[4][];          // Instantiate the slot containers for Cards...

        // Initialize Z88 Memory address space.
        for (int bank=0; bank<z88Memory.length; bank++) z88Memory[bank] = nullBank;
        for (int slot=0; slot<4; slot++) slotCards[slot] = null; // nothing available in slots..

        insertRamCard(128*1024, 0);         // Insert 128K RAM in slot 0 (top 512K address space)
    }


    public void hardReset() {
        reset();                		// reset Z80 registers
        blink.setCOM(0);        		// reset COM register
        blink.setRAMS(z88Memory[0]);    // point at ROM bank $00

        resetRam();             		// reset memory of all available RAM in Z88 memory
    }


    public void haltInstruction() {
        // Let the Blink know that a HALT instruction occured
        // so that the Z88 enters the correct state (coma, snooze, ...)
    }


    /**
     * Scan available slots for Ram Cards, and reset them..
     */
    private void resetRam() {
        for (int slot=0; slot<slotCards.length; slot++) {
            // look at bottom bank in Card for type; only reset RAM Cards...
            if (slotCards[slot] != null && slotCards[slot][0].getType() == Bank.RAM) {
                // reset all banks in Card of current slot
                for (int cardBank=0; cardBank<slotCards[slot].length; cardBank++) {
                    Bank b = slotCards[slot][cardBank];
                    for (int bankOffset = 0; bankOffset<Bank.SIZE; bankOffset++) {
                        b.writeByte(bankOffset, 0);
                    }
                }
            }
        }
    }


    /**
     * Insert RAM Card into Z88 memory system.
     * Size must be in modulus 32Kb (even numbered 16Kb banks).
     * RAM may be inserted into slots 0 - 3.
     * RAM is loaded from bottom bank of slot and upwards.
     * Slot 0 (512Kb): banks 20 - 3F
     * Slot 1 (1Mb):   banks 40 - 7F
     * Slot 2 (1Mb):   banks 80 - BF
     * Slot 3 (1Mb):   banks C0 - FF
     *
     * Slot 0 is special; max 512K RAM in top 512K address space.
     * (bottom 512K address space in slot 0 is reserved for ROM, banks 00-1F)
     */
    public void insertRamCard(int size, int slot) {
        int totalRamBanks, totalSlotBanks, curBank;

        slot %= 4;                      // allow only slots 0 - 3 range.
        size -= (size % 32768);         // allow only modulus 32Kb RAM.
        totalRamBanks = size / 16384;   // number of 16K banks in Ram Card

        Bank ramBanks[] = new Bank[totalRamBanks];  // the RAM card container
        for (curBank=0; curBank<totalRamBanks; curBank++) {
            ramBanks[curBank] = new Bank(Bank.RAM);
        }

        slotCards[slot] = ramBanks;     // remember Ram Card for future reference...
        loadCard(ramBanks, slot);       // load the physical card into Z88 memory
    }


    /**
     * Load externally specified ROM image into Z88 memory system, slot 0.
     *
     * @param filename
     * @throws FileNotFoundException
     * @throws IOException
     */
    public void loadRom(String filename) throws FileNotFoundException, IOException {
        RandomAccessFile rom = new RandomAccessFile(filename, "r");

        if (rom.length() > (1024*512)) {
            throw new IOException("Max 512K ROM!");
        }
        if (rom.length() % (Bank.SIZE*2) > 0) {
            throw new IOException("ROM must be in even banks!");
        }

        Bank romBanks[] = new Bank[(int) rom.length() / Bank.SIZE]; // allocate ROM container
        byte bankBuffer[] = new byte[Bank.SIZE];                    // allocate intermediate load buffer

        for(int curBank=0; curBank<romBanks.length; curBank++) {
            romBanks[curBank] = new Bank(Bank.ROM);
            rom.readFully(bankBuffer);                  // load 16K from file, sequentially
            romBanks[curBank].loadBytes(bankBuffer,0);  // and load fully into bank
        }

        // complete ROM image now loaded into container
        // insert container into Z88 memory, slot 0, banks $00 onwards.
        loadCard(romBanks, 0);
    }


    /**
     * Load Card (RAM/ROM/EPROM) into Z88 memory system.
     * Size is in modulus 32Kb (even numbered 16Kb banks).
     * Slot 0 (512Kb): banks 00 - 1F (ROM), banks 20 - 3F (RAM)
     * Slot 1 (1Mb):   banks 40 - 7F (RAM or EPROM)
     * Slot 2 (1Mb):   banks 80 - BF (RAM or EPROM)
     * Slot 3 (1Mb):   banks C0 - FF (RAM or EPROM)
     *
     * @param card
     * @param slot
     */
    private void loadCard(Bank card[], int slot) {
        int totalSlotBanks, slotBank, curBank;

        if (slot == 0) {
            // Define bottom bank for ROM/RAM
            slotBank = (card[0].getType() != Bank.RAM) ? 0x00 : 0x20;
            // slot 0 has 32 * 16Kb = 512K address space for RAM or ROM
            totalSlotBanks = 32;
        } else {
            slotBank = slot << 6;   // convert slot number to bottom bank of slot
            totalSlotBanks = 64;    // slots 1 - 3 have 64 * 16Kb = 1Mb address space
        }

        for (curBank=0; curBank<card.length; curBank++) {
            z88Memory[slotBank++] = card[curBank];  // "insert" 16Kb bank into Z88 memory
            --totalSlotBanks;
        }

        // - the bottom of the slot has been loaded with the Card.
        // Now, we need to fill the 1MB address space in the slot with the card.
        // Note, that most cards and the internal memory do not exploit
        // the full lMB addressing range, but only decode the lower address lines.
        // This means that memory will appear more than once within the lMB range.
        // The memory of a 32K card in slot 1 would appear at banks $40 and $41,
        // $42 and $43, ..., $7E and $7F. Alternatively a 128K EPROM in slot 3 would
        // appear at $C0 to $C7, $C8 to $CF, ..., $F8 to $FF.
        // This way of addressing is assumed by the system.
        // Note that the lowest and highest bank in an EPROM can always be addressed
        // by looking at the bank at the bottom of the 1MB address range and the bank
        // at the top respectively.
        while (totalSlotBanks > 0) {
            for (curBank=0; curBank<card.length; curBank++) {
                z88Memory[slotBank++] = card[curBank];  // "shadow" card banks into remaining slot
                --totalSlotBanks;
            }
        }
    }


    /**
     * Read byte from Z80 virtual memory model. <addr> is a 16bit word
     * that points into the Z80 64K address space.
     *
     * On the Z88, the 64K is split into 4 sections of 16K segments.
     * Any of the 256 16K banks can be bound into the address space
     * on the Z88. Bank 0 is special, however.
     * Please refer to hardware section of the Developer's Notes.
     */
    public int readByte( int addr ) {
        int segment = addr >>> 14; // bit 15 & 14 identifies segment

        // the Z88 spends most of the time in segments 1 - 3,
        // therefore we should ask for this first...
        if (segment > 0) {
            return z88Memory[blink.getSegmentBank(segment)].readByte(addr);
        } else {
            // Bank 0 is split into two 8K blocks.
            // Lower 8K is System Bank 0x00 (ROM on hard reset)
            // or 0x20 (RAM for Z80 stack and system variables)
            if (addr < 0x2000) {
                return blink.getRAMS().readByte(addr);
            } else {
                // determine which 8K of bank has been bound into
                // upper half of segment 0. Only even numbered banks
                // can be bound into upper segment 0.
                // (to implement this hardware feature, we strip bit 0
                // of the bank number with the bit mask 0xFE)
                if ((blink.getSegmentBank(0) & 1) == 1) {
                    // bit 0 is set in even bank number, ie. upper half of
                    // 8K bank is bound into upper segment 0...
                    // address is already in range of 0x2000 - 0x3FFF
                    // (upper half of bank)
                    return z88Memory[blink.getSegmentBank(0) & 0xFE].readByte(addr);
                } else {
                    // lower half of 8K bank is bound into upper segment 0...
                    // force address to read in the range 0 - 0x1FFF of bank
                    return z88Memory[blink.getSegmentBank(0) & 0xFE].readByte(addr & 0x1FFF);
                }
            }
        }
    }


    /**
     * Write byte to Z80 virtual memory model. <addr> is a 16bit word
     * that points into the Z80 64K address space.
     *
     * On the Z88, the 64K is split into 4 sections of 16K segments.
     * Any of the 256 16K banks can be bound into the address space
     * on the Z88. Bank 0 is special, however.
     * Please refer to hardware section of the Developer's Notes.
     */
    public void writeByte ( int addr, int b ) {
        int segment = addr >>> 14; // bit 15 & 14 identifies segment

        // the Z88 spends most of the time in segments 1 - 3,
        // therefore we should try this first...
        if (segment > 0) {
            z88Memory[blink.getSegmentBank(segment)].writeByte(addr, b);
        } else {
            // Bank 0 is split into two 8K blocks.
            // Lower 8K is System Bank 0x00 (ROM on hard reset)
            // or 0x20 (RAM for Z80 stack and system variables)
            if (addr < 0x2000) {
				blink.getRAMS().writeByte(addr, b);
            } else {
                // determine which 8K of bank has been bound into
                // upper half of segment 0. Only even numbered banks
                // can be bound into upper segment 0.
                // (to implement this hardware feature, we strip bit 0
                // of the bank number with the bit mask 0xFE)
                if ((blink.getSegmentBank(0) & 1) == 1) {
                    // bit 0 is set in even bank number, ie. upper half of
                    // 8K bank is bound into upper segment 0...
                    // address is already in range of 0x2000 - 0x3FFF
                    // (upper half of bank)
                    z88Memory[blink.getSegmentBank(0) & 0xFE].writeByte(addr, b);
                } else {
                    // lower half of 8K bank is bound into upper segment 0...
                    // force address to read in the range 0 - 0x1FFF of bank
                    z88Memory[blink.getSegmentBank(0) & 0xFE].writeByte(addr & 0x1FFF, b);
                }
            }
        }
    }

    /**
     * Disassemble implementation for Z88 virtual machine.
     * This method will be called by the Z80 processing engine
     * (the super class), when instructed to perform runtime
     * disassembly.
     */
    public void disassemble( int addr ) {

        dz.getInstrAscii(dzBuffer, addr, true);
        System.out.println(dzBuffer);   // display executing instruction in shell
    }


    /**
     * Implement Z88 input port hardware.
     * (BLINK)
     */
    public int inByte( int port ) {
        int res = 0xff;

        return(res);
    }

    /**
     * Implement Z88 output port hardware.
     * (BLINK)
     */
    public void outByte( int port, int outByte) {
        switch(port) {
            case 0xB0:  // COM
                blink.setCOM(outByte);
                if ( (outByte & Blink.BM_COMRAMS) == Blink.BM_COMRAMS)
                    // RAM is bound into lower 8K of segment 0
                    blink.setRAMS(z88Memory[0x20]);
                else
                    // ROM bank 0 is bound into lower 8K of segment 0
                    blink.setRAMS(z88Memory[0x00]);
                break;

            case 0xD0:  // SR0
			    blink.setSegmentBank(0, outByte);
                break;
            case 0xD1:  // SR1
				blink.setSegmentBank(1, outByte);
                break;
            case 0xD2:  // SR2
				blink.setSegmentBank(2, outByte);
                break;
            case 0xD3:  // SR3
				blink.setSegmentBank(2, outByte);
                break;
        }
    }
}
