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
import java.awt.Dimension;
import java.awt.Font;
import java.awt.Insets;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.File;
import java.io.IOException;

import javax.swing.BoxLayout;
import javax.swing.DefaultComboBoxModel;
import javax.swing.JButton;
import javax.swing.JComboBox;
import javax.swing.JFileChooser;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.SwingConstants;
import javax.swing.border.EtchedBorder;
import javax.swing.border.TitledBorder;

import net.sourceforge.z88.datastructures.SlotInfo;
import net.sourceforge.z88.screen.Z88display;

/**
 * Gui management of insertion and removal of cards in internal and external Z88
 * slots (0 - 3).
 */
public class Slots extends JPanel {

	private static final String installRomMsg = "Install new ROM in slot 0?\nWARNING: Installing a ROM will automatically perform a hard reset!";

	private static final String installRamMsg = "Install new RAM into slot 0?\nWARNING: Installing RAM will automatically perform a hard reset!";

	private static final DefaultComboBoxModel newCardTypes = new DefaultComboBoxModel(
			new String[] { "RAM", "EPROM", "INTEL FLASH", "AMD FLASH" });

	private static final DefaultComboBoxModel ram0Sizes = new DefaultComboBoxModel(
			new String[] { "32K", "128K", "256K", "512K" });

	private static final DefaultComboBoxModel ramCardSizes = new DefaultComboBoxModel(
			new String[] { "32K", "128K", "512K", "1024K" });

	private static final DefaultComboBoxModel eprSizes = new DefaultComboBoxModel(
			new String[] { "32K", "128K", "256K" });

	private static final DefaultComboBoxModel amdFlashSizes = new DefaultComboBoxModel(
			new String[] { "128K", "512K", "1024" });

	private static final DefaultComboBoxModel intelFlashSizes = new DefaultComboBoxModel(
			new String[] { "512K", "1024" });

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

	Memory memory;

	public Slots() {
		super();
		memory = Memory.getInstance();

		setBackground(Color.BLACK);

		setLayout(new BoxLayout(this, BoxLayout.X_AXIS));
		add(getSlot0Panel());
		add(getSlot1Panel());
		add(getSlot2Panel());
		add(getSlot3Panel());
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
		Color foregroundColor = Color.WHITE; // default empty slot colours
		Color backgroundColor = Color.BLACK;
		slotNo &= 3;

		int slotType = SlotInfo.getInstance().getCardType(slotNo);
		switch (slotType) {
		case SlotInfo.EmptySlot:
			slotText = "Empty";
			break;
		case SlotInfo.AmdFlashCard:
			slotText = "AMD FLASH";
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
				slotText += (" " + (memory.getExternalCardSize(slotNo) * 16) + "K");
				foregroundColor = Color.BLACK;
				backgroundColor = Color.LIGHT_GRAY;
			}
		}

		switch (slotNo) {
		case 0:
			getRom0Button().setText(
					"ROM " + (memory.getInternalRomSize() * 16) + "K");
			getRam0Button().setText(
					"RAM " + (memory.getInternalRamSize() * 16) + "K");
			break;
		case 1:
			getSlot1Button().setText(slotText);
			getSlot1Button().setForeground(foregroundColor);
			getSlot1Button().setBackground(backgroundColor);
			break;
		case 2:
			getSlot2Button().setText(slotText);
			getSlot2Button().setForeground(foregroundColor);
			getSlot2Button().setBackground(backgroundColor);
			break;
		case 3:
			getSlot3Button().setText(slotText);
			getSlot3Button().setForeground(foregroundColor);
			getSlot3Button().setBackground(backgroundColor);
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
			rom0Button.setPreferredSize(new Dimension(87, 20));
			rom0Button.setMaximumSize(new Dimension(87, 20));
			rom0Button.setHorizontalAlignment(SwingConstants.LEFT);
			rom0Button.setFont(buttonFont);
			rom0Button.setForeground(Color.BLACK);
			rom0Button.setBackground(Color.LIGHT_GRAY);
			rom0Button.setMargin(new Insets(2, 4, 2, 4));

			rom0Button.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					Blink.getInstance().signalFlapOpened();

					if (JOptionPane
							.showConfirmDialog(Slots.this, installRomMsg) == JOptionPane.YES_OPTION) {
						JFileChooser chooser = new JFileChooser(new File(System
								.getProperty("user.dir")));
						chooser
								.setDialogTitle("Load/install Z88 ROM into slot 0");
						chooser.setMultiSelectionEnabled(false);
						chooser.setFileSelectionMode(JFileChooser.FILES_ONLY);

						int returnVal = chooser.showOpenDialog(Slots.this);
						if (returnVal == JFileChooser.APPROVE_OPTION) {
							File romFile = new File(chooser.getSelectedFile()
									.getAbsolutePath());

							try {
								memory.loadRomBinary(romFile);
								// ROM installed, do a hard reset
								Blink.getInstance().pressHardReset(); 
							} catch (IOException e1) {
								JOptionPane.showMessageDialog(Slots.this,
										"Selected file couldn't be opened!");
								Blink.getInstance().signalFlapClosed();
							} catch (IllegalArgumentException e2) {
								JOptionPane.showMessageDialog(Slots.this,
										"Selected file was not a Z88 ROM!");
								Blink.getInstance().signalFlapClosed();
							}
						}
					} else {
						// User aborted...
						Blink.getInstance().signalFlapClosed();
					}

					refreshSlotInfo(0);
					Z88display.getInstance().grabFocus();
				}
			});
		}

		return rom0Button;
	}

	private JButton getRam0Button() {
		if (ram0Button == null) {
			ram0Button = new JButton();
			ram0Button.setPreferredSize(new Dimension(87, 20));
			ram0Button.setMaximumSize(new Dimension(87, 20));
			ram0Button.setHorizontalAlignment(SwingConstants.LEFT);
			ram0Button.setFont(buttonFont);
			ram0Button.setForeground(Color.BLACK);
			ram0Button.setBackground(Color.LIGHT_GRAY);
			ram0Button.setMargin(new Insets(2, 4, 2, 4));

			ram0Button.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					Blink.getInstance().signalFlapOpened();

					if (JOptionPane
							.showConfirmDialog(Slots.this, installRamMsg) == JOptionPane.YES_OPTION) {
						getCardSizeComboBox().setModel(ram0Sizes);
						JOptionPane.showMessageDialog(Slots.this,
								getCardSizeComboBox(),
								"Select RAM size for slot 0",
								JOptionPane.NO_OPTION);

						String size = (String) ram0Sizes.getElementAt(getCardSizeComboBox().getSelectedIndex());
						memory.insertRamCard(Integer.parseInt(size.substring(0,size.indexOf("K"))) * 1024, 0);
						Blink.getInstance().pressHardReset();
					} else {
						// User aborted...
						Blink.getInstance().signalFlapClosed();
					}

					refreshSlotInfo(0);
					Z88display.getInstance().grabFocus();
				}
			});
		}

		return ram0Button;
	}

	private JButton getSlot1Button() {
		if (slot1Button == null) {
			slot1Button = new JButton();
			slot1Button.setHorizontalAlignment(SwingConstants.LEFT);
			slot1Button.setPreferredSize(new Dimension(139, 20));
			slot1Button.setMaximumSize(new Dimension(139, 20));
			slot1Button.setFont(buttonFont);
			slot1Button.setMargin(new Insets(2, 4, 2, 4));
			slot1Button.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					manageSlotCard((JButton) e.getSource(), 1);
				}
			});
		}

		return slot1Button;
	}

	private JButton getSlot2Button() {
		if (slot2Button == null) {
			slot2Button = new JButton();
			slot2Button.setHorizontalAlignment(SwingConstants.LEFT);
			slot2Button.setPreferredSize(new Dimension(139, 20));
			slot2Button.setMaximumSize(new Dimension(139, 20));
			slot2Button.setFont(buttonFont);
			slot2Button.setMargin(new Insets(2, 4, 2, 4));
			slot2Button.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					manageSlotCard((JButton) e.getSource(), 2);
				}
			});
		}

		return slot2Button;
	}

	private JButton getSlot3Button() {
		if (slot3Button == null) {
			slot3Button = new JButton();
			slot3Button.setHorizontalAlignment(SwingConstants.LEFT);
			slot3Button.setPreferredSize(new Dimension(139, 20));
			slot3Button.setMaximumSize(new Dimension(139, 20));
			slot3Button.setFont(buttonFont);
			slot3Button.setMargin(new Insets(2, 4, 2, 4));
			slot3Button.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					manageSlotCard((JButton) e.getSource(), 3);
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
	 * Insert/remove a card (RAM/EPROM/FLASH) into slot.
	 * <p>
	 * Insertion may be a new (created) card or loaded from the filing system.
	 * Equally, an Eprom/Flash card may be removed from the slot and saved as an
	 * .epr file (Ram card has no meaning to be saved).
	 * <p>
	 * Finally, it may be possible to save a copy of an inserted Eprom/Flash
	 * Card as a file on the fly.
	 * 
	 * @param slotNo
	 */
	private void manageSlotCard(JButton slotButton, int slotNo) {
		int slotType = SlotInfo.getInstance().getCardType(slotNo);

		if (slotType == SlotInfo.EmptySlot) {
			// slot is empty, a card may be inserted;
			// load a card .Epr file or insert a new card (type)
			getCardTypeComboBox().setModel(newCardTypes);
			getCardSizeComboBox().setModel(ramCardSizes);
			getCardTypeComboBox().setSelectedIndex(0); // default RAM card
			getCardSizeComboBox().setSelectedIndex(0); // default 32K size

			getCardTypeComboBox().addActionListener(new ActionListener() {
				// when the Card type is changed, also change available size for
				// Card type
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
					}
				}
			});

			Blink.getInstance().signalFlapOpened();
			if (JOptionPane.showConfirmDialog(Slots.this, getNewCardPanel(),
					"Insert new card into slot " + slotNo,
					JOptionPane.NO_OPTION) == JOptionPane.YES_OPTION) {
				String size = (String) getCardSizeComboBox().getModel().getElementAt(getCardSizeComboBox().getSelectedIndex());
				
				switch (getCardTypeComboBox().getSelectedIndex()) {
				case 0:
					// insert selected RAM Card
					memory.insertRamCard(Integer.parseInt(size.substring(0,size.indexOf("K"))) * 1024, slotNo);
					break;
				case 1:
					// insert selected (UV) EPROM Card "32K", "128K", "256K"
					memory.insertEprCard(slotNo, Integer.parseInt(size.substring(0,size.indexOf("K"))), "27C");
					break;
				case 2:
					// insert selected Intel Flash Card sizes
					memory.insertEprCard(slotNo, Integer.parseInt(size.substring(0,size.indexOf("K"))), "28F");
					break;
				case 3:
					// insert selected Amd Flash Card sizes
					memory.insertEprCard(slotNo, Integer.parseInt(size.substring(0,size.indexOf("K"))), "29F");
					break;
				}

				refreshSlotInfo(slotNo);
				Z88display.getInstance().grabFocus();
			}

			Blink.getInstance().signalFlapClosed();
		} else {
			// remove a card, or for Eprom/Flash cards, and/or save a copy
			// of the card to an .Epr file...
		}
	}

	private JPanel getNewCardPanel() {
		if (newCardPanel == null) {
			newCardPanel = new JPanel();
			newCardPanel.setBorder(new TitledBorder(new EtchedBorder(
					EtchedBorder.LOWERED), "New Card",
					TitledBorder.DEFAULT_JUSTIFICATION,
					TitledBorder.DEFAULT_POSITION, null, null));
			newCardPanel.add(getCardTypeLabel());
			newCardPanel.add(getCardTypeComboBox());
			newCardPanel.add(getCardSizeLabel());
			newCardPanel.add(getCardSizeComboBox());
		}
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
}
