
     xlib ascorder

     lib read_pointer

     INCLUDE "avltree.def"


; ******************************************************************************
;
;    Traverse the AVL-tree in ascending order, i.e. the smallest (leftmost) first,
;    up to the largest element (rightmost node).
;    This type of binary tre traversal is also known as inorder.
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
;    ......../IXIY  same
;    AFBCDEHL/....  different
;
;    Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
.ascorder           inc  b
                    dec  b                        ; if ( n == NULL )
                    ret  z                             ; return
                         push bc                  ; else
                         push hl
                         ld   a, avltree_left
                         call read_pointer
                         call ascorder                 ; ascorder(n->left)
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
                         ld   a,avltree_right
                         call read_pointer
                         call ascorder                 ; ascorder(n->right)
                         pop  hl
                         pop  bc
                    ret
