
     xlib delete_all

     lib mfree
     lib read_pointer

     INCLUDE "avltree.def"


; ******************************************************************************
;
;    Delete the AVL-tree (and it's data nodes).
;
;    Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
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
