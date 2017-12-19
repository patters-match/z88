     XLIB Difference

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
;
;***************************************************************************************************

     LIB Read_pointer, Read_byte

     INCLUDE "avltree.def"


; **************************************************************************************
;
;    INTERNAL AVLTREE ROUTINE
;
;    Return the difference between the heights of the left and right subtree of node n.
;
;         IN:  BHL = pointer to node n
;         OUT: A = difference of subtree heights  (2. complement notation)
;
;         Local variables:    D = leftheight
;                             E = rightheight
;
;    Register affected on return:
;         ..BC..HL/IXIY
;         AF..DE../.... af
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ----------------------------------------------------------------------
;
.Difference         PUSH BC
                    PUSH HL
                    XOR  A                        ; A = 0
                    CP   B
                    JR   Z, exit_difference       ; if ( n != NULL )
                         PUSH BC
                         PUSH HL                       ; preserve n
                         LD   A,avltree_left
                         CALL Read_pointer
                         INC  B
                         DEC  B
.diff_tst_leftsubtree    JR   NZ, diff_get_leftheight  ; if ( n->left == NULL )
                              LD   D,-1                     ;    leftheight = -1
                              JR   diff_tst_rightsubtree    ; else
.diff_get_leftheight          LD   A,avltree_height
                              CALL Read_byte                ; leftheight = n->left->height , heigth of left subtree
                              LD   D,A

.diff_tst_rightsubtree   POP  HL
                         POP  BC
                         LD   A,avltree_right
                         CALL Read_pointer
                         INC  B
                         DEC  B
                         JR   NZ, diff_get_rightheight ; if ( n->right == NULL )
                              LD   E,-1                ;    rightheight = -1
                              JR   calc_difference     ; else
.diff_get_rightheight         LD   A,avltree_height
                              CALL Read_byte           ;    rightheight = n->right->height , heigth of right subtree
                              LD   E,A

.calc_difference    LD   A,D
                    SUB  E                   ; return leftheight - rightheight
.exit_difference    POP  HL
                    POP  BC
                    RET
