/*
 * FileArea.java
 * This	file is	part of	OZvm.
 *
 * OZvm	is free	software; you can redistribute it and/or modify	it under the terms of the
 * GNU General Public License as published by the Free Software	Foundation;
 * either version 2, or	(at your option) any later version.
 * OZvm	is distributed in the hope that	it will	be useful, but WITHOUT ANY WARRANTY;
 * without even	the implied warranty of	MERCHANTABILITY	or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * You should have received a copy of the GNU General Public License along with	OZvm;
 * see the file	COPYING. If not, write to the
 * Free	Software Foundation, Inc., 59 Temple Place - Suite 330,	Boston,	MA 02111-1307, USA.
 *
 * @author <A HREF="mailto:gbs@users.sourceforge.net">Gunther Strube</A>
 * $Id$
 *
 */
package net.sourceforge.z88.filecard;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.util.LinkedList;
import java.util.ListIterator;
import java.util.Random;

import net.sourceforge.z88.AmdFlashBank;
import net.sourceforge.z88.GenericAmdFlashBank;
import net.sourceforge.z88.Bank;
import net.sourceforge.z88.EpromBank;
import net.sourceforge.z88.IntelFlashBank;
import net.sourceforge.z88.Memory;
import net.sourceforge.z88.Z88;
import net.sourceforge.z88.datastructures.ApplicationCardHeader;
import net.sourceforge.z88.datastructures.FileAreaHeader;
import net.sourceforge.z88.datastructures.SlotInfo;

/**
 * Management of files in File Area of inserted card in specified slot (1-3).
 * Also validation of File Card image.
 */
public class FileArea {
	/** null-file for Intel Flash Card */
	private static byte[] nullFile = {1, 0, 0, 0, 0, 0};

	/** reference to available memory hardware and functionality */
	private Memory memory;

	/** Utility Class to get slot information */
	private SlotInfo slotinfo;

	/** the slot number of the File area. */
	private int slotNumber;

	/**
	 * The File Header of this File Area. Will be used to validate if another
	 * File area has been inserted into this slot since last time this object
	 * was accessed.
	 */
	private FileAreaHeader fileAreaHdr;

	/** Linked list of available File entries in File Area */
	private LinkedList filesList;

	/**
	 * Constructor<br>
	 * Scan file area at specified slot and populate this object with information.
	 *
	 * @param slotNo
	 * @throws throws FileAreaNotFoundException
	 */
	public FileArea(int slotNo) throws FileAreaNotFoundException {
		memory = Z88.getInstance().getMemory();
		slotinfo = SlotInfo.getInstance();

		slotNumber = slotNo;
		int bankNo = slotinfo.getFileHeaderBank(slotNumber);
		if (bankNo == -1)
			throw new FileAreaNotFoundException();
		else {
			fileAreaHdr = new FileAreaHeader(bankNo);
			refreshFileList(); // automatically build the file list...
		}
	}

	/**
	 * Scan the memory of the File Area and build a linked list of File entries.
	 *
	 * @throws FileAreaNotFoundException
	 */
	public void scanFileArea() throws FileAreaNotFoundException {
		if (isFileAreaAvailable() == false)
			throw new FileAreaNotFoundException();
		else {
			refreshFileList();
		}
	}

	/**
	 * Dump the old linked list of File Entries and re-scan the current
	 * file area to build a new linked list of File entries.
	 */
	private void refreshFileList() {
		// dump the old linked list (if any)...
		filesList = new LinkedList();

		// start scanning at bottom of card...
		int fileEntryPtr = (slotNumber << 6) << 16;
		while (memory.getByte(fileEntryPtr) != 0xFF
				& memory.getByte(fileEntryPtr) != 0x00) {

			// and create a linked list of FileEntry objects...
			FileEntry fe = new FileEntry(fileEntryPtr);
			filesList.add(fe);

			// point at next File Entry...
			fileEntryPtr = intToPtr(ptrToInt(fileEntryPtr)
					+ fe.getHdrLength() + fe.getFileLength());
		}
	}

	/**
	 * If files exist in file area, a ListIterator is returned,
	 * otherwise null.
	 * <p>Use next() on the iterator to get a
	 * net.sourceforge.z88.filecard.FileEntry object that contains all
	 * available information about each file entry.</p>
	 *
	 * @return a ListIterator for available application DOR's or null
	 * @throws FileAreaNotFoundException
	 */
	public ListIterator getFileEntries() throws FileAreaNotFoundException {
		if (isFileAreaAvailable() == false)
			throw new FileAreaNotFoundException();
		else {
			if (filesList != null & filesList.size() > 0)
				return filesList.listIterator(0);
			else
				return null;
		}
	}

	/**
	 * Get an array of Strings that contains all active file names
	 * in the file area. Used typically for JList Swing widget.
	 *
	 * @return an array of String objects or null if no files available
	 * @throws FileAreaNotFoundException
	 */
	public String[] getFileEntryNames() throws FileAreaNotFoundException {
		if (isFileAreaAvailable() == false)
			throw new FileAreaNotFoundException();
		else {
			if (filesList != null & filesList.size() > 0) {
				String[] fileNames = new String[getActiveFileCount()];
				int fi = 0;

				// scan the file list for active files...
				for(int f=0; f<filesList.size(); f++) {
					FileEntry fe = (FileEntry) filesList.get(f);
					if (fe.isDeleted() == false) {
						fileNames[fi++] = fe.getFileName();
					}
				}

				return fileNames;
			} else
				return null;
		}
	}

	/**
	 * Find file entry by filename and return a reference to the found
	 * object, or return null if the file entry wasn't found in the file area.
	 *
	 * @param fileName (in "oz" filename format)
	 * @return found reference to file entry, or null if not found
	 * @throws FileAreaNotFoundException
	 */
	public FileEntry getFileEntry(String fileName) throws FileAreaNotFoundException {
		if (isFileAreaAvailable() == false)
			throw new FileAreaNotFoundException();
		else {
			if (filesList == null || filesList.size() == 0) {
				return null; // no file entries available in file area..
			} else {
				// scan the file list...
				for(int i=0; i<filesList.size(); i++) {
					FileEntry fe = (FileEntry) filesList.get(i);
					if (fe.getFileName().compareToIgnoreCase(fileName) == 0)
						return fe; // found..
				}

				return null; // file entry was not found..
			}
		}
	}

	/**
	 * Return available free space on File Area. The free area is the number of
	 * bytes after the last available file and up until the header at the top
	 * bank of the file area.
	 *
	 * @return free space in bytes
	 * @throws FileAreaNotFoundException
	 */
	public int getFreeSpace() throws FileAreaNotFoundException {
		int freeSpace = 0;

		if (isFileAreaAvailable() == false)
			throw new FileAreaNotFoundException();
		else {
			if (filesList != null & filesList.size() > 0) {
				// there's file entries available, get to the end of the list
				// and calculate the free space to the file header...

				FileEntry fe = (FileEntry) filesList.getLast();
				int freeSpacePtr = intToPtr(ptrToInt(fe.getFileEntryPtr())
						+ fe.getHdrLength() + fe.getFileLength());

				int fileHdrPtr = (fileAreaHdr.getBankNo() << 16) | 0x3FC0;
				freeSpace = ptrToInt(fileHdrPtr) - ptrToInt(freeSpacePtr);
			} else {
				// the file area is empty, return all available space in file area
				freeSpace = fileAreaHdr.getSize() * Bank.SIZE - 64;
			}
		}

		return freeSpace;
	}

	/**
	 * Return the amount of deleted file space in File Area, ie. the amount
	 * of bytes occupied in the File Area the are used by files that are marked
	 * as deleted.
	 *
	 * @return deleted file space in bytes
	 * @throws FileAreaNotFoundException
	 */
	public int getDeletedSpace() throws FileAreaNotFoundException {
		int deletedSpace = 0;

		if (isFileAreaAvailable() == false)
			throw new FileAreaNotFoundException();
		else {
			if (filesList == null || filesList.size() == 0) {
				return 0;	// no files are stored in file area...
			} else {
				// calculate the deleted space by scanning the file list...
				for(int i=0; i<filesList.size(); i++) {
					FileEntry fe = (FileEntry) filesList.get(i);
					if (fe.isDeleted() == true)
						deletedSpace += fe.getHdrLength() + fe.getFileLength();
				}

				return deletedSpace;
			}
		}
	}

	/**
	 * Return the size of the file area in bytes.
	 *
	 * @return the size of the file area in bytes
	 * @throws FileAreaNotFoundException
	 */
	public int getFileAreaSize() throws FileAreaNotFoundException {
		if (isFileAreaAvailable() == false)
			throw new FileAreaNotFoundException();
		else {
			return fileAreaHdr.getSize() * Bank.SIZE - 64;
		}
	}

	/**
	 * Get the total number of active files in the file area, ie.
	 * only those which are not marked as deleted.
	 *
	 * @return total of active files in file area
	 * @throws FileAreaNotFoundException
	 */
	public int getActiveFileCount() throws FileAreaNotFoundException {
		int activeFiles = 0;

		if (isFileAreaAvailable() == false)
			throw new FileAreaNotFoundException();
		else {
			if (filesList != null & filesList.size() > 0) {
				// scan the file list for active files...
				for(int f=0; f<filesList.size(); f++) {
					FileEntry fe = (FileEntry) filesList.get(f);
					if (fe.isDeleted() == false)
						activeFiles++;
				}
			}
		}

		return activeFiles;
	}

	/**
	 * Get the total number of deleted files in the file area.
	 *
	 * @return total of deleted files in file area
	 * @throws FileAreaNotFoundException
	 */
	public int getDeletedFileCount() throws FileAreaNotFoundException {
		int deletedFiles = 0;

		if (isFileAreaAvailable() == false)
			throw new FileAreaNotFoundException();
		else {
			if (filesList != null & filesList.size() > 0) {
				// scan the file list for deleted files...
				for(int f=0; f<filesList.size(); f++) {
					FileEntry fe = (FileEntry) filesList.get(f);
					if (fe.isDeleted() == true)
						deletedFiles++;
				}
			}
		}

		return deletedFiles;
	}

	/**
	 * Get pointer to first free space in File Area (where to store a new file).
	 *
	 * @return extended address of free space.
	 * @throws FileAreaNotFoundException
	 */
	private int getFreeSpacePtr() throws FileAreaNotFoundException {
		if (isFileAreaAvailable() == false)
			throw new FileAreaNotFoundException();
		else {
			if (filesList != null & filesList.size() > 0) {
				// there's file entries available, get to the end of the list
				FileEntry fe = (FileEntry) filesList.getLast();
				return intToPtr(ptrToInt(fe.getFileEntryPtr())
						+ fe.getHdrLength() + fe.getFileLength());
			} else {
				// no files are available, point at bottom of card...
				return (slotNumber << 6) << 16;
			}
		}
	}

	/**
	 * Store file into File Card/Area.
	 *
	 * @param slotNo
	 *            of File Card/Area
	 * @param fileName
	 *            the filename for the file to be stored (in "oz" filename format).
	 * @param fileImage
	 *            the byte image of the file to be stored.
	 *
	 * @throws FileAreaNotFoundException, FileAreaExhaustedException
	 */
	public void storeFile(String fileName, byte[] fileImage)
			throws FileAreaNotFoundException, FileAreaExhaustedException {
		if (isFileAreaAvailable() == false)
			throw new FileAreaNotFoundException();
		else {
			if ( (1+fileName.length()+4+fileImage.length) > getFreeSpace() )
				// not enough free space for file entry header and file image
				throw new FileAreaExhaustedException();
			else {
				// first find a matching entry (if available) and mark it as deleted
				markAsDeleted(fileName);

				// get pointer in file area for new file entry...
				int fileEntryPtr = getFreeSpacePtr();
				int extAddress = fileEntryPtr;

				// first store byte of new file entry (length of filename)...
				memory.setByte(extAddress, fileName.length());
				extAddress = memory.getNextExtAddress(extAddress);

				// followed by the filename...
				byte[] filenameArray = fileName.getBytes();
				for (int n=0, fnl=fileName.length(); n<fnl; n++) {
					memory.setByte(extAddress, filenameArray[n]);
					extAddress = memory.getNextExtAddress(extAddress);
				}

				// followed by the file length, 4 bytes LSB order...
				int fileLength = fileImage.length;
				for (int i=0; i<4;i++) {
					memory.setByte(extAddress, fileLength & 0xFF);
					extAddress = memory.getNextExtAddress(extAddress);
					fileLength >>>= 8;
				}

				// followed by the file image...
				for (int b=0, l=fileImage.length; b<l;b++) {
					memory.setByte(extAddress, fileImage[b]);
					extAddress = memory.getNextExtAddress(extAddress);
				}

				// finally, register the new file entry in the linked list
				FileEntry fe = new FileEntry(fileEntryPtr);
				if (filesList == null)
					filesList = new LinkedList();
				filesList.add(fe);
			}
		}
	}

	/**
	 * Validate whether the selected files can fit into the current free space
	 * of the file areal.
	 *
	 * @param selectedFiles an array of File objects
	 * @return true if there is room enough for the seleted files, or false.
	 * @throws FileAreaNotFoundException
	 * @throws IOException
	 */
	public boolean isImportable(File selectedFiles[] )
			throws FileAreaNotFoundException, IOException {
		int totalFileSize = 0;

		if (isFileAreaAvailable() == false)
			throw new FileAreaNotFoundException();
		else {
			for (int f=0; f<selectedFiles.length; f++) {
				if (selectedFiles[f].isFile() == false) {
					throw new IOException("Not a file.");
				} else {
					String z88FileName = convertHostFileName(selectedFiles[f]);
					totalFileSize += 1 + z88FileName.length() + 4 + selectedFiles[f].length();

				}
			}

			if ( totalFileSize <= getFreeSpace() )
				return true;
			else
				// not enough free space for selected files
				return true;
		}
	}

	/**
	 * Import a file from the Host file system into the Z88 File Area.
	 * The Filename of the host file system will be converted into the
	 * filenaming format of the Z88 File Card. Due to limits of the Z88
	 * filename format, the host filename might get truncated.
	 *
	 * @param hostFile
	 * @throws FileAreaNotFoundException
	 * @throws FileAreaExhaustedException
	 * @throws IOException
	 */
	public void importHostFile(File hostFile)
		throws FileAreaNotFoundException, FileAreaExhaustedException, IOException {

		if (isFileAreaAvailable() == false)
			throw new FileAreaNotFoundException();
		else {
			if (hostFile.isFile() == false) {
				throw new IOException("Not a file.");
			} else {
				String z88FileName = convertHostFileName(hostFile);
				if ( (1+z88FileName.length()+4+hostFile.length()) > getFreeSpace() )
					// not enough free space for file entry header and file image
					throw new FileAreaExhaustedException();
				else {
					RandomAccessFile hf = new RandomAccessFile(hostFile, "r");
					byte[] fileData = new byte[(int) hf.length()];
					hf.readFully(fileData);
					hf.close();
					storeFile(z88FileName, fileData);
				}
			}
		}
	}

	/**
	 * Export a file entry on the file area to the host filing system. The
	 * path of file entry is truncated, and only the core filename is appended
	 * to the specified host filing system path.
	 *
	 * @param fe the File Entry
	 * @param hostExpDir The host filing system specific export directory
	 * @throws IOException
	 */
	public void exportFileEntry(FileEntry fe, String hostExpDir) throws IOException {
		// strip the "oz" path of the filename
		String hostFileName = fe.getFileName();
		hostFileName = hostFileName.substring(hostFileName.lastIndexOf("/")+1);
		// and build a complete file name for the host file system
		hostFileName = hostExpDir + File.separator + hostFileName;

		// create a new file in specified host directory (overwrite if it already exists)
		new File(hostFileName).delete();
		RandomAccessFile expFile = new RandomAccessFile(hostFileName, "rw");
		expFile.write(fe.getFileImage()); // export file image to host file system
		expFile.close();
	}


	/**
	 * Import all files from the Host directory into the Z88 File Area.
	 * The filenames of the host file system will be converted into the
	 * filenaming format of the Z88 File Card. Due to limits of the Z88
	 * filename format, the host filename might get truncated.
	 *
	 * @param hostDirectory
	 * @throws FileAreaNotFoundException
	 * @throws FileAreaExhaustedException
	 * @throws IOException
	 */
	public void importHostFiles(File hostDirectory)
		throws FileAreaNotFoundException, FileAreaExhaustedException, IOException {

		if (isFileAreaAvailable() == false)
			throw new FileAreaNotFoundException();
		else {
			if (hostDirectory.isDirectory() == false) {
				throw new IOException("Not a directory.");
			} else {
				File[] fileList = hostDirectory.listFiles();
				for (int f=0; f<fileList.length; f++) {
					if (fileList[f].isFile() == true) importHostFile(fileList[f]);
				}
			}
		}
	}

	private String convertHostFileName(File hostFile) {
		String newFilename = "/" + hostFile.getName();

		// a lot has to be checked and converted for this filename!
		return newFilename;
	}

	/**
	 * Check if the file area is still available in the slot (card might have
	 * been removed/replaced with another card), and update the linked list
	 * of file entries, if a new File area has become available.
	 *
	 * @return <b>true</b>, if a file area was found.
	 */
	public boolean isFileAreaAvailable() {
		int bankNo;

		if (fileAreaHdr == null) {
			bankNo = slotinfo.getFileHeaderBank(slotNumber);
			if (bankNo == -1)
				return false;
			else {
				fileAreaHdr = new FileAreaHeader(bankNo);
				refreshFileList(); // automatically build the file list...
				return true;
			}
		}

		bankNo = fileAreaHdr.getBankNo();
		if (slotinfo.isFileHeader(bankNo) == false) {
			// card with file area has been removed. Check if a new card
			// might have been inserted in this slot with another file area...
			bankNo = slotinfo.getFileHeaderBank(slotNumber);
			if (bankNo == -1) {
				// file area definitely gone...
				fileAreaHdr = null;
				filesList = null;
				return false;
			} else {
				fileAreaHdr = new FileAreaHeader(bankNo);
				refreshFileList(); // automatically build the file list...
				return true;
			}
		} else {
			// file header is available at the same position, but
			// is it a new file area (compared to the previous scanned
			// file area for this slot)?
			int randomId = (memory.getByte(0x3FF8, bankNo) << 24) |
							memory.getByte(0x3FF9, bankNo) << 16 |
							memory.getByte(0x3FFA, bankNo) << 8 |
							memory.getByte(0x3FFB, bankNo);

			if (randomId != fileAreaHdr.getRandomId()) {
				// A new file area that has the same size and
				// position has been inserted since the previous
				// scan of this slot...
				refreshFileList();
			}

			return true;
		}
	}

	/**
	 * Evaluate whether a file area can be created on the card in the specified slot.
	 * Ram card and empty slots will automatically be discarded (returns false).
	 * If empty space is found on card (ie. below an application area) and that it
	 * conforms to the rules of minimum needed file space for flash cards (64K, except
	 * AMD 128K chip that has 16K sectors) and UV Eprom (16K) then true is returned.
	 *
	 * Use the create() method for the specified slot to actually create/format the file area.
	 *
	 * This method also returns true if an existing file area is found (which means that
	 * the file area could be re-formatted).
	 *
	 * @param slotNumber
	 * @return true if a file area might be created on the card, otherwise return false
	 */
	public static boolean isCreateable(int slotNumber) {
		Memory memory = Z88.getInstance().getMemory();
		SlotInfo slotinfo = SlotInfo.getInstance();

		slotNumber &= 3; // only slot 0-3...
		if (slotNumber == 0)
			return false; // slot 0 does not support file areas...

		int topBankNo = (slotNumber << 6) | 0x3f;

		// get top bank of slot to determine card type...
		Bank bank = memory.getBank(topBankNo);
		if ((bank instanceof EpromBank == false)
				& (bank instanceof GenericAmdFlashBank == false)
				& (bank instanceof IntelFlashBank == false)) {
			// A file area can't be created on a Ram card or in an empty slot...
			return false;
		} else {
			int fileHdrBank = slotinfo.getFileHeaderBank(slotNumber);

			if (fileHdrBank != -1) {
				// file header found somewhere on card, file area can be re-formatted
				return true;
			} else {
				// no file area found, investigate if there's space available
				if (slotinfo.isApplicationCard(slotNumber) == true) {
					ApplicationCardHeader appCrdHdr = new ApplicationCardHeader(
							slotNumber);
					if (bank instanceof EpromBank == true) {
						if (memory.getExternalCardSize(slotNumber) == appCrdHdr
								.getAppAreaSize()) {
							return false; // no room for a file area on UV Eprom
						} else {
							// there's 16K or more available for file area...
							return true;
						}
					} else {
						int freeBanks = memory.getExternalCardSize(slotNumber)- appCrdHdr.getAppAreaSize();

						// validate free space for Flash Cards...
						if (bank instanceof GenericAmdFlashBank == true) {
							GenericAmdFlashBank amdFlashBank = (GenericAmdFlashBank) bank;
							if (amdFlashBank.getDeviceCode() == AmdFlashBank.AM29F010B) {
								// 128K AMD Flash uses 16K sectors,
								// minimum 16K must be available to create a file area...
								if (freeBanks >= 1)
									return true;
								else
									return false;
							}
						}

						// For all other Flash Card,
						// check if app area moves into bottom 64K sector...
						if (freeBanks < 4)
							return false;
						else
							return true; // 64K or more is available for file area...
					}
				} else {
					// empty card, ready for complete file area...
					return true;
				}
			}
		}
	}

	/**
	 * Create/reformat a file area in specified slot (1-3). Return <b>true </b> if a file
	 * area was formatted/created. A file area can only be created on Eprom or Flash
	 * Cards.
	 *
	 * The slot hardware will be evaluated and use the right sub type and
	 * position of the File Header. For Flash Cards, the header will be
	 * positioned on 64K boundaries, for conventional Eproms, the first
	 * available free 16K bank.
	 *
	 * If a card is empty, all memory will be claimed for the file area. If a
	 * slot contains an application area, the file area will be placed below the
	 * application area, if there's room on the card. If a file header is found,
	 * only the file area will be re-formatted (header is left untouched).
	 *
	 * The complete file area will be formatted with FFh's from the bottom of the
	 * card up until the File Area header.
	 *
	 * @param slotNumber
	 * @param formatArea <b>true</b>, if the file are is to be formatted.
	 * @return <b>true</b> if file area was formatted/created, otherwise
	 *         <b>false </b>
	 */
	public static boolean create(int slotNumber, boolean formatArea) {
		Memory memory = Z88.getInstance().getMemory();
		SlotInfo slotinfo = SlotInfo.getInstance();

		slotNumber &= 3; // only slot 0-3...
		if (slotNumber == 0)
			return false; // slot 0 does not support file areas...

		int topBankNo = (slotNumber << 6) | 0x3f;

		// get top bank of slot to determine card type (but this might be a hybrid card)...
		Bank bank = memory.getBank(topBankNo);
		if ((bank instanceof EpromBank == false)
				& (bank instanceof GenericAmdFlashBank == false)
				& (bank instanceof IntelFlashBank == false)) {
			// A file area can't be created on a Ram card or in an empty slot...
			return false;
		} else {
			int fileHdrBank = slotinfo.getFileHeaderBank(slotNumber);
			if (fileHdrBank != -1) {
				// file header found somewhere on card.
				// format file area from bank of file header, downwards...
				if (formatArea == true)
					formatFileArea(fileHdrBank);
			} else {
				if ((slotinfo.isOzRom(slotNumber) == true) | (slotinfo.isApplicationCard(slotNumber) == true)) {
					ApplicationCardHeader appCrdHdr = new ApplicationCardHeader(
							slotNumber);
					if (bank instanceof EpromBank == true) {
						if (memory.getExternalCardSize(slotNumber) == appCrdHdr
								.getAppAreaSize()) {
							return false; // no room for a file area on Eprom
						} else {
							// format file area just below application area...
							int topFileAreaBank = memory.getExternalCardSize(slotNumber) - appCrdHdr.getAppAreaSize() - 1;
							if (formatArea == true)
								formatFileArea(topFileAreaBank);
						}
					} else {
						// create file area in flash card (modulus 64K sector aligned)...
						int fileAreaSize = memory.getExternalCardSize(slotNumber)
								- appCrdHdr.getAppAreaSize();
                        fileAreaSize -= (fileAreaSize % 4);

						// validate free space for Flash Cards...
						if (bank instanceof GenericAmdFlashBank == true) {
							GenericAmdFlashBank amdFlashBank = (GenericAmdFlashBank) bank;
							if (amdFlashBank.getDeviceCode() == AmdFlashBank.AM29F010B) {
								// 128K AMD Flash uses 16K sectors,
								// minimum 16K must be available to create a file area...
								if (fileAreaSize < 1)
									return false;
							} else {
								// For all other AMD Flash Cards,
								// check that miminim 64K sector size is available...
								if (fileAreaSize < 4)
									return false;
							}
						} else {
							// For all INTEL Flash Cards,
							// check that miminim 64K sector size is available...
							if (fileAreaSize < 4)
								return false;
						}

						int topFileAreaBank = ((topBankNo - appCrdHdr.getAppAreaSize()) & 0xFC) - 1;

						if (formatArea == true)
							formatFileArea(topFileAreaBank);
					}
				} else {
					// empty card, write file header at top of card...
					if (formatArea == true)
						formatFileArea(topBankNo);
				}
			}

			if (bank instanceof IntelFlashBank == true & formatArea == true ) {
				// A null file is needed as the first file in the file area
				// for Intel Flash Cards to avoid undocumented behaviour
				// (occasional auto-command mode when card is inserted)
				int extAddress = slotNumber << 22;

				for (int offset = 0; offset < nullFile.length; offset++)
					memory.setByte(extAddress++, nullFile[offset]);
			}

			return true;
		}
	}

	/**
	 * Validate that the file image is in fact a copy of a file card:
	 * identified with an 'oz' watermark at the top of the card and
	 * make sure that the file size is matches a known card size, eg.
	 * 32K, 128K .. 1024K.
	 *
	 * @param fileEprImage
	 * @return true if a file area was properly identified
	 */
	public static boolean checkFileAreaImage(File fileEprImage) {
		boolean fileAreaStatus = true;

		try {
			RandomAccessFile f = new RandomAccessFile(fileEprImage, "r");
			switch((int) f.length()) {
				case 32*1024: // 32K UV Eprom
				case 128*1024: // 128K UV Eprom, or 128K Amd Flash
				case 256*1024: // 256K UV Eprom
				case 512*1024: // 512K Intel Flash or 512K Amd Flash
				case 1024*1024: // 1024K Intel Flash or Amd Flash
					break;
				default:
					// illegal card size
					fileAreaStatus = false;
			}

			// get bank size byte
			f.seek(f.length() - 4);
			if (f.readByte() * 16384 != f.length())
				// total number of banks doesn't match file image size...
				fileAreaStatus = false;

			f.readByte(); // skip Card subtype

			// read 'oz' File card watermark
			int wm_o = f.readByte();
			int wm_z = f.readByte();
			if (wm_o != 0x6F & wm_z != 0x7A)
				fileAreaStatus = false;

			f.close();
		} catch (FileNotFoundException e) {
			return false;
		} catch (IOException e) {
			return false;
		}

		return fileAreaStatus;
	}

	/**
	 * Write a file header in one of the external slots (1-3) at specified
	 * absolute bank ($40-$FF), offset $3FC0-$3FFF. A file header can only be
	 * written on Eprom or Flash Cards. <b>false </b> is returned if the slot
	 * was empty or contained a Ram card.
	 *
	 * @param bankNo
	 * @return <b>true </b> if file header was created, otherwise <b>false </b>
	 */
	public static boolean createFileHeader(final int bankNo) {
		Memory memory = Z88.getInstance().getMemory();
		Random generator = new Random();
		int slotNo = (bankNo & 0xC0) >> 6;

		if (slotNo == 0)
			return false; // slot 0 does not support file areas...

		Bank bank = memory.getBank(bankNo);
		if ((bank instanceof EpromBank == true)
				| (bank instanceof GenericAmdFlashBank == true)
				| (bank instanceof IntelFlashBank == true)) {

			for (int offset = 0x3FC0; offset < 0x3FF7; offset++)
				memory.setByte(offset, bankNo, 0);

			memory.setByte(0x3FF7, bankNo, 0x01);
			memory.setByte(0x3FF8, bankNo, generator.nextInt(255));
			memory.setByte(0x3FF9, bankNo, generator.nextInt(255));
			memory.setByte(0x3FFA, bankNo, generator.nextInt(255));
			memory.setByte(0x3FFB, bankNo, generator.nextInt(255));

			// size of file area is from bank of header downwards to bottom of
			// card.
			int fileAreaSize = (bankNo & (memory.getExternalCardSize(slotNo) - 1)) + 1;
			memory.setByte(0x3FFC, bankNo, fileAreaSize);

			if ((bank instanceof EpromBank == true))
				if (memory.getExternalCardSize(slotNo) == 2)
					// a 32K Eprom was identified...
					memory.setByte(0x3FFD, bankNo, 0x7E);
				else
					memory.setByte(0x3FFD, bankNo, 0x7C); // all other UV cards get $7C
			if ((bank instanceof GenericAmdFlashBank == true))
				memory.setByte(0x3FFD, bankNo, 0x6F);	// Define an AMD or STM sub type
			if ((bank instanceof IntelFlashBank == true))
				memory.setByte(0x3FFD, bankNo, 0x77);	// Define an INTEL sub type

			memory.setByte(0x3FFE, bankNo, 'o');
			memory.setByte(0x3FFF, bankNo, 'z');

			return true;
		} else {
			// header can't be written to Ram cards or empty slots..
			return false;
		}
	}

	/**
	 * Mark file entry as deleted, using specified filename (in "oz" filename format).
	 *
	 * @param fileName
	 * @return true, if file entry was found and marked as deleted, else false
	 * @throws FileAreaNotFoundException
	 */
	public boolean markAsDeleted(String fileName) throws FileAreaNotFoundException {
		if (isFileAreaAvailable() == false)
			throw new FileAreaNotFoundException();
		else {
			FileEntry fe = getFileEntry(fileName);
			if (fe == null)
				return false; // file entry wasn't found
			else {
				int feMemPtr = fe.getFileEntryPtr();
				feMemPtr = memory.getNextExtAddress(feMemPtr); // first byte of filename
				memory.setByte(feMemPtr, 0); // mark entry as deleted

				// point again at start of entry in memory for rescan...
				feMemPtr = fe.getFileEntryPtr();
				// make a new File Entry object (that now is 'marked as deleted')
				FileEntry feDeleted = new FileEntry(feMemPtr);
				// replace old File Entry with new in list...
				filesList.set(filesList.indexOf(fe), feDeleted);
			}
		}

		return true;
	}


	/**
	 * Format file area with FF's, beginning from top of specified bank (or bank of file header)
	 * downwards until bottom of (type of) card has been reached.
	 *
	 * @param topBank
	 *            the top bank of the file area including the header at $3FC0
	 */
	private static void formatFileArea(int topBank) {
	    int bankNo = topBank;
	    int totalBanks = (bankNo & 0x3f); // botton of slot is limit..
		Memory memory = Z88.getInstance().getMemory();

		// format file area from top bank, downwards...
		do
		{
        	Bank bank = memory.getBank(bankNo);
        	if ((bank instanceof EpromBank == true)
        			| (bank instanceof GenericAmdFlashBank == true)
        			| (bank instanceof IntelFlashBank == true))
        	{
    			for (int offset = 0; offset < 0x4000; offset++)
    				memory.setByte(offset, bankNo, 0xFF);
    		} else {
    		    // we're no longer in a card that can hold a file area...
    		    // (probably, we are part of a hybrid card..)
    		    break;
    		}

    		bankNo--;
		} while ( totalBanks-- > 0); // stop at bottom of slot

		createFileHeader(topBank);
	}


	/**
	 * Convert the extended address for the current slot to a calculable integer.
	 *
	 * @param extAddress
	 *            the extended address
	 * @return integer
	 */
	private int ptrToInt(int extAddress) {
		int bank = (extAddress >> 16) & 0x3F; // no slot info...
		int offset = extAddress & 0x3FFF;

		return bank * Bank.SIZE + offset;
	}

	/**
	 * Convert the calculable integer to an extended address for the current
	 * slot.
	 *
	 * @param i
	 * @return extended address
	 */
	private int intToPtr(int i) {
		int bank = i / Bank.SIZE | (slotNumber << 6); // mask slot into address
		int offset = i % Bank.SIZE;

		return (bank << 16) | offset;
	}

	/**
	 * Reclaim deleted file space in file area, ie. get a copy of all the
	 * active files, then reformat the file area (all traces of deleted files
	 * are gone) and finally save the active files back to the file area.
	 * @throws FileAreaNotFoundException
	 */
	public void reclaimDeletedFileSpace() throws FileAreaNotFoundException {
		if (isFileAreaAvailable() == false)
			throw new FileAreaNotFoundException();
		else {
			// Only reclaim if there's something in the file area...
			if (filesList != null & filesList.size() > 0) {

				// The temporary list of cached File entries
				LinkedList cachedFilesList = new LinkedList();

				// get the active files in file area and cache them...
				for(int f=0; f<filesList.size(); f++) {
					FileEntry fe = (FileEntry) filesList.get(f);
					if (fe.isDeleted() == false) {
						FileEntryCache cachedEntry = new FileEntryCache(fe.getFileEntryPtr());
						cachedFilesList.add(cachedEntry);
					}
				}

				// all active files cached, reformat file area...
				FileArea.create(slotNumber, true);
				filesList = new LinkedList();

				// then restore the active files...
				for(int f=0; f<cachedFilesList.size(); f++) {
					FileEntryCache cachedEntry = (FileEntryCache) cachedFilesList.get(f);
					try {
						storeFile(cachedEntry.getFileName(), cachedEntry.getFileImage());
					} catch (FileAreaExhaustedException e) {
						// never happens!
					}
				}
			}
		}
	}

	/**
	 * Private helper class used when reclaiming space of deleted files
	 */
	private class FileEntryCache extends FileEntry {
		/** The binary copy of the file image */
		private byte[] fileImageCopy;

		/**
		 * Constructor.<br>
		 * Create a cached FileEntry that also preserves the file image
		 */
		public FileEntryCache(int extAddress) {
			super(extAddress);

			// copy the image from file area memory
			fileImageCopy = super.getFileImage();
		}

		/**
		 * Override, so that we get the cached copy of the file image.
		 */
		public byte[] getFileImage() {
			return fileImageCopy;
		}
	}
}