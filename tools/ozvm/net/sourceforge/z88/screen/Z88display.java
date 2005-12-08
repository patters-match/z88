/*
 * Z88display.java
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

package net.sourceforge.z88.screen;

import java.awt.Dimension;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;
import java.awt.image.BufferedImage;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.util.LinkedList;
import java.util.TimerTask;

import javax.imageio.ImageIO;
import javax.swing.ImageIcon;
import javax.swing.JLabel;

import com.imagero.util.ThreadManager;

import net.sourceforge.z88.Blink;
import net.sourceforge.z88.Memory;
import net.sourceforge.z88.OZvm;
import net.sourceforge.z88.Z88;

/**
 * The display renderer of the Z88 virtual machine, updating
 * the Z88 screen 10, 25, 50 or 100 frames per second, 
 * depending on runtime configuration.
 */
public class Z88display extends JLabel implements MouseListener {

	/** 10 fps (poll for screen changes every 100 milli-seconds) */
	public static final int FPS10 = 0;

	/** 25 fps (poll for screen changes every 40 milli-seconds), default */
	public static final int FPS25 = 1; 
	
	/** 50 fps (poll for screen changes every 20 milli-seconds) */
	public static final int FPS50 = 2;
	
	/** 100 fps (poll for screen changes every 10 milli-seconds) */
	public static final int FPS100 = 3;
	
	/** The Z88 display width in pixels */
	public static final int Z88SCREENWIDTH = 640;

	/** The Z88 display height in pixels */
	public static final int Z88SCREENHEIGHT = 64;

	/** Size of Z88 Screen Base File (in bytes) */
	private static final int SBRSIZE = 2048;
	
	/** The internal screen frame renderer */
	private RenderPerMs renderPerMs;
	
	/** is the screen being updated at the moment, or not... */	
	private boolean renderRunning;
		
	/** points at the current framerate group, default 25 fps */
	private int curRenderSpeedIndex = FPS25;
	
	/** Runtime selection of Z88 screen frames per second */
	private static final int fps[] = new int[] {10, 25, 50, 100};

	/** Flash cursor duration frame counter (speed of each frame is controlled in fps[]) */
	private static final int fcd[] = new int[] {7, 18, 35, 70};

	/** Enabled pixel */
	private static final int PXCOLON = 0xff461B7D;

	/** Grey enabled pixel */
	private static final int PXCOLGREY = 0xff90B0A7;

	/** Empty pixel, when screen is switched on */
	private static final int PXCOLOFF = 0xffD2E0B9;

	/** Empty pixel, screen is switched off */
	private static final int PXCOLSCROFF = 0xffE0E0E0;

	/** Font attribute Hires Mask (HIRES1) */
	private static final int attrHrs = 0x20;

	/** Font attribute Reverse Mask (LORES1 & HIRES1) */
	private static final int attrRev = 0x10;

	/** Font attribute Flash Mask (LORES1 & HIRES1) */
	private static final int attrFls = 0x08;

	/** Font attribute Grey Mask (all) */
	private static final int attrGry = 0x04;

	/** Font attribute Underline Mask (LORES1) */
	private static final int attrUnd = 0x02;

	/** Null character (6x8 pixel blank) */
	private static final int attrNull = attrHrs | attrRev | attrGry;

	/** Lores cursor (6x8 pixel inverse flashing) */
	private static final int attrCursor = attrHrs | attrRev | attrFls;

	/** separate Thread to manage movie recording of screen activity */
	private ThreadManager movieHelper = new ThreadManager(1);  

	/** output stream to animated Gif movie */
	private OutputStream movieOutputStream;

	/** current filename of animated Gif file used during screen recording */
	private String movieFilename;

	/** The image (based on pixel data array) to be rendered onto Swing Component */
	private BufferedImage image;

	/** Screen dump counter */
	private int scrdumpCounter;

	/** Animated Gif Movie Counter */
	private int movieCounter;

	/** The currently recording screen movie */
	private Gif89Encoder gifEncoder; 

	/**
	 * Internal helper class that represent each frame to be saved
	 * into the animated Gif screen movie file.
	 */
	private class ScreenFrameAction {
		private static final int actionEncodeFrame = 1;
		private static final int actionCloseGifFile = 2;

		/** the output file stream */
		private OutputStream outStream;
		
		/** the action to be taken: encode a frame or close file stream */
		private int fileAction;
		
		/** the Gif frame that is to be encoded to the animated Gif file */
		private DirectGif89Frame gifFrame;
		
		/** The Gif file encoder */
		private Gif89Encoder gifEnc;
				
		/** the constructor for closing the animated Gif File */
		public ScreenFrameAction(OutputStream out) {
			// close the Gif file, no need for screen data
			outStream = out;
			fileAction = actionCloseGifFile;			
		}
		
		public ScreenFrameAction(OutputStream out, Gif89Encoder ge, int scrWidth, int scrHeight, int[] screen) {
			// encode the frame to the Gif file.
			outStream = out;
			gifEnc = ge;
			fileAction = actionEncodeFrame;
			gifFrame = new DirectGif89Frame(scrWidth, scrHeight, screen);
			gifFrame.setDelay(50); // default delay is 0.5 sec
		}

		/** set the display delay in 1/100 sec for this frame */ 
		public void setFrameDelay(int frameDelay) {
			if (gifFrame != null)
				gifFrame.setDelay(frameDelay);
		}
				
		/** execute the action */
		public void action() throws IOException {
			if (fileAction == actionEncodeFrame) {
				gifEnc.encodeFrame(outStream, gifFrame);
			}

			if (fileAction == actionCloseGifFile) {
				// the write GIF TRAILER
				outStream.write(';');
				outStream.close();
				outStream = null;
			}			
		}
	}
		
	/** 
	 * Accumulated time in ms since last displayed frame,
	 * produced by renderDisplay().
	 */
	private int frameDelay;
	
	/** queue of frames to be encoded as animated Gif's */
	private LinkedList screenFrameQueue = new LinkedList();	
	
	/** Cyclic counter that identifies number of frames displayed per second */
	private int frameCounter;

	/** Access to Blink hardware (screen, keyboard, timers...) */
	private Blink blink;

	/**Access to Memory model */
	private Memory memory;

	/** identifies whether screen activity is being recorded or not */	
	private boolean recordingMovie;

	/** Start cursor flash as dark */
	private boolean cursorInverse = true;

	/** Start text flash as dark, ie. text looks normal for 1 sec */
	private boolean flashTextEmpty;

	/** The actual low level pixel video data (used to create the AWT Image) */
	private int[] displayMatrix;

	/** A copy of the previously rendered pixel matrix frame. */
	private int[] cpyDisplayMatrix;

	/** Set to true, if a pixel was changed since the last screen frame rendering */
	private boolean screenChanged;

	/** bank offset pointers to the font pixels in OZ */
	private int lores0, lores1, hires0, hires1, sbr;

	/** bank references to the font pixels in OZ */
	private int bankLores0, bankLores1, bankHires0, bankHires1, bankSbr;

	/** constructor */
	public Z88display() {
		super();
		
		blink = Z88.getInstance().getBlink();
		memory = Z88.getInstance().getMemory();
		
		displayMatrix = new int[Z88SCREENWIDTH * Z88SCREENHEIGHT];
		cpyDisplayMatrix = new int[Z88SCREENWIDTH * Z88SCREENHEIGHT];

		renderRunning = false;

		this.setPreferredSize(new Dimension(640, 64));
		this.setToolTipText("Click on this window with the mouse to get Z88 keyboard focus.");
		this.setFocusable(true);
		this.addMouseListener(this);
	}
	
	/**
	 * Set the update frequency or frames per second (fps) of the Z88 screen. 
	 * The following values are possible:
	 * <pre>
	 * 	0: 10 fps (poll for screen changes every 100 milli-seconds)
	 * 	1: 25 fps (poll for screen changes every 40 milli-seconds)
	 * 	2: 50 fps (poll for screen changes every 20 milli-seconds)
	 * 	3: 100 fps (poll for screen changes every 10 milli-seconds)
	 * </pre>
	 * 
	 * 25 fps is the default. Use 10 fps when running the emulator on 'slow' 
	 * PC's (600Mhz or lower). Only use 50 or 100 fps on high end computers 
	 * (1 Ghz or higher). The real Z88 screen uses 100 fps.  
	 *  
	 * @param frameRateIndex
	 */
	public void setFrameRate(final int frameRateIndex) {
		stop(); // stop the current frames per second renderer
		
		curRenderSpeedIndex = frameRateIndex % fps.length; // only array range
		start(); // restart renderer with new timings
	}

	/**
	 * Get the current Frame Per Second Index. The following value is returned:
	 * <pre>
	 * 	0: 10 fps (poll for screen changes every 100 milli-seconds)
	 * 	1: 25 fps (poll for screen changes every 40 milli-seconds)
	 * 	2: 50 fps (poll for screen changes every 20 milli-seconds)
	 * 	3: 100 fps (poll for screen changes every 10 milli-seconds)
	 * </pre>
	 *  
	 * @return
	 */
	public int getCurrentFrameRate() {
		return curRenderSpeedIndex;
	}
	
	/**
	 * The core Z88 Display renderer. This code is called by RenderPerMs.
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

		if ( ((blink.getBlinkCom() & Blink.BM_COMLCDON) == 0) | (blink.coma == true)) {
			// Screen has been switched off (usually by using the SHIFT keys, or 
			// Blink is in Coma state)
			renderNoScreenFrame();
			return;
		}
		
		if (sbr == 0 | lores1 == 0 | lores0 == 0 | hires0 == 0 | hires1 == 0) {
			// Don't render frame if one of the Screen Registers hasn't been setup yet...
			renderNoScreenFrame();
			return;
		}
		
		// screen is ON and Blink registers are all pointing to font areas...
		renderScreenFrame();
	}

	/**
	 * Grab current screen frame pixel matrix and write it to a file. Default
	 * filename is "z88screen" appended with autogenerated sequence number. File
	 * format is png. The screen dump is saved to directory location where OZvm
	 * were executed.
	 */
	public void grabScreenFrameToFile() {
		BufferedImage img = new BufferedImage(Z88SCREENWIDTH, Z88SCREENHEIGHT, BufferedImage.TYPE_4BYTE_ABGR);
		img.setRGB(0, 0, Z88SCREENWIDTH, Z88SCREENHEIGHT, displayMatrix, 0,	Z88SCREENWIDTH);
		
		File file = new File(System.getProperty("user.dir") + File.separator + 
								"z88screen" + scrdumpCounter++ + ".png");
		OZvm.displayRtmMessage("Screen captured to '" + file.getAbsolutePath() + "'.");
		
		try {
			ImageIO.write(img, "PNG", file);
		} catch (IOException e) {
			// hmm...
		} finally {
			img = null;
		}
	}
	
	/**
	 * Enable/disable recording of Z88 screen into animated GIF movie.
	 */
	public void toggleMovieRecording() {
		if (recordingMovie == false) {
			// enable screen recording
			try {
				movieFilename = System.getProperty("user.dir") + File.separator + 
										"z88movie" + movieCounter++ + ".gif";
				// create a 16K buffered output stream to the animated Gif file
				movieOutputStream = new BufferedOutputStream(new FileOutputStream(movieFilename), 16*1024);
				gifEncoder = new Gif89Encoder();
				recordingMovie = true;
				OZvm.displayRtmMessage("Screen recording to '" + movieFilename + "' activated.");
			} catch (IOException e) {
				recordingMovie = false;
				OZvm.displayRtmMessage("Could not create animated Gif file.");
			}			
		} else {
			// stop screen recording; append Gif trailer and close GIF file
			// (executed later by background thread)
			recordingMovie = false;
			ScreenFrameAction frameAction = new ScreenFrameAction(movieOutputStream);
			screenFrameQueue.add(frameAction);
			
			OZvm.displayRtmMessage("Screen recording stopped. Saved in '" + movieFilename + "'.");
		}
	}

	/**
	 * Add the frame execution to the ThreadManager, which will
	 * enqueue the task and execute it when ready (first executing
	 * previously registered tasks). 
	 */
	private void scheduleFrameAction(final ScreenFrameAction frame) {		
		movieHelper.addTask( new Runnable() {
			public void run() {
				try {
					frame.action();
				} catch (IOException e) {
				}
			}
		});							
	}
			
	/**
	 * Get a copy of the current screen frame
	 * @return BufferedImage
	 */
	public BufferedImage getScreenFrame() {
		BufferedImage img = new BufferedImage(Z88SCREENWIDTH, Z88SCREENHEIGHT, BufferedImage.TYPE_4BYTE_ABGR);
		img.setRGB(0, 0, Z88SCREENWIDTH, Z88SCREENHEIGHT, displayMatrix, 0,	Z88SCREENWIDTH);		

		return img;
	}
	
	/**
	 * Render a "Z88 screen is switched off" image.
	 */
	private void renderNoScreenFrame() {		
		// assume that screen hasn't changed (status might change inside
		// writePixels() method)...
		screenChanged = false;

		for (int x = 0, n = Z88SCREENHEIGHT * Z88SCREENWIDTH; x < n; x++)
			setPixel(x, PXCOLSCROFF);

		if (screenChanged == true) {
			// pixels changed on the screen. Create an image, based on pixel
			// matrix, and render it via double buffering to the Awt/Swing component
			renderImageToComponent();
		}
	}

	/**
	 * Scan the Screen file in OZ, and render a pixel image if a change
	 * was identified since the last displayed pixel image. 
	 */
	private void renderScreenFrame() {
		// assume that screen hasn't changed (status might change inside
		// writePixels() method)...
		screenChanged = false;

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
		for (int scrRowOffset = 0; scrRowOffset < SBRSIZE; scrRowOffset += 256) {
			// scan 8 rows in screen file
			for (int lineCharOffset = 0; lineCharOffset < 213; lineCharOffset += 2) {
				// scan 106 2-byte control characters per row in screen file
				int sbrOffset = sbr + scrRowOffset + lineCharOffset;
				int scrChar = memory.getByte(sbrOffset, bankSbr);
				int scrCharAttr = memory.getByte(sbrOffset + 1, bankSbr);

				if ((scrCharAttr & attrHrs) == 0) {
					// Draw a LORES1 character (6x8 pixel matrix), char offset
					// into LORES1 is 9 bits...
					drawLoresChar(scrBaseCoordX, scrBaseCoordY, scrCharAttr,
							scrChar);
					scrBaseCoordX += 6;
				} else {
					if ((scrCharAttr & attrCursor) == attrCursor) {
						drawLoresCursor(scrBaseCoordX, scrBaseCoordY,
								scrCharAttr, scrChar);
						scrBaseCoordX += 6;
					} else {
						if ((scrCharAttr & attrNull) != attrNull) {
							// Draw a HIRES character (PipeDream MAP / OZ window
							// fonts)
							drawHiresChar(scrBaseCoordX, scrBaseCoordY,
									scrCharAttr, scrChar);
							scrBaseCoordX += 8;
						}
					}
				}
			}

			// when a complete row (8 pixels deep) has been rendered,
			// find out if pixels remain up to the 639'th pixel;
			// these need to get "blanked", before beginning with the next
			// row...
			if (scrBaseCoordX < Z88SCREENWIDTH - 1) {
				for (int y = scrBaseCoordY * Z88SCREENWIDTH, 
						 n = scrBaseCoordY * Z88SCREENWIDTH + 8 * Z88SCREENWIDTH;
						 y < n; y += Z88SCREENWIDTH) {
					// render x blank pixels until right edge of screen...
					for (int bit = 0, m = (Z88SCREENWIDTH - scrBaseCoordX); bit < m; bit++) {
						setPixel(y + scrBaseCoordX + bit, PXCOLOFF);
					}
				}
			}

			// finally, prepare for next pixel row base (downwards)...
			scrBaseCoordY += 8;
			scrBaseCoordX = 0;
		}

		if (screenChanged == true) {
			// pixels changed on the screen. Create an image, based on pixel
			// matrix, and render it to the Awt/Swing component			
			renderImageToComponent();			
			
			if (recordingMovie == true) {
				if (screenFrameQueue.size() > 0)
					// update the 'newest' frame in the queu with the correct display delay
					((ScreenFrameAction) screenFrameQueue.getLast()).setFrameDelay(frameDelay/10);

				// then add this screen latest frame
				ScreenFrameAction newFrameAction = new ScreenFrameAction(movieOutputStream, gifEncoder, 
						Z88SCREENWIDTH, Z88SCREENHEIGHT, displayMatrix);
				screenFrameQueue.add(newFrameAction);
			}
				
			frameDelay = 0; // new frame to be displayed, reset acc. time frame counter 			
		}

		if (screenFrameQueue.size() > 0) {
			if (recordingMovie == true & screenFrameQueue.size() == 1) {
				// do not schedule the first frame; it needs the frame delay from the next frame
				return;
			}

			// schedule item on the screen frame queue to be executed by a background thread...
			scheduleFrameAction((ScreenFrameAction) screenFrameQueue.removeFirst());
		}
	}

	/**
	 * Update the JLabel with a new pixel image of the Z88 screen.
	 */
	private void renderImageToComponent() {
		image = new BufferedImage(Z88SCREENWIDTH, Z88SCREENHEIGHT,
				BufferedImage.TYPE_4BYTE_ABGR);
		image.setRGB(0, 0, Z88SCREENWIDTH, Z88SCREENHEIGHT, displayMatrix, 0,
				Z88SCREENWIDTH);
		
		// make the new screen frame visible in the GUI.
		this.setIcon(new ImageIcon(image));
	}

	/**
	 * Draw the character at current position, and overlay with flashing cursor.
	 * 
	 * In cursor mode, neither hardware underline nor grey is functional. Only
	 * inverse video flashing on pixel data of character.
	 * 
	 * @param scrBaseCoordX
	 *            pixel column (0-639)
	 * @param scrBaseCoordY
	 *            pixel row coordinate (0-63)
	 * @param charAttr
	 *            the Screen File attribute fo the character (flashing, reverse,
	 *            tiny, bold)
	 * @param scrChar
	 *            the offset into the LORES character set (top bits in
	 *            charAttr).
	 */
	private void drawLoresCursor(final int scrBaseCoordX,
			final int scrBaseCoordY, final int charAttr, final int scrChar) {
		int bank, bit;

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
		for (int y = scrBaseCoordY * Z88SCREENWIDTH, 
				 n = scrBaseCoordY * Z88SCREENWIDTH + Z88SCREENWIDTH * 8; 
		 		 y < n; y += Z88SCREENWIDTH) {
			
			int charBits = memory.getByte(offset++, bank);
			// fetch current pixel row of char
			if (cursorInverse == true)
				charBits = ~charBits;

			// render 6 pixels wide...
			int pxOffset = 0;
			for (bit = 32; bit > 0; bit >>>= 1) {
				setPixel(y + scrBaseCoordX + pxOffset++,
						((charBits & bit) != 0) ? PXCOLON : PXCOLOFF);
			}
		}
	}

	/**
	 * Draw a LORES character (6x8 pixel matrix) at pixel position
	 * (scrBaseCoordX,scrBaseCoordY). <br>
	 * 
	 * @param scrBaseCoordX
	 *            pixel column (0-639)
	 * @param scrBaseCoordY
	 *            pixel row coordinate (0-63)
	 * @param charAttr
	 *            the Screen File attribute fo the character (flashing, reverse,
	 *            tiny, bold, underline, grey)
	 * @param scrChar
	 *            the offset into the LORES character set (top bits in
	 *            charAttr).
	 */
	private void drawLoresChar(final int scrBaseCoordX,
			final int scrBaseCoordY, final int charAttr, final int scrChar) {
		int bank, bit;
		int pxOn, pxColor;

		// safety: if 640 - X coordinate is less than 6 pixels, then abort...
		if (Z88SCREENWIDTH - scrBaseCoordX < 6)
			return;

		if (((charAttr & attrFls) == attrFls) && flashTextEmpty == true) {
			// render 8 pixel rows of 6 empty pixels, if flashing is enabled and
			// is currently "empty"..
			for (int y = scrBaseCoordY * Z88SCREENWIDTH, 
					 n = scrBaseCoordY * Z88SCREENWIDTH + Z88SCREENWIDTH * 8; 
					 y < n; y += Z88SCREENWIDTH) {
				// render 6 pixels wide...
				for (bit = 0; bit < 6; bit++)
					setPixel(y + scrBaseCoordX + bit, PXCOLOFF);
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
		int line = 0;
		for (int y = scrBaseCoordY * Z88SCREENWIDTH, 
				 n = scrBaseCoordY * Z88SCREENWIDTH + Z88SCREENWIDTH * 8; 
				 y < n; y += Z88SCREENWIDTH) {
			
			int charBits = memory.getByte(offset++, bank);
			// fetch current pixel row of char
			if ((charAttr & attrRev) == attrRev)
				charBits = ~charBits;

			// render 6 pixels wide...
			if (line++ == 7) {
				// we've reached the 8th pixel line of the char, VDU underline
				// or not?
				if ((charAttr & attrUnd) == attrUnd) {
					pxColor = pxOn;
					if ((charAttr & attrRev) == attrRev)
						pxColor = PXCOLOFF; // paint "inverse" underline..

					for (bit = 0; bit < 6; bit++)
						setPixel(y + scrBaseCoordX + bit, pxColor);
					break; // we've drawn an underline in stead of the last
						   // pixel row of the lores char...
				}
			}
			int pxOffset = 0;
			for (bit = 32; bit > 0; bit >>>= 1) {
				setPixel(y + scrBaseCoordX + pxOffset++,
						((charBits & bit) != 0) ? pxOn : PXCOLOFF);
			}
		}
	}

	/**
	 * Draw a HIRES character (8x8 pixel matrix) at pixel position
	 * (scrBaseCoordX,scrBaseCoordY).
	 * 
	 * @param scrBaseCoordX
	 *            pixel column (0-639)
	 * @param scrBaseCoordY
	 *            pixel row coordinate (0-63)
	 * @param charAttr
	 *            the Screen File attribute fo the character (flashing, grey)
	 * @param scrChar
	 *            the offset into the HIRES character set (top bits in
	 *            charAttr).
	 */
	private void drawHiresChar(final int scrBaseCoordX,
			final int scrBaseCoordY, final int charAttr, final int scrChar) {
		int offset, bank;
		int pxOn, bit;

		// safety: if 640 - X coordinate is less than 8 pixels, then abort...
		if (Z88SCREENWIDTH - scrBaseCoordX < 8)
			return;

		if (((charAttr & attrFls) == attrFls) && flashTextEmpty == true) {
			// render 8 pixel rows of 8 empty pixels, if flashing is enabled and
			// is currently "empty"..
			for (int y = scrBaseCoordY * Z88SCREENWIDTH, 
					 n = scrBaseCoordY * Z88SCREENWIDTH + Z88SCREENWIDTH * 8; 
			         y < n; y += Z88SCREENWIDTH) {
				
				// render 8 pixels wide...
				for (bit = 0; bit < 8; bit++)
					setPixel(y + scrBaseCoordX + bit, PXCOLOFF);
			}

			return;
		}

		// Main draw HIRES, define which font set to use...
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
		for (int y = scrBaseCoordY * Z88SCREENWIDTH, 
				 n = scrBaseCoordY * Z88SCREENWIDTH + Z88SCREENWIDTH * 8;
				 y < n; y += Z88SCREENWIDTH) {
			int charBits = memory.getByte(offset++, bank);
			// fetch current pixel row of char
			if ((charAttr & attrRev) == attrRev)
				charBits = ~charBits;

			int pxOffset = 0;
			// render 8 pixels wide...
			for (bit = 128; bit > 0; bit >>>= 1)
				setPixel(y + scrBaseCoordX + pxOffset++,
						((charBits & bit) != 0) ? pxOn : PXCOLOFF);
		}
	}

	/**
	 * Draw a pixel into the low level pixel matrix that represent the screen.
	 * The offset is a calculation of X and y coordinates that are handled by
	 * the caller. This method also handles the intelligence if the current
	 * frame has changed compared to the previous frame. The global flag
	 * <screenChanged>is set to <true>if the current frame needs to be
	 * produced as an image and displayed into the Swing JLabel component that
	 * holds the Z88 Display.
	 * 
	 * @param offset
	 *            The (Y,X) coordinate offset into the pixel matrix.
	 * @param pixelColour
	 *            The 24bit RGB colour for an enabled, grey, clear or screen off
	 *            clear pixel.
	 */
	private void setPixel(int offset, int pixelColour) {
		displayMatrix[offset] = pixelColour;

		if (cpyDisplayMatrix[offset] != displayMatrix[offset]) {
			cpyDisplayMatrix[offset] = displayMatrix[offset];
			screenChanged = true;
		}
	}

	/**
	 * Keep flash counters updated according to FPS settings. <br>
	 * Ordinary text flashing changes state each second (text appears one sec.
	 * then disappears one sec). Cursor flash inverts 6x8 LORES char 70% of 1
	 * second, remaining 30% renders the char as normal.
	 */
	private void flashCounter() {
		if (frameCounter++ > fps[curRenderSpeedIndex]) { // 1 second has passed
			frameCounter = 0;
			flashTextEmpty = !flashTextEmpty; // invert current text flashing mode
		}

		if (frameCounter < fcd[curRenderSpeedIndex])
			cursorInverse = true; // most of the time, cursor is black
		else
			cursorInverse = false; // rest of the time, cursor is invisible
	}

	
	/**
	 * Render Z88 Display each X ms (runtime adjusted) as long as the Z80 engine
	 * is running (The Z80 engine automatically stops the Z88 Display renderer,
	 * when the Z80 execution engine stops).
	 */
	private class RenderPerMs extends TimerTask {		
		boolean priorityDefined;
		
		public void run() {
			if (priorityDefined == false) {
				Thread.currentThread().setPriority(Thread.MIN_PRIORITY);
				priorityDefined = true;
			}
			
			frameDelay += (1000 / fps[curRenderSpeedIndex]);
			
			// update cursor flash and ordinary flash counters
			if (blink.isZ80running() == true)
				flashCounter();
			renderDisplay(); // then render display...
		}
	}

	/**
	 * Stop the fps Z88 screen renderer. 
	 */
	public void stop() {
		if (renderPerMs != null) {
			renderPerMs.cancel();
			renderRunning = false;
		}
	}

	/**
	 * Start fps Z88 screen renderer. 
	 */
	public void start() {
		if (renderRunning == false) {
			renderPerMs = new RenderPerMs();
			blink.getTimerDaemon().scheduleAtFixedRate(renderPerMs, 0,
					1000 / fps[curRenderSpeedIndex]);

			renderRunning = true;
		}
	}

	
	/*
	 * (non-Javadoc)
	 * 
	 * @see java.awt.event.MouseListener#mouseClicked(java.awt.event.MouseEvent)
	 */
	public void mouseClicked(MouseEvent arg0) {
		grabFocus();
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see java.awt.event.MouseListener#mouseEntered(java.awt.event.MouseEvent)
	 */
	public void mouseEntered(MouseEvent arg0) {
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see java.awt.event.MouseListener#mouseExited(java.awt.event.MouseEvent)
	 */
	public void mouseExited(MouseEvent arg0) {
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see java.awt.event.MouseListener#mousePressed(java.awt.event.MouseEvent)
	 */
	public void mousePressed(MouseEvent arg0) {
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see java.awt.event.MouseListener#mouseReleased(java.awt.event.MouseEvent)
	 */
	public void mouseReleased(MouseEvent arg0) {
	}
}