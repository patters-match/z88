     xlib copy

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

     lib insert
     lib read_pointer, set_pointer

     INCLUDE "avltree.def"


; ******************************************************************************
;
;    Copy (and merge) the current AVL-tree data into another AVL-tree.
;
;    IN:  BHL = *p, pointer to root of source AVL-tree
;         CDE = **newroot, pointer to pointer to root of destination AVL-tree
;         IX  = symcreate, pointer to routine that creates a copy of a data node
;         IY  = symcmp, pointer to compare routine (that perform comparison on
;               the to-be-copied-node data and the alien node data in the
;               destination AVL-tree)
;
;    OUT: None.
;
;    The compare routine is called for each node in the source AVL-tree. On entry
;    BHL = pointer to current node data in destination AVL-tree, CDE = pointer to
;    current node-data to be inserted into the destination AVL-tree. The subroutine
;    must return Fz = 1 if new data node = current data node, otherwise Fc = 1 if
;    new node > current node, otherwise Fc = 0. IY must not be altered by the
;    Compare subroutine.
;
;    The create routine is called for each data node in the source AVL-tree. On entry
;    BHL points to the current data node. The routine is responible for creating a
;    copy of the data and return a pointer to it in BHL. IX must not be altered by
;    the create routine.
;
;    Registers changed after return:
;    ..BCDE../IXIY  same
;    AF....HL/....  different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ----------------------------------------------------------------------
;
.copy               inc  b
                    dec  b
                    ret  z                        ; if (p != NULL)
                         push bc
                         push hl                       ; preserve p
                         ld   a, avltree_left
                         call read_pointer
                         call copy                     ; copy( p->left, newroot, symcmp, symcreate)
                         pop  hl
                         pop  bc
                         push bc
                         push hl
                         ld   a, avltree_right
                         call read_pointer
                         call copy                     ; copy( p->right, newroot, symcmp, symcreate)
                         pop  hl
                         pop  bc
                         push bc
                         push de                       ; preserve newroot
                         ld   a, avltree_data
                         call read_pointer             ; BHL = p->data
                         push ix
                         ld   ix, create_RETurn
                         ex   (sp),ix
                         jp   (ix)                     ; newsym = symcreate(p->data)

.create_RETurn           push ix                       ; preserve original IX
                         ld   ix, -5
                         add  ix,sp
                         ld   sp,ix
                         ld   (ix+0),l
                         ld   (ix+1),h
                         ld   (ix+2),b                 ; newsym parameter
                         push ix
                         push iy
                         pop  hl
                         ld   (ix+3),l
                         ld   (ix+4),h                 ; pointer to compare routine
                         ex   (sp),iy                  ; (SP) = compare routine, IY = base of parameters
                         ld   l,(ix+7)
                         ld   h,(ix+8)
                         ld   b,(ix+9)                 ; BHL = newroot (previously push'ed on stack)
                         call insert                   ; insert( newroot, (*p)->data, symcmp)
                         pop  iy                       ; restore pointer to compare routine
                         ld   hl,5
                         add  hl,sp
                         ld   sp,hl                    ; remove parameter block
                         pop  ix                       ; restore pointer to create routine
                         pop  de
                         pop  bc                       ; restore newroot
                         ret
