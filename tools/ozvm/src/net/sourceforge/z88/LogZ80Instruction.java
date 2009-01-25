/*
 * LogZ80Instruction.java
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
 * This class is used by the virtual Z80 processor, Z80.java, to dump executed
 * Z80 instructions in log files, in a readable format with ext. address,
 * instruction mnemonic and register dump of AF, BC, DE, HL, IX, IY, SP & PC
 * registers.
 *
 * The logging features uses a internal cache mechanism of 100.000 instructions.
 * When the cache is full, the instruction log is flushed to the current
 * "z80_" X log file. After each cache flush, the log counter increases.
 *
 * Logging Z80 instructions is an intensive I/O process and will severely slow down
 * execution emulation.
 *
 */
public class LogZ80Instruction {
		private static final int BUFSIZE = 100000;

		private int pcAddressCache[];
		private int registerCache[][];
		private int index;
		private int logFileCounter;

		public LogZ80Instruction() {
			pcAddressCache = new int[BUFSIZE];
			registerCache = new int[BUFSIZE][8];
		}

		public boolean isCacheAvailable() {
			return index != 0;
		}

		public void logInstruction(int pcAddress, int af, int bc, int de, int hl, int ix, int iy, int sp, int pc) {
			if (index == BUFSIZE) {
				// dump cache to log file, and reset index to 0
				flushCache();
			}

			pcAddressCache[index] = pcAddress;

			registerCache[index][0] = af;
			registerCache[index][1] = bc;
			registerCache[index][2] = de;
			registerCache[index][3] = hl;
			registerCache[index][4] = ix;
			registerCache[index][5] = iy;
			registerCache[index][6] = sp;
			registerCache[index][7] = pc;

			index++;
		}

		/**
		 * Dump executed instruction cache to log file
		 */
		public void flushCache() {
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
