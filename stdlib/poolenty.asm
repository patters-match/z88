     XLIB Get_pool_entity

     XREF pool_handles                            ; data structure in another module


; ******************************************************************************
;
; INTERNAL MALLOC ROUTINE.
;
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
; IN : C = handle index
; OUT: HL = pointer to pool entity
;
; Register status on return:
; AFBCDE../IXIY  same
; ......HL/....  different
;
.Get_pool_entity    PUSH AF
                    PUSH BC
                    LD   HL, pool_handles
                    SLA  C
                    SLA  C                          ; handle index * 4
                    LD   B,0
                    ADD  HL,BC                      ; HL points at pool entity
                    POP  BC
                    POP  AF
                    RET
