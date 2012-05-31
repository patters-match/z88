/*
 * GenericAmdFlashBank.java
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
 * and compatible chips (STMicroelectronics 29FxxxB and D series).
 *
 * The characteristics of a Flash Memory bank is chip memory that can be read at
 * all times and only be written (and erased) using a combination of AMD Flash
 * command sequences (write byte to address cycles), in ALL available slots on
 * the Z88.
 *
 * The emulation of the AMD and compatible Flash Memory solely implements the
 * chip command mode programming, since the Z88 Flash Cards only responds to
 * those command sequences (and not the hardware pin manipulation). Erase
 * Suspend and Erase Resume commands are also not implemented.
 *
 * The essential emulation is implemented to respond to the Standard Flash Eprom
 * Library (which implements all Flash chip manipulation, issuing commands on a
 * bank, typically specified indirectly using the BHL Z80 registers).
 */
public abstract class GenericAmdFlashBank extends Bank {

    /**
     * reference to Z88 memory model and API functionality
     */
    private Memory memory;
    /**
     * Read Array Mode<p> True = Amd Flash Memory behaves like an Eprom, False =
     * command mode
     *
     * Read Array Mode state applies for the complete slot which this bank is
     * part of.
     */
    private boolean readArrayMode;
    /**
     * Set to True, if a command reports failure, which continues to display the
     * error toggle through the read status cycle.
     */
    private boolean signalCommandFailure;
    /**
     * A command sequence consists of two unlock cycles, followed by a command
     * code cycle. Each cycle consists of an address and a: sub command code:
     * first cycle is [0x555,0xAA], the second cycle is [0x2AA, 0x55] followed
     * by the third cycle which is the command ('?') code (the actual command
     * will then be verified against known codes).
     */
    private static final int commandUnlockCycles[] = {0x555, 0xAA, 0x2AA, 0x55, 0x555, '?'};
    /**
     * Indicate success by DQ5 = 0 and DQ6 = 1, signaling no toggle in two
     * consecutive read cycles.
     */
    private static final int readStatusCommandSuccess[] = {0x40, 0x40};
    /**
     * Indicate failure by DQ5 = 1 and DQ6 toggling, for each consecutive read
     * cycle. The following bit patterns illustrate the sequence (from left to
     * right): [1] 0110 0000 (DQ6=1,DQ5=1), [2] 0010 0000 (DQ6=0,DQ5=1), [3]
     * 0110 0000 (DQ6=1,DQ5=1), [4] 0010 0000 (DQ6=0,DQ5=1)
     */
    private static final int readStatusCommandFailure[] = {0x60, 0x20, 0x60, 0x20};
    /**
     * The pending command sequence which is the template that is being
     * validated against the incoming command cycles (the processor write byte
     * cycles)
     */
    private SequenceStack commandUnlockCycleStack;
    /**
     * Whenever a Flash memory command has executed it's functionality, it
     * begins to feed read status sequences back to the application (which polls
     * for status using read cycles). This stack will contain read status
     * sequences for commands reporting success or failure.
     */
    private SequenceStack readStatusStack;
    /**
     * Status of ongoing accumulation of Flash Memory command, [<b>true</b>]
     * (ie. the individual cycles are accumulating and being verified as each
     * cycle is accumulated). A command sequence consists of three cycles; two
     * unlock cycles followed by the command code (The Erase commands consists
     * of two sections of three cycle command sequences).
     */
    private boolean isCommandAccumulating;
    /**
     * Indicate if a command is being executed [<b>true</b>] (Blow Byte, Erase
     * Sector/Chip or Auto-Select Mode command).
     */
    private boolean isCommandExecuting;
    /**
     * The command code of the executing command. Is set to 0, when no command
     * is executing (isCommandExecuting = false).
     */
    private int executingCommandCode;

    /**
     * Constructor. Assign the Flash Memory bank to the 4Mb memory model.
     */
    public GenericAmdFlashBank() {
        super(-1);

        memory = Z88.getInstance().getMemory();
        eraseBank(); // Flash Memory Bank is empty by default...

        // When a card is inserted into a slot, the Flash chip
        // is always in Ready Array Mode by default
        readArrayMode = true;
        isCommandAccumulating = false;
        isCommandExecuting = false;
    }

    /**
     * Read byte from Flash Memory bank. <addr> is a 16bit word that points into
     * the 16K address space of the bank.
     */
    public final int readByte(final int addr) {
        if (readArrayMode == true) // The chip is in Read Array Mode, get byte data at address..
        {
            return getByte(addr);
        } else // The chip is in Command Mode, get status of current command
        {
            return getCommandStatus(addr);
        }
    }

    /**
     * Write byte <b> to Flash Memory bank. <addr> is a 16bit word that points
     * into the 16K address space of the RAM bank.
     *
     * Z80 processor write byte affects the behaviour of the AMD Flash Memory
     * chip (activating the accumulating Command Mode). Using processor write
     * cycle sequences the Flash Memory chip can be programmed with data and get
     * erased again in ALL available Z88 slots.
     */
    public final void writeByte(final int addr, final int b) {
        processCommandCycle(addr, b);
    }

    /**
     * @return returns the Flash Memory Device Code of 29F series chip
     */
    public abstract int getDeviceCode();

    /**
     * @return returns the Flash Memory Manufacturer Code of 29F series chip
     */
    public abstract int getManufacturerCode();

    /**
     * Erase the contents of this bank to FF's (simulate the chip erase
     * functionality).
     */
    public void eraseBank() {
        for (int addr = 0; addr < Bank.SIZE; addr++) {
            setByte(addr, 0xFF);
        }
    }

    /**
     * Fetch success/failure status or chip information from the executing Flash
     * Memory command.
     *
     * @return command status information or device data
     */
    private final int getCommandStatus(int addr) {
        if (isCommandAccumulating == true) {
            // A command is being accumulated (not yet executing)
            // a Read Cycle automatically aborts the pre Command Mode and resets to Read Array Mode
            readArrayMode = true;
            isCommandAccumulating = false;
            isCommandExecuting = false;

            return getByte(addr);
        } else {
            if (isCommandExecuting == false) {
                // A command finished executing and we automatically get back to Read Array Mode
                readArrayMode = true;
                isCommandAccumulating = false;

                return getByte(addr);
            } else {
                // command is executing,
                // return status of Blow Byte, Erase Sector/Chip or
                // Auto Select Mode (get Manufacturer & Device Code)

                switch (executingCommandCode) {
                    case 0x10: // Chip Erase Command
                    case 0x30: // Sector Erase Command
                    case 0xA0: // Byte Program Command
                        int status;
                        if (signalCommandFailure == true) {
                            if (readStatusStack.isEmpty() == true) {
                                // Keep the error toggle status sequence "flowing"
                                // (the chip continues to be in command error mode)
                                // until the application issues a Read Array Mode command
                                readStatusStack = presetSequence(readStatusCommandFailure);
                            }
                            status = readStatusStack.pop(); // get error status cycle
                        } else {
                            status = readStatusStack.pop(); // get success status cycle
                            if (readStatusStack.isEmpty() == true) {
                                // When the last read status cycle has been delivered,
                                // the chip automatically returns to Read Array Mode
                                readArrayMode = true;
                                isCommandAccumulating = false;
                                isCommandExecuting = false;
                            }
                        }
                        return status;

                    case 0x90: // Autoselect Command
                        addr &= 0xFF;                           // only preserve lower 8 bits of address
                        switch (addr) {
                            case 0:
                                return getManufacturerCode();   // XX00 = Manufacturer Code
                            case 1:
                                return getDeviceCode();         // XX01 = Device Code
                            default:
                                return 0xFF;                // XXXX = Unknown behaviour...
                        }

                    default: // unknown command! Back to Read Array mode...
                        readArrayMode = true;
                        isCommandAccumulating = false;
                        isCommandExecuting = false;

                        return getByte(addr);
                }
            }
        }
    }

    /**
     * Process each command cycle sent to the Command Decoder, and execute the
     * parsed command, once it has been identified. If a command cycle is not
     * recognized as being a part of a command (address/data) sequence, the chip
     * automatically returns to Read Array Mode. Equally, if a read cycle is
     * performed against the Command Decoder while it is expecting a command
     * write cycle, the chip automatically returns to Read Array Mode.
     *
     * @param addr
     * @param b
     */
    private final void processCommandCycle(int addr, final int b) {

        if (readArrayMode == true) {
            // get into command mode...
            readArrayMode = false;
            isCommandAccumulating = true;
            executingCommandCode = 0;
            commandUnlockCycleStack = presetSequence(commandUnlockCycles);
        }

        if (isCommandAccumulating == false) {
            if (b == 0xF0) {
                // Reset to Read Array Mode; abort the error command mode state.
                // This command will be executed immediately, unless the Flash Memory has begun
                // programming or erasing (Read Array Mode command will then be ignored).

                readArrayMode = true;
                isCommandAccumulating = false;
                isCommandExecuting = false;
            }
        } else {
            // only accept other write cycles while accumulating a command (it's probably part of the command!)

            int cmdAddr = commandUnlockCycleStack.pop();    // validate cycle against this address
            int cmd = commandUnlockCycleStack.pop();        // validate cycle against this data

            if (cmd != '?') {
                // gathering the unlock cycles...
                addr &= 0x0FFF; // we're only interested in the three lowest hex digits in the unlock cycle address...

                if (addr != cmdAddr & b != cmd) {
                    // command sequence was 0xF0 (back to Read Array Mode) or an unknown command!
                    // Immediately return to Read Array Mode...
                    readArrayMode = true;
                    isCommandAccumulating = false;
                    isCommandExecuting = false;
                }
            } else {
                // we're reached the actual command code (Top of Stack reached)!
                if (executingCommandCode == 0xA0) {
                    // Byte Program Command, Part 2, we've fetched the Byte Program Address & Data,
                    // programming will now begin...
                    isCommandAccumulating = false;
                    isCommandExecuting = true;
                    programByteAtAddress(addr, b);
                } else {
                    switch (b) {
                        case 0x10: // Chip Erase Command, part 2
                            isCommandAccumulating = false;
                            isCommandExecuting = true;
                            executingCommandCode = 0x10;
                            eraseChipCommand();
                            break;

                        case 0x30: // Sector Erase Command (which this bank is part of), part 2
                            isCommandAccumulating = false;
                            isCommandExecuting = true;
                            executingCommandCode = 0x30;
                            eraseSectorCommand();
                            break;

                        case 0x80:  // Erase Command, part 1
                            // add new sub command sequence for erase chip or sector
                            // and wait for application command cycles...
                            commandUnlockCycleStack = presetSequence(commandUnlockCycles);
                            break;

                        case 0x90:  // Autoselect Command (get Manufacturer & Device Code)
                            isCommandAccumulating = false;
                            isCommandExecuting = true;
                            executingCommandCode = 0x90;
                            break;

                        case 0xA0:  // Byte Program Command, Part 1, get address and byte to program..
                            executingCommandCode = 0xA0;
                            commandUnlockCycleStack.push('?');  // and the Byte Program Data
                            commandUnlockCycleStack.push('?');  // We still need the Byte Program Address
                            break;

                        default:
                            // command cycle sequence was unknown!
                            // Immediately return to Read Array Mode...
                            readArrayMode = true;
                            isCommandAccumulating = false;
                            isCommandExecuting = false;
                    }
                }
            }
        }
    }

    /**
     * Blow Byte at address.
     *
     * Verify that the byte to be blown follows the rule that only 0 bit
     * patterns can be programmed (converting 1 to 0 in the Flash Memory). Flash
     * memory bit patterns can only be converted from 0 to 1 by erasing the
     * memory...
     *
     * If the byte is successfully written, this method will signal success by
     * establishing a sequence of read status data, which the outside
     * application polls and acknowledges as successfully completed.
     *
     * On Byte Write failure a similar sequence of read status data will signal
     * failure. The application must then signal back with forcing the chip back
     * into Read Array Mode.
     *
     * @param addr offset within bank
     * @param b byte to be blown on Flash Memory
     */
    private void programByteAtAddress(final int addr, final int b) {
        if ((b & getByte(addr)) == b) {
            // the byte can be blown (flash memory bit pattern can be changed from 1 to 0)
            setByte(addr, b);

            // indicate success when application polls for read status cycles...
            readStatusStack = presetSequence(readStatusCommandSuccess);
            signalCommandFailure = false;
        } else {
            // the byte will break the rule that a 0 bit cannot be programmed
            // to a 1, but only through a sector erase.

            // indicate failure when application polls for read status cycles...
            readStatusStack = presetSequence(readStatusCommandFailure);
            signalCommandFailure = true;
        }
    }

    /**
     * Erase complete Flash Memory (never fails in this emulation!). the banks
     * representing the chip are erased from top of slot downwards.
     */
    private void eraseChipCommand() {
        int cardTopBank, totalCardBanks = 0;

        // through this bank number we find the bottom Bank number of the slot
        int thisBottomSlotBank = (getBankNumber() & 0xC0);

        if (thisBottomSlotBank == 0) // the top bank number of ROM in slot 0
        {
            cardTopBank = memory.getBank(0x1F).getBankNumber();
        } else // get the top bank number of the card (might not be the top of the slot!)
        {
            cardTopBank = memory.getBank(thisBottomSlotBank | 0x3F).getBankNumber();
        }

        Bank bank = memory.getBank(cardTopBank);
        if (bank instanceof AmdFlashBank == true) {
            AmdFlashBank afb = (AmdFlashBank) bank;
            switch (afb.getDeviceCode()) {
                case AmdFlashBank.AM29F010B:
                    totalCardBanks = 8;
                    break;
                case AmdFlashBank.AM29F040B:
                    totalCardBanks = 32;
                    break;
                case AmdFlashBank.AM29F080B:
                    totalCardBanks = 64;
                    break;
            }
        }
        if (bank instanceof AmicFlashBank == true) {
            // Rakewell only uses a 512K chip in a hybrid card.
            // No other chip types are available
            totalCardBanks = 32;
        }

        while (totalCardBanks-- > 0) {
            GenericAmdFlashBank b = (GenericAmdFlashBank) memory.getBank(cardTopBank--);
            b.eraseBank();
        };

        // indicate success when application polls for read status cycles...
        readStatusStack = presetSequence(readStatusCommandSuccess);
        signalCommandFailure = false;
    }

    /**
     * Erase the Flash Memory Sector which this bank is part of (never fails in
     * this emulation!).
     */
    private void eraseSectorCommand() {
        if (getDeviceCode() == AmdFlashBank.AM29F010B) {
            // The 128K Flash chip uses a 16K sector architecture,
            // so just erase this bank and we're done!
            eraseBank();
        } else {
            // all known Amd Flash chips (except AM29F010B) uses a 64K sector architecture,
            // so erase the bottom bank of the current sector and the next three following banks
            int bottomBankOfSector = getBankNumber() & 0xFC;  // bottom bank of sector

            for (int thisBank = bottomBankOfSector; thisBank <= (bottomBankOfSector + 3); thisBank++) {
                GenericAmdFlashBank b = (GenericAmdFlashBank) memory.getBank(thisBank);
                b.eraseBank();
            }
        }

        // indicate success when application polls for read status cycles...
        readStatusStack = presetSequence(readStatusCommandSuccess);
        signalCommandFailure = false;
    }

    /**
     * Prepare a sequence stack.
     *
     * This will be used for validating a complete 3 cycle command sequence or
     * when an application polls for chip command status.
     */
    private SequenceStack presetSequence(int[] sequence) {
        SequenceStack seqStk = new SequenceStack();

        // prepare a new sequence
        for (int p = sequence.length - 1; p >= 0; p--) {
            seqStk.push(sequence[p]);
        }

        return seqStk;
    }

    /**
     * Sequence LIFO Stack, used for validation of command unlock cycles and
     * read status data sequences.
     */
    private class SequenceStack {

        private int sequence[];
        private int stackPtr = -1; // empty stack

        public SequenceStack() {
            sequence = new int[8];
        }

        public int push(int item) {
            sequence[++stackPtr] = item;
            return item;
        }

        public boolean isEmpty() {
            return (stackPtr < 0) ? true : false;
        }

        public int pop() {
            if (stackPtr < 0) {
                return -1;
            } else {
                return sequence[stackPtr--];
            }
        }
    }

    /**
     * Validate if Flash card bank contents is not altered, ie. only containing
     * FF bytes.
     *
     * @return true if all bytes in bank are FF
     */
    public boolean isEmpty() {
        for (int b = 0; b < Bank.SIZE; b++) {
            if (getByte(b) != 0xFF) {
                return false;
            }
        }

        return true;
    }
}
