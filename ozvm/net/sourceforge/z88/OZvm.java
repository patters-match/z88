package net.sourceforge.z88;

import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.RandomAccessFile;
import java.util.Map;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Timer;
import java.util.TimerTask;

/**
 * @author <A HREF="mailto:gstrube@tiscali.dk">Gunther Strube</A>
 *
 * Main entry of the Z88 virtual machine.
 * 
 * $Id$
 * 
 */
public class OZvm {

	Blink z88 = null;
	private MonitorZ80 z80Speed = null;

	OZvm() {
		try {
			z88 = new Blink();

			// Insert 128K RAM in slot 0 (top 512K address space)
			z88.insertRamCard(128 * 1024, 0);			
			z88.hardReset();

			z80Speed = new MonitorZ80();
			
			dz = new Dz(z88); // the disassembly engine, linked to the memory model
			breakp = new Breakpoints();

		} catch (Exception e) {
			e.printStackTrace();
			System.out.println("\n\nCouldn't initialize Z88 virtual machine.");
		}
	}

	public void startZ80SpeedPolling() {
		z80Speed.start();
	}

	public void stopZ80SpeedPolling() {
		z80Speed.stop();
	}

	public void startInterrupts() {
		z88.startInterrupts();
	}

	public void stopInterrupts() {
		z88.stopInterrupts();
	}

	/**
	 * The Z88 disassembly engine
	 */
	Dz dz;

	/**
	 * The Breakpoint manager instance.
	 */
	Breakpoints breakp;
	
	private StringBuffer z80Flags() {
		StringBuffer dzFlags = new StringBuffer(8);
		
		dzFlags.append( z88.Sset() == true ? "S" : "0");
		dzFlags.append( z88.Zset() == true ? "Z" : "0");
		dzFlags.append( z88.f5set() == true ? "1" : "0");
		dzFlags.append( z88.Hset() == true ? "H" : "0");
		dzFlags.append( z88.f3set() == true ? "1" : "0");
		dzFlags.append( z88.PVset() == true ? "P" : "V");
		dzFlags.append( z88.Nset() == true ? "N" : "0");
		dzFlags.append( z88.Cset() == true ? "C" : "0");
		
		return dzFlags;
	}

	private StringBuffer blinkBankBindings() {
		StringBuffer blinkBanks = new StringBuffer(256);
		
		blinkBanks.append("RAMS      (0000h-1FFFh): ");
		if ((z88.getCom() & Blink.BM_COMRAMS) == Blink.BM_COMRAMS) {
			blinkBanks.append("20h");
		} else {
			blinkBanks.append("00h");
		}
		blinkBanks.append("\n");
		
		blinkBanks.append("Segment 0 (2000h-3FFFh): ");
		blinkBanks.append(Dz.byteToHex(z88.getSegmentBank(0) & 0xFE,true)).append(" ");
		blinkBanks.append((z88.getSegmentBank(0) & 1) == 0 ? "(Lower 8K)" : "(Upper 8K)"); 
		blinkBanks.append("\n");
		
		blinkBanks.append("Segment 1 (4000h-7FFFh): ");
		blinkBanks.append(Dz.byteToHex(z88.getSegmentBank(1),true)).append("\n");

		blinkBanks.append("Segment 2 (8000h-BFFFh): ");
		blinkBanks.append(Dz.byteToHex(z88.getSegmentBank(2),true)).append("\n");

		blinkBanks.append("Segment 3 (C000h-FFFFh): ");
		blinkBanks.append(Dz.byteToHex(z88.getSegmentBank(3),true));
		
		return blinkBanks;
	}
	
	private StringBuffer blinkCom() {	
		StringBuffer blinkComFlags = new StringBuffer(256);
		blinkComFlags.append("");
		
		return blinkComFlags;
	}

	/**
	 * Dump current Z80 Registers.  
	 */
	private void displayZ80Registers() {
		StringBuffer dzRegisters = new StringBuffer(1024);

		dzRegisters.append(" ").append("BC=").append(Dz.addrToHex(z88.BC(),false)).append(" ");
		dzRegisters.append(" ").append("DE=").append(Dz.addrToHex(z88.DE(),false)).append(" ");
		dzRegisters.append(" ").append("HL=").append(Dz.addrToHex(z88.HL(),false)).append(" ");
		dzRegisters.append(" ").append("IX=").append(Dz.addrToHex(z88.IX(),false)).append(" ");
		dzRegisters.append(" ").append("IY=").append(Dz.addrToHex(z88.IY(),false)).append(" ");
		dzRegisters.append(" ").append("\n");
		z88.exx();
		dzRegisters.append("'BC=").append(Dz.addrToHex(z88.BC(),false)).append(" ");
		dzRegisters.append("'DE=").append(Dz.addrToHex(z88.DE(),false)).append(" ");
		dzRegisters.append("'HL=").append(Dz.addrToHex(z88.HL(),false)).append(" ");
		z88.exx();
		dzRegisters.append(" ").append("SP=").append(Dz.addrToHex(z88.SP(),false)).append(" ");
		dzRegisters.append(" ").append("PC=").append(Dz.addrToHex(z88.PC(),false)).append("\n");
		dzRegisters.append(" ").append("AF=").append(Dz.addrToHex(z88.AF(),false)).append(" ");
		dzRegisters.append(" ").append("A=").append(Dz.byteToHex(z88.A(),false)).append(" ");
		dzRegisters.append(" ").append("F=").append(z80Flags()).append(" ");
		dzRegisters.append(" ").append("I=").append(z88.I()).append("\n");
		z88.ex_af_af();
		dzRegisters.append("'AF=").append(Dz.addrToHex(z88.AF(),false)).append(" ");
		dzRegisters.append("'A=").append(Dz.byteToHex(z88.A(),false)).append(" ");
		dzRegisters.append("'F=").append(z80Flags()).append(" ");
		dzRegisters.append(" ").append("R=").append(z88.R()).append("\n");
		z88.ex_af_af();
		
		System.out.println(dzRegisters);
	}
	
	/**
	 * Dump current Z80 Registers and instruction disassembly to stdout.  
	 */
	private void z80Status() {
		StringBuffer dzBuffer = new StringBuffer(64);

		displayZ80Registers();
						
		dz.getInstrAscii(dzBuffer, z88.PC(), true);
		System.out.println(dzBuffer);
	}
	
	private boolean loadRom(String[] args) {
		try {
			if (args.length == 0) {
				System.out.println("No external ROM image specified, using default Z88.rom (V4.01 UK)");
				z88.loadRomBinary(z88.getClass().getResource("/Z88.rom"));				
			} else {
				System.out.println("Loading '" + args[0] + "'");
				RandomAccessFile rom = new RandomAccessFile(args[0], "r");		
				z88.loadRomBinary(rom);
			}			
			return true;

		} catch (FileNotFoundException e) {
			System.out.println("Couldn't load ROM image.\nOzvm terminated.");
			return false;
		} catch (IOException e) {
			System.out.println("Problem with ROM image or I/O.\nOzvm terminated.");
			return false;
		}		
	}

	private void cmdHelp() {
		System.out.println("run - execute Z88 machine from PC.");
		System.out.println("exit - exit OZvm.");
		System.out.println("");
		System.out.println(". - single step instruction at PC.");		
		System.out.println("d - disassembly at PC.");
		System.out.println("d [address [bank]] - disassemble at specified address.");
		System.out.println("m - view memory at PC.");
		System.out.println("m [address [bank]] - view memory at specified address.");
		System.out.println("bp - list breakpoints.");
		System.out.println("bp [address bank] - toggle breakpoint.");
		System.out.println("blsr - Blink: Segment Register Bank Binding.");
		System.out.println("r - Display current Z80 Registers.");
	}
	
	private void commandLine() throws IOException {
		int breakpointProgramCounter = -1;
		
		String cmdline = "";
		String[] cmdLineTokens = cmdLineTokens = cmdline.split(" ");
		
		BufferedReader in =
			new BufferedReader(new InputStreamReader(System.in));
		System.out.println("Type 'h' or 'help' for command line options\n");
		System.out.println(blinkBankBindings() + "\n");		
		z80Status();
		
		StringBuffer prevCmdline = new StringBuffer();
		do {
			if (cmdLineTokens[0].equalsIgnoreCase("h") == true || cmdLineTokens[0].equalsIgnoreCase("help") == true) {
				cmdHelp();
				cmdline = ""; // wait for a new command...
				cmdLineTokens = cmdline.split(" ");
			}

			if (cmdLineTokens[0].equalsIgnoreCase("run") == true) {
				if (z88.PC() == breakpointProgramCounter) {
					// we need to use single stepping mode to 
					// step past the break point at current instruction
					z88.run(true);
				}
				
				breakp.setBreakpoints();	// restore (patch) breakpoints into code
				z80Speed.start();			// enable execution speed monitor
				z88.startInterrupts();		// enable Z80/Z88 core interrupts 
				z88.run(false);				// execute Z80 code at full speed until breakpoint is encountered...
				z88.stopInterrupts();
				z80Speed.stop();
				breakp.clearBreakpoints();
				
				// when we're getting back, a breakpoint was encountered...
				breakpointProgramCounter = z88.PC();	// remember breakpoint address
				 
				System.out.println(blinkBankBindings() + "\n");	// display bank bindings
				z80Status();									// display Z80 register status
				cmdLineTokens[0] = ""; // wait for a new command...
			}

			if (cmdLineTokens[0].equalsIgnoreCase(".") == true) {
				z88.run(true);		// single stepping (no interrupts running)...				
				z80Status();
				cmdLineTokens[0] = ""; // wait for a new command...
			}
			
			if (cmdLineTokens[0].equalsIgnoreCase("d") == true) {
				cmdline = dzCommandline(in, cmdLineTokens);
				// sub commands return new command line...
				cmdLineTokens = cmdline.split(" ");
			}

			if (cmdLineTokens[0].equalsIgnoreCase("m") == true) {
				cmdline = viewMemory(in, cmdLineTokens);
				// sub commands return new command line...
				cmdLineTokens = cmdline.split(" ");
			}

			if (cmdLineTokens[0].equalsIgnoreCase("blsr") == true) {
				System.out.println(blinkBankBindings());
				cmdline = ""; // wait for a new command...
				cmdLineTokens = cmdline.split(" ");
			}

			if (cmdLineTokens[0].equalsIgnoreCase("r") == true) {
				displayZ80Registers();
				cmdline = ""; // wait for a new command...
				cmdLineTokens = cmdline.split(" ");
			}

			if (cmdLineTokens[0].equalsIgnoreCase("bp") == true) {
				bpCommandline(cmdLineTokens);
				cmdLineTokens[0] = ""; // wait for a new command...				
			}
			
			if (cmdLineTokens[0].length() > 0 &&
				cmdLineTokens[0].equalsIgnoreCase(".") == false &&
				cmdLineTokens[0].equalsIgnoreCase("d") == false &&
				cmdLineTokens[0].equalsIgnoreCase("r") == false &&
				cmdLineTokens[0].equalsIgnoreCase("h") == false &&
				cmdLineTokens[0].equalsIgnoreCase("m") == false &&				
				cmdLineTokens[0].equalsIgnoreCase("help") == false &&
				cmdLineTokens[0].equalsIgnoreCase("run") == false &&
			    cmdLineTokens[0].equalsIgnoreCase("bp") == false &&
				cmdLineTokens[0].equalsIgnoreCase("blsr") == false &&
				cmdLineTokens[0].equalsIgnoreCase("exit") == false
			   ) {
			   	// unknown commands get cleared so that we can 
			   	// read a new command...
			   	System.out.println("Unknown command.");
				cmdLineTokens[0] = "";
			}
				
			if (cmdLineTokens[0].length() == 0) {
				System.out.print("$");	// the command line prompt...
				cmdline = in.readLine();
				if (cmdline == null) 
					cmdLineTokens[0] = "exit";	// program aborted during input...
				else
					cmdLineTokens = cmdline.split(" ");
			} 
		} while (cmdLineTokens[0].equalsIgnoreCase("exit") == false);		
	}

	private void bpCommandline(String[] cmdLineTokens) throws IOException {
		if (cmdLineTokens.length == 3) {
			// no arguments, use PC in current bank binding
			breakp.toggleBreakpoint(Integer.parseInt(cmdLineTokens[1], 16), Integer.parseInt(cmdLineTokens[2], 16));
		}

		if (cmdLineTokens.length == 1) {
			// no arguments, use PC in current bank binding
			breakp.listBreakpoints();
		}
	}
	
	private String dzCommandline(BufferedReader in, String[] cmdLineTokens) throws IOException {
		int dzAddr = 0, dzBank = 0;		
		StringBuffer dzLine = new StringBuffer(64);
		String dzCmdline = null;
	
		if (cmdLineTokens.length == 1) {
			// no arguments, use PC in current bank binding
			dzAddr = z88.PC();
			dzBank = z88.getSegmentBank(dzAddr >>> 14);
		}

		if (cmdLineTokens.length == 2) {
			// one arguments; the local Z80 64K address 
			dzAddr = Integer.parseInt(cmdLineTokens[1], 16);
			dzBank = z88.getSegmentBank(dzAddr >>> 14);
		}

		if (cmdLineTokens.length == 3) {
			// two arguments; the offset and the bank number 
			dzAddr = Integer.parseInt(cmdLineTokens[1], 16);
			dzBank = Integer.parseInt(cmdLineTokens[2], 16);
		}

		do {		
			for (int dzLines = 0;  dzLines < 16; dzLines++) {
				dzAddr = dz.getInstrAscii(dzLine, dzAddr, dzBank, true);
				dzAddr &= 0xFFFF;
				System.out.println(dzLine);
			}
			
			System.out.print("$");
			dzCmdline = in.readLine();
			if (dzCmdline == null) dzCmdline = "exit";	// program aborted during input...
			
		}
		while (dzCmdline.length() == 0);
		
		return dzCmdline;
	}

	private int getMemoryAscii(StringBuffer memLine, int memAddr, int memBank) {
		int memHex, memAscii;
		
		memLine.delete(0,255);
		memLine.append(Dz.addrToHex(memAddr,true)).append("  ");
		for (memHex=memAddr; memHex < memAddr+16; memHex++) { 
			memLine.append(Dz.byteToHex(z88.getByte(memHex,memBank),false)).append(" ");
		}

		for (memAscii=memAddr; memAscii < memAddr+16; memAscii++) {
			int b = z88.getByte(memAscii,memBank); 
			memLine.append( (b >= 32 && b <= 127) ? Character.toString( (char) b) : "." );
		}
		
		return memAscii;	
	}
	
	private String viewMemory(BufferedReader in, String[] cmdLineTokens) throws IOException {
		int memAddr = 0, memBank = 0;		
		StringBuffer memLine = new StringBuffer(256);
		String memCmdline = null;
	
		if (cmdLineTokens.length == 1) {
			// no arguments, use PC in current bank binding
			memAddr = z88.PC();
			memBank = z88.getSegmentBank(memAddr >>> 14);
		}

		if (cmdLineTokens.length == 2) {
			// one arguments; the local Z80 64K address 
			memAddr = Integer.parseInt(cmdLineTokens[1], 16);
			memBank = z88.getSegmentBank(memAddr >>> 14);
		}

		if (cmdLineTokens.length == 3) {
			// two arguments; the offset and the bank number 
			memAddr = Integer.parseInt(cmdLineTokens[1], 16);
			memBank = Integer.parseInt(cmdLineTokens[2], 16);
		}

		do {		
			for (int memLines = 0;  memLines < 16; memLines++) {
				memAddr = getMemoryAscii(memLine, memAddr, memBank);
				memAddr &= 0xFFFF;
				System.out.println(memLine);
			}
			
			System.out.print("$");
			memCmdline = in.readLine();
			if (memCmdline == null) memCmdline = "exit";	// program aborted during input...
			
		}
		while (memCmdline.length() == 0);
		
		return memCmdline;
	}
	
	public static void main(String[] args) throws IOException {		
		System.out.println("OZvm V0.01, Z88 Virtual Machine");

		OZvm ozvm = new OZvm();
		if (ozvm.loadRom(args) == false) {
			System.out.println("Ozvm terminated.");
			System.exit(0);
		}
		
		ozvm.commandLine();
		
		System.out.println("Ozvm terminated.");
		System.exit(0);
	}

	/** 
	 * BreakPoint management in OZvm.
	 */
	private class Breakpoints {
		private Map breakPoints = null;
		
		/**
		 * Just instantiate this Breakpoint Manager
		 */
		Breakpoints() {
			breakPoints = new HashMap(); 
		}
		
		/**
		 * Instantiate this Breakpoint Manager with the
		 * first breakpoint.
		 */
		Breakpoints(int offset, int bank) {
			this();
			toggleBreakpoint(offset, bank);
		}

		/**
		 * Add (if not created) or remove breakpoint (if prev. created).
		 * 
		 * @param offset
		 * @param bank
		 */
		private void toggleBreakpoint(int offset, int bank) {
			Breakpoint bp = new Breakpoint(offset, bank);
			if (breakPoints.containsKey( (Breakpoint) bp) == false) 
				breakPoints.put((Breakpoint) bp, (Breakpoint) bp);
			else
				breakPoints.remove((Breakpoint) bp);
				
			listBreakpoints();
		}

		/**
		 * List breakpoints to console.
		 */
		private void listBreakpoints() {
			if (breakPoints.isEmpty() == true) {
				System.out.println("No Breakpoints defined.");
			} else {
				Iterator keyIterator = breakPoints.entrySet().iterator();
	
				while(keyIterator.hasNext()) {
					Map.Entry e = (Map.Entry) keyIterator.next();   
					Breakpoint bp = (Breakpoint) e.getKey();
	
					int offset = bp.getAddress() & 0xFFFF;
					int bank = bp.getAddress() >>> 16;
					System.out.print(Dz.addrToHex(offset,false) + "," + Dz.byteToHex(bank,false) + "\t"); 
				}
				System.out.println();
			}
		}

		/**
		 * Set the "breakpoint" instruction in Z88 memory for all 
		 * currently defined breakpoints.
		 */		
		private void setBreakpoints() {
			// now, set the breakpoint at the extended address; 
			// the instruction opcode ED80 (officially a NOP instruction).
			// which this virtual machine identifies as a "suspend" Z80 exection. 
			if (breakPoints.isEmpty() == false) {
				Iterator keyIterator = breakPoints.entrySet().iterator();
		
				while(keyIterator.hasNext()) {
					Map.Entry e = (Map.Entry) keyIterator.next();   
					Breakpoint bp = (Breakpoint) e.getKey();
	
					int offset = bp.getAddress() & 0x3FFF;
					int bank = bp.getAddress() >>> 16;
					z88.setByte(offset, bank, 0xED);
					z88.setByte(offset+1, bank, 0x80);
				}
			}
		}
		
		/**
		 * Clear the "breakpoint" instruction; ie. restore original bitpattern
		 * that was overwritten by the "breakpoint" instruction in Z88 memory.
		 */
		private void clearBreakpoints() {
			// restore at the extended address; 
			// the original instruction opcode that is preserved inside 
			// the BreakPoint object 
			if (breakPoints.isEmpty() == false) {
				Iterator keyIterator = breakPoints.entrySet().iterator();
		
				while(keyIterator.hasNext()) {
					Map.Entry e = (Map.Entry) keyIterator.next();   
					Breakpoint bp = (Breakpoint) e.getKey();
	
					int offset = bp.getAddress() & 0x3FFF;
					int bank = bp.getAddress() >>> 16;
					
					// restore the original opcode bit pattern... 
					z88.setByte(offset, bank, bp.getInstruction() & 0xFF);
					z88.setByte(offset+1, bank, bp.getInstruction() >>> 8);
				}
			}			
		}

		// The breakpoint container.
		private class Breakpoint {
			int addressKey;			// the 24bit address of the breakpoint
			int instr;				// the original 16bit opcode at breakpoint
			
			Breakpoint(int offset, int bank) {
				// the encoded key for the SortedSet...
				addressKey = bank << 16 | offset;
			
				// the original 2 byte opcode bit pattern in Z88 memory.
				setInstruction(z88.getByte(offset+1, bank) << 8 | z88.getByte(offset, bank));
			}
			
			private int setAddress() {
				return addressKey;
			}

			private int getAddress() {
				return addressKey;
			}
						
			private void setInstruction(int z80instr) {
				instr = z80instr;				
			}
			
			private int getInstruction() {
				return instr; 
			}
			
			// override interface with the actual implementation for this object. 
			public int hashCode() {
				return addressKey;	// the unique key is a perfect hash code
			}
			
			// override interface with the actual implementation for this object. 
			public boolean equals(Object bp) {
				if (!(bp instanceof Breakpoint)) {
					return false;
				}

				Breakpoint aBreakpoint = (Breakpoint) bp; 
				if (addressKey == aBreakpoint.addressKey)
					return true;
				else 
					return false; 
			}
		}
	}
	
	/** 
	 * Z80 instruction speed monitor. 
	 * Polls each second for the execution speed and displays it to std out.
	 */
	private class MonitorZ80 {

		Timer timer = null;
		TimerTask monitor = null;
		private long oldTimeMs = 0;

		private class SpeedPoll extends TimerTask {
			/**
			 * Request poll each second, or try to hit the 1 sec time frame...
			 * 
			 * @see java.lang.Runnable#run()
			 */
			public void run() {
				float realMs = System.currentTimeMillis() - oldTimeMs;
				int ips = (int) (z88.getInstructionCounter() * realMs/1000);
				int tps = z88.getTstatesCounter();

				// System.out.println( "IPS=" + ips + ",TPS=" + tps);

				oldTimeMs = System.currentTimeMillis();
			}			
		}
		
		private MonitorZ80() {
			timer = new Timer(true);
		}

		/**
		 * Stop the Z80 Speed Monitor.
		 */
		public void stop() {
			if (timer != null)
				monitor.cancel();
		}

		/**
		 * Speed polling monitor asks each second for Z80 speed status.
		 */
		public void start() {
			monitor = new SpeedPoll();
			oldTimeMs = 0;
			timer.scheduleAtFixedRate(monitor, 0, 1000);
		}
	} 
}
