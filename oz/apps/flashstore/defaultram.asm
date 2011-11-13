; *************************************************************************************
; FlashStore
; (C) Gunther Strube (gbs@users.sf.net) & Thierry Peycru (pek@users.sf.net), 1997-2007
;
; FlashStore is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; FlashStore is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with FlashStore;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
;
; *************************************************************************************

Module DefaultRamDevice

     XDEF DefaultRamCommand, SelectRamDevice, GetDefaultRamDevice, GetDefaultPanelRamDev
     XDEF selctram_msg, selectdev_msg

     XREF rdch, pwait, DispMainWindow        ; fsapp.asm
     XREF sopnln                             ; fsapp.asm
     XREF VduCursor                          ; selectcard.asm

     ; system definitions
     include "stdio.def"
     include "syspar.def"

     ; FlashStore popdown variables
     include "fsapp.def"


; *************************************************************************************
;
; Select Default RAM Device.
;
.DefaultRamCommand
                    ld   de,defram_banner
                    call DispMainWindow

                    ld   hl, selctram_msg
                    call_oz GN_Sop

                    ld   hl, selectdev_msg
                    call sopnln

                    call SelectRamDevice
                    ld   (ramdevno),a             ; remember selected RAM Device slot no ('0' - '3').
                    RET
; *************************************************************************************


; *************************************************************************************
; User selects RAM device by using keys 0-3,'-' or using <>J to toggle between available
; devices.
;
; IN:
;    -
; OUT:
;    A = Ascii Slot Number ('0' - '3', '-') of selected RAM Device
;
.SelectRamDevice
                    LD   DE,buf1
                    CALL GetDefaultRamDevice      ; the default RAM device at (buf1)
                    LD   A,32
                    CALL_OZ OS_Out
                    xor  a
                    ld   bc, NQ_WCUR
                    call_oz OS_Nq                 ; get current VDU cursor for current window
.inp_dev_loop
                    CALL VduCursor                ; put VDU cursor at (X,Y) = (C,B)
                    LD   HL, buf1
                    CALL_OZ(GN_Sop)               ; display the current RAM device.
                    LD   A,8
                    CALL_OZ(OS_Out)               ; put blinking cursor over slot number of RAM device

                    CALL rdch                     ; get RAM device slot number
                    cp   IN_ESC
                    jr   z, dev_aborted           ; user aborted selection
                    cp   IN_ENT
                    jr   z, dev_selected          ; user has selected a RAM device
                    cp   LF
                    jr   z, toggle_device         ; <>J
                    cp   '-'
                    jr   z, upd_slotno            ; allow for "-"
                    cp   48
                    jr   c,inp_dev_loop           ; only "0" to "3" allowed
                    cp   52
                    jr   nc,inp_dev_loop

                    LD   H,A                      ; preserve Ascii slot number
                    SUB  48
                    CALL CheckRamDevice
                    JR   C, inp_dev_loop          ; there's no RAM card in selected slot, ignore input
                    LD   A,H
.upd_slotno         LD   (buf1+5),A               ; update slot number in RAM device
                    JR   inp_dev_loop             ; and let it be displayed.
.toggle_device
                    LD   A,(buf1+5)
                    CP   '-'
                    JR   z, wrap_slotno           ; wrap from :RAM.- to :RAM.0
                    SUB  48
.toggle_device_loop
                    INC  A
                    CP   4
                    JR   Z, select_globalram      ; only scan slots 0 - 3, then automatically select :RAM.-
                    LD   H,A
                    CALL CheckRamDevice           ; RAM device at slot A?
                    JR   NC, ram_dev_found        ; yes!
                    LD   A,H
                    JR   toggle_device_loop       ; try next slot...
.wrap_slotno
                    LD   A,-1                     ; check slot 0 for a RAM device
                    JR   toggle_device_loop
.select_globalram
                    LD   A,'-'
                    JR   upd_slotno
.ram_dev_found
                    LD   A,H
                    ADD  A,48
                    JR   upd_slotno
.dev_aborted
                    LD   DE,buf1
                    CALL GetDefaultRamDevice      ; restore current default RAM Device
                    SCF                           ; indicate abort command
.dev_selected
                    LD   A,(buf1+5)               ; return Ascii Slot Number of RAM Device
                    RET
.CheckRamDevice
                    push bc                       ; preserve VDU X,Y cursor...
                    ld   bc,Nq_Mfp
                    oz   OS_Nq                    ; check if there's a RAM card in selected slot A
                    pop  bc
                    RET
; *************************************************************************************


; *************************************************************************************
;
; Get FlashStore's Default RAM Device at (DE).
;
.GetDefaultRamDevice
                    PUSH BC

                    LD   HL, ramdevname
                    LD   BC, 5
                    LDIR
                    LD   A,(ramdevno)
                    LD   (DE),A
                    INC  DE
                    XOR  A
                    LD   (DE),A                   ; null terminate RAM device name

                    POP  BC
                    RET
; *************************************************************************************


; *************************************************************************************
;
; Define the default Ascii RAM Device slot number at (ramdevno)
;
.GetDefaultPanelRamDev
                    LD    A, 64
                    LD   BC, PA_Dev               ; Read default device
                    LD   DE, buf1                 ; buffer for device name
                    PUSH DE                       ; save pointer to buffer
                    CALL_OZ (Os_Nq)
                    POP  DE
                    LD   B,0
                    LD   C,A                      ; actual length of string...
                    DEC  BC
                    EX   DE,HL
                    ADD  HL,BC
                    LD   A,(HL)                   ; get slot number of RAM device
                    LD   (ramdevno),A
                    RET
; *************************************************************************************


; *************************************************************************************
; constants

.defram_banner      DEFM "SELECT DEFAULT RAM DEVICE", 0
.ramdevname         DEFM ":RAM.", 0
.selctram_msg       DEFM 13,10, " Select RAM device.", 13, 10, 0
.selectdev_msg      DEFM " Use keys 0-3 or ",1, "+J to toggle. ", 1, SD_ENT, " to select.", 0
