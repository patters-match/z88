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

import javax.swing.JFileChooser;
import javax.swing.JMenuBar;
import javax.swing.JMenu;
import javax.swing.JMenuItem;
import javax.swing.JScrollPane;
import javax.swing.JTextArea;
import javax.swing.JToolBar;
import javax.swing.JButton;
import javax.swing.border.EmptyBorder;
import java.awt.event.KeyEvent;
import java.awt.Insets;
import java.awt.Color;

import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;
import java.io.File;
import java.io.IOException;
import javax.swing.JCheckBoxMenuItem;
import javax.swing.ButtonGroup;

/**
 * The end user Gui (Main menu, screen, runtime messages, keyboard & slot management)
 */
public class Gui extends JFrame {

	private JMenuItem createSnapshotMenuItem;
	private JMenuItem loadSnapshotMenuItem;
	private static final class singletonContainer {
		static final Gui singleton = new Gui();
	}

	public static Gui getInstance() {
		return singletonContainer.singleton;
	}

	private Gui() {
		super();
		initialize();
	}

	private ButtonGroup kbLayoutButtonGroup = new ButtonGroup();
	private JCheckBoxMenuItem seLayoutMenuItem;
	private JCheckBoxMenuItem frLayoutMenuItem;
	private JCheckBoxMenuItem dkLayoutMenuItem;
	private JCheckBoxMenuItem ukLayoutMenuItem;
	private JMenu keyboardMenu;
	
	private JScrollPane jRtmOutputScrollPane = null;
	private JTextArea jRtmOutputArea = null;

	private JToolBar toolBar;
	private JButton toolBarButton1;
	private JButton toolBarButton2;
	private JLabel z88Display;

	private JPanel z88ScreenPanel;
	private RubberKeyboard keyboardPanel;

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

	private JToolBar getToolBar() {
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

			fileMenu.addSeparator();
			fileMenu.add(getLoadSnapshotMenuItem());
			fileMenu.add(getCreateSnapshotMenuItem());

			fileMenu.addSeparator();
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

	private RubberKeyboard getKeyboardPanel() {
		if (keyboardPanel == null) {
			keyboardPanel = new RubberKeyboard();
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
					getKeyboardPanel().setKeyboardCountrySpecificIcons("uk");
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
					getKeyboardPanel().setKeyboardCountrySpecificIcons("dk");
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
					getKeyboardPanel().setKeyboardCountrySpecificIcons("fr");
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
					getKeyboardPanel().setKeyboardCountrySpecificIcons("se");
					getZ88Display().grabFocus();
				}
			});

			kbLayoutButtonGroup.add(seLayoutMenuItem);
		}
		return seLayoutMenuItem;
	}

	private JMenuItem getLoadSnapshotMenuItem() {
		if (loadSnapshotMenuItem == null) {
			loadSnapshotMenuItem = new JMenuItem();
			loadSnapshotMenuItem.setText("Load snapshot");
			
			loadSnapshotMenuItem.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					SaveRestoreVM srVM = new SaveRestoreVM();  
					JFileChooser chooser = new JFileChooser(new File(System.getProperty("user.dir")));
					chooser.setDialogTitle("Load Z88 snaphot");
					chooser.setMultiSelectionEnabled(false);
					chooser.setFileSelectionMode(JFileChooser.FILES_ONLY);
					chooser.setFileFilter(srVM.getSnapshotFilter());
					Blink.getInstance().stopZ80Execution();
					
					int returnVal = chooser.showOpenDialog(getContentPane().getParent());
					if (returnVal == JFileChooser.APPROVE_OPTION) {
						String fileName = chooser.getSelectedFile().getAbsolutePath();
						
						if (srVM.loadSnapShot(fileName) == true)
							displayRtmMessage("Snapshot successfully installed from " + fileName);
						else {
							displayRtmMessage("Loading of snapshot '" + fileName + "' failed. Z88 preset to default system.");
					    	Memory.getInstance().setDefaultSystem();
					    	Blink.getInstance().reset();				
					    	Blink.getInstance().resetBlinkRegisters();							
						}					
					}					

					OZvm.getInstance().runZ80Engine(-1);
				}
			});
		}
		return loadSnapshotMenuItem;
	}
	
	private JMenuItem getCreateSnapshotMenuItem() {
		if (createSnapshotMenuItem == null) {
			createSnapshotMenuItem = new JMenuItem();
			createSnapshotMenuItem.setText("Create snapshot");
			
			createSnapshotMenuItem.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					SaveRestoreVM srVM = new SaveRestoreVM();  
					JFileChooser chooser = new JFileChooser(new File(System.getProperty("user.dir")));
					chooser.setDialogTitle("Create Z88 snaphot");
					chooser.setMultiSelectionEnabled(false);
					chooser.setFileSelectionMode(JFileChooser.FILES_ONLY);
					chooser.setFileFilter(srVM.getSnapshotFilter());
					chooser.setSelectedFile(new File(OZvm.defaultVmFile));
					Blink.getInstance().stopZ80Execution();
					
					int returnVal = chooser.showSaveDialog(getContentPane().getParent());
					if (returnVal == JFileChooser.APPROVE_OPTION) {
						String fileName = chooser.getSelectedFile().getAbsolutePath();
						try {
							srVM.storeSnapShot(fileName);
							displayRtmMessage("Snapshot successfully created in " + fileName);
						} catch (IOException e1) {
							displayRtmMessage("Creating snapshot '" + fileName + "' failed.");
						}						
					}					

					OZvm.getInstance().runZ80Engine(-1);
				}
			});
		}
		return createSnapshotMenuItem;
	}
	
	/**
	 * This method initializes the main z88 window with screen menus,
	 * runtime messages and keyboard.
	 */
	private void initialize() {
		getContentPane().setLayout(new GridBagLayout());

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
		getUkLayoutMenuItem().doClick();
		
		setJMenuBar(getMainMenuBar());

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
