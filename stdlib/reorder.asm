
     xlib reorder

     lib malloc, mfree, transfer
     lib set_pointer, read_pointer


; ******************************************************************************
;
;    Re-order the current AVL-tree (move with new order).
;
;    Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
;    IN:  BHL = *p, pointer to root of AVL-tree.
;         IY  = symcmp, pointer to compare routine (that perform comparison on
;               the to-be-copied-node data and the alien node data in the
;               destination AVL-tree)
;
;    OUT: CDE = pointer to re-ordered AVL-tree.
;
;    The compare routine is called for each node in the source AVL-tree. On entry
;    BHL = pointer to current node data in new AVL-tree, CDE = pointer to
;    current node-data to be inserted into the new AVL-tree. The subroutine
;    must return Fz = 1 if new data node = current data node, otherwise Fc = 1 if
;    new node > current node, otherwise Fc = 0. IY must not be altered by the
;    Compare subroutine.
;
;    Registers changed after return:
;    ......../IXIY  same
;    AFBCDEHL/....  different
;
.reorder            push bc
                    push hl
                    ld   a, 6                     ; allocate room for 2 pointers
                    call malloc
                    jr   c, exit_reorder          ; srcroot = malloc(6)
                         pop  de
                         pop  af
                         ld   c,a
                         xor  a
                         call set_pointer         ; *srcroot = p
                         ld   c,0
                         ld   de,0
                         ld   a, 3
                         call set_pointer         ; *newroot = NULL
                         ld   c,b
                         push hl
                         pop  de                  ; newroot = srcroot + 3
                         inc  de
                         inc  de
                         inc  de
                         call transfer            ; transfer( srcroot, dstroot, symcmp)
                         ex   de,hl
                         ld   a,b
                         ld   b,c
                         ld   c,a                 ; BHL = dstroot, CDE = srcroot
                         xor  a
                         call read_pointer        ; BHL = *dstroot
                         ex   de,hl
                         ld   a,b
                         ld   b,c
                         ld   c,a                 ; BHL = srcroot, CDE = *dstroot
                         call mfree               ; free(srcroot)
                         ret                      ; return *dstroot, pointer to reordered tree
.exit_reorder       pop  hl
                    pop  bc
                    ld   c,b
                    ld   d,h
                    ld   e,l                      ; return CDE = BHL (no change)
                    ret
