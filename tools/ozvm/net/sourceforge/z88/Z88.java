/*
 * Z88.java
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
 */

package net.sourceforge.z88;

import net.sourceforge.z88.screen.Z88display;

/**
 * The Z88 class defines the Z88 virtual machine 
 * (Processor, Blink, Memory, Display & Keyboard).
 */
public class Z88 {

	private Blink blink;
	private Memory memory;
	private Z88Keyboard keyboard;
	private Z88display display;
	
	/**
	 * Z88 class default constructor.
	 */
	private Z88() {
	}

	private static final class singletonContainer {
		static final Z88 singleton = new Z88();
	}

	public static Z88 getInstance() {
		return singletonContainer.singleton;
	}
	
	public Blink getBlink() {
		if (blink == null)
			blink = new Blink();
		
		return blink;
	}

	public Memory getMemory() {
		if (memory == null)
			memory = new Memory();
		
		return memory;
	}
	
	public Z88display getDisplay() {
		if (display == null)
			display = new Z88display();
		
		return display;
	}
	
	public Z88Keyboard getKeyboard() {
		if (keyboard == null)
			keyboard = new Z88Keyboard();
		
		return keyboard;
	}
}
