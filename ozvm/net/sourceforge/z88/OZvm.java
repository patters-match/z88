package net.sourceforge.z88;

import java.io.*;
import java.util.Timer;
import java.util.TimerTask;

/**
 * @author <A HREF="mailto:gstrube@tiscali.dk">Gunther Strube</A>
 *
 * Main entry of the Z88 virtual machine.
 * 
 * $Id$
 * 
 */
public class OZvm {

	OZvm() {
		try {
			z88 = new Blink();

			// Insert 128K RAM in slot 0 (top 512K address space)
			z88.insertRamCard(128 * 1024, 0);			
			z88.hardReset();

			z80Speed = new MonitorZ80();
			
			dz = new Dz(z88); // the disassembly engine, linked to the memory model

		} catch (Exception e) {
			e.printStackTrace();
			System.out.println("\n\nCouldn't initialize Z88 virtual machine.");
		}
	}
	
	Blink z88 = null;

	private MonitorZ80 z80Speed = null;

	public void startZ80SpeedPolling() {
		z80Speed.start();
	}

	public void stopZ80SpeedPolling() {
		z80Speed.stop();
	}

	public void startInterrupts() {
		z88.startInterrupts();
	}

	public void stopInterrupts() {
		z88.stopInterrupts();
	}

	/**
	 * The Z88 disassembly engine
	 */
	Dz dz;

	private StringBuffer z80Flags() {
		StringBuffer dzFlags = new StringBuffer(8);
		
		dzFlags.append( z88.Sset() == true ? "S" : "0");
		dzFlags.append( z88.Zset() == true ? "Z" : "0");
		dzFlags.append( z88.f5set() == true ? "1" : "0");
		dzFlags.append( z88.Hset() == true ? "H" : "0");
		dzFlags.append( z88.f3set() == true ? "1" : "0");
		dzFlags.append( z88.PVset() == true ? "P" : "V");
		dzFlags.append( z88.Nset() == true ? "N" : "0");
		dzFlags.append( z88.Cset() == true ? "C" : "0");
		
		return dzFlags;
	}
	
	/**
	 * Dump current Z80 Registers and instruction disassembly to stdout.  
	 */
	private void z80Status() {
		StringBuffer dzBuffer = new StringBuffer(1024);
		
		dzBuffer.append(" ").append("BC=").append(dz.addrToHex(z88.BC(),false)).append(" ");
		dzBuffer.append(" ").append("DE=").append(dz.addrToHex(z88.DE(),false)).append(" ");
		dzBuffer.append(" ").append("HL=").append(dz.addrToHex(z88.HL(),false)).append(" ");
		dzBuffer.append(" ").append("IX=").append(dz.addrToHex(z88.IX(),false)).append(" ");
		dzBuffer.append(" ").append("IY=").append(dz.addrToHex(z88.IY(),false)).append(" ");
		dzBuffer.append(" ").append("\n");
		z88.exx();
		dzBuffer.append("'BC=").append(dz.addrToHex(z88.BC(),false)).append(" ");
		dzBuffer.append("'DE=").append(dz.addrToHex(z88.DE(),false)).append(" ");
		dzBuffer.append("'HL=").append(dz.addrToHex(z88.HL(),false)).append(" ");
		z88.exx();
		dzBuffer.append(" ").append("SP=").append(dz.addrToHex(z88.SP(),false)).append(" ");
		dzBuffer.append(" ").append("PC=").append(dz.addrToHex(z88.PC(),false)).append("\n");
		dzBuffer.append(" ").append("AF=").append(dz.addrToHex(z88.AF(),false)).append(" ");
		dzBuffer.append(" ").append("A=").append(dz.byteToHex(z88.A(),false)).append(" ");
		dzBuffer.append(" ").append("F=").append(z80Flags()).append(" ");
		dzBuffer.append(" ").append("I=").append(z88.I()).append("\n");
		z88.ex_af_af();
		dzBuffer.append("'AF=").append(dz.addrToHex(z88.AF(),false)).append(" ");
		dzBuffer.append("'A=").append(dz.byteToHex(z88.A(),false)).append(" ");
		dzBuffer.append("'F=").append(z80Flags()).append(" ");
		dzBuffer.append(" ").append("R=").append(z88.R()).append("\n");
		
		System.out.println(dzBuffer);
		
		dz.getInstrAscii(dzBuffer, z88.PC(), true);
		System.out.println(dzBuffer);
	}
	
	private boolean loadRom(String[] args) {
		try {
			if (args.length == 0) {
				System.out.println("No external ROM image specified, using default Z88.rom (V4.01 UK)");
				z88.loadRomBinary(z88.getClass().getResource("/Z88.rom"));				
			} else {
				System.out.println("Loading '" + args[0] + "'");
				RandomAccessFile rom = new RandomAccessFile(args[0], "r");		
				z88.loadRomBinary(rom);
			}			
			return true;

		} catch (FileNotFoundException e) {
			System.out.println("Couldn't load ROM image.\nOzvm terminated.");
			return false;
		} catch (IOException e) {
			System.out.println("Problem with ROM image or I/O.\nOzvm terminated.");
			return false;
		}		
	}

	private void commandLine() throws IOException {
		String cmdline = "";
		String[] cmdLineTokens = null;
		
		BufferedReader in =
			new BufferedReader(new InputStreamReader(System.in));
		System.out.println("Type 'h' or 'help' for command line options\n");
		z80Status();
		
		StringBuffer prevCmdline = new StringBuffer();
		System.out.print("$");
		do {
			if (cmdline.length() == 0)
				cmdline = prevCmdline.toString();
				
			cmdLineTokens = cmdline.split(" "); 
			if (cmdLineTokens[0].equalsIgnoreCase("run") == true) {
				System.out.println("Executing Z88 Virtual Machine...");		
				z80Speed.start();
				z88.startInterrupts();
				z88.run();
			}
			
			if (cmdLineTokens[0].equalsIgnoreCase("d") == true) {
				cmdline = dzCommandline(in, cmdLineTokens);
			}
			
			if (cmdline.length() > 0)
				prevCmdline.replace(0, 64, cmdline);
				
			if (cmdline.length() == 0) {
				cmdline = in.readLine();
				System.out.print("$");
			} 
		} while (cmdline.equalsIgnoreCase("exit") == false);		
	}

	private String dzCommandline(BufferedReader in, String[] cmdLineTokens) throws IOException {
		int dzAddr = 0, dzBank = 0;		
		StringBuffer dzLine = new StringBuffer(64);
		String dzCmdline = null;
	
		if (cmdLineTokens.length == 1) {
			// no arguments, use PC in current bank binding
			dzAddr = z88.PC();
			dzBank = z88.getSegmentBank(dzAddr >>> 14);
		}

		if (cmdLineTokens.length == 2) {
			// one arguments, the local Z80 64K address 
			dzAddr = Integer.parseInt(cmdLineTokens[1], 16);
			dzBank = z88.getSegmentBank(dzAddr >>> 14);
		}

		if (cmdLineTokens.length == 3) {
			// two arguments, the offset and the bank number 
			dzAddr = Integer.parseInt(cmdLineTokens[1], 16);
			dzBank = Integer.parseInt(cmdLineTokens[2], 16);
		}

		do {		
			for (int dzLines = 0;  dzLines < 16; dzLines++) {
				dzAddr = dz.getInstrAscii(dzLine, dzAddr, dzBank, true);
				System.out.println(dzLine);
			}
			
			System.out.print("$");
		}
		while ((dzCmdline = in.readLine()).length() == 0);
		
		return dzCmdline;
	}
	
	public static void main(String[] args) throws IOException {		
		System.out.println("OZvm V0.01, Z88 Virtual Machine");

		OZvm ozvm = new OZvm();
		if (ozvm.loadRom(args) == false) {
			System.out.println("Ozvm terminated.");
			System.exit(0);
		}
		
		ozvm.commandLine();
		
		System.out.println("Ozvm terminated.");
		System.exit(0);
	}


	/** 
	 * Z80 instruction speed monitor. 
	 * Polls each second for the execution speed and displays it to std out.
	 */
	private class MonitorZ80 {

		Timer timer = null;
		TimerTask monitor = null;
		private long oldTimeMs = 0;

		private class SpeedPoll extends TimerTask {
			/**
			 * Request poll each second, or try to hit the 1 sec time frame...
			 * 
			 * @see java.lang.Runnable#run()
			 */
			public void run() {
				float realMs = System.currentTimeMillis() - oldTimeMs;
				int ips = (int) (z88.getInstructionCounter() * realMs/1000);
				int tps = z88.getTstatesCounter();

				System.out.println( "IPS=" + ips + ",TPS=" + tps);

				oldTimeMs = System.currentTimeMillis();
			}			
		}
		
		private MonitorZ80() {
			timer = new Timer();
		}

		/**
		 * Stop the Z80 Speed Monitor.
		 */
		public void stop() {
			if (timer != null)
				timer.cancel();
		}

		/**
		 * Speed polling monitor asks each second for Z80 speed status.
		 */
		public void start() {
			monitor = new SpeedPoll();
			oldTimeMs = 0;
			timer.scheduleAtFixedRate(monitor, 0, 1000);
		}
	} 
}
