     XLIB RotateRight

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

     LIB Read_pointer, Set_pointer

     INCLUDE "avltree.def"


; ************************************************************************************
;
;    INTERNAL AVLTREE ROUTINE
;
;    Rotate subtree rightwards at node in memory at pointer to pointer in BHL = **x.
;
;    Register affected on return:
;         ..BC..HL/IXIY
;         AF..DE../.... af
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ----------------------------------------------------------------------
;
.RotateRight        PUSH BC
                    LD   C,B
                    LD   D,H
                    LD   E,L
                    XOR  A                        ;
                    CALL Read_pointer             ; *x
                    XOR  A
                    CP   B
                    JR   Z, exit_rotateright      ; if ( *x != NULL )
                         LD   A,avltree_left
                         CALL Read_pointer             ; y = (*x)->left
                         XOR  A
                         CP   B
                         JR   Z, exit_rotateright      ; if ( y != NULL )
                              PUSH BC
                              PUSH DE                       ; {preserve **x in CDE}
                              PUSH BC
                              PUSH HL                       ; {preserve y in BHL}
                              LD   A,avltree_right
                              CALL Read_pointer             ; y->right
                              LD   A,B
                              LD   B,C
                              LD   C,A
                              EX   DE,HL                    ; {BHL = **x, CDE = y->right}
                              XOR  A
                              CALL Read_pointer             ; {BHL = *x}
                              LD   A, avltree_left
                              CALL Set_pointer              ; (*x)->left = y->right
                              LD   A,B                      ; {AHL = *x}
                              EX   DE,HL
                              POP  HL
                              POP  BC
                              LD   C,A                      ; {BHL = y, CDE = *x}
                              LD   A, avltree_right
                              CALL Set_pointer              ; y->right = *x
                              LD   A,B
                              EX   DE,HL
                              POP  HL
                              POP  BC
                              LD   B,C                      ; {BHL = **x}
                              LD   C,A                      ; {CDE = y}
                              XOR  A
                              CALL Set_pointer              ; *x = y
                              POP  BC
                              RET
.exit_rotateright   POP  BC
                    EX   DE,HL                    ; {restore **x}
                    RET
