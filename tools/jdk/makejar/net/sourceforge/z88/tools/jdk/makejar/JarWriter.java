/*  JarWriter.java
 *
 *  Copyright (C) 2002-2003 Dominik Werthmueller
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 * @author <A HREF="mailto:werti@gmx.net">Dominik Werthmueller</A>
 *
 */ 
 
package net.sourceforge.z88.tools.jdk.makejar;

import java.util.jar.JarOutputStream;
import java.util.zip.ZipEntry;
import java.io.*;
 
/*
 * All Swing related feature has been removed from this class to
 * to let it serve as a pure helper class in generating Jar files
 * without the need to use a Gui. This class is now an internal
 * part of the makejar utility that mimics the command line parameters
 * for creating a jar file. Use the file list unmodified. 
 *
 * Modifications made by G.Strube (gbs@users.sf.net), June 2006.
 * 
*/ 
 
/** 
 * This class allows to easily build a jar file.
 *
 * @author Dominik Werthmueller
 * 
 */
 
public class JarWriter {
	
	private String[] files;
	private String manifest;
	private File manifestFile;
	private boolean includeManifest = true;
	private boolean loadManifest = false;
	private int writtenBytes;
	private int totalFileSize;
	
	private final int BUFFERSIZE = 32768;
		
	
	/** 
	 * set the manifest include option
	 *
	 * @param true for including manifest, false for non-including manifest
	 */
	public void setIncludeManifest(boolean b) {
		includeManifest = b;
	}
	
	
	/** 
	 * return the manifest include option
	 *
	 * @return manifest include option
	 */
	public boolean getIncludeManifest() {
		return includeManifest;
	}
	
	
	/** 
	 * set the manifest load option
	 *
	 * @param true for loading manifest, false for non-loading manifest
	 */
	public void setLoadManifest(boolean b) {
		loadManifest = b;
	}
	
	
	/** 
	 * return the manifest load option
	 *
	 * @return manifest include option
	 */
	public boolean getLoadManifest() {
		return loadManifest;
	}
	
		
	/** 
	 * set the files for the jar file
	 *
	 * @param files for the jar file
	 */
	public void setFiles(String[] f) {
		files = f;
	}
	
	
	/** 
	 * return the files of the jar file
	 *
	 * @return files of the jar file
	 */
	public String[] getFiles() {
		return files;
	}
	
	
	/** 
	 * return the file at the given index of the jar file
	 *
	 * @param index
	 * @return the file at the given index of the jar file
	 */
	public String getFile(int i) {
		return files[i];
	}
	
	
	/** 
	 * set the manifest content for the jar file
	 *
	 * @param manfest content for the jar file
	 */
	public void setManifest(String m) {
		manifest = m;
	}
	
	
	/** 
	 * return the manifest content of the jar file
	 *
	 * @return manifest content of the jar file
	 */
	public String getManifest() {
		return manifest;
	}
	
	
	/** 
	 * set the manifest file for the jar file
	 *
	 * @param manfest file for the jar file
	 */
	public void setManifestFile(File f) {
		manifestFile = f;
	}
	
	
	/** 
	 * return the manifest file of the jar file
	 *
	 * @return manifest file of the jar file
	 */
	public File getManifestFile() {
		return manifestFile;
	}
	
	
	
	/** 
	 * return the number of files of the jar file
	 *
	 * @return number of files of the jar file
	 */
	public int getLength() {
		return files.length;
	}
	
	
	/** 
	 * write the manifest file
	 *
	 * @return the manifest file
	 */
	private File writeManifest() {
		File fManifest = new File("Manifest.tmp");
		try {
			BufferedWriter bout = new BufferedWriter(new FileWriter(fManifest));
		
			if (!manifest.equals("")) {
				bout.write("Manifest-Version: 1.0");
				bout.newLine();
				bout.write("Created-By: " + MakeJar.appVersion);
				bout.newLine();
				bout.write(manifest);
				bout.newLine();
				bout.newLine();
			}
			
			bout.close();
		} catch (Exception e) {
			System.out.println("[writeManifest(), JarWriter] ERROR\n" + e);
		}
		
		return fManifest;	
	}	
	
	/**
	 * calculate the size of one file (kb)
	 *
	 * @param file
	 */
	private int getFileSize(File f) {
		File[] dContent;
		int dSize;
		
		if (f.isDirectory() ==  false) {
			return (int)(f.length() / 1024f);
		}
		else {
			dContent = f.listFiles();
			dSize = 0;
			for (int a = 0; a < dContent.length; a++) {
				dSize += getFileSize(dContent[a]);	
			}
			return dSize;
		}
	}

	
	/**
	 * calculate the size of all files (kb)
	 *
	 * @return the total file size
	 */
	private int getTotalFileSize() {
		File f;
		int totalSize = 0;
		
		for (int i = 0; i < files.length; i++) {
			f = new File(files[i]);
			totalSize += getFileSize(f);		
		}
		return totalSize;
	}
	
	 
	/** 
	 * write the manifest entry in the jar file
	 *
	 * @param file to write
	 * @param current JarOutputStream
	 */
	private void writeManifestEntry(File f, JarOutputStream out) {
		// buffer
		byte[] buffer = new byte[BUFFERSIZE];
			
		// read bytes
		int bytes_read;
		
		try {
			BufferedInputStream in = new BufferedInputStream(new FileInputStream(f), BUFFERSIZE);
			String en = "META-INF" + "/" + "MANIFEST.MF";
			out.putNextEntry(new ZipEntry(en));
			while ((bytes_read = in.read(buffer)) != -1) {
				out.write(buffer, 0, bytes_read);
			}
				
			in.close();
			out.closeEntry();
		} catch (Exception e) {
			System.out.println("[writeManifestEntry(), JarWriter] ERROR\n" + e);
		}
	}


	/** 
	 * write entries in the jar file
	 *
	 * @param file to write
	 * @param current JarOutputStream
	 * @return true if the file was successfully written, false if there was an error during the writing
	 */
	private boolean writeEntry(File f, JarOutputStream out) {
		// buffer
		byte[] buffer = new byte[BUFFERSIZE];
		String entryName = f.getPath();

    	// remove preceeding ".", ".." and
    	if (entryName.startsWith("..") == true)
    		entryName = entryName.substring(2);
    	
    	if (entryName.startsWith(".") == true)
    		entryName = entryName.substring(1);

    	if (entryName.startsWith(System.getProperty("file.separator")) == true)
    		entryName = entryName.substring(1);
    	
    	// Path separators in Zip entries are using '/', NOT '\'!
		entryName = entryName.replaceAll("\\\\","/");
		
		if (entryName.length() == 0)
			// ignore empty names
			return true;
			
		// read bytes
		int bytes_read;
		
		try {
			
			if (f.isDirectory() == false) {	
				out.putNextEntry(new ZipEntry(entryName));
				BufferedInputStream in = new BufferedInputStream(new FileInputStream(f), BUFFERSIZE);
				
				while ((bytes_read = in.read(buffer)) != -1) {
					// do the work
					out.write(buffer, 0, bytes_read);
										
					// update progress bar
					writtenBytes += bytes_read;
				}

				in.close();
			} else {
				// just write the directory entry..
				out.putNextEntry(new ZipEntry(entryName + "/"));
			}

			out.closeEntry();
		} catch (Exception e) {
			System.out.println("[writeEntry(), JarWriter] ERROR\n" + e);
			return false;
		}

		return true;
	}


	/**
	 * create a jar file including the files and the manifest file
	 *
	 * @param the jar file
	 * @param true to compress, false to not compress
	 * @return true if the file was successfully built, false if there was an error during the building process
	 */
	public boolean createJar(File fj, int compress) {
		File f;
		boolean written;
		
		try {
			// target
			JarOutputStream out = new JarOutputStream(new FileOutputStream(fj));
			out.setComment("This file was created by " + MakeJar.appVersion);
			
			// set the compression rate
			out.setLevel(compress);
			
			// preparations
			totalFileSize = getTotalFileSize();
			writtenBytes = 0;
			
			// add files
			for (int i = 0; i < files.length; i++) {
				f = new File(files[i]);
				written = writeEntry(f, out);
				if (!written) {
					out.close();
					fj.delete();
					return false;
				}
			}
			
			// add manifest
			if (includeManifest) {
				if (loadManifest == false) {
					f = writeManifest();
					writeManifestEntry(f, out);
					f.delete();
				}
				else {
					writeManifestEntry(manifestFile, out);
				}
			}
			
			out.close();
			return true;
			
		} catch (Exception e) {
			System.out.println("[createJar(), JarWriter] ERROR\n" + e);
			return false;
		}
	}
	
	
	
	// ---------- Begin Constructor Section ----------
		
	/** 
	 * construct an JarWriter class including the given files
	 */
	public JarWriter(String[] f) {
		files = f;
		manifest = "";
	}
	
	
	/** 
	 * construct an JarWriter class including the given files and the given Manifest file
	 */
	public JarWriter(String[] f, String m) {
		files = f;
		manifest = m;
	}	
}	
