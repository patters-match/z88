
     XLIB FindMin

     LIB Read_pointer

     INCLUDE "avltree.def"


; **************************************************************************************************
;
;    Find smallest (node) data in avltree (the leftmost node of the AVL-tree).
;
;    Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
;         IN:  BHL = pointer to root of avltree tree
;
;        OUT:  BHL = pointer to found data (sub)record in avltree.
;              BHL = NULL and Fc = 1 if the AVL-tree is empty.
;
;    Register affected on return:
;         ...CDE../IXIY  same
;         AFB...HL/....  different
;
.FindMin            INC  B
                    DEC  B
                    JR   NZ, find_node            ; IF ( n == NULL )
                         SCF                           ; return NULL
                         RET                      ; ELSE
.find_node               PUSH BC
                         PUSH HL
                         LD   A, avltree_left
                         CALL Read_pointer
                         INC  B
                         DEC  B
                         JR   Z, found_min             ; if (n->left != NULL)
                              POP  AF
                              POP  AF
                              CALL find_node                ; return FindMin(n->left)
                              RET                      ; else
.found_min                    POP  HL
                              POP  BC                       ; return n->data
                              LD   A, avltree_data
                              CALL Read_pointer
                              CP   A
                              RET
