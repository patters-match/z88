
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

 	public boolean	runAtFullSpeed = true;

	/** Since execute runs as a tight loop, some Java VM implementations
	 *  don't allow any other threads to get a look in. This give the
	 *  GUI time to update. If anyone has a better solution please 
	 *  email us at mailto:spectrum@odie.demon.co.uk
	 */
	public  int     sleepHack = 0;
	public  int     refreshRate = 1;  // refresh every 'n' interrupts

	private int     interruptCounter = 0;
	private boolean resetAtNextInterrupt = false;
	private boolean pauseAtNextInterrupt = false;
	private boolean refreshNextInterrupt = true;
	private boolean loadFromURLFieldNextInterrupt = false;

	public  Thread  pausedThread = null;
	public  long    timeOfLastInterrupt = 0;
	private long    timeOfLastSample = 0;

	public long oldTime = 0;
	public int oldSpeed = -1; // -1 mean update progressBar
	public int newSpeed = 0;
	public boolean showStats = true;
	public String statsMessage = null;
	private boolean flashInvert = false;

	private Bank z88Memory[];
		
	public Z88() throws Exception {
		// Z88 runs at 3.2768Mhz (the old spectrum was 3.5Mhz, a bit faster)
		super( 3.2768 );

		// Initialize Z88 memory
		z88Memory = new Bank[256];	// The Z88 memory organisation can address 256 banks * 16K = 4MB!
	}

	/** Byte access to virtual memory model */
	public int readByte( int addr ) {
		return 0;
	}
	
	/** Write byte to virtual memory model */
	public void writeByte ( int addr, int b ) {
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
			refreshFlashChars();
		}

		// Update speed indicator every 2 seconds of 'Spectrum time'
		if ( (interruptCounter % 100) == 0 ) {
			refreshSpeed();
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
			if ( !runAtFullSpeed && (durOfLastInterrupt < 40) ) {
				try { Thread.sleep( 50 - durOfLastInterrupt ); }
				catch ( Exception ignored ) {}
			}
		}

		// This was put in to handle Netscape 2 which was prone to
		// locking up if one thread never gave up its timeslice.
		if ( sleepHack > 0 ) {
			try { Thread.sleep( sleepHack ); }
			catch ( Exception ignored ) {}
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


	public final void refreshSpeed() {
		long newTime = timeOfLastInterrupt;

		if ( oldTime != 0 ) {
			newSpeed = (int) (200000.0 / (newTime - oldTime));
		}

		oldTime = newTime;
	}

	private final void refreshFlashChars() {
		flashInvert = !flashInvert;
	}

	private final void toggleSpeed() {
		runAtFullSpeed = !runAtFullSpeed;
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
