package net.sourceforge.z88;

import java.awt.Color;
import java.util.TimerTask;

import gameframe.graphics.*;
import gameframe.core.*;
import gameframe.*;

public class Z88display extends ApplicationAppletBase
{
	private static final int z88ScreenWidth = 640;			// The beasts display dimensions
	private static final int z88ScreenHeight = 64;
	
	private static final Color pxColOn = new Color(2,4,130,255);		// #020482, Trying to get as close as possibly to the LCD colors...
	private static final Color pxColGrey = new Color(2,113,130,255);	// #027182
	private static final Color pxColOff = new Color(192,224,215,255);	// #C0E0D7
	
	private static final int attrTiny = 0x80;	// Font attribute Tiny Mask (LORES1)
	private static final int attrBold = 0x40;	// Font attribute Bold Mask (LORES1)
	private static final int attrHrs = 0x20;	// Font attribute Hires Mask (HIRES1)
	private static final int attrRev = 0x10;	// Font attribute Reverse Mask (LORES1 & HIRES1)
	private static final int attrFls = 0x08;	// Font attribute Flash Mask (LORES1 & HIRES1)
	private static final int attrGry = 0x04;	// Font attribute Grey Mask (all)
	private static final int attrUnd = 0x02;	// Font attribute Underline Mask (LORES1)

	private static final int[] cpySBR = new int[2048];		// copy of rendered screen (internal SBR compact format)
	private final Blink blink;								// access to Blink hardware.

	private boolean initError = false;
	GraphicsEngine gfxe = null;
	GFGraphics grfx = null; 

	int lores0, lores1, hires0, hires1, sbr;
	int bankLores0, bankLores1, bankHires0, bankHires1, bankSbr;
	
    Z88display(Blink z88Blink) throws GameFrameException {
        super();
        
		init();
		if (initError == true) {
			throw new GameFrameException("Couldn't initialize GF4J"); 
		}
		
		blink = z88Blink; // The Z88 Display needs to access the Blink hardware		
    }
	
    /**
     * Sets up the settings used by this program to the given
     * <code>GameFrameSettings</code>.
     * 
     * @param settings The settings object that is configured.
     */
    protected void setSettings(GameFrameSettings settings) {
        settings.setTitle("Z88");
        settings.setRequestedGraphicsMode( new GraphicsMode(z88ScreenWidth, z88ScreenHeight, GraphicsMode.BITDEPTH_16BITS));
        settings.setScreenMode(GameFrameSettings.SCREENMODE_WINDOWED);	// later to GameFrameSettings.SCREENMODE_COMPONENT 
        settings.setSplashScreenAllowed(false);
    }

    /**
     * Initializes the GF4J library.
     * Z88 only needs Graphics and input.
     */
    public void init() {
        super.init();

		try {			
			GameFrame.createGraphicsEngine();		// Later as GameFrame.createGraphicsEngine(Component arg0);
			gfxe = GameFrame.getGraphicsEngine();
			grfx = gfxe.getBackbufferGraphics();	// for now, the Pure Java simple graphics renderer will be used.
													// (far from the fastest solution, but it works!)
		} catch (GameFrameException e) {
			initError = true;
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
		 		
		bankLores0 = lores0 >>> 16; lores0 &= 0x3FFF;  // convert to bank, offset
		bankLores1 = lores1 >>> 16; lores1 &= 0x3FFF;
		bankHires0 = hires0 >>> 16; hires0 &= 0x3FFF;
		bankHires1 = hires1 >>> 16; hires1 &= 0x3FFF;
		bankSbr = sbr >>> 16; sbr &= 0x3FFF;

		int scrBaseCoordX = 0, scrBaseCoordY = 0; 
		for (int scrRowOffset=0; scrRowOffset < 2048; scrRowOffset += 256) {			// scan 8 rows in screen file
			for (int lineCharOffset=0; lineCharOffset < 216; lineCharOffset += 2) {		// scan 108 2-byte control characters per row in screen file
				int sbrOffset = sbr + scrRowOffset + lineCharOffset;
				int scrChar = blink.getByte(sbrOffset, bankSbr);
				int scrCharAttr = blink.getByte(sbrOffset + 1, bankSbr);
								
				if ( (scrChar != cpySBR[scrRowOffset + lineCharOffset]) | 
				     (scrCharAttr != cpySBR[scrRowOffset + lineCharOffset + 1]) ) {
					// this char has been updated (by looking at the last rendered copy)
					// so, render the new one...
					cpySBR[scrRowOffset + lineCharOffset] = scrChar;		// update new char in render copy
					cpySBR[scrRowOffset + lineCharOffset + 1] = scrCharAttr; 

				}
			}
			
			// when a line complete row (8 pixels deep) has been rendered,
			// find out if there's some pixels left up to the 639'th pixel;
			// these need to get "blanked", before beginning with the next row...
			
			// finally, prepare for next pixel row base (downwards)...
			scrBaseCoordY += 8;
		}
		
		// grfx.setColor(color[h]);
		// grfx.drawPixel(w,h);

		gfxe.flip();
	}
	
    /**
     * NB: This method is a mandatory implementation (by inheritance). 
     * OZvm doesn't use it, as it only updates the screen indirectly.
     */
    protected void gameMain() {}
    
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
