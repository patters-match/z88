package net.sourceforge.z88;

import java.io.FileNotFoundException;
import java.io.IOException;

/**
 * @author Gunther Strube
 *
 * Main entry of the Z88 virtual machine.
 * 
 * $Id$
 * 
 */
public class OZvm {

	static private final String defaultRomImage = "z88.rom";
	
	public static void main(String[] args) {
		Z88 z88 = null;
		
		try {
			z88 = new Z88();	// Instantiate a Z88 environment with default 128K RAM
		} catch (Exception e) {
			System.out.println("Couldn't initialize Z88 virtual machine.");
			return;
		}
		
		try {
			if (args.length == 0)
				z88.loadRom(defaultRomImage);
			else
				z88.loadRom(args[0]);
		} catch (FileNotFoundException e) {
			System.out.println("Couldn't load ROM image.");
			return;
		} catch (IOException e) {
			System.out.println("Problem with ROM image or I/O");
			return;
		}
		
		System.out.println("OZvm V0.01, Z88 Virtual Machine");
	}
}
