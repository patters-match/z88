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
		z88vm = vm; // know about the processor environment outside the BLINK

		// the segment register SR0 - SR3
		sR = new int[4];
		// all segment registers points at ROM bank 0
		for (int segment = 0; segment < sR.length; segment++) {
			sR[segment] = 0;
		}

		memory = new Bank[256]; // The Z88 memory addresses 256 banks = 4MB!
		nullBank = new Bank(Bank.EPROM);
		for (int bank = 0; bank < memory.length; bank++)
			memory[bank] = nullBank;

		rtc = new Rtc(); // start the Real Time Clock...
		z80Int = new Z80interrupt(); // start the INT signals each 10ms to Z80
	}

	/**
	 * Reference to the Z80 processor / Z88 virtual machine 
	 * (which the BLINK is collaborating with).
	 */
	private Z88 z88vm;

	/**
	 * The Real Time Clock (RTC) inside the BLINK.
	 */
	private Rtc rtc;

	/**
	 * The 10ms interupt line to the Z80 processor.
	 */
	private Z80interrupt z80Int;

	/**
	 * Main Blink Interrrupts (INT).
	 * 
	 * BIT 7, KWAIT  If set, reading the keyboard will Snooze
	 * BIT 6, A19    If set, an active high on A19 will exit Coma
	 * BIT 5, FLAP   If set, flap interrupts are enabled
	 * BIT 4, UART   If set, UART interrupts are enabled
	 * BIT 3, BTL    If set, battery low interrupts are enabled
	 * BIT 2, KEY    If set, keyboard interrupts (Snooze or Coma) are enabl.
	 * BIT 1, TIME   If set, RTC interrupts are enabled
	 * BIT 0, GINT   If clear, no interrupts get out of blink
	 */
	private int INT = 0;

	public static final int BM_INTKWAIT = 0x80;	// If set, reading the keyboard will Snooze
	public static final int BM_INTA19 = 0x40;	// If set, an active high on A19 will exit Coma
	public static final int BM_INTFLAP = 0x20;	// If set, flap interrupts are enabled
	public static final int BM_INTUART = 0x10;	// If set, UART interrupts are enabled
	public static final int BM_INTBTL = 0x08;	// If set, battery low interrupts are enabled
	public static final int BM_INTKEY = 0x04;	// If set, keyboard interrupts (Snooze or Coma) are enabl.
	public static final int BM_INTTIME = 0x02;	// If set, RTC interrupts are enabled
	public static final int BM_INTGINT = 0x01;	// If clear, no interrupts get out of blink

	/**
	 * Set main Blink Interrrupts (INT), Z80 OUT Write Register 
	 * 
	 * @param bits
	 */
	public void setInt(int bits) {
		INT = bits;
	}
	
	/**
	 * Return Timer Interrupt Status
	 * BIT 2, MIN, Set if minute interrupt has occurred
	 * BIT 1, SEC, Set if second interrupt has occurred
	 * BIT 0, TICK, Set if tick interrupt has occurred
	 * 
	 * @return int
	 */
	public int getTsta() {
		if ( (INT & BM_INTTIME) == BM_INTTIME) {
			return rtc.TSTA;	// RTC interrupts are enabled...
		} else {
			return 0;			// RTC interrupts are disabled...
		}
	}

	/**
	 * Set Timer interrupt acknowledge (TACK), Z80 OUT Write Register
	 * 
	 * BIT 2, MIN, Set to acknowledge minute interrupt
	 * BIT 1, SEC, Set to acknowledge
	 * BIT 0, TICK, Set to acknowledge tick interrupt
	 */
	public void setTack(int bits) {
		rtc.TACK = bits;

		// reset TSTA bits (the prev. raised interrupt get cleared) 
		rtc.TSTA &= ~bits;
	}

	/**
	 * Set Timer Interrupt Mask (TMK), Z80 OUT Write Register
	 *  
	 * BIT 2, MIN, Set to enable minute interrupt
	 * BIT 1, SEC, Set to enable second interrupt
	 * BIT 0, TICK, Set enable tick interrupt
	 */
	public void setTmk(int bits) {
		rtc.TMK = bits;
	}

	/**
	 * Get current TIM0 register from the RTC.
	 * 
	 * @return int
	 */
	public int getTim0() {
		return rtc.TIM0;
	}

	/**
	 * Get current TIM1 register from the RTC.
	 * 
	 * @return int
	 */
	public int getTim1() {
		return rtc.TIM1;
	}

	/**
	 * Get current TIM2 register from the RTC.
	 * 
	 * @return int
	 */
	public int getTim2() {
		return rtc.TIM2;
	}

	/**
	 * Get current TIM3 register from the RTC.
	 * 
	 * @return int
	 */
	public int getTim3() {
		return rtc.TIM3;
	}

	/**
	 * Get current TIM4 register from the RTC.
	 * 
	 * @return int
	 */
	public int getTim4() {
		return rtc.TIM4;
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
	public int readByte(int addr) {
		int segment = addr >>> 14; // bit 15 & 14 identifies segment

		// the OZ spends most of the time in segments 1 - 3,
		// therefore we should ask for this first...
		if (segment > 0) {
			return memory[sR[segment]].readByte(addr);
		} else {
			// Bank 0 is split into two 8K blocks.
			// Lower 8K is System Bank 0x00 (ROM on hard reset)
			// or 0x20 (RAM for Z80 sTACK and system variables)
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
	public void writeByte(int addr, int b) {
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

	public static final int BM_COMSRUN = 0x80; // Bit 7, SRUN
	public static final int BM_COMSBIT = 0x40; // Bit 6, SBIT
	public static final int BM_COMOVERP = 0x20; // Bit 5, OVERP
	public static final int BM_COMRESTIM = 0x10; // Bit 4, RESTIM
	public static final int BM_COMPROGRAM = 0x08; // Bit 3, PROGRAM
	public static final int BM_COMRAMS = 0x04; // Bit 2, RAMS
	public static final int BM_COMVPPON = 0x02; // Bit 1, VPPON
	public static final int BM_COMLCDON = 0x01; // Bit 0, LCDON

	/**
	 * Set Blink Command Register flags, port $B0
	 *	Bit	7, SRUN
	 *	Bit	6, SBIT
	 *	Bit	5, OVERP
	 *	Bit	4, RESTIM
	 *	Bit	3, PROGRAM
	 *	Bit	2, RAMS
	 *	Bit	1, VPPON
	 *	Bit	0, LCDON
	 *
	 *	@param bits
	 */
	public void setCom(int bits) {
		COM = bits;

		if (rtc.isRunning() == true
			&& ((bits & Blink.BM_COMRESTIM) == Blink.BM_COMRESTIM)) {
			// Stop Real Time Clock (RESTIM = 1)
			rtc.stop();
			rtc.reset();
		}

		if (rtc.isRunning() == false && ((bits & Blink.BM_COMRESTIM) == 0)) {
			// Real Time Clock is not running, and is asked to start (RESTIM = 0)... 
			rtc.reset(); // reset counters before starting RTC
			rtc.start();
		}

		if ((bits & Blink.BM_COMRAMS) == Blink.BM_COMRAMS)
			// Slot 0 RAM Bank 0x20 will be bound into lower 8K of segment 0
			RAMS = memory[0x20];
		else
			// Slot 0 ROM bank 0 is bound into lower 8K of segment 0
			RAMS = memory[0x00];
	}

	/** 
	 * RTC, BLINK Real Time Clock, updated each 5ms.
	 */
	private class Rtc extends TimerTask {

		Timer countRtc = null;

		/**
		 * Internal counter, 2 ticks = 1/100 second (10ms)
		 */
		private int tick = 0;

		/**
		 * TIM0, 5 millisecond period, counts to 199, Z80 IN Register
		 */
		private int TIM0 = 0;
		
		/**
		 * TIM1, 1 second period, counts to 59, Z80 IN Register
		 */
		private int TIM1 = 0;
		 
		/**
		 * TIM2, 1 minutes period, counts to 255, Z80 IN Register
		 */
		private int TIM2 = 0;
		
		/**
		 * TIM3, 256 minutes period, counts to 255, Z80 IN Register
		 */
		private int TIM3 = 0;

		/**
		 * TIM4, 64K minutes period, counts to 31, Z80 IN Register
		 */
		private int TIM4 = 0;
		
		/**
		 * TSTA, Timer interrupt status, Z80 IN Read Register
		 */
		private int TSTA = 0;

		// Set if minute interrupt has occurred
		public static final int BM_TSTAMIN = 0x04;
		// Set if second interrupt has occurred
		public static final int BM_TSTASEC = 0x02;
		// Set if tick interrupt has occurred
		public static final int BM_TSTATICK = 0x01;

		/**
		 * TMK, Timer interrupt mask, Z80 OUT Write Register
		 */
		private int TMK = 0;
		 
		// Set to enable minute interrupt
		public static final int BM_TMKMIN = 0x04;
		// Set to enable second interrupt
		public static final int BM_TMKSEC = 0x02;
		// Set to enable tick interrupt
		public static final int BM_TMKTICK = 0x01;

		/**
		 * TACK, Timer interrupt acknowledge, Z80 OUT Write Register
		 */
		private int TACK = 0;
		
		// Set to acknowledge minute interrupt
		public static final int BM_TACKMIN = 0x04; 
		// Set to acknowledge second interrupt
		public static final int BM_TACKSEC = 0x02; 
		// Set to acknowledge tick interrupt
		public static final int BM_TACKTICK = 0x01;

		private boolean rtcRunning = false; // Rtc counting?

		private Rtc() {
			TMK = BM_TMKMIN | BM_TMKSEC | BM_TMKTICK;
			// enable minute, second and 1/100 second interrups
			TSTA = TACK = 0;
			TACK = BM_TACKMIN | BM_TACKSEC | BM_TACKTICK;
			// first interrupt events needs an acknowledge!

			start();
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
			TIM0 = TIM1 = TIM2 = TIM3 = TIM4 = 0;
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
			if (rtcRunning == false)
				return;

			if (++tick > 1) {
				// 1/100 second has passed
				tick = 0;
				if ((TMK & BM_TMKTICK) == BM_TMKTICK) {
					// 1/100 second interrupts (ticks) are enabled...
					// flag that a tick interrupted, but only
					// if a previous tick interrupt has been acknowledged...
					// (ie. TSTA.BM_TSTATICK = 0)
					if ((TSTA & BM_TSTATICK) == 0) {
						// a previous tick interrupt has been acknowledged
						TSTA |= BM_TSTATICK; // TSTA.BM_TSTATICK = 1
						TACK &= ~BM_TACKTICK; // TACK.BM_TACKTICK = 0 (reset prev. acknowledge)
					}
				}
			}

			if (++TIM0 > 199) {
				// 1 second has passed...
				TIM0 = 0;
				if ((TMK & BM_TMKSEC) == BM_TMKSEC) {
					// second interrupts are enabled...
					// flag that a second interrupted, but only
					// if a previous interrupt has been acknowledged...
					// (ie. TSTA.BM_TSTASEC = 0)
					if ((TSTA & BM_TSTASEC) == 0) {
						// a previous second interrupt has been acknowledged
						TSTA |= BM_TSTASEC; // TSTA.BM_TSTASEC = 1
						TACK &= ~BM_TACKSEC; // TACK.BM_TACKSEC = 0 (reset prev. acknowledge)
					}
				}

				if (++TIM1 > 59) {
					// 1 minute has passed
					TIM1 = 0;
					if ((TMK & BM_TMKMIN) == BM_TMKMIN) {
						// minute interrupts are enabled...
						// flag that a minute interrupted, but only
						// if a previous interrupt has been acknowledged...
						// (ie. TSTA.BM_TSTAMIN = 0)
						if ((TSTA & BM_TSTAMIN) == 0) {
							// a previous minute interrupt has been acknowledged
							TSTA |= BM_TSTAMIN; // TSTA.BM_TSTAMIN = 1
							TACK &= ~BM_TACKMIN; // TACK.BM_TACKMIN = 0 (reset prev. acknowledge)
						}
					}

					if (++TIM2 > 255) {
						TIM2 = 0; // 256 minutes has passed
						if (++TIM3 > 255) {
							TIM3 = 0; // 65536 minutes has passed
							if (++TIM4 > 31) {
								TIM4 = 0; // 65536 * 32 minutes has passed
							}
						}
					}
				}
			}
		}
	} /* Rtc class */

	/** 
	 * The BLINK supplies the INT signal to the Z80 processor.
	 * An INT is fired each 10ms, which the Z80 responds to through IM 1
	 * (executing an RST 38H instruction).
	 */
	private class Z80interrupt extends TimerTask {

		Timer intIm1 = null;

		private Z80interrupt() {
			start();
		}

		/**
		 * Stop the 10ms interrupt. 
		 * (INT.GINT = 0, no interrupts get out of BLINK)
		 */
		public void stop() {
			if (intIm1 != null)
				intIm1.cancel();
		}

		/**
		 * Start the Rtc counter immediately, and execute the run() method every
		 * 5 millisecond.
		 */
		public void start() {
			intIm1 = new Timer(true); // create Timer as a daemon...
			intIm1.scheduleAtFixedRate(this, 0, 10);
		}

		/**
		 * Send an INT each 10ms to the Z80 processor...
		 * 
		 * @see java.lang.Runnable#run()
		 */
		public void run() {
			if (z88vm.interruptTriggered() == false)
				// signal only if no interrupt is being executed...
				z88vm.setInterruptSignal();
		}
	} /* Z80interrupt class */
}
