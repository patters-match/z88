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
import javax.swing.JScrollPane;
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
	private javax.swing.JTextArea cmdOutput = null;  //  @jve:visual-info  decl-index=0 visual-constraint="674,10"
	private javax.swing.JTextField jTextField = null;  //  @jve:visual-info  decl-index=0 visual-constraint="691,108"
	private javax.swing.JTextArea rtmMessages = null;  //  @jve:visual-info  decl-index=0 visual-constraint="798,183"
	private javax.swing.JFrame jFrame = null;  //  @jve:visual-info  decl-index=0 visual-constraint="705,105"
	private javax.swing.JPanel jContentPane = null;
	private javax.swing.JButton jButton = null;
	private javax.swing.JScrollPane jScrollPane = null;  //  @jve:visual-info  decl-index=0 visual-constraint="845,488"
	private javax.swing.JScrollPane jScrollPane1 = null;
	private javax.swing.JTextArea rtmOutputArea = null;
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
		content.add(z88Screen(), BorderLayout.NORTH);
		content.add(commandArea(), BorderLayout.SOUTH);
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
	private javax.swing.JPanel z88Screen() {
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

		Gui gg = new Gui();
		gg.show();
		JFrame rtmOut = gg.getRtmOutputWindow();
		gg.rtmOutArea().append("OZvm V0.2, Z88 Virtual Machine\n");

		OZvm ozvm = new OZvm(gg.z88Screen(), gg.cmdLineInputArea(), gg.cmdlineOutputArea(), gg.rtmOutArea());
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
	private javax.swing.JPanel commandArea() {
		if(jPanel1 == null) {
			jPanel1 = new javax.swing.JPanel(new BorderLayout());
			jPanel1.add(new JScrollPane(cmdlineOutputArea()), BorderLayout.CENTER);
			jPanel1.add(cmdLineInputArea(), BorderLayout.SOUTH);
			jPanel1.setVisible(true);
		}
		return jPanel1;
	}
	/**
	 * This method initializes the OZvm Command Debugging Output Area
	 * 
	 * @return javax.swing.JTextArea
	 */
	private javax.swing.JTextArea cmdlineOutputArea() {
		if(cmdOutput == null) {
			cmdOutput = new javax.swing.JTextArea();
			cmdOutput.setPreferredSize(new Dimension(0,400));
			cmdOutput.setBackground(Color.BLACK);
			cmdOutput.setForeground(Color.GREEN);
			cmdOutput.setEditable(false);
			cmdOutput.setToolTipText("This area is used for Debugging output.");
			cmdOutput.setVisible(true);
		}
		return cmdOutput;
	}
	
	/**
	 * This method initializes the 
	 * 
	 * @return javax.swing.JTextField
	 */
	private javax.swing.JTextField cmdLineInputArea() {
		if(jTextField == null) {
			jTextField = new javax.swing.JTextField();
			jTextField.setPreferredSize(new Dimension(640,20));
			jTextField.setToolTipText("Type your debugging commands here");
			jTextField.setVisible(true);
		}
		return jTextField;
	}
	/**
	 * This method initializes jContentPane
	 * 
	 * @return javax.swing.JPanel
	 */
	private javax.swing.JPanel getJContentPane() {
		if(jContentPane == null) {
			jContentPane = new javax.swing.JPanel();
			jContentPane.setLayout(new java.awt.BorderLayout());
			jContentPane.add(btnClearRtmMessages(), java.awt.BorderLayout.NORTH);
			jContentPane.add(getJScrollPane1(), java.awt.BorderLayout.CENTER);
		}
		return jContentPane;
	}
	/**
	 * This method initializes the Runtime Output Window
	 * 
	 * @return javax.swing.JFrame
	 */
	private javax.swing.JFrame getRtmOutputWindow() {
		if(jFrame == null) {
			jFrame = new javax.swing.JFrame();
			jFrame.setContentPane(getJContentPane());
			jFrame.setTitle("Runtime Messages");
			jFrame.setResizable(true);
			JFrame.setDefaultLookAndFeelDecorated(true);
			jFrame.setDefaultCloseOperation(DO_NOTHING_ON_CLOSE);
			jFrame.pack();
			jFrame.show();			
		}
		return jFrame;
	}
	/**
	 * This method initializes jButton
	 * 
	 * @return javax.swing.JButton
	 */
	private javax.swing.JButton btnClearRtmMessages() {
		if(jButton == null) {
			jButton = new javax.swing.JButton();
			jButton.setText("Clear output");
			jButton.addActionListener(new java.awt.event.ActionListener() { 
				public void actionPerformed(java.awt.event.ActionEvent e) {
					rtmOutArea().setText("");
				}
			});
		}
		return jButton;
	}
	/**
	 * This method initializes jScrollPane1
	 * 
	 * @return javax.swing.JScrollPane
	 */
	private javax.swing.JScrollPane getJScrollPane1() {
		if(jScrollPane1 == null) {
			jScrollPane1 = new javax.swing.JScrollPane();
			jScrollPane1.setViewportView(rtmOutArea());
		}
		return jScrollPane1;
	}

	/**
	 * This method initializes jTextArea
	 * 
	 * @return javax.swing.JTextArea
	 */
	private javax.swing.JTextArea rtmOutArea() {
		if(rtmOutputArea == null) {
			rtmOutputArea = new javax.swing.JTextArea(30,80);
			rtmOutputArea.setFont(new java.awt.Font("Courier",java.awt.Font.PLAIN, 11));
			rtmOutputArea.setEditable(false);
		}
		return rtmOutputArea;
	}
}
