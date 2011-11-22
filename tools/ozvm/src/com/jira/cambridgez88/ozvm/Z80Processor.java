/*
 * Z80Processor.java
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

/**
 * Z80 processor implementation in Z88.
 */
public class Z80Processor extends Z80 implements Runnable {

	private Blink blink;
	private Breakpoints breakpoints;
    private boolean singleStepping;
	private long z88StoppedAtTime;
	private boolean interrupts;
	private int oneStopBreakpoint;

    /**
     * Internal signal for stopping the Z80 execution engine
     */
    private boolean stopZ88;

	public Z80Processor() {
		blink = Z88.getInstance().getBlink();
		breakpoints = new Breakpoints();
		singleStepping = true;
		stopZ88 = false;
	}

	/**
	 * execute a single Z80 instruction and return
	 */
	public void singleStepZ80() {
		singleStepping = true;
		decode(true);
	}

	/**
	 * execute Z80 instructions until a breakpoint is reached,
	 * stop command is entered or F5 was pressed in Z88 screen
	 */
    public void execZ80() {
    	singleStepping = false;
    	decode(false);			// run until we drop dread!
    }

    /**
     * Ask the Blink whether it's single stepping or not.
     */
	public boolean singleSteppingMode() {
        return singleStepping;
    }

	/**
	 * A HALT instruction was executed by the Z80 processor; Go into coma
	 * and wait for an interrupt (normally when both SHIFT keys pressed)
	 * HALT is ignored if Blink is in single stepping mode.
	 */
	public synchronized void haltZ80() {
		if (singleSteppingMode() == false) {
			// HALT is simulated when running the OZvm

			// During Coma, the I register hold the address lines to be read, and to generate an
			// interrupt when both SHIFT keys are pressed (matching the address line A8-A15)
			// Coma handling is done in Blink.signalKeyPressed() and Blink.Rtc.Counter.run()
			try {
                blink.enableComa();
			} catch (InterruptedException e1) {
			}

		    // Awakened from Coma, signal maskable interrupt to Z80..
		    setIntSignal();
		}
	}

	public void stopZ80Execution() {
		stopZ88 = true;
	}

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
     * Check if F5 key was pressed, or a stop was issued at command line.
     */
	public boolean isZ80Stopped() {
        if (stopZ88 == true) {
            stopZ88 = false;
            z88StoppedAtTime = System.currentTimeMillis();
            OZvm.displayRtmMessage("Z88 virtual machine was stopped at " + Dz.extAddrToHex(blink.decodeLocalAddress(getInstrPC()), true));

            return true;
        } else {
            return false;
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
	public int readByte(int addr) {
		return blink.readByte(addr);
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
	public void writeByte(int addr, int b) {
		blink.writeByte(addr, b);
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
	public int readWord(int addr) {
		return blink.readWord(addr);
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
	public void writeWord(int addr, int w) {
		blink.writeWord(addr, w);
	}

	/**
	 * Handle action on encountered breakpoint.<p>
	 * (But ignore it, if the processor is just executing a LD B,B without a registered breakpoint
	 * for that address (T-Touch on the Z88 does it)!
	 *
	 * @return true, if Z80 engine is to be stopped (a real breakpoint were found).
	 */
	public boolean breakPointAction() {
		int bpAddress = blink.decodeLocalAddress(getInstrPC());

		if (breakpoints.getOrigZ80Opcode(bpAddress) != -1) {
			// a breakpoint was defined for that address;
			OZvm.displayRtmMessage(Z88Info.dzPcStatus(getInstrPC())); 	// dissassemble original instruction, with Z80 main reg dump

			if (breakpoints.isActive(bpAddress) == true && breakpoints.isStoppable(bpAddress) == true) {
				PC(getInstrPC()); // PC is reset to breakpoint (currently, it points at the instruction AFTER the breakpoint)
				OZvm.displayRtmMessage("Z88 virtual machine was stopped at breakpoint.");

				OZvm.getInstance().commandLine(true); // Activate Debug Command Line Window...
				return true; // signal to stop the Z80 processor...
			}
		}

		return false; // don't stop; either no breakpoint were found, or it's just a display breakpoint..
	}

	/**
	 * Display information on encountered 'breakpoint'.<p>
	 * (But ignore it, if the processor is just executing a LD C,C without a registered breakpoint
	 * for that address!
	 *
	 * @return true, if Z80 engine is to be stopped (a real breakpoint were found).
	 */
	public void breakPointInfo() {
		breakPointAction();

		Memory memory = Z88.getInstance().getMemory();

		PC(PC() - 1); // reset Program Counter to Display Breakpoint Opcode
		int bpAddress = blink.decodeLocalAddress(PC());
		int bpOpcode = memory.getByte(bpAddress);	// remember the breakpoint instruction opcode

		int z80Opcode = getBreakpoints().getOrigZ80Opcode(bpAddress); 	// get the original Z80 opcode at breakpoint address
		memory.setByte(bpAddress, z80Opcode); // patch the original opcode back into memory (temporarily)
		decode(true); // execute the original instruction at display breakpoint
		memory.setByte(bpAddress, bpOpcode);  // re-patch the breakpoint opcode, for future encounter
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
	 * Implement Z88 output port Blink hardware.
	 * (RTC, Screen, Keyboard, Memory model, Serial port, CPU state).
	 *
	 * @param addrA8 LSB of port address
	 * @param addrA15 MSB of port address
	 * @param outByte the data to send to the hardware
	 */
	public final void outByte(final int addrA8, final int addrA15, final int outByte) {
		switch (addrA8) {
			case 0xD0 : // SR0, Segment register 0
			case 0xD1 : // SR1, Segment register 1
			case 0xD2 : // SR2, Segment register 2
			case 0xD3 : // SR3, Segment register 3
				blink.setSegmentBank(addrA8, outByte);
				break;

			case 0xB0 : // COM, Set Command Register
				blink.setBlinkCom(outByte);
				break;

			case 0xB1 : // INT, Set Main Blink Interrupts
				blink.setBlinkInt(outByte);
				break;

			case 0xB3 : // EPR, Eprom Programming Register
				blink.setBlinkEpr(outByte);
				break;

			case 0xB4 : // TACK, Set Timer Interrupt Acknowledge
				blink.setBlinkTack(outByte);
				break;

			case 0xB5 : // TMK, Set Timer interrupt Mask
				blink.setBlinkTmk(outByte);
				break;

			case 0xB6 : // ACK, Acknowledge INT Interrupts
				blink.setBlinkAck(outByte);
				break;

			case 0x70 : // PB0, Pixel Base Register 0 (Screen)
				blink.setBlinkPb0((addrA15 << 8) | outByte);
				break;

			case 0x71 : // PB1, Pixel Base Register 1 (Screen)
				blink.setBlinkPb1((addrA15 << 8) | outByte);
				break;

			case 0x72 : // PB2, Pixel Base Register 2 (Screen)
				blink.setBlinkPb2((addrA15 << 8) | outByte);
				break;

			case 0x73 : // PB3, Pixel Base Register 3 (Screen)
				blink.setBlinkPb3((addrA15 << 8) | outByte);
				break;

			case 0x74 : // SBR, Screen Base Register
				blink.setBlinkSbr((addrA15 << 8) | outByte);
				break;

			case 0xE2 : // RXC, UART Receiver Control (not yet implemented)
			case 0xE3 : // TXD, UART Transmit Data (not yet implemented)
			case 0xE4 : // TXC, UART Transmit Control (not yet implemented)
				break;
			case 0xE5 : // UMK, UART Int. mask (not yet implemented)
			case 0xE6 : // UAK, UART acknowledge int. mask (not yet implemented)
				break;

			default:
				if (OZvm.getInstance().getDebugMode() == true) {
					OZvm.displayRtmMessage("WARNING:\n" +
										Z88Info.dzPcStatus(getInstrPC()) + "\n" +
										"Blink Write Register " + Dz.byteToHex(addrA8, true) + " does not exist.");
				}
		}
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

		switch (addrA8) {
			case 0xB1:
                res = blink.getBlinkSta(); // STA, Main Blink Interrupt Status
				break;

			case 0xB2:
				if (singleSteppingMode() == false & stopZ88 == false) {
					res = blink.getBlinkKbd(addrA15);	// KBD, get Keyboard column for specified row.
				}
				break;

			case 0xB5:
                res = blink.getBlinkTsta();	// TSTA, which RTC interrupt occurred...
				break;

            case 0xD0:
				res = blink.getBlinkTim0();	// TIM0, 5ms period, counts to 199
				break;

			case 0xD1:
				res = blink.getBlinkTim1();	// TIM1, 1 second period, counts to 59
				break;

			case 0xD2:
				res = blink.getBlinkTim2();	// TIM2, 1 minute period, counts to 255
				break;

			case 0xD3:
				res = blink.getBlinkTim3();	// TIM3, 256 minutes period, counts to 255
				break;

			case 0xD4:
				res = blink.getBlinkTim4();	// TIM4, 64K minutes Period, counts to 31
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
				if (OZvm.getInstance().getDebugMode() == true) {
					OZvm.displayRtmMessage("WARNING:\n" +
									   Z88Info.dzPcStatus(getInstrPC()) + "\n" +
									   "Blink Read Register " + Dz.byteToHex(addrA8, true) + " does not exist.");
				}
				res = 0;
		}

		return res;
	}

	/**
	 * Thread start; execute the Z80 processor
	 */
	public void run() {
		Breakpoints breakPointManager = getBreakpoints();
        Thread.currentThread().setName("Z80Processor");

		if (breakPointManager.isStoppable(blink.decodeLocalAddress(PC())) == true) {
			// we need to use single stepping mode to
			// step	past the break point at	current	instruction
			singleStepZ80();
		}
		// restore (patch) breakpoints into code
		breakPointManager.installBreakpoints();
		if (interrupts == true) blink.startInterrupts(); // enable Z80/Z88 core interrupts
		execZ80();
		// execute Z80 code at full speed until	breakpoint is encountered...
		// (or F5 emergency break is used!)
		if (interrupts == true) blink.stopInterrupts();
		breakPointManager.clearBreakpoints();

		if (oneStopBreakpoint != -1)
			breakPointManager.toggleBreakpoint(oneStopBreakpoint); // remove the temporary breakpoint (reached, or not)

		if (OZvm.getInstance().getDebugMode() == true) {
			OZvm.getInstance().commandLine(true); // Activate Debug Command Line Window...
			OZvm.getInstance().getCommandLine().initDebugCmdline();
		}
	}

	public void setInterrupts(boolean interrupts) {
		this.interrupts = interrupts;
	}

	public void setOneStopBreakpoint(int oneStopBreakpoint) {
		this.oneStopBreakpoint = oneStopBreakpoint;
	}

	public int getPcAddress() {
		return blink.decodeLocalAddress(PC());
	}
}
