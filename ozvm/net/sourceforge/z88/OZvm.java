package net.sourceforge.z88;

import java.io.*;

/**
 * @author <A HREF="mailto:gstrube@tiscali.dk">Gunther Strube</A>
 *
 * Main entry of the Z88 virtual machine.
 * 
 * $Id$
 * 
 */
public class OZvm {

	static private final String defaultRomImage = "Z88.rom";

	public static void main(String[] args) throws IOException {
		Z88 z88 = null;

		/**
		 * The Z88 disassembly engine
		 */
		Dz dz;
		
		String cmdline = "";

		try {
			z88 = new Z88();
			dz = new Dz(z88); // the disassembly engine

			// Instantiate a Z88 environment with default 128K RAM
		} catch (Exception e) {
			e.printStackTrace();
			System.out.println("\n\nCouldn't initialize Z88 virtual machine.");
			return;
		}

		try {
			if (args.length == 0) {
				System.out.println("No external ROM image specified, using default Z88.rom (V4.01 UK)");
				z88.loadRom(z88.getClass().getResource("/" + defaultRomImage));
			} else {
				System.out.println("Loading '" + args[0] + "'");
				z88.loadRom(args[0]);
			}			

		} catch (FileNotFoundException e) {
			System.out.println("Couldn't load ROM image.\nOzvm terminated.");
			System.exit(0);
		} catch (IOException e) {
			System.out.println("Problem with ROM image or I/O.\nOzvm terminated.");
			System.exit(0);
		}

		z88.hardReset();

		System.out.println("OZvm V0.01, Z88 Virtual Machine");
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
				z88.startZ80SpeedPolling();
				z88.startInterrupts();
				z88.run();
			}
			
			if (cmdline.equalsIgnoreCase("d") == true) {
				int dzAddr = z88.PC();
				for (int dzLines = 0;  dzLines < 16; dzLines++) {
					dzAddr = dz.getInstrAscii(dzLine, dzAddr, true);
					System.out.println(dzLine);
				}
			}
			
			if (cmdline.length() > 0)
				prevCmdline.replace(0, 64, cmdline);
		}
		
		System.out.println("Ozvm terminated.");
		System.exit(0);
	}
}
