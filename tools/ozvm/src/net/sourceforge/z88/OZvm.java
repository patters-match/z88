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

import java.awt.DisplayMode;
import java.awt.GraphicsDevice;
import java.awt.GraphicsEnvironment;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.net.JarURLConnection;

import javax.swing.UIManager;

import net.sourceforge.z88.datastructures.SlotInfo;
import net.sourceforge.z88.filecard.FileArea;
import net.sourceforge.z88.filecard.FileAreaExhaustedException;
import net.sourceforge.z88.filecard.FileAreaNotFoundException;

/**
 * Main	entry of the Z88 virtual machine.
 */
public class OZvm {

	private static final class singletonContainer {
		static final OZvm singleton = new OZvm();  
	}
	
	public static OZvm getInstance() {
		return singletonContainer.singleton;
	}

	/** default boot snapshot filename */
	public static final String defaultVmFile = System.getProperty("user.dir")+ File.separator + "boot.z88";

	/** current release version string */
	public static final String VERSION = "0.5.dev.10";

	/** (default) boot the virtual machine, once it has been loaded */
	private boolean autoRun;

	private RtmMessageGui rtmMsgGui;
	
	/** Graphics device used for full screen mode */
	private GraphicsDevice device;
	
	/** Display mode for full screen (640x480) */
	private DisplayMode displayModeFullScreen;
	
	private String guiKbLayout;
	
	private	Blink blink;
	private	Memory memory;
	private CommandLine cmdLine;	
	private Gui gui;

	private boolean debugMode;

	private OZvm() {
		GraphicsEnvironment environment = GraphicsEnvironment.getLocalGraphicsEnvironment();
        device = environment.getDefaultScreenDevice();
		
        // get a display mode for 640x480, 16bit colour depth, used for full screen display
        displayModeFullScreen = new DisplayMode(640, 480, 16, DisplayMode.REFRESH_RATE_UNKNOWN);
    
        autoRun = true; // default autorun...
        
        // default keyboard layout is UK (for english 4.0 ROM)
        guiKbLayout = "uk";
        
		blink = Z88.getInstance().getBlink();
		memory = Z88.getInstance().getMemory();
		Z88.getInstance().getDisplay().start();
		
		debugMode = false;
	}

	public boolean getAutorunStatus() {
		return autoRun;
	}

	/** 
	 * Get a reference to the main graphical user interface.
	 * 
	 * @return
	 */
	public Gui getGui() {
		return gui;
	}
		
	public boolean isFullScreenSupported() {
		return device.isFullScreenSupported();
	}
	
    /**
     * Enters full screen mode (if system allows it) and change the 
     * display mode to 640x480 in 16bit colour depth. OZvm stays in
     * full screen mode until aborted (operating system returns
     * to window mode automatically when OZvm exits). 
     */
	public void setFullScreenMode() {	
		if (gui != null) {
			// get rid of current window mode main Gui window...
			gui.removeAll(); // release all widgets inside...
			gui.dispose(); // then remove it from the operating system view			
		}
		
		gui = new Gui(true); // new main gui for full screen mode (old object garbage collected)
	    device.setFullScreenWindow(gui);	    

	    try {
            device.setDisplayMode(displayModeFullScreen);
        }
        catch (IllegalArgumentException ex) {
            // ignore - illegal mode for this device
        }

        // finally, let's see the new stuff
	    gui.repaint();
	}
	
	/**
	 * Boot OZvm and parse operating system shell command line arguments
	 * 
	 * @param args
	 * @return
	 */
	public boolean boot(String[] args) {
		RandomAccessFile file;
		boolean	loadedRom = false;
		boolean	installedCard = false;
		boolean	loadedSnapshot = false;
		boolean	ramSlot0 = false;
		int ramSizeArg = 0, eprSizeArg = 0;

		gui = new Gui(); // instantiated but not yet displayed... 			
		
		try {
			int arg	= 0;
			while (arg<args.length)	{
				if ( 
					 args[arg].compareTo("rom") != 0 &
					 args[arg].compareTo("ram0") != 0 &	args[arg].compareTo("ram1") != 0 & 
					 args[arg].compareTo("ram2") !=	0 & args[arg].compareTo("ram3")	!= 0 &
					 args[arg].compareTo("epr1") !=	0 & args[arg].compareTo("epr2")	!= 0 & args[arg].compareTo("epr3") != 0	&
					 args[arg].compareTo("fcd1") !=	0 & args[arg].compareTo("fcd2")	!= 0 & args[arg].compareTo("fcd3") != 0	&
					 args[arg].compareTo("crd1") !=	0 & args[arg].compareTo("crd2")	!= 0 & args[arg].compareTo("crd3") != 0	&
					 args[arg].compareTo("kbl") != 0 & args[arg].compareTo("debug")	!= 0 & args[arg].compareTo("initdebug") != 0) {
					// try to install specified snapshot file
					SaveRestoreVM srVm = new SaveRestoreVM();
					String vmFileName = args[arg];
					if (vmFileName.toLowerCase().lastIndexOf(".z88") == -1)
						vmFileName += ".z88"; // '.z88' extension was missing.

					try {
						autoRun = srVm.loadSnapShot(vmFileName);
						displayRtmMessage("Snapshot successfully installed from " + vmFileName);
						gui.setWindowTitle("[" + (new File(vmFileName).getName()) + "]");
						loadedSnapshot = true;
					} catch (IOException ee) {
						// loading of snapshot failed (file not found, corrupt or not a snapshot file
						// define a default Z88 system as fall back plan.
				    	memory.setDefaultSystem();
				    	Z88.getInstance().getProcessor().reset();				
				    	blink.resetBlinkRegisters();
					}
					arg++;
				}

				if (arg<args.length && (args[arg].compareTo("rom") == 0)) {
					displayRtmMessage("Loading '" + args[arg+1] + "' into ROM space	in slot	0.");
					File romFile = new File(args[arg+1]);
					memory.loadRomBinary(romFile);
					gui.setWindowTitle("[" + (romFile.getName()) + "]");
					blink.resetBlinkRegisters();
					blink.setRAMS(memory.getBank(0));	// point at ROM bank 0
					loadedRom = true;
					arg+=2;						
				}
				
				if (arg<args.length && (args[arg].startsWith("ram") == true)) {
					int ramSlotNumber = args[arg].charAt(3)	- 48;
					ramSizeArg = Integer.parseInt(args[arg+1], 10);
					if (ramSlotNumber == 0)	{
						if ((ramSizeArg	<32) | (ramSizeArg>512)) {
							displayRtmMessage("Only 32K-512K RAM Card size allowed in slot " + ramSlotNumber);
							return false;
						}
					} else {
						if ((ramSizeArg<32) | (ramSizeArg>1024)) {
							displayRtmMessage("Only 32K-1024K RAM Card size allowed in slot " +	ramSlotNumber);
							return false;
						}
					}
					memory.insertRamCard(ramSizeArg, ramSlotNumber);	// RAM Card specified for slot x...
					if (ramSlotNumber == 0)	ramSlot0 = true;
					displayRtmMessage("Inserted	" + ramSizeArg + "K RAM	Card in	slot " + ramSlotNumber);
					installedCard = true;

					arg+=2;
					continue;
				}

				if (arg<args.length && (args[arg].startsWith("epr") == true)) {
					int eprSlotNumber = args[arg].charAt(3)	- 48;
					eprSizeArg = Integer.parseInt(args[arg+1], 10);
					String insertEprMsg = "";
					int eprType = 0;
					if (args[arg+2].compareToIgnoreCase("27C") == 0) {
						insertEprMsg =	"Inserted " + eprSizeArg + "K UV Eprom Card in slot " +	eprSlotNumber;
						eprType = SlotInfo.EpromCard;
					}
					if (args[arg+2].compareToIgnoreCase("28F") == 0) {
						insertEprMsg =	"Inserted " + eprSizeArg + "K Intel Flash Card in slot " + eprSlotNumber;
						eprType = SlotInfo.IntelFlashCard;
					}
					if (args[arg+2].compareToIgnoreCase("29F") == 0) {
						insertEprMsg =	"Inserted " + eprSizeArg + "K Amd Flash	Card in	slot " + eprSlotNumber;
						eprType = SlotInfo.AmdFlashCard;
					}
					if (memory.insertEprCard(eprSlotNumber,	eprSizeArg, eprType) == true) {
						displayRtmMessage(insertEprMsg);
						installedCard = true;
					} else
						displayRtmMessage("Eprom Card size/type configuration is illegal.");
					arg+=3;
					continue;
				}

				if (arg<args.length && (args[arg].startsWith("fcd") == true)) {
					int eprSlotNumber = args[arg].charAt(3)	- 48;
					eprSizeArg = Integer.parseInt(args[arg+1], 10);
					String insertEprMsg = "";
					int eprType = 0;
					if (args[arg+2].compareToIgnoreCase("27C") == 0) {
						insertEprMsg =	"Inserted " + eprSizeArg + "K UV Eprom Card in slot " +	eprSlotNumber;
						eprType = SlotInfo.EpromCard;
					}
					if (args[arg+2].compareToIgnoreCase("28F") == 0) {
						insertEprMsg =	"Inserted " + eprSizeArg + "K Intel Flash Card in slot " + eprSlotNumber;
						eprType = SlotInfo.IntelFlashCard;
					}
					if (args[arg+2].compareToIgnoreCase("29F") == 0) {
						insertEprMsg =	"Inserted " + eprSizeArg + "K Amd Flash	Card in	slot " + eprSlotNumber;
						eprType = SlotInfo.AmdFlashCard;
					}
					if (memory.insertFileCard(eprSlotNumber, eprSizeArg,	eprType) ==	true) {
						displayRtmMessage(insertEprMsg);
						installedCard = true;
					} else
						displayRtmMessage("Eprom File Card size/type configuration is illegal.");						
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
					String insertEprMsg = "";
					int eprType = 0;
					if (args[arg+2].compareToIgnoreCase("27C") == 0) {
						insertEprMsg =	"Loaded	file image '" +	args[arg+3] + "' on " +	eprSizeArg + "K	UV Eprom Card in slot "	+ eprSlotNumber;
						eprType = SlotInfo.EpromCard;
					}
					if (args[arg+2].compareToIgnoreCase("28F") == 0) {
						insertEprMsg =	"Loaded	file image '" +	args[arg+3] + "' on " +	eprSizeArg + "K	Intel Flash Card in slot " + eprSlotNumber;
						eprType = SlotInfo.IntelFlashCard;
					}
					if (args[arg+2].compareToIgnoreCase("29F") == 0) {
						insertEprMsg =	"Loaded	file image '" +	args[arg+3] + "' on " +	eprSizeArg + "K	Amd Flash Card in slot " + eprSlotNumber;
						eprType = SlotInfo.AmdFlashCard;
					}
					
					if (args[arg+3].compareToIgnoreCase("-b") == 0) {
						memory.loadBankFilesOnCard(eprSlotNumber, eprSizeArg, eprType, args[arg+4]);
						installedCard = true;
						arg+=5;
					} else {
						memory.loadFileImageOnCard(eprSlotNumber, eprSizeArg, eprType, new File(args[arg+3]));
						displayRtmMessage(insertEprMsg);
						installedCard = true;
						arg+=4;
					}
					continue;
				}

				if (arg<args.length && (args[arg].compareTo("debug") ==	0)) {
					autoRun = false;
					commandLine(true);
					arg++;
					continue;
				}

				if (arg<args.length && (args[arg].compareTo("initdebug") == 0))	{
					autoRun = false;
					commandLine(true);

					file = new RandomAccessFile(args[arg+1], "r");
					cmdLine.getDebugGui().getCmdLineInputArea().setEnabled(false);	// don't allow command input while parsing file...
					String cmd = null;
					while (	(cmd = file.readLine())	!= null) {
						cmdLine.parseCommandLine(cmd);
						Thread.yield();
					}
					cmdLine.getDebugGui().getCmdLineInputArea().setEnabled(true); // ready for commands from the keyboard...
					file.close();
					displayRtmMessage("Parsed '" + args[arg+1] + "' command file.");

					arg+=2;
					continue;
				}

				if (arg<args.length && (args[arg].compareTo("kbl") == 0)) {					
					if (args[arg+1].compareToIgnoreCase("uk") == 0 || args[arg+1].compareToIgnoreCase("en")	== 0) {
						guiKbLayout = "uk";
					}
					if (args[arg+1].compareTo("fr")	== 0) {
						guiKbLayout = "fr";
					}
					if (args[arg+1].compareTo("dk")	== 0) {
						guiKbLayout = "dk";
					}
					if (args[arg+1].compareTo("se")	== 0 | args[arg+1].compareTo("fi")	== 0) {
						guiKbLayout = "se";
					}
					
					arg+=2;
					continue;
				}
			}				

			// all operating system shell command options parsed,
			// if no snapshot file was specified or other resources installed, try to load the default 'boot.z88' snapshot
			if (loadedSnapshot == false & installedCard == false & loadedRom == false) {
				SaveRestoreVM srVm = new SaveRestoreVM();
				try {
					autoRun = srVm.loadSnapShot(OZvm.defaultVmFile);
					loadedSnapshot = true;
					displayRtmMessage("Snapshot successfully installed from " + OZvm.defaultVmFile);
					gui.setWindowTitle("[boot.z88]");
				} catch (IOException ee) {
					// 'boot.z88' wasn't available, or an error occurred - ignore it...
				}
			}
			
			if (loadedSnapshot == false & loadedRom == false) {
				displayRtmMessage("No external ROM image specified,	using default Z88.rom (V4.0 UK)");
				JarURLConnection jarConnection = (JarURLConnection) blink.getClass().getResource("/Z88.rom").openConnection();
				memory.loadRomBinary((int) jarConnection.getJarEntry().getSize(), jarConnection.getInputStream());
				blink.setRAMS(memory.getBank(0));	// point at ROM bank 0
			}

			if (loadedSnapshot == false && ramSlot0 == false) {
				displayRtmMessage("RAM0 set	to default 128K.");
				memory.insertRamCard(128, 0);	// no RAM specified for	slot 0,	set to default 128K RAM...
			}
/*			
			if (loadedSnapshot == false && memory.isSlotEmpty(1) == true) {
				memory.insertRamAmdCard(1);
			}
 */
		} catch	(FileNotFoundException e) {
			System.out.println("Couldn't load ROM/EPROM image:\n" +	e.getMessage());
			return false;
		} catch	(IOException e)	{
			System.out.println("Problem with ROM/EPROM image or I/O:\n" + e.getMessage());
			return false;
		} catch (FileAreaNotFoundException e) {
			System.out.println("Problem with importing file into File Card:\n" + e.getMessage());
			return false;
		} catch (FileAreaExhaustedException e) {
			System.out.println("Problem with importing file into File Card:\n" + e.getMessage());
			return false;
		}
		
		if (loadedSnapshot == false) displayDefaultGui();
		
		gui.pack(); // update the application UI
		gui.setVisible(true);		
		
		return true;
	}

	private void displayDefaultGui() {
		// default display; show Z88 Keyboard and Card Slots. Invisible runtime message window.
		gui.displayRunTimeMessagesPane(false);
		gui.displayZ88Keyboard(true);
		gui.displayZ88CardSlots(true);			

		if (guiKbLayout.compareToIgnoreCase("uk") == 0) {
			getGui().getUkLayoutMenuItem().doClick();
			displayRtmMessage("Using English (UK) keyboard layout.");
		}
		if (guiKbLayout.compareTo("fr")	== 0) {
			getGui().getFrLayoutMenuItem().doClick();
			displayRtmMessage("Using French keyboard layout.");
		}
		if (guiKbLayout.compareTo("dk")	== 0) {
			getGui().getDkLayoutMenuItem().doClick();
			displayRtmMessage("Using Danish keyboard layout.");
		}
		if (guiKbLayout.compareTo("se")	== 0) {
			getGui().getSeLayoutMenuItem().doClick();
			displayRtmMessage("Using Swedish/Finish keyboard layout.");
		}		
	}
	
	public void commandLine(boolean status) {				
		if (status == true) {
			if (getDebugMode() == true) {
				cmdLine.getDebugGui().getCmdLineInputArea().grabFocus();
			} else
				cmdLine = new CommandLine();
		} else
			cmdLine = null;
		
		setDebugMode(status);
	}
	
	public boolean getDebugMode() {
		return debugMode;
	}

	public void setDebugMode(boolean dbgMode) {
		debugMode = dbgMode;
	}
	
	public CommandLine getCommandLine() {
		return cmdLine; 
	}

	public static void displayRtmMessage(final String msg) {
		OZvm.getInstance().getRtmMsgGui().displayRtmMessage(msg);
	}
	
	/**
	 * OZvm application startup.
	 * 
	 * @param args shell command line arguments
	 */
	public static void main(String[] args) {
		try {
			UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
		} catch(Exception e1) {
			  System.out.println("Error setting cross platform LAF: " + e1);
		}
		
		OZvm ozvm = OZvm.getInstance();		
		
		if (ozvm.boot(args) == false) {
			System.out.println("Ozvm terminated.");
			System.exit(0);
		}

		if (ozvm.getAutorunStatus() == true) {
			// no debug mode, just boot the specified ROM and run the virtual Z88...
			Z88.getInstance().runZ80Engine(-1, true);
			// make sure that keyboard focus is available for Z88 (screen)
			Z88.getInstance().getDisplay().grabFocus();	 
		} else {
			ozvm.commandLine(true);
			ozvm.getCommandLine().initDebugCmdline();
		}
	}

	public RtmMessageGui getRtmMsgGui() {
		if (rtmMsgGui == null)
			rtmMsgGui = new RtmMessageGui();
		
		return rtmMsgGui;
	}
}
