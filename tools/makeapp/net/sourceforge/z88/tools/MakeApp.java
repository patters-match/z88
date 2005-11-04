/*
 * MakeApp.java
 * This file is part of MakeApp.
 * 
 * MakeApp is free software; you can redistribute it and/or modify it under the terms of the 
 * GNU General Public License as published by the Free Software Foundation;
 * either version 2, or (at your option) any later version.
 * MakeApp is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 * without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * You should have received a copy of the GNU General Public License along with MakeApp;
 * see the file COPYING. If not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 * 
 * @author <A HREF="mailto:gbs@users.sourceforge.net">Gunther Strube</A>
 * $Id$  
 *
 */

package net.sourceforge.z88.tools;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.RandomAccessFile;


/**
 * Simple command line tool that creates a 16K or larger card file where
 * small binary files are loaded into at various offsets.
 * Finally, the card is saved to a new file.
 * 
 * The tool is used to combine various Z88 application files into
 * a single application card of 16K or larger.
 */
public class MakeApp {
	private static final char[] hexcodes =
	{'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'};

	
	/**
	 * Return Hex 16bit address string in XXXXh zero prefixed format.
	 *
	 * @param addr The 16bit address to be converted to hex string
	 * @param hexTrailer append 'h' if true.
	 * @return String
	 */
	public static final String addrToHex(final int addr, final boolean hexTrailer) {
		int msb = addr >>> 8, lsb = addr & 0xFF;
		StringBuffer hexString = new StringBuffer(5);

		hexString.append(hexcodes[msb/16]).append(hexcodes[msb%16]);
		hexString.append(hexcodes[lsb/16]).append(hexcodes[lsb%16]);
		if (hexTrailer == true) hexString.append('h');

		return hexString.toString();
	}
	
	
	public static void main(String[] args) {
		int appCardBanks = 1;
		int appCardSize = 16; 
		RomBank[] banks = new RomBank[appCardBanks]; 	// the default 16K card container
		banks[0] = new RomBank(); 						// with a default 16K bank
		boolean splitBanks = false;
				
		try {
			if (args.length >= 1) {
				int arg = 0;
				
				if (args[0].compareToIgnoreCase("-sz") == 0 | args[0].compareToIgnoreCase("-szc") == 0) {
					if (args[0].indexOf("c") > 0) splitBanks = true;
					
					appCardSize = Integer.parseInt(args[1], 10);
					appCardBanks = appCardSize / 16;
					if ((appCardSize != ( 2 << (Math.round(Math.log(appCardSize)/Math.log(2))-1))) | appCardSize>1024 ) {
						System.err.println("Illegal card size. Use only: 16K, 32K, 64K, 128K, 256K, 512K or 1024K.");
						System.exit(0);							
					}
						
					banks = new RomBank[appCardBanks]; // the card container
					for (int b=0; b<appCardBanks; b++) banks[b] = new RomBank(); // container filled with memory... 
					arg += 2;
				}
				
				String outputFilename = args[arg++];
				
				while (arg < args.length) {
					String filename = args[arg++];
					RandomAccessFile binaryFile =  new RandomAccessFile(filename, "r");
					int codeSize = (int) binaryFile.length();
					byte codeBuffer[] = new byte[codeSize];
					binaryFile.readFully(codeBuffer);
					binaryFile.close();

					int offset = Integer.parseInt(args[arg++], 16);
					int bankNo = ((offset & 0x3f0000) >>> 16) & (appCardBanks-1);
					offset &= 0x3fff;
					
					if (codeSize > Bank.BANKSIZE) {
						System.err.println(filename + ": code size > 16K!");
						return;
					}
					
					if ((codeSize + offset) > Bank.BANKSIZE ) {
						System.err.println(filename + ": code block at offset " + addrToHex(offset,true) + " > crosses 16K bank boundary!");
						return;						
					}
					
					for (int b=0; b<codeSize; b++) {
						if ( (banks[bankNo].getByte(offset+b) & 0xff) != 0xFF ) {
							System.err.println(filename + ": code overlap was found at " + addrToHex(offset+b,true) + "!");
							return;													
						}
					}					
					
					banks[bankNo].loadBytes(codeBuffer, offset);
				}

				RandomAccessFile cardFile = new RandomAccessFile(outputFilename, "rw");
				for (int b=0; b<appCardBanks; b++) {
					byte bankDump[] = banks[b].dumpBytes(0, Bank.BANKSIZE); 
					cardFile.write(bankDump);
				}
				cardFile.close();
				
				if (splitBanks == true) {
					// Also dump the binary into 16 bank files...
					int topBank = 0x3F;
					for (int b=appCardBanks-1; b>=0; b--) {
						cardFile = new RandomAccessFile(outputFilename + "." + topBank--, "rw");
						byte bankDump[] = banks[b].dumpBytes(0, Bank.BANKSIZE); 
						cardFile.write(bankDump);
						cardFile.close();
					}					
				}				
			} else {
				System.out.println("Syntax: [-sz Size] memdump.file input1.file offset {inputX.file offset}");
				System.out.println("or");
				System.out.println("[-szc Size] memdump.file input1.file offset {inputX.file offset}\n");
				System.out.println("Usage: Load binary files into one or several 16K memory bank, and save it");
				System.out.println("all to a new file. Offsets are specified in hex (truncated to 16K offsets).\n");
				System.out.println("Larger application cards is created by optionally specifying size in K, eg.");
				System.out.println("32 ... up to 1024K. Offsets are then extended with relative bank number,");
				System.out.println("for example 3fc000 for bank 3f (top), offset 0000 (start of top bank).\n");
				System.out.println("If you need to split a large assembled card into 16 bank on the output,");
				System.out.println("use the -szc switch, eg. -szc 64 will make both a 64K file and 4 files,");
				System.out.println("added with .63 for the top bank of the card and downwards.\n");
				System.out.println("Example, using default 16K application bank dump (java -jar makeapp.jar):");
				System.out.println("appl.epr code.bin c000 romhdr.bin 3fc0");
				System.out.println("(load 1st file at 0000, 2nd file at 3fc0, and save 16K bank to appl.epr)\n");
				System.out.println("Example, using a 32K application bank dump (and separate 16K bank files):");
				System.out.println("-szc 32 bigappl.epr mth.bin 3e0000 code.bin 3fc000 romhdr.bin 3f3fc0");
			}
		} catch (FileNotFoundException e) {
			System.err.println("Couldn't load file image:\n" + e.getMessage() + "\nprogram terminated.");
			return;
		} catch (IOException e) {
			System.err.println("Problem with bank image or I/O:\n" + e.getMessage() + "\nprogram terminated.");
			return;
		}		
	}
}
