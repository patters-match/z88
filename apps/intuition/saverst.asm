; **************************************************************************************************
; This file is part of Intuition.
;
; Intuition is free software; you can redistribute it and/or modify it under the terms of the 
; GNU General Public License as published by the Free Software Foundation; either version 2, or
; (at your option) any later version.
; Intuition is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with Intuition; 
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
; 
; $Id$  
;
;***************************************************************************************************

     MODULE SAVE_RESTORE

     XDEF Save_SPAFHLPC, Restore_SPAFHLPC
     XDEF Enable_INT, Disable_INT
     XDEF Save_Alternate, Restore_alternate

     INCLUDE "defs.h"
     INCLUDE "interrpt.def"


; **************************************************************************************************
;
; Disable Z80 IM 2 interrupts
;
.Disable_INT      PUSH AF
                  PUSH HL
                  CALL OZ_DI                ; Disable interrupts
                  PUSH AF
                  POP  HL
                  LD   (IY + IntrptStat  ),L
                  LD   (IY + IntrptStat+1),H
                  POP  HL
                  POP  AF
                  RET


; **************************************************************************************************
;
; Enable Z80 IM 2 interrupts
;
.Enable_INT       PUSH AF
                  PUSH HL
                  LD   L,(IY + IntrptStat)
                  LD   H,(IY + IntrptStat+1)
                  PUSH HL
                  POP  AF
                  CALL OZ_EI                ; Enable interrupts
                  POP  HL
                  POP  AF
                  RET



; *****************************************************************************
;
; Save virtual PC, SP, HL and AF
;
;                no register change
;
.Save_SPAFHLPC   EXX                        ; get alternate set
                 LD   (IY + VP_PC)  ,L
                 LD   (IY + VP_PC+1),H      ; save virtual PC
                 LD   (IY + VP_SP)  ,E
                 LD   (IY + VP_SP+1),D      ; save virtual SP
                 EXX
                 PUSH IX
                 POP  HL
                 LD   (IY + VP_L),L
                 LD   (IY + VP_H),H         ; save virtual HL
                 EX   AF,AF'
                 PUSH AF
                 EX   AF,AF'
                 POP  HL
                 LD   (IY + VP_AF)  ,L
                 LD   (IY + VP_AF+1),H
                 RET


; *****************************************************************************
;
; Restore virtual PC, SP, HL and AF
;
;                HL, DE, HL', DE', AF' different
;
.Restore_SPAFHLPC
                 POP  HL                    ; get return address                    ** V0.28
                 LD   E, (IY + VP_L)        ;                                       ** V1.04
                 LD   D, (IY + VP_H)        ;                                       ** V1.04
                 PUSH DE                    ;                                       ** V1.04
                 POP  IX                    ; virtual HL installed                  ** V1.04
                 EXX                        ; get alternate set
                 LD   E,(IY + VP_PC)
                 LD   D,(IY + VP_PC+1)      ; restore PC
                 LD   L,(IY + VP_SP)
                 LD   H,(IY + VP_SP+1)      ; restore virtual SP
                 LD   SP,HL                 ; then the real...                      ** V0.28
                 EX   DE,HL                 ; virtual SP, PC installed              ** V0.28
                 EXX
                 LD   E,(IY + VP_AF)
                 LD   D,(IY + VP_AF+1)
                 PUSH DE
                 EX   AF,AF'
                 POP  AF                    ; virtual AF in place
                 EX   AF,AF'
                 JP   (HL)                  ;                                       ** V0.28


; *****************************************************************************
;
; Save alternate registers on stack (AF', BC', DE' & HL')
;
; This routine will always be CALL'ed. Please note that the return address is
; removed before any registers are PUSH'ed onto the stack.
;
; This routine must be called with main registers active...
; IX is different on return.
; V0.17
;
.Save_alternate   POP  IX                   ; get return address
                  EX   AF,AF'
                  PUSH AF                   ; AF' on stack...
                  EX   AF,AF'               ; main AF swapped back...
                  EXX
                  PUSH BC
                  PUSH DE
                  PUSH HL                   ; BC', DE', HL' on stack...
                  EXX
                  JP   (IX)                 ; return... (RET)


; ******************************************************************************
;
; Restore alternate registers from stack (saved previously by 'Save_alternate')
; V0.17
;
.Restore_Alternate
                  POP  IX
                  EXX
                  POP  HL
                  POP  DE
                  POP  BC
                  EXX
                  EX   AF,AF'
                  POP  AF
                  EX   AF,AF'
                  JP   (IX)
