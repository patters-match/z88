/*
 * MakeJar.java
 * (C) Copyright Gunther Strube (gbs@users.sf.net), 2006
 *
 * MakeJar is free software; you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation;
 * either version 2, or (at your option) any later version.
 * MakeJar is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 * without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * You should have received a copy of the GNU General Public License along with MakeJar;
 * see the file COPYING. If not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *
 * @author <A HREF="mailto:gbs@users.sourceforge.net">Gunther Strube</A>
 * $Id$
 *
 */

package net.sourceforge.z88.tools.jdk.makejar;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.RandomAccessFile;


/**
 * Simple command line tool to create Java Archives based on command line parameters.
 */
public class MakeJar {

	private static final String appVersion = "MakeJar V0.9";
	
	private boolean createArchive;
	private boolean listContents;
	private boolean includeManifestFile;
	
	private String archiveFilename;
	private int compressLevel;
	
	public MakeJar() {
		compressLevel = 9;  // use maximum compression level by default
	}
	
	/**
	 * Parse command line arguments and execute accordingly.
	 * @param args
	 */
	private void parseArgs(String[] args) {
		int arg;
		
		if (args.length == 0) {
			displayCmdLineSyntax();
		} else {
			if (args[0].charAt(0) != '-') {
				System.out.println("mandatory -c or -t option not specified!");
				return;
			}
			
			// parse options, -c, -t, -v 
			for (arg=0; arg<args.length; arg++) {
				if (args[arg].charAt(0) == '-') {
					for (int options=1; options<args[arg].length(); options++) {
						if (args[arg].charAt(options) == 'c') {
							createArchive = true;
						}
						
						if (args[arg].charAt(options) == 't') {
							listContents = true;
						}
						
						if (args[arg].charAt(options) == 'm') {
							// use specified manifest file
							includeManifestFile = true;
						}

						if (args[arg].charAt(options) >= '0' && args[arg].charAt(options) <= '9') {
							// fetch compress level
							compressLevel = args[arg].charAt(options) - 48; 
						}

						if (args[arg].charAt(options) == 'v') {
							System.out.println(appVersion);
						}
					}
				} else {
					// after mandatory options follows the java archive filename
					break;
				}
			}
			
			System.out.println("Options: -c = " + 
					Boolean.toString(createArchive) + ", -t = " + 
					Boolean.toString(listContents));
			
			archiveFilename = args[arg++];  
			
			System.out.println("Archive filename = " + archiveFilename);
			
			System.out.println("Add files/dirs = " + args[arg]);
			System.out.println("Compress level = " + compressLevel);
		}
	}


	/**
	 * When no command line arguments have been specified, write some explanations
	 * to the shell.
	 */
	private void displayCmdLineSyntax() {
		System.out.println("Name:");
		System.out.println("makejar.jar - Archive tool for Java archives.\n");
		System.out.println("Syntax:");
		System.out.println("makejar -ct [OPTIONS] jar-file [manifest-file] [-C] files...\n");
		System.out.println("-c      Create new archive");
		System.out.println("-t      List table of contents from archive");
		System.out.println("[OPTIONS]");
		System.out.println("-m manifest-file");
		System.out.println("        Include manifest information from specified manifest file.\n");
		System.out.println("-{0-9}  Specify ZIP compression (0=no compression, 9=highest).");
		System.out.println("        (Default compression is 9).\n");
		System.out.println("-C directory");
		System.out.println("        Change to the directory and include the following files.\n");
		System.out.println("-v      Display version information.");
	}

	/**
	 * Command Line Entry for MakeApp utility.
	 * @param args
	 */
	public static void main(String[] args) {
		MakeJar mj = new MakeJar();
		mj.parseArgs(args);
	}
}
