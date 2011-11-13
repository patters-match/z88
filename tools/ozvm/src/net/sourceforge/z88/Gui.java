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
 *
 */

package net.sourceforge.z88;

import javax.swing.JFrame;
import java.awt.GridBagLayout;
import javax.swing.JPanel;
import java.awt.GridBagConstraints;
import java.awt.Dimension;

import javax.swing.ImageIcon;
import javax.swing.JFileChooser;
import javax.swing.JMenuBar;
import javax.swing.JMenu;
import javax.swing.JMenuItem;
import javax.swing.JOptionPane;
import javax.swing.JToolBar;
import javax.swing.KeyStroke;
import javax.swing.JButton;
import javax.swing.border.EmptyBorder;
import java.awt.event.KeyEvent;
import java.awt.BorderLayout;
import java.awt.Insets;
import java.awt.Color;
import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;
import java.io.File;
import java.io.IOException;

import javax.swing.JCheckBoxMenuItem;
import javax.swing.ButtonGroup;

import net.sourceforge.z88.screen.Z88display;

/**
 * The end user Gui (Main menu, screen, runtime messages, keyboard & slot management)
 */
public class Gui extends JFrame {
	
	private static final String aboutDialogText = 	
		"<html><center>" + 
		"<h2>OZvm " + OZvm.VERSION + "</h2>" +
		"<h3>The Z88 emulator & debugging environment</h3>" +
		"Open Source (GPL) software by Gunther Strube<br>" + 
		"<tt>gbs@users.sourceforge.net</tt><br><br>" +
		"<tt>http://z88.sf.net</tt>" +
		"</center></html>";


	private Blink blink; 
	private boolean fullScreenMode;
	
	private ButtonGroup kbLayoutButtonGroup;
	private ButtonGroup scrRefreshRateButtonGroup;
	
	private JToolBar toolBar;
	private JButton toolBarButton1;
	private JButton toolBarButton2;
	private Z88display z88Display;

	private JPanel z88ScreenPanel;
	private RubberKeyboard keyboardPanel;
	private Slots slotsPanel;

	private JMenuBar menuBar;
	private JMenu fileMenu;
	private JMenu helpMenu;
	private JMenu viewMenu;
	private JMenu z88Menu;
	private JMenu screenMenu;
	private JMenu keyboardMenu;
	private JMenu screenRefrashRateMenu;
	private JMenuItem fileExitMenuItem;
	private JMenuItem fileDebugMenuItem;
	private JMenuItem aboutOZvmMenuItem;
	private JMenuItem createSnapshotMenuItem;
	private JMenuItem loadSnapshotMenuItem;
	private JMenuItem softResetMenuItem;
	private JMenuItem hardResetMenuItem;
	private JMenuItem userManualMenuItem;
	private JMenuItem gifMovieMenuItem;
	private JMenuItem screenSnapshotMenuItem;
	private JMenuItem fullScreenModeMenuItem;
        private JMenuItem viewMemoryMenuItem;

	private JCheckBoxMenuItem z88keyboardMenuItem;
	private JCheckBoxMenuItem z88CardSlotsMenuItem;
	private JCheckBoxMenuItem rtmMessagesMenuItem;

	private JCheckBoxMenuItem seLayoutMenuItem;
	private JCheckBoxMenuItem frLayoutMenuItem;
	private JCheckBoxMenuItem dkLayoutMenuItem;
	private JCheckBoxMenuItem ukLayoutMenuItem;

	private JCheckBoxMenuItem scr10FpsMenuItem;
	private JCheckBoxMenuItem scr25FpsMenuItem;
	private JCheckBoxMenuItem scr50FpsMenuItem;
	private JCheckBoxMenuItem scr100FpsMenuItem;

	/** Default Window mode Gui constructor */
	public Gui() {
		super();
		initialize(false);
	}
	
	public Gui(boolean fullScreen) {
		super();
		initialize(fullScreen);
	}
	
	private JPanel getZ88ScreenPanel() {
		if (z88ScreenPanel == null) {
			z88ScreenPanel = new JPanel();
			z88ScreenPanel.setPreferredSize(new Dimension(644, 66));
			z88ScreenPanel.setBackground(Color.GRAY);
			z88ScreenPanel.add(getZ88Display());
		}

		return z88ScreenPanel;
	}
	
	private Z88display getZ88Display() {
		if (z88Display == null) {
			z88Display = Z88.getInstance().getDisplay();
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

	private JButton getToolBarButton2()	{
		if (toolBarButton2 == null) {
			toolBarButton2 = new JButton();
			toolBarButton2.setText("New JButton");
		}
		return toolBarButton2;
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

			if (fullScreenMode == false) {
				helpMenu.add(getUserManualMenuItem());
			}
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
						new HelpViewer(blink.getClass().getResource("/ozvm-manual.html"));
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
			aboutOZvmMenuItem.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					JOptionPane.showMessageDialog(Gui.this, aboutDialogText, "About OZvm", JOptionPane.PLAIN_MESSAGE);
				}
			});
		}
		return aboutOZvmMenuItem;
	}

	private JMenuBar getMainMenuBar() {
		if (menuBar == null) {
			menuBar = new JMenuBar();
			if (fullScreenMode == false)
				menuBar.setBorder(new EmptyBorder(0, 0, 0, 0));
			menuBar.add(getFileMenu());
			menuBar.add(getZ88Menu());
			menuBar.add(getKeyboardMenu());
			if (fullScreenMode == false) {
				// the View menu has no relevance in full screen mode
				menuBar.add(getViewMenu());
			}
			menuBar.add(getHelpMenu());
		}

		return menuBar;
	}

	private JMenu getFileMenu() {
		if (fileMenu == null) {
			fileMenu = new JMenu();
			fileMenu.setText("File");

			if (fullScreenMode == false) {
				fileMenu.add(getFileDebugMenuItem());
				fileMenu.addSeparator();
			}

			fileMenu.add(getLoadSnapshotMenuItem());
			fileMenu.add(getCreateSnapshotMenuItem());
			fileMenu.add(getCreateScreenMenu());

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
			viewMenu.add(getZ88CardSlotsMenuItem());
                        viewMenu.add(getViewMemoryMenuItem());
			
			if (OZvm.getInstance().isFullScreenSupported() == true) {			
				viewMenu.add(getFullScreenModeMenuItem());
			}
		}
		
		return viewMenu;
	}

	public void displayZ88ScreenPane() {
		if (z88ScreenPanel != null) getContentPane().remove(z88ScreenPanel);		
		addZ88ScreenPanel();
		getZ88Display().grabFocus();
	}
	
	public void displayRunTimeMessagesPane(boolean display) {
		if (fullScreenMode == false) {
			// runtimes messages are not available in full screen mode
			// (a snapshot might try to activate it, but will be ignored)
			
			OZvm.getInstance().getRtmMsgGui().setVisible(display);
		}
		
		getZ88Display().grabFocus();
	}

	public void displayZ88Keyboard(boolean display) {
		if (display == true) {
			getContentPane().remove(getKeyboardPanel());
			addKeyboardPanel();
			getZ88keyboardMenuItem().setSelected(true);
		} else {
			if (fullScreenMode == false) {
				// in full screen mode, the keyboard cannot be removed
				getContentPane().remove(getKeyboardPanel());
				getZ88keyboardMenuItem().setSelected(false);
			}
		}
		
		getZ88Display().grabFocus();
	}

	public void displayZ88CardSlots(boolean display) {
		if (display == true) {
			getContentPane().remove(getSlotsPanel());
			addSlotsPanel();
			getZ88CardSlotsMenuItem().setSelected(true);
			getSlotsPanel().refreshSlotInfo();
		} else {
			getContentPane().remove(getSlotsPanel());
			getZ88CardSlotsMenuItem().setSelected(false);
		}
		
		getZ88Display().grabFocus();
	}
	
	
	public JMenuItem getFullScreenModeMenuItem() {
		if (fullScreenModeMenuItem == null) {
			fullScreenModeMenuItem = new JMenuItem();
			fullScreenModeMenuItem.setSelected(false);
			fullScreenModeMenuItem.setText("Full Screen Mode");
			fullScreenModeMenuItem.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					OZvm.getInstance().setFullScreenMode();
				}
			});
		}

		return fullScreenModeMenuItem;
	}
	
	public JCheckBoxMenuItem getRtmMessagesMenuItem() {
		if (rtmMessagesMenuItem == null) {
			rtmMessagesMenuItem = new JCheckBoxMenuItem();
			rtmMessagesMenuItem.setSelected(false);
			rtmMessagesMenuItem.setText("Runtime Messages");
			rtmMessagesMenuItem.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					displayRunTimeMessagesPane(rtmMessagesMenuItem.isSelected());
					Gui.this.pack();
				}
			});
		}

		return rtmMessagesMenuItem;
	}
	
	public JCheckBoxMenuItem getZ88keyboardMenuItem() {
		if (z88keyboardMenuItem == null) {
			z88keyboardMenuItem = new JCheckBoxMenuItem();
			z88keyboardMenuItem.setSelected(false);
			z88keyboardMenuItem.setText("Z88 Keyboard");
			z88keyboardMenuItem.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					displayZ88Keyboard(z88keyboardMenuItem.isSelected());
					Gui.this.pack();
				}
			});
		}

		return z88keyboardMenuItem;
	}

	public JCheckBoxMenuItem getZ88CardSlotsMenuItem() {
		if (z88CardSlotsMenuItem == null) {
			z88CardSlotsMenuItem = new JCheckBoxMenuItem();
			z88CardSlotsMenuItem.setSelected(false);
			z88CardSlotsMenuItem.setText("Z88 Card Slots");
			z88CardSlotsMenuItem.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					displayZ88CardSlots(z88CardSlotsMenuItem.isSelected());
					Gui.this.pack();					
				}
			});
		}

		return z88CardSlotsMenuItem;
	}

	public JMenuItem getViewMemoryMenuItem() {
		if (viewMemoryMenuItem == null) {
			viewMemoryMenuItem = new JMenuItem();
			viewMemoryMenuItem.setSelected(false);
			viewMemoryMenuItem.setText("View/edit memory");
			viewMemoryMenuItem.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
                                    String input=JOptionPane.showInputDialog(
                                            null, 
                                            "Enter bank number (00-FF): ", 
                                            "View/Edit Z88 Memory", 
                                            JOptionPane.QUESTION_MESSAGE);
                                    int bankNo = Integer.parseInt(input, 16);
                                    Z88.getInstance().getMemory().getBank(bankNo).editMemory();
				}
			});
		}

		return viewMemoryMenuItem;
	}
        
	private void addZ88ScreenPanel() {
		if (fullScreenMode == false) {
			final GridBagConstraints gridBagConstraints = new GridBagConstraints();
			gridBagConstraints.ipady = 5;
			gridBagConstraints.insets = new Insets(0, 0, 0, 0);
			gridBagConstraints.fill = GridBagConstraints.BOTH;
			gridBagConstraints.gridy = 1;
			gridBagConstraints.gridx = 0;
			getContentPane().add(getZ88ScreenPanel(), gridBagConstraints);
		} else {
			// in full screen mode we just display the 640x64 screen without border
			getContentPane().add(getZ88Display(), BorderLayout.NORTH);
		}
	}
	
	private void addKeyboardPanel() {
		if (fullScreenMode == false) {
			GridBagConstraints gridBagConstraints = new GridBagConstraints();
			gridBagConstraints.fill = GridBagConstraints.HORIZONTAL;
			gridBagConstraints.anchor = GridBagConstraints.SOUTHWEST;
			gridBagConstraints.ipady = 213;
			gridBagConstraints.gridy = 6;
			gridBagConstraints.gridx = 0;
			getContentPane().add(getKeyboardPanel(), gridBagConstraints);
		} else {
			getContentPane().add(getKeyboardPanel(), BorderLayout.CENTER);
		}
	}

	private void addSlotsPanel() {
		if (fullScreenMode == false) {
			GridBagConstraints gridBagConstraints = new GridBagConstraints();
			gridBagConstraints.fill = GridBagConstraints.HORIZONTAL;
			gridBagConstraints.anchor = GridBagConstraints.CENTER;
			gridBagConstraints.gridy = 7;
			gridBagConstraints.gridx = 0;
			getContentPane().add(getSlotsPanel(), gridBagConstraints);		
		} else {
			getContentPane().add(getSlotsPanel(), BorderLayout.SOUTH);
		}
	}
		
	private RubberKeyboard getKeyboardPanel() {
		if (keyboardPanel == null) {
			keyboardPanel = Z88.getInstance().getKeyboard().getRubberKeyboard();
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

	public Slots getSlotsPanel() {
		if (slotsPanel == null) {
			slotsPanel = new Slots();
		}

		return slotsPanel;		
	}

	public JCheckBoxMenuItem getUkLayoutMenuItem() {
		if (ukLayoutMenuItem == null) {
			ukLayoutMenuItem = new JCheckBoxMenuItem();
			ukLayoutMenuItem.setText("English Layout");
			ukLayoutMenuItem.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					Z88.getInstance().getKeyboard().setKeyboardLayout(Z88Keyboard.COUNTRY_UK);
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
					Z88.getInstance().getKeyboard().setKeyboardLayout(Z88Keyboard.COUNTRY_DK);
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
					Z88.getInstance().getKeyboard().setKeyboardLayout(Z88Keyboard.COUNTRY_FR);
					getZ88Display().grabFocus();
				}
			});

			kbLayoutButtonGroup.add(frLayoutMenuItem);
		}
		return frLayoutMenuItem;
	}

	public JCheckBoxMenuItem getScreen10FpsMenuItem() {
		if (scr10FpsMenuItem == null) {
			scr10FpsMenuItem = new JCheckBoxMenuItem();
			scr10FpsMenuItem.setText("10 Frames Per Second");
			scr10FpsMenuItem.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					getZ88Display().setFrameRate(Z88display.FPS10);
					getZ88Display().grabFocus();
				}
			});

			scrRefreshRateButtonGroup.add(scr10FpsMenuItem);
		}
		
		return scr10FpsMenuItem;
	}

	public JCheckBoxMenuItem getScreen25FpsMenuItem() {
		if (scr25FpsMenuItem == null) {
			scr25FpsMenuItem = new JCheckBoxMenuItem();
			scr25FpsMenuItem.setText("25 Frames Per Second");
			scr25FpsMenuItem.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					getZ88Display().setFrameRate(Z88display.FPS25);
					getZ88Display().grabFocus();
				}
			});

			scrRefreshRateButtonGroup.add(scr25FpsMenuItem);
		}
		
		return scr25FpsMenuItem;
	}

	public JCheckBoxMenuItem getScreen50FpsMenuItem() {
		if (scr50FpsMenuItem == null) {
			scr50FpsMenuItem = new JCheckBoxMenuItem();
			scr50FpsMenuItem.setText("50 Frames Per Second");
			scr50FpsMenuItem.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					getZ88Display().setFrameRate(Z88display.FPS50);
					getZ88Display().grabFocus();
				}
			});

			scrRefreshRateButtonGroup.add(scr50FpsMenuItem);
		}
		
		return scr50FpsMenuItem;
	}

	public JCheckBoxMenuItem getScreen100FpsMenuItem() {
		if (scr100FpsMenuItem == null) {
			scr100FpsMenuItem = new JCheckBoxMenuItem();
			scr100FpsMenuItem.setText("100 Frames Per Second");
			scr100FpsMenuItem.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					getZ88Display().setFrameRate(Z88display.FPS100);
					getZ88Display().grabFocus();
				}
			});

			scrRefreshRateButtonGroup.add(scr100FpsMenuItem);
		}
		
		return scr100FpsMenuItem;
	}	
	
	public JCheckBoxMenuItem getSeLayoutMenuItem() {
		if (seLayoutMenuItem == null) {
			seLayoutMenuItem = new JCheckBoxMenuItem();
			seLayoutMenuItem.setText("Swedish/Finish Layout");
			seLayoutMenuItem.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					Z88.getInstance().getKeyboard().setKeyboardLayout(Z88Keyboard.COUNTRY_SE);
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
			loadSnapshotMenuItem.setText("Load Z88 state");
			
			loadSnapshotMenuItem.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					boolean resumeExecution;
										
					SaveRestoreVM srVM = new SaveRestoreVM();  
					JFileChooser chooser = new JFileChooser(new File(System.getProperty("user.dir")));
					chooser.setDialogTitle("Load/resume Z88 state");
					chooser.setMultiSelectionEnabled(false);
					chooser.setFileSelectionMode(JFileChooser.FILES_ONLY);
					chooser.setFileFilter(srVM.getSnapshotFilter());

					if ((Z88.getInstance().getProcessorThread() != null)) {
						resumeExecution = true;
						Z88.getInstance().getProcessor().stopZ80Execution();
					} else {
						resumeExecution = false;
					}
					
					int returnVal = chooser.showOpenDialog(getContentPane().getParent());
					if (returnVal == JFileChooser.APPROVE_OPTION) {
						String fileName = chooser.getSelectedFile().getAbsolutePath();
						
						try {
							boolean autorun = srVM.loadSnapShot(fileName);
							getSlotsPanel().refreshSlotInfo();
							if (fullScreenMode == false) {
								OZvm.displayRtmMessage("Snapshot successfully installed from " + fileName);
								setWindowTitle("[" + (chooser.getSelectedFile().getName()) + "]");
							}
							
							if (autorun == true | fullScreenMode == true) {
								// debugging is disabled while full screen mode is enabled
								Z88.getInstance().runZ80Engine(-1, true);
								Z88.getInstance().getDisplay().grabFocus(); // default keyboard input focus to the Z88								
							} else {
								OZvm.getInstance().commandLine(true); // Activate Debug Command Line Window...
								OZvm.getInstance().getCommandLine().initDebugCmdline();
							}
						} catch (IOException e1) {							
							Z88.getInstance().getMemory().setDefaultSystem();
							Z88.getInstance().getProcessor().reset();				
							blink.resetBlinkRegisters();
					    	if (fullScreenMode == false) {
					    		OZvm.displayRtmMessage("Loading of snapshot '" + fileName + "' failed. Z88 preset to default system.");					    		
						    	OZvm.getInstance().commandLine(true); // Activate Debug Command Line Window...
								OZvm.getInstance().getCommandLine().initDebugCmdline();
					    	}
						}						
					} else {
						// User aborted Loading of snapshot..
						if (resumeExecution == true) {							
							Z88.getInstance().runZ80Engine(-1, true);		
							Z88.getInstance().getDisplay().grabFocus(); // default keyboard input focus to the Z88
						}
					}
										
					// the LAF changes sometimes affect the gui, 
					// redraw the slots panel and all is nice again...
					getSlotsPanel().repaint();
					
					Gui.this.pack(); // update Gui window (might have changed by snapshot file...)					
				}
			});
		}
		
		return loadSnapshotMenuItem;
	}
	
	private JMenuItem getCreateSnapshotMenuItem() {
		if (createSnapshotMenuItem == null) {
			createSnapshotMenuItem = new JMenuItem();
			createSnapshotMenuItem.setText("Save Z88 state");
			
			createSnapshotMenuItem.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					boolean autorun;
					
					SaveRestoreVM srVM = new SaveRestoreVM();  
					JFileChooser chooser = new JFileChooser(new File(System.getProperty("user.dir")));
					chooser.setDialogTitle("Save Z88 state");
					chooser.setMultiSelectionEnabled(false);
					chooser.setFileSelectionMode(JFileChooser.FILES_ONLY);
					chooser.setFileFilter(srVM.getSnapshotFilter());
					chooser.setSelectedFile(new File(OZvm.defaultVmFile));
					
					if ((Z88.getInstance().getProcessorThread() != null)) {
						autorun = true;
						Z88.getInstance().getProcessor().stopZ80Execution();
					} else {
						autorun = false;
					}
					
					int returnVal = chooser.showSaveDialog(getContentPane().getParent());
					if (returnVal == JFileChooser.APPROVE_OPTION) {
						String fileName = chooser.getSelectedFile().getAbsolutePath();
						try {
							srVM.storeSnapShot(fileName, autorun);
							OZvm.displayRtmMessage("Snapshot successfully created in " + fileName);
							setWindowTitle("[" + (chooser.getSelectedFile().getName()) + "]");
						} catch (IOException e1) {
							OZvm.displayRtmMessage("Creating snapshot '" + fileName + "' failed.");
						}						
					}					
					
					// the LAF changes sometimes affect the gui, 
					// redraw the slots panel and all is nice again...
					getSlotsPanel().repaint();
					
					if (autorun == true) {
						// Z80 engine was temporary stopped, now continue to execute...
						Z88.getInstance().runZ80Engine(-1, true);
						Z88.getInstance().getDisplay().grabFocus(); // default keyboard input	focus to the Z88
					}
				}
			});
		}
		return createSnapshotMenuItem;
	}
	
	private JMenu getZ88Menu() {
		if (z88Menu == null) {
			z88Menu = new JMenu();
			z88Menu.setText("Z88");
			z88Menu.add(getSoftResetMenuItem());
			z88Menu.add(getHardResetMenuItem());
			z88Menu.addSeparator();
			z88Menu.add(getScreenRefreshRateMenu());
		}
		
		return z88Menu;
	}
	
	private JMenuItem getSoftResetMenuItem() {
		if (softResetMenuItem == null) {
			softResetMenuItem = new JMenuItem();
			softResetMenuItem.setText("Soft Reset");
			softResetMenuItem.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					if (Z88.getInstance().getProcessorThread() != null) {						
						if (JOptionPane.showConfirmDialog(Gui.this, "Soft Reset Z88?") == JOptionPane.YES_OPTION) {
							blink.signalFlapClosed(); // close flap (if open): We don't want a Hard Reset!
							Z88.getInstance().pressResetButton();
						}
					} else {
						JOptionPane.showMessageDialog(Gui.this, "Z88 is not running");
					}
				}
			});
		}
		return softResetMenuItem;
	}
	
	private JMenuItem getHardResetMenuItem() {		
		if (hardResetMenuItem == null) {
			hardResetMenuItem = new JMenuItem();
			hardResetMenuItem.setText("Hard Reset");
			hardResetMenuItem.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					if (Z88.getInstance().getProcessorThread() != null) {						
						if (JOptionPane.showConfirmDialog(Gui.this, "Hard Reset Z88?") == JOptionPane.YES_OPTION) {
							Z88.getInstance().pressHardReset();
						}
					} else {
						JOptionPane.showMessageDialog(Gui.this, "Z88 is not running");
					}					
				}
			});
		}
		return hardResetMenuItem;
	}

	private JMenu getScreenRefreshRateMenu() {
		if (screenRefrashRateMenu == null) {
			screenRefrashRateMenu = new JMenu();
			screenRefrashRateMenu.setText("Screen Fresh Rate");			
			screenRefrashRateMenu.add(getScreen10FpsMenuItem());
			screenRefrashRateMenu.add(getScreen25FpsMenuItem());
			screenRefrashRateMenu.add(getScreen50FpsMenuItem());
			screenRefrashRateMenu.add(getScreen100FpsMenuItem());
		}
		
		return screenRefrashRateMenu;
	}
	
	private JMenu getCreateScreenMenu() {
		if (screenMenu == null) {
			screenMenu = new JMenu();
			screenMenu.setText("Create Screen");
			screenMenu.add(getCreateScreenSnapshotMenuItem());
			screenMenu.add(getCreateGifMovieMenuItem());
		}
		return screenMenu;
	}
	
	private JMenuItem getCreateScreenSnapshotMenuItem() {
		if (screenSnapshotMenuItem == null) {
			screenSnapshotMenuItem = new JMenuItem();
			screenSnapshotMenuItem.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					// grab a copy of the current screen frame and write it to file "./z88screenX.png" (X = counter).					
					getZ88Display().grabScreenFrameToFile();
				}
			});
			
			screenSnapshotMenuItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_F6, 0));
			screenSnapshotMenuItem.setText("Snapshot");
		}
		return screenSnapshotMenuItem;
	}
	
	private JMenuItem getCreateGifMovieMenuItem() {
		if (gifMovieMenuItem == null) {
			gifMovieMenuItem = new JMenuItem();
			gifMovieMenuItem.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					// record an animated Gif movie of the Z88 screen activity					
					getZ88Display().toggleMovieRecording();					
				}
			});
			gifMovieMenuItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_F7, 0));
			gifMovieMenuItem.setText("Gif movie (start/stop)");
		}
		return gifMovieMenuItem;
	}	

	/**
	 * Set the window title which is appended after the 'OZvm VX ' text
	 * 
	 * @param title
	 */
	public void setWindowTitle(String title) {
		this.setTitle("OZvm V" + OZvm.VERSION + "  " + title);	
	}
	
	/**
	 * This method initializes the main z88 window with screen menus,
	 * runtime messages and keyboard.
	 */
	private void initialize(boolean fullScreen) {
		fullScreenMode = fullScreen;
			
		blink = Z88.getInstance().getBlink();
		
		kbLayoutButtonGroup = new ButtonGroup();
		scrRefreshRateButtonGroup = new ButtonGroup();
		
		// set window decoration, depending on full screen or not
		setUndecorated(fullScreen); 
		
		// Main Gui window is never resizable
		setResizable(false);
		setIconImage(new ImageIcon(this.getClass().getResource("/pixel/title.gif")).getImage());
		setJMenuBar(getMainMenuBar());
				
		if (fullScreen == true) {
			getContentPane().setLayout(new BorderLayout());
			getContentPane().setBackground(Color.BLACK);
		    displayZ88ScreenPane();
			displayZ88Keyboard(true);
			displayZ88CardSlots(true);
		} else {		
			// normal OS window mode...
			getContentPane().setLayout(new GridBagLayout());

			final GridBagConstraints gridBagConstraints_1 = new GridBagConstraints();
			gridBagConstraints_1.fill = GridBagConstraints.HORIZONTAL;
			gridBagConstraints_1.gridy = 0;
			gridBagConstraints_1.gridx = 0;
			getContentPane().add(getToolBar(), gridBagConstraints_1);

			displayZ88ScreenPane();
			setWindowTitle("");
		}		
		
		// pre-select the Screen Refresh Rate Menu Item
		switch(getZ88Display().getCurrentFrameRate()) {
			case Z88display.FPS10:
				getScreen10FpsMenuItem().setSelected(true);
				break;			
			case Z88display.FPS25:
				getScreen25FpsMenuItem().setSelected(true);
				break;
			case Z88display.FPS50:
				getScreen50FpsMenuItem().setSelected(true);
				break;
			case Z88display.FPS100:
				getScreen100FpsMenuItem().setSelected(true);
				break;
		}

		// pre-select the keyboard layout Menu Item
		switch(Z88.getInstance().getKeyboard().getKeyboardLayout()) {
			case Z88Keyboard.COUNTRY_UK:
			case Z88Keyboard.COUNTRY_US:
				getUkLayoutMenuItem().setSelected(true);
				break;			
			// swedish/finish
			case Z88Keyboard.COUNTRY_SE:
				getSeLayoutMenuItem().setSelected(true);
				break;
			case Z88Keyboard.COUNTRY_DK:
				getDkLayoutMenuItem().setSelected(true);
				break;
			case Z88Keyboard.COUNTRY_FR:
				getFrLayoutMenuItem().setSelected(true);
				break;
			default:
				getUkLayoutMenuItem().setSelected(true);			
		}
		
		this.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		this.addWindowListener(new java.awt.event.WindowAdapter() {
			public void windowClosing(java.awt.event.WindowEvent e) {
				System.exit(0);
			}
		});
	}	
}
