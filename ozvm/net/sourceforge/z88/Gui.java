/*
 * Gui.java
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
import java.awt.Container;
import java.awt.Dimension;
import javax.swing.JFrame;
import javax.swing.JPanel;
import javax.swing.UIManager;


/**
 * Gui framework for OZvm.
 */
public class Gui extends JFrame {

	private static final class singletonContainer {
		static final Gui singleton = new Gui();  
	}
	
	public static Gui getInstance() {
		return singletonContainer.singleton;
	}
	
	private javax.swing.JMenuBar jJMenuBar = null;
	private javax.swing.JMenu jFileMenu = null;  
	private javax.swing.JMenu jHelpMenu = null;
	private javax.swing.JPanel jCommandArea = null;  
	private javax.swing.JTextArea jCmdOutput = null;  
	private javax.swing.JTextField jCmdlineInput = null;  
	private javax.swing.JTextArea jRtmMessages = null;  
	private javax.swing.JPanel jRtmOutputWindowContentPane = null;
	private javax.swing.JButton jClearMessagesButton = null;
	private javax.swing.JScrollPane jRtmOutputScrollPane = null;
	private javax.swing.JScrollPane jCmdLineScrollPane = null;
	private javax.swing.JTextArea jRtmOutputArea = null;

	/**
	 * This is the default constructor
	 */
	public Gui() {
		super();
		initialize();
	}

	/**
	 * This method initializes the z88 display window and menus
	 */
	private void initialize() {
		try {
		  UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
		} catch(Exception e) {
		  System.out.println("Error setting native LAF: " + e);
		}
		Container content = getContentPane();
		
		//setJMenuBar(getOZvmMenuBar());
		JPanel panel = new JPanel();
		panel.add(Z88display.getInstance());
		
		content.add(panel, BorderLayout.NORTH);
		
		this.setTitle("OZvm V" + OZvm.VERSION);
		this.setResizable(false);
		this.pack();
		this.setVisible(true);
		this.setForeground(java.awt.Color.green);
		this.setBackground(java.awt.Color.black);

		this.addWindowListener(new java.awt.event.WindowAdapter() {
			public void windowClosing(java.awt.event.WindowEvent e) {
				System.out.println("OZvm application ended by user.");
				//Blink.getInstance().stopZ80Execution();
				System.exit(0);
			}
		});
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
			jJMenuBar.add(getHelpMenu());
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
	 * This method initializes main Help Menu dropdown
	 *
	 * @return javax.swing.JMenu
	 */
	private javax.swing.JMenu getHelpMenu() {
		if(jHelpMenu == null) {
			jHelpMenu = new javax.swing.JMenu();
			jHelpMenu.setText("Help");
			jHelpMenu.setMnemonic(java.awt.event.KeyEvent.VK_H);
		}
		return jHelpMenu;
	}
	
	/**
	 * This method initializes the debug command area (below the Z88 screen)
	 *
	 * @return javax.swing.JPanel
	 */
	private javax.swing.JPanel getCommandArea() {
		if(jCommandArea == null) {
			jCommandArea = new javax.swing.JPanel(new BorderLayout());
			jCommandArea.add(getRtmWindowContentPane(), BorderLayout.NORTH);
			jCommandArea.add(getCmdLineScrollPane(), BorderLayout.CENTER);
			jCommandArea.add(getCmdLineInputArea(), BorderLayout.SOUTH);
			jCommandArea.setVisible(true);
		}
		return jCommandArea;
	}

	/**
	 * This method initializes the OZvm Command Debugging Output Area
	 *
	 * @return javax.swing.JTextArea
	 */
	public javax.swing.JTextArea getCmdlineOutputArea() {
		if(jCmdOutput == null) {
			jCmdOutput = new javax.swing.JTextArea(20,80);
			jCmdOutput.setFont(new java.awt.Font("Monospaced",java.awt.Font.PLAIN, 11));
			jCmdOutput.setBackground(Color.BLACK);
			jCmdOutput.setForeground(Color.GREEN);
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
			jCmdlineInput.setPreferredSize(new Dimension(640,20));
			jCmdlineInput.setToolTipText("Type your debugging commands here");
			jCmdlineInput.setVisible(true);
		}
		return jCmdlineInput;
	}
	
	/**
	 * This method initializes jContentPane
	 *
	 * @return javax.swing.JPanel
	 */
	private javax.swing.JPanel getRtmWindowContentPane() {
		if(jRtmOutputWindowContentPane == null) {
			jRtmOutputWindowContentPane = new javax.swing.JPanel();
			jRtmOutputWindowContentPane.setLayout(new java.awt.BorderLayout());
			jRtmOutputWindowContentPane.add(getClearRtmMessagesButton(), java.awt.BorderLayout.NORTH);
			jRtmOutputWindowContentPane.add(getRtmOutputScrollPane(), java.awt.BorderLayout.CENTER);
		}
		return jRtmOutputWindowContentPane;
	}
	
	
	/**
	 * This method initializes jButton
	 *
	 * @return javax.swing.JButton
	 */
	private javax.swing.JButton getClearRtmMessagesButton() {
		if(jClearMessagesButton == null) {
			jClearMessagesButton = new javax.swing.JButton();
			jClearMessagesButton.setText("Clear runtime messages");
			jClearMessagesButton.addActionListener(new java.awt.event.ActionListener() {
				public void actionPerformed(java.awt.event.ActionEvent e) {
					getRtmOutputArea().setText("");
				}
			});
		}
		return jClearMessagesButton;
	}
	
	/**
	 * This method initializes jScrollPane1
	 *
	 * @return javax.swing.JScrollPane
	 */
	private javax.swing.JScrollPane getRtmOutputScrollPane() {
		if(jRtmOutputScrollPane == null) {
			jRtmOutputScrollPane = new javax.swing.JScrollPane();
			jRtmOutputScrollPane.setViewportView(getRtmOutputArea());
		}
		return jRtmOutputScrollPane;
	}
	/**
	 * This method initializes jTextArea
	 *
	 * @return javax.swing.JTextArea
	 */
	public javax.swing.JTextArea getRtmOutputArea() {
		if(jRtmOutputArea == null) {
			jRtmOutputArea = new javax.swing.JTextArea(6,80);
			jRtmOutputArea.setFont(new java.awt.Font("Monospaced",java.awt.Font.PLAIN, 11));
			jRtmOutputArea.setEditable(false);
		}
		return jRtmOutputArea;
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

	public static void displayRtmMessage(final String msg) {
		if (OZvm.debugMode == true) {
			Thread displayMsgThread = new Thread() {
				public void run() {					
					Gui.getInstance().getRtmOutputArea().append(msg + "\n");
					Gui.getInstance().getRtmOutputArea().setCaretPosition(Gui.getInstance().getRtmOutputArea().getDocument().getLength());
				}
			};

			displayMsgThread.setPriority(Thread.MIN_PRIORITY);
			displayMsgThread.start();
		} else {
			System.out.println(msg);
		}
	}
	
	public static void main(String[] args) {
		Gui gg = Gui.getInstance();

		OZvm ozvm = new OZvm();
		if (ozvm.boot(args) == false) {
			System.out.println("Ozvm terminated.");
			System.exit(0);
		}

		if (OZvm.debugMode == false) {
			// no debug mode, just boot the specified ROM and run the virtual Z88...
			ozvm.bootZ88Rom();
			Z88display.getInstance().grabFocus();	// make sure that keyboard focus is available for Z88 
		} else {
			gg.getRtmOutputArea().append("OZvm V" + OZvm.VERSION + ", Z88 Virtual Machine\n");
			gg.getContentPane().add(gg.getCommandArea(), BorderLayout.SOUTH);
			gg.pack();
			gg.getCmdLineInputArea().grabFocus();	// make sure that caret is blinking in command line area...
		}
	}
}
