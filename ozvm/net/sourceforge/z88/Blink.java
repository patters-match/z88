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

import java.io.BufferedInputStream;
import java.io.InputStream;
import java.io.RandomAccessFile;
import java.io.IOException;
import java.net.URL;
import java.net.JarURLConnection;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Timer;
import java.util.TimerTask;
import javax.swing.JTextArea;
import javax.swing.JTextField;

/**
 * Blink chip, the "body" of the Z88, defining the surrounding hardware 
 * of the Z80 "mind" processor.
 */
public final class Blink extends Z80 {

	/**
	 * "HH.mm.ss.SSS" Time format used when displaying a runtime system message
	 */
	private static final SimpleDateFormat sdf = new SimpleDateFormat("HH.mm.ss.SSS");

	/**
	 * Blink class default constructor.
	 *
	 * @param canvas
	 * @param rtmOutput
	 */
	Blink(Z88display z88Dsp, JTextField cmdInput, JTextArea rtmOutput) {
		super();

		debugMode = false;	// define the default running status of the virtul Machine.

		memory = new Memory();	// create the Z88 memory model (4Mb addressable memory)
		RAMS = memory.getBank(0); // point at ROM bank 0 (null at the moment)
		
		// the segment register SR0 - SR3
		sR = new int[4];
		// all segment registers points at ROM bank 0
		for (int segment = 0; segment < sR.length; segment++) {
			sR[segment] = 0;
		}

		timerDaemon = new Timer(true);
		rtc = new Rtc(); 				// the Real Time Clock counter, not yet started...
		z80Int = new Z80interrupt(); 	// the INT signals each 10ms to Z80, not yet started...

		z88Keyboard = new Z88Keyboard(this, z88Dsp, cmdInput);
		runtimeOutput = rtmOutput;		// reference to runtime output window text area.
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

	private JTextArea runtimeOutput;

	private void displayRtmMessage(final String msg, final boolean displayTimeStamp) {
		final Date curDateTime = new Date();

		Thread displayMsgThread = new Thread() {
			public void run() {
				// Make sure the new text is visible, even if there
				// was a selection in the text area.
				if (displayTimeStamp == true) runtimeOutput.append(sdf.format(curDateTime) + ":\n");
				runtimeOutput.append(msg + "\n");
				runtimeOutput.setCaretPosition(runtimeOutput.getDocument().getLength());
			}
		};

		displayMsgThread.setPriority(Thread.MIN_PRIORITY);
		displayMsgThread.start();
	}

	private Breakpoints breakPoints = null;

	private boolean debugMode = false;

	/**
	 * The 640x64 pixel display.
	 */
	private Z88display z88Display;

	/**
	 * The keyboard hardware (receiving input from Host OS keyboard).
	 */
	private Z88Keyboard z88Keyboard;

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
		// System.out.println("Blink, Acknowledge interrupts: " + Integer.toBinaryString(bits));
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
//		System.out.println("STA = " + Integer.toBinaryString(STA));
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
	 * Get current TIM1 register from the RTC.
	 *
	 * @return int
	 */
	public int getBlinkTim1() {
		return rtc.TIM1;
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
	 * Get current TIM3 register from the RTC.
	 *
	 * @return int
	 */
	public int getBlinkTim3() {
		return rtc.TIM3;
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
	 * Fetch a keypress from the specified row(s) matrix, or 0 for all rows.<br>
	 * Interface call for IN r,(B2h).<br>
	 *
	 * @param row, eg @10111111, or 0 for all rows.
	 * @return int keycolumn status of row or merge of columns for specified rows.
	 */
	public int getBlinkKbd(int row) {
		int keyCol = 0xFF;	// Default to no keys pressed...

		if ( (INT & BM_INTKWAIT) != 0) {
			// Z80 snoozes... (wait a little bit, then ask for key press from Blink)
			try {
				Thread.sleep(1);
			} catch (InterruptedException e) {}
		}

		keyCol = z88Keyboard.scanKeyRow(row);
		if (keyCol != 0xFF) {
			if ( ((INT & Blink.BM_INTKEY) != 0) ) {
				// If keyboard interrupts are enabled, then signal that a key was pressed.
				STA |= BM_STAKEY;
			}
        }

		return keyCol;
	}

	/**
	 * System bank for lower 8K of segment 0.
	 * References bank 0x00 or 0x20 of slot 0.
	 */
	private Memory.Bank RAMS;
	
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
		sR[segment & 0x03] = (BankNo & 0xFF);
	}

	/**
	 * Decode Z80 Address Space to extended Blink Address (offset,bank).
	 *
	 * @param pc 16bit word that points into Z80 64K Address Space
	 * @return int 24bit extended address
	 */
	public int decodeLocalAddress(final int pc) {
		int bankno;

		if (pc >= 0x2000) {
			bankno = sR[(pc >>> 14) & 0x03];
		} else {
			// return lower 8K Bank binding
			// Lower 8K is System Bank 0x00 (ROM on hard reset)
			// or 0x20 (RAM for Z80 stack and system variables)
			if ((COM & Blink.BM_COMRAMS) == Blink.BM_COMRAMS)
				bankno = 0x20;	// RAM Bank 20h
			else
				bankno = 0x00;	// ROM bank 00h
		}

		return bankno << 16 | pc;
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
		Memory.Bank bank;

		if ( (addr & 0x3FFF) != 0x3FFF ) {
			if (addr > 0x3FFF) {
				bank = memory.getBank(sR[addr >>> 14]);
				return (bank.readByte(addr+1) << 8) | bank.readByte(addr);
			} else {
				if (addr < 0x2000) {
					// return lower 8K Bank binding
					// Lower 8K is System Bank 0x00 (ROM on hard reset)
					// or 0x20 (RAM for Z80 stack and system variables)
					return (RAMS.readByte(addr+1) << 8) | RAMS.readByte(addr);
				} else {
					bank = memory.getBank(sR[0] & 0xFE);
					if ((sR[0] & 1) == 0) {
						// lower 8K of even bank bound into upper 8K of segment 0
						addr &= 0x1FFF;
					}
					// else 
					// upper 8K of even bank bound into upper 8K of segment 0
					// addr = [0x2000 - 0x3FFF]...
					return (bank.readByte(addr+1) << 8) | bank.readByte(addr);
				}
			}
		} else {
			// bank boundary will be crossed...
			return (readByte(addr+1) << 8) | readByte(addr);
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
		Memory.Bank bank;

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
				bank = memory.getBank(sR[0] & 0xFE);
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
		Memory.Bank bank;

		if ( (addr & 0x3FFF) != 0x3FFF ) {
			if (addr > 0x3FFF) {
				bank = memory.getBank(sR[addr >>> 14]);
				bank.writeByte(addr, w);
				bank.writeByte(addr+1, w >>> 8);
			} else {
				if (addr < 0x2000) {
					// return lower 8K Bank binding
					// Lower 8K is System Bank 0x00 (ROM on hard reset)
					// or 0x20 (RAM for Z80 stack and system variables)
					RAMS.writeByte(addr, w);
					RAMS.writeByte(addr+1, w >>> 8);
				} else {
					bank = memory.getBank(sR[0] & 0xFE);
					if ((sR[0] & 1) == 0) addr &= 0x1FFF; // lower 8K of even bank bound into upper 8K of segment 0
					bank.writeByte(addr, w);
					bank.writeByte(addr+1, w >>> 8);
				}
			}
		} else {
			// bank boundary will be crossed...
			writeByte(addr, w);
			writeByte(addr+1, w >>> 8);
		}
	}

	
	/**
	 * The "internal" write byte method to be used in
	 * the OZvm debugging environment, allowing complete
	 * write permission.
	 *
	 * @param offset within the 16K memory bank.
	 * @param bank number of the 4MB memory model (0-255).
	 * @param bits to be written.
	 */
	public void setByte(final int offset, final int bankno, final int bits) {
		memory.getBank(bankno).setByte(offset, bits);
	}

	
	/**
	 * The "internal" write byte method to be used in
	 * the OZvm debugging environment, allowing complete
	 * write permission.
	 *
	 * @param extAddress 24bit extended address
	 * @param bits to be written.
	 */
	public void setByte(final int extAddress, final int bits) {
		setByte(extAddress & 0x3FFF, extAddress >>> 16, bits);
	}

	
	/**
	 * The "internal" read byte method to be used in the OZvm
	 * debugging environment.
	 *
	 * @param extAddress 24bit extended address
	 * @return int the byte at extended address
	 */
	public int getByte(final int extAddress) {
		return getByte(extAddress & 0x3FFF, extAddress >>> 16);
	}

	
	/**
	 * The "internal" read byte method to be used in the OZvm
	 * debugging environment.
	 *
	 * @param offset
	 * @param bank
	 * @return int
	 */
	public int getByte(final int offset, final int bankno) {
		return memory.getBank(bankno).getByte(offset);
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
				displayRtmMessage("WARNING:\n" +
								   (new DisplayStatus(this)).dzPcStatus(getInstrPC()).toString() + "\n" +
								   "Blink Read Register " + Dz.byteToHex(addrA8, true) + " does not exist.", true);
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
				displayRtmMessage("WARNING:\n" +
								   (new DisplayStatus(this)).dzPcStatus(getInstrPC()).toString() + "\n" +
								   "Eprom programming emulation not yet implemented.", true);			
			
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
				displayRtmMessage("WARNING:\n" +
								   (new DisplayStatus(this)).dzPcStatus(getInstrPC()).toString() + "\n" +
								   "UART Serial Port emulation not yet implemented.", true);						
				break;
			case 0xE5 : // UMK, UART int. mask (not yet implemented)
			case 0xE6 : // UAK, UART acknowledge int. mask (not yet implemented)
				break;
			
			default:
				displayRtmMessage("WARNING:\n" +
								   (new DisplayStatus(this)).dzPcStatus(getInstrPC()).toString() + "\n" +
								   "Blink Write Register " + Dz.byteToHex(addrA8, true) + " does not exist.", true);			
		}
	}

    /**
     * Internal signal for stopping the Z80 execution engine
     */
    private boolean stopZ88 = false;

	public void stopZ80Execution() {
		stopZ88 = true;
	}

    /**
     * Check if F5 key was pressed, or a stop was issued at command line.
     */
	public boolean isZ80Stopped() {
        if (stopZ88 == true) {
            stopZ88 = false;
			displayRtmMessage("Z88 virtual machine was stopped at " + Dz.extAddrToHex(decodeLocalAddress(getInstrPC()), true), true);
            return true;
        } else {
            return false;
        }
	}

	public void haltZ80() {
		// Z80 "Clock" is now stopped, but Blink "Clock" keeps running:
		// wait until an INT signal is fired...
		do {
			try {
				Thread.sleep(5);		// Z80 "sleeps" ... (interrupts still occurs in Blink)
			} catch (InterruptedException e) {
				e.printStackTrace(System.out);
			}						
		}
		// Only get out of snooze/coma if an interrupt occurred..
		while(interruptTriggered() == false);

		// (back to main Z80 decode loop)
	}

	public void hardReset() {
		reset(); 					// reset Z80 registers
		RAMS = memory.getBank(0);	// RAMS now points at ROM, bank 0 (reset code)
		memory.resetRam(); 			// reset memory of all available RAM in Z88 memory
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

		if ((bits & Blink.BM_COMVPPON) == Blink.BM_COMVPPON) {
			// Enable VPP pin on Eprom / Flash chip in slot 3, if available.
			cardType = memory.getBank(0xFF).getType();
			if (memory.getBank(0xFF).isVppPinEnabled() == false & 
				(cardType == Memory.Bank.EPROM_32KB | cardType == Memory.Bank.EPROM_128KB | cardType == Memory.Bank.FLASH)) {
				for (int bnk=0xC0; bnk <= 0xFF; bnk++) memory.getBank(bnk).setVppPin(true);
			}
		} else {
			// Disable VPP pin on Eprom / Flash chip in slot 3, if available and previously enabled...
			cardType = memory.getBank(0xFF).getType();
			if (memory.getBank(0xFF).isVppPinEnabled() == false & 
				(cardType == Memory.Bank.EPROM_32KB | cardType == Memory.Bank.EPROM_128KB | cardType == Memory.Bank.FLASH)) {
				for (int bnk=0xC0; bnk <= 0xFF; bnk++) memory.getBank(bnk).setVppPin(false);
			}			
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
	 * Insert RAM Card into Z88 memory system.
	 * RAM may be inserted into slots 0 - 3.
	 * RAM is loaded from bottom bank of slot and upwards.
	 * Slot 0 (512Kb): banks 20 - 3F
	 * Slot 1 (1Mb):   banks 40 - 7F
	 * Slot 2 (1Mb):   banks 80 - BF
	 * Slot 3 (1Mb):   banks C0 - FF
	 *
	 * Slot 0 is special; max 512K RAM in top 512K address space.
	 * (bottom 512K address space in slot 0 is reserved for ROM, banks 00-1F)
	 */
	public void insertRamCard(int size, int slot) {
		int totalRamBanks, totalSlotBanks, curBank;

		slot %= 4; // allow only slots 0 - 3 range.
		size -= (size % Memory.BANKSIZE);
		totalRamBanks = size / Memory.BANKSIZE; // number of 16K banks in Ram Card

		Memory.Bank ramBanks[] = new Memory.Bank[totalRamBanks]; // the RAM card container
		for (curBank = 0; curBank < totalRamBanks; curBank++) {
			ramBanks[curBank] = memory.createBank(Memory.Bank.RAM);
		}

		memory.insertCard(ramBanks, slot); // insert the physical card into Z88 memory
	}


	/**
	 * Load ROM image (from opened file ressource) into Z88 memory system, slot 0.
	 *
	 * @param rom
	 * @throws IOException
	 */
	public void loadRomBinary(RandomAccessFile rom) throws IOException {
		if (rom.length() > (1024 * 512)) {
			throw new IOException("Max 512K ROM!");
		}
		if (rom.length() % (Memory.BANKSIZE * 2) > 0) {
			throw new IOException("ROM must be in even banks!");
		}

		Memory.Bank romBanks[] = new Memory.Bank[(int) rom.length() / Memory.BANKSIZE];
		// allocate ROM container
		byte bankBuffer[] = new byte[Memory.BANKSIZE];
		// allocate intermediate load buffer

		for (int curBank = 0; curBank < romBanks.length; curBank++) {
			romBanks[curBank] = memory.createBank(Memory.Bank.ROM);
			rom.readFully(bankBuffer); // load 16K from file, sequentially
			romBanks[curBank].loadBytes(bankBuffer, 0);
			// and load fully into bank
		}

		// Finally, check for Z88 ROM Watermark
		if (romBanks[romBanks.length-1].getByte(0x3FFB) != 0x81 &
		    romBanks[romBanks.length-1].getByte(0x3FFE) != 'O' &
		    romBanks[romBanks.length-1].getByte(0x3FFF) != 'Z') {
				throw new IOException("This is not a Z88 ROM");
	    }

		// complete ROM image now loaded into container
		// insert container into Z88 memory, slot 0, banks $00 onwards.
		memory.insertCard(romBanks, 0);
		RAMS = memory.getBank(0);				// point at ROM bank 0
	}


	/**
	 * Load Card Image (from opened file ressource) into Z88 memory system,
	 * at defined slot.
	 *
	 * @param slot
	 * @param card
	 * @throws IOException
	 */
	public void loadCardBinary(int slot, RandomAccessFile card) throws IOException {
		int defaultType = Memory.Bank.EPROM_128KB;
		
		if (card.length() > (1024 * 1024)) {
			throw new IOException("Max 1024K Card!");
		}
		if (card.length() % Memory.BANKSIZE > 0) {
			throw new IOException("Card must be in 16K sizes!");
		}

		Memory.Bank cardBanks[] = new Memory.Bank[(int) card.length() / Memory.BANKSIZE];
		// allocate EPROM container
		byte bankBuffer[] = new byte[Memory.BANKSIZE];
		// allocate intermediate load buffer

		switch(cardBanks.length) {
			case 1:
			case 2:
				defaultType = Memory.Bank.EPROM_32KB;
				break;
			case 8:
			case 16:
				defaultType = Memory.Bank.EPROM_128KB;
				break;
			case 64:
				defaultType = Memory.Bank.FLASH;
				break;
			default:
				// all other sizes will be interpreted as UV EPROM's 
				// that can be programmed using 128K type specs.
				defaultType = Memory.Bank.EPROM_128KB;
				break;
		}
		
		for (int curBank = 0; curBank < cardBanks.length; curBank++) {
			cardBanks[curBank] = memory.createBank(defaultType);
			card.readFully(bankBuffer); // load 16K from file, sequentially
			cardBanks[curBank].loadBytes(bankBuffer, 0);
			// and load fully into bank
		}

		// Check for Z88 Application Card Watermark
		if (cardBanks[cardBanks.length-1].getByte(0x3FFB) == 0x80 &
			cardBanks[cardBanks.length-1].getByte(0x3FFE) == 'O' &
			cardBanks[cardBanks.length-1].getByte(0x3FFF) == 'Z') {
			displayRtmMessage("Application Card was inserted into slot " + slot, false);
		} else {
			// Check for Z88 File Card Watermark
			if (cardBanks[cardBanks.length-1].getByte(0x3FFE) == 'o' &
				cardBanks[cardBanks.length-1].getByte(0x3FFF) == 'z') {
				displayRtmMessage("File Card was inserted into slot " + slot, false);
			} else {
				throw new IOException("This is not a Z88 Application Card nor a File Card.");
			}
		}

		// complete Card image now loaded into container
		// insert container into Z88 memory, slot x, at bottom of slot, onwards.
		memory.insertCard(cardBanks, slot);
	}

	
	/**
	 * Load ROM image (from opened file ressource inside JAR)
	 * into Z88 memory system, slot 0.
	 *
	 * @param jarRessource
	 * @throws IOException
	 */
	public void loadRomBinary(URL jarRessource) throws IOException {
		JarURLConnection jarConnection = (JarURLConnection)jarRessource.openConnection();

		if (jarConnection.getJarEntry().getSize() > (1024 * 512)) {
			throw new IOException("Max 512K ROM!");
		}
		if (jarConnection.getJarEntry().getSize() % Memory.BANKSIZE > 0) {
			throw new IOException("ROM must be in 16K sizes!");
		}

		Memory.Bank romBanks[] = new Memory.Bank[(int) jarConnection.getJarEntry().getSize() / Memory.BANKSIZE];
		// allocate ROM container
		byte bankBuffer[] = new byte[Memory.BANKSIZE];
		// allocate intermediate load buffer

		InputStream is = jarConnection.getInputStream();
		BufferedInputStream bis = new BufferedInputStream( is, Memory.BANKSIZE );

		for (int curBank = 0; curBank < romBanks.length; curBank++) {
			romBanks[curBank] = memory.createBank(Memory.Bank.ROM);
			int bytesRead = bis.read(bankBuffer, 0, Memory.BANKSIZE);	// load 16K from file, sequentially
			romBanks[curBank].loadBytes(bankBuffer, 0); 		// and load fully into bank
		}

		// complete ROM image now loaded into container
		// insert container into Z88 memory, slot 0, banks $00 onwards.
		memory.insertCard(romBanks, 0);
		RAMS = memory.getBank(0);				// point at ROM bank 0
	}

	public void startInterrupts() {
		z80Int.start();
		if ( (getBlinkCom() & Blink.BM_COMRESTIM) == 0 ) rtc.start();
	}

	public void stopInterrupts() {
		z80Int.stop();
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

				if (++tick > 1) {
					// 1/100 second has passed
					tick = 0;
					if (((INT & BM_INTTIME) == BM_INTTIME) && ((TMK & BM_TMKTICK) == BM_TMKTICK)) {
						// INT.TIME interrupts are enabled and TMK.TICK interrupts are enabled:
						// Signal that a tick interrupt occurred
						TSTA |= BM_TSTATICK; // TSTA.BM_TSTATICK = 1
						STA |= BM_STATIME;
					}
				}

				if (++TIM0 > 199) {
					// 1 second has passed...
					TIM0 = 0;

					if (((INT & BM_INTTIME) == BM_INTTIME) && ((TMK & BM_TMKSEC) == BM_TMKSEC)) {
						// INT.TIME interrupts are enabled and TMK.SEC interrupts are enabled:
						// Signal that a second interrupt occurred
						TSTA |= BM_TSTASEC; // TSTA.BM_TSTASEC = 1
						STA |= BM_STATIME;
					}

					if (++TIM1 > 59) {
						// 1 minute has passed
						TIM1 = 0;
						if (((INT & BM_INTTIME) == BM_INTTIME) && ((TMK & BM_TMKMIN) == BM_TMKMIN)) {
							// INT.TIME interrupts are enabled and TMK.MIN interrupts are enabled:
							// Signal that a minute interrupt occurred
							TSTA |= BM_TSTAMIN; // TSTA.BM_TSTAMIN = 1
							STA |= BM_STATIME;
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
	 * The BLINK supplies the INT signal to the Z80 processor.
	 * An INT is fired each 10ms, which the Z80 responds to through IM 1
	 * (executing a RST 38H instruction).
	 */
	private final class Z80interrupt {
		private TimerTask intIm1 = null;

		/**
		 * Send an INT each 10ms to the Z80 processor...
		 */
		private final class Int10ms extends TimerTask {
			public void run() {
                // signal Maskable interrupt to be executed, as soon as Z80 is ready to grab it...
                setNmi(false);
                setInterruptSignal();
                Thread.yield();
			}
		}

		/**
		 * Stop the 10ms interrupt.
		 */
		public void stop() {
			if (intIm1 != null) {
				intIm1.cancel();
			}
		}

		/**
		 * Start interrupt to the Z80, and execute the run()
		 * method every 10 millisecond.
		 */
		public void start() {
			intIm1 = new Int10ms();
			timerDaemon.scheduleAtFixedRate(intIm1, 0, 10);
		}
	}

	/**
	 * @return
	 */
	public Z88Keyboard getZ88Keyboard() {
		return z88Keyboard;
	}

	/**
	 * @return
	 */
	public boolean isDebugMode() {
		return debugMode;
	}

	/**
	 * @param b
	 */
	public void setDebugMode(boolean b) {
		debugMode = b;
	}

	/**
	 * Handle action on encountered breakpoint.<p>
	 *
	 * @return true, if Z80 engine is to be stopped.
	 */
	public void breakPointAction() {
		int bpAddress = decodeLocalAddress(getInstrPC());
		int bpOpcode = getByte(bpAddress);	// remember the breakpoint instruction opcode
		int z80Opcode = breakPoints.getOrigZ80Opcode(bpAddress); 	// get the original Z80 opcode at breakpoint address
		setByte(bpAddress, z80Opcode);								// patch the original opcode back into memory (temporarily)
		displayRtmMessage((new DisplayStatus(this)).dzPcStatus(getInstrPC()).toString(), true); // dissassemble original instruction, with Z80 main reg dump
		setByte(bpAddress, bpOpcode);								// re-patch the breakpoint opcode, for future encounter
		if (breakPoints.isStoppable(bpAddress) == true) {
			displayRtmMessage("Z88 virtual machine was stopped at breakpoint.", false);
		}
	}

	/**
	 * @param breakpoints
	 */
	public void setBreakPointManager(Breakpoints bpm) {
		breakPoints = bpm;
	}
}
