package net.sourceforge.z88;

/**
 * @author <A HREF="mailto:gstrube@tiscali.dk">Gunther Strube</A>
 *
 * The "Mind" of the Z88.
 * 
 * $Id$
 */
public final class Blink {
	
	Blink() {
		
		// the segment register SR0 - SR3
		sR = new int[4];                    
		// all segment registers points at ROM bank 0
		for (int segment=0; segment < sR.length; segment++) {
			sR[segment] = 0;    
		}		
	}
	
	/**
	 * System bank for lower 8K of segment 0.
	 * References bank 0x00 or 0x20 of slot 0.
	 */
	private Bank RAMS;
	
	public Bank getRAMS() {
		return RAMS;
	}
	public void setRAMS(Bank b) {
		RAMS = b;
	}
	
	/**
	 * Segment register array for SR0 - SR3
	 * Segment register 0, SR0, bank binding for 0x2000 - 0x3FFF
	 * Segment register 1, SR1, bank binding for 0x4000 - 0x7FFF
	 * Segment register 2, SR2, bank binding for 0x8000 - 0xBFFF
	 * Segment register 3, SR3, bank binding for 0xC000 - 0xFFFF
	 *
	 * Any of the registers contains a bank number, 0 - 255 that
	 * is currently bound into the corresponding segment in the
	 * Z80 address space.
	 */
	private int sR[];
	public int getSegmentBank(int segment) {
		return sR[segment % 4];
	}
	
	/**
	 * Bind bank [0; 255] to segments [0; 3] in the Z80 address space.
	 *
	 * On the Z88, the 64K is split into 4 sections of 16K segments.
	 * Any of the 256 16K banks can be bound into the address space
	 * on the Z88. Bank 0 is special, however.
	 * Please refer to hardware section of the Developer's Notes.
	 */	
	public void setSegmentBank(int segment, int BankNo) {
		sR[segment % 4] = (BankNo % 256);
	}

	/**
	 * Blink Command register, port $B0
	 */
	private int COM;
	public void setCOM(int bits) {
		COM = bits;
	}
	public int getCOM() {
		return COM;
	}
	public static final int BM_COMSRUN = 0x80;     // Bit 7, SRUN
	public static final int BM_COMSBIT = 0x40;     // Bit 6, SBIT
	public static final int BM_COMOVERP = 0x20;    // Bit 5, OVERP
	public static final int BM_COMRESTIM = 0x10;   // Bit 4, RESTIM
	public static final int BM_COMPROGRAM = 0x08;  // Bit 3, PROGRAM
	public static final int BM_COMRAMS = 0x04;     // Bit 2, RAMS
	public static final int BM_COMVPPON = 0x02;    // Bit 1, VPPON
	public static final int BM_COMLCDON = 0x01;    // Bit 0, LCDON
}
