
     XLIB Difference

     LIB Read_pointer, Read_byte

     INCLUDE "avltree.def"


; **************************************************************************************
;
;    INTERNAL AVLTREE ROUTINE
;
;    Return the difference between the heights of the left and right subtree of node n.
;
;    Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
;         IN:  BHL = pointer to node n
;         OUT: A = difference of subtree heights  (2. complement notation)
;
;         Local variables:    D = leftheight
;                             E = rightheight
;
;    Register affected on return:
;         ..BC..HL/IXIY
;         AF..DE../.... af
;
.Difference         PUSH BC
                    PUSH HL
                    XOR  A                        ; A = 0
                    CP   B
                    JR   Z, exit_difference       ; if ( n != NULL )
                         PUSH BC
                         PUSH HL                       ; preserve n
                         LD   A,avltree_left
                         CALL Read_pointer
                         XOR  A
                         CP   B
.diff_tst_leftsubtree    JR   NZ, diff_get_leftheight  ; if ( n->left == NULL )
                              LD   D,-1                     ;    leftheight = -1
                              JR   diff_tst_rightsubtree    ; else
.diff_get_leftheight          LD   A,avltree_height
                              CALL Read_byte                ; leftheight = n->left->height , heigth of left subtree
                              LD   D,A

.diff_tst_rightsubtree   POP  HL
                         POP  BC
                         LD   A,avltree_right
                         CALL Read_pointer
                         XOR  A
                         CP   B
                         JR   NZ, diff_get_rightheight ; if ( n->right == NULL )
                              LD   E,-1                ;    rightheight = -1
                              JR   calc_difference     ; else
.diff_get_rightheight         LD   A,avltree_height
                              CALL Read_byte           ;    rightheight = n->right->height , heigth of right subtree
                              LD   E,A

.calc_difference    LD   A,D
                    SUB  E                   ; return leftheight - rightheight
.exit_difference    POP  HL
                    POP  BC
                    RET
