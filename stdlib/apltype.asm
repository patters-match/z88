     XLIB ApplEprType

     LIB MemAbsPtr
     LIB MemReadByte, MemWriteByte

IF MSDOS | UNIX
     include "error.def"
     include "memory.def"
else
     include ":*//error.def"
     include ":*//memory.def"
endif


; ************************************************************************
;
; Evaluate Standard Z88 Application ROM Format (Front DOR/ROM Header).
;
; Return Standard Application ROM "OZ" status in slot x (0, 1, 2 or 3).
;
; ------------------------------------------------------------------------
;
; Design & programming by Gunther Strube, InterLogic, Apr - Aug 1998
;
; ------------------------------------------------------------------------
; Version History:
;
; $Header$
;
; $History: AplType.asm $
; 
; *****************  Version 2  *****************
; User: Gbs          Date: 16-08-98   Time: 16:21
; Updated in $/Z88/StdLib/Memory
; Extended to evaluate Rom Front Dor in a Ram Card. This has been made to
; return a new application card type code, $82, which identifies the
; Front Dor as being alterable. 
; 
; This change is a reflection of Garry Lancaster's Installer utility to
; allow "insertion" of static applications on a RAM card.
; 
; *****************  Version 1  *****************
; User: Gbs          Date: 16-04-98   Time: 21:12
; Created in $/Z88/StdLib/Memory
; ----------------------------------------------------------------------
;
; In:
;    C = slot number (0, 1, 2 or 3)
;
; Out:
;    Success:
;         Fc = 0,
;              A = Application Eprom type (with Rom Front Dor):
;                   $80 = external EPROM, 
;                   $81 = system/internal EPROM,
;                   $82 = external RAM
;              B = size of reserved Application space in 16K banks.
;              C = size of physical Application Card in 16K banks.
;
;    Failure:
;         Fc = 1,
;              A = RC_ONF, Application Eprom not found
;
; Registers changed after return:
;    ....DEHL/IXIY same
;    AFBC..../.... different
;
.ApplEprType
                    PUSH DE
                    PUSH HL

                    LD   A,C                 ; slot C
                    LD   B,$3F
                    LD   HL,$3F00            ; top 256 byte page of top bank in slot
                    CALL MemAbsPtr           ; Convert to physical pointer...

                    LD   A,$FB
                    CALL MemReadByte         
                    LD   C,A                 ; get Application ROM type ($80 or $81)
                    LD   A,$FC               ; offset $FC
                    CALL MemReadByte
                    PUSH AF                  ; size of reserved Application space, $3FFC
                    CALL CheckRomId
                    JR   NZ,no_applrom       ; "OZ" watermark not found...

                    LD   A,C                 ; Application Rom found
                    AND  @11111110
                    XOR  $80
                    JR   NZ, no_applrom      ; invalid Application Type Code...

                    CALL CheckRamCard        ; If FRONT DOR is located in a RAM card, return type $82
                    
                    POP  DE                  ; D = size of reserved Application space (16K bank entities)
                    LD   E,C                 ; E = Application ROM Type Code ($80 or $81)
                    LD   A,D
                    CALL GetCardSize
                    LD   C,A                 ; C = physical card size (16K bank entities)
                    LD   B,D                 ; B = size of reserved Application space (16K bank entities)
                    LD   A,E                 ; A = Application ROM Type Code ($80 or $81)

                    POP  HL                  ; original HL restored
                    POP  DE                  ; original DE restored
                    RET

.no_applrom         POP  AF
                    LD   A,RC_ONF
                    SCF
                    POP HL
                    POP DE
                    RET


; ************************************************************************
;
; Calculate physical size of Card by scanning for "OZ" header from 
; bank $3E downwards in available 1MB slot.
;
; In:
;    B = top bank of slot containing Front DOR.
;    A = size of reserved Application space (16K bank entities)
;
;    HL = offset $3F00 (mapped to free segment in address space).
;
; Out:
;    A = physical size of card in 16K entities.
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;
.GetCardSize        PUSH DE
                    LD   D,B            ; preserve top bank number in slot
                    LD   E,A
                    LD   A,B
                    SUB  E              ; TopBank - ReservedSpace
                    LD   B,A            ; begin parsing at bank below reserved appl. space
                    LD   A,64
                    SUB  E              ; parse max. 64 - ReservedSpace banks...
.scan_loop
                    CALL CheckRomId
                    JR   Z, oz_found
                    DEC  B
                    DEC  A
                    JR   NZ,scan_loop

.oz_found           RES  7,B            ; slot size always max 64 * 16K banks...
                    RES  6,B
                    LD   A,D
                    AND  @00111111      
                    SUB  B              ; Card Size = TopBank - TopBank' (0-64)
                    POP  DE
                    RET  NZ
                    LD   A,64           ; Card was 1MB...
                    RET

; ************************************************************************
;
; IN:
;    A = original Application Card Type Code ($80 or $81)
;    BHL = <top bank> $3F00
;
; OUT:
;    A = $82, if FRONT DOR in RAM card, otherwise original code.
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;
.CheckRamCard       PUSH BC
                    PUSH DE

                    LD   E,A
                    LD   A,$F8
                    CALL MemReadByte         ; get low byte card ID
                    INC  A
                    LD   C,A
                    LD   A,$F8
                    CALL MemWriteByte        ; try to write another value to "RAM"
                    LD   A,$F8
                    CALL MemReadByte         ; then read it back
                    CP   C                   ; changed?
                    JR   Z, ramcard
                         LD   A,E            ; Eprom Card - return original type code
                         JR   exit_CheckRamCard
.ramcard                 
                         DEC  C
                         LD   A,$F8
                         CALL MemWriteByte        ; write back original card id
                         LD   A,$82               ; return $82 for RAM based application card
.exit_CheckRamCard
                    POP  DE
                    POP  BC
                    RET


; ************************************************************************
;
; Check for "OZ" watermark at bank B, offset $3FFE.
;
; In:
;    B = Bank (usually $3F, mapped to slot X) containing possible Front DOR.
;    HL = offset $3F00 (mapped to free segment).
;
; Out:
;    Success:
;         Fz = 1,
;              "OZ" watermark found in bank B
;
;    Failure:
;         Fz = 0,
;              "OZ" watermark not found.
;
; Registers changed after return:
;    A.BCDEHL/IXIY same
;    .F....../.... different
;
.CheckRomId         PUSH DE
                    PUSH AF

                    LD   A,$FE
                    CALL MemReadByte
                    LD   D,A                 ; 'O'
                    LD   A,$FF
                    CALL MemReadByte
                    LD   E,A                 ; 'Z'

                    CP   A
                    PUSH HL
                    LD   HL,$4F5A
                    SBC  HL,DE               ; 'OZ' ?
                    POP  HL
                    
                    POP  DE
                    LD   A,D                 ; original A restored
                    POP  DE
                    RET                      ; Fz = ?
