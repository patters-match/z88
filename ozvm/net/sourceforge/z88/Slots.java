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

import javax.swing.BoxLayout;
import javax.swing.JButton;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.SwingConstants;
import javax.swing.border.EtchedBorder;
import javax.swing.border.TitledBorder;

import net.sourceforge.z88.datastructures.SlotInfo;

/**
 * Gui management of insertion and removal of cards in internal and external Z88
 * slots (0 - 3).
 */
public class Slots extends JPanel {
	
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

	
	public Slots() {
		super();

		setLayout(new BoxLayout(this, BoxLayout.X_AXIS));
		add(getSlot0Panel());
		add(getSlot1Panel());
		add(getSlot2Panel());
		add(getSlot3Panel());
	}

	/**
	 * Update the button caption text, reflecting the contents
	 * of all slots (0 - 3).
	 */
	public void refreshSlotInfo() {
		for (int s=0; s<4; s++) {
			refreshSlotInfo(s);
		}
	}

	/**
	 * Update the button caption text, reflecting the contents
	 * of the specified slot.
	 * 
	 * @param slotNo (0 - 3)
	 */
	public void refreshSlotInfo(int slotNo) {
		Memory memory =	Memory.getInstance();
		String slotText = null;
		Color foregroundColor = Color.WHITE;	// default empty slot colours
		Color backgroundColor = Color.BLACK;
		slotNo &= 3;

		int slotType = SlotInfo.getInstance().getCardType(slotNo);
		switch(slotType) {
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
				slotText += (" " + (memory.getExternalCardSize(slotNo)*16) + "K");
				foregroundColor = Color.BLACK;
				backgroundColor = Color.LIGHT_GRAY;
			}
		}
		
		switch (slotNo) {
			case 0:
				getRom0Button().setText("ROM " + (memory.getInternalRomSize()*16) + "K");
				getRam0Button().setText("RAM " + (memory.getInternalRamSize()*16) + "K");
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
			rom0Button.setPreferredSize(new Dimension(90, 20));
			rom0Button.setMaximumSize(new Dimension(90, 20));
			rom0Button.setHorizontalAlignment(SwingConstants.LEFT);
			rom0Button.setFont(buttonFont);
			rom0Button.setForeground(Color.BLACK);
			rom0Button.setBackground(Color.LIGHT_GRAY);
			rom0Button.setMargin(new Insets(2, 4, 2, 4));
		}

		return rom0Button;
	}

	private JButton getRam0Button() {
		if (ram0Button == null) {
			ram0Button = new JButton();
			ram0Button.setPreferredSize(new Dimension(90, 20));
			ram0Button.setMaximumSize(new Dimension(90, 20));
			ram0Button.setHorizontalAlignment(SwingConstants.LEFT);
			ram0Button.setFont(buttonFont);
			ram0Button.setForeground(Color.BLACK);
			ram0Button.setBackground(Color.LIGHT_GRAY);
			ram0Button.setMargin(new Insets(2, 4, 2, 4));
		}

		return ram0Button;
	}

	private JButton getSlot1Button() {
		if (slot1Button == null) {
			slot1Button = new JButton();
			slot1Button.setHorizontalAlignment(SwingConstants.LEFT);
			slot1Button.setPreferredSize(new Dimension(140, 20));
			slot1Button.setMaximumSize(new Dimension(140, 20));
			slot1Button.setFont(buttonFont);
			slot1Button.setMargin(new Insets(2, 4, 2, 4));
		}

		return slot1Button;
	}

	private JButton getSlot2Button() {
		if (slot2Button == null) {
			slot2Button = new JButton();
			slot2Button.setHorizontalAlignment(SwingConstants.LEFT);
			slot2Button.setPreferredSize(new Dimension(140, 20));
			slot2Button.setMaximumSize(new Dimension(140, 20));
			slot2Button.setFont(buttonFont);
			slot2Button.setMargin(new Insets(2, 4, 2, 4));
		}

		return slot2Button;
	}

	private JButton getSlot3Button() {
		if (slot3Button == null) {
			slot3Button = new JButton();
			slot3Button.setHorizontalAlignment(SwingConstants.LEFT);
			slot3Button.setPreferredSize(new Dimension(140, 20));
			slot3Button.setMaximumSize(new Dimension(140, 20));
			slot3Button.setFont(buttonFont);
			slot3Button.setMargin(new Insets(2, 4, 2, 4));
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
}
