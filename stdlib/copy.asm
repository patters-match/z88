
     xlib copy

     lib insert
     lib read_pointer, set_pointer

     INCLUDE "avltree.def"


; ******************************************************************************
;
;    Copy (and merge) the current AVL-tree data into another AVL-tree.
;
;    Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
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
