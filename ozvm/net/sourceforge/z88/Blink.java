package net.sourceforge.z88;

import java.util.Timer;
import java.util.TimerTask;

/**
 * Blink chip, the "mind" of the Z88.
 * @author <A HREF="mailto:gstrube@tiscali.dk">Gunther Strube</A>
 * 
 * $Id$
 */
public final class Blink {

	/**
	 * Blink class default constructor.
	 */
	Blink(Z88 vm) {
		z88vm = vm;		// know about the processor environment outside the BLINK
		
		// the segment register SR0 - SR3
		sR = new int[4];
		// all segment registers points at ROM bank 0
		for (int segment = 0; segment < sR.length; segment++) {
			sR[segment] = 0;
		}

		memory = new Bank[256];          // The Z88 memory addresses 256 banks = 4MB!
		nullBank = new Bank(Bank.EPROM);
		for (int bank=0; bank<memory.length; bank++) memory[bank] = nullBank;

		rtc = new Rtc(); // start the Real Time Clock...
	}

	/**
	 * Reference to the Z80 processor / Z88 virtual machine 
	 * (which the BLINK is collaborating with).
	 */
	private Z88 z88vm;

	/**
	 * The Real Time Clock (RTC) inside the BLINK...
	 */
	private Rtc rtc;

	/**
	 * Get current TIM0 register from the RTC.
	 * 
	 * @return int
	 */
	public int getTim0() {
		return rtc.getTim0();
	}

	/**
	 * Get current TIM1 register from the RTC.
	 * 
	 * @return int
	 */
	public int getTim1() {
		return rtc.getTim1();
	}

	/**
	 * Get current TIM2 register from the RTC.
	 * 
	 * @return int
	 */
	public int getTim2() {
		return rtc.getTim2();
	}

	/**
	 * Get current TIM3 register from the RTC.
	 * 
	 * @return int
	 */
	public int getTim3() {
		return rtc.getTim3();
	}

	/**
	 * Get current TIM4 register from the RTC.
	 * 
	 * @return int
	 */
	public int getTim4() {
		return rtc.getTim4();
	}

	/**
	 * System bank for lower 8K of segment 0.
	 * References bank 0x00 or 0x20 of slot 0.
	 */
	private Bank RAMS;

	/**
	 * Get Bank, referenced by it's number [0-255] in the BLINK memory model 
	 * 
	 * @return Bank
	 */
	public Bank getBank(int bankNo) {
		return memory[bankNo % 256];
	}

	/**
	 * Install Bank entity into BLINK 16K memory system [0-255].
	 *  
	 * @param bank
	 * @param bankNo
	 */
	public void setBank(Bank bank, int bankNo) {
		memory[bankNo % 256] = bank;
	}
	
	/**
	 * Segment register array for SR0 - SR3
	 * Segment register 0, SR0, bank binding for 0x2000 - 0x3FFF
	 * Segment register 1, SR1, bank binding for 0x4000 - 0x7FFF
	 * Segment register 2, SR2, bank binding for 0x8000 - 0xBFFF
	 * Segment register 3, SR3, bank binding for 0xC000 - 0xFFFF
	 *
	 * Any of the registers contains a bank number, 0 - 255 that
	 * is currently bound into the corresponding segment in the
	 * Z80 address space.
	 */
	private int sR[];

	/**
	 * The Z88 memory organisation.
	 * Array for 256 x 16K banks = 4Mb memory
	 */
	private Bank memory[];

	/**
	 * Null bank. This is used in for unassigned banks,
	 * ie. when a card slot is empty in the Z88
	 * The contents of this bank contains 0xFF and is
	 * write-protected (just as an empty bank in an Eprom).
	 */
	private Bank nullBank;

	/**
	 * Get current bank [0; 255] binding in segments [0; 3] 
	 *
	 * On the Z88, the 64K is split into 4 sections of 16K segments.
	 * Any of the 256 16K banks can be bound into the address space
	 * on the Z88. Bank 0 is special, however.
	 * Please refer to hardware section of the Developer's Notes.
	 * 
	 * @return int
	 */
	public int getSegmentBank(int segment) {
		return sR[segment % 4];
	}

	/**
	 * Bind bank [0-255] to segments [0-3] in the Z80 address space.
	 * 
	 * <p>On the Z88, the 64K is split into 4 sections of 16K segments. Any of
	 * the 256 x 16K banks can be bound into the address space on the Z88. Bank
	 * 0 is special, however. Please refer to hardware section of the
	 * Developer's Notes.</p>
	 */
	public void setSegmentBank(int segment, int BankNo) {
		sR[segment % 4] = (BankNo % 256);
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

		// the OZ spends most of the time in segments 1 - 3,
		// therefore we should ask for this first...
		if (segment > 0) {
			return memory[sR[segment]].readByte(addr);
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
					return memory[sR[0] & 0xFE].readByte(addr);
				} else {
					// lower half of 8K bank is bound into upper segment 0...
					// force address to read in the range 0 - 0x1FFF of bank
					return memory[sR[0] & 0xFE].readByte(addr & 0x1FFF);
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

		// the OZ spends most of the time in segments 1 - 3,
		// therefore we should ask for this first...
		if (segment > 0) {
			memory[sR[segment]].writeByte(addr, b);
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
					memory[sR[0] & 0xFE].writeByte(addr, b);
				} else {
					// lower half of 8K bank is bound into upper segment 0...
					// force address to read in the range 0 - 0x1FFF of bank
					memory[sR[0] & 0xFE].writeByte(addr & 0x1FFF, b);
				}
			}
		}
	}
	
	/**
	 * BLINK Command Register
	 * 
	 *	Bit	 7, SRUN
	 *	Bit	 6, SBIT
	 *	Bit	 5, OVERP
	 *	Bit	 4, RESTIM
	 *	Bit	 3, PROGRAM
	 *	Bit	 2, RAMS
	 *	Bit	 1, VPPON
	 *	Bit	 0, LCDON
	 */
	private int COM;

	/**
	 * Set Blink Command Register flags, port $B0
	 *	Bit	 7, SRUN
	 *	Bit	 6, SBIT
	 *	Bit	 5, OVERP
	 *	Bit	 4, RESTIM
	 *	Bit	 3, PROGRAM
	 *	Bit	 2, RAMS
	 *	Bit	 1, VPPON
	 *	Bit	 0, LCDON
	 *
	 *	@param bits
	 */
	public void setCOM(int bits) {
		COM = bits;

		if ( rtc.isRunning() == true && ((bits & Blink.BM_COMRESTIM) == Blink.BM_COMRESTIM)) {
			// Stop Real Time Clock (RESTIM = 1)
			rtc.stop();
			rtc.reset();
		}

		if ( rtc.isRunning() == false && ((bits & Blink.BM_COMRESTIM) == 0)) {
			// Real Time Clock is not running, and is asked to start (RESTIM = 0)... 
			rtc.reset();	// reset counters before starting RTC
			rtc.start();
		}
		
		if ( (bits & Blink.BM_COMRAMS) == Blink.BM_COMRAMS)
			// RAM is bound into lower 8K of segment 0
			RAMS = memory[0x20];
		else
			// ROM bank 0 is bound into lower 8K of segment 0
			RAMS = memory[0x00];		
	}

	/**
	 * Get Command Register status.
	 * 
	 * @return int
	 */
	public int getCOM() {
		return COM;
	}

	public static final int BM_COMSRUN = 0x80; // Bit 7, SRUN
	public static final int BM_COMSBIT = 0x40; // Bit 6, SBIT
	public static final int BM_COMOVERP = 0x20; // Bit 5, OVERP
	public static final int BM_COMRESTIM = 0x10; // Bit 4, RESTIM
	public static final int BM_COMPROGRAM = 0x08; // Bit 3, PROGRAM
	public static final int BM_COMRAMS = 0x04; // Bit 2, RAMS
	public static final int BM_COMVPPON = 0x02; // Bit 1, VPPON
	public static final int BM_COMLCDON = 0x01; // Bit 0, LCDON

	/** 
	 * RTC, BLINK Real Time Clock, updated each 5ms.
	 */
	private class Rtc extends TimerTask {

		Timer countRtc = null;

		private int tim0 = 0; // 5 millisecond period, counts to 199
		private int tim1 = 0; // 1 second period, counts to 59
		private int tim2 = 0; // 1 minutes period, counts to 255
		private int tim3 = 0; // 256 minutes period, counts to 255
		private int tim4 = 0; // 64K minutes period, counts to 31

		private boolean rtcRunning = false; // Rtc counting?

		private Rtc() {
			start();
		}

		/**
		 * Get current TIM0 counter from the RTC.
		 * 
		 * @return int
		 */
		public int getTim0() {
			return tim0;
		}

		/**
		 * Get current TIM1 counter from the RTC.
		 * 
		 * @return int
		 */
		public int getTim1() {
			return tim1;
		}

		/**
		 * Get current TIM2 counter from the RTC.
		 * 
		 * @return int
		 */
		public int getTim2() {
			return tim2;
		}

		/**
		 * Get current TIM3 counter from the RTC.
		 * 
		 * @return int
		 */
		public int getTim3() {
			return tim3;
		}

		/**
		 * Get current TIM4 counter from the RTC.
		 * 
		 * @return int
		 */
		public int getTim4() {
			return tim4;
		}

		/**
		 * Stop the Rtc counter, but don't reset the counters themselves.
		 */
		public void stop() {
			if (countRtc != null)
				countRtc.cancel();
			rtcRunning = false;
		}

		/**
		 * Start the Rtc counter immediately, and execute the run() method every
		 * 5 millisecond.
		 */
		public void start() {
			if (rtcRunning == false) {
				rtcRunning = true;
				countRtc = new Timer(true); // create Timer as a daemon...
				countRtc.scheduleAtFixedRate(this, 0, 5);
			}
		}

		/**
		 * Reset time counters. Performed when COM.RESTIM = 1.
		 */
		public void reset() {
			tim0 = tim1 = tim2 = tim3 = tim4 = 0;
		}

		/**
		 * Is the RTC running?
		 * 
		 * @return boolean
		 */
		public boolean isRunning() {
			return rtcRunning;
		}

		/**
		 * Execute the RTC counter each 5ms
		 * 
		 * @see java.lang.Runnable#run()
		 */
		public void run() {
			if (rtcRunning == true) {
				if (++tim0 > 199) {
					tim0 = 0; // 1 second has passed...
					if (++tim1 > 59) {
						tim1 = 0; // 1 minute has passed
						if (++tim2 > 255) {
							tim2 = 0; // 256 minutes has passed
							if (++tim3 > 255) {
								tim3 = 0; // 65536 minutes has passed
								if (++tim4 > 31) {
									tim4 = 0; // 65536 * 32 minutes has passed
								}
							}
						}
					}
				}
			}
		}
	} /* Rtc class */
}
