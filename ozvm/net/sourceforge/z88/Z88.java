
package net.sourceforge.z88;

import java.util.*;
import java.io.*;
import java.net.*;

/*
 * @(#)Z88.java 1.1 Gunther Strube
 */

/**
 * The Z88 class extends the Z80 class implementing the supporting
 * hardware emulation which was specific to the Z88. This
 * includes the memory mapped screen and the IO ports which were used
 * to read the keyboard, the 4MB memory model, the BLINK
 * on/off. There is no sound support in this version.<P>
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

	public  int     refreshRate = 1;  // refresh every 'n' interrupts

	private int     interruptCounter = 0;
	private boolean resetAtNextInterrupt = false;
	private boolean pauseAtNextInterrupt = false;
	private boolean refreshNextInterrupt = true;

	public  Thread  pausedThread = null;
	public  long    timeOfLastInterrupt = 0;
	private long    timeOfLastSample = 0;

	// **************  Z88 Hardware ************************
	private Bank z88Memory[];	// array for 256 16K banks, addressing 4Mb
	private Bank RAMS;			// reference bank bank 0x00 or 0x20 
	
	// Segment register array for SR0 - SR3
	// Segment register 0, SR0, bank binding for 0x2000 - 0x3FFF
	// Segment register 1, SR1, bank binding for 0x4000 - 0x7FFF
	// Segment register 2, SR2, bank binding for 0x8000 - 0xBFFF	
	// Segment register 3, SR3, bank binding for 0xC000 - 0xFFFF
	//
	// any of the registers contains a bank number, 0 - 255 that
	// is currently bound into the corresponding segment in the
	// Z80 address space. 
	private int sR[];	

	
	// **************  Initialize Z88 Hardware ************************
	public Z88() throws Exception {
		// Z88 runs at 3.2768Mhz (the old spectrum was 3.5Mhz, a bit faster...)
		super( 3.2768 );

		// Initialize Z88 memory model
		z88Memory = new Bank[256];	// The Z88 memory addresses 256 banks = 4MB!
		sR = new int[4];			// the segment register SR0 - SR3
	}
	// *****************************************************************
	
	/** 
	 * Read byte from Z80 virtual memory model. <addr> is a 16bit word 
	 * that points into the Z80 64K address space.
	 * 
	 * On the Z88, the 64K is split into 4 sections of 16K segments.
	 * Any of the 256 16K banks can be bound into the address space 
	 * on the Z88. Bank 0 is special, however.
	 * Please refer to hardware section of the Developer's Notes. 
	 **/
	public int readByte( int addr ) {
		int segment = (addr & 0xC000) >>> 14; // bit 15 & 14 identifies segment
		
		// the Z88 spends most of the time in segments 1 - 3,
		// therefore we should ask for this first...
		if (segment > 0) {
			return z88Memory[sR[segment]].readByte(addr);
		} else {
			// Bank 0 is split into two 8K blocks.
			// Lower 8K is System Bank 0x00 (ROM on hard reset) 
			// or 0x20 (RAM for Z80 stack and system variables)
			if (addr < 0x2000) {
				return RAMS.readByte(addr);
			} else {
				// determine which 8K of bank has been bound into 
				// upper half of segment 0. Only even numbered banks
				// can be bound into upper segment 0.
				// (to implement this hardware feature, we strip bit 0
				// of the bank number with the bit mask 0xFE)
				if ((sR[0] & 1) == 1) {
					// bit 0 is set in even bank number, ie. upper half of 
					// 8K bank is bound into upper segment 0...
					// address is already in range of 0x2000 - 0x3FFF 
					// (upper half of bank)
					return z88Memory[sR[0] & 0xFE].readByte(addr);
				} else {
					// lower half of 8K bank is bound into upper segment 0...
					// force address to read in the range 0 - 0x1FFF of bank
					return z88Memory[sR[0] & 0xFE].readByte(addr & 0x1FFF);
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
	 **/
	public void writeByte ( int addr, int b ) {
		int segment = (addr & 0xC000) >>> 14; // bit 15 & 14 identifies segment
		
		// the Z88 spends most of the time in segments 1 - 3,
		// therefore we should try this first...
		if (segment > 0) {
			z88Memory[sR[segment]].writeByte(addr, b);
		} else {
			// Bank 0 is split into two 8K blocks.
			// Lower 8K is System Bank 0x00 (ROM on hard reset) 
			// or 0x20 (RAM for Z80 stack and system variables)
			if (addr < 0x2000) {
				RAMS.writeByte(addr, b);
			} else {
				// determine which 8K of bank has been bound into 
				// upper half of segment 0. Only even numbered banks
				// can be bound into upper segment 0.
				// (to implement this hardware feature, we strip bit 0
				// of the bank number with the bit mask 0xFE)
				if ((sR[0] & 1) == 1) {
					// bit 0 is set in even bank number, ie. upper half of 
					// 8K bank is bound into upper segment 0...
					// address is already in range of 0x2000 - 0x3FFF 
					// (upper half of bank)
					z88Memory[sR[0] & 0xFE].writeByte(addr, b);
				} else {
					// lower half of 8K bank is bound into upper segment 0...
					// force address to read in the range 0 - 0x1FFF of bank
					z88Memory[sR[0] & 0xFE].writeByte(addr & 0x1FFF, b);
				}
			}
		}
	}

	/**
	 * Z80 hardware interface
	 */
	public int inb( int port ) {
		int res = 0xff;

		return(res);
	}

	public void outb( int port, int outByte, int tstates ) {
	}

	/** Byte access */

	public final int interrupt() {
		if ( pauseAtNextInterrupt ) {

			pausedThread = Thread.currentThread();
			while ( pauseAtNextInterrupt ) {
				if ( refreshNextInterrupt ) {
					refreshNextInterrupt = false;
				}
			}
			pausedThread = null;
		}

		if ( refreshNextInterrupt ) {
			refreshNextInterrupt = false;
		}

		if ( resetAtNextInterrupt ) {
			resetAtNextInterrupt = false;
			reset();
		}

		interruptCounter++;

		// Characters flash every 1/2 a second
		if ( (interruptCounter % 25) == 0 ) {
			// refreshFlashChars();
		}

		// Refresh every interrupt by default
		if ( (interruptCounter % refreshRate) == 0 ) {
			// screenPaint();
		}

		timeOfLastInterrupt = System.currentTimeMillis();

		// Trying to slow to 100%, browsers resolution on the system
		// time is not accurate enough to check every interrurpt. So
		// we check every 4 interrupts.
		if ( (interruptCounter % 4) == 0 ) {
			long durOfLastInterrupt = timeOfLastInterrupt - timeOfLastSample;
			timeOfLastSample = timeOfLastInterrupt;
		}

		return super.interrupt();
	}

	public void pauseOrResume() {
		// Pause
		if ( pausedThread == null ) {
			pauseAtNextInterrupt = true;
		}
		// Resume
		else {
			pauseAtNextInterrupt = false;

		}
	}

	public void repaint() {
		refreshNextInterrupt = true;
	}

	public void reset() {
		super.reset();
	}


	private int readBytes( InputStream is, int a[], int off, int n ) throws Exception {
		try {
			BufferedInputStream bis = new BufferedInputStream( is, n );

			byte buff[] = new byte[ n ];
			int toRead = n;
			while ( toRead > 0 ) {
				int	nRead = bis.read( buff, n-toRead, toRead );
				toRead -= nRead;
			}

			for ( int i = 0; i < n; i++ ) {
				a[ i+off ] = (buff[i]+256)&0xff;
			}

			return n;
		}
		catch ( Exception e ) {
			System.err.println( e );
			e.printStackTrace();
			throw e;
		}
	}
}
