/*
 * Blink.java
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

import java.util.Timer;
import java.util.TimerTask;


/**
 * Blink chip, the "body" of the Z88, defining the surrounding hardware
 * of the Z80 "mind" processor.
 */
public final class Blink {

	/** Blink Snooze state */
	private boolean snooze;

	/** Blink Coma state */
	private boolean coma;

	/**
	 * Access to the Z88 Memory Model
	 */
	private Memory memory;

	/**
	 * The main Timer daemon that runs the Rtc clock and sends 10ms interrupts
	 * to the Z80 virtual processor.
	 */
	private Timer rtcTimer;

	/**
	 * The Real Time Clock (RTC) inside the BLINK.
	 */
	private Rtc rtc;

	/**
	 * Main Blink Interrrupts (INT).
	 *
	 * <PRE>
	 * BIT 7, KWAIT  If set, reading the keyboard will Snooze
	 * BIT 6, A19    If set, an active high on A19 will exit Coma
	 * BIT 5, FLAP   If set, flap interrupts are enabled
	 * BIT 4, UART   If set, UART interrupts are enabled
	 * BIT 3, BTL    If set, battery low interrupts are enabled
	 * BIT 2, KEY    If set, keyboard interrupts (Snooze or Coma) are enabl.
	 * BIT 1, TIME   If set, RTC interrupts are enabled
	 * BIT 0, GINT   If clear, no interrupts get out of blink
	 * </PRE>
	 */
	private int INT;

	public static final int BM_INTKWAIT = 0x80;	// Bit 7, If set, reading the keyboard will Snooze
	public static final int BM_INTA19 = 0x40;	// Bit 6, If set, an active high on A19 will exit Coma
	public static final int BM_INTFLAP = 0x20;	// Bit 5, If set, flap interrupts are enabled
	public static final int BM_INTUART = 0x10;	// Bit 4, If set, UART interrupts are enabled
	public static final int BM_INTBTL = 0x08;	// Bit 3, If set, battery low interrupts are enabled
	public static final int BM_INTKEY = 0x04;	// Bit 2, If set, keyboard interrupts (Snooze or Coma) are enabl.
	public static final int BM_INTTIME = 0x02;	// Bit 1, If set, RTC interrupts are enabled
	public static final int BM_INTGINT = 0x01;	// Bit 0, If clear, no interrupts get out of blink

	/**
	 * Acknowledge Main Blink Interrrupts (INT):
	 * BIT 6, A19    Acknowledge active high on A19
	 */
	public static final int BM_ACKA19 = 0x40;

	/**
	 * Acknowledge Main Blink Interrrupts (INT):
	 * BIT 5, FLAP   Acknowledge Flap interrupts
	 */
	public static final int BM_ACKFLAP = 0x20;

	/**
	 * Acknowledge Main Blink Interrrupts (INT):
	 * BIT 3, BTL    Acknowledge battery low interrupt
	 */
	public static final int BM_ACKBTL = 0x08;

	/**
	 * Acknowledge Main Blink Interrrupts (INT):
	 * BIT 2, KEY    Acknowledge keyboard interrupt
	 */
	public static final int BM_ACKKEY = 0x04;

	/**
	 * Acknowledge Main Blink Interrrupts (INT):
	 * Bit 0, TIME   Acknowledge TIME interrupt
	 */
	public static final int BM_ACKTIME = 0x01;

	/**
	 * Main Blink Interrupt Status (STA)
	 *
	 * <PRE>
	 * Bit 7, FLAPOPEN, If set, flap open, else flap closed
	 * Bit 6, A19, If set, high level on A19 occurred during coma
	 * Bit 5, FLAP, If set, positive edge has occurred on FLAPOPEN
	 * Bit 4, UART, If set, an enabled UART interrupt is active
	 * Bit 3, BTL, If set, battery low pin is active
	 * Bit 2, KEY, If set, a column has gone low in snooze (or coma)
	 * Bit 1, not defined.
	 * Bit 0, TIME, If set, an enabled TSTA interrupt is active
	 * </PRE>
	 */
	private int STA;

	public static final int BM_STAFLAPOPEN = 0x80;	// Bit 7, If set, flap open, else flap closed
	public static final int BM_STAA19 = 0x40;	// Bit 6, If set, high level on A19 occurred during coma
	public static final int BM_STAFLAP = 0x20;	// Bit 5, If set, positive edge has occurred on FLAPOPEN
	public static final int BM_STAUART = 0x10;	// Bit 4, If set, an enabled UART interrupt is active
	public static final int BM_STABTL = 0x08;	// Bit 3, If set, battery low pin is active
	public static final int BM_STAKEY = 0x04;	// Bit 2, If set, a column has gone low in snooze (or coma)
	public static final int BM_STATIME = 0x01;	// Bit 0, If set, an enabled TSTA interrupt is active

	/**
	 * LORES0 (PB0, 16bits register).<br>
	 * The 6 * 8 pixel per char User Defined Fonts.
	 */
	private int PB0;

	/**
	 * LORES1 (PB1, 16bits register).<br>
	 * The 6 * 8 pixel per char fonts.
	 */
	private int PB1;

	/**
	 * HIRES0 (PB2 16bits register)
     * (The 8 * 8 pixel per char PipeDream Map)
	 */
	private int PB2;

	/**
	 * HIRES1 (PB3, 16bits register)
	 * (The 8 * 8 pixel per char fonts for the OZ window)
	 */
	private int PB3;

	/**
	 * Screen Base Register (16bits register)
	 * (The Screen base File (2K size), containing char info about screen)
	 * If this register is 0, then the system cannot render the pixel screen.
	 */
	private int SBR;

	/**
	 * System bank for lower 8K of segment 0.
	 * References bank 0x00 or 0x20 of slot 0.
	 */
	private Bank RAMS;

	/**
	 * Segment register array for SR0 - SR3.
	 *
	 * <PRE>
	 * Segment register 0, SR0, bank binding for 0x2000 - 0x3FFF
	 * Segment register 1, SR1, bank binding for 0x4000 - 0x7FFF
	 * Segment register 2, SR2, bank binding for 0x8000 - 0xBFFF
	 * Segment register 3, SR3, bank binding for 0xC000 - 0xFFFF
	 * </PRE>
	 *
	 * Any of the registers contains a bank number, 0 - 255 that
	 * is currently bound into the corresponding segment in the
	 * Z80 address space.
	 */
	private int sR[];

	/**
	 * BLINK Command Register.
	 *
	 * <PRE>
	 *	Bit	 7, SRUN
	 *	Bit	 6, SBIT
	 *	Bit	 5, OVERP
	 *	Bit	 4, RESTIM
	 *	Bit	 3, PROGRAM
	 *	Bit	 2, RAMS
	 *	Bit	 1, VPPON
	 *	Bit	 0, LCDON
	 * </PRE>
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
	 * BLINK Eprom Programming Register.
	 *
	 * <PRE>
	 *	Bit	 7, PD1
	 *	Bit	 6, PD0
	 *	Bit	 5, PGMD
	 *	Bit	 4, EOED
	 *	Bit	 3, SE3D
	 *	Bit	 2, PGMP
	 *	Bit	 1, EOEP
	 *	Bit	 0, SE3P
	 * </PRE>
	 */
	private int EPR;

	public static final int BM_EPRPD1 = 0x80; // Bit 7, PD1
	public static final int BM_EPRPD0 = 0x40; // Bit 6, PD0
	public static final int BM_EPRPGMD = 0x20; // Bit 5, PGMD
	public static final int BM_EPREOED = 0x10; // Bit 4, EOED
	public static final int BM_EPRSE3D = 0x08; // Bit 3, SE3D
	public static final int BM_EPRPGMP = 0x04; // Bit 2, PGMP
	public static final int BM_EPREOEP = 0x02; // Bit 1, EOEP
	public static final int BM_EPRSE3P = 0x01; // Bit 0, SE3P

	/**
	 * Blink class default constructor.
	 */
	public Blink() {
		super();

		coma = false;
		snooze = false;

		memory = Z88.getInstance().getMemory();	// access to Z88 memory model (4Mb)
		RAMS = memory.getBank(0); // point at ROM bank 0 (null at the moment)

		// the segment register SR0 - SR3
		sR = new int[4];

		rtcTimer = new Timer(true);
		rtc = new Rtc(); 				// the Real Time Clock counter, not yet started...

		resetBlinkRegisters();
	}


	/**
	 * Reset Blink Registers to Power-On-State.
	 */
	public void resetBlinkRegisters() {
		PB0 = PB1 = PB2 = PB3 = SBR = 0;
		COM = INT = STA = 0;
		rtc.TMK = rtc.TSTA = 0;
		rtc.TIM0 = rtc.TIM1 = rtc.TIM2 = rtc.TIM3 = rtc.TIM4 = 0;

		// SR0, SR1, SR2, SR3 = 0
		for (int segment = 0; segment < sR.length; segment++) {
			sR[segment] = 0;
		}
	}


	/**
	 * Set main Blink Interrrupts (INT), Z80 OUT Write Register.
	 *
	 * <pre>
	 * BIT 7, KWAIT  If set, reading the keyboard will Snooze
	 * BIT 6, A19    If set, an active high on A19 will exit Coma
	 * BIT 5, FLAP   If set, flap interrupts are enabled
	 * BIT 4, UART   If set, UART interrupts are enabled>
	 * BIT 3, BTL    If set, battery low interrupts are enabled
	 * BIT 2, KEY    If set, keyboard interrupts (Snooze or Coma) are enabled
	 * BIT 1, TIME   If set, RTC interrupts are enabled
	 * BIT 0, GINT   If clear, no interrupts get out of blink
	 * </pre>
	 *
	 * @param bits
	 */
	public void setBlinkInt(int bits) {
		INT = bits;
	}

	/**
	 * Get main Blink Interrrupts (INT), Z80 OUT Write Register.
	 *
	 * <pre>
	 * BIT 7, KWAIT  If set, reading the keyboard will Snooze
	 * BIT 6, A19    If set, an active high on A19 will exit Coma
	 * BIT 5, FLAP   If set, flap interrupts are enabled
	 * BIT 4, UART   If set, UART interrupts are enabled>
	 * BIT 3, BTL    If set, battery low interrupts are enabled
	 * BIT 2, KEY    If set, keyboard interrupts (Snooze or Coma) are enabled
	 * BIT 1, TIME   If set, RTC interrupts are enabled
	 * BIT 0, GINT   If clear, no interrupts get out of blink
	 * </pre>
	 *
	 * @return INT Blink Register
	 */
   	public int getBlinkInt() {
		return INT;
	}


	/**
	 * Set Main Blink Interrupt Acknowledge (ACK), Z80 OUT Register
	 *
	 * <PRE>
	 * BIT 6, A19    Acknowledge active high on A19
	 * BIT 5, FLAP   Acknowledge Flap interrupts
	 * BIT 3, BTL    Acknowledge battery low interrupt
	 * BIT 2, KEY    Acknowledge keyboard interrupt
	 * </PRE>
	 *
	 * @param bits
	 */
	public void setBlinkAck(int bits) {
		if ((STA & (bits & 0xFF)) == 0)
			STA &= ~(bits & 0xff);	// Acknowledge (and clear) occurred STA interrupts (NAND)
	}

	/**
	 * Get Main Blink Interrupt Status (STA).
	 *
	 * <PRE>
	 * Bit 7, FLAPOPEN, If set, flap open, else flap closed
	 * Bit 6, A19, If set, high level on A19 occurred during coma
	 * Bit 5, FLAP, If set, positive edge has occurred on FLAPOPEN
	 * Bit 4, UART, If set, an enabled UART interrupt is active
	 * Bit 3, BTL, If set, battery low pin is active
	 * Bit 2, KEY, If set, a column has gone low in snooze (or coma)
	 * </PRE>
	 */
	public int getBlinkSta() {
		return STA;
	}

	/**
	 * Set Main Blink Interrupt Status (STA).
	 * (Used for restore machine state functionality)
	 *
	 * <PRE>
	 * Bit 7, FLAPOPEN, If set, flap open, else flap closed
	 * Bit 6, A19, If set, high level on A19 occurred during coma
	 * Bit 5, FLAP, If set, positive edge has occurred on FLAPOPEN
	 * Bit 4, UART, If set, an enabled UART interrupt is active
	 * Bit 3, BTL, If set, battery low pin is active
	 * Bit 2, KEY, If set, a column has gone low in snooze (or coma)
	 * Bit 1, not defined.
	 * Bit 0, TIME, If set, an enabled TSTA interrupt is active
	 * </PRE>
	 */
	public void setBlinkSta(int staBits) {
		STA = staBits;
	}

	/**
	 * Return Timer Interrupt Status (TSTA).
	 *
	 * <PRE>
	 * BIT 2, MIN, Set if minute interrupt has occurred
	 * BIT 1, SEC, Set if second interrupt has occurred
	 * BIT 0, TICK, Set if tick interrupt has occurred
	 * </PRE>
	 *
	 * @return TSTA
	 */
	public int getBlinkTsta() {
        return rtc.TSTA;
	}

	/**
	 * Set Timer Interrupt Status (TSTA).
	 * (Used for restore machine state functionality)
	 *
	 * <PRE>
	 * BIT 2, MIN, Set if minute interrupt has occurred
	 * BIT 1, SEC, Set if second interrupt has occurred
	 * BIT 0, TICK, Set if tick interrupt has occurred
	 * </PRE>
	 *
	 * @return TSTA
	 */
	public void setBlinkTsta(int tstaBits) {
        rtc.TSTA = tstaBits;
	}

	/**
	 * Set Timer Interrupt Acknowledge (TACK), Z80 OUT Write Register.
	 *
	 * <PRE>
	 * BIT 2, MIN, Set to acknowledge minute interrupt
	 * BIT 1, SEC, Set to acknowledge second interrupt
	 * BIT 0, TICK, Set to acknowledge tick interrupt
	 * </PRE>
	 */
	public void setBlinkTack(int bits) {
		if ((rtc.TSTA & (bits & 0xff)) != 0 )
			rtc.TSTA &= ~(bits & 0xff);		// reset TSTA interrupt
	}

	/**
	 * Set Timer Interrupt Mask (TMK), Z80 OUT Write Register
	 *
	 * <PRE>
	 * BIT 2, MIN, Set to enable minute interrupt
	 * BIT 1, SEC, Set to enable second interrupt
	 * BIT 0, TICK, Set enable tick interrupt
	 * </PRE>
	 */
	public void setBlinkTmk(int bits) {
		rtc.TMK = bits;
	}

	/**
	 * Get Timer Interrupt Mask (TMK), Z80 OUT Write Register
	 *
	 * <PRE>
	 * BIT 2, MIN, Set to enable minute interrupt
	 * BIT 1, SEC, Set to enable second interrupt
	 * BIT 0, TICK, Set enable tick interrupt
	 * </PRE>
	 */
	public int getBlinkTmk() {
		return rtc.TMK;
	}

	/**
	 * Get current TIM0 register from the RTC.
	 *
	 * @return int
	 */
	public int getBlinkTim0() {
		return rtc.TIM0;
	}

	/**
	 * set current Real Time Clock TIM0 register.
	 * (Used for restore machine state functionality)
	 */
	public void setBlinkTim0(int tim0Bits) {
		rtc.TIM0 = tim0Bits;
	}

	/**
	 * Get current TIM1 register from the RTC.
	 *
	 * @return int
	 */
	public int getBlinkTim1() {
		return rtc.TIM1;
	}

	/**
	 * set current Real Time Clock TIM1 register.
	 * (Used for restore machine state functionality)
	 */
	public void setBlinkTim1(int bits) {
		rtc.TIM1 = bits;
	}

	/**
	 * Get current TIM2 register from the RTC.
	 *
	 * @return int
	 */
	public int getBlinkTim2() {
		return rtc.TIM2;
	}

	/**
	 * set current Real Time Clock TIM2 register.
	 * (Used for restore machine state functionality)
	 */
	public void setBlinkTim2(int bits) {
		rtc.TIM2 = bits;
	}

	/**
	 * Get current TIM3 register from the RTC.
	 *
	 * @return int
	 */
	public int getBlinkTim3() {
		return rtc.TIM3;
	}

	/**
	 * set current Real Time Clock TIM3 register.
	 * (Used for restore machine state functionality)
	 */
	public void setBlinkTim3(int bits) {
		rtc.TIM3 = bits;
	}

	/**
	 * Get current TIM4 register from the RTC.
	 *
	 * @return int
	 */
	public int getBlinkTim4() {
		return rtc.TIM4;
	}

	/**
	 * set current Real Time Clock TIM4 register.
	 * (Used for restore machine state functionality)
	 */
	public void setBlinkTim4(int bits) {
		rtc.TIM4 = bits;
	}

	/**
	 * Set LORES0 (PB0, 16bits register).<br>
	 * The 6 * 8 pixel per char User Defined Fonts.
	 */
	public void setBlinkPb0(int bits) {
		PB0 = bits;
	}

	/**
	 * Get LORES0 (PB0, 16bits register).<br>
	 * The 6 * 8 pixel per char User Defined Fonts.
	 */
	public int getBlinkPb0() {
		return PB0;
	}

	/**
	 * Get Address of LORES0 (PB0 16bits register) in 24bit extended address format.<br>
	 * The 6 * 8 pixel per char User Defined Fonts.
	 */
	public int getBlinkPb0Address() {
		int extAddressBank = (PB0 << 3) & 0xF700;
		int extAddressOffset = (PB0 << 1) & 0x003F;

		return (extAddressBank | extAddressOffset) << 8;
	}

	/**
	 * Set LORES1 (PB1, 16bits register).<br>
	 * The 6 * 8 pixel per char fonts.
	 */
	public void setBlinkPb1(int bits) {
		PB1 = bits;
	}

	/**
	 * Get LORES1 (PB1, 16bits register).<br>
	 * The 6 * 8 pixel per char fonts.
	 */
	public int getBlinkPb1() {
		return PB1;
	}

	/**
	 * Get Address of LORES1 (PB1 16bits register) in 24bit extended address format.<br>
	 * The 6 * 8 pixel per char fonts.
	 */
	public int getBlinkPb1Address() {
		int extAddressBank = (PB1 << 6) & 0xFF00;
		int extAddressOffset = (PB1 << 4) & 0x0030;

		return (extAddressBank | extAddressOffset) << 8;
	}

	/**
	 * Set HIRES0 (PB2 16bits register)
	 * (The 8 * 8 pixel per char PipeDream Map)
	 */
	public void setBlinkPb2(int bits) {
		PB2 = bits;
	}

	/**
	 * Get HIRES0 (PB2 16bits register)
	 * (The 8 * 8 pixel per char PipeDream Map)
	 */
	public int getBlinkPb2() {
		return PB2;
	}

	/**
	 * Get Address of HIRES0 (PB2 register) in 24bit extended address format.
	 * (The 8 * 8 pixel per char PipeDream Map)
	 */
	public int getBlinkPb2Address() {
		int extAddressBank = (PB2 << 7) & 0xFF00;
		int extAddressOffset = (PB2 << 5) & 0x0020;

		return (extAddressBank | extAddressOffset) << 8;
	}

	/**
	 * Set HIRES1 (PB3, 16bits register)
	 * (The 8 * 8 pixel per char fonts for the OZ window)
	 */
	public void setBlinkPb3(int bits) {
		PB3 = bits;
	}

	/**
	 * Set HIRES1 (PB3, 16bits register)
	 * (The 8 * 8 pixel per char fonts for the OZ window)
	 */
	public int getBlinkPb3() {
		return PB3;
	}

	/**
	 * Get Address of HIRES1 (PB3 16bits register) in 24bit extended address format.
	 * (The 8 * 8 pixel per char fonts for the OZ window)
	 */
	public int getBlinkPb3Address() {
		int extAddressBank = (PB3 << 5) & 0xFF00;
		int extAddressOffset = (PB3 << 3) & 0x0038;

		return (extAddressBank | extAddressOffset) << 8;
	}


	/**
	 * Set Screen Base Register (16bits register)
	 * (The Screen base File (2K size), containing char info about screen)
	 * If this register is 0, then the system cannot render the pixel screen.
	 */
	public void setBlinkSbr(int bits) {
		SBR = bits;
	}

	/**
	 * Get Screen Base Register (16bits register)
	 * (The Screen base File (2K size), containing char info about screen)
	 * If this register is 0, then the system cannot render the pixel screen.
	 */
	public int getBlinkSbr() {
		return SBR;
	}

	/**
	 * Get Screen Base in 24bit extended address format.
	 * (The Screen base File (2K size), containing char info about screen)
	 * If this register is 0, then the system cannot render the pixel screen.
	 */
	public int getBlinkSbrAddress() {
		int extAddressBank = (SBR << 5) & 0xFF00;
		int extAddressOffset = (SBR << 3) & 0x0038;

		return (extAddressBank | extAddressOffset) << 8;
	}


	/**
	 * Signal to the Z80 processor that a key was pressed. The
	 * internal state machine inside the Blink resolves the
	 * snooze state or coma state and fires KEY interrupts,
	 * if enabled.
	 *
	 * This method is called from the Z88Keyboard thread, and will
	 * awake Z80Processor thread (if the Z88 was snoozing
	 * or in coma).
	 */
	public synchronized void signalKeyPressed() {
        Z80Processor z80 = Z88.getInstance().getProcessor();

		// processor snooze always awakes on a key press (even if INT.GINT = 0)
		awakeFromSnooze();

		if ( (INT & BM_INTKEY) == BM_INTKEY & ((STA & BM_STAKEY) == 0)) {
			// If keyboard interrupts are enabled, then signal that a key was pressed.

			if ((INT & BM_INTGINT) == BM_INTGINT) {
				// But only if the interrupt is allowed to escape the Blink...
				if (coma == true) {
				    // I register hold the address lines to be read
				    if ( Z88.getInstance().getKeyboard().scanKeyRow(z80.I()) == z80.I()) {
    				    awakeFromComa();
    			    }
				} else {
	    			STA |= BM_STAKEY;
			    }

			    // Signal INT interrupt when KEY interrupts are enabled
			    Z88.getInstance().getProcessor().setIntSignal();
			}
		}
	}


	/**
	 * Fetch a keypress from the specified row(s) matrix, or 0 for all rows.<br>
	 * Interface call for IN r,(B2h).<br>
	 *
	 * This method is executed through the Z80Processor thread.
	 * If Blink KWAIT is enabled, the Z80 processor will snooze and wait for a
	 * key press interrupt from the Blink.
	 *
	 * @param row, eg @10111111, or 0 for all rows.
	 * @return int keycolumn status of row or merge of columns for specified rows.
	 */
	public synchronized int getBlinkKbd(int row) {
		if ( (INT & Blink.BM_INTKWAIT) != 0 ) {
		    try {
			    enableSnooze();
			} catch (InterruptedException ie) {
			}

	        Z88.getInstance().getProcessor().setIntSignal();
	    }

		return Z88.getInstance().getKeyboard().scanKeyRow(row);
	}


	/**
	 * Get current bank [0; 255] binding in segments [0; 3].
	 *
	 * On the Z88, the 64K is split into 4 sections of 16K segments.
	 * Any of the 256 16K banks can be bound into the address space
	 * on the Z88. Bank 0 is special, however.
	 * Please refer to hardware section of the Developer's Notes.
	 *
	 * @return int
	 */
	public int getSegmentBank(final int segment) {
		return sR[segment & 0x03];
	}


	/**
	 * Bind bank [0-255] to segments [0-3] in the Z80 address space.
	 *
	 * On the Z88, the 64K is split into 4 sections of 16K segments. Any of the
	 * 256 x 16K banks can be bound into the address space on the Z88. Bank 0 is
	 * special, however. Please refer to hardware section of the Developer's
	 * Notes.
	 */
	public void setSegmentBank(final int segment, final int BankNo) {
		sR[segment & 0x03] = BankNo;
	}

	/**
	 * Decode Z80 Address Space to extended Blink Address (bank,offset).
	 *
	 * @param pc 16bit word that points into Z80 64K Address Space
	 * @return int 24bit extended address (bank number, bank offset)
	 */
	public int decodeLocalAddress(int pc) {
		int bankno;

		if (pc > 0x3FFF) {
			bankno = sR[pc >>> 14];
		} else {
			if (pc < 0x2000)
				// return lower 8K Bank binding
				// Lower 8K is System Bank 0x00 (ROM on hard reset)
				// or 0x20 (RAM for Z80 stack and system variables)
				if ((COM & Blink.BM_COMRAMS) == Blink.BM_COMRAMS)
					bankno = 0x20;	// RAM Bank 20h
				else
					bankno = 0x00;	// ROM bank 00h
			else {
				// 0x2000 <= pc <= 0x3FFF
				bankno = sR[0] & 0xFE; // banks are always even in SR0..
				if ((sR[0] & 1) == 0) {
					// lower 8K of even bank bound into upper 8K of segment 0
					// (relocate bank offset pointer to lower 8K)
					pc &= 0x1FFF;
				}
			}
		}

		return (bankno << 16) | (pc & 0x3FFF);
	}

	/**
	 * Decode Z88 Extended Blink Address (bank,offset) into
	 * specified Z80 Address Space segment (0 - 3)
	 *
	 * @param extaddr 24bit extended address (bank number & bank offset)
	 * @return int 16bit word that points into Z80 64K Address Space
	 */
	public int decodeExtendedAddress(int extaddr, int segment) {
		segment &= 0x03; // there's only 4 segments in Z80 address space..

		if (segment > 0) {
			return (extaddr & 0x003fff) | (segment << 14);
		} else{
			return (extaddr & 0x001fff) | 0x2000;
		}
	}

	/**
	 * Read byte from Z80 virtual memory model. <addr> is a 16bit word
	 * that points into the Z80 64K address space.
	 *
	 * On the Z88, the 64K is split into 4 sections of 16K segments.
	 * Any of the 256 16K banks can be bound into the address space
	 * on the Z88. Bank 0 is special, however.
	 *
	 * Please refer to hardware section of the Developer's Notes.
	 *
	 * @param addr 16bit word that points into Z80 64K Address Space
	 * @return byte at bank, mapped into segment for specified address
	 */
	public final int readByte(final int addr) {
		if (addr > 0x3FFF) {
			return memory.getBank(sR[addr >>> 14]).readByte(addr);
		} else {
			if (addr < 0x2000)
				// return lower 8K Bank binding
				// Lower 8K is System Bank 0x00 (ROM on hard reset)
				// or 0x20 (RAM for Z80 stack and system variables)
				return RAMS.readByte(addr);
			else {
				if ((sR[0] & 1) == 0)
					// lower 8K of even bank bound into upper 8K of segment 0
					return memory.getBank(sR[0] & 0xFE).readByte(addr & 0x1FFF);
				else
					// upper 8K of even bank bound into upper 8K of segment 0
					// addr <= 0x3FFF...
					return memory.getBank(sR[0] & 0xFE).readByte(addr);
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
	 *
	 * Please refer to hardware section of the Developer's Notes.
	 *
	 * @param addr 16bit word that points into Z80 64K Address Space
	 * @param b byte to be written into Z80 64K Address Space
	 */
	public final void writeByte(final int addr, final int b) {
		if (addr > 0x3FFF) {
			// write byte to segments 1 - 3
			memory.getBank(sR[addr >>> 14]).writeByte(addr, b);
		} else {
			if (addr < 0x2000) {
				// return lower 8K Bank binding
				// Lower 8K is System Bank 0x00 (ROM on hard reset)
				// or 0x20 (RAM for Z80 stack and system variables)
				RAMS.writeByte(addr, b);
			} else {
				Bank bank = memory.getBank(sR[0] & 0xFE);
				if ((sR[0] & 1) == 0) {
					// lower 8K of even bank bound into upper 8K of segment 0
					bank.writeByte(addr & 0x1FFF, b);
				} else {
					// upper 8K of even bank bound into upper 8K of segment 0
					// addr <= 0x3FFF...
					bank.writeByte(addr, b);
				}
			}
		}
	}

	/**
	 * Read word (16bits) from Z80 virtual memory model.
	 * <addr> is a 16bit word that points into the Z80 64K address space.
	 *
	 * 16bit word fetches across bank boundaries are automatically handled.
	 *
	 * On the Z88, the 64K is split into 4 sections of 16K segments.
	 * Any of the 256 16K banks can be bound into the address space
	 * on the Z88. Bank 0 is special, however.
	 *
	 * Please refer to hardware section of the Developer's Notes.
	 *
	 * @param addr 16bit word that points into Z80 64K Address Space
	 * @return word at bank, mapped into segment for specified address
	 */
	public final int readWord(int addr) {
		return (readByte(addr+1) << 8) | readByte(addr);
	}

	/**
	 * Write word (16bits) to Z80 virtual memory model.
	 *
	 * 16bit word write across bank boundaries are automatically handled.
	 *
	 * On the Z88, the 64K is split into 4 sections of 16K segments.
	 * Any of the 256 16K banks can be bound into the address space
	 * on the Z88. Bank 0 is special, however.
	 *
	 * Please refer to hardware section of the Developer's Notes.
	 *
	 * @param addr 16bit word that points into Z80 64K Address Space
	 * @param w word to be written into Z80 64K Address Space
	 */
	public final void writeWord(int addr, final int w) {
		writeByte(addr, w);
		writeByte(addr+1, w >>> 8);
	}


	/**
	 * Add the lost time to TIMx registers, which means
	 * when a virtual machine was stopped (including RTC), time
	 * continues to run on the host operating system.
	 *
	 * Add the time gone to the TIMx registers from the previous stop
	 * until NOW.
	 */
	private void adjustLostTime() {
		long rtcElapsedTime = 0;

		rtcElapsedTime += getBlinkTim0() * 5; // convert to ms.
		rtcElapsedTime += getBlinkTim1() * 1000;  // convert from sec to ms.
		rtcElapsedTime += getBlinkTim2() * 60 * 1000;  // convert from min to ms.
		rtcElapsedTime += getBlinkTim3() * 256 * 60 * 1000;  // convert from 256 min to ms.
		rtcElapsedTime += getBlinkTim4() * 65536 * 60 * 1000;  // convert from 64K min to ms.
		rtcElapsedTime += (System.currentTimeMillis() - Z88.getInstance().getProcessor().getZ88StoppedAtTime()); // add host system elapsed time...

	    setBlinkTim4( ((int) (rtcElapsedTime / 65536 / 60 / 1000)) & 0xFF);

		setBlinkTim3( ((int) (((rtcElapsedTime / 1000 / 60) - (getBlinkTim4() * 65536)) / 256)) & 0xFF);

		setBlinkTim2( ((int) (((rtcElapsedTime / 1000 / 60) - (getBlinkTim4() * 65536)) - (getBlinkTim3() * 256))) & 0xFF);

		setBlinkTim1( ((int) (((rtcElapsedTime / 1000) - (getBlinkTim4() * 65536 * 60)) -
						(getBlinkTim3() * 256 * 60) - getBlinkTim2() * 60)) & 0xFF);

		setBlinkTim0( ((int) (((rtcElapsedTime - (getBlinkTim4() * 65536 * 60 * 1000)) -
						(getBlinkTim3() * 256 * 60 * 1000) - (getBlinkTim2() * 60 * 1000) -
						(getBlinkTim1() * 1000)) / 5)) & 0xFF);
	}



	/**
	 * Set Blink Command Register flags, port $B0.
	 *
	 * <PRE>
	 *	Bit	7, SRUN
	 *	Bit	6, SBIT
	 *	Bit	5, OVERP
	 *	Bit	4, RESTIM
	 *	Bit	3, PROGRAM
	 *	Bit	2, RAMS
	 *	Bit	1, VPPON
	 *	Bit	0, LCDON
	 * </PRE>
	 *
	 *	@param bits
	 */
	public void setBlinkCom(int bits) {

		if (rtc.isRunning() == true && ((bits & Blink.BM_COMRESTIM) == Blink.BM_COMRESTIM)) {
			// Stop Real Time Clock (RESTIM = 1)
			if (Z88.getInstance().getProcessor().singleSteppingMode() == false) rtc.stop();
			rtc.reset();
		}

		if (rtc.isRunning() == false && ((bits & Blink.BM_COMRESTIM) == 0)) {
			// Real Time Clock is not running, and is asked to start (RESTIM = 0)...
			if (Z88.getInstance().getProcessor().singleSteppingMode() == false) rtc.start();
		}

		if ((bits & Blink.BM_COMRAMS) == Blink.BM_COMRAMS) {
			// Slot 0 RAM Bank 0x20 will be bound into lower 8K of segment 0
			RAMS = memory.getBank(0x20);
		} else {
			// Slot 0 ROM bank 0 is bound into lower 8K of segment 0
			RAMS = memory.getBank(0x00);
		}

		COM = bits;
	}

	/**
	 * Get Blink Command Register flags, port $B0.
	 *
	 * <PRE>
	 *	Bit	7, SRUN
	 *	Bit	6, SBIT
	 *	Bit	5, OVERP
	 *	Bit	4, RESTIM
	 *	Bit	3, PROGRAM
	 *	Bit	2, RAMS
	 *	Bit	1, VPPON
	 *	Bit	0, LCDON
	 * </PRE>
	 *
	 *	@return COM
	 */
	public final int getBlinkCom() {
		return COM;
	}

	/**
	 * Get Blink Eprom Programming Register, port $B3
	 *
	 * <PRE>
	 *	Bit	 7, PD1
	 *	Bit	 6, PD0
	 *	Bit	 5, PGMD
	 *	Bit	 4, EOED
	 *	Bit	 3, SE3D
	 *	Bit	 2, PGMP
	 *	Bit	 1, EOEP
	 *	Bit	 0, SE3P
	 * </PRE>
	 */
	public int getBlinkEpr() {
		return EPR;
	}


	/**
	 * Set Blink Eprom Programming Register, port $B3
	 *
	 * <PRE>
	 *	Bit	 7, PD1
	 *	Bit	 6, PD0
	 *	Bit	 5, PGMD
	 *	Bit	 4, EOED
	 *	Bit	 3, SE3D
	 *	Bit	 2, PGMP
	 *	Bit	 1, EOEP
	 *	Bit	 0, SE3P
	 * </PRE>
	 */
	public void setBlinkEpr(int epr) {
		EPR = epr;
	}

	public void startInterrupts() {
		if ( (getBlinkCom() & Blink.BM_COMRESTIM) == 0 ) {
			adjustLostTime();
			rtc.start();
		}
	}

	public void stopInterrupts() {
		rtc.stop();
	}

    public boolean isComaEnabled() {
        return coma;
    }

    /**
	 * The Z80Processor (and Z88) is set into coma mode when a HALT
	 * instruction is executed and the screen is turned off. Only both
	 * SHIFT keys pressed (defined by I register address line) can awake
	 * the Z80Processor from Coma with an INT signal.
	 *
	 * This method is executed by the Z80Processor thread and is suspended
	 * while waiting for an interrupt from the Blink.
     */
    public synchronized void enableComa() throws InterruptedException {
        coma = true;
        while (coma == true)
            wait();
    }

    /**
     * This method is called by Blink's own Rtc thread, HW or both SHIFT
     * keys are pressed - to signal an interrupt or out-of-coma state.
     * It will awake the Z80Processor thread (who is waiting for Blink
     * to signal out-of-coma).
     */
    public synchronized void awakeFromComa() {
        coma = false;
        notifyAll();
    }

    public boolean isSnoozeEnabled() {
        return snooze;
    }

	/**
	 * The Z80Processor is set into snooze mode when INT.KWAIT is enabled
	 * and the hardware keyboard matrix is scanned.
	 * Any interrupt (e.g. RTC, FLAP) or a key press awakes the processor
	 * (or if the Z80 engine is stopped by F5 or debug 'stop' command)
	 *
	 * This method is executed by the Z80Processor thread and is suspended
	 * while waiting for an interrupt from the Blink (keyboard, HW or Rtc)
	 */
    public synchronized void enableSnooze() throws InterruptedException {
        snooze = true;
		while( snooze == true & Z88.getInstance().getProcessor().isZ80running() == true) {
			wait();
		}
    }

    public synchronized void awakeFromSnooze() {
        snooze = false;
        notifyAll();
    }

	/**
	 * RTC, BLINK Real Time Clock, updated each 5ms.
	 */
	public final class Rtc {
		private TimerTask countRtc;

		/**
		 * Internal counter, 2 ticks = 1/100 second (10ms)
		 */
		private int tick;

		/**
		 * TIM0, 5 millisecond period, counts to 199, Z80 IN Register
		 */
		private int TIM0;

		/**
		 * TIM1, 1 second period, counts to 59, Z80 IN Register
		 */
		private int TIM1;

		/**
		 * TIM2, 1 minutes period, counts to 255, Z80 IN Register
		 */
		private int TIM2;

		/**
		 * TIM3, 256 minutes period, counts to 255, Z80 IN Register
		 */
		private int TIM3;

		/**
		 * TIM4, 64K minutes period, counts to 31, Z80 IN Register
		 */
		private int TIM4;

		/**
		 * TSTA, Timer interrupt status, Z80 IN Read Register
		 */
		private int TSTA;

		// Set if minute interrupt has occurred
		public static final int BM_TSTAMIN = 0x04;
		// Set if second interrupt has occurred
		public static final int BM_TSTASEC = 0x02;
		// Set if tick interrupt has occurred
		public static final int BM_TSTATICK = 0x01;

		/**
		 * TMK, Timer interrupt mask, Z80 OUT Write Register
		 */
		private int TMK;

		// Set to enable minute interrupt
		public static final int BM_TMKMIN = 0x04;
		// Set to enable second interrupt
		public static final int BM_TMKSEC = 0x02;
		// Set to enable tick interrupt
		public static final int BM_TMKTICK = 0x01;

		// Set to acknowledge minute interrupt
		public static final int BM_TACKMIN = 0x04;
		// Set to acknowledge second interrupt
		public static final int BM_TACKSEC = 0x02;
		// Set to acknowledge tick interrupt
		public static final int BM_TACKTICK = 0x01;

		private boolean rtcRunning; // Rtc counting?

		private Rtc() {
			rtcRunning = false;

			// enable minute, second and 1/100 second interrups
			TMK = BM_TMKMIN | BM_TMKSEC | BM_TMKTICK;
			TSTA = 0;
		}

		private final class Counter extends TimerTask {
			/**
			 * Execute the RTC counter each 5ms, and set the various RTC interrupts
			 * if they are enabled, but only if INT.TIME = 1.
			 *
			 * @see java.lang.Runnable#run()
			 */
			public void run() {
				boolean signalTimeInterrupt = false;

				if (++tick > 1) {
					// 1/100 second has passed (two 5ms ticks..)
					tick = 0;
					if ((TMK & BM_TMKTICK) == BM_TMKTICK ) {
						// TMK.TICK interrupts are enabled, signal that a tick occurred only if it not already signaled
						TSTA = BM_TSTATICK;

						if (((INT & BM_INTTIME) == BM_INTTIME) & ((INT & BM_INTGINT) == BM_INTGINT)) {
							// INT.TIME interrupts are enabled, and Blink may signal it as IM 1
							signalTimeInterrupt = true;
						}
					}
				}

				if (++TIM0 > 199) {
					// 1 second has passed... (200 * 5 ms ticks = 1 sec)
					TIM0 = 0;

					if ((TMK & BM_TMKSEC) == BM_TMKSEC & ((TSTA & BM_TSTASEC) == 0)) {
						// TMK.SEC interrupts are enabled, signal that a second occurred only if it not already signaled
						TSTA = BM_TSTASEC; // only signal one TSTA interrupt at a time, SEC > TICK...

						if (((INT & BM_INTTIME) == BM_INTTIME) & ((INT & BM_INTGINT) == BM_INTGINT)) {
							// INT.TIME interrupts are enabled, and Blink may signal it as IM 1
							signalTimeInterrupt = true;
						}
					}

					if (++TIM1 > 59) {
						// 1 minute has passed
						TIM1 = 0;

						if ((TMK & BM_TMKMIN) == BM_TMKMIN & ((TSTA & BM_TSTAMIN) == 0)) {
							// TMK.MIN interrupts are enabled, signal that a minute occurred only if it not already signaled
							TSTA = BM_TSTAMIN;  // only signal one TSTA interrupt at a time, MIN > SEC > TICK...

							if (((INT & BM_INTTIME) == BM_INTTIME) & ((INT & BM_INTGINT) == BM_INTGINT)) {
								// INT.TIME interrupts are enabled, and Blink may signal it as IM 1
								signalTimeInterrupt = true;
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

				if (signalTimeInterrupt == true) {
					// fire a single interrupt for one or several TIMx registers,
					// but only if the flap is closed (the Blink doesn't emit
					// RTC interrupts while the flap is open, even if INT.TIME
					// is enabled)
					if ((STA & BM_STAFLAPOPEN) == 0) {
						STA |= BM_STATIME;

					    awakeFromSnooze();
					    awakeFromComa();

        			    // Signal INT interrupt to Z80...
        			    Z88.getInstance().getProcessor().setIntSignal();
					}
				}
			}
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
				countRtc = new Counter();
				rtcTimer.scheduleAtFixedRate(countRtc, 0, 5);
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

	} /* Rtc class */


	/**
	 * @return Returns the current RAMS bank binding (Bank 00/ROM or Bank 20h/RAM).
	 */
	public Bank getRAMS() {
		return RAMS;
	}

	/**
	 * @param rams Define the current Bank binding for RAMS (Bank 00/ROM or Bank 20h/RAM)
	 */
	public void setRAMS(Bank rams) {
		RAMS = rams;
	}

	/**
	 * The Blink only fires an IM 1 interrupt when the flap is opened
	 * and when INT.FLAP is enabled. Both STA.FLAPOPEN and STA.FLAP is
	 * set at the time of the interrupt. As long as the flap is open,
	 * no STA.TIME interrupts gets out of the Blink (even though INT.TIME
	 * may be enabled and signals it to fire those RTC interrupts).
	 * The Flap interrupt is only fired once; when the flap is closed, and
	 * then opened. STA.FLAPOPEN remains enabled as long as the flap is open;
	 * when the flap is closed, NO interrupt is fired - only STA.FLAPOPEN is
	 * set to 0.
	 */
	public void signalFlapOpened() {
		if (((INT & BM_INTFLAP) == BM_INTFLAP) & ((INT & BM_INTGINT) == BM_INTGINT)) {
			STA = (STA | BM_STAFLAPOPEN | BM_STAFLAP) & ~BM_STATIME;
			awakeFromComa();
			awakeFromSnooze();
		}
	}

	/**
	 * Signal that the flap was closed.<p>
	 * The Blink will start to fire STA.TIME interrupts again if the INT.TIME
	 * is enabled and TMK has been setup to fire Minute, Second or TICK's.
	 */
	public void signalFlapClosed() {
		Thread thread = new Thread() {
			public void run() {
				try { Thread.sleep(100);
				} catch (InterruptedException e1) {}

				// delay the flap close 0.1 sec (after this method was executed)
				// this is to ensure that a flap is never closed too fast
				// after a previous insert or remove card in slot
				STA &= ~BM_STAFLAPOPEN;
			}
		};

		thread.start();
	}
}
