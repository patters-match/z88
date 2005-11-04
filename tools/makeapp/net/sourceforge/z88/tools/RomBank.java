/*
 * RomBank.java
 * This file is part of MakeApp.
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

/** 
 * This class represents the 16Kb ROM Bank. The characteristics of a ROM bank is
 * chip memory that can be read at all times and never written (Read Only Memory). 
 */
public class RomBank extends Bank {
	
	public RomBank() {		
		super(-1);		

		for (int i = 0; i < Bank.BANKSIZE; i++) setByte(i, 0xFF); // empty Rom contain FF's
	}
}
