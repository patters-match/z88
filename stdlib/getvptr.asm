
     XLIB GetVarPointer

     LIB GetPointer, Read_pointer


; ********************************************************************************
;
; Get pointer in pointer variable.
;
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
;    IN: HL = local address of pointer to pointer variable.
;
;    OUT: BHL = pointer in pointer variable.
;         IF pointer to pointer variable is NULL (pointer variable has not yet
;         been created), then a NULL is returned in stead.
;
; Registers changed after return:
;
;    AF.CDE../IXIY  same
;    ..B...HL/....  different
;
.GetVarPointer      CALL GetPointer               ; get &ptr (pointer to pointer)
                    PUSH AF
                    XOR  A
                    CP   B                        ; if ( &ptr == NULL ) return NULL
                    JR   Z, exit_getvarptr
                    CALL Read_pointer             ; read pointer in pointer variable
.exit_getvarptr     POP  AF
                    RET
