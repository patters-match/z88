How to install EazyLink popdown on your Z88
-------------------------------------------
 
1) Get latest RomCombiner from Sourceforge: http://sourceforge.net/projects/z88/files/Z88%20Applications/RomCombiner%20V2.10.zip/download
2) Unzip the RomCombiner archive.
3) Transfer "RomCombiner.bas", "RomUtil.bas" & "romcombiner.bin" files to your Z88.
   Make sure that the files are transfered binary intact (no byte translation or linefeed conversion)
OR
   Transfer bundled Romcombiner program as part of this EazyLink ZIP archive release.
   
4) Transfer "eazylink.63" binary file to your Z88 (that was part of this ZIP file)
   Make sure that the file is transfered binary intact (no byte translation or linefeed conversion).

5) On your Z88, create a BBC BASIC application instance, #B
6) type: RUN"ROMCOMBINER.BAS"

7) Select B), "Blow image files to blank EPROM"
8) Depending on your type of card, select a flash or UV Eprom card
9) Type slot number of where your blank card has been inserted (typically in slot 3)
10) "Card name?" is prompted. Type "EAZYLINK"
11) "Full ROM or Range of banks?" is prompted. Type F.

Romcombiner will now write the popdown code ("Blowing bank 63" message) to the card.
Go to index, and re-insert card. EazyLink popdown is now available. Type []L to start it..

If you want to merge Eazylink with existing applications on a card, you have to copy those
first, then combine / add the EazyLink popdown code bank to that list, and finally re-blow
all banks to a blank Flash or UV Eprom card.


EazyLink project wiki on Internet
-------------------------------------------
https://cambridgez88.jira.com/wiki/x/AgBN

Here, you will find latest news about the popdown.

Latest news about Z88 project:
https://cambridgez88.jira.com
