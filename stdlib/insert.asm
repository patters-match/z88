     XLIB Insert

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

     LIB Set_byte
     LIB Read_pointer, Set_pointer
     LIB BalanceLeft, BalanceRight
     LIB Difference, FixHeight
     LIB malloc
     LIB Compare

     INCLUDE "avltree.def"


; **************************************************************************************************
;
;    Insert (node) data in avltree.
;
;         IN:  BHL = pointer to pointer to AVLtree root
;        OUT:  Fc = 0, new AVLnode created and user data successfully linked.
;              Fc = 1, no room for data.
;
;         The following parameters must also have been prepared and pointed to by IY:
;         (E.g. on the stack before the RETurn address of .Insert)
;
;              High Address
;              (IY+3)-(IY+4)  2.    [pointer to compare routine]                (2 byte logical address)
;              (IY+0)-(IY+2)  1.    [pointer to new node data (to be inserted]  (3 byte extended address)
;              Low Address
;
;    The compare subroutine gets IY as base pointer to parameter block of Insert,
;    BHL as the pointer to the current user data node (avltree->data), NOT the current avltree node, and
;    finally CDE as the pointer to the node to be insert (copied from the parameter block)
;
;    The subroutine must return Fz = 1 if new data node = current data node, otherwise Fc = 1
;    if new node > current node, otherwise Fc = 0.
;    IY must not be altered by the Compare subroutine (because IY points to parameter block).
;
;    The node is inserted (and the tree possibly balanced) even though the search key finds a match.
;
;    Register affected on return:
;         ......../IXIY  same
;         AFBCDEHL/....  different
;
; ---------------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ---------------------------------------------------------------------------
;
.Insert             PUSH BC                  ; preserve pointer to pointer
                    PUSH HL
                    XOR  A
                    CALL Read_pointer        ; *n
                    CP   B
                    JR   NZ,find_new_node    ; if ( *n == NULL )
                         CALL Create_AVLnode      ; newnode = CreateAVLnode()
                         JR   C, err_insert       ; if ( newnode != NULL )
                         EX   DE,HL
                         LD   A,B
                         POP  HL
                         POP  BC                       ; BHL = n
                         LD   C,A                      ; CDE = pointer to new AVL noe
                         XOR  A
                         CALL Set_pointer              ; *n = newnode
                         RET                           ; return 0
.err_insert              POP  HL                  else
                         POP  BC                       ; return -1;
                         RET
                                             ; else
.find_new_node           LD   A,avltree_data
                         CALL Read_pointer        ; BHL = pointer to user node data
                         LD   DE,ret_cmpsym
                         PUSH DE                  ; RET address
                         LD   E,(IY+3)
                         LD   D,(IY+4)            ; get pointer to compare subroutine
                         PUSH DE
                         LD   E,(IY+0)
                         LD   D,(IY+1)
                         LD   C,(IY+2)            ; pointer to user data node to be inserted
                         RET                      ; compare current symbol node with search parameter

.ret_cmpsym              POP  HL
                         POP  BC                  ; get ptr to ptr to current node
                         PUSH BC
                         PUSH HL
                         PUSH AF                  ; preserve flags from compare routine
                         XOR  A
                         CALL Read_pointer        ; *n in BHL
                         POP  AF                  ; restore flags from compare routine
                         JR   C, sym_gt_node      ; if ( symcmp(newsym, node) <= 0 )
                         LD   DE,avltree_left          ; err = Insert(&(*n)->left)
                         JR   put_into_subtree    ; else
.sym_gt_node             LD   DE,avltree_right         ; err = Insert(&(*n)->right)
.put_into_subtree        ADD  HL,DE
                         CALL Insert
                         POP  HL
                         POP  BC                  ; get n (of this CALL level)
                         RET  C                   ; if err then return

                         CALL FixHeight           ; May have to adjust height if subtree grew
                         PUSH HL
                         PUSH BC                  ; preserve n
                         XOR  A
                         CALL Read_pointer        ; get *n
                         CALL Difference          ; get difference between subtree heights in A
                         LD   B,2
                         CALL Compare             ; if ( Difference(*n) > 1 )
                         JR   NZ, check_right_sbt ;    insertion caused left subtree to be too high
                              POP  BC
                              POP  HL
                              LD   C,1
                              CALL BalanceLeft    ;    BalanceLeft(n,1)
                              CP   A
                              RET
.check_right_sbt              LD   B,-1           ; else
                              CALL Compare        ;     if ( Difference(*n) < -1 )
                              POP  BC
                              POP  HL
                              RET  Z
                              LD   C,1
                              CALL BalanceRight   ;        BalanceRight(n,1)
                              CP   A
                    RET


; **************************************************************************************************
;
;    Create avltree node, initialize avltree information and
;    link node of user data into avltree node.
;
;    IN: None
;   OUT: BHL = extended pointer to allocated & intialized AVL node, otherwise NULL if no room.
;        Fc = 1, no room
;        Fc = 0, allocated & intialized.
;
; Registers changed after return:
;
;    ......../IXIY  same
;    AFBCDEHL/....  different
;
.Create_AVLnode     CALL Alloc_AVLnode            ; avlnode = malloc(SIZEOF_avltree)
                    RET  C                        ; if ( avlnode != NULL )
                    LD   C,0
                    LD   D,C
                    LD   E,C
                    LD   A, avltree_height
                    CALL Set_Byte                      ; avlnode->height = 0
                    LD   A, avltree_left
                    CALL Set_pointer                   ; avlnode->left = NULL
                    LD   A, avltree_right
                    CALL Set_pointer                   ; avlnode->right = NULL
                    LD   C,(IY+2)
                    LD   D,(IY+1)
                    LD   E,(IY+0)                      ; userdata
                    LD   A, avltree_data
                    CALL Set_pointer                   ; avlnode->data = userdata
                    CP   A
                    RET                           ; return avlnode


; **************************************************************************************************
;
;    Allocate memory for avltree node
;
;    IN: None
;   OUT: BHL = extended pointer to allocated memory, otherwise NULL if no room
;
; Registers changed after return:
;
;    ...CDE../IXIY  same
;    AFB...HL/....  different
;
.Alloc_AVLnode      LD   A, SIZEOF_avltree
                    CALL malloc
                    RET
