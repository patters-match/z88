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

import javax.swing.JFrame;
import java.awt.GridBagLayout;
import javax.swing.JPanel;
import java.awt.GridBagConstraints;
import javax.swing.JLabel;
import java.awt.Dimension;
import javax.swing.border.BevelBorder;
import javax.swing.JMenuBar;
import javax.swing.JMenu;
import javax.swing.JMenuItem;
import javax.swing.JToolBar;
import javax.swing.JButton;
import javax.swing.JTextArea;
import javax.swing.border.EmptyBorder;
import java.awt.event.KeyEvent;
import javax.swing.JCheckBoxMenuItem;
import java.awt.FlowLayout;
import javax.swing.SwingConstants;
import java.awt.Component;
import java.awt.Insets;
import java.awt.Color;
import javax.swing.JToggleButton;
import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;

/**
 * The end user Gui (Main menu, screen, runtime messages, keyboard & slot management)
 */
public class Gui extends JFrame {

	private static final class singletonContainer {
		static final Gui singleton = new Gui();  
	}
	
	public static Gui getInstance() {
		return singletonContainer.singleton;
	}
	
	private javax.swing.JScrollPane jRtmOutputScrollPane = null;
	private javax.swing.JTextArea jRtmOutputArea = null;
	
	private JButton button_2;
	private JButton button_1;
	private JToolBar toolBar;
	private JLabel z88Display;
	private JPanel panel_2;
	private JButton button_17_2;
	private JButton button_17_1_1;
	private JButton button_17_1;
	private JButton button_14_1_1;
	private JButton button_3_1_1_2;
	private JButton button_8_1_1;
	private JButton button_8_1;
	private JButton button_15_2_1;
	private JButton button_15_2;
	private JButton button_17;
	private JToggleButton button_3_1_1_1;
	private JButton button_14_1;
	private JButton button_13_1;
	private JButton button_12_1;
	private JButton button_11_1;
	private JButton button_10_1;
	private JButton button_9_1;
	private JButton button_7_1;
	private JButton button_6_1;
	private JButton button_4_2;
	private JButton button_4_1_2;
	private JToggleButton button_3_1_1;
	private JButton button_4_1_1_1_1_1_1_1_1_1_1_1;
	private JButton button_4_1_1_1_1_1_1_1_1_1_1;
	private JButton button_4_1_1_1_1_1_1_1_1_1;
	private JButton button_4_1_1_1_1_1_1_1_1;
	private JButton button_4_1_1_1_1_1_1_1;
	private JButton button_4_1_1_1_1_1_1;
	private JButton button_4_1_1_1_1_1;
	private JButton button_4_1_1_1_1;
	private JButton button_4_1_1_1;
	private JButton button_4_1_1;
	private JButton button_4_1;
	private JButton button_3_1;
	private JButton button_15_1;
	private JButton button;
	private JButton button_15;
	private JButton button_14;
	private JButton button_13;
	private JButton button_12;
	private JButton button_11;
	private JButton button_10;
	private JButton button_9;
	private JButton button_8;
	private JButton button_7;
	private JButton button_6;
	private JButton button_5;
	private JButton button_4;
	private JButton button_3;
	private JPanel panel_1;
	private JTextArea textArea;
	
	private Gui() {
		super();
		getContentPane().setLayout(new GridBagLayout());

		final JMenuBar menuBar = new JMenuBar();
		menuBar.setBorder(new EmptyBorder(0, 0, 0, 0));
		setJMenuBar(menuBar);

		final JMenu menu = new JMenu();
		menu.setMnemonic(KeyEvent.VK_F);
		menuBar.add(menu);
		menu.setText("File");

		final JMenuItem menuItem = new JMenuItem();
		menu.add(menuItem);
		menuItem.setText("Exit");

		final JMenu menu_1 = new JMenu();
		menuBar.add(menu_1);
		menu_1.setText("Run");

		final JCheckBoxMenuItem checkBoxMenuItem = new JCheckBoxMenuItem();
		menu_1.add(checkBoxMenuItem);
		checkBoxMenuItem.setText("Debug");

		final GridBagConstraints gridBagConstraints_2 = new GridBagConstraints();
		gridBagConstraints_2.ipady = 65;
		gridBagConstraints_2.fill = GridBagConstraints.BOTH;
		gridBagConstraints_2.ipadx = 275;
		gridBagConstraints_2.gridy = 3;
		gridBagConstraints_2.gridx = 0;
		getContentPane().add(getRtmOutputScrollPane(), gridBagConstraints_2);

		final JPanel panel_1 = new JPanel();
		panel_1.setBackground(Color.BLACK);
		final FlowLayout flowLayout = new FlowLayout();
		flowLayout.setHgap(11);
		panel_1.setLayout(flowLayout);
		final GridBagConstraints gridBagConstraints_3 = new GridBagConstraints();
		gridBagConstraints_3.fill = GridBagConstraints.HORIZONTAL;
		gridBagConstraints_3.ipadx = -2;
		gridBagConstraints_3.gridy = 5;
		gridBagConstraints_3.gridx = 0;
		getContentPane().add(panel_1, gridBagConstraints_3);

		final JButton button_3 = new JButton();
		button_3.setForeground(Color.WHITE);
		button_3.setBackground(Color.BLACK);
		button_3.setPreferredSize(new Dimension(32, 32));
		button_3.setMargin(new Insets(2, 1, 2, 1));
		button_3.setAlignmentX(Component.CENTER_ALIGNMENT);
		button_3.setHorizontalAlignment(SwingConstants.LEFT);
		panel_1.add(button_3);
		button_3.setText("ESC");

		final JButton button_4 = new JButton();
		button_4.setForeground(Color.WHITE);
		button_4.setBackground(Color.BLACK);
		button_4.setPreferredSize(new Dimension(32, 32));
		button_4.setMargin(new Insets(2, 2, 2, 2));
		panel_1.add(button_4);
		button_4.setText("1");

		final JButton button_5 = new JButton();
		button_5.setForeground(Color.WHITE);
		button_5.setBackground(Color.BLACK);
		button_5.setPreferredSize(new Dimension(32, 32));
		button_5.setMargin(new Insets(2, 2, 2, 2));
		panel_1.add(button_5);
		button_5.setText("2");

		final JButton button_6 = new JButton();
		button_6.setForeground(Color.WHITE);
		button_6.setBackground(Color.BLACK);
		button_6.setPreferredSize(new Dimension(32, 32));
		button_6.setMargin(new Insets(2, 2, 2, 2));
		panel_1.add(button_6);
		button_6.setText("3");

		final JButton button_7 = new JButton();
		button_7.setForeground(Color.WHITE);
		button_7.setBackground(Color.BLACK);
		button_7.setPreferredSize(new Dimension(32, 32));
		button_7.setMargin(new Insets(2, 2, 2, 2));
		panel_1.add(button_7);
		button_7.setText("4");

		final JButton button_8 = new JButton();
		button_8.setForeground(Color.WHITE);
		button_8.setBackground(Color.BLACK);
		button_8.setPreferredSize(new Dimension(32, 32));
		button_8.setMargin(new Insets(2, 2, 2, 2));
		panel_1.add(button_8);
		button_8.setText("5");

		final JButton button_9 = new JButton();
		button_9.setForeground(Color.WHITE);
		button_9.setBackground(Color.BLACK);
		button_9.setPreferredSize(new Dimension(32, 32));
		button_9.setMargin(new Insets(2, 2, 2, 2));
		panel_1.add(button_9);
		button_9.setText("6");

		final JButton button_10 = new JButton();
		button_10.setForeground(Color.WHITE);
		button_10.setBackground(Color.BLACK);
		button_10.setPreferredSize(new Dimension(32, 32));
		button_10.setMargin(new Insets(2, 2, 2, 2));
		panel_1.add(button_10);
		button_10.setText("7");

		final JButton button_11 = new JButton();
		button_11.setForeground(Color.WHITE);
		button_11.setBackground(Color.BLACK);
		button_11.setPreferredSize(new Dimension(32, 32));
		button_11.setMargin(new Insets(2, 2, 2, 2));
		panel_1.add(button_11);
		button_11.setText("8");

		final JButton button_12 = new JButton();
		button_12.setForeground(Color.WHITE);
		button_12.setBackground(Color.BLACK);
		button_12.setPreferredSize(new Dimension(32, 32));
		button_12.setMargin(new Insets(2, 2, 2, 2));
		panel_1.add(button_12);
		button_12.setText("9");

		final JButton button_13 = new JButton();
		button_13.setForeground(Color.WHITE);
		button_13.setBackground(Color.BLACK);
		button_13.setPreferredSize(new Dimension(32, 32));
		button_13.setMargin(new Insets(2, 2, 2, 2));
		panel_1.add(button_13);
		button_13.setText("0");

		final JButton button_14 = new JButton();
		button_14.setForeground(Color.WHITE);
		button_14.setBackground(Color.BLACK);
		button_14.setPreferredSize(new Dimension(32, 32));
		button_14.setMinimumSize(new Dimension(0, 0));
		button_14.setMargin(new Insets(2, 2, 2, 2));
		panel_1.add(button_14);
		button_14.setText("-");

		final JButton button_15 = new JButton();
		button_15.setForeground(Color.WHITE);
		button_15.setBackground(Color.BLACK);
		button_15.setPreferredSize(new Dimension(32, 32));
		button_15.setMargin(new Insets(2, 2, 2, 2));
		panel_1.add(button_15);
		button_15.setText("=");

		final JButton button_16 = new JButton();
		button_16.setForeground(Color.WHITE);
		button_16.setBackground(Color.BLACK);
		button_16.setPreferredSize(new Dimension(32, 32));
		button_16.setMargin(new Insets(2, 2, 2, 2));
		panel_1.add(button_16);
		button_16.setText("\\");

		final JButton button_17 = new JButton();
		button_17.setForeground(Color.WHITE);
		button_17.setBackground(Color.BLACK);
		button_17.setPreferredSize(new Dimension(32, 32));
		button_17.setMargin(new Insets(2, 1, 2, 1));
		panel_1.add(button_17);
		button_17.setText("DEL");
		final GridBagConstraints gridBagConstraints_4 = new GridBagConstraints();
		gridBagConstraints_4.fill = GridBagConstraints.HORIZONTAL;
		gridBagConstraints_4.ipadx = -5;
		gridBagConstraints_4.anchor = GridBagConstraints.WEST;
		gridBagConstraints_4.ipady = 166;
		gridBagConstraints_4.gridy = 6;
		gridBagConstraints_4.gridx = 0;
		getContentPane().add(getPanel_1(), gridBagConstraints_4);
		final GridBagConstraints gridBagConstraints = new GridBagConstraints();
		gridBagConstraints.ipady = 5;
		gridBagConstraints.insets = new Insets(0, 0, 0, 0);
		gridBagConstraints.fill = GridBagConstraints.BOTH;
		gridBagConstraints.gridx = 0;
		gridBagConstraints.gridy = 1;
		getContentPane().add(getPanel_2(), gridBagConstraints);
		final GridBagConstraints gridBagConstraints_1 = new GridBagConstraints();
		gridBagConstraints_1.fill = GridBagConstraints.HORIZONTAL;
		gridBagConstraints_1.gridx = 0;
		gridBagConstraints_1.gridy = 0;
		getContentPane().add(getToolBar(), gridBagConstraints_1);
		
		initialize();
	}
	
	protected JPanel getPanel_1()
	{
		if (panel_1 == null) {
			panel_1 = new JPanel();
			panel_1.setBackground(Color.BLACK);
			panel_1.setLayout(null);
			panel_1.add(getButton_3());
			panel_1.add(getButton_4());
			panel_1.add(getButton_5());
			panel_1.add(getButton_6());
			panel_1.add(getButton_7());
			panel_1.add(getButton_8());
			panel_1.add(getButton_9());
			panel_1.add(getButton_10());
			panel_1.add(getButton_11());
			panel_1.add(getButton_12());
			panel_1.add(getButton_13());
			panel_1.add(getButton_14());
			panel_1.add(getButton_15());
			panel_1.add(getButton());
			panel_1.add(getButton_15_1());
			panel_1.add(getButton_3_1());
			panel_1.add(getButton_4_1());
			panel_1.add(getButton_4_1_1());
			panel_1.add(getButton_4_1_1_1());
			panel_1.add(getButton_4_1_1_1_1());
			panel_1.add(getButton_4_1_1_1_1_1());
			panel_1.add(getButton_4_1_1_1_1_1_1());
			panel_1.add(getButton_4_1_1_1_1_1_1_1());
			panel_1.add(getButton_4_1_1_1_1_1_1_1_1());
			panel_1.add(getButton_4_1_1_1_1_1_1_1_1_1());
			panel_1.add(getButton_4_1_1_1_1_1_1_1_1_1_1());
			panel_1.add(getButton_4_1_1_1_1_1_1_1_1_1_1_1());
			panel_1.add(getButton_3_1_1());
			panel_1.add(getButton_4_1_2());
			panel_1.add(getButton_4_2());
			panel_1.add(getButton_6_1());
			panel_1.add(getButton_7_1());
			panel_1.add(getButton_9_1());
			panel_1.add(getButton_10_1());
			panel_1.add(getButton_11_1());
			panel_1.add(getButton_12_1());
			panel_1.add(getButton_13_1());
			panel_1.add(getButton_14_1());
			panel_1.add(getButton_3_1_1_1());
			panel_1.add(getButton_17());
			panel_1.add(getButton_15_2());
			panel_1.add(getButton_15_2_1());
			panel_1.add(getButton_8_1());
			panel_1.add(getButton_8_1_1());
			panel_1.add(getButton_3_1_1_2());
			panel_1.add(getButton_14_1_1());
			panel_1.add(getButton_17_1());
			panel_1.add(getButton_17_1_1());
			panel_1.add(getButton_17_2());
		}
		return panel_1;
	}
	
	protected JButton getButton_3()
	{
		if (button_3 == null) {
			button_3 = new JButton();
			button_3.setForeground(Color.WHITE);
			button_3.setBackground(Color.BLACK);
			button_3.setBounds(10, 5, 56, 32);
			button_3.setPreferredSize(new Dimension(56, 32));
			button_3.setMargin(new Insets(2, 13, 2, 12));
			button_3.setHorizontalAlignment(SwingConstants.LEFT);
			button_3.setAlignmentX(Component.CENTER_ALIGNMENT);
			button_3.setText("TAB");
		}
		return button_3;
	}
	
	protected JButton getButton_4()
	{
		if (button_4 == null) {
			button_4 = new JButton();
			button_4.setForeground(Color.WHITE);
			button_4.setBackground(Color.BLACK);
			button_4.setBounds(76, 5, 32, 32);
			button_4.setPreferredSize(new Dimension(32, 32));
			button_4.setMargin(new Insets(2, 2, 2, 2));
			button_4.setText("Q");
		}
		return button_4;
	}
	
	protected JButton getButton_5()
	{
		if (button_5 == null) {
			button_5 = new JButton();
			button_5.setForeground(Color.WHITE);
			button_5.setBackground(Color.BLACK);
			button_5.setBounds(118, 5, 32, 32);
			button_5.setPreferredSize(new Dimension(32, 32));
			button_5.setMargin(new Insets(2, 2, 2, 2));
			button_5.setText("W");
		}
		return button_5;
	}
	
	protected JButton getButton_6()
	{
		if (button_6 == null) {
			button_6 = new JButton();
			button_6.setForeground(Color.WHITE);
			button_6.setBackground(Color.BLACK);
			button_6.setBounds(160, 5, 32, 32);
			button_6.setPreferredSize(new Dimension(32, 32));
			button_6.setMargin(new Insets(2, 2, 2, 2));
			button_6.setText("E");
		}
		return button_6;
	}
	
	protected JButton getButton_7()
	{
		if (button_7 == null) {
			button_7 = new JButton();
			button_7.setForeground(Color.WHITE);
			button_7.setBackground(Color.BLACK);
			button_7.setBounds(202, 5, 32, 32);
			button_7.setPreferredSize(new Dimension(32, 32));
			button_7.setMargin(new Insets(2, 2, 2, 2));
			button_7.setText("R");
		}
		return button_7;
	}
	
	protected JButton getButton_8()
	{
		if (button_8 == null) {
			button_8 = new JButton();
			button_8.setForeground(Color.WHITE);
			button_8.setBackground(Color.BLACK);
			button_8.setBounds(244, 5, 32, 32);
			button_8.setPreferredSize(new Dimension(32, 32));
			button_8.setMargin(new Insets(2, 2, 2, 2));
			button_8.setText("T");
		}
		return button_8;
	}
	
	protected JButton getButton_9()
	{
		if (button_9 == null) {
			button_9 = new JButton();
			button_9.setForeground(Color.WHITE);
			button_9.setBackground(Color.BLACK);
			button_9.setBounds(286, 5, 32, 32);
			button_9.setPreferredSize(new Dimension(32, 32));
			button_9.setMargin(new Insets(2, 2, 2, 2));
			button_9.setText("Y");
		}
		return button_9;
	}
	
	protected JButton getButton_10()
	{
		if (button_10 == null) {
			button_10 = new JButton();
			button_10.setForeground(Color.WHITE);
			button_10.setBackground(Color.BLACK);
			button_10.setBounds(328, 5, 32, 32);
			button_10.setPreferredSize(new Dimension(32, 32));
			button_10.setMargin(new Insets(2, 2, 2, 2));
			button_10.setText("U");
		}
		return button_10;
	}
	
	protected JButton getButton_11()
	{
		if (button_11 == null) {
			button_11 = new JButton();
			button_11.setForeground(Color.WHITE);
			button_11.setBackground(Color.BLACK);
			button_11.setBounds(370, 5, 32, 32);
			button_11.setPreferredSize(new Dimension(32, 32));
			button_11.setMargin(new Insets(2, 2, 2, 2));
			button_11.setText("I");
		}
		return button_11;
	}
	
	protected JButton getButton_12()
	{
		if (button_12 == null) {
			button_12 = new JButton();
			button_12.setForeground(Color.WHITE);
			button_12.setBackground(Color.BLACK);
			button_12.setBounds(412, 5, 32, 32);
			button_12.setPreferredSize(new Dimension(32, 32));
			button_12.setMargin(new Insets(2, 2, 2, 2));
			button_12.setText("O");
		}
		return button_12;
	}
	protected JButton getButton_13()
	{
		if (button_13 == null) {
			button_13 = new JButton();
			button_13.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
				}
			});
			button_13.setForeground(Color.WHITE);
			button_13.setBackground(Color.BLACK);
			button_13.setBounds(454, 5, 32, 32);
			button_13.setPreferredSize(new Dimension(32, 32));
			button_13.setMargin(new Insets(2, 2, 2, 2));
			button_13.setText("P");
		}
		return button_13;
	}
	protected JButton getButton_14()
	{
		if (button_14 == null) {
			button_14 = new JButton();
			button_14.setForeground(Color.WHITE);
			button_14.setBackground(Color.BLACK);
			button_14.setBounds(496, 5, 32, 32);
			button_14.setPreferredSize(new Dimension(32, 32));
			button_14.setMargin(new Insets(2, 2, 2, 2));
			button_14.setText("?");
		}
		return button_14;
	}
	protected JButton getButton_15()
	{
		if (button_15 == null) {
			button_15 = new JButton();
			button_15.setForeground(Color.WHITE);
			button_15.setBackground(Color.BLACK);
			button_15.setBounds(538, 5, 32, 32);
			button_15.setPreferredSize(new Dimension(32, 32));
			button_15.setMargin(new Insets(2, 2, 2, 2));
			button_15.setText("?");
		}
		return button_15;
	}
	protected JButton getButton()
	{
		if (button == null) {
			button = new JButton();
			button.setForeground(Color.WHITE);
			button.setBackground(Color.BLACK);
			button.setBounds(587, 5, 57, 74);
			button.setText("CR");
		}
		return button;
	}
	protected JButton getButton_15_1()
	{
		if (button_15_1 == null) {
			button_15_1 = new JButton();
			button_15_1.setForeground(Color.WHITE);
			button_15_1.setBackground(Color.BLACK);
			button_15_1.setBounds(544, 47, 32, 32);
			button_15_1.setMargin(new Insets(2, 2, 2, 2));
			button_15_1.setText("?");
		}
		return button_15_1;
	}
	protected JButton getButton_3_1()
	{
		if (button_3_1 == null) {
			button_3_1 = new JButton();
			button_3_1.setForeground(Color.WHITE);
			button_3_1.setBackground(Color.BLACK);
			button_3_1.setBounds(10, 47, 63, 32);
			button_3_1.setMargin(new Insets(2, 22, 2, 10));
			button_3_1.setHorizontalAlignment(SwingConstants.LEFT);
			button_3_1.setAlignmentX(Component.CENTER_ALIGNMENT);
			button_3_1.setText("<>");
		}
		return button_3_1;
	}
	protected JButton getButton_4_1()
	{
		if (button_4_1 == null) {
			button_4_1 = new JButton();
			button_4_1.setForeground(Color.WHITE);
			button_4_1.setBackground(Color.BLACK);
			button_4_1.setBounds(82, 47, 32, 32);
			button_4_1.setMargin(new Insets(2, 2, 2, 2));
			button_4_1.setText("A");
		}
		return button_4_1;
	}
	protected JButton getButton_4_1_1()
	{
		if (button_4_1_1 == null) {
			button_4_1_1 = new JButton();
			button_4_1_1.setForeground(Color.WHITE);
			button_4_1_1.setBackground(Color.BLACK);
			button_4_1_1.setBounds(124, 47, 32, 32);
			button_4_1_1.setMargin(new Insets(2, 2, 2, 2));
			button_4_1_1.setText("S");
		}
		return button_4_1_1;
	}
	protected JButton getButton_4_1_1_1()
	{
		if (button_4_1_1_1 == null) {
			button_4_1_1_1 = new JButton();
			button_4_1_1_1.setForeground(Color.WHITE);
			button_4_1_1_1.setBackground(Color.BLACK);
			button_4_1_1_1.setBounds(165, 47, 32, 32);
			button_4_1_1_1.setMargin(new Insets(2, 2, 2, 2));
			button_4_1_1_1.setText("D");
		}
		return button_4_1_1_1;
	}
	protected JButton getButton_4_1_1_1_1()
	{
		if (button_4_1_1_1_1 == null) {
			button_4_1_1_1_1 = new JButton();
			button_4_1_1_1_1.setForeground(Color.WHITE);
			button_4_1_1_1_1.setBackground(Color.BLACK);
			button_4_1_1_1_1.setBounds(207, 47, 32, 32);
			button_4_1_1_1_1.setMargin(new Insets(2, 2, 2, 2));
			button_4_1_1_1_1.setText("F");
		}
		return button_4_1_1_1_1;
	}
	protected JButton getButton_4_1_1_1_1_1()
	{
		if (button_4_1_1_1_1_1 == null) {
			button_4_1_1_1_1_1 = new JButton();
			button_4_1_1_1_1_1.setForeground(Color.WHITE);
			button_4_1_1_1_1_1.setBackground(Color.BLACK);
			button_4_1_1_1_1_1.setBounds(249, 47, 32, 32);
			button_4_1_1_1_1_1.setMargin(new Insets(2, 2, 2, 2));
			button_4_1_1_1_1_1.setText("G");
		}
		return button_4_1_1_1_1_1;
	}
	protected JButton getButton_4_1_1_1_1_1_1()
	{
		if (button_4_1_1_1_1_1_1 == null) {
			button_4_1_1_1_1_1_1 = new JButton();
			button_4_1_1_1_1_1_1.setForeground(Color.WHITE);
			button_4_1_1_1_1_1_1.setBackground(Color.BLACK);
			button_4_1_1_1_1_1_1.setBounds(291, 47, 32, 32);
			button_4_1_1_1_1_1_1.setMargin(new Insets(2, 2, 2, 2));
			button_4_1_1_1_1_1_1.setText("H");
		}
		return button_4_1_1_1_1_1_1;
	}
	protected JButton getButton_4_1_1_1_1_1_1_1()
	{
		if (button_4_1_1_1_1_1_1_1 == null) {
			button_4_1_1_1_1_1_1_1 = new JButton();
			button_4_1_1_1_1_1_1_1.setForeground(Color.WHITE);
			button_4_1_1_1_1_1_1_1.setBackground(Color.BLACK);
			button_4_1_1_1_1_1_1_1.setBounds(333, 47, 32, 32);
			button_4_1_1_1_1_1_1_1.setMargin(new Insets(2, 2, 2, 2));
			button_4_1_1_1_1_1_1_1.setText("J");
		}
		return button_4_1_1_1_1_1_1_1;
	}
	protected JButton getButton_4_1_1_1_1_1_1_1_1()
	{
		if (button_4_1_1_1_1_1_1_1_1 == null) {
			button_4_1_1_1_1_1_1_1_1 = new JButton();
			button_4_1_1_1_1_1_1_1_1.setForeground(Color.WHITE);
			button_4_1_1_1_1_1_1_1_1.setBackground(Color.BLACK);
			button_4_1_1_1_1_1_1_1_1.setBounds(375, 47, 32, 32);
			button_4_1_1_1_1_1_1_1_1.setMargin(new Insets(2, 2, 2, 2));
			button_4_1_1_1_1_1_1_1_1.setText("K");
		}
		return button_4_1_1_1_1_1_1_1_1;
	}
	protected JButton getButton_4_1_1_1_1_1_1_1_1_1()
	{
		if (button_4_1_1_1_1_1_1_1_1_1 == null) {
			button_4_1_1_1_1_1_1_1_1_1 = new JButton();
			button_4_1_1_1_1_1_1_1_1_1.setForeground(Color.WHITE);
			button_4_1_1_1_1_1_1_1_1_1.setBackground(Color.BLACK);
			button_4_1_1_1_1_1_1_1_1_1.setBounds(417, 47, 32, 32);
			button_4_1_1_1_1_1_1_1_1_1.setMargin(new Insets(2, 2, 2, 2));
			button_4_1_1_1_1_1_1_1_1_1.setText("L");
		}
		return button_4_1_1_1_1_1_1_1_1_1;
	}
	protected JButton getButton_4_1_1_1_1_1_1_1_1_1_1()
	{
		if (button_4_1_1_1_1_1_1_1_1_1_1 == null) {
			button_4_1_1_1_1_1_1_1_1_1_1 = new JButton();
			button_4_1_1_1_1_1_1_1_1_1_1.setForeground(Color.WHITE);
			button_4_1_1_1_1_1_1_1_1_1_1.setBackground(Color.BLACK);
			button_4_1_1_1_1_1_1_1_1_1_1.setBounds(459, 47, 32, 32);
			button_4_1_1_1_1_1_1_1_1_1_1.setMargin(new Insets(2, 2, 2, 2));
			button_4_1_1_1_1_1_1_1_1_1_1.setText("?");
		}
		return button_4_1_1_1_1_1_1_1_1_1_1;
	}
	protected JButton getButton_4_1_1_1_1_1_1_1_1_1_1_1()
	{
		if (button_4_1_1_1_1_1_1_1_1_1_1_1 == null) {
			button_4_1_1_1_1_1_1_1_1_1_1_1 = new JButton();
			button_4_1_1_1_1_1_1_1_1_1_1_1.setForeground(Color.WHITE);
			button_4_1_1_1_1_1_1_1_1_1_1_1.setBackground(Color.BLACK);
			button_4_1_1_1_1_1_1_1_1_1_1_1.setBounds(501, 47, 32, 32);
			button_4_1_1_1_1_1_1_1_1_1_1_1.setMargin(new Insets(2, 2, 2, 2));
			button_4_1_1_1_1_1_1_1_1_1_1_1.setText("?");
		}
		return button_4_1_1_1_1_1_1_1_1_1_1_1;
	}
	protected JToggleButton getButton_3_1_1()
	{
		if (button_3_1_1 == null) {
			button_3_1_1 = new JToggleButton();
			button_3_1_1.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
				}
			});
			button_3_1_1.setForeground(Color.WHITE);
			button_3_1_1.setBackground(Color.BLACK);
			button_3_1_1.setBounds(10, 89, 82, 32);
			button_3_1_1.setMargin(new Insets(2, 22, 2, 10));
			button_3_1_1.setHorizontalAlignment(SwingConstants.LEFT);
			button_3_1_1.setAlignmentX(Component.CENTER_ALIGNMENT);
			button_3_1_1.setText("SHIFT");
		}
		return button_3_1_1;
	}
	protected JButton getButton_4_1_2()
	{
		if (button_4_1_2 == null) {
			button_4_1_2 = new JButton();
			button_4_1_2.setForeground(Color.WHITE);
			button_4_1_2.setBackground(Color.BLACK);
			button_4_1_2.setBounds(101, 89, 32, 32);
			button_4_1_2.setMargin(new Insets(2, 2, 2, 2));
			button_4_1_2.setText("Z");
		}
		return button_4_1_2;
	}
	protected JButton getButton_4_2()
	{
		if (button_4_2 == null) {
			button_4_2 = new JButton();
			button_4_2.setForeground(Color.WHITE);
			button_4_2.setBackground(Color.BLACK);
			button_4_2.setBounds(142, 89, 32, 32);
			button_4_2.setMargin(new Insets(2, 2, 2, 2));
			button_4_2.setText("X");
		}
		return button_4_2;
	}
	protected JButton getButton_6_1()
	{
		if (button_6_1 == null) {
			button_6_1 = new JButton();
			button_6_1.setForeground(Color.WHITE);
			button_6_1.setBackground(Color.BLACK);
			button_6_1.setBounds(183, 89, 32, 32);
			button_6_1.setMargin(new Insets(2, 2, 2, 2));
			button_6_1.setText("C");
		}
		return button_6_1;
	}
	protected JButton getButton_7_1()
	{
		if (button_7_1 == null) {
			button_7_1 = new JButton();
			button_7_1.setForeground(Color.WHITE);
			button_7_1.setBackground(Color.BLACK);
			button_7_1.setBounds(225, 89, 32, 32);
			button_7_1.setMargin(new Insets(2, 2, 2, 2));
			button_7_1.setText("V");
		}
		return button_7_1;
	}
	protected JButton getButton_9_1()
	{
		if (button_9_1 == null) {
			button_9_1 = new JButton();
			button_9_1.setForeground(Color.WHITE);
			button_9_1.setBackground(Color.BLACK);
			button_9_1.setBounds(266, 89, 32, 32);
			button_9_1.setMargin(new Insets(2, 2, 2, 2));
			button_9_1.setText("B");
		}
		return button_9_1;
	}
	protected JButton getButton_10_1()
	{
		if (button_10_1 == null) {
			button_10_1 = new JButton();
			button_10_1.setForeground(Color.WHITE);
			button_10_1.setBackground(Color.BLACK);
			button_10_1.setBounds(308, 89, 32, 32);
			button_10_1.setMargin(new Insets(2, 2, 2, 2));
			button_10_1.setText("N");
		}
		return button_10_1;
	}
	protected JButton getButton_11_1()
	{
		if (button_11_1 == null) {
			button_11_1 = new JButton();
			button_11_1.setForeground(Color.WHITE);
			button_11_1.setBackground(Color.BLACK);
			button_11_1.setBounds(350, 89, 32, 32);
			button_11_1.setMargin(new Insets(2, 2, 2, 2));
			button_11_1.setText("M");
		}
		return button_11_1;
	}
	protected JButton getButton_12_1()
	{
		if (button_12_1 == null) {
			button_12_1 = new JButton();
			button_12_1.setForeground(Color.WHITE);
			button_12_1.setBackground(Color.BLACK);
			button_12_1.setBounds(392, 89, 32, 32);
			button_12_1.setMargin(new Insets(2, 2, 2, 2));
			button_12_1.setText(",");
		}
		return button_12_1;
	}
	protected JButton getButton_13_1()
	{
		if (button_13_1 == null) {
			button_13_1 = new JButton();
			button_13_1.setForeground(Color.WHITE);
			button_13_1.setBackground(Color.BLACK);
			button_13_1.setBounds(434, 89, 32, 32);
			button_13_1.setMargin(new Insets(2, 2, 2, 2));
			button_13_1.setText(".");
		}
		return button_13_1;
	}
	protected JButton getButton_14_1()
	{
		if (button_14_1 == null) {
			button_14_1 = new JButton();
			button_14_1.setForeground(Color.WHITE);
			button_14_1.setBackground(Color.BLACK);
			button_14_1.setBounds(476, 89, 32, 32);
			button_14_1.setMargin(new Insets(2, 2, 2, 2));
			button_14_1.setText("?");
		}
		return button_14_1;
	}
	protected JToggleButton getButton_3_1_1_1()
	{
		if (button_3_1_1_1 == null) {
			button_3_1_1_1 = new JToggleButton();
			button_3_1_1_1.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
				}
			});
			button_3_1_1_1.setForeground(Color.WHITE);
			button_3_1_1_1.setBackground(Color.BLACK);
			button_3_1_1_1.setBounds(517, 89, 85, 32);
			button_3_1_1_1.setMargin(new Insets(2, 24, 2, 10));
			button_3_1_1_1.setHorizontalAlignment(SwingConstants.LEFT);
			button_3_1_1_1.setAlignmentX(Component.CENTER_ALIGNMENT);
			button_3_1_1_1.setText("SHIFT");
		}
		return button_3_1_1_1;
	}
	protected JButton getButton_17()
	{
		if (button_17 == null) {
			button_17 = new JButton();
			button_17.setForeground(Color.WHITE);
			button_17.setBackground(Color.BLACK);
			button_17.setBounds(612, 89, 32, 32);
			button_17.setMargin(new Insets(2, 1, 2, 1));
			button_17.setText("UP");
		}
		return button_17;
	}
	protected JButton getButton_15_2()
	{
		if (button_15_2 == null) {
			button_15_2 = new JButton();
			button_15_2.setForeground(Color.WHITE);
			button_15_2.setBackground(Color.BLACK);
			button_15_2.setBounds(10, 130, 32, 32);
			button_15_2.setMargin(new Insets(2, 2, 2, 2));
			button_15_2.setText("IX");
		}
		return button_15_2;
	}
	protected JButton getButton_15_2_1()
	{
		if (button_15_2_1 == null) {
			button_15_2_1 = new JButton();
			button_15_2_1.setForeground(Color.WHITE);
			button_15_2_1.setBackground(Color.BLACK);
			button_15_2_1.setBounds(51, 130, 32, 32);
			button_15_2_1.setMargin(new Insets(2, 2, 2, 2));
			button_15_2_1.setText("MN");
		}
		return button_15_2_1;
	}
	protected JButton getButton_8_1()
	{
		if (button_8_1 == null) {
			button_8_1 = new JButton();
			button_8_1.setForeground(Color.WHITE);
			button_8_1.setBackground(Color.BLACK);
			button_8_1.setBounds(92, 130, 32, 32);
			button_8_1.setMargin(new Insets(2, 2, 2, 2));
			button_8_1.setText("HP");
		}
		return button_8_1;
	}
	protected JButton getButton_8_1_1()
	{
		if (button_8_1_1 == null) {
			button_8_1_1 = new JButton();
			button_8_1_1.setForeground(Color.WHITE);
			button_8_1_1.setBackground(Color.BLACK);
			button_8_1_1.setBounds(133, 130, 32, 32);
			button_8_1_1.setMargin(new Insets(2, 2, 2, 2));
			button_8_1_1.setText("[]");
		}
		return button_8_1_1;
	}
	protected JButton getButton_3_1_1_2()
	{
		if (button_3_1_1_2 == null) {
			button_3_1_1_2 = new JButton();
			button_3_1_1_2.setForeground(Color.WHITE);
			button_3_1_1_2.setBackground(Color.BLACK);
			button_3_1_1_2.setBounds(174, 130, 303, 32);
			button_3_1_1_2.setMargin(new Insets(2, 22, 2, 10));
			button_3_1_1_2.setHorizontalAlignment(SwingConstants.LEFT);
			button_3_1_1_2.setAlignmentX(Component.CENTER_ALIGNMENT);
		}
		return button_3_1_1_2;
	}
	protected JButton getButton_14_1_1()
	{
		if (button_14_1_1 == null) {
			button_14_1_1 = new JButton();
			button_14_1_1.setForeground(Color.WHITE);
			button_14_1_1.setBackground(Color.BLACK);
			button_14_1_1.setBounds(487, 130, 32, 32);
			button_14_1_1.setMargin(new Insets(2, 2, 2, 2));
			button_14_1_1.setText("CL");
		}
		return button_14_1_1;
	}
	protected JButton getButton_17_1()
	{
		if (button_17_1 == null) {
			button_17_1 = new JButton();
			button_17_1.setForeground(Color.WHITE);
			button_17_1.setBackground(Color.BLACK);
			button_17_1.setBounds(612, 130, 32, 32);
			button_17_1.setMargin(new Insets(2, 1, 2, 1));
			button_17_1.setText("DN");
		}
		return button_17_1;
	}
	protected JButton getButton_17_1_1()
	{
		if (button_17_1_1 == null) {
			button_17_1_1 = new JButton();
			button_17_1_1.setForeground(Color.WHITE);
			button_17_1_1.setBackground(Color.BLACK);
			button_17_1_1.setBounds(529, 130, 32, 32);
			button_17_1_1.setMargin(new Insets(2, 1, 2, 1));
			button_17_1_1.setText("LF");
		}
		return button_17_1_1;
	}
	protected JButton getButton_17_2()
	{
		if (button_17_2 == null) {
			button_17_2 = new JButton();
			button_17_2.setForeground(Color.WHITE);
			button_17_2.setBackground(Color.BLACK);
			button_17_2.setBounds(570, 130, 32, 32);
			button_17_2.setMargin(new Insets(2, 1, 2, 1));
			button_17_2.setText("RG");
		}
		return button_17_2;
	}
	protected JPanel getPanel_2()
	{
		if (panel_2 == null) {
			panel_2 = new JPanel();
			panel_2.setPreferredSize(new Dimension(648, 72));
			panel_2.setBorder(new BevelBorder(BevelBorder.LOWERED, Color.GRAY, Color.WHITE));
			panel_2.setLayout(new FlowLayout());
			panel_2.setForeground(Color.WHITE);
			panel_2.setBackground(Color.BLACK);
			panel_2.add(getZ88Display());
		}
		return panel_2;
	}
	
	protected JLabel getZ88Display()
	{
		if (z88Display == null) {
			z88Display = Z88display.getInstance();
			z88Display.setLayout(null);
			z88Display.setForeground(Color.WHITE);
			z88Display.setText("This is the Z88 Screen");
		}
		return z88Display;
	}
	
	protected JToolBar getToolBar()
	{
		if (toolBar == null) {
			toolBar = new JToolBar();
			toolBar.add(getButton_1());
			toolBar.add(getButton_2());
			toolBar.setVisible(false);
		}
		return toolBar;
	}
	protected JButton getButton_1()
	{
		if (button_1 == null) {
			button_1 = new JButton();
			button_1.setText("New JButton");
		}
		return button_1;
	}
	protected JButton getButton_2()
	{
		if (button_2 == null) {
			button_2 = new JButton();
			button_2.setText("New JButton");
		}
		return button_2;
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
			jRtmOutputArea = new javax.swing.JTextArea();
			jRtmOutputArea.setTabSize(1);
			jRtmOutputArea.setFont(new java.awt.Font("Monospaced",java.awt.Font.PLAIN, 11));
			jRtmOutputArea.setEditable(false);
		}
		return jRtmOutputArea;
	}
	
	public static void displayRtmMessage(final String msg) {
		Gui.getInstance().getRtmOutputArea().append("\n" + msg);
		Gui.getInstance().getRtmOutputArea().setCaretPosition(Gui.getInstance().getRtmOutputArea().getDocument().getLength());
	}
	
	/**
	 * This method initializes the z88 display window and menus
	 */
	private void initialize() {
		this.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		this.setTitle("OZvm V" + OZvm.VERSION);
		this.setResizable(false);
		this.pack();
		this.setVisible(true);
		
		this.addWindowListener(new java.awt.event.WindowAdapter() {
			public void windowClosing(java.awt.event.WindowEvent e) {
				System.out.println("OZvm application ended by user.");
				//Blink.getInstance().stopZ80Execution();
				System.exit(0);
			}
		});		
	}	
}
