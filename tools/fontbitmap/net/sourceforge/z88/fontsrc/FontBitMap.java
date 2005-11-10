/*
 * FontBitMap - Z88 Font source code generator
 * (C) Copyright Gunther Strube (gbs@users.sf.net), 2005
 *
 * FontBitMap is free software; you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation;
 * either version 2, or (at your option) any later version.
 * FontBitMap is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 * without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * You should have received a copy of the GNU General Public License along with FontBitMap;
 * see the file COPYING. If not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *
 * @author <A HREF="mailto:gbs@users.sourceforge.net">Gunther Strube</A>
 * $Id$
 */

package net.sourceforge.z88.fontsrc;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.io.RandomAccessFile;

public class FontBitMap {

	private static final char[] hexcodes = { '0', '1', '2', '3', '4', '5', '6',
			'7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F' };

	private File romFile;
	private File asmFile;
	private File fontBitMapFile;
	private File tokenTableFile;

	private BufferedWriter bwAsmFile;

	private byte[] fontBitMap;
	private byte[] tokenTable; 
	
	/** constructor, define input & output filenames */
	public FontBitMap(String romFilename) {
		romFile = new File(romFilename);
		asmFile = new File(romFilename + ".asm");
		fontBitMapFile = new File(romFilename + ".dat");
		tokenTableFile = new File(romFilename + ".tkt");
	}

	
	/**
	 * Return Binary 8bit string in 01010101b zero prefixed format.
	 * 
	 * @param b
	 *            The byte to be converted to binary string
	 * @param binTrailer
	 *            append 'b' if true.
	 * @return String
	 */
	public static final String byteToBin(final int b, final boolean binTrailer) {
		StringBuffer binString = new StringBuffer(9);

		for (int bit = 7; bit >= 0; bit--) {
			if ((b & (1 << bit)) == 0)
				binString.append("0");
			else
				binString.append("1");
		}
		if (binTrailer == true)
			binString.append('b');

		return binString.toString();
	}

	
	/**
	 * Return Hex 16bit address string in XXXXh zero prefixed format.
	 * 
	 * @param addr
	 *            The 16bit address to be converted to hex string
	 * @param hexTrailer
	 *            append 'h' if true.
	 * @return String
	 */
	public static final String addrToHex(final int addr,
			final boolean hexTrailer) {
		int msb = addr >>> 8, lsb = addr & 0xFF;
		StringBuffer hexString = new StringBuffer(5);

		hexString.append(hexcodes[msb / 16]).append(hexcodes[msb % 16]);
		hexString.append(hexcodes[lsb / 16]).append(hexcodes[lsb % 16]);
		if (hexTrailer == true)
			hexString.append('h');

		return hexString.toString();
	}

	
	/** write the character as a comment and a defb sequence to the source code file */
	private void dumpCharMatrix(int offset) {
		try {
			bwAsmFile.write("\n\n; Char entry $" + addrToHex(offset / 8, false)
					+ " (offset $" + addrToHex(offset, false) + ")\n");
			for (int b = 0; b < 8; b++) {
				bwAsmFile.write("; ");
				int fbyte = fontBitMap[offset + b] & 0xFF;

				for (int i = 0; i < 8; i++) {
					if (offset < 0xc00) fbyte &= 0x3f; // don't display token table bits ...
					int mask = (1 << (7 - i));
					bwAsmFile.write(((fbyte & mask) != 0) ? "#" : " ");
				}
				bwAsmFile.write("\n");
			}

			for (int b = 0; b < 8; b++) {
				bwAsmFile.write("defb @"
						+ byteToBin(fontBitMap[offset + b] & 0xFF, false)
						+ "\n");
			}

		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	
	/** dump the font bitmap in the ROM as a binary file */
	private void dumpFontBitMap() throws IOException {	
		// dump font bit map as separate file..
		fontBitMapFile.delete();
		RandomAccessFile rafFontBitMap = new RandomAccessFile(fontBitMapFile, "rw");
		rafFontBitMap.write(fontBitMap);
		rafFontBitMap.close();
	}
	
	
	/** Dump the embedded Token Table in font bitmap as stand-alone binary file 
	 * @throws IOException */
	private void dumpTokenTable() throws IOException {
		int index=0;

		// extract the token table, embedded inside the font bitmap in
		// bit 7,6 of each byte.
		tokenTable = new byte[fontBitMap.length/4];
		for (int b=0, n=fontBitMap.length; b<n; b+=4) {
			int tbyte = 0;
			for (int bits=b; bits<(b+4); bits++) {
				tbyte = (tbyte << 2) | ((fontBitMap[bits] & 0xc0) >>> 6); 
			}
			tokenTable[index++] = (byte) tbyte;
		}
		
		int tokenCount = tokenTable[1] & 0xff;			
		int endTokenPtrOffset = 2 + tokenCount*2;
		int sizeOfTokenTable = (tokenTable[endTokenPtrOffset+1] & 0xff) * 256 + (tokenTable[endTokenPtrOffset] & 0xff);
		// System.out.println(addrToHex(tokenCount,true) + "," + addrToHex(endTokenPtrOffset,true) + "," + addrToHex(sizeOfTokenTable,true));
		
		// Raw dump of the extracted embedded token table inside font bit map 
		tokenTableFile.delete();
		RandomAccessFile rafTokenTable = new RandomAccessFile(tokenTableFile, "rw");
		rafTokenTable.write(tokenTable, 0, sizeOfTokenTable);
		rafTokenTable.close();		
	}
	
	
	/** 
	 * Scan the font bitmap in the ROM, generate source code for 
	 * font bitmaps and stand-alone token table,
	 * dump the font bitmap and token table as binary files.  
	 */
	private void scanFontBitMap() {
		try {
			RandomAccessFile rafRomImage = new RandomAccessFile(romFile, "r");
			byte[] romImage = new byte[(int) rafRomImage.length()];
			rafRomImage.readFully(romImage);
			rafRomImage.close();
			fontBitMap = new byte[0xF00]; // size of lores1 + hires1 Font Bit Map

			// copy font bit map at start of bank 7 from ROM file image
			int index = 0;
			for (int b = 0x1c000; b < (0x1c000 + 0xf00); b++)
				fontBitMap[index++] = romImage[b];

			// dump the Font Bitmap as stand-alone file image (4K)
			dumpFontBitMap();
			
			// dump the embedded Token Table in font bitmap as stand-alone file image (1K)
			dumpTokenTable();

			// create source code as text file...
			asmFile.delete();
			bwAsmFile = new BufferedWriter(new FileWriter(asmFile));

			for (int f = 0; f < fontBitMap.length; f += 8) {
				dumpCharMatrix(f);
			}
			bwAsmFile.close();
						
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	
	/**
	 * Open specified Z88 ROM, scan Z88 font bitmap and generate source code
	 * for fonts and token table.
	 * 
	 * @param args
	 */
	public static void main(String[] args) {
		if (args.length == 0) {
			System.out
					.println("Usage: java -jar fontbitmap.jar <Z88 ROM filename>");
		} else {
			FontBitMap zfs = new FontBitMap(args[0]);
			zfs.scanFontBitMap();
		}
	}
}
