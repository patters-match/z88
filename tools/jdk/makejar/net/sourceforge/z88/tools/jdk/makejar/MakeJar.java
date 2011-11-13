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
 *
 */

package net.sourceforge.z88.tools.jdk.makejar;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

/**
 * Simple command line tool to create Java Archives based on command line
 * parameters.<br>
 * The tool implements a command line compatible subset of the original jar tool
 * from the JDK.
 */
public class MakeJar {

	public static final String appVersion = "MakeJar V0.9";

	private boolean createArchive;

	private boolean listContents;

	private boolean includeManifestFile;

	private String archiveFilename;

	private String manifestFilename;

	private int compressLevel;

	private ArrayList fdList;

	public MakeJar() {
		compressLevel = 9; // use maximum compression level by default
		fdList = new ArrayList();
	}

	/**
	 * Process all files and directories under dir.
	 */
	private void visitAllDirsAndFiles(File dir) {
		fdList.add(dir.getPath());

		if (dir.isDirectory()) {
			String[] children = dir.list();
			for (int i = 0; i < children.length; i++) {
				visitAllDirsAndFiles(new File(dir, children[i]));
			}
		}
	}

	/**
	 * Create the final Jar archive, based on the specified command line
	 * options.
	 */
	private void createJar() {
		String files[] = new String[fdList.size()];

		for (int l = 0; l < fdList.size(); l++) {
			files[l] = fdList.get(l).toString();
		}

		JarWriter jw = new JarWriter(files);
		if (includeManifestFile == true) {
			jw.setManifestFile(new File(manifestFilename));
			jw.setIncludeManifest(true);
			jw.setLoadManifest(true);
		}

		jw.createJar(new File(archiveFilename), compressLevel);
	}

	/**
	 * List table of contents of specified Jar file to System out. (-t option
	 * was used from command line)
	 */
	private void tocJarFile() {
		try {
			// Open the ZIP file
			ZipFile zf = new ZipFile(archiveFilename);

			// Enumerate each entry
			for (Enumeration entries = zf.entries(); entries.hasMoreElements();) {
				// Display the entry name
				System.out
						.println(((ZipEntry) entries.nextElement()).getName());
			}

			zf.close();
		} catch (IOException e) {
			System.err.println("Couldn't open Jar file '" + archiveFilename
					+ "'");
		}
	}

	/**
	 * Parse command line arguments and execute accordingly.
	 * 
	 * @param args
	 */
	private void parseArgs(String[] args) {
		int arg;

		if (args.length == 0) {
			System.out.println("Try -h for more information");
		} else {
			if (args[0].charAt(0) != '-') {
				System.out.println("mandatory -c or -t option not specified!");
				return;
			}

			// parse options, -c, -t, -v
			for (arg = 0; arg < args.length; arg++) {
				if (args[arg].charAt(0) == '-') {
					for (int options = 1; options < args[arg].length(); options++) {
						if (args[arg].charAt(options) == 'c') {
							createArchive = true;
						}

						if (args[arg].charAt(options) == 't') {
							// don't create Jar, but list table of contents in
							// Jar...
							listContents = true;
						}

						if (args[arg].charAt(options) == 'h') {
							// display help page
							displayCmdLineSyntax();
						}

						if (args[arg].charAt(options) == 'm') {
							// use specified manifest file
							includeManifestFile = true;
						}

						if (args[arg].charAt(options) >= '0'
								&& args[arg].charAt(options) <= '9') {
							// fetch compress level
							compressLevel = args[arg].charAt(options) - 48;
						}

						if (args[arg].charAt(options) == 'V') {
							System.out.println(appVersion);
						}
					}
				} else {
					// break as soon as last option has been fetched
					// and start to fetch filenames and dirs (if options signals
					// it)
					break;
				}
			}

			// after mandatory options follows the java archive filename (if -c
			// or -t specified)
			if (createArchive == true || listContents == true)
				archiveFilename = args[arg++];

			if (includeManifestFile == true)
				// when -m option was specified, fetch manifest filename right
				// after mandatory Jar filename
				manifestFilename = args[arg++];

			if (createArchive == true) {
				// create Jar: scan rest of arguments as filenames/directories
				// to be added in Jar...
				for (; arg < args.length; arg++) {
					visitAllDirsAndFiles(new File(args[arg]));
				}

				createJar();
			} else {
				if (listContents == true) {
					// -t specified, just list table of contents of specified
					// jar
					// file to stdout...
					tocJarFile();
				}
			}
		}
	}

	/**
	 * When no command line arguments have been specified, write some
	 * explanations to the shell.
	 */
	private void displayCmdLineSyntax() {
		System.out.println("Name:");
		System.out.println("makejar.jar - Archive tool for Java archives.\n");
		System.out.println("Syntax:");
		System.out
				.println("java -jar makejar.jar -cthV [OPTIONS] jar-file [manifest-file] files...\n");
		System.out.println("-c      Create new archive");
		System.out.println("-t      List table of contents from archive");
		System.out.println("-h      Display this help page");
		System.out.println("-V      Display version information.\n");
		System.out.println("[OPTIONS]");
		System.out.println("-m manifest-file");
		System.out
				.println("        Include manifest information from specified manifest file.\n");
		System.out
				.println("-{0-9}  Specify ZIP compression (0=no compression, 9=highest).");
		System.out.println("        (Default compression is 9).\n");
	}

	/**
	 * Command Line Entry for MakeApp utility.
	 * 
	 * @param args
	 */
	public static void main(String[] args) {
		MakeJar mj = new MakeJar();
		mj.parseArgs(args);
	}
}
