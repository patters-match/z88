package net.sourceforge.z88;

/**
 * Blink register status display to console.
 * 
 * @author <A HREF="mailto:gstrube@tiscali.dk">Gunther Strube</A>
 * $Id$
 * 
 */
public class DisplayStatus {
    private Blink z88;
    
    /** Creates a new instance of DisplayStatus */
    public DisplayStatus(Blink b) {
        z88 = b;
    }
    
	/**
	 * Dump current Z80 Registers.  
	 */
	public void displayZ80Registers() {
		StringBuffer dzRegisters = new StringBuffer(1024);

		dzRegisters.append(" ").append("BC=").append(Dz.addrToHex(z88.BC(),false)).append(" ");
		dzRegisters.append(" ").append("DE=").append(Dz.addrToHex(z88.DE(),false)).append(" ");
		dzRegisters.append(" ").append("HL=").append(Dz.addrToHex(z88.HL(),false)).append(" ");
		dzRegisters.append(" ").append("IX=").append(Dz.addrToHex(z88.IX(),false)).append(" ");
		dzRegisters.append(" ").append("IY=").append(Dz.addrToHex(z88.IY(),false)).append(" ");
		dzRegisters.append(" ").append("\n");
		z88.exx();
		dzRegisters.append("'BC=").append(Dz.addrToHex(z88.BC(),false)).append(" ");
		dzRegisters.append("'DE=").append(Dz.addrToHex(z88.DE(),false)).append(" ");
		dzRegisters.append("'HL=").append(Dz.addrToHex(z88.HL(),false)).append(" ");
		z88.exx();
		dzRegisters.append(" ").append("SP=").append(Dz.addrToHex(z88.SP(),false)).append(" ");
		dzRegisters.append(" ").append("PC=").append(Dz.addrToHex(z88.PC(),false)).append("\n");
		dzRegisters.append(" ").append("AF=").append(Dz.addrToHex(z88.AF(),false)).append(" ");
		dzRegisters.append(" ").append("A=").append(Dz.byteToHex(z88.A(),false)).append(" ");
		dzRegisters.append(" ").append("F=").append(z80Flags()).append(" ");
		dzRegisters.append(" ").append("I=").append(z88.I()).append("\n");
		z88.ex_af_af();
		dzRegisters.append("'AF=").append(Dz.addrToHex(z88.AF(),false)).append(" ");
		dzRegisters.append("'A=").append(Dz.byteToHex(z88.A(),false)).append(" ");
		dzRegisters.append("'F=").append(z80Flags()).append(" ");
		dzRegisters.append(" ").append("R=").append(z88.R()).append("\n");
		z88.ex_af_af();
		
		System.out.println("\n" + dzRegisters);
	}

	/**
	 * current main purpose Z80 Registers and Flags as a one-liner string  
	 */
	public StringBuffer quickZ80Dump() {
		StringBuffer dzRegisters = new StringBuffer(1024);

		dzRegisters.append(Dz.byteToHex(z88.A(),false)).append(" ");
		dzRegisters.append(Dz.addrToHex(z88.BC(),false)).append(" ");
		dzRegisters.append(Dz.addrToHex(z88.DE(),false)).append(" ");
		dzRegisters.append(Dz.addrToHex(z88.HL(),false)).append(" ");
		dzRegisters.append(Dz.addrToHex(z88.IX(),false)).append(" ");
		dzRegisters.append(Dz.addrToHex(z88.IY(),false)).append(" ");
		dzRegisters.append(z80Flags());
		
		return dzRegisters;
	}
    
    /**
     * Display contents of Blink Registers to console.
     */
    public void displayBlinkRegisters() {
        displayBlinkCom();
        displayBlinkInt();
        displayBlinkSta();
        displayBlinkAck();           
        displayBlinkTimers();  	// TIM0, TIM1, TIM2, TIM3 & TIM4
		displayBlinkTsta();     
		displayBlinkTmk();
		displayBlinkTack();
		displayBlinkScreen();	// PB0, PB1, PB2, PB3 & SBR
		displayBlinkSegments();
    }

    
    public void displayBlinkTimers() {
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
        
        System.out.println(blinkTimers);        
    }

	
	private StringBuffer z80Flags() {
		StringBuffer dzFlags = new StringBuffer(8);
		
		dzFlags.append( z88.Sset() == true ? "S" : ".");
		dzFlags.append( z88.Zset() == true ? "Z" : ".");
		dzFlags.append( z88.f5set() == true ? "5" : ".");
		dzFlags.append( z88.Hset() == true ? "H" : ".");
		dzFlags.append( z88.f3set() == true ? "3" : ".");
		dzFlags.append( z88.PVset() == true ? "P" : "V");
		dzFlags.append( z88.Nset() == true ? "N" : ".");
		dzFlags.append( z88.Cset() == true ? "C" : ".");
		
		return dzFlags;
	}

    
	public void displayBankBindings() {
		StringBuffer blinkBanks = new StringBuffer(256);
		
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
        
        System.out.println(blinkBanks + "\n");		
	}
	
    
    /**
     * Display bit status of Blink COM register.
     */
	public void displayBlinkCom() {	
        int blComReg = z88.getBlinkCom();
		StringBuffer blinkComFlags = new StringBuffer(128);
        
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

        System.out.println("COM (B0h): " + blinkComFlags);
	}

    
    /**
     * Display bit status of Blink INT register.
     */
    public void displayBlinkInt() {
        int blIntReg = z88.getBlinkInt();
		StringBuffer blinkIntFlags = new StringBuffer(128);
        if ( ((blIntReg & Blink.BM_INTKWAIT) == Blink.BM_INTKWAIT) )
            blinkIntFlags.append("KWAIT");
        if ( ((blIntReg & Blink.BM_INTA19) == Blink.BM_INTA19) )
            blinkIntFlags.append(",A19");
        if ( ((blIntReg & Blink.BM_INTFLAP) == Blink.BM_INTFLAP) )
            blinkIntFlags.append(",FLAP");
        if ( ((blIntReg & Blink.BM_INTUART) == Blink.BM_INTUART) )
            blinkIntFlags.append(",UART");
        if ( ((blIntReg & Blink.BM_INTBTL) == Blink.BM_INTBTL) )
            blinkIntFlags.append(",BTL");
        if ( ((blIntReg & Blink.BM_INTKEY) == Blink.BM_INTKEY) )
            blinkIntFlags.append(",KEY");
        if ( ((blIntReg & Blink.BM_INTTIME) == Blink.BM_INTTIME) )
            blinkIntFlags.append(",TIME");
        if ( ((blIntReg & Blink.BM_INTGINT) == Blink.BM_INTGINT) )
            blinkIntFlags.append(",GINT");

        System.out.println("INT (B1h): " + blinkIntFlags);
    }

    
    /**
     * Display bit status of Blink STA register.
     */
    public void displayBlinkSta() {
        int blStaReg = z88.getBlinkSta();
		StringBuffer blinkStaFlags = new StringBuffer(128);
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

        System.out.println("STA (B1h): " + blinkStaFlags);
    }

    /**
     * Display bit status of Blink ACK register.
     */
    public void displayBlinkAck() {
        int blAckReg = z88.getBlinkAck();
		StringBuffer blinkAckFlags = new StringBuffer(128);
        if ( ((blAckReg & Blink.BM_ACKA19) == Blink.BM_ACKA19) )
            blinkAckFlags.append("A19");
        if ( ((blAckReg & Blink.BM_ACKFLAP) == Blink.BM_ACKFLAP) )
            blinkAckFlags.append(",FLAP");
        if ( ((blAckReg & Blink.BM_ACKBTL) == Blink.BM_ACKBTL) )
            blinkAckFlags.append(",BTL");
        if ( ((blAckReg & Blink.BM_ACKKEY) == Blink.BM_ACKKEY) )
            blinkAckFlags.append(",KEY");

        System.out.println("ACK (B6h): " + blinkAckFlags);
    }    

	/**
	 * Display bit status of Blink TSTA register.
	 */
	public void displayBlinkTsta() {
		int blTstaReg = z88.getBlinkTsta();
		StringBuffer blinkTstaFlags = new StringBuffer(128);
		if ( ((blTstaReg & Blink.Rtc.BM_TSTAMIN) == Blink.Rtc.BM_TSTAMIN) )
			blinkTstaFlags.append("MIN");
		if ( ((blTstaReg & Blink.Rtc.BM_TSTASEC) == Blink.Rtc.BM_TSTASEC) )
			blinkTstaFlags.append(",SEC");
		if ( ((blTstaReg & Blink.Rtc.BM_TSTATICK) == Blink.Rtc.BM_TSTATICK) )
			blinkTstaFlags.append(",TICK");

		System.out.println("TSTA (B5h): " + blinkTstaFlags);
	}    

	/**
	 * Display bit status of Blink TSTA register.
	 */
	public void displayBlinkTmk() {
		int blTmkReg = z88.getBlinkTmk();
		StringBuffer blinkTmkFlags = new StringBuffer(128);
		if ( ((blTmkReg & Blink.Rtc.BM_TMKMIN) == Blink.Rtc.BM_TMKMIN) )
			blinkTmkFlags.append("MIN");
		if ( ((blTmkReg & Blink.Rtc.BM_TMKSEC) == Blink.Rtc.BM_TMKSEC) )
			blinkTmkFlags.append(",SEC");
		if ( ((blTmkReg & Blink.Rtc.BM_TMKTICK) == Blink.Rtc.BM_TMKTICK) )
			blinkTmkFlags.append(",TICK");

		System.out.println("Tmk (B5h): " + blinkTmkFlags);
	}    

	/**
	 * Display bit status of Blink TSTA register.
	 */
	public void displayBlinkTack() {
		int blTackReg = z88.getBlinkTack();
		StringBuffer blinkTackFlags = new StringBuffer(128);
		if ( ((blTackReg & Blink.Rtc.BM_TACKMIN) == Blink.Rtc.BM_TACKMIN) )
			blinkTackFlags.append("MIN");
		if ( ((blTackReg & Blink.Rtc.BM_TACKSEC) == Blink.Rtc.BM_TACKSEC) )
			blinkTackFlags.append(",SEC");
		if ( ((blTackReg & Blink.Rtc.BM_TACKTICK) == Blink.Rtc.BM_TACKTICK) )
			blinkTackFlags.append(",TICK");

		System.out.println("Tack (B4h): " + blinkTackFlags);
	}    

	/**
	 * Display Screen registers (SBR, PB0-PB3)
	 */
	public void displayBlinkScreen() {
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
		
		System.out.println(blinkScreenRegs);
	} 

	/**
	 * Display Segment registers (SR0 -SR3)
	 */
	public void displayBlinkSegments() {
		StringBuffer blinkSegmentRegs = new StringBuffer(128);
		blinkSegmentRegs.append("SR0: " + Dz.byteToHex(z88.getSegmentBank(0), true) + ", ");
		blinkSegmentRegs.append("SR1: " + Dz.byteToHex(z88.getSegmentBank(1), true) + ", ");
		blinkSegmentRegs.append("SR2: " + Dz.byteToHex(z88.getSegmentBank(2), true) + ", ");
		blinkSegmentRegs.append("SR3: " + Dz.byteToHex(z88.getSegmentBank(3), true));
		
		System.out.println(blinkSegmentRegs);
	} 
}
