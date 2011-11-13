/*
 * OZvm.java
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
package net.sourceforge.z88.datastructures;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.util.LinkedList;
import java.util.List;
import java.util.ListIterator;

/**
 * Get Access to Z88 Application Information (DOR) for available slot.
 * Also, validate Application Card Image.
 */
public class ApplicationInfo {

	private List[] appSlotList;	// array of Application DOR lists for all slots

	public ApplicationInfo() {
		// linked application DOR lists for slots 0-3
		appSlotList = new List[4];

		// poll all slots for applications
		scanSlots();
	}

	/**
	 * Scan slots 0-3 for installed applications to update the
	 * information previously gathered by this class instance.
	 */
	public void scanSlots() {
		for (int slot=0; slot<4; slot++) scanSlot(slot);
	}

	/**
	 * Scan specified slot for installed applications
	 *
	 * @param slot
	 */
	private void scanSlot(int slot) {
		slot &= 3;

		if (SlotInfo.getInstance().isApplicationCard(slot) == false & SlotInfo.getInstance().isOzRom(slot) == false) {
			appSlotList[slot] = null; // no application card found in slot
		} else {
			appSlotList[slot] = new LinkedList();
			ApplicationFrontDor frontDor = new ApplicationFrontDor(slot);

			ApplicationDor appDor = new ApplicationDor(frontDor.getFirstApplicationDor());
			appSlotList[slot].add(appDor);

			while (appDor.getNextApp() != 0) {
				appDor = new ApplicationDor(appDor.getNextApp());
				appSlotList[slot].add(appDor);
			}
		}
	}

	/**
	 * If applications exist in card at specified slot, a ListIterator is returned,
	 * otherwise null.
	 * <p>Use next() on the iterator to get an ApplicationDor object that contains all
	 * available information about the installed application.</p>
	 *
	 * @param slot
	 * @return a ListIterator for available application DOR's or null
	 */
	public ListIterator getApplications(int slot) {
		slot &= 3;

		if (appSlotList[slot] != null)
			return appSlotList[slot].listIterator();
		else
			return null;
	}

	/**
	 * Validate that the file image contains data for an application card:
	 * Identified with an 'OZ' watermark at the top of the card and
	 * a bank counter less or equal to the size of the image.
	 *
	 * @param applImage
	 * @return true if a file area was properly identified
	 */
	public static boolean checkAppImage(File applImage) {
		boolean fileImageStatus = true;

		try {
			RandomAccessFile f = new RandomAccessFile(applImage, "r");
			if ((f.length() > 1024*1024) | (f.length() % 16384 != 0))
				// illegal card size
				fileImageStatus = false;

			// get bank size byte
			f.seek(f.length() - 4);
			if (f.readByte() * 16384 > f.length())
				// total number of banks larger than image size...
				fileImageStatus = false;

			f.readByte(); // skip..

			// read 'OZ' application card watermark
			int wm_o = f.readByte();
			int wm_z = f.readByte();
			if (wm_o != 0x4F & wm_z != 0x5A)
				fileImageStatus = false;

			f.close();
		} catch (FileNotFoundException e) {
			return false;
		} catch (IOException e) {
			return false;
		}

		return fileImageStatus;
	}
}
