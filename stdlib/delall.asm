     xlib delete_all

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

     lib mfree
     lib read_pointer

     INCLUDE "avltree.def"


; ******************************************************************************
;
;    Delete the AVL-tree (and it's data nodes).
;
;    IN:  BHL = pointer to root of AVL-tree
;         IY  = pointer to delete routine (that perform actions on the node data)
;
;    OUT: None.
;
;    The service routine is called for each node in the AVL-tree. All registers
;    except IY may be altered on exit of the service routine. BHL = pointer to data
;    (subrecord) of AVL-tree node on entry of the service-routine.
;
;    Registers changed after return:
;    ......../IXIY  same
;    AFBCDEHL/....  different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ----------------------------------------------------------------------
;
.delete_all         inc  b
                    dec  b                        ; if ( n == NULL )
                    ret  z                             ; return
                         push bc                  ; else
                         push hl
                         ld   a, avltree_left
                         call read_pointer
                         call delete_all               ; delete_all(n->left)
                         pop  hl
                         pop  bc
                         push bc
                         push hl
                         ld   a,avltree_right
                         call read_pointer
                         call delete_all               ; delete_all(n->right)
                         pop  hl
                         pop  bc
                         push bc
                         push hl
                         ld   a,avltree_data
                         call read_pointer
                         push iy
                         ld   iy, RET_service
                         ex   (sp),iy
                         jp   (iy)                     ; del_subrecord(n->data)
.RET_service
                         pop  hl
                         pop  bc
                         call mfree                    ; mfree(n)
                    ret
