package net.sourceforge.z88;

import java.util.Map;
import java.util.HashMap;
import java.util.Iterator;


/*
 * Manage breakpoint addresses in Z88 virtual machine.
 *
 * @author <A HREF="mailto:gstrube@tiscali.dk">Gunther Strube</A>
 * $Id$
 *
 * Created on July 11, 2003, 5:42 PM
 * 
 */
public class Breakpoints {
    private Map breakPoints = null;
    Blink blink; 

    /**
     * Just instantiate this Breakpoint Manager
     */
    Breakpoints(Blink b) {
        breakPoints = new HashMap(); 
        blink = b;
    }

    /**
     * Instantiate this Breakpoint Manager with the
     * first breakpoint.
     */
    Breakpoints(Blink b, int offset, int bank) {
        this(b);
        toggleBreakpoint(offset, bank);
    }

	/**
	 * Add (if not created) or remove breakpoint (if prev. created).
	 * 
	 * @param address 24bit extended address 
	 */
	public void toggleBreakpoint(int bpAddress) {
		int bpBank = bpAddress >>> 16;
		bpAddress &= 0xFFFF; 
		
		toggleBreakpoint(bpAddress, bpBank);
	}

	/**
	 * Get the original Z80 opcode, located at this breakpoint
	 * 
	 * @param address 24bit extended (breakpoint) address 
	 * @return Z80 opcode of breakpoint, or -1 if breakpoint wasn't found
	 */
	public int getOrigZ80Opcode(int bpAddress) {
		Breakpoint bp = new Breakpoint(bpAddress);
		Breakpoint bpv = (Breakpoint) breakPoints.get(bp);
		if (bpv != null) {
			return bpv.getCopyOfOpcode(); 
		} else
			return -1;
	}

    /**
     * Add (if not created) or remove breakpoint (if prev. created).
     * 
     * @param offset
     * @param bank
     */
    public void toggleBreakpoint(int offset, int bank) {
        Breakpoint bp = new Breakpoint(offset, bank);
        if (breakPoints.containsKey( (Breakpoint) bp) == false) 
            breakPoints.put((Breakpoint) bp, (Breakpoint) bp);
        else
            breakPoints.remove((Breakpoint) bp);
    }

	/**
	 * Add (if not created) or remove breakpoint (if prev. created).
	 * 
	 * @param offset
	 * @param bank
	 * @param stopStatus
	 */
	public void toggleBreakpoint(int offset, int bank, boolean stopStatus) {
		Breakpoint bp = new Breakpoint(offset, bank, stopStatus);
		if (breakPoints.containsKey( (Breakpoint) bp) == false) 
			breakPoints.put((Breakpoint) bp, (Breakpoint) bp);
		else
			breakPoints.remove((Breakpoint) bp);
	}

	/**
	 * Return <true> if breakpoint will stop exection. 
	 * 
	 * @param bpAddress 24bit extended address
	 * @return true, if breakpoint is defined to stop execution.
	 */
	public boolean isStoppable(int bpAddress) {
		int bpBank = bpAddress >>> 16;
		bpAddress &= 0xFFFF; 

		return isStoppable(bpAddress, bpBank); 
	}

	/**
	 * Return <true> if breakpoint will stop exection. 
	 * 
	 * @param offset
	 * @param bank
	 * @return true, if breakpoint is defined to stop execution.
	 */
	public boolean isStoppable(int offset, int bank) {
		Breakpoint bp = new Breakpoint(offset, bank);
		Breakpoint bpv = (Breakpoint) breakPoints.get(bp);
		if (bpv != null && bpv.stop == true) {
			return true; 
		} else
			return false;
	}

    /**
     * List breakpoints to stdout console.
     */
    public void listBreakpoints() {
        if (breakPoints.isEmpty() == true) {
            System.out.println("No Breakpoints defined.");
        } else {
            Iterator keyIterator = breakPoints.entrySet().iterator();

            while(keyIterator.hasNext()) {
                Map.Entry e = (Map.Entry) keyIterator.next();   
                Breakpoint bp = (Breakpoint) e.getKey();

                int offset = bp.getBpAddress() & 0xFFFF;
                int bank = bp.getBpAddress() >>> 16;
                System.out.print(Dz.addrToHex(offset,false) + "," + Dz.byteToHex(bank,false) + (bp.stop == true ? "[d]" : "") + "\t"); 
            }
            System.out.println();
        }
    }

    /**
     * Set the "breakpoint" instruction in Z88 memory for all 
     * currently defined breakpoints.
     */		
    public void setBreakpoints() {
        // now, set the breakpoint at the extended address; 
        // the instruction opcode 40 ("LD B,B"; quite useless!).
        // which this virtual machine identifies as a "suspend" Z80 exection. 
        if (breakPoints.isEmpty() == false) {
            Iterator keyIterator = breakPoints.entrySet().iterator();

            while(keyIterator.hasNext()) {
                Map.Entry e = (Map.Entry) keyIterator.next();   
                Breakpoint bp = (Breakpoint) e.getKey();

                int offset = bp.getBpAddress() & 0x3FFF;
                int bank = bp.getBpAddress() >>> 16;
                
                if (bp.stop == true) {
					blink.setByte(offset, bank, 0x40);	// use "LD B,B" as stop breakpoint
                } else {
					blink.setByte(offset, bank, 0x49);	// use "LD C,C" as display breakpoint 
                }
            }
        }
    }

    /**
     * Clear the "breakpoint" instruction; ie. restore original bitpattern
     * that was overwritten by the "breakpoint" instruction in Z88 memory.
     */
    public void clearBreakpoints() {
        // restore at the extended address; 
        // the original instruction opcode that is preserved inside 
        // the BreakPoint object 
        if (breakPoints.isEmpty() == false) {
            Iterator keyIterator = breakPoints.entrySet().iterator();

            while(keyIterator.hasNext()) {
                Map.Entry e = (Map.Entry) keyIterator.next();   
                Breakpoint bp = (Breakpoint) e.getKey();

                int offset = bp.getBpAddress() & 0x3FFF;
                int bank = bp.getBpAddress() >>> 16;

                // restore the original opcode bit pattern... 
                blink.setByte(offset, bank, bp.getCopyOfOpcode() & 0xFF);
            }
        }			
    }

    // The breakpoint container.
    private class Breakpoint {
        int addressKey;			// the 24bit address of the breakpoint
        int instr;				// the original 8bit opcode at breakpoint
        boolean stop;			

		/**
		 * Create a breakpoint object.
		 * 
		 * @param offset 16bit offset within bank
		 * @param bank 16K memory block number  
		 */
        Breakpoint(int offset, int bank) {
			// default is to stop execution at breakpoint
			stop = true;
			
            // the encoded key for the SortedSet...
            addressKey = (bank << 16) | offset;

            // the original 1 byte opcode bit pattern in Z88 memory.
            setCopyOfOpcode(blink.getByte(offset, bank));
        }

		/**
		 * Create a breakpoint object.
		 * 
		 * @param bpAddress 24bit extended address
		 */
		Breakpoint(int bpAddress) {
			// default is to stop execution at breakpoint
			stop = true;
			
			// the encoded key for the SortedSet...
			addressKey = bpAddress;

			// the original 1 byte opcode bit pattern in Z88 memory.
			setCopyOfOpcode(blink.getByte(bpAddress));
		}

		Breakpoint(int offset, int bank, boolean stopAtAddress) {
			// use <false> to display register status, then continue, <true> to stop execution.
			stop = stopAtAddress;
			
			// the encoded key for the SortedSet...
			addressKey = (bank << 16) | offset;

			// the original 1 byte opcode bit pattern in Z88 memory.
			setCopyOfOpcode(blink.getByte(offset, bank));
		}

        private int setBpAddress() {
            return addressKey;
        }

        private int getBpAddress() {
            return addressKey;
        }

        private void setCopyOfOpcode(int z80instr) {
            instr = z80instr;				
        }

        private int getCopyOfOpcode() {
            return instr; 
        }

        // override interface with the actual implementation for this object. 
        public int hashCode() {
            return addressKey;	// the unique key is a perfect hash code
        }

        // override interface with the actual implementation for this object. 
        public boolean equals(Object bp) {
            if (!(bp instanceof Breakpoint)) {
                return false;
            }

            Breakpoint aBreakpoint = (Breakpoint) bp; 
            if (addressKey == aBreakpoint.addressKey)
                return true;
            else 
                return false; 
        }
    }
}
