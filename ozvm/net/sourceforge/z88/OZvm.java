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

	public static final String VERSION = "0.5.dev.1";
	public static boolean debugMode = false;		// boot ROM and external cards immediately, unless "debug" is specified at cmdline

	private Blink z88 = null;
	private Memory memory = null;
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
	private Breakpoints breakPointManager;

	public OZvm() {
		
		try {
			gui = Gui.getInstance();
			
			z88 = Blink.getInstance();
			memory = Memory.getInstance();
			z88Screen = Z88display.getInstance();
			z88Screen.start();

			dz = Dz.getInstance(); // the disassembly engine...
			breakPointManager = Breakpoints.getInstance();

		} catch (Exception e) {
			e.printStackTrace();
			Gui.displayRtmMessage("\n\nCouldn't initialize Z88 virtual machine.");
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

	private void initDebugMode() {
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
		cmdList = new CommandHistory();

		commandOutput = gui.getCmdlineOutputArea();
        blinkStatus = new DisplayStatus();			
		displayCmdOutput("Type 'help' for available debugging commands");
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
						 args[arg].compareTo("fcd1") != 0 & args[arg].compareTo("fcd2") != 0 & args[arg].compareTo("fcd3") != 0 &
						 args[arg].compareTo("crd1") != 0 & args[arg].compareTo("crd2") != 0 & args[arg].compareTo("crd3") != 0 &						 
						 args[arg].compareTo("s1") != 0 & args[arg].compareTo("s2") != 0 & args[arg].compareTo("s3") != 0 &
						 args[arg].compareTo("kbl") != 0 & args[arg].compareTo("debug") != 0 &
						 args[arg].compareTo("initdebug") != 0) {
						Gui.displayRtmMessage("Loading '" + args[0] + "' into ROM space in slot 0.");
						file = new RandomAccessFile(args[0], "r");
						memory.loadRomBinary(file);
						file.close();
						loadedRom = true;
						arg++;
					}

					if (arg<args.length && (args[arg].startsWith("ram") == true)) {
						int ramSlotNumber = args[arg].charAt(3) - 48;
						ramSizeArg = Integer.parseInt(args[arg+1], 10);
						if (ramSlotNumber == 0) {
							if ((ramSizeArg <32) | (ramSizeArg>512)) {
								Gui.displayRtmMessage("Only 32K-512K RAM Card size allowed in slot " + ramSlotNumber);
								return false;
							}
						} else {
							if ((ramSizeArg<32) | (ramSizeArg>1024)) {
								Gui.displayRtmMessage("Only 32K-1024K RAM Card size allowed in slot " + ramSlotNumber);
								return false;
							}
						}
						memory.insertRamCard(ramSizeArg * 1024, ramSlotNumber);	// RAM Card specified for slot x...
						if (ramSlotNumber == 0) ramSlot0 = true; 
						Gui.displayRtmMessage("Inserted " + ramSizeArg + "K RAM Card in slot " + ramSlotNumber);

						arg+=2;
						continue;
					}

					if (arg<args.length && (args[arg].startsWith("epr") == true)) {
						int eprSlotNumber = args[arg].charAt(3) - 48;
						eprSizeArg = Integer.parseInt(args[arg+1], 10);
						if (memory.insertEprCard(eprSlotNumber, eprSizeArg, args[arg+2]) == true) {
							String insertEprMsg = "Inserted " + eprSlotNumber + " set to " + eprSizeArg + "K.";
							if (args[arg+2].compareToIgnoreCase("27C") == 0) insertEprMsg = "Inserted " + eprSizeArg + "K UV Eprom Card in slot " + eprSlotNumber; 
							if (args[arg+2].compareToIgnoreCase("28F") == 0) insertEprMsg = "Inserted " + eprSizeArg + "K Intel Flash Card in slot " + eprSlotNumber;
							if (args[arg+2].compareToIgnoreCase("29F") == 0) insertEprMsg = "Inserted " + eprSizeArg + "K Amd Flash Card in slot " + eprSlotNumber;
							Gui.displayRtmMessage(insertEprMsg);
						} else
							Gui.displayRtmMessage("Eprom Card size/type configuration is illegal.");
						arg+=3;
						continue;
					}

					if (arg<args.length && (args[arg].startsWith("fcd") == true)) {
						int eprSlotNumber = args[arg].charAt(3) - 48;
						eprSizeArg = Integer.parseInt(args[arg+1], 10);
						if (memory.insertFileEprCard(eprSlotNumber, eprSizeArg, args[arg+2]) == true) {
							String insertEprMsg = "Inserted " + eprSlotNumber + " set to " + eprSizeArg + "K.";
							if (args[arg+2].compareToIgnoreCase("27C") == 0) insertEprMsg = "Inserted " + eprSizeArg + "K UV File Eprom Card in slot " + eprSlotNumber; 
							if (args[arg+2].compareToIgnoreCase("28F") == 0) insertEprMsg = "Inserted " + eprSizeArg + "K Intel File Flash Card in slot " + eprSlotNumber;
							if (args[arg+2].compareToIgnoreCase("29F") == 0) insertEprMsg = "Inserted " + eprSizeArg + "K Amd File Flash Card in slot " + eprSlotNumber;
							Gui.displayRtmMessage(insertEprMsg);
						} else
							Gui.displayRtmMessage("Eprom File Card size/type configuration is illegal.");
						arg+=3;
						continue;
					}
					
					if (arg<args.length && (args[arg].startsWith("crd") == true)) {
						int eprSlotNumber = args[arg].charAt(3) - 48;
						eprSizeArg = Integer.parseInt(args[arg+1], 10);
						file = new RandomAccessFile(args[arg+3], "r");
						memory.loadImageOnEprom(eprSlotNumber, eprSizeArg, args[arg+2], file);
						String insertEprMsg = "";
						if (args[arg+2].compareToIgnoreCase("27C") == 0) insertEprMsg = "Loaded file image '" + args[arg+3] + "' on " + eprSizeArg + "K UV Eprom Card in slot " + eprSlotNumber; 
						if (args[arg+2].compareToIgnoreCase("28F") == 0) insertEprMsg = "Loaded file image '" + args[arg+3] + "' on " + eprSizeArg + "K Intel Flash Card in slot " + eprSlotNumber;
						if (args[arg+2].compareToIgnoreCase("29F") == 0) insertEprMsg = "Loaded file image '" + args[arg+3] + "' on " + eprSizeArg + "K Amd Flash Card in slot " + eprSlotNumber;
						Gui.displayRtmMessage(insertEprMsg);
						arg+=4;
						continue;
					}
					
					if (arg<args.length && ( args[arg].compareTo("s1") == 0 | args[arg].compareTo("s2") == 0 | args[arg].compareTo("s3") == 0)) {
						int slotNumber = Integer.parseInt(args[arg].substring(1));
						String crdType = null;
						if (args[arg+1].compareToIgnoreCase("-t") == 0) {
							// Optional type argument
							crdType = args[arg+2];
							arg += 2;
						} else {
							arg++;
						}
						file = new RandomAccessFile(args[arg], "r");
						Gui.displayRtmMessage("Loading '" + args[arg] + "' into slot " + slotNumber + ".");
						memory.loadCardBinary(slotNumber, crdType, file);
						file.close();
						arg++;
						continue;
					}

					if (arg<args.length && (args[arg].compareTo("debug") == 0)) {
						setDebugMode(true);
						initDebugMode();
						arg++;
						continue;
					}

					if (arg<args.length && (args[arg].compareTo("initdebug") == 0)) {
						setDebugMode(true);
						initDebugMode();

						file = new RandomAccessFile(args[arg+1], "r");
						gui.getCmdLineInputArea().setEnabled(false);	// don't allow command input while parsing file...
						String cmd = null;
						while ( (cmd = file.readLine()) != null) {
							parseCommandLine(cmd);
							Thread.yield();
						}
						gui.getCmdLineInputArea().setEnabled(true); // ready for commands from the keyboard...
						file.close();						
						Gui.displayRtmMessage("Parsed '" + args[arg+1] + "' command file.");
						
						arg+=2;						
						continue;
					}

					if (arg<args.length && (args[arg].compareTo("kbl") == 0)) {
						if (args[arg+1].compareToIgnoreCase("uk") == 0 || args[arg+1].compareToIgnoreCase("en") == 0) {
							Z88Keyboard.getInstance().setKeyboardLayout(Z88Keyboard.COUNTRY_EN);
							Gui.displayRtmMessage("Using English (UK) keyboard layout.");
						}
						if (args[arg+1].compareTo("fr") == 0) {
							Z88Keyboard.getInstance().setKeyboardLayout(Z88Keyboard.COUNTRY_FR);
							Gui.displayRtmMessage("Using French keyboard layout.");
						}
						if (args[arg+1].compareTo("dk") == 0) {
							Z88Keyboard.getInstance().setKeyboardLayout(Z88Keyboard.COUNTRY_DK);
							Gui.displayRtmMessage("Using Danish keyboard layout.");
						}
						if (args[arg+1].compareTo("se") == 0) {
							Z88Keyboard.getInstance().setKeyboardLayout(Z88Keyboard.COUNTRY_SE);
							Gui.displayRtmMessage("Using Swedish keyboard layout.");
						}
						if (args[arg+1].compareTo("fi") == 0) {
							Z88Keyboard.getInstance().setKeyboardLayout(Z88Keyboard.COUNTRY_FI);
							Gui.displayRtmMessage("Using Finish keyboard layout.");
						}
						arg+=2;
						continue;
					}
				}
			}

			if (loadedRom == false) {
				Gui.displayRtmMessage("No external ROM image specified, using default Z88.rom (V4.0 UK)");
				memory.loadRomBinary(z88.getClass().getResource("/Z88.rom"));
			}

			if (ramSlot0 == false) {
				Gui.displayRtmMessage("RAM0 set to default 32K.");
				memory.insertRamCard(32 * 1024, 0);	// no RAM specified for slot 0, set to default 32K RAM...
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
		displayCmdOutput("Flags are toggled using FZ, FC, FN, FS, FV and FH commands or");
		displayCmdOutput("set/reset using 1 or 0 argument, eg. fz 1 to enable Zero flag.");
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
				 z80Thread = runZ80Engine(-1);
			} else {
				if (z80Thread.isAlive() == true)
					displayCmdOutput("Z88 is already running.");
				else
					z80Thread = runZ80Engine(-1);
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
			
			z88.singleStepZ80();		// single stepping (no interrupts running)...
			displayCmdOutput(blinkStatus.dzPcStatus(z88.PC()).toString());
			
			gui.getCmdLineInputArea().setText(getNextStepCommand());
			gui.getCmdLineInputArea().setCaretPosition(gui.getCmdLineInputArea().getDocument().getLength());
			gui.getCmdLineInputArea().selectAll();			
		}

		if (cmdLineTokens[0].compareToIgnoreCase("z") == 0) {
			if (z80Thread != null && z80Thread.isAlive() == true) {
				displayCmdOutput("Z88 is already running.");
				return;
			} else {
				int nextInstrAddress = z88.decodeLocalAddress(dz.getNextInstrAddress(z88.PC()));
				if (breakPointManager.isCreated(nextInstrAddress) == true) {
					// there's already a breakpoint at that location...
					z80Thread = runZ80Engine(-1); 
				} else {
					breakPointManager.toggleBreakpoint(nextInstrAddress); 	// set a temporary breakpoint at next instruction 
					z80Thread = runZ80Engine(nextInstrAddress);				// and automatically remove it when the engine stops...	
				}				
			}
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
				memory.loadBankBinary(Integer.parseInt(cmdLineTokens[2], 16), file);
				file.close();
				displayCmdOutput("File image '" + cmdLineTokens[1] + "' loaded at " + cmdLineTokens[2] + ".");
			} catch (IOException e) {
				displayCmdOutput("Couldn't load file image at ext.address: '" + e.getMessage() + "'");
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

		if (cmdLineTokens[0].compareToIgnoreCase("fv") == 0) {
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
			case 0xDC: // CALL C,addr
				if (z88.fC == true) return "z"; else return "."; 
			case 0xD4: // CALL NC,addr
				if (z88.fC == false) return "z"; else return ".";
			case 0xCC: // CALL Z,addr
				if (z88.fZ == true) return "z"; else return ".";
			case 0xC4: // CALL NZ,addr
				if (z88.fZ == false) return "z"; else return ".";
			case 0xF4: // CALL P,addr
				if (z88.fS == false) return "z"; else return ".";
			case 0xFC: // CALL M,addr
				if (z88.fS == true) return "z"; else return ".";
			case 0xEC: // CALL PE,addr
				if (z88.fPV == true) return "z"; else return ".";
			case 0xE4: // CALL PO,addr
				if (z88.fPV == false) return "z"; else return ".";
			case 0xCD: // CALL addr
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

			breakPointManager.toggleBreakpoint(bpAddress, true);
			displayCmdOutput(breakPointManager.listBreakpoints());
		}

		if (cmdLineTokens.length == 1) {
			// no arguments, use PC in current bank binding
			displayCmdOutput(breakPointManager.listBreakpoints());
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

			breakPointManager.toggleBreakpoint(bpAddress, false);
			displayCmdOutput(breakPointManager.listBreakpoints());
		}

		if (cmdLineTokens.length == 1) {
			// no arguments, use PC in current bank binding
			displayCmdOutput(breakPointManager.listBreakpoints());
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
			memLine.append(Dz.byteToHex(memory.getByte(memHex,memBank),false)).append(" ");
		}

		for (memAscii=memAddr; memAscii < memAddr+16; memAscii++) {
			int b = memory.getByte(memAscii,memBank);
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
			memory.setByte(memAddress + aByte, memBank, argByte[aByte]);
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

	/**
	 * Just run the virtual machine if no debugging was enabled.
	 * (No breakpoints are defined by default)
	 *
	 */
	public void bootZ88Rom() {
		z80Thread = runZ80Engine(-1);
	}

	private Thread runZ80Engine(final int oneStopBreakpoint) {
		Gui.displayRtmMessage("Z88 virtual machine was started.");
		z80Thread = null;
		System.gc(); // try to garbage collect...
		
		Thread thread = new Thread() {
			public void run() {

				if (breakPointManager.isStoppable(z88.decodeLocalAddress(z88.PC())) == true) {
					// we need to use single stepping mode to
					// step past the break point at current instruction
					z88.singleStepZ80();
				}
				// restore (patch) breakpoints into code
				breakPointManager.installBreakpoints();
				z88.startInterrupts(); // enable Z80/Z88 core interrupts
				Z88display.getInstance().grabFocus(); // default keyboard input focus to the Z88
				z88.execZ80();
				// execute Z80 code at full speed until breakpoint is encountered...
				// (or F5 emergency break is used!)
				z88.stopInterrupts();
				breakPointManager.clearBreakpoints();

				if (oneStopBreakpoint != -1)
					breakPointManager.toggleBreakpoint(oneStopBreakpoint); // remove the temporary breakpoint (reached, or not)
					
				displayCmdOutput(blinkStatus.dzPcStatus(z88.PC()).toString());

				gui.getCmdLineInputArea().setText(getNextStepCommand());
				gui.getCmdLineInputArea().setCaretPosition(gui.getCmdLineInputArea().getDocument().getLength());
				gui.getCmdLineInputArea().selectAll();	
				commandInput.grabFocus();	// Z88 is stopped, get focus to debug command line.
			}
		};

		thread.setPriority(Thread.NORM_PRIORITY - 1); // execute the Z80 engine just below normal thread priority...
		thread.start();
		Thread.yield(); // the command line is not that important right now...

		return thread;
	}

	/**
	 * @param b
	 */
	public void setDebugMode(boolean b) {
		debugMode = b;
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
