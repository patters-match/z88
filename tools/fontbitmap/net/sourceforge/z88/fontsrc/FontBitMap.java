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

	private File fontFile;

	private File asmFile;

	private BufferedWriter bwAsmFile;

	private byte[] fontBitMap;

	/** constructor, define input & output filenames */
	public FontBitMap(String fontFilename) {
		fontFile = new File(fontFilename);
		asmFile = new File(fontFilename + ".asm");
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

	/** display the character as a comment and a defb sequence */
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

	private void scanFontFile() {
		try {
			RandomAccessFile rafFontBitMap = new RandomAccessFile(fontFile, "r");
			byte[] romImage = new byte[(int) rafFontBitMap.length()];
			rafFontBitMap.readFully(romImage);
			rafFontBitMap.close();
			fontBitMap = new byte[0xF00]; // size of lores1 + hires1 Font Bit Map

			// copy font bit map at start of bank 7 from ROM file image
			int index = 0;
			for (int b = 0x1c000; b < (0x1c000 + 0xf00); b++)
				fontBitMap[index++] = romImage[b];

			// create a text file for output.
			asmFile.delete();
			bwAsmFile = new BufferedWriter(new FileWriter(asmFile));

			for (int f = 0; f < fontBitMap.length; f += 8) {
				dumpCharMatrix(f);
			}
			bwAsmFile.close();

			// dump font bit map as separate file..
			File fontBitMapFile = new File(fontFile + ".dat");
			fontBitMapFile.delete();
			rafFontBitMap = new RandomAccessFile(fontBitMapFile, "rw");
			rafFontBitMap.write(fontBitMap);
			rafFontBitMap.close();

			// extract the token table, embedded inside the font bitmap in
			// bit 7,6 of each byte.
			byte[] tokentable = new byte[fontBitMap.length/4];
			index=0;
			for (int b=0, n=fontBitMap.length; b<n; b+=4) {
				int tbyte = 0;
				for (int bits=b; bits<(b+4); bits++) {
					tbyte = (tbyte << 2) | ((fontBitMap[bits] & 0xc0) >>> 6); 
				}
				tokentable[index++] = (byte) tbyte;
			}
			
			int tokenCount = tokentable[1] & 0xff;			
			int endTokenPtrOffset = 2 + tokenCount*2;
			int sizeOfTokenTable = (tokentable[endTokenPtrOffset+1] & 0xff) * 256 + (tokentable[endTokenPtrOffset] & 0xff);
			// System.out.println(addrToHex(tokenCount,true) + "," + addrToHex(endTokenPtrOffset,true) + "," + addrToHex(sizeOfTokenTable,true));
			
			// Raw dump of the extracted embedded token table inside font bit map 
			File tokenTableFile = new File(fontFile + ".tkt");
			tokenTableFile.delete();
			RandomAccessFile rafTokenTable = new RandomAccessFile(tokenTableFile, "rw");
			rafTokenTable.write(tokentable, 0, sizeOfTokenTable);
			rafTokenTable.close();
			
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	/**
	 * open specified filename, scan Z88 font bitmap and generate source code
	 * 
	 * @param args
	 */
	public static void main(String[] args) {
		if (args.length == 0) {
			System.out
					.println("Usage java -jar Z88FontSources <Z88 ROM filename>");
		} else {
			FontBitMap zfs = new FontBitMap(args[0]);
			zfs.scanFontFile();
		}
	}
}
