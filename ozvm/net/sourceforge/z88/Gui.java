/*
 * Created on Dec 12, 2003
 *
 * To change the template for this generated file go to
 * Window&gt;Preferences&gt;Java&gt;Code Generation&gt;Code and Comments
 */
package net.sourceforge.z88;

import gameframe.GameFrame;

import java.awt.Dimension;
import java.io.IOException;

import javax.swing.JFrame;

/**
 * @author gbs
 *
 * To change the template for this generated type comment go to
 * Window&gt;Preferences&gt;Java&gt;Code Generation&gt;Code and Comments
 */
public class Gui extends JFrame {

	private javax.swing.JPanel jContentPane = null;
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
		this.setContentPane(getJContentPane());
		this.setTitle("OZvm");
		this.pack();
		this.addWindowListener(new java.awt.event.WindowAdapter() { 
			public void windowClosing(java.awt.event.WindowEvent e) {    
				System.out.println("windowClosing()"); // TODO Auto-generated Event stub windowClosing()
				System.exit(0);				
			}
		});
	}
	/**
	 * This method initializes jContentPane
	 * 
	 * @return javax.swing.JPanel
	 */
	private javax.swing.JPanel getJContentPane() {
		if (jContentPane == null) {
			jContentPane = new javax.swing.JPanel();
			jContentPane.setPreferredSize(new Dimension(640, 64));
		}
		return jContentPane;
	}

	public static void main(String[] args) {
		System.out.println("OZvm V0.2, Z88 Virtual Machine");

		Gui gg = new Gui();
		gg.show();

		OZvm ozvm = new OZvm(gg.getJContentPane());
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
}
