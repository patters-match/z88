
    MODULE WindowManagement

    INCLUDE "defs.h"
    INCLUDE "syspar.def"
    INCLUDE "saverst.def"

    XREF Switch_bitnumber
    XREF Calc_HL_Ptr
    XREF Save_alternate, Restore_Alternate
    XREF Display_string, Display_char, Write_CRLF
    XREF SkipSpaces, Getchar
    XREF Syntax_Error

    XDEF RST_appl_window, SV_appl_window, REL_appl_window, REL_INT_window
    XDEF SV_INT_window, RST_INT_window
    XDEF Disp_monitor_win, ToggleWindow
    XDEF Disp_window_ID, Set_Intuition_ID
    XDEF Window_VDU
    XDEF window1, window2, std_window, vert_scroll
    XDEF redirect_window, simple_window


; *****************************************************************************
;
; Restore the application screen, if previously copied, and
; redirect output to current window of application.
;
; Register status after return:
;
;       AF....../IXIY  same
;       ..BCDEHL/....  different
;
.RST_appl_window  PUSH AF
                  PUSH IX
                  CALL Save_alternate
                  BIT  Flg_AplScr,(IY + Flagstat1)
                  JR   Z, redirect_output
                  LD   L,(IY+66)
                  LD   H,(IY+67)
                  PUSH HL
                  POP  IX                   ; screen copy handle...
                  LD   A, Sr_Rus            ; restore application screen
                  CALL_OZ(Os_Sr)
.redirect_output  LD   HL, redirect_window  ;                                           ** V0.26
                  LD   A,(IY + ApplWinID)   ; get application window ID                 ** V0.26
                  CALL Window_VDU           ; execute VDU string                        ** V0.26
                  RES  Flg_IntWinActv,(IY + FlagStat1) ; indicate application window active  ** V0.24a
                  RES  Flg_AplScr,(IY + Flagstat1)
                  CALL Restore_Alternate    ; - output redirected to appl. window
                  POP  IX
                  POP  AF
                  RET



; *****************************************************************************
;
; Release the application screen, without displaying it...
;
.REL_appl_window    PUSH AF
                    PUSH IX
                    BIT  Flg_AplScr,(IY + Flagstat1)
                    JR   Z, exit_REL_appl     ; no screen to release...
                    LD   L,(IY + ApplScrID)
                    LD   H,(IY + ApplScrID+1) ; get handle of screen copy
                    PUSH HL
                    POP  IX                   ; screen copy handle...
                    LD   A, Sr_Fus            ; Free application screen
                    CALL_OZ(Os_Sr)
                    RES  Flg_AplScr,(IY + Flagstat1)
.exit_REL_appl      POP  IX
                    POP  AF
                    RET


; *****************************************************************************
;
; Restore the Intuition screen
;
.RST_INT_window     PUSH AF
                    PUSH IX
                    BIT  Flg_IntScr,(IY + Flagstat1)
                    JR   Z, exit_RST_INT      ; no screen to restore...
                    LD   L,(IY + IntScrID)
                    LD   H,(IY + IntScrID+1)  ; get handle of screen copy
                    PUSH HL
                    POP  IX                   ; screen copy handle...
                    LD   A, Sr_Rus            ; restore screen
                    CALL_OZ(Os_Sr)
                    RES  Flg_IntScr,(IY + Flagstat1)
.exit_RST_INT       POP  IX
                    POP  AF
                    RET



; *****************************************************************************
;
; Release the Intuition screen, without displaying...
;
.REL_INT_window     PUSH AF
                    PUSH IX
                    BIT  Flg_IntScr,(IY + Flagstat1)
                    JR   Z, exit_REL_INT      ; no screen to release...
                    LD   L,(IY + IntScrID)
                    LD   H,(IY + IntScrID+1)  ; get handle of screen copy
                    PUSH HL
                    POP  IX                   ; screen copy handle...
                    LD   A, Sr_Fus            ; free Intuition screen
                    CALL_OZ(Os_Sr)
                    RES  Flg_IntScr,(IY + Flagstat1)
.exit_REL_INT       POP  IX
                    POP  AF
                    RET


; ****************************************************************************************
;
.SV_INT_window    PUSH AF
                  PUSH IX
                  BIT  Flg_IntScr,(IY + FlagStat1)   ; intitiate Intuition screen flag
                  JR   NZ, exit_SV_INT               ; screen already saved...
                  LD   A, Sr_Sus                     ; first make a copy of Intuition screen
                  CALL_OZ(Os_Sr)
                  RET  C                             ; couldn't save Intuition screen...
                  PUSH IX
                  POP  HL
                  LD   (IY + IntScrID  ),L
                  LD   (IY + IntScrID+1),H           ; save Intuition screen handle
                  SET  Flg_IntScr,(IY + FlagStat1)   ; intitiate Intuition screen saved
.exit_SV_INT      POP  IX
                  POP  AF
                  RET



; *****************************************************************************
;
; Make a copy of the application screen, and get the current window
; ID ('1' to '5') of the application.
;
; Register status after return:
;
;       ......../..IY  same
;       AFBCDEHL/IX..  different
;
.SV_appl_window   CALL Save_alternate
                  LD   A, Sr_Sus            ; save application screen
                  CALL_OZ(Os_Sr)
                  JR   C, scr_not_copied    ; an error occurred...
                  PUSH IX                   ; screen copied,
                  POP  HL                   ; save handle for next reference...
                  LD   (IY + ApplScrID  ),L
                  LD   (IY + ApplScrID+1),H
                  SET  Flg_AplScr,(IY + Flagstat1)
                  JR   get_current_win
.scr_not_copied   RES  Flg_WinMode,(IY + FlagStat3) ; Screen Protect Mode OFF.
                  RES  Flg_IntWinActv,(IY + FlagStat1) ; Indicate Intuition window NOT active        ** V0.24a
                  RES  Flg_AplScr,(IY + Flagstat1)                                   ** V0.31
.get_current_win  XOR  A                    ; get application current window ID
                  LD   BC, Nq_Wbox
                  CALL_OZ(Os_Nq)
                  LD   (IY + ApplWinID),A   ; remember current window of application
                  CALL Restore_Alternate    ; - output redirected to appl. window
                  RET

; ****************************************************************************************
;
.Set_Intuition_ID CALL SkipSpaces
                  LD   A,'6'
                  JR   C, set_ID            ; no parameter, set default window ID
                  CALL GetChar
                  CP   '1'
                  JP   C, Syntax_error
                  CP   '7'
                  JP   NC, Syntax_error
.set_ID           LD   (IY + IntWinID),A    ; new Intuition window ID
                  JP   Disp_Monitor_win     ; re-display with new ID...


; *****************************************************************************
;
; Create Intuition Monitor window #1 or #2.
;
;
.Disp_Monitor_win PUSH HL
                  PUSH AF
                  PUSH IX
                  LD   A,(IY + IntWinID)               ; get current Intuition window ID  ** V0.26
                  BIT  Flg_IntWin,(IY + FlagStat1)     ; Intuition window #1?
                  JR   Z, Intuition_win2
                  LD   HL, window1                     ;                                  ** V0.26
                  JR   set_window
.Intuition_win2   LD   HL, window2
.set_window       CALL Window_VDU                      ; use "Intuition" window...
                  LD   HL, std_window
                  CALL Window_VDU                      ;                                  ** V0.26
                  SET  Flg_IntWinActv,(IY + FlagStat1) ; indicate Intuition window active ** V0.24a
                  POP  IX
                  POP  AF
                  POP  HL
                  RET


; *****************************************************************************************
;
; Select Z88-Monitor window 1 or 2.  (toggle)           V0.18 / V0.22b
;
.ToggleWindow     PUSH BC
                  PUSH DE
                  PUSH HL
                  PUSH IX
                  LD   BC, 2^Flg_IntWin*256 + FlagStat1
                  CP   A
                  CALL Switch_bitnumber     ; first toggle Intuition window
                  CALL Disp_Monitor_win     ; display Intuition window...               ** V0.22
                  POP  IX
                  POP  HL
                  POP  DE
                  POP  BC
                  RET



; ****************************************************************************************
;
; Display Intuition window ID and application window ID                V0.26
;
.Disp_window_ID   LD   HL, Int_ID_msg
                  CALL Display_String
                  LD   A,(IY+70)            ; get current Intuition window ID
                  CALL Display_Char
                  CALL Write_CRLF
                  LD   HL, Appl_ID_msg
                  CALL Display_String
                  LD   A,(IY+65)            ; get current application window ID
                  CALL Display_Char
                  CALL Write_CRLF
                  RET

.Int_ID_msg       DEFM "Intuition window ID: ",0
.appl_ID_msg      DEFM "Appl. window ID: ",0



; *****************************************************************************************
;
; window related VDU call.                              V0.26
; HL points at VDU string
;         1. byte in VDU string is length of string
;         4. byte in VDU string is position of window ID in
; A contains window ID ('1' to '6')
;
; Register status after return:
;
;       A.BCDE../IXIY  same
;       .F....HL/....  different
;
.Window_VDU       PUSH BC
                  PUSH DE
                  PUSH IX
                  LD   C,(HL)
                  INC  HL
                  PUSH HL
                  POP  IX                   ; remember start of VDU string
                  LD   HL,0
                  ADD  HL,SP
                  LD   D,H
                  LD   E,L                  ; DE = current SP
                  LD   B,0
                  SBC  HL,BC                ; make room for VDU string on stack
                  LD   SP,HL                ; set SP below VDU string
                  PUSH DE                   ; remember current SP
                  PUSH IX
                  POP  DE                   ; DE = ptr. to start of VDU string
                  PUSH HL
                  POP  IX                   ; IX start of VDU string on stack
                  EX   DE,HL                ; HL = source, DE = dest.
                  LDIR                      ; copy VDU string to stack (dymamic memory)
                                            ; DE = ptr. to null + 1
                  LD   (IX+3),A             ; set window ID in VDU string
                  PUSH IX
                  POP  HL
                  CALL Display_String       ; execute window VDU string
                  POP  HL                   ; get old SP
                  LD   SP,HL                ; install old SP
                  POP  IX
                  POP  DE
                  POP  BC
                  RET


.window1          DEFB 10
                  DEFM 1,"7#6",$59,32,$44,32+8,129,0  ; with vertical bars
.window2          DEFB 10
                  DEFM 1,"7#6",32+1,32,$57,32+8,129,0
.std_window       DEFB 16
                  DEFM 1,"2H6"              ; select window
                  DEFM 13,10                ; execute line feed (to satisfy CLI)
                  DEFM 1,"2C6"              ; and clear window
.vert_scroll      DEFM 1,"3+CS",0           ; flashing cursor and vertical scrolling enabled

.simple_window    DEFB 5
                  DEFM 1,"2C6",0            ; select & clear window - no cursor and
                                            ; vertical scrolling disabled
.redirect_window  DEFB 5
                  DEFM 1,"2H6",0            ; redirect output to window #6 (default)
                                            ; #6 will change when used for application window
