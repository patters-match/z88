     XLIB Bsearch

; **************************************************************************************************
; This file is part of the Z88 Standard Library.
;
; The Z88 Standard Library is free software; you can redistribute it and/or modify it under 
; the terms of the GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; The Z88 Standard Library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with the
; Z88 Standard Library; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
; 
; $Id$  
;
;***************************************************************************************************


; ****************************************************************************************
;
; Binary search in array
;
; IN: HL = pointer to base of array
;          The first byte at the base of the array identifies the number of
;          elements in the array. The second byte identifies the size of
;          each element in the array, followed by the array elements.
;     DE = pointer to key to be matched with array element.
;     IY = pointer to CALL'ed routine that compares the key (DE) with the current
;          array element (pointed to by HL).
;          The routine must set Fz = 1 if a match is found,
;          otherwise Fz = 0 and Fc = 1 if key < array element
;          (Fc = 0 if key > array element).
;
; OUT: Fz = 1, HL = pointer to found element in array a[k], k is found element
;              in A register (first element in array is defined as 0)
;      Fz = 0, no match was found in the array (HL & A values redundant)
;
; Register status after return:
;    ..BCDE../IXIY/..bc....  same
;    AF....HL/..../af..dehl  different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ----------------------------------------------------------------------
;
.Bsearch            PUSH BC
                    LD   B,0
                    LD   C,(HL)                 ; get size of array element in BC
                    INC  HL                     ;
                    EX   AF,AF'
                    LD   A,(HL)                 ; get k number of elements in array
                    INC  HL                     ; HL points at a[1], first element.
                    CP   A
                    SBC  HL,BC                  ; HL adjusted to a[0] (non existent)
                    PUSH HL
                    EXX                         ; use alternate registers...
                    POP  HL                     ; hl always points at a[0]
                    LD   D,1                    ; a[1]
                    LD   E,A                    ; a[e] , last element in array
                    EX   AF,AF'
                                                ; REPEAT
.find_loop          EXX                         ;     {use main regs}
                    PUSH DE                     ;     preserve pointer to key
                    EXX                         ;     use alternate registers
                    EX   AF,AF'                 ;
                    PUSH HL                     ;     ptr to start of array on stack
                    LD   A,D
                    ADD  A,E                    ;
                    SRL  A                      ;     k = (d+e) DIV 2   {A'}
                    EXX                         ;     use main registers

                    LD   H,A                    ;     index k  (multiplier)
                    LD   L,0
                    EX   AF,AF'
                    LD   D,0
                    LD   E,C                    ;     multiplicand (size of elm.) in E
                    LD   B,8                    ;     8 bit multiplication

.multiply           ADD  HL,HL
                    JR   NC, noadd
                    ADD  HL,DE                  ;     HL = k(index) * E(size)
.noadd              DJNZ multiply
                    EX   DE,HL                  ;     DE = index k from base
                    POP  HL                     ;     get base of array
                    ADD  HL,DE                  ;     HL = pointer to a[k]
                    POP  DE                     ;     restore pointer to key

                    PUSH BC                     ;     preserve size of array element
                    PUSH DE                     ;     preserve pointer to key
                    PUSH HL                     ;     preserve pointer to a[k]
                    PUSH IY
                    LD   IY,move_indices        ;
                    EX   (SP),IY                ;     RETurn address on stack
                    JP   (IY)                   ;     CALL compare routine ( key=a[k]? )
.move_indices       POP  HL                     ;     restore pointer to a[k]
                    POP  DE                     ;     restore pointer to key
                    POP  BC                     ;     restore size of array element
                    EXX                         ;     use alternate's
.id_less_than       CALL C, update_e            ;     key < a[k]  e = k-1
                    JR   C, test_finish
                    CALL Z, update_de           ;     key = a[k]  d = k+1, e = k-1
                    JR   Z, test_finish
.id_larger_than     CALL NC, update_d           ;     key > a[k], d = k+1
.test_finish        LD   A,E
                    CP   D
                    JR   NC, find_loop          ; UNTIL d > e
                    DEC  D
                    CP   D                      ; if d-1 > e then found
                    EXX                         ; back to main registers
                    JR   C, id_found
.id_not_found       INC  A                      ; d-1 <= e, not found
                    POP  BC                     ; restore original BC
                    RET
.id_found           EX   AF,AF'
                    DEC  A                      ; return element k (in A register)
                    CP   A                      ; Fz = 1, found in array, HL ptr. to a[k]
                    POP  BC                     ; restore original BC
                    RET
.update_e           EX   AF,AF'
                    LD   E,A
                    DEC  E                      ; key <= a[k], e = k-1
                    EX   AF,AF'
                    RET
.update_d           EX   AF,AF'
                    LD   D,A
                    INC  D                      ; key >= a[k], d = k+1
                    EX   AF,AF'
                    RET
.update_de          CALL update_d
                    JR   update_e               ; key = a[k]
