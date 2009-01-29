/*
 * Memory.java
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

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FilenameFilter;
import java.io.IOException;
import java.io.InputStream;
import java.io.RandomAccessFile;
import java.net.JarURLConnection;

import net.sourceforge.z88.datastructures.SlotInfo;
import net.sourceforge.z88.filecard.FileArea;


/**
 * This class represents the 4Mb addressable memory model in the Z88, comprised
 * of 16K memory blocks or banks of memory. The characteristics of a bank can be
 * that it's part of a Ram card (or the internal memory of the Z88),
 * an Eprom card or a 1MB Flash Card.
 *
 * Further, the memory I/O characteristics of the bank can change if it
 * is located inside slot 3 and Eprom Programming is enabled in Blink
 * (the VPP Pin is enabled on the chip that is inserted in slot 3):
 * Depending on the bank type, all memory I/O will behave as the specified
 * hardware (U/V Eproms or Flash Card) when VPP is set (by the Blink).
 *
 * Databus access to bank is 8 bits, Z80 hardware. Therefore, the Blink
 * is responsible for reading 16bit values and getting cross bank boundary
 * words (lower byte at BankX, offset 3FFFh and high byte at BankY, offset 0000h).
 *
 * Apart from the core memory I/O functionality, this class also contains
 * high level utilities to insert/load/dump card resources from/to the host
 * filing system.
 */
public final class Memory {

	/**
	 * The Z88 memory organisation.
	 * Array for 256 x 16K banks = 4Mb memory
	 */
	private Bank memory[];

	/**
	 * Null bank. This is used in for unassigned banks,
	 * ie. when a card slot is empty in the Z88.
	 * The contents of this bank contains random data and is
	 * write-protected.
	 */
	private VoidBank nullBank;

	/** Constructor */
	public Memory() {
		// The Z80 (using Blink) can address 256 banks = 4MB memory
		memory = new Bank[256];

		nullBank = new VoidBank();
		setVoidMemory();
	}


	/**
	 * Get reference to Bank, identified by it's number [0-255]
	 * in the BLINK memory model.
	 *
	 * @param bankNo
	 * @return Bank
	 */
	public final Bank getBank(final int bankNo) {
		return memory[bankNo & 0xFF];
	}

	/**
	 * Install Bank entity into memory model (0-255).
	 *
	 * @param bank
	 * @param bankNo
	 */
	public final void setBank(final Bank bank, final int bankNo) {
		bank.setBankNumber(bankNo);
		memory[bankNo & 0xFF] = bank;
	}

	/**
	 * The "internal" write byte method to be used in
	 * the OZvm debugging environment, allowing complete
	 * write permission.
	 *
	 * @param offset within the 16K memory bank.
	 * @param bankNo number of the 4MB memory model (0-255).
	 * @param bits byte to be written.
	 */
	public void setByte(final int offset, final int bankno, final int bits) {
		getBank(bankno).setByte(offset, bits);
	}


	/**
	 * The "internal" write byte method to be used in
	 * the OZvm debugging environment, allowing complete
	 * write permission (no effect in empty slots, though!).
	 *
	 * @param extAddress 24bit extended address
	 * @param bits byte to be written.
	 */
	public void setByte(final int extAddress, final int bits) {
		setByte(extAddress & 0x3FFF, extAddress >>> 16, bits);
	}


	/**
	 * The "internal" read byte method to be used in the OZvm
	 * debugging environment.
	 *
	 * @param extAddress 24bit extended address
	 * @return int the byte at extended address
	 */
	public int getByte(final int extAddress) {
		return getByte(extAddress & 0x3FFF, extAddress >>> 16);
	}


	/**
	 * The "internal" read byte method to be used in the OZvm
	 * debugging environment.
	 *
	 * @param offset (0000 - 3FFFh)
	 * @param bankNo (00 - FFh)
	 * @return byte
	 */
	public int getByte(final int offset, final int bankNo) {
		return getBank(bankNo).getByte(offset);
	}

	/**
	 * "Internal" support method.
	 *
	 * Get the next adjacent extended address (24bit) pointer.
	 * The method ensures that when the extended address pointer
	 * crosses a bank boundary, the absolute bank number of the
	 * extended address is increased and the offset is reset to zero.
	 * For example FE3FFF -> FF0000.
	 *
	 * This method is typically used by the File Area Management
	 * system (net.sourceforge.z88.filecard.FileArea & FileEntry),
	 * but might be used for other purposes.
	 *
	 * @param extAddress
	 * @return extAddress+1 (bank boundary adjusted)
	 */
	public int getNextExtAddress(final int extAddress) {
		int segmentMask = extAddress & 0xC000;	// preserve the segment mask, if any
		int offset = extAddress & 0x3FFF;		// offset is within 16K boundary
		int bankNo = extAddress >>> 16;			// get absolute bank number

		if (offset == 0x3FFF) {
			// bank boundary will be crossed...
			offset = 0x0000;
			bankNo++;
		} else {
			// still within bank boundary...
			offset++;
		}

		// re-install the segment specifier, if any
		offset = segmentMask | offset;

		// finally return the updated extended address...
		return (bankNo << 16) | offset;
	}

	/**
	 * Insert Card (RAM/ROM/EPROM) into Z88 memory system.
	 * Size is in modulus 16Kb.<br>
	 *
	 * NB: Ram Card for slot 0 is inserted at banks 20 - 3F.<br>
	 *
	 * Slot 0 (1Mb): banks 00 - 1F (ROM, 512Kb), banks 20 - 3F (RAM, 512Kb)
	 * Slot 1 (1Mb): banks 40 - 7F (RAM or EPROM)
	 * Slot 2 (1Mb): banks 80 - BF (RAM or EPROM)
	 * Slot 3 (1Mb): banks C0 - FF (RAM or EPROM)
	 *
	 * @param card[] bank container
	 * @param slot (00 - FFh)
	 */
	public void insertCard(Bank card[], int slot) {
		int totalSlotBanks, slotBank, curBank;

		if (slot == 0) {
			// Define bottom bank for ROM/RAM
			slotBank = (card[0] instanceof RamBank) ? 0x20: 0x00;
			totalSlotBanks = 32; // inserting RAM or ROM can be max 32 * 16Kb = 512Kb
		} else {
			slotBank = slot << 6; // convert slot number to bottom bank of slot
			totalSlotBanks = 64;  // slots 1 - 3 have 64 * 16Kb = 1Mb address space
		}

		for (curBank = 0; curBank < card.length; curBank++) {
			setBank(card[curBank], slotBank++);
			// "insert" 16Kb bank into Z88 memory
			--totalSlotBanks;
		}

		// - the bottom of the slot has been loaded with the Card.
		// Now, we need to fill the 1MB address space in the slot with the card.
		// Note, that most cards and the internal memory do not exploit
		// the full lMB addressing range, but only decode the lower address lines.
		// This means that memory will appear more than once within the lMB range.
		// The memory of a 32K card in slot 1 would appear at banks $40 and $41,
		// $42 and $43, ..., $7E and $7F. Alternatively a 128K EPROM in slot 3 would
		// appear at $C0 to $C7, $C8 to $CF, ..., $F8 to $FF.
		// This way of addressing is assumed by the system.
		// Note that the lowest and highest bank in an EPROM can always be addressed
		// by looking at the bank at the bottom of the 1MB address range and the bank
		// at the top respectively.
		while (totalSlotBanks > 0) {
			for (curBank = 0; curBank < card.length; curBank++) {
				memory[slotBank++] = card[curBank];
				// "shadow" card banks into remaining slot
				--totalSlotBanks;
			}
		}

		if (slot > 0)
			// the external slot connector has sensed that a card was inserted...
			slotConnectorSenseLine();

		// Check for Z88 Application Card Watermark
		if (card[card.length-1].getByte(0x3FFE) == 'O' &
			card[card.length-1].getByte(0x3FFF) == 'Z') {
			OZvm.displayRtmMessage("Application Card was inserted into slot " + slot);
		} else {
			// Check for Z88 File Card Watermark
			if (card[card.length-1].getByte(0x3FFE) == 'o' &
				card[card.length-1].getByte(0x3FFF) == 'z') {
				OZvm.displayRtmMessage("File Card was inserted into slot " + slot);
			}
		}
	}


	/**
	 * Remove inserted card in external slot,
	 * ie. null'ify the banks for the specified slot.
	 *
	 * @param slotNo (1-3)
	 * @return a transferred copy of the slot in a card container
	 */
	public Bank[] removeCard(final int slotNo) {
		Bank cardContainer[] = new Bank[getExternalCardSize(slotNo)];

		int slotBank = (slotNo & 3) << 6; // convert slot number to bottom bank of slot
		int slotTopBank = slotBank | 0x3F;

		for (int b=0; b<cardContainer.length; b++)
			cardContainer[b] = memory[slotBank+b]; // transfer card to container

		while (slotBank <= slotTopBank) {
			memory[slotBank++] = nullBank; // then "remove" it from slot (1Mb range is emptied).
		}

		// the slot connector has sensed that a card was removed...
		slotConnectorSenseLine();

		return cardContainer;
	}


	/**
	 * Dump the contents of specified slot as a file, or as a collection of 16K bank files.
	 * When a slot is dumped as 16K bank files, the convention of Garry Lancaster's ROMCombiner
	 * is followed; the slot is dumped from the top of the slot downwards, using the bank number
	 * as a filename extension. Bank numbers are slot relative, ie. 63 (3Fh) as top bank and
	 * downwards.
	 *
	 * <i>Slot 0 is handled differently</i>.<br>
	 * Since slot 0 is not a container for removable cards and is physically divided as two separate
	 * 512K addressable memory ranges, two files are generated: "rom.bin" for the lower half 1Mb
	 * range (that contains the boot ROM) and "ram.bin" for the upper half 1Mb range (that contains
	 * the default system RAM).
	 * <p>Both filenames for slot 0 overrides the <b>bankFileName</b> argument. Also, slot 0 is not
	 * dumped as 16K bank files (<b>bankFileFormat</b> argument is overridden). <b>dirName</b>
	 * are used to identify where the slot 0 contents will be dumped.</p>
	 *
	 * @param slotNumber 0-3
	 * @param bankFileFormat <b>true</b> - dump slot as 16K bank files, otherwise as one file
	 * @param dirName base directory to store files, or ""
	 * @param bankFileName core filename for slot/bank file(s)
	 * @throws IOException if file(s) can't get created or storage error
	 * @throws FileNotFoundException if there's a problem with the dir/filename(s)
	 */
	public void dumpSlot(int slotNumber, final boolean bankFileFormat, final String dirName, final String fileName)
						throws IOException, FileNotFoundException {
		int bottomBankNo, topBankNo;
		slotNumber &= 3;

		if (slotNumber == 0) {
			// dump ROM (lower 512K address range)
			dumpBanksToFile(0x00, getInternalRomSize()-1, dirName, "rom.bin");
			// dump RAM (upper 512K address range)
			dumpBanksToFile(0x20, 0x20 + getInternalRamSize()-1, dirName, "ram.bin");
		} else {
			if (isSlotEmpty(slotNumber) == false) {
				if (bankFileFormat == false) {
					// dump slot as a single file...
					bottomBankNo = slotNumber << 6;
					topBankNo = bottomBankNo + (getExternalCardSize(slotNumber)-1);
					dumpBanksToFile(bottomBankNo, topBankNo, dirName, fileName);
				} else {
					// dump slot from top bank (63 / 0x3F), downwards...
					topBankNo = (((slotNumber & 3) << 6) | 0x3F);
					bottomBankNo = topBankNo - (getExternalCardSize(slotNumber)-1);
					for (int bankNo=topBankNo; bankNo >= bottomBankNo; bankNo--) {
						if (SlotInfo.getInstance().getCardType(slotNumber) == SlotInfo.RamCard)
							dumpBanksToFile(bankNo, bankNo, dirName, fileName + "." + (bankNo & 0x3F));
						else {
							if (getBank(bankNo).isEmpty() == false)
								dumpBanksToFile(bankNo, bankNo, dirName, fileName + "." + (bankNo & 0x3F));
						}
					}

                                        if (SlotInfo.getInstance().isOzRom(slotNumber) == true)
                                            createOzRomUpdCfgFile(slotNumber, dirName, fileName);
				}
			}
		}
	}

	/**
	 * Create "romupdate.cfg" file for OZ ROM in specified external slot.
	 *
	 * @param slotNo 1-3
	 * @param exportDir base directory to cfg file
	 * @param bankFileName core filename for OZ Rom bank file(s)
         * @return true, if "romupdate.cfg" file were created
	 */
	public boolean createOzRomUpdCfgFile(int slotNo, String exportDir, String bankFileName) {
		int totalBanks = 0;
                int topBankNo, bottomBankNo;
                int appCardBanks = getExternalCardSize(slotNo);
		int base_slot_bank = 64-appCardBanks;

                if (SlotInfo.getInstance().isOzRom(slotNo) == true) {
                    topBankNo = (((slotNo & 3) << 6) | 0x3F);
                    bottomBankNo = topBankNo - (appCardBanks-1);
                    for (int bankNo=topBankNo; bankNo >= bottomBankNo; bankNo--) {
                            if (getBank(bankNo).isEmpty() == false)
                                    totalBanks++; // count total number of banks to be blown to slot 0
                    }

                    try {
                            File f = new File(exportDir + File.separator + "romupdate.cfg");
                            f.delete();

                            RandomAccessFile cardFile = new RandomAccessFile(exportDir + File.separator + "romupdate.cfg", "rw");
                            cardFile.writeBytes("CFG.V3\n");
                            cardFile.writeBytes("; OZ ROM, and total amount of banks to update.\n");

                            cardFile.writeBytes("OZ.1" + "," + totalBanks + "\n");
                            cardFile.writeBytes("; Bank file, CRC, destination bank to update (in slot " + slotNo + ").\n");

                            for (int bankNo=bottomBankNo; bankNo <= topBankNo; bankNo++) {
                                    if (getBank(bankNo).isEmpty() == false)	{
                                            cardFile.writeBytes("\"" + bankFileName + "." + (bankNo & 0x3f) + "\",");
                                            cardFile.writeBytes("$" + Long.toHexString(getBank(bankNo).getCRC32()) + ",");
                                            cardFile.writeBytes("$" + Dz.byteToHex( (slotNo << 6) | (base_slot_bank + (bankNo & 0x3f)), false) + "\n");
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

                    return true;
                } else {
                    // not an OZ rom...
                    return false;
                }
	}

	/**
	 * Internal helper method to dump the memory contents of one or several
	 * banks to the file system.
	 *
	 * @param bottomBank
	 * @param topBank
	 * @param dirName
	 * @param bankFileName
	 * @throws IOException
	 * @throws FileNotFoundException
	 */
	private void dumpBanksToFile(final int bottomBank, final int topBank, final String dirName, final String fileName)
								throws IOException, FileNotFoundException {
		RandomAccessFile expSlotFile;

		expSlotFile = new RandomAccessFile(dirName + File.separator + fileName, "rw");
		for (int bankNo=bottomBank; bankNo <= topBank; bankNo++) {
			if (getBank(bankNo) != null)
				expSlotFile.write(getBank(bankNo).dumpBytes(0, Bank.SIZE));
		}
		expSlotFile.close();
	}


	/**
	 * Check if specified slot is empty (or not).
	 *
	 * @param slotNo (0 - 3)
	 * @return true if slot is empty (no cards inserted), otherwise false
	 */
	public boolean isSlotEmpty(final int slotNo) {
		if (slotNo == 0)
			return false;	// slot 0 always contains stuff (RAM/ROM)
		else {
			int bankNo = ((slotNo & 3) << 6); // bottom bank of slot
			return getBank(bankNo) instanceof VoidBank;
		}
	}

	/**
	 * Reset Z88 to default UK V4.0 ROM with 32K RAM
	 */
	public void setDefaultSystem() {
		JarURLConnection jarConnection;

		setVoidMemory(); // remove all current memory (set to void...)

		try {
			jarConnection = (JarURLConnection) Z88.getInstance().getBlink().getClass().getResource("/Z88.rom").openConnection();
			loadRomBinary((int) jarConnection.getJarEntry().getSize(), jarConnection.getInputStream());
			Z88.getInstance().getBlink().setRAMS(getBank(0));	// point at ROM bank 0

			insertRamCard(128, 0); // set to default 128K RAM...
		} catch (IOException e) {
		}
	}

	/**
	 * Remove all memory from the system.
	 */
	public void setVoidMemory() {
		for (int bank = 0; bank < memory.length; bank++)
			memory[bank] = nullBank;
	}

	/**
	 * Scan available slots for Ram Cards, and reset them..
	 */
	public void resetRam() {
		for (int bankNo = 0; bankNo < memory.length; bankNo++) {
			if ( memory[bankNo] instanceof RamBank == true) {
				// reset ...
				for (int bankOffset = 0; bankOffset < Bank.SIZE; bankOffset++) {
					memory[bankNo].setByte(bankOffset, 0);
				}
			}
		}
	}


	/**
	 * Create empty Card container of appropriate type.
	 *
	 * @param size of Card in K
	 * @param eprType SlotInfo.* types
	 * @return Bank array, or null, if illegal size or type is specified.
	 */
	private Bank[] createCard(int size, int eprType) {
		size -= (size % (Bank.SIZE/1024));
		int totalEprBanks = size / (Bank.SIZE/1024); // number of 16K banks in Eprom Card

		Bank banks[] = new Bank[totalEprBanks]; // the card container
		for (int curBank = 0; curBank < totalEprBanks; curBank++) {
			switch(eprType) {
				case SlotInfo.RamCard:
					banks[curBank] = new RamBank();
					break;

				case SlotInfo.EpromCard:
					// Traditional UV Eproms (all size configurations allowed)
					if (totalEprBanks <= 2)
						banks[curBank] = new EpromBank(EpromBank.VPP32KB);
					else
						banks[curBank] = new EpromBank(EpromBank.VPP128KB);
					break;

				case SlotInfo.IntelFlashCard:
					// Intel Flash Eprom Cards exists in 512K and 1MB configurations
					switch(totalEprBanks) {
						case 32: banks[curBank] = new IntelFlashBank(IntelFlashBank.I28F004S5); break;
						case 64: banks[curBank] = new IntelFlashBank(IntelFlashBank.I28F008S5); break;
						default:
							return null; // Only 512K or 1MB Intel Flash Cards are allowed.
					}
					break;

				case SlotInfo.AmdFlashCard:
					// Amd Flash Eprom Cards exists in 128K, 512K and 1MB configurations
					switch(totalEprBanks) {
						case 8: banks[curBank] = new AmdFlashBank(AmdFlashBank.AM29F010B); break;
						case 32: banks[curBank] = new AmdFlashBank(AmdFlashBank.AM29F040B); break;
						case 64: banks[curBank] = new AmdFlashBank(AmdFlashBank.AM29F080B); break;
						default:
							return null; // Only 128K, 512K or 1MB Amd Flash Cards are allowed.
					}
					break;

				case SlotInfo.StmFlashCard:
					// Stm Flash Eprom Cards exists in 128K, 512K and 1MB configurations
					switch(totalEprBanks) {
						case 8: banks[curBank] = new StmFlashBank(StmFlashBank.ST29F010B); break;
						case 32: banks[curBank] = new StmFlashBank(StmFlashBank.ST29F040B); break;
						case 64: banks[curBank] = new StmFlashBank(StmFlashBank.ST29F080D); break;
						default:
							return null; // Only 128K, 512K or 1MB Stm Flash Cards are allowed.
					}
					break;

				default:
					banks[curBank] = new RomBank();
					break;
			}
		}

		return banks;
	}


	/**
	 * Insert empty Eprom Card into Z88 memory system, slots 0 - 3.
	 * Eprom Card is loaded from bottom bank of slot and upwards.
	 *
	 * Slot 0 (512Kb): banks 00 - 1F
	 * Slot 1 (1Mb):   banks 40 - 7F
	 * Slot 2 (1Mb):   banks 80 - BF
	 * Slot 3 (1Mb):   banks C0 - FF
	 *
	 * Slot 0 is special; max 512K Memory in bottom 512K address space.
	 * (bottom 512K address space in slot 0 is reserved for ROM/EPROM, banks 00-1F)
	 *
	 * @param slot number which Card will be inserted into
	 * @param sizeK of Eprom in Kb
	 * @param eprType SlotInfo.EpromCard, SlotInfo.IntelFlashCard, SlotInfo.AmdFlashCard, SlotInfo.StmFlashCard
	 * @return true, if card was inserted, false, if illegal size and type
	 */
	public boolean insertEprCard(int slot, int sizeK, int eprType) {
		slot %= 4; // allow only slots 0 - 3 range.
		Bank banks[] = createCard(sizeK, eprType);

		if (banks != null) {
			insertCard(banks, slot); // insert the physical card into Z88 memory
			return true;
		} else {
			return false;
		}
	}


	/**
	 * Insert hybrid 512K RAM / 512K AMD card in slots 1 - 3.

	 * Slot 1 (1Mb):   banks 40 - 7F
	 * Slot 2 (1Mb):   banks 80 - BF
	 * Slot 3 (1Mb):   banks C0 - FF
	 *
	 * @param slot number which Card will be inserted into
	 * @return true, if card was inserted, false, if illegal size and type
	 */
	public boolean insertRamAmdCard(int slot) {
		slot %= 4; // allow only slots 0 - 3 range.
		Bank ramBanks[] = createCard(512, SlotInfo.RamCard);
		Bank amdBanks[] = createCard(512, SlotInfo.AmdFlashCard);

		Bank cardBanks[] = new Bank[64];
		System.arraycopy(ramBanks, 0, cardBanks, 0, ramBanks.length);
		System.arraycopy(amdBanks, 0, cardBanks, ramBanks.length, amdBanks.length);

		if (ramBanks != null & amdBanks != null) {
			insertCard(cardBanks, slot); // insert the physical card into Z88 memory
			return true;
		} else {
			return false;
		}
	}


	/**
	 * Insert empty File Card (file header automatically created) into
	 * Z88 memory system, slots 0 - 3. Eprom Card is loaded from bottom
	 * bank of slot and upwards.
	 *
	 * Slot 1 (1Mb):   banks 40 - 7F
	 * Slot 2 (1Mb):   banks 80 - BF
	 * Slot 3 (1Mb):   banks C0 - FF
	 *
	 * @param slot number which Card will be inserted into (1-3)
	 * @param sizeK of Card in Kb
	 * @param eprType SlotInfo.EpromCard, SlotInfo.IntelFlashCard, SlotInfo.AmdFlashCard, SlotInfo.StmFlashCard
	 * @return true, if card was inserted, false, if illegal size and type
	 */
	public boolean insertFileCard(int slot, int sizeK, int eprType) {
		if (insertEprCard(slot, sizeK, eprType) == true) {
			return FileArea.create(slot, true); // format file area...
		} else {
			return false;
		}
	}

	/**
	 * Insert empty RAM Card into Z88 memory system, slots 0 - 3.
	 * RAM is loaded from bottom bank of slot and upwards.<br>
	 * Slot 0 (512Kb): banks 20 - 3F
	 * Slot 1 (1Mb):   banks 40 - 7F
	 * Slot 2 (1Mb):   banks 80 - BF
	 * Slot 3 (1Mb):   banks C0 - FF
	 *
	 * Slot 0 is special; max 512K RAM in top 512K address space.
	 * (bottom 512K address space in slot 0 is reserved for ROM, banks 00-1F)
	 *
	 * @param sizeK - card size in Kb, eg. 32768 for 32K
	 * @param slot (0 - 3)
	 */
	public void insertRamCard(int sizeK, int slot) {
		sizeK -= (sizeK % (Bank.SIZE/1024));

		Bank ramBanks[] = createCard(sizeK, SlotInfo.RamCard); // the RAM card container
		if (ramBanks != null)
			insertCard(ramBanks, slot & 3); // insert the physical card into Z88 memory
	}

	/**
	 * Load File Image (from opened file ressource) on specific (flash) Eprom Card Hardware.
	 * The image will be loaded to the top of the card and downwards, eg. a 32K image will be loaded
	 * into the top two banks of the Eprom card ($3E and $3F. The remaining banks of the
	 * card will be left untouched (initialized as being empty).
	 *
	 * @param slot to insert card with loaded binary image
	 * @param sizeK of Card in Kb
	 * @param eprType SlotInfo.EpromCard, SlotInfo.IntelFlashCard, SlotInfo.AmdFlashCard, SlotInfo.StmFlashCard
	 * @param fileImage the File image to be loaded (in 16K boundary size)
	 * @throws IOException
	 */
	public void loadFileImageOnCard(int slot, int sizeK, int eprType, File file) throws IOException {
		RandomAccessFile fileImage = new RandomAccessFile(file, "r");
		int fileImageSize = (int) fileImage.length();
		fileImage.close();

		if (fileImageSize > (1024 * sizeK)) {
			throw new IOException("Binary image larger than specified Card size!");
		}
		if (fileImageSize % Bank.SIZE > 0) {
			throw new IOException("Binary image must be in 16K sizes!");
		}

		Bank banks[] = createCard(sizeK, eprType);
		if (banks != null) {
			loadBinaryImageIntoContainer(banks, fileImageSize, new FileInputStream(file));

			// complete Card image now loaded into container
			// insert container into Z88 memory, slot x, at bottom of slot, onwards.
			insertCard(banks, slot & 3);
		} else {
			throw new IOException("Illegal card type or size!");
		}
	}

	/**
	 * Load a list of card images or bank images on specific Card Hardware.
	 * A (file) image more than 16K size will be loaded to the top of the card and downwards,
	 * eg. a 32K image will be loaded into the top two banks of the Eprom card ($3E and $3F).
	 * Bank images will be loaded into the bank number as specified by the filename extension.
	 *
	 * @param slot to insert card with loaded binary image
	 * @param sizeK of Card in Kb
	 * @param eprType SlotInfo.EpromCard, SlotInfo.IntelFlashCard, SlotInfo.AmdFlashCard, SlotInfo.StmFlashCard
	 * @param selectedFiles a collection of selected filenames
	 * @throws IOException
	 */
	public void loadFileImagesOnCard(int slot, int sizeK, int eprType, File selectedFiles[]) throws IOException {
		int bankNo, cardBankNo;
		sizeK -= (sizeK % (Bank.SIZE/1024));
		Bank banks[] = createCard(sizeK, eprType);
		if (banks == null) {
			throw new IOException("Illegal card type or size!");
		}

		for (int f=0; f<selectedFiles.length; f++) {
			if (selectedFiles[f].isFile() == true) {
				RandomAccessFile fimg = new RandomAccessFile(selectedFiles[f], "r");
				int fileLength = (int) fimg.length();
				fimg.close();
				if (fileLength > Bank.SIZE) {
					loadBinaryImageIntoContainer(banks, fileLength, new FileInputStream(selectedFiles[f]));
				} else {
					try {
						String filename = selectedFiles[f].getName();
						bankNo = Integer.parseInt(filename.substring(filename.lastIndexOf(".")+1));
					} catch (NumberFormatException e) {
						// this file is apparently as bank file, but without the .63 extension
						// define the bank file number as default 63
						bankNo = 63;
					}

					if (bankNo < 0 | bankNo > 63) {
						throw new IOException("Illegal bank file number (must be 0-63)!");
					}

					// load only a bank file identified with bank number,
					// that is within the card size range
					cardBankNo = (banks.length-1) - (63-bankNo);
					if (cardBankNo >= 0 ) {
						loadBankBinary(banks[cardBankNo], 0, selectedFiles[f]);
					}
				}
			}
		}

		// complete Card image now loaded into container
		// insert container into Z88 memory, slot x, at bottom of slot, onwards.
		insertCard(banks, slot & 3);
	}

	/**
	 * Load 16K bank files into specific Card Hardware.
	 * The 16K images will be loaded relative to the top of the card. The remaining banks of the
	 * card will be left untouched (initialized as being empty).
	 *
	 * Runtime messages are displayed if an Application Card or a File Card is recognized
	 * ("OZ" or "oz" watermark in top of card).
	 *
	 * @param slot insert card in slot 1-3
	 * @param sizeK of Card in Kb
	 * @param eprType SlotInfo.EpromCard, SlotInfo.IntelFlashCard, SlotInfo.AmdFlashCard, SlotInfo.StmFlashCard
	 * @param fileNameBase the base filename of the 16K bank files
	 * @throws IOException
	 */
	public void loadBankFilesOnCard(int slot, int sizeK, int eprType, String fileNameBase) throws IOException {
		int bankNo;

		sizeK -= (sizeK % (Bank.SIZE/1024));
		Bank banks[] = createCard(sizeK, eprType);
		if (banks == null) {
			throw new IOException("Illegal card type or size!");
		}

		// now, load the banks into the card...
		File bankFiles = new File(new File(fileNameBase).getParent());
		BankFilesFilter bfFilter = new BankFilesFilter(new File(fileNameBase).getName());

		String bankFileNames[] = bankFiles.list(bfFilter);
		if (bankFileNames != null) {
			for(int n=0; n<bankFileNames.length; n++) {
				try {
					bankNo = Integer.parseInt(bankFileNames[n].
									substring(bankFileNames[n].lastIndexOf(".")+1));
				} catch (NumberFormatException e) {
					// ignore this file (and get the next file)
					// this file extension is not a number...
					continue;
				}

				if (bankNo < 0 | bankNo > 63) {
					throw new IOException("Illegal bank file number (must be 0-63)!");
				}

				// load only a bank file identified with bank number,
				// that is within the card size range
				int cardBankNo = (banks.length-1) - (63-bankNo);
				if (cardBankNo >= 0 ) {
					loadBankBinary(banks[cardBankNo], 0,
							new File(bankFiles.getAbsoluteFile() + File.separator + bankFileNames[n]));
				}
			}
		}

		// complete Card image now loaded into container
		// insert container into Z88 memory, slot x, at bottom of slot, onwards.
		insertCard(banks, slot & 3);
	}

	/**
	 * Helper class to load bank files into a new card.
	 */
	private class BankFilesFilter implements FilenameFilter {
		String baseName = null;

		public BankFilesFilter(String bankFileBaseName) {
			baseName = bankFileBaseName.toLowerCase();
		}

		/**
		 * Only accept bank file names.
		 */
		public boolean accept(File arg0, String arg1) {
			return arg1.toLowerCase().startsWith(baseName);
		}
	}

	/**
	 * Load file image (from file ressource) into Z88 Bank offset.
	 * The file image needs to fit within the 16K bank boundary. The specified
	 * bank must be part of an existing memory resource, ie. it is not possible
	 * to load a file binary into a bank that is part of an empty slot.
	 *
	 * @param b
	 * @param offset
	 * @param file
	 * @throws IOException
	 */
	public void loadBankBinary(final Bank b, int offset, final File file) throws IOException {
		if (b instanceof VoidBank == true) {
			throw new IOException("Bank is part of empty slot!");
		}

		RandomAccessFile rafile = new RandomAccessFile(file, "r");
		if ( offset+rafile.length() > Bank.SIZE) {
			rafile.close();
			throw new IOException("File image exceeds Bank boundary!");
		}

		byte bankBuffer[] = new byte[(int) rafile.length()];	// allocate intermediate load buffer
		rafile.readFully(bankBuffer); 						// load file image into buffer
		rafile.close();
		b.loadBytes(bankBuffer, offset);					// and move buffer into bank
	}


	/**
	 * Load card file image of specified type into Z88 memory model.
	 *
	 * @param slot 0 - 3
	 * @param type see SlotInfo.* types
	 * @param file external file
	 * @throws IOException
	 */
	public void loadCardBinary(int slot, int type, File file) throws IOException {
		RandomAccessFile rom = new RandomAccessFile(file, "r");
		int fileLength = (int) rom.length();
		rom.close();

		loadCardBinary(slot, fileLength, type, new FileInputStream(file));
	}


	/**
	 * Load card image of specified size and type into Z88 memory model
	 * (fetched from an external file, inside a Jar or Zip file).
	 *
	 * @param size in bytes, eg. 131072 is a 128K file image
	 * @param type see SlotInfo.* types
	 * @param slot 0 - 3
	 * @param iStream
	 * @throws IOException
	 */
	public void loadCardBinary(int slot, int size, int type, InputStream iStream) throws IOException {
		slot &= 3; // only slots 0 - 3

		if ((slot == 0) & (size > 1024*512)) {
			throw new IllegalArgumentException("Max 512K size for RAM or ROM in slot 0!");
		}
		if ((slot > 0) & (size > 1024*1024)) {
			throw new IllegalArgumentException("Max 1024K size for card binary in slots 1-3!");
		}
		if (size % Bank.SIZE > 0) {
			throw new IllegalArgumentException("Card binary must be in 16K sizes!");
		}

		Bank cardBanks[] = createCard(size/1024, type); // allocate container
		if (cardBanks != null) {
			loadBinaryImageIntoContainer(cardBanks, size, iStream);

			// insert container into Z88 memory model
			insertCard(cardBanks, slot);
		} else {
			throw new IOException("Illegal card type or size!");
		}
	}

	/**
	 * Load file (binary) image into card container. The image will be loaded to the top
	 * of the container and downwards, eg. a 32K image will be loaded  into the top two banks
	 * of the Eprom card ($3E and $3F. The remaining banks of the card will be left untouched
	 * (initialized as being empty). If the container has the same size as the file image, the
	 * complete container is automatically filled in natural order.
	 *
	 * @param cardBanks the container
	 * @param imageSize size of file image in bytes
	 * @param iStream an input stream to the binary file
	 * @throws IOException
	 */
	private void loadBinaryImageIntoContainer(Bank cardBanks[], int imageSize, InputStream iStream) throws IOException {
		BufferedInputStream bis = new BufferedInputStream(iStream, Bank.SIZE);

		byte bankBuffer[] = new byte[Bank.SIZE]; // allocate intermediate load buffer
		for (int curBank = cardBanks.length - (imageSize/Bank.SIZE); curBank < cardBanks.length; curBank++) {
			bis.read(bankBuffer, 0, Bank.SIZE);	// load 16K from file, sequentially
			cardBanks[curBank].loadBytes(bankBuffer, 0); // and load fully into bank
		}
		bis.close();
	}

	/**
	 * Load ROM image (from external file ressource) into Z88 memory system, slot 0
	 * (lower 512K of address space).
	 *
	 * @param file
	 * @throws IOException
	 */
	public void loadRomBinary(File file) throws IOException, IllegalArgumentException {
		RandomAccessFile rom = new RandomAccessFile(file, "r");
		int fileLength = (int) rom.length();
		rom.close();

		loadRomBinary(fileLength , new FileInputStream(file));
	}


	/**
	 * Load ROM image from Jar/Zip ressource into Z88 memory system, slot 0
	 * (lower 512K of address space).
	 *
	 * For all sizes, except 512K, a normal ROM type will be used.
	 * For 512K, an AMD Flash Chip will assigned (this allows to update the
	 * ROM via software!)
	 *
	 * @param size ROM size in bytes, eg. 131072 is a 128K ROM
	 * @param iStream input stream from a file ressource
	 * @throws IOException
	 */
	public void loadRomBinary(int size, InputStream iStream) throws IOException, IllegalArgumentException {
		if (size > (1024 * 512)) {
			throw new IllegalArgumentException("Max 512K ROM!");
		}
		if (size % Bank.SIZE > 0) {
			throw new IllegalArgumentException("ROM must be in 16K sizes!");
		}
		if (size % (Bank.SIZE * 2) > 0) {
			throw new IllegalArgumentException("ROM must be in even banks!");
		}

		Bank romBanks[];
		if (size / Bank.SIZE == 32)
			romBanks = createCard(size/1024, SlotInfo.AmdFlashCard); // Use 512K Amd Flash for ROM
		else
			romBanks = createCard(size/1024, SlotInfo.RomCard); // Use 128K std. ROM

		loadBinaryImageIntoContainer(romBanks, size, iStream);

		// Finally, check for Z88 ROM Watermark
		boolean foundWatermark = false;
		for (int b=romBanks.length-1; b>=0; b--) {
        		if (romBanks[b].getByte(0x3FFB) == 0x81 &
        		    romBanks[b].getByte(0x3FFE) == 'O' &
        		    romBanks[b].getByte(0x3FFF) == 'Z') {
        		    foundWatermark = true;
        		    break;
        		}
       	}

        if (foundWatermark == false)
        	throw new IllegalArgumentException("This is not a Z88 ROM");

		// validated ROM image now loaded into container
		// insert container into Z88 memory, slot 0, banks $00 onwards.
		insertCard(romBanks, 0);
	}


	/**
	 * Return the size of installed ROM in slot 0, motherboard
	 * (lower 512K address space, bank 0x00 - 0x1F)
	 *
	 * @return number of 16K banks of ROM in slot 0
	 */
	public int getInternalRomSize() {
		int cardSize = 1;
		int bankNo = 0x00;

		Bank bottomBank = getBank(bankNo);
		while (++bankNo <= 0x1F) {
			if (getBank(bankNo) != bottomBank)
				cardSize++;
			else
				break;
		}

		return cardSize;
	}


	/**
	 * Return the size of installed RAM in slot 0, motherboard
	 * (upper 512K address space, banks 0x20 - 0x3F)
	 *
	 * @return number of 16K banks of RAM in slot 0
	 */
	public int getInternalRamSize() {
		int cardSize = 1;
		int bankNo = 0x20;

		Bank bottomBank = getBank(bankNo);
		while (++bankNo <= 0x3F) {
			if (getBank(bankNo) != bottomBank)
				cardSize++;
			else
				break;
		}

		return cardSize;
	}


	/**
	 * Return the size of inserted Ram/Eprom/Rom/Flash Cards in
	 * specified external slot 1-3, in 16K banks.<br>
	 * If no card is available in specified slot, -1 is returned.
	 *
	 * @return number of 16K banks of inserted Card
	 */
	public int getExternalCardSize(final int slotNo) {
		int cardSize = -1;					// preset to "no card available"...
		int bankNo = ((slotNo & 3) << 6);	// bottom bank number of slot
		int bottomBankNo = bankNo;
		int maxBanks;

		if (isSlotEmpty(slotNo) == true)
			return -1;
		else {
			if (slotNo > 0) {
				maxBanks = 64;	// each external slot has 1Mb address range

				Bank bottomBank = getBank(bottomBankNo);
				cardSize = 1;
				while (++bankNo < (bottomBankNo+maxBanks)) {
					if (getBank(bankNo) != bottomBank)
						cardSize++;
					else
						break;
				}
			}

			return cardSize;
		}
	}

	/**
	 * When a Card is inserted or removed, a NMI interrupt is signaled
	 * from the Blink (the Z80 is instructed to execute a RST 66H instruction).
	 */
	private void slotConnectorSenseLine() {
		Z88.getInstance().getBlink().awakeFromComa();
		Z88.getInstance().getProcessor().setInterruptSignal(true);
	}
}
