package net.sourceforge.z88;

import java.awt.event.KeyEvent;
import java.awt.event.KeyListener;
import java.io.FileNotFoundException;
import java.io.IOException;
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
public class OZvm implements KeyListener {

	public static final String VERSION = "0.3.4";

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
	private JTextArea commandOutput = null;
	private JTextField commandInput = null;
	private JPanel z88Screen = null;
	private CommandHistory cmdList = null;
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
	public OZvm(Z88display z88Display, JTextField cmdInput, JTextArea cmdOutput, JTextArea rtmOutput) {

		try {
			runtimeOutput = rtmOutput;
			commandInput = cmdInput;
			commandOutput = cmdOutput;
			z88Screen = z88Display;
			
			z88 = new Blink(z88Display, cmdInput, rtmOutput);
			z88Display.init();
			z88Display.setBlink(z88);
			z88Display.start();
			z88.hardReset();

			z80Speed = new MonitorZ80(z88);
			dz = new Dz(z88); // the disassembly engine, linked to the memory model
			breakp = new Breakpoints(z88);
            blinkStatus = new DisplayStatus(z88, commandOutput);
			z88.setBreakPointManager(breakp);
			
			commandInput.addActionListener(new java.awt.event.ActionListener() { 
				public void actionPerformed(java.awt.event.ActionEvent e) {    
					String cmdline = commandInput.getText();
					cmdList.addCommand(cmdline);
					commandInput.setText("");			
					parseCommandLine(cmdline);					
				}
			});

			cmdList = new CommandHistory();
			commandInput.addKeyListener(this);
			
			displayCmdOutput("Type 'h' or 'help' for available debugging commands");
		} catch (Exception e) {
			e.printStackTrace();
			rtmOutput.append("\n\nCouldn't initialize Z88 virtual machine.");
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
	 * Dump current Z80 Registers and instruction disassembly to command output window.
	 */
	private void z80Status() {
		StringBuffer dzBuffer = new StringBuffer(64);
		int bank = ((z88.decodeLocalAddress(z88.PC()) | (z88.PC() & 0xF000)) >>> 16) & 0xFF;

		blinkStatus.displayZ80Registers();

		dz.getInstrAscii(dzBuffer, z88.PC(), true);
		displayCmdOutput( Dz.byteToHex(bank, false) + dzBuffer);
	}

	public boolean boot(String[] args) {
		RandomAccessFile file;
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
						 args[arg].compareTo("kbl") != 0 & args[arg].compareTo("debug") != 0 &
						 args[arg].compareTo("initdebug") != 0) {
						runtimeOutput.append("Loading '" + args[arg] + "' into ROM space in slot 0.\n");
						file = new RandomAccessFile(args[0], "r");
						z88.loadRomBinary(file);
						file.close();
						loadedRom = true;
						arg++;
					}

					if (arg<args.length && (args[arg].startsWith("ram") == true)) {
						int ramSlotNumber = args[arg].charAt(3) - 48;
						ramSizeArg = Integer.parseInt(args[arg+1], 10);
						z88.insertRamCard(ramSizeArg * 1024, ramSlotNumber);	// RAM specified for slot x...
						if (ramSlotNumber == 0) ramSlot0 = true; 
						runtimeOutput.append("RAM" + ramSlotNumber + " set to " + ramSizeArg + "K.\n");
						arg+=2;
						continue;
					}

					if (arg<args.length && (args[arg].compareTo("s1") == 0)) {
						file = new RandomAccessFile(args[arg+1], "r");
						runtimeOutput.append("Loading '" + args[arg+1] + "' into slot 1.\n");
						z88.loadCardBinary(1, file);
						file.close();
						arg+=2;
						continue;
					}

					if (arg<args.length && (args[arg].compareTo("s2") == 0)) {
						file = new RandomAccessFile(args[arg+1], "r");
						runtimeOutput.append("Loading '" + args[arg+1] + "' into slot 2.\n");
						z88.loadCardBinary(2, file);
						file.close();
						arg+=2;
						continue;
					}

					if (arg<args.length && (args[arg].compareTo("s3") == 0)) {
						runtimeOutput.append("Loading '" + args[arg+1] + "' into slot 3.\n");
						file = new RandomAccessFile(args[arg+1], "r");
						z88.loadCardBinary(3, file);
						file.close();
						arg+=2;
						continue;
					}

					if (arg<args.length && (args[arg].compareTo("debug") == 0)) {
						setDebugMode(true);
						arg++;
						continue;
					}

					if (arg<args.length && (args[arg].compareTo("initdebug") == 0)) {
						setDebugMode(true);
						file = new RandomAccessFile(args[arg+1], "r");
						JTextArea tmpOutput = commandOutput;
						commandInput.enable(false);	// don't allow command input while parsing file...
						commandOutput = null;	// don't write command output while parsing commands from file...
						String cmd = null;
						while ( (cmd = file.readLine()) != null) parseCommandLine(cmd);
						commandOutput = tmpOutput;
						commandInput.enable(true); // ready for commands from the keyboard...
						file.close();						
						runtimeOutput.append("Parsed '" + args[arg+1] + "' command file.\n");
						arg+=2;						
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
		displayCmdOutput("z - run z88 machine and break at next instruction");
		displayCmdOutput(". - Single step instruction at PC");
		displayCmdOutput("d - Disassembly at PC");
		displayCmdOutput("d [local address | extended address] - Disassemble at address");
		displayCmdOutput("wb <extended address> <byte> [<byte>] - Write byte(s) to memory");
		displayCmdOutput("m - View memory at PC");
		displayCmdOutput("m [local address | extended address] - View memory at address");
		displayCmdOutput("bp - List breakpoints");
		displayCmdOutput("bl - Display Blink register contents");
		displayCmdOutput("bp <extended address> - Toggle stop breakpoint");
		displayCmdOutput("bpd <extended address> - Toggle display breakpoint");
		displayCmdOutput("sr - Blink: Segment Register Bank Binding");
		displayCmdOutput("r - Display current Z80 Registers");
		displayCmdOutput("f/F - Display current Z80 Flag Register");
		displayCmdOutput("cls - Clear command output area\n");
		displayCmdOutput("Registers are edited using upper case, ex. A 01 and SP 1FFE");
		displayCmdOutput("Alternate registers are specified with ', ex. A' 01 and BC' C000");
		displayCmdOutput("Flags are toggled using FZ, FC, FN, FS, FPV and FH commands or");
		displayCmdOutput("set/reset using 1 or 0 argument, eg. FZ 1 to enable Zero flag.");
	}

	private void parseCommandLine(String cmdLineText) {				
		String[] cmdLineTokens = cmdLineTokens = cmdLineText.split(" ");

		if (z80Thread != null && z80Thread.isAlive() == false) {
			z80Thread = null;	// garbage collect dead thread...
		}

		if (cmdLineTokens[0].compareTo("h") == 0 || cmdLineTokens[0].compareTo("help") == 0) {
			cmdHelp();
		}

		if (cmdLineTokens[0].compareTo("cls") == 0) {
			commandOutput.setText("");
		}

		if (cmdLineTokens[0].compareTo("run") == 0) {
			if (z80Thread == null) {
				 z80Thread = run();
			} else {
				if (z80Thread.isAlive() == true)
					displayCmdOutput("Z88 is already running.");
				else
					z80Thread = run();
			}
		}

		if (cmdLineTokens[0].compareTo("stop") == 0) {
			z88.stopZ80Execution();
		}

		if (cmdLineTokens[0].compareTo(".") == 0) {
			if (z80Thread != null && z80Thread.isAlive() == true) {
				displayCmdOutput("Z88 is already running.");
				return;
			}

			commandInput.setText(".");
			commandInput.setCaretPosition(commandInput.getDocument().getLength());
			commandInput.selectAll();
			
			z88.run(true);		// single stepping (no interrupts running)...
			displayCmdOutput(blinkStatus.dzPcStatus().toString());
		}

		if (cmdLineTokens[0].compareTo("z") == 0) {
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

			displayCmdOutput(blinkStatus.dzPcStatus().toString());
		}

		if (cmdLineTokens[0].compareTo("d") == 0) {
			dzCommandline(cmdLineTokens);
		}

		if (cmdLineTokens[0].compareTo("m") == 0) {
			viewMemory(cmdLineTokens);
		}

		if (cmdLineTokens[0].compareTo("bl") == 0) {
			blinkStatus.displayBlinkRegisters();
		}

		if (cmdLineTokens[0].compareTo("sr") == 0) {
			blinkStatus.displayBankBindings();
		}

		if (cmdLineTokens[0].compareTo("r") == 0) {
			blinkStatus.displayZ80Registers();
		}

		if (cmdLineTokens[0].compareTo("bp") == 0) {
			try {
				bpCommandline(cmdLineTokens);
			} catch (IOException e1) {
				e1.printStackTrace();
			}
		}

		if (cmdLineTokens[0].compareTo("bpd") == 0) {
			try {
				bpdCommandline(cmdLineTokens);
			} catch (IOException e1) {
				e1.printStackTrace();
			}
		}

		if (cmdLineTokens[0].compareTo("wb") == 0) {
			try {
				putByte(cmdLineTokens);
			} catch (IOException e1) {
				e1.printStackTrace();
			}
		}

		if (cmdLineTokens[0].compareToIgnoreCase("f") == 0) {
			displayCmdOutput("F=" + blinkStatus.z80Flags());
		}

		if (cmdLineTokens[0].compareTo("FZ") == 0) {
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

		if (cmdLineTokens[0].compareTo("FC") == 0) {
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

		if (cmdLineTokens[0].compareTo("FS") == 0) {
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

		if (cmdLineTokens[0].compareTo("FH") == 0) {
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

		if (cmdLineTokens[0].compareTo("FN") == 0) {
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

		if (cmdLineTokens[0].compareTo("FP") == 0) {
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

		if (cmdLineTokens[0].compareTo("A") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change A register while Z88 is running!");
					return;
				}
				z88.A(Integer.parseInt(cmdLineTokens[1], 16) & 0xFF);
			}			
			displayCmdOutput("A=" + Dz.byteToHex(z88.A(),true));
		}

		if (cmdLineTokens[0].compareTo("A'") == 0) {
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

		if (cmdLineTokens[0].compareTo("B") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change B register while Z88 is running!");
					return;
				}
				z88.B(Integer.parseInt(cmdLineTokens[1], 16) & 0xFF);
			}			
			displayCmdOutput("B=" + Dz.byteToHex(z88.B(),true));
		}

		if (cmdLineTokens[0].compareTo("C") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change C register while Z88 is running!");
					return;
				}
				z88.C(Integer.parseInt(cmdLineTokens[1], 16) & 0xFF);
			}			
			displayCmdOutput("C=" + Dz.byteToHex(z88.C(),true));
		}

		if (cmdLineTokens[0].compareTo("B'") == 0) {
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

		if (cmdLineTokens[0].compareTo("C'") == 0) {
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

		if (cmdLineTokens[0].compareTo("BC") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change BC register while Z88 is running!");
					return;
				}
				z88.BC(Integer.parseInt(cmdLineTokens[1], 16) & 0xFFFF);
			}			
			displayCmdOutput("BC=" + Dz.addrToHex(z88.BC(),true));
		}

		if (cmdLineTokens[0].compareTo("BC'") == 0) {
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

		if (cmdLineTokens[0].compareTo("D") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change D register while Z88 is running!");
					return;
				}
				z88.D(Integer.parseInt(cmdLineTokens[1], 16) & 0xFF);
			}			
			displayCmdOutput("D=" + Dz.byteToHex(z88.D(),true));
		}

		if (cmdLineTokens[0].compareTo("E") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change E register while Z88 is running!");
					return;
				}
				z88.E(Integer.parseInt(cmdLineTokens[1], 16) & 0xFF);
			}			
			displayCmdOutput("E=" + Dz.byteToHex(z88.E(),true));
		}

		if (cmdLineTokens[0].compareTo("D'") == 0) {
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

		if (cmdLineTokens[0].compareTo("E'") == 0) {
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

		if (cmdLineTokens[0].compareTo("DE") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change DE register while Z88 is running!");
					return;
				}
				z88.DE(Integer.parseInt(cmdLineTokens[1], 16) & 0xFFFF);
			}			
			displayCmdOutput("DE=" + Dz.addrToHex(z88.DE(),true));
		}
		
		if (cmdLineTokens[0].compareTo("DE'") == 0) {
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

		if (cmdLineTokens[0].compareTo("H") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change H register while Z88 is running!");
					return;
				}
				z88.H(Integer.parseInt(cmdLineTokens[1], 16) & 0xFF);
			}			
			displayCmdOutput("H=" + Dz.byteToHex(z88.H(),true));
		}

		if (cmdLineTokens[0].compareTo("L") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change L register while Z88 is running!");
					return;
				}
				z88.L(Integer.parseInt(cmdLineTokens[1], 16) & 0xFF);
			}			
			displayCmdOutput("L=" + Dz.byteToHex(z88.L(),true));
		}

		if (cmdLineTokens[0].compareTo("H'") == 0) {
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

		if (cmdLineTokens[0].compareTo("L'") == 0) {
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

		if (cmdLineTokens[0].compareTo("HL") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change HL register while Z88 is running!");
					return;
				}
				z88.HL(Integer.parseInt(cmdLineTokens[1], 16) & 0xFFFF);
			}			
			displayCmdOutput("HL=" + Dz.addrToHex(z88.HL(),true));
		}

		if (cmdLineTokens[0].compareTo("HL'") == 0) {
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

		if (cmdLineTokens[0].compareTo("IX") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change IX register while Z88 is running!");
					return;
				}
				z88.IX(Integer.parseInt(cmdLineTokens[1], 16) & 0xFFFF);
			}			
			displayCmdOutput("IX=" + Dz.addrToHex(z88.IX(),true));
		}

		if (cmdLineTokens[0].compareTo("IY") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change IY register while Z88 is running!");
					return;
				}
				z88.IY(Integer.parseInt(cmdLineTokens[1], 16) & 0xFFFF);
			}			
			displayCmdOutput("IY=" + Dz.addrToHex(z88.IY(),true));
		}

		if (cmdLineTokens[0].compareTo("SP") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change SP register while Z88 is running!");
					return;
				}
				z88.SP(Integer.parseInt(cmdLineTokens[1], 16) & 0xFFFF);
			}			
			displayCmdOutput("SP=" + Dz.addrToHex(z88.SP(),true));
		}

		if (cmdLineTokens[0].compareTo("PC") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z80Thread != null && z80Thread.isAlive() == true) {
					displayCmdOutput("Cannot change PC register while Z88 is running!");
					return;
				}
				z88.PC(Integer.parseInt(cmdLineTokens[1], 16) & 0xFFFF);
			}			
			displayCmdOutput("PC=" + Dz.addrToHex(z88.PC(),true));
		}
		
		if (cmdLineTokens[0].compareTo("exit") == 0) {
			System.exit(0);
		}		
	}

	private void bpCommandline(String[] cmdLineTokens) throws IOException {
		if (cmdLineTokens.length == 2) {
			if (z80Thread != null && z80Thread.isAlive() == true) {
				displayCmdOutput("Breakpoints cannot be edited while Z88 is running.");
				return;
			} else {
				int bpAddress = Integer.parseInt(cmdLineTokens[1], 16);
				breakp.toggleBreakpoint(bpAddress);
				displayCmdOutput(breakp.listBreakpoints());
			}
		}

		if (cmdLineTokens.length == 1) {
			// no arguments, use PC in current bank binding
			displayCmdOutput(breakp.listBreakpoints());
		}
	}

	private void bpdCommandline(String[] cmdLineTokens) throws IOException {
		if (cmdLineTokens.length == 2) {
			if (z80Thread != null && z80Thread.isAlive() == true) {
				displayCmdOutput("Display Breakpoints cannot be edited while Z88 is running.");
				return;
			} else {
				int bpAddress = Integer.parseInt(cmdLineTokens[1], 16);
				breakp.toggleBreakpoint(bpAddress, false);
				displayCmdOutput(breakp.listBreakpoints());
			}
		}

		if (cmdLineTokens.length == 1) {
			// no arguments, use PC in current bank binding
			displayCmdOutput(breakp.listBreakpoints());
		}
	}

	private void dzCommandline(String[] cmdLineTokens) {
		int dzAddr = 0, dzBank = 0;
		StringBuffer dzLine = new StringBuffer(64);

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
				displayCmdOutput("Illegal argument.");
				return;
			}
		}

		for (int dzLines = 0;  dzLines < 16; dzLines++) {
			dzAddr = dz.getInstrAscii(dzLine, dzAddr, dzBank, true);
			dzAddr &= 0xFFFF;
			displayCmdOutput(Dz.byteToHex(dzBank,false) + dzLine);
		}

		commandInput.setText("d " + Dz.byteToHex(dzBank,false) + Dz.addrToHex(dzAddr,false));
		commandInput.setCaretPosition(commandInput.getDocument().getLength());
		commandInput.selectAll();
	}


	private int getMemoryAscii(StringBuffer memLine, int memAddr, int memBank) {
		int memHex, memAscii;

		memLine.delete(0,255);
		memLine.append(Dz.byteToHex(memBank, false) + Dz.addrToHex(memAddr,true)).append("  ");
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
		int memAddr = 0, memBank = 0;
		StringBuffer memLine = new StringBuffer(256);

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
				displayCmdOutput("Illegal argument.");
				return;
			}
		}

		for (int memLines = 0;  memLines < 16; memLines++) {
			memAddr = getMemoryAscii(memLine, memAddr, memBank);
			memAddr &= 0xFFFF;
			displayCmdOutput(memLine.toString());
		}

		commandInput.setText("m " + Dz.byteToHex(memBank,false) + Dz.addrToHex(memAddr,false));
		commandInput.setCaretPosition(commandInput.getDocument().getLength());		
		commandInput.selectAll();
	}

	public void bootZ88Rom() {
		z80Thread = run();
	}

	private Thread run() {
		runtimeOutput.append("Z88 virtual machine was started.\n");

		Thread thread = new Thread() {
			public void run() {

				if (breakp.isStoppable(z88.decodeLocalAddress(z88.PC())) == true) {
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
					commandInput.setText(prevCmd);
					commandInput.setCaretPosition(commandInput.getDocument().getLength());
					commandInput.selectAll();
				}
				break;
								
			case KeyEvent.VK_DOWN:
				// replace current contents of command line with next 
				// input from command history and remember new position in list. 
				String nextCmd = cmdList.browseNextCommand();
				if (nextCmd != null) {
					commandInput.setText(nextCmd);
					commandInput.setCaretPosition(commandInput.getDocument().getLength());
					commandInput.selectAll();
				}
				break;				
		}	
	}

	public void keyReleased(KeyEvent arg0) {
	}

	public void keyTyped(KeyEvent arg0) {
	}
}
