/*
 * Z88Info.java
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
 * @author <A HREF="mailto:gstrube@gmail.com">Gunther Strube</A>
 *
 */

package com.jira.cambridgez88.ozvm;

/**
 * Z80 Registers & Blink Info.
 */
public class Z88Info {

	/**
	 * Dump current Z80 Registers.
	 */
	public static String z80RegisterInfo() {
		Z80Processor z80 = Z88.getInstance().getProcessor();
		StringBuffer dzRegisters = new StringBuffer(1024);

		dzRegisters.append(" ").append("BC=").append(Dz.addrToHex(z80.BC(),false)).append(" ");
		dzRegisters.append(" ").append("DE=").append(Dz.addrToHex(z80.DE(),false)).append(" ");
		dzRegisters.append(" ").append("HL=").append(Dz.addrToHex(z80.HL(),false)).append(" ");
		dzRegisters.append(" ").append("IX=").append(Dz.addrToHex(z80.IX(),false)).append(" ");
		dzRegisters.append(" ").append("IY=").append(Dz.addrToHex(z80.IY(),false)).append(" ");
		dzRegisters.append(" ").append("\n");
		z80.exx();
		dzRegisters.append("'BC=").append(Dz.addrToHex(z80.BC(),false)).append(" ");
		dzRegisters.append("'DE=").append(Dz.addrToHex(z80.DE(),false)).append(" ");
		dzRegisters.append("'HL=").append(Dz.addrToHex(z80.HL(),false)).append(" ");
		z80.exx();
		dzRegisters.append(" ").append("SP=").append(Dz.addrToHex(z80.SP(),false)).append(" ");
		dzRegisters.append(" ").append("PC=").append(Dz.addrToHex(z80.PC(),false)).append("\n");
		dzRegisters.append(" ").append("AF=").append(Dz.addrToHex(z80.AF(),false)).append(" ");
		dzRegisters.append(" ").append("A=").append(Dz.byteToHex(z80.A(),false)).append(" ");
		dzRegisters.append(" ").append("F=").append(z80Flags()).append(" ");
		dzRegisters.append(" ").append("I=").append(z80.I()).append("\n");
		z80.ex_af_af();
		dzRegisters.append("'AF=").append(Dz.addrToHex(z80.AF(),false)).append(" ");
		dzRegisters.append("'A=").append(Dz.byteToHex(z80.A(),false)).append(" ");
		dzRegisters.append("'F=").append(z80Flags()).append(" ");
		dzRegisters.append(" ").append("R=").append(z80.R()).append("\n");
		z80.ex_af_af();

		return dzRegisters.toString();
	}

	/** 
	 * Return a String of current disassembled instruction
	 * with main register dump.
	 *  
	 * @return
	 */
	public static String dzPcStatus(int pc) {
		Dz dz = Dz.getInstance();
		StringBuffer dzLine = new StringBuffer(128);
		dz.getInstrAscii(dzLine, pc, false, true);

		StringBuffer dzBuffer = new StringBuffer(128);
		dzBuffer.append(Dz.addrToHex(pc,false)).append(" (").
						append(Dz.extAddrToHex(Z88.getInstance().getBlink().decodeLocalAddress(pc),false).toString()).
						append(") ").append(dzLine);
		for(int space=45 - dzBuffer.length(); space>0; space--) dzBuffer.append(" ");
		dzBuffer.append(quickZ80Dump());
		
		return dzBuffer.toString();
	}

	public static StringBuffer quickZ80Dump(int af, int bc, int de, int hl, int ix, int iy, int sp ) {
		int a = af >>> 8;
		int f = af & 0xff;
		StringBuffer dzRegisters = new StringBuffer(128);

		dzRegisters.append(Dz.byteToHex(a, false)).append(" ");
		dzRegisters.append(Dz.addrToHex(bc, false)).append(" ");
		dzRegisters.append(Dz.addrToHex(de, false)).append(" ");
		dzRegisters.append(Dz.addrToHex(hl, false)).append(" ");
		dzRegisters.append(Dz.addrToHex(sp, false)).append(" ");			
		dzRegisters.append(Dz.addrToHex(ix, false)).append(" ");
		dzRegisters.append(Dz.addrToHex(iy ,false)).append(" ");

		dzRegisters.append( (f & Z80.F_S) != 0 ? "S" : ".");
		dzRegisters.append( (f & Z80.F_Z) != 0 ? "Z" : ".");
		dzRegisters.append( (f & Z80.F_5) != 0 ? "5" : ".");
		dzRegisters.append( (f & Z80.F_H) != 0 ? "H" : ".");
		dzRegisters.append( (f & Z80.F_3) != 0 ? "3" : ".");
		dzRegisters.append( (f & Z80.F_PV) != 0 ? "V" : ".");
		dzRegisters.append( (f & Z80.F_N) != 0 ? "N" : ".");
		dzRegisters.append( (f & Z80.F_C) != 0 ? "C" : ".");
		
		return dzRegisters;		
	}
	
	/**
	 * Current main purpose Z80 Registers and Flags as a one-liner string
	 */
	private static StringBuffer quickZ80Dump() {
		StringBuffer dzRegisters = new StringBuffer(1024);
		Z80Processor z80 = Z88.getInstance().getProcessor();		

		dzRegisters.append(Dz.byteToHex(z80.A(),false)).append(" ");
		dzRegisters.append(Dz.addrToHex(z80.BC(),false)).append(" ");
		dzRegisters.append(Dz.addrToHex(z80.DE(),false)).append(" ");
		dzRegisters.append(Dz.addrToHex(z80.HL(),false)).append(" ");
		dzRegisters.append("(").append(Dz.addrToHex(z80.SP(),false)).append(")=");
		
		// display contents of current SP
		dzRegisters.append(Dz.addrToHex(z80.readWord(z80.SP()),false)).append(" ");
		
		dzRegisters.append(Dz.addrToHex(z80.IX(),false)).append(" ");
		dzRegisters.append(Dz.addrToHex(z80.IY(),false)).append(" ");
		dzRegisters.append(z80Flags());

		return dzRegisters;
	}

    /**
     * Information of all Blink Registers.
     */
    public static String blinkRegisterDump() {
    	StringBuffer blinkInfo = new StringBuffer(1024);
    	
    	blinkInfo.append(blinkComInfo()).append("\n");
    	blinkInfo.append(blinkIntInfo()).append("\n");
    	blinkInfo.append(blinkStaInfo()).append("\n");
        blinkInfo.append(blinkTimersInfo()).append("\n");
        blinkInfo.append(blinkTstaInfo()).append("\n");
        blinkInfo.append(blinkTmkInfo()).append("\n");
        blinkInfo.append(blinkScreenInfo()).append("\n");
		blinkInfo.append(blinkSegmentsInfo()).append("\n");
		
		return blinkInfo.toString();
    }

    public static String blinkTimersInfo() {
    	Blink z88 = Z88.getInstance().getBlink();
    	
    	int blTim0Reg = z88.getBlinkTim0();
        int blTim1Reg = z88.getBlinkTim1();
        int blTim2Reg = z88.getBlinkTim2();
        int blTim3Reg = z88.getBlinkTim3();
        int blTim4Reg = z88.getBlinkTim4();
        int timeElapsedMinutes = 65536 * blTim4Reg + 256 * blTim3Reg + blTim2Reg;
        int timeElapsedDays = timeElapsedMinutes / 1440;
        int timeElapsedHours = (timeElapsedMinutes - (timeElapsedDays * 1440)) / 60;
        timeElapsedMinutes = timeElapsedMinutes - (timeElapsedDays * 1440) - (timeElapsedHours * 60);

		StringBuffer blinkTimers = new StringBuffer(128);
        blinkTimers.append("TIM4=" + blTim4Reg); blinkTimers.append(",TIM3=" + blTim3Reg);
        blinkTimers.append(",TIM2=" + blTim2Reg); blinkTimers.append(",TIM1=" + blTim1Reg);
        blinkTimers.append(",TIM0=" + blTim0Reg);
        blinkTimers.append(", Time elapsed: " + timeElapsedDays + "d:" + timeElapsedHours + "h:");
        blinkTimers.append(timeElapsedMinutes + "m:" + blTim1Reg + "s:" + blTim0Reg * 5 + "ms");

        return blinkTimers.toString();
    }


	public static StringBuffer z80Flags() {
		StringBuffer dzFlags = new StringBuffer(8);
		Z80Processor z80 = Z88.getInstance().getProcessor();
		
		dzFlags.append( z80.Sset() == true ? "S" : ".");
		dzFlags.append( z80.Zset() == true ? "Z" : ".");
		dzFlags.append( z80.f5set() == true ? "5" : ".");
		dzFlags.append( z80.Hset() == true ? "H" : ".");
		dzFlags.append( z80.f3set() == true ? "3" : ".");
		dzFlags.append( z80.PVset() == true ? "V" : ".");
		dzFlags.append( z80.Nset() == true ? "N" : ".");
		dzFlags.append( z80.Cset() == true ? "C" : ".");

		return dzFlags;
	}

	public static String bankBindingInfo() {
		StringBuffer blinkBanks = new StringBuffer(256);
		Blink z88 = Z88.getInstance().getBlink();
		
		blinkBanks.append("RAMS      (0000h-1FFFh): ");
		if ((z88.getBlinkCom() & Blink.BM_COMRAMS) == Blink.BM_COMRAMS) {
			blinkBanks.append("20h");
		} else {
			blinkBanks.append("00h");
		}
		blinkBanks.append("\n");

		blinkBanks.append("Segment 0 (2000h-3FFFh): ");
		blinkBanks.append(Dz.byteToHex(z88.getSegmentBank(0) & 0xFE,true)).append(" ");
		blinkBanks.append((z88.getSegmentBank(0) & 1) == 0 ? "(Lower 8K)" : "(Upper 8K)");
		blinkBanks.append("\n");

		blinkBanks.append("Segment 1 (4000h-7FFFh): ");
		blinkBanks.append(Dz.byteToHex(z88.getSegmentBank(1),true)).append("\n");

		blinkBanks.append("Segment 2 (8000h-BFFFh): ");
		blinkBanks.append(Dz.byteToHex(z88.getSegmentBank(2),true)).append("\n");

		blinkBanks.append("Segment 3 (C000h-FFFFh): ");
		blinkBanks.append(Dz.byteToHex(z88.getSegmentBank(3),true));

        return blinkBanks.toString();
	}


    /**
     * Bit status of Blink COM register.
     */
	public static String blinkComInfo() {
		StringBuffer blinkComFlags = new StringBuffer(128);
		Blink z88 = Z88.getInstance().getBlink();
        int blComReg = z88.getBlinkCom() & 0xFF;

        blinkComFlags.append("COM (B0h) = " + Dz.byteToBin(blComReg, true) + " : ");
        if ( ((blComReg & Blink.BM_COMSRUN) == 0) & ((blComReg & Blink.BM_COMSBIT) == 0) )
            blinkComFlags.append("Speaker=Low");
        if ( ((blComReg & Blink.BM_COMSRUN) == 0) & ((blComReg & Blink.BM_COMSBIT) == Blink.BM_COMSBIT) )
            blinkComFlags.append("Speaker=High");
        if ( ((blComReg & Blink.BM_COMSRUN) == Blink.BM_COMSRUN) & ((blComReg & Blink.BM_COMSBIT) == 0) )
            blinkComFlags.append("Speaker=3200Khz");
        if ( ((blComReg & Blink.BM_COMSRUN) == Blink.BM_COMSRUN) & ((blComReg & Blink.BM_COMSBIT) == Blink.BM_COMSBIT) )
            blinkComFlags.append("Speaker=TxD");

        if ( ((blComReg & Blink.BM_COMOVERP) == Blink.BM_COMOVERP) )
            blinkComFlags.append(",OVERP");
        if ( ((blComReg & Blink.BM_COMRESTIM) == Blink.BM_COMRESTIM) )
            blinkComFlags.append(",RESTIM");
        if ( ((blComReg & Blink.BM_COMPROGRAM) == Blink.BM_COMPROGRAM) )
            blinkComFlags.append(",PROGRAM");

        if ( ((blComReg & Blink.BM_COMRAMS) == Blink.BM_COMRAMS) )
            blinkComFlags.append(",RAMS");
        else
            blinkComFlags.append(",BANK0");

        if ( ((blComReg & Blink.BM_COMVPPON) == Blink.BM_COMVPPON) )
            blinkComFlags.append(",VPPON");
        if ( ((blComReg & Blink.BM_COMLCDON) == Blink.BM_COMLCDON) )
            blinkComFlags.append(",LCDON");

        return blinkComFlags.toString();
	}


    /**
     * Bit status of Blink INT register
     */
    public static String blinkIntInfo() {
		StringBuffer blinkIntFlags = new StringBuffer(128);
		int blIntReg = Z88.getInstance().getBlink().getBlinkInt() & 0xFF;
		
		blinkIntFlags.append("INT (B1h) = " + Dz.byteToBin(blIntReg,true) + " : ");
        if ( (blIntReg & Blink.BM_INTKWAIT) == Blink.BM_INTKWAIT ) 
        	blinkIntFlags.append("KWAIT");
        if ( (blIntReg & Blink.BM_INTA19) == Blink.BM_INTA19 ) 
        	blinkIntFlags.append(",A19");
        if ( (blIntReg & Blink.BM_INTFLAP) == Blink.BM_INTFLAP ) 
        	blinkIntFlags.append(",FLAP");
        if ( (blIntReg & Blink.BM_INTUART) == Blink.BM_INTUART ) 
        	blinkIntFlags.append(",UART");
        if ( (blIntReg & Blink.BM_INTBTL) == Blink.BM_INTBTL ) 
        	blinkIntFlags.append(",BTL");
        if ( (blIntReg & Blink.BM_INTKEY) == Blink.BM_INTKEY ) 
        	blinkIntFlags.append(",KEY");
        if ( (blIntReg & Blink.BM_INTTIME) == Blink.BM_INTTIME ) 
        	blinkIntFlags.append(",TIME");
        if ( (blIntReg & Blink.BM_INTGINT) == Blink.BM_INTGINT ) 
        	blinkIntFlags.append(",GINT");

        return blinkIntFlags.toString();
    }


    /**
     * Bit status of Blink STA register.
     */
    public static String blinkStaInfo() {
		StringBuffer blinkStaFlags = new StringBuffer(128);
        int blStaReg = Z88.getInstance().getBlink().getBlinkSta() & 0xFF;
		
        blinkStaFlags.append("STA (B1h) = " + Dz.byteToBin(blStaReg, true) + " : ");
        if ( ((blStaReg & Blink.BM_STAFLAPOPEN) == Blink.BM_STAFLAPOPEN) )
            blinkStaFlags.append("FLAPOPEN");
        if ( ((blStaReg & Blink.BM_STAA19) == Blink.BM_STAA19) )
            blinkStaFlags.append(",A19");
        if ( ((blStaReg & Blink.BM_STAFLAP) == Blink.BM_STAFLAP) )
            blinkStaFlags.append(",FLAP");
        if ( ((blStaReg & Blink.BM_STAUART) == Blink.BM_STAUART) )
            blinkStaFlags.append(",UART");
        if ( ((blStaReg & Blink.BM_STABTL) == Blink.BM_STABTL) )
            blinkStaFlags.append(",BTL");
        if ( ((blStaReg & Blink.BM_STAKEY) == Blink.BM_STAKEY) )
            blinkStaFlags.append(",KEY");
        if ( ((blStaReg & Blink.BM_STATIME) == Blink.BM_STATIME) )
            blinkStaFlags.append(",TIME");

        return blinkStaFlags.toString();
    }

	/**
	 * Bit status of Blink TSTA register.
	 */
	public static String blinkTstaInfo() {
		int blTstaReg = Z88.getInstance().getBlink().getBlinkTsta() & 0xFF;
		StringBuffer blinkTstaFlags = new StringBuffer(128);
		
		blinkTstaFlags.append("TSTA (B5h) = " + Dz.byteToBin(blTstaReg, true) + " : ");
		if ( ((blTstaReg & Blink.Rtc.BM_TSTAMIN) == Blink.Rtc.BM_TSTAMIN) )
			blinkTstaFlags.append("MIN");
		if ( ((blTstaReg & Blink.Rtc.BM_TSTASEC) == Blink.Rtc.BM_TSTASEC) )
			blinkTstaFlags.append(",SEC");
		if ( ((blTstaReg & Blink.Rtc.BM_TSTATICK) == Blink.Rtc.BM_TSTATICK) )
			blinkTstaFlags.append(",TICK");

		return blinkTstaFlags.toString();
	}

	/**
	 * Bit status of Blink TMK register.
	 */
	public static String blinkTmkInfo() {
		int blTmkReg = Z88.getInstance().getBlink().getBlinkTmk() & 0xFF;
		StringBuffer blinkTmkFlags = new StringBuffer(128);
		
		blinkTmkFlags.append("TMK (B5h) = " + Dz.byteToBin(blTmkReg, true) + " : ");
		if ( ((blTmkReg & Blink.Rtc.BM_TMKMIN) == Blink.Rtc.BM_TMKMIN) )
			blinkTmkFlags.append("MIN");
		if ( ((blTmkReg & Blink.Rtc.BM_TMKSEC) == Blink.Rtc.BM_TMKSEC) )
			blinkTmkFlags.append(",SEC");
		if ( ((blTmkReg & Blink.Rtc.BM_TMKTICK) == Blink.Rtc.BM_TMKTICK) )
			blinkTmkFlags.append(",TICK");

		return blinkTmkFlags.toString();
	}
	
	/**
	 * Screen registers (SBR, PB0-PB3)
	 */
	public static String blinkScreenInfo() {
		Blink z88 = Z88.getInstance().getBlink();		
		StringBuffer blinkScreenRegs = new StringBuffer(128);
		
		blinkScreenRegs.append("SBR (Screen file): ");
		blinkScreenRegs.append(Dz.addrToHex(z88.getBlinkSbr(),true));
		blinkScreenRegs.append(" (" + Dz.extAddrToHex(z88.getBlinkSbrAddress(),true) + ")\n");
		blinkScreenRegs.append("PB0 (LORES0): ");
		blinkScreenRegs.append(Dz.addrToHex(z88.getBlinkPb0(),true));
		blinkScreenRegs.append(" (" + Dz.extAddrToHex(z88.getBlinkPb0Address(),true) + "), ");
		blinkScreenRegs.append("PB1 (LORES1): ");
		blinkScreenRegs.append(Dz.addrToHex(z88.getBlinkPb1(),true));
		blinkScreenRegs.append(" (" + Dz.extAddrToHex(z88.getBlinkPb1Address(),true) + ")\n");
		blinkScreenRegs.append("PB2 (HIRES0): ");
		blinkScreenRegs.append(Dz.addrToHex(z88.getBlinkPb2(),true));
		blinkScreenRegs.append(" (" + Dz.extAddrToHex(z88.getBlinkPb2Address(),true) + "), ");
		blinkScreenRegs.append("PB3 (HIRES1): ");
		blinkScreenRegs.append(Dz.addrToHex(z88.getBlinkPb3(),true));
		blinkScreenRegs.append(" (" + Dz.extAddrToHex(z88.getBlinkPb3Address(),true) + ")");

		return blinkScreenRegs.toString();
	}

	/**
	 * Return a displayable string the contains informaiton about
	 * the bank bindings in the segment registers (SR0 -SR3).
	 */
	public static String blinkSegmentsInfo() {
		StringBuffer blinkSegmentRegs = new StringBuffer(128);
		Blink z88 = Z88.getInstance().getBlink();
		
		blinkSegmentRegs.append("SR0: " + Dz.byteToHex(z88.getSegmentBank(0), true) + ", ");
		blinkSegmentRegs.append("SR1: " + Dz.byteToHex(z88.getSegmentBank(1), true) + ", ");
		blinkSegmentRegs.append("SR2: " + Dz.byteToHex(z88.getSegmentBank(2), true) + ", ");
		blinkSegmentRegs.append("SR3: " + Dz.byteToHex(z88.getSegmentBank(3), true));

		return blinkSegmentRegs.toString();
	}
}
