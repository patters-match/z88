
     MODULE Name_application

     XREF Write_Msg
     XREF SkipSpaces, Syntax_error

     XDEF Name_application, nofile_msg


     INCLUDE "director.def"


; ******************************************************************************
;
; Define a name for the 'Z80debug' application
;
.Name_application   CALL SkipSpaces
                    JP   C, Syntax_error          ; name must be defined
                    CALL_OZ(Dc_Nam)               ; define application name
                    RET
