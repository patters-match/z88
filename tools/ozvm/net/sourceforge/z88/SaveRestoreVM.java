/*
 * SaveRestoreVM.java
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

import java.awt.image.BufferedImage;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.*;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;
import java.util.zip.ZipOutputStream;
import javax.imageio.ImageIO;
import javax.swing.filechooser.FileFilter;

import net.sourceforge.z88.datastructures.SlotInfo;
import net.sourceforge.z88.screen.Z88display;

/**
 * Management of saving and resuming a OZvm machine instance.
 * The machine state is saved in a Zip file containing a combination 
 * of a properties file, and a memory dump of current slot contents, 
 * saved as slotX.ram or slotX.epr, depending of the type. 
 */
public class SaveRestoreVM {

	private Blink blink;
    private Z80Processor z80;
    private Memory memory;

	/** Constructor */
	public SaveRestoreVM() {
		z80 = Z88.getInstance().getProcessor();
		memory = Z88.getInstance().getMemory();
	}

	/**
	 * Preserve state of the Z80 CPU registers.
	 */
	private void storeZ80Regs(Properties properties) {
	    properties.setProperty("AF", Dz.addrToHex(z80.AF(),false));
	    properties.setProperty("BC", Dz.addrToHex(z80.BC(),false));
	    properties.setProperty("DE", Dz.addrToHex(z80.DE(),false));
	    properties.setProperty("HL", Dz.addrToHex(z80.HL(),false));
	    properties.setProperty("IX", Dz.addrToHex(z80.IX(),false));
	    properties.setProperty("IY", Dz.addrToHex(z80.IY(),false));
	    properties.setProperty("PC", Dz.addrToHex(z80.PC(),false));
	    properties.setProperty("SP", Dz.addrToHex(z80.SP(),false));
	    z80.ex_af_af();
	    properties.setProperty("_AF", Dz.addrToHex(z80.AF(),false));
	    z80.ex_af_af();
	    z80.exx();
	    properties.setProperty("_BC", Dz.addrToHex(z80.BC(),false));
	    properties.setProperty("_DE", Dz.addrToHex(z80.DE(),false));
	    properties.setProperty("_HL", Dz.addrToHex(z80.HL(),false));
	    z80.exx();
	    properties.setProperty("I", Dz.byteToHex(z80.I(),false));
	    properties.setProperty("R", Dz.byteToHex(z80.R(),false));
	    properties.setProperty("IM", Dz.byteToHex(z80.IM(), false));
	    properties.setProperty("IFF1", Boolean.toString(z80.IFF1()));
	    properties.setProperty("IFF2", Boolean.toString(z80.IFF2()));	    
	}

	/**
	 * Restore register values into the Z80 engine.
	 */
	private void loadZ80Regs(Properties properties) {
		z80.AF(Integer.parseInt(properties.getProperty("AF"), 16));
		z80.BC(Integer.parseInt(properties.getProperty("BC"), 16));
		z80.DE(Integer.parseInt(properties.getProperty("DE"), 16));		
		z80.HL(Integer.parseInt(properties.getProperty("HL"), 16));
		z80.IX(Integer.parseInt(properties.getProperty("IX"), 16));
		z80.IY(Integer.parseInt(properties.getProperty("IY"), 16));
		z80.PC(Integer.parseInt(properties.getProperty("PC"), 16));
		z80.SP(Integer.parseInt(properties.getProperty("SP"), 16));		
	    z80.ex_af_af();
		z80.AF(Integer.parseInt(properties.getProperty("_AF"), 16));
	    z80.ex_af_af();
	    z80.exx();
		z80.BC(Integer.parseInt(properties.getProperty("_BC"), 16));
		z80.DE(Integer.parseInt(properties.getProperty("_DE"), 16));		
		z80.HL(Integer.parseInt(properties.getProperty("_HL"), 16));
	    z80.exx();
		z80.I(Integer.parseInt(properties.getProperty("I"), 16));
		z80.R(Integer.parseInt(properties.getProperty("R"), 16));
		z80.IM(Integer.parseInt(properties.getProperty("IM"), 16));
		z80.IFF1(Boolean.valueOf(properties.getProperty("IFF1")).booleanValue());
		z80.IFF2(Boolean.valueOf(properties.getProperty("IFF2")).booleanValue());		
	}
	
	/**
	 * Restore register values into the Blink hardware.
	 */
	private void storeBlinkRegs(Properties properties) {
		properties.setProperty("PB0", Dz.addrToHex(blink.getBlinkPb0(),false));
		properties.setProperty("PB1", Dz.addrToHex(blink.getBlinkPb1(),false));
		properties.setProperty("PB2", Dz.addrToHex(blink.getBlinkPb2(),false));
		properties.setProperty("PB3", Dz.addrToHex(blink.getBlinkPb3(),false));
		properties.setProperty("SBR", Dz.addrToHex(blink.getBlinkSbr(),false));
		
		properties.setProperty("COM", Dz.byteToHex(blink.getBlinkCom(),false));
		properties.setProperty("INT", Dz.byteToHex(blink.getBlinkInt(),false));
		properties.setProperty("STA", Dz.byteToHex(blink.getBlinkSta(),false));
		
		// KBD,ACK,TACK is not preserved (not needed)
		// EPR not yet implemented

		properties.setProperty("TMK", Dz.byteToHex(blink.getBlinkTmk(),false));
		properties.setProperty("TSTA", Dz.byteToHex(blink.getBlinkTsta(),false));
		
		properties.setProperty("SR0", Dz.byteToHex(blink.getSegmentBank(0),false));
		properties.setProperty("SR1", Dz.byteToHex(blink.getSegmentBank(1),false));
		properties.setProperty("SR2", Dz.byteToHex(blink.getSegmentBank(2),false));
		properties.setProperty("SR3", Dz.byteToHex(blink.getSegmentBank(3),false));
		
		properties.setProperty("TIM0", Dz.byteToHex(blink.getBlinkTim0(),false));
		properties.setProperty("TIM1", Dz.byteToHex(blink.getBlinkTim1(),false));
		properties.setProperty("TIM2", Dz.byteToHex(blink.getBlinkTim2(),false));
		properties.setProperty("TIM3", Dz.byteToHex(blink.getBlinkTim3(),false));
		properties.setProperty("TIM4", Dz.byteToHex(blink.getBlinkTim4(),false));
						
		// UART Registers not yet implemented		
	}
	
	/**
	 * Restore state of Blink Hardware Registers.
	 */
	private void loadBlinkRegs(Properties properties) {
		blink.setBlinkPb0(Integer.parseInt(properties.getProperty("PB0"), 16));
		blink.setBlinkPb1(Integer.parseInt(properties.getProperty("PB1"), 16));
		blink.setBlinkPb2(Integer.parseInt(properties.getProperty("PB2"), 16));
		blink.setBlinkPb3(Integer.parseInt(properties.getProperty("PB3"), 16));
		blink.setBlinkSbr(Integer.parseInt(properties.getProperty("SBR"), 16));
		
		blink.setBlinkCom(Integer.parseInt(properties.getProperty("COM"), 16));
		blink.setBlinkInt(Integer.parseInt(properties.getProperty("INT"), 16));
		blink.setBlinkSta(Integer.parseInt(properties.getProperty("STA"), 16));
		
		// KBD,ACK,TACK is not preserved (not needed)
		// EPR not yet implemented

		blink.setBlinkTmk(Integer.parseInt(properties.getProperty("TMK"), 16));
		blink.setBlinkTsta(Integer.parseInt(properties.getProperty("TSTA"), 16));
		
		blink.setSegmentBank(0, Integer.parseInt(properties.getProperty("SR0"), 16));		
		blink.setSegmentBank(1, Integer.parseInt(properties.getProperty("SR1"), 16));
		blink.setSegmentBank(2, Integer.parseInt(properties.getProperty("SR2"), 16));
		blink.setSegmentBank(3, Integer.parseInt(properties.getProperty("SR3"), 16));
		
		blink.setBlinkTim0(Integer.parseInt(properties.getProperty("TIM0"), 16));
		blink.setBlinkTim1(Integer.parseInt(properties.getProperty("TIM1"), 16));
		blink.setBlinkTim2(Integer.parseInt(properties.getProperty("TIM2"), 16));
		blink.setBlinkTim3(Integer.parseInt(properties.getProperty("TIM3"), 16));
		blink.setBlinkTim4(Integer.parseInt(properties.getProperty("TIM4"), 16));
		
		// UART Registers not yet implemented		
	}

	/**
	 * Fetch the 'Breakpoints' entry from the properties collection, which is
	 * a comma separated list of breakpoint adresses and install them into
	 * the breakpoint container (part of Blink).
	 * 
	 * @param properties
	 */
	private void loadBreakpoints(Properties properties) {
		Breakpoints bp = z80.getBreakpoints(); 

		// remove current breakpoints before loading a new set 
		// from the snapshot (the old breakpoints doesn't theoretically
		// match the memory of another snapshot)
		bp.removeBreakPoints();
		
		String breakpoints = properties.getProperty("Breakpoints");
		if (breakpoints == null)
			return;
		
		
		String[] breakpointList = breakpoints.split(",");
		for(int l=0; l<breakpointList.length; l++) {
			String breakpointAscii = breakpointList[l];
			
			if (breakpointAscii != null) {
				if (breakpointAscii.length() > 0) {
					if (breakpointAscii.startsWith("[d]") == true) {
						// remove display breakpoint indicator
						breakpointAscii = breakpointAscii.substring(3);
						bp.toggleBreakpoint(Integer.parseInt(breakpointAscii, 16), false);
					} else {
						bp.toggleBreakpoint(Integer.parseInt(breakpointAscii, 16));
					}				
				}
			}
		}
	}
	
	/**
	 * Save contents of virtual machine into a snapshot file (Zip file).
	 *
	 * @param autorun 
	 * @param snapshotFileName
	 * @throws IOException
	 */
	public void storeSnapShot(String snapshotFileName, boolean autorun) throws IOException {
		String propfilename = System.getProperty("user.dir") + File.separator + "snapshot.settings";
		String snapshotPngFile = System.getProperty("user.dir") + File.separator + "snapshot.png";
		Properties properties = new Properties();
	
		if (snapshotFileName.toLowerCase().lastIndexOf(".z88") == -1)
			snapshotFileName += ".z88"; // '.z88' extension is missing.
		
        // save Z80 & Blink registers to properties collection
        storeZ80Regs(properties);
        storeBlinkRegs(properties);
        
    	ZipOutputStream zipOut = new ZipOutputStream(new FileOutputStream(snapshotFileName));
    	zipOut.setLevel(9); // compress contents as much as possible...
    	
        // save a copy of the current screen...
        BufferedImage bi = Z88.getInstance().getDisplay().getScreenFrame();
		File imgf = new File(snapshotPngFile);
		ImageIO.write(bi, "PNG", imgf);
    	copyToZip(snapshotPngFile, "snapshot.png", zipOut);
    	imgf.delete(); // temp. image file no longer needed in filing system...
    	
    	for (int slotNo=0; slotNo<=3; slotNo++) {
    		if (memory.isSlotEmpty(slotNo) == false) {
    			if (slotNo == 0) {
    				// dump ROM.0 and RAM.0 
    				memory.dumpSlot(slotNo, false, System.getProperty("user.dir"), "");
    				copyToZip(System.getProperty("user.dir") + File.separator + "rom.bin", "rom.bin", zipOut);
    				copyToZip(System.getProperty("user.dir") + File.separator + "ram.bin", "ram.bin", zipOut);
    				new File(System.getProperty("user.dir") + File.separator + "rom.bin").delete();
    				new File(System.getProperty("user.dir") + File.separator + "ram.bin").delete();					
    			} else {
    				properties.setProperty("SLOT" + slotNo + "TYPE", "" + SlotInfo.getInstance().getCardType(slotNo)); 
    				String slotShortFilename = "slot" + slotNo + ".bin";
    				String slotLongFilename = System.getProperty("user.dir") + File.separator + slotShortFilename;
    				memory.dumpSlot(slotNo, false, System.getProperty("user.dir"), slotShortFilename);
    				copyToZip(slotLongFilename, slotShortFilename, zipOut);
    				new File(slotLongFilename).delete();
    			}
    		} else {
    			properties.setProperty("SLOT" + slotNo + "TYPE", "" + SlotInfo.EmptySlot);
    		}
    	}

    	// remember the Host computer system time 
    	// when a snapshot is installed and the Blink TIMx register are adjusted to "lost" time...
    	properties.setProperty("Z88StoppedAtTime", "" + z80.getZ88StoppedAtTime());
    	
    	// remember the current Z88 keyboard layout
    	properties.setProperty("Z88KbLayout", "" + Z88.getInstance().getKeyboard().getKeyboardLayout());
		
    	// remember the visual state of the Runtime Message Panel
    	properties.setProperty("RtmMessages", Boolean.toString(OZvm.getInstance().getGui().getRtmMessagesMenuItem().isSelected()));

    	// remember the visual state of the Z88 Keyboard Panel
    	properties.setProperty("Z88Keyboard", Boolean.toString(OZvm.getInstance().getGui().getZ88keyboardMenuItem().isSelected()));

    	// remember the visual state of the Z88 Card Slots Panel
    	properties.setProperty("Z88CardSlots", Boolean.toString(OZvm.getInstance().getGui().getZ88CardSlotsMenuItem().isSelected()));
    	
    	// remember the breakpoints
    	properties.setProperty("Breakpoints", z80.getBreakpoints().breakpointList());
		
    	// remember if virtual machine is to be auto-executed after restore,
    	// or just activate the debug command line..
    	properties.setProperty("Autorun", Boolean.toString(autorun));
    	
    	// save the properties to a temp. file
	    File pf = new File(propfilename);
	    FileOutputStream pfs = new FileOutputStream(pf);
        properties.store(pfs, null);
        pfs.close();        
        // Transfer the properties file to the ZIP archive
    	copyToZip(propfilename, "snapshot.settings", zipOut);
        pf.delete(); // temp. properties file no longer needed in filing system...
        
        zipOut.close();            
	}
	
	/**
	 * Copy a file into a Zip archive.
	 * 
	 * @param fileName the external file to be copied
	 * @param zipFilename the name of the file on the Zip archive
	 * @param zip the open Zip archive resource 
	 * @throws IOException
	 */
	private void copyToZip(String fileName, String zipFilename, ZipOutputStream zip) throws IOException {
        int len;
		byte[] buffer = new byte[Bank.SIZE];
		
        FileInputStream in = new FileInputStream(fileName);
    	zip.putNextEntry(new ZipEntry(zipFilename));
        while ((len = in.read(buffer)) > 0) {
        	zip.write(buffer, 0, len);
        }	        
        in.close();		
	}

	/**
	 * Restore virtual machine from snapshot file.
	 * 
	 * @param snapshotFileName
	 * @return true if virtual machine is to be automatically executed after restore
	 * @throws IOException
	 */
	public boolean loadSnapShot(String snapshotFileName) throws IOException {
		ZipFile zf;
		ZipEntry ze;
		Properties properties = new Properties();
		boolean autorun;
		
		if (snapshotFileName.toLowerCase().lastIndexOf(".z88") == -1)
			snapshotFileName += ".z88"; // '.z88' extension is missing.
		
		// Remove all current active memory and reset Blink before restoring a snapshot.
		memory.setVoidMemory();
		blink.resetBlinkRegisters();
		
        // Open the snapshot (Zip) file
        zf = new ZipFile(snapshotFileName);
    
        // start with loading the properties...
        ze = zf.getEntry("snapshot.settings");
        if (ze != null)
        	properties.load(zf.getInputStream(ze));
        else 
        	throw new IOException("'snapshot.settings' is missing!");
        
        ze = zf.getEntry("rom.bin"); // default slot 0 ROM
        if (ze != null) 
        	memory.loadRomBinary((int) ze.getSize(), zf.getInputStream(ze));
        else
        	throw new IOException("ROM image is missing!");

        ze = zf.getEntry("ram.bin"); // default slot 0 RAM
        if (ze != null) 
        	memory.loadCardBinary(0, (int) ze.getSize(), SlotInfo.RamCard, zf.getInputStream(ze));
        else
        	throw new IOException("RAM.0 image is missing!");
		
        for (int slotNo=1; slotNo<=3; slotNo++) {
	        ze = zf.getEntry("slot" + slotNo + ".bin");
	        if (ze != null) {
	        	memory.loadCardBinary(slotNo, (int) ze.getSize(), 
	        			Integer.parseInt(properties.getProperty("SLOT" + slotNo + "TYPE"), 16), 
						zf.getInputStream(ze));
	        }
        }
        
        loadZ80Regs(properties); // restore Z80 processor registers
        loadBlinkRegs(properties); // restore Blink hardware registers
        loadBreakpoints(properties); // restore breakpoints from snapshot
        
        if (properties.getProperty("Z88StoppedAtTime") != null)
        	z80.setZ88StoppedAtTime(Long.parseLong(properties.getProperty("Z88StoppedAtTime")));
        else
        	z80.setZ88StoppedAtTime(System.currentTimeMillis());
        
        if (properties.getProperty("Z88KbLayout") != null) {
        	int kbLayoutCountryCode = Integer.parseInt(properties.getProperty("Z88KbLayout"));
        	switch(kbLayoutCountryCode) {
        		case Z88Keyboard.COUNTRY_EN:
        			OZvm.getInstance().getGui().getUkLayoutMenuItem().doClick();
        			break;
        		case Z88Keyboard.COUNTRY_DK:
        			OZvm.getInstance().getGui().getDkLayoutMenuItem().doClick();
        			break;
        		case Z88Keyboard.COUNTRY_FR:
        			OZvm.getInstance().getGui().getFrLayoutMenuItem().doClick();
        			break;
        		case Z88Keyboard.COUNTRY_SE: // Swedish/Finish
        			OZvm.getInstance().getGui().getSeLayoutMenuItem().doClick();
        			break;
        		default:
        			// all other keyboard layouts are default UK (since they're not implemented yet)
        			OZvm.getInstance().getGui().getUkLayoutMenuItem().doClick();	        			
        	}
        }      

        if (properties.getProperty("RtmMessages") != null) {
        	boolean dispRtmPanel = Boolean.valueOf(properties.getProperty("RtmMessages")).booleanValue();
        	OZvm.getInstance().getGui().displayRunTimeMessagesPane(dispRtmPanel);
        }      

        if (properties.getProperty("Z88Keyboard") != null) {
        	boolean dispZ88Kb = Boolean.valueOf(properties.getProperty("Z88Keyboard")).booleanValue();
        	OZvm.getInstance().getGui().displayZ88Keyboard(dispZ88Kb);
        }      
        if (properties.getProperty("Z88CardSlots") != null) {
        	boolean dispZ88CrdSlots = Boolean.valueOf(properties.getProperty("Z88CardSlots")).booleanValue();
        	OZvm.getInstance().getGui().displayZ88CardSlots(dispZ88CrdSlots);
        }      
        
        if (properties.getProperty("Autorun") != null)
        	autorun = Boolean.valueOf(properties.getProperty("Autorun")).booleanValue();        	
        else
        	autorun = true;
        
        zf.close();
                
        return autorun;	        
	}	

	/** 
	 * Get a JFileChooser filter for Z88 snapshot files
	 */
	public SnapshotFilter getSnapshotFilter() {
		return new SnapshotFilter();
	}
	
	/**
	 * JFileChooser filter to validate z88 snapshot files
	 */
	private class SnapshotFilter extends FileFilter {

	    /** Accept all directories and z88 files */
	    public boolean accept(File f) {
	        if (f.isDirectory()) {
	            return true;
	        }

	        String extension = getExtension(f);
	        if (extension != null) {
	            if (extension.equalsIgnoreCase("z88") == true) {
	        		ZipFile zf;
	        		ZipEntry ze;
	        		Properties properties = new Properties();
	        		
	        		try {
	        	        // Try to open the snapshot (Zip) file
	        	        zf = new ZipFile(f);
	        	    
	        	        // try to load the properties...
	        	        ze = zf.getEntry("snapshot.settings");
	        	        if (ze != null)
	        	        	properties.load(zf.getInputStream(ze));
	        	        else 
	        	        	return false;
	        	        
	        	        ze = zf.getEntry("rom.bin");
	        	        if (ze == null) 
	        	        	return false;
       	        
	        	        zf.close();
	        		} catch (IOException e) {
	        			return false;
	        		}

	        		// the Zip file was polled successfully.
	            	return true;
	            	
	            } else {
	            	// ignore files that doesn't use the 'z88' extension.
	                return false;
	            }
	        }

	        // file didn't have an extension...
	        return false;
	    }

	    /** The description of this filter */
	    public String getDescription() {
	        return "Z88 snapshot files";
	    }

	    /** Get the extension of a file */  
	    private String getExtension(File f) {
	        String ext = null;
	        String s = f.getName();
	        int i = s.lastIndexOf('.');

	        if (i > 0 &&  i < s.length() - 1) {
	            ext = s.substring(i+1).toLowerCase();
	        }
	        return ext;
	    }	    
	}	
}
