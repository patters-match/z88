     XLIB Find

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

     LIB Read_pointer

     INCLUDE "avltree.def"


; **************************************************************************************************
;
;    Find (node) data in avltree.
;
;         IN:  BHL = pointer to root of avltree tree
;              CDE = search key (user defined)
;              IY  = pointer to compare routine
;
;        OUT:  Fc = 0, BHL = pointer to found data (sub)record in avltree.
;              Fc = 1, BHL = NULL, information not found.
;
;    The compare subroutine must return Fz = 1 if search key = current avltree (sub)record
;    otherwise Fz = 0 and Fc = 1 if search key > current avltree node, else Fc = 0.
;    IY and the search key must not be altered by the Compare subroutine.
;    BHL points at current node of (sub)record on entry of the compare routine.
;
;    Register affected on return:
;         ...CDE../IXIY  same
;         AFB...HL/....  different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ----------------------------------------------------------------------
;
.Find               INC  B
                    DEC  B
                    JR   NZ, find_node            ; IF ( *n == NULL )
                         SCF                           ; return NULL
                         RET                      ; ELSE
.find_node               PUSH BC
                         PUSH HL                       ; preserve *n
                         LD   A, avltree_data
                         CALL Read_pointer             ; BHL = (*n)->data
                         PUSH IY
                         LD   IY, RET_cmp
                         EX   (SP),IY                  ; prepare RETurn from compare routine
                         JP   (IY)                     ; compare...
.RET_cmp                 POP  HL
                         POP  BC                       ; *n
                         JR   Z, node_found
                         JR   C, key_larger            ; IF ( compare(key,(*n)->data) < 0 )
                              LD   A, avltree_left          ; return Find((*n)->left )
                              JR   search_node         ; ELSE
.key_larger                   LD   A, avltree_right         ; IF ( compare(key,(*n)->data) > 0 )
.search_node                  PUSH BC
                              PUSH HL
                              CALL Read_pointer
                              CALL Find                          ; return Find((*n)->right)
                              INC  SP                            ; (in BHL)
                              INC  SP
                              INC  SP
                              INC  SP                            ; remove local pointer and get return address
                              RET                           ; ELSE    /* node to be deleted is found */
.node_found                        LD   A, avltree_data
                                   CALL Read_pointer             ; return (*n)->data
                                   CP   A                        ; signal found (Fc = 0)
                                   RET
