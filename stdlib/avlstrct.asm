     xlib avlstructure

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

     include "avltree.def"
     include "stdio.def"


; ****************************************************************************
;
; Display tree structure.
;
;    in:  bhl = pointer to root of tree
;         iy  = pointer to action routine (that display contents of node data)
;
;    registers changed after return:
;         ..bcdehl/ixiy  same
;         af....../....  different
;
.avlstructure       push bc
                    push hl
                    push de
                    call_oz(gn_nln)
                    ld   de,0
                    call desctraverse        ; desctraverse( root, level)
                    pop  de
                    pop  hl
                    pop  bc
                    ret


; ****************************************************************************
;
.desctraverse       push de
                    inc  de                  ; ++level
                    inc  b
                    dec  b
                    jr   nz, node            ; if ( ptr == null)
                         call writeleaf           ; writeleaf(level)
                         pop  de
                         ret                 ; else
.node                    push bc
                         push hl
                         ld   a, avltree_right
                         call read_pointer
                         call desctraverse        ; desctraverse(ptr->right, level)
                         pop  hl
                         pop  bc
                         call writenode           ; writenode(ptr, level)
                         push bc
                         push hl
                         ld   a, avltree_left
                         call read_pointer
                         call desctraverse        ; desctraverse(ptr->left, level)
                         pop  hl
                         pop  bc
                    pop  de
                    ret


; *****************************************************************************
;
;    tabulate to current level and write leaf
;
.writeleaf          call displevel
                    ld   hl, leaf
                    call_oz(gn_sop)
                    ret
.leaf               defm "<>", 13, 10, 0


; *****************************************************************************
;
;    tabulate to current level of node and write user data
;
.writenode          push bc
                    push hl
                    call displevel
                    ld   a, avltree_data
                    call read_pointer
                    push de
                    push iy
                    ld   iy, writenode_RET   ; service(ptr->data)
                    ex   (sp),iy
                    jp   (iy)
.writenode_RET      pop  de
                    pop  hl
                    pop  bc
                    ret


; *****************************************************************************
;
;    tabulate to current level of node
;
.displevel          push de
.displevel_loop     ld   a, 9
                    call_oz(os_out)
                    dec  de
                    ld   a,d
                    or   e
                    jr   nz, displevel_loop
                    pop  de
                    ret
