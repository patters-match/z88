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
import javax.swing.ImageIcon;
import javax.swing.JMenuBar;
import javax.swing.JMenu;
import javax.swing.JMenuItem;
import javax.swing.JScrollPane;
import javax.swing.JTextArea;
import javax.swing.JToolBar;
import javax.swing.JButton;
import javax.swing.border.EmptyBorder;
import java.awt.event.KeyEvent;
import java.awt.Component;
import java.awt.Insets;
import java.awt.Color;

import javax.swing.JToggleButton;
import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;
import java.io.IOException;
import javax.swing.JCheckBoxMenuItem;
import javax.swing.ButtonGroup;

/**
 * The end user Gui (Main menu, screen, runtime messages, keyboard & slot management)
 */
public class Gui extends JFrame {

	private ButtonGroup kbLayoutButtonGroup = new ButtonGroup();
	private JCheckBoxMenuItem seLayoutMenuItem;
	private JCheckBoxMenuItem frLayoutMenuItem;
	private JCheckBoxMenuItem dkLayoutMenuItem;
	private JCheckBoxMenuItem ukLayoutMenuItem;
	private JMenu keyboardMenu;
	private static final class singletonContainer {
		static final Gui singleton = new Gui();  
	}
	
	public static Gui getInstance() {
		return singletonContainer.singleton;
	}
	
	private JScrollPane jRtmOutputScrollPane = null;
	private JTextArea jRtmOutputArea = null;
	
	private JToolBar toolBar;
	private JButton toolBarButton1;
	private JButton toolBarButton2;
	private JLabel z88Display;

	private JToggleButton rightShiftKeyButton;
	private JToggleButton leftShiftKeyButton;
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
	private JButton leftArrowKeyButton;
	private JButton downArrowKeyButton;
	private JButton capslockKeyButton;
	private JButton spaceKeyButton;
	private JButton squareKeyButton;
	private JButton menuKeyButton;
	private JButton indexKeyButton;
	private JButton upArrowKeyButton;
	private JButton key07FdButton;
	private JButton key07FbButton;
	private JButton key06FbButton;
	private JButton key04FdButton;
	private JButton key00FbButton;
	private JButton key01FbButton;
	private JButton key02FbButton;
	private JButton key03FbButton;
	private JButton key04FbButton;
	private JButton key05FbButton;
	private JButton key06FeButton;
	private JButton key06FdButton;
	private JButton key05FdButton;
	private JButton key03FdButton;
	private JButton key02FdButton;
	private JButton key00F7Button;
	private JButton key01F7Button;
	private JButton key02F7Button;
	private JButton key03F7Button;
	private JButton key04F7Button;
	private JButton key05F7Button;
	private JButton diamondKeyButton;
	private JButton key07FeButton;
	private JButton enterKeyButton;
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
	private JButton tabKeyButton;
	
	private JPanel z88ScreenPanel;
	private JPanel keyboardPanel;
	private JPanel keyboardPanel1;

	private JMenuBar menuBar; 
	private JMenu fileMenu;
	private JMenu helpMenu;
	private JMenu viewMenu;
	private JMenuItem fileExitMenuItem;
	private JMenuItem fileDebugMenuItem;
	private JMenuItem aboutOZvmMenuItem;
	private JMenuItem userManualMenuItem;
	private JCheckBoxMenuItem z88keyboardMenuItem;
	private JCheckBoxMenuItem rtmMessagesMenuItem;
	
	private Gui() {
		super();
		initialize();
	}

	private JButton getTabKeyButton()
	{
		if (tabKeyButton == null) {
			tabKeyButton = new JButton();
			tabKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			tabKeyButton.setForeground(Color.WHITE);
			tabKeyButton.setBackground(Color.BLACK);
			tabKeyButton.setBounds(7, 49, 56, 32);
			tabKeyButton.setPreferredSize(new Dimension(56, 32));
			tabKeyButton.setMargin(new Insets(2, 13, 2, 12));
			tabKeyButton.setAlignmentX(Component.CENTER_ALIGNMENT);
			tabKeyButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/tab.gif")));
			
			tabKeyButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x06, 0xDF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x06, 0xDF);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																											
		}
		return tabKeyButton;
	}
	
	private JButton getKey05EfButton() {
		if (key05EfButton == null) {
			key05EfButton = new JButton();
			key05EfButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key05EfButton.setForeground(Color.WHITE);
			key05EfButton.setBackground(Color.BLACK);			
			key05EfButton.setBounds(73, 49, 32, 32);
			key05EfButton.setPreferredSize(new Dimension(32, 32));
			key05EfButton.setMargin(new Insets(2, 2, 2, 2));
			key05EfButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/q.gif")));
			key05EfButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x05, 0xEF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x05, 0xEF);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																											
		}
		
		return key05EfButton;
	}
	
	private JButton getKey04EfButton() {
		if (key04EfButton == null) {
			key04EfButton = new JButton();
			key04EfButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key04EfButton.setForeground(Color.WHITE);
			key04EfButton.setBackground(Color.BLACK);
			key04EfButton.setBounds(115, 49, 32, 32);
			key04EfButton.setPreferredSize(new Dimension(32, 32));
			key04EfButton.setMargin(new Insets(2, 2, 2, 2));
			key04EfButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/w.gif")));
			key04EfButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x04, 0xEF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x04, 0xEF);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																											
		}
		
		return key04EfButton;
	}
	
	private JButton getKey03EfButton() {
		if (key03EfButton == null) {
			key03EfButton = new JButton();
			key03EfButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key03EfButton.setForeground(Color.WHITE);
			key03EfButton.setBackground(Color.BLACK);
			key03EfButton.setBounds(157, 49, 32, 32);
			key03EfButton.setPreferredSize(new Dimension(32, 32));
			key03EfButton.setMargin(new Insets(2, 2, 2, 2));
			key03EfButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/e.gif")));
			
			key03EfButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x03, 0xEF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x03, 0xEF);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																											
		}
		
		return key03EfButton;
	}
	
	private JButton getKey02EfButton()
	{
		if (key02EfButton == null) {
			key02EfButton = new JButton();
			key02EfButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key02EfButton.setForeground(Color.WHITE);
			key02EfButton.setBackground(Color.BLACK);
			key02EfButton.setBounds(199, 49, 32, 32);
			key02EfButton.setPreferredSize(new Dimension(32, 32));
			key02EfButton.setMargin(new Insets(2, 2, 2, 2));
			key02EfButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/r.gif")));
			key02EfButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x02, 0xEF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x02, 0xEF);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																											
		}
		return key02EfButton;
	}
	
	private JButton getKey01EfButton() {
		if (key01EfButton == null) {
			key01EfButton = new JButton();
			key01EfButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key01EfButton.setForeground(Color.WHITE);
			key01EfButton.setBackground(Color.BLACK);
			key01EfButton.setBounds(241, 49, 32, 32);
			key01EfButton.setPreferredSize(new Dimension(32, 32));
			key01EfButton.setMargin(new Insets(2, 2, 2, 2));
			key01EfButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/t.gif")));
			
			key01EfButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x01, 0xEF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x01, 0xEF);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																											
		}
		return key01EfButton;
	}
	
	private JButton getKey00EfButton() {
		if (key00EfButton == null) {
			key00EfButton = new JButton();
			key00EfButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key00EfButton.setForeground(Color.WHITE);
			key00EfButton.setBackground(Color.BLACK);
			key00EfButton.setBounds(283, 49, 32, 32);
			key00EfButton.setPreferredSize(new Dimension(32, 32));
			key00EfButton.setMargin(new Insets(2, 2, 2, 2));
			key00EfButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/y.gif")));
			
			key00EfButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x00, 0xEF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x00, 0xEF);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																											
		}
		
		return key00EfButton;
	}
	
	private JButton getKey01FdButton()
	{
		if (key01FdButton == null) {
			key01FdButton = new JButton();
			key01FdButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key01FdButton.setForeground(Color.WHITE);
			key01FdButton.setBackground(Color.BLACK);
			key01FdButton.setBounds(325, 49, 32, 32);
			key01FdButton.setPreferredSize(new Dimension(32, 32));
			key01FdButton.setMargin(new Insets(2, 2, 2, 2));
			key01FdButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/u.gif")));
			
			key01FdButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x01, 0xFD);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x01, 0xFD);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																											
		}
		
		return key01FdButton;
	}
	
	private JButton getKey01FeButton() {
		if (key01FeButton == null) {
			key01FeButton = new JButton();
			key01FeButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key01FeButton.setForeground(Color.WHITE);
			key01FeButton.setBackground(Color.BLACK);
			key01FeButton.setBounds(367, 49, 32, 32);
			key01FeButton.setPreferredSize(new Dimension(32, 32));
			key01FeButton.setMargin(new Insets(2, 2, 2, 2));
			key01FeButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/i.gif")));

			key01FeButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x01, 0xFE);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x01, 0xFE);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																											
		}
		
		return key01FeButton;
	}
	
	private JButton getKey02FeButton()
	{
		if (key02FeButton == null) {
			key02FeButton = new JButton();
			key02FeButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key02FeButton.setForeground(Color.WHITE);
			key02FeButton.setBackground(Color.BLACK);
			key02FeButton.setBounds(409, 49, 32, 32);
			key02FeButton.setPreferredSize(new Dimension(32, 32));
			key02FeButton.setMargin(new Insets(2, 2, 2, 2));
			key02FeButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/o.gif")));
			
			key02FeButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x02, 0xFE);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x02, 0xFE);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																											
		}
		
		return key02FeButton;
	}
	
	private JButton getKey04FeButton() {
		if (key04FeButton == null) {
			key04FeButton = new JButton();
			key04FeButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key04FeButton.setForeground(Color.WHITE);
			key04FeButton.setBackground(Color.BLACK);
			key04FeButton.setBounds(451, 49, 32, 32);
			key04FeButton.setPreferredSize(new Dimension(32, 32));
			key04FeButton.setMargin(new Insets(2, 2, 2, 2));
			key04FeButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/p.gif")));
			
			key04FeButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x04, 0xFE);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x04, 0xFE);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});
		}
		
		return key04FeButton;
	}
	
	private JButton getKey057fButton() {
		if (key057fButton == null) {
			key057fButton = new JButton();
			key057fButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key057fButton.setForeground(Color.WHITE);
			key057fButton.setBackground(Color.BLACK);
			key057fButton.setBounds(493, 49, 32, 32);
			key057fButton.setPreferredSize(new Dimension(32, 32));
			key057fButton.setMargin(new Insets(2, 2, 2, 2));
			key057fButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/uk/key057f.gif")));
			
			key057fButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x05, 0x7F);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x05, 0x7F);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});
		}
		
		return key057fButton;
	}
	private JButton getKey047fButton()
	{
		if (key047fButton == null) {
			key047fButton = new JButton();
			key047fButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key047fButton.setForeground(Color.WHITE);
			key047fButton.setBackground(Color.BLACK);
			key047fButton.setBounds(535, 49, 32, 32);
			key047fButton.setPreferredSize(new Dimension(32, 32));
			key047fButton.setMargin(new Insets(2, 2, 2, 2));
			key047fButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/uk/key047f.gif")));
			
			key047fButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x04, 0x7F);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x04, 0x7F);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});
		}
		return key047fButton;
	}
	
	private JButton getEnterKeyButton() {
		if (enterKeyButton == null) {
			enterKeyButton = new JButton();
			enterKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			enterKeyButton.setForeground(Color.WHITE);
			enterKeyButton.setBackground(Color.BLACK);
			enterKeyButton.setBounds(584, 49, 57, 74);
			enterKeyButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/enter.gif")));
			
			enterKeyButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x00, 0xBF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x00, 0xBF);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});			
		}
		return enterKeyButton;
	}
	
	private JButton getKey07FeButton() {
		if (key07FeButton == null) {
			key07FeButton = new JButton();
			key07FeButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key07FeButton.setForeground(Color.WHITE);
			key07FeButton.setBackground(Color.BLACK);
			key07FeButton.setBounds(541, 91, 32, 32);
			key07FeButton.setMargin(new Insets(2, 2, 2, 2));
			key07FeButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/uk/key07fe.gif")));
			
			key07FeButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x07, 0xFE);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x07, 0xFE);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});			
		}
		
		return key07FeButton;
	}
	
	private JButton getDiamondKeyButton()
	{
		if (diamondKeyButton == null) {
			diamondKeyButton = new JButton();
			diamondKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			diamondKeyButton.setForeground(Color.WHITE);
			diamondKeyButton.setBackground(Color.BLACK);
			diamondKeyButton.setBounds(7, 91, 63, 32);
			diamondKeyButton.setMargin(new Insets(2, 22, 2, 10));
			diamondKeyButton.setAlignmentX(Component.CENTER_ALIGNMENT);
			diamondKeyButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/diamond.gif")));
			
			diamondKeyButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x06, 0xEF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x06, 0xEF);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});						
		}
		return diamondKeyButton;
	}
	
	private JButton getKey05F7Button() {
		if (key05F7Button == null) {
			key05F7Button = new JButton();
			key05F7Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key05F7Button.setForeground(Color.WHITE);
			key05F7Button.setBackground(Color.BLACK);
			key05F7Button.setBounds(79, 91, 32, 32);
			key05F7Button.setMargin(new Insets(2, 2, 2, 2));
			key05F7Button.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/a.gif")));
			
			key05F7Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x05, 0xF7);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x05, 0xF7);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});			
		}
		
		return key05F7Button;
	}
	
	private JButton getKey04F7Button()
	{
		if (key04F7Button == null) {
			key04F7Button = new JButton();
			key04F7Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key04F7Button.setForeground(Color.WHITE);
			key04F7Button.setBackground(Color.BLACK);
			key04F7Button.setBounds(121, 91, 32, 32);
			key04F7Button.setMargin(new Insets(2, 2, 2, 2));
			key04F7Button.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/s.gif")));
			
			key04F7Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x04, 0xF7);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x04, 0xF7);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});			
		}
		
		return key04F7Button;
	}
	
	private JButton getKey03F7Button() {
		if (key03F7Button == null) {
			key03F7Button = new JButton();
			key03F7Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key03F7Button.setForeground(Color.WHITE);
			key03F7Button.setBackground(Color.BLACK);
			key03F7Button.setBounds(162, 91, 32, 32);
			key03F7Button.setMargin(new Insets(2, 2, 2, 2));
			key03F7Button.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/d.gif")));
			
			key03F7Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x03, 0xF7);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x03, 0xF7);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});			
		}
		
		return key03F7Button;
	}
	
	private JButton getKey02F7Button()
	{
		if (key02F7Button == null) {
			key02F7Button = new JButton();
			key02F7Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key02F7Button.setForeground(Color.WHITE);
			key02F7Button.setBackground(Color.BLACK);
			key02F7Button.setBounds(204, 91, 32, 32);
			key02F7Button.setMargin(new Insets(2, 2, 2, 2));
			key02F7Button.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/f.gif")));
			
			key02F7Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x02, 0xF7);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x02, 0xF7);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});			
		}
		
		return key02F7Button;
	}
	
	private JButton getKey01F7Button() {
		if (key01F7Button == null) {
			key01F7Button = new JButton();
			key01F7Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key01F7Button.setForeground(Color.WHITE);
			key01F7Button.setBackground(Color.BLACK);
			key01F7Button.setBounds(246, 91, 32, 32);
			key01F7Button.setMargin(new Insets(2, 2, 2, 2));
			key01F7Button.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/g.gif")));
			
			key01F7Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x01, 0xF7);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x01, 0xF7);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});						
		}
		
		return key01F7Button;
	}
	
	private JButton getKey00F7Button() {
		if (key00F7Button == null) {
			key00F7Button = new JButton();
			key00F7Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key00F7Button.setForeground(Color.WHITE);
			key00F7Button.setBackground(Color.BLACK);
			key00F7Button.setBounds(288, 91, 32, 32);
			key00F7Button.setMargin(new Insets(2, 2, 2, 2));
			key00F7Button.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/h.gif")));
			
			key00F7Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x00, 0xF7);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x00, 0xF7);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});						
		}
		
		return key00F7Button;
	}
	
	private JButton getKey02FdButton()
	{
		if (key02FdButton == null) {
			key02FdButton = new JButton();
			key02FdButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key02FdButton.setForeground(Color.WHITE);
			key02FdButton.setBackground(Color.BLACK);
			key02FdButton.setBounds(330, 91, 32, 32);
			key02FdButton.setMargin(new Insets(2, 2, 2, 2));
			key02FdButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/j.gif")));
			
			key02FdButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x02, 0xFD);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x02, 0xFD);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});									
		}
		
		return key02FdButton;
	}
	
	private JButton getKey03FdButton() {
		if (key03FdButton == null) {
			key03FdButton = new JButton();
			key03FdButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key03FdButton.setForeground(Color.WHITE);
			key03FdButton.setBackground(Color.BLACK);
			key03FdButton.setBounds(372, 91, 32, 32);
			key03FdButton.setMargin(new Insets(2, 2, 2, 2));
			key03FdButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/k.gif")));
			
			key03FdButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x03, 0xFD);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x03, 0xFD);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});									
		}
		
		return key03FdButton;
	}
	
	private JButton getKey05FdButton() {
		if (key05FdButton == null) {
			key05FdButton = new JButton();
			key05FdButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key05FdButton.setForeground(Color.WHITE);
			key05FdButton.setBackground(Color.BLACK);
			key05FdButton.setBounds(414, 91, 32, 32);
			key05FdButton.setMargin(new Insets(2, 2, 2, 2));
			key05FdButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/l.gif")));
			
			key05FdButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x05, 0xFD);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x05, 0xFD);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});									
		}
		
		return key05FdButton;
	}
	
	private JButton getKey06FdButton() {
		if (key06FdButton == null) {
			key06FdButton = new JButton();
			key06FdButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key06FdButton.setForeground(Color.WHITE);
			key06FdButton.setBackground(Color.BLACK);
			key06FdButton.setBounds(456, 91, 32, 32);
			key06FdButton.setMargin(new Insets(2, 2, 2, 2));
			key06FdButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/uk/key06fd.gif")));
			
			key06FdButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x06, 0xFD);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x06, 0xFD);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});									
		}
		
		return key06FdButton;
	}
	
	private JButton getKey06FeButton()
	{
		if (key06FeButton == null) {
			key06FeButton = new JButton();
			key06FeButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key06FeButton.setForeground(Color.WHITE);
			key06FeButton.setBackground(Color.BLACK);
			key06FeButton.setBounds(498, 91, 32, 32);
			key06FeButton.setMargin(new Insets(2, 2, 2, 2));
			key06FeButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/uk/key06fe.gif")));
			
			key06FeButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x06, 0xFE);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x06, 0xFE);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});									
		}
		return key06FeButton;
	}
	
	private JToggleButton getLeftShiftKeyButton()
	{
		if (leftShiftKeyButton == null) {
			leftShiftKeyButton = new JToggleButton();
			leftShiftKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			leftShiftKeyButton.setForeground(Color.WHITE);
			leftShiftKeyButton.setBackground(Color.BLACK);
			leftShiftKeyButton.setBounds(7, 133, 82, 32);
			leftShiftKeyButton.setMargin(new Insets(2, 22, 2, 10));
			leftShiftKeyButton.setAlignmentX(Component.CENTER_ALIGNMENT);
			leftShiftKeyButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/shift.gif")));
			
			leftShiftKeyButton.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					if (leftShiftKeyButton.isSelected() == true) {
						Z88Keyboard.getInstance().pressZ88key(0x06, 0xBF);
					} else {
						Z88Keyboard.getInstance().releaseZ88key(0x06, 0xBF);						
					}
					getZ88Display().grabFocus();
				}
			});
		}
		return leftShiftKeyButton;
	}
	
	private JButton getKey05FbButton() {
		if (key05FbButton == null) {
			key05FbButton = new JButton();
			key05FbButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key05FbButton.setForeground(Color.WHITE);
			key05FbButton.setBackground(Color.BLACK);
			key05FbButton.setBounds(98, 133, 32, 32);
			key05FbButton.setMargin(new Insets(2, 2, 2, 2));
			key05FbButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/z.gif")));
			
			key05FbButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x05, 0xFB);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x05, 0xFB);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});									
		}
		
		return key05FbButton;
	}
	
	private JButton getKey04FbButton() {
		if (key04FbButton == null) {
			key04FbButton = new JButton();
			key04FbButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key04FbButton.setForeground(Color.WHITE);
			key04FbButton.setBackground(Color.BLACK);
			key04FbButton.setBounds(139, 133, 32, 32);
			key04FbButton.setMargin(new Insets(2, 2, 2, 2));
			key04FbButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/x.gif")));
			
			key04FbButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x04, 0xFB);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x04, 0xFB);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});									
		}
		return key04FbButton;
	}
	
	private JButton getKey03FbButton() {
		if (key03FbButton == null) {
			key03FbButton = new JButton();
			key03FbButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key03FbButton.setForeground(Color.WHITE);
			key03FbButton.setBackground(Color.BLACK);
			key03FbButton.setBounds(180, 133, 32, 32);
			key03FbButton.setMargin(new Insets(2, 2, 2, 2));
			key03FbButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/c.gif")));
			
			key03FbButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x03, 0xFB);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x03, 0xFB);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});									
		}
		
		return key03FbButton;
	}
	
	private JButton getKey02FbButton() {
		if (key02FbButton == null) {
			key02FbButton = new JButton();
			key02FbButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key02FbButton.setForeground(Color.WHITE);
			key02FbButton.setBackground(Color.BLACK);
			key02FbButton.setBounds(222, 133, 32, 32);
			key02FbButton.setMargin(new Insets(2, 2, 2, 2));
			key02FbButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/v.gif")));
			
			key02FbButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x02, 0xFB);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x02, 0xFB);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});									
		}
		return key02FbButton;
	}
	
	private JButton getKey01FbButton() {
		if (key01FbButton == null) {
			key01FbButton = new JButton();
			key01FbButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key01FbButton.setForeground(Color.WHITE);
			key01FbButton.setBackground(Color.BLACK);
			key01FbButton.setBounds(263, 133, 32, 32);
			key01FbButton.setMargin(new Insets(2, 2, 2, 2));
			key01FbButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/b.gif")));
			
			key01FbButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x01, 0xFB);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x01, 0xFB);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});									
		}
		
		return key01FbButton;
	}
	
	private JButton getKey00FbButton()
	{
		if (key00FbButton == null) {
			key00FbButton = new JButton();
			key00FbButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key00FbButton.setForeground(Color.WHITE);
			key00FbButton.setBackground(Color.BLACK);
			key00FbButton.setBounds(305, 133, 32, 32);
			key00FbButton.setMargin(new Insets(2, 2, 2, 2));
			key00FbButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/n.gif")));
			
			key00FbButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x00, 0xFB);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x00, 0xFB);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});									
		}
		
		return key00FbButton;
	}
	
	private JButton getKey04FdButton() {
		if (key04FdButton == null) {
			key04FdButton = new JButton();
			key04FdButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key04FdButton.setForeground(Color.WHITE);
			key04FdButton.setBackground(Color.BLACK);
			key04FdButton.setBounds(347, 133, 32, 32);
			key04FdButton.setMargin(new Insets(2, 2, 2, 2));
			key04FdButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/m.gif")));
			
			key04FdButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x04, 0xFD);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x04, 0xFD);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});									
		}
		return key04FdButton;
	}
	
	private JButton getKey06FbButton()
	{
		if (key06FbButton == null) {
			key06FbButton = new JButton();
			key06FbButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key06FbButton.setForeground(Color.WHITE);
			key06FbButton.setBackground(Color.BLACK);
			key06FbButton.setBounds(389, 133, 32, 32);
			key06FbButton.setMargin(new Insets(2, 2, 2, 2));
			key06FbButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/uk/key06fb.gif")));
			
			key06FbButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x06, 0xFB);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x06, 0xFB);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});												
		}
		return key06FbButton;
	}
	
	private JButton getKey07FbButton() {
		if (key07FbButton == null) {
			key07FbButton = new JButton();
			key07FbButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key07FbButton.setForeground(Color.WHITE);
			key07FbButton.setBackground(Color.BLACK);
			key07FbButton.setBounds(431, 133, 32, 32);
			key07FbButton.setMargin(new Insets(2, 2, 2, 2));
			key07FbButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/uk/key07fb.gif")));
			
			key07FbButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x07, 0xFB);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x07, 0xFB);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});												
		}
		
		return key07FbButton;
	}
	
	private JButton getKey07FdButton()
	{
		if (key07FdButton == null) {
			key07FdButton = new JButton();
			key07FdButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key07FdButton.setForeground(Color.WHITE);
			key07FdButton.setBackground(Color.BLACK);
			key07FdButton.setBounds(473, 133, 32, 32);
			key07FdButton.setMargin(new Insets(2, 2, 2, 2));
			key07FdButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/uk/key07fd.gif")));
			
			key07FdButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x07, 0xFD);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x07, 0xFD);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});												
		}
		
		return key07FdButton;
	}
	
	private JToggleButton getRightShiftKeyButton()
	{
		if (rightShiftKeyButton == null) {
			rightShiftKeyButton = new JToggleButton();		
			rightShiftKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			rightShiftKeyButton.setForeground(Color.WHITE);
			rightShiftKeyButton.setBackground(Color.BLACK);
			rightShiftKeyButton.setBounds(516, 133, 82, 32);
			rightShiftKeyButton.setMargin(new Insets(2, 24, 2, 10));
			rightShiftKeyButton.setAlignmentX(Component.CENTER_ALIGNMENT);
			rightShiftKeyButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/shift.gif")));
			
			rightShiftKeyButton.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					if (rightShiftKeyButton.isSelected() == true) {
						Z88Keyboard.getInstance().pressZ88key(0x07, 0x7F);
					} else {
						Z88Keyboard.getInstance().releaseZ88key(0x07, 0x7F);						
					}
					getZ88Display().grabFocus();
				}
			});			
		}
		return rightShiftKeyButton;
	}
	
	private JButton getUpArrowKeyButton() {
		if (upArrowKeyButton == null) {
			upArrowKeyButton = new JButton();
			upArrowKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			upArrowKeyButton.setForeground(Color.WHITE);
			upArrowKeyButton.setBackground(Color.BLACK);
			upArrowKeyButton.setBounds(609, 133, 32, 32);
			upArrowKeyButton.setMargin(new Insets(2, 1, 2, 1));
			upArrowKeyButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/arrowup.gif")));
			
			upArrowKeyButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x01, 0xBF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x01, 0xBF);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																								
		}
		return upArrowKeyButton;
	}
	
	private JButton getIndexKeyButton() {
		if (indexKeyButton == null) {
			indexKeyButton = new JButton();
			indexKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			indexKeyButton.setForeground(Color.WHITE);
			indexKeyButton.setBackground(Color.BLACK);
			indexKeyButton.setBounds(7, 174, 32, 32);
			indexKeyButton.setMargin(new Insets(2, 2, 2, 2));
			indexKeyButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/index.gif")));
			
			indexKeyButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x07, 0xEF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x07, 0xEF);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																					
		}
		
		return indexKeyButton;
	}
	
	private JButton getMenuKeyButton() {
		if (menuKeyButton == null) {
			menuKeyButton = new JButton();
			menuKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			menuKeyButton.setForeground(Color.WHITE);
			menuKeyButton.setBackground(Color.BLACK);
			menuKeyButton.setBounds(48, 174, 32, 32);
			menuKeyButton.setMargin(new Insets(2, 2, 2, 2));
			menuKeyButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/menu.gif")));
			
			menuKeyButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x06, 0xF7);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x06, 0xF7);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																		
		}
		return menuKeyButton;
	}
	
	private JButton getHelpKeyButton()
	{
		if (helpKeyButton == null) {
			helpKeyButton = new JButton();
			helpKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			helpKeyButton.setForeground(Color.WHITE);
			helpKeyButton.setBackground(Color.BLACK);
			helpKeyButton.setBounds(89, 174, 32, 32);
			helpKeyButton.setMargin(new Insets(2, 2, 2, 2));
			helpKeyButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/help.gif")));

			helpKeyButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x06, 0x7F);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x06, 0x7F);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});															
		}
		return helpKeyButton;
	}
	
	private JButton getSquareKeyButton()
	{
		if (squareKeyButton == null) {
			squareKeyButton = new JButton();
			squareKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			squareKeyButton.setForeground(Color.WHITE);
			squareKeyButton.setBackground(Color.BLACK);
			squareKeyButton.setBounds(130, 174, 32, 32);
			squareKeyButton.setMargin(new Insets(2, 2, 2, 2));
			squareKeyButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/square.gif")));
			
			squareKeyButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x07, 0xBF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x07, 0xBF);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});						
		}
		return squareKeyButton;
	}
	
	private JButton getSpaceKeyButton()
	{
		if (spaceKeyButton == null) {
			spaceKeyButton = new JButton();
			spaceKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			spaceKeyButton.setForeground(Color.WHITE);
			spaceKeyButton.setBackground(Color.BLACK);
			spaceKeyButton.setBounds(171, 174, 303, 32);
			spaceKeyButton.setMargin(new Insets(2, 22, 2, 10));
			spaceKeyButton.setAlignmentX(Component.CENTER_ALIGNMENT);
			
			spaceKeyButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x05, 0xBF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x05, 0xBF);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																											
			
		}
		return spaceKeyButton;
	}
	
	private JButton getCapslockKeyButton()
	{
		if (capslockKeyButton == null) {
			capslockKeyButton = new JButton();
			capslockKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			capslockKeyButton.setForeground(Color.WHITE);
			capslockKeyButton.setBackground(Color.BLACK);
			capslockKeyButton.setBounds(484, 174, 32, 32);
			capslockKeyButton.setMargin(new Insets(2, 2, 2, 2));
			capslockKeyButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/capslock.gif")));
			
			capslockKeyButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x07, 0xF7);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x07, 0xF7);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});									
		}
		return capslockKeyButton;
	}
	
	private JButton getDownArrowKeyButton() {
		if (downArrowKeyButton == null) {
			downArrowKeyButton = new JButton();
			downArrowKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			downArrowKeyButton.setForeground(Color.WHITE);
			downArrowKeyButton.setBackground(Color.BLACK);
			downArrowKeyButton.setBounds(609, 174, 32, 32);
			downArrowKeyButton.setMargin(new Insets(2, 1, 2, 1));
			downArrowKeyButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/arrowdwn.gif")));
			
			downArrowKeyButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x02, 0xBF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x02, 0xBF);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});									
		}
		return downArrowKeyButton;
	}
	
	private JButton getLeftArrowKeyButton()
	{
		if (leftArrowKeyButton == null) {
			leftArrowKeyButton = new JButton();
			leftArrowKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			leftArrowKeyButton.setForeground(Color.WHITE);
			leftArrowKeyButton.setBackground(Color.BLACK);
			leftArrowKeyButton.setBounds(526, 174, 32, 32);
			leftArrowKeyButton.setMargin(new Insets(2, 2, 2, 2));
			leftArrowKeyButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/arrowlft.gif")));

			leftArrowKeyButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x04, 0xBF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x04, 0xBF);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});									
		}
		return leftArrowKeyButton;
	}
	
	private JButton getRightArrowKeyButton()
	{
		if (rightArrowKeyButton == null) {
			rightArrowKeyButton = new JButton();
			rightArrowKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			rightArrowKeyButton.setForeground(Color.WHITE);
			rightArrowKeyButton.setBackground(Color.BLACK);
			rightArrowKeyButton.setBounds(567, 174, 32, 32);
			rightArrowKeyButton.setMargin(new Insets(2, 2, 2, 2));
			rightArrowKeyButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/arrowrgt.gif")));
			
			rightArrowKeyButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x03, 0xBF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x03, 0xBF);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});												
		}
		
		return rightArrowKeyButton;
	}
	
	private JPanel getZ88ScreenPanel() {
		if (z88ScreenPanel == null) {
			z88ScreenPanel = new JPanel();
			z88ScreenPanel.setPreferredSize(new Dimension(648, 68));
			z88ScreenPanel.setBackground(Color.GRAY);
			z88ScreenPanel.add(getZ88Display());
		}
		
		return z88ScreenPanel;
	}
	
	private JLabel getZ88Display() {
		if (z88Display == null) {
			z88Display = Z88display.getInstance();
			z88Display.setLayout(null);
			z88Display.setForeground(Color.WHITE);
			z88Display.setText("This is the Z88 Screen");
		}
		return z88Display;
	}
	
	private JToolBar getToolBar()	{
		if (toolBar == null) {
			toolBar = new JToolBar();
			toolBar.add(getToolBarButton1());
			toolBar.add(getToolBarButton2());
			toolBar.setVisible(false);
		}
		return toolBar;
	}
	
	private JButton getToolBarButton1()	{
		if (toolBarButton1 == null) {
			toolBarButton1 = new JButton();
			toolBarButton1.setText("New JButton");
		}
		return toolBarButton1;
	}
	
	private JButton getToolBarButton2()
	{
		if (toolBarButton2 == null) {
			toolBarButton2 = new JButton();
			toolBarButton2.setText("New JButton");
		}
		return toolBarButton2;
	}

	private JButton getEscKeyButton() {
		if (escKeyButton == null) {
			escKeyButton = new JButton();
			escKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			escKeyButton.setForeground(Color.WHITE);
			escKeyButton.setBackground(Color.BLACK);
			escKeyButton.setBounds(7, 7, 32, 32);
			escKeyButton.setPreferredSize(new Dimension(32, 32));
			escKeyButton.setMargin(new Insets(2, 2, 2, 2));
			escKeyButton.setAlignmentX(Component.CENTER_ALIGNMENT);
			escKeyButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/esc.gif")));
			
			escKeyButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x07, 0xDF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x07, 0xDF);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});					
		}
		
		return escKeyButton;
	}

	private JButton getNumKey1Button() {
		if (numKey1Button == null) {
			numKey1Button = new JButton();
			numKey1Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			numKey1Button.setForeground(Color.WHITE);
			numKey1Button.setBackground(Color.BLACK);
			numKey1Button.setBounds(50, 7, 32, 32);
			numKey1Button.setPreferredSize(new Dimension(32, 32));
			numKey1Button.setMargin(new Insets(2, 2, 2, 2));
			numKey1Button.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/uk/numkey1.gif")));
			numKey1Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x05, 0xDF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x05, 0xDF);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																														
		}
		
		return numKey1Button;
	}

	private JButton getNumKey2Button() {
		if (numKey2Button == null) {
			numKey2Button = new JButton();
			numKey2Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			numKey2Button.setForeground(Color.WHITE);
			numKey2Button.setBackground(Color.BLACK);
			numKey2Button.setBounds(93, 7, 32, 32);
			numKey2Button.setPreferredSize(new Dimension(32, 32));
			numKey2Button.setMargin(new Insets(2, 2, 2, 2));
			numKey2Button.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/uk/numkey2.gif")));
			numKey2Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x04, 0xDF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x04, 0xDF);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																														
		}
		
		return numKey2Button;
	}
	
	private JButton getNumKey3Button() {
		if (numKey3Button == null) {
			numKey3Button = new JButton();
			numKey3Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			numKey3Button.setForeground(Color.WHITE);
			numKey3Button.setBackground(Color.BLACK);
			numKey3Button.setBounds(136, 7, 32, 32);
			numKey3Button.setPreferredSize(new Dimension(32, 32));
			numKey3Button.setMargin(new Insets(2, 2, 2, 2));
			numKey3Button.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/uk/numkey3.gif")));
			numKey3Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x03, 0xDF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x03, 0xDF);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																														
		}
		
		return numKey3Button;
	}

	private JButton getNumKey4Button() {
		if (numKey4Button == null) {
			numKey4Button = new JButton();
			numKey4Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			numKey4Button.setForeground(Color.WHITE);
			numKey4Button.setBackground(Color.BLACK);
			numKey4Button.setBounds(179, 7, 32, 32);
			numKey4Button.setPreferredSize(new Dimension(32, 32));
			numKey4Button.setMargin(new Insets(2, 2, 2, 2));
			numKey4Button.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/uk/numkey4.gif")));
			numKey4Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x02, 0xDF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x02, 0xDF);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																														
		}
		
		return numKey4Button;
	}

	private JButton getNumKey5Button() {
		if (numKey5Button == null) {
			numKey5Button = new JButton();
			numKey5Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			numKey5Button.setForeground(Color.WHITE);
			numKey5Button.setBackground(Color.BLACK);
			numKey5Button.setBounds(222, 7, 32, 32);
			numKey5Button.setPreferredSize(new Dimension(32, 32));
			numKey5Button.setMargin(new Insets(2, 2, 2, 2));
			numKey5Button.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/uk/numkey5.gif")));
			numKey5Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x01, 0xDF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x01, 0xDF);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																														
		}
		
		return numKey5Button;
	}

	private JButton getNumKey6Button() {
		if (numKey6Button == null) {
			numKey6Button = new JButton();
			numKey6Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			numKey6Button.setForeground(Color.WHITE);
			numKey6Button.setBackground(Color.BLACK);
			numKey6Button.setBounds(265, 7, 32, 32);
			numKey6Button.setPreferredSize(new Dimension(32, 32));
			numKey6Button.setMargin(new Insets(2, 2, 2, 2));
			numKey6Button.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/uk/numkey6.gif")));
			numKey6Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x00, 0xDF);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x00, 0xDF);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																														
		}
		
		return numKey6Button;
	}

	private JButton getNumKey7Button() {
		if (numKey7Button == null) {
			numKey7Button = new JButton();
			numKey7Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			numKey7Button.setForeground(Color.WHITE);
			numKey7Button.setBackground(Color.BLACK);
			numKey7Button.setBounds(308, 7, 32, 32);
			numKey7Button.setPreferredSize(new Dimension(32, 32));
			numKey7Button.setMargin(new Insets(2, 2, 2, 2));
			numKey7Button.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/uk/numkey7.gif")));
			numKey7Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x00, 0xFD);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x00, 0xFD);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																														
		}
		
		return numKey7Button;
	}

	private JButton getNumKey8Button() {
		if (numKey8Button == null) {
			numKey8Button = new JButton();
			numKey8Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			numKey8Button.setForeground(Color.WHITE);
			numKey8Button.setBackground(Color.BLACK);
			numKey8Button.setBounds(351, 7, 32, 32);
			numKey8Button.setPreferredSize(new Dimension(32, 32));
			numKey8Button.setMargin(new Insets(2, 2, 2, 2));
			numKey8Button.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/uk/numkey8.gif")));
			numKey8Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x00, 0xFE);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x00, 0xFE);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																														
		}
		
		return numKey8Button;
	}
	
	private JButton getNumKey9Button() {
		if (numKey9Button == null) {
			numKey9Button = new JButton();
			numKey9Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			numKey9Button.setForeground(Color.WHITE);
			numKey9Button.setBackground(Color.BLACK);
			numKey9Button.setBounds(394, 7, 32, 32);
			numKey9Button.setPreferredSize(new Dimension(32, 32));
			numKey9Button.setMargin(new Insets(2, 2, 2, 2));
			numKey9Button.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/uk/numkey9.gif")));
			numKey9Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x03, 0xFE);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x03, 0xFE);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																														
		}
		
		return numKey9Button;
	}

	private JButton getNumKey0Button() {
		if (numKey0Button == null) {
			numKey0Button = new JButton();
			numKey0Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			numKey0Button.setForeground(Color.WHITE);
			numKey0Button.setBackground(Color.BLACK);
			numKey0Button.setBounds(437, 7, 32, 32);
			numKey0Button.setPreferredSize(new Dimension(32, 32));
			numKey0Button.setMargin(new Insets(2, 2, 2, 2));
			numKey0Button.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/uk/numkey0.gif")));
			numKey0Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x05, 0xFE);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x05, 0xFE);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																														
		}
		
		return numKey0Button;
	}
	
	private JButton getKey037fButton() {
		if (key037fButton == null) {
			key037fButton = new JButton();
			key037fButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key037fButton.setForeground(Color.WHITE);
			key037fButton.setBackground(Color.BLACK);
			key037fButton.setBounds(480, 7, 32, 32);
			key037fButton.setPreferredSize(new Dimension(32, 32));
			key037fButton.setMargin(new Insets(2, 2, 2, 2));
			key037fButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/uk/key037f.gif")));
			key037fButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x03, 0x7F);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x03, 0x7F);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																														
		}
		
		return key037fButton;
	}
	
	private JButton getKey027fButton() {
		if (key027fButton == null) {
			key027fButton = new JButton();
			key027fButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key027fButton.setForeground(Color.WHITE);
			key027fButton.setBackground(Color.BLACK);
			key027fButton.setBounds(523, 7, 32, 32);
			key027fButton.setPreferredSize(new Dimension(32, 32));
			key027fButton.setMargin(new Insets(2, 2, 2, 2));
			key027fButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/uk/key027f.gif")));
			key027fButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x02, 0x7F);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x02, 0x7F);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																														
		}
		
		return key027fButton;
	}
	
	private JButton getKey017fButton() {
		if (key017fButton == null) {
			key017fButton = new JButton();
			key017fButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key017fButton.setForeground(Color.WHITE);
			key017fButton.setBackground(Color.BLACK);
			key017fButton.setBounds(566, 7, 32, 32);
			key017fButton.setPreferredSize(new Dimension(32, 32));
			key017fButton.setMargin(new Insets(2, 2, 2, 2));
			key017fButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/uk/key017f.gif")));
			key017fButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x01, 0x7F);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x01, 0x7F);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																														
		}
		
		return key017fButton;
	}

	private JButton getDelKeyButton() {
		if (delKeyButton == null) {
			delKeyButton = new JButton();
			delKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			delKeyButton.setForeground(Color.WHITE);
			delKeyButton.setBackground(Color.BLACK);
			delKeyButton.setBounds(609, 7, 32, 32);
			delKeyButton.setPreferredSize(new Dimension(32, 32));
			delKeyButton.setMargin(new Insets(2, 2, 2, 2));
			delKeyButton.setIcon(new ImageIcon(Blink.getInstance().getClass().getResource("/pixel/keys/std/del.gif")));
			delKeyButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					Z88Keyboard.getInstance().pressZ88key(0x00, 0x7F);
				}
				public void mouseReleased(MouseEvent arg0) {
					Z88Keyboard.getInstance().releaseZ88key(0x00, 0x7F);
					getZ88Display().grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}				
			});																											
		}

		return delKeyButton;
	}
	
	public static void displayRtmMessage(final String msg) {
		Gui.getInstance().getRtmOutputArea().append("\n" + msg);
		Gui.getInstance().getRtmOutputArea().setCaretPosition(Gui.getInstance().getRtmOutputArea().getDocument().getLength());
	}
	
	private void addRtmMessagesPanel() {
		GridBagConstraints gridBagConstraints = new GridBagConstraints();
		gridBagConstraints.fill = GridBagConstraints.BOTH;
		gridBagConstraints.gridy = 3;
		gridBagConstraints.gridx = 0;
		getContentPane().add(getRtmOutputScrollPane(), gridBagConstraints);		
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
			jRtmOutputArea = new javax.swing.JTextArea(6,80);
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
		if(helpMenu == null) {		
			helpMenu = new javax.swing.JMenu();
			helpMenu.setText("Help");
			
			helpMenu.add(getUserManualMenuItem());
			helpMenu.add(getAboutOZvmMenuItem());			
		}
		
		return helpMenu;
	}
	
	private JMenuItem getUserManualMenuItem() {
		if (userManualMenuItem == null) {
			userManualMenuItem = new JMenuItem();
			userManualMenuItem.setMnemonic(KeyEvent.VK_U);
			userManualMenuItem.setText("User Manual");
			
			userManualMenuItem.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					try {
						HelpViewer hv = new HelpViewer(Blink.getInstance().getClass().getResource("/ozvm-manual.html"));
					} catch (IOException e1) {
						// TODO Auto-generated catch block
						e1.printStackTrace();
					}					
				}
			});
		}
		
		return userManualMenuItem;
	}
	
	private JMenuItem getAboutOZvmMenuItem() {
		if (aboutOZvmMenuItem == null) {
			aboutOZvmMenuItem = new JMenuItem();
			aboutOZvmMenuItem.setMnemonic(KeyEvent.VK_A);
			aboutOZvmMenuItem.setText("About");
		}
		return aboutOZvmMenuItem;
	}
	
	private JMenuBar getMainMenuBar() {
		if (menuBar == null) {
			menuBar = new JMenuBar();
			menuBar.setBorder(new EmptyBorder(0, 0, 0, 0));		
			menuBar.add(getFileMenu());
			menuBar.add(getKeyboardMenu());
			menuBar.add(getViewMenu());
			menuBar.add(getHelpMenu());
		}
		
		return menuBar;
	}

	private JMenu getFileMenu() {
		if (fileMenu == null) {
			fileMenu = new JMenu();
			fileMenu.setText("File");

			fileMenu.add(getFileDebugMenuItem());
			fileMenu.add(getFileExitMenuItem());			
		}
		
		return fileMenu;
	}
	
	private JMenuItem getFileDebugMenuItem() {
		if (fileDebugMenuItem == null) {
			fileDebugMenuItem = new JMenuItem();
			fileDebugMenuItem.setMnemonic(KeyEvent.VK_D);
			fileDebugMenuItem.setText("Debug Command Line");
			
			fileDebugMenuItem.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					if (OZvm.getInstance().getCommandLine() == null)
						OZvm.getInstance().commandLine(true);
					else {
						OZvm.getInstance().getCommandLine().getDebugGui().toFront();
					}
				}
			});
		}
		
		return fileDebugMenuItem;
	}
	
	private JMenuItem getFileExitMenuItem() {
		if (fileExitMenuItem == null) {
			fileExitMenuItem = new JMenuItem();
			fileExitMenuItem.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					System.exit(0);
				}
			});
			fileExitMenuItem.setMnemonic(KeyEvent.VK_E);
			fileExitMenuItem.setText("Exit");
		}
		
		return fileExitMenuItem;
	}
	
	private JMenu getViewMenu() {
		if (viewMenu == null) {
			viewMenu = new JMenu();
			viewMenu.setText("View");			
			viewMenu.add(getRtmMessagesMenuItem());
			viewMenu.add(getZ88keyboardMenuItem());			
		}
		return viewMenu;
	}
	
	public JCheckBoxMenuItem getRtmMessagesMenuItem() {
		if (rtmMessagesMenuItem == null) {
			rtmMessagesMenuItem = new JCheckBoxMenuItem();
			rtmMessagesMenuItem.setSelected(true);
			rtmMessagesMenuItem.setText("Runtime Messages");
			rtmMessagesMenuItem.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					displayRunTimeMessagesPane(rtmMessagesMenuItem.isSelected());
				}
			});
		}

		return rtmMessagesMenuItem;
	}
	
	public void displayRunTimeMessagesPane(boolean display) {
		if (display == true) {
			getContentPane().remove(getRtmOutputScrollPane());
			addRtmMessagesPanel();
		} else {
			getContentPane().remove(getRtmOutputScrollPane());			
		}
		Gui.this.pack();
		getZ88Display().grabFocus();		
	}

	public void displayZ88Keyboard(boolean display) {
		if (display == true) {
			getContentPane().remove(getKeyboardPanel());
			addKeyboardPanel();
		} else {
			getContentPane().remove(getKeyboardPanel());			
		}
		Gui.this.pack();
		getZ88Display().grabFocus();		
	}
	
	public JCheckBoxMenuItem getZ88keyboardMenuItem() {
		if (z88keyboardMenuItem == null) {
			z88keyboardMenuItem = new JCheckBoxMenuItem();
			z88keyboardMenuItem.setSelected(true);
			z88keyboardMenuItem.setText("Z88 Keyboard");
			z88keyboardMenuItem.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					displayZ88Keyboard(z88keyboardMenuItem.isSelected());
				}
			});
		}
		
		return z88keyboardMenuItem;
	}	

	private void addKeyboardPanel() {	
		GridBagConstraints gridBagConstraints = new GridBagConstraints();
		gridBagConstraints.fill = GridBagConstraints.HORIZONTAL;
		gridBagConstraints.anchor = GridBagConstraints.SOUTHWEST;
		gridBagConstraints.ipady = 213;
		gridBagConstraints.gridy = 6;
		gridBagConstraints.gridx = 0;
		getContentPane().add(getKeyboardPanel(), gridBagConstraints);		
	}
		
	private JPanel getKeyboardPanel() {
		if (keyboardPanel == null) {
			keyboardPanel = new JPanel();
			keyboardPanel.setBackground(Color.BLACK);
			keyboardPanel.setLayout(null);

			keyboardPanel.add(getEscKeyButton());
			keyboardPanel.add(getNumKey1Button());
			keyboardPanel.add(getNumKey2Button());
			keyboardPanel.add(getNumKey3Button());
			keyboardPanel.add(getNumKey4Button());
			keyboardPanel.add(getNumKey5Button());
			keyboardPanel.add(getNumKey6Button());
			keyboardPanel.add(getNumKey7Button());
			keyboardPanel.add(getNumKey8Button());
			keyboardPanel.add(getNumKey9Button());
			keyboardPanel.add(getNumKey0Button());
			keyboardPanel.add(getKey037fButton());
			keyboardPanel.add(getKey027fButton());
			keyboardPanel.add(getKey017fButton());
			keyboardPanel.add(getDelKeyButton());
			keyboardPanel.add(getTabKeyButton());
			keyboardPanel.add(getKey05EfButton());
			keyboardPanel.add(getKey04EfButton());
			keyboardPanel.add(getKey03EfButton());
			keyboardPanel.add(getKey02EfButton());
			keyboardPanel.add(getKey01EfButton());
			keyboardPanel.add(getKey00EfButton());
			keyboardPanel.add(getKey01FdButton());
			keyboardPanel.add(getKey01FeButton());
			keyboardPanel.add(getKey02FeButton());
			keyboardPanel.add(getKey04FeButton());
			keyboardPanel.add(getKey057fButton());
			keyboardPanel.add(getKey047fButton());
			keyboardPanel.add(getEnterKeyButton());
			keyboardPanel.add(getKey07FeButton());
			keyboardPanel.add(getDiamondKeyButton());
			keyboardPanel.add(getKey05F7Button());
			keyboardPanel.add(getKey04F7Button());
			keyboardPanel.add(getKey03F7Button());
			keyboardPanel.add(getKey02F7Button());
			keyboardPanel.add(getKey01F7Button());
			keyboardPanel.add(getKey00F7Button());
			keyboardPanel.add(getKey02FdButton());
			keyboardPanel.add(getKey03FdButton());
			keyboardPanel.add(getKey05FdButton());
			keyboardPanel.add(getKey06FdButton());
			keyboardPanel.add(getKey06FeButton());
			keyboardPanel.add(getLeftShiftKeyButton());
			keyboardPanel.add(getKey05FbButton());
			keyboardPanel.add(getKey04FbButton());
			keyboardPanel.add(getKey03FbButton());
			keyboardPanel.add(getKey02FbButton());
			keyboardPanel.add(getKey01FbButton());
			keyboardPanel.add(getKey00FbButton());
			keyboardPanel.add(getKey04FdButton());
			keyboardPanel.add(getKey06FbButton());
			keyboardPanel.add(getKey07FbButton());
			keyboardPanel.add(getKey07FdButton());
			keyboardPanel.add(getRightShiftKeyButton());
			keyboardPanel.add(getUpArrowKeyButton());
			keyboardPanel.add(getIndexKeyButton());
			keyboardPanel.add(getMenuKeyButton());
			keyboardPanel.add(getHelpKeyButton());
			keyboardPanel.add(getSquareKeyButton());
			keyboardPanel.add(getSpaceKeyButton());
			keyboardPanel.add(getCapslockKeyButton());
			keyboardPanel.add(getDownArrowKeyButton());
			keyboardPanel.add(getLeftArrowKeyButton());
			keyboardPanel.add(getRightArrowKeyButton());
		}
		
		return keyboardPanel;
	}
	
	
	private JMenu getKeyboardMenu() {
		if (keyboardMenu == null) {
			keyboardMenu = new JMenu();
			keyboardMenu.setText("Keyboard");
			keyboardMenu.add(getUkLayoutMenuItem());
			keyboardMenu.add(getDkLayoutMenuItem());
			keyboardMenu.add(getFrLayoutMenuItem());
			keyboardMenu.add(getSeLayoutMenuItem());
		}
		return keyboardMenu;
	}
	
	public JCheckBoxMenuItem getUkLayoutMenuItem() {
		if (ukLayoutMenuItem == null) {
			ukLayoutMenuItem = new JCheckBoxMenuItem();
			ukLayoutMenuItem.setText("US/UK Layout");
			ukLayoutMenuItem.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					Z88Keyboard.getInstance().setKeyboardLayout(Z88Keyboard.COUNTRY_EN);
					getZ88Display().grabFocus();
				}
			});

			kbLayoutButtonGroup.add(ukLayoutMenuItem);
		}
		return ukLayoutMenuItem;
	}
	
	public JCheckBoxMenuItem getDkLayoutMenuItem() {
		if (dkLayoutMenuItem == null) {
			dkLayoutMenuItem = new JCheckBoxMenuItem();
			dkLayoutMenuItem.setText("Danish Layout");
			dkLayoutMenuItem.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					Z88Keyboard.getInstance().setKeyboardLayout(Z88Keyboard.COUNTRY_DK);
					getZ88Display().grabFocus();
				}
			});

			kbLayoutButtonGroup.add(dkLayoutMenuItem);
		}
		return dkLayoutMenuItem;
	}
	
	public JCheckBoxMenuItem getFrLayoutMenuItem() {
		if (frLayoutMenuItem == null) {
			frLayoutMenuItem = new JCheckBoxMenuItem();
			frLayoutMenuItem.setText("French Layout");
			frLayoutMenuItem.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					Z88Keyboard.getInstance().setKeyboardLayout(Z88Keyboard.COUNTRY_FR);
					getZ88Display().grabFocus();
				}
			});
			
			kbLayoutButtonGroup.add(frLayoutMenuItem);
		}
		return frLayoutMenuItem;
	}
	
	public JCheckBoxMenuItem getSeLayoutMenuItem() {
		if (seLayoutMenuItem == null) {
			seLayoutMenuItem = new JCheckBoxMenuItem();
			seLayoutMenuItem.setText("Swedish/Finish Layout");
			seLayoutMenuItem.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					Z88Keyboard.getInstance().setKeyboardLayout(Z88Keyboard.COUNTRY_SE);
					getZ88Display().grabFocus();
				}
			});
			
			kbLayoutButtonGroup.add(seLayoutMenuItem);
		}
		return seLayoutMenuItem;
	}	

	/**
	 * This method initializes the main z88 window with screen menus,
	 * runtime messages and keyboard.
	 */
	private void initialize() {
		getContentPane().setLayout(new GridBagLayout());

		setJMenuBar(getMainMenuBar());
								
		final GridBagConstraints gridBagConstraints_1 = new GridBagConstraints();
		gridBagConstraints_1.fill = GridBagConstraints.HORIZONTAL;
		gridBagConstraints_1.gridy = 0;
		gridBagConstraints_1.gridx = 0;
		getContentPane().add(getToolBar(), gridBagConstraints_1);

		final GridBagConstraints gridBagConstraints = new GridBagConstraints();
		gridBagConstraints.ipady = 5;
		gridBagConstraints.insets = new Insets(0, 0, 0, 0);
		gridBagConstraints.fill = GridBagConstraints.BOTH;
		gridBagConstraints.gridy = 1;
		gridBagConstraints.gridx = 0;
		getContentPane().add(getZ88ScreenPanel(), gridBagConstraints);

		addRtmMessagesPanel();
		addKeyboardPanel();
						
		this.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		this.setTitle("OZvm V" + OZvm.VERSION);
		this.setResizable(false);
		this.pack();
		this.setVisible(true);
		
		this.addWindowListener(new java.awt.event.WindowAdapter() {
			public void windowClosing(java.awt.event.WindowEvent e) {
				System.exit(0);
			}
		});		
	}
}
