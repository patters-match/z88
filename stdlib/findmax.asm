
     XLIB FindMax

     LIB Read_pointer

     INCLUDE "avltree.def"



; **************************************************************************************************
;
;    Find largest node) data in avltree (the rightmost node of the AVL-tree).
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
.FindMax            INC  B
                    DEC  B
                    JR   NZ, find_node            ; IF ( n == NULL )
                         SCF                           ; return NULL
                         RET                      ; ELSE
.find_node               PUSH BC
                         PUSH HL
                         LD   A, avltree_right
                         CALL Read_pointer
                         INC  B
                         DEC  B
                         JR   Z, found_max             ; if (n->right != NULL)
                              POP  AF
                              POP  AF
                              CALL find_node                ; return FindMin(n->right)
                              RET                      ; else
.found_max                    POP  HL
                              POP  BC                       ; return n->data
                              LD   A, avltree_data
                              CALL Read_pointer
                              CP   A
                              RET
