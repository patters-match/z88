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
import javax.swing.BorderFactory;
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
import java.awt.Component;
import java.awt.Insets;
import java.awt.Color;
import javax.swing.JToggleButton;
import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;

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
	private javax.swing.JMenu jHelpMenu = null;
	private JButton escKeyButton;
	private JButton helpKeyButton;
	private JButton rightArrowKeyButton;
	private JButton numKey0Button;
	private JButton numKey1Button;
	private JButton numKey2Button;
	private JButton numKey3Button;
	private JButton numKey4Button;
	private JButton numKey5Button;
	private JButton numKey6Button;
	private JButton numKey7Button;
	private JButton numKey8Button;
	private JButton numKey9Button;
	private JButton key037fButton;
	private JButton key027fButton;
	private JButton key017fButton;
	private JButton delKeyButton;
	
	
	private JButton button_2;
	private JButton button_1;
	private JToolBar toolBar;
	private JLabel z88Display;
	private JPanel panel_2;
	private JButton button_17_1_1;
	private JButton button_17_1;
	private JButton button_14_1_1;
	private JButton button_3_1_1_2;
	private JButton button_8_1_1;
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
	private JButton key047fButton;
	private JButton key057fButton;
	private JButton key04FeButton;
	private JButton key02FeButton;
	private JButton key01FeButton;
	private JButton key01FdButton;
	private JButton key00EfButton;
	private JButton key01EfButton;
	private JButton key02EfButton;
	private JButton key03EfButton;
	private JButton key04EfButton;
	private JButton key05EfButton;
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

		menuBar.add(getHelpMenu());
		
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

		panel_1.add(getEscKeyButton());
		panel_1.add(getNumKey1Button());
		panel_1.add(getNumKey2Button());
		panel_1.add(getNumKey3Button());
		panel_1.add(getNumKey4Button());
		panel_1.add(getNumKey5Button());
		panel_1.add(getNumKey6Button());
		panel_1.add(getNumKey7Button());
		panel_1.add(getNumKey8Button());
		panel_1.add(getNumKey9Button());
		panel_1.add(getNumKey0Button());
		panel_1.add(getKey037fButton());
		panel_1.add(getKey027fButton());
		panel_1.add(getKey017fButton());
		panel_1.add(getDelKeyButton());
		
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
			panel_1.add(getKey05EfButton());
			panel_1.add(getKey04EfButton());
			panel_1.add(getKey03EfButton());
			panel_1.add(getKey02EfButton());
			panel_1.add(getKey01EfButton());
			panel_1.add(getKey00EfButton());
			panel_1.add(getKey01FdButton());
			panel_1.add(getKey01FeButton());
			panel_1.add(getKey02FeButton());
			panel_1.add(getKey04FeButton());
			panel_1.add(getKey057fButton());
			panel_1.add(getKey047fButton());
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
			panel_1.add(getHelpKeyButton());
			panel_1.add(getButton_8_1_1());
			panel_1.add(getButton_3_1_1_2());
			panel_1.add(getButton_14_1_1());
			panel_1.add(getButton_17_1());
			panel_1.add(getButton_17_1_1());
			panel_1.add(getRightArrowKeyButton());
		}
		return panel_1;
	}
	
	protected JButton getButton_3()
	{
		if (button_3 == null) {
			button_3 = new JButton();
			button_3.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			button_3.setForeground(Color.WHITE);
			button_3.setBackground(Color.BLACK);
			button_3.setBounds(10, 5, 56, 32);
			button_3.setPreferredSize(new Dimension(56, 32));
			button_3.setMargin(new Insets(2, 13, 2, 12));
			button_3.setAlignmentX(Component.CENTER_ALIGNMENT);
			button_3.setText("TAB");
			
			button_3.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x06, 0xDF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x06, 0xDF);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																											
		}
		return button_3;
	}
	
	protected JButton getKey05EfButton() {
		if (key05EfButton == null) {
			key05EfButton = new JButton();
			key05EfButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key05EfButton.setForeground(Color.WHITE);
			key05EfButton.setBackground(Color.BLACK);
			key05EfButton.setBounds(76, 5, 32, 32);
			key05EfButton.setPreferredSize(new Dimension(32, 32));
			key05EfButton.setMargin(new Insets(2, 2, 2, 2));
			key05EfButton.setText("Q");
			key05EfButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x05, 0xEF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x05, 0xEF);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																											
		}
		
		return key05EfButton;
	}
	
	protected JButton getKey04EfButton() {
		if (key04EfButton == null) {
			key04EfButton = new JButton();
			key04EfButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key04EfButton.setForeground(Color.WHITE);
			key04EfButton.setBackground(Color.BLACK);
			key04EfButton.setBounds(118, 5, 32, 32);
			key04EfButton.setPreferredSize(new Dimension(32, 32));
			key04EfButton.setMargin(new Insets(2, 2, 2, 2));
			key04EfButton.setText("W");
			key04EfButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x04, 0xEF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x04, 0xEF);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																											
		}
		
		return key04EfButton;
	}
	
	protected JButton getKey03EfButton() {
		if (key03EfButton == null) {
			key03EfButton = new JButton();
			key03EfButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key03EfButton.setForeground(Color.WHITE);
			key03EfButton.setBackground(Color.BLACK);
			key03EfButton.setBounds(160, 5, 32, 32);
			key03EfButton.setPreferredSize(new Dimension(32, 32));
			key03EfButton.setMargin(new Insets(2, 2, 2, 2));
			key03EfButton.setText("E");
			
			key03EfButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x03, 0xEF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x03, 0xEF);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																											
		}
		
		return key03EfButton;
	}
	
	protected JButton getKey02EfButton()
	{
		if (key02EfButton == null) {
			key02EfButton = new JButton();
			key02EfButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key02EfButton.setForeground(Color.WHITE);
			key02EfButton.setBackground(Color.BLACK);
			key02EfButton.setBounds(202, 5, 32, 32);
			key02EfButton.setPreferredSize(new Dimension(32, 32));
			key02EfButton.setMargin(new Insets(2, 2, 2, 2));
			key02EfButton.setText("R");
			key02EfButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x02, 0xEF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x02, 0xEF);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																											
		}
		return key02EfButton;
	}
	
	protected JButton getKey01EfButton() {
		if (key01EfButton == null) {
			key01EfButton = new JButton();
			key01EfButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key01EfButton.setForeground(Color.WHITE);
			key01EfButton.setBackground(Color.BLACK);
			key01EfButton.setBounds(244, 5, 32, 32);
			key01EfButton.setPreferredSize(new Dimension(32, 32));
			key01EfButton.setMargin(new Insets(2, 2, 2, 2));
			key01EfButton.setText("T");
			
			key01EfButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x01, 0xEF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x01, 0xEF);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																											
		}
		return key01EfButton;
	}
	
	protected JButton getKey00EfButton() {
		if (key00EfButton == null) {
			key00EfButton = new JButton();
			key00EfButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key00EfButton.setForeground(Color.WHITE);
			key00EfButton.setBackground(Color.BLACK);
			key00EfButton.setBounds(286, 5, 32, 32);
			key00EfButton.setPreferredSize(new Dimension(32, 32));
			key00EfButton.setMargin(new Insets(2, 2, 2, 2));
			key00EfButton.setText("Y");
			
			key00EfButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x00, 0xEF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x00, 0xEF);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																											
		}
		
		return key00EfButton;
	}
	
	protected JButton getKey01FdButton()
	{
		if (key01FdButton == null) {
			key01FdButton = new JButton();
			key01FdButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key01FdButton.setForeground(Color.WHITE);
			key01FdButton.setBackground(Color.BLACK);
			key01FdButton.setBounds(328, 5, 32, 32);
			key01FdButton.setPreferredSize(new Dimension(32, 32));
			key01FdButton.setMargin(new Insets(2, 2, 2, 2));
			key01FdButton.setText("U");
			
			key01FdButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x01, 0xFD);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x01, 0xFD);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																											
		}
		
		return key01FdButton;
	}
	
	protected JButton getKey01FeButton() {
		if (key01FeButton == null) {
			key01FeButton = new JButton();
			key01FeButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key01FeButton.setForeground(Color.WHITE);
			key01FeButton.setBackground(Color.BLACK);
			key01FeButton.setBounds(370, 5, 32, 32);
			key01FeButton.setPreferredSize(new Dimension(32, 32));
			key01FeButton.setMargin(new Insets(2, 2, 2, 2));
			key01FeButton.setText("I");

			key01FeButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x01, 0xFE);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x01, 0xFE);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																											
		}
		
		return key01FeButton;
	}
	
	protected JButton getKey02FeButton()
	{
		if (key02FeButton == null) {
			key02FeButton = new JButton();
			key02FeButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key02FeButton.setForeground(Color.WHITE);
			key02FeButton.setBackground(Color.BLACK);
			key02FeButton.setBounds(412, 5, 32, 32);
			key02FeButton.setPreferredSize(new Dimension(32, 32));
			key02FeButton.setMargin(new Insets(2, 2, 2, 2));
			key02FeButton.setText("O");
			
			key02FeButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x02, 0xFE);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x02, 0xFE);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																											
		}
		
		return key02FeButton;
	}
	
	protected JButton getKey04FeButton() {
		if (key04FeButton == null) {
			key04FeButton = new JButton();
			key04FeButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key04FeButton.setForeground(Color.WHITE);
			key04FeButton.setBackground(Color.BLACK);
			key04FeButton.setBounds(454, 5, 32, 32);
			key04FeButton.setPreferredSize(new Dimension(32, 32));
			key04FeButton.setMargin(new Insets(2, 2, 2, 2));
			key04FeButton.setText("P");
			
			key04FeButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x04, 0xFE);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x04, 0xFE);
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});
		}
		
		return key04FeButton;
	}
	
	protected JButton getKey057fButton() {
		if (key057fButton == null) {
			key057fButton = new JButton();
			key057fButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key057fButton.setForeground(Color.WHITE);
			key057fButton.setBackground(Color.BLACK);
			key057fButton.setBounds(496, 5, 32, 32);
			key057fButton.setPreferredSize(new Dimension(32, 32));
			key057fButton.setMargin(new Insets(2, 2, 2, 2));
			key057fButton.setText("[");
			
			key057fButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x05, 0x7F);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x05, 0x7F);
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});
		}
		
		return key057fButton;
	}
	protected JButton getKey047fButton()
	{
		if (key047fButton == null) {
			key047fButton = new JButton();
			key047fButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key047fButton.setForeground(Color.WHITE);
			key047fButton.setBackground(Color.BLACK);
			key047fButton.setBounds(538, 5, 32, 32);
			key047fButton.setPreferredSize(new Dimension(32, 32));
			key047fButton.setMargin(new Insets(2, 2, 2, 2));
			key047fButton.setText("]");
			
			key047fButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x04, 0x7F);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x04, 0x7F);
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});
		}
		return key047fButton;
	}
	protected JButton getButton()
	{
		if (button == null) {
			button = new JButton();
			button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			button.setForeground(Color.WHITE);
			button.setBackground(Color.BLACK);
			button.setBounds(587, 5, 57, 74);
			button.setText("CR");
			
			button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x00, 0xBF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x00, 0xBF);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});			
		}
		return button;
	}
	protected JButton getButton_15_1()
	{
		if (button_15_1 == null) {
			button_15_1 = new JButton();
			button_15_1.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			button_15_1.setForeground(Color.WHITE);
			button_15_1.setBackground(Color.BLACK);
			button_15_1.setBounds(544, 47, 32, 32);
			button_15_1.setMargin(new Insets(2, 2, 2, 2));
			button_15_1.setText("£");
		}
		return button_15_1;
	}
	protected JButton getButton_3_1()
	{
		if (button_3_1 == null) {
			button_3_1 = new JButton();
			button_3_1.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			button_3_1.setForeground(Color.WHITE);
			button_3_1.setBackground(Color.BLACK);
			button_3_1.setBounds(10, 47, 63, 32);
			button_3_1.setMargin(new Insets(2, 22, 2, 10));
			button_3_1.setAlignmentX(Component.CENTER_ALIGNMENT);
			button_3_1.setText("<>");
			
			button_3_1.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x06, 0xEF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x06, 0xEF);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});						
		}
		return button_3_1;
	}
	protected JButton getButton_4_1()
	{
		if (button_4_1 == null) {
			button_4_1 = new JButton();
			button_4_1.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
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
			button_4_1_1.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
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
			button_4_1_1_1.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
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
			button_4_1_1_1_1.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
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
			button_4_1_1_1_1_1.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
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
			button_4_1_1_1_1_1_1.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
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
			button_4_1_1_1_1_1_1_1.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
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
			button_4_1_1_1_1_1_1_1_1.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
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
			button_4_1_1_1_1_1_1_1_1_1.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
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
			button_4_1_1_1_1_1_1_1_1_1_1.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			button_4_1_1_1_1_1_1_1_1_1_1.setForeground(Color.WHITE);
			button_4_1_1_1_1_1_1_1_1_1_1.setBackground(Color.BLACK);
			button_4_1_1_1_1_1_1_1_1_1_1.setBounds(459, 47, 32, 32);
			button_4_1_1_1_1_1_1_1_1_1_1.setMargin(new Insets(2, 2, 2, 2));
			button_4_1_1_1_1_1_1_1_1_1_1.setText(";");
		}
		return button_4_1_1_1_1_1_1_1_1_1_1;
	}
	protected JButton getButton_4_1_1_1_1_1_1_1_1_1_1_1()
	{
		if (button_4_1_1_1_1_1_1_1_1_1_1_1 == null) {
			button_4_1_1_1_1_1_1_1_1_1_1_1 = new JButton();
			button_4_1_1_1_1_1_1_1_1_1_1_1.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			button_4_1_1_1_1_1_1_1_1_1_1_1.setForeground(Color.WHITE);
			button_4_1_1_1_1_1_1_1_1_1_1_1.setBackground(Color.BLACK);
			button_4_1_1_1_1_1_1_1_1_1_1_1.setBounds(501, 47, 32, 32);
			button_4_1_1_1_1_1_1_1_1_1_1_1.setMargin(new Insets(2, 2, 2, 2));
			button_4_1_1_1_1_1_1_1_1_1_1_1.setText("'");
		}
		return button_4_1_1_1_1_1_1_1_1_1_1_1;
	}
	protected JToggleButton getButton_3_1_1()
	{
		if (button_3_1_1 == null) {
			button_3_1_1 = new JToggleButton();
			button_3_1_1.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			button_3_1_1.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					if (button_3_1_1.isSelected() == true) {
						Z88Keyboard.getInstance().pressZ88key(0x06, 0xBF);
					} else {
						Z88Keyboard.getInstance().releaseZ88key(0x06, 0xBF);						
					}
					Z88display.getInstance().grabFocus();
				}
			});
			button_3_1_1.setForeground(Color.WHITE);
			button_3_1_1.setBackground(Color.BLACK);
			button_3_1_1.setBounds(10, 89, 82, 32);
			button_3_1_1.setMargin(new Insets(2, 22, 2, 10));
			button_3_1_1.setAlignmentX(Component.CENTER_ALIGNMENT);
			button_3_1_1.setText("SHIFT");
		}
		return button_3_1_1;
	}
	protected JButton getButton_4_1_2()
	{
		if (button_4_1_2 == null) {
			button_4_1_2 = new JButton();
			button_4_1_2.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
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
			button_4_2.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
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
			button_6_1.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
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
			button_7_1.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
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
			button_9_1.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
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
			button_10_1.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
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
			button_11_1.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
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
			button_12_1.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
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
			button_13_1.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
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
			button_14_1.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			button_14_1.setForeground(Color.WHITE);
			button_14_1.setBackground(Color.BLACK);
			button_14_1.setBounds(476, 89, 32, 32);
			button_14_1.setMargin(new Insets(2, 2, 2, 2));
			button_14_1.setText("/");
		}
		return button_14_1;
	}
	protected JToggleButton getButton_3_1_1_1()
	{
		if (button_3_1_1_1 == null) {
			button_3_1_1_1 = new JToggleButton();
			button_3_1_1_1.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					if (button_3_1_1_1.isSelected() == true) {
						Z88Keyboard.getInstance().pressZ88key(0x07, 0x7F);
					} else {
						Z88Keyboard.getInstance().releaseZ88key(0x07, 0x7F);						
					}
					Z88display.getInstance().grabFocus();
				}
			});
			
			button_3_1_1_1.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			button_3_1_1_1.setForeground(Color.WHITE);
			button_3_1_1_1.setBackground(Color.BLACK);
			button_3_1_1_1.setBounds(517, 89, 85, 32);
			button_3_1_1_1.setMargin(new Insets(2, 24, 2, 10));
			button_3_1_1_1.setAlignmentX(Component.CENTER_ALIGNMENT);
			button_3_1_1_1.setText("SHIFT");
		}
		return button_3_1_1_1;
	}
	protected JButton getButton_17()
	{
		if (button_17 == null) {
			button_17 = new JButton();
			button_17.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			button_17.setForeground(Color.WHITE);
			button_17.setBackground(Color.BLACK);
			button_17.setBounds(612, 89, 32, 32);
			button_17.setMargin(new Insets(2, 1, 2, 1));
			button_17.setText("UP");
			
			button_17.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x01, 0xBF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x01, 0xBF);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																								
		}
		return button_17;
	}
	protected JButton getButton_15_2()
	{
		if (button_15_2 == null) {
			button_15_2 = new JButton();
			button_15_2.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			button_15_2.setForeground(Color.WHITE);
			button_15_2.setBackground(Color.BLACK);
			button_15_2.setBounds(10, 130, 32, 32);
			button_15_2.setMargin(new Insets(2, 2, 2, 2));
			button_15_2.setText("IX");
			
			button_15_2.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x07, 0xEF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x07, 0xEF);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																					
		}
		return button_15_2;
	}
	protected JButton getButton_15_2_1()
	{
		if (button_15_2_1 == null) {
			button_15_2_1 = new JButton();
			button_15_2_1.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			button_15_2_1.setForeground(Color.WHITE);
			button_15_2_1.setBackground(Color.BLACK);
			button_15_2_1.setBounds(51, 130, 32, 32);
			button_15_2_1.setMargin(new Insets(2, 2, 2, 2));
			button_15_2_1.setText("MN");
			
			button_15_2_1.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x06, 0xF7);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x06, 0xF7);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																		
		}
		return button_15_2_1;
	}
	
	protected JButton getHelpKeyButton()
	{
		if (helpKeyButton == null) {
			helpKeyButton = new JButton();
			helpKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			helpKeyButton.setForeground(Color.WHITE);
			helpKeyButton.setBackground(Color.BLACK);
			helpKeyButton.setBounds(92, 130, 32, 32);
			helpKeyButton.setMargin(new Insets(2, 2, 2, 2));
			helpKeyButton.setText("HLP");

			helpKeyButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x06, 0x7F);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x06, 0x7F);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});															
		}
		return helpKeyButton;
	}
	
	protected JButton getButton_8_1_1()
	{
		if (button_8_1_1 == null) {
			button_8_1_1 = new JButton();
			button_8_1_1.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			button_8_1_1.setForeground(Color.WHITE);
			button_8_1_1.setBackground(Color.BLACK);
			button_8_1_1.setBounds(133, 130, 32, 32);
			button_8_1_1.setMargin(new Insets(2, 2, 2, 2));
			button_8_1_1.setText("[]");
			
			button_8_1_1.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x07, 0xBF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x07, 0xBF);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});						
		}
		return button_8_1_1;
	}
	protected JButton getButton_3_1_1_2()
	{
		if (button_3_1_1_2 == null) {
			button_3_1_1_2 = new JButton();
			button_3_1_1_2.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			button_3_1_1_2.setForeground(Color.WHITE);
			button_3_1_1_2.setBackground(Color.BLACK);
			button_3_1_1_2.setBounds(174, 130, 303, 32);
			button_3_1_1_2.setMargin(new Insets(2, 22, 2, 10));
			button_3_1_1_2.setAlignmentX(Component.CENTER_ALIGNMENT);
			
			button_3_1_1_2.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x05, 0xBF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x05, 0xBF);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																											
			
		}
		return button_3_1_1_2;
	}
	protected JButton getButton_14_1_1()
	{
		if (button_14_1_1 == null) {
			button_14_1_1 = new JButton();
			button_14_1_1.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			button_14_1_1.setForeground(Color.WHITE);
			button_14_1_1.setBackground(Color.BLACK);
			button_14_1_1.setBounds(487, 130, 32, 32);
			button_14_1_1.setMargin(new Insets(2, 2, 2, 2));
			button_14_1_1.setText("CPS");
			
			button_14_1_1.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x07, 0xF7);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x07, 0xF7);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});									
		}
		return button_14_1_1;
	}
	protected JButton getButton_17_1()
	{
		if (button_17_1 == null) {
			button_17_1 = new JButton();
			button_17_1.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			button_17_1.setForeground(Color.WHITE);
			button_17_1.setBackground(Color.BLACK);
			button_17_1.setBounds(612, 130, 32, 32);
			button_17_1.setMargin(new Insets(2, 1, 2, 1));
			button_17_1.setText("DN");
			
			button_17_1.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x02, 0xBF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x02, 0xBF);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});									
		}
		return button_17_1;
	}
	protected JButton getButton_17_1_1()
	{
		if (button_17_1_1 == null) {
			button_17_1_1 = new JButton();
			button_17_1_1.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			button_17_1_1.setForeground(Color.WHITE);
			button_17_1_1.setBackground(Color.BLACK);
			button_17_1_1.setBounds(529, 130, 32, 32);
			button_17_1_1.setMargin(new Insets(2, 2, 2, 2));
			button_17_1_1.setText("LF");

			button_17_1_1.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x04, 0xBF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x04, 0xBF);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});									
		}
		return button_17_1_1;
	}
	
	protected JButton getRightArrowKeyButton()
	{
		if (rightArrowKeyButton == null) {
			rightArrowKeyButton = new JButton();
			rightArrowKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			rightArrowKeyButton.setForeground(Color.WHITE);
			rightArrowKeyButton.setBackground(Color.BLACK);
			rightArrowKeyButton.setBounds(570, 130, 32, 32);
			rightArrowKeyButton.setMargin(new Insets(2, 2, 2, 2));
			rightArrowKeyButton.setText("RG");
			
			rightArrowKeyButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x03, 0xBF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x03, 0xBF);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});												
		}
		return rightArrowKeyButton;
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

	protected JButton getEscKeyButton() {
		if (escKeyButton == null) {
			escKeyButton = new JButton();
			escKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			escKeyButton.setForeground(Color.WHITE);
			escKeyButton.setBackground(Color.BLACK);
			escKeyButton.setPreferredSize(new Dimension(32, 32));
			escKeyButton.setMargin(new Insets(2, 2, 2, 2));
			escKeyButton.setAlignmentX(Component.CENTER_ALIGNMENT);
			escKeyButton.setText("ESC");
			
			escKeyButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x07, 0xDF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x07, 0xDF);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});					
		}
		
		return escKeyButton;
	}

	protected JButton getNumKey0Button() {
		if (numKey0Button == null) {
			numKey0Button = new JButton();
			numKey0Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			numKey0Button.setForeground(Color.WHITE);
			numKey0Button.setBackground(Color.BLACK);
			numKey0Button.setPreferredSize(new Dimension(32, 32));
			numKey0Button.setMargin(new Insets(2, 2, 2, 2));
			numKey0Button.setText("0");
			numKey0Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x05, 0xFE);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x05, 0xFE);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																														
		}
		
		return numKey0Button;
	}
	
	protected JButton getNumKey1Button() {
		if (numKey1Button == null) {
			numKey1Button = new JButton();
			numKey1Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			numKey1Button.setForeground(Color.WHITE);
			numKey1Button.setBackground(Color.BLACK);
			numKey1Button.setPreferredSize(new Dimension(32, 32));
			numKey1Button.setMargin(new Insets(2, 2, 2, 2));
			numKey1Button.setText("1");
			numKey1Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x05, 0xDF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x05, 0xDF);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																														
		}
		
		return numKey1Button;
	}

	protected JButton getNumKey2Button() {
		if (numKey2Button == null) {
			numKey2Button = new JButton();
			numKey2Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			numKey2Button.setForeground(Color.WHITE);
			numKey2Button.setBackground(Color.BLACK);
			numKey2Button.setPreferredSize(new Dimension(32, 32));
			numKey2Button.setMargin(new Insets(2, 2, 2, 2));
			numKey2Button.setText("2");
			numKey2Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x04, 0xDF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x04, 0xDF);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																														
		}
		
		return numKey2Button;
	}
	
	protected JButton getNumKey3Button() {
		if (numKey3Button == null) {
			numKey3Button = new JButton();
			numKey3Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			numKey3Button.setForeground(Color.WHITE);
			numKey3Button.setBackground(Color.BLACK);
			numKey3Button.setPreferredSize(new Dimension(32, 32));
			numKey3Button.setMargin(new Insets(2, 2, 2, 2));
			numKey3Button.setText("3");
			numKey3Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x03, 0xDF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x03, 0xDF);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																														
		}
		
		return numKey3Button;
	}

	protected JButton getNumKey4Button() {
		if (numKey4Button == null) {
			numKey4Button = new JButton();
			numKey4Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			numKey4Button.setForeground(Color.WHITE);
			numKey4Button.setBackground(Color.BLACK);
			numKey4Button.setPreferredSize(new Dimension(32, 32));
			numKey4Button.setMargin(new Insets(2, 2, 2, 2));
			numKey4Button.setText("4");
			numKey4Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x02, 0xDF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x02, 0xDF);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																														
		}
		
		return numKey4Button;
	}

	protected JButton getNumKey5Button() {
		if (numKey5Button == null) {
			numKey5Button = new JButton();
			numKey5Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			numKey5Button.setForeground(Color.WHITE);
			numKey5Button.setBackground(Color.BLACK);
			numKey5Button.setPreferredSize(new Dimension(32, 32));
			numKey5Button.setMargin(new Insets(2, 2, 2, 2));
			numKey5Button.setText("5");
			numKey5Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x01, 0xDF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x01, 0xDF);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																														
		}
		
		return numKey5Button;
	}

	protected JButton getNumKey6Button() {
		if (numKey6Button == null) {
			numKey6Button = new JButton();
			numKey6Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			numKey6Button.setForeground(Color.WHITE);
			numKey6Button.setBackground(Color.BLACK);
			numKey6Button.setPreferredSize(new Dimension(32, 32));
			numKey6Button.setMargin(new Insets(2, 2, 2, 2));
			numKey6Button.setText("6");
			numKey6Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x00, 0xDF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x00, 0xDF);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																														
		}
		
		return numKey6Button;
	}

	protected JButton getNumKey7Button() {
		if (numKey7Button == null) {
			numKey7Button = new JButton();
			numKey7Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			numKey7Button.setForeground(Color.WHITE);
			numKey7Button.setBackground(Color.BLACK);
			numKey7Button.setPreferredSize(new Dimension(32, 32));
			numKey7Button.setMargin(new Insets(2, 2, 2, 2));
			numKey7Button.setText("7");
			numKey7Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x00, 0xFD);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x00, 0xFD);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																														
		}
		
		return numKey7Button;
	}

	protected JButton getNumKey8Button() {
		if (numKey8Button == null) {
			numKey8Button = new JButton();
			numKey8Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			numKey8Button.setForeground(Color.WHITE);
			numKey8Button.setBackground(Color.BLACK);
			numKey8Button.setPreferredSize(new Dimension(32, 32));
			numKey8Button.setMargin(new Insets(2, 2, 2, 2));
			numKey8Button.setText("8");
			numKey8Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x00, 0xFE);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x00, 0xFE);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																														
		}
		
		return numKey8Button;
	}
	
	protected JButton getNumKey9Button() {
		if (numKey9Button == null) {
			numKey9Button = new JButton();
			numKey9Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			numKey9Button.setForeground(Color.WHITE);
			numKey9Button.setBackground(Color.BLACK);
			numKey9Button.setPreferredSize(new Dimension(32, 32));
			numKey9Button.setMargin(new Insets(2, 2, 2, 2));
			numKey9Button.setText("9");
			numKey9Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x03, 0xFE);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x03, 0xFE);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																														
		}
		
		return numKey9Button;
	}

	protected JButton getKey037fButton() {
		if (key037fButton == null) {
			key037fButton = new JButton();
			key037fButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key037fButton.setForeground(Color.WHITE);
			key037fButton.setBackground(Color.BLACK);
			key037fButton.setPreferredSize(new Dimension(32, 32));
			key037fButton.setMargin(new Insets(2, 2, 2, 2));
			key037fButton.setText("-");
			key037fButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x03, 0x7F);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x03, 0x7F);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																														
		}
		
		return key037fButton;
	}
	
	protected JButton getKey027fButton() {
		if (key027fButton == null) {
			key027fButton = new JButton();
			key027fButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key027fButton.setForeground(Color.WHITE);
			key027fButton.setBackground(Color.BLACK);
			key027fButton.setPreferredSize(new Dimension(32, 32));
			key027fButton.setMargin(new Insets(2, 2, 2, 2));
			key027fButton.setText("=");
			key027fButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x02, 0x7F);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x02, 0x7F);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																														
		}
		
		return key027fButton;
	}
	
	protected JButton getKey017fButton() {
		if (key017fButton == null) {
			key017fButton = new JButton();
			key017fButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key017fButton.setForeground(Color.WHITE);
			key017fButton.setBackground(Color.BLACK);
			key017fButton.setPreferredSize(new Dimension(32, 32));
			key017fButton.setMargin(new Insets(2, 2, 2, 2));
			key017fButton.setText("\\");
			key017fButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x01, 0x7F);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x01, 0x7F);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																														
		}
		
		return key017fButton;
	}

	protected JButton getDelKeyButton() {
		if (delKeyButton == null) {
			delKeyButton = new JButton();
			delKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			delKeyButton.setForeground(Color.WHITE);
			delKeyButton.setBackground(Color.BLACK);
			delKeyButton.setPreferredSize(new Dimension(32, 32));
			delKeyButton.setMargin(new Insets(2, 2, 2, 2));
			delKeyButton.setText("DEL");
			delKeyButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x00, 0x7F);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x00, 0x7F);
					Z88display.getInstance().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																											
		}

		return delKeyButton;
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
