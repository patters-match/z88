     XLIB BalanceLeft

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

     LIB Read_byte, Set_byte
     LIB Read_pointer
     LIB Difference
     LIB RotateLeft, RotateRight

     INCLUDE "avltree.def"


; **************************************************************************************************
;
;    INTERNAL AVLTREE ROUTINE
;
;    Restores balance at n after insertion, assuming that the left subtree of n is too high.
;
;         IN:  BHL = pointer to pointer to node n (**n)
;              C   = adjust constant (1 or -1)
;
;    Register affected on return:
;         ......../IXIY
;         AFBCDEHL/.... af
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ----------------------------------------------------------------------
;
.BalanceLeft        PUSH HL                       ; preserve a copy of n
                    PUSH BC
                    XOR  A
                    CALL Read_pointer             ; *n
                    LD   A, avltree_left
                    CALL Read_pointer
                    CALL Difference               ; Difference( (*n)->left );
                    CP   0
                    JR   NZ, tst_diffleft         ; if ( Difference() == 0 ) {
                         POP  BC
                         POP  HL
                         CALL RotateRight         ;     RotateRight(n), Both subtrees of left child of n have same height
                         XOR  A
                         CALL Read_pointer        ;     *n
                         LD   A, avltree_height
                         CALL Read_byte           ;     (*n)->height
                         SUB  C
                         LD   C,A
                         LD   A, avltree_height
                         CALL Set_byte            ;     ((*n)->height) -= adjust, 'decrease' height of current node
                         LD   A, avltree_right
                         CALL Read_pointer        ;     (*n)->right
                         LD   A, avltree_height
                         CALL Read_byte           ;     (*n)->right->height
                         ADD  A,C
                         LD   C,A
                         LD   A, avltree_height
                         CALL Set_byte            ;     ((*n)->right->height) += adjust, 'increase' height of right subtree
                         RET

.tst_diffleft            POP  BC
                         POP  HL
                         BIT  7,A                 ; else
                         JR   NZ, diffleft_negative;   if ( Difference((*n)->left) > 0 ) {
                              CALL RotateRight         ;    RotateRight(n), right subtree of left child of n is higher
                              XOR  A
                              CALL Read_pointer        ;    get *n
                              LD   A, avltree_right
                              CALL Read_pointer        ;    (*n)->right
                              LD   A, avltree_height
                              CALL Read_byte           ;    (*n)->right->height
                              SUB  2
                              LD   C,A
                              LD   A, avltree_height
                              CALL Set_byte            ;    ((*n)->right->height) -= 2
                              RET
                                                       ;else
.diffleft_negative            PUSH BC                  ;
                              PUSH HL                  ;    preserce n
                              XOR  A
                              CALL Read_pointer        ;    *n
                              LD   DE, avltree_left
                              ADD  HL,DE               ;    &(*n)->left
                              CALL RotateLeft          ;    RotateLeft( &(*n)->left ), rotate right subtree ...
                              POP  HL
                              POP  BC
                              CALL RotateRight         ;    RotateRight(n)
                              XOR  A
                              CALL Read_pointer        ;    *n
                              LD   A, avltree_height
                              CALL Read_byte           ;    (*n)->height
                              LD   C,A
                              INC  C
                              LD   A, avltree_height
                              CALL Set_byte            ;    ++((*n)->height), increase height of current node
                              PUSH HL
                              PUSH BC                  ;    preserve *n
                              LD   A, avltree_right
                              CALL Read_pointer        ;     (*n)->right
                              LD   A, avltree_height
                              CALL Read_byte           ;     (*n)->right->height
                              SUB  2
                              LD   C,A
                              LD   A, avltree_height
                              CALL Set_byte            ;     ((*n)->right->height) -= 2
                              POP  BC
                              POP  HL                  ;     *n
                              LD   A, avltree_left
                              CALL Read_pointer        ;     (*n)->left
                              LD   A, avltree_height
                              CALL Read_byte           ;     (*n)->left->height
                              DEC  A
                              LD   C,A
                              LD   A, avltree_height
                              CALL Set_byte            ;     --((*n)->left->height)
                              RET
