     XLIB ExtCall

; **************************************************************************************************
; This file is part of the Z88 Standard Library.
;
; The Z88 Standard Library is free software; you can redistribute it and/or modify it under 
; the terms of the GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; The Z88 Standard Library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with FlashStore;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
; 
; $Id$  
;
;***************************************************************************************************


; ******************************************************************************************
;
; EXTCALL - Call subroutine in external bank at segment.
;
; The routine copies a small 'bind-bank' routine on the stack which performs the actual
; bank binding. This avoids the conflict of the EXT_CALL routine to be paged out during
; bank binding and calling of the subroutine, if the current segment is to bound 
; with another bank.
;
; Since the stack is being used below the <EXT_CALL> RET address, it is best to use a 
; register to point at eventual parameters on the stack before CALL'ing EXT_CALL.
;
;  IN: b  (alternate) = bank number where subroutine resides.
;      c  (alternate) = bits 0 - 1: segment of bank binding (0 - 3)
;      hl (alternate) = <Subroutine> address to CALL
;
;  The bank specifier may be a relative bank number (0 - 3Fh), specified with
;  with port number in register c, bits 7,6.
;  If an absolute bank number is specified, the port number is ignored.
;
; Register status on entry of subroutine (pointed to by HL):
;
; AFBCDEHL/IXIY ........ same
; ......../.... afbcdehl different
;
; Register status after return to caller (that executed EXT_CALL):
;
; ????????/???? af..de.. same
; ????????/???? ..bc..hl different      (main registers changed by CALL'ed subroutine)
;
; As seen above, all main register and alternate AF registers may be
; used as parameter passing between the <Subroutine> and the caller.
;
; ------------------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ------------------------------------------------------------------------------
;
.ExtCall            EX   AF,AF'                   ; use alternate registers
                    EXX
                    PUSH BC                       ; preserve bank & segment
                    EX   DE,HL                    ; subroutine addr. in DE
                    LD   HL,0
                    ADD  HL,SP                    ; fetch stack pointer
                    LD   BC,end_bindbank-bindbank ; size of binding routine...
                    SBC  HL,BC
                    LD   SP,HL                    ; make room on stack for binding routine
                    PUSH BC
                    PUSH DE
                    PUSH HL
                    EX   DE,HL                    ; DE points to start of stack area
                    LD   HL, bindbank             ; copy binding subroutine
                    LDIR                          ; to stack...
                    POP  HL                       ; HL = start of stack area
                    POP  DE                       ; DE = subroutine address
                    POP  BC                       ; BC = length of area...
                    ADD  HL,BC                    ; point at bank, segment
                    LD   C,(HL)                   ; restore segment & port specifier
                    INC  HL
                    LD   B,(HL)                   ; restore bank specifier
                    INC  HL                       ;
                    PUSH HL                       ; preserve pointer to <EXT_CALL> RET address
                    LD   HL, restore_SP
                    PUSH HL                       ; <RET> address for RET_subr (to 'restore_SP')
                    LD   HL,4
                    ADD  HL,SP
                    PUSH HL                       ; preserve pointer to bindbank routine
                    PUSH BC                       ; preserve bank,segment
                    LD   BC, RET_subroutine-bindbank
                    ADD  HL,BC                    ; HL = relocated RET_subroutine address
                    POP  BC                       ; restore bank, segment
                    EX   (SP),HL                  ; (SP) = relocated RET_subroutine
                    JP   (HL)                     ; HL = binding routine, execute...

.restore_SP         POP  HL                       ; pointer to RET <EXT_CALL>
                    LD   SP,HL                    ; restore original stack pointer
                    EXX                           ; back to main registers...
                    RET                           ; return to caller.

; this is executed on the stack:   DE = subroutine address
.bindbank           LD   HL,$04D0
                    LD   A,C
                    AND  @00000011                ; only segments 0 - 3
                    OR   L                        ; in port $D0 - $D3
                    LD   L,A                      ; at address $04D0 - $04D3
                    LD   C,A                      ; (hardware port $D0 - $D3)
                    LD   A,(HL)                   ; get old bank binding
.absolute_banknum   LD   (HL),B                   ; first update soft copy
                    OUT  (C),B                    ; then bind in new bank
                    LD   B,A                      ; old bank in B
                    EX   (SP),HL                  ; HL = RET_subroutine, (SP) = port address
                    PUSH BC                       ; preserve old bank & port
                    PUSH HL                       ; RET_subroutine on stack
                    PUSH DE                       ; subroutine address on stack
                    EXX
                    EX   AF,AF'                   ; back to main registers
                    RET                           ; jump to subroutine

.RET_subroutine     EXX                           ; use alternate registers...
                    POP  BC                       ; get old bank & port
                    POP  HL                       ; get address of soft copy
                    LD   (HL),B                   ; update soft copy first
                    OUT  (C),B                    ; bind in previous bank  at segment
                    RET                           ; now restore original stack pointer...
.end_bindbank
