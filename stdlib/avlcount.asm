     xlib avlcount

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

     lib read_pointer

     INCLUDE "avltree.def"


; ******************************************************************************
;
;    Count the number of nodes (elements) in the AVL-tree
;
;    IN:  BHL = pointer to root of AVL-tree
;    OUT: DE = number of items in the AVL-tree
;
;    Registers changed after return:
;    ..BC..HL/IXIY  same
;    AF..DE../....  different
;
; 
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ----------------------------------------------------------------------
;
.avlcount           ld   de,0
.traverse_avltree   inc  b
                    dec  b
                    ret  z              ; NULL - branch ended...
                         inc  de                  ; count node...
                         push bc
                         push hl
                         ld   a, avltree_left
                         call read_pointer
                         call traverse_avltree    ; count left subtree
                         pop  hl
                         pop  bc
                         push bc
                         push hl
                         ld   a,avltree_right
                         call read_pointer
                         call traverse_avltree
                         pop  hl
                         pop  bc
                    ret
