package net.sourceforge.z88;

import java.awt.Color;
import java.util.TimerTask;

import gameframe.graphics.*;
import gameframe.input.*;
import gameframe.*;

public class Z88display 
{
	private static final int z88ScreenWidth = 640;			// The Z88 display dimensions
	private static final int z88ScreenHeight = 64;
	
	private static final Color pxColOn = new Color(2,4,130,255);		// #020482, Trying to get as close as possibly to the LCD colors...
	private static final Color pxColGrey = new Color(2,113,130,255);	// #027182
	private static final Color pxColOff = new Color(192,224,215,255);	// #C0E0D7
	
	private static final int attrBold = 0x80;	// Font attribute Bold Mask (LORES1)
	private static final int attrTiny = 0x40;	// Font attribute Tiny Mask (LORES1)
	private static final int attrHrs = 0x20;	// Font attribute Hires Mask (HIRES1)
	private static final int attrRev = 0x10;	// Font attribute Reverse Mask (LORES1 & HIRES1)
	private static final int attrFls = 0x08;	// Font attribute Flash Mask (LORES1 & HIRES1)
	private static final int attrGry = 0x04;	// Font attribute Grey Mask (all)
	private static final int attrUnd = 0x02;	// Font attribute Underline Mask (LORES1)
	private static final int attrNull = attrHrs | attrRev | attrGry;	// Null character (6x8 pixel blank)

	private static final int[] cpySBR = new int[2048];		// copy of rendered screen (internal SBR compact format)
	private final Blink blink;								// access to Blink hardware.

	private boolean initError = false;
	GraphicsEngine gfxe = null;
	GFGraphics grfx = null; 
	private KeyboardDevice keyboard;
	
	int lores0, lores1, hires0, hires1, sbr;
	int bankLores0, bankLores1, bankHires0, bankHires1, bankSbr;
	
    Z88display(Blink z88Blink) throws GameFrameException {

		blink = z88Blink; // The Z88 Display needs to access the Blink hardware
		for (int clrSbrCpy = 0; clrSbrCpy < cpySBR.length; clrSbrCpy++) {
			cpySBR[clrSbrCpy] = -1;
		}
        
		GameFrameSettings settings = new GameFrameSettings(); 
		settings.setTitle("Z88");
		settings.setRequestedGraphicsMode( new GraphicsMode(z88ScreenWidth, z88ScreenHeight));
		settings.setScreenMode(GameFrameSettings.SCREENMODE_WINDOWED);	// later to GameFrameSettings.SCREENMODE_COMPONENT
		settings.setSplashScreenAllowed(false);

		try {			
			GameFrame.init(settings);
			GameFrame.createGraphicsEngine();
			gfxe = GameFrame.getGraphicsEngine();
			GameFrame.createInputEngine(gfxe);
			grfx = gfxe.getBackbufferGraphics();	// for now, the Pure Java simple graphics renderer will be used.
													// (far from the fastest solution, but it works!)
		} catch (GameFrameException e) {
			initError = true;
			return;
		}
		
		// Get keyboard engine
		try
		{
			keyboard = GameFrame.getInputEngine().getDefaultKeyboardDevice();
		}
		catch( GameFrameException noKeyboard )
		{
			return;
		}
    }
	
	
	/**
	 * The core Z88 Display renderer.
	 * This code is called each 10ms by a Timer
	 */
	public void renderDisplay() {		
		lores0 = blink.getPb0();	// Memory base address of 6x8 pixel user defined fonts.		
		lores1 = blink.getPb1();	// Memory base address of 6x8 pixel fonts (0000=normal, 0400=bold, 0800=Tiny)
		hires0 = blink.getPb2();	// Memory base address of PipeDream Map (max 256x64 pixels)
		hires1 = blink.getPb3();	// Memory base address of 8x8 pixel fonts for OZ window
		sbr = blink.getSbr();		// Memory base address of Screen Base File (2K) 
		
		if (sbr == 0) return;		// LCD enabled, but the Screen Base Register hasn't been defined yet...

		long start = System.currentTimeMillis();
				 		
		bankLores0 = lores0 >>> 16; lores0 &= 0x3FFF;  // convert to bank, offset
		bankLores1 = lores1 >>> 16; lores1 &= 0x3FFF;
		bankHires0 = hires0 >>> 16; hires0 &= 0x3FFF;
		bankHires1 = hires1 >>> 16; hires1 &= 0x3FFF;
		bankSbr = sbr >>> 16; sbr &= 0x3FFF;

		int scrBaseCoordX = 0, scrBaseCoordY = 0; 
		for (int scrRowOffset=0; scrRowOffset < 2048; scrRowOffset += 256) {			// scan 8 rows in screen file
			for (int lineCharOffset=0; lineCharOffset < 213; lineCharOffset += 2) {		// scan 106 2-byte control characters per row in screen file
				int sbrOffset = sbr + scrRowOffset + lineCharOffset;
				int scrChar = blink.getByte(sbrOffset, bankSbr);
				int scrCharAttr = blink.getByte(sbrOffset + 1, bankSbr);
								
				if ( (scrChar != cpySBR[scrRowOffset + lineCharOffset]) | 
				     (scrCharAttr != cpySBR[scrRowOffset + lineCharOffset + 1]) ) {
					// this char has been updated (by comparing current SBR with the rendered copy)
					// so, render the new char now...
					cpySBR[scrRowOffset + lineCharOffset] = scrChar;		// update new char in render copy
					cpySBR[scrRowOffset + lineCharOffset + 1] = scrCharAttr; 

					if ((scrCharAttr & attrHrs) == 0) {						
						// Draw a LORES1 character (6x8 pixel matrix), char offset into LORES1 is 9 bits...
						drawLoresChar(scrBaseCoordX, scrBaseCoordY, scrCharAttr, scrChar);
						scrBaseCoordX += 6;
					} else {
						if ((scrCharAttr & (attrHrs|attrRev)) == attrHrs) {
							// Draw a HIRES character (UDG or PipeDream MAP)
							drawHiresChar(scrBaseCoordX, scrBaseCoordY, scrCharAttr, scrChar);
							scrBaseCoordX += 8;							
						}
					}
				}				
			}
			
			// when a complete row (8 pixels deep) has been rendered,
			// find out if pixels remain up to the 639'th pixel;
			// these need to get "blanked", before beginning with the next row...
			
			// finally, prepare for next pixel row base (downwards)...
			scrBaseCoordY += 8;
			scrBaseCoordX = 0;
		}
		
		// complete screen has been rendered, flip buffer into video memory
		gfxe.flip();

		System.out.println("Time to render screen: " + (System.currentTimeMillis() - start));		

		// Wait until user presses ESC key or tries to otherwise exit
		while( !keyboard.wasKeyDown( java.awt.event.KeyEvent.VK_ESCAPE )
				&& !GameFrame.isExitWanted() ) {
			try {
				Thread.sleep(10);
			} catch (InterruptedException e) {
			}
		}		
	}
	
	private void drawLoresChar(final int scrBaseCoordX, final int scrBaseCoordY, final int charAttr, final int scrChar) {
		int charRow;
		int bank; 
		Color pxOn = null, pxColor = null;
		
		if ( (charAttr & attrGry) == 0)
			pxOn = pxColOn;		// paint a clear enabled pixel
		else
			pxOn = pxColGrey;	// paint a 'grey' enabled pixel									

		int offset = ((charAttr & 1) << 8) | scrChar;
		if (offset >= 0x1c0) { 
			offset = lores0 + (scrChar << 3);	// User defined graphics, default in RAM.0
			bank = bankLores0;
		}
		else {
			offset = lores1 + (offset << 3);	// Base fonts (tiny, bold), default in ROM.0 
			bank = bankLores1;
		}

		// render 8 pixel rows of character
		for(charRow=0; charRow<8; charRow++) {
			int pxOffset = 0;
		
			int charBits = blink.getByte(offset+charRow, bank);	// fetch current row of char
			if ( (charAttr & attrRev) == attrRev) {
				charBits = ~charBits;
			}
		
			// render only 6 pixels wide (bit 7 & 6 are ignored)...
			for(int bit=32; bit>0; bit>>>=1) {
				if ((charBits & bit) != 0)
					pxColor = pxOn; 
				else 
					pxColor = pxColOff;			// paint no pixel, just LCD background				
							
				grfx.setColor(pxColor);	
				grfx.drawPixel(scrBaseCoordX + pxOffset++, scrBaseCoordY + charRow);
			}			
		}

		// draw underline?
		if ( (charAttr & attrUnd) == attrUnd) {
			pxColor = pxOn;	 
			if ((charAttr & attrRev) == attrRev) pxColor = pxColOff;	// paint "inverse" underline.. 
	
			grfx.setColor(pxColor);
			grfx.drawLine(scrBaseCoordX, scrBaseCoordY + 7, scrBaseCoordX + 5, scrBaseCoordY + 7);
		}		
	}
	
	private void drawHiresChar(final int scrBaseCoordX, final int scrBaseCoordY, final int charAttr, final int scrChar) {
		int charRow;
		int bank;
		Color pxOn = null, pxColor = null;
		
		if ( (charAttr & attrGry) == 0)
			pxOn = pxColOn;		// paint a clear enabled pixel
		else
			pxOn = pxColGrey;	// paint a 'grey' enabled pixel									

		// define which font set to use...
		int offset = ((charAttr & 3) << 8) | scrChar;
		if (offset >= 0x300) {
			offset = hires1 + (scrChar << 3);	// "OZ" window font entries
			bank = bankHires1;
		} else {
			offset = hires0 + (offset << 3);	// PipeDream Map entries
			bank = bankHires0;
		}
			 			
		// render 8 pixel rows of character
		for(charRow=0; charRow<8; charRow++) {
			int pxOffset = 0;
		
			int charBits = blink.getByte(offset+charRow, bank);	// fetch current row of char
			if ( (charAttr & attrRev) == attrRev) {
				charBits = ~charBits;
			}
		
			// render 8 pixels wide...
			for(int bit=128; bit>0; bit>>>=1) {
				if ((charBits & bit) != 0)
					pxColor = pxOn; 
				else 
					pxColor = pxColOff;			// paint no pixel, just LCD background				
							
				grfx.setColor(pxColor);	
				grfx.drawPixel(scrBaseCoordX + pxOffset++, scrBaseCoordY + charRow);
			}			
		}
	}
    
	private TimerTask render10ms = null;
	
	private final class Render10ms extends TimerTask {
		/**
		 * Render Z88 Display each 10ms ...
		 * 
		 * @see java.lang.Runnable#run()
		 */
		public void run() {
			renderDisplay();
		}			
	}
		
	/**
	 * Stop the 10ms screen render polling. 
	 */
	public void stop() {
		if (render10ms != null) {
			render10ms.cancel();
		}
	}

	/**
	 * Start screen render polling which executes the run()
	 * method each 10ms. 
	 */
	public void start() {
		render10ms = new Render10ms();
		blink.getTimerDaemon().scheduleAtFixedRate(render10ms, 10, 10);
	}    
}
