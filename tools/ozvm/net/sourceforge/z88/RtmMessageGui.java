/*
 * RtmMessageGui.java
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
import java.awt.Font;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.sql.Timestamp;

import javax.swing.ImageIcon;
import javax.swing.JFrame;
import javax.swing.JMenuItem;
import javax.swing.JScrollPane;

import com.imagero.util.ThreadManager;


/**
 * Gui Runtime message window.
 */
public class RtmMessageGui extends JFrame {
	
	private ThreadManager rtmMsgHelper;
	private Timestamp rtmMsgTime;
	
	private javax.swing.JMenuBar jJMenuBar;
	private javax.swing.JMenu jFileMenu;  
	private JMenuItem clearRtmWindowMenuItem;	
	
	private javax.swing.JTextArea jRtmOutputArea;  
	private javax.swing.JScrollPane jRtmOutputScrollPane;
	
	/**
	 * This is the default constructor
	 */
	public RtmMessageGui() {
		super();
		initialize();
	}

	/**
	 * This method initializes the runtime window and menus
	 */
	private void initialize() {
		setJMenuBar(getRtmMenuBar());

		getContentPane().add(getRtmOutputScrollPane());
		
		this.setTitle("Runtime messages");
		this.setResizable(true);
		this.pack();
		this.setVisible(false);
		
		rtmMsgHelper = new ThreadManager(1);
		rtmMsgTime = new Timestamp(0);
	}
	
	/**
	 * This method initializes the Menu bar
	 *
	 * @return javax.swing.JMenuBar
	 */
	public javax.swing.JMenuBar getRtmMenuBar() {
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
			jFileMenu.add(getClearRtmWindowMenuItem());
		}
		return jFileMenu;
	}
	
	public JMenuItem getClearRtmWindowMenuItem() {
		if (clearRtmWindowMenuItem == null) {
			clearRtmWindowMenuItem = new JMenuItem();
			clearRtmWindowMenuItem.setSelected(false);
			clearRtmWindowMenuItem.setText("Clear Runtime Messages");
			clearRtmWindowMenuItem.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					getRtmOutputArea().setText("");
				}
			});
		}

		return clearRtmWindowMenuItem;		
	}
	
	
	public void displayRtmMessage(final String msg) {
		rtmMsgHelper.addTask( new Runnable() {
			public void run() {
				rtmMsgTime.setTime(System.currentTimeMillis());
				String dtstmp = rtmMsgTime.toString();
				if (dtstmp.length() < 23) dtstmp += "0"; 
				getRtmOutputArea().append("\n" + dtstmp + ": " + msg);
				getRtmOutputArea().setCaretPosition(getRtmOutputArea().getDocument().getLength());
			}
		});							
	}
	
	/**
	 * This method initializes jScrollPane1
	 *
	 * @return javax.swing.JScrollPane
	 */
	private javax.swing.JScrollPane getRtmOutputScrollPane() {
		if(jRtmOutputScrollPane == null) {
			jRtmOutputScrollPane = new JScrollPane();
			jRtmOutputScrollPane.setViewportView(getRtmOutputArea());
		}
		return jRtmOutputScrollPane;
	}

	/**
	 * This method initializes jTextArea
	 *
	 * @return javax.swing.JTextArea
	 */
	private javax.swing.JTextArea getRtmOutputArea() {
		if(jRtmOutputArea == null) {
			jRtmOutputArea = new javax.swing.JTextArea(20,110);
			jRtmOutputArea.setTabSize(1);
			jRtmOutputArea.setFont(new Font("Monospaced",Font.PLAIN, 11));
			jRtmOutputArea.setEditable(false);
		}
		return jRtmOutputArea;
	}
}
