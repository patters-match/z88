/*
 * FileAreaNotFoundException.java
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

/**
 * File Area not found. Ie. the Eprom of Flash Card in a specified slot didn't
 * contain a file area (or slot was empty, or a Ram Card).
 */
public class FileAreaNotFoundException extends Exception {
	public FileAreaNotFoundException() {
		super();
	}

	/**
	 * @param arg0
	 */
	public FileAreaNotFoundException(String arg0) {
		super(arg0);
	}

	/**
	 * @param arg0
	 * @param arg1
	 */
	public FileAreaNotFoundException(String arg0, Throwable arg1) {
		super(arg0, arg1);
	}

	/**
	 * @param arg0
	 */
	public FileAreaNotFoundException(Throwable arg0) {
		super(arg0);
	}
}
