/*
 * Created on Dec 12, 2003
 *
 * To change the template for this generated file go to
 * Window&gt;Preferences&gt;Java&gt;Code Generation&gt;Code and Comments
 */
package net.sourceforge.z88;

import gameframe.GameFrame;

import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Container;
import java.awt.Dimension;
import java.io.IOException;

import javax.swing.JFrame;
import javax.swing.JTextArea;
import javax.swing.UIManager;

/**
 * @author gbs
 *
 * To change the template for this generated type comment go to
 * Window&gt;Preferences&gt;Java&gt;Code Generation&gt;Code and Comments
 */
public class Gui extends JFrame {

	private javax.swing.JPanel z88Screen = null;  //  @jve:visual-info  decl-index=0 visual-constraint="344,19"
	private javax.swing.JMenuBar jJMenuBar = null;
	private javax.swing.JMenu jMenu = null;  //  @jve:visual-info  decl-index=0 visual-constraint="70,150"
	private javax.swing.JMenu jMenu1 = null;
	private javax.swing.JPanel jPanel1 = null;  //  @jve:visual-info  decl-index=0 visual-constraint="365,177"
	private javax.swing.JTextArea jTextArea = null;  //  @jve:visual-info  decl-index=0 visual-constraint="674,10"
	private javax.swing.JTextField jTextField = null;  //  @jve:visual-info  decl-index=0 visual-constraint="691,108"
	/**
	 * This is the default constructor
	 */
	public Gui() {
		super();
		initialize();
	}
	/**
	 * This method initializes this
	 * 
	 * @return void
	 */
	private void initialize() {
		try {
		  UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
		} catch(Exception e) {
		  System.out.println("Error setting native LAF: " + e);
		}
		Container content = getContentPane();
		
		this.setJMenuBar(getJJMenuBar());
		this.setSize(640, 480);
		content.add(getZ88Screen(), BorderLayout.NORTH);
		content.add(getDebuggingArea(), BorderLayout.SOUTH);
		this.setTitle("OZvm");
		this.pack();
		this.setVisible(true);
		this.setForeground(java.awt.Color.green);
		this.setBackground(java.awt.Color.black);
		
		this.addWindowListener(new java.awt.event.WindowAdapter() { 
			public void windowClosing(java.awt.event.WindowEvent e) {    
				System.out.println("windowClosing()"); 
				System.exit(0);				
			}
		});
	}
	/**
	 * This method initializes jContentPane
	 * 
	 * @return javax.swing.JPanel
	 */
	private javax.swing.JPanel getZ88Screen() {
		if (z88Screen == null) {
			z88Screen = new javax.swing.JPanel();
			z88Screen.setPreferredSize(new Dimension(640, 64));
			z88Screen.setLayout(new BorderLayout());
			z88Screen.setToolTipText("Use TAB key to get keyboard focus to this window.");
			z88Screen.setFocusable(true);
		}
		return z88Screen;
	}

	public static void main(String[] args) {
		System.out.println("OZvm V0.2, Z88 Virtual Machine");

		Gui gg = new Gui();
		gg.show();

		OZvm ozvm = new OZvm(gg.getZ88Screen());
		if (ozvm.boot(args) == false) {
			System.out.println("Ozvm terminated.");
			System.exit(0);
		}
		
		if (ozvm.isDebugMode() == true) {
			// Run OZvm in debugging mode, ie. start with command line mode and allow debugging
			try {
				ozvm.commandLine();

				System.out.println("Ozvm terminated.");
				GameFrame.exit(0);						
			} catch (IOException e) {
				e.printStackTrace();
			}
		} else {
			// no debug mode, just boot the specified ROM and run the virtual Z88...
			ozvm.bootZ88Rom();
		}		
	}
	/**
	 * This method initializes jJMenuBar
	 * 
	 * @return javax.swing.JMenuBar
	 */
	private javax.swing.JMenuBar getJJMenuBar() {
		if(jJMenuBar == null) {
			jJMenuBar = new javax.swing.JMenuBar();
			jJMenuBar.add(getFileMenu());			
			jJMenuBar.add(getHelpMenu());
		}
		return jJMenuBar;
	}
	/**
	 * This method initializes jMenu
	 * 
	 * @return javax.swing.JMenu
	 */
	private javax.swing.JMenu getFileMenu() {
		if(jMenu == null) {
			jMenu = new javax.swing.JMenu();
			jMenu.setSize(46, 24);
			jMenu.setText("File");
			jMenu.setMnemonic(java.awt.event.KeyEvent.VK_F);
		}
		return jMenu;
	}
	/**
	 * This method initializes jMenu1
	 * 
	 * @return javax.swing.JMenu
	 */
	private javax.swing.JMenu getHelpMenu() {
		if(jMenu1 == null) {
			jMenu1 = new javax.swing.JMenu();
			jMenu1.setText("Help");
			jMenu1.setMnemonic(java.awt.event.KeyEvent.VK_H);
		}
		return jMenu1;
	}
	/**
	 * This method initializes jPanel1
	 * 
	 * @return javax.swing.JPanel
	 */
	private javax.swing.JPanel getDebuggingArea() {
		if(jPanel1 == null) {
			jPanel1 = new javax.swing.JPanel(new BorderLayout());
			jPanel1.add(getJTextArea(), BorderLayout.NORTH);
			jPanel1.add(getJTextField(), BorderLayout.SOUTH);
			//jPanel1.setSize(192, 46);
			jPanel1.setVisible(true);
		}
		return jPanel1;
	}
	/**
	 * This method initializes jTextArea
	 * 
	 * @return javax.swing.JTextArea
	 */
	private javax.swing.JTextArea getJTextArea() {
		if(jTextArea == null) {
			jTextArea = new javax.swing.JTextArea();
			jTextArea.setPreferredSize(new Dimension(640,200));
			jTextArea.setBackground(Color.BLACK);
			jTextArea.setForeground(Color.GREEN);
			jTextArea.setEditable(false);
			jTextArea.setToolTipText("This area is used for Debugging output.");
			jTextArea.setVisible(true);
		}
		return jTextArea;
	}
	/**
	 * This method initializes jTextField
	 * 
	 * @return javax.swing.JTextField
	 */
	private javax.swing.JTextField getJTextField() {
		if(jTextField == null) {
			jTextField = new javax.swing.JTextField();
			jTextField.setPreferredSize(new Dimension(640,20));
			jTextField.setToolTipText("Type your debugging commands here");
			jTextField.setVisible(true);
		}
		return jTextField;
	}
}  //  @jve:visual-info  decl-index=0 visual-constraint="24,6"
