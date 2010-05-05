/*
 * Slots.java
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
 * $Id$
 *
 */
package net.sourceforge.z88;

import java.awt.Color;
import java.awt.Component;
import java.awt.Dimension;
import java.awt.Font;
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.Insets;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;

import javax.swing.BorderFactory;
import javax.swing.BoxLayout;
import javax.swing.DefaultComboBoxModel;
import javax.swing.ImageIcon;
import javax.swing.JButton;
import javax.swing.JCheckBox;
import javax.swing.JComboBox;
import javax.swing.JFileChooser;
import javax.swing.JLabel;
import javax.swing.JList;
import javax.swing.JMenuItem;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JPopupMenu;
import javax.swing.JScrollPane;
import javax.swing.ListSelectionModel;
import javax.swing.SwingConstants;
import javax.swing.border.BevelBorder;
import javax.swing.border.EtchedBorder;
import javax.swing.border.TitledBorder;
import javax.swing.filechooser.FileFilter;

import net.sourceforge.z88.datastructures.SlotInfo;
import net.sourceforge.z88.filecard.FileArea;
import net.sourceforge.z88.filecard.FileAreaExhaustedException;
import net.sourceforge.z88.filecard.FileAreaNotFoundException;
import net.sourceforge.z88.filecard.FileEntry;

/**
 * Gui management of insertion and removal of cards in internal and external Z88
 * slots (0 - 3).
 */
public class Slots extends JPanel {

	private static final String defaultAppLoadText = "Select Application or File Card Image:";

	private static final String installRomMsg = "Install new ROM in slot 0?\nWARNING: Installing a ROM will automatically perform a hard reset!";

	private static final String installRamMsg = "Install new RAM into slot 0?\nWARNING: Installing RAM will automatically perform a hard reset!";

	private static final DefaultComboBoxModel newCardTypes = new DefaultComboBoxModel(
			new String[] { "RAM", "EPROM", "INTEL FLASH", "AMD FLASH", "AMD/RAM 512/512K", "AMIC/RAM 512/512K"});

	private static final DefaultComboBoxModel ram0Sizes = new DefaultComboBoxModel(
			new String[] { "32K", "128K", "256K", "512K" });

	private static final DefaultComboBoxModel ramCardSizes = new DefaultComboBoxModel(
			new String[] { "32K", "128K", "512K", "1024K" });

	private static final DefaultComboBoxModel eprSizes = new DefaultComboBoxModel(
			new String[] { "32K", "128K", "256K" });

	private static final DefaultComboBoxModel amdFlashSizes = new DefaultComboBoxModel(
			new String[] { "128K", "512K", "1024K" });

	private static final DefaultComboBoxModel intelFlashSizes = new DefaultComboBoxModel(
			new String[] { "512K", "1024K" });

	private static final DefaultComboBoxModel amdHybridSizes = new DefaultComboBoxModel(
			new String[] { "1024K" });

	private static final DefaultComboBoxModel amicHybridSizes = new DefaultComboBoxModel(
			new String[] { "1024K" });

	private static final Font buttonFont = new Font("Sans Serif", Font.BOLD, 11);

	private JLabel spaceLabel;

	private JPanel slot1Panel;

	private JPanel slot2Panel;

	private JPanel slot3Panel;

	private JPanel slot0Panel;

	private JButton ram0Button;

	private JButton rom0Button;

	private JButton slot1Button;

	private JButton slot2Button;

	private JButton slot3Button;

	private JComboBox cardSizeComboBox;

	private JLabel cardSizeLabel;

	private JComboBox cardTypeComboBox;

	private JLabel cardTypeLabel;

	private JPanel newCardPanel;

	private JButton browseAppsButton;

	private JLabel appAreaLabel;

	private JButton browseFilesButton;

	private JCheckBox fileAreaCheckBox;

	private JCheckBox saveAsBanksCheckBox;

	private JCheckBox insertCardCopyCheckBox;

	private Memory memory;
	private Blink blink;

	private EpromFileFilter eprfileFilter;

	private JFileChooser cardImageFileChooser;

	private JFileChooser fileAreaChooser;

	/** Keep a copy of each last removed (flash) eprom card from slots (1-3) */
	private Bank lastRemovedCard[][];

	private File currentEpromDir;

	private File currentFilesDir;

	private JPanel saveAsBanksPanel;

	private JLabel saveAsBanksLabel;

	private MouseAdapter externSlotPopupMenuListener[];

	private ImageIcon emptySlotIcon;

	public Slots() {
		super();
		blink = Z88.getInstance().getBlink();
		memory = Z88.getInstance().getMemory();
		eprfileFilter = new EpromFileFilter();
		currentEpromDir = new File(System.getProperty("user.dir"));
		currentFilesDir = new File(System.getProperty("user.dir"));

		// references to last removed card (bank containers)
		// in external slots (1-3).
		lastRemovedCard = new Bank[4][];

		// references to active popup menu listeners in slots 1-3
		externSlotPopupMenuListener = new MouseAdapter[4];

		setBackground(Color.BLACK);
		emptySlotIcon = getEmptySlotIcon();

		setLayout(new BoxLayout(this, BoxLayout.X_AXIS));
		add(getSlot0Panel());
		add(getSlot1Panel());
		add(getSlot2Panel());
		add(getSlot3Panel());
	}

	/**
	 * Create an Icon (black space) for empty slots
	 * @return
	 */
	private ImageIcon getEmptySlotIcon() {
		int[] matrix = new int[135 * 16]; // default black
		for (int p=0; p<matrix.length; p++) matrix[p] = 0xff000000;

		BufferedImage image = new BufferedImage(135, 16, BufferedImage.TYPE_4BYTE_ABGR);
		image.setRGB(0, 0, 135, 16, matrix, 0, 135);

		// make the new screen frame visible in the GUI.
		return new ImageIcon(image);
	}

	/**
	 * Update the button caption text, reflecting the contents of all slots (0 -
	 * 3).
	 */
	public void refreshSlotInfo() {
		for (int s = 0; s < 4; s++) {
			refreshSlotInfo(s);
		}
	}

	/**
	 * Update the button caption text, reflecting the contents of the specified
	 * slot.
	 *
	 * @param slotNo
	 *            (0 - 3)
	 */
	public void refreshSlotInfo(int slotNo) {
		String slotText = null;
		slotNo &= 3;

		int slotType = SlotInfo.getInstance().getCardType(slotNo);
		switch (slotType) {
		case SlotInfo.AmdFlashCard:
			slotText = "AMD FLASH";
			break;
		case SlotInfo.AmdHybridRamCard:
			slotText = "AMD/RAM";
			break;
		case SlotInfo.AmicHybridRamCard:
			slotText = "AMIC/RAM";
			break;
		case SlotInfo.EpromCard:
			slotText = "EPROM";
			break;
		case SlotInfo.IntelFlashCard:
			slotText = "INTEL FLASH";
			break;
		case SlotInfo.RamCard:
			slotText = "RAM";
			break;
		case SlotInfo.RomCard:
			slotText = "ROM";
			break;
		}

		if (slotNo > 0) {
			if (slotType != SlotInfo.EmptySlot) {
				switch(slotType) {
				    case SlotInfo.AmdHybridRamCard:
				        slotText = "512/512K AMD/RAM";
				        break;
				    case SlotInfo.AmicHybridRamCard:
				        slotText = "512/512K AMIC/RAM";
				        break;
				    default:
					    slotText = (memory.getExternalCardSize(slotNo) * 16) + "K " + slotText;
				}
			}
		}

		switch (slotNo) {
		case 0:
			if (SlotInfo.getInstance().getCardType(slotNo) != SlotInfo.RomCard)
				getRom0Button().setText(
					(" " + memory.getInternalRomSize() * 16) + "K FLASH ");
			else
				getRom0Button().setText(
						(" " + memory.getInternalRomSize() * 16) + "K ROM ");

			getRam0Button().setText(
					(" " + memory.getInternalRamSize() * 16) + "K RAM");
			break;
		case 1:
			if (slotType == SlotInfo.EmptySlot) {
				getSlot1Button().setBorder(BorderFactory.createBevelBorder(BevelBorder.LOWERED, Color.LIGHT_GRAY, Color.DARK_GRAY));
				getSlot1Button().setIcon(emptySlotIcon);
				getSlot1Button().setText(null);
			} else {
				getSlot1Button().setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
				getSlot1Button().setIcon(null);
				getSlot1Button().setText(" " + slotText);
			}
			break;
		case 2:
			if (slotType == SlotInfo.EmptySlot) {
				getSlot2Button().setBorder(BorderFactory.createBevelBorder(BevelBorder.LOWERED, Color.LIGHT_GRAY, Color.DARK_GRAY));
				getSlot2Button().setIcon(emptySlotIcon);
				getSlot2Button().setText(null);
			} else {
				getSlot2Button().setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
				getSlot2Button().setIcon(null);
				getSlot2Button().setText(" " + slotText);
			}
			break;
		case 3:
			if (slotType == SlotInfo.EmptySlot) {
				getSlot3Button().setBorder(BorderFactory.createBevelBorder(BevelBorder.LOWERED, Color.LIGHT_GRAY, Color.DARK_GRAY));
				getSlot3Button().setIcon(emptySlotIcon);
				getSlot3Button().setText(null);
			} else {
				getSlot3Button().setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
				getSlot3Button().setIcon(null);
				getSlot3Button().setText(" " + slotText);
			}
			break;
		}
	}

	private JPanel getSlot0Panel() {
		if (slot0Panel == null) {
			slot0Panel = new JPanel();
			slot0Panel.setLayout(new BoxLayout(slot0Panel, BoxLayout.X_AXIS));
			slot0Panel.setBackground(Color.BLACK);
			slot0Panel.add(getRom0Button());
			slot0Panel.add(getSpaceLabel());
			slot0Panel.add(getRam0Button());
			slot0Panel.setBorder(new TitledBorder(new EtchedBorder(Color.GRAY,
					Color.DARK_GRAY), "Slot 0", TitledBorder.RIGHT,
					TitledBorder.DEFAULT_POSITION, null, Color.WHITE));
		}

		return slot0Panel;
	}

	private JPanel getSlot1Panel() {
		if (slot1Panel == null) {
			slot1Panel = new JPanel();
			slot1Panel.setLayout(new BoxLayout(slot1Panel, BoxLayout.X_AXIS));
			slot1Panel.setBackground(Color.BLACK);
			slot1Panel.setBorder(new TitledBorder(new EtchedBorder(Color.GRAY,
					Color.DARK_GRAY), "Slot 1", TitledBorder.RIGHT,
					TitledBorder.DEFAULT_POSITION, null, Color.WHITE));
			slot1Panel.add(getSlot1Button());
		}

		return slot1Panel;
	}

	private JPanel getSlot2Panel() {
		if (slot2Panel == null) {
			slot2Panel = new JPanel();
			slot2Panel.setLayout(new BoxLayout(slot2Panel, BoxLayout.X_AXIS));
			slot2Panel.setBackground(Color.BLACK);
			slot2Panel.setBorder(new TitledBorder(new EtchedBorder(Color.GRAY,
					Color.DARK_GRAY), "Slot 2", TitledBorder.RIGHT,
					TitledBorder.DEFAULT_POSITION, null, Color.WHITE));
			slot2Panel.add(getSlot2Button());
		}

		return slot2Panel;
	}

	private JPanel getSlot3Panel() {
		if (slot3Panel == null) {
			slot3Panel = new JPanel();
			slot3Panel.setLayout(new BoxLayout(slot3Panel, BoxLayout.X_AXIS));
			slot3Panel.setBackground(Color.BLACK);
			slot3Panel.setForeground(Color.WHITE);
			slot3Panel.setBorder(new TitledBorder(new EtchedBorder(Color.GRAY,
					Color.DARK_GRAY), "Slot 3", TitledBorder.RIGHT,
					TitledBorder.DEFAULT_POSITION, null, Color.WHITE));
			slot3Panel.add(getSlot3Button());
		}

		return slot3Panel;
	}

	private JButton getRom0Button() {
		if (rom0Button == null) {
			rom0Button = new JButton();
			rom0Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			rom0Button.setMaximumSize(new Dimension(87, 20));
			rom0Button.setHorizontalAlignment(SwingConstants.LEFT);
			rom0Button.setFont(buttonFont);
			rom0Button.setForeground(Color.BLACK);
			rom0Button.setBackground(Color.LIGHT_GRAY);
			rom0Button.setMargin(new Insets(2, 2, 2, 2));

			rom0Button.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					blink.signalFlapOpened();

					if (JOptionPane
							.showConfirmDialog(Slots.this, installRomMsg, "Replace OZ operating system ROM", JOptionPane.YES_NO_OPTION) == JOptionPane.YES_OPTION) {
						JFileChooser chooser = new JFileChooser(currentEpromDir);
						chooser.setDialogTitle("Load/install Z88 ROM into slot 0");
						chooser.setMultiSelectionEnabled(false);
						chooser.setFileSelectionMode(JFileChooser.FILES_ONLY);

						int returnVal = chooser.showOpenDialog(Slots.this);
						if (returnVal == JFileChooser.APPROVE_OPTION) {
							// remember current directory for next time..
							currentEpromDir = chooser.getCurrentDirectory();

							File romFile = new File(chooser.getSelectedFile().getAbsolutePath());
							try {
								memory.loadRomBinary(romFile);
								OZvm.getInstance().getGui().setWindowTitle("[" + (romFile.getName()) + "]");
								// ROM installed, do a hard reset (flap is automatically closed)
								Z88.getInstance().pressHardReset();
							} catch (IOException e1) {
								JOptionPane.showMessageDialog(Slots.this,
										"Selected file couldn't be opened!");
								blink.signalFlapClosed();
							} catch (IllegalArgumentException e2) {
								JOptionPane.showMessageDialog(Slots.this,
										"Selected file was not a Z88 ROM!");
								blink.signalFlapClosed();
							}
						} else {
							// User aborted...
							blink.signalFlapClosed();
						}
					} else {
						// User aborted...
						blink.signalFlapClosed();
					}

					refreshSlotInfo(0);
					Z88.getInstance().getDisplay().grabFocus();
				}
			});
		}

		return rom0Button;
	}

	private JButton getRam0Button() {
		if (ram0Button == null) {
			ram0Button = new JButton();
			ram0Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.RAISED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			ram0Button.setMaximumSize(new Dimension(87, 20));
			ram0Button.setHorizontalAlignment(SwingConstants.LEFT);
			ram0Button.setFont(buttonFont);
			ram0Button.setForeground(Color.BLACK);
			ram0Button.setBackground(Color.LIGHT_GRAY);
			ram0Button.setMargin(new Insets(2, 2, 2, 2));

			ram0Button.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					blink.signalFlapOpened();

					if (JOptionPane
							.showConfirmDialog(Slots.this, installRamMsg, "Replace internal RAM memory", JOptionPane.YES_NO_OPTION) == JOptionPane.YES_OPTION) {
						getCardSizeComboBox().setModel(ram0Sizes);
						JOptionPane.showMessageDialog(Slots.this,
								getCardSizeComboBox(),
								"Select RAM size for slot 0",
								JOptionPane.NO_OPTION);

						String size = (String) ram0Sizes
								.getElementAt(getCardSizeComboBox()
										.getSelectedIndex());
						memory.insertRamCard(Integer.parseInt(size.substring(0,
								size.indexOf("K"))), 0);

						// ROM installed, do a hard reset (flap is automatically closed)
						Z88.getInstance().pressHardReset();
					} else {
						// User aborted...
						blink.signalFlapClosed();
					}

					refreshSlotInfo(0);
					Z88.getInstance().getDisplay().grabFocus();
				}
			});
		}

		return ram0Button;
	}


	private JButton getSlot1Button() {
		if (slot1Button == null) {
			slot1Button = new JButton();
			slot1Button.setHorizontalAlignment(SwingConstants.LEFT);
			slot1Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.LOWERED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			slot1Button.setMaximumSize(new Dimension(139, 20));
			slot1Button.setFont(buttonFont);
			slot1Button.setMargin(new Insets(2, 2, 2, 2));
			slot1Button.setForeground(Color.BLACK);
			slot1Button.setBackground(Color.LIGHT_GRAY);

			// add a right-click popup for file area management
			externSlotPopupMenuListener[1] = addPopup(slot1Button, new CardPopupMenu(1));

			slot1Button.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {

					if (SlotInfo.getInstance().getCardType(1) == SlotInfo.EmptySlot) {
						// slot is empty, a card may be inserted;
						// load a card .Epr file or insert a new card (type)
						insertCard((JButton) e.getSource(), 1);
					} else {
						// remove a card, or for Eprom/Flash cards, and/or save a copy
						// of the card to an .Epr file...
						removeCard((JButton) e.getSource(), 1);
					}
				}
			});
		}

		return slot1Button;
	}

	private JButton getSlot2Button() {
		if (slot2Button == null) {
			slot2Button = new JButton();
			slot2Button.setHorizontalAlignment(SwingConstants.LEFT);
			slot2Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.LOWERED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			slot2Button.setMaximumSize(new Dimension(139, 20));
			slot2Button.setFont(buttonFont);
			slot2Button.setMargin(new Insets(2, 2, 2, 2));
			slot2Button.setForeground(Color.BLACK);
			slot2Button.setBackground(Color.LIGHT_GRAY);

			// add a right-click popup for file area management
			externSlotPopupMenuListener[2] = addPopup(slot2Button, new CardPopupMenu(2));

			slot2Button.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					if (SlotInfo.getInstance().getCardType(2) == SlotInfo.EmptySlot) {
						// slot is empty, a card may be inserted;
						// load a card .Epr file or insert a new card (type)
						insertCard((JButton) e.getSource(), 2);
					} else {
						// remove a card, or for Eprom/Flash cards, and/or save a copy
						// of the card to an .Epr file...
						removeCard((JButton) e.getSource(), 2);
					}
				}
			});
		}

		return slot2Button;
	}

	private JButton getSlot3Button() {
		if (slot3Button == null) {
			slot3Button = new JButton();
			slot3Button.setHorizontalAlignment(SwingConstants.LEFT);
			slot3Button.setBorder(BorderFactory.createBevelBorder(BevelBorder.LOWERED, Color.LIGHT_GRAY, Color.DARK_GRAY));
			slot3Button.setMaximumSize(new Dimension(139, 20));
			slot3Button.setFont(buttonFont);
			slot3Button.setMargin(new Insets(2, 2, 2, 2));
			slot3Button.setForeground(Color.BLACK);
			slot3Button.setBackground(Color.LIGHT_GRAY);

			// add a right-click popup for file area management
			externSlotPopupMenuListener[3] = addPopup(slot3Button, new CardPopupMenu(3));

			slot3Button.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {

					if (SlotInfo.getInstance().getCardType(3) == SlotInfo.EmptySlot) {
						// slot is empty, a card may be inserted;
						// load a card .Epr file or insert a new card (type)
						insertCard((JButton) e.getSource(), 3);
					} else {
						// remove a card, or for Eprom/Flash cards, and/or save a copy
						// of the card to an .Epr file...
						removeCard((JButton) e.getSource(), 3);
					}
				}
			});
		}

		return slot3Button;
	}

	private JLabel getSpaceLabel() {
		if (spaceLabel == null) {
			spaceLabel = new JLabel();
			spaceLabel.setText(" ");
		}

		return spaceLabel;
	}

	/**
	 * Insert card functionality, controlled via Gui dialogs.
	 *
	 * @param slotButton
	 * @param slotNo
	 */
	private void insertCard(JButton slotButton, int slotNo) {
		FileArea fa = null;
		File cardImageFiles[] = null;
		int internalCardType = 0;

		// re-initialize standard checkbox text
		getFileAreaCheckBox().setText("Create File Area:");

		if (slotNo == 1) {
			// default select RAM card for slot 1 (easier for users)
			getCardSizeComboBox().setModel(ramCardSizes);
			getCardTypeComboBox().setSelectedIndex(0); // default RAM card
			getCardSizeComboBox().setSelectedIndex(3); // default 1024K size

			getFileAreaCheckBox().setEnabled(false); // remaining widgets disabled...
			getAppAreaLabel().setEnabled(false);
			getBrowseFilesButton().setEnabled(false);
			getBrowseAppsButton().setEnabled(false);
		}
		if (slotNo == 2) {
			// default select an 1Mb Amd Flash Card
			getCardSizeComboBox().setModel(amdFlashSizes);
			getCardTypeComboBox().setSelectedIndex(3); // default AMD Flash card
			getCardSizeComboBox().setSelectedIndex(2); // default 1024K size

			insertCardDialogAccessibility(true);
		}
		if (slotNo == 3) {
			// default select an Intel 1mb Flash Card
			getCardSizeComboBox().setModel(intelFlashSizes);
			getCardTypeComboBox().setSelectedIndex(2); // default Intel Flash card
			getCardSizeComboBox().setSelectedIndex(1); // default 1024K size

			insertCardDialogAccessibility(true);
		}

		getReInsertCardCopyCheckBox().setSelected(false);

		getFileAreaCheckBox().setSelected(false); // default no file area on card...
		getAppAreaLabel().setText(defaultAppLoadText);
		cardImageFileChooser = fileAreaChooser = null;

		if (lastRemovedCard[slotNo] != null)
			// The user may choose to re-insert a previously removed card
			getReInsertCardCopyCheckBox().setEnabled(true);
		else
			getReInsertCardCopyCheckBox().setEnabled(false);

		blink.signalFlapOpened();
		if (JOptionPane.showConfirmDialog(Slots.this, getNewCardPanel(),
				"Create Card to insert into slot " + slotNo, JOptionPane.YES_NO_OPTION) == JOptionPane.YES_OPTION) {
			String size = (String) getCardSizeComboBox().getModel()
					.getElementAt(getCardSizeComboBox().getSelectedIndex());
			int cardSizeK = Integer.parseInt(size.substring(0,size.indexOf("K")));

			if (getReInsertCardCopyCheckBox().isSelected() == true) {
				// re-insert previously removed card
				memory.insertCard(lastRemovedCard[slotNo], slotNo);
				lastRemovedCard[slotNo] = null;
				OZvm.displayRtmMessage("Re-inserted previously removed Card back to slot " + slotNo);
			} else {
				if (cardImageFileChooser != null) {
					// load an EPR image on the card: start with opening the file
					cardImageFiles = cardImageFileChooser.getSelectedFiles();
				}

				switch (getCardTypeComboBox().getSelectedIndex()) {
					case 0:
						// insert selected RAM Card
						memory.insertRamCard(cardSizeK, slotNo);
						OZvm.displayRtmMessage(cardSizeK + "K RAM Card was inserted in slot " + slotNo);
						break;
					case 1:
						// insert an (UV) EPROM Card
						internalCardType = SlotInfo.EpromCard;
						break;
					case 2:
						// insert an Intel Flash Card
						internalCardType = SlotInfo.IntelFlashCard;
						break;
					case 3:
						// insert an Amd Flash Card
						internalCardType = SlotInfo.AmdFlashCard;
						break;
					case 4:
						// insert a hybrid Amd 512K Flash / 512K Ram Card
						internalCardType = SlotInfo.AmdHybridRamCard;
						break;
					case 5:
						// insert a hybrid Amic 512K Flash / 512K Ram Card
						internalCardType = SlotInfo.AmicHybridRamCard;
						break;
				}

				if (cardImageFiles != null) {
					// A selected Card was also marked to load an (app) image..
					try {
						memory.loadFileImagesOnCard(slotNo, cardSizeK, internalCardType, cardImageFiles);
					} catch (IOException e1) {
						JOptionPane.showMessageDialog(Slots.this, e1.getMessage(),
								"Insert Card Error", JOptionPane.ERROR_MESSAGE);
						blink.signalFlapClosed();
						Z88.getInstance().getDisplay().grabFocus();
						return;
					}
				} else {
					// Insert a selected Eprom type (which is not to be loaded with a file image...
					if (internalCardType != 0)
						memory.insertEprCard(slotNo, cardSizeK, internalCardType);
				}

				// User has also chosen to create a file area on card...
				if (getFileAreaCheckBox().isSelected() == true) {
					// user has chosen to create/format a file area on the card
					if (SlotInfo.getInstance().getFileHeaderBank(slotNo) != -1) {
						// a file area already exists on the card!
						if (JOptionPane.showConfirmDialog(Slots.this, "Re-format file area on card?\nWarning: All current files is lost",
								"File Area available on card", JOptionPane.NO_OPTION) == JOptionPane.YES_OPTION) {
							if (FileArea.create(slotNo, true) == false) {
								JOptionPane.showMessageDialog(Slots.this, "File Area could not be re-formatted",
										"Card Error in slot " + slotNo, JOptionPane.ERROR_MESSAGE);
							}
						}
					} else {
						if (FileArea.create(slotNo, true) == false) {
							JOptionPane.showMessageDialog(Slots.this, "File Area could not be created",
									"Card Error in slot " + slotNo, JOptionPane.ERROR_MESSAGE);
						}
					}

					if (SlotInfo.getInstance().getFileHeaderBank(slotNo) != -1) {
						try {
							fa = new FileArea(slotNo);

							if (fileAreaChooser != null) {
								File selectedFiles[] = fileAreaChooser.getSelectedFiles();
								// import files into file area, if selected by user...
								for (int f=0; f<selectedFiles.length; f++) {
									fa.importHostFile(selectedFiles[f]);
								}
							}
						} catch (FileAreaNotFoundException e1) {
							JOptionPane.showMessageDialog(Slots.this, "File Area not available in slot" + slotNo,
									"Insert Card Error in slot " + slotNo, JOptionPane.ERROR_MESSAGE);
						} catch (FileAreaExhaustedException e) {
							JOptionPane.showMessageDialog(Slots.this, "File Area exhausted during import",
									"Insert Card Error in slot " + slotNo, JOptionPane.ERROR_MESSAGE);
						} catch (IOException e) {
							JOptionPane.showMessageDialog(Slots.this, "I/O error during File Area import",
									"Insert Card Error in slot " + slotNo, JOptionPane.ERROR_MESSAGE);
						}
					}
				}
			}

			// card has been successfully inserted into slot...
			refreshSlotInfo(slotNo);
		}

		blink.signalFlapClosed();
		Z88.getInstance().getDisplay().grabFocus();
	}

	/**
	 * Remove card functionality, controlled via Gui dialogs.
	 *
	 * @param slotButton
	 * @param slotNo
	 */
	private void removeCard(JButton slotButton, int slotNo) {
		blink.signalFlapOpened();

		if (SlotInfo.getInstance().getCardType(slotNo) == SlotInfo.RamCard) {
			if (JOptionPane.showConfirmDialog(Slots.this,
					"Remove RAM card?\nWarning: Z88 enters \"fail\" mode after removal.\nPerform a (suggested) hard reset in the 'Z88' menu.",
					"Remove card from slot " + slotNo, JOptionPane.YES_NO_OPTION) == JOptionPane.YES_OPTION) {
				memory.removeCard(slotNo);
				lastRemovedCard[slotNo] = null; // RAM card is not preserved when removed from slot...

				blink.signalFlapClosed();
			}
		} else {
			if (JOptionPane.showConfirmDialog(Slots.this,
					"Remove "+ slotButton.getText() + " card?",
					"Remove card from slot " + slotNo,
					JOptionPane.YES_NO_OPTION) == JOptionPane.YES_OPTION) {

				if (JOptionPane.showConfirmDialog(Slots.this,
						getSaveAsBanksPanel(),
						"Remove card from slot " + slotNo,
						JOptionPane.YES_NO_OPTION) == JOptionPane.YES_OPTION) {
					if (getSaveAsBanksCheckBox().isSelected() == false) {
						// save card as an EPR image file...
						JFileChooser chooser = new JFileChooser(currentEpromDir);
						chooser.setDialogTitle("Save Z88 Card as a single image file (*.EPR)");
						chooser.setMultiSelectionEnabled(false);
						chooser.setFileSelectionMode(JFileChooser.FILES_ONLY);
						chooser.setFileFilter(eprfileFilter);

						int returnVal = chooser.showSaveDialog(Slots.this.getParent());
						if (returnVal == JFileChooser.APPROVE_OPTION) {
							String eprFilename = chooser.getSelectedFile().getAbsolutePath();
							if (eprFilename.toLowerCase().lastIndexOf(".epr") == -1) {
								// append ".epr" extension if not specified by user...
								eprFilename += ".epr";
							}

							try {
								memory.dumpSlot(slotNo, false, "", eprFilename);
							} catch (FileNotFoundException e) {
								JOptionPane.showMessageDialog(Slots.this, "Couldn't save the card to an EPR file",
										"Remove Card from slot " + slotNo, JOptionPane.ERROR_MESSAGE);
							} catch (IOException e) {
								JOptionPane.showMessageDialog(Slots.this, "Couldn't save the card to an EPR file",
										"Remove Card from slot " + slotNo, JOptionPane.ERROR_MESSAGE);
							}
						}
					} else {
						// save card as 16K bank files...
						JFileChooser chooser = new JFileChooser(currentEpromDir);
						chooser.setDialogTitle("Save Z88 Card as 16 Bank files (.0 - .63)");
						chooser.setMultiSelectionEnabled(false);
						chooser.setFileSelectionMode(JFileChooser.FILES_ONLY);

						int returnVal = chooser.showSaveDialog(Slots.this.getParent());
						if (returnVal == JFileChooser.APPROVE_OPTION) {
							String filenameDir = chooser.getSelectedFile().getParent();

							try {
								memory.dumpSlot(slotNo, true, filenameDir, chooser.getSelectedFile().getName());
							} catch (FileNotFoundException e) {
								JOptionPane.showMessageDialog(Slots.this, "Couldn't save the card as 16k bank files",
										"Remove Card from slot " + slotNo, JOptionPane.ERROR_MESSAGE);
							} catch (IOException e) {
								JOptionPane.showMessageDialog(Slots.this, "Couldn't save the card as 16k bank files",
										"Remove Card from slot " + slotNo, JOptionPane.ERROR_MESSAGE);
							}
						}

					}
				}

				// keep a copy of removed File/App card...
				lastRemovedCard[slotNo] = memory.removeCard(slotNo);
			}
		}

		blink.signalFlapClosed();

		if (memory.isSlotEmpty(slotNo) == true)
			OZvm.displayRtmMessage(slotButton.getText() + " Card was removed from slot " + slotNo);
		refreshSlotInfo(slotNo);

		Z88.getInstance().getDisplay().grabFocus();
	}

	private JLabel getSaveAsBanksLabel() {
		if (saveAsBanksLabel == null) {
			saveAsBanksLabel = new JLabel();
			saveAsBanksLabel.setText("Dump card to filing system, before removing it?");
		}

		return saveAsBanksLabel;
	}

	private JPanel getSaveAsBanksPanel() {
		if (saveAsBanksPanel == null) {
			saveAsBanksPanel = new JPanel();
			saveAsBanksPanel.setLayout(new BoxLayout(saveAsBanksPanel, BoxLayout.Y_AXIS));
			saveAsBanksPanel.add(getSaveAsBanksLabel());
			saveAsBanksPanel.add(getSaveAsBanksCheckBox());
		}

		return saveAsBanksPanel;
	}

	private JPanel getNewCardPanel() {
		newCardPanel = new JPanel();
		newCardPanel.setLayout(new GridBagLayout());
		newCardPanel.setBorder(new TitledBorder(new EtchedBorder(
				EtchedBorder.LOWERED), "Create Card",
				TitledBorder.DEFAULT_JUSTIFICATION,
				TitledBorder.DEFAULT_POSITION, null, null));

		final GridBagConstraints gridBagConstraints = new GridBagConstraints();
		gridBagConstraints.insets = new Insets(0, 0, 0, 20);
		gridBagConstraints.fill = GridBagConstraints.HORIZONTAL;
		gridBagConstraints.gridy = 0;
		gridBagConstraints.gridx = 0;
		newCardPanel.add(getCardTypeLabel(), gridBagConstraints);

		final GridBagConstraints gridBagConstraints_1 = new GridBagConstraints();
		gridBagConstraints_1.fill = GridBagConstraints.HORIZONTAL;
		gridBagConstraints_1.gridy = 0;
		gridBagConstraints_1.gridx = 1;
		newCardPanel.add(getCardTypeComboBox(), gridBagConstraints_1);

		final GridBagConstraints gridBagConstraints_2 = new GridBagConstraints();
		gridBagConstraints_2.insets = new Insets(0, 10, 0, 20);
		gridBagConstraints_2.gridy = 0;
		gridBagConstraints_2.gridx = 2;
		newCardPanel.add(getCardSizeLabel(), gridBagConstraints_2);

		final GridBagConstraints gridBagConstraints_3 = new GridBagConstraints();
		gridBagConstraints_3.fill = GridBagConstraints.HORIZONTAL;
		gridBagConstraints_3.gridy = 0;
		gridBagConstraints_3.gridx = 3;
		newCardPanel.add(getCardSizeComboBox(), gridBagConstraints_3);

		final GridBagConstraints gridBagConstraints_6 = new GridBagConstraints();
		gridBagConstraints_6.gridwidth = 3;
		gridBagConstraints_6.insets = new Insets(0, 0, 0, 20);
		gridBagConstraints_6.fill = GridBagConstraints.HORIZONTAL;
		gridBagConstraints_6.gridy = 1;
		gridBagConstraints_6.gridx = 0;
		newCardPanel.add(getAppAreaLabel(), gridBagConstraints_6);

		final GridBagConstraints gridBagConstraints_7 = new GridBagConstraints();
		gridBagConstraints_7.fill = GridBagConstraints.HORIZONTAL;
		gridBagConstraints_7.gridy = 1;
		gridBagConstraints_7.gridx = 3;
		newCardPanel.add(getBrowseAppsButton(), gridBagConstraints_7);

		final GridBagConstraints gridBagConstraints_4 = new GridBagConstraints();
		gridBagConstraints_4.gridwidth = 3;
		gridBagConstraints_4.fill = GridBagConstraints.HORIZONTAL;
		gridBagConstraints_4.gridy = 2;
		gridBagConstraints_4.gridx = 0;
		newCardPanel.add(getFileAreaCheckBox(), gridBagConstraints_4);

		final GridBagConstraints gridBagConstraints_5 = new GridBagConstraints();
		gridBagConstraints_5.fill = GridBagConstraints.HORIZONTAL;
		gridBagConstraints_5.gridy = 2;
		gridBagConstraints_5.gridx = 3;
		newCardPanel.add(getBrowseFilesButton(), gridBagConstraints_5);

		final GridBagConstraints gridBagConstraints_8 = new GridBagConstraints();
		gridBagConstraints_8.gridwidth = 4;
		gridBagConstraints_8.fill = GridBagConstraints.HORIZONTAL;
		gridBagConstraints_8.gridy = 4;
		gridBagConstraints_8.gridx = 0;
		newCardPanel.add(getReInsertCardCopyCheckBox(), gridBagConstraints_8);

		return newCardPanel;
	}

	private JLabel getCardTypeLabel() {
		if (cardTypeLabel == null) {
			cardTypeLabel = new JLabel();
			cardTypeLabel.setText("Type:");
		}
		return cardTypeLabel;
	}

	private JComboBox getCardTypeComboBox() {
		if (cardTypeComboBox == null) {
			cardTypeComboBox = new JComboBox();
			cardTypeComboBox.setModel(newCardTypes);

			cardTypeComboBox.addActionListener(new ActionListener() {
				// when the Card type is changed, also change available sizes
				public void actionPerformed(ActionEvent e) {
					JComboBox typeComboBox = (JComboBox) e.getSource();
					switch (typeComboBox.getSelectedIndex()) {
						case 0:
							// define available RAM Card sizes
							getCardSizeComboBox().setModel(ramCardSizes);
							break;
						case 1:
							// define available (UV) EPROM Card sizes
							getCardSizeComboBox().setModel(eprSizes);
							break;
						case 2:
							// define available Intel Flash Card sizes
							getCardSizeComboBox().setModel(intelFlashSizes);
							break;
						case 3:
							// define available Amd Flash Card sizes
							getCardSizeComboBox().setModel(amdFlashSizes);
							break;
						case 4:
							// define available Amd/Ram Hybrid Card size
							getCardSizeComboBox().setModel(amdHybridSizes);
							break;
						case 5:
							// define available Amic/Ram Hybrid Card size
							getCardSizeComboBox().setModel(amicHybridSizes);
							break;
					}

					if (getCardTypeComboBox().getSelectedIndex() == 0) {
						// RAM card is selected
						getFileAreaCheckBox().setEnabled(false);
						getAppAreaLabel().setEnabled(false);
						getBrowseFilesButton().setEnabled(false);
						getBrowseAppsButton().setEnabled(false);
					} else {
						getFileAreaCheckBox().setEnabled(true);
						getAppAreaLabel().setEnabled(true);
						getBrowseFilesButton().setEnabled(true);
						getBrowseAppsButton().setEnabled(true);
					}
				}
			});
		}

		return cardTypeComboBox;
	}

	private JLabel getCardSizeLabel() {
		if (cardSizeLabel == null) {
			cardSizeLabel = new JLabel();
			cardSizeLabel.setText("Size:");
		}
		return cardSizeLabel;
	}

	private JComboBox getCardSizeComboBox() {
		if (cardSizeComboBox == null) {
			cardSizeComboBox = new JComboBox();
		}
		return cardSizeComboBox;
	}

	private void insertCardDialogAccessibility(boolean state) {
		getCardTypeLabel().setEnabled(state);
		getCardTypeComboBox().setEnabled(state);
		getCardSizeLabel().setEnabled(state);
		getCardSizeComboBox().setEnabled(state);
		getFileAreaCheckBox().setEnabled(state);
		getBrowseFilesButton().setEnabled(state);
		getAppAreaLabel().setEnabled(state);
		getBrowseAppsButton().setEnabled(state);
	}

	private JCheckBox getReInsertCardCopyCheckBox() {
		if (insertCardCopyCheckBox == null) {
			insertCardCopyCheckBox = new JCheckBox();
			insertCardCopyCheckBox.setText("Re-insert previously removed card");

			insertCardCopyCheckBox.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					if (insertCardCopyCheckBox.isSelected() == true)
						// disable all other insert-dialog features -
						// the user wants to re-insert a previously removed card
						insertCardDialogAccessibility(false);
					else
						// re-enable insert-card-dialog features -
						// the user discarded the choice of re-inserting an old card
						insertCardDialogAccessibility(true);
				}
			});
		}

		return insertCardCopyCheckBox;
	}

	private JCheckBox getFileAreaCheckBox() {
		if (fileAreaCheckBox == null) {
			fileAreaCheckBox = new JCheckBox();
			fileAreaCheckBox.setText("Create File Area:");
		}

		return fileAreaCheckBox;
	}

	private JCheckBox getSaveAsBanksCheckBox() {
		if (saveAsBanksCheckBox == null) {
			saveAsBanksCheckBox = new JCheckBox();
			saveAsBanksCheckBox.setText("Save Card as 16K bank files (0-63)");
		}

		return saveAsBanksCheckBox;
	}

	private JButton getBrowseFilesButton() {
		if (browseFilesButton == null) {
			browseFilesButton = new JButton();
			browseFilesButton.setFont(buttonFont);
			browseFilesButton.setText("Load Files..");

			browseFilesButton.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					fileAreaChooser = new JFileChooser(currentFilesDir);
					fileAreaChooser
							.setDialogTitle("Import files into Card File Area");
					fileAreaChooser.setMultiSelectionEnabled(true);
					fileAreaChooser
							.setFileSelectionMode(JFileChooser.FILES_ONLY);

					int returnVal = fileAreaChooser.showOpenDialog(Slots.this
							.getParent());
					if (returnVal == JFileChooser.APPROVE_OPTION) {
						getFileAreaCheckBox().setSelected(true);
						// remember current directory for next time..
						currentFilesDir = fileAreaChooser.getCurrentDirectory();

						File selectedFiles[] = fileAreaChooser.getSelectedFiles();
						int totalSelectedSize = 0;
						for (int f=0; f<selectedFiles.length; f++) {
							if (selectedFiles[f].isFile() == true) {
								totalSelectedSize += 1 + selectedFiles[f].getName().length() +
													 4 + selectedFiles[f].length();
							}
						}

						getFileAreaCheckBox().setText("Create File Area: (" +
								fileAreaChooser.getSelectedFiles().length + " files = " +
								totalSelectedSize/1024 + "K)");
					} else {
						getFileAreaCheckBox().setSelected(false);
					}
				}
			});
		}

		return browseFilesButton;
	}

	private JLabel getAppAreaLabel() {
		if (appAreaLabel == null) {
			appAreaLabel = new JLabel();
			appAreaLabel.setText(defaultAppLoadText);
		}
		return appAreaLabel;
	}


	private JButton getBrowseAppsButton() {
		if (browseAppsButton == null) {
			browseAppsButton = new JButton();
			browseAppsButton.setFont(buttonFont);
			browseAppsButton.setText("Load Images..");

			browseAppsButton.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {

					cardImageFileChooser = new JFileChooser(currentEpromDir);
					cardImageFileChooser
							.setDialogTitle("Load eprom and/or 16K bank file images into card");
					cardImageFileChooser.setMultiSelectionEnabled(true);
					cardImageFileChooser
							.setFileSelectionMode(JFileChooser.FILES_ONLY);
					cardImageFileChooser.setFileFilter(eprfileFilter);

					int returnVal = cardImageFileChooser.showOpenDialog(Slots.this.getParent());
					if (returnVal == JFileChooser.APPROVE_OPTION) {
						// remember current directory for next time..
						currentEpromDir = cardImageFileChooser.getCurrentDirectory();
						if (cardImageFileChooser.getSelectedFiles().length == 1) {
							String eprFilename = cardImageFileChooser.getSelectedFile().getAbsolutePath();
							if (eprFilename.toLowerCase().lastIndexOf(".epr") == -1) {
								// append ".epr" extension if not specified by user...
								eprFilename += ".epr";
							}
							File eprFile = new File(eprFilename);

							getAppAreaLabel().setText(eprFile.getName());
						} else {
							getAppAreaLabel().setText("Multiple file images");
						}
					} else {
						getAppAreaLabel().setText(defaultAppLoadText);
					}
				}
			});
		}

		return browseAppsButton;
	}

	/**
	 * .bin, .epr and .0 - .63 extension filter when browsing the filing system
	 * for Application or File Cards.
	 */
	private class EpromFileFilter extends FileFilter {

		/** Accept all directories and z88 files */
		public boolean accept(File f) {
			if (f.isDirectory()) {
				return true;
			}

			String extension = getExtension(f);
			if (extension != null) {
				if (extension.equalsIgnoreCase("epr") == true | extension.equalsIgnoreCase("bin") == true) {
					// the Eprom file was polled successfully.
					return true;
				} else {
					try {
						int bankNo = Integer.parseInt(extension);
						if (bankNo >= 0 & bankNo <= 63)
							return true;
						else
							return false;
					} catch (Exception n) {
						// the extension couldn't be evaluated as a number...
						// (it is not a .0 - .63 extension...)
						return false;
					}
				}
			}

			// file didn't have an extension...
			return false;
		}

		/** The description of this filter */
		public String getDescription() {
			return "Z88 Card image files";
		}

		/** Get the extension of a file */
		private String getExtension(File f) {
			String ext = null;
			String s = f.getName();
			int i = s.lastIndexOf('.');

			if (i > 0 && i < s.length() - 1) {
				ext = s.substring(i + 1).toLowerCase();
			}

			return ext;
		}
	}

	/**
	 * Extended Popup menu with context sensitive menu items
	 * that enables the user to import/export files to the file area
	 * of the card.
	 */
	private class CardPopupMenu extends JPopupMenu {
		private static final String expFilesMsg = "Export files from File Area";
		private static final String impFilesMsg = "Import files into File Area";
		private static final String formatFileAreaMsg = "Format File Area";
		private static final String reclaimDelSpaceMsg = "Reclaim deleted space in File Area";
		private static final String markFileDeletedMsg = "Mark file(s) as deleted in File Area";

		private FileArea cardFileArea;
		private int cardSlotNo;
		private JMenuItem importFilesMenuItem;
		private JMenuItem exportFilesMenuItem;
		private JMenuItem formatFileAreaMenuItem;
		private JMenuItem reclaimDelSpaceMenuItem;
		private JMenuItem markFileDeletedMenuItem;

		public CardPopupMenu(int slotNo) {
			super();

			// remember in which slot this card is located...
			cardSlotNo = slotNo;

			add(getImportFilesMenuItem());
			add(getExportFilesMenuItem());
			add(getMarkFileDeletedMenuItem());
			add(getReclaimDelSpaceMenuItem());
			add(getFormatFileAreaMenuItem());
		}

		private boolean isFileAreaAvailable() {
			boolean FileAreaStatus = false;

			if (SlotInfo.getInstance().getFileHeaderBank(cardSlotNo) != -1) {
				// The physical poll of the slot indicates a file area..
				try {
					if (cardFileArea == null) {
						// File Area Management hasn't been instantiated yet...
							cardFileArea = new FileArea(cardSlotNo);
					} else {
						// refresh file list in file area
						cardFileArea.scanFileArea();
					}
				} catch (FileAreaNotFoundException e) {
					// this will never get called
				}

				FileAreaStatus = true;
			}

			return FileAreaStatus;
		}

		private JMenuItem getExportFilesMenuItem() {
			if (exportFilesMenuItem == null) {
				exportFilesMenuItem = new JMenuItem();
				exportFilesMenuItem.setText(expFilesMsg);
				exportFilesMenuItem.addActionListener(new ActionListener() {
					public void actionPerformed(ActionEvent e) {
						try {

							// get a list of filenames and display it in a JList widget
							// which the user can select from...
							JList list = new JList(cardFileArea.getFileEntryNames());
							list.setSelectionMode(ListSelectionModel.MULTIPLE_INTERVAL_SELECTION);
							JScrollPane scrollListPane = new JScrollPane();
							scrollListPane.setViewportView(list);

							if (JOptionPane.showConfirmDialog(Slots.this, scrollListPane,
								expFilesMsg + " in slot " + cardSlotNo, JOptionPane.YES_NO_OPTION) == JOptionPane.YES_OPTION) {

								JFileChooser chooser = new JFileChooser(currentFilesDir);
								chooser.setDialogTitle(expFilesMsg + " in slot " + cardSlotNo + " to filing system");
								chooser.setMultiSelectionEnabled(false);
								chooser.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);

								int returnVal = chooser.showSaveDialog(Slots.this);
								if (returnVal == JFileChooser.APPROVE_OPTION) {
									int totalExportedFiles = 0;
									currentFilesDir = chooser.getSelectedFile();
									String exportDirectory = chooser.getSelectedFile().getAbsolutePath();

									if (list.getSelectedIndex() == -1) {
										// no selection made, export all active files..
										totalExportedFiles = list.getModel().getSize();
										for(int i = 0; i < list.getModel().getSize(); i++) {
											String selectedFilename = (String) list.getModel().getElementAt(i);
											FileEntry fe = cardFileArea.getFileEntry(selectedFilename);
											cardFileArea.exportFileEntry(fe, exportDirectory);
										 }
									} else {
										// export only selected files...
										int selectedItems[] = list.getSelectedIndices();
										totalExportedFiles = selectedItems.length;

										for (int f=0; f<selectedItems.length; f++) {
											list.setSelectedIndex(selectedItems[f]);
											String selectedFilename = (String) list.getSelectedValue();
											FileEntry fe = cardFileArea.getFileEntry(selectedFilename);
											cardFileArea.exportFileEntry(fe, exportDirectory);
										}
									}

									JOptionPane.showMessageDialog(Slots.this,
											totalExportedFiles + " file(s) were exported to " + exportDirectory,
											expFilesMsg + " in slot " + cardSlotNo,
											JOptionPane.INFORMATION_MESSAGE);
								}
							}
						} catch (FileAreaNotFoundException e1) {
							// this exception will never get called...
						} catch (IOException e2) {
							JOptionPane.showMessageDialog(Slots.this, e2.getMessage(),
									expFilesMsg + " in slot " + cardSlotNo +
									" to filing system", JOptionPane.ERROR_MESSAGE);
						}

					}
				});
			}

			return exportFilesMenuItem;
		}

		private JMenuItem getImportFilesMenuItem() {
			if (importFilesMenuItem == null) {
				importFilesMenuItem = new JMenuItem();
				importFilesMenuItem.setText(impFilesMsg);

				importFilesMenuItem.addActionListener(new ActionListener() {
					public void actionPerformed(ActionEvent e) {
						File selectedFiles[] = null;

						try {
							JFileChooser chooser = new JFileChooser(currentFilesDir);
							chooser.setDialogTitle(impFilesMsg);
							chooser.setMultiSelectionEnabled(true);
							chooser.setFileSelectionMode(JFileChooser.FILES_ONLY);

							if (chooser.showOpenDialog(Slots.this.getParent()) == JFileChooser.APPROVE_OPTION) {
								// remember current directory for next time..
								currentFilesDir = chooser.getCurrentDirectory();

								selectedFiles = chooser.getSelectedFiles();
								// import selected files into file area...
								for (int f=0; f<selectedFiles.length; f++) {
									cardFileArea.importHostFile(selectedFiles[f]);
								}
							}

							JOptionPane.showMessageDialog(Slots.this,
									selectedFiles.length + " file(s) were imported",
									impFilesMsg + " in slot " + cardSlotNo,
									JOptionPane.INFORMATION_MESSAGE);

						} catch (FileAreaNotFoundException e1) {
							// this exception will never get called...
						} catch (FileAreaExhaustedException e2) {
							JOptionPane.showMessageDialog(Slots.this, "File Area exhausted during import",
							impFilesMsg + " in slot " + cardSlotNo,
							JOptionPane.ERROR_MESSAGE);
						} catch (IOException e3) {
							JOptionPane.showMessageDialog(Slots.this, e3.getMessage(),
							impFilesMsg + " in slot " + cardSlotNo,
							JOptionPane.ERROR_MESSAGE);
						}
					}
				});
			}

			return importFilesMenuItem;
		}

		private JMenuItem getFormatFileAreaMenuItem() {
			if (formatFileAreaMenuItem == null) {
				formatFileAreaMenuItem = new JMenuItem();
				formatFileAreaMenuItem.setText(formatFileAreaMsg);
				formatFileAreaMenuItem.addActionListener(new ActionListener() {
					public void actionPerformed(ActionEvent e) {
                		if (Z88.getInstance().getProcessorThread() != null) {
                    		// cannot format while Z88 is running...
                    		JOptionPane.showMessageDialog(null, "Cannot format file are while Z88 is running.");
                    		return;
                		}

						if (JOptionPane.showConfirmDialog(Slots.this, "Format file area?\nWarning: All files will be lost.",
								formatFileAreaMsg + " in slot " + cardSlotNo, JOptionPane.YES_NO_OPTION) == JOptionPane.YES_OPTION) {
							if (FileArea.create(cardSlotNo, true) == true)
								JOptionPane.showMessageDialog(Slots.this,
										"File area was successfully formatted",
										formatFileAreaMsg + " in slot " + cardSlotNo,
										JOptionPane.INFORMATION_MESSAGE);
							else
								JOptionPane.showMessageDialog(Slots.this,
										"An error occurred. File area was not formatted",
										formatFileAreaMsg + " in slot " + cardSlotNo,
										JOptionPane.ERROR_MESSAGE);
						}
					}
				});
			}

			return formatFileAreaMenuItem;
		}

		private JMenuItem getReclaimDelSpaceMenuItem() {
			if (reclaimDelSpaceMenuItem == null) {
				reclaimDelSpaceMenuItem = new JMenuItem();
				reclaimDelSpaceMenuItem.setText(reclaimDelSpaceMsg);
				reclaimDelSpaceMenuItem.addActionListener(new ActionListener() {
					public void actionPerformed(ActionEvent e) {

						if (JOptionPane.showConfirmDialog(Slots.this, "Reclaim deleted file space?",
								reclaimDelSpaceMsg + " in slot " + cardSlotNo, JOptionPane.YES_NO_OPTION) == JOptionPane.YES_OPTION) {
							try {
								// then reclaim deleted file space..
								cardFileArea.reclaimDeletedFileSpace();

								JOptionPane.showMessageDialog(Slots.this,
										"Files marked as deleted were removed from File Area.",
										reclaimDelSpaceMsg + " in slot " + cardSlotNo,
										JOptionPane.INFORMATION_MESSAGE);
							} catch (FileAreaNotFoundException e1) {
								// this exception is never called..
							}
						}
					}
				});
			}

			return reclaimDelSpaceMenuItem;
		}

		private JMenuItem getMarkFileDeletedMenuItem() {
			if (markFileDeletedMenuItem == null) {
				markFileDeletedMenuItem = new JMenuItem();
				markFileDeletedMenuItem.setText(markFileDeletedMsg);
				markFileDeletedMenuItem.addActionListener(new ActionListener() {
					public void actionPerformed(ActionEvent e) {

						try {
							// get a list of filenames and display it in a JList widget
							// which the user can select from...
							JList list = new JList(cardFileArea.getFileEntryNames());
							list.setSelectionMode(ListSelectionModel.MULTIPLE_INTERVAL_SELECTION);
							JScrollPane scrollListPane = new JScrollPane();
							scrollListPane.setViewportView(list);

							if (JOptionPane.showConfirmDialog(Slots.this, scrollListPane,
									markFileDeletedMsg + " in slot " + cardSlotNo, JOptionPane.YES_NO_OPTION) == JOptionPane.YES_OPTION) {

								if (list.getSelectedIndex() == -1) {
									// no selection made, export all active files..
									JOptionPane.showMessageDialog(Slots.this,
											"No files were marked to be 'deleted'.",
											markFileDeletedMsg + " in slot " + cardSlotNo,
											JOptionPane.INFORMATION_MESSAGE);
								} else {
									// only selected files will be marked as deleted...
									int selectedItems[] = list.getSelectedIndices();

									for (int f=0; f<selectedItems.length; f++) {
										list.setSelectedIndex(selectedItems[f]);
										String selectedFilename = (String) list.getSelectedValue();
										cardFileArea.markAsDeleted(selectedFilename);
									}

									JOptionPane.showMessageDialog(Slots.this,
											selectedItems.length + " files were marked as deleted.",
											markFileDeletedMsg + " in slot " + cardSlotNo,
											JOptionPane.INFORMATION_MESSAGE);
								}
							}

						} catch (FileAreaNotFoundException e1) {
							// this exception is never called..
						}
					}
				});
			}

			return markFileDeletedMenuItem;
		}


		/**
		 * If the card contains a file area,
		 * a popup menu is displayed at the position x,y in
		 * the coordinate space of the component invoker.
		 *
		 * @param invoker
		 * @param x
		 * @param y
		 */
		public void show(Component invoker, int x, int y) {
			if (isFileAreaAvailable() == true) {
				getImportFilesMenuItem().setEnabled(true);
				try {
					if (cardFileArea.getActiveFileCount() > 0) {
						getExportFilesMenuItem().setEnabled(true);
						getMarkFileDeletedMenuItem().setEnabled(true);
					} else {
						getExportFilesMenuItem().setEnabled(false);
						getMarkFileDeletedMenuItem().setEnabled(false);
					}

					if (cardFileArea.getDeletedFileCount() > 0) {
						getReclaimDelSpaceMenuItem().setEnabled(true);
					} else {
						getReclaimDelSpaceMenuItem().setEnabled(false);
					}
				} catch (FileAreaNotFoundException e) {
					// This exception is never reached...
				}

				super.show(invoker, x, y);
			} else {
				if (FileArea.isCreateable(cardSlotNo) == true) {
					// a file area is not available, but can be created on card...
					getImportFilesMenuItem().setEnabled(false);
					getExportFilesMenuItem().setEnabled(false);
					getMarkFileDeletedMenuItem().setEnabled(false);
					getReclaimDelSpaceMenuItem().setEnabled(false);
					getFormatFileAreaMenuItem().setEnabled(true);

					super.show(invoker, x, y);
				}
			}
		}
	}

	private MouseAdapter addPopup(Component component, final JPopupMenu popup) {
		MouseAdapter mouseAdapter = new MouseAdapter() {
			public void mousePressed(MouseEvent e) {
				if (e.isPopupTrigger())
					showMenu(e);
			}
			public void mouseReleased(MouseEvent e) {
				if (e.isPopupTrigger())
					showMenu(e);
			}
			private void showMenu(MouseEvent e) {
				popup.show(e.getComponent(), e.getX(), e.getY());
			}
		};

		component.addMouseListener(mouseAdapter);
		return mouseAdapter; // return a reference, for future removal.
	}

	/**
	 * Remove right-click pop-up menu from a component
	 *
	 * @param component
	 * @param mouseAdapter
	 */
	private void removePopup(Component component, MouseAdapter mouseAdapter) {
		if (mouseAdapter != null)
			component.removeMouseListener(mouseAdapter);
	}
}