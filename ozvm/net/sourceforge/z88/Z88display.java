package net.sourceforge.z88;

import java.awt.BorderLayout;
import java.awt.Dimension;
import java.awt.Graphics2D;
import java.awt.GraphicsConfiguration;
import java.awt.Image;
import java.awt.RenderingHints;
import java.awt.Toolkit;
import java.awt.image.BufferedImage;
import java.awt.image.MemoryImageSource;
import java.io.File;
import java.io.IOException;
import java.util.Hashtable;
import java.util.TimerTask;
import javax.swing.JPanel;

/**
 * The display renderer of the Z88 virtual machine,
 * called each 5ms, 10ms, 25ms or 50ms, depending on speed of JVM.<br>
 *
 * $Id$
 * @author <A HREF="mailto:gstrube@tiscali.dk">Gunther Strube</A>
 */
public class Z88display extends JPanel {
	public static final int Z88SCREENWIDTH = 640; // The Z88 display dimensions
	public static final int Z88SCREENHEIGHT = 64;

	/** The image that is shown on the screen upon repaint. */
	private BufferedImage frontBufferImg = null;

	/** The graphics context of the image shown on the screen. */
	private Graphics2D frontBufferGrfx = null;

	/** The offscreen image used for double buffering. */
	private BufferedImage backBufferImg = null;
	/** The graphics context of the current offscreen buffer. */
	private Graphics2D backBufferGrfx = null;

	/** The graphics context of the display. */
	private Graphics2D displayGrfx = null;

	/** The current display graphics configuration. */
	private GraphicsConfiguration displayGrfxConfig = null;

	/** Rendering hints for optimized display of graphics */
	private Hashtable grfxSettings = null;

	/** The image (based on pixel data array) to be rendered onto Swing Component */
	private Image image = null;

	/** Screen dump counter */
	private int scrdumpCounter = 0;
	
	private static final int SBRSIZE = 2048;
	// Size of Screen Base File (bytes)
	private static final int fps[] = new int[] { 5, 10, 25, 50 };
	// runtime selection of Z88 screen frames per second
	private static final int fcd[] = new int[] { 3, 7, 18, 35 };
	// flash cursor duration frame counter

	private static final int PXCOLON = 0xff461B7D;
	// Trying to get as close as possibly to the LCD colors...
	private static final int PXCOLGREY = 0xff90B0A7;
	private static final int PXCOLOFF = 0xffD2E0B9;		// Empty pixel, when screen is switched on
	private static final int PXCOLSCROFF = 0xffE0E0E0;	// Empty pixel, screen is switched off	

	private static final int attrBold = 0x80;
	// Font attribute Bold Mask (LORES1)
	private static final int attrTiny = 0x40;
	// Font attribute Tiny Mask (LORES1)
	private static final int attrHrs = 0x20;
	// Font attribute Hires Mask (HIRES1)
	private static final int attrRev = 0x10;
	// Font attribute Reverse Mask (LORES1 & HIRES1)
	private static final int attrFls = 0x08;
	// Font attribute Flash Mask (LORES1 & HIRES1)
	private static final int attrGry = 0x04; // Font attribute Grey Mask (all)
	private static final int attrUnd = 0x02;
	// Font attribute Underline Mask (LORES1)
	private static final int attrNull = attrHrs | attrRev | attrGry;
	// Null character (6x8 pixel blank)
	private static final int attrCursor = attrHrs | attrRev | attrFls;
	// Lores cursor (6x8 pixel inverse flashing)

	private static int cursorFlashCounter = 0;
	private static int curRenderSpeedIndex = 0;
	// points at the current framerate group
	private static int frameCounter = 0;
	private static long renderTimeTotal = 0;
	// accumulated rendering speed during 3 seconds

	private Blink blink = null;
	// access to Blink hardware (memory, screen, keyboard, timers...)
	private RenderPerMs renderPerMs = null;
	private RenderSupervisor renderSupervisor = null;

	private boolean renderRunning = false;

	private boolean cursorInverse = true; // start cursor flash as dark,
	private boolean flashTextEmpty = false;
	// start text flash as dark, ie. text looks normal for 1 sec.

	private int[] displayMatrix = null;
	// the actual low level pixel video data

	int lores0, lores1, hires0, hires1, sbr;
	int bankLores0, bankLores1, bankHires0, bankHires1, bankSbr;

	Z88display() {
		super();

		displayMatrix = new int[Z88SCREENWIDTH * Z88SCREENHEIGHT];
		renderRunning = false;

		this.setPreferredSize(new Dimension(640, 64));
		this.setLayout(new BorderLayout());
		this.setToolTipText("Use F12 to get keyboard focus to this window.");
		this.setFocusable(true);

		this.setDoubleBuffered(false);
	}

	public void init() {
		// Setup the used Graphics rendering hints
		grfxSettings = new Hashtable();
		grfxSettings.put(
			RenderingHints.KEY_ALPHA_INTERPOLATION,
			RenderingHints.VALUE_ALPHA_INTERPOLATION_SPEED);
		grfxSettings.put(
			RenderingHints.KEY_ANTIALIASING,
			RenderingHints.VALUE_ANTIALIAS_OFF);
		grfxSettings.put(
			RenderingHints.KEY_COLOR_RENDERING,
			RenderingHints.VALUE_COLOR_RENDER_SPEED);
		grfxSettings.put(
			RenderingHints.KEY_DITHERING,
			RenderingHints.VALUE_DITHER_DISABLE);
		grfxSettings.put(
			RenderingHints.KEY_FRACTIONALMETRICS,
			RenderingHints.VALUE_FRACTIONALMETRICS_OFF);
		grfxSettings.put(
			RenderingHints.KEY_INTERPOLATION,
			RenderingHints.VALUE_INTERPOLATION_NEAREST_NEIGHBOR);
		grfxSettings.put(
			RenderingHints.KEY_RENDERING,
			RenderingHints.VALUE_RENDER_SPEED);
		grfxSettings.put(
			RenderingHints.KEY_TEXT_ANTIALIASING,
			RenderingHints.VALUE_TEXT_ANTIALIAS_OFF);

		displayGrfx = (Graphics2D) this.getGraphics();
		displayGrfx.setRenderingHints(grfxSettings);
		displayGrfx.setClip(0, 0, Z88SCREENWIDTH, Z88SCREENHEIGHT);

		displayGrfxConfig = displayGrfx.getDeviceConfiguration();

		// Create the front and back buffers
		backBufferImg =
			displayGrfxConfig.createCompatibleImage(
				Z88SCREENWIDTH,
				Z88SCREENHEIGHT);
		frontBufferImg =
			displayGrfxConfig.createCompatibleImage(
				Z88SCREENWIDTH,
				Z88SCREENHEIGHT);

		// Get the graphics contexts of front and back buffers
		backBufferGrfx = (Graphics2D) backBufferImg.getGraphics();
		frontBufferGrfx = (Graphics2D) frontBufferImg.getGraphics();

		// Set the rendering settings of the graphics contexts
		backBufferGrfx.setRenderingHints(grfxSettings);
		frontBufferGrfx.setRenderingHints(grfxSettings);
	}

	public void setBlink(Blink bl) {
		// The Z88 Display needs to access the Blink hardware...
		blink = bl;
	}
	
	/**
	 * The core Z88 Display renderer. This code is called by RenderPerMs.<br>
	 * called manually (ie. to refresh window during focus and paint events).
	 */
	public void renderDisplay() {
		lores0 = blink.getBlinkPb0Address();
		// Memory base address of 6x8 pixel user defined fonts.
		lores1 = blink.getBlinkPb1Address();
		// Memory base address of 6x8 pixel fonts (normal, bold, Tiny)
		hires0 = blink.getBlinkPb2Address();
		// Memory base address of PipeDream Map (max 256x64 pixels)
		hires1 = blink.getBlinkPb3Address();
		// Memory base address of 8x8 pixel fonts for OZ window
		sbr = blink.getBlinkSbrAddress();
		// Memory base address of Screen Base File (2K)

		if ((blink.getBlinkCom() & Blink.BM_COMLCDON) != 0) {
			if (sbr == 0 | lores1 == 0 | lores0 == 0 | hires0 == 0 | hires1 == 0) {
				// Don't render frame if one of the Screen Registers hasn't been setup yet...
				renderNoScreenFrame();  
			} else {
				// screen is ON and Blink registers are all pointing to font areas...
				renderScreenFrame();
			}
		} else {
			// Screen has been switched off (usually by using the SHIFT keys) 
			renderNoScreenFrame();
		}
	}

	/**
	 * Grab current screen frame pixel matrix and write it to a file.
	 * 
	 * @param filename
	 * @param imgFormat formats supported by javax.imageio.ImageIO.write 
	 */
	public void grabScreenFrame() {
		// create image, based on pixel array colours
		BufferedImage bi = new BufferedImage(Z88SCREENWIDTH, Z88SCREENHEIGHT, BufferedImage.TYPE_4BYTE_ABGR);
		bi.setRGB(0, 0, Z88SCREENWIDTH, Z88SCREENHEIGHT, displayMatrix, 0, Z88SCREENWIDTH);
					
		File file = new File("z88screen" + scrdumpCounter++ + ".png");
		try {
			javax.imageio.ImageIO.write(bi, "PNG", file);
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}			
	}
	
	private void renderNoScreenFrame() {
		long timeMs = System.currentTimeMillis();

		for (int x = 0; x < (Z88SCREENHEIGHT * Z88SCREENWIDTH); x++) displayMatrix[x] = PXCOLSCROFF;

		// create an image, based on pixel matrix, and render it via double buffering to 
		// the Awt/Swing component 
		renderImageToComponent();

		// remember the time it took to render the complete screen, accumulated
		renderTimeTotal += System.currentTimeMillis() - timeMs;
	}
			
	private void renderScreenFrame() {
		long timeMs = System.currentTimeMillis();

		bankLores0 = lores0 >>> 16;
		lores0 &= 0x3FFF; // convert to bank, offset
		bankLores1 = lores1 >>> 16;
		lores1 &= 0x3FFF;
		bankHires0 = hires0 >>> 16;
		hires0 &= 0x3FFF;
		bankHires1 = hires1 >>> 16;
		hires1 &= 0x3FFF;
		bankSbr = sbr >>> 16;
		sbr &= 0x3FFF;

		int scrBaseCoordX = 0, scrBaseCoordY = 0;
		for (int scrRowOffset = 0;
			scrRowOffset < SBRSIZE;
			scrRowOffset += 256) {
			// scan 8 rows in screen file
			for (int lineCharOffset = 0;
				lineCharOffset < 213;
				lineCharOffset += 2) {
				// scan 106 2-byte control characters per row in screen file
				int sbrOffset = sbr + scrRowOffset + lineCharOffset;
				int scrChar = blink.getByte(sbrOffset, bankSbr);
				int scrCharAttr = blink.getByte(sbrOffset + 1, bankSbr);

				if ((scrCharAttr & attrHrs) == 0) {
					// Draw a LORES1 character (6x8 pixel matrix), char offset into LORES1 is 9 bits...
					drawLoresChar(
						scrBaseCoordX,
						scrBaseCoordY,
						scrCharAttr,
						scrChar);
					scrBaseCoordX += 6;
				} else {
					if ((scrCharAttr & attrCursor) == attrCursor) {
						drawLoresCursor(
							scrBaseCoordX,
							scrBaseCoordY,
							scrCharAttr,
							scrChar);
						scrBaseCoordX += 6;
					} else {
						if ((scrCharAttr & attrNull) != attrNull) {
							// Draw a HIRES character (PipeDream MAP / OZ window fonts)
							drawHiresChar(
								scrBaseCoordX,
								scrBaseCoordY,
								scrCharAttr,
								scrChar);
							scrBaseCoordX += 8;
						}
					}
				}
			}

			// when a complete row (8 pixels deep) has been rendered,
			// find out if pixels remain up to the 639'th pixel;
			// these need to get "blanked", before beginning with the next row...
			if (scrBaseCoordX < Z88SCREENWIDTH - 1) {
				for (int y = scrBaseCoordY * Z88SCREENWIDTH;
					y < (scrBaseCoordY * Z88SCREENWIDTH + 8 * Z88SCREENWIDTH);
					y += Z88SCREENWIDTH) {
					// render x blank pixels until right edge of screen...
					for (int bit = 0;
						bit < (Z88SCREENWIDTH - scrBaseCoordX);
						bit++) {
						displayMatrix[y + scrBaseCoordX + bit] = PXCOLOFF;
					}
				}
			}

			// finally, prepare for next pixel row base (downwards)...
			scrBaseCoordY += 8;
			scrBaseCoordX = 0;
		}

		// create an image, based on pixel matrix, and render it via double buffering to 
		// the Awt/Swing component 
		renderImageToComponent();

		// remember the time it took to render the complete screen, accumulated
		renderTimeTotal += System.currentTimeMillis() - timeMs;
	}

	private void renderImageToComponent() {
		if (image != null) {
			// release previous bitmap to the system; 
			// it's been dumped to video already and is now useless...
			image.flush();
			image = null;
		}

		// create image, based on pixel array colours
		Toolkit toolkit = Toolkit.getDefaultToolkit();
		Image image =
			toolkit.createImage(
				new MemoryImageSource(
					Z88SCREENWIDTH,
					Z88SCREENHEIGHT,
					displayMatrix,
					0,
					Z88SCREENWIDTH));
		// Wait until the image has been completely prepared for rendering
		while (!toolkit
			.prepareImage(image, Z88SCREENWIDTH, Z88SCREENHEIGHT, null));

		// draw image into back buffer
		backBufferGrfx.drawImage(image, 0, 0, null);
		// flip back buffer with front buffer which displays current screen frame...
		flip();		
	}
	
	/** Switch the display front and backbuffers */
	private void flip() {
		BufferedImage tempImage = frontBufferImg;
		Graphics2D tempGraphics = frontBufferGrfx;
		frontBufferImg = backBufferImg;
		frontBufferGrfx = backBufferGrfx;
		backBufferImg = tempImage;
		backBufferGrfx = tempGraphics;

		// Draw the new frontbuffer to the screen
		displayGrfx.drawImage(frontBufferImg, 0, 0, null);

		// Allow the painting thread to do its stuff
		Thread.yield();
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
	private void drawLoresCursor(
		final int scrBaseCoordX,
		final int scrBaseCoordY,
		final int charAttr,
		final int scrChar) {
		int bank, bit, y;

		// safety: if 640 - X coordinate is less than 6 pixels, then abort...
		if (Z88SCREENWIDTH - scrBaseCoordX < 6)
			return;

		int offset = ((charAttr & 1) << 8) | scrChar;
		if (offset >= 0x1c0) {
			offset = lores0 + ((scrChar & 0x3F) << 3); // User defined graphics
			bank = bankLores0;
		} else {
			offset = lores1 + (offset << 3);
			// Base fonts (tiny, bold), default in ROM.0
			bank = bankLores1;
		}

		// render 8 pixel rows of 6 pixel wide scrChar
		for (y = scrBaseCoordY * Z88SCREENWIDTH;
			y < (scrBaseCoordY * Z88SCREENWIDTH + Z88SCREENWIDTH * 8);
			y += Z88SCREENWIDTH) {
			int charBits = blink.getByte(offset++, bank);
			// fetch current pixel row of char
			if (cursorInverse == true)
				charBits = ~charBits;

			// render 6 pixels wide...
			int pxOffset = 0;
			for (bit = 32; bit > 0; bit >>>= 1) {
				displayMatrix[y + scrBaseCoordX + pxOffset++] =
					((charBits & bit) != 0) ? PXCOLON : PXCOLOFF;
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
	private void drawLoresChar(
		final int scrBaseCoordX,
		final int scrBaseCoordY,
		final int charAttr,
		final int scrChar) {
		int bank, bit, y;
		int pxOn, pxColor;

		// safety: if 640 - X coordinate is less than 6 pixels, then abort...
		if (Z88SCREENWIDTH - scrBaseCoordX < 6)
			return;

		if (((charAttr & attrFls) == attrFls) && flashTextEmpty == true) {
			// render 8 pixel rows of 6 empty pixels, if flashing is enabled and is currently "empty"..
			for (y = scrBaseCoordY * Z88SCREENWIDTH;
				y < (scrBaseCoordY * Z88SCREENWIDTH + Z88SCREENWIDTH * 8);
				y += Z88SCREENWIDTH) {
				// render 6 pixels wide...
				for (bit = 0; bit < 6; bit++)
					displayMatrix[y + scrBaseCoordX + bit] = PXCOLOFF;
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
		} else {
			offset = lores1 + (offset << 3);
			// Base fonts (tiny, bold), default in ROM.0
			bank = bankLores1;
		}

		// render 8 pixel rows of 6 pixel wide scrChar
		for (y = scrBaseCoordY * Z88SCREENWIDTH;
			y < (scrBaseCoordY * Z88SCREENWIDTH + Z88SCREENWIDTH * 8);
			y += Z88SCREENWIDTH) {
			int charBits = blink.getByte(offset++, bank);
			// fetch current pixel row of char
			if ((charAttr & attrRev) == attrRev)
				charBits = ~charBits;

			// render 6 pixels wide...
			int pxOffset = 0;
			for (bit = 32; bit > 0; bit >>>= 1) {
				displayMatrix[y + scrBaseCoordX + pxOffset++] =
					((charBits & bit) != 0) ? pxOn : PXCOLOFF;
			}
		}

		// draw underline?
		if ((charAttr & attrUnd) == attrUnd) {
			pxColor = pxOn;
			if ((charAttr & attrRev) == attrRev)
				pxColor = PXCOLOFF; // paint "inverse" underline..

			y -= Z88SCREENWIDTH; // back on 8th row...
			for (bit = 0; bit < 6; bit++)
				displayMatrix[y + scrBaseCoordX + bit] = pxColor;
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
	private void drawHiresChar(
		final int scrBaseCoordX,
		final int scrBaseCoordY,
		final int charAttr,
		final int scrChar) {
		int offset, bank;
		int pxOn, bit;

		// safety: if 640 - X coordinate is less than 8 pixels, then abort...
		if (Z88SCREENWIDTH - scrBaseCoordX < 8)
			return;

		if (((charAttr & attrFls) == attrFls) && flashTextEmpty == true) {
			// render 8 pixel rows of 8 empty pixels, if flashing is enabled and is currently "empty"..
			for (int y = scrBaseCoordY * Z88SCREENWIDTH;
				y < (scrBaseCoordY * Z88SCREENWIDTH + Z88SCREENWIDTH * 8);
				y += Z88SCREENWIDTH) {
				// render 8 pixels wide...
				for (bit = 0; bit < 8; bit++)
					displayMatrix[y + scrBaseCoordX + bit] = PXCOLOFF;
			}

			return;
		}

		// Main draw HIRES...
		// define which font set to use...
		offset = ((charAttr & 3) << 8) | scrChar;
		if (offset >= 0x300) {
			offset = hires1 + (scrChar << 3); // "OZ" window font entries
			bank = bankHires1;
		} else {
			offset = hires0 + (offset << 3); // PipeDream Map entries
			bank = bankHires0;
		}

		// define pixel colour; clear ON or GREY
		pxOn = ((charAttr & attrGry) == 0) ? PXCOLON : PXCOLGREY;

		// render 8 pixel rows of 8 pixel wide scrChar
		for (int y = scrBaseCoordY * Z88SCREENWIDTH;
			y < (scrBaseCoordY * Z88SCREENWIDTH + Z88SCREENWIDTH * 8);
			y += Z88SCREENWIDTH) {
			int charBits = blink.getByte(offset++, bank);
			// fetch current pixel row of char
			if ((charAttr & attrRev) == attrRev)
				charBits = ~charBits;

			int pxOffset = 0;
			// render 8 pixels wide...
			for (bit = 128; bit > 0; bit >>>= 1)
				displayMatrix[y + scrBaseCoordX + pxOffset++] =
					((charBits & bit) != 0) ? pxOn : PXCOLOFF;
		}
	}

	/**
	 * Keep flash counters updated according to FPS settings.<br>
	 * Ordinary text flashing changes state each second (text appears one sec. then disappears one sec).
	 * Cursor flash inverts 6x8 LORES char 70% of 1 sec, remaining 30% renders the char as normal.
	 */
	private void flashCounter() {
		if (frameCounter++ > fps[curRenderSpeedIndex]) { // 1 second has passed
			frameCounter = 0;
			flashTextEmpty = !flashTextEmpty; // invert current text flashing mode
		}

		if (frameCounter < fcd[curRenderSpeedIndex])
			cursorInverse = true; // most of the time, cursor is black
		else
			cursorInverse = false; // rest of the time, cursor is invisible (normal text)
	}

	/**
	 * Render Z88 Display each X ms (runtime adjusted)...
	 * If Z80 engine has stopped, then don't blink the cursor (which
	 * otherwise gives a feel of a running Z80 engine).
	 */
	private class RenderPerMs extends TimerTask {
		public void run() {
			if (blink.isZ80running() == true) flashCounter(); // update cursor flash and ordinary flash counters
			renderDisplay(); // then render display...
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
			blink.getTimerDaemon().scheduleAtFixedRate(
				renderPerMs,
				0,
				1000 / fps[curRenderSpeedIndex]);

			renderTimeTotal = 0;
			renderSupervisor = new RenderSupervisor();
			blink.getTimerDaemon().scheduleAtFixedRate(
				renderSupervisor,
				3000,
				3000);
			// poll every 3rd second
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
			int avgRenderSpeed =
				(int) renderTimeTotal / fps[curRenderSpeedIndex];
			// System.out.println("Avg Frame Render Speed: " + avgRenderSpeed + " ms");
			
			if (avgRenderSpeed * 1.4 > 1000 / fps[curRenderSpeedIndex]) {
				// current average render speed and safety margin takes longer than the time interval
				// between frames. Choose a one-step lower frame rate, if possible...
				if (curRenderSpeedIndex > 0) {
					curRenderSpeedIndex--;
					// choose a lower framerate, then restart screen rendering...
					stop();
					start();
					return;
				}
			}
			if (avgRenderSpeed * 1.4 < 1000 / fps[curRenderSpeedIndex]) {
				// current average render speed and safety margin is faster than the time interval
				// between frames. Choose a one-step higher frame rate, if possible...
				if (curRenderSpeedIndex < fps.length - 1) {
					curRenderSpeedIndex++;
					// choose a higher framerate, then restart screen rendering...
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
