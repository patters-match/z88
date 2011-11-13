/*
 * RubberKeyboard.java
 * This	file is	part of	OZvm.
 *
 * OZvm	is free	software; you can redistribute it and/or modify	it under the terms of the
 * GNU General Public License as published by the Free Software	Foundation;
 * either version 2, or	(at your option) any later version.
 * OZvm	is distributed in the hope that	it will	be useful, but WITHOUT ANY WARRANTY;
 * without even	the implied warranty of	MERCHANTABILITY	or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * You should have received a copy of the GNU General Public License along with	OZvm;
 * see the file	COPYING. If not, write to the
 * Free	Software Foundation, Inc., 59 Temple Place - Suite 330,	Boston,	MA 02111-1307, USA.
 *
 * @author <A HREF="mailto:gbs@users.sourceforge.net">Gunther Strube</A>
 *
 */
package net.sourceforge.z88;

import java.awt.Color;
import java.awt.Component;
import java.awt.Dimension;
import java.awt.Insets;
import java.awt.LayoutManager;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;
import java.util.Hashtable;

import javax.swing.BorderFactory;
import javax.swing.ImageIcon;
import javax.swing.JButton;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JToggleButton;
import javax.swing.border.BevelBorder;

import com.imagero.util.ThreadManager;

/**
 * Display of the Z88 Rubber Keyboard.
 */
public class RubberKeyboard extends JPanel {
		
	private Hashtable kbStdIcons;
	private Hashtable kbLanguageIconsUk; 
	private Hashtable kbLanguageIconsSe;
	private Hashtable kbLanguageIconsDk;
	private Hashtable kbLanguageIconsFr;

	private ThreadManager threadMgr;
	private JLabel display;
	private Z88Keyboard keyboard;
	
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
	private JToggleButton rightShiftKeyButton;
	private JToggleButton leftShiftKeyButton;

	public RubberKeyboard(LayoutManager arg0, boolean arg1) {
		super(arg0, arg1);
	}

	public RubberKeyboard(LayoutManager arg0) {
		super(arg0);
	}

	public RubberKeyboard(boolean arg0) {
		super(arg0);
	}

	public RubberKeyboard() {
		super();
		kbStdIcons = new Hashtable();
		kbLanguageIconsUk = new Hashtable(); 
		kbLanguageIconsSe = new Hashtable();
		kbLanguageIconsDk = new Hashtable();
		kbLanguageIconsFr = new Hashtable();

		threadMgr = new ThreadManager(1);

		display = Z88.getInstance().getDisplay();
		keyboard = Z88.getInstance().getKeyboard();
		
		setBackground(Color.BLACK);
		setLayout(null);

		cacheKeyStdIcons();
		cacheKeyIcons(kbLanguageIconsUk, "uk");
		cacheKeyIcons(kbLanguageIconsSe, "se");
		cacheKeyIcons(kbLanguageIconsDk, "dk");
		cacheKeyIcons(kbLanguageIconsFr, "fr");		
		
		// Row #1
		add(getEscKeyButton());
		add(getNumKey1Button());
		add(getNumKey2Button());
		add(getNumKey3Button());
		add(getNumKey4Button());
		add(getNumKey5Button());
		add(getNumKey6Button());
		add(getNumKey7Button());
		add(getNumKey8Button());
		add(getNumKey9Button());
		add(getNumKey0Button());
		add(getKey037fButton());
		add(getKey027fButton());
		add(getKey017fButton());
		add(getDelKeyButton());

		// Row #2
		add(getTabKeyButton());
		add(getKey05EfButton());
		add(getKey04EfButton());
		add(getKey03EfButton());
		add(getKey02EfButton());
		add(getKey01EfButton());
		add(getKey00EfButton());
		add(getKey01FdButton());
		add(getKey01FeButton());
		add(getKey02FeButton());
		add(getKey04FeButton());
		add(getKey057fButton());
		add(getKey047fButton());
		add(getEnterKeyButton());
		
		// Row #3		
		add(getKey07FeButton());
		add(getDiamondKeyButton());
		add(getKey05F7Button());
		add(getKey04F7Button());
		add(getKey03F7Button());
		add(getKey02F7Button());
		add(getKey01F7Button());
		add(getKey00F7Button());
		add(getKey02FdButton());
		add(getKey03FdButton());
		add(getKey05FdButton());
		add(getKey06FdButton());
		add(getKey06FeButton());

		// Row #4
		add(getLeftShiftKeyButton());
		add(getKey05FbButton());
		add(getKey04FbButton());
		add(getKey03FbButton());
		add(getKey02FbButton());
		add(getKey01FbButton());
		add(getKey00FbButton());
		add(getKey04FdButton());
		add(getKey06FbButton());
		add(getKey07FbButton());
		add(getKey07FdButton());
		add(getRightShiftKeyButton());		
		add(getUpArrowKeyButton());
		
		// Row #5		
		add(getIndexKeyButton());
		add(getMenuKeyButton());
		add(getHelpKeyButton());
		add(getSquareKeyButton());
		add(getSpaceKeyButton());
		add(getCapslockKeyButton());
		add(getLeftArrowKeyButton());
		add(getRightArrowKeyButton());		
		add(getDownArrowKeyButton());
	}

	// Row #1
	private JButton getEscKeyButton() {
		if (escKeyButton == null) {
			escKeyButton = new JButton();
			escKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			escKeyButton.setForeground(Color.WHITE);
			escKeyButton.setBackground(Color.BLACK);
			escKeyButton.setBounds(4, 7, 32, 32);
			escKeyButton.setPreferredSize(new Dimension(32, 32));
			escKeyButton.setMargin(new Insets(2, 2, 2, 2));
			escKeyButton.setAlignmentX(Component.CENTER_ALIGNMENT);
			escKeyButton.setIcon((ImageIcon) kbStdIcons.get("esc"));

			escKeyButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x07, 0xDF);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x07, 0xDF);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return escKeyButton;
	}

	// Row #1
	private JButton getNumKey1Button() {
		if (numKey1Button == null) {
			numKey1Button = new JButton();
			numKey1Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			numKey1Button.setForeground(Color.WHITE);
			numKey1Button.setBackground(Color.BLACK);
			numKey1Button.setBounds(47, 7, 32, 32);
			numKey1Button.setPreferredSize(new Dimension(32, 32));
			numKey1Button.setMargin(new Insets(2, 2, 2, 2));

			numKey1Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x05, 0xDF);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x05, 0xDF);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return numKey1Button;
	}

	// Row #1
	private JButton getNumKey2Button() {
		if (numKey2Button == null) {
			numKey2Button = new JButton();
			numKey2Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			numKey2Button.setForeground(Color.WHITE);
			numKey2Button.setBackground(Color.BLACK);
			numKey2Button.setBounds(90, 7, 32, 32);
			numKey2Button.setPreferredSize(new Dimension(32, 32));
			numKey2Button.setMargin(new Insets(2, 2, 2, 2));

			numKey2Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x04, 0xDF);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x04, 0xDF);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return numKey2Button;
	}

	// Row #1
	private JButton getNumKey3Button() {
		if (numKey3Button == null) {
			numKey3Button = new JButton();
			numKey3Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			numKey3Button.setForeground(Color.WHITE);
			numKey3Button.setBackground(Color.BLACK);
			numKey3Button.setBounds(133, 7, 32, 32);
			numKey3Button.setPreferredSize(new Dimension(32, 32));
			numKey3Button.setMargin(new Insets(2, 2, 2, 2));

			numKey3Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x03, 0xDF);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x03, 0xDF);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return numKey3Button;
	}

	// Row #1
	private JButton getNumKey4Button() {
		if (numKey4Button == null) {
			numKey4Button = new JButton();
			numKey4Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			numKey4Button.setForeground(Color.WHITE);
			numKey4Button.setBackground(Color.BLACK);
			numKey4Button.setBounds(176, 7, 32, 32);
			numKey4Button.setPreferredSize(new Dimension(32, 32));
			numKey4Button.setMargin(new Insets(2, 2, 2, 2));

			numKey4Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x02, 0xDF);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x02, 0xDF);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return numKey4Button;
	}

	// Row #1
	private JButton getNumKey5Button() {
		if (numKey5Button == null) {
			numKey5Button = new JButton();
			numKey5Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			numKey5Button.setForeground(Color.WHITE);
			numKey5Button.setBackground(Color.BLACK);
			numKey5Button.setBounds(219, 7, 32, 32);
			numKey5Button.setPreferredSize(new Dimension(32, 32));
			numKey5Button.setMargin(new Insets(2, 2, 2, 2));

			numKey5Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x01, 0xDF);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x01, 0xDF);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return numKey5Button;
	}

	// Row #1
	private JButton getNumKey6Button() {
		if (numKey6Button == null) {
			numKey6Button = new JButton();
			numKey6Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			numKey6Button.setForeground(Color.WHITE);
			numKey6Button.setBackground(Color.BLACK);
			numKey6Button.setBounds(262, 7, 32, 32);
			numKey6Button.setPreferredSize(new Dimension(32, 32));
			numKey6Button.setMargin(new Insets(2, 2, 2, 2));

			numKey6Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x00, 0xDF);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x00, 0xDF);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return numKey6Button;
	}

	// Row #1
	private JButton getNumKey7Button() {
		if (numKey7Button == null) {
			numKey7Button = new JButton();
			numKey7Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			numKey7Button.setForeground(Color.WHITE);
			numKey7Button.setBackground(Color.BLACK);
			numKey7Button.setBounds(305, 7, 32, 32);
			numKey7Button.setPreferredSize(new Dimension(32, 32));
			numKey7Button.setMargin(new Insets(2, 2, 2, 2));

			numKey7Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x00, 0xFD);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x00, 0xFD);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return numKey7Button;
	}

	// Row #1
	private JButton getNumKey8Button() {
		if (numKey8Button == null) {
			numKey8Button = new JButton();
			numKey8Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			numKey8Button.setForeground(Color.WHITE);
			numKey8Button.setBackground(Color.BLACK);
			numKey8Button.setBounds(348, 7, 32, 32);
			numKey8Button.setPreferredSize(new Dimension(32, 32));
			numKey8Button.setMargin(new Insets(2, 2, 2, 2));

			numKey8Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x00, 0xFE);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x00, 0xFE);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return numKey8Button;
	}

	// Row #1
	private JButton getNumKey9Button() {
		if (numKey9Button == null) {
			numKey9Button = new JButton();
			numKey9Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			numKey9Button.setForeground(Color.WHITE);
			numKey9Button.setBackground(Color.BLACK);
			numKey9Button.setBounds(391, 7, 32, 32);
			numKey9Button.setPreferredSize(new Dimension(32, 32));
			numKey9Button.setMargin(new Insets(2, 2, 2, 2));

			numKey9Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x03, 0xFE);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x03, 0xFE);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return numKey9Button;
	}

	// Row #1
	private JButton getNumKey0Button() {
		if (numKey0Button == null) {
			numKey0Button = new JButton();
			numKey0Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			numKey0Button.setForeground(Color.WHITE);
			numKey0Button.setBackground(Color.BLACK);
			numKey0Button.setBounds(434, 7, 32, 32);
			numKey0Button.setPreferredSize(new Dimension(32, 32));
			numKey0Button.setMargin(new Insets(2, 2, 2, 2));

			numKey0Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x05, 0xFE);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x05, 0xFE);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return numKey0Button;
	}

	// Row #1
	private JButton getKey037fButton() {
		if (key037fButton == null) {
			key037fButton = new JButton();
			key037fButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key037fButton.setForeground(Color.WHITE);
			key037fButton.setBackground(Color.BLACK);
			key037fButton.setBounds(477, 7, 32, 32);
			key037fButton.setPreferredSize(new Dimension(32, 32));
			key037fButton.setMargin(new Insets(2, 2, 2, 2));

			key037fButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x03, 0x7F);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x03, 0x7F);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return key037fButton;
	}

	// Row #1
	private JButton getKey027fButton() {
		if (key027fButton == null) {
			key027fButton = new JButton();
			key027fButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key027fButton.setForeground(Color.WHITE);
			key027fButton.setBackground(Color.BLACK);
			key027fButton.setBounds(520, 7, 32, 32);
			key027fButton.setPreferredSize(new Dimension(32, 32));
			key027fButton.setMargin(new Insets(2, 2, 2, 2));

			key027fButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x02, 0x7F);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x02, 0x7F);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return key027fButton;
	}

	// Row #1
	private JButton getKey017fButton() {
		if (key017fButton == null) {
			key017fButton = new JButton();
			key017fButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key017fButton.setForeground(Color.WHITE);
			key017fButton.setBackground(Color.BLACK);
			key017fButton.setBounds(563, 7, 32, 32);
			key017fButton.setPreferredSize(new Dimension(32, 32));
			key017fButton.setMargin(new Insets(2, 2, 2, 2));

			key017fButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x01, 0x7F);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x01, 0x7F);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return key017fButton;
	}

	// Row #1
	private JButton getDelKeyButton() {
		if (delKeyButton == null) {
			delKeyButton = new JButton();
			delKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			delKeyButton.setForeground(Color.WHITE);
			delKeyButton.setBackground(Color.BLACK);
			delKeyButton.setBounds(606, 7, 32, 32);
			delKeyButton.setPreferredSize(new Dimension(32, 32));
			delKeyButton.setMargin(new Insets(2, 2, 2, 2));
			delKeyButton.setIcon((ImageIcon) kbStdIcons.get("del"));
			
			delKeyButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x00, 0x7F);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x00, 0x7F);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return delKeyButton;
	}

	// Row #2
	private JButton getTabKeyButton()
	{
		if (tabKeyButton == null) {
			tabKeyButton = new JButton();
			tabKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			tabKeyButton.setForeground(Color.WHITE);
			tabKeyButton.setBackground(Color.BLACK);
			tabKeyButton.setBounds(4, 49, 56, 32);
			tabKeyButton.setPreferredSize(new Dimension(56, 32));
			tabKeyButton.setMargin(new Insets(2, 13, 2, 12));
			tabKeyButton.setAlignmentX(Component.CENTER_ALIGNMENT);
			tabKeyButton.setIcon((ImageIcon) kbStdIcons.get("tab"));

			tabKeyButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x06, 0xDF);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x06, 0xDF);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}
		return tabKeyButton;
	}

	// Row #2
	private JButton getKey05EfButton() {
		if (key05EfButton == null) {
			key05EfButton = new JButton();
			key05EfButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key05EfButton.setForeground(Color.WHITE);
			key05EfButton.setBackground(Color.BLACK);
			key05EfButton.setBounds(71, 49, 32, 32);
			key05EfButton.setPreferredSize(new Dimension(32, 32));
			key05EfButton.setMargin(new Insets(2, 2, 2, 2));
			key05EfButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x05, 0xEF);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x05, 0xEF);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return key05EfButton;
	}

	// Row #2
	private JButton getKey04EfButton() {
		if (key04EfButton == null) {
			key04EfButton = new JButton();
			key04EfButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key04EfButton.setForeground(Color.WHITE);
			key04EfButton.setBackground(Color.BLACK);
			key04EfButton.setBounds(112, 49, 32, 32);
			key04EfButton.setPreferredSize(new Dimension(32, 32));
			key04EfButton.setMargin(new Insets(2, 2, 2, 2));
			key04EfButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x04, 0xEF);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x04, 0xEF);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return key04EfButton;
	}

	// Row #2
	private JButton getKey03EfButton() {
		if (key03EfButton == null) {
			key03EfButton = new JButton();
			key03EfButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key03EfButton.setForeground(Color.WHITE);
			key03EfButton.setBackground(Color.BLACK);
			key03EfButton.setBounds(154, 49, 32, 32);
			key03EfButton.setPreferredSize(new Dimension(32, 32));
			key03EfButton.setMargin(new Insets(2, 2, 2, 2));

			key03EfButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x03, 0xEF);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x03, 0xEF);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return key03EfButton;
	}

	// Row #2
	private JButton getKey02EfButton() {
		if (key02EfButton == null) {
			key02EfButton = new JButton();
			key02EfButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key02EfButton.setForeground(Color.WHITE);
			key02EfButton.setBackground(Color.BLACK);
			key02EfButton.setBounds(196, 49, 32, 32);
			key02EfButton.setPreferredSize(new Dimension(32, 32));
			key02EfButton.setMargin(new Insets(2, 2, 2, 2));
			key02EfButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x02, 0xEF);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x02, 0xEF);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}
		return key02EfButton;
	}

	// Row #2
	private JButton getKey01EfButton() {
		if (key01EfButton == null) {
			key01EfButton = new JButton();
			key01EfButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key01EfButton.setForeground(Color.WHITE);
			key01EfButton.setBackground(Color.BLACK);
			key01EfButton.setBounds(238, 49, 32, 32);
			key01EfButton.setPreferredSize(new Dimension(32, 32));
			key01EfButton.setMargin(new Insets(2, 2, 2, 2));

			key01EfButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x01, 0xEF);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x01, 0xEF);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}
		return key01EfButton;
	}

	// Row #2
	private JButton getKey00EfButton() {
		if (key00EfButton == null) {
			key00EfButton = new JButton();
			key00EfButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key00EfButton.setForeground(Color.WHITE);
			key00EfButton.setBackground(Color.BLACK);
			key00EfButton.setBounds(280, 49, 32, 32);
			key00EfButton.setPreferredSize(new Dimension(32, 32));
			key00EfButton.setMargin(new Insets(2, 2, 2, 2));

			key00EfButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x00, 0xEF);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x00, 0xEF);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return key00EfButton;
	}
	
	// Row #2
	private JButton getKey01FdButton()
	{
		if (key01FdButton == null) {
			key01FdButton = new JButton();
			key01FdButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key01FdButton.setForeground(Color.WHITE);
			key01FdButton.setBackground(Color.BLACK);
			key01FdButton.setBounds(322, 49, 32, 32);
			key01FdButton.setPreferredSize(new Dimension(32, 32));
			key01FdButton.setMargin(new Insets(2, 2, 2, 2));

			key01FdButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x01, 0xFD);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x01, 0xFD);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return key01FdButton;
	}
	
	// Row #2
	private JButton getKey01FeButton() {
		if (key01FeButton == null) {
			key01FeButton = new JButton();
			key01FeButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key01FeButton.setForeground(Color.WHITE);
			key01FeButton.setBackground(Color.BLACK);
			key01FeButton.setBounds(363, 49, 32, 32);
			key01FeButton.setPreferredSize(new Dimension(32, 32));
			key01FeButton.setMargin(new Insets(2, 2, 2, 2));

			key01FeButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x01, 0xFE);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x01, 0xFE);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return key01FeButton;
	}

	// Row #2	
	private JButton getKey02FeButton()
	{
		if (key02FeButton == null) {
			key02FeButton = new JButton();
			key02FeButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key02FeButton.setForeground(Color.WHITE);
			key02FeButton.setBackground(Color.BLACK);
			key02FeButton.setBounds(406, 49, 32, 32);
			key02FeButton.setPreferredSize(new Dimension(32, 32));
			key02FeButton.setMargin(new Insets(2, 2, 2, 2));

			key02FeButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x02, 0xFE);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x02, 0xFE);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return key02FeButton;
	}

	// Row #2
	private JButton getKey04FeButton() {
		if (key04FeButton == null) {
			key04FeButton = new JButton();
			key04FeButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key04FeButton.setForeground(Color.WHITE);
			key04FeButton.setBackground(Color.BLACK);
			key04FeButton.setBounds(448, 49, 32, 32);
			key04FeButton.setPreferredSize(new Dimension(32, 32));
			key04FeButton.setMargin(new Insets(2, 2, 2, 2));

			key04FeButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x04, 0xFE);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x04, 0xFE);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return key04FeButton;
	}

	// Row #2	
	private JButton getKey057fButton() {
		if (key057fButton == null) {
			key057fButton = new JButton();
			key057fButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key057fButton.setForeground(Color.WHITE);
			key057fButton.setBackground(Color.BLACK);
			key057fButton.setBounds(490, 49, 32, 32);
			key057fButton.setPreferredSize(new Dimension(32, 32));
			key057fButton.setMargin(new Insets(2, 2, 2, 2));

			key057fButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x05, 0x7F);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x05, 0x7F);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return key057fButton;
	}
	
	// Row #2	
	private JButton getKey047fButton() {
		if (key047fButton == null) {
			key047fButton = new JButton();
			key047fButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key047fButton.setForeground(Color.WHITE);
			key047fButton.setBackground(Color.BLACK);
			key047fButton.setBounds(532, 49, 32, 32);
			key047fButton.setPreferredSize(new Dimension(32, 32));
			key047fButton.setMargin(new Insets(2, 2, 2, 2));

			key047fButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x04, 0x7F);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x04, 0x7F);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}
		return key047fButton;
	}
	
	// Row #2
	private JButton getEnterKeyButton() {
		if (enterKeyButton == null) {
			enterKeyButton = new JButton();
			enterKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			enterKeyButton.setForeground(Color.WHITE);
			enterKeyButton.setBackground(Color.BLACK);
			enterKeyButton.setBounds(581, 49, 57, 74);
			enterKeyButton.setIcon((ImageIcon) kbStdIcons.get("enter"));

			enterKeyButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x00, 0xBF);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x00, 0xBF);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}
		return enterKeyButton;
	}


	// Row #3	
	private JButton getDiamondKeyButton() {
		if (diamondKeyButton == null) {
			diamondKeyButton = new JButton();
			diamondKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			diamondKeyButton.setForeground(Color.WHITE);
			diamondKeyButton.setBackground(Color.BLACK);
			diamondKeyButton.setBounds(4, 91, 63, 32);
			diamondKeyButton.setMargin(new Insets(2, 22, 2, 10));
			diamondKeyButton.setAlignmentX(Component.CENTER_ALIGNMENT);
			diamondKeyButton.setIcon((ImageIcon) kbStdIcons.get("diamond"));

			diamondKeyButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x06, 0xEF);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x06, 0xEF);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}
		return diamondKeyButton;
	}

	// Row #3		
	private JButton getKey05F7Button() {
		if (key05F7Button == null) {
			key05F7Button = new JButton();
			key05F7Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key05F7Button.setForeground(Color.WHITE);
			key05F7Button.setBackground(Color.BLACK);
			key05F7Button.setBounds(76, 91, 32, 32);
			key05F7Button.setMargin(new Insets(2, 2, 2, 2));

			key05F7Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x05, 0xF7);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x05, 0xF7);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return key05F7Button;
	}

	// Row #3	
	private JButton getKey04F7Button() {
		if (key04F7Button == null) {
			key04F7Button = new JButton();
			key04F7Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key04F7Button.setForeground(Color.WHITE);
			key04F7Button.setBackground(Color.BLACK);
			key04F7Button.setBounds(118, 91, 32, 32);
			key04F7Button.setMargin(new Insets(2, 2, 2, 2));

			key04F7Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x04, 0xF7);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x04, 0xF7);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return key04F7Button;
	}

	// Row #3	
	private JButton getKey03F7Button() {
		if (key03F7Button == null) {
			key03F7Button = new JButton();
			key03F7Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key03F7Button.setForeground(Color.WHITE);
			key03F7Button.setBackground(Color.BLACK);
			key03F7Button.setBounds(159, 91, 32, 32);
			key03F7Button.setMargin(new Insets(2, 2, 2, 2));

			key03F7Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x03, 0xF7);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x03, 0xF7);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return key03F7Button;
	}

	// Row #3	
	private JButton getKey02F7Button() {
		if (key02F7Button == null) {
			key02F7Button = new JButton();
			key02F7Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key02F7Button.setForeground(Color.WHITE);
			key02F7Button.setBackground(Color.BLACK);
			key02F7Button.setBounds(201, 91, 32, 32);
			key02F7Button.setMargin(new Insets(2, 2, 2, 2));

			key02F7Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x02, 0xF7);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x02, 0xF7);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return key02F7Button;
	}

	// Row #3	
	private JButton getKey01F7Button() {
		if (key01F7Button == null) {
			key01F7Button = new JButton();
			key01F7Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key01F7Button.setForeground(Color.WHITE);
			key01F7Button.setBackground(Color.BLACK);
			key01F7Button.setBounds(243, 91, 32, 32);
			key01F7Button.setMargin(new Insets(2, 2, 2, 2));

			key01F7Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x01, 0xF7);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x01, 0xF7);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return key01F7Button;
	}

	// Row #3	
	private JButton getKey00F7Button() {
		if (key00F7Button == null) {
			key00F7Button = new JButton();
			key00F7Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key00F7Button.setForeground(Color.WHITE);
			key00F7Button.setBackground(Color.BLACK);
			key00F7Button.setBounds(285, 91, 32, 32);
			key00F7Button.setMargin(new Insets(2, 2, 2, 2));

			key00F7Button.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x00, 0xF7);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x00, 0xF7);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return key00F7Button;
	}

	// Row #3	
	private JButton getKey02FdButton() {
		if (key02FdButton == null) {
			key02FdButton = new JButton();
			key02FdButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key02FdButton.setForeground(Color.WHITE);
			key02FdButton.setBackground(Color.BLACK);
			key02FdButton.setBounds(327, 91, 32, 32);
			key02FdButton.setMargin(new Insets(2, 2, 2, 2));

			key02FdButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x02, 0xFD);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x02, 0xFD);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return key02FdButton;
	}

	// Row #3	
	private JButton getKey03FdButton() {
		if (key03FdButton == null) {
			key03FdButton = new JButton();
			key03FdButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key03FdButton.setForeground(Color.WHITE);
			key03FdButton.setBackground(Color.BLACK);
			key03FdButton.setBounds(369, 91, 32, 32);
			key03FdButton.setMargin(new Insets(2, 2, 2, 2));

			key03FdButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x03, 0xFD);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x03, 0xFD);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return key03FdButton;
	}

	// Row #3	
	private JButton getKey05FdButton() {
		if (key05FdButton == null) {
			key05FdButton = new JButton();
			key05FdButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key05FdButton.setForeground(Color.WHITE);
			key05FdButton.setBackground(Color.BLACK);
			key05FdButton.setBounds(411, 91, 32, 32);
			key05FdButton.setMargin(new Insets(2, 2, 2, 2));

			key05FdButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x05, 0xFD);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x05, 0xFD);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return key05FdButton;
	}

	// Row #3	
	private JButton getKey06FdButton() {
		if (key06FdButton == null) {
			key06FdButton = new JButton();
			key06FdButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key06FdButton.setForeground(Color.WHITE);
			key06FdButton.setBackground(Color.BLACK);
			key06FdButton.setBounds(453, 91, 32, 32);
			key06FdButton.setMargin(new Insets(2, 2, 2, 2));

			key06FdButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x06, 0xFD);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x06, 0xFD);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return key06FdButton;
	}

	// Row #3	
	private JButton getKey06FeButton()
	{
		if (key06FeButton == null) {
			key06FeButton = new JButton();
			key06FeButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key06FeButton.setForeground(Color.WHITE);
			key06FeButton.setBackground(Color.BLACK);
			key06FeButton.setBounds(495, 91, 32, 32);
			key06FeButton.setMargin(new Insets(2, 2, 2, 2));

			key06FeButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x06, 0xFE);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x06, 0xFE);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}
		return key06FeButton;
	}

	// Row #3	
	private JButton getKey07FeButton() {
		if (key07FeButton == null) {
			key07FeButton = new JButton();
			key07FeButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key07FeButton.setForeground(Color.WHITE);
			key07FeButton.setBackground(Color.BLACK);
			key07FeButton.setBounds(538, 91, 32, 32);
			key07FeButton.setMargin(new Insets(2, 2, 2, 2));

			key07FeButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x07, 0xFE);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x07, 0xFE);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return key07FeButton;
	}
	
	// Row #4
	private JToggleButton getLeftShiftKeyButton() {
		if (leftShiftKeyButton == null) {
			leftShiftKeyButton = new JToggleButton();
			leftShiftKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			leftShiftKeyButton.setForeground(Color.WHITE);
			leftShiftKeyButton.setBackground(Color.BLACK);
			leftShiftKeyButton.setBounds(4, 133, 82, 32);
			leftShiftKeyButton.setMargin(new Insets(2, 22, 2, 10));
			leftShiftKeyButton.setAlignmentX(Component.CENTER_ALIGNMENT);
			leftShiftKeyButton.setIcon((ImageIcon) kbStdIcons.get("shift"));

			leftShiftKeyButton.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					if (leftShiftKeyButton.isSelected() == true) {
						keyboard.pressZ88key(0x06, 0xBF);
						leftShiftKeyButton.setIcon((ImageIcon) kbStdIcons.get("shift_pressed"));
					} else {
						keyboard.releaseZ88key(0x06, 0xBF);
						leftShiftKeyButton.setIcon((ImageIcon) kbStdIcons.get("shift"));
					}
					display.grabFocus();
				}
			});
		}
		return leftShiftKeyButton;
	}

	// Row #4
	private JButton getKey05FbButton() {
		if (key05FbButton == null) {
			key05FbButton = new JButton();
			key05FbButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key05FbButton.setForeground(Color.WHITE);
			key05FbButton.setBackground(Color.BLACK);
			key05FbButton.setBounds(95, 133, 32, 32);
			key05FbButton.setMargin(new Insets(2, 2, 2, 2));

			key05FbButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x05, 0xFB);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x05, 0xFB);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return key05FbButton;
	}

	// Row #4
	private JButton getKey04FbButton() {
		if (key04FbButton == null) {
			key04FbButton = new JButton();
			key04FbButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key04FbButton.setForeground(Color.WHITE);
			key04FbButton.setBackground(Color.BLACK);
			key04FbButton.setBounds(136, 133, 32, 32);
			key04FbButton.setMargin(new Insets(2, 2, 2, 2));

			key04FbButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x04, 0xFB);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x04, 0xFB);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}
		return key04FbButton;
	}

	// Row #4
	private JButton getKey03FbButton() {
		if (key03FbButton == null) {
			key03FbButton = new JButton();
			key03FbButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key03FbButton.setForeground(Color.WHITE);
			key03FbButton.setBackground(Color.BLACK);
			key03FbButton.setBounds(177, 133, 32, 32);
			key03FbButton.setMargin(new Insets(2, 2, 2, 2));

			key03FbButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x03, 0xFB);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x03, 0xFB);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return key03FbButton;
	}

	// Row #4
	private JButton getKey02FbButton() {
		if (key02FbButton == null) {
			key02FbButton = new JButton();
			key02FbButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key02FbButton.setForeground(Color.WHITE);
			key02FbButton.setBackground(Color.BLACK);
			key02FbButton.setBounds(219, 133, 32, 32);
			key02FbButton.setMargin(new Insets(2, 2, 2, 2));

			key02FbButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x02, 0xFB);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x02, 0xFB);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}
		return key02FbButton;
	}

	// Row #4
	private JButton getKey01FbButton() {
		if (key01FbButton == null) {
			key01FbButton = new JButton();
			key01FbButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key01FbButton.setForeground(Color.WHITE);
			key01FbButton.setBackground(Color.BLACK);
			key01FbButton.setBounds(260, 133, 32, 32);
			key01FbButton.setMargin(new Insets(2, 2, 2, 2));

			key01FbButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x01, 0xFB);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x01, 0xFB);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return key01FbButton;
	}

	// Row #4
	private JButton getKey00FbButton() {
		if (key00FbButton == null) {
			key00FbButton = new JButton();
			key00FbButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key00FbButton.setForeground(Color.WHITE);
			key00FbButton.setBackground(Color.BLACK);
			key00FbButton.setBounds(302, 133, 32, 32);
			key00FbButton.setMargin(new Insets(2, 2, 2, 2));

			key00FbButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x00, 0xFB);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x00, 0xFB);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return key00FbButton;
	}

	// Row #4
	private JButton getKey04FdButton() {
		if (key04FdButton == null) {
			key04FdButton = new JButton();
			key04FdButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key04FdButton.setForeground(Color.WHITE);
			key04FdButton.setBackground(Color.BLACK);
			key04FdButton.setBounds(344, 133, 32, 32);
			key04FdButton.setMargin(new Insets(2, 2, 2, 2));

			key04FdButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x04, 0xFD);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x04, 0xFD);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}
		return key04FdButton;
	}

	// Row #4
	private JButton getKey06FbButton() {
		if (key06FbButton == null) {
			key06FbButton = new JButton();
			key06FbButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key06FbButton.setForeground(Color.WHITE);
			key06FbButton.setBackground(Color.BLACK);
			key06FbButton.setBounds(386, 133, 32, 32);
			key06FbButton.setMargin(new Insets(2, 2, 2, 2));

			key06FbButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x06, 0xFB);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x06, 0xFB);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}
		return key06FbButton;
	}

	// Row #4
	private JButton getKey07FbButton() {
		if (key07FbButton == null) {
			key07FbButton = new JButton();
			key07FbButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key07FbButton.setForeground(Color.WHITE);
			key07FbButton.setBackground(Color.BLACK);
			key07FbButton.setBounds(428, 133, 32, 32);
			key07FbButton.setMargin(new Insets(2, 2, 2, 2));

			key07FbButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x07, 0xFB);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x07, 0xFB);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return key07FbButton;
	}

	// Row #4
	private JButton getKey07FdButton() {
		if (key07FdButton == null) {
			key07FdButton = new JButton();
			key07FdButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			key07FdButton.setForeground(Color.WHITE);
			key07FdButton.setBackground(Color.BLACK);
			key07FdButton.setBounds(470, 133, 32, 32);
			key07FdButton.setMargin(new Insets(2, 2, 2, 2));

			key07FdButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x07, 0xFD);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x07, 0xFD);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return key07FdButton;
	}

	// Row #4
	private JToggleButton getRightShiftKeyButton() {
		if (rightShiftKeyButton == null) {
			rightShiftKeyButton = new JToggleButton();
			rightShiftKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			rightShiftKeyButton.setForeground(Color.WHITE);
			rightShiftKeyButton.setBackground(Color.BLACK);
			rightShiftKeyButton.setBounds(513, 133, 82, 32);
			rightShiftKeyButton.setMargin(new Insets(2, 24, 2, 10));
			rightShiftKeyButton.setAlignmentX(Component.CENTER_ALIGNMENT);
			rightShiftKeyButton.setIcon((ImageIcon) kbStdIcons.get("shift"));

			rightShiftKeyButton.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					if (rightShiftKeyButton.isSelected() == true) {
						keyboard.pressZ88key(0x07, 0x7F);
						rightShiftKeyButton.setIcon((ImageIcon) kbStdIcons.get("shift_pressed"));
					} else {
						keyboard.releaseZ88key(0x07, 0x7F);
						rightShiftKeyButton.setIcon((ImageIcon) kbStdIcons.get("shift"));
					}
					display.grabFocus();
				}
			});
		}
		return rightShiftKeyButton;
	}

	// Row #4
	private JButton getUpArrowKeyButton() {
		if (upArrowKeyButton == null) {
			upArrowKeyButton = new JButton();
			upArrowKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			upArrowKeyButton.setForeground(Color.WHITE);
			upArrowKeyButton.setBackground(Color.BLACK);
			upArrowKeyButton.setBounds(606, 133, 32, 32);
			upArrowKeyButton.setMargin(new Insets(2, 1, 2, 1));
			upArrowKeyButton.setIcon((ImageIcon) kbStdIcons.get("arrowup"));

			upArrowKeyButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x01, 0xBF);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x01, 0xBF);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}
		return upArrowKeyButton;
	}

	// Row #5
	private JButton getIndexKeyButton() {
		if (indexKeyButton == null) {
			indexKeyButton = new JButton();
			indexKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			indexKeyButton.setForeground(Color.WHITE);
			indexKeyButton.setBackground(Color.BLACK);
			indexKeyButton.setBounds(4, 174, 32, 32);
			indexKeyButton.setMargin(new Insets(2, 2, 2, 2));
			indexKeyButton.setIcon((ImageIcon) kbStdIcons.get("index"));

			indexKeyButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x07, 0xEF);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x07, 0xEF);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return indexKeyButton;
	}

	// Row #5
	private JButton getMenuKeyButton() {
		if (menuKeyButton == null) {
			menuKeyButton = new JButton();
			menuKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			menuKeyButton.setForeground(Color.WHITE);
			menuKeyButton.setBackground(Color.BLACK);
			menuKeyButton.setBounds(45, 174, 32, 32);
			menuKeyButton.setMargin(new Insets(2, 2, 2, 2));
			menuKeyButton.setIcon((ImageIcon) kbStdIcons.get("menu"));

			menuKeyButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x06, 0xF7);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x06, 0xF7);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}
		return menuKeyButton;
	}

	// Row #5
	private JButton getHelpKeyButton() {
		if (helpKeyButton == null) {
			helpKeyButton = new JButton();
			helpKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			helpKeyButton.setForeground(Color.WHITE);
			helpKeyButton.setBackground(Color.BLACK);
			helpKeyButton.setBounds(86, 174, 32, 32);
			helpKeyButton.setMargin(new Insets(2, 2, 2, 2));
			helpKeyButton.setIcon((ImageIcon) kbStdIcons.get("help"));

			helpKeyButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x06, 0x7F);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x06, 0x7F);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}
		return helpKeyButton;
	}

	// Row #5
	private JButton getSquareKeyButton() {
		if (squareKeyButton == null) {
			squareKeyButton = new JButton();
			squareKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			squareKeyButton.setForeground(Color.WHITE);
			squareKeyButton.setBackground(Color.BLACK);
			squareKeyButton.setBounds(127, 174, 32, 32);
			squareKeyButton.setMargin(new Insets(2, 2, 2, 2));
			squareKeyButton.setIcon((ImageIcon) kbStdIcons.get("square"));

			squareKeyButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x07, 0xBF);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x07, 0xBF);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}
		return squareKeyButton;
	}

	// Row #5
	private JButton getSpaceKeyButton() {
		if (spaceKeyButton == null) {
			spaceKeyButton = new JButton();
			spaceKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			spaceKeyButton.setForeground(Color.WHITE);
			spaceKeyButton.setBackground(Color.BLACK);
			spaceKeyButton.setBounds(168, 174, 303, 32);
			spaceKeyButton.setMargin(new Insets(2, 22, 2, 10));
			spaceKeyButton.setIcon((ImageIcon) kbStdIcons.get("space"));
			spaceKeyButton.setAlignmentX(Component.CENTER_ALIGNMENT);

			spaceKeyButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x05, 0xBF);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x05, 0xBF);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});

		}
		return spaceKeyButton;
	}

	// Row #5
	private JButton getCapslockKeyButton() {
		if (capslockKeyButton == null) {
			capslockKeyButton = new JButton();
			capslockKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			capslockKeyButton.setForeground(Color.WHITE);
			capslockKeyButton.setBackground(Color.BLACK);
			capslockKeyButton.setBounds(481, 174, 32, 32);
			capslockKeyButton.setMargin(new Insets(2, 2, 2, 2));
			capslockKeyButton.setIcon((ImageIcon) kbStdIcons.get("capslock"));

			capslockKeyButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x07, 0xF7);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x07, 0xF7);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}
		return capslockKeyButton;
	}


	// Row #5
	private JButton getLeftArrowKeyButton() {
		if (leftArrowKeyButton == null) {
			leftArrowKeyButton = new JButton();
			leftArrowKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			leftArrowKeyButton.setForeground(Color.WHITE);
			leftArrowKeyButton.setBackground(Color.BLACK);
			leftArrowKeyButton.setBounds(523, 174, 32, 32);
			leftArrowKeyButton.setMargin(new Insets(2, 2, 2, 2));
			leftArrowKeyButton.setIcon((ImageIcon) kbStdIcons.get("arrowlft"));

			leftArrowKeyButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x04, 0xBF);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x04, 0xBF);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}
		return leftArrowKeyButton;
	}

	// Row #5
	private JButton getRightArrowKeyButton() {
		if (rightArrowKeyButton == null) {
			rightArrowKeyButton = new JButton();
			rightArrowKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			rightArrowKeyButton.setForeground(Color.WHITE);
			rightArrowKeyButton.setBackground(Color.BLACK);
			rightArrowKeyButton.setBounds(564, 174, 32, 32);
			rightArrowKeyButton.setMargin(new Insets(2, 2, 2, 2));
			rightArrowKeyButton.setIcon((ImageIcon) kbStdIcons.get("arrowrgt"));

			rightArrowKeyButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x03, 0xBF);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x03, 0xBF);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}

		return rightArrowKeyButton;
	}

	// Row #5
	private JButton getDownArrowKeyButton() {
		if (downArrowKeyButton == null) {
			downArrowKeyButton = new JButton();
			downArrowKeyButton.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			downArrowKeyButton.setForeground(Color.WHITE);
			downArrowKeyButton.setBackground(Color.BLACK);
			downArrowKeyButton.setBounds(606, 174, 32, 32);
			downArrowKeyButton.setMargin(new Insets(2, 1, 2, 1));
			downArrowKeyButton.setIcon((ImageIcon) kbStdIcons.get("arrowdwn"));

			downArrowKeyButton.addMouseListener(new MouseListener() {
				public void mousePressed(MouseEvent arg0) {
					keyboard.pressZ88key(0x02, 0xBF);
				}
				public void mouseReleased(MouseEvent arg0) {
					keyboard.releaseZ88key(0x02, 0xBF);
					display.grabFocus();
				}

				public void mouseClicked(MouseEvent arg0) {}
				public void mouseEntered(MouseEvent arg0) {}
				public void mouseExited(MouseEvent arg0) {}
			});
		}
		return downArrowKeyButton;
	}


	private void cacheKeyStdIcons() {
		String path = "/pixel/keys/std/";
		Class c = Z88.getInstance().getClass();

		kbStdIcons.put("del", new ImageIcon(c.getResource(path + "del.gif")));
		kbStdIcons.put("esc", new ImageIcon(c.getResource(path + "esc.gif")));
		kbStdIcons.put("tab", new ImageIcon(c.getResource(path + "tab.gif")));
		kbStdIcons.put("enter", new ImageIcon(c.getResource(path + "enter.gif")));
		kbStdIcons.put("diamond", new ImageIcon(c.getResource(path + "diamond.gif")));
		kbStdIcons.put("shift", new ImageIcon(c.getResource(path + "shift.gif")));
		kbStdIcons.put("shift_pressed", new ImageIcon(c.getResource(path + "shift_pressed.gif")));
		kbStdIcons.put("index", new ImageIcon(c.getResource(path + "index.gif")));
		kbStdIcons.put("menu", new ImageIcon(c.getResource(path + "menu.gif")));
		kbStdIcons.put("help", new ImageIcon(c.getResource(path + "help.gif")));
		kbStdIcons.put("square", new ImageIcon(c.getResource(path + "square.gif")));
		kbStdIcons.put("capslock", new ImageIcon(c.getResource(path + "capslock.gif")));
		kbStdIcons.put("arrowup", new ImageIcon(c.getResource(path + "arrowup.gif")));
		kbStdIcons.put("arrowdwn", new ImageIcon(c.getResource(path + "arrowdwn.gif")));
		kbStdIcons.put("arrowrgt", new ImageIcon(c.getResource(path + "arrowrgt.gif")));
		kbStdIcons.put("arrowlft", new ImageIcon(c.getResource(path + "arrowlft.gif")));
		kbStdIcons.put("space", new ImageIcon(c.getResource(path + "space.gif")));
		kbStdIcons.put("q", new ImageIcon(c.getResource(path + "q.gif")));
		kbStdIcons.put("w", new ImageIcon(c.getResource(path + "w.gif")));
		kbStdIcons.put("e", new ImageIcon(c.getResource(path + "e.gif")));
		kbStdIcons.put("r", new ImageIcon(c.getResource(path + "r.gif")));
		kbStdIcons.put("t", new ImageIcon(c.getResource(path + "t.gif")));
		kbStdIcons.put("y", new ImageIcon(c.getResource(path + "y.gif")));
		kbStdIcons.put("u", new ImageIcon(c.getResource(path + "u.gif")));
		kbStdIcons.put("i", new ImageIcon(c.getResource(path + "i.gif")));
		kbStdIcons.put("o", new ImageIcon(c.getResource(path + "o.gif")));
		kbStdIcons.put("p", new ImageIcon(c.getResource(path + "p.gif")));
		kbStdIcons.put("a", new ImageIcon(c.getResource(path + "a.gif")));
		kbStdIcons.put("s", new ImageIcon(c.getResource(path + "s.gif")));
		kbStdIcons.put("d", new ImageIcon(c.getResource(path + "d.gif")));
		kbStdIcons.put("f", new ImageIcon(c.getResource(path + "f.gif")));
		kbStdIcons.put("g", new ImageIcon(c.getResource(path + "g.gif")));
		kbStdIcons.put("h", new ImageIcon(c.getResource(path + "h.gif")));
		kbStdIcons.put("j", new ImageIcon(c.getResource(path + "j.gif")));
		kbStdIcons.put("k", new ImageIcon(c.getResource(path + "k.gif")));
		kbStdIcons.put("l", new ImageIcon(c.getResource(path + "l.gif")));
		kbStdIcons.put("z", new ImageIcon(c.getResource(path + "z.gif")));
		kbStdIcons.put("x", new ImageIcon(c.getResource(path + "x.gif")));
		kbStdIcons.put("c", new ImageIcon(c.getResource(path + "c.gif")));
		kbStdIcons.put("v", new ImageIcon(c.getResource(path + "v.gif")));
		kbStdIcons.put("b", new ImageIcon(c.getResource(path + "b.gif")));
		kbStdIcons.put("n", new ImageIcon(c.getResource(path + "n.gif")));
		kbStdIcons.put("m", new ImageIcon(c.getResource(path + "m.gif")));
	}
	
	private void cacheKeyIcons(Hashtable ht, String kbLanguageCountryCode) {
		String path = "/pixel/keys/" + kbLanguageCountryCode + "/";
		Class c = Z88.getInstance().getClass();
		
		ht.put("numkey1", new ImageIcon(c.getResource(path + "numkey1.gif")));
		ht.put("numkey2", new ImageIcon(c.getResource(path + "numkey2.gif")));
		ht.put("numkey3", new ImageIcon(c.getResource(path + "numkey3.gif")));
		ht.put("numkey4", new ImageIcon(c.getResource(path + "numkey4.gif")));
		ht.put("numkey5", new ImageIcon(c.getResource(path + "numkey5.gif")));
		ht.put("numkey6", new ImageIcon(c.getResource(path + "numkey6.gif")));
		ht.put("numkey7", new ImageIcon(c.getResource(path + "numkey7.gif")));
		ht.put("numkey8", new ImageIcon(c.getResource(path + "numkey8.gif")));
		ht.put("numkey9", new ImageIcon(c.getResource(path + "numkey9.gif")));
		ht.put("numkey0", new ImageIcon(c.getResource(path + "numkey0.gif")));
		ht.put("key037f", new ImageIcon(c.getResource(path + "key037f.gif")));
		ht.put("key027f", new ImageIcon(c.getResource(path + "key027f.gif")));
		ht.put("key017f", new ImageIcon(c.getResource(path + "key017f.gif")));
		ht.put("key057f", new ImageIcon(c.getResource(path + "key057f.gif")));
		ht.put("key047f", new ImageIcon(c.getResource(path + "key047f.gif")));
		ht.put("key07fe", new ImageIcon(c.getResource(path + "key07fe.gif")));
		ht.put("key06fd", new ImageIcon(c.getResource(path + "key06fd.gif")));
		ht.put("key06fe", new ImageIcon(c.getResource(path + "key06fe.gif")));
		ht.put("key06fb", new ImageIcon(c.getResource(path + "key06fb.gif")));
		ht.put("key07fb", new ImageIcon(c.getResource(path + "key07fb.gif")));
		ht.put("key07fd", new ImageIcon(c.getResource(path + "key07fd.gif")));
		if (kbLanguageCountryCode.compareTo("fr") == 0)
			ht.put("key04fd", new ImageIcon(c.getResource(path + "key04fd.gif")));
	}
	
	/**
	 * Define the icons on key buttons according to the current
	 * keyboard language code.
	 * 
	 * <PRE>
	 *	COUNTRY_US = 0;		// English/US Keyboard layout
	 *	COUNTRY_FR = 1;		// French Keyboard layout
	 *	COUNTRY_DE = 2;		// German Keyboard layout
	 *	COUNTRY_EN = 3;		// English/UK Keyboard layout
	 *	COUNTRY_DK = 4;		// Danish Keyboard layout
	 *	COUNTRY_SE = 5;		// Swedish Keyboard layout
	 *	COUNTRY_IT = 6;		// Italian Keyboard layout
	 *	COUNTRY_ES = 7;		// Spanish Keyboard layout
	 *	COUNTRY_JP = 8;		// Japanese Keyboard layout
	 *	COUNTRY_IS = 9;		// Icelandic Keyboard layout
	 *	COUNTRY_NO = 10;	// Norwegian Keyboard layout
	 *	COUNTRY_CH = 11;	// Swiss Keyboard layout 
	 * 	COUNTRY_TR = 12;	// Turkish Keyboard layout
	 *	COUNTRY_FI = 13;	// Finnish Keyboard layout
	 * </PRE>
	 * 
	 * The above constant are predefined in Z88Keyboard class.
	 */
	public void setKeyboardCountrySpecificIcons(final int kbl) {		
		threadMgr.addTask( new Runnable() {
			public void run() {
				Hashtable keyIcons;
				
				switch(kbl) {
					case Z88Keyboard.COUNTRY_UK:
					case Z88Keyboard.COUNTRY_US:
						keyIcons = kbLanguageIconsUk;
						break;
					
					// swedish/finish
					case Z88Keyboard.COUNTRY_SE:
						keyIcons = kbLanguageIconsSe;
						break;
						
					case Z88Keyboard.COUNTRY_DK:
						keyIcons = kbLanguageIconsDk;
						break;
					case Z88Keyboard.COUNTRY_FR:
						keyIcons = kbLanguageIconsFr;
						break;
					
					default:
						keyIcons = kbLanguageIconsUk;
				}
				
				getNumKey1Button().setIcon((ImageIcon) keyIcons.get("numkey1"));
				getNumKey2Button().setIcon((ImageIcon) keyIcons.get("numkey2"));
				getNumKey3Button().setIcon((ImageIcon) keyIcons.get("numkey3"));
				getNumKey4Button().setIcon((ImageIcon) keyIcons.get("numkey4"));
				getNumKey5Button().setIcon((ImageIcon) keyIcons.get("numkey5"));
				getNumKey6Button().setIcon((ImageIcon) keyIcons.get("numkey6"));
				getNumKey7Button().setIcon((ImageIcon) keyIcons.get("numkey7"));
				getNumKey8Button().setIcon((ImageIcon) keyIcons.get("numkey8"));
				getNumKey9Button().setIcon((ImageIcon) keyIcons.get("numkey9"));
				getNumKey0Button().setIcon((ImageIcon) keyIcons.get("numkey0"));
				getKey037fButton().setIcon((ImageIcon) keyIcons.get("key037f"));
				getKey027fButton().setIcon((ImageIcon) keyIcons.get("key027f"));
				getKey017fButton().setIcon((ImageIcon) keyIcons.get("key017f"));
				getKey03EfButton().setIcon((ImageIcon) kbStdIcons.get("e"));
				getKey02EfButton().setIcon((ImageIcon) kbStdIcons.get("r"));
				getKey01EfButton().setIcon((ImageIcon) kbStdIcons.get("t"));
				getKey00EfButton().setIcon((ImageIcon) kbStdIcons.get("y"));
				getKey01FdButton().setIcon((ImageIcon) kbStdIcons.get("u"));
				getKey01FeButton().setIcon((ImageIcon) kbStdIcons.get("i"));
				getKey02FeButton().setIcon((ImageIcon) kbStdIcons.get("o"));
				getKey04FeButton().setIcon((ImageIcon) kbStdIcons.get("p"));
				getKey057fButton().setIcon((ImageIcon) keyIcons.get("key057f"));
				getKey047fButton().setIcon((ImageIcon) keyIcons.get("key047f"));
				getKey07FeButton().setIcon((ImageIcon) keyIcons.get("key07fe"));
				getKey04F7Button().setIcon((ImageIcon) kbStdIcons.get("s"));
				getKey03F7Button().setIcon((ImageIcon) kbStdIcons.get("d"));
				getKey02F7Button().setIcon((ImageIcon) kbStdIcons.get("f"));
				getKey01F7Button().setIcon((ImageIcon) kbStdIcons.get("g"));
				getKey00F7Button().setIcon((ImageIcon) kbStdIcons.get("h"));
				getKey02FdButton().setIcon((ImageIcon) kbStdIcons.get("j"));
				getKey03FdButton().setIcon((ImageIcon) kbStdIcons.get("k"));
				getKey05FdButton().setIcon((ImageIcon) kbStdIcons.get("l"));
				getKey06FdButton().setIcon((ImageIcon) keyIcons.get("key06fd"));
				getKey06FeButton().setIcon((ImageIcon) keyIcons.get("key06fe"));
				getKey04FbButton().setIcon((ImageIcon) kbStdIcons.get("x"));
				getKey03FbButton().setIcon((ImageIcon) kbStdIcons.get("c"));
				getKey02FbButton().setIcon((ImageIcon) kbStdIcons.get("v"));
				getKey01FbButton().setIcon((ImageIcon) kbStdIcons.get("b"));
				getKey00FbButton().setIcon((ImageIcon) kbStdIcons.get("n"));
				
				if (kbl == Z88Keyboard.COUNTRY_FR) {
					getKey05EfButton().setIcon((ImageIcon) kbStdIcons.get("a"));
					getKey04EfButton().setIcon((ImageIcon) kbStdIcons.get("z"));
					getKey05F7Button().setIcon((ImageIcon) kbStdIcons.get("q"));
					getKey05FbButton().setIcon((ImageIcon) kbStdIcons.get("w"));
					getKey04FdButton().setIcon((ImageIcon) keyIcons.get("key04fd"));
				} else {
					getKey05EfButton().setIcon((ImageIcon) kbStdIcons.get("q"));
					getKey04EfButton().setIcon((ImageIcon) kbStdIcons.get("w"));
					getKey05F7Button().setIcon((ImageIcon) kbStdIcons.get("a"));
					getKey05FbButton().setIcon((ImageIcon) kbStdIcons.get("z"));
					getKey04FdButton().setIcon((ImageIcon) kbStdIcons.get("m"));
				}
				
				getKey06FbButton().setIcon((ImageIcon) keyIcons.get("key06fb"));
				getKey07FbButton().setIcon((ImageIcon) keyIcons.get("key07fb"));
				getKey07FdButton().setIcon((ImageIcon) keyIcons.get("key07fd"));
			}
		}); 		
	}	
}
