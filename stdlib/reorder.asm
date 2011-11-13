     xlib reorder

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

     lib malloc, mfree, transfer
     lib set_pointer, read_pointer


; ******************************************************************************
;
;    Re-order the current AVL-tree (move with new order).
;
;    IN:  BHL = *p, pointer to root of AVL-tree.
;         IY  = symcmp, pointer to compare routine (that perform comparison on
;               the to-be-copied-node data and the alien node data in the
;               destination AVL-tree)
;
;    OUT: CDE = pointer to re-ordered AVL-tree.
;
;    The compare routine is called for each node in the source AVL-tree. On entry
;    BHL = pointer to current node data in new AVL-tree, CDE = pointer to
;    current node-data to be inserted into the new AVL-tree. The subroutine
;    must return Fz = 1 if new data node = current data node, otherwise Fc = 1 if
;    new node > current node, otherwise Fc = 0. IY must not be altered by the
;    Compare subroutine.
;
;    Registers changed after return:
;    ......../IXIY  same
;    AFBCDEHL/....  different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ----------------------------------------------------------------------
;
.reorder            push bc
                    push hl
                    ld   a, 6                     ; allocate room for 2 pointers
                    call malloc
                    jr   c, exit_reorder          ; srcroot = malloc(6)
                         pop  de
                         pop  af
                         ld   c,a
                         xor  a
                         call set_pointer         ; *srcroot = p
                         ld   c,0
                         ld   de,0
                         ld   a, 3
                         call set_pointer         ; *newroot = NULL
                         ld   c,b
                         push hl
                         pop  de                  ; newroot = srcroot + 3
                         inc  de
                         inc  de
                         inc  de
                         call transfer            ; transfer( srcroot, dstroot, symcmp)
                         ex   de,hl
                         ld   a,b
                         ld   b,c
                         ld   c,a                 ; BHL = dstroot, CDE = srcroot
                         xor  a
                         call read_pointer        ; BHL = *dstroot
                         ex   de,hl
                         ld   a,b
                         ld   b,c
                         ld   c,a                 ; BHL = srcroot, CDE = *dstroot
                         call mfree               ; free(srcroot)
                         ret                      ; return *dstroot, pointer to reordered tree
.exit_reorder       pop  hl
                    pop  bc
                    ld   c,b
                    ld   d,h
                    ld   e,l                      ; return CDE = BHL (no change)
                    ret
