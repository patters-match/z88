package net.sourceforge.z88;

import java.awt.event.KeyEvent;
import java.awt.event.KeyListener;
import java.util.Map;
import java.util.HashMap;


/**
 * Bind host operating system keyboard events to Z88 keyboard
 *
 * @author <A HREF="mailto:gstrube@tiscali.dk">Gunther Strube</A>
 * $Id$
 *
 */
public class Z88Keyboard implements KeyListener {
	// Index of HashMap array entries for Z88 keyboard layouts.
	public static final int COUNTRY_US = 0;		// English/US Keyboard layout
	public static final int COUNTRY_FR = 1;		// French Keyboard layout
	public static final int COUNTRY_DE = 2;		// German Keyboard layout
	public static final int COUNTRY_EN = 3;		// English/UK Keyboard layout
	public static final int COUNTRY_DK = 4;		// Danish Keyboard layout
	public static final int COUNTRY_SE = 5;		// Swedish Keyboard layout
	public static final int COUNTRY_IT = 6;		// Italian Keyboard layout
	public static final int COUNTRY_ES = 7;		// Spanish Keyboard layout
	public static final int COUNTRY_JP = 8;		// Japanese Keyboard layout
	public static final int COUNTRY_IS = 9;		// Icelandic Keyboard layout
	public static final int COUNTRY_NO = 10;	// Norwegian Keyboard layout
	public static final int COUNTRY_CH = 11;	// Keyboard layout for Schweiz
	public static final int COUNTRY_TR = 12;	// Keyboard layout for Turkey
	public static final int COUNTRY_FI = 13;	// Finnish Keyboard layout
	
    private Map currentLayout = null;
    private Map[] z88Keyboards = null;			// country specific keyboard layouts  
	
	private int keyRows[] = new int[8];
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
	
	private Blink blink = null;

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
     * Create the instance to bind the blink and SWT widget together.
     * 
     */
	public Z88Keyboard(Blink bl, java.awt.Canvas cnv) {
		blink = bl;
		
		for(int r=0; r<8;r++) keyRows[r] = 0xFF;	// Initialize to no keys pressed in z88 key matrix
		
		z88Keyboards = new Map[14];	// create the container for the various country keyboard layouts.
		createSystemKeys();
		createUkLayout();
		currentLayout = z88Keyboards[COUNTRY_EN];
		 
		// map Host keyboard events to this z88 keyboard, so that the emulator responds to keypresses.
		cnv.addKeyListener(this);		
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

		// CAPS LOCK = CAPS LOCK, row 7 (0x7F), column 3 (0xF7, 11110111)
		keyboardLayout.put(new Integer(KeyEvent.VK_CAPS_LOCK), (KeyPress) z88CapslockKey);

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
	 * Create Key Event mappings for Z88 UK keyboard matrix.
	 *
	 * All key entry mappings are implemented using the
	 * International 104 PC Keyboard with the UK layout.
	 * In other words, to obtain the best Z88 keyboard access
	 * on a UK Rom, you need to use the UK keyboard layout on
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
	private void createUkLayout() {
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

		z88Keyboards[COUNTRY_EN] = keyboardLayout;
	}


	/**
	 * Scans a particular Z88 hardware keyboard row, and returns the 
	 * corresponding key column.<br>
	 * 
	 * @param row, of Z88 keyboard to be scanned
	 * @return keyColumn, the column containing one or several key presses.
	 */
	public int scanKeyRow(int row) {
		int col = 0xFF;
				
		switch(row) {
			case 0x7F:
				col = keyRows[7]; // Row 01111111
				break;
			case 0xBF: 
				col = keyRows[6]; // Row 10111111
				break;
			case 0xDF: 
				col = keyRows[5]; // Row 11011111
				break;
			case 0xEF: 
				col = keyRows[4]; // Row 11101111
				break;
			case 0xF7: 
				col = keyRows[3]; // Row 11110111
				break;
			case 0xFB: 
				col = keyRows[2]; // Row 11111011
				break;				
			case 0xFD: 
				col = keyRows[1]; // Row 11111101
				break;				
			case 0xFE: 
				col = keyRows[0]; // Row 11111110
				break;
			default: 
				col = 0xFF; // This should never get called!
		}

		return col;
	}
		

	/**
	 * Scans the Z88 hardware keyboard, and returns true if one or several keys
	 * were pressed.<p> 
	 *
	 * The keyRows[] property contains all current keycolumns of this scan.<br>
	 * 
	 * @return active keyrow, if one or several keys were pressed during scan.
	 */ 
	public int getActiveKeyRow() {
		int keyRow = 0xFF;

		for (int scanRow = 0; scanRow < keyRows.length; scanRow++) {
			if ( keyRows[scanRow] != 0xFF ) keyRow = keyRows[scanRow];
		}  		

		return keyRow; 
	}


	/**
	 * Type a Z88 key into the Z88 hardware keyboard matrix.
	 */
	private void pressZ88key(KeyPress keyp) {
		int keyMatrixRow, keyMask;
		 
		keyMatrixRow = (keyp.keyZ88Typed & 0xff00) >>> 8;
		keyMask = keyp.keyZ88Typed & 0xff;
		keyRows[keyMatrixRow] &= keyMask;			
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
	 * This event is fired whenever a key press is recognised on the java.awt.Canvas.
	 */
	public void keyPressed(KeyEvent e) {
		System.out.println("keyPressed() event: " + e.getKeyCode() + "('" + e.getKeyChar() + "'," + e.getKeyLocation() + "," + (int) e.getModifiers() + ")");
				
		switch(e.getKeyCode()) {
			case KeyEvent.VK_SHIFT:
				// check if left or right SHIFT were pressed
				if (e.getKeyLocation() == KeyEvent.KEY_LOCATION_LEFT) pressZ88key(z88LshKey);
				if (e.getKeyLocation() == KeyEvent.KEY_LOCATION_RIGHT) pressZ88key(z88RshKey);  
				break;

			case KeyEvent.VK_CONTROL:
				pressZ88key(z88DiamondKey);		// CTRL executes single Z88 DIAMOND key   
				break;
				
			case KeyEvent.VK_ALT:
				pressZ88key(z88SquareKey);		// ALT executes single Z88 SQUARE key 
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
				
			default:
				// All other keypresses are available in keyboard map layout
				KeyPress kp = (KeyPress) currentLayout.get(new Integer(e.getKeyCode()));
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
		System.out.println("keyReleased() event: " + e.getKeyCode() + "('" + e.getKeyChar() + "'," + e.getKeyLocation() + "," + (int) e.getModifiers() + ")");

		switch(e.getKeyCode()) {
			case KeyEvent.VK_SHIFT:
				// check if left or right SHIFT were pressed
				if (e.getKeyLocation() == KeyEvent.KEY_LOCATION_LEFT) releaseZ88key(z88LshKey);
				if (e.getKeyLocation() == KeyEvent.KEY_LOCATION_RIGHT) releaseZ88key(z88RshKey);  
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
								
			default:
				// All other key releases are available in keyboard map layout
				KeyPress kp = (KeyPress) currentLayout.get(new Integer(e.getKeyCode()));
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
