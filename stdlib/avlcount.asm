
     xlib avlcount

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
;    Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
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
