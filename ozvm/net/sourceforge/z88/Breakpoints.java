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
     * List breakpoints to console.
     */
    public void listBreakpoints() {
        if (breakPoints.isEmpty() == true) {
            System.out.println("No Breakpoints defined.");
        } else {
            Iterator keyIterator = breakPoints.entrySet().iterator();

            while(keyIterator.hasNext()) {
                Map.Entry e = (Map.Entry) keyIterator.next();   
                Breakpoint bp = (Breakpoint) e.getKey();

                int offset = bp.getAddress() & 0xFFFF;
                int bank = bp.getAddress() >>> 16;
                System.out.print(Dz.addrToHex(offset,false) + "," + Dz.byteToHex(bank,false) + "\t"); 
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

                int offset = bp.getAddress() & 0x3FFF;
                int bank = bp.getAddress() >>> 16;
                blink.setByte(offset, bank, 0x40);
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

                int offset = bp.getAddress() & 0x3FFF;
                int bank = bp.getAddress() >>> 16;

                // restore the original opcode bit pattern... 
                blink.setByte(offset, bank, bp.getInstruction() & 0xFF);
            }
        }			
    }

    // The breakpoint container.
    private class Breakpoint {
        int addressKey;			// the 24bit address of the breakpoint
        int instr;				// the original 16bit opcode at breakpoint

        Breakpoint(int offset, int bank) {
            // the encoded key for the SortedSet...
            addressKey = (bank << 16) | offset;

            // the original 1 byte opcode bit pattern in Z88 memory.
            setInstruction(blink.getByte(offset, bank));
        }

        private int setAddress() {
            return addressKey;
        }

        private int getAddress() {
            return addressKey;
        }

        private void setInstruction(int z80instr) {
            instr = z80instr;				
        }

        private int getInstruction() {
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
