package net.sourceforge.z88;

import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.RandomAccessFile;
import gameframe.GameFrame;
import gameframe.GameFrameException;

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

			z88.insertRamCard(32 * 1024, 0);	// 32K RAM in slot (standard machine)	
			z88.insertRamCard(128 * 1024, 1);	// Insert 128K RAM in slot 1			
			z88.hardReset();

			z80Speed = new MonitorZ80(z88);
			dz = new Dz(z88); // the disassembly engine, linked to the memory model
			breakp = new Breakpoints(z88);
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
		if ((z88.getBlinkCom() & Blink.BM_COMRAMS) == Blink.BM_COMRAMS) {
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
	
    /**
     * Display bit status of Blink COM register.
     */
	private void displayBlinkCom() {	
        int blComReg = z88.getBlinkCom();
		StringBuffer blinkComFlags = new StringBuffer(128);
        
        if ( ((blComReg & Blink.BM_COMSRUN) == 0) & ((blComReg & Blink.BM_COMSBIT) == 0) )
            blinkComFlags.append("Speaker=Low");
        if ( ((blComReg & Blink.BM_COMSRUN) == 0) & ((blComReg & Blink.BM_COMSBIT) == Blink.BM_COMSBIT) )
            blinkComFlags.append("Speaker=High");
        if ( ((blComReg & Blink.BM_COMSRUN) == Blink.BM_COMSRUN) & ((blComReg & Blink.BM_COMSBIT) == 0) )
            blinkComFlags.append("Speaker=3200Khz");
        if ( ((blComReg & Blink.BM_COMSRUN) == Blink.BM_COMSRUN) & ((blComReg & Blink.BM_COMSBIT) == Blink.BM_COMSBIT) )
            blinkComFlags.append("Speaker=TxD");

        if ( ((blComReg & Blink.BM_COMOVERP) == Blink.BM_COMOVERP) )
            blinkComFlags.append(",OVERP");
        if ( ((blComReg & Blink.BM_COMRESTIM) == Blink.BM_COMRESTIM) )
            blinkComFlags.append(",RESTIM");
        if ( ((blComReg & Blink.BM_COMPROGRAM) == Blink.BM_COMPROGRAM) )
            blinkComFlags.append(",PROGRAM");
        if ( ((blComReg & Blink.BM_COMRAMS) == Blink.BM_COMRAMS) )
            blinkComFlags.append(",RAMS");
        else
            blinkComFlags.append(",BANK0");
        if ( ((blComReg & Blink.BM_COMVPPON) == Blink.BM_COMVPPON) )
            blinkComFlags.append(",VPPON");
        if ( ((blComReg & Blink.BM_COMLCDON) == Blink.BM_COMLCDON) )
            blinkComFlags.append(",LCDON");

        System.out.println("COM (B0h): " + blinkComFlags);
	}

    /**
     * Display bit status of Blink INT register.
     */
    private void displayBlinkInt() {
        int blIntReg = z88.getBlinkInt();
		StringBuffer blinkIntFlags = new StringBuffer(128);
        if ( ((blIntReg & Blink.BM_INTKWAIT) == Blink.BM_INTKWAIT) )
            blinkIntFlags.append("KWAIT");
        if ( ((blIntReg & Blink.BM_INTA19) == Blink.BM_INTA19) )
            blinkIntFlags.append(",A19");
        if ( ((blIntReg & Blink.BM_INTFLAP) == Blink.BM_INTFLAP) )
            blinkIntFlags.append(",FLAP");
        if ( ((blIntReg & Blink.BM_INTUART) == Blink.BM_INTUART) )
            blinkIntFlags.append(",UART");
        if ( ((blIntReg & Blink.BM_INTBTL) == Blink.BM_INTBTL) )
            blinkIntFlags.append(",BTL");
        if ( ((blIntReg & Blink.BM_INTKEY) == Blink.BM_INTKEY) )
            blinkIntFlags.append(",KEY");
        if ( ((blIntReg & Blink.BM_INTTIME) == Blink.BM_INTTIME) )
            blinkIntFlags.append(",TIME");
        if ( ((blIntReg & Blink.BM_INTGINT) == Blink.BM_INTGINT) )
            blinkIntFlags.append(",GINT");

        System.out.println("INT (B1h): " + blinkIntFlags);
    }

    /**
     * Display bit status of Blink STA register.
     */
    private void displayBlinkSta() {
        int blStaReg = z88.getBlinkSta();
		StringBuffer blinkStaFlags = new StringBuffer(128);
        if ( ((blStaReg & Blink.BM_STAFLAPOPEN) == Blink.BM_STAFLAPOPEN) )
            blinkStaFlags.append("FLAPOPEN");
        if ( ((blStaReg & Blink.BM_STAA19) == Blink.BM_STAA19) )
            blinkStaFlags.append(",A19");
        if ( ((blStaReg & Blink.BM_STAFLAP) == Blink.BM_STAFLAP) )
            blinkStaFlags.append(",FLAP");
        if ( ((blStaReg & Blink.BM_STAUART) == Blink.BM_STAUART) )
            blinkStaFlags.append(",UART");
        if ( ((blStaReg & Blink.BM_STABTL) == Blink.BM_STABTL) )
            blinkStaFlags.append(",BTL");
        if ( ((blStaReg & Blink.BM_STAKEY) == Blink.BM_STAKEY) )
            blinkStaFlags.append(",KEY");
        if ( ((blStaReg & Blink.BM_STATIME) == Blink.BM_STATIME) )
            blinkStaFlags.append(",TIME");

        System.out.println("STA (B1h): " + blinkStaFlags);
    }

    /**
     * Display bit status of Blink ACK register.
     */
    private void displayBlinkAck() {
        int blAckReg = z88.getBlinkAck();
		StringBuffer blinkAckFlags = new StringBuffer(128);
        if ( ((blAckReg & Blink.BM_ACKA19) == Blink.BM_ACKA19) )
            blinkAckFlags.append("A19");
        if ( ((blAckReg & Blink.BM_ACKFLAP) == Blink.BM_ACKFLAP) )
            blinkAckFlags.append(",FLAP");
        if ( ((blAckReg & Blink.BM_ACKBTL) == Blink.BM_ACKBTL) )
            blinkAckFlags.append(",BTL");
        if ( ((blAckReg & Blink.BM_ACKKEY) == Blink.BM_ACKKEY) )
            blinkAckFlags.append(",KEY");

        System.out.println("ACK (B6h): " + blinkAckFlags);
    }

    private void displayBlinkTimers() {
        int blTim0Reg = z88.getBlinkTim0();
        int blTim1Reg = z88.getBlinkTim1();
        int blTim2Reg = z88.getBlinkTim2();
        int blTim3Reg = z88.getBlinkTim3();
        int blTim4Reg = z88.getBlinkTim4();
        int timeElapsedMinutes = 65536 * blTim4Reg + 256 * blTim3Reg + blTim2Reg;
        int timeElapsedDays = timeElapsedMinutes / 1440;
        int timeElapsedHours = (timeElapsedMinutes - (timeElapsedDays * 1440)) / 60; 
        timeElapsedMinutes = timeElapsedMinutes - (timeElapsedDays * 1440) - (timeElapsedHours * 60);
        
		StringBuffer blinkTimers = new StringBuffer(128);        
        blinkTimers.append("TIM4=" + blTim4Reg); blinkTimers.append(",TIM3=" + blTim3Reg);
        blinkTimers.append(",TIM2=" + blTim2Reg); blinkTimers.append(",TIM1=" + blTim1Reg);
        blinkTimers.append(",TIM0=" + blTim0Reg);
        blinkTimers.append(", Time elapsed: " + timeElapsedDays + "d:" + timeElapsedHours + "h:");
        blinkTimers.append(timeElapsedMinutes + "m:" + blTim1Reg + "s:" + blTim0Reg * 5 + "ms");
        
        System.out.println(blinkTimers);        
    }

    /**
     * Display contents of Blink Registers to console.
     */
    private void blinkRegisters() {
        displayBlinkCom();
        displayBlinkInt();
        displayBlinkSta();
        displayBlinkAck();           
        displayBlinkTimers();  // TIM0, TIM1, TIM2, TIM3 & TIM4
//        blinkTack();
//        blinkTmk();     
//        blinkTsta();    
//        blinkScreen();  // PB0, PB1, PB2, PB3 & SBR
//        blinkSegment();  // SR0 - SR3
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
		
		System.out.println("\n" + dzRegisters);
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
		System.out.println("All arguments are in Hex: Local address = 64K address space,\nExtended address = 24bit address, eg. 073800 (bank 07h, offset 3800h)\n");
		System.out.println("Commands:");
		System.out.println("exit - end OZvm application");
		System.out.println("run - execute Z88 machine from PC");
		System.out.println(". - Single step instruction at PC");
		System.out.println("d - Disassembly at PC");
		System.out.println("d [local address | extended address] - Disassemble at address");
		System.out.println("wb <extended address> <byte> [<byte>] - Write byte(s) to memory");
		System.out.println("m - View memory at PC");
		System.out.println("m [local address | extended address] - View memory at address");
		System.out.println("bp - List breakpoints");
		System.out.println("bl - Display Blink register contents");        
		System.out.println("bp <extended address> - Toggle breakpoint");
		System.out.println("blsr - Blink: Segment Register Bank Binding");
		System.out.println("r - Display current Z80 Registers");
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
				
				breakp.setBreakpoints();   // restore (patch) breakpoints into code
				z80Speed.start();		    // enable execution speed monitor
				z88.startInterrupts();	    // enable Z80/Z88 core interrupts 
				z88.run(false);				// execute Z80 code at full speed until breakpoint is encountered...
				z88.stopInterrupts();
				z80Speed.stop();
				breakp.clearBreakpoints();
				
				// when we're getting back, a breakpoint was encountered...
				breakpointProgramCounter = z88.PC();	// remember breakpoint address
				 
				z80Status();	// display Z80 register status
                cmdline = "";
				cmdLineTokens = cmdline.split(" "); // wait for a new command...
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

  			if (cmdLineTokens[0].equalsIgnoreCase("bl") == true) {
				blinkRegisters();
				cmdline = ""; // wait for a new command...
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

			if (cmdLineTokens[0].equalsIgnoreCase("wb") == true) {
				putByte(cmdLineTokens);
				cmdLineTokens[0] = ""; // wait for a new command...				
			}
			
			if (cmdLineTokens[0].length() > 0 &&
				cmdLineTokens[0].equalsIgnoreCase(".") == false &&
				cmdLineTokens[0].equalsIgnoreCase("d") == false &&
				cmdLineTokens[0].equalsIgnoreCase("r") == false &&
				cmdLineTokens[0].equalsIgnoreCase("h") == false &&
				cmdLineTokens[0].equalsIgnoreCase("m") == false &&
				cmdLineTokens[0].equalsIgnoreCase("wb") == false &&
				cmdLineTokens[0].equalsIgnoreCase("help") == false &&
				cmdLineTokens[0].equalsIgnoreCase("run") == false &&
			    cmdLineTokens[0].equalsIgnoreCase("bp") == false &&
				cmdLineTokens[0].equalsIgnoreCase("blsr") == false &&
                cmdLineTokens[0].equalsIgnoreCase("bl") == false &&
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
		if (cmdLineTokens.length == 2) {
			int bpAddress = Integer.parseInt(cmdLineTokens[1], 16);
			int bpBank = (bpAddress >>> 16) & 0xFF;
			bpAddress &= 0xFFFF; 
			
			breakp.toggleBreakpoint(bpAddress, bpBank);
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
			
		if (cmdLineTokens.length == 2) {
			// one argument; the local Z80 64K address or a compact 24bit extended address
			dzAddr = Integer.parseInt(cmdLineTokens[1], 16);
			if (dzAddr > 65535) {
				dzBank = (dzAddr >>> 16) & 0xFF;
				dzAddr &= 0xFFFF;	// preserve local address look, makes it easier to read DZ code.. 
			} else {
				if (cmdLineTokens[1].length() == 6) {
					// bank defined as '00'
					dzBank = 0;					
				} else {
                    // get extended address from current bank binding
                    dzAddr = z88.decodeLocalAddress(dzAddr) | (dzAddr & 0xF000);
                    dzBank = (dzAddr >>> 16) & 0xFF;
                    dzAddr &= 0xFFFF;	// preserve local address look, makes it easier to read DZ code.. 
				}
			}
		} else {
			if (cmdLineTokens.length == 1) {
				// no arguments, use PC in current bank binding
                dzAddr = z88.decodeLocalAddress(z88.PC()) | (z88.PC() & 0xF000);
                dzBank = (dzAddr >>> 16) & 0xFF;
                dzAddr &= 0xFFFF;	// preserve local address look, makes it easier to read DZ code.. 
			} else {
				System.out.println("Illegal argument.");
				System.out.print("$");
				dzCmdline = in.readLine();
				return dzCmdline;
			}			
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


	private void putByte(String[] cmdLineTokens) throws IOException {
		String cmdline = null;
		int argByte[], memAddress, memBank, temp, aByte; 

		if (cmdLineTokens.length >= 3 & cmdLineTokens.length <= 18) {
			memAddress = Integer.parseInt(cmdLineTokens[1], 16);
			memBank = (memAddress >>> 16) & 0xFF;
			memAddress &= 0xFFFF;
			argByte = new int[cmdLineTokens.length - 2];
			for (aByte= 0; aByte < cmdLineTokens.length - 2; aByte++) {
				argByte[aByte] = Integer.parseInt(cmdLineTokens[2 + aByte], 16);
			}						 
		} else {
			System.out.println("Illegal argument(s).");
			return;
		}
		
		StringBuffer memLine = new StringBuffer(256);
		temp = getMemoryAscii(memLine, memAddress, memBank);
		System.out.println("Before:\n" + memLine);
		for (aByte= 0; aByte < cmdLineTokens.length - 2; aByte++) {
			z88.setByte(memAddress + aByte, memBank, argByte[aByte]);
		}		
		
		temp = getMemoryAscii(memLine, memAddress, memBank);
		System.out.println("After:\n" + memLine);
	}

	
	private String viewMemory(BufferedReader in, String[] cmdLineTokens) throws IOException {
		int memAddr = 0, memBank = 0;		
		StringBuffer memLine = new StringBuffer(256);
		String memCmdline = null;
	
		if (cmdLineTokens.length == 2) {
			// one argument; the local Z80 64K address or 24bit compact ext. address
			memAddr = Integer.parseInt(cmdLineTokens[1], 16);
						
			if (memAddr > 65535) {
				memBank = (memAddr >>> 16) & 0xFF;
				memAddr &= 0x3FFF; 
			} else {
				if (cmdLineTokens[1].length() == 6) {
					// bank defined as '00'
					memBank = 0;					
				} else {
                    memAddr = z88.decodeLocalAddress(memAddr) | (memAddr & 0xF000);
                    memBank = (memAddr >>> 16) & 0xFF;
                    memAddr &= 0xFFFF;	// preserve local address look, makes it easier to identify..
				}
			}
		} else {
			if (cmdLineTokens.length == 1) {
				// no arguments, use PC in current bank binding
                memAddr = z88.decodeLocalAddress(z88.PC()) | (z88.PC() & 0xF000);
                memBank = (memAddr >>> 16) & 0xFF;
                memAddr &= 0xFFFF;	// preserve local address look, makes it easier identify..
			} else {
				System.out.println("Illegal argument.");
				System.out.print("$");
				memCmdline = in.readLine();
				return memCmdline;
			}			
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
	
	public static void main(String[] args) throws IOException, GameFrameException {		
		System.out.println("OZvm V0.1, Z88 Virtual Machine");

		OZvm ozvm = new OZvm();
		if (ozvm.loadRom(args) == false) {
			System.out.println("Ozvm terminated.");
			System.exit(0);
		}
				
		ozvm.commandLine();
		
		System.out.println("Ozvm terminated.");
		GameFrame.exit(0);
	}
}
