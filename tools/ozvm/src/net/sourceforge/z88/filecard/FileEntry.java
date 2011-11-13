/*
 * FileEntry.java
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
 *
 */
package net.sourceforge.z88.filecard;

import net.sourceforge.z88.Memory;
import net.sourceforge.z88.Z88;

/**
 * Information about File Entry in a File Area 
 * (name, file length, status, etc.).
 * 
 * <p>A File Entry is organised as follows in a file area:</p>
 * <pre>
 * 		1 byte      n      length of filename
 * 		1 byte      x      '/' for latest version, $00 for old version (deleted)
 * 		n-1 bytes   'xxxx' filename
 * 		4 bytes     m      length of file (least significant byte first)
 * 		m bytes            body of file
 * </pre> 
 */
public class FileEntry {

	/** Reference to available memory hardware and functionality */
	private Memory memory;
	
	/**
	 * Filename of entry. If the entry is active, the filename begins
	 * with a '/'. If the file is marked as deleted, the filename
	 * has the marker removed. 
	 */
	private String fileName;
	
	/** Length of file image (excluding the file entry data) */
	private int fileLength;
	
	/** Length of File Entry Header. */
	private int hdrLength;
	
	/** Indicates whether the file entry is marked as deleted or not. */
	private boolean deleted;
	
	/**
	 * The File Entry pointer
	 */
	private int fileEntryPtr;

	/** Pointer to beginning of file image */
	private int fileImagePtr;
	
	/**
	 * Get the File Entry information at extended address.
	 * 
	 * @param extAddress
	 */
	public FileEntry(int extAddress) {
		memory = Z88.getInstance().getMemory();
		
		// remember the pointer to this File Entry 
		fileEntryPtr = extAddress;
		
		// read memory contents at pointer into property variables...
		int flnmLength = memory.getByte(extAddress);
		extAddress = memory.getNextExtAddress(extAddress);
		hdrLength++;
		
		if (memory.getByte(extAddress) == 0) {
			// first char of filename is 0, which identifies
			// a file entry marked as deleted
			flnmLength--; // filename is one char less...
			extAddress = memory.getNextExtAddress(extAddress);
			hdrLength++;
			deleted = true;
		} else {
			deleted = false;
		}
		StringBuffer bufName = new StringBuffer(flnmLength);
		for (int c = 0; c < flnmLength; c++) {
			bufName.append((char) memory.getByte(extAddress));
			extAddress = memory.getNextExtAddress(extAddress);
			hdrLength++;
		}
		fileName = bufName.toString();

		fileLength = memory.getByte(extAddress);
		extAddress = memory.getNextExtAddress(extAddress);		
		fileLength |= (memory.getByte(extAddress) << 8); 
		extAddress = memory.getNextExtAddress(extAddress);		
		fileLength |= (memory.getByte(extAddress) << 16);
		extAddress = memory.getNextExtAddress(extAddress);		
		fileLength |= (memory.getByte(extAddress) << 24); 
		extAddress = memory.getNextExtAddress(extAddress);		
		hdrLength += 4;
		
		fileImagePtr = extAddress;
	}
	
	/**
	 * @return the file marked as deleted status (<b>false</b> = active file).
	 */
	public boolean isDeleted() {
		return deleted;
	}
	
	/**
	 * @return the length of the file (image) in bytes.
	 */	
	public int getFileLength() {
		return fileLength;
	}

	/**
	 * @return a copy of the file image in a byte array
	 */
	public byte[] getFileImage() {
		int n = getFileLength();
		int extAddress = fileImagePtr;
		byte[] fileArray = new byte[n];
		
		for (int i=0; i<n; i++) {
			fileArray[i] = (byte) memory.getByte(extAddress);
			extAddress = memory.getNextExtAddress(extAddress);		
		}
		
		return fileArray;		
	}
	
	/**
	 * @return the fileName (leading "/" is missing for deleted file).
	 */
	public String getFileName() {
		return fileName;
	}
	
	/**
	 * @return the length of the file entry header.
	 */
	public int getHdrLength() {
		return hdrLength;
	}
	
	/**
	 * @return the pointer to the beginning of the file image
	 */
	public int getFileImagePtr() {
		return fileImagePtr;
	}
	
	/**
	 * @return the Pointer in the File Area to this File Entry.
	 */
	public int getFileEntryPtr() {
		return fileEntryPtr;
	}
}
