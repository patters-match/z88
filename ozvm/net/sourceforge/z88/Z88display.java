package net.sourceforge.z88;

import java.util.TimerTask;

import gameframe.graphics.*;
import gameframe.input.*;
import gameframe.*;


public class Z88display 
{
	public static final int Z88SCREENWIDTH = 640;			// The Z88 display dimensions
	public static final int Z88SCREENHEIGHT = 64;
	private static final int SBRSIZE = 2048;				// Size of Screen Base File (bytes) 
	
	private static final int PXCOLON = 0xff020482;			// Trying to get as close as possibly to the LCD colors...
	private static final int PXCOLGREY = 0xff027182;
	private static final int PXCOLOFF = 0xffc0e0d7;
	
	private static final int attrBold = 0x80;	// Font attribute Bold Mask (LORES1)
	private static final int attrTiny = 0x40;	// Font attribute Tiny Mask (LORES1)
	private static final int attrHrs = 0x20;	// Font attribute Hires Mask (HIRES1)
	private static final int attrRev = 0x10;	// Font attribute Reverse Mask (LORES1 & HIRES1)
	private static final int attrFls = 0x08;	// Font attribute Flash Mask (LORES1 & HIRES1)
	private static final int attrGry = 0x04;	// Font attribute Grey Mask (all)
	private static final int attrUnd = 0x02;	// Font attribute Underline Mask (LORES1)
	private static final int attrNull = attrHrs | attrRev | attrGry;	// Null character (6x8 pixel blank)

	private Blink blink; 						// access to Blink hardware (memory, screen, keyboard, timers...)
	private TimerTask renderPerMs = null;

	private GraphicsEngine gfxe = null;
	private KeyboardDevice keyboard = null;
	
	private int[] displayMatrix = null;			// the actual low level pixel video data
	private BitmapData displayMap = null;		// The container for the low level pixel data
	private CloneableBitmap cbm = null;
	
	int lores0, lores1, hires0, hires1, sbr;
	int bankLores0, bankLores1, bankHires0, bankHires1, bankSbr;
	

    Z88display(Blink z88Blink) throws GameFrameException {        
		GameFrameSettings settings = new GameFrameSettings(); 
		settings.setTitle("Z88");
		settings.setRequestedGraphicsMode( new GraphicsMode(Z88SCREENWIDTH, Z88SCREENHEIGHT));
		settings.setScreenMode(GameFrameSettings.SCREENMODE_WINDOWED);	// later to GameFrameSettings.SCREENMODE_COMPONENT
		settings.setSplashScreenAllowed(false);

		GameFrame.init(settings);
		GameFrame.createGraphicsEngine();
		gfxe = GameFrame.getGraphicsEngine();
		GameFrame.createInputEngine(gfxe);

		InputEngine inputEngine = GameFrame.getInputEngine();
		keyboard = inputEngine.getDefaultKeyboardDevice();
		
		blink = z88Blink; // The Z88 Display needs to access the Blink hardware

		displayMatrix = new int[Z88SCREENWIDTH * Z88SCREENHEIGHT];
		displayMap = new BitmapData(displayMatrix, Z88SCREENWIDTH, Z88SCREENHEIGHT, Z88SCREENWIDTH);
    }

	
	/**
	 * Outside world can get access to keyboard input from this Z88 screen window.
	 * @return keyboard device
	 */	
	public KeyboardDevice getKeyboardDevice() {
		return keyboard;
	}
	
	
	/**
	 * The core Z88 Display renderer.
	 * This code is called each 10ms by a Timer
	 * 
	 * May be called manually (ie. to refresh window in an out-of-focus scenario).
	 */
	public void renderDisplay() throws GameFrameException {
				
		lores0 = blink.getPb0();	// Memory base address of 6x8 pixel user defined fonts.		
		lores1 = blink.getPb1();	// Memory base address of 6x8 pixel fonts (normal, bold, Tiny)
		hires0 = blink.getPb2();	// Memory base address of PipeDream Map (max 256x64 pixels)
		hires1 = blink.getPb3();	// Memory base address of 8x8 pixel fonts for OZ window
		sbr = blink.getSbr();		// Memory base address of Screen Base File (2K) 
		
		if (sbr == 0 | lores1 == 0 | lores0 == 0 | hires0 == 0 | hires1 == 0) return;		// LCD enabled, but the Screen Registers hasn't been setup yet...
						 		
		bankLores0 = lores0 >>> 16; lores0 &= 0x3FFF;  // convert to bank, offset
		bankLores1 = lores1 >>> 16; lores1 &= 0x3FFF;
		bankHires0 = hires0 >>> 16; hires0 &= 0x3FFF;
		bankHires1 = hires1 >>> 16; hires1 &= 0x3FFF;
		bankSbr = sbr >>> 16; sbr &= 0x3FFF;

		int scrBaseCoordX = 0, scrBaseCoordY = 0; 
		for (int scrRowOffset=0; scrRowOffset < SBRSIZE; scrRowOffset += 256) {			// scan 8 rows in screen file
			for (int lineCharOffset=0; lineCharOffset < 213; lineCharOffset += 2) {		// scan 106 2-byte control characters per row in screen file
				int sbrOffset = sbr + scrRowOffset + lineCharOffset;
				int scrChar = blink.getByte(sbrOffset, bankSbr);
				int scrCharAttr = blink.getByte(sbrOffset + 1, bankSbr);
								
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
						
			// when a complete row (8 pixels deep) has been rendered,
			// find out if pixels remain up to the 639'th pixel;
			// these need to get "blanked", before beginning with the next row...
			if (scrBaseCoordX < Z88SCREENWIDTH-1) {
				for(int y=scrBaseCoordY * Z88SCREENWIDTH; y < (scrBaseCoordY*Z88SCREENWIDTH + 8*Z88SCREENWIDTH); y+=Z88SCREENWIDTH) {		
					// render x blank pixels until right edge of screen...
					for(int bit = 0; bit < Z88SCREENWIDTH - scrBaseCoordX; bit++) {
						displayMatrix[y + scrBaseCoordX + bit] = PXCOLOFF;   
					}			
				}			 			
			}
			
			// finally, prepare for next pixel row base (downwards)...
			scrBaseCoordY += 8;
			scrBaseCoordX = 0;
		}
		
		if (cbm != null) cbm.finalize();			// release the bitmap to the system; it's been dumped to video previously and is now useless...			
		cbm = gfxe.createBitmap(displayMap, true);	// then, create a new bitmap with our screen pixel data
		cbm.drawTo(0,0); 							// and paint to back buffer
		gfxe.flip();								// finally, make back buffer visible...		
	}

	
	private void drawLoresChar(final int scrBaseCoordX, final int scrBaseCoordY, final int charAttr, final int scrChar) {
		int bank, bit, y; 
		int pxOn, pxColor;

		int offset = ((charAttr & 1) << 8) | scrChar;
		if (offset >= 0x1c0) { 
			offset = lores0 + (scrChar << 3);	// User defined graphics, default in RAM.0
			bank = bankLores0;
		}
		else {
			offset = lores1 + (offset << 3);	// Base fonts (tiny, bold), default in ROM.0 
			bank = bankLores1;
		}

		// define pixel colour; clear ON or GREY
		pxOn = ((charAttr & attrGry) == 0) ? PXCOLON : PXCOLGREY;

		// render 8 pixel rows of scrChar
		for(y = scrBaseCoordY * Z88SCREENWIDTH; y < (scrBaseCoordY*Z88SCREENWIDTH + Z88SCREENWIDTH*8); y+=Z88SCREENWIDTH) {		
			int charBits = blink.getByte(offset++, bank);	// fetch current pixel row of char
			if ( (charAttr & attrRev) == attrRev) charBits = ~charBits;
			
			int pxOffset = 0;
			// render 6 pixels wide...
			for(bit=32; bit>0; bit>>>=1) displayMatrix[y + scrBaseCoordX + pxOffset++] = ((charBits & bit) != 0) ? pxOn : PXCOLOFF;   
		}			 			

		// draw underline?
		if ( (charAttr & attrUnd) == attrUnd) {
			pxColor = pxOn;	 
			if ((charAttr & attrRev) == attrRev) pxColor = PXCOLOFF;	// paint "inverse" underline.. 

			y -= Z88SCREENWIDTH;	// back on 8th row...
			for(bit = 0; bit<8; bit++)  displayMatrix[y + scrBaseCoordX + bit] = pxColor;
		}		
	}

	
	private void drawHiresChar(final int scrBaseCoordX, final int scrBaseCoordY, final int charAttr, final int scrChar) {
		int offset, bank;
		int pxOn;
				
		// define which font set to use...
		offset = ((charAttr & 3) << 8) | scrChar;
		if (offset >= 0x300) {
			offset = hires1 + (scrChar << 3);	// "OZ" window font entries
			bank = bankHires1;
		} else {
			offset = hires0 + (offset << 3);	// PipeDream Map entries
			bank = bankHires0;
		}

		// define pixel colour; clear ON or GREY
		pxOn = ((charAttr & attrGry) == 0) ? PXCOLON : PXCOLGREY;

		// render 8 pixel rows of scrChar
		for(int y = scrBaseCoordY * Z88SCREENWIDTH; y < (scrBaseCoordY*Z88SCREENWIDTH + Z88SCREENWIDTH*8); y+=Z88SCREENWIDTH) {				
			int charBits = blink.getByte(offset++, bank);	// fetch current pixel row of char
			if ( (charAttr & attrRev) == attrRev) charBits = ~charBits;
			
			int pxOffset = 0;
			// render 8 pixels wide...
			for(int bit=128; bit>0; bit>>>=1) displayMatrix[y + scrBaseCoordX + pxOffset++] = ((charBits & bit) != 0) ? pxOn : PXCOLOFF;   
		}			 			
	}
    
    private void flashCounter() {
    	
    }
	
	private final class RenderPerMs extends TimerTask {
		/**
		 * Render Z88 Display each 10ms ...
		 * 
		 * @see java.lang.Runnable#run()
		 */
		public void run() {
			try {
				flashCounter();		// update cursor flash and ordinary flash counters 
				renderDisplay();	// then render display...
			} catch (GameFrameException e) {}
		}			
	}
		

	/**
	 * Stop the 10ms screen render polling. 
	 */
	public void stop() {
		if (renderPerMs != null) {
			renderPerMs.cancel();
		}
	}


	/**
	 * Start screen render polling which executes the run()
	 * method each X ms. 
	 */
	public void start() {
		renderPerMs = new RenderPerMs();
		blink.getTimerDaemon().scheduleAtFixedRate(renderPerMs, 10, 10);
	}    
}
