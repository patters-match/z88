     XLIB Delete

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
     LIB Read_pointer, Set_pointer
     LIB RotateLeft, RotateRight
     LIB BalanceLeft, BalanceRight
     LIB Difference, FixHeight
     LIB Mfree
     LIB Compare

     INCLUDE "avltree.def"


; **************************************************************************************************
;
;    Delete the node 'closest' in value to the current node (the last smallest node in the right
;    subtree of the current node).
;
;    IN:  BHL  = **n (pointer to pointer to node)
;         IX   = pointer to store pointer of avlnode data
;    OUT: (IX) = pointer to user data node (record) previously linked to deleted avltree node.
;
;    Register affected on return:
;         ..B...HL/IXIY  same
;         AF.CDE../....  different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ----------------------------------------------------------------------
;
.deletemin               PUSH BC
                         PUSH HL                            ; preserve n
                         XOR  A
                         CALL Read_pointer                  ; *n
                         PUSH BC
                         PUSH HL
                         LD   A, avltree_left
                         CALL Read_pointer                  ; (*n)->left
                         INC  B
                         DEC  B
                         JR   Z, found_avlnode              ; if ( (*n)->left != NULL )
                              POP  HL
                              POP  BC
                              LD   DE, avltree_left
                              ADD  HL,DE
                              CALL Deletemin                     ; Deletemin(&(*n)->left)
                              POP  HL
                              POP  BC                            ; n
                              JR   rebalance_deletemin      ; else

.found_avlnode                POP  HL
                              POP  BC                            ; *n
                              PUSH BC
                              PUSH HL
                              LD   A, avltree_data
                              CALL Read_pointer
                              LD   (IX+0),L
                              LD   (IX+1),H
                              LD   (IX+3),B                      ; datarecord = (*n)->data
                              POP  HL
                              POP  BC                            ; BHL = *n
                              PUSH BC
                              PUSH HL
                              LD   A, avltree_right
                              CALL Read_pointer                  ; BHL = (*n)->right
                              LD   A,B
                              EX   DE,HL
                              POP  HL
                              POP  BC                            ; temp (BHL) = *n
                              LD   C,A                           ; CDE = (*n)->right
                              CALL mfree                         ; free(temp)
                              LD   A,C
                              POP  HL
                              POP  BC                            ; BHL = n
                              LD   C,A                           ; CDE = (*n)->right
                              XOR  A
                              CALL Set_pointer                   ; *n = CDE

.rebalance_deletemin     PUSH BC
                         PUSH HL
                         XOR  A
                         CALL Read_pointer        ; *n
                         INC  B
                         DEC  B
                         POP  HL
                         POP  BC
                         RET  Z                   ; if ( *n != NULL )
                              CALL FixHeight           ; May have to adjust height if subtree grew
                              PUSH HL
                              PUSH BC                  ; preserve n
                              XOR  A
                              CALL Read_pointer        ; get *n
                              CALL Difference          ; get difference between subtree heights in A
                              LD   B,2
                              CALL Compare             ; if ( Difference(*n) > 1 )
                              JR   NZ, check_right_sbt1;    deletion caused left subtree to be too high
                                   POP  BC
                                   POP  HL
                                   LD   C,-1
                                   CALL BalanceLeft    ;    BalanceLeft(n, -1)
                                   RET
.check_right_sbt1                  LD   B,-1           ; else
                                   CALL Compare        ;     if ( Difference(*n) < -1 )
                                   POP  BC
                                   POP  HL
                                   RET  Z
                                   LD   C,-1
                                   CALL BalanceRight   ;       BalanceRight(n, -1)
                         RET


; **************************************************************************************************
;
;    Delete (node) data in avltree.
;
;         IN:  BHL = pointer to pointer to current avltree node
;              CDE = search key (user defined)
;              IX  = pointer to compare routine
;              IY  = pointer to delete routine (avlnode->data record)
;
;        OUT:  None.
;
;    The compare subroutine must return Fz = 1 if search key = current avltree node,
;    otherwise Fc = 1 if search key > current avltree node, else Fc = 0.
;    CDE, IX & IY must not be altered by the Compare subroutine.
;    The following registers are setup on entry of the compare routine (IX):
;         BHL = pointer to current AVL-tree subrecord
;         CDE = user defined search key
;    The following registers are setup on entry of the delete routine (IY):
;         BHL = pointer to current AVL-tree (sub)record:
;
;    Register affected on return:
;         ..B...HL/..IY  same
;         AF.CDE../IX..  different
;
.Delete             PUSH BC
                    PUSH HL                       ; preserve n (pointer to pointer)
                    XOR  A
                    CALL Read_pointer
                    INC  B
                    DEC  B
                    JR   NZ, find_node            ; IF ( *n == NULL )
                         POP  HL
                         POP  BC                       ; return
                         RET                      ; ELSE

.find_node               PUSH BC
                         PUSH HL                       ; preserve *n
                         LD   A, avltree_data
                         CALL Read_pointer             ; BHL = (*n)->data
                         PUSH IX
                         LD   IX, RET_cmp
                         EX   (SP),IX                  ; prepare RETurn from compare routine
                         JP   (IX)                     ; compare...
.RET_cmp                 POP  HL
                         POP  BC                       ; *n
                         PUSH BC
                         PUSH HL
                         JR   Z, node_found
                         JR   C, key_larger            ; IF ( compare(key,(*n)->data) < 0 )
                              LD   A, avltree_left          ; Delete(&(*n)->left )
                              JR   calc_pointer        ; ELSE

.key_larger                   LD   A, avltree_right         ; IF ( compare(key,(*n)->data) > 0 )
.calc_pointer                 ADD  A,L
                              LD   L,A
                              JR   NC, search_newnode
                              INC  H                             ; BHL = &(*n)->left/right, CDE = search key
.search_newnode               CALL Delete                        ; Delete(&(*n)->right)
                              POP  AF                            ;
                              POP  AF                            ; ignore old *n
                              POP  HL
                              POP  BC                            ; BHL = n
                              JR   rebalance_delete         ; ELSE
                                                                 ; node to be deleted is found
.node_found                        LD   A, avltree_left          ; *n preserved on stack...
                                   CALL Read_pointer             ; BHL = (*n)->left
                                   INC  B
                                   DEC  B
                                   JR   Z, check_rightsubtree    ; IF ( (*n)->left != NULL )
                                                                      ; node has at least a left subtree...
                                        POP  HL
                                        POP  BC                       ; *n
                                        PUSH BC
                                        PUSH HL
                                        LD   A, avltree_right
                                        CALL Read_pointer
                                        INC  B
                                        DEC  B
                                        JR   Z, no_rightsubtree       ; IF ( (*n)->right != NULL )
                                                                           ; node has both left & right subtrees
                                             POP  HL
                                             POP  BC
                                             PUSH BC
                                             PUSH HL                       ; *n
                                             LD   DE, avltree_right
                                             ADD  HL,DE
                                             LD   IX,-4
                                             ADD  IX,SP
                                             LD   SP,IX                    ; IX = datarecord pointer
                                             CALL Deletemin                ; Deletemin( &(*n)->right, datarecord)
                                             POP  DE
                                             POP  AF                       ; user data record pointer from (SP)
                                             POP  HL
                                             POP  BC                       ; BHL = *n
                                             LD   C,A                      ; CDE = *datarecord
                                             CALL free_userdata            ; free((*n)->data), release current data (sub)record
                                             LD   A, avltree_data
                                             CALL Set_pointer              ; (*n)->data = CDE, assign new data record pointer.
                                             POP  HL
                                             POP  BC                       ; n
                                             JR   rebalance_delete    ; ELSE

.no_rightsubtree                             LD   A, avltree_left          ; *n = (*n)->left, node has only left subtree
                                             JR   get_newsubtree

                                                                 ; ELSE
.check_rightsubtree                     POP  HL
                                        POP  BC                       ; *n
                                        PUSH BC
                                        PUSH HL
                                        LD   A, avltree_right
                                        CALL Read_pointer
                                        INC  B
                                        DEC  B
                                        JR   Z, no_subtrees           ; IF ( (*n)->right != NULL ), node has only right subtree
                                             LD   A, avltree_right         ; *n = (*n)->right
                                             JR   get_newsubtree      ; ELSE

.no_subtrees                                 EX   DE,HL                    ; *n = NULL, root deleted.
                                             POP  HL
                                             POP  BC                       ; BHL = temp, CDE = *n
                                             LD   C,0
                                             JR   delete_curnode

.get_newsubtree                         POP  HL
                                        POP  BC
                                        PUSH BC
                                        PUSH HL                  ; *n
                                        CALL Read_pointer
                                        LD   A,B
                                        EX   DE,HL
                                        POP  HL
                                        POP  BC                  ; BHL = *n
                                        LD   C,A                 ; CDE = (*n)->subtree (left or right)

.delete_curnode                         CALL free_userdata       ; free(temp->data)
                                        CALL mfree               ; free(temp)
                                        POP  HL
                                        LD   A,C
                                        POP  BC                  ; n
                                        LD   C,A                 ; CDE = (*n)->left,right or NULL
                                        XOR  A
                                        CALL Set_pointer         ; *n = CDE
.rebalance_delete        PUSH BC
                         PUSH HL
                         XOR  A
                         CALL Read_pointer             ; get *n...
                         INC  B
                         DEC  B
                         POP  HL
                         POP  BC
                         RET  Z                        ; if ( *n != NULL )
                              CALL FixHeight                ; fixheight(n), May have to adjust height if subtree grew
                              PUSH HL
                              PUSH BC                       ; preserve n
                              XOR  A
                              CALL Read_pointer             ; get *n
                              CALL Difference               ; get difference between subtree heights in A
                              LD   B,2
                              CALL Compare                  ; if ( Difference(*n) > 1 )
                              JR   NZ, check_right_sbt2          ; deletion caused left subtree to be too high
                                   POP  BC
                                   POP  HL
                                   LD   C,-1
                                   CALL BalanceLeft              ; BalanceLeft(n,-1)
                                   RET
.check_right_sbt2                  LD   B,-1                ; else
                                   CALL Compare                  ; if ( Difference(*n) < -1 )
                                   POP  BC
                                   POP  HL
                                   RET  Z
                                   LD   C,-1
                                   CALL BalanceRight                  ; BalanceRight(n,-1)
                    RET


; **************************************************************************************************
;
;    Release User Data Record, referenced by avlnode->data.
;
;    Register affected on return:
;         AFBCDEHL/..IY  same
;         ......../IX..  different
;
.free_userdata      PUSH AF
                    PUSH BC
                    PUSH DE
                    PUSH HL                  ; preserve *n
                    LD   A, avltree_data
                    CALL Read_pointer        ; (*n)->data, point at user data record
                    PUSH IY
                    LD   IY, RET_delete
                    EX   (SP),IY
                    JP   (IY)                ; execute delete routine, free((*n)->data)
.RET_delete         POP  HL
                    POP  DE
                    POP  BC
                    POP  AF
                    RET
