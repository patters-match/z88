     XLIB CheckBattLow

     DEFC STA = $B1           ; Interrupt Status register
     DEFC BTL = 3             ; If set, Battery low pin is active


; ***********************************************************************
;
; Check Battery Low Status
;
; Design & Programming, InterLogic 1997, Gunther Strube
;
; In:
;         None
;
; Out:
;         Fc = 1, Battery condition is low
;         Fc = 0, Battery condition is OK.
;
; Design & programming by Gunther Strube, InterLogic, Dec 1997
;
; Registers changed after return:
;    A.BCDEHL/IXIY same
;    .F....../.... different
;
.CheckBattLow       PUSH AF
                    IN   A,(STA)             ; Read Interrupt Status Register
                    BIT  BTL,A
                    JR   NZ, battlow
                    POP  AF
                    SCF
                    CCF                      ; Fc = 0, signal Batteries OK
                    RET
.battlow            POP  AF
                    SCF                      ; Fc = 1, signal batteries are low
                    RET
