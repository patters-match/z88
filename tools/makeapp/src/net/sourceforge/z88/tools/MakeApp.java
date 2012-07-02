/*
 * MakeApp.java
 * (C) Copyright Gunther Strube (gstrube@gmail.com), 2005-2012
 * (C) Copyright Garry Lancaster 2012
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
 * @author <A HREF="mailto:gstrube@gmail.com">Gunther Strube</A>
 *
 */

package net.sourceforge.z88.tools;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.InputStreamReader;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.util.zip.CRC32;


/**
 * Simple command line tool that creates a 16K or larger card file where
 * small binary files are loaded into at various offsets.
 * Finally, the card is saved to a new file.
 *
 * The tool is used to build the Z88 ROM or to combine various Z88 application
 * files into a single application card of 16K or larger.
 */
public class MakeApp {

	private static final String progVersion = "MakeApp V1.0.2";

	private static final char[] hexcodes = {'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'};
	private static final String revisionMacroSearchKey = "$RevisionDescriptionString$";
	private static final String revisionFilename = "revision.tmp";
	private static final String romUpdateConfigFilename = "romupdate.cfg";

	private int appCardBanks = 1; // default output is 16K bank
	private int appCardSize = 16;
	private boolean splitBanks;
        private boolean generateCardId;
	private int lineNo;
	private int romUpdateConfigFileType;

	private RomBank[] banks;
	private String outputFilename;
	private String loadmapFilename;

    public MakeApp() {
    }

	/**
	 * Return Hex 8bit string in XXh zero prefixed format.
	 *
	 * @param b The 8bit integer to be converted to hex string
	 * @param hexTrailer append 'h' if true.
	 * @return String
	 */
	public static final String byteToHex(final int b, final boolean hexTrailer) {
		StringBuffer hexString = new StringBuffer(5);

		hexString.append(hexcodes[b/16]).append(hexcodes[b%16]);
		if (hexTrailer == true) hexString.append('h');

		return hexString.toString();
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
	private int getHexValue(String v) {
		int hexValue;

		try {
			hexValue = Integer.parseInt(v, 16);
		} catch (NumberFormatException e) {
			System.err.println(
					loadmapFilename + ", at line " + lineNo + ", " +
					"Illegal hexadecimal value. Use only digits 0-9, A-F.");
			hexValue = -1;
		}

		return hexValue;
	}

	/**
	 * Parse integer value from string (fetched from command line or loadmap
	 * file) and interpret it as the card size. The value must be a valid card
	 * size and not larger than 1Mb (max size of Z88 slot).
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
			System.err.println(
					loadmapFilename + ", at line " + lineNo + ", " +
					"Illegal card size. Use only: 16K, 32K, 64K, 128K, 256K, 512K or 1024K.");
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

		// make sure that path names in loadmap file follow the OS convention...
		if ("/" != System.getProperty("file.separator"))
			filename = filename.replace('/', System.getProperty("file.separator").charAt(0));
		if ("\\" != System.getProperty("file.separator"))
			filename = filename.replace('\\', System.getProperty("file.separator").charAt(0));

		try {
			binaryInputFile = new RandomAccessFile(filename, "r");
			int codeSize = (int) binaryInputFile.length();
			codeBuffer = new byte[codeSize];
			binaryInputFile.readFully(codeBuffer);
			binaryInputFile.close();

		} catch (FileNotFoundException e) {
			codeBuffer = null;
		} catch (IOException e) {
			codeBuffer = null;
		}

		return codeBuffer;
	}

	/**
	 * Create "romupdate.cfg" file for Application card.
	 */
	private void createRomUpdCfgFile_AppCard() {
		if (appCardBanks > 1) {
			System.err.println("RomUpdate currently only supports 16K application cards. 'romupdate.cfg' not created.");
			return;
		}

		if (banks[0].containsAppHeader() == false)
			System.err.println("Application card not recognized. 'romupdate.cfg' not created.");
		else {
			try {
				RandomAccessFile cardFile = new RandomAccessFile(romUpdateConfigFilename, "rw");
				cardFile.writeBytes("CFG.V1\n");
				cardFile.writeBytes("; filename of a single 16K bank image, CRC (32bit), pointer to application DOR in 16K file image.\n");
				cardFile.writeBytes("\"" + banks[0].getBankFileName() + "\",");
				cardFile.writeBytes("$" + Long.toHexString(banks[0].getCRC32()) + ",");
				cardFile.writeBytes("$" + addrToHex(banks[0].getAppDorOffset(), false) + "\n");
				cardFile.close();

			} catch (FileNotFoundException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}
	}

	/**
	 * Create "romupdate.cfg" file for OZ ROM in slot 0 or 1.
	 */
	private void createRomUpdCfgFile_OzSlot(int slotNo) {
		int totalBanks = 0;
		int base_slot_bank = 0;

		if (slotNo == 1)
			base_slot_bank = 64-appCardBanks;

		for (int b=0; b<appCardBanks; b++) {
			if (banks[b].isEmpty() == false)
				totalBanks++; // count total number of banks to be blown to slot 0
		}

		try {
			RandomAccessFile cardFile = new RandomAccessFile(romUpdateConfigFilename, "rw");
			cardFile.writeBytes("CFG.V4\n");
			cardFile.writeBytes("; OZ ROM, and total amount of banks to update.\n");

			cardFile.writeBytes("CD," + totalBanks + ","+'"'+"OZ V4.3 for slot "+slotNo+'"'+"\n");
			cardFile.writeBytes("; Bank file, CRC, destination bank to update (in slot " + slotNo + ").\n");

			for (int b=0; b<appCardBanks; b++) {
				if (banks[b].isEmpty() == false) {
					cardFile.writeBytes("\"" + banks[b].getBankFileName() + "\",");
					cardFile.writeBytes("$" + Long.toHexString(banks[b].getCRC32()) + ",");
					cardFile.writeBytes("$" + byteToHex( (base_slot_bank + b), false) + "\n");
				}
			}
			cardFile.close();

		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	/**
	 * Create RomUpdate.cfg file, based on loadmap directive.
	 * <pre>
	 * "romupdate oz.{0|1}"  Create romupdate.cfg using OZ ROM template
	 * "romupdate app"       Create romupdate.cfg using APP template
	 * </pre>
	 */
	private void createRomUpdCfgFile() {
		switch (romUpdateConfigFileType) {
		case 1:
			// application card
			createRomUpdCfgFile_AppCard();
			break;
		case 2:
			// OZ ROM for slot 0
			createRomUpdCfgFile_OzSlot(0);
			break;
		case 3:
			// OZ ROM for slot 1 (not yet implemented)
			createRomUpdCfgFile_OzSlot(1);
			break;
		}
	}


	/**
	 * Search for the revision text pattern and replace it with
	 * "build TTTTTTTT-RRRR-gCCCCCCC" where:
	 *  "TTTTTTT" is the last tag in the build system (normally of the
	 *            form OZ_Vx.y)
	 *  "RRRR"    is the number of commits since the tag
	 *  "CCCCCCC" is the SHA1 id of the latest commit
	 * This string is generated by the git describe command into a text
	 * file by the makeapp.sh/.bat script.
	 * If the string is too large to fit the available space (likely due
	 * to an unexpectedly-long tag name) it is truncated at the left so
	 * that the commit SHA1 id is always available).
	 */
	private void adjustRevisionKeywordMacro() {
		int offsetStart = -1;
		int bankNo=0;
		Process p = null;
		String revisionStr = null;

		while (bankNo<banks.length) {
			if ( (offsetStart = banks[bankNo].findString(revisionMacroSearchKey)) != -1)
				break;

			bankNo++;
		}

		if (offsetStart != -1) {
			// fetch Git revision text
			try 
			{ 
				if (System.getProperty("os.name").indexOf("Windows") != -1)
					p=Runtime.getRuntime().exec("cmd /c git describe --long --match OZ_V*"); 
				else
					p=Runtime.getRuntime().exec("git describe --long --match OZ_V*"); 
				
				p.waitFor(); 
				BufferedReader reader=new BufferedReader(new InputStreamReader(p.getInputStream())); 
				revisionStr=reader.readLine();
			} 
			catch(IOException e1) {} 
			catch(InterruptedException e2) {} 

			if (revisionStr == null) {
				System.err.println("Build description not found, at line " + lineNo);
				return;
			}

			String buildStr = "build ";

			// Trim revision description string at the left if necessary.
			int length = buildStr.length() + revisionStr.length();
			if (length > revisionMacroSearchKey.length()) {
				revisionStr = revisionStr.substring(length - revisionMacroSearchKey.length());
			}

			buildStr = buildStr.concat(revisionStr);

			// Pad build description string with spaces if necessary.
			while (buildStr.length() < revisionMacroSearchKey.length()) {
				buildStr = buildStr.concat(" ");
			}

			// Patch build description string where revision macro was found.
			banks[bankNo].loadBytes(buildStr.getBytes(), offsetStart);
		}
	}


	/**
	 * Parse the loadmap file for the following load directives:
	 * <pre>
	 * outputfile <filename>  ; filename of combined binary
	 * size <size>            ; total file size K, from 16K-1024K
	 * save16k                ; save output as 16K bank files
	 * patch <addr> {<byte>}  ; patch memory buffer at address with byte(s)
	 *                        ; (hex bytes are separated with spaces)
	 * </pre>
	 *
	 * Remaining directive are to be interpreted as file(names) and offset
	 * that identifies the binary fragments to be loaded into the code space.
	 *
	 * @param loadmapFilename
	 * @return true, if file was parsed successfully.
	 */
	private boolean parseLoadMapFile() {
        BufferedReader in = null;
        String str;

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
    			// System.out.println("["+  directive.length  + "," + str + "]");

	        	if (directive[0].length() > 0 ) {
	        		if (directive[0].compareToIgnoreCase("romupdate") == 0) {
	        			splitBanks = true;
	        			if (directive[1].compareToIgnoreCase("oz.1") == 0)
	        				romUpdateConfigFileType = 3;
	        			if (directive[1].compareToIgnoreCase("oz.0") == 0)
	        				romUpdateConfigFileType = 2;
	        			if (directive[1].compareToIgnoreCase("app") == 0)
	        				romUpdateConfigFileType = 1;
	        		} else if (directive[0].compareToIgnoreCase("save16k") == 0) {
	        			splitBanks = true;
                                } else if (directive[0].compareToIgnoreCase("generateCardId") == 0) {
                                        generateCardId = true;
	        		} else if (directive[0].compareToIgnoreCase("outputfile") == 0) {
	        			outputFilename = directive[1];
	        		} else if (directive[0].compareToIgnoreCase("size") == 0) {
	        			appCardSize = getCardSize(directive[1]);
						if (appCardSize != -1) {
							appCardBanks = appCardSize / 16;
						} else {
							return false;
						}
	        		} else if (directive[0].compareToIgnoreCase("patch") == 0) {
	        			if (patchBuffer(directive) == false)
	        				return false;
	        		} else {
	        			// now, create the card container based on previous loadmap directives
	        			if (banks == null)
							if (createCard() == false)	// create the card container
								return false;

	        			// all other directive are file names and offsets...
	        			if (directive.length == 2 & directive[0].length() != 0) {
							int offset = getHexValue(directive[1]);
							if (offset != -1) {
								if ( loadCode(directive[0], (offset & 0x3f0000) >>> 16, offset & 0x3fff) == false ) {
									System.err.println(loadmapFilename + ", at line " + lineNo + ", File binary couldn't be loaded.");
									return false;
								}
		        			} else {
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
			System.err.println(loadmapFilename + ", at line " + lineNo + ", Illegal bank offset.");
			return false;
		}

		return true;
	}

	/**
	 * Parse the directive and patch bytes at specified buffer locations.
	 * patchargument[1] contains the patch address, followed by byte arguments.
	 *
	 * @param patchArgument
	 * @return false if no buffer has yet been loaded or illegal numbers were parsed
	 */
	private boolean patchBuffer(String patchArgument[]) {

		if (patchArgument.length < 3) {
			System.err.println(loadmapFilename + ", at line " + lineNo + ", insufficient patch address arguments.");
			return false;
		}
		if (banks == null) {
			System.err.println(loadmapFilename + ", at line " + lineNo + ", Buffer hasn't been created yet!");
			return false;
		}

		int patchAddr = getHexValue(patchArgument[1]);
		for(int i=2; i<patchArgument.length; i++) {
			int bankNo = ((patchAddr & 0x3f0000) >>> 16) & (appCardBanks-1);
			int offset = patchAddr & 0x3fff;
			int patchByte = getHexValue(patchArgument[i]);

			if (patchAddr == -1 | patchByte == -1) {
				System.err.println(loadmapFilename + ", at line " + lineNo + ", illegal patch address arguments.");
				return false;
			}

			banks[bankNo].setByte(offset, patchByte);
			patchAddr++;
		}

		return true;
	}

	/**
	 * Load file (binary) image into card container. The image will be loaded from the
	 * specified bank and upwards in the card container.
	 * The remaining banks of the card will be left untouched
	 * (initialized as being empty). If the container has the same size as the file image, the
	 * complete container is automatically filled in natural order.
	 *
	 * @param bankNo start to load image from specified bank and upwards
	 * @param codeBuffer the binary file
	 * @throws IOException
	 */
	private void loadLargeBinary(int bankNo, byte codeBuffer[]) {

		if (codeBuffer.length > (banks.length * Bank.SIZE)) {
			throw new IllegalArgumentException("Binary image larger than specified loadmap buffer!");
		}
		if (codeBuffer.length % Bank.SIZE > 0) {
			throw new IllegalArgumentException("Binary image must be in 16K sizes!");
		}
		if ((codeBuffer.length % Bank.SIZE) > banks.length) {
			throw new IllegalArgumentException("Binary image larger than specified loadmap buffer!");
		}

		int copyOffset = 0;
		byte bankBuffer[] = new byte[Bank.SIZE]; // allocate intermediate load buffer
		while (copyOffset < codeBuffer.length) {
			System.arraycopy(codeBuffer, copyOffset, bankBuffer, 0, Bank.SIZE);
			banks[bankNo++].loadBytes(bankBuffer, 0);

			copyOffset += Bank.SIZE;
		}
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

		if (codeBuffer.length > Bank.SIZE) {
			loadLargeBinary(bankNo, codeBuffer);
		} else {
			if ((codeBuffer.length + offset) > Bank.SIZE ) {
				System.err.println(filename + ": code block at offset " + addrToHex(offset,true) +
						" > crosses 16K bank boundary by " + ((codeBuffer.length + offset) - Bank.SIZE) + " bytes !");
				return false;
			}

			if (banks == null) {
				System.err.println(loadmapFilename + ", at line " + lineNo + ", Buffer hasn't been created yet!");
				return false;
			}

			for (int b=0; b<codeBuffer.length; b++) {
				if ( (banks[bankNo].getByte(offset+b) & 0xff) != 0xFF ) {
					System.err.println(filename + ": code overlap was found at " + addrToHex(offset+b,true) + "!");
					return false;
				}
			}

			banks[bankNo].loadBytes(codeBuffer, offset);
		}

		return true;
	}

	/**
	 * Create a card container (buffer), based on previously defined class properties
	 * <appCardBanks>, <outputFilename>.
	 */
	private boolean createCard() {
		int topBank = 0x3F;
        String bFilename;

		if (outputFilename == null) {
			System.err.println("Couldn't create buffer, Output filename hasn't been defined yet!");
			return false;
		}

        bFilename = outputFilename;
		if (bFilename.indexOf(".") > 0) {
			bFilename = bFilename.substring(0, bFilename.indexOf("."));
		}

                if (romUpdateConfigFileType == 3 | romUpdateConfigFileType == 2) {
                    // OZ binaries are being generated..
                    bFilename += (romUpdateConfigFileType == 3) ? "s1": "s0";
                }

		banks = new RomBank[appCardBanks]; // the card container
		for (int b=appCardBanks-1; b>=0; b--) {
			banks[b] = new RomBank(topBank--); 		// container filled with memory...
			banks[b].setBankFileName(bFilename);
		}

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
					loadmapFilename = args[1];
					if (parseLoadMapFile() == false) {
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

					outputFilename = args[arg++];

					if (banks == null)
						if (createCard() == false) // create card container based on command line directives.
							return;

					// remaining arguments on command line are the file binaries to be loaded into the code space.
					while (arg < args.length) {
						String fileName = args[arg++];
						int offset = Integer.parseInt(args[arg++], 16);
						if ( loadCode(fileName, (offset & 0x3f0000) >>> 16, offset & 0x3fff) == false ) {
							return;
						}
					}
				}

                                if (generateCardId == true) {
                                        // Generate cardId by calculating CRC32 of the image files, using
                                        // bits 0..6 and 8..14 (bits 7 and 15 must be 0 in the card header).
                                        CRC32 crc = new CRC32();
                                        for (int b=0; b<appCardBanks; b++) {
                                                crc = banks[b].updateCRC32(crc);
                                        }

                                        short cardId = (short)(crc.getValue() & 0x7f7f);
		                        System.out.println("Generated card ID:" + addrToHex(cardId, false));

			                banks[appCardBanks-1].setByte(0x3ff8, (cardId & 0xff));
			                banks[appCardBanks-1].setByte(0x3ff9, ((cardId >>> 8) & 0xff));
                                }
		
				// replace revision macro inside binary with build description.
				adjustRevisionKeywordMacro();

				// all binary fragments loaded, now dump the final code space as complete output file...
				RandomAccessFile cardFile = new RandomAccessFile(outputFilename, "rw");
				for (int b=0; b<appCardBanks; b++) {
					byte bankDump[] = banks[b].dumpBytes(0, Bank.SIZE);
					cardFile.write(bankDump);
				}
				cardFile.close();

				if (splitBanks == true) {
					// Also dump the final binary as 16K bank files (only the non-empty)...
					for (int b=appCardBanks-1; b>=0; b--) {
						if (banks[b].isEmpty() == false) {
							cardFile = new RandomAccessFile(banks[b].getBankFileName(), "rw");
							byte bankDump[] = banks[b].dumpBytes(0, Bank.SIZE);
							cardFile.write(bankDump);
							cardFile.close();
						}
					}

					// create a 'romupdate.cfg' file, if it has been directed in loadmap file.
					createRomUpdCfgFile();
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
		System.out.println(progVersion + "\n");
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
		System.out.println("4) romupdate <oz.{0|1}>   ; Create romupdate.cfg using OZ ROM template");
		System.out.println("5) romupdate <app>        ; Create romupdate.cfg using APP template");
		System.out.println("6) patch <addr> {<byte>}  ; patch memory buffer at address with byte(s)");
		System.out.println("x) <input.file> <addr>    ; the binary file fragment to load at address");
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
