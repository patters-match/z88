; **************************************************************************************************
;
; Intuition routine entry from CALL instruction in application code that wished Intuition monitoring.
;
; Original values of registers and runtime variables will be stored in an allocated area on the
; system stack in LOWRAM, just below the pointer address contained in the SP register.
;
; After having made a copy of the original registers, and fetched the original PC from
; the return address, a new Stack Pointer is set 2 bytes below the beginning of the reserved area.
; The application PC (the first instruction after the CALL) is also stored at the new stack pointer.
;
; Intuition will by default activate Single Step Mode and Screen Protect Mode.
;
;                             High byte, return address      -+
;     Current SP on entry:    Low  byte, return address       |
;                             ...                             |
;     Intuition               ...                             |
;     Reserved area           ...                             |
;                             ...                             |
;                             ...                            -+
;     New Stack Pointer:      <application PC after this CALL>
;
;
.IntuitionEntry   PUSH IY                   ;                                           ** V0.28
                  PUSH IX                   ;                                           ** V0.28
                  EX   AF,AF'               ;                                           ** V0.28
                  PUSH AF                   ;                                           ** V0.28
                  EX   AF,AF'               ;                                           ** V0.28
                  EXX                       ;                                           ** V0.28
                  PUSH HL                   ;                                           ** V0.28
                  PUSH DE                   ;                                           ** V0.28
                  PUSH BC                   ;                                           ** V0.28
                  EXX                       ;                                           ** V0.28
                  PUSH AF                   ;                                           ** V0.28
                  PUSH HL                   ;                                           ** V0.28
                  PUSH DE                   ;                                           ** V0.28
                  PUSH BC                   ;                                           ** V0.28
                  LD   HL,0
                  ADD  HL,SP
                  LD   DE,20                ;                                           ** V0.28
                  ADD  HL,DE                ; HL points at return address               ** V0.28
                  LD   C,(HL)               ;                                           ** V0.28
                  INC  HL
                  LD   B,(HL)               ; BC = return address (the Intuition PC)    ** V0.28
                  LD   E, Int_Worksp+2      ; now make room for Intuition RTM area      ** V0.28/V0.29
                  SBC  HL,DE                ; and 2 bytes for current PC below RTM
                  LD   SP,HL                ; Set new Application Stack Pointer         ** V0.28
                  LD   D,H                  ;                                           ** V0.28
                  LD   E,L                  ; get a copy of new Top Of Stack (T.O.S.)   ** V0.28
                  LD   (HL),C               ; now at Top of of Stack                    ** V0.20a/V0.29
                  INC  HL                   ; (HL now the new Stack Pointer)            ** V0.20a/V0.29
                  LD   (HL),B               ; return address to application             ** V0.20a/V0.29
                  INC  HL                   ; point at beginning of RTM area            ** V0.29
                  PUSH HL                   ;                                           ** V0.29
                  POP  IY                   ; IY = Base of Intuition Runtime Area
                  LD   (IY + VP_SP),E       ;                                           ** V0.29
                  LD   (IY + VP_SP+1),D     ; New SP installed (Top of Stack)           ** V0.29
                  LD   (IY + VP_PC),C
                  LD   (IY + VP_PC+1),B     ; PC = return address
                  LD   BC,Int_Worksp-20-1
                  ADD  HL,BC                ; HL points at original BC (prev. pushed on stack)
                  LD   C,20                 ;                                           ** V0.28
                  INC  DE                   ;                                           ** V0.29
                  INC  DE                   ; Destination at beginning of RTM           ** V0.29
                  LDIR                      ; copy the registers from (HL) to (DE)...   ** V0.28
                                            ; BC,DE,HL,AF,BC',DE',HL',AF',IX,IY         ** V0.28
