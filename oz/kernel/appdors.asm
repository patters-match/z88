; -----------------------------------------------------------------------------
; Bank 7 @ S2           ROM offset $1f3ff
;
; $Id$
; -----------------------------------------------------------------------------

        Module AppStatic

        include "blink.def"
	include	"director.def"
	include	"sysvar.def"

        org $B3FF   ; 3073 bytes

xdef    PrinterEdTopics
xdef    PrinterEdCommands
xdef    PrinterEdHelp

xdef    PanelTopics
xdef    PanelCommands
xdef    PanelHelp

xref	Bootstrap3


;       !! Use application DOR null-pointer for these.
;       !! It makes clear they are dummy entries.

        defb    0
        defb    0
        defb    0
.PrinterEdHelp
	defb	0
.PanelHelp
	defb	0
        defb    0
        defb    0

.IndexTopics
        defb    0
        defb    4,$D8,0,4
        defb    0
.IndexCommands
        defb    0
        defb    11,5,$E1,0,$E8,$65,$63,$75,$AF,0,11
        defb    7,6,$1B,0,$B1,0,7
        defb    17,8,$43,$41,$52,$44,0,$43,$8C,$B2,$44,$69,$73,$D9,$FB,0,17
        defb    7,1,$FD,0,$A7,1,7
        defb    7,2,$FC,0,$A8,0,7
        defb    7,3,$FF,0,$DA,0,7
        defb    7,4,$FE,0,$DB,0,7
        defb    23,7,$4B,$49,$4C,$4C,0,$80,$4B,$49,$4C,$4C,$20,$41,$43,$54,$49,$56,$49,$54,$59,9,23
        defb    23,9,$50,$55,$52,$47,$45,0,$80,$50,$55,$52,$47,$45,$20,$53,$59,$53,$54,$45,$4D,8,23
        defb    0

.PipeDreamTopics
        defb    0
        defb    5,$C5,$73,0,5
        defb    4,$DC,0,4
        defb    6,$45,$64,$FC,1,6
        defb    4,$FD,0,4
        defb    8,$4C,$FB,$6F,$75,$74,0,8
        defb    5,$EC,$73,0,5
        defb    4,$FE,0,4
        defb    0
.PipeDreamCommands
        defb    0
        defb    10,1,$5A,0,$DD,$6B,$20,$C5,0,10
        defb    12,2,$51,0,$43,$8B,$8C,$20,$DD,$6B,0,12
        defb    8,4,$42,$43,0,$DE,0,8
        defb    11,5,$42,$4D,0,$4D,$6F,$76,$65,0,11
        defb    10,6,$42,$44,0,$44,$C7,$AF,0,10
        defb    11,7,$42,$53,$4F,0,$53,$8F,$74,0,11
        defb    13,3,$42,$52,$45,0,$C8,$D9,$69,$63,$C3,0,13
        defb    12,8,$42,$53,$45,0,$53,$65,$8C,$B4,1,12
        defb    12,$A,$42,$52,$50,0,$C8,$D9,$61,$C9,0,12
        defb    10,9,$42,$4E,$4D,0,$97,$F7,0,10
        defb    15,$B,$42,$57,$43,0,$57,$8F,$B2,$AB,$75,$6E,$74,1,15
        defb    12,$C,$42,$4E,$45,$57,0,$4E,$65,$77,0,12
        defb    13,$D,$41,0,$C8,$63,$95,$63,$75,$6C,$C3,0,13
        defb    1
        defb    8,$10,$F5,0,$DF,$FA,0,8
        defb    12,$F,$F4,0,$53,$74,$8C,$84,$89,$FA,0,12
        defb    12,$20,$F7,0,$54,$6F,$70,$20,$89,$B5,0,12
        defb    10,$21,$43,$4F,$42,$52,$41,0,4,10
        defb    13,$22,$F6,0,$42,$6F,$74,$9E,$D7,$89,$B5,0,13
        defb    10,$14,$43,$53,$50,0,$BD,$BE,0,10
        defb    13,$15,$43,$52,$50,0,$C8,$73,$74,$8F,$BE,0,13
        defb    13,$E,$43,$47,$53,0,$47,$6F,$20,$BB,$FA,0,13
        defb    7,$13,$E1,0,$D2,0,7
        defb    8,$1A,$F9,0,$97,$D3,1,8
        defb    8,$1B,$F8,0,$98,$D3,0,8
        defb    8,$1C,$FB,0,$D4,$B9,0,8
        defb    8,$1D,$FA,0,$D4,$AC,0,8
        defb    7,$16,$FD,0,$A7,0,7
        defb    7,$17,$FC,0,$A8,0,7
        defb    7,$19,$FF,0,$DA,0,7
        defb    7,$18,$FE,0,$DB,0,7
        defb    8,$1F,$E2,0,$97,$B5,1,8
        defb    8,$1E,$D2,0,$98,$B5,0,8
        defb    10,$11,$43,$46,$43,0,$F8,$B5,0,10
        defb    6,$11,$C2,0,4,6
        defb    12,$12,$43,$4C,$43,0,$4C,$61,$CA,$B5,0,12
        defb    1
        defb    7,$23,$E3,0,$E0,0,7
        defb    8,$24,$47,0,$96,$E9,0,8
        defb    6,$24,$D3,0,4,6
        defb    8,$25,$55,0,$CB,$E9,0,8
        defb    8,$26,$54,0,$96,$D3,0,8
        defb    10,$27,$44,0,$96,$BB,$DF,$FA,0,10
        defb    9,$29,$59,0,$96,$52,$9D,0,9
        defb    6,$29,$C3,0,4,6
        defb    9,$2F,$4E,0,$CB,$52,$9D,0,9
        defb    7,$36,$1B,0,$B1,0,7
        defb    7,$38,$56,0,$EA,1,7
        defb    7,$35,$53,0,$FF,0,7
        defb    8,$37,$4A,0,$97,$EC,0,8
        defb    17,$34,$58,0,$45,$64,$69,$84,$E8,$70,$8D,$73,$73,$69,$BC,0,$83  ; !! last byte invalid - Edit Expression
        defb    12,$2C,$4B,0,$CB,$C8,$66,$86,$A2,$C9,0,12
        defb    19,$39,$45,$4E,$54,0,$4E,$75,$6D,$62,$86,$3C,$3E,$54,$65,$78,$74,0,19
        defb    18,$33,$52,0,$46,$8F,$6D,$61,$84,$50,$8C,$61,$67,$E2,$70,$68,0,18
        defb    13,$31,$45,$53,$4C,0,$53,$D9,$69,$84,$A9,1,13
        defb    13,$2B,$45,$4A,$4C,0,$4A,$6F,$A3,$A9,$73,0,13
        defb    15,$28,$45,$44,$52,$43,0,$96,$52,$9D,$20,$A3,$B5,0,15
        defb    15,$2E,$45,$49,$52,$43,0,$CB,$52,$9D,$20,$A3,$B5,0,15
        defb    10,$2A,$45,$44,$43,0,$96,$B5,0,10
        defb    10,$30,$45,$49,$43,0,$CB,$B5,0,10
        defb    12,$32,$45,$41,$43,0,$41,$64,$B2,$B5,0,12
        defb    13,$2D,$45,$49,$50,0,$CB,$50,$61,$67,$65,0,13
        defb    1
        defb    8,$3A,$46,$4C,0,$E1,0,8
        defb    9,$3B,$46,$53,0,$BD,$65,0,9
        defb    10,$3C,$46,$43,0,$4E,$ED,$65,0,10
        defb    9,$3D,$46,$4E,0,$97,$BA,1,9
        defb    9,$3E,$46,$50,0,$98,$BA,0,9
        defb    12,$3F,$46,$54,0,$54,$6F,$70,$20,$BA,0,12
        defb    13,$40,$46,$42,0,$42,$6F,$74,$9E,$D7,$BA,0,13
        defb    1
        defb    10,$41,$57,0,$57,$69,$64,$88,0,10
        defb    12,$42,$48,0,$53,$65,$84,$DD,$67,$85,0,12
        defb    13,$43,$4C,$46,$52,0,$A6,$78,$20,$52,$9D,0,13
        defb    12,$44,$4C,$46,$43,0,$A6,$78,$20,$B5,0,12
        defb    12,$46,$F1,0,$DD,$67,$A3,$52,$CC,$74,0,12
        defb    13,$45,$F0,0,$DD,$67,$A3,$4C,$65,$66,$74,0,13
        defb    12,$47,$4C,$41,$52,0,$52,$CC,$84,$D1,1,12
        defb    13,$48,$4C,$41,$4C,0,$4C,$65,$66,$84,$D1,0,13
        defb    14,$49,$4C,$41,$43,0,$43,$A2,$74,$72,$82,$D1,0,14
        defb    14,$4A,$4C,$4C,$43,$52,0,$4C,$43,$52,$20,$D1,0,14
        defb    12,$4B,$4C,$41,$46,0,$46,$8D,$82,$D1,0,12
        defb    20,$4C,$4C,$44,$50,0,$44,$65,$63,$69,$6D,$95,$20,$50,$6C,$61,$C9,$73,1,20
        defb    19,$4D,$4C,$53,$42,0,$53,$90,$6E,$20,$42,$E2,$63,$6B,$65,$74,$73,0,19
        defb    16,$4E,$4C,$53,$4D,0,$53,$90,$6E,$20,$4D,$85,$75,$73,0,16
        defb    15,$4F,$4C,$43,$4C,0,$4C,$65,$61,$64,$C0,$E9,$73,0,15
        defb    15,$50,$4C,$43,$54,0,$54,$E2,$69,$6C,$C0,$E9,$73,0,15
        defb    19,$51,$4C,$44,$46,0,$44,$65,$66,$61,$75,$6C,$84,$46,$8F,$6D,$91,0,19
        defb    1
        defb    12,$52,$4F,0,$EC,$8E,$50,$61,$67,$65,0,12
        defb    1
        defb    8,$53,$50,$4F,0,$FE,0,8
        defb    20,$54,$50,$4D,0,$4D,$69,$63,$72,$6F,$73,$70,$61,$63,$82,$50,$FC,$B4,0,20
        defb    14,$55,$50,$55,0,$55,$6E,$64,$86,$6C,$85,$65,1,14
        defb    11,$56,$50,$42,0,$42,$6F,$6C,$64,0,11
        defb    16,$57,$50,$58,0,$E8,$74,$CE,$53,$65,$71,$75,$A2,$C9,0,16
        defb    12,$58,$50,$49,0,$49,$74,$95,$69,$63,0,12
        defb    16,$59,$50,$4C,0,$53,$75,$62,$73,$63,$72,$69,$70,$74,0,16
        defb    17,$5A,$50,$52,0,$53,$75,$70,$86,$73,$63,$72,$69,$70,$74,0,17
        defb    14,$5B,$50,$41,0,$41,$6C,$74,$CE,$46,$BC,$74,0,14
        defb    16,$5C,$50,$45,0,$55,$73,$EF,$44,$65,$66,$85,$65,$64,0,16
        defb    15,$5D,$50,$48,$49,0,$CB,$48,$CC,$6C,$CC,$74,$73,1,15
        defb    19,$5E,$50,$48,$52,0,$C8,$6D,$6F,$76,$82,$48,$CC,$6C,$CC,$74,$73,0,19
        defb    14,$5F,$50,$48,$42,0,$48,$CC,$6C,$CC,$84,$C5,0,14
        defb    0

.DiaryTopics
        defb    0
        defb    5,$C5,$73,0,5
        defb    4,$DC,0,4
        defb    6,$45,$64,$FC,1,6
        defb    4,$FD,0,4
        defb    0
.DiaryCommands
        defb    0
        defb    10,$20,$5A,0,$DD,$6B,$20,$C5,0,10               ; Mark Block
        defb    12,$21,$51,0,$43,$8B,$8C,$20,$DD,$6B,0,12       ; Clear Mark
        defb     8,$22,$42,$43,0,$DE,0,8                        ; Copy
        defb    11,$23,$42,$4D,0,$4D,$6F,$76,$65,0,11           ; Move
        defb    10,$24,$42,$44,0,$44,$C7,$AF,0,10               ; Delete
        defb    13,$25,$42,$4C,0,$4C,$69,$73,$74,$2F,$FE,0,13   ; List/Print
        defb    12,$26,$42,$53,$45,0,$53,$65,$8C,$B4,1,12       ; Search
        defb    12,$29,$42,$52,$50,0,$C8,$D9,$61,$C9,0,12       ; Replace
        defb    10,$27,$42,$4E,$4D,0,$97,$F7,0,10               ; Next Match
        defb    10,$28,$42,$50,$4D,0,$98,$F7,0,10               ; Previous Match
        defb    1
        defb     8,$F5,$F5,0,$DF,$A9,0,8                        ; End of Line
        defb    12,$F4,$F4,0,$53,$74,$8C,$84,$89,$A9,0,12       ; Start of Line
        defb     8,$30,$F7,0,$F8,$A9,0,8                        ; First Line
        defb    10,$2F,$F6,0,$4C,$61,$CA,$A9,0,10               ; Last Line
        defb    10,$2B,$43,$53,$50,0,$BD,$BE,0,10               ; Save position
        defb    13,$2C,$43,$52,$50,0,$C8,$73,$74,$8F,$BE,0,13   ; Restore position
        defb     7,$0D,$E1,0,$D2,0,7                            ; ENTER
        defb     8,$F9,$F9,0,$97,$D3,1,8                        ; Next Word
        defb     8,$F8,$F8,0,$98,$D3,0,8                        ; Previous Word
        defb     8,$32,$FB,0,$D4,$B9,0,8                        ; Screen Up
        defb     8,$31,$FA,0,$D4,$AC,0,8                        ; Screen Down
        defb     7,$FD,$FD,0,$A7,0,7                            ; Cursor Right
        defb     7,$FC,$FC,0,$A8,0,7                            ; Cursor Left
        defb     7,$2E,$FF,0,$DA,0,7                            ; Cursor Up
        defb     7,$2D,$FE,0,$DB,0,7                            ; Cursor Down
        defb     9,$2A,$E2,0,$54,$41,$42,1,9                    ; Tab
        defb    11,$33,$43,$54,0,$54,$6F,$64,$FB,0,11           ; Today
        defb    11,$39,$43,$46,$41,$44,0,$F8,$AD,0,11           ; First Active Day
        defb    13,$38,$43,$4C,$41,$44,0,$4C,$61,$CA,$AD,0,13   ; Last Active Day
        defb     8,$36,$F1,0,$97,$AD,0,8                        ; Next Active Day
        defb     8,$37,$F0,0,$98,$AD,0,8                        ; Previous Active Day
        defb     9,$35,$F3,0,$98,$44,$FB,0,9                    ; Previous Day
        defb     9,$34,$F2,0,$97,$44,$FB,0,9                    ; Next Day
        defb    1
        defb     7,$7F,$E3,0,$E0,0,7                            ; Rubout
        defb     8,7,$47,0,$96,$E9,0,8                          ; Delete Character
        defb     6,7,$D3,0,4,6                                  ; 
        defb     8,$15,$55,0,$CB,$E9,0,8                        ; Insert Character
        defb     8,$14,$54,0,$96,$D3,0,8                        ; Delete Word
        defb    10,4,$44,0,$96,$BB,$DF,$A9,0,10                 ; Delete to End of Line
        defb    8,$3A,$59,0,$96,$A9,0,8                         ; Delete Line
        defb    6,$3A,$C3,0,4,6                                 ; 
        defb    8,$3C,$4E,0,$CB,$A9,0,8                         ; Insert Line
        defb    7,$16,$56,0,$EA,1,7                             ; Insert/Overtype
        defb    7,$13,$53,0,$FF,0,7                             ; Swap Case
        defb    8,$3F,$4A,0,$97,$EC,0,8                         ; Next Option
        defb    16,$3E,$45,$4D,$46,0,$4D,$65,$6D,$8F,$D6,$46,$8D,$65,0,16       ; Memory Free
        defb    13,$3D,$45,$53,$4C,0,$53,$D9,$69,$84,$A9,1,13   ; Split Line
        defb    13,$3B,$45,$4A,$4C,0,$4A,$6F,$A3,$A9,$73,0,13   ; Join Lines
        defb    1
        defb    8,$40,$46,$4C,0,$E1,0,8                         ; Load
        defb    9,$41,$46,$53,0,$BD,$65,0,9                     ; Save
        defb    0

.PrinterEdTopics
        defb    0
        defb    4,$DC,0,4
        defb    4,$FD,0,4
        defb    0
.PrinterEdCommands
        defm    0
        defm    8,$26,$4A,0,$97,$EC,0,8                                 ; Next Option
        defm    7,$0D,$E1,0,$D2,0,7                                     ; ENTER
        defm    7,$1B,$1B,0,$B1,0,7                                     ; ESCAPE
        defm    7,$FD,$FD,0,$A7,1,7                                     ; Cursor LRUD
        defm    7,$FC,$FC,0,$A8,0,7
        defm    7,$24,$FF,0,$DA,0,7
        defm    7,$25,$FE,0,$DB,0,7
        defm    14,$27,$FB,0,"Page 1/2",1,14       ; Page 1/2
        defm    14,$28,$FA,0,"Page 1/2",0,14       ; Page 1/2  !! should be 2/2?
        defm    24,$2E,$49,$53,$4F,0,"ISO Translations",0,24            ; ISO Translations
        defm    1
        defm    8,$29,$46,$4C,0,$E1,0,8
        defm    9,$2A,$46,$53,0,$BD,$65,0,9
        defm    10,$2B,$46,$43,0,$4E,$ED,$65,0,10
        defm    12,$2C,$46,"NEW",0,"New",0,12
        defm    16,$2D,$46,$55,0,$B9,$64,$91,$82,$44,$72,$69,$76,$86,0,16
        defb    0

;       BBAA

.PanelTopics
        defb    0
        defb    4,$DC,0,4
        defb    4,$FD,0,4
        defb    0

;       BBB4
.PanelCommands
        defb    0
        defb    8,$26,$4A,0,$97,$EC,0,8
        defb    7,$0D,$E1,0,$D2,0,7
        defb    7,$1B,$1B,0,$B1,0,7
        defb    7,$FD,$FD,0,$A7,1,7     ; Cursor LRUD
        defb    7,$FC,$FC,0,$A8,0,7
        defb    7,$24,$FF,0,$DA,0,7
        defb    7,$25,$FE,0,$DB,0,7
        defb    1
        defb    8,$29,$46,$4C,0,$E1,0,8
        defb    9,$2A,$46,$53,0,$BD,$65,0,9
        defb    12,$2C,$46,$4E,$45,$57,0,$4E,$65,$77,0,12
        defb    0

.FilerTopics
        defb    0
        defb    4,$D8,0,4
        defb    0
.FilerCommands
        defb    0
        defb    15,$21,$43,$46,0,$43,$91,$95,$6F,$67,$75,$82,$FD,0,15   ; Catalogue Files
        defb    8,$25,$43,$4F,0,$DE,0,8                                 ; Copy
        defb    11,$26,$52,$45,0,$52,$A2,$ED,$65,0,11                   ; Rename
        defb    10,$27,$45,$52,0,$45,$E2,$EB,0,10                       ; Erase
        defb    12,$2A,$45,$58,0,$E8,$65,$63,$75,$AF,0,12               ; Execute
        defb    9,$0D,$E1,0,$E3,$F8,$BA,0,9                             ; Select First File
        defb    12,$20,$D1,0,$E3,$E8,$74,$E2,$20,$BA,0,12               ; Select Extra File
        defb    6,$20,$E2,0,4,6                                         ; ???
        defb    12,$2B,$43,$44,0,$43,$8D,$91,$82,$B6,1,12               ; Create Directory
        defb    9,$28,$53,$49,0,$E3,$B6,0,9                             ; Select Directory
        defb    9,$2E,$FB,0,$B9,$20,$B6,0,9                             ; Up Directory
        defb    9,$2F,$FA,0,$AC,$20,$B6,0,9                             ; Down Directory
        defb    7,$FD,$FD,0,$A7,0,7                                     ; Cursor Right
        defb    7,$FC,$FC,0,$A8,0,7                                     ; Cursor Left
        defb    7,$FF,$FF,0,$DA,0,7                                     ; Cursor Up
        defb    7,$FE,$FE,0,$DB,0,7                                     ; Cursor Down
        defb    15,$22,$43,$45,0,$43,$91,$95,$6F,$67,$75,$82,$EE,1,15   ; Catalogue EPROM
        defb    11,$23,$45,$53,0,$BD,$82,$BB,$EE,0,11                   ; Save to EPROM
        defb    17,$24,$45,$46,0,$46,$65,$74,$B4,$20,$66,$72,$6F,$D7,$EE,0,17   ; Fetch from EPROM
        defb    13,$29,$53,$56,0,$E3,$44,$65,$76,$69,$C9,0,13           ; Select Device
        defb    11,$2C,$54,$43,0,$54,$8D,$82,$DE,0,11                   ; Tree Copy
        defb    11,$2D,$4E,$4D,0,$4E,$ED,$82,$F7,0,11                   ; Name Match
        defb    0

.TerminalTopics
        defb    0
        defb    4,$D8,0,4
        defb    0
.TerminalCommands
        defb    0
        defb    7,2,$E3,0,$E0,0,7                               ; Rubout
        defb    14,3,$D3,0,$42,$61,$63,$6B,$73,$70,$61,$C9,0,14 ; Backspace
        defb    8,1,$D1,0,$E8,$FC,0,8                           ; Exit
        defb    7,6,$FD,0,$A7,1,7                               ; Cursor Right
        defb    7,7,$FC,0,$A8,0,7                               ; Cursor Left
        defb    7,4,$FF,0,$DA,0,7                               ; Cursor Up
        defb    7,5,$FE,0,$DB,0,7                               ; Cursor Down
        defb    9,8,$F8,0,$9C,$20,$30,1,9                       ; Function 0
        defb    9,9,$F9,0,$9C,$20,$31,0,9                       ; Function 1
        defb    9,$0A,$FA,0,$9C,$20,$32,0,9                     ; Function 2
        defb    9,$0B,$FB,0,$9C,$20,$33,0,9                     ; Function 3
        defb    0

.AlarmDOR
        defp    0,0                     ; parent
        defp    FilerDor|$c000,7              ; brother
.AlarmTCH
        defp    0,0                     ; son
        defb    $83,AlarmDORe-$PC       ; DOR type, sizeof

        defb    '@',18,0,0              ; info, info sizeof, 2xreserved
        defb    'A',0                   ; application key letter, bad app RAM
        defw    0,0,0                   ; env. size, unsafe and safe workspace
        defw    $E7F4                   ; entry point
        defb    0,0,0,1                 ; bindings
        defb    AT_Good|AT_Popd         ; appl type
        defb    AT2_Ie                  ; appl type 2

        defb    'H',12                  ; help, sizeof
        defp    AlarmTCH&$3fff,7        ; topics
        defp    AlarmTCH&$3fff,7        ; commands
        defp    AlarmTCH&$3fff,7        ; help
        defp    $8000,7                 ; token base

        defb    'N',AlarmDORe-$PC-1     ; name, length
        defm    "Alarm",0
.AlarmDORe
        defb    $FF                     ; terminate

.FilerDOR
        defp    0,0                     ; parent
        defp    $ff90,2                 ; brother
.FilerTCH
        defp    0,0                     ; son
        defb    $83,FilerDORe-$PC       ; DOR type, sizeof

        defb    '@',18,0,0              ; info, info sizeof, 2xreserved
        defb    'F',0                   ; application key letter, bad app RAM
        defw    0,$230,0                ; env. size, unsafe and safe workspace
        defw    $EAB1                   ; entry point
        defb    0,0,0,2                 ; bindings
        defb    AT_Good|AT_Popd|AT_Film ; appl type
        defb    0                       ; appl type 2

        defb    'H',12                  ; help, sizeof
        defp    FilerTopics&$3fff,7     ; topics
        defp    FilerCommands&$3fff,7   ; commands
        defp    FilerTCH&$3fff,7        ; help
        defp    $8000,7                 ; token base

        defb    'N',FilerDORe-$PC-1     ; name, length
        defm    "Filer",0
.FilerDORe
        defb    $FF                     ; terminate

.IndexDOR
        defp    0,0                     ; parent
        defp    DiaryDOR|$c000,7        ; brother
.IndexTCH
        defp    0,0                     ; son
        defb    $83,IndexDORe-$PC       ; DOR type, sizeof

        defb    '@',18,0,0              ; info, info sizeof, 2xreserved
        defb    'I',0                   ; application key letter, bad app RAM
        defw    0,$28,0                 ; env. size, unsafe and safe workspace
        defw    $C000                   ; entry point
        defb    0,0,0,2                 ; bindings
        defb    AT_Good|AT_Popd|AT_Ones ; appl type
        defb    0                       ; appl type 2

        defb    'H',12                  ; help, sizeof
        defp    IndexTopics&$3fff,7     ; topics
        defp    IndexCommands&$3fff,7   ; commands
        defp    IndexTCH&$3fff,7       ; help
        defp    $8000,7                 ; token base

        defb    'N',IndexDORe-$PC-1     ; name, length
        defm    "Index",0
.IndexDORe
        defb    $FF                     ; terminate

.DiaryDOR
        defp    0,0                     ; parent
        defp    PipeDreamDOR|$c000,7    ; brother
.DiaryTCH
        defp    0,0                     ; son
        defb    $83,DiaryDORe-$PC       ; DOR type, sizeof

        defb    '@',18,0,0              ; info, info sizeof, 2xreserved
        defb    'D',0                   ; application key letter, bad app RAM
        defw    $26C,0,$20              ; env. size, unsafe and safe workspace
        defw    $C000                   ; entry point
        defb    0,0,0,1                 ; bindings
        defb    AT_Good|AT_Ones         ; appl type
        defb    0                       ; appl type 2

        defb    'H',12                  ; help, sizeof
        defp    DiaryTopics&$3fff,7     ; topics
        defp    DiaryCommands&$3fff,7   ; commands
        defp    DiaryTCH&$3fff,7        ; help
        defp    $8000,7                 ; token base

        defb    'N',DiaryDORe-$PC-1     ; name, length
        defm    "Diary",0
.DiaryDORe
        defb    $FF                     ; terminate

.PipeDreamDOR
        defp    0,0                     ; parent
        defp    BasicDOR|$c000,7        ; brother
.PipeDreamTCH
        defp    0,0                     ; son
        defb    $83,PipeDreamDORe-$PC   ; DOR type, sizeof

        defb    '@',18,0,0              ; info, info sizeof, 2xreserved
        defb    'P',0                   ; application key letter, bad app RAM
        defw    $4D8,$268,$60           ; env. size, unsafe and safe workspace
        defw    $8000                   ; entry point
        defb    0,0,4,5                 ; bindings
        defb    AT_Good                 ; appl type
        defb    0                       ; appl type 2

        defb    'H',12                  ; help, sizeof
        defp    PipeDreamTopics&$3fff,7 ; topics
        defp    PipeDreamCommands&$3fff,7       ; commands
        defp    PipeDreamTCH&$3fff,7    ; help
        defp    $8000,7                 ; token base

        defb    'N',PipeDreamDORe-$PC-1 ; name, length
        defm    "PipeDream",0
.PipeDreamDORe
        defb    $FF                     ; terminate

.BasicDOR
        defp    0,0                     ; parent
        defp    CalculatorDOR|$c000,7         ; brother
.BasicTCH
        defp    0,0                     ; son
        defb    $83,BasicDORe-$PC       ; DOR type, sizeof

        defb    '@',18,0,0              ; info, info sizeof, 2xreserved
        defb    'B',0                   ; application key letter, bad app RAM
        defw    $9B0,$3E,$52            ; env. size, unsafe and safe workspace
        defw    $D200                   ; entry point
        defb    0,0,0,6                 ; bindings
        defb    AT_Bad|AT_Draw          ; appl type
        defb    AT2_Cl                  ; appl type 2

        defb    'H',12                  ; help, sizeof
        defp    BasicTCH&$3fff,7        ; topics
        defp    BasicTCH&$3fff,7        ; commands
        defp    BasicTCH&$3fff,7        ; help
        defp    0,0                     ; token base

        defb    'N',BasicDORe-$PC-1     ; name, length
        defm    "BASIC",0
.BasicDORe
        defb    $FF                     ; terminate

.CalculatorDOR
        defp    0,0                     ; parent
        defp    $ff91,6                 ; brother
.CalculatorTCH
        defp    0,0                     ; son
        defb    $83,CalculatorDORe-$PC  ; DOR type, sizeof

        defb    '@',18,0,0              ; info, info sizeof, 2xreserved
        defb    'R',0                   ; application key letter, bad app RAM
        defw    0,$12,$40               ; env. size, unsafe and safe workspace
        defw    $F300                   ; entry point
        defb    0,0,0,3                 ; bindings
        defb    AT_Good|AT_Popd         ; appl type
        defb    0                       ; appl type 2

        defb    'H',12                  ; help, sizeof
        defp    CalculatorTCH&$3fff,7   ; topics
        defp    CalculatorTCH&$3fff,7   ; commands
        defp    CalculatorTCH&$3fff,7   ; help
        defp    $8000,7                 ; token base

        defb    'N',CalculatorDORe-$PC-1        ; name, length
        defm    "Calculator",0
.CalculatorDORe
        defb    $FF                     ; terminate

.TerminalDOR
        defp    0,0                     ; parent
        defp    $ffc5,1                 ; brother
.TerminalTCH
        defp    0,0                     ; son
        defb    $83,TerminalDORe-$PC    ; DOR type, sizeof

        defb    '@',18,0,0              ; info, info sizeof, 2xreserved
        defb    'V',0                   ; application key letter, bad app RAM
        defw    $744,0,$A               ; env. size, unsafe and safe workspace
        defw    $E7F0                   ; entry point
        defb    0,0,0,2                 ; bindings
        defb    AT_Good|AT_Ones|AT_Draw ; appl type
        defb    AT2_Ie                  ; appl type 2

        defb    'H',12                  ; help, sizeof
        defp    TerminalTopics&$3fff,7  ; topics
        defp    TerminalCommands&$3fff,7; commands
        defp    TerminalTCH&$3fff,7     ; help
        defp    $8000,7                 ; token base

        defb    'N',TerminalDORe-$PC-1  ; name, length
        defm    "Terminal",0
.TerminalDORe
        defb    $FF                     ; terminate

        defb    0
        defm    "{ Clive Dave Eric Felicity^2 Graham Jim John Mark"
        defm    " Matthew^2 Paul Peter Richard^3 Tim Wings Zee&Kessna }",13,0

	defs	67 ($ff)

;       $BFC0
        defp    0,0                     ; parent
        defp    0,0                     ; brother
        defp    IndexDor|$c000,7        ; son
        defb    $13,8                   ; DOR type, sizeof

        defb    $4e,$05                 ; name, length
        defm    "APPL",0
        defb    $ff                     ; terminate

.BootCode
	ld	a, OZBANK_HI
	out     (BL_SR3), a
	jp	Bootstrap3

        defs    30 ($ff)

;       $BFF8

;       defb    $54,$43                 ; card ID       !! "TCL"
	jr	BootCode
        defb    $4C                     ; country ID
        defb    $81                     ; external app would be $80
        defb    8                       ; size in banks
        defb    'Z'                     ; subtype: bootable, jp $bff8!
        defm    "OZ"
