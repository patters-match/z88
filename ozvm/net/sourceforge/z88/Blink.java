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
		public void resetRtc() {
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
			if (rtcRunning == false) {
				resetRtc(); // counters must be 0 when not counting...
			} else {
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

	/**
	 * The RTC inside the BLINK...
	 */
	private Rtc rtc;

	/**
	 * Blink class default constructor.
	 */
	Blink() {
		// the segment register SR0 - SR3
		sR = new int[4];
		// all segment registers points at ROM bank 0
		for (int segment = 0; segment < sR.length; segment++) {
			sR[segment] = 0;
		}

		rtc = new Rtc(); // start the Real Time Clock...
	}

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
	 * Get current System Bank for lower 8K of segment 0. 
	 * References bank 0x00 or 0x20 of slot 0.
	 * 
	 * @return Bank
	 */
	public Bank getRAMS() {
		return RAMS;
	}

	/**
	 * Set System Bank binding for lower 8K of segment 0. 
	 * References bank 0x00 or 0x20 of slot 0.
	 * 
	 */
	public void setRAMS(Bank b) {
		RAMS = b;
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
	 * On the Z88, the 64K is split into 4 sections of 16K segments.
	 * Any of the 256 x 16K banks can be bound into the address space on the
	 * Z88. Bank 0 is special, however. Please refer to hardware section of the
	 * Developer's Notes.
	 */
	public void setSegmentBank(int segment, int BankNo) {
		sR[segment % 4] = (BankNo % 256);
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
}
