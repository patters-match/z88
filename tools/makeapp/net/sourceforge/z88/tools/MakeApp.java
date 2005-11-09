/*
 * MakeApp.java
 * (C) Copyright Gunther Strube (gbs@users.sf.net), 2005
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

import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.io.RandomAccessFile;


/**
 * Simple command line tool that creates a 16K or larger card file where
 * small binary files are loaded into at various offsets.
 * Finally, the card is saved to a new file.
 *
 * The tool is used to build the Z88 ROM or to combine various Z88 application
 * files into a single application card of 16K or larger.
 */
public class MakeApp {

	private static final char[] hexcodes =
	{'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'};

	private int appCardBanks = 1; // default output is 16K bank
	private int appCardSize = 16;
	private boolean splitBanks = false;

	private RomBank[] banks;
	private String outputFilename;


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


	/**
	 * Parse integer value from string (fetched from command line or loadmap file)
	 * and interpret it as the card size. The value must be a valid card size and not
	 * larger than 1Mb (max size of Z88 slot).
	 *
	 * Card size is evaluated as size in K.
	 *
	 * @param v
	 * @return card sice in K, or -1 if the value was illegal or badly formed
	 */
	private int getCardSize(String v) {
		int cardSize = 0;

		try {
			cardSize = Integer.parseInt(v, 10);
			if ((cardSize != ( 2 << (Math.round(Math.log(cardSize)/Math.log(2))-1))) | cardSize>1024 ) {
				// illegal card size
				cardSize = -1;
			}
		} catch (NumberFormatException e) {
			cardSize = -1;
		}

		return cardSize;
	}


	/**
	 * Load contents of file into a byte array.
	 *
	 * @param filename
	 * @return contents of file as byte array, or null if I/O error occurred
	 */
	private byte[] getFileBinary(String filename) {
		RandomAccessFile binaryInputFile;
		byte codeBuffer[] = null;

		try {
			binaryInputFile = new RandomAccessFile(filename, "r");
			int codeSize = (int) binaryInputFile.length();
			codeBuffer = new byte[codeSize];
			binaryInputFile.readFully(codeBuffer);
			binaryInputFile.close();

		} catch (FileNotFoundException e) {
			e.printStackTrace();
			codeBuffer = null;
		} catch (IOException e) {
			e.printStackTrace();
			codeBuffer = null;
		}

		return codeBuffer;
	}



	/**
	 * Parse the loadmap file for the following load directives:
	 * <pre>
	 * outputfile <filename>  ; filename of combined binary
	 * size <size>            ; total file size K, from 16K-1024K
	 * save16k                ; save output as 16K bank files
	 * </pre>
	 *
	 * Remaining directive are to be interpreted as file(names) and offset
	 * that identifies the binary fragments to be loaded into the code space.
	 *
	 * @param loadmapFilename
	 * @return true, if file was parsed successfully.
	 */
	private boolean parseLoadMapFile(String loadmapFilename) {
        BufferedReader in = null;
        String str;
        int lineNo=0;

		try {
	        in = new BufferedReader(new FileReader(loadmapFilename));
	        while ((str = in.readLine()) != null) {
	        	lineNo++;
	        	str = str.replace((char) 9,' '); // get rid of all TAB's and replace with space

	        	if (str.indexOf(";") > 0) {
	        		str = str.substring(0,str.indexOf(";")); // strip comments from line
	        	} else if (str.indexOf(";") == 0) {
	        		// comment at start of line - nothing to do, get another line...
	        		continue;
	        	}

	        	String directive[] = str.split(" "); // split string into directive tokens
	        	if (directive != null) {
	        		if (directive[0].compareToIgnoreCase("save16k") == 0) {
	        			splitBanks = true;
	        		} else if (directive[0].compareToIgnoreCase("outputfile") == 0) {
	        			outputFilename = directive[1];
	        		} else if (directive[0].compareToIgnoreCase("size") == 0) {
	        			appCardSize = getCardSize(directive[1]);
						if (appCardSize != -1) {
							appCardBanks = appCardSize / 16;
						} else {
							System.err.println(
									loadmapFilename + ", at line " + lineNo + ", " +
									"Illegal card size. Use only: 16K, 32K, 64K, 128K, 256K, 512K or 1024K.");
							return false;
						}

						banks = new RomBank[appCardBanks]; // the card container
						for (int b=0; b<appCardBanks; b++) banks[b] = new RomBank(); // container filled with memory...

	        		} else {
	        			// all other directive are file names and offsets...
	        			if (directive.length == 2 & directive[0].length() != 0) {
							int offset = Integer.parseInt(directive[1], 16);
							if ( loadCode(directive[0], (offset & 0x3f0000) >>> 16, offset & 0x3fff) == false ) {
								System.err.println(loadmapFilename + ", at line " + lineNo + ", File binary couldn't be loaded.");
								return false;
							}
	        			}
	        		}
	        	}
	        }
	        in.close();

	    } catch (IOException e) {
	    	if (in != null) try { in.close(); } catch (IOException e1) {}
	    	return false;
	    } catch (NumberFormatException e) {
	    	if (in != null) try { in.close(); } catch (IOException e1) {}
			System.err.println(loadmapFilename + ", at line " + lineNo + "Illegal bank offset.");
			return false;
		}

		return true;
	}


	/**
	 * Load the specified code into the final code space <b>banks</b> at bank, offset.
	 * The function will check for bank boundary code loading overlap errors, and
	 * report a message to stderr shell channel if an error occurs.
	 *
	 * @param filename name of file binary to load
	 * @param bankNo bank of final code space to load the binary
	 * @param offset offset within bank of final code space to load the binary
	 * @return true, if code was succcessfully loaded into final code space.
	 */
	private boolean loadCode(String filename, int bankNo, int offset) {
		bankNo &= appCardBanks-1;  // code to be placed properly within the boundary of the allocated banks

		byte codeBuffer[] = getFileBinary(filename);

		if (codeBuffer == null) {
			System.err.println(filename + ": couldn't open file!");
			return false;
		}
		if (codeBuffer.length > Bank.BANKSIZE) {
			System.err.println(filename + ": code size > 16K!");
			return false;
		}

		if ((codeBuffer.length + offset) > Bank.BANKSIZE ) {
			System.err.println(filename + ": code block at offset " + addrToHex(offset,true) + " > crosses 16K bank boundary!");
			return false;
		}

		for (int b=0; b<codeBuffer.length; b++) {
			if ( (banks[bankNo].getByte(offset+b) & 0xff) != 0xFF ) {
				System.err.println(filename + ": code overlap was found at " + addrToHex(offset+b,true) + "!");
				return false;
			}
		}

		banks[bankNo].loadBytes(codeBuffer, offset);
		return true;
	}


	/**
	 * Generate output binary, depending on command line arguments.
	 * @param args
	 */
	private void parseArgs(String[] args) {

		try {
			if (args.length == 0) {
				displayCmdLineSyntax();
			} else {
				int arg = 0;

				if (args[0].compareToIgnoreCase("-f") == 0) {
					// parse contents of loadmap file...
					if (parseLoadMapFile(args[1]) == false) {
						return;
					}
				} else {
					// parse the command arguments...
					if (args[0].compareToIgnoreCase("-sz") == 0 | args[0].compareToIgnoreCase("-szc") == 0) {
						if (args[0].indexOf("c") > 0) splitBanks = true;

						appCardSize = getCardSize(args[1]);
						if (appCardSize != -1) {
							appCardBanks = appCardSize / 16;
						} else {
							System.err.println("Illegal card size. Use only: 16K, 32K, 64K, 128K, 256K, 512K or 1024K.");
							return;
						}

						arg += 2;
					}

					banks = new RomBank[appCardBanks]; // the card container
					for (int b=0; b<appCardBanks; b++) banks[b] = new RomBank(); // container filled with memory...

					outputFilename = args[arg++];

					// remaining arguments on command line are the file binaries to be loaded into the code space.
					while (arg < args.length) {
						String fileName = args[arg++];
						int offset = Integer.parseInt(args[arg++], 16);
						if ( loadCode(fileName, (offset & 0x3f0000) >>> 16, offset & 0x3fff) == false ) {
							return;
						}
					}
				}

				// all binary fragments loaded, now dump the final code space as complete output file...
				RandomAccessFile cardFile = new RandomAccessFile(outputFilename, "rw");
				for (int b=0; b<appCardBanks; b++) {
					byte bankDump[] = banks[b].dumpBytes(0, Bank.BANKSIZE);
					cardFile.write(bankDump);
				}
				cardFile.close();

				if (splitBanks == true) {
					// Also dump the final binary as 16K bank files...
					int topBank = 0x3F;
					for (int b=appCardBanks-1; b>=0; b--) {
						cardFile = new RandomAccessFile(outputFilename + "." + topBank--, "rw");
						byte bankDump[] = banks[b].dumpBytes(0, Bank.BANKSIZE);
						cardFile.write(bankDump);
						cardFile.close();
					}
				}
			}
		} catch (FileNotFoundException e) {
			System.err.println("Couldn't load file image:\n" + e.getMessage() + "\nprogram terminated.");
			return;
		} catch (IOException e) {
			System.err.println("Problem with bank image or I/O:\n" + e.getMessage() + "\nprogram terminated.");
			return;
		}
	}

	/**
	 * When no command line arguments have been specified, write some explanations
	 * to the shell.
	 */
	private void displayCmdLineSyntax() {
		System.out.println("Syntax:");
		System.out.println("[-szc Size] memdump.file input1.file offset {inputX.file offset}");
		System.out.println("or");
		System.out.println("-f loadmap.file\n");
		System.out.println("Usage: Load binary files into one or several 16K memory bank, and save it");
		System.out.println("all to a new file. Offsets are specified in hex (truncated to 16K offsets).\n");
		System.out.println("Larger application cards is created by optionally specifying size in K, eg.");
		System.out.println("32 ... up to 1024K. Offsets are then extended with relative bank number,");
		System.out.println("for example 3fc000 for bank 3f (top), offset 0000 (start of top bank).\n");
		System.out.println("If you need to split a large assembled card into 16 bank on the output,");
		System.out.println("use the -c switch, eg. -szc 64 will make both a 64K file and 4 files,");
		System.out.println("added with .63 for the top bank of the card and downwards.\n");
		System.out.println("Example, using default 16K application bank dump (java -jar makeapp.jar):");
		System.out.println("appl.epr code.bin c000 romhdr.bin 3fc0");
		System.out.println("(load 1st file at 0000, 2nd file at 3fc0, and save 16K bank to appl.epr)\n");
		System.out.println("Example, using a 32K application bank dump (and separate 16K bank files):");
		System.out.println("-szc 32 bigappl.epr mth.bin 3e0000 code.bin 3fc000 romhdr.bin 3f3fc0\n");
		System.out.println("-----------------------------------------------------------------------");
		System.out.println("Using the -f <loadmap.file> option, all load instructions are specified");
		System.out.println("in the 'loadmap' text file, having one load directive per line.");
		System.out.println("Comments are allowed (to document the loadmap) using ; (semicolon).");
		System.out.println("Directives, and arguments in <>, are specified in the following order: ");
		System.out.println("1) outputfile <filename>  ; filename of combined binary.");
		System.out.println("2) size <size>            ; total file size K, from 16K-1024K");
		System.out.println("3) save16k                ; save output as 16K bank files (optional)");
		System.out.println("x) <input.file> <offset>  ; the binary file fragment to load at offset");
	}


	/**
	 * Command Line Entry for MakeApp utility.
	 * @param args
	 */
	public static void main(String[] args) {
		MakeApp ma = new MakeApp();
		ma.parseArgs(args);
	}
}
