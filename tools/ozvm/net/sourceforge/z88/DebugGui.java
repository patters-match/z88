/*
 * DebugGui.java
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

import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Dimension;

import javax.swing.ImageIcon;
import javax.swing.JFrame;


/**
 * Gui framework OZvm debugging mode.
 */
public class DebugGui extends JFrame {
	
	private javax.swing.JMenuBar jJMenuBar = null;
	private javax.swing.JMenu jFileMenu = null;  
	
	private javax.swing.JTextArea jCmdOutput = null;  
	private javax.swing.JTextField jCmdlineInput = null;  
	private javax.swing.JScrollPane jCmdLineScrollPane = null;

	/**
	 * This is the default constructor
	 */
	public DebugGui() {
		super();
		initialize();
	}

	/**
	 * This method initializes the z88 display window and menus
	 */
	private void initialize() {
		setIconImage(new ImageIcon(this.getClass().getResource("/pixel/debug.gif")).getImage());		
		setJMenuBar(getOZvmMenuBar());

		getContentPane().add(getCmdLineScrollPane(), BorderLayout.CENTER);
		getContentPane().add(getCmdLineInputArea(), BorderLayout.SOUTH);
		
		this.setTitle("OZvm Debugger");
		this.setResizable(true);
		this.setForeground(java.awt.Color.green);
		this.pack();
		this.setVisible(true);

		this.addWindowListener(new java.awt.event.WindowAdapter() {
			public void windowClosing(java.awt.event.WindowEvent e) {
				OZvm.getInstance().commandLine(false);
			}
		});		
				
		getCmdLineInputArea().grabFocus();	// make sure that caret is blinking in command line area...		
	}
	
	/**
	 * This method initializes the Menu bar for OZvm
	 *
	 * @return javax.swing.JMenuBar
	 */
	public javax.swing.JMenuBar getOZvmMenuBar() {
		if(jJMenuBar == null) {
			jJMenuBar = new javax.swing.JMenuBar();
			jJMenuBar.add(getFileMenu());
		}
		return jJMenuBar;
	}
	
	/**
	 * This method initializes main File Menu dropdown
	 *
	 * @return javax.swing.JMenu
	 */
	private javax.swing.JMenu getFileMenu() {
		if(jFileMenu == null) {
			jFileMenu = new javax.swing.JMenu();
			jFileMenu.setSize(46, 24);
			jFileMenu.setText("File");
			jFileMenu.setMnemonic(java.awt.event.KeyEvent.VK_F);
		}
		return jFileMenu;
	}
	
	
	/**
	 * This method initializes the OZvm Command Debugging Output Area
	 *
	 * @return javax.swing.JTextArea
	 */
	public javax.swing.JTextArea getCmdlineOutputArea() {
		if(jCmdOutput == null) {
			jCmdOutput = new javax.swing.JTextArea(20,96);
			jCmdOutput.setFont(new java.awt.Font("Monospaced",java.awt.Font.PLAIN, 11));
			jCmdOutput.setBackground(Color.BLACK);
			jCmdOutput.setForeground(Color.GREEN);
			jCmdOutput.setTabSize(1);
			jCmdOutput.setEditable(false);
			jCmdOutput.setToolTipText("This area displays debug command output.");
			jCmdOutput.setVisible(true);
		}
		return jCmdOutput;
	}

	/**
	 * This method initializes the
	 *
	 * @return javax.swing.JTextField
	 */
	public javax.swing.JTextField getCmdLineInputArea() {
		if(jCmdlineInput == null) {
			jCmdlineInput = new javax.swing.JTextField();
			jCmdlineInput.setFont(new java.awt.Font("Monospaced",java.awt.Font.PLAIN, 11));
			jCmdlineInput.setToolTipText("Type your debugging commands here");
			jCmdlineInput.setVisible(true);
		}
		return jCmdlineInput;
	}
	
	/**
	 * This method initializes jScrollPane2
	 *
	 * @return javax.swing.JScrollPane
	 */
	private javax.swing.JScrollPane getCmdLineScrollPane() {
		if(jCmdLineScrollPane == null) {
			jCmdLineScrollPane = new javax.swing.JScrollPane();
			jCmdLineScrollPane.setViewportView(getCmdlineOutputArea());
		}
		return jCmdLineScrollPane;
	}	
}
