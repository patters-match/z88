package net.sourceforge.z88;

import java.io.*;
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
	public Z88() throws Exception {
		// Z88 runs at 3.2768Mhz (the old spectrum was 3.5Mhz, a bit faster...)
		// This emulator runs at the speed it can get and provides external
		// interrupt signals each 10ms from BLINK to Z80 through INT pin
		super();

		blink = new Blink(this); // initialize BLINK chip

		slotCards = new Bank[4][];
		// Instantiate the slot containers for Cards...
		for (int slot = 0; slot < 4; slot++)
			slotCards[slot] = null; // nothing available in slots..

		insertRamCard(128 * 1024, 0);
		// Insert 128K RAM in slot 0 (top 512K address space)

		// z80Speed = new MonitorZ80();	// finally, set up a monitor that display current Z80 speed
	}

	private MonitorZ80 z80Speed = null;
	
	/**
	 * Z80 processor is hardwired to the BLINK chip logic.
	 */
	private Blink blink;


	/**
	 * Internal static buffer for runtime disassembly.
	 */
	private static final StringBuffer dzBuffer = new StringBuffer(64);

	/**
	 * The container for the current loaded card entities in the Z88 memory
	 * system for slot 0, 1, 2 and 3.
	 *
	 * Slot 0 will only keep a RAM Card in top 512K address space
	 * The ROM "Card" is only loaded once at OZvm boot
	 * and is never removed.
	 */
	private Bank slotCards[][];

	public void hardReset() {
		reset(); // reset Z80 registers
		blink.setCom(0); // reset COM register
		resetRam(); // reset memory of all available RAM in Z88 memory
	}

	public void haltInstruction() {
		// Let the Blink know that a HALT instruction occured
		// so that the Z88 enters the correct state (coma, snooze, ...)
	}

	/**
	 * Scan available slots for Ram Cards, and reset them..
	 */
	private void resetRam() {
		for (int slot = 0; slot < slotCards.length; slot++) {
			// look at bottom bank in Card for type; only reset RAM Cards...
			if (slotCards[slot] != null
				&& slotCards[slot][0].getType() == Bank.RAM) {
				// reset all banks in Card of current slot
				for (int cardBank = 0;
					cardBank < slotCards[slot].length;
					cardBank++) {
					Bank b = slotCards[slot][cardBank];
					for (int bankOffset = 0;
						bankOffset < Bank.SIZE;
						bankOffset++) {
						b.writeByte(bankOffset, 0);
					}
				}
			}
		}
	}

	/**
	 * Insert RAM Card into Z88 memory system.
	 * Size must be in modulus 32Kb (even numbered 16Kb banks).
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
		size -= (size % 32768); // allow only modulus 32Kb RAM.
		totalRamBanks = size / 16384; // number of 16K banks in Ram Card

		Bank ramBanks[] = new Bank[totalRamBanks]; // the RAM card container
		for (curBank = 0; curBank < totalRamBanks; curBank++) {
			ramBanks[curBank] = new Bank(Bank.RAM);
		}

		slotCards[slot] = ramBanks;
		// remember Ram Card for future reference...
		loadCard(ramBanks, slot); // load the physical card into Z88 memory
	}

	/**
	 * Load externally specified ROM image into Z88 memory system, slot 0.
	 *
	 * @param filename
	 * @throws FileNotFoundException
	 * @throws IOException
	 */
	public void loadRom(String filename)
		throws FileNotFoundException, IOException {
		RandomAccessFile rom = new RandomAccessFile(filename, "r");

		if (rom.length() > (1024 * 512)) {
			throw new IOException("Max 512K ROM!");
		}
		if (rom.length() % (Bank.SIZE * 2) > 0) {
			throw new IOException("ROM must be in even banks!");
		}

		Bank romBanks[] = new Bank[(int) rom.length() / Bank.SIZE];
		// allocate ROM container
		byte bankBuffer[] = new byte[Bank.SIZE];
		// allocate intermediate load buffer

		for (int curBank = 0; curBank < romBanks.length; curBank++) {
			romBanks[curBank] = new Bank(Bank.ROM);
			rom.readFully(bankBuffer); // load 16K from file, sequentially
			romBanks[curBank].loadBytes(bankBuffer, 0);
			// and load fully into bank
		}

		// complete ROM image now loaded into container
		// insert container into Z88 memory, slot 0, banks $00 onwards.
		loadCard(romBanks, 0);
	}

	/**
	 * Load Card (RAM/ROM/EPROM) into Z88 memory system.
	 * Size is in modulus 32Kb (even numbered 16Kb banks).
	 * Slot 0 (512Kb): banks 00 - 1F (ROM), banks 20 - 3F (RAM)
	 * Slot 1 (1Mb):   banks 40 - 7F (RAM or EPROM)
	 * Slot 2 (1Mb):   banks 80 - BF (RAM or EPROM)
	 * Slot 3 (1Mb):   banks C0 - FF (RAM or EPROM)
	 *
	 * @param card
	 * @param slot
	 */
	private void loadCard(Bank card[], int slot) {
		int totalSlotBanks, slotBank, curBank;

		if (slot == 0) {
			// Define bottom bank for ROM/RAM
			slotBank = (card[0].getType() != Bank.RAM) ? 0x00 : 0x20;
			// slot 0 has 32 * 16Kb = 512K address space for RAM or ROM
			totalSlotBanks = 32;
		} else {
			slotBank = slot << 6; // convert slot number to bottom bank of slot
			totalSlotBanks = 64;
			// slots 1 - 3 have 64 * 16Kb = 1Mb address space
		}

		for (curBank = 0; curBank < card.length; curBank++) {
			blink.setBank(card[curBank], slotBank++);
			// "insert" 16Kb bank into Z88 memory
			--totalSlotBanks;
		}

		// - the bottom of the slot has been loaded with the Card.
		// Now, we need to fill the 1MB address space in the slot with the card.
		// Note, that most cards and the internal memory do not exploit
		// the full lMB addressing range, but only decode the lower address lines.
		// This means that memory will appear more than once within the lMB range.
		// The memory of a 32K card in slot 1 would appear at banks $40 and $41,
		// $42 and $43, ..., $7E and $7F. Alternatively a 128K EPROM in slot 3 would
		// appear at $C0 to $C7, $C8 to $CF, ..., $F8 to $FF.
		// This way of addressing is assumed by the system.
		// Note that the lowest and highest bank in an EPROM can always be addressed
		// by looking at the bank at the bottom of the 1MB address range and the bank
		// at the top respectively.
		while (totalSlotBanks > 0) {
			for (curBank = 0; curBank < card.length; curBank++) {
				blink.setBank(card[curBank], slotBank++);
				// "shadow" card banks into remaining slot
				--totalSlotBanks;
			}
		}
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
			start();
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
