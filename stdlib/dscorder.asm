     xlib descorder

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

     lib read_pointer

     INCLUDE "avltree.def"


; ******************************************************************************
;
;    Traverse the AVL-tree in descending order, i.e. the largest element
;    (rightmost node) first, down to the smallest (leftmost) node.
;
;    IN:  BHL = pointer to root of AVL-tree
;         IY  = pointer to service routine (that perform actions on the node data)
;
;    OUT: None.
;
;    The service routine is called for each node in the AVL-tree. All registers
;    except IY may be altered on exit of the service routine. BHL = pointer to data
;    (subrecord) of AVL-tree node on entry of the service-routine.
;
;    Registers changed after return:
;    ...CDE../IXIY  same
;    AFB???HL/??..  different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ----------------------------------------------------------------------
;
.descorder          inc  b
                    dec  b                        ; if ( n == NULL )
                    ret  z                             ; return
                         push bc                  ; else
                         push hl
                         ld   a, avltree_right
                         call read_pointer
                         call descorder                 ; descorder(n->right)
                         pop  hl
                         pop  bc
                         push bc
                         push hl
                         ld   a,avltree_data
                         call read_pointer
                         push iy
                         ld   iy, RET_service
                         ex   (sp),iy
                         jp   (iy)                     ; service(n->data)
.RET_service             pop  hl
                         pop  bc
                         push bc
                         push hl
                         ld   a,avltree_left
                         call read_pointer
                         call descorder                ; descorder(n->left)
                         pop  hl
                         pop  bc
                    ret
