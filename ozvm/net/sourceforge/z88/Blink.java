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
 * @author <A HREF="mailto:gbs@users.sourceforge.net">Gunther Strube</A>
 * $Id$
 *
 */

package net.sourceforge.z88;

import java.text.SimpleDateFormat;
import java.util.Timer;
import java.util.TimerTask;


/**
 * Blink chip, the "body" of the Z88, defining the surrounding hardware
 * of the Z80 "mind" processor.
 */
public final class Blink extends Z80 {

	private static final class singletonContainer {
		static final Blink singleton = new Blink();
	}

	public static Blink getInstance() {
		return singletonContainer.singleton;
	}

	/**
	 * "HH.mm.ss.SSS" Time format used when displaying a runtime system message
	 */
	private static final SimpleDateFormat sdf = new SimpleDateFormat("HH.mm.ss.SSS");

	private Breakpoints breakpoints = new Breakpoints();

	/** Blink Snooze state */
	private boolean snooze = false;
	
	/** Blink Coma state */
	private boolean coma = false;
	
	/**
	 * The Z80 databus methods for getting/writing bytes
	 * to/from the memory system through the 64K Z80 address
	 * space (and the segment bindings to the extended
	 * memory model of the Z88).
	 */
	private interface DataBus {
		public int readByte(final int addr);
		public int readWord(final int addr);
		public void writeByte(final int addr, final int b);
		public void writeWord(final int addr, final int b);
	}

	/**
	 * The databus read/write methods for lower 8K of segment 0
	 * (Access through RAMS register)
	 */
	private final class LowerSegment0 implements DataBus {
		public final int readByte(final int addr) {
			return RAMS.readByte(addr);
		}

		public final void writeByte(final int addr, final int b) {
			RAMS.writeByte(addr, b);
		}

		public final int readWord(final int addr) {
			return RAMS.readByte(addr) | (RAMS.readByte(addr+1) << 8);
		}

		public final void writeWord(final int addr, final int w) {
			RAMS.writeByte(addr, w);
			RAMS.writeByte(addr+1, w >>> 8);
		}
	}

	/**
	 * The databus read/write methods for upper 8K of segment 0
	 * (Only even banks are mapped into this segment, where bit 0
	 * of the bank number identifies whether the upper 8K or the
	 * lower 8K of the bank are bound into the upper 8K of
	 * segment 0)
	 * Read/write occurs in address range 2000h-3FFFh of the 64K
	 * Z80 address space.
	 */
	private final class UpperSegment0 implements DataBus {
		public final int readByte(final int addr) {
			return memory.getBank(sR[0] & 0xFE).readByte( ((sR[0] & 1) << 13) | (addr & 0x1FFF) );
		}

		public final void writeByte(final int addr, final int b) {
			memory.getBank(sR[0] & 0xFE).writeByte( ((sR[0] & 1) << 13) | (addr & 0x1FFF), b);
		}

		public final int readWord(int addr) {
			Bank b = memory.getBank(sR[0] & 0xFE);
			addr = ((sR[0] & 1) << 13) | (addr & 0x1FFF);

			return b.readByte(addr) | (b.readByte(addr+1) << 8);
		}

		public final void writeWord(int addr, final int w) {
			Bank b = memory.getBank(sR[0] & 0xFE);
			addr = ((sR[0] & 1) << 13) | (addr & 0x1FFF);

			b.writeByte(addr, w);
			b.writeByte(addr+1, w >>> 8);
		}
	}

	/**
	 * The databus read/write methods for segments 1 - 3.
	 *
	 * Read/write occurs in address range 4000h-FFFFh of the 64K
	 * Z80 address space.
	 */
	private final class Segments1To3 implements DataBus {
		public final int readByte(final int addr) {
			return memory.getBank(sR[(addr >>> 14) & 3]).readByte(addr);
		}

		public final void writeByte(final int addr, final int b) {
			memory.getBank(sR[(addr >>> 14) & 3]).writeByte(addr, b);
		}

		public final int readWord(final int addr) {
			Bank b = memory.getBank(sR[(addr >>> 14) & 3]);

			return b.readByte(addr) | (b.readByte(addr+1) << 8);
		}

		public final void writeWord(final int addr, final int w) {
			Bank b = memory.getBank(sR[(addr >>> 14) & 3]);

			b.writeByte(addr, w);
			b.writeByte(addr+1, w >>> 8);
		}
	}

	private DataBus[] addressSpace = null;
	private LowerSegment0 segm00addrSpace;
	private UpperSegment0 segm01addrSpace;
	private Segments1To3 segm13addrSpace;
	
	/**
	 * Blink class default constructor.
	 */
	private Blink() {
		super();

		debugMode = false;	// define the default running status of the virtul Machine.

		memory = Memory.getInstance();	// create the Z88 memory model (4Mb addressable memory)
		RAMS = memory.getBank(0); // point at ROM bank 0 (null at the moment)

		// the segment register SR0 - SR3
		sR = new int[4];

		segm00addrSpace = new LowerSegment0();
		segm01addrSpace = new UpperSegment0();
		segm13addrSpace = new Segments1To3();
		addressSpace = new DataBus[] {
					segm00addrSpace, segm00addrSpace, segm01addrSpace, segm01addrSpace,
					segm13addrSpace, segm13addrSpace, segm13addrSpace, segm13addrSpace,
					segm13addrSpace, segm13addrSpace, segm13addrSpace, segm13addrSpace,
					segm13addrSpace, segm13addrSpace, segm13addrSpace, segm13addrSpace
				};

		timerDaemon = new Timer(true);
		rtc = new Rtc(); 				// the Real Time Clock counter, not yet started...

		resetBlinkRegisters();
	}


	/**
	 * execute a single Z80 instruction and return
	 */
	public void singleStepZ80() {
		run(true);
	}

	/**
	 * execute Z80 instructions until a breakpoint is reached,
	 * stop command is entered or F5 was pressed in Z88 screen
	 */
    public void execZ80() {
    	run(false);			// run until we drop dread!
    }

	/**
	 * Access to the Z88 Memory Model
	 */
	private Memory memory = null;

	/**
	 * The main Timer daemon that runs the Rtc clock and sends 10ms interrupts
	 * to the Z80 virtual processor.
	 */
	private Timer timerDaemon = null;

	public Timer getTimerDaemon() {
		return timerDaemon;
	}

	private boolean debugMode = false;

	/**
	 * The Real Time Clock (RTC) inside the BLINK.
	 */
	private Rtc rtc;

	/**
	 * 'Press' the reset button on the left side of the Z88
	 * (hidden in the small crack next to the power plug)
	 *
	 */
	public void pressResetButton() {
		int comReg = getBlinkCom();
		comReg &= ~Blink.BM_COMRAMS;	// COM.RAMS = 0 (lower 8K = Bank 0)
		PC(0x000);						// execute (soft/hard) reset
	}
	
	/**
	 * Reset Blink Registers to Power-On-State.
	 */
	public void resetBlinkRegisters() {
		PB0 = PB1 = PB2 = PB3 = SBR = 0;
		COM = INT = STA = 0;
		rtc.TACK = rtc.TMK = rtc.TSTA = ACK = 0;
		rtc.TIM0 = rtc.TIM1 = rtc.TIM2 = rtc.TIM3 = rtc.TIM4 = 0;

		// SR0, SR1, SR2, SR3 = 0
		for (int segment = 0; segment < sR.length; segment++) {
			sR[segment] = 0;
		}
	}

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
	private int INT = 0;

	public static final int BM_INTKWAIT = 0x80;	// Bit 7, If set, reading the keyboard will Snooze
	public static final int BM_INTA19 = 0x40;	// Bit 6, If set, an active high on A19 will exit Coma
	public static final int BM_INTFLAP = 0x20;	// Bit 5, If set, flap interrupts are enabled
	public static final int BM_INTUART = 0x10;	// Bit 4, If set, UART interrupts are enabled
	public static final int BM_INTBTL = 0x08;	// Bit 3, If set, battery low interrupts are enabled
	public static final int BM_INTKEY = 0x04;	// Bit 2, If set, keyboard interrupts (Snooze or Coma) are enabl.
	public static final int BM_INTTIME = 0x02;	// Bit 1, If set, RTC interrupts are enabled
	public static final int BM_INTGINT = 0x01;	// Bit 0, If clear, no interrupts get out of blink

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
//		System.out.println("Setting INT:");
//		if ((bits & BM_INTKWAIT) != 0) System.out.println("INT.BM_INTKWAIT");
//		if ((bits & BM_INTA19) != 0) System.out.println("INT.BM_INTA19");
//		if ((bits & BM_INTFLAP) != 0) System.out.println("INT.BM_INTFLAP");
//		if ((bits & BM_INTUART) != 0) System.out.println("INT.BM_INTUART");
//		if ((bits & BM_INTBTL) != 0) System.out.println("INT.BM_INTBTL");
//		if ((bits & BM_INTKEY) != 0) System.out.println("INT.BM_INTKEY");
//		if ((bits & BM_INTTIME) != 0) System.out.println("INT.BM_INTTIME");
//		if ((bits & BM_INTGINT) != 0) System.out.println("INT.BM_INTGINT");
//
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
	 * Acknowledge Main Blink Interrrupts (ACK)
	 *
	 * <PRE>
	 * BIT 6, A19    Acknowledge active high on A19
	 * BIT 5, FLAP   Acknowledge Flap interrupts
	 * BIT 3, BTL    Acknowledge battery low interrupt
	 * BIT 2, KEY    Acknowledge keyboard interrupt
	 * </PRE>
	 */
	private int ACK = 0;

	public static final int BM_ACKA19 = 0x40;	// Bit 6, Acknowledge A19 interrupt
	public static final int BM_ACKFLAP = 0x20;	// Bit 5, Acknowledge flap interrupt
	public static final int BM_ACKBTL = 0x08;	// Bit 3, Acknowledge battery low interrupt
	public static final int BM_ACKKEY = 0x04;	// Bit 2, Acknowledge keyboard interrupt
	public static final int BM_ACKTIME = 0x01;	// Bit 0, Acknowledge TIME interrupt

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
		if ((bits & BM_ACKA19) == BM_ACKA19) STA &= ~BM_STAA19;
		if ((bits & BM_ACKBTL) == BM_ACKBTL) STA &= ~BM_STABTL;
		if ((bits & BM_ACKFLAP) == BM_ACKFLAP) STA &= ~BM_STAFLAP;
		if ((bits & BM_ACKTIME) == BM_ACKTIME) STA &= ~BM_STATIME;
	}

   	/**
	 * Get Main Blink Interrupt Acknowledge (ACK), Z80 OUT Register
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
	public int getBlinkAck() {
		return ACK;
	}

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
	 * Bit 1, TIME, If set, an enabled TIME interrupt is active
	 * Bit 0, not defined.
	 * </PRE>
	 */
	private int STA;

	public static final int BM_STAFLAPOPEN = 0x80;	// Bit 7, If set, flap open, else flap closed
	public static final int BM_STAA19 = 0x40;	// Bit 6, If set, high level on A19 occurred during coma
	public static final int BM_STAFLAP = 0x20;	// Bit 5, If set, positive edge has occurred on FLAPOPEN
	public static final int BM_STAUART = 0x10;	// Bit 4, If set, an enabled UART interrupt is active
	public static final int BM_STABTL = 0x08;	// Bit 3, If set, battery low pin is active
	public static final int BM_STAKEY = 0x04;	// Bit 2, If set, a column has gone low in snooze (or coma)
	public static final int BM_STATIME = 0x01;	// Bit 1, If set, an enabled TSTA interrupt is active

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
	 * Bit 1, TIME, If set, an enabled TSTA interrupt is active
	 * Bit 0, not defined.
	 * </PRE>
	 */
	public int getBlinkSta() {
//		System.out.println("STA = " + Dz.byteToBin(STA,true));
//
//		if ((STA & BM_STAFLAPOPEN) != 0) System.out.println("STA.BM_STAFLAPOPEN");
//		if ((STA & BM_STAA19) != 0) System.out.println("STA.BM_STAA19");
//		if ((STA & BM_STAFLAP) != 0) System.out.println("STA.BM_STAFLAP");
//		if ((STA & BM_STAUART) != 0) System.out.println("STA.BM_STAUART");
//		if ((STA & BM_STABTL) != 0) System.out.println("STA.BM_STABTL");
//		if ((STA & BM_STAKEY) != 0) System.out.println("STA.BM_STAKEY");
//		if ((STA & BM_STATIME) != 0) System.out.println("STA.BM_STATIME");
//		if ((STA & BM_STAGINT) != 0) System.out.println("STA.BM_STAGINT");

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
	 * Bit 1, TIME, If set, an enabled TSTA interrupt is active
	 * Bit 0, not defined.
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

		// reset appropriate TSTA bits (the prev. raised interrupt get cleared)
		if ((bits & Rtc.BM_TACKMIN) == Rtc.BM_TACKMIN) rtc.TSTA &= ~Rtc.BM_TACKMIN;
		if ((bits & Rtc.BM_TACKSEC) == Rtc.BM_TACKSEC) rtc.TSTA &= ~Rtc.BM_TACKSEC;
		if ((bits & Rtc.BM_TACKTICK) == Rtc.BM_TACKTICK) rtc.TSTA &= ~Rtc.BM_TACKTICK;

		STA &= ~BM_STATIME;			// also acknowledge enabled STA.TIME interrupt
	}

	/**
	 * Get Timer interrupt acknowledge (TACK), Z80 OUT Write Register.
	 *
	 * <PRE>
	 * BIT 2, MIN, Set to acknowledge minute interrupt
	 * BIT 1, SEC, Set to acknowledge
	 * BIT 0, TICK, Set to acknowledge tick interrupt
	 * </PRE>
	 */
	public int getBlinkTack() {
		return rtc.TACK;
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
	 * LORES0 (PB0, 16bits register).<br>
	 * The 6 * 8 pixel per char User Defined Fonts.
	 */
	private int PB0;

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
	 * LORES1 (PB1, 16bits register).<br>
	 * The 6 * 8 pixel per char fonts.
	 */
	private int PB1;

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
	 * HIRES0 (PB2 16bits register)
     * (The 8 * 8 pixel per char PipeDream Map)
	 */
	private int PB2;

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
	 * HIRES1 (PB3, 16bits register)
	 * (The 8 * 8 pixel per char fonts for the OZ window)
	 */
	private int PB3;

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
	 * Screen Base Register (16bits register)
	 * (The Screen base File (2K size), containing char info about screen)
	 * If this register is 0, then the system cannot render the pixel screen.
	 */
	private int SBR;

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
	 * Signal to the Blink that a key was pressed.
	 * The internal state machine inside the Blink resolves the 
	 * snooze state and fires KEY interrupts, if enabled. 
	 */
	public void signalKeyPressed() {
		// processor always awakes on a key press (even if INT.GINT = 0)
		snooze = false; 
		
		if ( (INT & Blink.BM_INTKEY) == Blink.BM_INTKEY ) {
			// If keyboard interrupts are enabled, then signal that a key was pressed.
			STA |= BM_STAKEY;

			if (((INT & BM_INTGINT) == BM_INTGINT)) {
				coma = false;
				setInterruptSignal(false);
			}
		}
	}
	
	
	/**
	 * Fetch a keypress from the specified row(s) matrix, or 0 for all rows.<br>
	 * Interface call for IN r,(B2h).<br>
	 *
	 * @param row, eg @10111111, or 0 for all rows.
	 * @return int keycolumn status of row or merge of columns for specified rows.
	 */
	public int getBlinkKbd(int row) {		
		if ( (INT & Blink.BM_INTKWAIT) != 0 ) {
			snooze = true;
			Thread.currentThread().setPriority(Thread.MIN_PRIORITY);
			
			while( snooze == true & stopZ88 == false) {
				try {
					// The processor is set into snooze mode when INT.KWAIT is enabled 
					// and the hardware keyboard matrix is scanned.
					// Any interrupt (e.g. RTC, FLAP) or a key press awakes the processor
					// (or if the Z80 engine is stopped by F5 or debug 'stop' command) 
					if (System.currentTimeMillis() % 13 != 0)
						Thread.sleep(0,100);
					else
						Thread.yield();					
				} catch (InterruptedException e) {
				}
			}
			
			Thread.currentThread().setPriority(Thread.NORM_PRIORITY);
		}

		return Z88Keyboard.getInstance().scanKeyRow(row);
	}

	
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
			bankno = sR[(pc >>> 14) & 0x03];
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

		return bankno << 16 | (pc & 0x3FFF);
	}

	/**
	 * Decode Z88 Extended Blink Address (bank,offset) into
	 * specified Z80 Address Space segment (0 - 3)
	 *
	 * @param extaddr 24bit extended address (bank number & bank offset)
	 * @return int 16bit word that points into Z80 64K Address Space
	 */
	public int decodeExtendedAddress(int extaddr, int segment) {
		int bankNo = extaddr >>> 16;
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
		return addressSpace[ (addr & 0xF000) >>> 12].readByte(addr);
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
		return addressSpace[ (addr & 0xF000) >>> 12].readWord(addr);
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
		addressSpace[ (addr & 0xF000) >>> 12].writeByte(addr, b);
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
		addressSpace[ (addr & 0xF000) >>> 12].writeWord(addr, w);
	}

	/**
	 * Implement Z88 input port BLINK hardware
	 * (Registers STA, KBD, TSTA, TIM0-TIM4, RXD, RXE, UIT).
	 *
	 * @param addrA8 Port number (low byte address)
	 * @param addrA15 high byte address
	 */
	public final int inByte(int addrA8, int addrA15) {
		int res = 0;

		Thread.yield();	// let the Java System work on the other thread for a short while...

		switch (addrA8) {
			case 0xB1:
                res = getBlinkSta();		// STA, Main Blink Interrupt Status
				break;

			case 0xB2:
				res = getBlinkKbd(addrA15);	// KBD, get Keyboard column for specified row.
				break;

			case 0xB5:
                if ((INT & BM_INTTIME) == BM_INTTIME) {
                    res = getBlinkTsta();	// RTC interrupts are enabled, so TSTA is active...
                }
				break;

            case 0xD0:
				res = getBlinkTim0();	// TIM0, 5ms period, counts to 199
				break;

			case 0xD1:
				res = getBlinkTim1();	// TIM1, 1 second period, counts to 59
				break;

			case 0xD2:
				res = getBlinkTim2();	// TIM2, 1 minute period, counts to 255
				break;

			case 0xD3:
				res = getBlinkTim3();	// TIM3, 256 minutes period, counts to 255
				break;

			case 0xD4:
				res = getBlinkTim4();	// TIM4, 64K minutes Period, counts to 31
				break;

			case 0xE0:					// RxD
				res = 0;
				break;

			case 0xE1:					// RxE
				res = 0;
				break;

			case 0xE5:					// UIT, UART Int status
				res = 0;
				break;

			default :
				if (OZvm.debugMode == true) {
					Gui.displayRtmMessage("WARNING:\n" +
									   Z88Info.dzPcStatus(getInstrPC()) + "\n" +
									   "Blink Read Register " + Dz.byteToHex(addrA8, true) + " does not exist.");
				}
				res = 0;
		}

		return res;
	}

	/**
	 * Implement Z88 output port Blink hardware.
	 * (RTC, Screen, Keyboard, Memory model, Serial port, CPU state).
	 *
	 * @param addrA8 LSB of port address
	 * @param addrA15 MSB of port address
	 * @param outByte the data to send to the hardware
	 */
	public final void outByte(final int addrA8, final int addrA15, final int outByte) {
		Thread.yield();	// let the Java System work on the other thread for a short while...

		switch (addrA8) {
			case 0xD0 : // SR0, Segment register 0
			case 0xD1 : // SR1, Segment register 1
			case 0xD2 : // SR2, Segment register 2
			case 0xD3 : // SR3, Segment register 3
				setSegmentBank(addrA8, outByte);
				break;

			case 0xB0 : // COM, Set Command Register
				setBlinkCom(outByte);
				break;

			case 0xB1 : // INT, Set Main Blink Interrupts
				setBlinkInt(outByte);
				break;

			case 0xB3 : // EPR, Eprom programming (not yet implemented)
//				if (OZvm.debugMode == true) {
//					displayRtmMessage("WARNING:\n" +
//									   (new DisplayStatus(this)).dzPcStatus(getInstrPC()) + "\n" +
//									   "Eprom programming emulation not yet implemented.", true);
//				}
				break;

			case 0xB4 : // TACK, Set Timer Interrupt Acknowledge
				setBlinkTack(outByte);
				break;

			case 0xB5 : // TMK, Set Timer interrupt Mask
				setBlinkTmk(outByte);
				break;

			case 0xB6 : // ACK, Acknowledge Main Interrupts
				setBlinkAck(outByte);
				break;

			case 0x70 : // PB0, Pixel Base Register 0 (Screen)
				setBlinkPb0((addrA15 << 8) | outByte);
				break;

			case 0x71 : // PB1, Pixel Base Register 1 (Screen)
				setBlinkPb1((addrA15 << 8) | outByte);
				break;

			case 0x72 : // PB2, Pixel Base Register 2 (Screen)
				setBlinkPb2((addrA15 << 8) | outByte);
				break;

			case 0x73 : // PB3, Pixel Base Register 3 (Screen)
				setBlinkPb3((addrA15 << 8) | outByte);
				break;

			case 0x74 : // SBR, Screen Base Register
				setBlinkSbr((addrA15 << 8) | outByte);
				break;

			case 0xE2 : // RXC, Receiver Control (not yet implemented)
			case 0xE3 : // TXD, Transmit Data (not yet implemented)
			case 0xE4 : // TXC, Transmit Control (not yet implemented)
				if (OZvm.debugMode == true) {
					Gui.displayRtmMessage("WARNING:\n" +
										Z88Info.dzPcStatus(getInstrPC()) + "\n" +
										"UART Serial Port emulation not yet implemented.");
				}
				break;
			case 0xE5 : // UMK, UART int. mask (not yet implemented)
			case 0xE6 : // UAK, UART acknowledge int. mask (not yet implemented)
				break;

			default:
				if (OZvm.debugMode == true) {
					Gui.displayRtmMessage("WARNING:\n" +
										Z88Info.dzPcStatus(getInstrPC()) + "\n" +
										"Blink Write Register " + Dz.byteToHex(addrA8, true) + " does not exist.");
				}
		}
	}

    /**
     * Internal signal for stopping the Z80 execution engine
     */
    private boolean stopZ88 = false;

	public void stopZ80Execution() {
		stopZ88 = true;
	}

	private long z88StoppedAtTime;

	/**
	 * @return the system time when Z88 was stopped.
	 */
	public long getZ88StoppedAtTime() {
		return z88StoppedAtTime;
	}

	/**
	 * Restore system time when Z88 was stopped
	 * (from snapshot).
	 */
	public void setZ88StoppedAtTime(long time) {
		z88StoppedAtTime = time;
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
		rtcElapsedTime += (System.currentTimeMillis() - getZ88StoppedAtTime()); // add host system elapsed time...

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
     * Check if F5 key was pressed, or a stop was issued at command line.
     */
	public boolean isZ80Stopped() {
        if (stopZ88 == true) {
            stopZ88 = false;
            z88StoppedAtTime = System.currentTimeMillis();
            Gui.displayRtmMessage("Z88 virtual machine was stopped at " + Dz.extAddrToHex(decodeLocalAddress(getInstrPC()), true));

            return true;
        } else {
            return false;
        }
	}

	/**
	 * a HALT instruction was executed by the Z80 processor.
	 * go into coma and wait for an interrupt..
	 */
	public void haltZ80() {
		// Z80 "Clock" is now stopped, 
		// wait until an interrupt is fired...
		
		coma = true;
		do {
			try {
				Thread.sleep(1);
			} catch (InterruptedException e) {
			}
		} // Only get out of coma if an interrupt occurred or if Z80 engine was stopped..
		while(coma == true & stopZ88 == false);

		// (back to main Z80 decode loop)
	}


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
		int cardType;

		if (rtc.isRunning() == true && ((bits & Blink.BM_COMRESTIM) == Blink.BM_COMRESTIM)) {
			// Stop Real Time Clock (RESTIM = 1)
			if (singleSteppingMode() == false) rtc.stop();
			rtc.reset();
		}

		if (rtc.isRunning() == false && ((bits & Blink.BM_COMRESTIM) == 0)) {
			// Real Time Clock is not running, and is asked to start (RESTIM = 0)...
			if (singleSteppingMode() == false) rtc.start();
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

	public void startInterrupts() {
		if ( (getBlinkCom() & Blink.BM_COMRESTIM) == 0 ) {
			adjustLostTime();
			rtc.start();
		}
	}

	public void stopInterrupts() {
		rtc.stop();
	}

	/**
	 * RTC, BLINK Real Time Clock, updated each 5ms.
	 */
	public final class Rtc {

		private Rtc() {
			rtcRunning = false;

			// enable minute, second and 1/100 second interrups
			TMK = BM_TMKMIN | BM_TMKSEC | BM_TMKTICK;
			TSTA = TACK = 0;
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
					if (((INT & BM_INTTIME) == BM_INTTIME) && ((TMK & BM_TMKTICK) == BM_TMKTICK)) {
						// INT.TIME interrupts are enabled and TMK.TICK interrupts are enabled:
						// Signal that a tick interrupt occurred
						TSTA |= BM_TSTATICK; // TSTA.BM_TSTATICK = 1
						STA |= BM_STATIME;
						
						if (((INT & BM_INTGINT) == BM_INTGINT)) {
							signalTimeInterrupt = true;
						}
					}
				}

				if (++TIM0 > 199) {
					// 1 second has passed... (200 * 5 ms ticks = 1 sec)
					TIM0 = 0;

					if (((INT & BM_INTTIME) == BM_INTTIME) && ((TMK & BM_TMKSEC) == BM_TMKSEC)) {
						// INT.TIME interrupts are enabled and TMK.SEC interrupts are enabled:
						// Signal that a second interrupt occurred
						TSTA |= BM_TSTASEC; // TSTA.BM_TSTASEC = 1
						STA |= BM_STATIME;

						if (((INT & BM_INTGINT) == BM_INTGINT)) {
							signalTimeInterrupt = true;
						}
					}

					if (++TIM1 > 59) {
						// 1 minute has passed
						TIM1 = 0;
						
						if (((INT & BM_INTTIME) == BM_INTTIME) && ((TMK & BM_TMKMIN) == BM_TMKMIN)) {
							// INT.TIME interrupts are enabled and TMK.MIN interrupts are enabled:
							// Signal that a minute interrupt occurred
							TSTA |= BM_TSTAMIN; // TSTA.BM_TSTAMIN = 1
							STA |= BM_STATIME;

							if (((INT & BM_INTGINT) == BM_INTGINT)) {
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
					// fire a single interrupt for one or several TIMx registers...
					snooze = false;
					coma = false;
					setInterruptSignal(false);
				}				
			}
		}

		TimerTask countRtc = null;

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
				timerDaemon.scheduleAtFixedRate(countRtc, 0, 5);
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
	 * Handle action on encountered breakpoint.<p>
	 * (But ignore it, if the processor is just executing a LD B,B (T-Touch on the Z88 does it)!
	 *
	 * @return true, if Z80 engine is to be stopped (a real breakpoint were found).
	 */
	public boolean breakPointAction() {
		int bpAddress = decodeLocalAddress(getInstrPC());
		int bpOpcode = memory.getByte(bpAddress);	// remember the breakpoint instruction opcode

		int z80Opcode = breakpoints.getOrigZ80Opcode(bpAddress); 	// get the original Z80 opcode at breakpoint address
		if (z80Opcode != -1) {
			// a breakpoint was defined for that address;
			// don't stop the processor if it's only a display breakpoint...
			memory.setByte(bpAddress, z80Opcode);						// patch the original opcode back into memory (temporarily)
			Gui.displayRtmMessage(Z88Info.dzPcStatus(getInstrPC())); 	// dissassemble original instruction, with Z80 main reg dump
			memory.setByte(bpAddress, bpOpcode);						// re-patch the breakpoint opcode, for future encounter
			if (breakpoints.isActive(bpAddress) == true && breakpoints.isStoppable(bpAddress) == true) {
				PC(getInstrPC()); // PC is reset to breakpoint (currently, it points at the instruction AFTER the breakpoint)
				Gui.displayRtmMessage("Z88 virtual machine was stopped at breakpoint.");

				OZvm.getInstance().commandLine(true); // Activate Debug Command Line Window...
				return true;
			}
		}

		return false; // don't stop; either no breakpoint were found, or it's just a display breakpoint..
	}

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
	 * @return Returns the breakpoints.
	 */
	public Breakpoints getBreakpoints() {
		return breakpoints;
	}

	/**
	 * @param breakpoints The breakpoints to set.
	 */
	public void setBreakpoints(Breakpoints breakpoints) {
		this.breakpoints = breakpoints;
	}

	/**
	 * Internal status of the flap; whether it has been
	 * openened (to insert/remove cards from the external
	 * slots) or not.
	 *
	 * The status is being monitored by the Blink and will
	 * define the BM_STAFLAPOPEN bit of the STA hardware register.
	 */
	private boolean flapOpen = false;

	public void openFlap() {
		flapOpen = true;
		STA |= BM_STAFLAPOPEN;
		snooze = coma = false;
		setInterruptSignal(false);
	}

	public void closeFlap() {
		flapOpen = false;
	}
}
