     XLIB FindMax

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

     LIB Read_pointer

     INCLUDE "avltree.def"



; **************************************************************************************************
;
;    Find largest node) data in avltree (the rightmost node of the AVL-tree).
;
;         IN:  BHL = pointer to root of avltree tree
;
;        OUT:  BHL = pointer to found data (sub)record in avltree.
;              BHL = NULL and Fc = 1 if the AVL-tree is empty.
;
;    Register affected on return:
;         ...CDE../IXIY  same
;         AFB...HL/....  different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ----------------------------------------------------------------------
;
.FindMax            INC  B
                    DEC  B
                    JR   NZ, find_node            ; IF ( n == NULL )
                         SCF                           ; return NULL
                         RET                      ; ELSE
.find_node               PUSH BC
                         PUSH HL
                         LD   A, avltree_right
                         CALL Read_pointer
                         INC  B
                         DEC  B
                         JR   Z, found_max             ; if (n->right != NULL)
                              POP  AF
                              POP  AF
                              CALL find_node                ; return FindMin(n->right)
                              RET                      ; else
.found_max                    POP  HL
                              POP  BC                       ; return n->data
                              LD   A, avltree_data
                              CALL Read_pointer
                              CP   A
                              RET
