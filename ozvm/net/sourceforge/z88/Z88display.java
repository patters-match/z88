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

	private static final int[] cpySBR = new int[2048];		// copy of rendered screen (internal SBR compact format)
	private final Blink blink;								// access to Blink hardware.

	private boolean initError = false;
	GraphicsEngine gfxe = null;
	GFGraphics grfx = null; 

	int lores0, lores1, hires0, hires1, sbr;
	int bankLores0, bankLores1, bankHires0, bankHires1, bankSbr;
	
    Z88display(Blink z88Blink) throws GameFrameException {
        super();
        
		// When we are executed as an application we need to call
		// the init() method.
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
		lores1 = blink.getPb1();	// Memory base address of 6x8 pixel fonts.
		hires0 = blink.getPb2();	// Memory base address of PipeDream Map (max 256x64 pixels)
		hires1 = blink.getPb3();	// Memory base address of 8x8 pixel fonts for OZ window
		sbr = blink.getSbr();		// Memory base address of Screen Base File (2K) 
		
		bankLores0 = lores0 >> 16; lores0 &= 0x3FFF;  // convert to bank, offset
		bankLores1 = lores1 >> 16; lores1 &= 0x3FFF;
		bankHires0 = hires0 >> 16; hires0 &= 0x3FFF;
		bankHires1 = hires1 >> 16; hires1 &= 0x3FFF;
		bankSbr = sbr >> 16; sbr &= 0x3FFF;
		
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
