/*
 * Created on Dec 12, 2003
 *
 * To change the template for this generated file go to
 * Window&gt;Preferences&gt;Java&gt;Code Generation&gt;Code and Comments
 */
package net.sourceforge.z88;

import gameframe.GameFrame;

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

	private java.awt.Canvas canvas = null;
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
		this.setSize(648, 96);
		this.setContentPane(getJContentPane());
		this.setTitle("OZvm");
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
			jContentPane.setLayout(new java.awt.BorderLayout());
			jContentPane.add(getCanvas(), java.awt.BorderLayout.CENTER);
		}
		return jContentPane;
	}
	/**
	 * This method initializes canvas
	 * 
	 * @return java.awt.Canvas
	 */
	private java.awt.Canvas getCanvas() {
		if(canvas == null) {
			canvas = new java.awt.Canvas();
			canvas.setSize(640,64);
			canvas.setVisible(true);
		}
		return canvas;
	}
	/**
	 * @param canvas
	 */
	public void setCanvas(java.awt.Canvas canvas) {
		this.canvas = canvas;
	}

	public static void main(String[] args) {
		System.out.println("OZvm V0.2, Z88 Virtual Machine");

		Gui gg = new Gui();
		gg.show();

		OZvm ozvm = new OZvm(gg.getCanvas());
		if (ozvm.loadRoms(args) == false) {
			System.out.println("Ozvm terminated.");
			System.exit(0);
		}
		
		try {
			ozvm.commandLine();
		} catch (IOException e) {
			e.printStackTrace();
		}
		
		System.out.println("Ozvm terminated.");
		GameFrame.exit(0);		
	}
}
