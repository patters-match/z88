package net.sourceforge.z88.fontsrc;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.io.RandomAccessFile;

public class FontBitMap {

	private static final char[] hexcodes =
		{'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'};
	
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
	 * @param b The byte to be converted to binary string
	 * @param binTrailer append 'b' if true.
	 * @return String
	 */
	public static final String byteToBin(final int b, final boolean binTrailer) {
		StringBuffer binString = new StringBuffer(9);
		
		for (int bit=7; bit>=0; bit--) {
			if ((b & (1 << bit)) == 0) 
				binString.append("0");
			else
				binString.append("1");
		}
		if (binTrailer == true) binString.append('b');

		return binString.toString();
	}	

	
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

	
	/** display the character as a comment and a defb sequence */
	private void dumpCharMatrix(int offset) {
		try {
			bwAsmFile.write("\n\n; Char entry $" + addrToHex(offset/8,false) + " (offset $" + addrToHex(offset,false) + ")\n");
			for (int b=0; b<8; b++) {
				bwAsmFile.write("; ");
				int fbyte = fontBitMap[offset+b] & 0xFF;
				
				for (int i = 0; i<8; i++) {
					int mask = (1 << (7-i));
					bwAsmFile.write( ((fbyte & mask) != 0) ? "#": " " );
				}
				bwAsmFile.write("\n");
			}

			for (int b=0; b<8; b++) {
				bwAsmFile.write( "defb @" + byteToBin(fontBitMap[offset+b] & 0xFF, false) + "\n");
			}
			
		} catch (IOException e) {
			e.printStackTrace();
		}		
	}
	
	
	private void scanFontFile() {
		try {
			RandomAccessFile rafFontBitMap = new RandomAccessFile(fontFile, "r");
			fontBitMap = new byte[(int) rafFontBitMap.length()];
			rafFontBitMap.readFully(fontBitMap);
			rafFontBitMap.close();
			
			// create a text file for output. 
			asmFile.delete();
			bwAsmFile = new BufferedWriter(new FileWriter(asmFile));
			
			for (int f=0; f<fontBitMap.length; f+=8) {
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
	 * open specified filename, scan Z88 font bitmap and generate source code
	 * @param args 
	 */
	public static void main(String[] args) {
		if (args.length == 0) {
			System.out.println("Usage java -jar Z88FontSources <filename>");
		} else {
			FontBitMap zfs = new FontBitMap(args[0]);
			zfs.scanFontFile();			
		}
	}
}
