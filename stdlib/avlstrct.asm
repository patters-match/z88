
     xlib avlstructure

     lib read_pointer

     include "avltree.def"
     if Z88
          include ":*//stdio.def"
     else
          include "stdio.def"
     endif


; ****************************************************************************
;
;    display tree structure.
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
