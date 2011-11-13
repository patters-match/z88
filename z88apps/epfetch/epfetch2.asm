; *************************************************************************************
; EP-Fetch2
; (C) Garry Lancaster / Jorma Oksanen, 1993-2005
;
; EP-Fetch2 is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; EP-Fetch2 is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with EP-Fetch2;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
;
; *************************************************************************************

        Module  ep3

        include "director.def"
        include "dor.def"
        include "error.def"
        include "fileio.def"
        include "integer.def"
        include "memory.def"
        include "stdio.def"
        include "tokens.def"

        include "sysvar.def"

xdef    EPFetchDOR

defc    BANK    = 63                    ; we are here

        org     $C000

defc    LINK_BANK = 0                   ; next app is here
defc    LINK_ADDR = 0

defc    SafeWorkspaceSize       = $171
defc    SafeWorkspaceStart      = $1ffe - SafeWorkspaceSize


DEFVARS         SafeWorkspaceStart
{
FilePositions   ds.b    3*64                    ; $00C0
WildBuffer      ds.b    16                      ; $00d0
NumBuffer       ds.b    10                      ; $00da
NameBuffer      ds.b    128                     ; $015a

DataPtr         ds.b    3                       ; $015d
FileSize        ds.b    4                       ; $0161

ListDeleted     ds.b    1
PrintC          ds.b    1
Printing        ds.b    1
FirstPO         ds.b    1                       ; $0165

MaxFNameLen     ds.b    1

FileIndex       ds.w    1
NumFiles        ds.w    1                       ; $016a
NumBytes        ds.b    4                       ; $016e
CardBanks       ds.b    1                       ; $016f
EPROMbase       ds.b    1
S1Bank          ds.b    1                       ; $0171
}


defc    CMD_FETCH       = CR
defc    CMD_ESC         = 1
defc    CMD_RESCAN      = 2
defc    CMD_SAVELIST    = 3
defc    CMD_PRINTLIST   = 4
defc    CMD_MEM         = 5

;       file entry has the form:
;
;1 byte����� n���������� length of filename
;1 byte����� x���������� '/' for latest version, $00 for old (deleted) version
;n-1 bytes�� 'xxxx'����� filename
;4 bytes���� m���������� length of file (least significant byte first)
;m bytes���������������� body of file


.EPFetchDOR

        defp    0,0                             ; parent
        defp    LINK_ADDR,LINK_BANK             ; brother
        defp    0,0                             ; son

        defb    DM_ROM,46

        defb    '@',18
        defb    0,0
        defb    'F'                             ; cmd letter
        defb    0                               ; cont. RAM
        defw    0                               ; env. overhead
        defw    0                               ; unsafe mem
        defw    SafeWorkspaceSize               ; safe mem
        defw    EPFetch                         ; entry point
        defb    0,0,0,BANK                      ; bindings
        defb    8                               ; type=popdown
        defb    3                               ; inversed caps

        defb    'H',12
        defp    sTopics, BANK
        defp    sCommands, BANK
        defp    sHelp, BANK
        defp    0, 0

        defb    'N',10
        defm    "EP-Fetch2",0
        defb    -1

;       ----

.sTopics        defb 0

.sTPh           defb sTP1-sTPh
                defm "Printing"
                defb >(sHelp2-sHelp),<(sHelp2-sHelp)
                defb $12
                defb sTP1-sTPh

.sTP1           defb sTPe-sTP1
                defm "Commands"
                defb 0
                defb sTPe-sTP1

.sTPe           defb 0

;       ----

.sCommands      defb 0

.sH1            defb sH2-sH1
                defb 0,0
                defm "Serial settings"
                defb >(sH1txt-sHelp),<(sH1txt-sHelp)
                defb $10
                defb sH2-sH1

.sH2            defb sHx-sH2
                defb 0,0
                defm "Printer settings"
                defb >(sH2txt-sHelp),<(sH2txt-sHelp)
                defb $10
                defb sHx-sH2

.shx            defb 1

.sCfetch        defb sCrescan-sCfetch
                defb CMD_FETCH
                defb $E1, 0
                defm "Fetch a file"
                defb 0
                defb sCrescan-sCfetch

.sCrescan       defb sCfiles-sCrescan
                defb CMD_RESCAN
                defb $D1, 0
                defm "Re-scan EPROM"
                defb 0
                defb sCfiles-sCrescan

.sCfiles        defb sCprint-sCfiles
                defb CMD_SAVELIST
                defm "FS", 0
                defm "Save file list"
                defb 0
                defb sCprint-sCfiles

.sCprint        defb sCmem-sCprint
                defb CMD_PRINTLIST
                defm "PO", 0
                defm "Print file list"
                defb 0
                defb sCmem-sCprint

.sCmem          defb sCesc-sCmem
                defb CMD_MEM
                defm "M", 0
                defm "Free memory"
                defb 0
                defb sCesc-sCmem

.sCesc          defb sCprev-sCesc
                defb CMD_ESC
                defb ESC, 0
                defm "Escape"
                defb 0
                defb sCprev-sCesc

.sCprev         defb sCnext-sCprev
                defb IN_UP
                defb IN_UP, 0
                defm "Previous file"
                defb 1
                defb sCnext-sCprev

.sCnext         defb sCprevpg-sCnext
                defb IN_DWN
                defb IN_DWN, 0
                defm "Next file"
                defb 0
                defb sCprevpg-sCnext

.sCprevpg       defb sCnextpg-sCprevpg
                defb IN_SUP
                defb IN_SUP, 0
                defm "Previous page"
                defb 0
                defb sCnextpg-sCprevpg

.sCnextpg       defb sCtop-sCnextpg
                defb IN_SDWN
                defb IN_SDWN, 0
                defm "Next page"
                defb 0
                defb sCtop-sCnextpg

.sCtop          defb sCbottom-sCtop
                defb IN_DUP
                defb IN_DUP, 0
                defm "First file"
                defb 0
                defb sCbottom-sCtop

.sCbottom       defb sC-sCbottom
                defb IN_DDWN
                defb IN_DDWN, 0
                defm "Last file"
                defb 0
                defb sC-sCbottom

                defb 0

;       ----

.PrintHelp

;       max. 62 chars/line

.sHelp          defm    $7F
                defm    "This utility is for EPROMs and Flash EPROMs.",$7f
                defm    "To fetch a file move bar over the filename required.",$7f
                defm    "Deleted files are shown in ",1,"T","tiny text",1,"T"," and preceeded by -",$7f
                defm    "The printing and listing of filenames is supported.",$7f,$7f
                defm    1,"T","Modified GWL 1998-99, JO 2004-05",0


.sHelp2         defm    1,"2JL",1,"2L!",$7f
                defm    "This topic has some suggestions in case you have problems",$7f
                defm    "with print out.",0


.sH1txt         defm    1,"2JL",1,"2L!",$7f
                defm    "Check Panel 'baud rates', 'Parity' and 'Xon/Xoff' settings.",$7f
                defm    "If you don't know the required settings for your printer,",$7f
                defm    "try 'Parity' ",1,"BNone",1,"B, 'Xon/Xoff' ",1,"BNo",1,"B.",0

.sH2txt         defm    1,"2JL",1,"2L!",$7f
                defm    "Check PrinterEd (Page 2) Printer 'on/off' sequences.",$7f
                defm    "If you don't know correct settings, try clearing both of",$7f
                defm    "them.",$7f
                defm    $7f
                defm    "If line feeds don't work correctly, try toggling the",$7f
                defm    "'Allow Line feed.'",0


.EPFetch
        xor     a
        ld      b, a
        ld      hl, ErrHandler
        OZ      OS_Erh
        ld      a, SC_ENA
        OZ      OS_Esc                          ; Enable error detection

        call    KPrint
        ; clear whole display area

        defm    1,"6#1",$20+50,$20+0,$20+3,$20+8
        defm    1,"2C1"

        ; draw file area title

        defm    1,"7#1",$20+1,$20+0,$20+50,$20+8,$83
        defm    1,"2C1", 1,"2JC"
        defm    1,"3+TU","EPROM FILES",13
        defm    1,"R",1,"2A",$20+50

        ; real file area - 7 lines

        defm    1,"7#1",$20+1,$20+1,$20+50,$20+7,$81

        ; draw status area title

        defm    1,"7#2",$20+50+3,$20+0,$20+40,$20+8,$83
        defm    1,"2C2", 1,"2JC", 1,"3+TU"
        defm    "STATUS",13
        defm    1,"R",1,"2A",$20+40

        ; real status area - 5 lines

        defm    1,"7#2",$20+50+3,$20+3,$20+40,$20+5,$81
        defm    1,"2C2", 1,"S"          ; vertical scrolling

        ; status header showing files / bytes

        defm    1,"7#3",$20+50+3,$20+1,$20+40,$20+2,$81,0

        call    FirstSlot

;       DE=top file, C=cursor Y

.m_1
        call    HandleInput
        jr      m_1

.ErrHandler
        ret     z
        cp      RC_Esc
        jr      nz, erh_2
        OZ      OS_Esc                          ; ack ESC
.erh_1
        cp      a                               ; Fc=0
        ret
.erh_2
        cp      RC_Quit
        jr      nz, erh_1

.Exit
        xor     a
        OZ      OS_Bye                          ; Application exit

;       ----

.NoFiles
        call    KPrint
        defm    12,"No files",0
        ld      hl, AnyKey_txt
        jr      AnyKey

.NoEPROM
        ld      hl, NoEPROM_txt
.AnyKey
        call    PrintString
        call    ReadKey
        jr      z, AskSlot
        jr      c, Exit
        jr      AskSlot

;       ----
.FirstSlot
        ld      a, 3
        call    IsEPROM
        jr      c, AskSlot
        jr      nz, as_ok2

.AskSlot
        call    KPrint
        defm    1,"2C1"
        defm    1,"2C2", 1,"S"
        defm    1,"2C3"
        defm    "Which slot (1-3)?",0
.as_1
        call    ReadKey
        jr      c, Exit

        sub     '1'
        cp      3
        jr      nc, as_1

        inc     a
        call    IsEPROM
        jr      c, NoEPROM
        jr      nz, as_ok2

        ld      hl, Corrupted_txt
        call    AskYesNo
        jp      c, AskSlot
        jr      nz, AskSlot
        ld      a, 64                   ; assume 1MB card

.as_ok2
        ld      (CardBanks), a
        call    CountFiles
        ld      de, (NumFiles)
        ld      a, d
        or      e
        jp      z, NoFiles

        call    ShowRAM

        ld      de, 0
        ld      c, d

        call    DisplayFiles
        ret

;in:    A=slot #
;out:   Fc=1 - no EPROM
;       Fc=0, A=0 - possible corrupted EPROM
;       Fc=0, A=n - filing system EPROM

.IsEPROM

        ld      hl, ubSlotRamSize
        add     a, l
        ld      l, a
        and     3                               ; 1-3
        rrca
        rrca                                    ; $40/$80/$c0
        ld      (EPROMbase), a
        ld      (S1Bank), a                     ; force bank binding
        ld      a, (hl)
        or      a
        jr      nz, ie_err                      ; RAM, skip

;       check for $3F3FFE = "oz", file EPROM

        ld      hl, $3ffe
        ld      b, h
        call    RdozSignature
        jr      z, ie_size                      ; ok, use size from header

;       check for $3F3FFE = "OZ", application (EP)ROM

        ld      hl, -['Z'<<8|'O']
        add     hl, de
        ld      a, h
        or      l
        jr      nz, ie_maybe                    ; no, test for corrupt EPROM

;       check for $..3FFE = "oz", combined Flash EPROM

        ld      hl, $3ffc
        call    RdBHL                           ; get card size
        add     a, 3
        and     ~3                              ; rounded to next 64K
        neg
        add     a, b                            ; last filesystem bank

        ld      b, a
        ld      hl, $3ffe
        call    RdozSignature
        jr      z, ie_size                      ; ok, use size from file header

;       check for $3F3FF6 = "oz", combined (EP)ROM without file header (corrupted)

        ld      hl, $3ff6
        ld      b, h
        call    RdozSignature
        jr      nz, ie_err                      ; plain application card
        jr      ie_1mb                          ; else corrupted

.ie_size
        ld      hl, $3ffc                       ; get size from header
        call    RdBHL
        cp      65
        jr      c, ie_ok                        ; size ok
        jr      ie_1mb                          ; else corrupted

;       check for $3F3FC0 = 00 00 00 00 00 00

.ie_maybe
        ld      bc, $3f06
        ld      hl, $3fc0
.ie_m1
        call    RdBHL_Inc
        or      a
        jr      nz, ie_err
        dec     c
        jr      nz, ie_m1
.ie_1mb
        xor     a                       ; assume 1MB card
.ie_ok  or      a
        ret
.ie_err
        scf
        ret

;       ----

.HandleInput
        call    ToggleHighlight
        call    ReadKey
        cp      CMD_FETCH                       ; enter - fetch a file
        jp      z, Fetch
        call    ToggleHighlight

        ld      hl, CmdTable
        ld      b, 11
.hi_1
        cp      (hl)
        inc     hl
        jr      z, hi_2
        inc     hl
        inc     hl
        djnz    hi_1
        ret
.hi_2
        ld      a, (hl)
        inc     hl
        ld      h, (hl)
        ld      l, a
        jp      (hl)

.CmdTable
        defb    IN_UP
        defw    CrsrUp
        defb    IN_DWN
        defw    CrsrDown
        defb    IN_SUP
        defw    PageUp
        defb    IN_SDWN
        defw    PageDown
        defb    IN_DUP
        defw    FirstFile
        defb    IN_DDWN
        defw    LastFile
        defb    CMD_SAVELIST
        defw    SaveList
        defb    CMD_PRINTLIST
        defw    PrintList
        defb    CMD_MEM
        defw    ShowRAM
        defb    CMD_RESCAN
        defw    AskSlot
        defb    CMD_ESC
        defw    Exit

;       ----

.CrsrUp
        dec     c                               ; cursor up
        ret     p

        inc     c
        ld      a, d                            ; scroll up
        or      e
        ret     z
        dec     de
        ld      a, 1
        OZ      OS_Out
        ld      a, SD_UP
        OZ      OS_Out
        jr      DisplayFile

.CrsrDown

        call    indn_sub                        ; de+c=numfiles-1? ret
        ret     z

        inc     c                               ; c!=6? c++
        ld      a, c
        cp      7
        ret     nz
        dec     c

        call    indn_sub                        ; de+6=numfiles-1? ret
        ret     z
        inc     de
        ld      a, 1
        OZ      OS_Out
        ld      a, SD_DWN
        OZ      OS_Out
        jr      DisplayFile

.indn_sub
        xor     a
        ld      b, a
        ld      hl, (NumFiles)
        dec     hl
        sbc     hl, bc
        sbc     hl, de
        ld      a, h
        or      l
        ret

.PageUp
        ld      hl, -7                          ; de<7? top
        add     hl, de
        jr      nc, FirstFile
        ex      de, hl                          ; de -= 7
        jr      DisplayFiles

.PageDown
        call    insdn_sub                       ; numfiles<7? ret
        ret     nc
 dec    hl
        push    hl                              ; de=min(d+7,numfiles-7)
        ld      hl, 7
        add     hl, de
        ex      de, hl
        pop     hl

        sbc     hl, de                          ; Fc= (hl<de)
        adc     hl, de
        jr      nc, DisplayFiles
        ex      de, hl
        jr      DisplayFiles

.insdn_sub
        ld      a, c
        ld      bc, -7
        ld      hl, (NumFiles)
        add     hl, bc
        ld      c, a
        ret

.FirstFile
        ld      de, 0
        ld      c, d
        jr      DisplayFiles

.LastFile
        call    insdn_sub                       ; numfiles<7? exit
        ret     nc
        ex      de, hl
        ld      c, 6
;       jr      DisplayFiles

;       ----

.DisplayFiles
        push    bc
        push    de

        ld      bc, 7<<8|0
.daf_1
        call    DisplayFile
        jr      c, daf_x
        inc     c
        djnz    daf_1

.daf_x
        pop     de
        pop     bc
        ret

;       draw File DE+C on line C

.DisplayFile

        push    bc
        push    de

        ld      a, e
        add     a, c
        ld      e, a
        jr      nc, df_1
        inc     d
.df_1
        push    bc
        call    GetFileInfoN
        pop     bc
        jr      c, df_x

        ld      hl, FileSize
        ld      a, $80
        call    ItoA

        ld      hl, Move2XY_txt
        OZ      GN_Sop
        ld      a, $20
        OZ      OS_Out
        ld      a, $20
        add     a, c
        OZ      OS_Out

        ld      hl, NameBuffer
        ld      a, (hl)                         ; deleted? prepend with "-", make tiny
        or      a
        ld      (hl), ' '
        jr      nz, df_2
        ld      (hl), '-'
        call    KPrint
        defm    1,"T",0
.df_2
        ld      hl, NameBuffer
        ld      bc, 42
        xor     a
        cpir                                    ; find trailing NULL

        dec     hl                              ; replace it with multiple spaces
        ld      (hl), 1
        inc     hl
        ld      (hl), '3'
        inc     hl
        ld      (hl), 'N'
        inc     hl
        ld      a, $20
        add     a, c
        ld      (hl), a
        inc     hl
        ld      (hl), ' '
        inc     hl

        ex      de, hl                          ; append length
        ld      hl, NumBuffer
        ld      c, 9
        ldir
        ld      hl, NameBuffer
        OZ      GN_Sop
        call    KPrint
        defm    1,"2-T", 0
        or      a
.df_x
        pop     de
        pop     bc
        ret

;       ----

.SaveList

        push    bc
        push    de

        xor     a
        call    Request
        jr      c, sl_x3

        ld      de, 0
        push    de                              ; output flag
        xor     a
        ld      (PrintC), a
.sl_loop
        ld      (FileIndex), de
        call    MatchNext
        jr      c, sl_x1
        jr      nz, sl_skip

        ex      (sp), hl                        ; H into output flag
        call    OutputLine
        jr      c, sl_x2

.sl_skip
        ld      de, (FileIndex)
        inc     de
        jr      sl_loop

.sl_x1
        pop     af                              ; print "no files" if needed
        push    af
        or      a
        call    z, NoMatch

.sl_x2
        pop     bc
        push    af
        ld      a, ' '
        OZ      OS_Out

        OZ      OS_Cl
        pop     af
.sl_x3
        call    PrintSuccess

        pop     de
        pop     bc
        ret

;       ----

.PrintList

        push    bc
        push    de


        ld      a, 1
        call    Request
        jr      c, pl_x3

        ld      a, 5
        OZ      OS_Pb
        ld      a, '['
        OZ      OS_Pb
        jr      c, pl_x2

        ld      de, 0
        push    de                              ; output flag
        ld      a, 3
        ld      (PrintC), a
.pl_loop
        ld      (FileIndex), de
        call    MatchNext
        jr      c, pl_x1
        jr      nz, pl_skip

        ex      (sp), hl                        ; H into output flag
        call    OutputLine
        jr      c, pl_x2

        ld      hl, PrintC
        ld      a, (hl)
        dec     a
        jr      nz, pl_2
        ld      a, 3
.pl_2
        ld      (hl), a
.pl_skip
        ld      de, (FileIndex)
        inc     de
        jr      pl_loop

.pl_x1
        pop     af
        push    af
        or      a
        call    z, NoMatch

        ld      a, 12
        OZ      OS_Pb

        ld      a, 5
        OZ      OS_Pb
        ld      a, ']'
        OZ      OS_Pb

.pl_x2
        pop     bc
        push    af

        ld      a, ' '
        OZ      OS_Out

        OZ      OS_Cl

        pop     af
.pl_x3
        call    PrintSuccess

        pop     de
        pop     bc
        ret

;       ----

defc    PRINTWIDTH3C    = 25
defc    PRINTWIDTH2C    = 36
defc    MAXFILENAMELEN  = PRINTWIDTH2C

.OutputLine

;       save:  always one file/line
;       print: 3 columns if max. filename length <=16, 2 columns otherwise
;
;
;       7-digit length, followed by ' ' or '-' showing if active or deleted
;       filename ;      save:  LF ;     print: space padding + CRLF if last column

        ld      hl, FileSize
        ld      a, $70
        call    ItoA

        ex      de, hl                  ; HL=buffer
        ld      de, NameBuffer
        ld      bc, 7+1                 ; 7 digits + LF

        ld      a, (de)                 ; prepend with '-' if deleted
        or      a
        ld      a, ' '
        jr      nz, ol_1
        ld      a, '-'
.ol_1
        ld      (hl), a
        inc     bc
        inc     de
        inc     hl
        ld      a, (de)                 ; end of name?
        or      a
        jr      nz, ol_1                ; nope, copy more

;       decide between save/print

        ld      (hl), 13                ; assume save
        ld      de, Printing
        ld      a, (de)
        or      a
        jr      z, ol_save

;       see if this one needs separate line

        dec     bc
        ld      a, c
        cp      MAXFILENAMELEN
        jr      c, ol_3

;       print CRFL if middle of line

        ld      a, (de)
        cp      1                               ; column 1? no need for pre-CRLF
        jr      z, ol_2

        push    bc
        push    de
        push    hl
        ld      c, 2
        ld      hl, crlf_txt
        call    ol_save2
        pop     hl
        pop     de
        pop     bc
        ret     c                               ; error? return Fc=1
.ol_2
        jr      ol_crlf                         ; print with trailing CRLF

;       this one is normal length, see if we pad it to 2- or 3-column width

.ol_3
        ld      a, (MaxFNameLen)
        cp      18+1
        push    af
        ld      a, PRINTWIDTH3C
        jr      c, ol_4
        ld      a, PRINTWIDTH2C
.ol_4
        sub     a, c
        ld      b, a
.ol_5
        ld      (hl), ' '
        inc     c
        inc     hl
        djnz    ol_5

;       check for last column - add CRLF if needed

        pop     af                              ; C set if 3-column
        ld      a, 2
        adc     a, 0                            ; A = #max_column
        ex      de, hl
        cp      (hl)
        ex      de, hl
        jr      nz, ol_7

.ol_crlf
        xor     a                               ; column #0 (incremented below)
        ld      (de), a
        ld      (hl), 13
        inc     hl
        ld      (hl), 10
        inc     bc
        inc     bc
.ol_7
        ex      de, hl                          ; bump column
        inc     (hl)
.ol_save
        ld      hl, NumBuffer
.ol_save2
        ld      de, 0
        OZ      OS_Mv
        ret

;       ----

.MatchNext
        call    GetFileInfoN
        ret     c

        ld      a, e
        and     3
        jr      nz, mn_1

        ld      a, e
        rrca
        rrca
        call    PrntProgress
.mn_1
        ld      hl, NameBuffer
        ld      a, (hl)
        or      a
        jr      nz, mn_2
        ld      a, (ListDeleted)
        or      a
        ret     nz
.mn_2
        inc     hl

;       find last segment of name

.mn_3
        ld      d, h
        ld      e, l
.mn_4
        ld      a, (hl)
        inc     hl
        cp      '/'
        jr      z, mn_3
        cp      '\'
        jr      z, mn_3
        or      a
        jr      nz, mn_4

        ld      hl, WildBuffer
        OZ      GN_Wsm
        scf
        ccf
        ret

;       ----

.NoMatch
        ld      hl, NoMatch_txt
        ld      d, a
        ld      e, a
        ld      bc, #NoMatch_end-NoMatch_txt
        OZ      OS_Mv
        ret

;       ----

.ShowRAM
        push    bc
        push    de

        ld      a, '2'
        call    SelectWd

        call    KPrint
        defm    13,10,10,"Free space:",0

        ld      b, 4
        ld      ix, ubSlotRAMoffset
.slots
        ld      a, (ix+4)               ; #banks
        or      a
        jr      z, skips

        push    bc

        ld      a, (ix+0)               ; mat bank
        cp      $40                     ; slot0? add 1
        adc     a, 0
        ld      b, a
        ld      c, 2
        OZ      OS_Mpb

        ld      a, (ix+4)               ; #banks
        inc     a
        srl     a
        ld      b, a                    ; #pages in mat
        ld      de, 0                   ; #free pages
        ld      hl, $8100
.pages
        ld      a, (hl)
        inc     l
        or      (hl)
        jr      nz, skipp
        inc     de
.skipp
        inc     l
        jr      nz, pages
        inc     h
        djnz    pages

        srl     d                       ; pages -> KB
        rr      e
        srl     d
        rr      e

        call    KPrint
        defm    13,10,":RAM.",0

        push    ix
        pop     bc
        ld      a, c
        and     3
        add     a, '0'
        OZ      OS_Out

        ld      b, d
        ld      c, e
        ld      hl, 2
        ld      a, $50
        call    PrintNA

        ld      a, 'K'
        OZ      OS_Out

        pop     bc
.skips
        inc     ix
        djnz    slots

        ld      a, '1'
        call    SelectWd

        pop     de
        pop     bc
        ret

;       ----

;       count #files in EPROM

.CountFiles

        xor     a
        ld      h, a                            ; BHL=ptr
        ld      l, a
        ld      b, a
        ld      d, a                            ; DE=#files
        ld      e, a
        ld      (NumBytes), de
        ld      (NumBytes+2), de
        ld      (MaxFNameLen), a

        ld      ix, FilePositions
.cf_1
        ld      a, e                            ; see if we save file position
        and     15                              ; (every 16th file)
        jr      nz, cf_2

        ld      a, d
        cp      >(64*16)
        jr      nc, cf_esc

        ld      (ix+0), b
        ld      (ix+64), h
        inc     ix
        ld      (ix+127), l
        jr      cf_2
.cf_esc
        xor     a
        OZ      OS_Esc
        jr      c, cf_x
.cf_2
        call    GetFileInfo
        jr      c, cf_x

;       check for Flash init file - zero bytes

        ld      a, d
        or      e
        jr      nz, cf_3
        exx
        ld      bc, (FileSize)
        ld      a, (FileSize+2)
        or      b
        or      c
        exx
        jr      nz, cf_3
        dec     ix
        jr      cf_4

.cf_3
        push    bc
        push    de
        push    hl

        ld      hl, (NumBytes)
        ld      a, (NumBytes+2)
        ld      b, a

        ld      de, (FileSize)
        ld      a, (FileSize+2)
        ld      c, a

        call    AddBHL_CDE
        ld      a, b
        ld      (NumBytes), hl
        ld      (NumBytes+2), a

        pop     hl
        pop     de
        pop     bc

        ld      a, d                            ; I doubt this happens...
        and     e                               ; anyway, exit if 65535 files already
        inc     a
        jr      z, cf_x
        inc     de
.cf_4
        call    NextFile
        jr      nc, cf_1

.cf_x
        ld      (NumFiles), de
        ld      a, '3'
        call    SelectWd

        call    KPrint
        defm    12,"Files: ",0
        ld      bc, (NumFiles)
        ld      hl, 2
        call    PrintN

        call    KPrint
        defm    1,"2X",$20+16,"Bytes used: ",0
        ld      hl, NumBytes
        call    PrintN
        ret

.PrintN
        xor     a
.PrintNA
        call    ItoA
        ld      hl, NumBuffer
        OZ      GN_Sop
        ret

;       ----

.ItoA
        ld      de, NumBuffer
        OZ      GN_Pdn                          ; Int2Asc -> (DE)
        xor     a
        ld      (de), a                         ; terminate
        ret

;       ----

;IN:    BHL=file header
;OUT:   BHL=file header
;       Fc=1 if no more files

.NextFile
        call    RdBHL
        inc     a                               ; -1 -> 0
        cp      1
        ret     c

        cp      18+1                            ;16 for name, 1 for '/', 1 for 'inc a'
        jr      c, nf_1
        ld      (MaxFNameLen), a
.nf_1
        push    bc
        push    de

        ld      c, 0                            ; CDE = name length+1
        ld      d, c
        ld      e, a
        call    AddBHL_CDE_a                    ; skip name
        call    RdBHL_CDE                       ; read length
        call    IncBHL                          ; one more for bits 24-31
        call    AddBHL_CDE_a                    ; skip file data

        call    RdBHL
        inc     a
        cp      1                               ; Fc=1 if namelen=-1
        ld      a, b
        pop     de
        pop     bc
        ld      b, a
        ret

;       ----

;IN:    DE=file#

.GetFileInfoN
        push    de
        push    ix

        ld      a, d
        cp      >(64*16)
        jr      nc, gfin_1

        ld      a, e                            ; # additional files
        and     15

        ld      b, 4
.gfin_0
        srl     d                               ; IX=FilePositions+DE/16
        rr      e
        djnz    gfin_0
        ld      ix, FilePositions
        add     ix, de

        ld      b, (ix+0)
        ld      h, (ix+64)
        inc     ix
        ld      l, (ix+127)

        ld      e, a                            ; DE=0-15, additional skip
        jr      gfin_2

.gfin_1
        ld      hl, -63*16                      ; DE -= 63*16
        add     hl, de
        ex      de, hl

        ld      bc, (FilePositions+63-1)
        ld      hl, (FilePositions+127-1)
        ld      a, (FilePositions+191)
        ld      l, a

.gfin_2
        ld      a, d
        or      e
        jr      z, gfin_3
        call    NextFile
        jr      c, gfin_3
        dec     de
        jr      gfin_2
.gfin_3
        pop     ix
        pop     de
        ret     c

;       ----

;IN:    BHL=file header
;OUT:   Fc=1 if error

.GetFileInfo

        call    RdBHL                           ; filename length, 1-100 is valid
        dec     a
        cp      100
        ccf
        ret     c

        push    bc
        push    de
        push    hl

        inc     a
        ld      c, a

        call    IncBHL
        ld      de, NameBuffer                  ; get file status and name
        call    RdBHL_Inc                       ; !! should check this is 0 or '/'
        jr      gfi_2
.gfi_1
        call    RdBHL_Inc
        cp      $a0                             ; '_'
        jr      z, gfi_2
        cp      $a3                             ; '�'
        jr      z, gfi_2
        cp      $7f
        ccf
        jr      c, gfi_x
        cp      $20
        jr      c, gfi_x
.gfi_2
        ld      (de), a
        inc     de
        dec     c
        jr      nz, gfi_1
        xor     a
        ld      (de), a                         ; terminate

        call    RdBHL_CDE
        ld      a, c
        ld      (FileSize), de
        ld      (FileSize+2), a
        call    IncBHL                          ; skip bits 24-31 of length
        ld      a, (EPROMbase)
        or      b
        ld      (DataPtr), hl
        ld      (DataPtr+2), a

        call    AddBHL_CDE
        jr      c, gfi_x                        ; overflow
        call    NormalizeBHL
        jr      c, gfi_x                        ; overflow
        ld      a, (CardBanks)
        dec     a
        cp      b                               ; c=1 if past end

.gfi_x
        pop     hl
        pop     de
        pop     bc
        ret

;       ----

.AddBHL_CDE
        ld      a, b
        add     hl, de
        adc     a, c
        ld      b, a
        ret


.AddBHL_CDE_a
        ld      a, d
        add     a, a
        rl      c
        add     a, a
        rl      c
        ld      a, d
        and     $3f
        ld      d, a

        ld      a, b
        add     hl, de
        adc     a, c
        ld      b, a
                                                ; drop thru
;       ----

.NormalizeBHL
        ld      a, h
        and     $c0
        res     6, h
        res     7, h
        rlca
        rlca
        add     a, b
        ld      b, a
        ret

;       ----

.RdBHL

        ld      a, (S1Bank)
        cp      b
        jr      nz, rd_2
.rd_1
        set     6, h                            ; S1 fix
        ld      a, (hl)
        res     6, h
        ret

.rd_2
        ld      a, b
        ld      (S1Bank), a

        push    bc
        ld      a, (EPROMbase)
        or      b
        ld      b, a
        ld      c, 1
        OZ      OS_Mpb
        pop     bc
        jr      rd_1

;       ----
.RdozSignature
        ld      de, -['z'<<8|'o']               ; 'oz', file EPROM
.RdSignature
        push    de
        call    RdBHL
        ld      e, a
        inc     hl
        call    RdBHL
        ld      d, a
        pop     hl
        add     hl, de
        ld      a, h
        or      l
        ret

;       ----

.RdBHL_CDE
        call    RdBHL_Inc
        ld      e, a
        call    RdBHL_Inc
        ld      d, a
        call    RdBHL_Inc
        ld      c, a
        ret

;       ----

.RdBHL_Inc
        call    RdBHL
.IncBHL
        inc     hl
        bit     6, h
        ret     z
        res     6, h
        inc     b
        ret

;       ----

.Fetch
        push    bc
        push    de
        ld      a, '2'
        call    SelectWd

        ld      hl, CursorOn_txt
        OZ      GN_Sop
        call    OpenDestination
        jr      c, f_1
        call    CopyEPROM2File

.f_1
        call    PrintSuccess

        pop     de
        pop     bc
        call    ToggleHighlight
        ret

;       ----

.OpenDestination
        ld      h, 0                            ; DE += C
        ld      l, c
        add     hl, de
        ex      de, hl
        call    GetFileInfoN
        ret     c

        OZ      GN_Nln
        ld      c, 0
        ld      de, NameBuffer+1
.od_1
        ld      hl, FetchAs_txt
        ld      bc, 100<<8|30
        call    Inputline
        ret     c
        scf
        ret     z

        ld      hl, NameBuffer+1
        call    ParseName
        ret     c

        xor     a
        ld      (Printing), a
        ld      hl, NameBuffer+1
        call    OpenWrite
        ret

;       ----

;IN:    HL=name
;OUT:   IX=handle
;       Fc=1 if error
.OpenWrite
        ld      a, (Printing)
        or      a
        jr      nz, ow_1                ; printing, don't check for existing

        ld      a, OP_IN
        call    ow_sub
        jr      c, ow_1                 ; doesn't exist, open for write

        OZ      GN_Cl
        OZ      GN_Nln

        push    hl
        ld      hl, Overwrite_txt
        call    AskYesNo
        pop     hl
        ret     c                               ; error
        jr      nz, ow_err                      ; don't overwrite

.ow_1
        ld      a, OP_OUT
        call    ow_sub
        ret     nc

        OZ      GN_Err
.ow_err
        scf
        ret

.ow_sub
        ld      bc, 0<<8|30                     ; local ptr, explicit buffer size
        ld      de, 3                           ; ignore explicit name
        OZ      GN_Opf
        ret

;       ----

.ParseName
        ld      d, h
        ld      e, l

        ld      b, 0
        OZ      GN_Prs                  ; check full path
        jr      c, pn_err               ; bad syntax

        ld      c, a
        and     $b8                     ; wildcards, "//", "..", "."
        jr      nz, pn_ivf              ; error

        bit     6, c                    ; device?
        jr      z, pn_loop              ; no, check all parts

        dec     b                       ; only device specified? exit
        ret     z

        ld      b, a                    ; skip device part
        OZ      GN_Pfs

.pn_loop0
        inc     hl                      ; and delimeter

.pn_loop

        push    hl
        ld      b, 0                    ; parse next part
        OZ      GN_Pfs                  ; errors were trapped in GN_Prs
        ld      (hl), 0                 ; terminate

        bit     2, a                    ; dir?
        jr      nz, pn_dir
        bit     1, a                    ; file?
        jr      nz, pn_file

.pn_ivf
        ld      a, RC_Ivf
.pn_err
        OZ      GN_Err
        pop     hl
        scf
        ret

.pn_opf
        push    bc
        push    de
        ld      bc, 255
        ld      de, 3
        OZ      GN_Opf
        pop     de
        pop     bc
        ret

.pn_dir
        ex      (sp), hl
        ld      h, d                    ; try to find directory
        ld      l, e
        ld      a, OP_DOR
.pn_d2
        call    pn_opf
        jr      nc, pn_d3               ; found? verify type

        cp      RC_Onf                  ; "object not found"? create dir
        jr      nz, pn_err              ; error otherwise
        inc     b
        ld      a, OP_DIR
        jr      pn_d2

.pn_d3
        ld      c, a
        ld      a, DR_FRE
        OZ      OS_Dor

        dec     b                       ; don't check type if we just
        jr      z, pn_d4                ; created dir
        ld      a, DN_DIR
        cp      c
        jr      nz, pn_type

.pn_d4
        pop     hl
        ld      (hl), '/'
        jr      pn_loop0

.pn_file
        ex      (sp), hl
        ld      h, d                    ; try to find file
        ld      l, e
        ld      a, OP_DOR
        call    pn_opf
        jr      nc, pn_f2

        cp      RC_Onf                  ; object not found? OK
        jr      nz, pn_err
        pop     hl
        ret

.pn_f2
        ld      c, a
        ld      a, DR_FRE
        OZ      OS_Dor

        ld      a, DN_FIL
        cp      c
        jr      nz, pn_type

        pop     hl
        ret

.pn_type
        push    de
        ld      hl, dir_txt
        ld      de, file_txt
        cp      DN_DIR
        jr      z, pn_t2
        ex      de, hl
.pn_t2
        call    KPrint
        defm    13,10,"Can't create ",0
        OZ      GN_Sop                  ; "directory" / "file"
        call    KPrint
        defm    " ",1,"B",0
        pop     hl
        OZ      GN_Sop
        call    KPrint
        defm    1,"B",13,10,0
        ex      de, hl
        OZ      GN_Sop                  ; "file" / "directory"
        call    KPrint
        defm    " with same name already exists",0
        pop     hl
        scf
        ret

;       ----

.CopyEPROM2File

.c_loop
        ld      de, (FileSize)                  ; CDE=remaining bytes
        ld      bc, (FileSize+2)
        ld      hl, (DataPtr)                   ; BHL=ptr inside bank
        ld      b, 0
        call    AddBHL_CDE_a
        ld      a, b
        or      a
        jr      z, c_last                       ; no bank change

        ld      de, (DataPtr)                   ; Fc=0 when we come here
        ld      hl, $4000
        sbc     hl, de                          ; HL=bytes until end of bank

        ex      de, hl                          ; FileSize -= #bytes
        ld      hl, (FileSize)
        ld      a, (FileSize+2)
        sbc     hl, de
        sbc     a, 0
        ld      (FileSize), hl
        ld      (FileSize+2), a

        ld      hl, DataPtr+2                   ; get bank and bump it
        ld      b, (hl)
        inc     (hl)
        call    c_sub
        jr      c_loop

;       write last part

.c_last
        ld      de, (FileSize)                  ; #bytes
        ld      bc, (DataPtr+1)                 ; bank into B
        call    c_sub
        OZ      GN_Cl
        or      a
        ret

.c_sub
        ld      c, 2
        OZ      OS_Mpb
        ld      b, d
        ld      c, e
        ld      hl, (DataPtr)                   ; source, S2 fix
        set     7, h
        ld      de, 0                           ; dest=file
        ld      (DataPtr), de
        OZ      OS_Mv
        ret     nc
        pop     hl

.c_err  OZ      GN_Err                          ; Display an interactive error box
        OZ      GN_Cl                           ; close file/stream
        scf
        ret

;       ----

;       common input routines

;       ----

;       B  buffer size
;       C  width of line
;       DE buffer (pre-filled)
;       HL prompt

.Inputline

        OZ      GN_Nln
.il_1
        push    bc
        push    hl
        call    PrintString                     ; prompt
        ld      a, $21                          ; single line, has data
        ld      l, c
        OZ      GN_Sip
        pop     hl
        pop     bc
        jr      c, il_2
        ld      a, (de)
        or      a
        ret

.il_2
        cp      RC_Susp                         ; if pre-emption we just retry
        jr      z, il_1
        scf
        ret


;       ----

.ReadKey
        OZ      OS_In
        jr      nc, rdk_1
        cp      RC_Susp
        jr      z, ReadKey
        cp      RC_Esc                          ; Fz=1 if ESC
.rdk_esc
        scf
        ret
.rdk_1
        or      a
        ret     nz                              ; return normal key
        OZ      OS_In
        cp      CMD_ESC                         ; Fz=1 if ESC
        jr      z, rdk_esc
        scf
        ccf
        ret                                     ; return expanded key

;       ----

;save/print requester:
;
; Output list to: [          ]          only for save
; List files matching: [*     ]
; List deleted files: [Yes/No]

.Request
        ld      (Printing), a

        ld      a, '2'
        call    SelectWd
        ld      hl, CursorOn_txt
        OZ      GN_Sop
        OZ      GN_Nln

        ld      hl, Printing
        ld      a, (hl)
        or      a
        jr      nz, req_1

        xor     a
        ld      bc, 100<<8|30
        ld      de, NameBuffer+1                ; default to no name
        ld      (de), a
        ld      hl, Output_txt
        call    Inputline
        jp      c, req_err
        jp      z, req_err

        ld      hl, NameBuffer+1
        jr      req_3

.req_1
        inc     hl                              : FirstPO
        ld      a, (hl)
        or      a
        jr      nz, req_1b
        cpl
        ld      (hl), a

        call    KPrint
        defm    $7f,"If you have trouble with the print out,",$7f
        defm    "Press ",1,SD_HLP," for suggestions",$7f,0
.req_1b
        ld      hl, Prt_txt

.req_3
        push    hl

        ld      hl, WildBuffer+1
        ld      (hl), 0
        dec     hl
        ld      (hl), '*'
        ex      de, hl
        ld      hl, Match_txt
        ld      bc, 16<<8|16
        call    Inputline
        jr      c, req_errpop
        jr      nz, req_4
        ex      de, hl
        ld      (hl), '*'
        inc     hl
        ld      (hl), a
.req_4
        OZ      GN_Nln
        ld      hl, ListDeleted_txt
        call    AskYesNo
        jr      c, req_errpop
        ld      (ListDeleted), a

        pop     hl
        call    OpenWrite
        jr      req_x

.req_errpop
        pop     hl
.req_err
        scf
.req_x
        push    af
        ld      hl, CursorOff_txt
        OZ      GN_Sop
        pop     af
        ret

;       ----

;HL=prompt, DE=default
;
; A=0, Fz=1 Yes         A!=0, Fz=0 No

.AskYesNo
        ld      de, No_txt
.yn_0
        push    hl
        call    PrintString
        ld      h, d
        ld      l, e
        OZ      GN_Sop
        pop     hl
        call    ReadKey
        ret     c
        cp      13
        jr      nz, yn_1
        ld      a, (de)
        sub     'Y'
        scf
        ccf
        ret

.yn_1   or      $20                             ; lower()
        cp      'y'
        jr      nz, yn_2
        ld      de, Yes_txt
        jr      yn_0

.yn_2   cp      'n'
        jr      z, AskYesNo
        jr      yn_0

.Yes_txt        defm    "Yes",0
.No_txt         defm    "No ",8,0

;       ---

;       common output routines

.KPrint
        ex      (sp), hl
        call    PrintString
        ex      (sp), hl
        ret

.PrintString
.ps_1
        ld      a, (hl)
        inc     hl
        OZ      OS_Wrt
        jr      nc, ps_1
        ret

;       ----

.ToggleHighlight
        push    af
        ld      hl, Move2XY_txt
        OZ      GN_Sop
        ld      a, $20
        OZ      OS_Out
        ld      a, c                            ; line
        add     a, $20
        OZ      OS_Out
        call    KPrint
        defm    1,"R",1,"2E",$20+50,1,"R",0
        pop     af
        ret


.PrntProgress
        push    hl
        ld      hl, Progress_txt
        and     3
        add     a, l
        ld      l, a
        jr      nc, pp_1
        inc     hl
.pp_1
        ld      a, (hl)
        OZ      OS_Out
        ld      a, 8
        OZ      OS_Out
        pop     hl
        ret

.PrintSuccess
        ld      hl, Done_txt
        jr      nc, pc_2
        ld      hl, Failed_txt
.pc_2
        call    PrintString
        ld      hl, CursorOff_txt
        call    PrintString

        ld      a, '1'

.SelectWd
        push    af
        call    KPrint
        defm    1,"2H",0
        pop     af
        OZ      OS_Out
        ret

;       ----

.NoEPROM_txt    defm    13,"Valid EPROM not present"
.AnyKey_txt     defm    $7f," - press any key",7,0
.Corrupted_txt  defm    12,"Possible corrupted EPROM"
                defm    $7f,"Attempt to read it: ",0

.FetchAs_txt    defm    13,"Fetch as: ",0

.Overwrite_txt  defm    13,"Overwrite existing file: ",0
.Done_txt       defm    $7f,"Done",0
.Failed_txt     defm    $7f,"Failed",7,0

.Output_txt     defm    13,"Output list to: ",0
.Prt_txt        defm    ":PRT.0",0
.Match_txt      defm    13,"List files matching: ",0
.ListDeleted_txt defm   13,"List deleted files: ",0
.NoMatch_txt    defm    "no matching files",13          ; !! can't use tokens with this one
.NoMatch_end

.dir_txt        defm    "directory",0
.file_txt       defm    "file",0


.Progress_txt   defm    "/-\|"
.Move2XY_txt    defm    1,"3@",0

.CursorOn_txt   defm    1,"2+C",0
.CursorOff_txt  defm    1,"2-C",0
.crlf_txt       defm    13,10

;       ----
