
    MODULE Breakpoint_commands

    INCLUDE "defs.h"

    XREF FindBreakPoint
    XREF GetChar
    XREF Write_CRLF, Display_char
    XREF Write_Err_Msg
    XREF Get_Constant
    XREF IntHexDisp_H
    XREF Toggle_Brkpdump

    XDEF ToggleBreakPoint, Breakpoint_List



; **********************************************************************************
;
; Toggle Breakpoint (Set / Reset)
;
; Entry: HL = pointer in input buffer to a possible 16 bit value
;
.ToggleBreakpoint LD   C,16
                  CALL Get_Constant         ; integer value into DE
                  RET  C                    ; error occurred...
                  BIT  Flg_RTM_Breakp,(IY + FlagStat2)            ; any breakpoints defined?                  ** V0.18
                  JR   Z, def_breakpoint
                  CALL FindBreakPoint       ; breakpoint returned in DE
                  JR   Z, found_breakp
.def_breakpoint   LD   BC, BreakPoints
                  PUSH IY
                  POP  HL
                  ADD  HL,BC
                  LD   A,(HL)               ; get number of defined breakpoints
                  CP   8
                  JR   Z, all_bp_defined    ; all defined - no more room
                  SET  Flg_RTM_Breakp,(IY + FlagStat2)            ; indicate defined breakpoint               ** V0.18
                  INC  HL                   ; point at base of breakpoints
                  LD   B,0
                  LD   C,A
                  SLA  C                    ; word offset...
                  ADD  HL,BC                ; point at free location
                  LD   (HL),D               ; save high byte of breakpoint
                  INC  HL
                  LD   (HL),E               ; save low byte of breakpoint
                  INC  A
                  LD   (IY + Breakpoints),A ; save new counter
                  JR   exit_toggle_bp
.found_breakp     PUSH HL                   ; remember pointer to low byte
                  LD   BC, BreakPoints      ; of found breakpoint
                  PUSH IY
                  POP  HL
                  ADD  HL,BC
                  LD   A,(HL)               ; get breakpoint counter
                  DEC  A                    ; one less breakpoint
                  LD   (HL),A               ; save new counter
                  INC  HL                   ; point at base of breakpoints
                  LD   C,A                  ; this also points to
                  SLA  C                    ; word offset
                  ADD  HL,BC                ; the last breakpoint,
                  LD   D,(HL)               ; the high byte...
                  INC  HL
                  LD   E,(HL)               ; DE = last breakpoint
                  POP  HL
                  LD   (HL),E               ; save last breakpoint at
                  DEC  HL                   ;
                  LD   (HL),D               ; previous erased breakpoint!
                  OR   A                    ; last breakpoint removed?                  ** V0.18
                  JR   NZ, exit_toggle_bp   ; no...                                     ** V0.18
                  RES  Flg_RTM_Breakp,(IY + FlagStat2)            ; indicate no more breakpoints defined      ** V0.18
.exit_toggle_bp   JP   Breakpoint_List      ; display breakpoints, and

.all_bp_defined   LD   A,$0E                ; 'Cannot satisfy request'
                  JP   Write_Err_Msg


; **********************************************************************************
;
; List Breakpoints in window
;
; Register status after return:
;
;       ......../IXIY  same
;       AFBCDEHL/....  different
;
.Breakpoint_List  LD   BC,31                 ; offset to base of breakpoints
                  PUSH IY
                  POP  HL
                  ADD  HL,BC
                  BIT  Flg_RTM_Breakp,(IY + FlagStat2)            ; any breakpoints defined?                  ** V0.18
                  JR   Z, No_breakpoints    ; Error message "No Breakpoints entered."
                  LD   B,(HL)               ; print-breakpoint-counter                  ** V0.18
                  LD   C,1                  ; print item counter
.list_breakpoints INC  HL                   ; High byte of first breakp.
                  LD   D,(HL)
                  INC  HL
                  LD   E,(HL)               ; get low byte of breakp.
                  PUSH HL                   ; remember pointer in breakpoint list
                  PUSH BC
                  EX   DE,HL                ; HL = breakpoint address
                  SCF
                  CALL IntHexDisp_H         ; display into ASCII Hex notation
                  POP  BC                   ; restore counter
                  BIT  0,C                  ; display comma if counter odd
                  JR   NZ, print_tab        ; first item in line printed...
                  CALL Write_CRLF           ; two items in line printed, execute
                  JR   bp_printed           ; a CR in window

.print_tab        LD   A,B
                  CP   1
                  JR   Z,bp_printed         ; last bp. printed - ignore comma
                  LD   A,' '                ; more breakpoints, print space
                  CALL Display_char
.bp_printed       POP  HL                   ; restore pointer to previous high byte
                  INC  C                    ; update print counter
                  DJNZ,list_breakpoints     ; more breakpoints to list...
                  JP   Write_CRLF           ; execute a CR in window

.no_breakpoints   LD   A, ERR_none
                  JP   Write_Err_Msg
