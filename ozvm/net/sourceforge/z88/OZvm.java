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
			blink = new Blink();

			// Insert 128K RAM in slot 0 (top 512K address space)
			blink.insertRamCard(128 * 1024, 0);			
			blink.hardReset();

			z80Speed = new MonitorZ80();
			
			dz = new Dz(blink); // the disassembly engine, linked to the memory model

		} catch (Exception e) {
			e.printStackTrace();
			System.out.println("\n\nCouldn't initialize Z88 virtual machine.");
		}
	}
	
	static private final String defaultRomImage = "Z88.rom";

	Blink blink = null;

	private MonitorZ80 z80Speed = null;

	public void startZ80SpeedPolling() {
		z80Speed.start();
	}

	public void stopZ80SpeedPolling() {
		z80Speed.stop();
	}

	public void startInterrupts() {
		blink.startInterrupts();
	}

	public void stopInterrupts() {
		blink.stopInterrupts();
	}

	/**
	 * The Z88 disassembly engine
	 */
	Dz dz;

	private boolean loadRom(String[] args) {
		try {
			if (args.length == 0) {
				System.out.println("No external ROM image specified, using default Z88.rom (V4.01 UK)");
				blink.loadRomBinary(blink.getClass().getResource("/" + defaultRomImage));				
			} else {
				System.out.println("Loading '" + args[0] + "'");
				RandomAccessFile rom = new RandomAccessFile(args[0], "r");		
				blink.loadRomBinary(rom);
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
		
		BufferedReader in =
			new BufferedReader(new InputStreamReader(System.in));
		System.out.print("Type 'h' or 'help' for command line options\n$");
		
		StringBuffer dzLine = new StringBuffer(64);
		StringBuffer prevCmdline = new StringBuffer();
		while ((cmdline = in.readLine()).equalsIgnoreCase("exit") == false) {
			System.out.print("$");
			
			if (cmdline.length() == 0)
				cmdline = prevCmdline.toString();
				
			if (cmdline.equalsIgnoreCase("run") == true) {
				System.out.println("Executing Z88 Virtual Machine...");		
				z80Speed.start();
				blink.startInterrupts();
				blink.run();
			}
			
			if (cmdline.equalsIgnoreCase("d") == true) {
				int dzAddr = blink.PC();
				for (int dzLines = 0;  dzLines < 16; dzLines++) {
					dzAddr = dz.getInstrAscii(dzLine, dzAddr, true);
					System.out.println(dzLine);
				}
			}
			
			if (cmdline.length() > 0)
				prevCmdline.replace(0, 64, cmdline);
		}		
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
				int ips = (int) (blink.getInstructionCounter() * realMs/1000);
				int tps = blink.getTstatesCounter();

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
