/*
 * OZvm.java
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

import java.awt.event.KeyEvent;
import java.awt.event.KeyListener;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.RandomAccessFile;

import javax.swing.JTextArea;
import javax.swing.JTextField;

/**
 * Main entry of the Z88 virtual machine.
 *
 */
public class OZvm implements KeyListener {

	public static final String VERSION = "0.3.6";
	public static boolean debugMode = false;		// boot ROM and external cards immediately, unless "debug" is specified at cmdline

	private Blink z88 = null;
    private DisplayStatus blinkStatus;

	/**
	 * The Z88 disassembly engine
	 */
	private Dz dz;

	private Thread z80Thread = null;

	private JTextArea runtimeOutput = null;
	private JTextArea commandOutput = null;
	private JTextField commandInput = null;
	private Z88display z88Screen = null;
	private CommandHistory cmdList = null;
	private static Gui gui = null;
	/**
	 * The Breakpoint manager instance.
	 */
	private Breakpoints breakp;

	public OZvm(Gui gg) {
		
		try {
			gui = gg;
			
			z88Screen = gui.z88Screen();
			
			z88 = new Blink(z88Screen);
			z88Screen.init();
			z88Screen.setBlink(z88);
			z88Screen.start();
			z88.hardReset();

			dz = new Dz(z88); // the disassembly engine, linked to the memory model
			breakp = new Breakpoints(z88);
			z88.setBreakPointManager(breakp);

		} catch (Exception e) {
			e.printStackTrace();
			displayRtmMessage("\n\nCouldn't initialize Z88 virtual machine.");
		}
	}

	public static void displayRtmMessage(final String msg) {
		if (OZvm.debugMode == true) {
			Thread displayMsgThread = new Thread() {
				public void run() {					
					gui.getRtmOutputArea().append(msg + "\n");
					gui.getRtmOutputArea().setCaretPosition(gui.getRtmOutputArea().getDocument().getLength());
				}
			};

			displayMsgThread.setPriority(Thread.MIN_PRIORITY);
			displayMsgThread.start();
		} else {
			System.out.println(msg);
		}
	}
	
	public void startInterrupts() {
		z88.startInterrupts();
	}

	public void stopInterrupts() {
		z88.stopInterrupts();
	}

	/**
	 * Dump current Z80 Registers and instruction disassembly to command output window.
	 */
	private void z80Status() {
		StringBuffer dzBuffer = new StringBuffer(64);
		int bank = ((z88.decodeLocalAddress(z88.PC()) | (z88.PC() & 0xF000)) >>> 16) & 0xFF;

		blinkStatus.displayZ80Registers();

		dz.getInstrAscii(dzBuffer, z88.PC(), true, true);
		displayCmdOutput( Dz.byteToHex(bank, false) + dzBuffer);
	}

	public boolean boot(String[] args) {
		RandomAccessFile file;
		boolean loadedRom = false;
		boolean ramSlot0 = false;
		int ramSizeArg = 0, eprSizeArg = 0;

		try {
			if (args.length >= 1) {
				int arg = 0;
				while (arg<args.length) {
					if ( args[arg].compareTo("ram0") != 0 & args[arg].compareTo("ram1") != 0 &
						 args[arg].compareTo("ram2") != 0 & args[arg].compareTo("ram3") != 0 &
						 args[arg].compareTo("epr1") != 0 & args[arg].compareTo("epr2") != 0 & args[arg].compareTo("epr3") != 0 &						 
						 args[arg].compareTo("s1") != 0 & args[arg].compareTo("s2") != 0 & args[arg].compareTo("s3") != 0 &
						 args[arg].compareTo("kbl") != 0 & args[arg].compareTo("debug") != 0 &
						 args[arg].compareTo("initdebug") != 0) {
						displayRtmMessage("Loading '" + args[0] + "' into ROM space in slot 0.");
						file = new RandomAccessFile(args[0], "r");
						z88.loadRomBinary(file);
						file.close();
						loadedRom = true;
						arg++;
					}

					if (arg<args.length && (args[arg].startsWith("ram") == true)) {
						int ramSlotNumber = args[arg].charAt(3) - 48;
						ramSizeArg = Integer.parseInt(args[arg+1], 10);
						z88.insertRamCard(ramSizeArg * 1024, ramSlotNumber);	// RAM Card specified for slot x...
						if (ramSlotNumber == 0) ramSlot0 = true; 
						displayRtmMessage("Inserted " + ramSizeArg + "K RAM Card in slot " + ramSlotNumber);
						arg+=2;
						continue;
					}

					if (arg<args.length && (args[arg].startsWith("epr") == true)) {
						int eprSlotNumber = args[arg].charAt(3) - 48;
						eprSizeArg = Integer.parseInt(args[arg+1], 10);
						if (z88.insertEprCard(eprSizeArg * 1024, eprSlotNumber, args[arg+2]) == true) {
							String insertEprMsg = "Inserted " + eprSlotNumber + " set to " + eprSizeArg + "K.";
							if (args[arg+2].compareToIgnoreCase("27C") == 0) insertEprMsg = "Inserted " + eprSizeArg + "K UV Eprom Card in slot " + eprSlotNumber; 
							if (args[arg+2].compareToIgnoreCase("28F") == 0) insertEprMsg = "Inserted " + eprSizeArg + "K Intel Flash Card in slot " + eprSlotNumber;
							if (args[arg+2].compareToIgnoreCase("29F") == 0) insertEprMsg = "Inserted " + eprSizeArg + "K Amd Flash Card in slot " + eprSlotNumber;
							displayRtmMessage(insertEprMsg);
						} else
							displayRtmMessage("Eprom Card size/type configuration is illegal.");
						arg+=3;
						continue;
					}
					
					if (arg<args.length && (args[arg].compareTo("s1") == 0)) {
						file = new RandomAccessFile(args[arg+1], "r");
						displayRtmMessage("Loading '" + args[arg+1] + "' into slot 1.");
						z88.loadCardBinary(1, file);
						file.close();
						arg+=2;
						continue;
					}

					if (arg<args.length && (args[arg].compareTo("s2") == 0)) {
						file = new RandomAccessFile(args[arg+1], "r");
						displayRtmMessage("Loading '" + args[arg+1] + "' into slot 2.");
						z88.loadCardBinary(2, file);
						file.close();
						arg+=2;
						continue;
					}

					if (arg<args.length && (args[arg].compareTo("s3") == 0)) {
						displayRtmMessage("Loading '" + args[arg+1] + "' into slot 3.");
						file = new RandomAccessFile(args[arg+1], "r");
						z88.loadCardBinary(3, file);
						file.close();
						arg+=2;
						continue;
					}

					if (arg<args.length && (args[arg].compareTo("debug") == 0)) {
						setDebugMode(true);
						arg++;

						commandInput = gui.getCmdLineInputArea();
						commandInput.addActionListener(new java.awt.event.ActionListener() { 
							public void actionPerformed(java.awt.event.ActionEvent e) {    
								String cmdline = commandInput.getText();
								cmdList.addCommand(cmdline);
								commandInput.setText("");			
								parseCommandLine(cmdline);					
							}
						});
						commandInput.addKeyListener(this);
						z88.getZ88Keyboard().setDebugModeCmdLineField(commandInput);					

						cmdList = new CommandHistory();

						commandOutput = gui.getCmdlineOutputArea();
			            blinkStatus = new DisplayStatus(z88, commandOutput);			
						displayCmdOutput("Type 'help' for available debugging commands");
						
						continue;
					}

					if (arg<args.length && (args[arg].compareTo("initdebug") == 0)) {
						setDebugMode(true);
						file = new RandomAccessFile(args[arg+1], "r");
						JTextArea tmpOutput = commandOutput;
						gui.getCmdLineInputArea().setEnabled(false);	// don't allow command input while parsing file...
						commandOutput = null;	// don't write command output while parsing commands from file...
						String cmd = null;
						while ( (cmd = file.readLine()) != null) parseCommandLine(cmd);
						commandOutput = tmpOutput;
						gui.getCmdLineInputArea().setEnabled(true); // ready for commands from the keyboard...
						file.close();						
						displayRtmMessage("Parsed '" + args[arg+1] + "' command file.");
						arg+=2;						
						continue;
					}

					if (arg<args.length && (args[arg].compareTo("kbl") == 0)) {
						if (args[arg+1].compareToIgnoreCase("uk") == 0 || args[arg+1].compareToIgnoreCase("en") == 0) {
							z88.getZ88Keyboard().setKeyboardLayout(Z88Keyboard.COUNTRY_EN);
							displayRtmMessage("Using English (UK) keyboard layout.");
						}
						if (args[arg+1].compareTo("fr") == 0) {
							z88.getZ88Keyboard().setKeyboardLayout(Z88Keyboard.COUNTRY_FR);
							displayRtmMessage("Using French keyboard layout.");
						}
						if (args[arg+1].compareTo("dk") == 0) {
							z88.getZ88Keyboard().setKeyboardLayout(Z88Keyboard.COUNTRY_DK);
							displayRtmMessage("Using Danish keyboard layout.");
						}
						if (args[arg+1].compareTo("se") == 0) {
							z88.getZ88Keyboard().setKeyboardLayout(Z88Keyboard.COUNTRY_SE);
							displayRtmMessage("Using Swedish keyboard layout.");
						}
						if (args[arg+1].compareTo("fi") == 0) {
							z88.getZ88Keyboard().setKeyboardLayout(Z88Keyboard.COUNTRY_FI);
							displayRtmMessage("Using Finish keyboard layout.");
						}
						arg+=2;
						continue;
					}
				}
			}

			if (loadedRom == false) {
				displayRtmMessage("No external ROM image specified, using default Z88.rom (V4.0 UK)");
				z88.loadRomBinary(z88.getClass().getResource("/Z88.rom"));
			}

			if (ramSlot0 == false) {
				displayRtmMessage("RAM0 set to default 32K.");
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

	private void displayCmdOutput(String msg) {
		if (commandOutput != null) {
			commandOutput.append(msg + "\n");
			commandOutput.setCaretPosition(commandOutput.getDocument().getLength());
		}
	}

	private void cmdHelp() {
		displayCmdOutput("\nUse F12 to toggle keyboard focus between debug command line and Z88 window."); 
		displayCmdOutput("All arguments are in Hex: Local address = 64K address space,\nExtended address = 24bit address, eg. 073800 (bank 07h, offset 3800h)");
		displayCmdOutput("Commands:");
		displayCmdOutput("exit - end OZvm application");
		displayCmdOutput("run - execute virtual Z88 from PC");
		displayCmdOutput("stop - stop virtual Z88 (or press F5 when Z88 window has focus)");
		displayCmdOutput("ldc filename <extended address> - Load file binary at address");
		displayCmdOutput("z - run z88 machine (eg. CALL subroutine) and break at next instruction");
		displayCmdOutput(". - Single step instruction at PC");
		displayCmdOutput("dz - Disassembly at PC");
		displayCmdOutput("dz [local address | extended address] - Disassemble at address");
		displayCmdOutput("wb <extended address> <byte> [<byte>] - Write byte(s) to memory");
		displayCmdOutput("m - View memory at PC");
		displayCmdOutput("m [local address | extended address] - View memory at address");
		displayCmdOutput("bp - List breakpoints");
		displayCmdOutput("bl - Display Blink register contents");
		displayCmdOutput("bp <extended address> - Toggle stop breakpoint");
		displayCmdOutput("bpd <extended address> - Toggle display breakpoint");
		displayCmdOutput("sr - Blink: Segment Register Bank Binding");
		displayCmdOutput("rg - Display current Z80 Registers");
		displayCmdOutput("f/F - Display current Z80 Flag Register");		
		displayCmdOutput("cls - Clear command output area\n");
		displayCmdOutput("Registers are edited using their name, ex. A 01 or sp 1FFE");
		displayCmdOutput("Alternate registers are specified with ', ex. a' 01 or BC' C000");
		displayCmdOutput("Flags are toggled using FZ, FC, FN, FS, FPV and FH commands or");
		displayCmdOutput("set/reset using 1 or 0 argument, eg. FZ 1 to enable Zero flag.");
	}

	private void parseCommandLine(String cmdLineText) {				
		String[] cmdLineTokens = cmdLineTokens = cmdLineText.split(" ");

		if (z80Thread != null && z80Thread.isAlive() == false) {
			z80Thread = null;	// garbage collect dead thread...
		}

		if (cmdLineTokens[0].compareToIgnoreCase("help") == 0) {
			cmdHelp();
		}

		if (cmdLineTokens[0].compareToIgnoreCase("cls") == 0) {
			commandOutput.setText("");
		}

		if (cmdLineTokens[0].compareToIgnoreCase("run") == 0) {
			if (z80Thread == null) {
				 z80Thread = run();
			} else {
				if (z80Thread.isAlive() == true)
					displayCmdOutput("Z88 is already running.");
				else
					z80Thread = run();
			}
		}

		if (cmdLineTokens[0].compareToIgnoreCase("stop") == 0) {
			z88.stopZ80Execution();
		}

		if (cmdLineTokens[0].compareTo(".") == 0) {
			if (z80Thread != null && z80Thread.isAlive() == true) {
				displayCmdOutput("Z88 is already running.");
				return;
			}
			
			z88.run(true);		// single stepping (no interrupts running)...
			displayCmdOutput(blinkStatus.dzPcStatus(z88.PC()).toString());
			
			gui.getCmdLineInputArea().setText(getNextStepCommand());
			gui.getCmdLineInputArea().setCaretPosition(gui.getCmdLineInputArea().getDocument().getLength());
			gui.getCmdLineInputArea().selectAll();			
		}

		if (cmdLineTokens[0].compareToIgnoreCase("z") == 0) {
			if (z80Thread != null && z80Thread.isAlive() == true) {
				displayCmdOutput("Z88 is already running.");
				return;
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
				} catch (InterruptedException err) {}
			}
			z88.setBreakPointManager(origBreakPoints);	// restore user defined break points
			this.setBreakPointManager(origBreakPoints);

			displayCmdOutput(blinkStatus.dzPcStatus(z88.PC()).toString());

			gui.getCmdLineInputArea().setText(getNextStepCommand());
			gui.getCmdLineInputArea().setCaretPosition(gui.getCmdLineInputArea().getDocument().getLength());
			gui.getCmdLineInputArea().selectAll();			
		}

		if (cmdLineTokens[0].compareToIgnoreCase("dz") == 0) {
			dzCommandline(cmdLineTokens);
			displayCmdOutput("");
		}

		if (cmdLineTokens[0].compareToIgnoreCase("m") == 0) {
			viewMemory(cmdLineTokens);
			displayCmdOutput("");
		}

		if (cmdLineTokens[0].compareToIgnoreCase("bl") == 0) {
			blinkStatus.displayBlinkRegisters();
			displayCmdOutput("");
		}

		if (cmdLineTokens[0].compareToIgnoreCase("sr") == 0) {
			blinkStatus.displayBankBindings();
			displayCmdOutput("");
		}

		if (cmdLineTokens[0].compareToIgnoreCase("rg") == 0) {
			blinkStatus.displayZ80Registers();
			displayCmdOutput("");
		}

		if (cmdLineTokens[0].compareToIgnoreCase("bp") == 0) {
			try {
				bpCommandline(cmdLineTokens);
				displayCmdOutput("");
			} catch (IOException e1) {
				e1.printStackTrace();
			}
		}

		if (cmdLineTokens[0].compareToIgnoreCase("bpd") == 0) {
			try {
				bpdCommandline(cmdLineTokens);
				displayCmdOutput("");
			} catch (IOException e1) {
				e1.printStackTrace();
			}
		}

		if (cmdLineTokens[0].compareToIgnoreCase("wb") == 0) {
			try {
				putByte(cmdLineTokens);
			} catch (IOException e1) {
				e1.printStackTrace();
			}
		}

		if (cmdLineTokens[0].compareToIgnoreCase("ldc") == 0) {
			try {
				RandomAccessFile file = new RandomAccessFile(cmdLineTokens[1], "r");
				z88.loadBankBinary(Integer.parseInt(cmdLineTokens[2], 16), file);
				file.close();
				displayCmdOutput("File image loaded into bank.");
			} catch (IOException e) {
				displayCmdOutput("Couldn't load file image into bank: '" + e.getMessage() + "'");
			}
			displayCmdOutput("");
		}

		if (cmdLineTokens[0].compareToIgnoreCase("f") == 0) {
			displayCmdOutput("F=" + blinkStatus.z80Flags());
		}

		if (cmdLineTokens[0].compareToIgnoreCase("fz") == 0) {
			if (z80Thread != null && z80Thread.isAlive() == true) {
				displayCmdOutput("Cannot change Zero flag while Z88 is running!");
				return;
			}
			if (cmdLineTokens.length == 2) {
				if (Integer.parseInt(cmdLineTokens[1], 16) == 0)
					z88.fZ = false;
				else
					z88.fZ = true;
			} else {
				// toggle/invert flag status
				z88.fZ = !z88.fZ;
			}
			displayCmdOutput("F=" + blinkStatus.z80Flags());
		}

		if (cmdLineTokens[0].compareToIgnoreCase("fc") == 0) {
			if (z80Thread != null && z80Thread.isAlive() == true) {
				displayCmdOutput("Cannot change Carry flag while Z88 is running!");
				return;
			}
			if (cmdLineTokens.length == 2) {
				if (Integer.parseInt(cmdLineTokens[1], 16) == 0)
					z88.fC = false;
				else
					z88.fC = true;
			} else {
				// toggle/invert flag status
				z88.fC = !z88.fC;
			}
			displayCmdOutput("F=" + blinkStatus.z80Flags());
		}

		if (cmdLineTokens[0].compareToIgnoreCase("fs") == 0) {
			if (z80Thread != null && z80Thread.isAlive() == true) {
				displayCmdOutput("Cannot change Sign flag while Z88 is running!");
				return;
			}
			if (cmdLineTokens.length == 2) {
				if (Integer.parseInt(cmdLineTokens[1], 16) == 0)
					z88.fS = false;
				else
					z88.fS = true;
			} else {
				// toggle/invert flag status
				z88.fS = !z88.fS;
			}
			displayCmdOutput("F=" + blinkStatus.z80Flags());
		}

		if (cmdLineTokens[0].compareToIgnoreCase("fh") == 0) {
			if (z80Thread != null && z80Thread.isAlive() == true) {
				displayCmdOutput("Cannot change Half Carry flag while Z88 is running!");
				return;
			}
			if (cmdLineTokens.length == 2) {
				if (Integer.parseInt(cmdLineTokens[1], 16) == 0)
					z88.fH = false;
				else
					z88.fH = true;
			} else {
				// toggle/invert flag status
				z88.fH = !z88.fH;
			}
			displayCmdOutput("F=" + blinkStatus.z80Flags());
		}

		if (cmdLineTokens[0].compareToIgnoreCase("fn") == 0) {
			if (z80Thread != null && z80Thread.isAlive() == true) {
				displayCmdOutput("Cannot change Add./Sub. flag while Z88 is running!");
				return;
			}
			if (cmdLineTokens.length == 2) {
				if (Integer.parseInt(cmdLineTokens[1], 16) == 0)
					z88.fN = false;
				else
					z88.fN = true;
			} else {
				// toggle/invert flag status
				z88.fN = !z88.fN;
			}
			displayCmdOutput("F=" + blinkStatus.z80Flags());
		}

		if (cmdLineTokens[0].compareToIgnoreCase("fp") == 0) {
			if (z80Thread != null && z80Thread.isAlive() == true) {
				displayCmdOutput("Cannot change Parity flag while Z88 is running!");
				return;
			}
			if (cmdLineTokens.length == 2) {
				if (Integer.parseInt(cmdLineTokens[1], 16) == 0)
					z88.fPV = false;
				else
					z88.fPV = true;
			} else {
				// toggle/invert flag status
				z88.fPV = !z88.fPV;
			}
			displayCmdOutput("F=" + blinkStatus.z80Flags());
		}

		if (cmdLineTokens[0].compareToIgnoreCase("a") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change A register while Z88 is running!");
					return;
				}
				z88.A(Integer.parseInt(cmdLineTokens[1], 16) & 0xFF);
			}			
			displayCmdOutput("A=" + Dz.byteToHex(z88.A(),true));
		}

		if (cmdLineTokens[0].compareToIgnoreCase("a'") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change alternate A register while Z88 is running!");
					return;
				}
				z88.ex_af_af();
				z88.A(Integer.parseInt(cmdLineTokens[1], 16) & 0xFF);
				z88.ex_af_af();
			}	
			z88.ex_af_af();		
			displayCmdOutput("A'=" + Dz.byteToHex(z88.A(),true));
			z88.ex_af_af();
		}

		if (cmdLineTokens[0].compareToIgnoreCase("b") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change B register while Z88 is running!");
					return;
				}
				z88.B(Integer.parseInt(cmdLineTokens[1], 16) & 0xFF);
			}			
			displayCmdOutput("B=" + Dz.byteToHex(z88.B(),true));
		}

		if (cmdLineTokens[0].compareToIgnoreCase("c") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change C register while Z88 is running!");
					return;
				}
				z88.C(Integer.parseInt(cmdLineTokens[1], 16) & 0xFF);
			}			
			displayCmdOutput("C=" + Dz.byteToHex(z88.C(),true));
		}

		if (cmdLineTokens[0].compareToIgnoreCase("b'") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change alternate B register while Z88 is running!");
					return;
				}
				z88.exx();
				z88.B(Integer.parseInt(cmdLineTokens[1], 16) & 0xFF);
				z88.exx();
			}	
			z88.exx();		
			displayCmdOutput("B'=" + Dz.byteToHex(z88.B(),true));
			z88.exx();
		}

		if (cmdLineTokens[0].compareToIgnoreCase("c'") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change alternate C register while Z88 is running!");
					return;
				}
				z88.exx();
				z88.C(Integer.parseInt(cmdLineTokens[1], 16) & 0xFF);
				z88.exx();
			}	
			z88.exx();		
			displayCmdOutput("C'=" + Dz.byteToHex(z88.C(),true));
			z88.exx();
		}

		if (cmdLineTokens[0].compareToIgnoreCase("bc") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change BC register while Z88 is running!");
					return;
				}
				z88.BC(Integer.parseInt(cmdLineTokens[1], 16) & 0xFFFF);
			}			
			displayCmdOutput("BC=" + Dz.addrToHex(z88.BC(),true));
		}

		if (cmdLineTokens[0].compareToIgnoreCase("bc'") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change alternate BC register while Z88 is running!");
					return;
				}
				z88.exx();
				z88.BC(Integer.parseInt(cmdLineTokens[1], 16) & 0xFFFF);
				z88.exx();
			}	
			z88.exx();		
			displayCmdOutput("BC'=" + Dz.addrToHex(z88.BC(),true));
			z88.exx();
		}

		if (cmdLineTokens[0].compareToIgnoreCase("d") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change D register while Z88 is running!");
					return;
				}
				z88.D(Integer.parseInt(cmdLineTokens[1], 16) & 0xFF);
			}			
			displayCmdOutput("D=" + Dz.byteToHex(z88.D(),true));
		}

		if (cmdLineTokens[0].compareToIgnoreCase("e") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change E register while Z88 is running!");
					return;
				}
				z88.E(Integer.parseInt(cmdLineTokens[1], 16) & 0xFF);
			}			
			displayCmdOutput("E=" + Dz.byteToHex(z88.E(),true));
		}

		if (cmdLineTokens[0].compareToIgnoreCase("d'") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change alternate D register while Z88 is running!");
					return;
				}
				z88.exx();
				z88.D(Integer.parseInt(cmdLineTokens[1], 16) & 0xFF);
				z88.exx();
			}	
			z88.exx();		
			displayCmdOutput("D'=" + Dz.byteToHex(z88.D(),true));
			z88.exx();
		}

		if (cmdLineTokens[0].compareToIgnoreCase("e'") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change alternate E register while Z88 is running!");
					return;
				}
				z88.exx();
				z88.E(Integer.parseInt(cmdLineTokens[1], 16) & 0xFF);
				z88.exx();
			}	
			z88.exx();		
			displayCmdOutput("E'=" + Dz.byteToHex(z88.E(),true));
			z88.exx();
		}

		if (cmdLineTokens[0].compareToIgnoreCase("de") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change DE register while Z88 is running!");
					return;
				}
				z88.DE(Integer.parseInt(cmdLineTokens[1], 16) & 0xFFFF);
			}			
			displayCmdOutput("DE=" + Dz.addrToHex(z88.DE(),true));
		}
		
		if (cmdLineTokens[0].compareToIgnoreCase("de'") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change alternate DE register while Z88 is running!");
					return;
				}
				z88.exx();
				z88.DE(Integer.parseInt(cmdLineTokens[1], 16) & 0xFFFF);
				z88.exx();
			}	
			z88.exx();		
			displayCmdOutput("DE'=" + Dz.addrToHex(z88.DE(),true));
			z88.exx();
		}

		if (cmdLineTokens[0].compareToIgnoreCase("h") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change H register while Z88 is running!");
					return;
				}
				z88.H(Integer.parseInt(cmdLineTokens[1], 16) & 0xFF);
			}			
			displayCmdOutput("H=" + Dz.byteToHex(z88.H(),true));
		}

		if (cmdLineTokens[0].compareToIgnoreCase("l") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change L register while Z88 is running!");
					return;
				}
				z88.L(Integer.parseInt(cmdLineTokens[1], 16) & 0xFF);
			}			
			displayCmdOutput("L=" + Dz.byteToHex(z88.L(),true));
		}

		if (cmdLineTokens[0].compareToIgnoreCase("h'") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change alternate H register while Z88 is running!");
					return;
				}
				z88.exx();
				z88.H(Integer.parseInt(cmdLineTokens[1], 16) & 0xFF);
				z88.exx();
			}	
			z88.exx();		
			displayCmdOutput("H'=" + Dz.byteToHex(z88.H(),true));
			z88.exx();
		}

		if (cmdLineTokens[0].compareToIgnoreCase("l'") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change alternate L register while Z88 is running!");
					return;
				}
				z88.exx();
				z88.L(Integer.parseInt(cmdLineTokens[1], 16) & 0xFF);
				z88.exx();
			}	
			z88.exx();		
			displayCmdOutput("L'=" + Dz.byteToHex(z88.L(),true));
			z88.exx();
		}

		if (cmdLineTokens[0].compareToIgnoreCase("hl") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change HL register while Z88 is running!");
					return;
				}
				z88.HL(Integer.parseInt(cmdLineTokens[1], 16) & 0xFFFF);
			}			
			displayCmdOutput("HL=" + Dz.addrToHex(z88.HL(),true));
		}

		if (cmdLineTokens[0].compareToIgnoreCase("hl'") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change alternate HL register while Z88 is running!");
					return;
				}
				z88.exx();
				z88.HL(Integer.parseInt(cmdLineTokens[1], 16) & 0xFFFF);
				z88.exx();
			}	
			z88.exx();		
			displayCmdOutput("HL'=" + Dz.addrToHex(z88.HL(),true));
			z88.exx();
		}

		if (cmdLineTokens[0].compareToIgnoreCase("ix") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change IX register while Z88 is running!");
					return;
				}
				z88.IX(Integer.parseInt(cmdLineTokens[1], 16) & 0xFFFF);
			}			
			displayCmdOutput("IX=" + Dz.addrToHex(z88.IX(),true));
		}

		if (cmdLineTokens[0].compareToIgnoreCase("iy") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change IY register while Z88 is running!");
					return;
				}
				z88.IY(Integer.parseInt(cmdLineTokens[1], 16) & 0xFFFF);
			}			
			displayCmdOutput("IY=" + Dz.addrToHex(z88.IY(),true));
		}

		if (cmdLineTokens[0].compareToIgnoreCase("sp") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change SP register while Z88 is running!");
					return;
				}
				z88.SP(Integer.parseInt(cmdLineTokens[1], 16) & 0xFFFF);
			}			
			displayCmdOutput("SP=" + Dz.addrToHex(z88.SP(),true));
		}

		if (cmdLineTokens[0].compareToIgnoreCase("pc") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change PC register while Z88 is running!");
					return;
				}
				z88.PC(Integer.parseInt(cmdLineTokens[1], 16) & 0xFFFF);
			}			
			displayCmdOutput("PC=" + Dz.addrToHex(z88.PC(),true));
		}
		
		if (cmdLineTokens[0].compareToIgnoreCase("exit") == 0) {
			System.exit(0);
		}		
	}

	/**
	 * Based on the current instruction that will be executed next,
	 * suggest a default step command; either a single step or a subroutine call.
	 * 
	 * The purpose is to easy the amount of typing on the command line while
	 * stepping through the current subroutine level code. 
	 * 
	 * @return step command suggestion
	 */
	private String getNextStepCommand() {
		int instrOpcode = z88.readByte(z88.PC());	// get current instruction opcode (to be executed)
		
		switch(instrOpcode) {
			case 0xCD: // CALL addr
			case 0xDC: // CALL C,addr
			case 0xFC: // CALL M,addr
			case 0xD4: // CALL NC,addr
			case 0xC4: // CALL NZ,addr
			case 0xF4: // CALL P,addr
			case 0xEC: // CALL PE,addr
			case 0xE4: // CALL PO,addr
			case 0xCC: // CALL Z,addr
				return "z";	// suggest a subroutine step
			case 0xC7: // RST 00
			case 0xCF: // RST 08
			case 0xD7: // RST 10
			case 0xDF: // RST 18
			case 0xE7: // RST 20
			case 0xEF: // RST 28
			case 0xF7: // RST 30
			case 0xFF: // RST 38
				return "z";	// suggest a subroutine step
			default:
				return "."; // suggest a single step
		}
	}
	
	private void bpCommandline(String[] cmdLineTokens) throws IOException {
		int bpAddress;
		
		if (cmdLineTokens.length == 2) {
			if (z80Thread != null && z80Thread.isAlive() == true) {
				displayCmdOutput("Breakpoints cannot be edited while Z88 is running.");
				return;
			} else {
				bpAddress = Integer.parseInt(cmdLineTokens[1], 16);

				if (bpAddress > 65535) {
					bpAddress &= 0xFF3FFF;	// strip segment mask
				} else {
					if (cmdLineTokens[1].length() == 6) {
						// bank defined as '00'
						bpAddress &= 0x3FFF;	// strip segment mask
					} else {
						bpAddress = z88.decodeLocalAddress(bpAddress); // local address -> ext.address
					}
				}
			}

			breakp.toggleBreakpoint(bpAddress, true);
			displayCmdOutput(breakp.listBreakpoints());
		}

		if (cmdLineTokens.length == 1) {
			// no arguments, use PC in current bank binding
			displayCmdOutput(breakp.listBreakpoints());
		}
	}

	private void bpdCommandline(String[] cmdLineTokens) throws IOException {
		int bpAddress;
		
		if (cmdLineTokens.length == 2) {
			if (z80Thread != null && z80Thread.isAlive() == true) {
				displayCmdOutput("Display Breakpoints cannot be edited while Z88 is running.");
				return;
			} else {
				bpAddress = Integer.parseInt(cmdLineTokens[1], 16);

				if (bpAddress > 65535) {
					bpAddress &= 0xFF3FFF;	// strip segment mask
				} else {
					if (cmdLineTokens[1].length() == 6) {
						// bank defined as '00'
						bpAddress &= 0x3FFF;	// strip segment mask
					} else {
						bpAddress = z88.decodeLocalAddress(bpAddress); // local address -> ext.address
					}
				}
			}

			breakp.toggleBreakpoint(bpAddress, false);
			displayCmdOutput(breakp.listBreakpoints());
		}

		if (cmdLineTokens.length == 1) {
			// no arguments, use PC in current bank binding
			displayCmdOutput(breakp.listBreakpoints());
		}
	}

	private void dzCommandline(String[] cmdLineTokens) {
		boolean localAddressing = true;
		int dzAddr = 0, dzBank = 0;
		StringBuffer dzLine = new StringBuffer(64);

		if (cmdLineTokens.length == 2) {
			// one argument; the local Z80 64K address or a compact 24bit extended address
			dzAddr = Integer.parseInt(cmdLineTokens[1], 16);
			if (dzAddr > 65535) {
				dzBank = (dzAddr >>> 16) & 0xFF;
				dzAddr &= 0xFFFF;	// bank offset (with simulated segment addressing)
				localAddressing = false;
			} else {
				if (cmdLineTokens[1].length() == 6) {
					// bank defined as '00'
					dzBank = 0;
					localAddressing = false;
				} else {
					localAddressing = true;				
				}				
			}
		} else {
			if (cmdLineTokens.length == 1) {
				// no arguments, use PC in current bank binding (use local addressing)...
				dzAddr = z88.PC();
				localAddressing = true;
			} else {
				displayCmdOutput("Illegal argument.");
				return;
			}
		}

		if (localAddressing == true) {
			for (int dzLines = 0;  dzLines < 16; dzLines++) {
				int origAddr = dzAddr; 
				dzAddr = dz.getInstrAscii(dzLine, dzAddr, false, true);
				displayCmdOutput(Dz.addrToHex(origAddr,false) + " (" + Dz.extAddrToHex(z88.decodeLocalAddress(origAddr),false).toString() + ") " + dzLine.toString());
			}
			
			gui.getCmdLineInputArea().setText("dz " + Dz.addrToHex(dzAddr,false));			
		} else {
			// extended addressing
			for (int dzLines = 0;  dzLines < 16; dzLines++) {
				int origAddr = dzAddr; 
				dzAddr = dz.getInstrAscii(dzLine, dzAddr, dzBank, false, true);
				displayCmdOutput(Dz.extAddrToHex((dzBank << 16) | origAddr,false) + " " + dzLine);
			}

			gui.getCmdLineInputArea().setText("dz " + Dz.extAddrToHex((dzBank << 16) | dzAddr,false));
		}		
		gui.getCmdLineInputArea().setCaretPosition(gui.getCmdLineInputArea().getDocument().getLength());
		gui.getCmdLineInputArea().selectAll();			
	}

	private int getMemoryAscii(StringBuffer memLine, int memAddr) {
		int memHex, memAscii;

		memLine.delete(0,255);		
		for (memHex=memAddr; memHex < memAddr+16; memHex++) {
			memLine.append(Dz.byteToHex(z88.readByte(memHex),false)).append(" ");
		}

		for (memAscii=memAddr; memAscii < memAddr+16; memAscii++) {
			int b = z88.readByte(memAscii);
			memLine.append( (b >= 32 && b <= 127) ? Character.toString( (char) b) : "." );
		}
		
		return memAscii;
	}

	private int getMemoryAscii(StringBuffer memLine, int memAddr, int memBank) {
		int memHex, memAscii;

		memLine.delete(0,255);
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
			displayCmdOutput("Illegal argument(s).");
			return;
		}

		StringBuffer memLine = new StringBuffer(256);
		temp = getMemoryAscii(memLine, memAddress, memBank);
		displayCmdOutput("Before:\n" + memLine);
		for (aByte= 0; aByte < cmdLineTokens.length - 2; aByte++) {
			z88.setByte(memAddress + aByte, memBank, argByte[aByte]);
		}

		temp = getMemoryAscii(memLine, memAddress, memBank);
		displayCmdOutput("After:\n" + memLine);
	}


	private void viewMemory(String[] cmdLineTokens) {
		boolean localAddressing = true;
		int memAddr = 0, memBank = 0;
		StringBuffer memLine = new StringBuffer(256);
		
		if (cmdLineTokens.length == 2) {
			// one argument; the local Z80 64K address or 24bit compact ext. address
			memAddr = Integer.parseInt(cmdLineTokens[1], 16);

			if (memAddr > 65535) {
				memBank = (memAddr >>> 16) & 0xFF;
				memAddr &= 0xFFFF;
				localAddressing = false;
			} else {
				if (cmdLineTokens[1].length() == 6) {
					// bank defined as '00'
					memBank = 0;
					localAddressing = false;
				} else {
					localAddressing = true;				
				}
			}
		} else {
			if (cmdLineTokens.length == 1) {
				// no arguments, use PC in current bank binding (use local addressing)...
                memAddr = z88.PC();
				localAddressing = true;
			} else {
				displayCmdOutput("Illegal argument.");
				return;
			}
		}

		if (localAddressing == true) {
			for (int memLines = 0;  memLines < 16; memLines++) {
				int origAddr = memAddr; 				
				memAddr = getMemoryAscii(memLine, memAddr);
				displayCmdOutput(Dz.addrToHex(origAddr, false) + " (" + 
						Dz.extAddrToHex(z88.decodeLocalAddress(origAddr),false).toString() + ") " +  
						memLine.toString());
			}

			gui.getCmdLineInputArea().setText("m " + Dz.addrToHex(memAddr,false));			
		} else {
			// extended addressing
			for (int memLines = 0;  memLines < 16; memLines++) {
				int origAddr = memAddr; 				
				memAddr = getMemoryAscii(memLine, memAddr, memBank);
				memAddr &= 0xFFFF; // stay within bank boundary..
				displayCmdOutput(Dz.extAddrToHex((memBank << 16) | origAddr,false) + " " + memLine.toString());
			}

			gui.getCmdLineInputArea().setText("m " + Dz.extAddrToHex((memBank << 16) | memAddr,false));
		}
		
		gui.getCmdLineInputArea().setCaretPosition(gui.getCmdLineInputArea().getDocument().getLength());		
		gui.getCmdLineInputArea().selectAll();
	}

	public void bootZ88Rom() {
		z80Thread = run();
	}

	private Thread run() {
		displayRtmMessage("Z88 virtual machine was started.");

		Thread thread = new Thread() {
			public void run() {

				if (breakp.isStoppable(z88.decodeLocalAddress(z88.PC())) == true) {
					// we need to use single stepping mode to
					// step past the break point at current instruction
					z88.run(true);
				}
				// restore (patch) breakpoints into code
				breakp.setBreakpoints();
				z88.startInterrupts(); // enable Z80/Z88 core interrupts
				z88.run(false);
				// execute Z80 code at full speed until breakpoint is encountered...
				z88.stopInterrupts();
				breakp.clearBreakpoints();
			}
		};

		thread.setPriority(Thread.MIN_PRIORITY);
		thread.start();

		return thread;
	}

	/**
	 * @param b
	 */
	public void setDebugMode(boolean b) {
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

	public void keyPressed(KeyEvent e) {
		switch (e.getKeyCode()) {
			case KeyEvent.VK_F12:
				z88Screen.grabFocus();
				break;
				
			case KeyEvent.VK_UP:
				// replace current contents of command line with previous 
				// input from command history and remember new position in list.
				String prevCmd = cmdList.browsePrevCommand();
				if (prevCmd != null) {
					gui.getCmdLineInputArea().setText(prevCmd);
					gui.getCmdLineInputArea().setCaretPosition(gui.getCmdLineInputArea().getDocument().getLength());
					gui.getCmdLineInputArea().selectAll();
				}
				break;
								
			case KeyEvent.VK_DOWN:
				// replace current contents of command line with next 
				// input from command history and remember new position in list. 
				String nextCmd = cmdList.browseNextCommand();
				if (nextCmd != null) {
					gui.getCmdLineInputArea().setText(nextCmd);
					gui.getCmdLineInputArea().setCaretPosition(gui.getCmdLineInputArea().getDocument().getLength());
					gui.getCmdLineInputArea().selectAll();
				}
				break;				
		}	
	}

	public void keyReleased(KeyEvent arg0) {
	}

	public void keyTyped(KeyEvent arg0) {
	}
}
