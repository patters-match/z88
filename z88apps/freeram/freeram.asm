; *************************************************************************************
; FreeRam
; (C) Gunther Strube (gbs@users.sf.net) 1998
;
; FreeRam is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; FreeRam is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with FreeRam;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
;
; *************************************************************************************

     Module FreeRam

; V1.0 implemented 11/06/1998

lib opengraphics, cleargraphics
lib createwindow
lib RamDevFreeSpace
lib MemDefBank

xdef base_graphics            ; prepare pointer for graphics library routines.
                              ; (used by library routines)

include "stdio.def"
include "dor.def"
include "director.def"
include "error.def"
include "integer.def"
include "syspar.def"
include "fpp.def"

; FreeRam is made as a ROM popdown.

defc FreeRam_Workspace = 32

DEFVARS $1FFE-FreeRam_WorkSpace
     base_graphics  ds.w 1         ; pointer to base of HIRES0
     slotno         ds.b 1         ; the selected slot to scan for free space
     cardsize       ds.b 1         ; size of card in 16K banks
     freespace      ds.l 1         ; free space in bytes (32bit integer)
     ascbuf         ds.b 16        ; buffer for ascii integers, etc.
     inpbuf         ds.b 1         ; 1 byte buffer for input of device number
ENDDEF

     ORG $F800

; ******************************************************************************
; Z88 application data structure for FreeRam .
;
.appl1_DOR          DEFB 0, 0, 0                  ; link to parent
                    DEFB 0, 0, 0                  
                    DEFB 0, 0, 0
                    DEFB $83                      ; DOR type - application ROM
                    DEFB DOREnd1-DORStart1        ; total length of DOR
.DORStart1          DEFB '@'                      ; Key to info section
                    DEFB InfoEnd1-InfoStart1      ; length of info section
.InfoStart1         DEFW 0                        ; reserved...
                    DEFB 'M'                      ; application key letter
                    DEFB 0                        ; contigous RAM size (0 = good application)
                    DEFW 0                        ;
                    DEFW 0                        ; Unsafe workspace
                    DEFW FreeRam_WorkSpace        ; Safe workspace
                    DEFW FreeRam_Entry            ; Entry point of code in seg. 3
                    DEFB 0                        ; bank binding to segment 0 (Intuition)
                    DEFB 0                        ; bank binding to segment 1
                    DEFB 0                        ; bank binding to segment 2
                    DEFB $3F                      ; bank binding to segment 3 (FreeRam)
                    DEFB AT_Popd | AT_Good        ; Good popdown
                    DEFB 0                        ; no caps lock on activation
.InfoEnd1           DEFB 'H'                      ; Key to help section
                    DEFB 12                       ; total length of help
                    DEFW FreeRam_topics
                    DEFB $3F
                    DEFW FreeRam_commands
                    DEFB $3F
                    DEFW FreeRam_help
                    DEFB $3F
                    DEFB 0, 0, 0                  ; No token base
                    DEFB 'N'                      ; Key to name section
                    DEFB NameEnd1-NameStart1      ; length of name
.NameStart1         DEFM "FreeRam", 0
.NameEnd1           DEFB $FF
.DOREnd1


; ******************************************************************************
;
; Entry of FreeRAM program when the popdown is created by OZ
;
.FreeRam_entry
                    ld   a, SC_ENA
                    call_oz(OS_Esc)               ; enable ESC detection

                    ld   a, 128+64 | '1'          ; draw bottom line, display banner...
                    ld   hl,NameStart1            ; banner text (application name)
                    ld   bc,$003B
                    ld   de,$0810                 ; window at (0,59), width 16, height 8
                    call createwindow

                    ld   a,'2'                    ; invisible window area for "K" lines
                    ld   bc,$004D
                    ld   de,$0806                 ; window at (0,77), width 6, height 8
                    call createwindow

                    ld   a,'3'
                    ld   b, $80                   ; use segment 2 for map manipulation
                    ld   l,64                     ; map width of 64 pixels
                    call opengraphics             ; create map window...

                    ld    a, 10                   ; read max. 10 characters
                    ld   bc, PA_DEV               ; read default device
                    ld   de, ascbuf               ; buffer for device name
                    call FetchParameter
                    ld   b,0
                    ld   c,a
                    ex   de,hl
                    add  hl,bc
                    dec  hl
                    ld   a,(hl)                   ; get (slot) number
                                                  ; of default RAM device
                    ld   (inpbuf),a
.inp_dev_loop
                    sub  48                       ; slot number
                    ld   (slotno),a               ; as internal integer

                    call GetFreeSpace             ; get RAM device info
                    call c, DispNoRam             ; - if available
                    call nc,DispFreeRamInfo
.keyb_loop
                    ld   hl,ramdev
                    call_oz(GN_Sop)               ; display ":RAM." at top of window

                    ld   a,(inpbuf)
                    call_oz(OS_Out)               ; then current select device number
                    ld   a,8
                    call_oz(OS_Out)               ; BACKSPACE (cursor on top of number)

.ext_key            call_oz(OS_In)                ; input a device number
                    jr   c, check_errors
                    cp   0
                    jr   z, ext_key               ; extended key pressed, fetch it...
                    cp   48
                    jr   c,ext_key                ; only "0" to "3" allowed
                    cp   52
                    jr   nc,ext_key
                    ld   (inpbuf),a
                    jr   inp_dev_loop             ; user selected ram device number...
.check_errors
                    cp   rc_quit
                    jr   z,exit_FreeRam           ; popdown pre-empted
                    cp   rc_esc
                    jr   z,exit_FreeRam           ; user pressed ESC
                    jr   keyb_loop                ; ignore other errors...
.exit_FreeRam
                    xor  a
                    call_oz(OS_Bye)               ; popdown performs suicide ...


; ***************************************************************************************
;
.DispFreeRamInfo    push af
                    call DispCardSizeColumn
                    ld   hl,64                    ; map width is 64 pixels
                    call cleargraphics            ; reset graphics map (no card present)
                    call DispFreeRamMap           ; display graphical view of card
                    call DispCardSize
                    call DispFreeSpaceInfo
                    pop  af
                    ret


; ***************************************************************************************
;
.DispNoRam          push af
                    ld   hl, selwin2
                    call_oz(Gn_Sop)               ; select (and clear) window #2
                    ld   hl,64                    ; map width is 64 pixels
                    call cleargraphics            ; reset graphics map (no card present)
                    ld   hl, selwin1
                    call_oz(Gn_Sop)               ; select (and clear) window #1
                    ld   hl, nonemsg
                    call_oz(GN_Sop)               ; display "(None)"
                    pop  af
                    ret


; ***************************************************************************************
;
.DispCardSize
                    ld   hl,selwin1
                    call_oz(GN_Sop)
                    ld   hl,ramsize
                    call_oz(GN_Sop)
                    ld   a,(cardsize)
                    ld   h,0
                    ld   l,a
                    call m16                      ; cardsize * 16 (K)
                    ld   b,h
                    ld   c,l
                    ld   hl,2
                    call DispIntAscii
                    ld   a,'K'
                    call_oz(OS_Out)
                    ld   a,')'
                    call_oz(OS_Out)
                    ret


; ***************************************************************************************
;
.DispFreeSpaceInfo  
                    ld   hl, freespmsg
                    call_oz(GN_Sop)
                    call_oz(Gn_Nln)
                    ld   hl, freespace
                    call DispIntAscii
                    ld   hl, bytesmsg
                    call_oz(GN_Sop)
                    call_oz(GN_Nln)

                    ld   a,'('
                    call_oz(OS_Out)

                    xor  a                   
                    ld   b,a
                    ld   c,a
                    ld   h,a
                    ld   a,(cardsize)
                    ld   l,a
                    ld   de,16384
                    call_oz(GN_M24)               ; TotalBytes = <cardsize> * 16384

                    push hl
                    ld   d,0
                    ld   e,b
                    ld   hl,(freespace+2)
                    exx
                    pop  de
                    ld   hl,(freespace)
                    exx
                    ld   bc,0
                    fpp  (FP_DIV)                 ; FreeSpace / TotalBytes
                    ld   b,0
                    ld   de,0
                    exx
                    ld   de,100
                    exx
                    fpp  (FP_MUL)                 ; FreeSpace / TotalBytes * 100 (%)

                    ld   de,ascbuf
                    exx
                    ld   d,0
                    ld   e,4
                    exx
                    fpp  (FP_STR)
                    xor  a
                    ld   (de),a

                    ld   hl, ascbuf
                    call_oz(GN_Sop)               ; display free space in %

                    ld   a,'%'
                    call_oz(OS_Out)
                    ld   a,')'
                    call_oz(OS_Out)
                    ret


; ***************************************************************************************
;
.GetFreeSpace
                    ld   a,(slotno)               ; scan slot x
                    call RamDevFreeSpace
                    ret  c

                    ld   (cardsize),a             ; size of card in 16K banks...
                    ld   b,e                      ; store free space in bytes...
                    ld   c,0
                    ld   e,d
                    ld   d,0                      ; <free pages> * 256 bytes
                    ld   (freespace),bc
                    ld   (freespace+2),de         ; low byte, high byte sequense
                    cp   a
                    ret


; ***************************************************************************************
;
.DispFreeRamMap
                    ld   a,(slotno)
                    rrca
                    rrca                          ; slot number converted to bottom bank
                    or   a
                    jr   nz, external_slot
                         ld   a,$21               ; bottom bank in slot 0 for MAT is $21
.external_slot
                    ld   b,a                      ; get bank of memory allocation table (MAT)
                    ld   c,1                      ; (bottom of RAM card)
                    call MemDefBank               ; and bind into segment 1.

                    ld   a,(cardsize)             ; size of card in 16K banks...
                    ld   b,a                      ; actual number of banks
                    ld   hl,$4100                 ; data start at $0100
                    ld   c,b                      ; parse table of B(anks) * 64 pages

                    exx
                    ld   hl,(base_graphics)       ; ptr. to current 8x8 matrix
                    ld   bc,0                     ; row counter in 8x8 matrix (0 - 7)
                    ld   d,@10000000              ; column bit in 8x8 matrix (begin with leftmost)
                    exx
.card_scan_loop                              
                    ld   b,64                     ; total of pages in a bank...
.bank_scan_loop
                    ld   a,(hl)
                    inc  hl
                    or   (hl)                     ; must be 00 if free
                    inc  hl
                    call nz,plot_usedpage         ; page used, plot a pixel in map...
                    call update_pixelptr          ; prepare for next pixel position
                    djnz bank_scan_loop
                    dec  c
                    jr   nz, card_scan_loop
                    ret
.plot_usedpage      
                    exx
                    push hl
                    add  hl,bc                    ; ptr to current row in matrix
                    ld   a,(hl)                   ; get current row of matrix
                    or   d                        
                    ld   (hl),a                   ; "plot" point identifying used page
                    pop  hl
                    exx
                    ret
.update_pixelptr    
                    exx
                    inc  c                        ; next row of matrix...
                    bit  3,c
                    call nz,new_column
                    exx
                    ret
.new_column         
                    rrc  d                        ; in next column
                    call c,next_matrix
                    ld   c,0                      ; begin at first row
                    ret
.next_matrix        
                    add  hl,bc                    ; in next matrix
                    ret


; ***************************************************************************************
;
.DispCardSizeColumn
                    ld   hl, selwin2
                    call_oz(Gn_Sop)               ; select (and clear) window #2
                    ld   hl, rightjustify         ; window "2", right justify, 
                    call_oz(Gn_Sop)               ; no cursor no scrolling

                    ld   a,(cardsize)
                    ld   d,a                      ; B = card size (in 16K banks)
                    ld   e,0                      ; X = 0
.disp_k_loop
                    ld   a,d
                    inc  a
                    dec  a
                    ret  z                        ; while B > 0
                         sub  8                   ;    if B-8 < 0 then
                         jr   nc, larger_128K
                         ld   c,d                 ;         i = B
                         jr   disp_k              ;    else
.larger_128K             ld   c,8                 ;         i = 8
.disp_k                  
                         ld   a,e
                         add  a,c
                         ld   e,a                 ;    X = X + i
                         ld   a,d
                         sub  c
                         ld   d,a                 ;    B = B - i

                         ld   h,0
                         ld   l,e
                         call m16                 ;    X*16
                         ld   b,h
                         ld   c,l
                         ld   hl,2                
                         call DispIntAscii        ;    print str$(X*16) + "K"
                         ld   hl, kb
                         call_oz(Gn_Sop)
                    jr   disp_k_loop              ; end while


; ***************************************************************************************
;
; Multiply HL * 16, result in HL.
;
.m16                add  hl,hl
                    add  hl,hl
                    add  hl,hl
                    add  hl,hl
                    ret


; ****************************************************************************
;
; Convert integer in HL (or BC) to Ascii string, which is written to (AscBuf) 
; and null-terminated.
;
.DispIntAscii
                    push af
                    push de
                    xor  a
                    ld   de,ascbuf
                    push de
                    call_oz(Gn_Pdn)
                    xor  a
                    ld   (de),a
                    pop  hl
                    call_oz(Gn_Sop)               ; display integer
                    pop  de
                    pop  af
                    ret


; ***********************************************************************
; Fetch a system parameter:
;
; BC = Parameter code
; A = max number of bytes to be read
; DE = Buffer to write bytes
;
; Returns A = bytes actually read
.FetchParameter
                    push de                         ; save pointer to buffer
                    call_oz (OS_Nq)
                    pop  de
                    ret


; ***************************************************************************************
;
; Various string constants
;
.rightjustify       defm 1, "2JR", 1,  "2+T", 0
.kb                 defm "K ", 13, 10, 0
.ramdev             defm 1, "2H1", 1, "2JN", 1, "3@", 32+1, 32+0, 1, "2+C:RAM.", 0
.selwin1            defm 1, "2C1", 0
.selwin2            defm 1, "2C2", 0
.nonemsg            defm 1, "3@", 32+8, 32+0, "(None)", 0
.ramsize            defm 1, "3@", 32+8, 32+0, "(", 0
.freespmsg          defm 1, "2JC", 1, "3@", 32+0, 32+2, 1, "TFREE SPACE", 1, "T", 0
.bytesmsg           defm " bytes", 0

.FreeRam_topics     DEFB 0

; 'INFO' topic
.freeram_info_topic DEFB freeram_info_topic_end - freeram_info_topic
                    DEFM "INFO"
                    DEFW 0
                    DEFB @00000010
                    DEFB freeram_info_topic_end - freeram_info_topic
.freeram_info_topic_end

                    DEFB 0

; ********************************************************************************************************************
;
.FreeRam_commands   DEFB 0

.FreeRam_info1      DEFB FreeRam_info1_end - FreeRam_info1
                    DEFW 0                                                      ; command code, keyboard sequense
                    DEFM "About"
                    DEFB (inf_cmd1_help - FreeRam_help) / 256                   ; high byte of rel. pointer
                    DEFB (inf_cmd1_help - FreeRam_help) % 256                   ; low byte of rel. pointer
                    DEFB $10
                    DEFB FreeRam_info1_end - FreeRam_info1
.FreeRam_info1_end
                    DEFB 0

.FreeRam_help       
                    defm $7F, "Release V1.0", $7F
                    defm "Implemented by G.Strube, June 1998", 0

.inf_cmd1_help      defb $7F
                    defm "FreeRam enables you to obtain the actual free space", $7F
                    defm "available on a particular RAM device. Further, it displays", $7F
                    defm "a graphical map of the used and free areas of the card.", $7F
                    defm "Each pixel represents 256 bytes. An enabled pixel (dark)", $7F
                    defm "identifies used space (file or system). Void pixels", $7F
                    defm "identifies free space. Select RAM device by slot number.", 0
