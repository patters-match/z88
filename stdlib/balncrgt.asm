     XLIB BalanceRight

; **************************************************************************************************
; This file is part of the Z88 Standard Library.
;
; The Z88 Standard Library is free software; you can redistribute it and/or modify it under 
; the terms of the GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; The Z88 Standard Library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with FlashStore;
; see the file COPYING. If not, write to the
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
;    Restores balance at n after insertion, assuming that the right subtree of n is too high
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
.BalanceRight       PUSH HL                       ; preserve a copy of n
                    PUSH BC
                    XOR  A
                    CALL Read_pointer             ; *n
                    LD   A, avltree_right
                    CALL Read_pointer
                    CALL Difference               ; Difference( (*n)->right );
                    CP   0
                    JR   NZ, tst_diffright        ; if ( Difference() == 0 ) {
                         POP  BC
                         POP  HL
                         CALL RotateLeft          ;     RotateLeft(n), Both subtrees of right child of n have same height
                         XOR  A
                         CALL Read_pointer        ;     *n
                         LD   A, avltree_height
                         CALL Read_byte           ;     (*n)->height
                         SUB  C
                         LD   C,A
                         LD   A, avltree_height
                         CALL Set_byte            ;     ((*n)->height) -= adjust, 'decrease' height of current node
                         LD   A, avltree_left
                         CALL Read_pointer        ;     (*n)->left
                         LD   A, avltree_height
                         CALL Read_byte           ;     (*n)->left->height
                         ADD  A,C
                         LD   C,A
                         LD   A, avltree_height
                         CALL Set_byte            ;     ((*n)->left->height) += adjust, 'increase' height of left subtree
                         RET

.tst_diffright           POP  BC
                         POP  HL
                         BIT  7,A                 ; else
                         JR   Z, diffright_positive    ; if ( Difference() < 0 ) {
                              CALL RotateLeft          ;    RotateLeft(n), right subtree of right child of n is higher
                              XOR  A
                              CALL Read_pointer        ;    get *n
                              LD   A, avltree_left
                              CALL Read_pointer        ;    (*n)->left
                              LD   A, avltree_height
                              CALL Read_byte           ;    (*n)->left->height
                              SUB  2
                              LD   C,A
                              LD   A, avltree_height
                              CALL Set_byte            ;    ((*n)->left->height) -= 2
                              RET
                                                       ; else
.diffright_positive           PUSH HL                  ;    preserve n
                              PUSH BC                  ;
                              XOR  A
                              CALL Read_pointer        ;    *n
                              LD   DE, avltree_right
                              ADD  HL,DE               ;    &(*n)->right
                              CALL RotateRight         ;    RotateRight( &(*n)->right ), rotate right subtree ...
                              POP  BC
                              POP  HL
                              CALL RotateLeft          ;    RotateLeft(n)
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
                              LD   A, avltree_left
                              CALL Read_pointer        ;     (*n)->left
                              LD   A, avltree_height
                              CALL Read_byte           ;     (*n)->left->height
                              SUB  2
                              LD   C,A
                              LD   A, avltree_height
                              CALL Set_byte            ;     ((*n)->left->height) -= 2
                              POP  BC
                              POP  HL                  ;     *n
                              LD   A, avltree_right
                              CALL Read_pointer        ;     (*n)->right
                              LD   A, avltree_height
                              CALL Read_byte           ;     (*n)->right->height
                              DEC  A
                              LD   C,A
                              LD   A, avltree_height
                              CALL Set_byte            ;     --((*n)->right->height)
                              RET
