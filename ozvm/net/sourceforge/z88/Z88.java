package net.sourceforge.z88;

import java.io.*;
import java.net.URL;
import java.util.Timer;
import java.util.TimerTask;

/**
 * 
 * The "Heart" and blood stream of the Z88 (Z80 processor and RAM).
 * 
 * The Z88 class extends the Z80 class implementing the supporting hardware
 * emulation which was specific to the Z88. This includes the memory mapped
 * screen and the IO ports which were used to read the keyboard, the 4MB memory
 * model, the BLINK on/off. There is no sound support in this version.<P>
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

	/**
	 * Constructor.
	 * Initialize Z88 Hardware.
	 */
	public Z88() {
		// Z88 runs at 3.2768Mhz (the old spectrum was 3.5Mhz, a bit faster...)
		// This emulator runs at the speed it can get and provides external
		// interrupt signals each 10ms from BLINK to Z80 through INT pin
		super();

		blink = new Blink(this); // initialize BLINK chip

		// Insert 128K RAM in slot 0 (top 512K address space)
		blink.insertRamCard(128 * 1024, 0);

		z80Speed = new MonitorZ80();	// finally, set up a monitor that display current Z80 speed
	}

	private MonitorZ80 z80Speed = null;

	public void startZ80SpeedPolling() {
		z80Speed.start();
	}

	public void stopZ80SpeedPolling() {
		z80Speed.stop();
	}
	
	/**
	 * Z80 processor is hardwired to the BLINK chip logic.
	 */
	private Blink blink;


	/**
	 * Internal static buffer for runtime disassembly.
	 */
	private static final StringBuffer dzBuffer = new StringBuffer(64);

	public void hardReset() {
		reset(); // reset Z80 registers
		blink.setCom(0); // reset COM register
		blink.resetRam(); // reset memory of all available RAM in Z88 memory
	}

	public void haltInstruction() {
		// Let the Blink know that a HALT instruction occured
		// so that the Z88 enters the correct state (coma, snooze, ...)
	}

	/**
	 * Load default ROM image from this JAR into Z88 memory system, slot 0.
	 *
	 * @param filename
	 * @throws FileNotFoundException
	 * @throws IOException
	 */
	public void loadRom(String filename)
		throws FileNotFoundException, IOException {
		RandomAccessFile rom = new RandomAccessFile(filename, "r");		
		blink.loadRomBinary(rom);	
	}

	/**
	 * Load default ROM image from this JAR into Z88 memory system, slot 0.
	 *
	 * @param filename
	 * @throws FileNotFoundException
	 * @throws IOException
	 */
	public void loadRom(URL filename)
		throws FileNotFoundException, IOException {
		RandomAccessFile rom = new RandomAccessFile(filename.getFile(),"r");		
		blink.loadRomBinary(rom);	
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
	public final int readByte(final int addr) {
		return blink.readByte(addr);
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
	public final void writeByte(final int addr, final int b) {
		blink.writeByte(addr, b);
	}

	/**
	 * Read word (16bits) from Z80 virtual memory model. 
	 * <addr> is a 16bit word that points into the Z80 64K address space.
	 *
	 * On the Z88, the 64K is split into 4 sections of 16K segments.
	 * Any of the 256 16K banks can be bound into the address space
	 * on the Z88. Bank 0 is special, however.
	 * Please refer to hardware section of the Developer's Notes.
	 */
	public final int readWord(final int addr) {
		return blink.readWord(addr);
	}

	/**
	 * Write word (16bits) to Z80 virtual memory model. <addr> is a 16bit word
	 * that points into the Z80 64K address space.
	 *
	 * On the Z88, the 64K is split into 4 sections of 16K segments.
	 * Any of the 256 16K banks can be bound into the address space
	 * on the Z88. Bank 0 is special, however.
	 * Please refer to hardware section of the Developer's Notes.
	 */
	public final void writeWord(final int addr, final int w) {
		blink.writeWord(addr, w);
	}

	/**
	 * Read Z80 instruction as a 4 byte entity from Z80 virtual memory model,
	 * starting from offset, onwards. <addr> is a 16bit word that points into
	 * the Z80 64K address space. Z80 instructions varies between 1 and 4 bytes,
	 * but here a complete 4 byte sequence is cached in the return argument,
	 * without knowing the actual length.
	 * 
	 * The instruction is returned as a 32bit integer for compactness, in low
	 * byte, high byte order, ie. lowest 8bit is the first byte of the
	 * instruction, highest 8bit of 32bit integer is the 4th byte of the
	 * instruction.
	 *  
	 * @param addr address offset in bank
	 * @return int 4 byte Z80 instruction 
	 */
	public final int readInstruction(final int addr) {
		return blink.readInstruction(addr);
	}

	/**
	 * Implement Z88 input port BLINK hardware 
	 * (RTC, Keyboard, Flap, Batt Low, Serial port).
	 * 
	 * @param addrA8
	 * @param addrA15
	 */	
	public final int inByte(int addrA8, int addrA15) {
		int res = 0;

		switch (addrA8) {
			case 0xD0:
				res = blink.getTim0();	// TIM0, 5ms period, counts to 199  
				break;
				
			case 0xD1:
				res = blink.getTim1();	// TIM1, 1 second period, counts to 59  
				break;
				
			case 0xD2:
				res = blink.getTim2();	// TIM2, 1 minute period, counts to 255  
				break;
				
			case 0xD3:
				res = blink.getTim3();	// TIM3, 256 minutes period, counts to 255     
				break;
				
			case 0xD4:
				res = blink.getTim4();	// TIM4, 64K minutes Period, counts to 31        
				break;
				
			case 0xB1:
				res = blink.getSta();	// STA, Main Blink Interrupt Status
				break;
				
			case 0xB2:
				res = blink.getKbd(addrA15);	// KBD, Keyboard matrix for specified row.
				break;
				
			case 0xB5:
				res = blink.getTsta(); 	// TSTA, RTC Interrupt Status
				break;
				
			default :
				res = 0;				// all other ports in BLINK not yet implemented...
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
		switch (addrA8) {
			case 0xD0 : // SR0, Segment register 0
			case 0xD1 : // SR1, Segment register 1
			case 0xD2 : // SR2, Segment register 2
			case 0xD3 : // SR3, Segment register 3
				blink.setSegmentBank(addrA8, outByte);
				break;
			
			case 0xB0 : // COM, Set Command Register
				blink.setCom(outByte);
				break;

			case 0xB1 : // INT, Set Main Blink Interrupts
				blink.setInt(outByte);
				break;

			case 0xB4 : // TACK, Set Timer Interrupt Acknowledge
				blink.setTack(outByte);
				break;

			case 0xB5 : // TMK, Set Timer interrupt Mask
				blink.setTmk(outByte);
				break;
							
			case 0xB6 : // ACK, Acknowledge Main Interrupts				
				blink.setAck(outByte);
				break;

			case 0x70 : // PB0, Pixel Base Register 0 (Screen)
				blink.setPb0(outByte);
				break;				

			case 0x71 : // PB1, Pixel Base Register 1 (Screen)
				blink.setPb1(outByte);
				break;				

			case 0x72 : // PB2, Pixel Base Register 2 (Screen)
				blink.setPb2(outByte);
				break;				

			case 0x73 : // PB3, Pixel Base Register 3 (Screen)
				blink.setPb3(outByte);
				break;				

			case 0x74 : // SBR, Screen Base Register 
				blink.setSbr(outByte);
				break;				
		}
	}
	
	/** 
	 * Z80 instruction speed monitor. 
	 * Polls each second for the execution speed and displays it to std out.
	 */
	private class MonitorZ80 {

		Timer timer = null;
		TimerTask monitor = null;

		private class SpeedPoll extends TimerTask {
			/**
			 * Send an INT each 10ms to the Z80 processor...
			 * 
			 * @see java.lang.Runnable#run()
			 */
			public void run() {
				System.out.println( "IPS=" + getInstructionCounter() + 
                                   ",TPS=" + getTstatesCounter());
			}			
		}
		
		private MonitorZ80() {
			timer = new Timer();
		}

		/**
		 * Stop the Z80 Speed Monitor.
		 */
		public void stop() {
			if (timer != null)
				timer.cancel();
		}

		/**
		 * Speed polling monitor asks each second for Z80 speed status.
		 */
		public void start() {
			monitor = new SpeedPoll();
			timer.scheduleAtFixedRate(monitor, 0, 1000);
		}
	} 
}
