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

import net.sourceforge.z88.screen.Z88display;


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
	public static final int COUNTRY_EN = 3;
	
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

	private Z88display z88Display = null;

	private RubberKeyboard rubberKb;
	
	/** Current Keyboard layout Country Code (default = COUNTRY_EN during boot of OZvm) */ 
    private int currentKbLayoutCountryCode = COUNTRY_EN;

    private Map currentKbLayout = null;
    private Map[] z88Keyboards = null;			// country specific keyboard layouts
    
	private int keyRows[] = new int[8];			// Z88 Hardware Keyboard (8x8) Matrix
	private KeyPress z88RshKey = null;			// Right Shift Key
	private KeyPress z88LshKey = null;			// Left Shift Key

	private KeyPress z88DiamondKey = null;
	private KeyPress z88SquareKey = null;
	private KeyPress z88TabKey = null;
	private KeyPress z88DelKey = null;
	private KeyPress z88EnterKey = null;
	private KeyPress z88ArrowLeftKey = null;
	private KeyPress z88ArrowRightKey = null;
	private KeyPress z88ArrowUpKey = null;
	private KeyPress z88ArrowDownKey = null;
	private KeyPress z88CapslockKey = null;
	private KeyPress z88EscKey = null;
	private KeyPress z88IndexKey = null;
	private KeyPress z88HelpKey = null;
	private KeyPress z88MenuKey = null;
	private KeyPress z88SpaceKey = null;

	private static final class singletonContainer {
		static final Z88Keyboard singleton = new Z88Keyboard();  
	}
	
	public static Z88Keyboard getInstance() {
		return singletonContainer.singleton;
	}
	
	// The Key.
	private class KeyPress {
		private int keyCode;		// The unique host 'key' for this entity, typically a SWT.xxx constant
		private int keyZ88Typed;	// The Z88 Keyboard Matrix Entry for single typed key, eg. "A"
		private int keyZ88Modifier;	// The Z88 Keyboard Matrix Entry for Z88 modifier key, eg. SHIFT OR DIAMOND

		public KeyPress(int kcd, int keyTyped) {
			keyCode = kcd;			// the KeyEvent.* definition host keyboard constants
			keyZ88Typed = keyTyped;
		}
	}


    /**
     * Create the instance to bind the blink and Swing widget together.
     *
     */
	private Z88Keyboard() {
		rubberKb = new RubberKeyboard(); // prepare the Gui keyboard
		
		z88Display = Z88display.getInstance();

		for(int r=0; r<8;r++) keyRows[r] = 0xFF;	// Initialize to no keys pressed in z88 key matrix

		z88Keyboards = new Map[13];					// create the container for the various country keyboard layouts.
		createSystemKeys();
		createKbLayouts();
		
		// use default UK keyboard layout for default UK V4 ROM.
		currentKbLayout = z88Keyboards[currentKbLayoutCountryCode];

		Thread thread = new Thread() {
			public void run() {
				Z88KeyboardListener z88Kbl = new Z88KeyboardListener(); 
				
				// map Host keyboard events to this z88 keyboard, so that the emulator responds to keypresses.
				z88Display.setFocusTraversalKeysEnabled(false);	// get TAB key events on canvas
				z88Display.addKeyListener(z88Kbl); // keyboard events are processed in isolated Thread..				
			}
		};

		thread.setPriority(Thread.NORM_PRIORITY);
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
		keyboardLayout.put(new Integer(KeyEvent.VK_TAB), (KeyPress) z88TabKey);

		// DEL = Back Space, row 0 (0xFE), column 7 (0x7F, 01111111)
		keyboardLayout.put(new Integer(KeyEvent.VK_BACK_SPACE), (KeyPress) z88DelKey);

		// ENTER, row 0 (0xFE), column 6 (0xBF, 10111111)
		keyboardLayout.put(new Integer(KeyEvent.VK_ENTER), (KeyPress) z88EnterKey);

		// ARROW LEFT, row 4 (0xEF), column 6 (0xBF, 10111111)
		keyboardLayout.put(new Integer(KeyEvent.VK_LEFT), (KeyPress) z88ArrowLeftKey);
		keyboardLayout.put(new Integer(KeyEvent.VK_KP_LEFT), (KeyPress) z88ArrowLeftKey);

		// ARROW RIGHT, row 3 (0xF7), column 6 (0xBF, 10111111)
		keyboardLayout.put(new Integer(KeyEvent.VK_RIGHT), (KeyPress) z88ArrowRightKey);
		keyboardLayout.put(new Integer(KeyEvent.VK_KP_RIGHT), (KeyPress) z88ArrowRightKey);

		// ARROW DOWN, row 2 (0xFB), column 6 (0xBF, 10111111)
		keyboardLayout.put(new Integer(KeyEvent.VK_DOWN), (KeyPress) z88ArrowDownKey);
		keyboardLayout.put(new Integer(KeyEvent.VK_KP_DOWN), (KeyPress) z88ArrowDownKey);

		// ARROW UP, row 1 (0xFD), column 6 (0xBF, 10111111)
		keyboardLayout.put(new Integer(KeyEvent.VK_UP), (KeyPress) z88ArrowUpKey);
		keyboardLayout.put(new Integer(KeyEvent.VK_KP_UP), (KeyPress) z88ArrowUpKey);

		// CAPS LOCK = CAPS, row 7 (0x7F), column 3 (0xF7, 11110111)
		keyboardLayout.put(new Integer(KeyEvent.VK_CAPS_LOCK), (KeyPress) z88CapslockKey);

		// ESC = ESC, row 7 (0x7F), column 5 (0xDF, 11011111)
		keyboardLayout.put(new Integer(KeyEvent.VK_ESCAPE), (KeyPress) z88EscKey);

		// HELP = F1, row 6 (0xBF), column 7 (0x7F, 01111111)
		keyboardLayout.put(new Integer(KeyEvent.VK_F1), (KeyPress) z88HelpKey);

		// INDEX = F2, row 7 (0x7F), column 4 (0xEF, 11101111)
		keyboardLayout.put(new Integer(KeyEvent.VK_F2), (KeyPress) z88IndexKey);

		// MENU = F3, row 6 (0xBF), column 3 (0xF7, 11110111)
		keyboardLayout.put(new Integer(KeyEvent.VK_F3), (KeyPress) z88MenuKey);

		// SPACE, row 5 (0xEF), column 6 (0xBF, 10111111)
		keyboardLayout.put(new Integer(KeyEvent.VK_SPACE), (KeyPress) z88SpaceKey);
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
		Map keyboardLayout;
		KeyPress keyp;

		keyboardLayout = new HashMap();
		mapSystemKeys(keyboardLayout);

		// --------------------------------------------------------------------------------------------------------------------------
		// Row 01111111:
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A15 (#7) | RSH    SQR     ESC     INDEX   CAPS    .       /       £
		// Single key:
		keyp = new KeyPress(KeyEvent.VK_PERIOD, 0x07FB); keyboardLayout.put(new Integer(KeyEvent.VK_PERIOD), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_SLASH, 0x07FD); keyboardLayout.put(new Integer(KeyEvent.VK_SLASH), (KeyPress) keyp);

		// The '£' key is not available as a single letter on UK Internatial PC keyboards
		// Therefore we use the '#' key (the same position on the host UK keyboard layout as on the Z88 keyboard)
		keyp = new KeyPress(KeyEvent.VK_NUMBER_SIGN, 0x07FE); keyboardLayout.put(new Integer(KeyEvent.VK_NUMBER_SIGN), (KeyPress) keyp);
		// --------------------------------------------------------------------------------------------------------------------------


		// --------------------------------------------------------------------------------------------------------------------------
		// Row 10111111
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A14 (#6) | HELP   LSH     TAB     DIA     MENU    ,       ;       '
		// Single key:
		keyp = new KeyPress(KeyEvent.VK_COMMA, 0x06FB); keyboardLayout.put(new Integer(KeyEvent.VK_COMMA), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_SEMICOLON, 0x06FD); keyboardLayout.put(new Integer(KeyEvent.VK_SEMICOLON), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_QUOTE, 0x06FE); keyboardLayout.put(new Integer(KeyEvent.VK_QUOTE), (KeyPress) keyp);
		// --------------------------------------------------------------------------------------------------------------------------


		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11011111
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A13 (#5) | [      SPACE   1       Q       A       Z       L       0
		// Single key:
		keyp = new KeyPress(KeyEvent.VK_OPEN_BRACKET, 0x057F); keyboardLayout.put(new Integer(KeyEvent.VK_OPEN_BRACKET), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_1, 0x05DF); keyboardLayout.put(new Integer(KeyEvent.VK_1), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD1, 0x05DF); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD1), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_Q, 0x05EF); keyboardLayout.put(new Integer(KeyEvent.VK_Q), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_A, 0x05F7); keyboardLayout.put(new Integer(KeyEvent.VK_A), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_Z, 0x05FB); keyboardLayout.put(new Integer(KeyEvent.VK_Z), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_L, 0x05FD); keyboardLayout.put(new Integer(KeyEvent.VK_L), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_0, 0x05FE); keyboardLayout.put(new Integer(KeyEvent.VK_0), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD0, 0x05FE); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD0), (KeyPress) keyp);
		// --------------------------------------------------------------------------------------------------------------------------


		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11101111
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A12 (#4) | ]      LFT     2       W       S       X       M       P
		// Single key:
		keyp = new KeyPress(KeyEvent.VK_CLOSE_BRACKET, 0x047F); keyboardLayout.put(new Integer(KeyEvent.VK_CLOSE_BRACKET), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_2, 0x04DF); keyboardLayout.put(new Integer(KeyEvent.VK_2), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD2, 0x04DF); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD2), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_W, 0x04EF); keyboardLayout.put(new Integer(KeyEvent.VK_W), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_S, 0x04F7); keyboardLayout.put(new Integer(KeyEvent.VK_S), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_X, 0x04FB); keyboardLayout.put(new Integer(KeyEvent.VK_X), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_M, 0x04FD); keyboardLayout.put(new Integer(KeyEvent.VK_M), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_P, 0x04FE); keyboardLayout.put(new Integer(KeyEvent.VK_P), (KeyPress) keyp);
		// --------------------------------------------------------------------------------------------------------------------------


		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11110111
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A11 (#3) | -      RGT     3       E       D       C       K       9
		// Single key:
		keyp = new KeyPress(KeyEvent.VK_MINUS, 0x037F); keyboardLayout.put(new Integer(KeyEvent.VK_MINUS), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_3, 0x03DF); keyboardLayout.put(new Integer(KeyEvent.VK_3), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD3, 0x03DF); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD3), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_E, 0x03EF); keyboardLayout.put(new Integer(KeyEvent.VK_E), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_D, 0x03F7); keyboardLayout.put(new Integer(KeyEvent.VK_D), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_C, 0x03FB); keyboardLayout.put(new Integer(KeyEvent.VK_C), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_K, 0x03FD); keyboardLayout.put(new Integer(KeyEvent.VK_K), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_9, 0x03FE); keyboardLayout.put(new Integer(KeyEvent.VK_9), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD9, 0x03FE); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD9), (KeyPress) keyp);
		// --------------------------------------------------------------------------------------------------------------------------


		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11111011
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A10 (#2) | =      DWN     4       R       F       V       J       O
		// Single key:
		keyp = new KeyPress(KeyEvent.VK_EQUALS, 0x027F); keyboardLayout.put(new Integer(KeyEvent.VK_EQUALS), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_4, 0x02DF); keyboardLayout.put(new Integer(KeyEvent.VK_4), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD4, 0x02DF); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD4), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_R, 0x02EF); keyboardLayout.put(new Integer(KeyEvent.VK_R), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_F, 0x02F7); keyboardLayout.put(new Integer(KeyEvent.VK_F), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_V, 0x02FB); keyboardLayout.put(new Integer(KeyEvent.VK_V), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_J, 0x02FD); keyboardLayout.put(new Integer(KeyEvent.VK_J), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_O, 0x02FE); keyboardLayout.put(new Integer(KeyEvent.VK_O), (KeyPress) keyp);
		// --------------------------------------------------------------------------------------------------------------------------


		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11111101
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A9  (#1) | \      UP      5       T       G       B       U       I
		// Single key:
		keyp = new KeyPress(KeyEvent.VK_BACK_SLASH, 0x017F); keyboardLayout.put(new Integer(KeyEvent.VK_BACK_SLASH), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_5, 0x01DF); keyboardLayout.put(new Integer(KeyEvent.VK_5), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD5, 0x01DF); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD5), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_T, 0x01EF); keyboardLayout.put(new Integer(KeyEvent.VK_T), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_G, 0x01F7); keyboardLayout.put(new Integer(KeyEvent.VK_G), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_B, 0x01FB); keyboardLayout.put(new Integer(KeyEvent.VK_B), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_U, 0x01FD); keyboardLayout.put(new Integer(KeyEvent.VK_U), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_I, 0x01FE); keyboardLayout.put(new Integer(KeyEvent.VK_I), (KeyPress) keyp);
		// --------------------------------------------------------------------------------------------------------------------------


		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11111110
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A8  (#0) | DEL    ENTER   6       Y       H       N       7       8
		// Single key:
		keyp = new KeyPress(KeyEvent.VK_6, 0x00DF); keyboardLayout.put(new Integer(KeyEvent.VK_6), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD6, 0x00DF); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD6), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_Y, 0x00EF); keyboardLayout.put(new Integer(KeyEvent.VK_Y), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_H, 0x00F7); keyboardLayout.put(new Integer(KeyEvent.VK_H), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_N, 0x00FB); keyboardLayout.put(new Integer(KeyEvent.VK_N), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_7, 0x00FD); keyboardLayout.put(new Integer(KeyEvent.VK_7), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD7, 0x00FD); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD7), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_8, 0x00FE); keyboardLayout.put(new Integer(KeyEvent.VK_8), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD8, 0x00FE); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD8), (KeyPress) keyp);
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
		Map keyboardLayout;
		KeyPress keyp;

		keyboardLayout = new HashMap();
		mapSystemKeys(keyboardLayout);

		// --------------------------------------------------------------------------------------------------------------------------
		// Row 01111111:
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A15 (#7) | RSH    SQR     ESC     INDEX   CAPS    :       $       ^
		// Single key:
		keyp = new KeyPress(KeyEvent.VK_COLON, 0x07FB); keyboardLayout.put(new Integer(KeyEvent.VK_COLON), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_DOLLAR, 0x07FD); keyboardLayout.put(new Integer(KeyEvent.VK_DOLLAR), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_DEAD_CIRCUMFLEX, 0x07FE); keyboardLayout.put(new Integer(KeyEvent.VK_DEAD_CIRCUMFLEX), (KeyPress) keyp);
		// --------------------------------------------------------------------------------------------------------------------------


		// --------------------------------------------------------------------------------------------------------------------------
		// Row 10111111
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A14 (#6) | HELP   LSH     TAB     DIA     MENU    ;       M       ù
		// Single key:
		keyp = new KeyPress(KeyEvent.VK_SEMICOLON, 0x06FB); keyboardLayout.put(new Integer(KeyEvent.VK_SEMICOLON), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_M, 0x06FD); keyboardLayout.put(new Integer(KeyEvent.VK_M), (KeyPress) keyp);
		keyp = new KeyPress((0x10000 | 'ù'), 0x06FE); keyboardLayout.put(new Integer((0x10000 | 'ù')), (KeyPress) keyp);
		keyp = new KeyPress((0x10000 | '%'), 0x06FE); keyboardLayout.put(new Integer((0x10000 | '%')), (KeyPress) keyp); // SHIFT 'ù' = '%'
		// --------------------------------------------------------------------------------------------------------------------------


		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11011111
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A13 (#5) | *      SPACE   &       A       Q       W       L       à
		// Single key:
		keyp = new KeyPress(KeyEvent.VK_ASTERISK, 0x057F); keyboardLayout.put(new Integer(KeyEvent.VK_ASTERISK), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_1, 0x05DF); keyboardLayout.put(new Integer(KeyEvent.VK_1), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD1, 0x05DF); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD1), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_A, 0x05EF); keyboardLayout.put(new Integer(KeyEvent.VK_A), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_Q, 0x05F7); keyboardLayout.put(new Integer(KeyEvent.VK_Q), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_W, 0x05FB); keyboardLayout.put(new Integer(KeyEvent.VK_W), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_L, 0x05FD); keyboardLayout.put(new Integer(KeyEvent.VK_L), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_0, 0x05FE); keyboardLayout.put(new Integer(KeyEvent.VK_0), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD0, 0x05FE); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD0), (KeyPress) keyp);
		// --------------------------------------------------------------------------------------------------------------------------


		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11101111
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A12 (#4) | =      LFT     é       Z       S       X       ,       P
		// Single key:
		keyp = new KeyPress(KeyEvent.VK_EQUALS, 0x047F); keyboardLayout.put(new Integer(KeyEvent.VK_EQUALS), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_2, 0x04DF); keyboardLayout.put(new Integer(KeyEvent.VK_2), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD2, 0x04DF); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD2), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_Z, 0x04EF); keyboardLayout.put(new Integer(KeyEvent.VK_Z), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_S, 0x04F7); keyboardLayout.put(new Integer(KeyEvent.VK_S), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_X, 0x04FB); keyboardLayout.put(new Integer(KeyEvent.VK_X), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_COMMA, 0x04FD); keyboardLayout.put(new Integer(KeyEvent.VK_COMMA), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_P, 0x04FE); keyboardLayout.put(new Integer(KeyEvent.VK_P), (KeyPress) keyp);
		// --------------------------------------------------------------------------------------------------------------------------


		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11110111
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A11 (#3) | )      RGT     "       E       D       C       K       ç
		// Single key:
		keyp = new KeyPress(KeyEvent.VK_RIGHT_PARENTHESIS, 0x037F); keyboardLayout.put(new Integer(KeyEvent.VK_RIGHT_PARENTHESIS), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_3, 0x03DF); keyboardLayout.put(new Integer(KeyEvent.VK_3), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD3, 0x03DF); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD3), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_E, 0x03EF); keyboardLayout.put(new Integer(KeyEvent.VK_E), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_D, 0x03F7); keyboardLayout.put(new Integer(KeyEvent.VK_D), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_C, 0x03FB); keyboardLayout.put(new Integer(KeyEvent.VK_C), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_K, 0x03FD); keyboardLayout.put(new Integer(KeyEvent.VK_K), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_9, 0x03FE); keyboardLayout.put(new Integer(KeyEvent.VK_9), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD9, 0x03FE); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD9), (KeyPress) keyp);
		// --------------------------------------------------------------------------------------------------------------------------


		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11111011
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A10 (#2) | -      DWN     '       R       F       V       J       O
		// Single key:
		keyp = new KeyPress(KeyEvent.VK_MINUS, 0x027F); keyboardLayout.put(new Integer(KeyEvent.VK_MINUS), (KeyPress) keyp);
		//keyp = new KeyPress(KeyEvent.VK_UNDERSCORE, 0x027F); keyboardLayout.put(new Integer(KeyEvent.VK_UNDERSCORE), (KeyPress) keyp);
		
		keyp = new KeyPress(KeyEvent.VK_4, 0x02DF); keyboardLayout.put(new Integer(KeyEvent.VK_4), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD4, 0x02DF); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD4), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_R, 0x02EF); keyboardLayout.put(new Integer(KeyEvent.VK_R), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_F, 0x02F7); keyboardLayout.put(new Integer(KeyEvent.VK_F), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_V, 0x02FB); keyboardLayout.put(new Integer(KeyEvent.VK_V), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_J, 0x02FD); keyboardLayout.put(new Integer(KeyEvent.VK_J), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_O, 0x02FE); keyboardLayout.put(new Integer(KeyEvent.VK_O), (KeyPress) keyp);
		// --------------------------------------------------------------------------------------------------------------------------


		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11111101
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A9  (#1) | <      UP      (       T       G       B       U       I
		// Single key:
		keyp = new KeyPress(KeyEvent.VK_LESS, 0x017F); keyboardLayout.put(new Integer(KeyEvent.VK_LESS), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_5, 0x01DF); keyboardLayout.put(new Integer(KeyEvent.VK_5), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD5, 0x01DF); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD5), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_T, 0x01EF); keyboardLayout.put(new Integer(KeyEvent.VK_T), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_G, 0x01F7); keyboardLayout.put(new Integer(KeyEvent.VK_G), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_B, 0x01FB); keyboardLayout.put(new Integer(KeyEvent.VK_B), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_U, 0x01FD); keyboardLayout.put(new Integer(KeyEvent.VK_U), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_I, 0x01FE); keyboardLayout.put(new Integer(KeyEvent.VK_I), (KeyPress) keyp);
		// --------------------------------------------------------------------------------------------------------------------------


		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11111110
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A8  (#0) | DEL    ENTER   §       Y       H       N       è       !
		// Single key:

		keyp = new KeyPress(KeyEvent.VK_6, 0x00DF); keyboardLayout.put(new Integer(KeyEvent.VK_6), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD6, 0x00DF); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD6), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_Y, 0x00EF); keyboardLayout.put(new Integer(KeyEvent.VK_Y), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_H, 0x00F7); keyboardLayout.put(new Integer(KeyEvent.VK_H), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_N, 0x00FB); keyboardLayout.put(new Integer(KeyEvent.VK_N), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_7, 0x00FD); keyboardLayout.put(new Integer(KeyEvent.VK_7), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD7, 0x00FD); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD7), (KeyPress) keyp);
		
		keyp = new KeyPress(KeyEvent.VK_EXCLAMATION_MARK, 0x00FE); keyboardLayout.put(new Integer(KeyEvent.VK_EXCLAMATION_MARK), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD8, 0x00FE); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD8), (KeyPress) keyp);
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
		Map keyboardLayout;
		KeyPress keyp;

		keyboardLayout = new HashMap();
		mapSystemKeys(keyboardLayout);

		// --------------------------------------------------------------------------------------------------------------------------
		// Row 01111111:
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A15 (#7) | RSH    SQR     ESC     INDEX   CAPS    .       -       £
		// Single key:
		keyp = new KeyPress(KeyEvent.VK_PERIOD, 0x07FB); keyboardLayout.put(new Integer(KeyEvent.VK_PERIOD), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_MINUS, 0x07FD); keyboardLayout.put(new Integer(KeyEvent.VK_MINUS), (KeyPress) keyp);

		// The '£' key is not available as a single letter on DK International PC keyboards, so we steel the '<' key next to 'Z'
		keyp = new KeyPress(KeyEvent.VK_LESS, 0x07FE); keyboardLayout.put(new Integer(KeyEvent.VK_LESS), (KeyPress) keyp);
		// --------------------------------------------------------------------------------------------------------------------------


		// --------------------------------------------------------------------------------------------------------------------------
		// Row 10111111
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A14 (#6) | HELP   LSH     TAB     DIA     MENU    ,       Æ       Ø
		// Single key:
		keyp = new KeyPress(KeyEvent.VK_COMMA, 0x06FB); keyboardLayout.put(new Integer(KeyEvent.VK_COMMA), (KeyPress) keyp);
		keyp = new KeyPress((0x10000 | 'æ'), 0x06FD); keyboardLayout.put(new Integer((0x10000 | 'æ')), (KeyPress) keyp);
		keyp = new KeyPress((0x10000 | 'Æ'), 0x06FD); keyboardLayout.put(new Integer((0x10000 | 'Æ')), (KeyPress) keyp);
		keyp = new KeyPress((0x10000 | 134), 0x06FD); keyboardLayout.put(new Integer((0x10000 | 134)), (KeyPress) keyp); // CTRL æ
		keyp = new KeyPress((0x10000 | 'ø'), 0x06FE); keyboardLayout.put(new Integer((0x10000 | 'ø')), (KeyPress) keyp);
		keyp = new KeyPress((0x10000 | 'Ø'), 0x06FE); keyboardLayout.put(new Integer((0x10000 | 'Ø')), (KeyPress) keyp);
		keyp = new KeyPress((0x10000 | 152), 0x06FE); keyboardLayout.put(new Integer((0x10000 | 152)), (KeyPress) keyp); // CTRL ø
		// --------------------------------------------------------------------------------------------------------------------------


		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11011111
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A13 (#5) | Å      SPACE   1       Q       A       Z       L       0
		// Single key:
		keyp = new KeyPress((0x10000 | 'å'), 0x057F); keyboardLayout.put(new Integer((0x10000 | 'å')), (KeyPress) keyp);
		keyp = new KeyPress((0x10000 | 'Å'), 0x057F); keyboardLayout.put(new Integer((0x10000 | 'Å')), (KeyPress) keyp);
		keyp = new KeyPress((0x10000 | 133), 0x057F); keyboardLayout.put(new Integer((0x10000 | 133)), (KeyPress) keyp); // CTRL å

		keyp = new KeyPress(KeyEvent.VK_1, 0x05DF); keyboardLayout.put(new Integer(KeyEvent.VK_1), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD1, 0x05DF); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD1), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_Q, 0x05EF); keyboardLayout.put(new Integer(KeyEvent.VK_Q), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_A, 0x05F7); keyboardLayout.put(new Integer(KeyEvent.VK_A), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_Z, 0x05FB); keyboardLayout.put(new Integer(KeyEvent.VK_Z), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_L, 0x05FD); keyboardLayout.put(new Integer(KeyEvent.VK_L), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_0, 0x05FE); keyboardLayout.put(new Integer(KeyEvent.VK_0), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD0, 0x05FE); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD0), (KeyPress) keyp);
		// --------------------------------------------------------------------------------------------------------------------------


		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11101111
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A12 (#4) | '      LFT     2       W       S       X       M       P
		// Single key:
		keyp = new KeyPress(KeyEvent.VK_QUOTE, 0x047F); keyboardLayout.put(new Integer(KeyEvent.VK_QUOTE), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_2, 0x04DF); keyboardLayout.put(new Integer(KeyEvent.VK_2), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD2, 0x04DF); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD2), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_W, 0x04EF); keyboardLayout.put(new Integer(KeyEvent.VK_W), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_S, 0x04F7); keyboardLayout.put(new Integer(KeyEvent.VK_S), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_X, 0x04FB); keyboardLayout.put(new Integer(KeyEvent.VK_X), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_M, 0x04FD); keyboardLayout.put(new Integer(KeyEvent.VK_M), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_P, 0x04FE); keyboardLayout.put(new Integer(KeyEvent.VK_P), (KeyPress) keyp);
		// --------------------------------------------------------------------------------------------------------------------------


		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11110111
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A11 (#3) | =      RGT     3       E       D       C       K       9
		// Single key:
		// '=' is not available as a direct key on DK host layout, so we steel the '`' key between '+' key and BACK SPACE
		keyp = new KeyPress(KeyEvent.VK_DEAD_ACUTE, 0x037F); keyboardLayout.put(new Integer(KeyEvent.VK_DEAD_ACUTE), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_3, 0x03DF); keyboardLayout.put(new Integer(KeyEvent.VK_3), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD3, 0x03DF); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD3), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_E, 0x03EF); keyboardLayout.put(new Integer(KeyEvent.VK_E), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_D, 0x03F7); keyboardLayout.put(new Integer(KeyEvent.VK_D), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_C, 0x03FB); keyboardLayout.put(new Integer(KeyEvent.VK_C), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_K, 0x03FD); keyboardLayout.put(new Integer(KeyEvent.VK_K), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_9, 0x03FE); keyboardLayout.put(new Integer(KeyEvent.VK_9), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD9, 0x03FE); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD9), (KeyPress) keyp);
		// --------------------------------------------------------------------------------------------------------------------------


		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11111011
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A10 (#2) | +      DWN     4       R       F       V       J       O
		// Single key:
		keyp = new KeyPress(KeyEvent.VK_PLUS, 0x027F); keyboardLayout.put(new Integer(KeyEvent.VK_PLUS), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_4, 0x02DF); keyboardLayout.put(new Integer(KeyEvent.VK_4), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD4, 0x02DF); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD4), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_R, 0x02EF); keyboardLayout.put(new Integer(KeyEvent.VK_R), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_F, 0x02F7); keyboardLayout.put(new Integer(KeyEvent.VK_F), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_V, 0x02FB); keyboardLayout.put(new Integer(KeyEvent.VK_V), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_J, 0x02FD); keyboardLayout.put(new Integer(KeyEvent.VK_J), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_O, 0x02FE); keyboardLayout.put(new Integer(KeyEvent.VK_O), (KeyPress) keyp);
		// --------------------------------------------------------------------------------------------------------------------------


		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11111101
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A9  (#1) | /      UP      5       T       G       B       U       I
		// Single key:
		// '/' does not exist as a single key press, so we steel the '^' key next to 'Å' key.
		keyp = new KeyPress(KeyEvent.VK_DEAD_DIAERESIS, 0x017F); keyboardLayout.put(new Integer(KeyEvent.VK_DEAD_DIAERESIS), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_5, 0x01DF); keyboardLayout.put(new Integer(KeyEvent.VK_5), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD5, 0x01DF); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD5), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_T, 0x01EF); keyboardLayout.put(new Integer(KeyEvent.VK_T), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_G, 0x01F7); keyboardLayout.put(new Integer(KeyEvent.VK_G), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_B, 0x01FB); keyboardLayout.put(new Integer(KeyEvent.VK_B), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_U, 0x01FD); keyboardLayout.put(new Integer(KeyEvent.VK_U), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_I, 0x01FE); keyboardLayout.put(new Integer(KeyEvent.VK_I), (KeyPress) keyp);
		// --------------------------------------------------------------------------------------------------------------------------


		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11111110
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A8  (#0) | DEL    ENTER   6       Y       H       N       7       8
		// Single key:
		keyp = new KeyPress(KeyEvent.VK_6, 0x00DF); keyboardLayout.put(new Integer(KeyEvent.VK_6), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD6, 0x00DF); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD6), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_Y, 0x00EF); keyboardLayout.put(new Integer(KeyEvent.VK_Y), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_H, 0x00F7); keyboardLayout.put(new Integer(KeyEvent.VK_H), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_N, 0x00FB); keyboardLayout.put(new Integer(KeyEvent.VK_N), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_7, 0x00FD); keyboardLayout.put(new Integer(KeyEvent.VK_7), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD7, 0x00FD); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD7), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_8, 0x00FE); keyboardLayout.put(new Integer(KeyEvent.VK_8), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD8, 0x00FE); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD8), (KeyPress) keyp);
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
		Map keyboardLayout;
		KeyPress keyp;

		keyboardLayout = new HashMap();
		mapSystemKeys(keyboardLayout);

		// --------------------------------------------------------------------------------------------------------------------------
		// Row 01111111:
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A15 (#7) | RSH    SQR     ESC     INDEX   CAPS    .       -       £
		// Single key:
		keyp = new KeyPress(KeyEvent.VK_PERIOD, 0x07FB); keyboardLayout.put(new Integer(KeyEvent.VK_PERIOD), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_MINUS, 0x07FD); keyboardLayout.put(new Integer(KeyEvent.VK_MINUS), (KeyPress) keyp);

		// The '£' key is not available as a single letter on DK International PC keyboards, so we steel the '<' key next to 'Z'
		keyp = new KeyPress(KeyEvent.VK_LESS, 0x07FE); keyboardLayout.put(new Integer(KeyEvent.VK_LESS), (KeyPress) keyp);
		// --------------------------------------------------------------------------------------------------------------------------


		// --------------------------------------------------------------------------------------------------------------------------
		// Row 10111111
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A14 (#6) | HELP   LSH     TAB     DIA     MENU    ,       Æ       Ø
		// Single key:
		keyp = new KeyPress(KeyEvent.VK_COMMA, 0x06FB); keyboardLayout.put(new Integer(KeyEvent.VK_COMMA), (KeyPress) keyp);
		keyp = new KeyPress((0x10000 | 'ö'), 0x06FD); keyboardLayout.put(new Integer((0x10000 | 'ö')), (KeyPress) keyp);
		keyp = new KeyPress((0x10000 | 'Ö'), 0x06FD); keyboardLayout.put(new Integer((0x10000 | 'Ö')), (KeyPress) keyp);
		keyp = new KeyPress((0x10000 | 150), 0x06FD); keyboardLayout.put(new Integer((0x10000 | 150)), (KeyPress) keyp); // CTRL ö
		keyp = new KeyPress((0x10000 | 'ä'), 0x06FE); keyboardLayout.put(new Integer((0x10000 | 'ä')), (KeyPress) keyp);
		keyp = new KeyPress((0x10000 | 'Ä'), 0x06FE); keyboardLayout.put(new Integer((0x10000 | 'Ä')), (KeyPress) keyp);
		keyp = new KeyPress((0x10000 | 132), 0x06FE); keyboardLayout.put(new Integer((0x10000 | 132)), (KeyPress) keyp); // CTRL ä
		// --------------------------------------------------------------------------------------------------------------------------


		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11011111
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A13 (#5) | Å      SPACE   1       Q       A       Z       L       0
		// Single key:
		keyp = new KeyPress((0x10000 | 'å'), 0x057F); keyboardLayout.put(new Integer((0x10000 | 'å')), (KeyPress) keyp);
		keyp = new KeyPress((0x10000 | 'Å'), 0x057F); keyboardLayout.put(new Integer((0x10000 | 'Å')), (KeyPress) keyp);
		keyp = new KeyPress((0x10000 | 133), 0x057F); keyboardLayout.put(new Integer((0x10000 | 133)), (KeyPress) keyp); // CTRL å

		keyp = new KeyPress(KeyEvent.VK_1, 0x05DF); keyboardLayout.put(new Integer(KeyEvent.VK_1), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD1, 0x05DF); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD1), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_Q, 0x05EF); keyboardLayout.put(new Integer(KeyEvent.VK_Q), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_A, 0x05F7); keyboardLayout.put(new Integer(KeyEvent.VK_A), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_Z, 0x05FB); keyboardLayout.put(new Integer(KeyEvent.VK_Z), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_L, 0x05FD); keyboardLayout.put(new Integer(KeyEvent.VK_L), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_0, 0x05FE); keyboardLayout.put(new Integer(KeyEvent.VK_0), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD0, 0x05FE); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD0), (KeyPress) keyp);
		// --------------------------------------------------------------------------------------------------------------------------


		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11101111
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A12 (#4) | '      LFT     2       W       S       X       M       P
		// Single key:
		keyp = new KeyPress(KeyEvent.VK_QUOTE, 0x047F); keyboardLayout.put(new Integer(KeyEvent.VK_QUOTE), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_2, 0x04DF); keyboardLayout.put(new Integer(KeyEvent.VK_2), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD2, 0x04DF); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD2), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_W, 0x04EF); keyboardLayout.put(new Integer(KeyEvent.VK_W), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_S, 0x04F7); keyboardLayout.put(new Integer(KeyEvent.VK_S), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_X, 0x04FB); keyboardLayout.put(new Integer(KeyEvent.VK_X), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_M, 0x04FD); keyboardLayout.put(new Integer(KeyEvent.VK_M), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_P, 0x04FE); keyboardLayout.put(new Integer(KeyEvent.VK_P), (KeyPress) keyp);
		// --------------------------------------------------------------------------------------------------------------------------


		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11110111
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A11 (#3) | =      RGT     3       E       D       C       K       9
		// Single key:
		// '=' is not available as a direct key on DK host layout, so we steel the '`' key between '+' key and BACK SPACE
		keyp = new KeyPress(KeyEvent.VK_DEAD_ACUTE, 0x037F); keyboardLayout.put(new Integer(KeyEvent.VK_DEAD_ACUTE), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_3, 0x03DF); keyboardLayout.put(new Integer(KeyEvent.VK_3), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD3, 0x03DF); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD3), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_E, 0x03EF); keyboardLayout.put(new Integer(KeyEvent.VK_E), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_D, 0x03F7); keyboardLayout.put(new Integer(KeyEvent.VK_D), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_C, 0x03FB); keyboardLayout.put(new Integer(KeyEvent.VK_C), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_K, 0x03FD); keyboardLayout.put(new Integer(KeyEvent.VK_K), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_9, 0x03FE); keyboardLayout.put(new Integer(KeyEvent.VK_9), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD9, 0x03FE); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD9), (KeyPress) keyp);
		// --------------------------------------------------------------------------------------------------------------------------


		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11111011
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A10 (#2) | +      DWN     4       R       F       V       J       O
		// Single key:
		keyp = new KeyPress(KeyEvent.VK_PLUS, 0x027F); keyboardLayout.put(new Integer(KeyEvent.VK_PLUS), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_4, 0x02DF); keyboardLayout.put(new Integer(KeyEvent.VK_4), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD4, 0x02DF); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD4), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_R, 0x02EF); keyboardLayout.put(new Integer(KeyEvent.VK_R), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_F, 0x02F7); keyboardLayout.put(new Integer(KeyEvent.VK_F), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_V, 0x02FB); keyboardLayout.put(new Integer(KeyEvent.VK_V), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_J, 0x02FD); keyboardLayout.put(new Integer(KeyEvent.VK_J), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_O, 0x02FE); keyboardLayout.put(new Integer(KeyEvent.VK_O), (KeyPress) keyp);
		// --------------------------------------------------------------------------------------------------------------------------


		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11111101
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A9  (#1) | /      UP      5       T       G       B       U       I
		// Single key:
		// '/' does not exist as a single key press, so we steel the '^' key next to 'Å' key.
		keyp = new KeyPress(KeyEvent.VK_DEAD_DIAERESIS, 0x017F); keyboardLayout.put(new Integer(KeyEvent.VK_DEAD_DIAERESIS), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_5, 0x01DF); keyboardLayout.put(new Integer(KeyEvent.VK_5), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD5, 0x01DF); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD5), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_T, 0x01EF); keyboardLayout.put(new Integer(KeyEvent.VK_T), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_G, 0x01F7); keyboardLayout.put(new Integer(KeyEvent.VK_G), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_B, 0x01FB); keyboardLayout.put(new Integer(KeyEvent.VK_B), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_U, 0x01FD); keyboardLayout.put(new Integer(KeyEvent.VK_U), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_I, 0x01FE); keyboardLayout.put(new Integer(KeyEvent.VK_I), (KeyPress) keyp);
		// --------------------------------------------------------------------------------------------------------------------------


		// --------------------------------------------------------------------------------------------------------------------------
		// Row 11111110
		//			| D7     D6      D5      D4      D3      D2      D1      D0
		// -------------------------------------------------------------------------
		// A8  (#0) | DEL    ENTER   6       Y       H       N       7       8
		// Single key:
		keyp = new KeyPress(KeyEvent.VK_6, 0x00DF); keyboardLayout.put(new Integer(KeyEvent.VK_6), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD6, 0x00DF); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD6), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_Y, 0x00EF); keyboardLayout.put(new Integer(KeyEvent.VK_Y), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_H, 0x00F7); keyboardLayout.put(new Integer(KeyEvent.VK_H), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_N, 0x00FB); keyboardLayout.put(new Integer(KeyEvent.VK_N), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_7, 0x00FD); keyboardLayout.put(new Integer(KeyEvent.VK_7), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD7, 0x00FD); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD7), (KeyPress) keyp);

		keyp = new KeyPress(KeyEvent.VK_8, 0x00FE); keyboardLayout.put(new Integer(KeyEvent.VK_8), (KeyPress) keyp);
		keyp = new KeyPress(KeyEvent.VK_NUMPAD8, 0x00FE); keyboardLayout.put(new Integer(KeyEvent.VK_NUMPAD8), (KeyPress) keyp);
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
		int columns = 0xFF; int mask = 1;

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

		keyMatrixRow = (keyp.keyZ88Typed & 0xff00) >>> 8;
		keyMask = keyp.keyZ88Typed & 0xff;
		keyRows[keyMatrixRow] &= keyMask;
		
		Blink.getInstance().signalKeyPressed();
	}

	
	/**
	 * "Press" the Z88 key according to the hardware matrix.
	 * 
	 * @param keyMatrixRow
	 * @param keyMask
	 */
	public void pressZ88key(int keyMatrixRow, int keyMask) {
		keyRows[keyMatrixRow] &= keyMask;
		Blink.getInstance().signalKeyPressed();
	}

	
	/**
	 * "Release" the Z88 key according to the hardware matrix.
	 * 
	 * @param keyMatrixRow
	 * @param keyMask
	 */
	public void releaseZ88key(int keyMatrixRow, int keyMask) {
		keyRows[keyMatrixRow] |= (~keyMask & 0xff);
		Blink.getInstance().signalKeyPressed();
	}

	
	/**
	 * Release a Z88 key from the Z88 hardware keyboard matrix.
	 */
	private void releaseZ88key(KeyPress keyp) {
		int keyMatrixRow, keyMask;

		keyMatrixRow = (keyp.keyZ88Typed & 0xff00) >>> 8;
		keyMask = keyp.keyZ88Typed & 0xff;
		keyRows[keyMatrixRow] |= (~keyMask & 0xff);
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
		rubberKb.setKeyboardCountrySpecificIcons(kbl);
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

			//System.out.println("keyPressed() event: " + e.getKeyCode() + "('" + e.getKeyChar() + "' (" + (int) e.getKeyChar()+ ")," + e.getKeyLocation() + "," + (int) e.getModifiers() + ")");

			switch(e.getKeyCode()) {								
				case KeyEvent.VK_SHIFT:
					// check if left or right SHIFT were pressed
					if (e.getKeyLocation() == KeyEvent.KEY_LOCATION_LEFT) pressZ88key(z88LshKey);
					if (e.getKeyLocation() == KeyEvent.KEY_LOCATION_RIGHT) pressZ88key(z88RshKey);
					break;

				case KeyEvent.VK_F5:
					OZvm.getInstance().commandLine(true);
					Blink.getInstance().stopZ80Execution();						
					break;

				case KeyEvent.VK_F12:
					if (Blink.getInstance().getDebugMode() == true) { 
						OZvm.getInstance().getCommandLine().getDebugGui().getCmdLineInputArea().grabFocus();	// Use F12 to toggle between debugger command input and Z88 kb input 
					}
					break;

				case KeyEvent.VK_CONTROL:
					pressZ88key(z88DiamondKey);		// CTRL executes single Z88 DIAMOND key
					break;

				case KeyEvent.VK_ALT:
					pressZ88key(z88SquareKey);		// ALT executes single Z88 SQUARE key
					break;
					
				case KeyEvent.VK_INSERT:
					kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_V));
					pressZ88key(z88DiamondKey);
					pressZ88key(kp);				// INSERT executes Z88 DIAMOND V
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
					kp = (KeyPress) currentKbLayout.get(new Integer(e.getKeyCode()));
					pressZ88key(kp);
					break;

				case 0:
					// Special characters
					kp = (KeyPress) currentKbLayout.get(new Integer((0x10000 | e.getKeyChar())));
					if (kp != null) {
						pressZ88key(kp);
					}
					break;

				case KeyEvent.VK_6:
					if (currentKbLayout == z88Keyboards[COUNTRY_FR]) {
						if ( e.getModifiers() == 0 ) {
							// French PC '-' is mapped to Z88 -
							kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_MINUS));
						}

						if ((e.getModifiers() == java.awt.Event.SHIFT_MASK) | (e.getModifiers() == java.awt.Event.CTRL_MASK)) {
							// French PC SHIFT - is mapped to Z88 SHIFT § which gives an 6.
							kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_6));
						}
						
						if (e.getModifiers() == (java.awt.Event.CTRL_MASK + java.awt.Event.ALT_MASK)) {
							// PC [ALT Gr '6'] = '|' converts to Z88 <>' = |
							releaseZ88key(z88SquareKey); // only DIAMOND (is already) pressed...
							kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_4));					}
					} else {
						kp = (KeyPress) currentKbLayout.get(new Integer(e.getKeyCode()));	
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
							kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_MINUS));
						}

						if ((e.getModifiers() == java.awt.Event.SHIFT_MASK) | (e.getModifiers() == java.awt.Event.CTRL_MASK)) {
							// French PC SHIFT _ is mapped to Z88 SHIFT ! which gives an 8.
							kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_EXCLAMATION_MARK));
						}
						
						if (e.getModifiers() == (java.awt.Event.CTRL_MASK + java.awt.Event.ALT_MASK)) {
							// PC [ALT Gr '8'] = '\' converts to Z88 <>& = \
							releaseZ88key(z88SquareKey); // only DIAMOND (is already) pressed...
							kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_1));
						}
					} else {
						kp = (KeyPress) currentKbLayout.get(new Integer(e.getKeyCode()));	
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
							kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_6));
						} else {
							kp = (KeyPress) currentKbLayout.get(new Integer(e.getKeyCode()));	
						}
					} else {
						kp = (KeyPress) currentKbLayout.get(new Integer(e.getKeyCode()));	
					}				
					if (kp != null) {
						pressZ88key(kp);
					}									
					break;

				case KeyEvent.VK_ADD:
					if (currentKbLayout == z88Keyboards[COUNTRY_FR]) {
						pressZ88key(z88RshKey);
						kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_EQUALS));					
					}
					if (kp != null) {
						pressZ88key(kp);
					}
					break;
					
				case KeyEvent.VK_SUBTRACT:
					// Numerical Keyboard, '-' key
					if (currentKbLayout == z88Keyboards[COUNTRY_FR]) {
						kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_MINUS));					
					}
					if (kp != null) {
						pressZ88key(kp);
					}
					break;
					
				case KeyEvent.VK_MULTIPLY:
					// Numerical Keyboard, '*' key
					if (currentKbLayout == z88Keyboards[COUNTRY_FR]) {
						kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_ASTERISK));					
					}
					if (kp != null) {
						pressZ88key(kp);
					}
					break;

				case KeyEvent.VK_DIVIDE:
					// Numerical Keyboard, '/' key
					if (currentKbLayout == z88Keyboards[COUNTRY_FR]) {
						pressZ88key(z88RshKey);
						kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_COLON));					
					}
					if (kp != null) {
						pressZ88key(kp);
					}
					break;
					
				case KeyEvent.VK_DECIMAL:
					// Numerical Keyboard, '.' key
					if (currentKbLayout == z88Keyboards[COUNTRY_FR]) {
						pressZ88key(z88RshKey);
						kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_SEMICOLON));					
					}
					if (kp != null) {
						pressZ88key(kp);
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
									kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_5));
									break;
								case KeyEvent.VK_3:  // PC [ALT Gr '3'] = '#' converts to Z88 <>" = #
									releaseZ88key(z88SquareKey); // only DIAMOND (is already) pressed...
									kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_3));
									break;
								case KeyEvent.VK_4:  // PC [ALT Gr '4'] = '{' converts to Z88 <>è = {
									releaseZ88key(z88SquareKey); // only DIAMOND (is already) pressed...
									kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_7));
									break;
								case KeyEvent.VK_5:  // PC [ALT Gr '5'] = '[' converts to Z88 <>ç = [
									releaseZ88key(z88SquareKey); // only DIAMOND (is already) pressed...
									kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_9));
									break;
								case KeyEvent.VK_7:  // PC [ALT Gr '7'] = '`' converts to Z88 <>) = `
									releaseZ88key(z88SquareKey); // only DIAMOND (is already) pressed...
									kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_RIGHT_PARENTHESIS));
									break;
								case KeyEvent.VK_9:  // PC [ALT Gr '9'] = '^' converts to Z88 <>§ = ^
									releaseZ88key(z88SquareKey); // only DIAMOND (is already) pressed...
									kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_6));
									break;
								case KeyEvent.VK_0:  // PC [ALT Gr '0'] = '@' converts to Z88 <>é = @
									releaseZ88key(z88SquareKey); // only DIAMOND (is already) pressed...
									kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_2));
									break;
								case KeyEvent.VK_RIGHT_PARENTHESIS:  // PC [ALT Gr ')'] = ']' converts to Z88 <>à = ]
									releaseZ88key(z88SquareKey); // only DIAMOND (is already) pressed...
									kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_0));
									break;
								case KeyEvent.VK_EQUALS:  // PC [ALT Gr '='] = '}' converts to Z88 <>! = }
									releaseZ88key(z88SquareKey); // only DIAMOND (is already) pressed...
									kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_EXCLAMATION_MARK));
									break;
							}
						}
						
					} else {
						kp = (KeyPress) currentKbLayout.get(new Integer(e.getKeyCode()));	
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

			//System.out.println("keyReleased() event: " + e.getKeyCode() + "('" + e.getKeyChar() + "' (" + (int) e.getKeyChar()+ ")," + e.getKeyLocation() + "," + (int) e.getModifiers() + ")");

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
					kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_V));
					releaseZ88key(kp);
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
					kp = (KeyPress) currentKbLayout.get(new Integer(e.getKeyCode()));
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
					kp = (KeyPress) currentKbLayout.get(new Integer((0x10000 | e.getKeyChar())));
					if (kp != null) {
						releaseZ88key(kp);
					}
					break;

				case KeyEvent.VK_6:
					if (currentKbLayout == z88Keyboards[COUNTRY_FR]) {
						if ( e.getModifiers() == 0 ) {
							// French PC '-' is mapped to Z88 -
							kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_MINUS));
						}

						if ((e.getModifiers() == java.awt.Event.SHIFT_MASK) | (e.getModifiers() == java.awt.Event.CTRL_MASK)) {
							// French PC SHIFT - is mapped to Z88 SHIFT § which gives an 6.
							kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_6));
						}
						
						if (e.getModifiers() == (java.awt.Event.CTRL_MASK + java.awt.Event.ALT_MASK)) {
							// PC [ALT Gr '6'] = '|' converts to Z88 <>' = |
							kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_4));					}
					} else {
						kp = (KeyPress) currentKbLayout.get(new Integer(e.getKeyCode()));	
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
							kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_MINUS));
						}

						if ((e.getModifiers() == java.awt.Event.SHIFT_MASK) | (e.getModifiers() == java.awt.Event.CTRL_MASK)) {
							// French PC SHIFT _ is mapped to Z88 SHIFT ! which gives an 8.
							kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_EXCLAMATION_MARK));
						}

						if (e.getModifiers() == (java.awt.Event.CTRL_MASK + java.awt.Event.ALT_MASK)) {
							// PC [ALT Gr '8'] = '\' converts to Z88 <>& = \
							kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_1));
						}
					} else {
						kp = (KeyPress) currentKbLayout.get(new Integer(e.getKeyCode()));	
					}
					
					if (kp != null) {
						releaseZ88key(kp);
					}									
					break;

				case KeyEvent.VK_EXCLAMATION_MARK:
					if (currentKbLayout == z88Keyboards[COUNTRY_FR]) {
						if ((e.getModifiers() == java.awt.Event.SHIFT_MASK)) {
							// French PC SHIFT ! is mapped to Z88 single key § (6).
							kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_6));
						} else {
							kp = (KeyPress) currentKbLayout.get(new Integer(e.getKeyCode()));	
						}
					} else {
						kp = (KeyPress) currentKbLayout.get(new Integer(e.getKeyCode()));	
					}				
					if (kp != null) {
						releaseZ88key(kp);
					}									
					break;

				case KeyEvent.VK_ADD:
					// Numerical Keyboard, '+' key
					if (currentKbLayout == z88Keyboards[COUNTRY_FR]) {
						releaseZ88key(z88RshKey);
						kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_EQUALS));					
					}
					if (kp != null) {
						releaseZ88key(kp);
					}
					break;

				case KeyEvent.VK_SUBTRACT:
					// Numerical Keyboard, '-' key
					if (currentKbLayout == z88Keyboards[COUNTRY_FR]) {
						kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_MINUS));					
					}
					if (kp != null) {
						releaseZ88key(kp);
					}
					break;
					
				case KeyEvent.VK_MULTIPLY:
					// Numerical Keyboard, '*' key
					if (currentKbLayout == z88Keyboards[COUNTRY_FR]) {
						kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_ASTERISK));					
					}
					if (kp != null) {
						releaseZ88key(kp);
					}
					break;

				case KeyEvent.VK_DIVIDE:
					// Numerical Keyboard, '/' key
					if (currentKbLayout == z88Keyboards[COUNTRY_FR]) {
						releaseZ88key(z88RshKey);
						kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_COLON));					
					}
					if (kp != null) {
						releaseZ88key(kp);
					}
					break;

				case KeyEvent.VK_DECIMAL:
					// Numerical Keyboard, '.' key
					if (currentKbLayout == z88Keyboards[COUNTRY_FR]) {
						releaseZ88key(z88RshKey);
						kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_SEMICOLON));					
					}
					if (kp != null) {
						releaseZ88key(kp);
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
									kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_5));
								    break;
								case KeyEvent.VK_3:  // PC [ALT Gr '3'] = '#' converts to Z88 <>" = #
									kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_3));
									break;
								case KeyEvent.VK_4:  // PC [ALT Gr '4'] = '{' converts to Z88 <>è = {
									kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_7));
								    break;
								case KeyEvent.VK_5:  // PC [ALT Gr '5'] = '[' converts to Z88 <>ç = [
									kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_9));
									break;							    
								case KeyEvent.VK_7:  // PC [ALT Gr '7'] = '`' converts to Z88 <>) = `
									kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_RIGHT_PARENTHESIS));
									break;
								case KeyEvent.VK_9:  // PC [ALT Gr '9'] = '^' converts to Z88 <>§ = ^
									kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_6));
									break;
								case KeyEvent.VK_0:  // PC [ALT Gr '0'] = '@' converts to Z88 <>é = @
									kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_2));
									break;
								case KeyEvent.VK_RIGHT_PARENTHESIS:  // PC [ALT Gr ')'] = ']' converts to Z88 <>à = ]
									kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_0));
									break;
								case KeyEvent.VK_EQUALS:  // PC [ALT Gr '='] = '}' converts to Z88 <>! = }
									kp = (KeyPress) currentKbLayout.get(new Integer(KeyEvent.VK_EXCLAMATION_MARK));
									break;
							}
						}
					} else {
						kp = (KeyPress) currentKbLayout.get(new Integer(e.getKeyCode()));	
					}
				
					if (kp != null) {
						releaseZ88key(kp);
					}
					break;
			}
		}

		public void keyTyped(KeyEvent e) {
			//System.out.println("keyTyped() event: " + e.getKeyCode() + "('" + e.getKeyChar() + "'," + e.getKeyLocation() + "," + (int) e.getModifiers() + ")");
		}		
	}
}
