
     XLIB memcompare


; ******************************************************************************
;
;    Compare memory strings
;
;    Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
;    IN:  HL = local pointer to source string
;         DE = local pointer to source string
;         BC = number of bytes to compare
;    OUT: Fz = 1, if strings are equal, otherwise Fz = 0
;
;    Registers changed after return:
;
;         ....DEHL/IXIY  same
;         AFBC..../....  different
;
.memcompare         PUSH DE
                    PUSH HL
.compare_loop       LD   A,(DE)              ; do
                    CPI
                    INC  DE                       ; if ( (HL) != (DE) ) return 0
                    JR   NZ, exit_memcompare
                    JP   PE, compare_loop    ; while ( --BC != 0 )
.exit_memcompare    POP  HL                  ; return 1
                    POP  DE
                    RET
