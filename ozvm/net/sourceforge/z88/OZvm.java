package net.sourceforge.z88;

import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.RandomAccessFile;
import javax.swing.JPanel;
import javax.swing.JTextArea;
import javax.swing.JTextField;
/**
 * Main entry of the Z88 virtual machine.
 *
 * @author <A HREF="mailto:gstrube@tiscali.dk">Gunther Strube</A>
 * $Id$
 *
 */
public class OZvm {

	public static final String VERSION = "0.2.1";
	private static final String CMDLINEPROMPT = "OZvm$";

	private Blink z88 = null;
    private DisplayStatus blinkStatus;
	private MonitorZ80 z80Speed = null;

	/**
	 * The Z88 disassembly engine
	 */
	private Dz dz;

	private Thread z80Thread = null;
	private boolean debugMode = false;		// boot ROM and external cards immediately, unless "debug" is specified at cmdline

	private JTextArea runtimeOutput = null;

	/**
	 * The Breakpoint manager instance.
	 */
	private Breakpoints breakp;

	/**
	 * @param panel
	 * @param field
	 * @param area
	 * @param area2
	 */
	public OZvm(JPanel canvas, JTextField cmdInput, JTextArea cmdOutput, JTextArea rtmOutput) {

		try {
			runtimeOutput = rtmOutput;

			z88 = new Blink(canvas, rtmOutput);
			z88.hardReset();

			z80Speed = new MonitorZ80(z88);
			dz = new Dz(z88); // the disassembly engine, linked to the memory model
			breakp = new Breakpoints(z88);
            blinkStatus = new DisplayStatus(z88);
			z88.setBreakPointManager(breakp);
		} catch (Exception e) {
			e.printStackTrace();
			rtmOutput.append("\n\nCouldn't initialize Z88 virtual machine.\n");
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
	 * Dump current Z80 Registers and instruction disassembly to stdout.
	 */
	private void z80Status() {
		StringBuffer dzBuffer = new StringBuffer(64);
		int bank = ((z88.decodeLocalAddress(z88.PC()) | (z88.PC() & 0xF000)) >>> 16) & 0xFF;

		blinkStatus.displayZ80Registers();

		dz.getInstrAscii(dzBuffer, z88.PC(), true);
		System.out.println(Dz.byteToHex(bank, false) + dzBuffer);
	}

	public boolean boot(String[] args) {
		RandomAccessFile card, rom;
		boolean loadedRom = false;
		boolean ramSlot0 = false;
		int ramSizeArg = 0;

		try {
			if (args.length >= 1) {
				int arg = 0;
				while (arg<args.length) {
					if ( args[arg].compareTo("ram0") != 0 & args[arg].compareTo("ram1") != 0 &
						 args[arg].compareTo("ram2") != 0 & args[arg].compareTo("ram3") != 0 &
						 args[arg].compareTo("s1") != 0 & args[arg].compareTo("s2") != 0 & args[arg].compareTo("s3") != 0 &
						 args[arg].compareTo("kbl") != 0 & args[arg].compareTo("debug") != 0) {
						runtimeOutput.append("Loading '" + args[arg] + "' into ROM space in slot 0.\n");
						rom = new RandomAccessFile(args[0], "r");
						z88.loadRomBinary(rom);
						rom.close();
						loadedRom = true;
						arg++;
					}

					if (arg<args.length && (args[arg].startsWith("ram") == true)) {
						int ramSlotNumber = args[arg].charAt(3) - 48;
						ramSizeArg = Integer.parseInt(args[arg+1], 10);
						z88.insertRamCard(ramSizeArg * 1024, ramSlotNumber);	// RAM specified for slot x...
						runtimeOutput.append("RAM" + ramSlotNumber + " set to " + ramSizeArg + "K.\n");
						arg+=2;
						continue;
					}

					if (arg<args.length && (args[arg].compareTo("s1") == 0)) {
						card = new RandomAccessFile(args[arg+1], "r");
						runtimeOutput.append("Loading '" + args[arg+1] + "' into slot 1.\n");
						z88.loadCardBinary(1, card);
						card.close();
						arg+=2;
						continue;
					}

					if (arg<args.length && (args[arg].compareTo("s2") == 0)) {
						card = new RandomAccessFile(args[arg+1], "r");
						runtimeOutput.append("Loading '" + args[arg+1] + "' into slot 2.\n");
						z88.loadCardBinary(2, card);
						card.close();
						arg+=2;
						continue;
					}

					if (arg<args.length && (args[arg].compareTo("s3") == 0)) {
						runtimeOutput.append("Loading '" + args[arg+1] + "' into slot 3.\n");
						card = new RandomAccessFile(args[arg+1], "r");
						z88.loadCardBinary(3, card);
						card.close();
						arg+=2;
						continue;
					}

					if (arg<args.length && (args[arg].compareTo("debug") == 0)) {
						setDebugMode(true);
						arg++;
						continue;
					}

					if (arg<args.length && (args[arg].compareTo("kbl") == 0)) {
						if (args[arg+1].compareToIgnoreCase("uk") == 0 || args[arg+1].compareToIgnoreCase("en") == 0) {
							z88.getZ88Keyboard().setKeyboardLayout(Z88Keyboard.COUNTRY_EN);
							runtimeOutput.append("Using English (UK) keyboard layout.\n");
						}
						if (args[arg+1].compareTo("fr") == 0) {
							z88.getZ88Keyboard().setKeyboardLayout(Z88Keyboard.COUNTRY_FR);
							runtimeOutput.append("Using French keyboard layout.\n");
						}
						if (args[arg+1].compareTo("dk") == 0) {
							z88.getZ88Keyboard().setKeyboardLayout(Z88Keyboard.COUNTRY_DK);
							runtimeOutput.append("Using Danish keyboard layout.\n");
						}
						if (args[arg+1].compareTo("se") == 0) {
							z88.getZ88Keyboard().setKeyboardLayout(Z88Keyboard.COUNTRY_SE);
							runtimeOutput.append("Using Swedish keyboard layout.\n");
						}
						if (args[arg+1].compareTo("fi") == 0) {
							z88.getZ88Keyboard().setKeyboardLayout(Z88Keyboard.COUNTRY_FI);
							runtimeOutput.append("Using Finish keyboard layout.\n");
						}
						arg+=2;
						continue;
					}
				}
			}

			if (loadedRom == false) {
				runtimeOutput.append("No external ROM image specified, using default Z88.rom (V4.0 UK)\n");
				z88.loadRomBinary(z88.getClass().getResource("/Z88.rom"));
			}

			if (ramSlot0 == false) {
				runtimeOutput.append("RAM0 set to default 32K.\n");
				z88.insertRamCard(32 * 1024, 0);	// no RAM specified for slot 0, set to default 32K RAM...
			}
			return true;

		} catch (FileNotFoundException e) {
			System.out.println("Couldn't load ROM/EPROM image:\n" + e.getMessage() + "\nOzvm terminated.");
			return false;
		} catch (IOException e) {
			System.out.println("Problem with ROM/EPROM image or I/O:\n" + e.getMessage() + "\nOzvm terminated.");
			return false;
		}
	}

	private void cmdHelp() {
		System.out.println("All arguments are in Hex: Local address = 64K address space,\nExtended address = 24bit address, eg. 073800 (bank 07h, offset 3800h)\n");
		System.out.println("Commands:");
		System.out.println("exit - end OZvm application");
		System.out.println("run - execute Z88 machine from PC");
		System.out.println("z - run z88 machine and break at next instruction");
		System.out.println(". - Single step instruction at PC");
		System.out.println("d - Disassembly at PC");
		System.out.println("d [local address | extended address] - Disassemble at address");
		System.out.println("wb <extended address> <byte> [<byte>] - Write byte(s) to memory");
		System.out.println("m - View memory at PC");
		System.out.println("m [local address | extended address] - View memory at address");
		System.out.println("bp - List breakpoints");
		System.out.println("bl - Display Blink register contents");
		System.out.println("bp <extended address> - Toggle stop breakpoint");
		System.out.println("bpd <extended address> - Toggle display breakpoint");
		System.out.println("sr - Blink: Segment Register Bank Binding");
		System.out.println("r - Display current Z80 Registers");
	}

	public void commandLine() throws IOException {
		int breakpointProgramCounter = -1;

		String cmdline = "";
		String[] cmdLineTokens = cmdLineTokens = cmdline.split(" ");

		BufferedReader in =
			new BufferedReader(new InputStreamReader(System.in));
		System.out.println("Type 'h' or 'help' for command line options\n");
		z80Status();

		StringBuffer prevCmdline = new StringBuffer();
		do {
			if (z80Thread != null && z80Thread.isAlive() == false) {
				z80Thread = null;	// garbage collect dead thread...
			}

			if (cmdLineTokens[0].equalsIgnoreCase("h") == true || cmdLineTokens[0].equalsIgnoreCase("help") == true) {
				cmdHelp();
				cmdline = ""; // wait for a new command...
				cmdLineTokens = cmdline.split(" ");
			}

			if (cmdLineTokens[0].equalsIgnoreCase("run") == true) {
				if (z80Thread == null) {
					 z80Thread = run();
				} else {
					if (z80Thread.isAlive() == true)
						System.out.println("Z88 is already running.");
					else
						z80Thread = run();
				}

                cmdline = "";
				cmdLineTokens = cmdline.split(" "); // wait for a new command...
			}

			if (cmdLineTokens[0].equalsIgnoreCase("stop") == true) {
				z88.stopZ80Execution();

				cmdline = "";
				cmdLineTokens = cmdline.split(" "); // wait for a new command...
			}

			if (cmdLineTokens[0].equalsIgnoreCase(".") == true) {
				z88.run(true);		// single stepping (no interrupts running)...
				System.out.println(blinkStatus.dzPcStatus());

				cmdLineTokens[0] = ""; // wait for a new command...
			}

			if (cmdLineTokens[0].equalsIgnoreCase("z") == true) {
				if (z80Thread != null) {
					if (z80Thread.isAlive() == true)
						System.out.println("Z88 is already running.");

						cmdLineTokens[0] = ""; // wait for a new command...
						continue;
				}

				Breakpoints origBreakPoints = this.getBreakpointManager();	// get the current breakpoints
				Breakpoints singleBreakpoint = new Breakpoints(z88);
				int nextInstrAddress = dz.getNextInstrAddress(z88.PC());
				nextInstrAddress = z88.decodeLocalAddress(nextInstrAddress);	// convert 16bit address to 24bit address
				singleBreakpoint.toggleBreakpoint(nextInstrAddress);  // set breakpoint at next instruction

				this.setBreakPointManager(singleBreakpoint);	// use this single breakpoint
				z88.setBreakPointManager(singleBreakpoint);
				z80Thread = run();	// let Z80 engine run until breakpoint is reached...
				while(z80Thread.isAlive() == true) {
					try {
						Thread.sleep(1);	// wait for Z88 to reach breakpoint...
					} catch (InterruptedException e) {}
				}
				z88.setBreakPointManager(origBreakPoints);	// restore user defined break points
				this.setBreakPointManager(origBreakPoints);

				System.out.println(blinkStatus.dzPcStatus());
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
				blinkStatus.displayBlinkRegisters();
				cmdline = ""; // wait for a new command...
				cmdLineTokens = cmdline.split(" ");
			}

			if (cmdLineTokens[0].equalsIgnoreCase("sr") == true) {
				blinkStatus.displayBankBindings();
				cmdline = ""; // wait for a new command...
				cmdLineTokens = cmdline.split(" ");
			}

			if (cmdLineTokens[0].equalsIgnoreCase("r") == true) {
				blinkStatus.displayZ80Registers();
				cmdline = ""; // wait for a new command...
				cmdLineTokens = cmdline.split(" ");
			}

			if (cmdLineTokens[0].equalsIgnoreCase("bp") == true) {
				bpCommandline(cmdLineTokens);
				cmdLineTokens[0] = ""; // wait for a new command...
			}

			if (cmdLineTokens[0].equalsIgnoreCase("bpd") == true) {
				bpdCommandline(cmdLineTokens);
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
				cmdLineTokens[0].equalsIgnoreCase("z") == false &&
				cmdLineTokens[0].equalsIgnoreCase("stop") == false &&
			    cmdLineTokens[0].equalsIgnoreCase("bp") == false &&
				cmdLineTokens[0].equalsIgnoreCase("bpd") == false &&
				cmdLineTokens[0].equalsIgnoreCase("sr") == false &&
                cmdLineTokens[0].equalsIgnoreCase("bl") == false &&
				cmdLineTokens[0].equalsIgnoreCase("exit") == false
			   ) {
			   	// unknown commands get cleared so that we can
			   	// read a new command...
			   	System.out.println("Unknown command.");
				cmdLineTokens[0] = "";
			}

			if (cmdLineTokens[0].length() == 0) {
				System.out.print(CMDLINEPROMPT);	// the command line prompt...
				cmdline = in.readLine();
				if (cmdline == null)
					cmdLineTokens[0] = "exit";	// program aborted during input...
				else
					cmdLineTokens = cmdline.split(" ");
			}
		} while (cmdLineTokens[0].equalsIgnoreCase("exit") == false);

		if (z80Thread != null && z80Thread.isAlive() == true) z88.stopZ80Execution();
	}


	private void bpCommandline(String[] cmdLineTokens) throws IOException {
		if (cmdLineTokens.length == 2) {
			if (z80Thread != null && z80Thread.isAlive() == true) {
				System.out.println("Breakpoints cannot be edited while Z88 is running.");
				return;
			} else {
				int bpAddress = Integer.parseInt(cmdLineTokens[1], 16);
				breakp.toggleBreakpoint(bpAddress);
				breakp.listBreakpoints();
			}
		}

		if (cmdLineTokens.length == 1) {
			// no arguments, use PC in current bank binding
			breakp.listBreakpoints();
		}
	}

	private void bpdCommandline(String[] cmdLineTokens) throws IOException {
		if (cmdLineTokens.length == 2) {
			if (z80Thread != null && z80Thread.isAlive() == true) {
				System.out.println("Display Breakpoints cannot be edited while Z88 is running.");
				return;
			} else {
				int bpAddress = Integer.parseInt(cmdLineTokens[1], 16);
				breakp.toggleBreakpoint(bpAddress, false);
				breakp.listBreakpoints();
			}
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
				System.out.print(CMDLINEPROMPT);
				dzCmdline = in.readLine();
				return dzCmdline;
			}
		}

		do {
			for (int dzLines = 0;  dzLines < 16; dzLines++) {
				dzAddr = dz.getInstrAscii(dzLine, dzAddr, dzBank, true);
				dzAddr &= 0xFFFF;
				System.out.println(Dz.byteToHex(dzBank,false) + dzLine);
			}

			System.out.print(CMDLINEPROMPT);
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
				System.out.print(CMDLINEPROMPT);
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

			System.out.print(CMDLINEPROMPT);
			memCmdline = in.readLine();
			if (memCmdline == null) memCmdline = "exit";	// program aborted during input...

		}
		while (memCmdline.length() == 0);

		return memCmdline;
	}

	public void bootZ88Rom() {
		z80Thread = run();
	}

	private Thread run() {
		runtimeOutput.append("Z88 virtual machine was started.\n");

		Thread thread = new Thread() {
			public void run() {
				int breakpointProgramCounter = -1;

				if (z88.PC() == breakpointProgramCounter) {
					// we need to use single stepping mode to
					// step past the break point at current instruction
					z88.run(true);
				}
				// restore (patch) breakpoints into code
				breakp.setBreakpoints();
				z80Speed.start(); // enable execution speed monitor
				z88.startInterrupts(); // enable Z80/Z88 core interrupts
				z88.run(false);
				// execute Z80 code at full speed until breakpoint is encountered...
				z88.stopInterrupts();
				z80Speed.stop();
				breakp.clearBreakpoints();

				// a breakpoint was encountered, or an external source asked for stop...
				breakpointProgramCounter = z88.PC();
				// remember breakpoint address
			}
		};

		thread.setPriority(Thread.MIN_PRIORITY);
		thread.start();

		return thread;
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
		z88.setDebugMode(b);
		debugMode = b;
	}

	/**
	 * @return
	 */
	private Breakpoints getBreakpointManager() {
		return breakp;
	}

	/**
	 * @param breakpoints
	 */
	private void setBreakPointManager(Breakpoints breakpoints) {
		breakp = breakpoints;
	}
}
