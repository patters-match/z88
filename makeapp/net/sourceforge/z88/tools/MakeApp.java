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
	
	public static void main(String[] args) {
		int appCardBanks = 1;
		int appCardSize = 16; 
		RomBank[] banks = new RomBank[appCardBanks]; 	// the default 16K card container
		banks[0] = new RomBank(); 						// with a default 16K bank
		
		try {
			if (args.length >= 1) {
				int arg = 0;
				
				if (args[0].compareToIgnoreCase("-sz") == 0) {
					appCardSize = Integer.parseInt(args[1], 10);
					appCardBanks = appCardSize / 16;
					if (appCardSize % 16 != 0 & appCardBanks != 1 & appCardBanks != 2 & appCardBanks != 4 & 
						appCardBanks != 8 & appCardBanks != 16 & appCardBanks != 32 & appCardBanks != 64) {
						System.out.println("Card sizes allowed: 16K, 32K, 64K, 128K, 256K, 512K or 1024K.");
						System.exit(0);							
					}
						
					banks = new RomBank[appCardBanks]; // the card container
					for (int b=0; b<appCardBanks; b++) banks[b] = new RomBank(); // container filled with memory... 
					arg += 2;
				}
				
				RandomAccessFile cardFile = new RandomAccessFile(args[arg++], "rw");
				
				while (arg < args.length) {
					RandomAccessFile binaryFile =  new RandomAccessFile(args[arg++], "r");
					int offset = Integer.parseInt(args[arg++], 16);
					int bankNo = ((offset & 0x3f0000) >>> 16) & (appCardBanks-1);
					offset &= 0x3fff;
					
					byte codeBuffer[] = new byte[(int) binaryFile.length()];
					binaryFile.readFully(codeBuffer);
					banks[bankNo].loadBytes(codeBuffer, offset);
				}
								
				for (int b=0; b<appCardBanks; b++) {
					byte bankDump[] = banks[b].dumpBytes(0, Bank.BANKSIZE); 
					cardFile.write(bankDump);
				}
				cardFile.close();
				
			} else {
				System.out.println("Syntax: [-sz Size] memdump.file input1.file offset {inputX.file offset}\n");
				System.out.println("Usage: Load binary files a into default 16K memory bank, and save contents");
				System.out.println("to a new file. Offsets are specified in hex (truncated to 16K offsets).\n");
				System.out.println("Larger application cards is created by optionally specifying size in K, eg.");
				System.out.println("32 ... up to 1024K. Offsets are then extended with relative bank number,");
				System.out.println("for example 3fc000 for bank 3f (top), offset 0000 (start of top bank).\n");
				System.out.println("Example, using default 16K application bank dump:");
				System.out.println("java -jar makeapp.jar appl.epr code.bin c000 romhdr.bin 3fc0");
				System.out.println("(load 1st file at 0000, 2nd file at 3fc0, and save 16K bank to appl.epr)");
			}
		} catch (FileNotFoundException e) {
			System.out.println("Couldn't load file image:\n" + e.getMessage() + "\nprogram terminated.");
			return;
		} catch (IOException e) {
			System.out.println("Problem with bank image or I/O:\n" + e.getMessage() + "\nprogram terminated.");
			return;
		}		
	}
}
