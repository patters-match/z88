     xlib transfer

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

     lib insert, mfree
     lib read_pointer, set_pointer

     INCLUDE "avltree.def"


; ******************************************************************************
;
;    Transfer (and merge) the current AVL-tree data into another AVL-tree.
;
;    IN:  BHL = **p, pointer to pointer to root of source AVL-tree
;         CDE = **newroot, pointer to pointer to root of destination AVL-tree
;         IY  = symcmp, pointer to compare routine (that perform comparison on
;               the to-be-moved-node data and the alien node data in the
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
;    Registers changed after return:
;    ..BCDEHL/IXIY  same
;    AF....../....  different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ----------------------------------------------------------------------
;
.transfer           push de                       ; preserve newroot
                    push bc
                    push hl                       ; preserve p
                    xor  a
                    call read_pointer             ; get *p
                    inc  b
                    dec  b
                    jr   z, exit_transfer         ; if (*p != null)
                         push bc
                         push hl                       ; preserve *p
                         ld   a, avltree_left
                         add  a,l
                         ld   l,a
                         jr   nc, transfer_leftsubtree
                         inc  h
.transfer_leftsubtree    call transfer                 ; transfer( &(*p)->left, newroot, symcmp)
                         pop  hl
                         pop  bc
                         push bc
                         push hl
                         ld   a, avltree_right
                         add  a,l
                         ld   l,a
                         jr   nc, transfer_rightsubtree
                         inc  h
.transfer_rightsubtree   call transfer                 ; transfer( &(*p)->right, newroot, symcmp)

                         pop  hl
                         pop  bc
                         push bc
                         push hl                       ; preserve *p
                         ld   a, avltree_data
                         call read_pointer             ; BHL = (*p)->data
                         push ix                       ; preserve original IX
                         ld   ix, -5
                         add  ix,sp
                         ld   sp,ix
                         ld   (ix+0),l
                         ld   (ix+1),h
                         ld   (ix+2),b                 ; (*p)->data parameter
                         push ix
                         push iy
                         pop  hl
                         ld   (ix+3),l
                         ld   (ix+4),h                 ; pointer to compare routine
                         ex   (sp),iy                  ; (SP) = compare routine, IY = base of parameters
                         ld   b,c
                         ex   de,hl                    ; BHL = newroot (pointer to pointer)
                         call insert                   ; insert( newroot, (*p)->data, symcmp)
                         pop  iy                       ; pointer to compare routine restored
                         ld   hl,5
                         add  hl,sp
                         ld   sp,hl                    ; remove parameter block
                         pop  ix                       ; restore original IX
                         pop  hl
                         pop  bc                       ; restore *p
                         call mfree                    ; free(*p), release AVL anchor node
                         pop  hl
                         pop  bc                       ; p
                         push bc
                         xor  a
                         ld   c,a
                         ld   d,a
                         ld   e,a
                         call set_pointer              ; *p = NULL
                         pop  bc
                         pop  de                       ; newroot pointer restored, p pointer unchanged...
                         ret

.exit_transfer      pop  hl
                    pop  bc
                    pop  de
                    ret
