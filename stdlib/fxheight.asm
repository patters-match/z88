     XLIB FixHeight

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

     LIB Read_pointer
     LIB Read_byte, Set_byte
     LIB Compare

     INCLUDE "avltree.def"


; ********************************************************************************************
;
;    INTERNAL AVLTREE ROUTINE
;
;    Sets the correct height for node pointed to by n, used after insertion into the subtree
;
;         IN:  BHL = pointer to pointer to node n (**n)
;        OUT:  None
;
;               variables:    D = leftheight
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
.FixHeight          PUSH BC
                    PUSH HL
                    XOR  A
                    CALL Read_pointer             ; get (*n)
                    PUSH BC
                    PUSH HL
                    LD   A, avltree_left          ; (*n)->left
                    CALL Read_pointer
                    XOR  A
                    CP   B                        ; if ( (*n)->left == NULL )
                    JR   NZ, fix_get_leftheight
                         LD   D,-1                ;    leftheight = -1
                         JR   fix_tst_rightsubtree; else
.fix_get_leftheight      LD   A,avltree_height
                         CALL Read_byte
                         LD   D,A                 ;    leftheight = (*n)->left->height
.fix_tst_rightsubtree
                    POP  HL
                    POP  BC
                    PUSH HL
                    PUSH BC                       ; preserve *n ...
                    LD   A,avltree_right
                    CALL Read_pointer
                    XOR  A
                    CP   B
                    JR   NZ, fix_get_rightheight  ; if ( (*n)->right == NULL )
                         LD   E,-1                ;    rightheight = -1
                         JR   fix_height          ; else
.fix_get_rightheight     LD   A,avltree_height
                         CALL Read_byte                ; rightheight = n->right->height , heigth of right subtree
                         LD   E,A
.fix_height         LD   A,D
                    LD   B,E                      ;        A              B
                    CALL Compare                  ; if ( leftheight < rightheight )
                    JR   Z, adjust_left
                         LD   A,E                 ;    h = rightheight + 1
                         JR   store_new_height    ; else
.adjust_left             LD   A,D                 ;    h = leftheight + 1
.store_new_height   INC  A
                    POP  BC
                    POP  HL                       ; *n
                    LD   C,A
                    LD   A, avltree_height
                    CALL Set_byte                 ; (*n)->height = h
                    POP  HL
                    POP  BC
                    RET
