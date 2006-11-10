/*
 * Z88Keyboard.java
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

import java.awt.event.KeyEvent;
import java.awt.event.KeyListener;
import java.util.Map;
import java.util.HashMap;


/**
 * Bind host operating system keyboard events to Z88 keyboard.
 * Management of "foreign" keyboard layout between host keyboard
 * and "native" Z88 keyboard. 
 */ 
public class Z88Keyboard {

	/** English/US Keyboard layout Country Code */
	public static final int COUNTRY_US = 0;
	
	/** French Keyboard layout Country Code */
	public static final int COUNTRY_FR = 1;
	
	/** German Keyboard layout Country Code */
	public static final int COUNTRY_DE = 2;
	
	/** English/UK Keyboard layout Country Code */
	public static final int COUNTRY_UK = 3;
	
	/** Danish Keyboard layout Country Code */
	public static final int COUNTRY_DK = 4;	 
	
	/** Swedish/Finish Keyboard layout Country Code */
	public static final int COUNTRY_SE = 5; 
	
	/** Swedish/Finish Keyboard layout Country Code */
	public static final int COUNTRY_FI = 5;
	
	/** Italian Keyboard layout Country Code */
	public static final int COUNTRY_IT = 6;
	
	/** Spanish Keyboard layout Country Code */
	public static final int COUNTRY_ES = 7;
	
	/** Japanese Keyboard layout Country Code */
	public static final int COUNTRY_JP = 8;
	
	/** Icelandic Keyboard layout Country Code */
	public static final int COUNTRY_IS = 9; 
	
	/** Norwegian Keyboard layout Country Code */
	public static final int COUNTRY_NO = 10;
	
	/** Swiss Keyboard layout Country Code */
	public static final int COUNTRY_CH = 11;
	
	/** Turkish Keyboard layout Country Code */
	public static final int COUNTRY_TR = 12;

	private RubberKeyboard rubberKb;
	
	/** Current Keyboard layout Country Code (default = COUNTRY_UK during boot of OZvm) */ 
    private int currentKbLayoutCountryCode;

    private Map currentKbLayout;
    private Map[] z88Keyboards;			// country specific keyboard layouts
    
	private int keyRows[];				// Z88 Hardware Keyboard (8x8) Matrix
	private KeyPress z88RshKey;			// Right Shift Key
	private KeyPress z88LshKey;			// Left Shift Key

	private KeyPress z88DiamondKey;
	private KeyPress z88SquareKey;
	private KeyPress z88TabKey;
	private KeyPress z88DelKey;
	private KeyPress z88EnterKey;
	private KeyPress z88ArrowLeftKey;
	private KeyPress z88ArrowRightKey;
	private KeyPress z88ArrowUpKey;
	private KeyPress z88ArrowDownKey;
	private KeyPress z88CapslockKey;
	private KeyPress z88EscKey;
	private KeyPress z88IndexKey;
	private KeyPress z88HelpKey;
	private KeyPress z88MenuKey;
	private KeyPress z88SpaceKey;

	private KeyPress searchKey;

	/** The Host -> Z88 Key mapping */ 
	private class KeyPress {
		private int keyCode;		// The unique host 'key' for this entity, typically a SWT.xxx constant
		private int keyZ88Typed;	// The Z88 Keyboard Matrix Entry for single typed key, eg. "A"

		public KeyPress(int kcd, int keyTyped) {
			keyCode = kcd;			// the KeyEvent.* definition host keyboard constants
			keyZ88Typed = keyTyped;
		}

		// override interface with the actual implementation for this object.
        public int hashCode() {
            return keyCode;	// the unique key is a perfect hash code
        }

        // override interface with the actual implementation for this object.
        public boolean equals(Object kc) {            
            if (!(kc instanceof KeyPress)) {
                return false;
            } else {
                KeyPress keyp = (KeyPress) kc;
	            if (keyCode == keyp.keyCode)
	                return true;
	            else
	                return false;
            }
        }
	}


    /**
     * Create the instance to bind the blink and Swing widget together.
     */
	public Z88Keyboard() {
		currentKbLayoutCountryCode = COUNTRY_UK;
		keyRows = new int[8];	// Z88 Hardware Keyboard (8x8) Matrix
		
		searchKey = new KeyPress(0,0); // create a search key instance 		

		for(int r=0; r<8;r++) keyRows[r] = 0xFF;	// Initialize to no keys pressed in z88 key matrix

		z88Keyboards = new HashMap[13];				// create the container for the various country keyboard layouts.
		createSystemKeys();
		createKbLayouts();
		
		// use default UK keyboard layout for default UK V4 ROM.
		currentKbLayout = z88Keyboards[currentKbLayoutCountryCode];

		Thread thread = new Thread() {
			public void run() {
				Z88KeyboardListener z88Kbl = new Z88KeyboardListener(); 
				
				// map Host keyboard events to this z88 keyboard, so that the emulator responds to keypresses.
				Z88.getInstance().getDisplay().setFocusTraversalKeysEnabled(false);	// get TAB key events on canvas
				Z88.getInstance().getDisplay().addKeyListener(z88Kbl); // keyboard events are processed in isolated Thread..				
			}
		};

		thread.setPriority(Thread.MAX_PRIORITY);
		thread.start();		
    }

	private void createKbLayouts() {
		Map defaultKbLayout = createUkLayout();

		// just use english keyboard for all countries that haven't got their layout implemented yet
		for (int l=0; l<z88Keyboards.length; l++) z88Keyboards[l] = defaultKbLayout;

		z88Keyboards[COUNTRY_FR] = createFrLayout();	// implement French keyboard layout
		z88Keyboards[COUNTRY_DK] = createDkLayout();	// implement Danish keyboard layout
		z88Keyboards[COUNTRY_SE] = createSeFiLayout();	// implement Swedish/Finish keyboard layout
		z88Keyboards[COUNTRY_FI] = z88Keyboards[COUNTRY_SE];
	}


	private void createSystemKeys() {
		// RSH: row 7 (0x7F), column 7 (0x7F, 01111111)
		z88RshKey = new KeyPress(KeyEvent.VK_SHIFT, 0x077F);

		// LSH: row 6 (0xBF), column 7 (0xBF, 10111111)
		z88LshKey = new KeyPress(KeyEvent.VK_SHIFT, 0x06BF);

		// SQR: row 7 (0x7F), column 6 (0xBF, 10111111)
		z88SquareKey = new KeyPress(KeyEvent.VK_ALT, 0x07BF);

		// DIA: row 6 (0xBF), column 4 (0xEF, 11101111)
		z88DiamondKey = new KeyPress(KeyEvent.VK_CONTROL, 0x06EF);

		// TAB = TAB, row 6 (0xBF), column 5 (0xDF, 11011111)
		z88TabKey = new KeyPress(KeyEvent.VK_TAB, 0x06DF);

		// DEL = Back Space, row 0 (0xFE), column 7 (0x7F, 01111111)
		z88DelKey = new KeyPress(KeyEvent.VK_BACK_SPACE, 0x007F);

		// ENTER, row 0 (0xFE), column 6 (0xBF, 10111111)
		z88EnterKey = new KeyPress(KeyEvent.VK_ENTER, 0x00BF);

		// ARROW LEFT, row 4 (0xEF), column 6 (0xBF, 10111111)
		z88ArrowLeftKey = new KeyPress(KeyEvent.VK_LEFT, 0x04BF);

		// ARROW RIGHT, row 3 (0xF7), column 6 (0xBF, 10111111)
		z88ArrowRightKey = new KeyPress(KeyEvent.VK_RIGHT, 0x03BF);

		// ARROW DOWN, row 2 (0xFB), column 6 (0xBF, 10111111)
		z88ArrowDownKey = new KeyPress(KeyEvent.VK_DOWN, 0x02BF);

		// ARROW UP, row 1 (0xFD), column 6 (0xBF, 10111111)
		z88ArrowUpKey = new KeyPress(KeyEvent.VK_UP, 0x01BF);

		// CAPS LOCK = CAPS, row 7 (0x7F), column 3 (0xF7, 11110111)
		z88CapslockKey = new KeyPress(KeyEvent.VK_CAPS_LOCK, 0x07F7);

		// ESC = ESC, row 7 (0x7F), column 5 (0xDF, 11011111)
		z88EscKey = new KeyPress(KeyEvent.VK_ESCAPE, 0x07DF);

		// INDEX = F2, row 7 (0x7F), column 4 (0xEF, 11101111)
		z88IndexKey = new KeyPress(KeyEvent.VK_F2, 0x07EF);

		// HELP = F1, row 6 (0xBF), column 7 (0x7F, 01111111)
		z88HelpKey = new KeyPress(KeyEvent.VK_F1, 0x067F);

		// MENU = F3, row 6 (0xBF), column 3 (0xF7, 11110111)
		z88MenuKey = new KeyPress(KeyEvent.VK_F3, 0x06F7);

		// SPACE, row 5 (0xEF), column 6 (0xBF, 10111111)
		z88SpaceKey = new KeyPress(KeyEvent.VK_SPACE, 0x05BF);
	}


	/**
	 * All Z88 keyboard layouts, whatever country, has the same system
	 * key positions in the matrix (<>, [], INDEX, HELP, CAPS...)<p>
	 *
	 * A few conventions have been defined to map the special keys in the Z88
	 * to a conventional computer keyboard:
	 * <PRE>
	 * 		HELP			= F1
	 * 		INDEX 			= F2
	 * 		MENU			= F3
	 * 		<> (Diamond) 	= Ctrl
	 * 		[] (Square)		= Alt
	 * 		HOME			= SHIFT LeftArrow
	 * 		END				= SHIFT RightArrow
	 * 		PAGE UP			= SHIFT UpArrow
	 * 		PAGE DOWN		= SHIFT DownArrow
	 * 		DELETE			= SHIFT BackSpace
	 * </PRE>
	 *
	 */
	private void mapSystemKeys(Map keyboardLayout) {
		// TAB = TAB, row 6 (0xBF), column 5 (0xDF, 11011111)
		keyboardLayout.put(z88TabKey, z88TabKey);

		// DEL = Back Space, row 0 (0xFE), column 7 (0x7F, 01111111)
		keyboardLayout.put(z88DelKey, z88DelKey);

		// ENTER, row 0 (0xFE), column 6 (0xBF, 10111111)
		keyboardLayout.put(z88EnterKey, z88EnterKey);

		// ARROW LEFT, row 4 (0xEF), column 6 (0xBF, 10111111)
		keyboardLayout.put(z88ArrowLeftKey, z88ArrowLeftKey);
		keyboardLayout.put(new KeyPress(KeyEvent.VK_KP_LEFT, 0), z88ArrowLeftKey);

		// ARROW RIGHT, row 3 (0xF7), column 6 (0xBF, 10111111)
		keyboardLayout.put(z88ArrowRightKey, z88ArrowRightKey);
		keyboardLayout.put(new KeyPress(KeyEvent.VK_KP_RIGHT, 0), z88ArrowRightKey);

		// ARROW DOWN, row 2 (0xFB), column 6 (0xBF, 10111111)
		keyboardLayout.put(z88ArrowDownKey, z88ArrowDownKey);
		keyboardLayout.put(new KeyPress(KeyEvent.VK_KP_DOWN, 0), z88ArrowDownKey);

		// ARROW UP, row 1 (0xFD), column 6 (0xBF, 10111111)
		keyboardLayout.put(z88ArrowUpKey, z88ArrowUpKey);
		keyboardLayout.put(new KeyPress(KeyEvent.VK_KP_UP, 0), z88ArrowUpKey);

		// CAPS LOCK = CAPS, row 7 (0x7F), column 3 (0xF7, 11110111)
		keyboardLayout.put(z88CapslockKey, z88CapslockKey);

		// ESC = ESC, row 7 (0x7F), column 5 (0xDF, 11011111)
		keyboardLayout.put(z88EscKey, z88EscKey);

		// HELP = F1, row 6 (0xBF), column 7 (0x7F, 01111111)
		keyboardLayout.put(z88HelpKey, z88HelpKey);

		// INDEX = F2, row 7 (0x7F), column 4 (0xEF, 11101111)
		keyboardLayout.put(z88IndexKey, z88IndexKey);

		// MENU = F3, row 6 (0xBF), column 3 (0xF7, 11110111)
		keyboardLayout.put(z88MenuKey, z88MenuKey);

		// SPACE, row 5 (0xEF), column 6 (0xBF, 10111111)
		keyboardLayout.put(z88SpaceKey, z88SpaceKey);
	}

	/**
	 * Add a KeyPress object into the specified HashMap
	 * 
	 * @param kbdLayout the HashMap Host -> Z88 keyboard layout
	 * @param keyCode the host keyboard entry
	 * @param keyTyped the Z88 key matrix 
	 */
	private void addKey(Map kbdLayout, int keyCode, int keyTyped) {
		KeyPress kp = new KeyPress(keyCode, keyTyped); 
		kbdLayout.put(kp, kp);
	}
	
	/**
	 * Create Key Event mappings for Z88 english (UK) keyboard matrix.
	 *
	 * All key entry mappings are implemented using the
	 * International 104 PC Keyboard with the UK layout.
	 * In other words, to obtain the best Z88 keyboard access
	 * on an english (UK) Rom, you need to use the english keyboard
	 * layout on your host operating system.
	 *
	 * The mappings only contains the single key press access.
	 * Modifier key combinations (with Shift, Diamond, Square) are
	 * automatically handled by the Z88 operating system. "OZvm"
	 * just maps the modifier keys to host PC keyboard and let
	 * OZ decide what to display on the Z88.
	 *
	 * <PRE>
	 *	------------------------------------------------------------------------
	 *	UK Keyboard matrix
	 *	-------------------------------------------------------------------------
	 *			 | D7     D6      D5      D4      D3      D2      D1      D0
	 *	-------------------------------------------------------------------------
	 *	A15 (#7) | RSH    SQR     ESC     INDEX   CAPS    .       /       £
	 *	A14 (#6) | HELP   LSH     TAB     DIA     MENU    ,       ;       '
	 *	A13 (#5) | [      SPACE   1       Q       A       Z       L       0
	 *	A12 (#4) | ]      LFT     2       W       S       X       M       P
	 *	A11 (#3) | -      RGT     3       E       D       C       K       9
	 *	A10 (#2) | =      DWN     4       R       F       V       J       O
	 *	A9  (#1) | \      UP      5       T       G       B       U       I
	 *	A8  (#0) | DEL    ENTER   6       Y       H       N       7       8
	 *	-------------------------------------------------------------------------
	 * </PRE>
	 *
	 */
	private Map createUkLayout() {
		Map keyboardLayout = new HashMap();
		mapSystemKeys(keyboardLayout);
	
		// --------------------------------------------------------------------------------------------------------------------------
		// Row 01111111:
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A15 (#7) | RSH    SQR     ESC     INDEX   CAPS    .       /       £
		// Single key:
		addKey(keyboardLayout, KeyEvent.VK_PERIOD, 0x07FB);
		addKey(keyboardLayout, KeyEvent.VK_SLASH, 0x07FD);
	
		// The '£' key is not available as a single letter on Brittish (UK) PC keyboards
		// and is therefore handled specially 
		// ('£' is accessed using SHIFT 3 on a PC keyboard)
		addKey(keyboardLayout, '£', 0x07FE);
		// --------------------------------------------------------------------------------------------------------------------------
	
		// --------------------------------------------------------------------------------------------------------------------------
		// Row 10111111
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A14 (#6) | HELP   LSH     TAB     DIA     MENU    ,       ;       '
		// Single key:
		addKey(keyboardLayout, KeyEvent.VK_COMMA, 0x06FB);
		addKey(keyboardLayout, KeyEvent.VK_SEMICOLON, 0x06FD);
		addKey(keyboardLayout, KeyEvent.VK_QUOTE, 0x06FE);
		// --------------------------------------------------------------------------------------------------------------------------
	
		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11011111
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A13 (#5) | [      SPACE   1       Q       A       Z       L       0
		// Single key:
		addKey(keyboardLayout, KeyEvent.VK_OPEN_BRACKET, 0x057F);
	
		addKey(keyboardLayout, KeyEvent.VK_1, 0x05DF);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD1, 0x05DF);
		
		addKey(keyboardLayout, KeyEvent.VK_Q, 0x05EF);
		addKey(keyboardLayout, KeyEvent.VK_A, 0x05F7);
		addKey(keyboardLayout, KeyEvent.VK_Z, 0x05FB);
		addKey(keyboardLayout, KeyEvent.VK_L, 0x05FD);
	
		addKey(keyboardLayout, KeyEvent.VK_0, 0x05FE);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD0, 0x05FE);
		// --------------------------------------------------------------------------------------------------------------------------
	
		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11101111
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A12 (#4) | ]      LFT     2       W       S       X       M       P
		// Single key:
		addKey(keyboardLayout, KeyEvent.VK_CLOSE_BRACKET, 0x047F);
		
		addKey(keyboardLayout, KeyEvent.VK_2, 0x04DF);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD2, 0x04DF);
	
		addKey(keyboardLayout, KeyEvent.VK_W, 0x04EF);
		addKey(keyboardLayout, KeyEvent.VK_S, 0x04F7);
		addKey(keyboardLayout, KeyEvent.VK_X, 0x04FB);
		addKey(keyboardLayout, KeyEvent.VK_M, 0x04FD);
		addKey(keyboardLayout, KeyEvent.VK_P, 0x04FE);
		// --------------------------------------------------------------------------------------------------------------------------
	
		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11110111
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A11 (#3) | -      RGT     3       E       D       C       K       9
		// Single key:
		addKey(keyboardLayout, KeyEvent.VK_MINUS, 0x037F);
	
		addKey(keyboardLayout, KeyEvent.VK_3, 0x03DF);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD3, 0x03DF);
		
		addKey(keyboardLayout, KeyEvent.VK_E, 0x03EF);
		addKey(keyboardLayout, KeyEvent.VK_D, 0x03F7);
		addKey(keyboardLayout, KeyEvent.VK_C, 0x03FB);
		addKey(keyboardLayout, KeyEvent.VK_K, 0x03FD);
	
		addKey(keyboardLayout, KeyEvent.VK_9, 0x03FE);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD9, 0x03FE);
		// --------------------------------------------------------------------------------------------------------------------------
	
		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11111011
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A10 (#2) | =      DWN     4       R       F       V       J       O
		// Single key:
		addKey(keyboardLayout, KeyEvent.VK_EQUALS, 0x027F);
		
		addKey(keyboardLayout, KeyEvent.VK_4, 0x02DF);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD4, 0x02DF);
	
		addKey(keyboardLayout, KeyEvent.VK_R, 0x02EF);
		addKey(keyboardLayout, KeyEvent.VK_F, 0x02F7);
		addKey(keyboardLayout, KeyEvent.VK_V, 0x02FB);
		addKey(keyboardLayout, KeyEvent.VK_J, 0x02FD);
		addKey(keyboardLayout, KeyEvent.VK_O, 0x02FE);
		// --------------------------------------------------------------------------------------------------------------------------
	
		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11111101
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A9  (#1) | \      UP      5       T       G       B       U       I
		// Single key:
		addKey(keyboardLayout, KeyEvent.VK_BACK_SLASH, 0x017F);		
		
		addKey(keyboardLayout, KeyEvent.VK_5, 0x01DF);		
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD5, 0x01DF);		
	
		addKey(keyboardLayout, KeyEvent.VK_T, 0x01EF);		
		addKey(keyboardLayout, KeyEvent.VK_G, 0x01F7);		
		addKey(keyboardLayout, KeyEvent.VK_B, 0x01FB);		
		addKey(keyboardLayout, KeyEvent.VK_U, 0x01FD);		
		addKey(keyboardLayout, KeyEvent.VK_I, 0x01FE);		
		// --------------------------------------------------------------------------------------------------------------------------
	
		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11111110
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A8  (#0) | DEL    ENTER   6       Y       H       N       7       8
		// Single key:
		addKey(keyboardLayout, KeyEvent.VK_6, 0x00DF);		
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD6, 0x00DF);		
	
		addKey(keyboardLayout, KeyEvent.VK_Y, 0x00EF);		
		addKey(keyboardLayout, KeyEvent.VK_H, 0x00F7);		
		addKey(keyboardLayout, KeyEvent.VK_N, 0x00FB);		
	
		addKey(keyboardLayout, KeyEvent.VK_7, 0x00FD);		
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD7, 0x00FD);		
	
		addKey(keyboardLayout, KeyEvent.VK_8, 0x00FE);		
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD8, 0x00FE);		
		// --------------------------------------------------------------------------------------------------------------------------
	
		return keyboardLayout;
	}

	/**
	 * Create Key Event mappings for Z88 english (US) keyboard matrix.
	 *
	 * All key entry mappings are implemented using the
	 * International 104 PC Keyboard with the UK layout.
	 * In other words, to obtain the best Z88 keyboard access
	 * on an english (US) Rom, you need to use the english keyboard
	 * layout on your host operating system.
	 *
	 * The mappings only contains the single key press access.
	 * Modifier key combinations (with Shift, Diamond, Square) are
	 * automatically handled by the Z88 operating system. "OZvm"
	 * just maps the modifier keys to host PC keyboard and let
	 * OZ decide what to display on the Z88.
	 *
	 * <PRE>
	 *	------------------------------------------------------------------------
	 *	US Keyboard matrix
	 *	-------------------------------------------------------------------------
	 *			 | D7     D6      D5      D4      D3      D2      D1      D0
	 *	-------------------------------------------------------------------------
	 *	A15 (#7) | RSH    SQR     ESC     INDEX   CAPS    .       /       £
	 *	A14 (#6) | HELP   LSH     TAB     DIA     MENU    ,       ;       '
	 *	A13 (#5) | [      SPACE   1       Q       A       Z       L       0
	 *	A12 (#4) | ]      LFT     2       W       S       X       M       P
	 *	A11 (#3) | -      RGT     3       E       D       C       K       9
	 *	A10 (#2) | =      DWN     4       R       F       V       J       O
	 *	A9  (#1) | \      UP      5       T       G       B       U       I
	 *	A8  (#0) | DEL    ENTER   6       Y       H       N       7       8
	 *	-------------------------------------------------------------------------
	 * </PRE>
	 *
	 */
	private Map createUsLayout() {
		Map keyboardLayout = new HashMap();
		mapSystemKeys(keyboardLayout);

		// --------------------------------------------------------------------------------------------------------------------------
		// Row 01111111:
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A15 (#7) | RSH    SQR     ESC     INDEX   CAPS    .       /       £
		// Single key:
		addKey(keyboardLayout, KeyEvent.VK_PERIOD, 0x07FB);
		addKey(keyboardLayout, KeyEvent.VK_SLASH, 0x07FD);

		// The '£' key is not available as a single letter on US International PC keyboards
		// and is therefore handled specially
		// --------------------------------------------------------------------------------------------------------------------------

		// --------------------------------------------------------------------------------------------------------------------------
		// Row 10111111
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A14 (#6) | HELP   LSH     TAB     DIA     MENU    ,       ;       '
		// Single key:
		addKey(keyboardLayout, KeyEvent.VK_COMMA, 0x06FB);
		addKey(keyboardLayout, KeyEvent.VK_SEMICOLON, 0x06FD);
		addKey(keyboardLayout, KeyEvent.VK_QUOTE, 0x06FE);
		// --------------------------------------------------------------------------------------------------------------------------

		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11011111
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A13 (#5) | [      SPACE   1       Q       A       Z       L       0
		// Single key:
		addKey(keyboardLayout, KeyEvent.VK_OPEN_BRACKET, 0x057F);

		addKey(keyboardLayout, KeyEvent.VK_1, 0x05DF);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD1, 0x05DF);
		
		addKey(keyboardLayout, KeyEvent.VK_Q, 0x05EF);
		addKey(keyboardLayout, KeyEvent.VK_A, 0x05F7);
		addKey(keyboardLayout, KeyEvent.VK_Z, 0x05FB);
		addKey(keyboardLayout, KeyEvent.VK_L, 0x05FD);

		addKey(keyboardLayout, KeyEvent.VK_0, 0x05FE);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD0, 0x05FE);
		// --------------------------------------------------------------------------------------------------------------------------

		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11101111
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A12 (#4) | ]      LFT     2       W       S       X       M       P
		// Single key:
		addKey(keyboardLayout, KeyEvent.VK_CLOSE_BRACKET, 0x047F);
		
		addKey(keyboardLayout, KeyEvent.VK_2, 0x04DF);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD2, 0x04DF);

		addKey(keyboardLayout, KeyEvent.VK_W, 0x04EF);
		addKey(keyboardLayout, KeyEvent.VK_S, 0x04F7);
		addKey(keyboardLayout, KeyEvent.VK_X, 0x04FB);
		addKey(keyboardLayout, KeyEvent.VK_M, 0x04FD);
		addKey(keyboardLayout, KeyEvent.VK_P, 0x04FE);
		// --------------------------------------------------------------------------------------------------------------------------

		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11110111
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A11 (#3) | -      RGT     3       E       D       C       K       9
		// Single key:
		addKey(keyboardLayout, KeyEvent.VK_MINUS, 0x037F);

		addKey(keyboardLayout, KeyEvent.VK_3, 0x03DF);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD3, 0x03DF);
		
		addKey(keyboardLayout, KeyEvent.VK_E, 0x03EF);
		addKey(keyboardLayout, KeyEvent.VK_D, 0x03F7);
		addKey(keyboardLayout, KeyEvent.VK_C, 0x03FB);
		addKey(keyboardLayout, KeyEvent.VK_K, 0x03FD);

		addKey(keyboardLayout, KeyEvent.VK_9, 0x03FE);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD9, 0x03FE);
		// --------------------------------------------------------------------------------------------------------------------------

		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11111011
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A10 (#2) | =      DWN     4       R       F       V       J       O
		// Single key:
		addKey(keyboardLayout, KeyEvent.VK_EQUALS, 0x027F);
		
		addKey(keyboardLayout, KeyEvent.VK_4, 0x02DF);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD4, 0x02DF);

		addKey(keyboardLayout, KeyEvent.VK_R, 0x02EF);
		addKey(keyboardLayout, KeyEvent.VK_F, 0x02F7);
		addKey(keyboardLayout, KeyEvent.VK_V, 0x02FB);
		addKey(keyboardLayout, KeyEvent.VK_J, 0x02FD);
		addKey(keyboardLayout, KeyEvent.VK_O, 0x02FE);
		// --------------------------------------------------------------------------------------------------------------------------

		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11111101
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A9  (#1) | \      UP      5       T       G       B       U       I
		// Single key:
		addKey(keyboardLayout, KeyEvent.VK_BACK_SLASH, 0x017F);		
		
		addKey(keyboardLayout, KeyEvent.VK_5, 0x01DF);		
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD5, 0x01DF);		

		addKey(keyboardLayout, KeyEvent.VK_T, 0x01EF);		
		addKey(keyboardLayout, KeyEvent.VK_G, 0x01F7);		
		addKey(keyboardLayout, KeyEvent.VK_B, 0x01FB);		
		addKey(keyboardLayout, KeyEvent.VK_U, 0x01FD);		
		addKey(keyboardLayout, KeyEvent.VK_I, 0x01FE);		
		// --------------------------------------------------------------------------------------------------------------------------

		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11111110
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A8  (#0) | DEL    ENTER   6       Y       H       N       7       8
		// Single key:
		addKey(keyboardLayout, KeyEvent.VK_6, 0x00DF);		
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD6, 0x00DF);		

		addKey(keyboardLayout, KeyEvent.VK_Y, 0x00EF);		
		addKey(keyboardLayout, KeyEvent.VK_H, 0x00F7);		
		addKey(keyboardLayout, KeyEvent.VK_N, 0x00FB);		

		addKey(keyboardLayout, KeyEvent.VK_7, 0x00FD);		
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD7, 0x00FD);		

		addKey(keyboardLayout, KeyEvent.VK_8, 0x00FE);		
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD8, 0x00FE);		
		// --------------------------------------------------------------------------------------------------------------------------

		return keyboardLayout;
	}


	/**
	 * Create Key Event mappings for Z88 FR (French) keyboard matrix.
	 *
	 * All key entry mappings are implemented using the
	 * International 104 PC Keyboard with the french (FR) layout.
	 * In other words, to obtain the best Z88 keyboard access
	 * on a French Z88 Rom, you need to use the French keyboard layout on
	 * your host operating system.
	 *
	 * The mappings only contains the single key press access.
	 * Modifier key combinations (with Shift, Diamond, Square) are
	 * automatically handled by the Z88 operating system. "OZvm"
	 * just maps the modifier keys to host PC keyboard and let
	 * OZ decide what to display on the Z88.
	 *
	 * <PRE>
	 *	------------------------------------------------------------------------
	 *	FR Keyboard matrix
	 *	-------------------------------------------------------------------------
	 *			 | D7     D6      D5      D4      D3      D2      D1      D0
	 *	-------------------------------------------------------------------------
	 *	A15 (#7) | RSH    SQR     ESC     INDEX   CAPS    :       $       ^
	 *	A14 (#6) | HELP   LSH     TAB     DIA     MENU    ;       M       ù
	 *	A13 (#5) | *      SPACE   &       A       Q       W       L       à
	 *	A12 (#4) | =      LFT     é       Z       S       X       ,       P
	 *	A11 (#3) | )      RGT     "       E       D       C       K       ç
	 *	A10 (#2) | -      DWN     '       R       F       V       J       O
	 *	A9  (#1) | <      UP      (       T       G       B       U       I
	 *	A8  (#0) | DEL    ENTER   §       Y       H       N       è       !
	 *	-------------------------------------------------------------------------
	 * </PRE>
	 *
	 */
	private Map createFrLayout() {
		Map keyboardLayout = new HashMap();
		mapSystemKeys(keyboardLayout);

		// --------------------------------------------------------------------------------------------------------------------------
		// Row 01111111:
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A15 (#7) | RSH    SQR     ESC     INDEX   CAPS    :       $       ^
		// Single key:
		addKey(keyboardLayout, KeyEvent.VK_COLON, 0x07FB);
		addKey(keyboardLayout, KeyEvent.VK_DOLLAR, 0x07FD);

		addKey(keyboardLayout, KeyEvent.VK_DEAD_CIRCUMFLEX, 0x07FE);
		// --------------------------------------------------------------------------------------------------------------------------

		// --------------------------------------------------------------------------------------------------------------------------
		// Row 10111111
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A14 (#6) | HELP   LSH     TAB     DIA     MENU    ;       M       ù
		// Single key:
		addKey(keyboardLayout, KeyEvent.VK_SEMICOLON, 0x06FB);		
		addKey(keyboardLayout, KeyEvent.VK_M, 0x06FD);		
		addKey(keyboardLayout, (0x10000 | 0xF9), 0x06FE);	// 'ù'		
		addKey(keyboardLayout, (0x10000 | '%'), 0x06FE);	// SHIFT 'ù' = '%'
		// --------------------------------------------------------------------------------------------------------------------------

		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11011111
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A13 (#5) | *      SPACE   &       A       Q       W       L       à
		// Single key:
		addKey(keyboardLayout, KeyEvent.VK_ASTERISK, 0x057F);		

		addKey(keyboardLayout, KeyEvent.VK_1, 0x05DF);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD1, 0x05DF);

		addKey(keyboardLayout, KeyEvent.VK_A, 0x05EF);
		addKey(keyboardLayout, KeyEvent.VK_Q, 0x05F7);
		addKey(keyboardLayout, KeyEvent.VK_W, 0x05FB);
		addKey(keyboardLayout, KeyEvent.VK_L, 0x05FD);

		addKey(keyboardLayout, KeyEvent.VK_0, 0x05FE);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD0, 0x05FE);
		// --------------------------------------------------------------------------------------------------------------------------

		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11101111
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A12 (#4) | =      LFT     é       Z       S       X       ,       P
		// Single key:
		addKey(keyboardLayout, KeyEvent.VK_EQUALS, 0x047F);
		
		addKey(keyboardLayout, KeyEvent.VK_2, 0x04DF);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD2, 0x04DF);

		addKey(keyboardLayout, KeyEvent.VK_Z, 0x04EF);
		addKey(keyboardLayout, KeyEvent.VK_S, 0x04F7);
		addKey(keyboardLayout, KeyEvent.VK_X, 0x04FB);
		addKey(keyboardLayout, KeyEvent.VK_COMMA, 0x04FD);
		addKey(keyboardLayout, KeyEvent.VK_P, 0x04FE);
		// --------------------------------------------------------------------------------------------------------------------------

		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11110111
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A11 (#3) | )      RGT     "       E       D       C       K       ç
		// Single key:
		addKey(keyboardLayout, KeyEvent.VK_RIGHT_PARENTHESIS, 0x037F);

		addKey(keyboardLayout, KeyEvent.VK_3, 0x03DF);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD3, 0x03DF);

		addKey(keyboardLayout, KeyEvent.VK_E, 0x03EF);
		addKey(keyboardLayout, KeyEvent.VK_D, 0x03F7);
		addKey(keyboardLayout, KeyEvent.VK_C, 0x03FB);
		addKey(keyboardLayout, KeyEvent.VK_K, 0x03FD);

		addKey(keyboardLayout, KeyEvent.VK_9, 0x03FE);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD9, 0x03FE);
		// --------------------------------------------------------------------------------------------------------------------------

		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11111011
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A10 (#2) | -      DWN     '       R       F       V       J       O
		// Single key:
		addKey(keyboardLayout, KeyEvent.VK_MINUS, 0x027F);

		addKey(keyboardLayout, KeyEvent.VK_4, 0x02DF);		
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD4, 0x02DF);		

		addKey(keyboardLayout, KeyEvent.VK_R, 0x02EF);		
		addKey(keyboardLayout, KeyEvent.VK_F, 0x02F7);		
		addKey(keyboardLayout, KeyEvent.VK_V, 0x02FB);		
		addKey(keyboardLayout, KeyEvent.VK_J, 0x02FD);		
		addKey(keyboardLayout, KeyEvent.VK_O, 0x02FE);		
		// --------------------------------------------------------------------------------------------------------------------------

		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11111101
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A9  (#1) | <      UP      (       T       G       B       U       I
		// Single key:
		addKey(keyboardLayout, KeyEvent.VK_LESS, 0x017F);

		addKey(keyboardLayout, KeyEvent.VK_5, 0x01DF);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD5, 0x01DF);

		addKey(keyboardLayout, KeyEvent.VK_T, 0x01EF);
		addKey(keyboardLayout, KeyEvent.VK_G, 0x01F7);
		addKey(keyboardLayout, KeyEvent.VK_B, 0x01FB);
		addKey(keyboardLayout, KeyEvent.VK_U, 0x01FD);
		addKey(keyboardLayout, KeyEvent.VK_I, 0x01FE);
		// --------------------------------------------------------------------------------------------------------------------------

		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11111110
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A8  (#0) | DEL    ENTER   §       Y       H       N       è       !
		// Single key:
		addKey(keyboardLayout, KeyEvent.VK_6, 0x00DF);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD6, 0x00DF);

		addKey(keyboardLayout, KeyEvent.VK_Y, 0x00EF);
		addKey(keyboardLayout, KeyEvent.VK_H, 0x00F7);
		addKey(keyboardLayout, KeyEvent.VK_N, 0x00FB);

		addKey(keyboardLayout, KeyEvent.VK_7, 0x00FD);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD7, 0x00FD);
		
		addKey(keyboardLayout, KeyEvent.VK_EXCLAMATION_MARK, 0x00FE);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD8, 0x00FE);
		// --------------------------------------------------------------------------------------------------------------------------

		return keyboardLayout;
	}


	/**
	 * Create Key Event mappings for Z88 danish (DK) keyboard matrix.
	 *
	 * All key entry mappings are implemented using the
	 * International 104 PC Keyboard using the danish layout.
	 * In other words, to obtain the best Z88 keyboard access
	 * on a danish (DK) Rom, you need to use the danish keyboard
	 * layout on your host operating system.
	 *
	 * The mappings only contains the single key press access.
	 * Modifier key combinations (with Shift, Diamond, Square) are
	 * automatically handled by the Z88 operating system. "OZvm"
	 * just maps the modifier keys to host PC keyboard and let
	 * OZ decide what to display on the Z88.
	 *
	 * <PRE>
	 *	------------------------------------------------------------------------
	 *	DK Keyboard matrix
	 *	-------------------------------------------------------------------------
	 *			 | D7     D6      D5      D4      D3      D2      D1      D0
	 *	-------------------------------------------------------------------------
	 *	A15 (#7) | RSH    SQR     ESC     INDEX   CAPS    .       -       £
	 *	A14 (#6) | HELP   LSH     TAB     DIA     MENU    ,       Æ       Ø
	 *	A13 (#5) | Å      SPACE   1       Q       A       Z       L       0
	 *	A12 (#4) | '      LFT     2       W       S       X       M       P
	 *	A11 (#3) | =      RGT     3       E       D       C       K       9
	 *	A10 (#2) | +      DWN     4       R       F       V       J       O
	 *	A9  (#1) | /      UP      5       T       G       B       U       I
	 *	A8  (#0) | DEL    ENTER   6       Y       H       N       7       8
	 *	-------------------------------------------------------------------------
	 * </PRE>
	 *
	 */
	private Map createDkLayout() {
		Map keyboardLayout = new HashMap();
		mapSystemKeys(keyboardLayout);

		// --------------------------------------------------------------------------------------------------------------------------
		// Row 01111111:
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A15 (#7) | RSH    SQR     ESC     INDEX   CAPS    .       -       £
		// Single key:
		addKey(keyboardLayout, KeyEvent.VK_PERIOD, 0x07FB);
		addKey(keyboardLayout, KeyEvent.VK_MINUS, 0x07FD);

		// The '£' key is not available as a single letter on DK International PC keyboards, so we steel the '<' key next to 'Z'
		addKey(keyboardLayout, KeyEvent.VK_LESS, 0x07FE);
		// --------------------------------------------------------------------------------------------------------------------------

		// --------------------------------------------------------------------------------------------------------------------------
		// Row 10111111
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A14 (#6) | HELP   LSH     TAB     DIA     MENU    ,       Æ       Ø
		// Single key:
		addKey(keyboardLayout, KeyEvent.VK_COMMA, 0x06FB);
		addKey(keyboardLayout, (0x10000 | 0xE6), 0x06FD); // 'æ'
		addKey(keyboardLayout, (0x10000 | 0xC6), 0x06FD); // 'Æ'
		addKey(keyboardLayout, (0x10000 | 134), 0x06FD); // CTRL æ
		addKey(keyboardLayout, (0x10000 | 0xF8), 0x06FE); // 'ø'
		addKey(keyboardLayout, (0x10000 | 0xD8), 0x06FE); // 'Ø'
		addKey(keyboardLayout, (0x10000 | 152), 0x06FE); // CTRL ø
		// --------------------------------------------------------------------------------------------------------------------------

		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11011111
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A13 (#5) | Å      SPACE   1       Q       A       Z       L       0
		// Single key:
		addKey(keyboardLayout, (0x10000 | 0xE5), 0x057F); // 'å'
		addKey(keyboardLayout, (0x10000 | 0xC5), 0x057F); // 'Å'
		addKey(keyboardLayout, (0x10000 | 133), 0x057F); // CTRL å
		
		addKey(keyboardLayout, KeyEvent.VK_1, 0x05DF);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD1, 0x05DF);

		addKey(keyboardLayout, KeyEvent.VK_Q, 0x05EF);
		addKey(keyboardLayout, KeyEvent.VK_A, 0x05F7);
		addKey(keyboardLayout, KeyEvent.VK_Z, 0x05FB);
		addKey(keyboardLayout, KeyEvent.VK_L, 0x05FD);

		addKey(keyboardLayout, KeyEvent.VK_0, 0x05FE);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD0, 0x05FE);
		// --------------------------------------------------------------------------------------------------------------------------

		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11101111
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A12 (#4) | '      LFT     2       W       S       X       M       P
		// Single key:
		addKey(keyboardLayout, KeyEvent.VK_QUOTE, 0x047F);
		
		addKey(keyboardLayout, KeyEvent.VK_2, 0x04DF);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD2, 0x04DF);

		addKey(keyboardLayout, KeyEvent.VK_W, 0x04EF);
		addKey(keyboardLayout, KeyEvent.VK_S, 0x04F7);
		addKey(keyboardLayout, KeyEvent.VK_X, 0x04FB);
		addKey(keyboardLayout, KeyEvent.VK_M, 0x04FD);
		addKey(keyboardLayout, KeyEvent.VK_P, 0x04FE);
		// --------------------------------------------------------------------------------------------------------------------------

		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11110111
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A11 (#3) | =      RGT     3       E       D       C       K       9
		// Single key:
		// '=' is not available as a direct key on DK host layout, so we steel the '`' key between '+' key and BACK SPACE
		addKey(keyboardLayout, KeyEvent.VK_DEAD_ACUTE, 0x037F);

		addKey(keyboardLayout, KeyEvent.VK_3, 0x03DF);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD3, 0x03DF);

		addKey(keyboardLayout, KeyEvent.VK_E, 0x03EF);
		addKey(keyboardLayout, KeyEvent.VK_D, 0x03F7);
		addKey(keyboardLayout, KeyEvent.VK_C, 0x03FB);
		addKey(keyboardLayout, KeyEvent.VK_K, 0x03FD);

		addKey(keyboardLayout, KeyEvent.VK_9, 0x03FE);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD9, 0x03FE);
		// --------------------------------------------------------------------------------------------------------------------------

		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11111011
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A10 (#2) | +      DWN     4       R       F       V       J       O
		// Single key:
		addKey(keyboardLayout, KeyEvent.VK_PLUS, 0x027F);

		addKey(keyboardLayout, KeyEvent.VK_4, 0x02DF);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD4, 0x02DF);

		addKey(keyboardLayout, KeyEvent.VK_R, 0x02EF);
		addKey(keyboardLayout, KeyEvent.VK_F, 0x02F7);
		addKey(keyboardLayout, KeyEvent.VK_V, 0x02FB);
		addKey(keyboardLayout, KeyEvent.VK_J, 0x02FD);
		addKey(keyboardLayout, KeyEvent.VK_O, 0x02FE);
		// --------------------------------------------------------------------------------------------------------------------------

		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11111101
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A9  (#1) | /      UP      5       T       G       B       U       I
		// Single key:
		// '/' does not exist as a single key press, so we steel the '^' key next to 'Å' key.
		addKey(keyboardLayout, KeyEvent.VK_DEAD_DIAERESIS, 0x017F);

		addKey(keyboardLayout, KeyEvent.VK_5, 0x01DF);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD5, 0x01DF);

		addKey(keyboardLayout, KeyEvent.VK_T, 0x01EF);
		addKey(keyboardLayout, KeyEvent.VK_G, 0x01F7);
		addKey(keyboardLayout, KeyEvent.VK_B, 0x01FB);
		addKey(keyboardLayout, KeyEvent.VK_U, 0x01FD);
		addKey(keyboardLayout, KeyEvent.VK_I, 0x01FE);
		// --------------------------------------------------------------------------------------------------------------------------


		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11111110
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A8  (#0) | DEL    ENTER   6       Y       H       N       7       8
		// Single key:
		addKey(keyboardLayout, KeyEvent.VK_6, 0x00DF);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD6, 0x00DF);

		addKey(keyboardLayout, KeyEvent.VK_Y, 0x00EF);
		addKey(keyboardLayout, KeyEvent.VK_H, 0x00F7);
		addKey(keyboardLayout, KeyEvent.VK_N, 0x00FB);

		addKey(keyboardLayout, KeyEvent.VK_7, 0x00FD);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD7, 0x00FD);

		addKey(keyboardLayout, KeyEvent.VK_8, 0x00FE);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD8, 0x00FE);
		// --------------------------------------------------------------------------------------------------------------------------

		return keyboardLayout;
	}


	/**
	 * Create Key Event mappings for Z88 Swedish/Finish (SE/FI) keyboard matrix.
	 *
	 * All key entry mappings are implemented using the
	 * International 104 PC Keyboard using the swedish/finish layout.
	 * In other words, to obtain the best Z88 keyboard access
	 * on a swedish/finish (SE/FI) Rom, you need to use the
	 * swedish/finish keyboard layout on your host operating system.
	 *
	 * The mappings only contains the single key press access.
	 * Modifier key combinations (with Shift, Diamond, Square) are
	 * automatically handled by the Z88 operating system. "OZvm"
	 * just maps the modifier keys to host PC keyboard and let
	 * OZ decide what to display on the Z88.
	 *
	 * <PRE>
	 *	------------------------------------------------------------------------
	 *	SE/FI Keyboard matrix
	 *	-------------------------------------------------------------------------
	 *			 | D7     D6      D5      D4      D3      D2      D1      D0
	 *	-------------------------------------------------------------------------
	 *	A15 (#7) | RSH    SQR     ESC     INDEX   CAPS    .       -       £
	 *	A14 (#6) | HELP   LSH     TAB     DIA     MENU    ,       Ö       Ä
	 *	A13 (#5) | Å      SPACE   1       Q       A       Z       L       0
	 *	A12 (#4) | '      LFT     2       W       S       X       M       P
	 *	A11 (#3) | =      RGT     3       E       D       C       K       9
	 *	A10 (#2) | +      DWN     4       R       F       V       J       O
	 *	A9  (#1) | /      UP      5       T       G       B       U       I
	 *	A8  (#0) | DEL    ENTER   6       Y       H       N       7       8
	 *	-------------------------------------------------------------------------
	 * </PRE>
	 *
	 */
	private Map createSeFiLayout() {
		Map keyboardLayout = new HashMap();
		mapSystemKeys(keyboardLayout);

		// --------------------------------------------------------------------------------------------------------------------------
		// Row 01111111:
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A15 (#7) | RSH    SQR     ESC     INDEX   CAPS    .       -       £
		// Single key:
		addKey(keyboardLayout, KeyEvent.VK_PERIOD, 0x07FB);		
		addKey(keyboardLayout, KeyEvent.VK_MINUS, 0x07FD);		

		// The '£' key is not available as a single letter on DK International PC keyboards, so we steel the '<' key next to 'Z'
		addKey(keyboardLayout, KeyEvent.VK_LESS, 0x07FE);		
		// --------------------------------------------------------------------------------------------------------------------------

		// --------------------------------------------------------------------------------------------------------------------------
		// Row 10111111
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A14 (#6) | HELP   LSH     TAB     DIA     MENU    ,       Æ       Ø
		// Single key:
		addKey(keyboardLayout, KeyEvent.VK_COMMA, 0x06FB);
		addKey(keyboardLayout, (0x10000 | 0xF6), 0x06FD); // 'ö'
		addKey(keyboardLayout, (0x10000 | 0xD6), 0x06FD); // 'Ö'
		addKey(keyboardLayout, (0x10000 | 150), 0x06FD); // CTRL ö
		addKey(keyboardLayout, (0x10000 | 0xE4), 0x06FE); // 'ä'
		addKey(keyboardLayout, (0x10000 | 0xC4), 0x06FE); // 'Ä'
		addKey(keyboardLayout, (0x10000 | 132), 0x06FE); // CTRL ä
		// --------------------------------------------------------------------------------------------------------------------------

		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11011111
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A13 (#5) | Å      SPACE   1       Q       A       Z       L       0
		// Single key:
		addKey(keyboardLayout, (0x10000 | 0xE5), 0x057F); // 'å'
		addKey(keyboardLayout, (0x10000 | 0xC5), 0x057F); // 'Å'
		addKey(keyboardLayout, (0x10000 | 133), 0x057F); // CTRL å

		addKey(keyboardLayout, KeyEvent.VK_1, 0x05DF);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD1, 0x05DF);

		addKey(keyboardLayout, KeyEvent.VK_Q, 0x05EF);
		addKey(keyboardLayout, KeyEvent.VK_A, 0x05F7);
		addKey(keyboardLayout, KeyEvent.VK_Z, 0x05FB);
		addKey(keyboardLayout, KeyEvent.VK_L, 0x05FD);

		addKey(keyboardLayout, KeyEvent.VK_0, 0x05FE);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD0, 0x05FE);
		// --------------------------------------------------------------------------------------------------------------------------

		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11101111
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A12 (#4) | '      LFT     2       W       S       X       M       P
		// Single key:
		addKey(keyboardLayout, KeyEvent.VK_QUOTE, 0x047F);

		addKey(keyboardLayout, KeyEvent.VK_2, 0x04DF);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD2, 0x04DF);

		addKey(keyboardLayout, KeyEvent.VK_W, 0x04EF);
		addKey(keyboardLayout, KeyEvent.VK_S, 0x04F7);
		addKey(keyboardLayout, KeyEvent.VK_X, 0x04FB);
		addKey(keyboardLayout, KeyEvent.VK_M, 0x04FD);
		addKey(keyboardLayout, KeyEvent.VK_P, 0x04FE);
		// --------------------------------------------------------------------------------------------------------------------------

		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11110111
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A11 (#3) | =      RGT     3       E       D       C       K       9
		// Single key:
		// '=' is not available as a direct key on DK host layout, so we steel the '`' key between '+' key and BACK SPACE
		addKey(keyboardLayout, KeyEvent.VK_DEAD_ACUTE, 0x037F);

		addKey(keyboardLayout, KeyEvent.VK_3, 0x03DF);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD3, 0x03DF);

		addKey(keyboardLayout, KeyEvent.VK_E, 0x03EF);
		addKey(keyboardLayout, KeyEvent.VK_D, 0x03F7);
		addKey(keyboardLayout, KeyEvent.VK_C, 0x03FB);
		addKey(keyboardLayout, KeyEvent.VK_K, 0x03FD);

		addKey(keyboardLayout, KeyEvent.VK_9, 0x03FE);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD9, 0x03FE);
		// --------------------------------------------------------------------------------------------------------------------------

		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11111011
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A10 (#2) | +      DWN     4       R       F       V       J       O
		// Single key:
		addKey(keyboardLayout, KeyEvent.VK_PLUS, 0x027F);

		addKey(keyboardLayout, KeyEvent.VK_4, 0x02DF);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD4, 0x02DF);

		addKey(keyboardLayout, KeyEvent.VK_R, 0x02EF);
		addKey(keyboardLayout, KeyEvent.VK_F, 0x02F7);
		addKey(keyboardLayout, KeyEvent.VK_V, 0x02FB);
		addKey(keyboardLayout, KeyEvent.VK_J, 0x02FD);
		addKey(keyboardLayout, KeyEvent.VK_O, 0x02FE);
		// --------------------------------------------------------------------------------------------------------------------------

		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11111101
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A9  (#1) | /      UP      5       T       G       B       U       I
		// Single key:
		// '/' does not exist as a single key press, so we steel the '^' key next to 'Å' key.
		addKey(keyboardLayout, KeyEvent.VK_DEAD_DIAERESIS, 0x017F);

		addKey(keyboardLayout, KeyEvent.VK_5, 0x01DF);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD5, 0x01DF);

		addKey(keyboardLayout, KeyEvent.VK_T, 0x01EF);
		addKey(keyboardLayout, KeyEvent.VK_G, 0x01F7);
		addKey(keyboardLayout, KeyEvent.VK_B, 0x01FB);
		addKey(keyboardLayout, KeyEvent.VK_U, 0x01FD);
		addKey(keyboardLayout, KeyEvent.VK_I, 0x01FE);
		// --------------------------------------------------------------------------------------------------------------------------

		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11111110
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A8  (#0) | DEL    ENTER   6       Y       H       N       7       8
		// Single key:
		addKey(keyboardLayout, KeyEvent.VK_6, 0x00DF);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD6, 0x00DF);

		addKey(keyboardLayout, KeyEvent.VK_Y, 0x00EF);
		addKey(keyboardLayout, KeyEvent.VK_H, 0x00F7);
		addKey(keyboardLayout, KeyEvent.VK_N, 0x00FB);

		addKey(keyboardLayout, KeyEvent.VK_7, 0x00FD);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD7, 0x00FD);

		addKey(keyboardLayout, KeyEvent.VK_8, 0x00FE);
		addKey(keyboardLayout, KeyEvent.VK_NUMPAD8, 0x00FE);
		// --------------------------------------------------------------------------------------------------------------------------

		return keyboardLayout;
	}


	/**
	 * Scans Z88 hardware keyboard row(s), and returns the
	 * corresponding key column(s).<br>
	 *
	 * Typically, only a single row is scanned, eg. @10111111,
	 * but several columns might be polled for simultaneously,
	 * eg @00111111 (this example would catch left & right SHIFT's
	 * simultaneously).
	 *
	 * If the Z88 wanted to check for a key press in all rows,
	 * 0 would be specified.
	 *
	 * @param row, of Z88 keyboard to be scanned, eg @10111111
	 * @return keyColumn, the column containing one or several key presses.
	 */
	public int scanKeyRow(int row) {
		int columns = 0xFF; int mask = 1;

		for (int bit = 0; bit < 8; bit++) {
			if ((row & mask) == 0) columns &= keyRows[bit];
			mask <<= 1;
		}

		return columns;
	}

	/**
	 * Debug Command line interface.
	 * Press/release one or more keys programmatically.
	 *
	 */
	public void setKeyRow(int keyMatrixRow, int keyMask) {
		int mask = 1;

		for (int bit = 0; bit < 8; bit++) {
			if ((keyMatrixRow & mask) == 0) keyRows[bit] = keyMask;
			mask <<= 1;
		}		
	}
	
	/**
	 * Get a string representation of the current KBD matrix,
	 * each row on a 'separate' line (using a \n).
	 * 
	 * @return
	 */
	public String getKbdMatrix() {
		StringBuffer kbdRows = new StringBuffer(128);
		
		for(int r=0; r<8; r++) 
			kbdRows.append("A" + (15-r < 10 ? "0": "") + (15-r) + ": " + Dz.byteToBin(keyRows[7-r],false) + "\n");
		
		return kbdRows.toString();
	}
	
	/**
	 * Type a Z88 key into the Z88 hardware keyboard matrix.
	 */
	private void pressZ88key(KeyPress keyp) {
		int keyMatrixRow, keyMask;

		if (Z88.getInstance().getProcessorThread() != null) {
			// Only allow keypresses to be registered by Blink while Z80 engine is running...
			keyMatrixRow = (keyp.keyZ88Typed & 0xff00) >>> 8;
			keyMask = keyp.keyZ88Typed & 0xff;
			keyRows[keyMatrixRow] &= keyMask;
			
			Z88.getInstance().getBlink().signalKeyPressed();
		}
	}

	
	/**
	 * "Press" the Z88 key according to the hardware matrix.
	 * 
	 * @param keyMatrixRow
	 * @param keyMask
	 */
	public void pressZ88key(int keyMatrixRow, int keyMask) {
		if (Z88.getInstance().getProcessorThread() != null) {
			// Only allow keypresses to be registered by Blink while Z80 engine is running...
			keyRows[keyMatrixRow] &= keyMask;
			Z88.getInstance().getBlink().signalKeyPressed();
		}
	}

	
	/**
	 * "Release" the Z88 key according to the hardware matrix.
	 * 
	 * @param keyMatrixRow
	 * @param keyMask
	 */
	public void releaseZ88key(int keyMatrixRow, int keyMask) {
		if (Z88.getInstance().getProcessorThread() != null) {
			// Only allow key releases to be registered by Blink while Z80 engine is running...
			keyRows[keyMatrixRow] |= (~keyMask & 0xff);
			Z88.getInstance().getBlink().signalKeyPressed();
		}
	}

	
	/**
	 * Release a Z88 key from the Z88 hardware keyboard matrix.
	 */
	private void releaseZ88key(KeyPress keyp) {
		if (Z88.getInstance().getProcessorThread() != null) {
			// Only allow key releases to be registered by Blink while Z80 engine is running...
			keyRows[((keyp.keyZ88Typed & 0xff00) >>> 8)] |= (~(keyp.keyZ88Typed & 0xff) & 0xff);
		}
	}


	/**
	 * Set the Z88 keyboard layout to be used for mapping
	 * host keyboard events to Z88 keys. The following
	 * country codes are available:
	 * 
	 * The instance of the graphical representation (Rubberkeyboard)
	 * are also updated with the appropriate icons. 
	 *
	 * <PRE>
	 *	COUNTRY_US = 0;		// English/US Keyboard layout
	 *	COUNTRY_FR = 1;		// French Keyboard layout
	 *	COUNTRY_DE = 2;		// German Keyboard layout
	 *	COUNTRY_EN = 3;		// English/UK Keyboard layout
	 *	COUNTRY_DK = 4;		// Danish Keyboard layout
	 *	COUNTRY_SE = 5;		// Swedish Keyboard layout
	 *	COUNTRY_IT = 6;		// Italian Keyboard layout
	 *	COUNTRY_ES = 7;		// Spanish Keyboard layout
	 *	COUNTRY_JP = 8;		// Japanese Keyboard layout
	 *	COUNTRY_IS = 9;		// Icelandic Keyboard layout
	 *	COUNTRY_NO = 10;	// Norwegian Keyboard layout
	 *	COUNTRY_CH = 11;	// Swiss Keyboard layout 
	 * 	COUNTRY_TR = 12;	// Turkish Keyboard layout
	 *	COUNTRY_FI = 13;	// Finnish Keyboard layout
	 * </PRE>
	 *
	 * @param kbl the country code ID
	 */
	public void setKeyboardLayout(int kbl) {
		kbl %= z88Keyboards.length;

		currentKbLayoutCountryCode = kbl;
		currentKbLayout = z88Keyboards[kbl];
		getRubberKeyboard().setKeyboardCountrySpecificIcons(kbl);
	}

	/**
	 * Get a reference to Rubberkeyboard, which is the graphical
	 * representation of the Z88 keyboard (a JPanel)
	 * 
	 * The Rubberkeyboard is auto-loaded with the key caps (icons) of the
	 * current defined keyboard layout.
	 * 
	 * @return
	 */
	public RubberKeyboard getRubberKeyboard() {
		if (rubberKb == null)
			rubberKb = new RubberKeyboard(); // prepare the Gui keyboard
		return rubberKb;
	}
	
	/**
	 * Get the current Z88 keyboard layout Country code.<br>
	 * The following country codes are available:
	 *
	 * <PRE>
	 *	COUNTRY_US = 0;		// English/US Keyboard layout
	 *	COUNTRY_FR = 1;		// French Keyboard layout
	 *	COUNTRY_DE = 2;		// German Keyboard layout
	 *	COUNTRY_EN = 3;		// English/UK Keyboard layout
	 *	COUNTRY_DK = 4;		// Danish Keyboard layout
	 *	COUNTRY_SE = 5;		// Swedish Keyboard layout
	 *	COUNTRY_IT = 6;		// Italian Keyboard layout
	 *	COUNTRY_ES = 7;		// Spanish Keyboard layout
	 *	COUNTRY_JP = 8;		// Japanese Keyboard layout
	 *	COUNTRY_IS = 9;		// Icelandic Keyboard layout
	 *	COUNTRY_NO = 10;	// Norwegian Keyboard layout
	 *	COUNTRY_CH = 11;	// Swiss Keyboard layout 
	 * 	COUNTRY_TR = 12;	// Turkish Keyboard layout
	 *	COUNTRY_FI = 13;	// Finnish Keyboard layout
	 * </PRE>
	 *
	 * @param kbl the country code ID
	 */
	public int getKeyboardLayout() {
		return currentKbLayoutCountryCode;
	}

	/**
	 * Return the Z88 Key that represents the host key (event)
	 * Returns null if a Z88 Key wasn't mapped to the host keyboard event.
	 * 
	 * @param keyEvent
	 * @return
	 */
	public KeyPress getZ88Key(final int keyEvent) {
		searchKey.keyCode = keyEvent;
		KeyPress kp = (KeyPress) currentKbLayout.get(searchKey); 
		return kp;
	}
	
	/**
	 * This class is responsible for receiving java.awt.KeyEvent's from 
	 * the real world PC keyboard and redistribute that into the Z88 
	 * keyboard hardware that is polled by Z80 IN r,(B2h) instructions. 
	 * 
	 * Further, this class is executed in a separate Java Thread, avoiding
	 * being suspended when the virtual Z80 processor goes into snooze mode
	 * (simulated by a Thread.sleep() call).
	 */
	private class Z88KeyboardListener implements KeyListener {
		/**
		 * This event is fired whenever a key press is recognised on the java.awt.Canvas.
		 */
		public void keyPressed(KeyEvent e) {
			KeyPress kp = null;

			System.out.println("keyPressed() event: " + e.getKeyCode() + "('" + e.getKeyChar() + "' (" + (int) e.getKeyChar()+ ")," + e.getKeyLocation() + "," + (int) e.getModifiers() + ")");

			switch(e.getKeyCode()) {								
				case KeyEvent.VK_SHIFT:
					// check if left or right SHIFT were pressed
					if (e.getKeyLocation() == KeyEvent.KEY_LOCATION_LEFT) pressZ88key(z88LshKey);
					if (e.getKeyLocation() == KeyEvent.KEY_LOCATION_RIGHT) pressZ88key(z88RshKey);
					break;

				case KeyEvent.VK_F5:
					OZvm.getInstance().commandLine(true);
					Z88.getInstance().getProcessor().stopZ80Execution();						
					break;

				case KeyEvent.VK_F12:
					if (OZvm.getInstance().getDebugMode() == true) { 
						// Use F12 to toggle between debugger command input and Z88 kb input
						OZvm.getInstance().getCommandLine().getDebugGui().getCmdLineInputArea().grabFocus();	 
					}
					break;

				case KeyEvent.VK_CONTROL:
					pressZ88key(z88DiamondKey);		// CTRL executes single Z88 DIAMOND key
					break;

				case KeyEvent.VK_ALT:
					pressZ88key(z88SquareKey);		// ALT executes single Z88 SQUARE key
					break;
					
				case KeyEvent.VK_INSERT:
					pressZ88key(z88DiamondKey);
					pressZ88key(getZ88Key(KeyEvent.VK_V));	// INSERT executes Z88 DIAMOND V
					break;

				case KeyEvent.VK_DELETE:
					pressZ88key(z88RshKey);
					pressZ88key(z88DelKey);
					break;

				case KeyEvent.VK_HOME:
					pressZ88key(z88DiamondKey);
					pressZ88key(z88ArrowLeftKey);
					break;

				case KeyEvent.VK_END:
					pressZ88key(z88DiamondKey);
					pressZ88key(z88ArrowRightKey);
					break;

				case KeyEvent.VK_PAGE_UP:
					pressZ88key(z88RshKey);
					pressZ88key(z88ArrowUpKey);
					break;

				case KeyEvent.VK_PAGE_DOWN:
					pressZ88key(z88RshKey);
					pressZ88key(z88ArrowDownKey);
					break;

				case KeyEvent.VK_NUMPAD0:
				case KeyEvent.VK_NUMPAD1:
				case KeyEvent.VK_NUMPAD2:
				case KeyEvent.VK_NUMPAD3:
				case KeyEvent.VK_NUMPAD4:
				case KeyEvent.VK_NUMPAD5:
				case KeyEvent.VK_NUMPAD6:
				case KeyEvent.VK_NUMPAD7:
				case KeyEvent.VK_NUMPAD8:
				case KeyEvent.VK_NUMPAD9:
					if (currentKbLayout == z88Keyboards[Z88Keyboard.COUNTRY_FR]) {
						// those pesky french keyboards!!!
						pressZ88key(z88RshKey);
					}
					pressZ88key(getZ88Key(e.getKeyCode()));
					break;

				case 0:
					// Special characters
					kp = getZ88Key(0x10000 | (int) e.getKeyChar());
					if (kp != null) {
						pressZ88key(kp);
					}
					break;

				case KeyEvent.VK_6:
					if (currentKbLayout == z88Keyboards[COUNTRY_FR]) {
						if ( e.getModifiers() == 0 ) {
							// French PC '-' is mapped to Z88 -
							kp = getZ88Key(KeyEvent.VK_MINUS);
						}

						if ((e.getModifiers() == java.awt.Event.SHIFT_MASK) | (e.getModifiers() == java.awt.Event.CTRL_MASK)) {
							// French PC SHIFT - is mapped to Z88 SHIFT § which gives an 6.
							kp = getZ88Key(KeyEvent.VK_6);
						}
						
						if (e.getModifiers() == (java.awt.Event.CTRL_MASK + java.awt.Event.ALT_MASK)) {
							// PC [ALT Gr '6'] = '|' converts to Z88 <>' = |
							releaseZ88key(z88SquareKey); // only DIAMOND (is already) pressed...
							kp = getZ88Key(KeyEvent.VK_4);
						}
					} else {
						kp = getZ88Key(e.getKeyCode());	
					}
					if (kp != null) {
						pressZ88key(kp);
					}									
					break;
					
				case KeyEvent.VK_8:
					if (currentKbLayout == z88Keyboards[COUNTRY_FR]) {
						if ( e.getModifiers() == 0 ) {
							// French PC '_' is mapped to Z88 SHIFT-
							pressZ88key(z88RshKey);
							kp = getZ88Key(KeyEvent.VK_MINUS);
						}

						if ((e.getModifiers() == java.awt.Event.SHIFT_MASK) | (e.getModifiers() == java.awt.Event.CTRL_MASK)) {
							// French PC SHIFT _ is mapped to Z88 SHIFT ! which gives an 8.
							kp = getZ88Key(KeyEvent.VK_EXCLAMATION_MARK);
						}
						
						if (e.getModifiers() == (java.awt.Event.CTRL_MASK + java.awt.Event.ALT_MASK)) {
							// PC [ALT Gr '8'] = '\' converts to Z88 <>& = \
							releaseZ88key(z88SquareKey); // only DIAMOND (is already) pressed...
							kp = getZ88Key(KeyEvent.VK_1);
						}
					} else {
						kp = getZ88Key(e.getKeyCode());	
					}
					if (kp != null) {
						pressZ88key(kp);
					}									
					break;
					
				case KeyEvent.VK_EXCLAMATION_MARK:
					if (currentKbLayout == z88Keyboards[COUNTRY_FR]) {
						if ((e.getModifiers() == java.awt.Event.SHIFT_MASK)) {
							// French PC SHIFT ! is mapped to Z88 single key § (6).
							releaseZ88key(z88RshKey); // SHIFT (is already) pressed...
							kp = getZ88Key(KeyEvent.VK_6);
						} else {
							kp = getZ88Key(e.getKeyCode());
						}
					} else {
						kp = getZ88Key(e.getKeyCode());	
					}				
					if (kp != null) {
						pressZ88key(kp);
					}									
					break;

				case KeyEvent.VK_ADD:
					if (currentKbLayout == z88Keyboards[COUNTRY_FR]) {
						pressZ88key(z88RshKey);
						kp = getZ88Key(KeyEvent.VK_EQUALS);
					}
					if (kp != null) {
						pressZ88key(kp);
					}
					break;
					
				case KeyEvent.VK_SUBTRACT:
					// Numerical Keyboard, '-' key
					if (currentKbLayout == z88Keyboards[COUNTRY_FR]) {
						kp = getZ88Key(KeyEvent.VK_MINUS);
					}
					if (kp != null) {
						pressZ88key(kp);
					}
					break;
					
				case KeyEvent.VK_MULTIPLY:
					// Numerical Keyboard, '*' key
					if (currentKbLayout == z88Keyboards[COUNTRY_FR]) {
						kp = getZ88Key(KeyEvent.VK_ASTERISK);
					}
					if (kp != null) {
						pressZ88key(kp);
					}
					break;

				case KeyEvent.VK_DIVIDE:
					// Numerical Keyboard, '/' key
					if (currentKbLayout == z88Keyboards[COUNTRY_FR]) {
						pressZ88key(z88RshKey);
						kp = getZ88Key(KeyEvent.VK_COLON);
					}
					if (kp != null) {
						pressZ88key(kp);
					}
					break;
					
				case KeyEvent.VK_DECIMAL:
					// Numerical Keyboard, '.' key
					if (currentKbLayout == z88Keyboards[COUNTRY_FR]) {
						pressZ88key(z88RshKey);
						kp = getZ88Key(KeyEvent.VK_SEMICOLON);
					}
					if (kp != null) {
						pressZ88key(kp);
					}
					break;

				// The single letter key press '#' is possible on UK PC keyboards...
				case KeyEvent.VK_NUMBER_SIGN:
					if (e.getKeyChar() == '#') {
						pressZ88key(z88RshKey);
						pressZ88key(getZ88Key(KeyEvent.VK_3));
					}
					if (e.getKeyChar() == '~') {
						pressZ88key(z88RshKey);
						pressZ88key(getZ88Key('£'));
					}
					break;
									
				case KeyEvent.VK_QUOTE:
					if (e.getKeyChar() == '\'') {
						pressZ88key(getZ88Key(KeyEvent.VK_QUOTE));
					}
					if (e.getKeyChar() == '@') {
						// PC UK keyboard has pressed SHIFT (so shift already pressed on Z88)
						pressZ88key(getZ88Key(KeyEvent.VK_2));
					}
					if (e.getKeyChar() == '*') {
						// PC DK keyboard has released SHIFT (so shift already released on Z88)
						pressZ88key(getZ88Key(KeyEvent.VK_8));
					}								
					break;
					
				default:
					// All other keypresses are available in keyboard map layout			
					
					// Nightmare begins with ALT GRAPHIC PC key combinations that are mapped into the right z88 keyboard location...
					if (e.getModifiers() == (java.awt.Event.CTRL_MASK + java.awt.Event.ALT_MASK)) {
						// ALT GR pressed down...
						
						if (currentKbLayout == z88Keyboards[COUNTRY_FR]) {
							switch(e.getKeyCode()) {
								case KeyEvent.VK_2:  // PC [ALT Gr '2'] = '~' converts to Z88 <>( = ~
									releaseZ88key(z88SquareKey); // only DIAMOND (is already) pressed...
									kp = getZ88Key(KeyEvent.VK_5);
									break;
								case KeyEvent.VK_3:  // PC [ALT Gr '3'] = '#' converts to Z88 <>" = #
									releaseZ88key(z88SquareKey); // only DIAMOND (is already) pressed...
									kp = getZ88Key(KeyEvent.VK_3);
									break;
								case KeyEvent.VK_4:  // PC [ALT Gr '4'] = '{' converts to Z88 <>è = {
									releaseZ88key(z88SquareKey); // only DIAMOND (is already) pressed...
									kp = getZ88Key(KeyEvent.VK_7);
									break;
								case KeyEvent.VK_5:  // PC [ALT Gr '5'] = '[' converts to Z88 <>ç = [
									releaseZ88key(z88SquareKey); // only DIAMOND (is already) pressed...
									kp = getZ88Key(KeyEvent.VK_9);
									break;
								case KeyEvent.VK_7:  // PC [ALT Gr '7'] = '`' converts to Z88 <>) = `
									releaseZ88key(z88SquareKey); // only DIAMOND (is already) pressed...
									kp = getZ88Key(KeyEvent.VK_RIGHT_PARENTHESIS);
									break;
								case KeyEvent.VK_9:  // PC [ALT Gr '9'] = '^' converts to Z88 <>§ = ^
									releaseZ88key(z88SquareKey); // only DIAMOND (is already) pressed...
									kp = getZ88Key(KeyEvent.VK_6);
									break;
								case KeyEvent.VK_0:  // PC [ALT Gr '0'] = '@' converts to Z88 <>é = @
									releaseZ88key(z88SquareKey); // only DIAMOND (is already) pressed...
									kp = getZ88Key(KeyEvent.VK_2);
									break;
								case KeyEvent.VK_RIGHT_PARENTHESIS:  // PC [ALT Gr ')'] = ']' converts to Z88 <>à = ]
									releaseZ88key(z88SquareKey); // only DIAMOND (is already) pressed...
									kp = getZ88Key(KeyEvent.VK_0);
									break;
								case KeyEvent.VK_EQUALS:  // PC [ALT Gr '='] = '}' converts to Z88 <>! = }
									releaseZ88key(z88SquareKey); // only DIAMOND (is already) pressed...
									kp = getZ88Key(KeyEvent.VK_EXCLAMATION_MARK);
									break;
							}
						}						
					} else {
						if (e.getKeyChar() == '£' & currentKbLayout == z88Keyboards[COUNTRY_UK]) {
							releaseZ88key(z88RshKey);
							kp = getZ88Key('£');
						} else if(e.getKeyChar() == '"') {
							// for PC UK/DK/SE, SHIFT has been pressed on 2
							kp = getZ88Key(KeyEvent.VK_QUOTE);
						} else
							kp = getZ88Key(e.getKeyCode());						
					}
					
					if (kp != null) {
						pressZ88key(kp);
					}
					break;
			}
		}


		/**
		 * This event is fired whenever a key is released on the java.awt.canvas.
		 */
		public void keyReleased(KeyEvent e) {
			KeyPress kp = null;

			System.out.println("keyReleased() event: " + e.getKeyCode() + "('" + e.getKeyChar() + "' (" + (int) e.getKeyChar()+ ")," + e.getKeyLocation() + "," + (int) e.getModifiers() + ")");

			switch(e.getKeyCode()) {			
				case KeyEvent.VK_SHIFT:
					// BUG in JVM on Windows:
					// always release both SHIFT's on Z88, since this event doesn't 
					// always properly signal left or right SHIFT releases in JVM. 
					releaseZ88key(z88LshKey);
					releaseZ88key(z88RshKey);
					break;

				case KeyEvent.VK_CONTROL:
					releaseZ88key(z88DiamondKey);		// CTRL executes single Z88 DIAMOND key
					break;

				case KeyEvent.VK_ALT:
					releaseZ88key(z88SquareKey);		// ALT executes single Z88 SQUARE key
					break;

				case KeyEvent.VK_DELETE:
					releaseZ88key(z88DelKey);
					releaseZ88key(z88RshKey);
					break;

				case KeyEvent.VK_INSERT:
					releaseZ88key(getZ88Key(KeyEvent.VK_V));
					releaseZ88key(z88DiamondKey);		// INSERT executes Z88 DIAMOND V
					break;

				case KeyEvent.VK_NUMPAD0:
				case KeyEvent.VK_NUMPAD1:
				case KeyEvent.VK_NUMPAD2:
				case KeyEvent.VK_NUMPAD3:
				case KeyEvent.VK_NUMPAD4:
				case KeyEvent.VK_NUMPAD5:
				case KeyEvent.VK_NUMPAD6:
				case KeyEvent.VK_NUMPAD7:
				case KeyEvent.VK_NUMPAD8:
				case KeyEvent.VK_NUMPAD9:
					kp = getZ88Key(e.getKeyCode());
					releaseZ88key(kp);
					if (currentKbLayout == z88Keyboards[Z88Keyboard.COUNTRY_FR]) {
						// those pesky french keyboards!!!
						releaseZ88key(z88RshKey);
					}
					break;

				case KeyEvent.VK_HOME:
					releaseZ88key(z88ArrowLeftKey);
					releaseZ88key(z88DiamondKey);
					break;

				case KeyEvent.VK_END:
					releaseZ88key(z88ArrowRightKey);
					releaseZ88key(z88DiamondKey);
					break;

				case KeyEvent.VK_PAGE_UP:
					releaseZ88key(z88ArrowUpKey);
					releaseZ88key(z88RshKey);
					break;

				case KeyEvent.VK_PAGE_DOWN:
					releaseZ88key(z88ArrowDownKey);
					releaseZ88key(z88RshKey);
					break;

				case 0:
					// Special characters
					kp = getZ88Key(0x10000 | (int) e.getKeyChar());
					if (kp != null) {
						releaseZ88key(kp);
					}
					break;

				case KeyEvent.VK_6:
					if (currentKbLayout == z88Keyboards[COUNTRY_FR]) {
						if ( e.getModifiers() == 0 ) {
							// French PC '-' is mapped to Z88 -
							kp = getZ88Key(KeyEvent.VK_MINUS);
						}

						if ((e.getModifiers() == java.awt.Event.SHIFT_MASK) | (e.getModifiers() == java.awt.Event.CTRL_MASK)) {
							// French PC SHIFT - is mapped to Z88 SHIFT § which gives an 6.
							kp = getZ88Key(KeyEvent.VK_6);
						}
						
						if (e.getModifiers() == (java.awt.Event.CTRL_MASK + java.awt.Event.ALT_MASK)) {
							// PC [ALT Gr '6'] = '|' converts to Z88 <>' = |
							kp = getZ88Key(KeyEvent.VK_4);
						}
					} else {
						kp = getZ88Key(e.getKeyCode());
					}
					if (kp != null) {
						releaseZ88key(kp);
					}									
					break;
					
				case KeyEvent.VK_8:
					if (currentKbLayout == z88Keyboards[COUNTRY_FR]) {
						if ( e.getModifiers() == 0 ) {
							// French PC '_' is mapped to Z88 SHIFT-
							releaseZ88key(z88RshKey);
							kp = getZ88Key(KeyEvent.VK_MINUS);
						}

						if ((e.getModifiers() == java.awt.Event.SHIFT_MASK) | (e.getModifiers() == java.awt.Event.CTRL_MASK)) {
							// French PC SHIFT _ is mapped to Z88 SHIFT ! which gives an 8.
							kp = getZ88Key(KeyEvent.VK_EXCLAMATION_MARK);
						}

						if (e.getModifiers() == (java.awt.Event.CTRL_MASK + java.awt.Event.ALT_MASK)) {
							// PC [ALT Gr '8'] = '\' converts to Z88 <>& = \
							kp = getZ88Key(KeyEvent.VK_1);
						}
					} else {
						kp = getZ88Key(e.getKeyCode());
					}
					
					if (kp != null) {
						releaseZ88key(kp);
					}									
					break;

				case KeyEvent.VK_EXCLAMATION_MARK:
					if (currentKbLayout == z88Keyboards[COUNTRY_FR]) {
						if ((e.getModifiers() == java.awt.Event.SHIFT_MASK)) {
							// French PC SHIFT ! is mapped to Z88 single key § (6).
							kp = getZ88Key(KeyEvent.VK_6);
						} else {
							kp = getZ88Key(e.getKeyCode());
						}
					} else {
						kp = getZ88Key(e.getKeyCode());
					}				
					if (kp != null) {
						releaseZ88key(kp);
					}									
					break;

				case KeyEvent.VK_ADD:
					// Numerical Keyboard, '+' key
					if (currentKbLayout == z88Keyboards[COUNTRY_FR]) {
						releaseZ88key(z88RshKey);
						kp = getZ88Key(KeyEvent.VK_EQUALS);
					}
					if (kp != null) {
						releaseZ88key(kp);
					}
					break;

				case KeyEvent.VK_SUBTRACT:
					// Numerical Keyboard, '-' key
					if (currentKbLayout == z88Keyboards[COUNTRY_FR]) {
						kp = getZ88Key(KeyEvent.VK_MINUS);
					}
					if (kp != null) {
						releaseZ88key(kp);
					}
					break;
					
				case KeyEvent.VK_MULTIPLY:
					// Numerical Keyboard, '*' key
					if (currentKbLayout == z88Keyboards[COUNTRY_FR]) {
						kp = getZ88Key(KeyEvent.VK_ASTERISK);
					}
					if (kp != null) {
						releaseZ88key(kp);
					}
					break;

				case KeyEvent.VK_DIVIDE:
					// Numerical Keyboard, '/' key
					if (currentKbLayout == z88Keyboards[COUNTRY_FR]) {
						releaseZ88key(z88RshKey);
						kp = getZ88Key(KeyEvent.VK_COLON);
					}
					if (kp != null) {
						releaseZ88key(kp);
					}
					break;

				case KeyEvent.VK_DECIMAL:
					// Numerical Keyboard, '.' key
					if (currentKbLayout == z88Keyboards[COUNTRY_FR]) {
						releaseZ88key(z88RshKey);
						kp = getZ88Key(KeyEvent.VK_SEMICOLON);
					}
					if (kp != null) {
						releaseZ88key(kp);
					}
					break;
					
				case KeyEvent.VK_NUMBER_SIGN:
					if (e.getKeyChar() == '#') {
						releaseZ88key(z88RshKey);
						releaseZ88key(getZ88Key(KeyEvent.VK_3));
					}
					if (e.getKeyChar() == '~') {
						releaseZ88key(z88RshKey);
						releaseZ88key(getZ88Key('£'));
					}
					break;

				case KeyEvent.VK_QUOTE:
					if (e.getKeyChar() == '\'') {
						releaseZ88key(getZ88Key(KeyEvent.VK_QUOTE));
					}
					if (e.getKeyChar() == '@') {
						// PC UK keyboard has released SHIFT (so shift already released on Z88)
						releaseZ88key(getZ88Key(KeyEvent.VK_2));
					}			
					if (e.getKeyChar() == '*') {
						// PC DK keyboard has released SHIFT (so shift already released on Z88)
						releaseZ88key(getZ88Key(KeyEvent.VK_8));
					}			
					break;

				default:
					// All other key releases are available in keyboard map layout

					// Nightmare begins with ALT GRAPHIC PC key combinations that are mapped into the right z88 keyboard location...
					if (e.getModifiers() == (java.awt.Event.CTRL_MASK + java.awt.Event.ALT_MASK)) {
						// ALT GR pressed down...
						
						if (currentKbLayout == z88Keyboards[COUNTRY_FR]) {
							switch(e.getKeyCode()) {
								case KeyEvent.VK_2:  // PC [ALT Gr '2'] = '~' converts to Z88 <>( = ~
									kp = getZ88Key(KeyEvent.VK_5);
								    break;
								case KeyEvent.VK_3:  // PC [ALT Gr '3'] = '#' converts to Z88 <>" = #
									kp = getZ88Key(KeyEvent.VK_3);
									break;
								case KeyEvent.VK_4:  // PC [ALT Gr '4'] = '{' converts to Z88 <>è = {
									kp = getZ88Key(KeyEvent.VK_7);
								    break;
								case KeyEvent.VK_5:  // PC [ALT Gr '5'] = '[' converts to Z88 <>ç = [
									kp = getZ88Key(KeyEvent.VK_9);
									break;							    
								case KeyEvent.VK_7:  // PC [ALT Gr '7'] = '`' converts to Z88 <>) = `
									kp = getZ88Key(KeyEvent.VK_RIGHT_PARENTHESIS);									
									break;
								case KeyEvent.VK_9:  // PC [ALT Gr '9'] = '^' converts to Z88 <>§ = ^
									kp = getZ88Key(KeyEvent.VK_6);
									break;
								case KeyEvent.VK_0:  // PC [ALT Gr '0'] = '@' converts to Z88 <>é = @
									kp = getZ88Key(KeyEvent.VK_2);
									break;
								case KeyEvent.VK_RIGHT_PARENTHESIS:  // PC [ALT Gr ')'] = ']' converts to Z88 <>à = ]
									kp = getZ88Key(KeyEvent.VK_0);
									break;
								case KeyEvent.VK_EQUALS:  // PC [ALT Gr '='] = '}' converts to Z88 <>! = }
									kp = getZ88Key(KeyEvent.VK_EXCLAMATION_MARK);
									break;
							}
						}
					} else {
						if (e.getKeyChar() == '£' & currentKbLayout == z88Keyboards[COUNTRY_UK]) {
							kp = getZ88Key('£');
						} else if(e.getKeyChar() == '"') {
							// for PC UK/DK, SHIFT has been released on 2
							kp = getZ88Key(KeyEvent.VK_QUOTE);
						} else
							kp = getZ88Key(e.getKeyCode());
					}
				
					if (kp != null) {
						releaseZ88key(kp);
					}
					break;
			}
		}

		public void keyTyped(KeyEvent e) {
			// System.out.println("keyTyped() event: " + e.getKeyCode() + "('" + e.getKeyChar() + "' (" + (int) e.getKeyChar()+ ")," + e.getKeyLocation() + "," + (int) e.getModifiers() + ")");
			
			if (e.getKeyCode() == 0) {
				// use this event for missing keypresses on Linux.. 
				KeyPress kp = getZ88Key(0x10000 | (int) e.getKeyChar());
				if (kp != null) {
					pressZ88key(kp);
				}
			}			
		}		
	}
}
