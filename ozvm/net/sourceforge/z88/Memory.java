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
import java.io.IOException;
import java.io.InputStream;
import java.io.RandomAccessFile;
import java.net.JarURLConnection;
import java.net.URL;

import net.sourceforge.z88.filecard.FileArea;
import net.sourceforge.z88.filecard.FileAreaNotFoundException;


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
 */
public final class Memory {
		
	private static final class singletonContainer {
		static final Memory singleton = new Memory();  
	}
	
	public static Memory getInstance() {
		return singletonContainer.singleton;
	}
	
	/**
	 * The Z88 memory organisation.
	 * Array for 256 x 16K banks = 4Mb memory
	 */
	private Bank memory[];

	/**
	 * Null bank. This is used in for unassigned banks,
	 * ie. when a card slot is empty in the Z88
	 * The contents of this bank contains 0xFF and is
	 * write-protected (just as an empty bank in an Eprom).
	 */
	private VoidBank nullBank;
	
	private Memory() {
		memory = new Bank[256]; // The Z88 memory addresses 256 banks = 4MB!		

		nullBank = new VoidBank();
		for (int bank = 0; bank < memory.length; bank++)
			memory[bank] = nullBank;
	}
	
	/**
	 * Get Bank, referenced by it's number [0-255] in the BLINK memory model
	 *
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
	 * @param bank number of the 4MB memory model (0-255).
	 * @param bits to be written.
	 */
	public void setByte(final int offset, final int bankno, final int bits) {
		getBank(bankno).setByte(offset, bits);
	}

	
	/**
	 * The "internal" write byte method to be used in
	 * the OZvm debugging environment, allowing complete
	 * write permission.
	 *
	 * @param extAddress 24bit extended address
	 * @param bits to be written.
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
	 * @param offset
	 * @param bank
	 * @return int
	 */
	public int getByte(final int offset, final int bankno) {
		return getBank(bankno).getByte(offset);
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
	 * Size is in modulus 16Kb.
	 * Slot 0 (1Mb): banks 00 - 1F (ROM, 512Kb), banks 20 - 3F (RAM, 512Kb)
	 * Slot 1 (1Mb): banks 40 - 7F (RAM or EPROM)
	 * Slot 2 (1Mb): banks 80 - BF (RAM or EPROM)
	 * Slot 3 (1Mb): banks C0 - FF (RAM or EPROM)
	 *
	 * @param card
	 * @param slot
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
	}

	/**
	 * Remove inserted card, ie. null'ify the banks for the specified slot.
	 *   
	 * @param slot (1-3)
	 */
	public void removeCard(int slot) {		
	}
	
	/**
	 * Check if slot is empty (ie. no cards inserted)
	 *
	 * @param slotNo
	 * @return true, if slot is empty
	 */
	public final boolean isSlotEmpty(final int slotNo) {
		// convert slot number to top bank number of specified slot
		// if top bank of slot is of type NullBank, then we know it's empty...
		return memory[(((slotNo & 3) << 6) | 0x3F)] == nullBank;
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
	 * @param size of Eprom in K
	 * @param eprType "27C" (UV Eprom), "28F" (Intel FlashFile) or "29F" (Amd Flash Memory)
	 * @return true, if card was inserted, false, if illegal size and type
	 */
	public boolean insertEprCard(int slot, int size, String eprType) {
		int totalEprBanks, totalSlotBanks, curBank;
		int eprSubType = 0;

		slot %= 4; // allow only slots 0 - 3 range.
		size -= (size % (Bank.SIZE/1024));
		totalEprBanks = size / (Bank.SIZE/1024); // number of 16K banks in Eprom Card
		if (eprType.compareToIgnoreCase("27C") == 0) {
			// Traditional UV Eproms (all size configurations allowed)
			if (totalEprBanks <= 2) 
				eprSubType = EpromBank.VPP32KB;
			else
				eprSubType = EpromBank.VPP128KB;			
		}
		if (eprType.compareToIgnoreCase("28F") == 0) {
			// Intel Flash Eprom Cards exists in 512K and 1MB configurations
			switch(totalEprBanks) {
				case 32: eprSubType = IntelFlashBank.I28F004S5; break;
				case 64: eprSubType = IntelFlashBank.I28F008S5; break;
				default:
					return false; // Only 512K or 1MB Intel Flash Cards are allowed.
			}
		}
		if (eprType.compareToIgnoreCase("29F") == 0) {
			// Amd Flash Eprom Cards exists in 128K, 512K and 1MB configurations 
			switch(totalEprBanks) {
				case 8: eprSubType = AmdFlashBank.AM29F010B; break;
				case 32: eprSubType = AmdFlashBank.AM29F040B; break;
				case 64: eprSubType = AmdFlashBank.AM29F080B; break;
				default:
					return false; // Only 128K, 512K or 1MB Amd Flash Cards are allowed.
			}
		}
			
		Bank banks[] = new Bank[totalEprBanks]; // the card container
		for (curBank = 0; curBank < totalEprBanks; curBank++) {
			if (eprType.compareToIgnoreCase("27C") == 0) banks[curBank] = new EpromBank(eprSubType); 
			if (eprType.compareToIgnoreCase("28F") == 0) banks[curBank] = new IntelFlashBank(eprSubType);
			if (eprType.compareToIgnoreCase("29F") == 0) banks[curBank] = new AmdFlashBank(eprSubType);
		}

		insertCard(banks, slot); // insert the physical card into Z88 memory		
		return true;
	}

	/**
	 * Insert empty File Card into Z88 memory system, slots 0 - 3. 
	 * Eprom Card is loaded from bottom bank of slot and upwards.
	 * 
	 * Slot 1 (1Mb):   banks 40 - 7F
	 * Slot 2 (1Mb):   banks 80 - BF
	 * Slot 3 (1Mb):   banks C0 - FF
	 * 
	 * @param slot number which Card will be inserted into (1-3)
	 * @param size of Card in K
	 * @param eprType "27C" (UV Eprom), "28F" (Intel FlashFile) or "29F" (Amd Flash Memory)
	 * @return true, if card was inserted, false, if illegal size and type
	 */
	public boolean insertFileEprCard(int slot, int size, String eprType) {
		if (insertEprCard(slot, size, eprType) == true) {
			// make File Header at top of Card...
			if (FileArea.createFileHeader(((slot & 3) << 6) | 0x3F) == true) {
				try {
					FileArea fa = new FileArea(slot);
					fa.createFileArea(); // format file area...
				} catch (FileAreaNotFoundException e) {
					// this shouldn't happen...
					return false;
				}
			}

			return true;
		} else {
			return false;
		}
	}
	
	
	/**
	 * Insert RAM Card into Z88 memory system.
	 * RAM may be inserted into slots 0 - 3.
	 * RAM is loaded from bottom bank of slot and upwards.
	 * Slot 0 (512Kb): banks 20 - 3F
	 * Slot 1 (1Mb):   banks 40 - 7F
	 * Slot 2 (1Mb):   banks 80 - BF
	 * Slot 3 (1Mb):   banks C0 - FF
	 *
	 * Slot 0 is special; max 512K RAM in top 512K address space.
	 * (bottom 512K address space in slot 0 is reserved for ROM, banks 00-1F)
	 */
	public void insertRamCard(int size, int slot) {
		int totalRamBanks, totalSlotBanks, curBank;

		slot %= 4; // allow only slots 0 - 3 range.
		size -= (size % Bank.SIZE);
		totalRamBanks = size / Bank.SIZE; // number of 16K banks in Ram Card

		Bank ramBanks[] = new RamBank[totalRamBanks]; // the RAM card container
		for (curBank = 0; curBank < totalRamBanks; curBank++) {
			ramBanks[curBank] = new RamBank(); // bank is assigned to the card, not yet to the Z88 memory model...
		}

		insertCard(ramBanks, slot); // insert the physical card into Z88 memory
	}


	/**
	 * Load ROM image (from opened file ressource) into Z88 memory system, slot 0.
	 *
	 * @param rom
	 * @throws IOException
	 */
	public void loadRomBinary(RandomAccessFile rom) throws IOException {
		if (rom.length() > (1024 * 512)) {
			throw new IOException("Max 512K ROM!");
		}
		if (rom.length() % (Bank.SIZE * 2) > 0) {
			throw new IOException("ROM must be in even banks!");
		}

		Bank romBanks[] = new Bank[(int) rom.length() / Bank.SIZE];
		// allocate ROM container
		byte bankBuffer[] = new byte[Bank.SIZE];
		// allocate intermediate load buffer

		for (int curBank = 0; curBank < romBanks.length; curBank++) {
			// A little cadeau to Thierry Peycru to simulate his modified Z88 motherboard...
			switch((int) rom.length()) {
				case 131072: 
					romBanks[curBank] = new AmdFlashBank(AmdFlashBank.AM29F010B); // 128K, use the AMD Flash Memory AM29F010B 
					break;
				case 524288: 
					romBanks[curBank] = new AmdFlashBank(AmdFlashBank.AM29F010B); // 512K, use the AMD Flash Memory AM29F040B 
					break;
				default:
					romBanks[curBank] = new RomBank();
			}
			rom.readFully(bankBuffer); // load 16K from file, sequentially
			romBanks[curBank].loadBytes(bankBuffer, 0);
			// and load fully into bank
		}

		// Finally, check for Z88 ROM Watermark
		if (romBanks[romBanks.length-1].getByte(0x3FFB) != 0x81 &
		    romBanks[romBanks.length-1].getByte(0x3FFE) != 'O' &
		    romBanks[romBanks.length-1].getByte(0x3FFF) != 'Z') {
				throw new IOException("This is not a Z88 ROM");
	    }

		// complete ROM image now loaded into container
		// insert container into Z88 memory, slot 0, banks $00 onwards.
		insertCard(romBanks, 0);
		Blink.getInstance().setRAMS(getBank(0));		// point at ROM bank 0
	}


	/**
	 * Load Card Image (from opened file ressource) into Z88 memory system,
	 * at defined slot. The file size of the Card image will determine the
	 * hardware Eprom Card emulation:
	 * <pre>
	 *   16/32K: UV Eprom (27C)
	 *     128K: AM29F010B Flash Card (29F)
	 *     256K: UV Eprom (27C)
	 *     512K: I28F004S5 Flash Card
	 *    1024K: AM29F080B Flash Card
	 * </pre> 
	 *
	 * @param slot where to insert card image
	 * @param card contains the binary image
	 * @throws IOException
	 */
	public void loadCardBinary(int slot, String cardType, RandomAccessFile card) throws IOException {
		
		if (card.length() > (1024 * 1024)) {
			throw new IOException("Max 1024K Card!");
		}
		if (card.length() % Bank.SIZE > 0) {
			throw new IOException("Card must be in 16K sizes!");
		}

		Bank cardBanks[] = new Bank[(int) card.length() / Bank.SIZE];
		// allocate EPROM container
		byte bankBuffer[] = new byte[Bank.SIZE];
		// allocate intermediate load buffer
		
		for (int curBank = 0; curBank < cardBanks.length; curBank++) {
			switch(cardBanks.length) {
			
			case 1:
			case 2:
				// 32K size exists only as Eprom
				cardBanks[curBank] = new EpromBank(EpromBank.VPP32KB);
				break;
			case 8:
				// 128K size exists as Eprom or Amd Flash Card				
				if (cardType.compareToIgnoreCase("29F") == 0)
					cardBanks[curBank] = new AmdFlashBank(AmdFlashBank.AM29F010B);
				else
					cardBanks[curBank] = new EpromBank(EpromBank.VPP128KB);
				break;
			case 16:
				// 256K size exists only as Eprom
				cardBanks[curBank] = new EpromBank(EpromBank.VPP128KB);
				break;
			case 32:
				// 512K size exists as Intel or Amd Flash Card
				if (cardType.compareToIgnoreCase("29F") == 0)
					cardBanks[curBank] = new AmdFlashBank(AmdFlashBank.AM29F040B);
				else
					cardBanks[curBank] = new IntelFlashBank(IntelFlashBank.I28F004S5);
				break;
			case 64:
				// 1024K size exists as Intel or Amd Flash Card
				if (cardType.compareToIgnoreCase("29F") == 0)
					cardBanks[curBank] = new AmdFlashBank(AmdFlashBank.AM29F080B);
				else
					cardBanks[curBank] = new IntelFlashBank(IntelFlashBank.I28F008S5);
				break;
			default:
				// all other sizes will be interpreted as UV EPROM's 
				// that can be programmed using 128K type specs.
				cardBanks[curBank] = new EpromBank(EpromBank.VPP128KB);
				break;
			}

			card.readFully(bankBuffer); // load 16K from file, sequentially
			cardBanks[curBank].loadBytes(bankBuffer, 0);
			// and load fully into bank
		}

		// Check for Z88 Application Card Watermark
		if (cardBanks[cardBanks.length-1].getByte(0x3FFE) == 'O' &
			cardBanks[cardBanks.length-1].getByte(0x3FFF) == 'Z') {
			Gui.displayRtmMessage("Application Card was inserted into slot " + slot);
		} else {
			// Check for Z88 File Card Watermark
			if (cardBanks[cardBanks.length-1].getByte(0x3FFE) == 'o' &
				cardBanks[cardBanks.length-1].getByte(0x3FFF) == 'z') {
				Gui.displayRtmMessage("File Card was inserted into slot " + slot);
			} else {
				throw new IOException("This is not a Z88 Application Card nor a File Card.");
			}
		}

		// complete Card image now loaded into container
		// insert container into Z88 memory, slot x, at bottom of slot, onwards.
		insertCard(cardBanks, slot);
	}

	/**
	 * Load Card Image (from opened file ressource) on specific Eprom Card Hardware.
	 * The image will be loaded to the top of the card, eg. a 32K image will be loaded
	 * into the top two banks of the Eprom card ($3E and $3F. The remaining banks of the 
	 * Eprom card will be left untouched (initialized as being empty).
	 * 
	 * The File image must represent an Application Card or a File Eprom
	 * ("OZ" or "oz" watermark in two bytes of the file). 
	 *
	 * @param slot to insert Eprom card with loaded binary image
	 * @param size of Eprom Card in K  
	 * @param type of Eprom: "27C" (UV Eprom), "28F" (Intel FlashFile) or "29F" (Amd Flash Memory)
	 * @param fileImage the File image to be loaded (in 16K boundary size)
	 * @throws IOException
	 */
	public void loadImageOnEprom(int slot, int size, String eprType, RandomAccessFile fileImage) throws IOException {
		int totalEprBanks, totalSlotBanks, curBank;
		int eprSubType = 0;

		if (fileImage.length() > (1024 * size)) {
			throw new IOException("Binary image larger than specified Eprom Card size!");
		}
		if (fileImage.length() % Bank.SIZE > 0) {
			throw new IOException("Binary image must be in 16K sizes!");
		}

		slot %= 4; // allow only slots 0 - 3 range.
		size -= (size % (Bank.SIZE/1024));
		totalEprBanks = size / (Bank.SIZE/1024); // number of 16K banks in Eprom Card
		if (eprType.compareToIgnoreCase("27C") == 0) {
			// Traditional UV Eproms (all size configurations allowed)
			if (totalEprBanks <= 2) 
				eprSubType = EpromBank.VPP32KB;
			else
				eprSubType = EpromBank.VPP128KB;			
		}
		if (eprType.compareToIgnoreCase("28F") == 0) {
			// Intel Flash Eprom Cards exists in 512K and 1MB configurations
			switch(totalEprBanks) {
				case 32: eprSubType = IntelFlashBank.I28F004S5; break;
				case 64: eprSubType = IntelFlashBank.I28F008S5; break;
				default:
					throw new IOException("Illegal size for Intel Flash Card type!");
			}
		}
		if (eprType.compareToIgnoreCase("29F") == 0) {
			// Amd Flash Eprom Cards exists in 128K, 512K and 1MB configurations 
			switch(totalEprBanks) {
				case 8: eprSubType = AmdFlashBank.AM29F010B; break;
				case 32: eprSubType = AmdFlashBank.AM29F040B; break;
				case 64: eprSubType = AmdFlashBank.AM29F080B; break;
				default:
					throw new IOException("Illegal size for Amd Flash Card type!");
			}
		}
		
		// Create the Eprom card (of specified type)...
		Bank banks[] = new Bank[totalEprBanks]; 
		for (curBank = 0; curBank < totalEprBanks; curBank++) {
			if (eprType.compareToIgnoreCase("27C") == 0) banks[curBank] = new EpromBank(eprSubType); 
			if (eprType.compareToIgnoreCase("28F") == 0) banks[curBank] = new IntelFlashBank(eprSubType);
			if (eprType.compareToIgnoreCase("29F") == 0) banks[curBank] = new AmdFlashBank(eprSubType);
		}
		
		// allocate intermediate load buffer
		byte bankBuffer[] = new byte[Bank.SIZE];
		for (curBank = totalEprBanks - ((int) fileImage.length()/Bank.SIZE); curBank < totalEprBanks; curBank++) {
			fileImage.readFully(bankBuffer); // load 16K from file, sequentially
			banks[curBank].loadBytes(bankBuffer, 0); // and load fully into bank
		}

		// Check for Z88 Application Card Watermark
		if (banks[banks.length-1].getByte(0x3FFE) == 'O' &
			banks[banks.length-1].getByte(0x3FFF) == 'Z') {
			Gui.displayRtmMessage("Application Card was inserted into slot " + slot);
		} else {
			// Check for Z88 File Card Watermark
			if (banks[banks.length-1].getByte(0x3FFE) == 'o' &
				banks[banks.length-1].getByte(0x3FFF) == 'z') {
				Gui.displayRtmMessage("File Card was inserted into slot " + slot);
			} else {
				throw new IOException("This is not a Z88 Application Card nor a File Card.");
			}
		}

		// complete Card image now loaded into container
		// insert container into Z88 memory, slot x, at bottom of slot, onwards.
		insertCard(banks, slot);
	}
	

	/**
	 * Load file image (from opened file ressource) into Z88 Bank offset.
	 * The file image needs to fit within the 16K bank boundary. The specified
	 * bank must be part of an existing memory resource, ie. it is not possible
	 * to load a file binary into a bank that is part of an empty slot.
	 *  
	 * @param extAddress
	 * @param file
	 * @throws IOException
	 */
	public void loadBankBinary(final int extAddress, final RandomAccessFile file) throws IOException {
		int bank = (extAddress >>> 16) & 0xFF;
		int offset = extAddress & 0x3FFF;
		Bank b = getBank(bank); 
		
		if ( offset+file.length() > Bank.SIZE) {
			throw new IOException("File image exceeds Bank boundary!");
		}

		if (b instanceof VoidBank == true) {
			throw new IOException("Bank is part of empty slot!");
		}

		byte bankBuffer[] = new byte[(int) file.length()];	// allocate intermediate load buffer
		file.readFully(bankBuffer); 						// load file image into buffer
		b.loadBytes(bankBuffer, offset);					// and move buffer into bank
	}

	
	/**
	 * Load ROM image (from opened file ressource inside JAR)
	 * into Z88 memory system, slot 0.
	 *
	 * @param jarRessource
	 * @throws IOException
	 */
	public void loadRomBinary(URL jarRessource) throws IOException {
		JarURLConnection jarConnection = (JarURLConnection)jarRessource.openConnection();

		if (jarConnection.getJarEntry().getSize() > (1024 * 512)) {
			throw new IOException("Max 512K ROM!");
		}
		if (jarConnection.getJarEntry().getSize() % Bank.SIZE > 0) {
			throw new IOException("ROM must be in 16K sizes!");
		}

		Bank romBanks[] = new Bank[(int) jarConnection.getJarEntry().getSize() / Bank.SIZE];
		// allocate ROM container
		byte bankBuffer[] = new byte[Bank.SIZE];
		// allocate intermediate load buffer

		InputStream is = jarConnection.getInputStream();
		BufferedInputStream bis = new BufferedInputStream( is, Bank.SIZE );

		for (int curBank = 0; curBank < romBanks.length; curBank++) {
			switch((int) jarConnection.getJarEntry().getSize()) {
				case 131072: 
					romBanks[curBank] = new AmdFlashBank(AmdFlashBank.AM29F010B); // 128K, use the AMD Flash Memory AM29F010B 
					break;
				case 524288: 
					romBanks[curBank] = new AmdFlashBank(AmdFlashBank.AM29F010B); // 512K, use the AMD Flash Memory AM29F040B 
					break;
				default:
					romBanks[curBank] = new RomBank();
			}

			int bytesRead = bis.read(bankBuffer, 0, Bank.SIZE);	// load 16K from file, sequentially
			romBanks[curBank].loadBytes(bankBuffer, 0); 		// and load fully into bank
		}

		// complete ROM image now loaded into container
		// insert container into Z88 memory, slot 0, banks $00 onwards.
		insertCard(romBanks, 0);
		Blink.getInstance().setRAMS(getBank(0));	// point at ROM bank 0
	}

	/**
	 * Return the size of inserted Eprom/Rom/Flash Cards in 16K banks.
	 * If no card is available in specified slot, -1 is returned.
	 * 
	 * @return number of 16K banks of inserted Card
	 */
	public int getCardSize(final int slotNo) {		
		int bankNo = ((slotNo & 3) << 6);	// bottom bank number of slot
		int bottomBankNo = bankNo;
		int maxBanks;

		if (isSlotEmpty(slotNo) == true)
			return -1;
		else {
			if (slotNo == 0) 
				maxBanks = 32;	// internal ROM may be max 512K (banks 00 - 1F)
			else
				maxBanks = 64;	// each external slot has 1Mb address range
			
			Bank bottomBank = getBank(bottomBankNo);
			int cardSize = 1;
			while (++bankNo < (bottomBankNo+maxBanks)) {
				if (getBank(bankNo) != bottomBank) 
					cardSize++;
				else 
					break;				
			}
			
			return cardSize;			
		}
	}
}
