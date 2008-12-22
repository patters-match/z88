/*
 * Z80.java
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

package net.sourceforge.z88;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;

/**
 * The Z80 class emulates the Zilog Z80 microprocessor. Optimized and added with
 * new features for Z88 virtual machine.
 *
 * -------------------------------------------------------------------------------------
 * Original implementation of Z80 emulation by Adam Davidson & Andrew Pollard.
 *
 * @version 1.1 27 Apr 1997
 * @author <A HREF="http://www.spectrum.lovely.net/">Adam Davidson & Andrew
 *         Pollard </A>
 *
 * @see Jasper
 * @see Spectrum
 *      -------------------------------------------------------------------------------------
 */
public abstract class Z80 {

	private final class LogZ80 {
		private static final int BUFSIZE = 100000;

		private int pcAddressCache[];
		private int registerCache[][];
		private int index;
		private int logFileCounter;

		public LogZ80() {
			pcAddressCache = new int[BUFSIZE];
			registerCache = new int[BUFSIZE][8];
		}

		private boolean isCacheAvailable() {
			return index != 0;
		}

		private void logInstruction() {
			if (index == BUFSIZE) {
				// dump cache to log file, and reset index to 0
				flushCache();
			}

			pcAddressCache[index] = getPcAddress();

			registerCache[index][0] = AF();
			registerCache[index][1] = BC();
			registerCache[index][2] = DE();
			registerCache[index][3] = HL();
			registerCache[index][4] = IX();
			registerCache[index][5] = IY();
			registerCache[index][6] = SP();
			registerCache[index][7] = PC();

			index++;
		}

		/**
		 * Dump executed instruction cache to log file in a background thread..
		 */
		private void flushCache() {
					Dz dz = Dz.getInstance();

					try {
						BufferedWriter out = new BufferedWriter(new FileWriter("z80_" + logFileCounter++ + ".log"));
						StringBuffer dzLine = new StringBuffer(64);
						StringBuffer dzBuf = new StringBuffer(128);
						for (int i=0; i<index; i++) {
							int dzBank = (pcAddressCache[i] >>> 16) & 0xFF;
							int dzOffset = pcAddressCache[i] & 0xFFFF;	// bank	offset

							dz.getInstrAscii(dzLine, registerCache[i][7], dzOffset, dzBank, false, true);
							dzBuf.append(
							                Dz.extAddrToHex( pcAddressCache[i] & 0xff0000 |
							                                (pcAddressCache[i] & 0xffff) |
							                                registerCache[i][7]
							                                , false)
							            );
							dzBuf.append(" ");
							dzBuf.append(dzLine);
							for(int space=31 - dzLine.length(); space>0; space--) dzBuf.append(" ");
							dzBuf.append(
									Z88Info.quickZ80Dump(
											registerCache[i][0], // AF
											registerCache[i][1], // BC
											registerCache[i][2], // DE
											registerCache[i][3], // HL
											registerCache[i][4], // SP
											registerCache[i][5], // IX
											registerCache[i][6]) // IY
											);
							dzBuf.append(System.getProperty("line.separator"));
							out.write(dzBuf.toString());

							dzBuf.delete(0,127);
				        }
				    	out.close();

				    } catch (IOException e) {
				    }

                    // Cache flushed...
    		        index = 0;
		}
	}

	public void flushZ80LogCache() {
		if (lgZ80.isCacheAvailable() == true) {
			lgZ80.flushCache();
		}
	}

	public void setZ80Logging(boolean logState) {
		logZ80instructions = logState;
	}

	public boolean izZ80Logged() {
		return logZ80instructions;
	}

	public Z80() {
		tstatesCounter = 0;

		parity = new boolean[256];
		for (int i = 0; i < 256; i++) {
			boolean p = true;
			for (int j = 0; j < 8; j++) {
				if ((i & (1 << j)) != 0) {
					p = !p;
				}
			}
			parity[i] = p;
		}

		lgZ80 = new LogZ80();
		reset();
	}

	private int tstatesCounter = 0;

	/**
	 * Get and reset Z80 T-States counter
	 */
	public int getTstatesCounter() {
		int c = tstatesCounter;
		tstatesCounter = 0;

		return c;
	}

	private LogZ80 lgZ80;
	private boolean logZ80instructions;

	private boolean externIntSignal = false;

	private boolean z80Stopped = false;

	private static final int tstatesPerInterrupt = (int) ((3.2768 * 1e6) / 50); /* the no of T-states for virtual static interrupt */

	private static final int IM0 = 0;

	private static final int IM1 = 1;

	private static final int IM2 = 2;

	public static final int F_C = 0x01;

	public static final int F_N = 0x02;

	public static final int F_PV = 0x04;

	public static final int F_3 = 0x08;

	public static final int F_H = 0x10;

	public static final int F_5 = 0x20;

	public static final int F_Z = 0x40;

	public static final int F_S = 0x80;

	private final boolean parity[];

	/** Main registers */
	private int _A = 0, _HL = 0, _B = 0, _C = 0, _DE = 0;

	public boolean fS = false, fZ = false, f5 = false, fH = false;

	public boolean f3 = false, fPV = false, fN = false, fC = false;

	/** Alternate registers */
	private int _AF_ = 0, _HL_ = 0, _BC_ = 0, _DE_ = 0;

	/** Index registers - ID used as temporary for ix/iy */
	private int _IX = 0, _IY = 0, _ID = 0;

	/** Stack Pointer and Program Counter */
	private char _SP = 0, _PC = 0;

	/** PC of current instruction (used for warning and error reporting */
	private int instrPC = 0;

	/** Interrupt and Refresh registers */
	private int _I = 0, _R = 0, _R7 = 0;

	/** Interrupt flip-flops */
	private boolean _IFF1 = true, _IFF2 = true;

	private int _IM = 2;

	/** 16 bit register access */
	public final int AF() {
		return (A() << 8) | F();
	}

	public final void AF(int word) {
		A(word >>> 8);
		F(word);
	}

	public final int BC() {
		return (B() << 8) | C();
	}

	public final void BC(int word) {
		B(word >> 8);
		C(word & 0xff);
	}

	public final int DE() {
		return _DE;
	}

	public final void DE(int word) {
		_DE = word;
	}

	public final int HL() {
		return _HL;
	}

	public final void HL(int word) {
		_HL = word;
	}

	public final int PC() {
		return _PC;
	}

	public int getInstrPC() {
		return instrPC;
	}

	public final void PC(int word) {
		_PC = (char) word;
	}

	public final int SP() {
		return _SP;
	}

	public final void SP(int word) {
		_SP = (char) word;
	}

	private final int ID() {
		return _ID;
	}

	private final void ID(int word) {
		_ID = word;
	}

	public final int IX() {
		return _IX;
	}

	public final void IX(int word) {
		_IX = word;
	}

	public final int IY() {
		return _IY;
	}

	public final void IY(int word) {
		_IY = word;
	}

	/** 8 bit register access */
	public final int A() {
		return _A;
	}

	public final void A(int bite) {
		_A = bite;
	}

	public final int F() {
		return (Sset() ? F_S : 0) | (Zset() ? F_Z : 0) | (f5 ? F_5 : 0)
				| (Hset() ? F_H : 0) | (f3 ? F_3 : 0) | (PVset() ? F_PV : 0)
				| (Nset() ? F_N : 0) | (Cset() ? F_C : 0);
	}

	public final void F(int bite) {
		fS = (bite & F_S) != 0;
		fZ = (bite & F_Z) != 0;
		f5 = (bite & F_5) != 0;
		fH = (bite & F_H) != 0;
		f3 = (bite & F_3) != 0;
		fPV = (bite & F_PV) != 0;
		fN = (bite & F_N) != 0;
		fC = (bite & F_C) != 0;
	}

	public final int B() {
		return _B;
	}

	public final void B(int bite) {
		_B = bite;
	}

	public final int C() {
		return _C;
	}

	public final void C(int bite) {
		_C = bite;
	}

	public final int D() {
		return (_DE >> 8);
	}

	public final void D(int bite) {
		_DE = (bite << 8) | (_DE & 0x00ff);
	}

	public final int E() {
		return (_DE & 0xff);
	}

	public final void E(int bite) {
		_DE = (_DE & 0xff00) | bite;
	}

	public final int H() {
		return (_HL >> 8);
	}

	public final void H(int bite) {
		_HL = (bite << 8) | (_HL & 0x00ff);
	}

	public final int L() {
		return (_HL & 0xff);
	}

	public final void L(int bite) {
		_HL = (_HL & 0xff00) | bite;
	}

	private final int IDH() {
		return (_ID >> 8);
	}

	private final void IDH(int bite) {
		_ID = (bite << 8) | (_ID & 0x00ff);
	}

	private final int IDL() {
		return (_ID & 0xff);
	}

	private final void IDL(int bite) {
		_ID = (_ID & 0xff00) | bite;
	}

	/** Memory refresh register */
	private final int R7() {
		return _R7;
	}

	public final int R() {
		return (_R & 0x7f) | _R7;
	}

	public final void R(int bite) {
		_R = bite;
		_R7 = bite & 0x80;
	}

	private final void REFRESH(int t) {
		_R += t;

		if (tstatesCounter > tstatesPerInterrupt) {
			tstatesCounter = 0;
			Thread.yield(); /* give the Java threading system some breath */
		}
	}

	/** Interrupt modes/register */
	public final int I() {
		return _I;
	}

	public final void I(int bite) {
		_I = bite;
	}

	public final boolean IFF1() {
		return _IFF1;
	}

	public final void IFF1(boolean iff1) {
		_IFF1 = iff1;
	}

	public final boolean IFF2() {
		return _IFF2;
	}

	public final void IFF2(boolean iff2) {
		_IFF2 = iff2;
	}

	private boolean nmi = false;

	public boolean getNmi() {
		return nmi;
	}

	public synchronized void setNmi(boolean nmiState) {
		nmi = nmiState;
	}

	public final int IM() {
		return _IM;
	}

	public final void IM(int im) {
		_IM = im;
	}

	/** Flag access */
	private final void setZ(boolean f) {
		fZ = f;
	}

	private final void setC(boolean f) {
		fC = f;
	}

	private final void setS(boolean f) {
		fS = f;
	}

	private final void setH(boolean f) {
		fH = f;
	}

	private final void setN(boolean f) {
		fN = f;
	}

	private final void setPV(boolean f) {
		fPV = f;
	}

	private final void set3(boolean f) {
		f3 = f;
	}

	private final void set5(boolean f) {
		f5 = f;
	}

	public final boolean f3set() {
		return f3;
	}

	public final boolean f5set() {
		return f5;
	}

	public final boolean Zset() {
		return fZ;
	}

	public final boolean Cset() {
		return fC;
	}

	public final boolean Sset() {
		return fS;
	}

	public final boolean Hset() {
		return fH;
	}

	public final boolean Nset() {
		return fN;
	}

	public final boolean PVset() {
		return fPV;
	}

	/** External implementation of HALT instruction */
	public abstract void haltZ80();

	/**
	 * External implementation stop Z80 execution (back to command line or other
	 * state
	 */
	public abstract boolean isZ80Stopped();

	/** External implemenation of Read Byte from the Z80 virtual memory model */
	public abstract int readByte(int addr);

	/** External implemenation of Write byte to the Z80 virtual memory model */
	public abstract void writeByte(int addr, int b);

	/** External implemenation of Read Word from the Z80 virtual memory model */
	public abstract int readWord(final int addr);

	/** External implemenation of Write Word to the Z80 virtual memory model */
	public abstract void writeWord(final int addr, final int w);

	/** External implemenation getting current physical PC address
	 * @return extended PC address */
	public abstract int getPcAddress();

	/**
	 * External implemenation of action to be taken when a breakpoint is
	 * encountered
	 */
	public abstract boolean breakPointAction();

	/**
	 * External implemenation of action to be taken when a display breakpoint is
	 * encountered
	 */
	public abstract void breakPointInfo();

	/** IO ports */
	public abstract void outByte(int addrA8, int addrA15, int bits);

	public abstract int inByte(int addrA8, int addrA15);

	/** Index register access */
	private final int ID_d() {
		return ((ID() + (byte) readByte(_PC++)) & 0xffff);
	}

	/** Stack access, push 16bit value */
	private final void pushw(int word) {
		int sp = (SP() - 2) & 0xffff;
		SP(sp);
		writeWord(sp, word);
	}

	/** Stack access, pop 16bit value */
	private final int popw() {
		int sp = SP();
		int w = readWord(sp);
		SP((sp + 2) & 0xffff);

		return w;
	}

	/** Program Counter Word Access */
	private final int nxtpcw() {
		_PC += 2;
		return readWord(_PC - 2);
	}

	/** Reset all registers to power on state */
	public void reset() {
		PC(0);
		SP(0);

		A(0);
		F(0);
		BC(0);
		DE(0);
		HL(0);

		exx();
		ex_af_af();

		A(0);
		F(0);
		BC(0);
		DE(0);
		HL(0);

		IX(0);
		IY(0);

		R(0);

		I(0);
		IFF1(false);
		IFF2(false);
		IM(IM0);
	}

	/** Interrupt handler */
	public final boolean interruptTriggered() {
		return externIntSignal;
	}

	/** Interrupt handler */
	public final void setInterruptSignal(boolean nmiState) {
		nmi = nmiState;
		externIntSignal = true;
	}

	/** Interrupt handler */
	private final void acknowledgeInterrupt() {
		externIntSignal = false;
	}

	/** process interrupt */
	private boolean execInterrupt() {
		acknowledgeInterrupt();

		if (getNmi() == true) {
			// non maskable interrupt occurred... (overrides DI)
			pushw(_PC);
			IFF1(false);
			IFF2(false);
			PC(0x66);
			tstatesCounter += 13;
			setNmi(false);
			return true;
		}

		switch (IM()) {
		case IM0:
			pushw(_PC);
			IFF1(false);
			IFF2(false);
			PC(0x0066);
			tstatesCounter += 13;
			return true;
		case IM1:
			pushw(_PC);
			IFF1(false);
			IFF2(false);
			PC(0x0038);
			tstatesCounter += 13;
			return true;
		case IM2:
			pushw(_PC);
			IFF1(false);
			IFF2(false);
			int t = (I() << 8) | 0x00ff;
			PC(readWord(t));
			tstatesCounter += 19;
			return true;
		default:
			return false;
		}
	}

	public boolean isZ80running() {
		return !z80Stopped;
	}

	/** Z80 fetch/execute loop, engine full throttle ahead.. */
	public void decode(boolean debugMode) {
		z80Stopped = false;

		do {
			instrPC = _PC; // define origin PC of current instruction

			if (isZ80Stopped() == true) {
				z80Stopped = true;
				return;
			}

			if ((debugMode == false) & IFF1() == true && interruptTriggered() == true) {
				// a maskable interrupt want's to be executed...
				execInterrupt();
			}

			if (logZ80instructions == true) {
				lgZ80.logInstruction();
			}

			REFRESH(1);

			switch (readByte(_PC++)) { // decode first byte from Z80 instruction
				case 0: /* NOP */{
					tstatesCounter += 4;
					break;
				}
				case 8: /* EX AF,AF' */{
					ex_af_af();
					tstatesCounter += 4;
					break;
				}
				case 16: /* DJNZ dis */{
					int b;

					B(b = qdec8(B()));
					if (b != 0) {
						byte d = (byte) readByte(_PC++);
						PC((PC() + d) & 0xffff);
						tstatesCounter += 13;
					} else {
						PC(inc16(PC()));
						tstatesCounter += 8;
					}
					break;
				}
				case 24: /* JR dis */{
					byte d = (byte) readByte(_PC++);
					PC((PC() + d) & 0xffff);
					tstatesCounter += 12;
					break;
				}
				/* JR cc,dis */
				case 32: /* JR NZ,dis */{
					if (!Zset()) {
						byte d = (byte) readByte(_PC++);
						PC((PC() + d) & 0xffff);
						tstatesCounter += 12;
					} else {
						PC(inc16(PC()));
						tstatesCounter += 7;
					}
					break;
				}
				case 40: /* JR Z,dis */{
					if (Zset()) {
						byte d = (byte) readByte(_PC++);
						PC((PC() + d) & 0xffff);
						tstatesCounter += 12;
					} else {
						PC(inc16(PC()));
						tstatesCounter += 7;
					}
					break;
				}
				case 48: /* JR NC,dis */{
					if (!Cset()) {
						byte d = (byte) readByte(_PC++);
						PC((PC() + d) & 0xffff);
						tstatesCounter += 12;
					} else {
						PC(inc16(PC()));
						tstatesCounter += 7;
					}
					break;
				}
				case 56: /* JR C,dis */{
					if (Cset()) {
						byte d = (byte) readByte(_PC++);
						PC((PC() + d) & 0xffff);
						tstatesCounter += 12;
					} else {
						PC(inc16(PC()));
						tstatesCounter += 7;
					}
					break;
				}

				/* LD rr,nn / ADD HL,rr */
				case 1: /* LD BC(),nn */{
					BC(nxtpcw());
					tstatesCounter += 10;
					break;
				}
				case 9: /* ADD HL,BC */{
					HL(add16(HL(), BC()));
					tstatesCounter += 11;
					break;
				}
				case 17: /* LD DE,nn */{
					DE(nxtpcw());
					tstatesCounter += 10;
					break;
				}
				case 25: /* ADD HL,DE */{
					HL(add16(HL(), DE()));
					tstatesCounter += 11;
					break;
				}
				case 33: /* LD HL,nn */{
					HL(nxtpcw());
					tstatesCounter += 10;
					break;
				}
				case 41: /* ADD HL,HL */{
					int hl = HL();
					HL(add16(hl, hl));
					tstatesCounter += 11;
					break;
				}
				case 49: /* LD SP,nn */{
					SP(nxtpcw());
					tstatesCounter += 10;
					break;
				}
				case 57: /* ADD HL,SP */{
					HL(add16(HL(), SP()));
					tstatesCounter += 11;
					break;
				}

				/* LD (**),A/A,(**) */
				case 2: /* LD (BC),A */{
					writeByte(BC(), A());
					tstatesCounter += 7;
					break;
				}
				case 10: /* LD A,(BC) */{
					A(readByte(BC()));
					tstatesCounter += 7;
					break;
				}
				case 18: /* LD (DE),A */{
					writeByte(DE(), A());
					tstatesCounter += 7;
					break;
				}
				case 26: /* LD A,(DE) */{
					A(readByte(DE()));
					tstatesCounter += 7;
					break;
				}
				case 34: /* LD (nn),HL */{
					writeWord(nxtpcw(), HL());
					tstatesCounter += 16;
					break;
				}
				case 42: /* LD HL,(nn) */{
					HL(readWord(nxtpcw()));
					tstatesCounter += 16;
					break;
				}
				case 50: /* LD (nn),A */{
					writeByte(nxtpcw(), A());
					tstatesCounter += 13;
					break;
				}
				case 58: /* LD A,(nn) */{
					A(readByte(nxtpcw()));
					tstatesCounter += 13;
					break;
				}

				/* INC/DEC * */
				case 3: /* INC BC */{
					BC(inc16(BC()));
					tstatesCounter += 6;
					break;
				}
				case 11: /* DEC BC */{
					BC(dec16(BC()));
					tstatesCounter += 6;
					break;
				}
				case 19: /* INC DE */{
					DE(inc16(DE()));
					tstatesCounter += 6;
					break;
				}
				case 27: /* DEC DE */{
					DE(dec16(DE()));
					tstatesCounter += 6;
					break;
				}
				case 35: /* INC HL */{
					HL(inc16(HL()));
					tstatesCounter += 6;
					break;
				}
				case 43: /* DEC HL */{
					HL(dec16(HL()));
					tstatesCounter += 6;
					break;
				}
				case 51: /* INC SP */{
					SP(inc16(SP()));
					tstatesCounter += 6;
					break;
				}
				case 59: /* DEC SP */{
					SP(dec16(SP()));
					tstatesCounter += 6;
					break;
				}

				/* INC * */
				case 4: /* INC B */{
					B(inc8(B()));
					tstatesCounter += 4;
					break;
				}
				case 12: /* INC C */{
					C(inc8(C()));
					tstatesCounter += 4;
					break;
				}
				case 20: /* INC D */{
					D(inc8(D()));
					tstatesCounter += 4;
					break;
				}
				case 28: /* INC E */{
					E(inc8(E()));
					tstatesCounter += 4;
					break;
				}
				case 36: /* INC H */{
					H(inc8(H()));
					tstatesCounter += 4;
					break;
				}
				case 44: /* INC L */{
					L(inc8(L()));
					tstatesCounter += 4;
					break;
				}
				case 52: /* INC (HL) */{
					int hl = HL();
					writeByte(hl, inc8(readByte(hl)));
					tstatesCounter += 11;
					break;
				}
				case 60: /* INC A() */{
					A(inc8(A()));
					tstatesCounter += 4;
					break;
				}

				/* DEC * */
				case 5: /* DEC B */{
					B(dec8(B()));
					tstatesCounter += 4;
					break;
				}
				case 13: /* DEC C */{
					C(dec8(C()));
					tstatesCounter += 4;
					break;
				}
				case 21: /* DEC D */{
					D(dec8(D()));
					tstatesCounter += 4;
					break;
				}
				case 29: /* DEC E */{
					E(dec8(E()));
					tstatesCounter += 4;
					break;
				}
				case 37: /* DEC H */{
					H(dec8(H()));
					tstatesCounter += 4;
					break;
				}
				case 45: /* DEC L */{
					L(dec8(L()));
					tstatesCounter += 4;
					break;
				}
				case 53: /* DEC (HL) */{
					int hl = HL();
					writeByte(hl, dec8(readByte(hl)));
					tstatesCounter += 11;
					break;
				}
				case 61: /* DEC A() */{
					A(dec8(A()));
					tstatesCounter += 4;
					break;
				}

				/* LD *,N */
				case 6: /* LD B,n */{
					B(readByte(_PC++));
					tstatesCounter += 7;
					break;
				}
				case 14: /* LD C,n */{
					C(readByte(_PC++));
					tstatesCounter += 7;
					break;
				}
				case 22: /* LD D,n */{
					D(readByte(_PC++));
					tstatesCounter += 7;
					break;
				}
				case 30: /* LD E,n */{
					E(readByte(_PC++));
					tstatesCounter += 7;
					break;
				}
				case 38: /* LD H,n */{
					H(readByte(_PC++));
					tstatesCounter += 7;
					break;
				}
				case 46: /* LD L,n */{
					L(readByte(_PC++));
					tstatesCounter += 7;
					break;
				}
				case 54: /* LD (HL),n */{
					writeByte(HL(), readByte(_PC++));
					tstatesCounter += 10;
					break;
				}
				case 62: /* LD A,n */{
					A(readByte(_PC++));
					tstatesCounter += 7;
					break;
				}

				/* R**A */
				case 7: /* RLCA */{
					rlc_a();
					tstatesCounter += 4;
					break;
				}
				case 15: /* RRCA */{
					rrc_a();
					tstatesCounter += 4;
					break;
				}
				case 23: /* RLA */{
					rl_a();
					tstatesCounter += 4;
					break;
				}
				case 31: /* RRA */{
					rr_a();
					tstatesCounter += 4;
					break;
				}
				case 39: /* DAA */{
					daa_a();
					tstatesCounter += 4;
					break;
				}
				case 47: /* CPL */{
					cpl_a();
					tstatesCounter += 4;
					break;
				}
				case 55: /* SCF */{
					scf();
					tstatesCounter += 4;
					break;
				}
				case 63: /* CCF */{
					ccf();
					tstatesCounter += 4;
					break;
				}

				/* LD B,? */
				case 64: /* LD B,B */{
					// Stop at encountered breakpoint, if found...
					z80Stopped = breakPointAction();
					tstatesCounter += 4;
					break;
				}
				case 65: /* LD B,C */{
					B(C());
					tstatesCounter += 4;
					break;
				}
				case 66: /* LD B,D */{
					B(D());
					tstatesCounter += 4;
					break;
				}
				case 67: /* LD B,E */{
					B(E());
					tstatesCounter += 4;
					break;
				}
				case 68: /* LD B,H */{
					B(H());
					tstatesCounter += 4;
					break;
				}
				case 69: /* LD B,L */{
					B(L());
					tstatesCounter += 4;
					break;
				}
				case 70: /* LD B,(HL) */{
					B(readByte(HL()));
					tstatesCounter += 7;
					break;
				}

				case 71: /* LD B,A */{
					B(A());
					tstatesCounter += 4;
					break;
				}

				/* LD C,* */
				case 72: /* LD C,B */{
					C(B());
					tstatesCounter += 4;
					break;
				}
				case 73: /* LD C,C */{
					// Dump Z80 register info at breakpoint, then continue execution
					breakPointInfo();
					tstatesCounter += 4;

					break;
				}
				case 74: /* LD C,D */{
					C(D());
					tstatesCounter += 4;
					break;
				}
				case 75: /* LD C,E */{
					C(E());
					tstatesCounter += 4;
					break;
				}
				case 76: /* LD C,H */{
					C(H());
					tstatesCounter += 4;
					break;
				}
				case 77: /* LD C,L */{
					C(L());
					tstatesCounter += 4;
					break;
				}
				case 78: /* LD C,(HL) */{
					C(readByte(HL()));
					tstatesCounter += 7;
					break;
				}
				case 79: /* LD C,A */{
					C(A());
					tstatesCounter += 4;
					break;
				}

				/* LD D,* */
				case 80: /* LD D,B */{
					D(B());
					tstatesCounter += 4;
					break;
				}
				case 81: /* LD D,C */{
					D(C());
					tstatesCounter += 4;
					break;
				}
				case 82: /* LD D,D */{
					tstatesCounter += 4;
					break;
				}
				case 83: /* LD D,E */{
					D(E());
					tstatesCounter += 4;
					break;
				}
				case 84: /* LD D,H */{
					D(H());
					tstatesCounter += 4;
					break;
				}
				case 85: /* LD D,L */{
					D(L());
					tstatesCounter += 4;
					break;
				}
				case 86: /* LD D,(HL) */{
					D(readByte(HL()));
					tstatesCounter += 7;
					break;
				}
				case 87: /* LD D,A */{
					D(A());
					tstatesCounter += 4;
					break;
				}

				/* LD E,* */
				case 88: /* LD E,B */{
					E(B());
					tstatesCounter += 4;
					break;
				}
				case 89: /* LD E,C */{
					E(C());
					tstatesCounter += 4;
					break;
				}
				case 90: /* LD E,D */{
					E(D());
					tstatesCounter += 4;
					break;
				}
				case 91: /* LD E,E */{
					tstatesCounter += 4;
					break;
				}
				case 92: /* LD E,H */{
					E(H());
					tstatesCounter += 4;
					break;
				}
				case 93: /* LD E,L */{
					E(L());
					tstatesCounter += 4;
					break;
				}
				case 94: /* LD E,(HL) */{
					E(readByte(HL()));
					tstatesCounter += 7;
					break;
				}
				case 95: /* LD E,A */{
					E(A());
					tstatesCounter += 4;
					break;
				}

				/* LD H,* */
				case 96: /* LD H,B */{
					H(B());
					tstatesCounter += 4;
					break;
				}
				case 97: /* LD H,C */{
					H(C());
					tstatesCounter += 4;
					break;
				}
				case 98: /* LD H,D */{
					H(D());
					tstatesCounter += 4;
					break;
				}
				case 99: /* LD H,E */{
					H(E());
					tstatesCounter += 4;
					break;
				}
				case 100: /* LD H,H */{
					tstatesCounter += 4;
					break;
				}
				case 101: /* LD H,L */{
					H(L());
					tstatesCounter += 4;
					break;
				}
				case 102: /* LD H,(HL) */{
					H(readByte(HL()));
					tstatesCounter += 7;
					break;
				}
				case 103: /* LD H,A */{
					H(A());
					tstatesCounter += 4;
					break;
				}

				/* LD L,* */
				case 104: /* LD L,B */{
					L(B());
					tstatesCounter += 4;
					break;
				}
				case 105: /* LD L,C */{
					L(C());
					tstatesCounter += 4;
					break;
				}
				case 106: /* LD L,D */{
					L(D());
					tstatesCounter += 4;
					break;
				}
				case 107: /* LD L,E */{
					L(E());
					tstatesCounter += 4;
					break;
				}
				case 108: /* LD L,H */{
					L(H());
					tstatesCounter += 4;
					break;
				}
				case 109: /* LD L,L */{
					tstatesCounter += 4;
					break;
				}
				case 110: /* LD L,(HL) */{
					L(readByte(HL()));
					tstatesCounter += 7;
					break;
				}
				case 111: /* LD L,A */{
					L(A());
					tstatesCounter += 4;
					break;
				}
				/* LD (HL),* */
				case 112: /* LD (HL),B */{
					writeByte(HL(), B());
					tstatesCounter += 7;
					break;
				}
				case 113: /* LD (HL),C */{
					writeByte(HL(), C());
					tstatesCounter += 7;
					break;
				}
				case 114: /* LD (HL),D */{
					writeByte(HL(), D());
					tstatesCounter += 7;
					break;
				}
				case 115: /* LD (HL),E */{
					writeByte(HL(), E());
					tstatesCounter += 7;
					break;
				}
				case 116: /* LD (HL),H */{
					writeByte(HL(), H());
					tstatesCounter += 7;
					break;
				}
				case 117: /* LD (HL),L */{
					writeByte(HL(), L());
					tstatesCounter += 7;
					break;
				}
				case 118: /* HALT */{
					haltZ80();
					tstatesCounter += 4;
					break;
				}

				case 119: /* LD (HL),A */{
					writeByte(HL(), A());
					tstatesCounter += 7;
					break;
				}
				/* LD A,* */
				case 120: /* LD A,B */{
					A(B());
					tstatesCounter += 4;
					break;
				}
				case 121: /* LD A,C */{
					A(C());
					tstatesCounter += 4;
					break;
				}
				case 122: /* LD A,D */{
					A(D());
					tstatesCounter += 4;
					break;
				}
				case 123: /* LD A,E */{
					A(E());
					tstatesCounter += 4;
					break;
				}
				case 124: /* LD A,H */{
					A(H());
					tstatesCounter += 4;
					break;
				}
				case 125: /* LD A,L */{
					A(L());
					tstatesCounter += 4;
					break;
				}
				case 126: /* LD A,(HL) */{
					A(readByte(HL()));
					tstatesCounter += 7;
					break;
				}
				case 127: /* LD A,A */{
					tstatesCounter += 4;
					break;
				}

				/* ADD A,* */
				case 128: /* ADD A,B */{
					add_a(B());
					tstatesCounter += 4;
					break;
				}
				case 129: /* ADD A,C */{
					add_a(C());
					tstatesCounter += 4;
					break;
				}
				case 130: /* ADD A,D */{
					add_a(D());
					tstatesCounter += 4;
					break;
				}
				case 131: /* ADD A,E */{
					add_a(E());
					tstatesCounter += 4;
					break;
				}
				case 132: /* ADD A,H */{
					add_a(H());
					tstatesCounter += 4;
					break;
				}
				case 133: /* ADD A,L */{
					add_a(L());
					tstatesCounter += 4;
					break;
				}
				case 134: /* ADD A,(HL) */{
					add_a(readByte(HL()));
					tstatesCounter += 7;
					break;
				}
				case 135: /* ADD A,A */{
					add_a(A());
					tstatesCounter += 4;
					break;
				}

				/* ADC A,* */
				case 136: /* ADC A,B */{
					adc_a(B());
					tstatesCounter += 4;
					break;
				}
				case 137: /* ADC A,C */{
					adc_a(C());
					tstatesCounter += 4;
					break;
				}
				case 138: /* ADC A,D */{
					adc_a(D());
					tstatesCounter += 4;
					break;
				}
				case 139: /* ADC A,E */{
					adc_a(E());
					tstatesCounter += 4;
					break;
				}
				case 140: /* ADC A,H */{
					adc_a(H());
					tstatesCounter += 4;
					break;
				}
				case 141: /* ADC A,L */{
					adc_a(L());
					tstatesCounter += 4;
					break;
				}
				case 142: /* ADC A,(HL) */{
					adc_a(readByte(HL()));
					tstatesCounter += 7;
					break;
				}
				case 143: /* ADC A,A */{
					adc_a(A());
					tstatesCounter += 4;
					break;
				}

				/* SUB * */
				case 144: /* SUB B */{
					sub_a(B());
					tstatesCounter += 4;
					break;
				}
				case 145: /* SUB C */{
					sub_a(C());
					tstatesCounter += 4;
					break;
				}
				case 146: /* SUB D */{
					sub_a(D());
					tstatesCounter += 4;
					break;
				}
				case 147: /* SUB E */{
					sub_a(E());
					tstatesCounter += 4;
					break;
				}
				case 148: /* SUB H */{
					sub_a(H());
					tstatesCounter += 4;
					break;
				}
				case 149: /* SUB L */{
					sub_a(L());
					tstatesCounter += 4;
					break;
				}
				case 150: /* SUB (HL) */{
					sub_a(readByte(HL()));
					tstatesCounter += 7;
					break;
				}
				case 151: /* SUB A() */{
					sub_a(A());
					tstatesCounter += 4;
					break;
				}

				/* SBC A,* */
				case 152: /* SBC A,B */{
					sbc_a(B());
					tstatesCounter += 4;
					break;
				}
				case 153: /* SBC A,C */{
					sbc_a(C());
					tstatesCounter += 4;
					break;
				}
				case 154: /* SBC A,D */{
					sbc_a(D());
					tstatesCounter += 4;
					break;
				}
				case 155: /* SBC A,E */{
					sbc_a(E());
					tstatesCounter += 4;
					break;
				}
				case 156: /* SBC A,H */{
					sbc_a(H());
					tstatesCounter += 4;
					break;
				}
				case 157: /* SBC A,L */{
					sbc_a(L());
					tstatesCounter += 4;
					break;
				}
				case 158: /* SBC A,(HL) */{
					sbc_a(readByte(HL()));
					tstatesCounter += 7;
					break;
				}
				case 159: /* SBC A,A */{
					sbc_a(A());
					tstatesCounter += 4;
					break;
				}

				/* AND * */
				case 160: /* AND B */{
					and_a(B());
					tstatesCounter += 4;
					break;
				}
				case 161: /* AND C */{
					and_a(C());
					tstatesCounter += 4;
					break;
				}
				case 162: /* AND D */{
					and_a(D());
					tstatesCounter += 4;
					break;
				}
				case 163: /* AND E */{
					and_a(E());
					tstatesCounter += 4;
					break;
				}
				case 164: /* AND H */{
					and_a(H());
					tstatesCounter += 4;
					break;
				}
				case 165: /* AND L */{
					and_a(L());
					tstatesCounter += 4;
					break;
				}
				case 166: /* AND (HL) */{
					and_a(readByte(HL()));
					tstatesCounter += 7;
					break;
				}
				case 167: /* AND A() */{
					and_a(A());
					tstatesCounter += 4;
					break;
				}

				/* XOR * */
				case 168: /* XOR B */{
					xor_a(B());
					tstatesCounter += 4;
					break;
				}
				case 169: /* XOR C */{
					xor_a(C());
					tstatesCounter += 4;
					break;
				}
				case 170: /* XOR D */{
					xor_a(D());
					tstatesCounter += 4;
					break;
				}
				case 171: /* XOR E */{
					xor_a(E());
					tstatesCounter += 4;
					break;
				}
				case 172: /* XOR H */{
					xor_a(H());
					tstatesCounter += 4;
					break;
				}
				case 173: /* XOR L */{
					xor_a(L());
					tstatesCounter += 4;
					break;
				}
				case 174: /* XOR (HL) */{
					xor_a(readByte(HL()));
					tstatesCounter += 7;
					break;
				}
				case 175: /* XOR A() */{
					xor_a(A());
					tstatesCounter += 4;
					break;
				}

				/* OR * */
				case 176: /* OR B */{
					or_a(B());
					tstatesCounter += 4;
					break;
				}
				case 177: /* OR C */{
					or_a(C());
					tstatesCounter += 4;
					break;
				}
				case 178: /* OR D */{
					or_a(D());
					tstatesCounter += 4;
					break;
				}
				case 179: /* OR E */{
					or_a(E());
					tstatesCounter += 4;
					break;
				}
				case 180: /* OR H */{
					or_a(H());
					tstatesCounter += 4;
					break;
				}
				case 181: /* OR L */{
					or_a(L());
					tstatesCounter += 4;
					break;
				}
				case 182: /* OR (HL) */{
					or_a(readByte(HL()));
					tstatesCounter += 7;
					break;
				}
				case 183: /* OR A() */{
					or_a(A());
					tstatesCounter += 4;
					break;
				}

				/* CP * */
				case 184: /* CP B */{
					cp_a(B());
					tstatesCounter += 4;
					break;
				}
				case 185: /* CP C */{
					cp_a(C());
					tstatesCounter += 4;
					break;
				}
				case 186: /* CP D */{
					cp_a(D());
					tstatesCounter += 4;
					break;
				}
				case 187: /* CP E */{
					cp_a(E());
					tstatesCounter += 4;
					break;
				}
				case 188: /* CP H */{
					cp_a(H());
					tstatesCounter += 4;
					break;
				}
				case 189: /* CP L */{
					cp_a(L());
					tstatesCounter += 4;
					break;
				}
				case 190: /* CP (HL) */{
					cp_a(readByte(HL()));
					tstatesCounter += 7;
					break;
				}
				case 191: /* CP A() */{
					cp_a(A());
					tstatesCounter += 4;
					break;
				}

				/* RET cc */
				case 192: /* RET NZ */{
					if (!Zset()) {
						PC(popw());
						tstatesCounter += 11;
					} else {
						tstatesCounter += 5;
					}
					break;
				}
				case 200: /* RET Z */{
					if (Zset()) {
						PC(popw());
						tstatesCounter += 11;
					} else {
						tstatesCounter += 5;
					}
					break;
				}
				case 208: /* RET NC */{
					if (!Cset()) {
						PC(popw());
						tstatesCounter += 11;
					} else {
						tstatesCounter += 5;
					}
					break;
				}
				case 216: /* RET C */{
					if (Cset()) {
						PC(popw());
						tstatesCounter += 11;
					} else {
						tstatesCounter += 5;
					}
					break;
				}
				case 224: /* RET PO */{
					if (!PVset()) {
						PC(popw());
						tstatesCounter += 11;
					} else {
						tstatesCounter += 5;
					}
					break;
				}
				case 232: /* RET PE */{
					if (PVset()) {
						PC(popw());
						tstatesCounter += 11;
					} else {
						tstatesCounter += 5;
					}
					break;
				}
				case 240: /* RET P */{
					if (!Sset()) {
						PC(popw());
						tstatesCounter += 11;
					} else {
						tstatesCounter += 5;
					}
					break;
				}
				case 248: /* RET M */{
					if (Sset()) {
						PC(popw());
						tstatesCounter += 11;
					} else {
						tstatesCounter += 5;
					}
					break;
				}

				/* POP,Various */
				case 193: /* POP BC */{
					BC(popw());
					tstatesCounter += 10;
					break;
				}
				case 201: /* RET */{
					PC(popw());
					tstatesCounter += 10;
					break;
				}
				case 209: /* POP DE */{
					DE(popw());
					tstatesCounter += 10;
					break;
				}
				case 217: /* EXX */{
					exx();
					tstatesCounter += 4;
					break;
				}
				case 225: /* POP HL */{
					HL(popw());
					tstatesCounter += 10;
					break;
				}
				case 233: /* JP (HL) */{
					PC(HL());
					tstatesCounter += 4;
					break;
				}
				case 241: /* POP AF */{
					AF(popw());
					tstatesCounter += 10;
					break;
				}
				case 249: /* LD SP,HL */{
					SP(HL());
					tstatesCounter += 6;
					break;
				}

				/* JP cc,nn */
				case 194: /* JP NZ,nn */{
					if (!Zset()) {
						PC(nxtpcw());
					} else {
						PC((PC() + 2) & 0xffff);
					}
					tstatesCounter += 10;
					break;
				}
				case 202: /* JP Z,nn */{
					if (Zset()) {
						PC(nxtpcw());
					} else {
						PC((PC() + 2) & 0xffff);
					}
					tstatesCounter += 10;
					break;
				}
				case 210: /* JP NC,nn */{
					if (!Cset()) {
						PC(nxtpcw());
					} else {
						PC((PC() + 2) & 0xffff);
					}
					tstatesCounter += 10;
					break;
				}
				case 218: /* JP C,nn */{
					if (Cset()) {
						PC(nxtpcw());
					} else {
						PC((PC() + 2) & 0xffff);
					}
					tstatesCounter += 10;
					break;
				}
				case 226: /* JP PO,nn */{
					if (!PVset()) {
						PC(nxtpcw());
					} else {
						PC((PC() + 2) & 0xffff);
					}
					tstatesCounter += 10;
					break;
				}
				case 234: /* JP PE,nn */{
					if (PVset()) {
						PC(nxtpcw());
					} else {
						PC((PC() + 2) & 0xffff);
					}
					tstatesCounter += 10;
					break;
				}
				case 242: /* JP P,nn */{
					if (!Sset()) {
						PC(nxtpcw());
					} else {
						PC((PC() + 2) & 0xffff);
					}
					tstatesCounter += 10;
					break;
				}
				case 250: /* JP M,nn */{
					if (Sset()) {
						PC(nxtpcw());
					} else {
						PC((PC() + 2) & 0xffff);
					}
					tstatesCounter += 10;
					break;
				}

				/* Various */
				case 195: /* JP nn */{
					PC(nxtpcw());
					tstatesCounter += 10;
					break;
				}
				case 203: /* prefix CB */{
					REFRESH(1);

					switch (readByte(_PC++)) {
						case 0: /* RLC B */{
							B(rlc(B()));
							tstatesCounter += 8;
							break;
						}
						case 1: /* RLC C */{
							C(rlc(C()));
							tstatesCounter += 8;
							break;
						}
						case 2: /* RLC D */{
							D(rlc(D()));
							tstatesCounter += 8;
							break;
						}
						case 3: /* RLC E */{
							E(rlc(E()));
							tstatesCounter += 8;
							break;
						}
						case 4: /* RLC H */{
							H(rlc(H()));
							tstatesCounter += 8;
							break;
						}
						case 5: /* RLC L */{
							L(rlc(L()));
							tstatesCounter += 8;
							break;
						}
						case 6: /* RLC (HL) */{
							int hl = HL();
							writeByte(hl, rlc(readByte(hl)));
							tstatesCounter += 15;
							break;
						}
						case 7: /* RLC A */{
							A(rlc(A()));
							tstatesCounter += 8;
							break;
						}

						case 8: /* RRC B */{
							B(rrc(B()));
							tstatesCounter += 8;
							break;
						}
						case 9: /* RRC C */{
							C(rrc(C()));
							tstatesCounter += 8;
							break;
						}
						case 10: /* RRC D */{
							D(rrc(D()));
							tstatesCounter += 8;
							break;
						}
						case 11: /* RRC E */{
							E(rrc(E()));
							tstatesCounter += 8;
							break;
						}
						case 12: /* RRC H */{
							H(rrc(H()));
							tstatesCounter += 8;
							break;
						}
						case 13: /* RRC L */{
							L(rrc(L()));
							tstatesCounter += 8;
							break;
						}
						case 14: /* RRC (HL) */{
							int hl = HL();
							writeByte(hl, rrc(readByte(hl)));
							tstatesCounter += 15;
							break;
						}
						case 15: /* RRC A */{
							A(rrc(A()));
							tstatesCounter += 8;
							break;
						}

						case 16: /* RL B */{
							B(rl(B()));
							tstatesCounter += 8;
							break;
						}
						case 17: /* RL C */{
							C(rl(C()));
							tstatesCounter += 8;
							break;
						}
						case 18: /* RL D */{
							D(rl(D()));
							tstatesCounter += 8;
							break;
						}
						case 19: /* RL E */{
							E(rl(E()));
							tstatesCounter += 8;
							break;
						}
						case 20: /* RL H */{
							H(rl(H()));
							tstatesCounter += 8;
							break;
						}
						case 21: /* RL L */{
							L(rl(L()));
							tstatesCounter += 8;
							break;
						}
						case 22: /* RL (HL) */{
							int hl = HL();
							writeByte(hl, rl(readByte(hl)));
							tstatesCounter += 15;
							break;
						}
						case 23: /* RL A */{
							A(rl(A()));
							tstatesCounter += 8;
							break;
						}

						case 24: /* RR B */{
							B(rr(B()));
							tstatesCounter += 8;
							break;
						}
						case 25: /* RR C */{
							C(rr(C()));
							tstatesCounter += 8;
							break;
						}
						case 26: /* RR D */{
							D(rr(D()));
							tstatesCounter += 8;
							break;
						}
						case 27: /* RR E */{
							E(rr(E()));
							tstatesCounter += 8;
							break;
						}
						case 28: /* RR H */{
							H(rr(H()));
							tstatesCounter += 8;
							break;
						}
						case 29: /* RR L */{
							L(rr(L()));
							tstatesCounter += 8;
							break;
						}
						case 30: /* RR (HL) */{
							int hl = HL();
							writeByte(hl, rr(readByte(hl)));
							tstatesCounter += 15;
							break;
						}
						case 31: /* RR A */{
							A(rr(A()));
							tstatesCounter += 8;
							break;
						}

						case 32: /* SLA B */{
							B(sla(B()));
							tstatesCounter += 8;
							break;
						}
						case 33: /* SLA C */{
							C(sla(C()));
							tstatesCounter += 8;
							break;
						}
						case 34: /* SLA D */{
							D(sla(D()));
							tstatesCounter += 8;
							break;
						}
						case 35: /* SLA E */{
							E(sla(E()));
							tstatesCounter += 8;
							break;
						}
						case 36: /* SLA H */{
							H(sla(H()));
							tstatesCounter += 8;
							break;
						}
						case 37: /* SLA L */{
							L(sla(L()));
							tstatesCounter += 8;
							break;
						}
						case 38: /* SLA (HL) */{
							int hl = HL();
							writeByte(hl, sla(readByte(hl)));
							tstatesCounter += 15;
							break;
						}
						case 39: /* SLA A */{
							A(sla(A()));
							tstatesCounter += 8;
							break;
						}

						case 40: /* SRA B */{
							B(sra(B()));
							tstatesCounter += 8;
							break;
						}
						case 41: /* SRA C */{
							C(sra(C()));
							tstatesCounter += 8;
							break;
						}
						case 42: /* SRA D */{
							D(sra(D()));
							tstatesCounter += 8;
							break;
						}
						case 43: /* SRA E */{
							E(sra(E()));
							tstatesCounter += 8;
							break;
						}
						case 44: /* SRA H */{
							H(sra(H()));
							tstatesCounter += 8;
							break;
						}
						case 45: /* SRA L */{
							L(sra(L()));
							tstatesCounter += 8;
							break;
						}
						case 46: /* SRA (HL) */{
							int hl = HL();
							writeByte(hl, sra(readByte(hl)));
							tstatesCounter += 15;
							break;
						}
						case 47: /* SRA A */{
							A(sra(A()));
							tstatesCounter += 8;
							break;
						}

						case 48: /* SLS B */{
							B(sls(B()));
							tstatesCounter += 8;
							break;
						}
						case 49: /* SLS C */{
							C(sls(C()));
							tstatesCounter += 8;
							break;
						}
						case 50: /* SLS D */{
							D(sls(D()));
							tstatesCounter += 8;
							break;
						}
						case 51: /* SLS E */{
							E(sls(E()));
							tstatesCounter += 8;
							break;
						}
						case 52: /* SLS H */{
							H(sls(H()));
							tstatesCounter += 8;
							break;
						}
						case 53: /* SLS L */{
							L(sls(L()));
							tstatesCounter += 8;
							break;
						}
						case 54: /* SLS (HL) */{
							int hl = HL();
							writeByte(hl, sls(readByte(hl)));
							tstatesCounter += 15;
							break;
						}
						case 55: /* SLS A */{
							A(sls(A()));
							tstatesCounter += 8;
							break;
						}

						case 56: /* SRL B */{
							B(srl(B()));
							tstatesCounter += 8;
							break;
						}
						case 57: /* SRL C */{
							C(srl(C()));
							tstatesCounter += 8;
							break;
						}
						case 58: /* SRL D */{
							D(srl(D()));
							tstatesCounter += 8;
							break;
						}
						case 59: /* SRL E */{
							E(srl(E()));
							tstatesCounter += 8;
							break;
						}
						case 60: /* SRL H */{
							H(srl(H()));
							tstatesCounter += 8;
							break;
						}
						case 61: /* SRL L */{
							L(srl(L()));
							tstatesCounter += 8;
							break;
						}
						case 62: /* SRL (HL) */{
							int hl = HL();
							writeByte(hl, srl(readByte(hl)));
							tstatesCounter += 15;
							break;
						}
						case 63: /* SRL A */{
							A(srl(A()));
							tstatesCounter += 8;
							break;
						}

						case 64: /* BIT 0,B */{
							bit(0x01, B());
							tstatesCounter += 8;
							break;
						}
						case 65: /* BIT 0,C */{
							bit(0x01, C());
							tstatesCounter += 8;
							break;
						}
						case 66: /* BIT 0,D */{
							bit(0x01, D());
							tstatesCounter += 8;
							break;
						}
						case 67: /* BIT 0,E */{
							bit(0x01, E());
							tstatesCounter += 8;
							break;
						}
						case 68: /* BIT 0,H */{
							bit(0x01, H());
							tstatesCounter += 8;
							break;
						}
						case 69: /* BIT 0,L */{
							bit(0x01, L());
							tstatesCounter += 8;
							break;
						}
						case 70: /* BIT 0,(HL) */{
							bit(0x01, readByte(HL()));
							tstatesCounter += 12;
							break;
						}
						case 71: /* BIT 0,A */{
							bit(0x01, A());
							tstatesCounter += 8;
							break;
						}

						case 72: /* BIT 1,B */{
							bit(0x02, B());
							tstatesCounter += 8;
							break;
						}
						case 73: /* BIT 1,C */{
							bit(0x02, C());
							tstatesCounter += 8;
							break;
						}
						case 74: /* BIT 1,D */{
							bit(0x02, D());
							tstatesCounter += 8;
							break;
						}
						case 75: /* BIT 1,E */{
							bit(0x02, E());
							tstatesCounter += 8;
							break;
						}
						case 76: /* BIT 1,H */{
							bit(0x02, H());
							tstatesCounter += 8;
							break;
						}
						case 77: /* BIT 1,L */{
							bit(0x02, L());
							tstatesCounter += 8;
							break;
						}
						case 78: /* BIT 1,(HL) */{
							bit(0x02, readByte(HL()));
							tstatesCounter += 12;
							break;
						}
						case 79: /* BIT 1,A */{
							bit(0x02, A());
							tstatesCounter += 8;
							break;
						}

						case 80: /* BIT 2,B */{
							bit(0x04, B());
							tstatesCounter += 8;
							break;
						}
						case 81: /* BIT 2,C */{
							bit(0x04, C());
							tstatesCounter += 8;
							break;
						}
						case 82: /* BIT 2,D */{
							bit(0x04, D());
							tstatesCounter += 8;
							break;
						}
						case 83: /* BIT 2,E */{
							bit(0x04, E());
							tstatesCounter += 8;
							break;
						}
						case 84: /* BIT 2,H */{
							bit(0x04, H());
							tstatesCounter += 8;
							break;
						}
						case 85: /* BIT 2,L */{
							bit(0x04, L());
							tstatesCounter += 8;
							break;
						}
						case 86: /* BIT 2,(HL) */{
							bit(0x04, readByte(HL()));
							tstatesCounter += 12;
							break;
						}
						case 87: /* BIT 2,A */{
							bit(0x04, A());
							tstatesCounter += 8;
							break;
						}

						case 88: /* BIT 3,B */{
							bit(0x08, B());
							tstatesCounter += 8;
							break;
						}
						case 89: /* BIT 3,C */{
							bit(0x08, C());
							tstatesCounter += 8;
							break;
						}
						case 90: /* BIT 3,D */{
							bit(0x08, D());
							tstatesCounter += 8;
							break;
						}
						case 91: /* BIT 3,E */{
							bit(0x08, E());
							tstatesCounter += 8;
							break;
						}
						case 92: /* BIT 3,H */{
							bit(0x08, H());
							tstatesCounter += 8;
							break;
						}
						case 93: /* BIT 3,L */{
							bit(0x08, L());
							tstatesCounter += 8;
							break;
						}
						case 94: /* BIT 3,(HL) */{
							bit(0x08, readByte(HL()));
							tstatesCounter += 12;
							break;
						}
						case 95: /* BIT 3,A */{
							bit(0x08, A());
							tstatesCounter += 8;
							break;
						}

						case 96: /* BIT 4,B */{
							bit(0x10, B());
							tstatesCounter += 8;
							break;
						}
						case 97: /* BIT 4,C */{
							bit(0x10, C());
							tstatesCounter += 8;
							break;
						}
						case 98: /* BIT 4,D */{
							bit(0x10, D());
							tstatesCounter += 8;
							break;
						}
						case 99: /* BIT 4,E */{
							bit(0x10, E());
							tstatesCounter += 8;
							break;
						}
						case 100: /* BIT 4,H */{
							bit(0x10, H());
							tstatesCounter += 8;
							break;
						}
						case 101: /* BIT 4,L */{
							bit(0x10, L());
							tstatesCounter += 8;
							break;
						}
						case 102: /* BIT 4,(HL) */{
							bit(0x10, readByte(HL()));
							tstatesCounter += 12;
							break;
						}
						case 103: /* BIT 4,A */{
							bit(0x10, A());
							tstatesCounter += 8;
							break;
						}

						case 104: /* BIT 5,B */{
							bit(0x20, B());
							tstatesCounter += 8;
							break;
						}
						case 105: /* BIT 5,C */{
							bit(0x20, C());
							tstatesCounter += 8;
							break;
						}
						case 106: /* BIT 5,D */{
							bit(0x20, D());
							tstatesCounter += 8;
							break;
						}
						case 107: /* BIT 5,E */{
							bit(0x20, E());
							tstatesCounter += 8;
							break;
						}
						case 108: /* BIT 5,H */{
							bit(0x20, H());
							tstatesCounter += 8;
							break;
						}
						case 109: /* BIT 5,L */{
							bit(0x20, L());
							tstatesCounter += 8;
							break;
						}
						case 110: /* BIT 5,(HL) */{
							bit(0x20, readByte(HL()));
							tstatesCounter += 12;
							break;
						}
						case 111: /* BIT 5,A */{
							bit(0x20, A());
							tstatesCounter += 8;
							break;
						}

						case 112: /* BIT 6,B */{
							bit(0x40, B());
							tstatesCounter += 8;
							break;
						}
						case 113: /* BIT 6,C */{
							bit(0x40, C());
							tstatesCounter += 8;
							break;
						}
						case 114: /* BIT 6,D */{
							bit(0x40, D());
							tstatesCounter += 8;
							break;
						}
						case 115: /* BIT 6,E */{
							bit(0x40, E());
							tstatesCounter += 8;
							break;
						}
						case 116: /* BIT 6,H */{
							bit(0x40, H());
							tstatesCounter += 8;
							break;
						}
						case 117: /* BIT 6,L */{
							bit(0x40, L());
							tstatesCounter += 8;
							break;
						}
						case 118: /* BIT 6,(HL) */{
							bit(0x40, readByte(HL()));
							tstatesCounter += 12;
							break;
						}
						case 119: /* BIT 6,A */{
							bit(0x40, A());
							tstatesCounter += 8;
							break;
						}

						case 120: /* BIT 7,B */{
							bit(0x80, B());
							tstatesCounter += 8;
							break;
						}
						case 121: /* BIT 7,C */{
							bit(0x80, C());
							tstatesCounter += 8;
							break;
						}
						case 122: /* BIT 7,D */{
							bit(0x80, D());
							tstatesCounter += 8;
							break;
						}
						case 123: /* BIT 7,E */{
							bit(0x80, E());
							tstatesCounter += 8;
							break;
						}
						case 124: /* BIT 7,H */{
							bit(0x80, H());
							tstatesCounter += 8;
							break;
						}
						case 125: /* BIT 7,L */{
							bit(0x80, L());
							tstatesCounter += 8;
							break;
						}
						case 126: /* BIT 7,(HL) */{
							bit(0x80, readByte(HL()));
							tstatesCounter += 12;
							break;
						}
						case 127: /* BIT 7,A */{
							bit(0x80, A());
							tstatesCounter += 8;
							break;
						}

						case 128: /* RES 0,B */{
							B(res(0x01, B()));
							tstatesCounter += 8;
							break;
						}
						case 129: /* RES 0,C */{
							C(res(0x01, C()));
							tstatesCounter += 8;
							break;
						}
						case 130: /* RES 0,D */{
							D(res(0x01, D()));
							tstatesCounter += 8;
							break;
						}
						case 131: /* RES 0,E */{
							E(res(0x01, E()));
							tstatesCounter += 8;
							break;
						}
						case 132: /* RES 0,H */{
							H(res(0x01, H()));
							tstatesCounter += 8;
							break;
						}
						case 133: /* RES 0,L */{
							L(res(0x01, L()));
							tstatesCounter += 8;
							break;
						}
						case 134: /* RES 0,(HL) */{
							int hl = HL();
							writeByte(hl, res(0x01, readByte(hl)));
							tstatesCounter += 15;
							break;
						}
						case 135: /* RES 0,A */{
							A(res(0x01, A()));
							tstatesCounter += 8;
							break;
						}

						case 136: /* RES 1,B */{
							B(res(0x02, B()));
							tstatesCounter += 8;
							break;
						}
						case 137: /* RES 1,C */{
							C(res(0x02, C()));
							tstatesCounter += 8;
							break;
						}
						case 138: /* RES 1,D */{
							D(res(0x02, D()));
							tstatesCounter += 8;
							break;
						}
						case 139: /* RES 1,E */{
							E(res(0x02, E()));
							tstatesCounter += 8;
							break;
						}
						case 140: /* RES 1,H */{
							H(res(0x02, H()));
							tstatesCounter += 8;
							break;
						}
						case 141: /* RES 1,L */{
							L(res(0x02, L()));
							tstatesCounter += 8;
							break;
						}
						case 142: /* RES 1,(HL) */{
							int hl = HL();
							writeByte(hl, res(0x02, readByte(hl)));
							tstatesCounter += 15;
							break;
						}
						case 143: /* RES 1,A */{
							A(res(0x02, A()));
							tstatesCounter += 8;
							break;
						}

						case 144: /* RES 2,B */{
							B(res(0x04, B()));
							tstatesCounter += 8;
							break;
						}
						case 145: /* RES 2,C */{
							C(res(0x04, C()));
							tstatesCounter += 8;
							break;
						}
						case 146: /* RES 2,D */{
							D(res(0x04, D()));
							tstatesCounter += 8;
							break;
						}
						case 147: /* RES 2,E */{
							E(res(0x04, E()));
							tstatesCounter += 8;
							break;
						}
						case 148: /* RES 2,H */{
							H(res(0x04, H()));
							tstatesCounter += 8;
							break;
						}
						case 149: /* RES 2,L */{
							L(res(0x04, L()));
							tstatesCounter += 8;
							break;
						}
						case 150: /* RES 2,(HL) */{
							int hl = HL();
							writeByte(hl, res(0x04, readByte(hl)));
							tstatesCounter += 15;
							break;
						}
						case 151: /* RES 2,A */{
							A(res(0x04, A()));
							tstatesCounter += 8;
							break;
						}

						case 152: /* RES 3,B */{
							B(res(0x08, B()));
							tstatesCounter += 8;
							break;
						}
						case 153: /* RES 3,C */{
							C(res(0x08, C()));
							tstatesCounter += 8;
							break;
						}
						case 154: /* RES 3,D */{
							D(res(0x08, D()));
							tstatesCounter += 8;
							break;
						}
						case 155: /* RES 3,E */{
							E(res(0x08, E()));
							tstatesCounter += 8;
							break;
						}
						case 156: /* RES 3,H */{
							H(res(0x08, H()));
							tstatesCounter += 8;
							break;
						}
						case 157: /* RES 3,L */{
							L(res(0x08, L()));
							tstatesCounter += 8;
							break;
						}
						case 158: /* RES 3,(HL) */{
							int hl = HL();
							writeByte(hl, res(0x08, readByte(hl)));
							tstatesCounter += 15;
							break;
						}
						case 159: /* RES 3,A */{
							A(res(0x08, A()));
							tstatesCounter += 8;
							break;
						}

						case 160: /* RES 4,B */{
							B(res(0x10, B()));
							tstatesCounter += 8;
							break;
						}
						case 161: /* RES 4,C */{
							C(res(0x10, C()));
							tstatesCounter += 8;
							break;
						}
						case 162: /* RES 4,D */{
							D(res(0x10, D()));
							tstatesCounter += 8;
							break;
						}
						case 163: /* RES 4,E */{
							E(res(0x10, E()));
							tstatesCounter += 8;
							break;
						}
						case 164: /* RES 4,H */{
							H(res(0x10, H()));
							tstatesCounter += 8;
							break;
						}
						case 165: /* RES 4,L */{
							L(res(0x10, L()));
							tstatesCounter += 8;
							break;
						}
						case 166: /* RES 4,(HL) */{
							int hl = HL();
							writeByte(hl, res(0x10, readByte(hl)));
							tstatesCounter += 15;
							break;
						}
						case 167: /* RES 4,A */{
							A(res(0x10, A()));
							tstatesCounter += 8;
							break;
						}

						case 168: /* RES 5,B */{
							B(res(0x20, B()));
							tstatesCounter += 8;
							break;
						}
						case 169: /* RES 5,C */{
							C(res(0x20, C()));
							tstatesCounter += 8;
							break;
						}
						case 170: /* RES 5,D */{
							D(res(0x20, D()));
							tstatesCounter += 8;
							break;
						}
						case 171: /* RES 5,E */{
							E(res(0x20, E()));
							tstatesCounter += 8;
							break;
						}
						case 172: /* RES 5,H */{
							H(res(0x20, H()));
							tstatesCounter += 8;
							break;
						}
						case 173: /* RES 5,L */{
							L(res(0x20, L()));
							tstatesCounter += 8;
							break;
						}
						case 174: /* RES 5,(HL) */{
							int hl = HL();
							writeByte(hl, res(0x20, readByte(hl)));
							tstatesCounter += 15;
							break;
						}
						case 175: /* RES 5,A */{
							A(res(0x20, A()));
							tstatesCounter += 8;
							break;
						}

						case 176: /* RES 6,B */{
							B(res(0x40, B()));
							tstatesCounter += 8;
							break;
						}
						case 177: /* RES 6,C */{
							C(res(0x40, C()));
							tstatesCounter += 8;
							break;
						}
						case 178: /* RES 6,D */{
							D(res(0x40, D()));
							tstatesCounter += 8;
							break;
						}
						case 179: /* RES 6,E */{
							E(res(0x40, E()));
							tstatesCounter += 8;
							break;
						}
						case 180: /* RES 6,H */{
							H(res(0x40, H()));
							tstatesCounter += 8;
							break;
						}
						case 181: /* RES 6,L */{
							L(res(0x40, L()));
							tstatesCounter += 8;
							break;
						}
						case 182: /* RES 6,(HL) */{
							int hl = HL();
							writeByte(hl, res(0x40, readByte(hl)));
							tstatesCounter += 15;
							break;
						}
						case 183: /* RES 6,A */{
							A(res(0x40, A()));
							tstatesCounter += 8;
							break;
						}

						case 184: /* RES 7,B */{
							B(res(0x80, B()));
							tstatesCounter += 8;
							break;
						}
						case 185: /* RES 7,C */{
							C(res(0x80, C()));
							tstatesCounter += 8;
							break;
						}
						case 186: /* RES 7,D */{
							D(res(0x80, D()));
							tstatesCounter += 8;
							break;
						}
						case 187: /* RES 7,E */{
							E(res(0x80, E()));
							tstatesCounter += 8;
							break;
						}
						case 188: /* RES 7,H */{
							H(res(0x80, H()));
							tstatesCounter += 8;
							break;
						}
						case 189: /* RES 7,L */{
							L(res(0x80, L()));
							tstatesCounter += 8;
							break;
						}
						case 190: /* RES 7,(HL) */{
							int hl = HL();
							writeByte(hl, res(0x80, readByte(hl)));
							tstatesCounter += 15;
							break;
						}
						case 191: /* RES 7,A */{
							A(res(0x80, A()));
							tstatesCounter += 8;
							break;
						}

						case 192: /* SET 0,B */{
							B(set(0x01, B()));
							tstatesCounter += 8;
							break;
						}
						case 193: /* SET 0,C */{
							C(set(0x01, C()));
							tstatesCounter += 8;
							break;
						}
						case 194: /* SET 0,D */{
							D(set(0x01, D()));
							tstatesCounter += 8;
							break;
						}
						case 195: /* SET 0,E */{
							E(set(0x01, E()));
							tstatesCounter += 8;
							break;
						}
						case 196: /* SET 0,H */{
							H(set(0x01, H()));
							tstatesCounter += 8;
							break;
						}
						case 197: /* SET 0,L */{
							L(set(0x01, L()));
							tstatesCounter += 8;
							break;
						}
						case 198: /* SET 0,(HL) */{
							int hl = HL();
							writeByte(hl, set(0x01, readByte(hl)));
							tstatesCounter += 15;
							break;
						}
						case 199: /* SET 0,A */{
							A(set(0x01, A()));
							tstatesCounter += 8;
							break;
						}

						case 200: /* SET 1,B */{
							B(set(0x02, B()));
							tstatesCounter += 8;
							break;
						}
						case 201: /* SET 1,C */{
							C(set(0x02, C()));
							tstatesCounter += 8;
							break;
						}
						case 202: /* SET 1,D */{
							D(set(0x02, D()));
							tstatesCounter += 8;
							break;
						}
						case 203: /* SET 1,E */{
							E(set(0x02, E()));
							tstatesCounter += 8;
							break;
						}
						case 204: /* SET 1,H */{
							H(set(0x02, H()));
							tstatesCounter += 8;
							break;
						}
						case 205: /* SET 1,L */{
							L(set(0x02, L()));
							tstatesCounter += 8;
							break;
						}
						case 206: /* SET 1,(HL) */{
							int hl = HL();
							writeByte(hl, set(0x02, readByte(hl)));
							tstatesCounter += 15;
							break;
						}
						case 207: /* SET 1,A */{
							A(set(0x02, A()));
							tstatesCounter += 8;
							break;
						}

						case 208: /* SET 2,B */{
							B(set(0x04, B()));
							tstatesCounter += 8;
							break;
						}
						case 209: /* SET 2,C */{
							C(set(0x04, C()));
							tstatesCounter += 8;
							break;
						}
						case 210: /* SET 2,D */{
							D(set(0x04, D()));
							tstatesCounter += 8;
							break;
						}
						case 211: /* SET 2,E */{
							E(set(0x04, E()));
							tstatesCounter += 8;
							break;
						}
						case 212: /* SET 2,H */{
							H(set(0x04, H()));
							tstatesCounter += 8;
							break;
						}
						case 213: /* SET 2,L */{
							L(set(0x04, L()));
							tstatesCounter += 8;
							break;
						}
						case 214: /* SET 2,(HL) */{
							int hl = HL();
							writeByte(hl, set(0x04, readByte(hl)));
							tstatesCounter += 15;
							break;
						}
						case 215: /* SET 2,A */{
							A(set(0x04, A()));
							tstatesCounter += 8;
							break;
						}

						case 216: /* SET 3,B */{
							B(set(0x08, B()));
							tstatesCounter += 8;
							break;
						}
						case 217: /* SET 3,C */{
							C(set(0x08, C()));
							tstatesCounter += 8;
							break;
						}
						case 218: /* SET 3,D */{
							D(set(0x08, D()));
							tstatesCounter += 8;
							break;
						}
						case 219: /* SET 3,E */{
							E(set(0x08, E()));
							tstatesCounter += 8;
							break;
						}
						case 220: /* SET 3,H */{
							H(set(0x08, H()));
							tstatesCounter += 8;
							break;
						}
						case 221: /* SET 3,L */{
							L(set(0x08, L()));
							tstatesCounter += 8;
							break;
						}
						case 222: /* SET 3,(HL) */{
							int hl = HL();
							writeByte(hl, set(0x08, readByte(hl)));
							tstatesCounter += (15);
							break;
						}
						case 223: /* SET 3,A */{
							A(set(0x08, A()));
							tstatesCounter += 8;
							break;
						}

						case 224: /* SET 4,B */{
							B(set(0x10, B()));
							tstatesCounter += 8;
							break;
						}
						case 225: /* SET 4,C */{
							C(set(0x10, C()));
							tstatesCounter += 8;
							break;
						}
						case 226: /* SET 4,D */{
							D(set(0x10, D()));
							tstatesCounter += 8;
							break;
						}
						case 227: /* SET 4,E */{
							E(set(0x10, E()));
							tstatesCounter += 8;
							break;
						}
						case 228: /* SET 4,H */{
							H(set(0x10, H()));
							tstatesCounter += 8;
							break;
						}
						case 229: /* SET 4,L */{
							L(set(0x10, L()));
							tstatesCounter += 8;
							break;
						}
						case 230: /* SET 4,(HL) */{
							int hl = HL();
							writeByte(hl, set(0x10, readByte(hl)));
							tstatesCounter += 15;
							break;
						}
						case 231: /* SET 4,A */{
							A(set(0x10, A()));
							tstatesCounter += 8;
							break;
						}

						case 232: /* SET 5,B */{
							B(set(0x20, B()));
							tstatesCounter += 8;
							break;
						}
						case 233: /* SET 5,C */{
							C(set(0x20, C()));
							tstatesCounter += 8;
							break;
						}
						case 234: /* SET 5,D */{
							D(set(0x20, D()));
							tstatesCounter += 8;
							break;
						}
						case 235: /* SET 5,E */{
							E(set(0x20, E()));
							tstatesCounter += 8;
							break;
						}
						case 236: /* SET 5,H */{
							H(set(0x20, H()));
							tstatesCounter += 8;
							break;
						}
						case 237: /* SET 5,L */{
							L(set(0x20, L()));
							tstatesCounter += 8;
							break;
						}
						case 238: /* SET 5,(HL) */{
							int hl = HL();
							writeByte(hl, set(0x20, readByte(hl)));
							tstatesCounter += 15;
							break;
						}
						case 239: /* SET 5,A */{
							A(set(0x20, A()));
							tstatesCounter += 8;
							break;
						}

						case 240: /* SET 6,B */{
							B(set(0x40, B()));
							tstatesCounter += 8;
							break;
						}
						case 241: /* SET 6,C */{
							C(set(0x40, C()));
							tstatesCounter += 8;
							break;
						}
						case 242: /* SET 6,D */{
							D(set(0x40, D()));
							tstatesCounter += 8;
							break;
						}
						case 243: /* SET 6,E */{
							E(set(0x40, E()));
							tstatesCounter += 8;
							break;
						}
						case 244: /* SET 6,H */{
							H(set(0x40, H()));
							tstatesCounter += 8;
							break;
						}
						case 245: /* SET 6,L */{
							L(set(0x40, L()));
							tstatesCounter += 8;
							break;
						}
						case 246: /* SET 6,(HL) */{
							int hl = HL();
							writeByte(hl, set(0x40, readByte(hl)));
							tstatesCounter += 15;
							break;
						}
						case 247: /* SET 6,A */{
							A(set(0x40, A()));
							tstatesCounter += 8;
							break;
						}

						case 248: /* SET 7,B */{
							B(set(0x80, B()));
							tstatesCounter += 8;
							break;
						}
						case 249: /* SET 7,C */{
							C(set(0x80, C()));
							tstatesCounter += 8;
							break;
						}
						case 250: /* SET 7,D */{
							D(set(0x80, D()));
							tstatesCounter += 8;
							break;
						}
						case 251: /* SET 7,E */{
							E(set(0x80, E()));
							tstatesCounter += 8;
							break;
						}
						case 252: /* SET 7,H */{
							H(set(0x80, H()));
							tstatesCounter += 8;
							break;
						}
						case 253: /* SET 7,L */{
							L(set(0x80, L()));
							tstatesCounter += 8;
							break;
						}
						case 254: /* SET 7,(HL) */{
							int hl = HL();
							writeByte(hl, set(0x80, readByte(hl)));
							tstatesCounter += 15;
							break;
						}
						case 255: /* SET 7,A */{
							A(set(0x80, A()));
							tstatesCounter += 8;
							break;
						}
					} // CB opcode group instructions
					break;
				}

				case 211: /* OUT (n),A */{
					outByte(readByte(_PC++), A(), A());
					tstatesCounter += 11;
					break;
				}
				case 219: /* IN A,(n) */{
					A(inByte(readByte(_PC++), A()));
					tstatesCounter += 11;
					break;
				}
				case 227: /* EX (SP),HL */{
					int hl = HL();
					int sp = SP();
					HL(readWord(sp));
					writeWord(sp, hl);
					tstatesCounter += 19;
					break;
				}
				case 235: /* EX DE,HL */{
					int hl = HL();
					HL(DE());
					DE(hl);
					tstatesCounter += 4;
					break;
				}
				case 243: /* DI */{
					IFF1(false);
					IFF2(false);
					tstatesCounter += 4;
					break;
				}
				case 251: /* EI */{
					tstatesCounter += 4;
					if (debugMode == false)
						decode(true); // execute a single instruction after EI...
					IFF1(true); // open up for interrupts again...
					IFF2(true);
					break;
				}

				/* CALL cc,nn */
				case 196: /* CALL NZ,nn */{
					if (!Zset()) {
						int nn = nxtpcw();
						pushw(_PC);
						PC(nn);
						tstatesCounter += 17;
					} else {
						PC((PC() + 2) & 0xffff);
						tstatesCounter += 10;
					}
					break;
				}
				case 204: /* CALL Z,nn */{
					if (Zset()) {
						int nn = nxtpcw();
						pushw(_PC);
						PC(nn);
						tstatesCounter += 17;
					} else {
						PC((PC() + 2) & 0xffff);
						tstatesCounter += 10;
					}
					break;
				}
				case 212: /* CALL NC,nn */{
					if (!Cset()) {
						int nn = nxtpcw();
						pushw(_PC);
						PC(nn);
						tstatesCounter += 17;
					} else {
						PC((PC() + 2) & 0xffff);
						tstatesCounter += 10;
					}
					break;
				}
				case 220: /* CALL C,nn */{
					if (Cset()) {
						int nn = nxtpcw();
						pushw(_PC);
						PC(nn);
						tstatesCounter += 17;
					} else {
						PC((PC() + 2) & 0xffff);
						tstatesCounter += 10;
					}
					break;
				}
				case 228: /* CALL PO,nn */{
					if (!PVset()) {
						int nn = nxtpcw();
						pushw(_PC);
						PC(nn);
						tstatesCounter += 17;
					} else {
						PC((PC() + 2) & 0xffff);
						tstatesCounter += 10;
					}
					break;
				}
				case 236: /* CALL PE,nn */{
					if (PVset()) {
						int nn = nxtpcw();
						pushw(_PC);
						PC(nn);
						tstatesCounter += 17;
					} else {
						PC((PC() + 2) & 0xffff);
						tstatesCounter += 10;
					}
					break;
				}
				case 244: /* CALL P,nn */{
					if (!Sset()) {
						int nn = nxtpcw();
						pushw(_PC);
						PC(nn);
						tstatesCounter += 17;
					} else {
						PC((PC() + 2) & 0xffff);
						tstatesCounter += 10;
					}
					break;
				}
				case 252: /* CALL M,nn */{
					if (Sset()) {
						int nn = nxtpcw();
						pushw(_PC);
						PC(nn);
						tstatesCounter += 17;
					} else {
						PC((PC() + 2) & 0xffff);
						tstatesCounter += 10;
					}
					break;
				}

				/* PUSH,Various */
				case 197: /* PUSH BC */{
					pushw(BC());
					tstatesCounter += 11;
					break;
				}
				case 205: /* CALL nn */{
					int nn = nxtpcw();
					pushw(_PC);
					PC(nn);
					tstatesCounter += 17;
					break;
				}
				case 213: /* PUSH DE */{
					pushw(DE());
					tstatesCounter += 11;
					break;
				}
				case 221: /* prefix IX */{
					ID(IX());
					execute_id();
					IX(ID());
					break;
				}
				case 229: /* PUSH HL */{
					pushw(HL());
					tstatesCounter += 11;
					break;
				}

				case 237: /* prefix ED */{
					REFRESH(1);

					switch (readByte(_PC++)) {
						case 0: /* NOP */
						case 1:
						case 2:
						case 3:
						case 4:
						case 5:
						case 6:
						case 7:
						case 8:
						case 9:
						case 10:
						case 11:
						case 12:
						case 13:
						case 14:
						case 15:
						case 16:
						case 17:
						case 18:
						case 19:
						case 20:
						case 21:
						case 22:
						case 23:
						case 24:
						case 25:
						case 26:
						case 27:
						case 28:
						case 29:
						case 30:
						case 31:
						case 32:
						case 33:
						case 34:
						case 35:
						case 36:
						case 37:
						case 38:
						case 39:
						case 40:
						case 41:
						case 42:
						case 43:
						case 44:
						case 45:
						case 46:
						case 47:
						case 48:
						case 49:
						case 50:
						case 51:
						case 52:
						case 53:
						case 54:
						case 55:
						case 56:
						case 57:
						case 58:
						case 59:
						case 60:
						case 61:
						case 62:
						case 63:
						case 127:

						case 129:
						case 130:
						case 131:
						case 132:
						case 133:
						case 134:
						case 135:
						case 136:
						case 137:
						case 138:
						case 139:
						case 140:
						case 141:
						case 142:
						case 143:
						case 144:
						case 145:
						case 146:
						case 147:
						case 148:
						case 149:
						case 150:
						case 151:
						case 152:
						case 153:
						case 154:
						case 155:
						case 156:
						case 157:
						case 158:
						case 159:

						case 164:
						case 165:
						case 166:
						case 167:

						case 172:
						case 173:
						case 174:
						case 175:

						case 180:
						case 181:
						case 182:
						case 183: {
							tstatesCounter += 8;
							break;
						}

						case 128: {
							tstatesCounter += 4;
							break;
						}

						/* IN r,(c) */
						case 64: /* IN B,(c) */{
							B(in_bc());
							tstatesCounter += 12;
							break;
						}
						case 72: /* IN C,(c) */{
							C(in_bc());
							tstatesCounter += 12;
							break;
						}
						case 80: /* IN D,(c) */{
							D(in_bc());
							tstatesCounter += 12;
							break;
						}
						case 88: /* IN E,(c) */{
							E(in_bc());
							tstatesCounter += 12;
							break;
						}
						case 96: /* IN H,(c) */{
							H(in_bc());
							tstatesCounter += 12;
							break;
						}
						case 104: /* IN L,(c) */{
							L(in_bc());
							tstatesCounter += 12;
							break;
						}
						case 112: /* IN (c) */{
							in_bc();
							tstatesCounter += 12;
							break;
						}
						case 120: /* IN A,(c) */{
							A(in_bc());
							tstatesCounter += 12;
							break;
						}

						/* OUT (c),r */
						case 65: /* OUT (c),B */{
							outByte(C(), B(), B());
							tstatesCounter += 12;
							break;
						}
						case 73: /* OUT (c),C */{
							outByte(C(), B(), C());
							tstatesCounter += 12;
							break;
						}
						case 81: /* OUT (c),D */{
							outByte(C(), B(), D());
							tstatesCounter += 12;
							break;
						}
						case 89: /* OUT (c),E */{
							outByte(C(), B(), E());
							tstatesCounter += 12;
							break;
						}
						case 97: /* OUT (c),H */{
							outByte(C(), B(), H());
							tstatesCounter += 12;
							break;
						}
						case 105: /* OUT (c),L */{
							outByte(C(), B(), L());
							tstatesCounter += 12;
							break;
						}
						case 113: /* OUT (c),0 */{
							outByte(C(), B(), 0);
							tstatesCounter += 12;
							break;
						}
						case 121: /* OUT (c),A */{
							outByte(C(), B(), A());
							tstatesCounter += 12;
							break;
						}

						/* SBC/ADC HL,ss */
						case 66: /* SBC HL,BC */{
							HL(sbc16(HL(), BC()));
							tstatesCounter += (15);
							break;
						}
						case 74: /* ADC HL,BC */{
							HL(adc16(HL(), BC()));
							tstatesCounter += (15);
							break;
						}
						case 82: /* SBC HL,DE */{
							HL(sbc16(HL(), DE()));
							tstatesCounter += (15);
							break;
						}
						case 90: /* ADC HL,DE */{
							HL(adc16(HL(), DE()));
							tstatesCounter += (15);
							break;
						}
						case 98: /* SBC HL,HL */{
							int hl = HL();
							HL(sbc16(hl, hl));
							tstatesCounter += (15);
							break;
						}
						case 106: /* ADC HL,HL */{
							int hl = HL();
							HL(adc16(hl, hl));
							tstatesCounter += (15);
							break;
						}
						case 114: /* SBC HL,SP */{
							HL(sbc16(HL(), SP()));
							tstatesCounter += (15);
							break;
						}
						case 122: /* ADC HL,SP */{
							HL(adc16(HL(), SP()));
							tstatesCounter += (15);
							break;
						}

						/* LD (nn),ss, LD ss,(nn) */
						case 67: /* LD (nn),BC */{
							writeWord(nxtpcw(), BC());
							tstatesCounter += (20);
							break;
						}
						case 75: /* LD BC,(nn) */{
							BC(readWord(nxtpcw()));
							tstatesCounter += (20);
							break;
						}
						case 83: /* LD (nn),DE */{
							writeWord(nxtpcw(), DE());
							tstatesCounter += (20);
							break;
						}
						case 91: /* LD DE,(nn) */{
							DE(readWord(nxtpcw()));
							tstatesCounter += (20);
							break;
						}
						case 99: /* LD (nn),HL */{
							writeWord(nxtpcw(), HL());
							tstatesCounter += (20);
							break;
						}
						case 107: /* LD HL,(nn) */{
							HL(readWord(nxtpcw()));
							tstatesCounter += (20);
							break;
						}
						case 115: /* LD (nn),SP */{
							writeWord(nxtpcw(), SP());
							tstatesCounter += (20);
							break;
						}
						case 123: /* LD SP,(nn) */{
							SP(readWord(nxtpcw()));
							tstatesCounter += (20);
							break;
						}

						/* NEG */
						case 68: /* NEG */
						case 76: /* NEG */
						case 84: /* NEG */
						case 92: /* NEG */
						case 100: /* NEG */
						case 108: /* NEG */
						case 116: /* NEG */
						case 124: /* NEG */{
							neg_a();
							tstatesCounter += 8;
							break;
						}

						/* RETn */
						case 69: /* RETN */
						case 85: /* RETN */
						case 101: /* RETN */
						case 117: /* RETN */{
							IFF1(IFF2());
							PC(popw());
							tstatesCounter += (14);
							break;
						}
						case 77: /* RETI */
						case 93: /* RETI */
						case 109: /* RETI */
						case 125: /* RETI */{
							PC(popw());
							tstatesCounter += (14);
							break;
						}

						/* IM x */
						case 70: /* IM 0 */
						case 78: /* IM 0 */
						case 102: /* IM 0 */
						case 110: /* IM 0 */{
							IM(IM0);
							tstatesCounter += 8;
							break;
						}
						case 86: /* IM 1 */
						case 118: /* IM 1 */{
							IM(IM1);
							tstatesCounter += 8;
							break;
						}
						case 94: /* IM 2 */
						case 126: /* IM 2 */{
							IM(IM2);
							tstatesCounter += 8;
							break;
						}

						/* LD A,s / LD s,A / RxD */
						case 71: /* LD I,A */{
							I(A());
							tstatesCounter += 9;
							break;
						}
						case 79: /* LD R,A */{
							R(A());
							tstatesCounter += 9;
							break;
						}
						case 87: /* LD A,I */{
							ld_a_i();
							tstatesCounter += 9;
							break;
						}
						case 95: /* LD A,R */{
							ld_a_r();
							tstatesCounter += 9;
							break;
						}
						case 103: /* RRD */{
							rrd_a();
							tstatesCounter += (18);
							break;
						}
						case 111: /* RLD */{
							rld_a();
							tstatesCounter += (18);
							break;
						}

						/* xxI */
						case 160: /* LDI */{
							writeByte(DE(), readByte(HL()));
							DE(inc16(DE()));
							HL(inc16(HL()));
							BC(dec16(BC()));

							setPV(BC() != 0);
							setH(false);
							setN(false);

							tstatesCounter += 16;
							break;
						}
						case 161: /* CPI */{
							boolean c = Cset();

							cp_a(readByte(HL()));
							HL(inc16(HL()));
							BC(dec16(BC()));

							setPV(BC() != 0);
							setC(c);

							tstatesCounter += 16;
							break;
						}
						case 162: /* INI */{
							int b;
							writeByte(HL(), inByte(C(), B()));
							B(b = qdec8(B()));
							HL(inc16(HL()));

							setZ(b == 0);
							setN(true);

							tstatesCounter += 16;
							break;
						}
						case 163: /* OUTI */{
							int b;
							B(b = qdec8(B()));
							outByte(C(), B(), readByte(HL()));
							HL(inc16(HL()));

							setZ(b == 0);
							setN(true);

							tstatesCounter += 16;
							break;
						}

						/* xxD */
						case 168: /* LDD */{
							writeByte(DE(), readByte(HL()));
							DE(dec16(DE()));
							HL(dec16(HL()));
							BC(dec16(BC()));

							setPV(BC() != 0);
							setH(false);
							setN(false);

							tstatesCounter += 16;
							break;
						}
						case 169: /* CPD */{
							boolean c = Cset();

							cp_a(readByte(HL()));
							HL(dec16(HL()));
							BC(dec16(BC()));

							setPV(BC() != 0);
							setC(c);

							tstatesCounter += 16;
							break;
						}
						case 170: /* IND */{
							int b;
							writeByte(HL(), inByte(C(), B()));
							B(b = qdec8(B()));
							HL(dec16(HL()));

							setZ(b == 0);
							setN(true);

							tstatesCounter += 16;
							break;
						}
						case 171: /* OUTD */{
							int b;
							B(b = qdec8(B()));
							outByte(C(), B(), readByte(HL()));
							HL(dec16(HL()));

							setZ(b == 0);
							setN(true);

							tstatesCounter += 16;
							break;
						}

						/* xxIR */
						case 176: /* LDIR */{
							int count, dest, from;

							count = BC();
							dest = DE();
							from = HL();
							REFRESH(-2);
							do {
								writeByte(dest, readByte(from));
								from = inc16(from);
								dest = inc16(dest);
								count = dec16(count);

								tstatesCounter += 21;
								REFRESH(2);
							} while (count != 0);
							if (count != 0) {
								PC((PC() - 2) & 0xffff);
								setH(false);
								setN(false);
								setPV(true);
							} else {
								tstatesCounter -= 5;
								setH(false);
								setN(false);
								setPV(false);
							}
							DE(dest);
							HL(from);
							BC(count);
							break;
						}
						case 177: /* CPIR */{
							boolean c = Cset();

							cp_a(readByte(HL()));
							HL(inc16(HL()));
							BC(dec16(BC()));

							boolean pv = (BC() != 0);

							setPV(pv);
							setC(c);
							if (pv && !Zset()) {
								PC((PC() - 2) & 0xffff);
								tstatesCounter += 21;
							}
							tstatesCounter += 16;
							break;
						}

						case 178: /* INIR */{
							int b;
							writeByte(HL(), inByte(C(), B()));
							B(b = qdec8(B()));
							HL(inc16(HL()));

							setZ(true);
							setN(true);
							if (b != 0) {
								PC((PC() - 2) & 0xffff);
								tstatesCounter += 21;
							}
							tstatesCounter += 16;
							break;
						}

						case 179: /* OTIR */{
							int b;
							B(b = qdec8(B()));
							outByte(C(), B(), readByte(HL()));
							HL(inc16(HL()));

							setZ(true);
							setN(true);
							if (b != 0) {
								PC((PC() - 2) & 0xffff);
								tstatesCounter += 21;
							}
							tstatesCounter += 16;
							break;
						}

						/* xxDR */
						case 184: /* LDDR */{
							int count, dest, from;

							count = BC();
							dest = DE();
							from = HL();
							REFRESH(-2);
							do {
								writeByte(dest, readByte(from));
								from = dec16(from);
								dest = dec16(dest);
								count = dec16(count);

								tstatesCounter += 21;
								REFRESH(2);
							} while (count != 0);
							if (count != 0) {
								PC((PC() - 2) & 0xffff);
								setH(false);
								setN(false);
								setPV(true);
							} else {
								tstatesCounter -= 5;
								setH(false);
								setN(false);
								setPV(false);
							}
							DE(dest);
							HL(from);
							BC(count);

							break;
						}

						case 185: /* CPDR */{
							boolean c = Cset();

							cp_a(readByte(HL()));
							HL(dec16(HL()));
							BC(dec16(BC()));

							boolean pv = (BC() != 0);

							setPV(pv);
							setC(c);
							if (pv && !Zset()) {
								PC((PC() - 2) & 0xffff);
								tstatesCounter += 21;
							}
							tstatesCounter += 16;
							break;
						}
						case 186: /* INDR */{
							int b;
							writeByte(HL(), inByte(C(), B()));
							B(b = qdec8(B()));
							HL(dec16(HL()));

							setZ(true);
							setN(true);
							if (b != 0) {
								PC((PC() - 2) & 0xffff);
								tstatesCounter += 21;
							}
							tstatesCounter += 16;
							break;
						}
						case 187: /* OTDR */{
							int b;
							B(b = qdec8(B()));
							outByte(C(), B(), readByte(HL()));
							HL(dec16(HL()));

							setZ(true);
							setN(true);
							if (b != 0) {
								PC((PC() - 2) & 0xffff);
								tstatesCounter += 21;
							}
							tstatesCounter += 16;
							break;
						}

					} // ED instruction group
					break;
				}

				case 245: /* PUSH AF */{
					pushw(AF());
					tstatesCounter += 11;
					break;
				}
				case 253: /* prefix IY */{
					ID(IY());
					execute_id();
					IY(ID());
					break;
				}

				/* op A,N */
				case 198: /* ADD A,N */{
					add_a(readByte(_PC++));
					tstatesCounter += 7;
					break;
				}
				case 206: /* ADC A,N */{
					adc_a(readByte(_PC++));
					tstatesCounter += 7;
					break;
				}
				case 214: /* SUB N */{
					sub_a(readByte(_PC++));
					tstatesCounter += 7;
					break;
				}
				case 222: /* SBC A,N */{
					sbc_a(readByte(_PC++));
					tstatesCounter += 7;
					break;
				}
				case 230: /* AND N */{
					and_a(readByte(_PC++));
					tstatesCounter += 7;
					break;
				}
				case 238: /* XOR N */{
					xor_a(readByte(_PC++));
					tstatesCounter += 7;
					break;
				}
				case 246: /* OR N */{
					or_a(readByte(_PC++));
					tstatesCounter += 7;
					break;
				}
				case 254: /* CP N */{
					cp_a(readByte(_PC++));
					tstatesCounter += 7;
					break;
				}

				/* RST n */
				case 199: /* RST 00h */{
					pushw(_PC);
					PC(0);
					tstatesCounter += 11;
					break;
				}
				case 207: /* RST 08h */{
					pushw(_PC);
					PC(8);
					tstatesCounter += 11;
					break;
				}
				case 215: /* RST 10h */{
					pushw(_PC);
					PC(16);
					tstatesCounter += 11;
					break;
				}
				case 223: /* RST 18h */{
					pushw(_PC);
					PC(24);
					tstatesCounter += 11;
					break;
				}
				case 231: /* RST 20h */{
					pushw(_PC);
					PC(32);
					tstatesCounter += 11;
					break;
				}
				case 239: /* RST 28h */{
					pushw(_PC);
					PC(40);
					tstatesCounter += 11;
					break;
				}
				case 247: /* RST 30h */{
					pushw(_PC);
					PC(48);
					tstatesCounter += 11;
					break;
				}
				case 255: /* RST 38h */{
					pushw(_PC);
					PC(56);
					tstatesCounter += 11;
					break;
				}
			}
		} while (debugMode == false & z80Stopped == false);
	}


	private final void execute_id() {
		REFRESH(1);

		switch (readByte(_PC++)) {
			case 0: /* NOP */
			case 1:
			case 2:
			case 3:
			case 4:
			case 5:
			case 6:
			case 7:
			case 8:

			case 10:
			case 11:
			case 12:
			case 13:
			case 14:
			case 15:
			case 16:
			case 17:
			case 18:
			case 19:
			case 20:
			case 21:
			case 22:
			case 23:
			case 24:

			case 26:
			case 27:
			case 28:
			case 29:
			case 30:
			case 31:
			case 32:

			case 39:
			case 40:

			case 47:
			case 48:
			case 49:
			case 50:
			case 51:

			case 55:
			case 56:

			case 58:
			case 59:
			case 60:
			case 61:
			case 62:
			case 63:
			case 64:
			case 65:
			case 66:
			case 67:

			case 71:
			case 72:
			case 73:
			case 74:
			case 75:

			case 79:
			case 80:
			case 81:
			case 82:
			case 83:

			case 87:
			case 88:
			case 89:
			case 90:
			case 91:

			case 95:

			case 120:
			case 121:
			case 122:
			case 123:

			case 127:
			case 128:
			case 129:
			case 130:
			case 131:

			case 135:
			case 136:
			case 137:
			case 138:
			case 139:

			case 143:
			case 144:
			case 145:
			case 146:
			case 147:

			case 151:
			case 152:
			case 153:
			case 154:
			case 155:

			case 159:
			case 160:
			case 161:
			case 162:
			case 163:

			case 167:
			case 168:
			case 169:
			case 170:
			case 171:

			case 175:
			case 176:
			case 177:
			case 178:
			case 179:

			case 183:
			case 184:
			case 185:
			case 186:
			case 187:

			case 191:
			case 192:
			case 193:
			case 194:
			case 195:
			case 196:
			case 197:
			case 198:
			case 199:
			case 200:
			case 201:
			case 202:

			case 204:
			case 205:
			case 206:
			case 207:
			case 208:
			case 209:
			case 210:
			case 211:
			case 212:
			case 213:
			case 214:
			case 215:
			case 216:
			case 217:
			case 218:
			case 219:
			case 220:
			case 221:
			case 222:
			case 223:
			case 224:

			case 226:

			case 228:

			case 230:
			case 231:
			case 232:

			case 234:
			case 235:
			case 236:
			case 237:
			case 238:
			case 239:
			case 240:
			case 241:
			case 242:
			case 243:
			case 244:
			case 245:
			case 246:
			case 247:
			case 248: {
				PC(dec16(PC()));
				REFRESH(-1);
				tstatesCounter += 4;
				break;
			}

			case 9: /* ADD ID,BC */{
				ID(add16(ID(), BC()));
				tstatesCounter += 15;
				break;
			}
			case 25: /* ADD ID,DE */{
				ID(add16(ID(), DE()));
				tstatesCounter += 15;
				break;
			}
			case 41: /* ADD ID,ID */{
				int id = ID();
				ID(add16(id, id));
				tstatesCounter += 15;
				break;
			}
			case 57: /* ADD ID,SP */{
				ID(add16(ID(), SP()));
				tstatesCounter += 15;
				break;
			}

			case 33: /* LD ID,nn */{
				ID(nxtpcw());
				tstatesCounter += (14);
				break;
			}
			case 34: /* LD (nn),ID */{
				writeWord(nxtpcw(), ID());
				tstatesCounter += 20;
				break;
			}
			case 42: /* LD ID,(nn) */{
				ID(readWord(nxtpcw()));
				tstatesCounter += 20;
				break;
			}
			case 35: /* INC ID */{
				ID(inc16(ID()));
				tstatesCounter += 10;
				break;
			}
			case 43: /* DEC ID */{
				ID(dec16(ID()));
				tstatesCounter += 10;
				break;
			}
			case 36: /* INC IDH */{
				IDH(inc8(IDH()));
				tstatesCounter += 8;
				break;
			}
			case 44: /* INC IDL */{
				IDL(inc8(IDL()));
				tstatesCounter += 8;
				break;
			}
			case 52: /* INC (ID+d) */{
				int z = ID_d();
				writeByte(z, inc8(readByte(z)));
				tstatesCounter += 23;
				break;
			}
			case 37: /* DEC IDH */{
				IDH(dec8(IDH()));
				tstatesCounter += 8;
				break;
			}
			case 45: /* DEC IDL */{
				IDL(dec8(IDL()));
				tstatesCounter += 8;
				break;
			}
			case 53: /* DEC (ID+d) */{
				int z = ID_d();
				writeByte(z, dec8(readByte(z)));
				tstatesCounter += 23;
				break;
			}

			case 38: /* LD IDH,n */{
				IDH(readByte(_PC++));
				tstatesCounter += 11;
				break;
			}
			case 46: /* LD IDL,n */{
				IDL(readByte(_PC++));
				tstatesCounter += 11;
				break;
			}
			case 54: /* LD (ID+d),n */{
				int z = ID_d();
				writeByte(z, readByte(_PC++));
				tstatesCounter += 19;
				break;
			}

			case 68: /* LD B,IDH */{
				B(IDH());
				tstatesCounter += 8;
				break;
			}
			case 69: /* LD B,IDL */{
				B(IDL());
				tstatesCounter += 8;
				break;
			}
			case 70: /* LD B,(ID+d) */{
				B(readByte(ID_d()));
				tstatesCounter += 19;
				break;
			}

			case 76: /* LD C,IDH */{
				C(IDH());
				tstatesCounter += 8;
				break;
			}
			case 77: /* LD C,IDL */{
				C(IDL());
				tstatesCounter += 8;
				break;
			}
			case 78: /* LD C,(ID+d) */{
				C(readByte(ID_d()));
				tstatesCounter += 19;
				break;
			}

			case 84: /* LD D,IDH */{
				D(IDH());
				tstatesCounter += 8;
				break;
			}
			case 85: /* LD D,IDL */{
				D(IDL());
				tstatesCounter += 8;
				break;
			}
			case 86: /* LD D,(ID+d) */{
				D(readByte(ID_d()));
				tstatesCounter += 19;
				break;
			}

			case 92: /* LD E,IDH */{
				E(IDH());
				tstatesCounter += 8;
				break;
			}
			case 93: /* LD E,IDL */{
				E(IDL());
				tstatesCounter += 8;
				break;
			}
			case 94: /* LD E,(ID+d) */{
				E(readByte(ID_d()));
				tstatesCounter += 19;
				break;
			}

			case 96: /* LD IDH,B */{
				IDH(B());
				tstatesCounter += 8;
				break;
			}
			case 97: /* LD IDH,C */{
				IDH(C());
				tstatesCounter += 8;
				break;
			}
			case 98: /* LD IDH,D */{
				IDH(D());
				tstatesCounter += 8;
				break;
			}
			case 99: /* LD IDH,E */{
				IDH(E());
				tstatesCounter += 8;
				break;
			}
			case 100: /* LD IDH,IDH */{
				tstatesCounter += 8;
				break;
			}
			case 101: /* LD IDH,IDL */{
				IDH(IDL());
				tstatesCounter += 8;
				break;
			}
			case 102: /* LD H,(ID+d) */{
				H(readByte(ID_d()));
				tstatesCounter += 19;
				break;
			}
			case 103: /* LD IDH,A */{
				IDH(A());
				tstatesCounter += 8;
				break;
			}

			case 104: /* LD IDL,B */{
				IDL(B());
				tstatesCounter += 8;
				break;
			}
			case 105: /* LD IDL,C */{
				IDL(C());
				tstatesCounter += 8;
				break;
			}
			case 106: /* LD IDL,D */{
				IDL(D());
				tstatesCounter += 8;
				break;
			}
			case 107: /* LD IDL,E */{
				IDL(E());
				tstatesCounter += 8;
				break;
			}
			case 108: /* LD IDL,IDH */{
				IDL(IDH());
				tstatesCounter += 8;
				break;
			}
			case 109: /* LD IDL,IDL */{
				tstatesCounter += 8;
				break;
			}
			case 110: /* LD L,(ID+d) */{
				L(readByte(ID_d()));
				tstatesCounter += 19;
				break;
			}
			case 111: /* LD IDL,A */{
				IDL(A());
				tstatesCounter += 8;
				break;
			}

			case 112: /* LD (ID+d),B */{
				writeByte(ID_d(), B());
				tstatesCounter += 19;
				break;
			}
			case 113: /* LD (ID+d),C */{
				writeByte(ID_d(), C());
				tstatesCounter += 19;
				break;
			}
			case 114: /* LD (ID+d),D */{
				writeByte(ID_d(), D());
				tstatesCounter += 19;
				break;
			}
			case 115: /* LD (ID+d),E */{
				writeByte(ID_d(), E());
				tstatesCounter += 19;
				break;
			}
			case 116: /* LD (ID+d),H */{
				writeByte(ID_d(), H());
				tstatesCounter += 19;
				break;
			}
			case 117: /* LD (ID+d),L */{
				writeByte(ID_d(), L());
				tstatesCounter += 19;
				break;
			}
			case 119: /* LD (ID+d),A */{
				writeByte(ID_d(), A());
				tstatesCounter += 19;
				break;
			}

			case 124: /* LD A,IDH */{
				A(IDH());
				tstatesCounter += 8;
				break;
			}
			case 125: /* LD A,IDL */{
				A(IDL());
				tstatesCounter += 8;
				break;
			}
			case 126: /* LD A,(ID+d) */{
				A(readByte(ID_d()));
				tstatesCounter += 19;
				break;
			}

			case 132: /* ADD A,IDH */{
				add_a(IDH());
				tstatesCounter += 8;
				break;
			}
			case 133: /* ADD A,IDL */{
				add_a(IDL());
				tstatesCounter += 8;
				break;
			}
			case 134: /* ADD A,(ID+d) */{
				add_a(readByte(ID_d()));
				tstatesCounter += 19;
				break;
			}

			case 140: /* ADC A,IDH */{
				adc_a(IDH());
				tstatesCounter += 8;
				break;
			}
			case 141: /* ADC A,IDL */{
				adc_a(IDL());
				tstatesCounter += 8;
				break;
			}
			case 142: /* ADC A,(ID+d) */{
				adc_a(readByte(ID_d()));
				tstatesCounter += 19;
				break;
			}

			case 148: /* SUB IDH */{
				sub_a(IDH());
				tstatesCounter += 8;
				break;
			}
			case 149: /* SUB IDL */{
				sub_a(IDL());
				tstatesCounter += 8;
				break;
			}
			case 150: /* SUB (ID+d) */{
				sub_a(readByte(ID_d()));
				tstatesCounter += 19;
				break;
			}

			case 156: /* SBC A,IDH */{
				sbc_a(IDH());
				tstatesCounter += 8;
				break;
			}
			case 157: /* SBC A,IDL */{
				sbc_a(IDL());
				tstatesCounter += 8;
				break;
			}
			case 158: /* SBC A,(ID+d) */{
				sbc_a(readByte(ID_d()));
				tstatesCounter += 19;
				break;
			}

			case 164: /* AND IDH */{
				and_a(IDH());
				tstatesCounter += 8;
				break;
			}
			case 165: /* AND IDL */{
				and_a(IDL());
				tstatesCounter += 8;
				break;
			}
			case 166: /* AND (ID+d) */{
				and_a(readByte(ID_d()));
				tstatesCounter += 19;
				break;
			}

			case 172: /* XOR IDH */{
				xor_a(IDH());
				tstatesCounter += 8;
				break;
			}
			case 173: /* XOR IDL */{
				xor_a(IDL());
				tstatesCounter += 8;
				break;
			}
			case 174: /* XOR (ID+d) */{
				xor_a(readByte(ID_d()));
				tstatesCounter += 19;
				break;
			}

			case 180: /* OR IDH */{
				or_a(IDH());
				tstatesCounter += 8;
				break;
			}
			case 181: /* OR IDL */{
				or_a(IDL());
				tstatesCounter += 8;
				break;
			}
			case 182: /* OR (ID+d) */{
				or_a(readByte(ID_d()));
				tstatesCounter += 19;
				break;
			}

			case 188: /* CP IDH */{
				cp_a(IDH());
				tstatesCounter += 8;
				break;
			}
			case 189: /* CP IDL */{
				cp_a(IDL());
				tstatesCounter += 8;
				break;
			}
			case 190: /* CP (ID+d) */{
				cp_a(readByte(ID_d()));
				tstatesCounter += 19;
				break;
			}

			case 225: /* POP ID */{
				ID(popw());
				tstatesCounter += 14;
				break;
			}

			case 233: /* JP (ID) */{
				PC(ID());
				tstatesCounter += 8;
				break;
			}

			case 249: /* LD SP,ID */{
				SP(ID());
				tstatesCounter += 10;
				break;
			}

			case 203: /* prefix CB */{
				// Get index address (offset byte is first)
				int z = ID_d();
				// Opcode comes after offset byte
				int op = readByte(_PC++);

				switch (op) {
					case 0: /* RLC B */{
						B(op = rlc(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 1: /* RLC C */{
						C(op = rlc(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 2: /* RLC D */{
						D(op = rlc(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 3: /* RLC E */{
						E(op = rlc(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 4: /* RLC H */{
						H(op = rlc(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 5: /* RLC L */{
						L(op = rlc(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 6: /* RLC (HL) */{
						writeByte(z, rlc(readByte(z)));
						break;
					}
					case 7: /* RLC A */{
						A(op = rlc(readByte(z)));
						writeByte(z, op);
						break;
					}

					case 8: /* RRC B */{
						B(op = rrc(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 9: /* RRC C */{
						C(op = rrc(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 10: /* RRC D */{
						D(op = rrc(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 11: /* RRC E */{
						E(op = rrc(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 12: /* RRC H */{
						H(op = rrc(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 13: /* RRC L */{
						L(op = rrc(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 14: /* RRC (HL) */{
						writeByte(z, rrc(readByte(z)));
						break;
					}
					case 15: /* RRC A */{
						A(op = rrc(readByte(z)));
						writeByte(z, op);
						break;
					}

					case 16: /* RL B */{
						B(op = rl(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 17: /* RL C */{
						C(op = rl(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 18: /* RL D */{
						D(op = rl(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 19: /* RL E */{
						E(op = rl(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 20: /* RL H */{
						H(op = rl(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 21: /* RL L */{
						L(op = rl(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 22: /* RL (HL) */{
						writeByte(z, rl(readByte(z)));
						break;
					}
					case 23: /* RL A */{
						A(op = rl(readByte(z)));
						writeByte(z, op);
						break;
					}

					case 24: /* RR B */{
						B(op = rr(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 25: /* RR C */{
						C(op = rr(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 26: /* RR D */{
						D(op = rr(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 27: /* RR E */{
						E(op = rr(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 28: /* RR H */{
						H(op = rr(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 29: /* RR L */{
						L(op = rr(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 30: /* RR (HL) */{
						writeByte(z, rr(readByte(z)));
						break;
					}
					case 31: /* RR A */{
						A(op = rr(readByte(z)));
						writeByte(z, op);
						break;
					}

					case 32: /* SLA B */{
						B(op = sla(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 33: /* SLA C */{
						C(op = sla(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 34: /* SLA D */{
						D(op = sla(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 35: /* SLA E */{
						E(op = sla(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 36: /* SLA H */{
						H(op = sla(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 37: /* SLA L */{
						L(op = sla(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 38: /* SLA (HL) */{
						writeByte(z, sla(readByte(z)));
						break;
					}
					case 39: /* SLA A */{
						A(op = sla(readByte(z)));
						writeByte(z, op);
						break;
					}

					case 40: /* SRA B */{
						B(op = sra(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 41: /* SRA C */{
						C(op = sra(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 42: /* SRA D */{
						D(op = sra(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 43: /* SRA E */{
						E(op = sra(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 44: /* SRA H */{
						H(op = sra(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 45: /* SRA L */{
						L(op = sra(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 46: /* SRA (HL) */{
						writeByte(z, sra(readByte(z)));
						break;
					}
					case 47: /* SRA A */{
						A(op = sra(readByte(z)));
						writeByte(z, op);
						break;
					}

					case 48: /* SLS B */{
						B(op = sls(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 49: /* SLS C */{
						C(op = sls(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 50: /* SLS D */{
						D(op = sls(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 51: /* SLS E */{
						E(op = sls(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 52: /* SLS H */{
						H(op = sls(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 53: /* SLS L */{
						L(op = sls(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 54: /* SLS (HL) */{
						writeByte(z, sls(readByte(z)));
						break;
					}
					case 55: /* SLS A */{
						A(op = sls(readByte(z)));
						writeByte(z, op);
						break;
					}

					case 56: /* SRL B */{
						B(op = srl(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 57: /* SRL C */{
						C(op = srl(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 58: /* SRL D */{
						D(op = srl(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 59: /* SRL E */{
						E(op = srl(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 60: /* SRL H */{
						H(op = srl(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 61: /* SRL L */{
						L(op = srl(readByte(z)));
						writeByte(z, op);
						break;
					}
					case 62: /* SRL (HL) */{
						writeByte(z, srl(readByte(z)));
						break;
					}
					case 63: /* SRL A */{
						A(op = srl(readByte(z)));
						writeByte(z, op);
						break;
					}

					case 64: /* BIT 0,B */
					case 65: /* BIT 0,B */
					case 66: /* BIT 0,B */
					case 67: /* BIT 0,B */
					case 68: /* BIT 0,B */
					case 69: /* BIT 0,B */
					case 70: /* BIT 0,B */
					case 71: /* BIT 0,B */{
						bit(0x01, readByte(z));
						break;
					}

					case 72: /* BIT 1,B */
					case 73: /* BIT 1,B */
					case 74: /* BIT 1,B */
					case 75: /* BIT 1,B */
					case 76: /* BIT 1,B */
					case 77: /* BIT 1,B */
					case 78: /* BIT 1,B */
					case 79: /* BIT 1,B */{
						bit(0x02, readByte(z));
						break;
					}

					case 80: /* BIT 2,B */
					case 81: /* BIT 2,B */
					case 82: /* BIT 2,B */
					case 83: /* BIT 2,B */
					case 84: /* BIT 2,B */
					case 85: /* BIT 2,B */
					case 86: /* BIT 2,B */
					case 87: /* BIT 2,B */{
						bit(0x04, readByte(z));
						break;
					}

					case 88: /* BIT 3,B */
					case 89: /* BIT 3,B */
					case 90: /* BIT 3,B */
					case 91: /* BIT 3,B */
					case 92: /* BIT 3,B */
					case 93: /* BIT 3,B */
					case 94: /* BIT 3,B */
					case 95: /* BIT 3,B */{
						bit(0x08, readByte(z));
						break;
					}

					case 96: /* BIT 4,B */
					case 97: /* BIT 4,B */
					case 98: /* BIT 4,B */
					case 99: /* BIT 4,B */
					case 100: /* BIT 4,B */
					case 101: /* BIT 4,B */
					case 102: /* BIT 4,B */
					case 103: /* BIT 4,B */{
						bit(0x10, readByte(z));
						break;
					}

					case 104: /* BIT 5,B */
					case 105: /* BIT 5,B */
					case 106: /* BIT 5,B */
					case 107: /* BIT 5,B */
					case 108: /* BIT 5,B */
					case 109: /* BIT 5,B */
					case 110: /* BIT 5,B */
					case 111: /* BIT 5,B */{
						bit(0x20, readByte(z));
						break;
					}

					case 112: /* BIT 6,B */
					case 113: /* BIT 6,B */
					case 114: /* BIT 6,B */
					case 115: /* BIT 6,B */
					case 116: /* BIT 6,B */
					case 117: /* BIT 6,B */
					case 118: /* BIT 6,B */
					case 119: /* BIT 6,B */{
						bit(0x40, readByte(z));
						break;
					}

					case 120: /* BIT 7,B */
					case 121: /* BIT 7,B */
					case 122: /* BIT 7,B */
					case 123: /* BIT 7,B */
					case 124: /* BIT 7,B */
					case 125: /* BIT 7,B */
					case 126: /* BIT 7,B */
					case 127: /* BIT 7,B */{
						bit(0x80, readByte(z));
						break;
					}

					case 128: /* RES 0,B */{
						B(op = res(0x01, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 129: /* RES 0,C */{
						C(op = res(0x01, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 130: /* RES 0,D */{
						D(op = res(0x01, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 131: /* RES 0,E */{
						E(op = res(0x01, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 132: /* RES 0,H */{
						H(op = res(0x01, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 133: /* RES 0,L */{
						L(op = res(0x01, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 134: /* RES 0,(HL) */{
						writeByte(z, res(0x01, readByte(z)));
						break;
					}
					case 135: /* RES 0,A */{
						A(op = res(0x01, readByte(z)));
						writeByte(z, op);
						break;
					}

					case 136: /* RES 1,B */{
						B(op = res(0x02, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 137: /* RES 1,C */{
						C(op = res(0x02, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 138: /* RES 1,D */{
						D(op = res(0x02, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 139: /* RES 1,E */{
						E(op = res(0x02, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 140: /* RES 1,H */{
						H(op = res(0x02, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 141: /* RES 1,L */{
						L(op = res(0x02, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 142: /* RES 1,(HL) */{
						writeByte(z, res(0x02, readByte(z)));
						break;
					}
					case 143: /* RES 1,A */{
						A(op = res(0x02, readByte(z)));
						writeByte(z, op);
						break;
					}

					case 144: /* RES 2,B */{
						B(op = res(0x04, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 145: /* RES 2,C */{
						C(op = res(0x04, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 146: /* RES 2,D */{
						D(op = res(0x04, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 147: /* RES 2,E */{
						E(op = res(0x04, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 148: /* RES 2,H */{
						H(op = res(0x04, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 149: /* RES 2,L */{
						L(op = res(0x04, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 150: /* RES 2,(HL) */{
						writeByte(z, res(0x04, readByte(z)));
						break;
					}
					case 151: /* RES 2,A */{
						A(op = res(0x04, readByte(z)));
						writeByte(z, op);
						break;
					}

					case 152: /* RES 3,B */{
						B(op = res(0x08, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 153: /* RES 3,C */{
						C(op = res(0x08, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 154: /* RES 3,D */{
						D(op = res(0x08, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 155: /* RES 3,E */{
						E(op = res(0x08, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 156: /* RES 3,H */{
						H(op = res(0x08, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 157: /* RES 3,L */{
						L(op = res(0x08, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 158: /* RES 3,(HL) */{
						writeByte(z, res(0x08, readByte(z)));
						break;
					}
					case 159: /* RES 3,A */{
						A(op = res(0x08, readByte(z)));
						writeByte(z, op);
						break;
					}

					case 160: /* RES 4,B */{
						B(op = res(0x10, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 161: /* RES 4,C */{
						C(op = res(0x10, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 162: /* RES 4,D */{
						D(op = res(0x10, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 163: /* RES 4,E */{
						E(op = res(0x10, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 164: /* RES 4,H */{
						H(op = res(0x10, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 165: /* RES 4,L */{
						L(op = res(0x10, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 166: /* RES 4,(HL) */{
						writeByte(z, res(0x10, readByte(z)));
						break;
					}
					case 167: /* RES 4,A */{
						A(op = res(0x10, readByte(z)));
						writeByte(z, op);
						break;
					}

					case 168: /* RES 5,B */{
						B(op = res(0x20, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 169: /* RES 5,C */{
						C(op = res(0x20, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 170: /* RES 5,D */{
						D(op = res(0x20, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 171: /* RES 5,E */{
						E(op = res(0x20, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 172: /* RES 5,H */{
						H(op = res(0x20, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 173: /* RES 5,L */{
						L(op = res(0x20, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 174: /* RES 5,(HL) */{
						writeByte(z, res(0x20, readByte(z)));
						break;
					}
					case 175: /* RES 5,A */{
						A(op = res(0x20, readByte(z)));
						writeByte(z, op);
						break;
					}

					case 176: /* RES 6,B */{
						B(op = res(0x40, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 177: /* RES 6,C */{
						C(op = res(0x40, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 178: /* RES 6,D */{
						D(op = res(0x40, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 179: /* RES 6,E */{
						E(op = res(0x40, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 180: /* RES 6,H */{
						H(op = res(0x40, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 181: /* RES 6,L */{
						L(op = res(0x40, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 182: /* RES 6,(HL) */{
						writeByte(z, res(0x40, readByte(z)));
						break;
					}
					case 183: /* RES 6,A */{
						A(op = res(0x40, readByte(z)));
						writeByte(z, op);
						break;
					}

					case 184: /* RES 7,B */{
						B(op = res(0x80, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 185: /* RES 7,C */{
						C(op = res(0x80, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 186: /* RES 7,D */{
						D(op = res(0x80, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 187: /* RES 7,E */{
						E(op = res(0x80, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 188: /* RES 7,H */{
						H(op = res(0x80, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 189: /* RES 7,L */{
						L(op = res(0x80, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 190: /* RES 7,(HL) */{
						writeByte(z, res(0x80, readByte(z)));
						break;
					}
					case 191: /* RES 7,A */{
						A(op = res(0x80, readByte(z)));
						writeByte(z, op);
						break;
					}

					case 192: /* SET 0,B */{
						B(op = set(0x01, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 193: /* SET 0,C */{
						C(op = set(0x01, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 194: /* SET 0,D */{
						D(op = set(0x01, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 195: /* SET 0,E */{
						E(op = set(0x01, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 196: /* SET 0,H */{
						H(op = set(0x01, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 197: /* SET 0,L */{
						L(op = set(0x01, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 198: /* SET 0,(HL) */{
						writeByte(z, set(0x01, readByte(z)));
						break;
					}
					case 199: /* SET 0,A */{
						A(op = set(0x01, readByte(z)));
						writeByte(z, op);
						break;
					}

					case 200: /* SET 1,B */{
						B(op = set(0x02, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 201: /* SET 1,C */{
						C(op = set(0x02, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 202: /* SET 1,D */{
						D(op = set(0x02, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 203: /* SET 1,E */{
						E(op = set(0x02, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 204: /* SET 1,H */{
						H(op = set(0x02, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 205: /* SET 1,L */{
						L(op = set(0x02, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 206: /* SET 1,(HL) */{
						writeByte(z, set(0x02, readByte(z)));
						break;
					}
					case 207: /* SET 1,A */{
						A(op = set(0x02, readByte(z)));
						writeByte(z, op);
						break;
					}

					case 208: /* SET 2,B */{
						B(op = set(0x04, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 209: /* SET 2,C */{
						C(op = set(0x04, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 210: /* SET 2,D */{
						D(op = set(0x04, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 211: /* SET 2,E */{
						E(op = set(0x04, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 212: /* SET 2,H */{
						H(op = set(0x04, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 213: /* SET 2,L */{
						L(op = set(0x04, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 214: /* SET 2,(HL) */{
						writeByte(z, set(0x04, readByte(z)));
						break;
					}
					case 215: /* SET 2,A */{
						A(op = set(0x04, readByte(z)));
						writeByte(z, op);
						break;
					}

					case 216: /* SET 3,B */{
						B(op = set(0x08, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 217: /* SET 3,C */{
						C(op = set(0x08, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 218: /* SET 3,D */{
						D(op = set(0x08, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 219: /* SET 3,E */{
						E(op = set(0x08, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 220: /* SET 3,H */{
						H(op = set(0x08, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 221: /* SET 3,L */{
						L(op = set(0x08, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 222: /* SET 3,(HL) */{
						writeByte(z, set(0x08, readByte(z)));
						break;
					}
					case 223: /* SET 3,A */{
						A(op = set(0x08, readByte(z)));
						writeByte(z, op);
						break;
					}

					case 224: /* SET 4,B */{
						B(op = set(0x10, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 225: /* SET 4,C */{
						C(op = set(0x10, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 226: /* SET 4,D */{
						D(op = set(0x10, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 227: /* SET 4,E */{
						E(op = set(0x10, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 228: /* SET 4,H */{
						H(op = set(0x10, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 229: /* SET 4,L */{
						L(op = set(0x10, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 230: /* SET 4,(HL) */{
						writeByte(z, set(0x10, readByte(z)));
						break;
					}
					case 231: /* SET 4,A */{
						A(op = set(0x10, readByte(z)));
						writeByte(z, op);
						break;
					}

					case 232: /* SET 5,B */{
						B(op = set(0x20, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 233: /* SET 5,C */{
						C(op = set(0x20, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 234: /* SET 5,D */{
						D(op = set(0x20, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 235: /* SET 5,E */{
						E(op = set(0x20, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 236: /* SET 5,H */{
						H(op = set(0x20, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 237: /* SET 5,L */{
						L(op = set(0x20, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 238: /* SET 5,(HL) */{
						writeByte(z, set(0x20, readByte(z)));
						break;
					}
					case 239: /* SET 5,A */{
						A(op = set(0x20, readByte(z)));
						writeByte(z, op);
						break;
					}

					case 240: /* SET 6,B */{
						B(op = set(0x40, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 241: /* SET 6,C */{
						C(op = set(0x40, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 242: /* SET 6,D */{
						D(op = set(0x40, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 243: /* SET 6,E */{
						E(op = set(0x40, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 244: /* SET 6,H */{
						H(op = set(0x40, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 245: /* SET 6,L */{
						L(op = set(0x40, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 246: /* SET 6,(HL) */{
						writeByte(z, set(0x40, readByte(z)));
						break;
					}
					case 247: /* SET 6,A */{
						A(op = set(0x40, readByte(z)));
						writeByte(z, op);
						break;
					}

					case 248: /* SET 7,B */{
						B(op = set(0x80, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 249: /* SET 7,C */{
						C(op = set(0x80, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 250: /* SET 7,D */{
						D(op = set(0x80, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 251: /* SET 7,E */{
						E(op = set(0x80, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 252: /* SET 7,H */{
						H(op = set(0x80, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 253: /* SET 7,L */{
						L(op = set(0x80, readByte(z)));
						writeByte(z, op);
						break;
					}
					case 254: /* SET 7,(HL) */{
						writeByte(z, set(0x80, readByte(z)));
						break;
					}
					case 255: /* SET 7,A */{
						A(op = set(0x80, readByte(z)));
						writeByte(z, op);
						break;
					}
				}

				// Bit instructions take 20 T states, rest 23
				tstatesCounter += (((op & 0xc0) == 0x40) ? 20 : 23);
				break;
			}

			case 227: /* EX (SP),ID */{
				int t = ID();
				int sp = SP();
				ID(readWord(sp));
				writeWord(sp, t);
				tstatesCounter += 23;
				break;
			}

			case 229: /* PUSH ID */{
				pushw(ID());
				tstatesCounter += 15;
				break;
			}
		} // end switch
	}

	private final int in_bc() {
		int ans = inByte(C(), B());

		setZ(ans == 0);
		setS((ans & F_S) != 0);
		set3((ans & F_3) != 0);
		set5((ans & F_5) != 0);
		setPV(parity[ans]);
		setN(false);
		setH(false);

		return ans;
	}

	/** Add with carry - alters all flags (CHECKED) */
	private final void adc_a(int b) {
		int a = A();
		int c = Cset() ? 1 : 0;
		int wans = a + b + c;
		int ans = wans & 0xff;

		setS((ans & F_S) != 0);
		set3((ans & F_3) != 0);
		set5((ans & F_5) != 0);
		setZ((ans) == 0);
		setC((wans & 0x100) != 0);
		setPV(((a ^ ~b) & (a ^ ans) & 0x80) != 0);
		setH((((a & 0x0f) + (b & 0x0f) + c) & F_H) != 0);
		setN(false);

		A(ans);
	}

	/** Add - alters all flags (CHECKED) */
	private final void add_a(int b) {
		int a = A();
		int wans = a + b;
		int ans = wans & 0xff;

		setS((ans & F_S) != 0);
		set3((ans & F_3) != 0);
		set5((ans & F_5) != 0);
		setZ((ans) == 0);
		setC((wans & 0x100) != 0);
		setPV(((a ^ ~b) & (a ^ ans) & 0x80) != 0);
		setH((((a & 0x0f) + (b & 0x0f)) & F_H) != 0);
		setN(false);

		A(ans);
	}

	/** Subtract with carry - alters all flags (CHECKED) */
	private final void sbc_a(int b) {
		int a = A();
		int c = Cset() ? 1 : 0;
		int wans = a - b - c;
		int ans = wans & 0xff;

		setS((ans & F_S) != 0);
		set3((ans & F_3) != 0);
		set5((ans & F_5) != 0);
		setZ((ans) == 0);
		setC((wans & 0x100) != 0);
		setPV(((a ^ b) & (a ^ ans) & 0x80) != 0);
		setH((((a & 0x0f) - (b & 0x0f) - c) & F_H) != 0);
		setN(true);

		A(ans);
	}

	/** Subtract - alters all flags (CHECKED) */
	private final void sub_a(int b) {
		int a = A();
		int wans = a - b;
		int ans = wans & 0xff;

		setS((ans & F_S) != 0);
		set3((ans & F_3) != 0);
		set5((ans & F_5) != 0);
		setZ((ans) == 0);
		setC((wans & 0x100) != 0);
		setPV(((a ^ b) & (a ^ ans) & 0x80) != 0);
		setH((((a & 0x0f) - (b & 0x0f)) & F_H) != 0);
		setN(true);

		A(ans);
	}

	/** Rotate Left - alters H N C 3 5 flags (CHECKED) */
	private final void rlc_a() {
		int ans = A();
		boolean c = (ans & 0x80) != 0;

		if (c) {
			ans = (ans << 1) | 0x01;
		} else {
			ans <<= 1;
		}
		ans &= 0xff;

		set3((ans & F_3) != 0);
		set5((ans & F_5) != 0);
		setN(false);
		setH(false);
		setC(c);

		A(ans);
	}

	/** Rotate Right - alters H N C 3 5 flags (CHECKED) */
	private final void rrc_a() {
		int ans = A();
		boolean c = (ans & 0x01) != 0;

		if (c) {
			ans = (ans >> 1) | 0x80;
		} else {
			ans >>= 1;
		}

		set3((ans & F_3) != 0);
		set5((ans & F_5) != 0);
		setN(false);
		setH(false);
		setC(c);

		A(ans);
	}

	/** Rotate Left through Carry - alters H N C 3 5 flags (CHECKED) */
	private final void rl_a() {
		int ans = A();
		boolean c = (ans & 0x80) != 0;

		if (Cset()) {
			ans = (ans << 1) | 0x01;
		} else {
			ans <<= 1;
		}

		ans &= 0xff;

		set3((ans & F_3) != 0);
		set5((ans & F_5) != 0);
		setN(false);
		setH(false);
		setC(c);

		A(ans);
	}

	/** Rotate Right through Carry - alters H N C 3 5 flags (CHECKED) */
	private final void rr_a() {
		int ans = A();
		boolean c = (ans & 0x01) != 0;

		if (Cset()) {
			ans = (ans >> 1) | 0x80;
		} else {
			ans >>= 1;
		}

		set3((ans & F_3) != 0);
		set5((ans & F_5) != 0);
		setN(false);
		setH(false);
		setC(c);

		A(ans);
	}

	/** Compare - alters all flags (CHECKED) */
	private final void cp_a(int b) {
		int a = A();
		int wans = a - b;
		int ans = wans & 0xff;

		setS((ans & F_S) != 0);
		set3((b & F_3) != 0);
		set5((b & F_5) != 0);
		setN(true);
		setZ(ans == 0);
		setC((wans & 0x100) != 0);
		setH((((a & 0x0f) - (b & 0x0f)) & F_H) != 0);
		setPV(((a ^ b) & (a ^ ans) & 0x80) != 0);
	}

	/** Bitwise and - alters all flags (CHECKED) */
	private final void and_a(int b) {
		int ans = A() & b;

		setS((ans & F_S) != 0);
		set3((ans & F_3) != 0);
		set5((ans & F_5) != 0);
		setH(true);
		setPV(parity[ans]);
		setZ(ans == 0);
		setN(false);
		setC(false);

		A(ans);
	}

	/** Bitwise or - alters all flags (CHECKED) */
	private final void or_a(int b) {
		int ans = A() | b;

		setS((ans & F_S) != 0);
		set3((ans & F_3) != 0);
		set5((ans & F_5) != 0);
		setH(false);
		setPV(parity[ans]);
		setZ(ans == 0);
		setN(false);
		setC(false);

		A(ans);
	}

	/** Bitwise exclusive or - alters all flags (CHECKED) */
	private final void xor_a(int b) {
		int ans = (A() ^ b) & 0xff;

		setS((ans & F_S) != 0);
		set3((ans & F_3) != 0);
		set5((ans & F_5) != 0);
		setH(false);
		setPV(parity[ans]);
		setZ(ans == 0);
		setN(false);
		setC(false);

		A(ans);
	}

	/** Negate (Two's complement) - alters all flags (CHECKED) */
	private final void neg_a() {
		int t = A();

		A(0);
		sub_a(t);
	}

	/** One's complement - alters N H 3 5 flags (CHECKED) */
	private final void cpl_a() {
		int ans = A() ^ 0xff;

		set3((ans & F_3) != 0);
		set5((ans & F_5) != 0);
		setH(true);
		setN(true);

		A(ans);
	}

	/** Decimal Adjust Accumulator - alters all flags (CHECKED) */
	private final void daa_a() {
		int ans = A();
		int incr = 0;
		boolean carry = Cset();

		if ((Hset()) || ((ans & 0x0f) > 0x09)) {
			incr |= 0x06;
		}
		if (carry || (ans > 0x9f) || ((ans > 0x8f) && ((ans & 0x0f) > 0x09))) {
			incr |= 0x60;
		}
		if (ans > 0x99) {
			carry = true;
		}
		if (Nset()) {
			sub_a(incr);
		} else {
			add_a(incr);
		}

		ans = A();

		setC(carry);
		setPV(parity[ans]);
	}

	/** Load a with i - (NOT CHECKED) */
	private final void ld_a_i() {
		int ans = I();

		setS((ans & F_S) != 0);
		set3((ans & F_3) != 0);
		set5((ans & F_5) != 0);
		setZ(ans == 0);
		setPV(IFF2());
		setH(false);
		setN(false);

		A(ans);
	}

	/** Load a with r - (NOT CHECKED) */
	private final void ld_a_r() {
		int ans = R();

		setS((ans & F_S) != 0);
		set3((ans & F_3) != 0);
		set5((ans & F_5) != 0);
		setZ(ans == 0);
		setPV(IFF2());
		setH(false);
		setN(false);

		A(ans);
	}

	/** Rotate right through a and (hl) - (NOT CHECKED) */
	private final void rrd_a() {
		int ans = A();
		int t = readByte(HL());
		int q = t;

		t = (t >> 4) | (ans << 4);
		ans = (ans & 0xf0) | (q & 0x0f);
		writeByte(HL(), t);

		setS((ans & F_S) != 0);
		set3((ans & F_3) != 0);
		set5((ans & F_5) != 0);
		setZ(ans == 0);
		setPV(IFF2());
		setH(false);
		setN(false);

		A(ans);
	}

	/** Rotate left through a and (hl) - (NOT CHECKED) */
	private final void rld_a() {
		int ans = A();
		int t = readByte(HL());
		int q = t;

		t = (t << 4) | (ans & 0x0f);
		ans = (ans & 0xf0) | (q >> 4);
		writeByte(HL(), (t & 0xff));

		setS((ans & F_S) != 0);
		set3((ans & F_3) != 0);
		set5((ans & F_5) != 0);
		setZ(ans == 0);
		setPV(IFF2());
		setH(false);
		setN(false);

		A(ans);
	}

	/** Test bit - alters all but C flag (CHECKED) */
	private final void bit(int b, int r) {
		boolean bitSet = ((r & b) != 0);

		setN(false);
		setH(true);
		set3((r & F_3) != 0);
		set5((r & F_5) != 0);
		setS((b == F_S) ? bitSet : false);
		setZ(!bitSet);
		setPV(!bitSet);
	}

	/** Set carry flag - alters N H 3 5 C flags (CHECKED) */
	private final void scf() {
		int ans = A();

		set3((ans & F_3) != 0);
		set5((ans & F_5) != 0);
		setN(false);
		setH(false);
		setC(true);
	}

	/** Complement carry flag - alters N 3 5 C flags (CHECKED) */
	private final void ccf() {
		int ans = A();

		set3((ans & F_3) != 0);
		set5((ans & F_5) != 0);
		setN(false);
		setC(Cset() ? false : true);
	}

	/** Rotate left - alters all flags (CHECKED) */
	private final int rlc(int ans) {
		boolean c = (ans & 0x80) != 0;

		if (c) {
			ans = (ans << 1) | 0x01;
		} else {
			ans <<= 1;
		}
		ans &= 0xff;

		setS((ans & F_S) != 0);
		set3((ans & F_3) != 0);
		set5((ans & F_5) != 0);
		setZ((ans) == 0);
		setPV(parity[ans]);
		setH(false);
		setN(false);
		setC(c);

		return (ans);
	}

	/** Rotate right - alters all flags (CHECKED) */
	private final int rrc(int ans) {
		boolean c = (ans & 0x01) != 0;

		if (c) {
			ans = (ans >> 1) | 0x80;
		} else {
			ans >>= 1;
		}

		setS((ans & F_S) != 0);
		set3((ans & F_3) != 0);
		set5((ans & F_5) != 0);
		setZ((ans) == 0);
		setPV(parity[ans]);
		setH(false);
		setN(false);
		setC(c);

		return (ans);
	}

	/** Rotate left through carry - alters all flags (CHECKED) */
	private final int rl(int ans) {
		boolean c = (ans & 0x80) != 0;

		if (Cset()) {
			ans = (ans << 1) | 0x01;
		} else {
			ans <<= 1;
		}
		ans &= 0xff;

		setS((ans & F_S) != 0);
		set3((ans & F_3) != 0);
		set5((ans & F_5) != 0);
		setZ((ans) == 0);
		setPV(parity[ans]);
		setH(false);
		setN(false);
		setC(c);

		return (ans);
	}

	/** Rotate right through carry - alters all flags (CHECKED) */
	private final int rr(int ans) {
		boolean c = (ans & 0x01) != 0;

		if (Cset()) {
			ans = (ans >> 1) | 0x80;
		} else {
			ans >>= 1;
		}

		setS((ans & F_S) != 0);
		set3((ans & F_3) != 0);
		set5((ans & F_5) != 0);
		setZ((ans) == 0);
		setPV(parity[ans]);
		setH(false);
		setN(false);
		setC(c);

		return (ans);
	}

	/** Shift Left Arithmetically - alters all flags (CHECKED) */
	private final int sla(int ans) {
		boolean c = (ans & 0x80) != 0;
		ans = (ans << 1) & 0xff;

		setS((ans & F_S) != 0);
		set3((ans & F_3) != 0);
		set5((ans & F_5) != 0);
		setZ((ans) == 0);
		setPV(parity[ans]);
		setH(false);
		setN(false);
		setC(c);

		return (ans);
	}

	/** Shift Left and Set - alters all flags (CHECKED) */
	private final int sls(int ans) {
		boolean c = (ans & 0x80) != 0;
		ans = ((ans << 1) | 0x01) & 0xff;

		setS((ans & F_S) != 0);
		set3((ans & F_3) != 0);
		set5((ans & F_5) != 0);
		setZ((ans) == 0);
		setPV(parity[ans]);
		setH(false);
		setN(false);
		setC(c);

		return (ans);
	}

	/** Shift Right Arithmetically - alters all flags (CHECKED) */
	private final int sra(int ans) {
		boolean c = (ans & 0x01) != 0;
		ans = (ans >> 1) | (ans & 0x80);

		setS((ans & F_S) != 0);
		set3((ans & F_3) != 0);
		set5((ans & F_5) != 0);
		setZ((ans) == 0);
		setPV(parity[ans]);
		setH(false);
		setN(false);
		setC(c);

		return (ans);
	}

	/** Shift Right Logically - alters all flags (CHECKED) */
	private final int srl(int ans) {
		boolean c = (ans & 0x01) != 0;
		ans = ans >> 1;

		setS((ans & F_S) != 0);
		set3((ans & F_3) != 0);
		set5((ans & F_5) != 0);
		setZ((ans) == 0);
		setPV(parity[ans]);
		setH(false);
		setN(false);
		setC(c);

		return (ans);
	}

	/** Decrement - alters all but C flag (CHECKED) */
	private final int dec8(int ans) {
		boolean pv = (ans == 0x80);
		boolean h = (((ans & 0x0f) - 1) & F_H) != 0;
		ans = (ans - 1) & 0xff;

		setS((ans & F_S) != 0);
		set3((ans & F_3) != 0);
		set5((ans & F_5) != 0);
		setZ((ans) == 0);
		setPV(pv);
		setH(h);
		setN(true);

		return (ans);
	}

	/** Increment - alters all but C flag (CHECKED) */
	private final int inc8(int ans) {
		boolean pv = (ans == 0x7f);
		boolean h = (((ans & 0x0f) + 1) & F_H) != 0;
		ans = (ans + 1) & 0xff;

		setS((ans & F_S) != 0);
		set3((ans & F_3) != 0);
		set5((ans & F_5) != 0);
		setZ((ans) == 0);
		setPV(pv);
		setH(h);
		setN(false);

		return (ans);
	}

	/** Add with carry - (NOT CHECKED) */
	private final int adc16(int a, int b) {
		int c = Cset() ? 1 : 0;
		int lans = a + b + c;
		int ans = lans & 0xffff;

		setS((ans & (F_S << 8)) != 0);
		set3((ans & (F_3 << 8)) != 0);
		set5((ans & (F_5 << 8)) != 0);
		setZ((ans) == 0);
		setC((lans & 0x10000) != 0);
		setPV(((a ^ ~b) & (a ^ ans) & 0x8000) != 0);
		setH((((a & 0x0fff) + (b & 0x0fff) + c) & 0x1000) != 0);
		setN(false);

		return (ans);
	}

	/** Add - (NOT CHECKED) */
	private final int add16(int a, int b) {
		int lans = a + b;
		int ans = lans & 0xffff;

		set3((ans & (F_3 << 8)) != 0);
		set5((ans & (F_5 << 8)) != 0);
		setC((lans & 0x10000) != 0);
		setH((((a & 0x0fff) + (b & 0x0fff)) & 0x1000) != 0);
		setN(false);

		return (ans);
	}

	/** Add with carry - (NOT CHECKED) */
	private final int sbc16(int a, int b) {
		int c = Cset() ? 1 : 0;
		int lans = a - b - c;
		int ans = lans & 0xffff;

		setS((ans & (F_S << 8)) != 0);
		set3((ans & (F_3 << 8)) != 0);
		set5((ans & (F_5 << 8)) != 0);
		setZ((ans) == 0);
		setC((lans & 0x10000) != 0);
		setPV(((a ^ b) & (a ^ ans) & 0x8000) != 0);
		setH((((a & 0x0fff) - (b & 0x0fff) - c) & 0x1000) != 0);
		setN(true);

		return (ans);
	}

	/** EXX */
	public final void exx() {
		int t;

		t = HL();
		HL(_HL_);
		_HL_ = t;

		t = DE();
		DE(_DE_);
		_DE_ = t;

		t = BC();
		BC(_BC_);
		_BC_ = t;
	}

	/** EX AF,AF' */
	public final void ex_af_af() {
		int t;
		t = AF();
		AF(_AF_);
		_AF_ = t;
	}

	/** Quick Increment : no flags */
	private final int inc16(int a) {
		return (a + 1) & 0xffff;
	}

	private final int qinc8(int a) {
		return (a + 1) & 0xff;
	}

	/** Quick Decrement : no flags */
	private final int dec16(int a) {
		return (a - 1) & 0xffff;
	}

	private final int qdec8(int a) {
		return (a - 1) & 0xff;
	}

	/** Bit toggling */
	private final int res(int bit, int val) {
		return val & ~bit;
	}

	private final int set(int bit, int val) {
		return val | bit;
	}
}
