/*
 * OZvm.java
 * This	file is	part of	OZvm.
 *
 * OZvm	is free	software; you can redistribute it and/or modify	it under the terms of the
 * GNU General Public License as published by the Free Software	Foundation;
 * either version 2, or	(at your option) any later version.
 * OZvm	is distributed in the hope that	it will	be useful, but WITHOUT ANY WARRANTY;
 * without even	the implied warranty of	MERCHANTABILITY	or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * You should have received a copy of the GNU General Public License along with	OZvm;
 * see the file	COPYING. If not, write to the
 * Free	Software Foundation, Inc., 59 Temple Place - Suite 330,	Boston,	MA 02111-1307, USA.
 *
 * @author <A HREF="mailto:gbs@users.sourceforge.net">Gunther Strube</A>
 * $Id$
 *
 */

package	net.sourceforge.z88;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.RandomAccessFile;

import net.sourceforge.z88.filecard.FileArea;
import net.sourceforge.z88.filecard.FileAreaExhaustedException;
import net.sourceforge.z88.filecard.FileAreaNotFoundException;

/**
 * Main	entry of the Z88 virtual machine.
 *
 */
public class OZvm {

	private static final class singletonContainer {
		static final OZvm singleton = new OZvm();  
	}
	
	public static OZvm getInstance() {
		return singletonContainer.singleton;
	}
	
	public static final String VERSION = "0.5.dev.2";
	public static boolean debugMode = false;

	private	Blink z88 = null;
	private	Memory memory =	null;
	private CommandLine cmdLine = null;

	private OZvm() {
		z88 = Blink.getInstance();
		memory = Memory.getInstance();
		Z88display.getInstance().start();
	}

	/**
	 * Parse boot time operating system shell command line arguments
	 * 
	 * @param args
	 * @return
	 */
	public boolean boot(String[] args) {
		RandomAccessFile file;
		boolean	loadedRom = false;
		boolean	ramSlot0 = false;
		int ramSizeArg = 0, eprSizeArg = 0;

		try {
			if (args.length	>= 1) {
				int arg	= 0;
				while (arg<args.length)	{
					if ( args[arg].compareTo("ram0") != 0 &	args[arg].compareTo("ram1") != 0 &
						 args[arg].compareTo("ram2") !=	0 & args[arg].compareTo("ram3")	!= 0 &
						 args[arg].compareTo("epr1") !=	0 & args[arg].compareTo("epr2")	!= 0 & args[arg].compareTo("epr3") != 0	&
						 args[arg].compareTo("fcd1") !=	0 & args[arg].compareTo("fcd2")	!= 0 & args[arg].compareTo("fcd3") != 0	&
						 args[arg].compareTo("crd1") !=	0 & args[arg].compareTo("crd2")	!= 0 & args[arg].compareTo("crd3") != 0	&
						 args[arg].compareTo("s1") != 0	& args[arg].compareTo("s2") != 0 & args[arg].compareTo("s3") !=	0 &
						 args[arg].compareTo("kbl") != 0 & args[arg].compareTo("debug")	!= 0 &
						 args[arg].compareTo("initdebug") != 0)	{
						Gui.displayRtmMessage("Loading '" + args[0] + "' into ROM space	in slot	0.");
						file = new RandomAccessFile(args[0], "r");
						memory.loadRomBinary(file);
						file.close();
						loadedRom = true;
						arg++;
					}

					if (arg<args.length && (args[arg].startsWith("ram") == true)) {
						int ramSlotNumber = args[arg].charAt(3)	- 48;
						ramSizeArg = Integer.parseInt(args[arg+1], 10);
						if (ramSlotNumber == 0)	{
							if ((ramSizeArg	<32) | (ramSizeArg>512)) {
								Gui.displayRtmMessage("Only 32K-512K RAM Card size allowed in slot " + ramSlotNumber);
								return false;
							}
						} else {
							if ((ramSizeArg<32) | (ramSizeArg>1024)) {
								Gui.displayRtmMessage("Only 32K-1024K RAM Card size allowed in slot " +	ramSlotNumber);
								return false;
							}
						}
						memory.insertRamCard(ramSizeArg	* 1024,	ramSlotNumber);	// RAM Card specified for slot x...
						if (ramSlotNumber == 0)	ramSlot0 = true;
						Gui.displayRtmMessage("Inserted	" + ramSizeArg + "K RAM	Card in	slot " + ramSlotNumber);

						arg+=2;
						continue;
					}

					if (arg<args.length && (args[arg].startsWith("epr") == true)) {
						int eprSlotNumber = args[arg].charAt(3)	- 48;
						eprSizeArg = Integer.parseInt(args[arg+1], 10);
						if (memory.insertEprCard(eprSlotNumber,	eprSizeArg, args[arg+2]) == true) {
							String insertEprMsg = "Inserted	" + eprSlotNumber + " set to " + eprSizeArg + "K.";
							if (args[arg+2].compareToIgnoreCase("27C") == 0) insertEprMsg =	"Inserted " + eprSizeArg + "K UV Eprom Card in slot " +	eprSlotNumber;
							if (args[arg+2].compareToIgnoreCase("28F") == 0) insertEprMsg =	"Inserted " + eprSizeArg + "K Intel Flash Card in slot " + eprSlotNumber;
							if (args[arg+2].compareToIgnoreCase("29F") == 0) insertEprMsg =	"Inserted " + eprSizeArg + "K Amd Flash	Card in	slot " + eprSlotNumber;
							Gui.displayRtmMessage(insertEprMsg);
						} else
							Gui.displayRtmMessage("Eprom Card size/type configuration is illegal.");
						arg+=3;
						continue;
					}

					if (arg<args.length && (args[arg].startsWith("fcd") == true)) {
						int eprSlotNumber = args[arg].charAt(3)	- 48;
						eprSizeArg = Integer.parseInt(args[arg+1], 10);
						if (memory.insertFileEprCard(eprSlotNumber, eprSizeArg,	args[arg+2]) ==	true) {
							String insertEprMsg = "Inserted	" + eprSlotNumber + " set to " + eprSizeArg + "K.";
							if (args[arg+2].compareToIgnoreCase("27C") == 0) insertEprMsg =	"Inserted " + eprSizeArg + "K UV File Eprom Card in slot " + eprSlotNumber;
							if (args[arg+2].compareToIgnoreCase("28F") == 0) insertEprMsg =	"Inserted " + eprSizeArg + "K Intel File Flash Card in slot " +	eprSlotNumber;
							if (args[arg+2].compareToIgnoreCase("29F") == 0) insertEprMsg =	"Inserted " + eprSizeArg + "K Amd File Flash Card in slot " + eprSlotNumber;
							Gui.displayRtmMessage(insertEprMsg);
						} else
							Gui.displayRtmMessage("Eprom File Card size/type configuration is illegal.");						
						arg+=3;
						
						if (arg < args.length) {
							FileArea fa = new FileArea(eprSlotNumber);
							// optional: import files from host system into file area.
							while(args[arg].compareToIgnoreCase("-d") == 0 | args[arg].compareToIgnoreCase("-f") == 0) {
								if (args[arg].compareToIgnoreCase("-f") == 0) fa.importHostFile(new File(args[arg+1]));
								if (args[arg].compareToIgnoreCase("-d") == 0) fa.importHostFiles(new File(args[arg+1]));
								arg+=2;
								if (arg >= args.length) break;
							}
						}
						continue;
					}

					if (arg<args.length && (args[arg].startsWith("crd") == true)) {
						int eprSlotNumber = args[arg].charAt(3)	- 48;
						eprSizeArg = Integer.parseInt(args[arg+1], 10);
						if (args[arg+3].compareToIgnoreCase("-b") == 0) {
							memory.loadBankFilesOnCard(eprSlotNumber, eprSizeArg, args[arg+2], args[arg+4]);
							arg+=5;
						} else {
							file = new RandomAccessFile(args[arg+3], "r");
							memory.loadImageOnCard(eprSlotNumber, eprSizeArg, args[arg+2], file);
							String insertEprMsg = "";
							if (args[arg+2].compareToIgnoreCase("27C") == 0) insertEprMsg =	"Loaded	file image '" +	args[arg+3] + "' on " +	eprSizeArg + "K	UV Eprom Card in slot "	+ eprSlotNumber;
							if (args[arg+2].compareToIgnoreCase("28F") == 0) insertEprMsg =	"Loaded	file image '" +	args[arg+3] + "' on " +	eprSizeArg + "K	Intel Flash Card in slot " + eprSlotNumber;
							if (args[arg+2].compareToIgnoreCase("29F") == 0) insertEprMsg =	"Loaded	file image '" +	args[arg+3] + "' on " +	eprSizeArg + "K	Amd Flash Card in slot " + eprSlotNumber;
							Gui.displayRtmMessage(insertEprMsg);
							arg+=4;
						}
						continue;
					}

					if (arg<args.length && ( args[arg].compareTo("s1") == 0	| args[arg].compareTo("s2") == 0 | args[arg].compareTo("s3") ==	0)) {
						int slotNumber = Integer.parseInt(args[arg].substring(1));
						String crdType = "27C";
						if (args[arg+1].compareToIgnoreCase("-t") == 0)	{
							// Optional type argument
							crdType	= args[arg+2];
							arg += 3;
						} else {
							arg++;
						}
						file = new RandomAccessFile(args[arg], "r");
						Gui.displayRtmMessage("Loading '" + args[arg] +	"' into	slot " + slotNumber + ".");
						memory.loadCardBinary(slotNumber, crdType, file);
						file.close();
						arg++;
						continue;
					}

					if (arg<args.length && (args[arg].compareTo("debug") ==	0)) {
						debugMode = true;
						cmdLine = new CommandLine();
						arg++;
						continue;
					}

					if (arg<args.length && (args[arg].compareTo("initdebug") == 0))	{
						debugMode = true;
						cmdLine = new CommandLine();

						file = new RandomAccessFile(args[arg+1], "r");
						Gui.getInstance().getCmdLineInputArea().setEnabled(false);	// don't allow command input while parsing file...
						String cmd = null;
						while (	(cmd = file.readLine())	!= null) {
							cmdLine.parseCommandLine(cmd);
							Thread.yield();
						}
						Gui.getInstance().getCmdLineInputArea().setEnabled(true); // ready for commands from the keyboard...
						file.close();
						Gui.displayRtmMessage("Parsed '" + args[arg+1] + "' command file.");

						arg+=2;
						continue;
					}

					if (arg<args.length && (args[arg].compareTo("kbl") == 0)) {
						if (args[arg+1].compareToIgnoreCase("uk") == 0 || args[arg+1].compareToIgnoreCase("en")	== 0) {
							Z88Keyboard.getInstance().setKeyboardLayout(Z88Keyboard.COUNTRY_EN);
							Gui.displayRtmMessage("Using English (UK) keyboard layout.");
						}
						if (args[arg+1].compareTo("fr")	== 0) {
							Z88Keyboard.getInstance().setKeyboardLayout(Z88Keyboard.COUNTRY_FR);
							Gui.displayRtmMessage("Using French keyboard layout.");
						}
						if (args[arg+1].compareTo("dk")	== 0) {
							Z88Keyboard.getInstance().setKeyboardLayout(Z88Keyboard.COUNTRY_DK);
							Gui.displayRtmMessage("Using Danish keyboard layout.");
						}
						if (args[arg+1].compareTo("se")	== 0) {
							Z88Keyboard.getInstance().setKeyboardLayout(Z88Keyboard.COUNTRY_SE);
							Gui.displayRtmMessage("Using Swedish keyboard layout.");
						}
						if (args[arg+1].compareTo("fi")	== 0) {
							Z88Keyboard.getInstance().setKeyboardLayout(Z88Keyboard.COUNTRY_FI);
							Gui.displayRtmMessage("Using Finish keyboard layout.");
						}
						arg+=2;
						continue;
					}
				}
			}

			if (loadedRom == false)	{
				Gui.displayRtmMessage("No external ROM image specified,	using default Z88.rom (V4.0 UK)");
				memory.loadRomBinary(z88.getClass().getResource("/Z88.rom"));
			}

			if (ramSlot0 ==	false) {
				Gui.displayRtmMessage("RAM0 set	to default 32K.");
				memory.insertRamCard(32	* 1024,	0);	// no RAM specified for	slot 0,	set to default 32K RAM...
			}
			return true;

		} catch	(FileNotFoundException e) {
			System.out.println("Couldn't load ROM/EPROM image:\n" +	e.getMessage() + "\nOzvm terminated.");
			return false;
		} catch	(IOException e)	{
			System.out.println("Problem with ROM/EPROM image or I/O:\n" + e.getMessage() + "\nOzvm terminated.");
			return false;
		} catch (FileAreaNotFoundException e) {
			System.out.println("Problem with importing file into File Card:\n" + e.getMessage() + "\nOzvm terminated.");
			return false;
		} catch (FileAreaExhaustedException e) {
			System.out.println("Problem with importing file into File Card:\n" + e.getMessage() + "\nOzvm terminated.");
			return false;
		}
	}

	/**
	 * Execute a Z80 thread.
	 * 
	 * @param oneStopBreakpoint
	 * @return
	 */
	public Thread runZ80Engine(final int oneStopBreakpoint) {
		Gui.displayRtmMessage("Z88 virtual machine was started.");
		System.gc(); //	try to garbage collect...
		
		Thread thread =	new Thread() {
			public void run() {
				Breakpoints breakPointManager = Breakpoints.getInstance();

				if (breakPointManager.isStoppable(z88.decodeLocalAddress(z88.PC())) == true) {
					// we need to use single stepping mode to
					// step	past the break point at	current	instruction
					z88.singleStepZ80();
				}
				// restore (patch) breakpoints into code
				breakPointManager.installBreakpoints();
				z88.startInterrupts(); // enable Z80/Z88 core interrupts
				Z88display.getInstance().grabFocus(); // default keyboard input	focus to the Z88
				z88.execZ80();
				// execute Z80 code at full speed until	breakpoint is encountered...
				// (or F5 emergency break is used!)
				z88.stopInterrupts();
				breakPointManager.clearBreakpoints();

				if (oneStopBreakpoint != -1)
					breakPointManager.toggleBreakpoint(oneStopBreakpoint); // remove the temporary breakpoint (reached, or not)

				if (cmdLine != null) {
					cmdLine.displayCmdOutput(Z88Info.dzPcStatus(z88.PC()));
					Gui.getInstance().getCmdLineInputArea().setText(Dz.getNextStepCommand());
					Gui.getInstance().getCmdLineInputArea().setCaretPosition(Gui.getInstance().getCmdLineInputArea().getDocument().getLength());
					Gui.getInstance().getCmdLineInputArea().selectAll();
					Gui.getInstance().getCmdLineInputArea().grabFocus();	// Z88 is stopped, get focus to	debug command line.
				}
			}
		};

		thread.setPriority(Thread.NORM_PRIORITY	- 1); // execute the Z80 engine	just below normal thread priority...
		thread.start();
		Thread.yield();	// the command line is not that	important right	now...

		return thread;
	}


	/**
	 * Just	run the	virtual	machine	if no debugging	was enabled.
	 * (No breakpoints are defined by default)
	 */
	public void bootZ88Rom() {
		runZ80Engine(-1);
	}
}
