
	XLIB RotateLeft

	LIB Read_pointer, Set_pointer

     INCLUDE "avltree.def"

; **********************************************************************************
;
;	INTERNAL AVLTREE ROUTINE
;
;	Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
;	Rotate subtree leftwards at node in memory at pointer to pointer in BHL = **x.
;
;	Register affected on return:
;		..BC..HL/IXIY
;		AF..DE../.... af
;
.RotateLeft		PUSH BC
				LD	C,B
				LD	D,H
				LD	E,L
				XOR	A					;
				CALL Read_pointer			; {*x in BHL}
				XOR	A
				CP	B
				JR	Z, exit_rotateleft		; if ( *x != NULL )
					LD	A,avltree_right
					CALL Read_pointer			; y = (*x)->right
					XOR	A
					CP	B
					JR	Z, exit_rotateleft		; if ( y != NULL )
						PUSH BC
						PUSH DE					; {preserve **x in CDE}
						PUSH BC
						PUSH HL					; {preserve y in BHL}
						LD	A,avltree_left
						CALL Read_pointer			; y->left
						LD	A,B
						LD	B,C
						LD	C,A
						EX	DE,HL				; {BHL = **x, CDE = y->left}
						XOR	A
						CALL Read_pointer			; {BHL = *x}
						LD	A, avltree_right
						CALL Set_pointer			; (*x)->right = y->left
						LD	A,B					; {AHL = *x}
						EX	DE,HL
						POP	HL
						POP	BC
						LD	C,A					; {BHL = y, CDE = *x}
						LD	A, avltree_left
						CALL Set_pointer			; y->left = *x
						EX	DE,HL
						POP	HL
						LD	A,B
						POP	BC
						LD	B,C					; {BHL = **x}
						LD	C,A					; {CDE = y}
						XOR	A
						CALL Set_pointer			; *x = y
						POP	BC
						RET
.exit_rotateleft	POP	BC
				EX	DE,HL				; {restore **x}
				RET
