package net.sourceforge.z88;

import java.util.TimerTask;

import gameframe.graphics.*;
import gameframe.*;

/**
 * The display renderer of the Z88 virtual machine, 
 * called each 5ms, 10ms, 25ms or 50ms, depending on speed of JVM.<br>
 * 
 * $Id$
 * @author <A HREF="mailto:gstrube@tiscali.dk">Gunther Strube</A>
 */
public class Z88display 
{
	public static final int Z88SCREENWIDTH = 640;					// The Z88 display dimensions
	public static final int Z88SCREENHEIGHT = 64;
	private static final int SBRSIZE = 2048;						// Size of Screen Base File (bytes)
	private static final int fps[] = new int[] {5,10,25,50};		// runtime selection of Z88 screen frames per second
	private static final int fcd[] = new int[] {3,7,18,35};			// flash cursor duration frame counter 
	
	private static final int PXCOLON = 0xff461B7D;			// Trying to get as close as possibly to the LCD colors...
	private static final int PXCOLGREY = 0xff90B0A7;
	private static final int PXCOLOFF = 0xffD2E0B9;
	
	private static final int attrBold = 0x80;	// Font attribute Bold Mask (LORES1)
	private static final int attrTiny = 0x40;	// Font attribute Tiny Mask (LORES1)
	private static final int attrHrs = 0x20;	// Font attribute Hires Mask (HIRES1)
	private static final int attrRev = 0x10;	// Font attribute Reverse Mask (LORES1 & HIRES1)
	private static final int attrFls = 0x08;	// Font attribute Flash Mask (LORES1 & HIRES1)
	private static final int attrGry = 0x04;	// Font attribute Grey Mask (all)
	private static final int attrUnd = 0x02;	// Font attribute Underline Mask (LORES1)
	private static final int attrNull = attrHrs | attrRev | attrGry;	// Null character (6x8 pixel blank)
	private static final int attrCursor = attrHrs | attrRev | attrFls;	// Lores cursor (6x8 pixel inverse flashing)

	private static int cursorFlashCounter = 0;
	private static int curRenderSpeedIndex = 0;	// points at the current framerate group 
	private static int frameCounter = 0;
	private static long renderTimeTotal = 0;	// accumulated rendering speed during 3 seconds
    
	private Blink blink = null;					// access to Blink hardware (memory, screen, keyboard, timers...)
	private RenderPerMs renderPerMs = null;
	private RenderSupervisor renderSupervisor = null;
	
    private boolean renderRunning = false;
	private GraphicsEngine gfxe = null;
        
    private boolean cursorInverse = true;       // start cursor flash as dark, 
    private boolean flashTextEmpty = false;     // start text flash as dark, ie. text looks normal for 1 sec.
    
	private int[] displayMatrix = null;			// the actual low level pixel video data
	private BitmapData displayMap = null;		// The container for the low level pixel data
	private CloneableBitmap cbm = null;
	
	int lores0, lores1, hires0, hires1, sbr;
	int bankLores0, bankLores1, bankHires0, bankHires1, bankSbr;
	

    Z88display(Blink z88Blink, java.awt.Canvas canvas) throws GameFrameException {
		GameFrameSettings settings = new GameFrameSettings(); 
		settings.setTitle("Z88");
		settings.setRequestedGraphicsMode( new GraphicsMode(Z88SCREENWIDTH, Z88SCREENHEIGHT));
		settings.setScreenMode(GameFrameSettings.SCREENMODE_COMPONENT);
		settings.setSplashScreenAllowed(false);

		GameFrame.init(settings);
		GameFrame.createGraphicsEngine(canvas);
		gfxe = GameFrame.getGraphicsEngine();
        gfxe.addFocusListener(new Z88DisplayFocusListener());
		
		blink = z88Blink; // The Z88 Display needs to access the Blink hardware...

		displayMatrix = new int[Z88SCREENWIDTH * Z88SCREENHEIGHT];
		displayMap = new BitmapData(displayMatrix, Z88SCREENWIDTH, Z88SCREENHEIGHT, Z88SCREENWIDTH);
        
        renderRunning = false;
    }
	
	
	/**
	 * The core Z88 Display renderer. This code is called by RenderPerMs.<br>
	 * May be called manually (ie. to refresh window in an out-of-focus scenario).
	 */
	public void renderDisplay() throws GameFrameException {				
		lores0 = blink.getBlinkPb0Address();	// Memory base address of 6x8 pixel user defined fonts.		
		lores1 = blink.getBlinkPb1Address();	// Memory base address of 6x8 pixel fonts (normal, bold, Tiny)
		hires0 = blink.getBlinkPb2Address();	// Memory base address of PipeDream Map (max 256x64 pixels)
		hires1 = blink.getBlinkPb3Address();	// Memory base address of 8x8 pixel fonts for OZ window
		sbr = blink.getBlinkSbrAddress();		// Memory base address of Screen Base File (2K) 
		
		// LCD enabled, but one of the Screen Registers hasn't been setup yet...
		if (sbr == 0 | lores1 == 0 | lores0 == 0 | hires0 == 0 | hires1 == 0) return;		

		long timeMs = System.currentTimeMillis();
								 		
		bankLores0 = lores0 >>> 16; lores0 &= 0x3FFF;  // convert to bank, offset
		bankLores1 = lores1 >>> 16; lores1 &= 0x3FFF;
		bankHires0 = hires0 >>> 16; hires0 &= 0x3FFF;
		bankHires1 = hires1 >>> 16; hires1 &= 0x3FFF;
		bankSbr = sbr >>> 16; sbr &= 0x3FFF;

		int scrBaseCoordX = 0, scrBaseCoordY = 0; 
		for (int scrRowOffset=0; scrRowOffset < SBRSIZE; scrRowOffset += 256) {
			// scan 8 rows in screen file			
			for (int lineCharOffset=0; lineCharOffset < 213; lineCharOffset += 2) {
				// scan 106 2-byte control characters per row in screen file
				int sbrOffset = sbr + scrRowOffset + lineCharOffset;
				int scrChar = blink.getByte(sbrOffset, bankSbr);
				int scrCharAttr = blink.getByte(sbrOffset + 1, bankSbr);
								
				if ((scrCharAttr & attrHrs) == 0) {						
					// Draw a LORES1 character (6x8 pixel matrix), char offset into LORES1 is 9 bits...
					drawLoresChar(scrBaseCoordX, scrBaseCoordY, scrCharAttr, scrChar);
					scrBaseCoordX += 6;		
				} else {
					if ((scrCharAttr & attrCursor) == attrCursor) {
                        drawLoresCursor(scrBaseCoordX, scrBaseCoordY, scrCharAttr, scrChar);
                        scrBaseCoordX += 6;		
                    } else {
                        if ((scrCharAttr & attrNull) != attrNull) {
                            // Draw a HIRES character (PipeDream MAP / OZ window fonts)
                            drawHiresChar(scrBaseCoordX, scrBaseCoordY, scrCharAttr, scrChar);
                            scrBaseCoordX += 8;							
                        }
					}
				}                
			}
						
			// when a complete row (8 pixels deep) has been rendered,
			// find out if pixels remain up to the 639'th pixel;
			// these need to get "blanked", before beginning with the next row...
			if (scrBaseCoordX < Z88SCREENWIDTH-1) {
				for(int y=scrBaseCoordY * Z88SCREENWIDTH; y < (scrBaseCoordY*Z88SCREENWIDTH + 8*Z88SCREENWIDTH); y+=Z88SCREENWIDTH) {		
					// render x blank pixels until right edge of screen...
					for(int bit = 0; bit < (Z88SCREENWIDTH - scrBaseCoordX); bit++) {
						displayMatrix[y + scrBaseCoordX + bit] = PXCOLOFF;   
					}			
				}			 			
			}
			
			// finally, prepare for next pixel row base (downwards)...
			scrBaseCoordY += 8;
			scrBaseCoordX = 0;
		}
		
		if (cbm != null) cbm.finalize();			// release the bitmap to the system; it's been dumped to video previously and is now useless...
		cbm = gfxe.createBitmap(displayMap, true); 	// then, create a new bitmap with our screen pixel data
		cbm.drawTo(0,0);                          	// and paint to back buffer
		gfxe.flip();								// finally, make back buffer visible...
		
		// remember the time it took to render the complete screen, accumulated
		renderTimeTotal += System.currentTimeMillis() - timeMs;	
	}


    /**
     * Draw the character at current position, and overlay with flashing cursor.<br>
     * In cursor mode, neither hardware underline nor grey is functional.
     * Only inverse video flashing on pixel data of character.
	 *   
	 * @param scrBaseCoordX pixel column (0-639)
	 * @param scrBaseCoordY pixel row coordinate (0-63)
	 * @param charAttr the Screen File attribute fo the character (flashing, reverse, tiny, bold)
	 * @param scrChar the offset into the LORES character set (top bits in charAttr). 
     */
	private void drawLoresCursor(final int scrBaseCoordX, final int scrBaseCoordY, final int charAttr, final int scrChar) {
        int bank, bit, y; 

        // safety: if 640 - X coordinate is less than 6 pixels, then abort...
        if (Z88SCREENWIDTH - scrBaseCoordX < 6) return;
        
		int offset = ((charAttr & 1) << 8) | scrChar;
		if (offset >= 0x1c0) { 
			offset = lores0 + ((scrChar & 0x3F) << 3); // User defined graphics
			bank = bankLores0;
		}
		else {
			offset = lores1 + (offset << 3);	// Base fonts (tiny, bold), default in ROM.0 
			bank = bankLores1;
		}

		// render 8 pixel rows of 6 pixel wide scrChar
		for(y = scrBaseCoordY * Z88SCREENWIDTH; y < (scrBaseCoordY*Z88SCREENWIDTH + Z88SCREENWIDTH*8); y+=Z88SCREENWIDTH) {
			int charBits = blink.getByte(offset++, bank);	// fetch current pixel row of char
			if ( cursorInverse == true) charBits = ~charBits;
            
			// render 6 pixels wide...
            int pxOffset=0;
			for(bit=32; bit>0; bit>>>=1) {
                displayMatrix[y + scrBaseCoordX + pxOffset++] = ((charBits & bit) != 0) ? PXCOLON : PXCOLOFF;
            }
        }
	}


	/**
	 * Draw a LORES character (6x8 pixel matrix) at pixel position (scrBaseCoordX,scrBaseCoordY).<br>
	 *   
	 * @param scrBaseCoordX pixel column (0-639)
	 * @param scrBaseCoordY pixel row coordinate (0-63)
	 * @param charAttr the Screen File attribute fo the character (flashing, reverse, tiny, bold, underline, grey)
	 * @param scrChar the offset into the LORES character set (top bits in charAttr). 
	 */
	private void drawLoresChar(final int scrBaseCoordX, final int scrBaseCoordY, final int charAttr, final int scrChar) {
        int bank, bit, y; 
		int pxOn, pxColor;

        // safety: if 640 - X coordinate is less than 6 pixels, then abort...
        if (Z88SCREENWIDTH - scrBaseCoordX < 6) return;
        
        if ( ((charAttr & attrFls) == attrFls) && flashTextEmpty == true) {
            // render 8 pixel rows of 6 empty pixels, if flashing is enabled and is currently "empty"..
            for(y = scrBaseCoordY * Z88SCREENWIDTH; y < (scrBaseCoordY*Z88SCREENWIDTH + Z88SCREENWIDTH*8); y+=Z88SCREENWIDTH) {
                // render 6 pixels wide...
                for(bit=0; bit<6; bit++) displayMatrix[y + scrBaseCoordX + bit] = PXCOLOFF;
            }
            
            return; // char render completed...
        } 
        
        // Main draw LORES...
        // define pixel colour; clear ON or GREY
        pxOn = ((charAttr & attrGry) == 0) ? PXCOLON : PXCOLGREY;

        int offset = ((charAttr & 1) << 8) | scrChar;
        if (offset >= 0x1c0) { 
            offset = lores0 + ((scrChar & 0x3F) << 3); // User defined graphics
            bank = bankLores0;
        }
        else {
            offset = lores1 + (offset << 3);	// Base fonts (tiny, bold), default in ROM.0 
            bank = bankLores1;
        }

        // render 8 pixel rows of 6 pixel wide scrChar
        for(y = scrBaseCoordY * Z88SCREENWIDTH; y < (scrBaseCoordY*Z88SCREENWIDTH + Z88SCREENWIDTH*8); y+=Z88SCREENWIDTH) {
            int charBits = blink.getByte(offset++, bank);	// fetch current pixel row of char
            if ( (charAttr & attrRev) == attrRev) charBits = ~charBits;

            // render 6 pixels wide...
            int pxOffset=0;
            for(bit=32; bit>0; bit>>>=1) {
                displayMatrix[y + scrBaseCoordX + pxOffset++] = ((charBits & bit) != 0) ? pxOn : PXCOLOFF;   
            }
        }			 			

        // draw underline?
        if ( (charAttr & attrUnd) == attrUnd) {
            pxColor = pxOn;	 
            if ((charAttr & attrRev) == attrRev) pxColor = PXCOLOFF;	// paint "inverse" underline.. 

            y -= Z88SCREENWIDTH;	// back on 8th row...
            for(bit = 0; bit<6; bit++)  displayMatrix[y + scrBaseCoordX + bit] = pxColor;
        }		
	}

	
	/**
	 * Draw a HIRES character (8x8 pixel matrix) at pixel position (scrBaseCoordX,scrBaseCoordY).<br>
	 *   
	 * @param scrBaseCoordX pixel column (0-639)
	 * @param scrBaseCoordY pixel row coordinate (0-63)
	 * @param charAttr the Screen File attribute fo the character (flashing, grey)
	 * @param scrChar the offset into the HIRES character set (top bits in charAttr). 
	 */
	private void drawHiresChar(final int scrBaseCoordX, final int scrBaseCoordY, final int charAttr, final int scrChar) {
		int offset, bank;
		int pxOn, bit;

        // safety: if 640 - X coordinate is less than 8 pixels, then abort...
        if (Z88SCREENWIDTH - scrBaseCoordX < 8) return;

        if ( ((charAttr & attrFls) == attrFls) && flashTextEmpty == true) {
            // render 8 pixel rows of 8 empty pixels, if flashing is enabled and is currently "empty"..
            for(int y = scrBaseCoordY * Z88SCREENWIDTH; y < (scrBaseCoordY*Z88SCREENWIDTH + Z88SCREENWIDTH*8); y+=Z88SCREENWIDTH) {
                // render 8 pixels wide...
                for(bit=0; bit<8; bit++) displayMatrix[y + scrBaseCoordX + bit] = PXCOLOFF;   
            }			 			
            
            return;
        }
        
        // Main draw HIRES...
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

        // render 8 pixel rows of 8 pixel wide scrChar
        for(int y = scrBaseCoordY * Z88SCREENWIDTH; y < (scrBaseCoordY*Z88SCREENWIDTH + Z88SCREENWIDTH*8); y+=Z88SCREENWIDTH) {				
            int charBits = blink.getByte(offset++, bank);	// fetch current pixel row of char
            if ( (charAttr & attrRev) == attrRev) charBits = ~charBits;

            int pxOffset = 0;
            // render 8 pixels wide...
            for(bit=128; bit>0; bit>>>=1) displayMatrix[y + scrBaseCoordX + pxOffset++] = ((charBits & bit) != 0) ? pxOn : PXCOLOFF;   
        }
	}
    
    /**
     * Keep flash counters updated according to FPS settings.<br>
     * Ordinary text flashing changes state each second (text appears one sec. then disappears one sec).
     * Cursor flash inverts 6x8 LORES char 70% of 1 sec, remaining 30% renders the char as normal.
     */
    private void flashCounter() {
        if (frameCounter++ > fps[curRenderSpeedIndex]) {   // 1 second has passed
            frameCounter = 0;                   
            flashTextEmpty = !flashTextEmpty;   // invert current text flashing mode
        }
        
        if (frameCounter < fcd[curRenderSpeedIndex]) 
            cursorInverse = true;               // most of the time, cursor is black
        else
            cursorInverse = false;              // rest of the time, cursor is invisible (normal text)
    }

	/**
	 * A focus listener, hooked into the GameFrame Window, so that we can refresh 
	 * the Z88 screen during focus lost/gained events. 
	 */    
    private final class Z88DisplayFocusListener implements java.awt.event.FocusListener {
        public void focusGained(java.awt.event.FocusEvent e) {
            if (renderRunning == false) {
                // The Z88 screen rendering is disabled, so draw the screen manually
                try {
                    renderDisplay();
                } catch(GameFrameException g) {}
            }
        }
        
        public void focusLost(java.awt.event.FocusEvent e) {
            if (renderRunning == false) {
                // The Z88 screen rendering is disabled, so draw the screen manually
                try {
                    renderDisplay();
                } catch(GameFrameException g) {}
            }
        }    
    }

    
	/**
	 * Render Z88 Display each X ms (runtime adjusted)...
	 */
	private class RenderPerMs extends TimerTask {
		public void run() {
			try {
				flashCounter();		// update cursor flash and ordinary flash counters 
				renderDisplay();	// then render display...
			} catch (GameFrameException e) {}
		}			
	}
		

	/**
	 * Stop the fps Z88 screen renderer (and supervisor). 
	 */
	public void stop() {
		if (renderPerMs != null) {
			renderPerMs.cancel();
		}
		if (renderSupervisor != null) {
			renderSupervisor.cancel();
		}
        renderRunning = false;
	}


	/**
	 * Start fps Z88 screen renderer (and supervisor). 
	 */
	public void start() {
        if (renderRunning == false) {
            renderPerMs = new RenderPerMs();
            blink.getTimerDaemon().scheduleAtFixedRate(renderPerMs, 0, 1000/fps[curRenderSpeedIndex]);

			renderTimeTotal = 0;
			renderSupervisor = new RenderSupervisor();
			blink.getTimerDaemon().scheduleAtFixedRate(renderSupervisor, 3000, 3000);	// poll every 3rd second
			renderRunning = true;
        }
	}    
		

	/**
	 * The Z88 Display Render supervisor.<br>
	 * Called each 3 seconds, it monitors the rendering speed, and adjusts the 
	 * framerate, if it takes longer or faster to render than the current fps timing.
	 */
	private class RenderSupervisor extends TimerTask {		
		public void run() {
			int avgRenderSpeed = (int) renderTimeTotal / fps[curRenderSpeedIndex]; 
			if ( avgRenderSpeed * 1.4 > 1000/fps[curRenderSpeedIndex] ) {
				// current average render speed and safety margin takes longer than the time interval
				// between frames. Choose a one-step lower frame rate, if possible...
				if (curRenderSpeedIndex > 0) {
					curRenderSpeedIndex--;	// choose a lower framerate, then restart screen rendering...
					stop();			 
					start();
					return;
				}
			}
			if ( avgRenderSpeed * 1.4 < 1000/fps[curRenderSpeedIndex] ) {
				// current average render speed and safety margin is faster than the time interval
				// between frames. Choose a one-step higher frame rate, if possible...
				if (curRenderSpeedIndex < fps.length-1) {
					curRenderSpeedIndex++;	// choose a higher framerate, then restart screen rendering...
					stop();			 
					start();
					return;			 
				}
			}
			
			// no change in framerate, clear accumulated framerate...
			renderTimeTotal = 0;
		}
	}
}
