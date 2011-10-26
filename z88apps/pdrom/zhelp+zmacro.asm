MODULE pdrom

include "stdio.def"
include "fileio.def"
include "error.def"
include "director.def"
include "time.def"
include "saverst.def"


; Z-Help
; Wait for a key and exit!

.L_C000                         CALL   L_C005
                                SCF
                                RET
.L_C005                         CALL_OZ(OS_IN)
                                XOR    A
                                CALL_OZ(OS_BYE)

; ***********************************************************************
; Z-Macro

.L_C00A                         CALL   L_C00F
                                SCF
                                RET
.L_C00F                         XOR    A
                                LD     B,A
                                LD     HL,L_C020
                                CALL_OZ(OS_ERH)
                                LD     A,$05
                                CALL_OZ(OS_ESC)
                                CALL   L_C1F4
                                XOR    A
                                CALL_OZ(OS_BYE)

; Error handler for Z-Macro

.L_C020                         RET    Z
                                CP     $01
                                JR     NZ,L_C029
                                CALL_OZ(OS_ESC)
                                CP     A
                                RET
.L_C029                         CP     $67
                                JR     NZ,L_C030
                                XOR    A
                                CALL_OZ(OS_BYE)
.L_C030                         CP     $66
                                JR     NZ,L_C036
                                CP     A
                                RET
.L_C036                         CP     A
                                RET


; Z-Macro main entry point

.L_C1F4                         LD     HL,$0000
                                LD     ($1F9E),HL
                                LD     ($1FA0),HL
                                ADD    HL,SP
                                LD     ($1FA2),HL
                                CALL_OZ(OS_IN)          ; get the key
                                JP     C,L_C383
                                CALL   L_CAA2
                                LD     ($1F9D),A
                                CALL   L_C3B6
.L_C20F                         CALL   L_C375
                                CP     '.'
                                JR     NZ,L_C22A
                                CALL   L_C375
                                CP     '#'
                                JR     NZ,L_C22A
                                CALL   L_C375
                                CALL   L_CAA2
                                LD     B,A
                                LD     A,($1F9D)
                                CP     B
                                JR     Z,L_C22F
.L_C22A                         CALL   L_C294
                                JR     L_C20F
.L_C22F                         CALL   L_C294
                                CALL   L_C3D2
                                LD     A,'Z'
                                CALL   L_C287
                                LD     A,$0D
                                CALL   L_C287
.L_C23F                         CALL   L_C375
                                CP     '.'
                                JR     Z,L_C258
                                CALL   L_C29F
                                CALL   L_C287
.L_C24C                         CALL   L_C29C
                                CALL   L_C287
                                CP     $0D
                                JR     Z,L_C23F
                                JR     L_C24C
.L_C258                         CALL   L_C375
                                CP     '#'
                                JR     Z,L_C26B
                                PUSH   AF
                                LD     A,'.'
                                CALL   L_C287
                                POP    AF
                                CALL   L_C287
                                JR     L_C24C
.L_C26B                         CALL   L_C38E
                                LD     BC,$000F
                                LD     HL,L_C400
                                LD     DE,$1FA4
                                PUSH   DE
                                LDIR
                                POP    HL
                                LD     BC,$000F
                                CALL_OZ(DC_ICL)
                                LD     BC,$0001
                                CALL_OZ(OS_TIN)
                                RET

; Subroutine to write a byte

.L_C287                         LD     IX,($1FA0)
                                CALL_OZ(OS_PB)
                                RET    NC
                                LD     HL,L_C4F6
                                JP     L_C3A1

; Subroutine to ???

.L_C294                         CALL   L_C375
                                CP     $0D
                                JR     NZ,L_C294
                                RET

; Subroutine to ???

.L_C29C                         CALL   L_C375
.L_C29F                         CP     '{'
                                RET    NZ
                                CALL   L_C375
                                CP     '{'
                                RET    Z
                                LD     HL,$1FA4
                                LD     (HL),A
                                INC    HL
                                LD     B,'/'
.L_C2AF                         PUSH   HL
                                PUSH   BC
                                CALL   L_C375
                                CP     '}'
                                JR     Z,L_C2C7
                                POP    BC
                                POP    HL
                                DEC    B
                                JR     NZ,L_C2C3
                                LD     HL,L_C520
                                JP     L_C3A1
.L_C2C3                         LD     (HL),A
                                INC    HL
                                JR     L_C2AF
.L_C2C7                         POP    HL
                                POP    HL
                                XOR    A
                                LD     (HL),A
                                LD     A,($1FA4)
                                CALL   L_CAA2
                                CP     'd'
                                JP     Z,L_C2E7
                                CP     't'
                                JP     Z,L_C31B
                                CP     '?'
                                JP     Z,L_C348
                                JP     L_C2E3
.L_C2E3                         CALL   L_C375
                                RET
.L_C2E7                         LD     DE,$1FD4
                                CALL_OZ(GN_GMD)
                                LD     HL,$1FA5
                                CALL   L_CAF6
                                PUSH   AF
                                CALL   L_CAF6
                                PUSH   AF
                                CALL   L_CAF6
                                LD     C,A
                                POP    AF
                                LD     B,A
                                POP    AF
                                LD     HL,$1FD4
                                LD     DE,$1FA4
                                PUSH   DE
                                CALL_OZ(GN_PDT)
                                XOR    A
                                EX     DE,HL
                                LD     (HL),A
                                POP    HL
.L_C30D                         LD     A,(HL)
                                CP     $00
                                JP     Z,L_C2E3
                                PUSH   HL
                                CALL   L_C287
                                POP    HL
                                INC    HL
                                JR     L_C30D
.L_C31B                         LD     DE,$1FD4
                                CALL_OZ(GN_GMT)
                                LD     HL,$1FA5
                                CALL   L_CAF6
                                AND    $F7
                                LD     HL,$1FD4
                                LD     DE,$1FA4
                                PUSH   DE
                                CALL_OZ(GN_PTM)
                                XOR    A
                                EX     DE,HL
                                LD     (HL),A
                                POP    HL
.L_C337                         LD     A,(HL)
                                CP     $00
                                JP     Z,L_C2E3
                                PUSH   HL
                                CALL   L_C287
                                POP    HL
                                INC    HL
                                JR     L_C337
.L_C345                         JP     L_C2E3
.L_C348                         LD     HL,L_C41D
                                CALL_OZ(GN_SOP)
                                LD     HL,$1FA5
                                CALL_OZ(GN_SOP)
                                LD     HL,L_C43A
                                CALL_OZ(GN_SOP)
                                LD     A,$00
                                LD     B,$28
                                LD     DE,$1FD4
                                CALL_OZ(GN_SIP)
                                LD     HL,$1FD4
.L_C367                         LD     A,(HL)
                                CP     $00
                                JP     Z,L_C2E3
                                PUSH   HL
                                CALL   L_C287
                                POP    HL
                                INC    HL
                                JR     L_C367

; Subroutine to get a byte

.L_C375                         LD     IX,($1F9E)
                                CALL_OZ(OS_GB)
                                RET    NC
                                CP     $09
                                JP     Z,L_C39B
                                JR     L_C375

; Subroutine to ????

.L_C383                         LD     HL,($1FA2)
                                LD     SP,HL
                                CALL   L_C38E
                                CALL   L_C94C
                                RET

; Subroutine to ????

.L_C38E                         LD     HL,$1F9E
                                CALL   L_CBC1
                                LD     HL,$1FA0
                                CALL   L_CBC1
                                RET

; Subroutine to ????

.L_C39B                         LD     HL,L_C496
                                JP     L_C3A1

; Subroutine to ????

.L_C3A1                         PUSH   HL
                                CALL   L_C3AF
                                POP    HL
                                CALL_OZ(GN_SOP)
                                CALL   L_CA6C
                                JP     L_C383

; Subroutine to ???

.L_C3AF                         LD     HL,L_C40F
                                CALL   L_C965
                                RET

; Subroutine to ????

.L_C3B6                         LD     A,$01
                                LD     B,$00
                                LD     C,$20
                                LD     DE,$1FA4
                                LD     HL,L_C3EE
                                CALL_OZ(GN_OPF)
                                JR     NC,L_C3CD
                                LD     HL,L_C460
                                JP     L_C3A1

; Subroutine to ????

.L_C3CD                         LD     ($1F9E),IX
                                RET

; Subroutine to ????

.L_C3D2                         LD     A,$02
                                LD     B,$00
                                LD     C,$20
                                LD     DE,$1FA4
                                LD     HL,L_C402
                                CALL_OZ(GN_OPF)
                                JR     NC,L_C3E9
                                LD     HL,L_C4CC
                                JP     L_C3A1

; Subroutine to ????

.L_C3E9                         LD     ($1FA0),IX
                                RET

; Messages

.L_C3EE defm    ":RAM.0/ZMACRO.MAC",0
.L_C400 defm    ".*"
.L_C402 defm    ":RAM.0/E.CLI",0
.L_C40F defm    "Z-MACRO v 1.00",0
.L_C41D defm    1,"7#1",$2B,$22,$5C,$24,$83,1,"2I1",1,"4+TUR"
        defm    1,"2JC",1,"3@",$20,$20,0
.L_C43A defm    1,"3@",$20,$20,1,"2A",$5C,1,"7#1",$2B,$23,$5C,$23,$81
        defm    1,"2I1",1,"3+CS",1,"2JN",$0C,$0A,"   >",0
.L_C460 defm    1,"2JC",1,"2-C",$0C,$0A,$0A,$0A
        defm    "Z-Macro file :RAM.0/ZMACRO.MAC not found",$0A,0
.L_C496 defm    1,"2JC",1,"2-C",$0C,$0A,$0A,$0A
        defm    "End of file reached on :RAM.0/ZMACRO.MAC",$0A,0
.L_C4CC defm    1,"2JC",1,"2-C",$0C,$0A,$0A,$0A
        defm    "Error opening temporary file",$0A,0
.L_C4F6 defm    1,"2JC",1,"2-C",$0C,$0A,$0A,$0A
        defm    "Error writing temporary file",$0A,0
.L_C520 defm    1,"2JC",1,"2-C",$0C,$0A,$0A,$0A
        defm    "Z-Macro command too long",$0A,0


; Subroutine to ???

.L_C94C                         LD     HL,L_C953
                                CALL_OZ(GN_SOP)
                                RET

.L_C953 defm    1,"7#1",$20,$20,$7B,$28,$80,1,"2C1",1,"S",1,"C",0

; Subroutine to ????

.L_C965                         PUSH   HL
                                LD     HL,L_C977
                                CALL_OZ(GN_SOP)
                                POP    HL
                                CALL_OZ(GN_SOP)
                                LD     HL,L_C994
                                CALL_OZ(GN_SOP)
                                RET

.L_C977 defm    1,"7#1",$21,$20,$78,$28,$83,1,"2I1",1,"4+TUR"
        defm    1,"2JC",1,"3@",$20,$20,0

.L_C994 defm    1,"3@",$20,$20,1,"2A",$78,1,"7#1",$21,$21,$78,$27,$81
        defm    1,"2I1",1,"3+CS",1,"S",1,"2+C",0


; Subroutine to ????

.L_CA6C                         PUSH   AF
                                PUSH   BC
                                PUSH   DE
                                PUSH   HL
.L_CA70                         LD     A,$08
                                CALL_OZ(OS_SR)
                                JR     C,L_CA70
                                POP    HL
                                POP    DE
                                POP    BC
                                POP    AF
                                RET


; Subroutine to convert a character to lowercase

.L_CAA2                         CP     'A'
                                RET    C
                                CP     'Z'+1
                                JR     C,L_CAAA
                                RET
.L_CAAA                         OR     $20
                                RET


; Subroutine to ????

.L_CAF6                         PUSH   DE
                                LD     A,(HL)
                                LD     D,A
                                INC    HL
                                LD     A,(HL)
                                LD     E,A
                                INC    HL
                                PUSH   HL
                                EX     DE,HL
                                CALL   L_CB05
                                POP    HL
                                POP    DE
                                RET

.L_CB05                         LD     A,H
                                CALL   L_CB15
                                AND    A
                                RLA
                                RLA
                                RLA
                                RLA
                                LD     H,A
                                LD     A,L
                                CALL   L_CB15
                                ADD    A,H
                                RET

.L_CB15                         CP     'a'-1
                                JR     C,L_CB1B
                                SUB    $20
.L_CB1B                         SUB    $30
                                CP     $0A
                                JR     C,L_CB23
                                SUB    $07
.L_CB23                         RET


; Subroutine to ????

.L_CBC1                         PUSH   HL
                                LD     E,(HL)
                                INC    HL
                                LD     D,(HL)
                                LD     A,E
                                AND    A
                                JR     Z,L_CBD3
                                LD     A,D
                                AND    A
                                JR     Z,L_CBD3
                                PUSH   DE
                                POP    IX
                                CALL_OZ(GN_CL)
.L_CBD3                         POP    HL
                                RET

