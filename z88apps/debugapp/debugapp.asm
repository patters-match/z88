; **************************************************************************************************
; This file is part of the Z88 DebugApp application.
;
; DebugApp is free software; you can redistribute it and/or modify it under 
; the terms of the GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; DebugApp is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with DebugApp;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
; 
; $Id$  
;
;***************************************************************************************************

    MODULE DebugApp

    ORG $C000

    INCLUDE "stdio.def"
    INCLUDE "director.def"
    INCLUDE "error.def"

    DEFC RAM_pages = 32                           ; 32 * 256 = 8K RAM at $2000-3FFF


.DebugAppEntry
                    JP   check_memory
                    SCF                           ; preserve allocated memory on pre-emption
                    RET
.check_memory
                    LD   A,(IX+$02)               ; IX points at information block
                    CP   $20+RAM_pages            ; get end page+1 of contiguous RAM
                    JR   Z, continue_appl         ; end page OK, RAM allocated...

                    LD   A,$07                    ; No Room for Application, return to Index
                    CALL_OZ(Os_Bye)               ; Application suicide...
.continue_appl
                    LD   A, SC_ENA
                    CALL_OZ OS_ESC                ; ESC will suicide application...

                    XOR  A
                    LD   B,A
                    LD   HL,Errhandler
                    CALL_OZ OS_ERH                ; install an Error Handler...

                    CALL appwindow
                    JP   $C200                    ; then execute debugging code at $C200


; ****************************************************************************
; Debug application window, also used by default error handler on RC_DRAW
;
.appwindow
                    LD   HL, window_vdu
                    CALL_OZ GN_SOP
                    CP   A
                    RET
.window_vdu         DEFM 1,"7#6",32,32,32+80,32+8,129 ; window at (0,0) width,heigth = 80,8
                    DEFM 1,"2H6"                  ; select window
                    DEFM 13,10                    ; execute line feed (to satisfy CLI)
                    DEFM 1,"2C6"                  ; and clear window
                    DEFM 1,"3+CS"                 ; flashing cursor and vertical scrolling enabled
.helloworld_msg     DEFM "Hello world!", 13, 10, 0
                    
; ****************************************************************************


; ****************************************************************************
;
; Default Application Error Handler
;
.ErrHandler
                    RET  Z
                    CP   rc_draw
                    JR   Z,appwindow
                    CP   rc_esc
                    JR   Z,akn_esc
                    CP   rc_quit
                    JR   Z,suicide
                    CP   A
                    RET
.akn_esc
                    LD   A,1
                    CALL_OZ os_esc           ; acknowledge ESC detection (and perform suicide)
.suicide
                    XOR  A
                    CALL_OZ(os_bye)          ; perform suicide, focus to Index...
.void               JR   void
; ****************************************************************************

                    DS $100-$PC

; ****************************************************************************
; Debug application DOR at $C100

.DbgApp_DOR
                    DEFB 0, 0, 0                  ; link to parent
                    DEFB 0, 0, 0
                    DEFB 0, 0, 0
                    DEFB $83                      ; DOR type - application ROM
                    DEFB DOREnd0-DORStart0        ; total length of DOR
.DORStart0          DEFB '@'                      ; Key to info section
                    DEFB InfoEnd0-InfoStart0      ; length of info section
.InfoStart0         DEFW 0                        ; reserved...
                    DEFB 'T'                      ; application key letter (T for test)
                    DEFB RAM_pages                ; 4K of contigous RAM to play with
                    DEFW 0                        ;
                    DEFW 0                        ; Unsafe workspace
                    DEFW 256                      ; Safe workspace
                    DEFW DebugAppEntry            ; Entry point of code in seg. 3
                    DEFB 0                        ; bank binding to segment 0 (none)
                    DEFB 0                        ; bank binding to segment 1 (none)
                    DEFB 0                        ; bank binding to segment 2 (none)
                    DEFB $3F                      ; bank binding to segment 3
                    DEFB AT_Bad                   ; Bad application
                    DEFB 0                        ; no caps lock on activation
.InfoEnd0           DEFB 'H'                      ; Key to help section
                    DEFB 12                       ; total length of help
                    DEFW DbgApp_DOR
                    DEFB $3F                      ; point to topics (none)
                    DEFW DbgApp_DOR
                    DEFB $3F                      ; point to commands (none)
                    DEFW DebugApp_Help
                    DEFB $3F                      ; point to help
                    DEFW DbgApp_DOR
                    DEFB $3F                      ; point to token base
                    DEFB 'N'                      ; Key to name section
                    DEFB NameEnd0-NameStart0      ; length of name
.NameStart0         DEFM "DebugApp",0
.NameEnd0           DEFB $FF
.DOREnd0

.DebugApp_Help      DEFM $7F
                    DEFM "Debug Application for OZvm, Release V1.0, October 2004",$7F, $7F
                    DEFM "Load your code using 'ldc filename bfc200' into top", $7F
                    DEFM "bank of slot 2 at ORG $C200 (ffc200 = slot 3).", $7F
                    DEFM "Workspace is available at $2000-$3FFF.", 0

                    DS $200-$PC



; ########################################################################################
; ========================================================================================
; INSERT YOUR CODE HERE, at ORG $C200
; (A simple hello world example has been placed as default)
.testcode
                    CALL_OZ Os_In               ; wait for keypress
                    JR   C, testcode
                    CALL_OZ OS_Out              ; print keypress
.end                JR   testcode

; ========================================================================================
; ########################################################################################




.space              DS  $3FC0-$PC                 ;  pad spaces until $3FC0

; ========================================================================================

.appl_front_dor     DEFB 0, 0, 0                ; link to parent...
                    DEFB 0, 0, 0                ; no help DOR
                    DEFW DbgApp_DOR             ; offset of code
                    DEFB $3F                    ; in bank
                    DEFB $13                    ; DOR type - ROM front DOR
                    DEFB 8                      ; length of DOR
                    DEFB 'N'
                    DEFB 5                      ; length of name and terminator
                    DEFM "APPL", 0
                    DEFB $FF                    ; end of application front DOR

                    DEFS 37                     ; blanks to fill-out space.

.eprom_header       DEFW $0051                  ; $3FF8 Card ID for this application
                    DEFB @00000100              ; $3FFA Denmark country code isfn
                    DEFB $80                    ; $3FFB external application
                    DEFB $01                    ; $3FFC size of EPROM (1 banks of 16K = 16K)
                    DEFB 0                      ; $3FFD subtype of card ...
.eprom_adr_3FFE     DEFM "OZ"                   ; $3FFE card is an application EPROM
.EpromTop
