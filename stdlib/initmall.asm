     XLIB Init_malloc

     LIB Alloc_new_pool

     XREF  pool_index                   ; data structures defined in application code
     XREF  allocated_mem                ; variable defined in application code


; ***********************************************************************************
;
;    Very important initial call to be performed by application
;    before using the .malloc routine.
;
;    Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
.Init_malloc        XOR  A
                    LD   (pool_index),A             ; initiate index to first pool
                    LD   C,A
                    LD   HL, 0
                    LD   (allocated_mem),HL
                    LD   (allocated_mem+2),A        ; reset variable
                    CALL Alloc_new_pool             ; then create a pool at index
                    RET
