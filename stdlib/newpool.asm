     XLIB Alloc_new_pool

     LIB Open_pool, Get_pool_entity


     DEFC POOL_OPEN = 0, POOL_CLOSED = $FF

     if MSDOS | UNIX
         INCLUDE "memory.def"
     endif
     if Z88
         INCLUDE ":*//memory.def"
     endif


; ******************************************************************************
;
;    INTERNAL MALLOC ROUTINE.
;
;    Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
;    IN  : C = new pool index
;
; Register status on return:
; A.BCDEHL/IXIY  same
; .F....../....  different
;
.Alloc_new_pool     PUSH IX
                    PUSH HL
                    PUSH BC
                    PUSH AF                         ; preserve
                    CALL open_pool                  ; open a pool for segment 1
                    JR   C,exit_alloc_pool          ; ups - no memory...
                    CALL Get_pool_entity            ; get pointer to pool index (in C)
                    LD   (HL), POOL_OPEN            ; indicate pool is open
                    INC  HL
                    PUSH IX
                    POP  BC
                    LD   (HL),C
                    INC  HL
                    LD   (HL),B                     ; pool handle saved
                    INC  HL
                    PUSH HL
                    LD   BC,2
                    XOR  A                          ; 2 bytes
                    CALL_OZ(OS_MAL)                 ; dummy allocation to get
                    POP  HL
                    LD   (HL),B                     ; bank number into pool entity
.exit_alloc_pool    POP  BC                         ;
                    LD   A,B                        ; A restored
                    POP  BC                         ; BC restored
                    POP  HL                         ; HL restored
                    POP  IX                         ; IX restored
                    RET
