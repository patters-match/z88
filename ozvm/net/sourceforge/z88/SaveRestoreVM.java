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

import net.sourceforge.z88.datastructures.SlotInfo;

/**
 * Management of saving and resuming a OZvm machine instance.
 * The machine state is saved in a Zip file containing a combination 
 * of a properties file, and a memory dump of current slot contents, 
 * saved as slotX.ram or slotX.epr, depending of the type. 
 */
public class SaveRestoreVM {

    Blink blink;
    Memory memory;

	/** Constructor */
	public SaveRestoreVM() {
		blink = Blink.getInstance();
		memory = Memory.getInstance();
	}

	/**
	 * Preserve state of the Z80 CPU registers.
	 */
	private void storeZ80Regs(Properties properties) {
	    properties.setProperty("AF", Dz.addrToHex(blink.AF(),false));
	    properties.setProperty("BC", Dz.addrToHex(blink.BC(),false));
	    properties.setProperty("DE", Dz.addrToHex(blink.DE(),false));
	    properties.setProperty("HL", Dz.addrToHex(blink.HL(),false));
	    properties.setProperty("IX", Dz.addrToHex(blink.IX(),false));
	    properties.setProperty("IY", Dz.addrToHex(blink.IY(),false));
	    properties.setProperty("PC", Dz.addrToHex(blink.PC(),false));
	    properties.setProperty("SP", Dz.addrToHex(blink.SP(),false));
	    blink.ex_af_af();
	    properties.setProperty("_AF", Dz.addrToHex(blink.AF(),false));
	    blink.ex_af_af();
	    blink.exx();
	    properties.setProperty("_BC", Dz.addrToHex(blink.BC(),false));
	    properties.setProperty("_DE", Dz.addrToHex(blink.DE(),false));
	    properties.setProperty("_HL", Dz.addrToHex(blink.HL(),false));
	    blink.exx();
	    properties.setProperty("I", Dz.byteToHex(blink.I(),false));
	    properties.setProperty("R", Dz.byteToHex(blink.R(),false));
	    properties.setProperty("IM", Dz.byteToHex(blink.IM(), false));
	    properties.setProperty("IFF1", Boolean.toString(blink.IFF1()));
	    properties.setProperty("IFF2", Boolean.toString(blink.IFF2()));	    
	}

	/**
	 * Restore register values into the Z80 engine.
	 */
	private void loadZ80Regs(Properties properties) {
		blink.AF(Integer.parseInt(properties.getProperty("AF"), 16));
		blink.BC(Integer.parseInt(properties.getProperty("BC"), 16));
		blink.DE(Integer.parseInt(properties.getProperty("DE"), 16));		
		blink.HL(Integer.parseInt(properties.getProperty("HL"), 16));
		blink.IX(Integer.parseInt(properties.getProperty("IX"), 16));
		blink.IY(Integer.parseInt(properties.getProperty("IY"), 16));
		blink.PC(Integer.parseInt(properties.getProperty("PC"), 16));
		blink.SP(Integer.parseInt(properties.getProperty("SP"), 16));		
	    blink.ex_af_af();
		blink.AF(Integer.parseInt(properties.getProperty("_AF"), 16));
	    blink.ex_af_af();
	    blink.exx();
		blink.BC(Integer.parseInt(properties.getProperty("_BC"), 16));
		blink.DE(Integer.parseInt(properties.getProperty("_DE"), 16));		
		blink.HL(Integer.parseInt(properties.getProperty("_HL"), 16));
	    blink.exx();
		blink.I(Integer.parseInt(properties.getProperty("I"), 16));
		blink.R(Integer.parseInt(properties.getProperty("R"), 16));
		blink.IM(Integer.parseInt(properties.getProperty("IM"), 16));
		blink.IFF1(Boolean.valueOf(properties.getProperty("IFF1")).booleanValue());
		blink.IFF2(Boolean.valueOf(properties.getProperty("IFF2")).booleanValue());		
	}
	
	private void storeBlinkRegs(Properties properties) {
		properties.setProperty("PB0", Dz.addrToHex(blink.getBlinkPb0(),false));
		properties.setProperty("PB1", Dz.addrToHex(blink.getBlinkPb1(),false));
		properties.setProperty("PB2", Dz.addrToHex(blink.getBlinkPb2(),false));
		properties.setProperty("PB3", Dz.addrToHex(blink.getBlinkPb3(),false));
		properties.setProperty("SBR", Dz.addrToHex(blink.getBlinkSbr(),false));
		
		properties.setProperty("COM", Dz.byteToHex(blink.getBlinkCom(),false));
		properties.setProperty("INT", Dz.byteToHex(blink.getBlinkInt(),false));
		properties.setProperty("STA", Dz.byteToHex(blink.getBlinkSta(),false));
		
		// KBD is not preserved (not needed)
		// EPR not yet implemented

		properties.setProperty("TACK", Dz.byteToHex(blink.getBlinkTack(),false));
		properties.setProperty("TMK", Dz.byteToHex(blink.getBlinkTmk(),false));
		properties.setProperty("TSTA", Dz.byteToHex(blink.getBlinkTsta(),false));
		properties.setProperty("ACK", Dz.byteToHex(blink.getBlinkAck(),false));
		
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
		
		// KBD is not preserved (not needed)
		// EPR not yet implemented

		blink.setBlinkTack(Integer.parseInt(properties.getProperty("TACK"), 16));
		blink.setBlinkTmk(Integer.parseInt(properties.getProperty("TMK"), 16));
		blink.setBlinkTsta(Integer.parseInt(properties.getProperty("TSTA"), 16));
		blink.setBlinkAck(Integer.parseInt(properties.getProperty("ACK"), 16));
		
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
	 * Save contents of virtual machine into a snapshot file (Zip file).
	 * 
	 * @param snapshotFileName
	 * @throws IOException
	 */
	public void storeSnapShot(String snapshotFileName) throws IOException {
		String propfilename = System.getProperty("user.dir") + File.separator + "snapshot.settings";
		String snapshotPngFile = System.getProperty("user.dir") + File.separator + "snapshot.png";
		Properties properties = new Properties();
	
        // save Z80 & Blink registers to properties collection
        storeZ80Regs(properties);
        storeBlinkRegs(properties);
        
    	ZipOutputStream zipOut = new ZipOutputStream(new FileOutputStream(snapshotFileName));
    	zipOut.setLevel(9); // compress contents as much as possible...
    	
        // save a copy of the current screen...
        BufferedImage bi = Z88display.getInstance().getScreenFrame();
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
	 * @param fileName
	 */
	public boolean loadSnapShot(String fileName) {
		ZipFile zf;
		ZipEntry ze;
		Properties properties = new Properties();
		
	    try {
	        // Open the snapshot (Zip) file
	        zf = new ZipFile(fileName);
	    
	        // start with loading the properties...
	        ze = zf.getEntry("snapshot.settings");
	        properties.load(zf.getInputStream(ze));
	        
	        ze = zf.getEntry("rom.bin"); // default slot 0 ROM
	        if (ze != null) 
	        	memory.loadRomBinary((int) ze.getSize(), zf.getInputStream(ze));

	        ze = zf.getEntry("ram.bin"); // default slot 0 RAM
	        if (ze != null) 
	        	memory.loadCardBinary(0, (int) ze.getSize(), SlotInfo.RamCard, zf.getInputStream(ze));
			
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
	        
	        return true;
	        
	    } catch (IOException e) {
	    	return false;
	    }		
	}	
}
