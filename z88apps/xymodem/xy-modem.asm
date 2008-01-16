
; *************************************************************************************
; XY-Modem popdown
; (C) Dennis Groning (dennisgr@algonet.se) 1999-2008
;
; XY-Modem is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; XY-Modem is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with XY-Modem;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
; *************************************************************************************

module XY-Modem

INCLUDE "error.def"
INCLUDE "director.def"
INCLUDE "fileio.def"
INCLUDE "saverst.def"
INCLUDE "stdio.def"
INCLUDE "integer.def"
INCLUDE "memory.def"
INCLUDE "serintfc.def"
INCLUDE "blink.def"
INCLUDE "bastoken.def"
INCLUDE "dor.def"
INCLUDE "fpp.def"
INCLUDE "time.def"

DEFC debug=0

;Structure defs
;   DEFC safe_ws = 1+1024+2+4+1+1+1
;   DEFC ram_vars  = $1FFE - safe_ws
    DEFC ram_vars  = $2000
    
DEFVARS ram_vars
{
    fname_buf   ds.b 1
    data_buf0   ds.b 128
    data_buf1   ds.b 1024-128
    oct         ds.b 11             ;4176241405
    filesize    ds.l 1              ;
    bytes       ds.w 1
    blocks      ds.w 1
    time        ds.b 3              ;   48002 /     64 = --+
    date        ds.b 3              ;  255751 - 253D8C =   |
    ;days       ds.l 1              ;    19C5 *  15180 =   |
    seconds     ds.l 1              ;21F93780 +            |
    ;seconds1   ds.l 1              ;     B85 =          <-+
    ;seconds2   ds.l 1              ;21F94305
    next_pos    ds.w 1              ;    2014
    wild_handle ds.w 1
    retries     ds.b 1
    blk         ds.b 1
    state       ds.b 3
    fname_buf1  ds.b 52
}

DEFC state_prg = 0
DEFC state_rx  = 1
DEFC state_tx  = 2

;state_prg control bit flags
    DEFC crc=0
    DEFC block1k=1
    DEFC ymodem=2
    DEFC g=3
    DEFC end_of_file=4
    DEFC crc_trans=5
    DEFC header=6
    DEFC file_open=7
;state_rx control bit flags
;   DEFC block1k=1
    DEFC date_rx=5
;state_tx control bit flags
    DEFC escape=5

;Program start
;   org $C000
    org $10000 - 3372

.card_start

;DEFS  $4000 - 1775

;----------------------------------------------------------------------

.app_entry
    ;CALL $8000
    CALL app_start
    SCF
    RET

.app_start
    XOR A
    LD B,A
    LD HL,error_handler
    CALL_OZ(os_erh)
;   LD A,sc_ena    
;   CALL_OZ(os_esc)
    CALL app_main

.kill
    CALL file_close
    CALL hw_close_com
    XOR A
    CALL_OZ(os_bye)
    
.error_handler
;err_fatal
    RET Z
;err_quit
    CP rc_quit
    JR Z,kill
;err_esc
;   CP rc_esc        
;   JR NZ,err_susp   
;   LD A,sc_ack      
;   CALL_OZ(os_esc)  
;   CALL file_close  
;   LD A,rc_esc      
;   JR ret_err       
.err_susp
    CP rc_susp
    JR NZ,err_eof
    JR ret_err
.err_eof
    CP rc_eof
    JR NZ,report_err
    JR ret_err
.report_err
    CALL_OZ(gn_nln)      
    CALL_OZ(gn_esp)      
    CALL_OZ(gn_soe)      
;   CALL_OZ(gn_nln)  
;   CALL_OZ(gn_err)
.ret_err
    CP A
    RET

.app_main
    if basic
        LD HL,name_str                                         
        call_oz(dc_nam)              ;name current application 
    endif

    LD IY,state+state_prg
    call load_cfg

    LD HL,window_init
    CALL_OZ(gn_sop)

    call hw_open_com

;----------------------------------------------------------------------

    XOR A
    LD B,A
    LD HL,fname_buf     ;Address of input buffer
    LD C,51
    LD DE,name
    LD A,sr_rpd             ;Read mailbox
    CALL_OZ(os_sr)
    JR NC,show_sending
    LD A,ff
    CALL_OZ(os_out)
    ;JR main_menu
    JR no_new_line_first_time   ;991216

;----------------------------------------------------------------------

.show_sending
    LD HL,xmodem_str
    BIT ymodem,(IY+state_prg)
    JR Z,not_ymodem_send
    LD HL,ymodem_str
.not_ymodem_send
    CALL_OZ(gn_sop)
    BIT block1k,(IY+state_prg)
    JR Z,not_block1k_send
    LD HL,block1k_str
    CALL_OZ(gn_sop)
.not_block1k_send
    LD HL,sending
    CALL_OZ(gn_sop)
    CALL send_file

;----------------------------------------------------------------------

.main_menu
    CALL ei_tick
    CALL file_close
    CALL_OZ(gn_nln)              ;new line  991216
.no_new_line_first_time         ;991216
    LD HL,xmodem_str
    BIT ymodem,(IY+state_prg)
    JR Z,not_ymodem
    LD HL,ymodem_str
.not_ymodem
    CALL_OZ(gn_sop)
    LD HL,checksum_str
    BIT crc,(IY+state_prg)
    JR Z,not_crc
    LD HL,crc_str
.not_crc
    CALL_OZ(gn_sop)
    BIT block1k,(IY+state_prg)
    JR Z,not_block1k
    LD HL,block1k_str
    CALL_OZ(gn_sop)
.not_block1k
;   BIT g,(IY+state_prg)
;   JR Z,not_g_option
;   LD HL,g_str
;   CALL_OZ(gn_sop)
;.not_g_option
    BIT ymodem,(IY+state_prg)
    JR Z,not_end_batch
    LD HL,end_batch_str
    CALL_OZ(gn_sop)
.not_end_batch
    LD HL,commands_str          ;address of menu string
    CALL_OZ(gn_sop)           ;write string

;----------------------------------------------------------------------

.read_char
    CALL_OZ(os_in)                ;read character from standard input
    JR C,read_char
;   JR NC,read_ok 
;   CP rc_esc     
;   RET Z         
;   JR read_char  
.read_ok
    CP esc
    JR Z,read_char      ;991217
    CP 209              ;Shift + Enter  991217
    RET Z
    CALL_OZ(os_out)
    ;CALL_OZ(gn_nln)    ;991216           ;new line
;to_upper
    cp 'z'+1
    jr nc,not_lower
    cp 'a'
    jr c,not_lower
    sub 'a'-'A'
.not_lower

;set_xmodem
    CP 'X'
    JR NZ,set_ymodem
    RES ymodem,(IY+state_prg)
    call save_cfg
    JR main_menu
.set_ymodem 
    CP 'Y'
    JR NZ,toggle_crc
    SET ymodem,(IY+state_prg)
    call save_cfg
    JR main_menu
; .toggle_ymodem 
;   LD A,(state+state_prg) 
;   XOR 2^ymodem 
;   LD (state+state_prg),A 
;   call save_cfg
;   jp main_menu 
.toggle_crc
    CP 'C'
    JR NZ,toggle_block1k
    LD A,(state+state_prg)
    XOR 2^crc
    LD (state+state_prg),A
    call save_cfg
    JP main_menu
.toggle_block1k
    CP 'K'
;   JR NZ,toggle_g
    JR NZ,batch
    LD A,(state+state_prg)
    XOR 2^block1k
    LD (state+state_prg),A
    call save_cfg
    JP main_menu
;.toggle_g
;   CP 'G'
;   JR NZ,batch
;   LD A,(state+state_prg)
;   XOR 2^g
;   LD (state+state_prg),A
;   call save_cfg
;   JP main_menu
.batch
    CP 'B'
    JR NZ,set_end_batch
;   JR receive_ymodem
.set_end_batch
    CP 'E'
    JR NZ,set_receive
    CALL send_end_batch
    JP main_menu
.set_receive
    CP 'R'
    JR NZ,set_send
    BIT ymodem,(IY+state_prg)
    JR Z,local_name
    CALL di_tick
    CALL receive_ymodem
    JP main_menu
.local_name
    CALL get_filename
    JP C,main_menu
    CALL di_tick
    CALL reset_file_info
    SET crc,(IY+state_rx)
    BIT crc,(IY+state_prg)
    JR NZ,receive_crc
    RES crc,(IY+state_rx)
.receive_crc
    CALL receive_file
    JP main_menu
.set_send
    CP 'S'
    JP NZ,main_menu
    CALL get_filename
    JP C,main_menu

;----------------------------------------------------------------------

    LD BC,51                ;Local buffer, length 51
    LD HL,fname_buf     ;Source
    ;LD E,L                 ;Destination
    ;LD D,H
    LD DE,fname_buf     ;Destination
    CALL_OZ(gn_fex)         ;expand a filename
    JP C,main_menu

    XOR A
    LD B,A
    LD HL,fname_buf     ;address of wildcard string
    CALL_OZ(gn_opw)
    LD (wild_handle),IX
.next_name
    LD DE,fname_buf         ;address of explicit file name buffer
    LD C,51
    LD IX,(wild_handle)
    CALL_OZ(gn_wfn)
    JR NC,send_next
    CALL_OZ(gn_wcl)
    JP main_menu
.send_next
    RES escape,(IY+state_tx)    ;991217
    CALL send_file
    BIT escape,(IY+state_tx)
    JP NZ,main_menu
;   LD A,vt
;   CALL_OZ(os_out)
    JP next_name

;----------------------------------------------------------------------

.get_filename
    LD DE,fname_buf     ;address of input buffer
    XOR A                   ;input mode 0
;   LD C,A                  ;cursor position
.read_line
    LD HL,file_str          ;address of filename prompt string
    CALL_OZ(gn_sop)         ;write string
    LD B,51                 ;length of input buffer
    CALL_OZ(gn_sip)         ;system input line routine
    JR NC,end_of_line
;   CP rc_esc     
;   JR Z,esc_line 
    CP rc_susp
    JR NZ,get_filename
    LD A,1
    JR read_line
 .end_of_line
    CP in_esc
    JR NZ,not_esc
.esc_line
    CALL_OZ(gn_nln)              ;new line
    SCF
    RET
.not_esc
;   CALL_OZ(gn_nln)              ;new line
;   LD A,B
;   CP 1
;   JR Z,get_filename
    XOR A
    LD B,A
    LD H,D
    LD L,E
    CALL_OZ(gn_prs)              ;parse filename
    RET NC
    ;CALL_OZ(gn_nln)      991216        ;new line
    JR get_filename

;----------------------------------------------------------------------

.reset_file_info
    ;max size in case no size sent
    LD DE,$FFFF
    LD (filesize+2),DE
    LD (filesize+0),DE
    ;max positive 32767 => max 4M filesize
    LD DE,$7FFF
    LD (blocks),DE
    ;no surplus bytes
    LD DE,0
    LD (bytes),DE
    ;in case no date sent
    RES date_rx,(IY+state_rx)
    RET

;----------------------------------------------------------------------

.receive_ymodem
    SET crc,(IY+state_rx)
    BIT crc,(IY+state_prg)
    JR NZ,crc_rx
    RES crc,(IY+state_rx)
.crc_rx
    LD A,0
    LD (blk),A                   ;block 0
    JP send_NAKs

.receive_ymodem_header
    LD A,(data_buf0)                                    
    CP 0                                                
    ;JP Z,quit_to_main          ;No filename - End of batch 
    ;JP Z,end_of_batch_quit_to_main
    JP Z,quit_to_main           ;No filename - End of batch     991216
    CALL reset_file_info
;find_file_name_nul_termination
    LD HL,data_buf0
    LD A,NUL
    LD BC,88                    ;enough
    CPIR
;zero_terminate_file_len_string
    LD (next_pos),HL            ;Start of file size string
    LD A,32                     ;space
    LD BC,8                     ;Max 9,999,999
    CPIR
    JP NZ,end_of_date_time_convert  ;if not found
    DEC HL
    XOR A
    LD (HL),A
;store file length
    LD HL,(next_pos)
    FPP(FP_VAL)                 ;Returns the numeric value of a string
    LD (filesize+2),HL
    EXX
    LD (filesize+0),hl
    EXX
    INC DE
    LD (next_pos),DE            ;Start of file date time

;   .temp_printout_start
;       ;LD BC,(seconds)
;       ;LD HL,2
;       LD HL,filesize
;       LD DE,data_buf1
;       ;XOR A
;       LD A,@10100001
;       CALL_OZ(gn_pdn)
;       JR C,temp_printout_end
;       EX DE,HL
;       LD (HL),0
;       LD HL,data_buf1
;       CALL_OZ(gn_sop)
;       CALL_OZ(gn_nln)
;   .temp_printout_end

CALL calc_blocks_and_bytes

;get_file_date_time_start
    LD DE,0
    LD (seconds+0),DE
    LD (seconds+2),DE
    LD DE,(next_pos)
.next_date_time_digit
    LD A,(DE)
    SUB '0'
    JP M,get_file_date_time_end
    SET date_rx,(IY+state_rx)
    LD B,3
.next_seconds_bit
    LD HL,seconds
    SLA (HL)
    INC HL
    RL (HL)
    INC HL
    RL (HL)
    INC HL
    RL (HL)
    DJNZ,next_seconds_bit
    LD HL,seconds
    OR (HL)
    LD (HL),A
    INC DE
    JR next_date_time_digit
.get_file_date_time_end

;  .temp_printout_start
;   ;LD BC,(seconds)
;   ;LD HL,2
;   LD HL,seconds
;   LD DE,data_buf1
;   ;XOR A
;   LD A,@10100001
;   CALL_OZ(gn_pdn)
;   JR C,temp_printout_end
;   EX DE,HL
;   LD (HL),0
;   LD HL,data_buf1
;   CALL_OZ(gn_sop)
;   CALL_OZ(gn_nln)
;  .temp_printout_end

;date
    LD HL,(seconds+2)
    EXX
    LD hl,(seconds+0)
    EXX
    LD C,0
    LD DE,1     ;(60*60*24)/$10000
    EXX
    LD de,20864 ;(60*60*24)%$10000
    EXX
    LD B,0
    FPP(fp_idv) ;get days since 1970-01-01
    JP C,end_of_date_time_convert
    LD DE,$0025
    EXX
    LD de,$3D8C
    EXX
    LD B,0
    FPP(fp_add) ;add days until 1970-01-01
    JR C,end_of_date_time_convert
    LD A,L
    LD (date+2),A
    EXX
    LD (date+0),hl
    EXX

;time
    LD HL,(seconds+2)
    EXX
    LD hl,(seconds+0)
    EXX
    LD C,0
    LD DE,1     ;(60*60*24)/$10000
    EXX
    LD de,20864 ;(60*60*24)%$10000
    EXX
    LD B,0
    FPP(fp_mod) ;get seconds since midnight
    JR C,end_of_date_time_convert

;   LD DE,data_buf1
;   EXX
;   LD d,0
;   LD e,10
;   EXX
;   FPP(fp_str) ;get string representation
;   XOR A
;   LD (DE),A
;   PUSH HL
;   LD HL,data_buf1
;   CALL_OZ(gn_sop)
;   CALL_OZ(gn_nln)
;   POP HL
;   LD C,0

    LD DE,0
    EXX
    LD de,100
    EXX
    LD B,0
    FPP(fp_mul) ;get centiseconds
    JR C,end_of_date_time_convert
    LD A,L
    LD (time+2),A
    EXX
    LD (time+0),hl
    EXX

;   LD DE,data_buf1
;   EXX
;   LD d,0
;   LD e,10
;   EXX
;   FPP(fp_str) ;get string representation
;   XOR A
;   LD (DE),A
;   PUSH HL
;   LD HL,data_buf1
;   CALL_OZ(gn_sop)
;   CALL_OZ(gn_nln)
;   POP HL
;   LD C,0

;   LD HL,time
;   CALL_OZ(gn_sdo)
    ;CALL_OZ(gn_nln)
.end_of_date_time_convert

.receive_file
    LD A,op_out                  ;open file/stream for output
    LD HL,data_buf0            ;address of file name string = fname_buf+1
    BIT ymodem,(IY+state_prg)
    JR NZ,not_manually_input_filename
    LD HL,fname_buf            ;address of file name string = fname_buf
.not_manually_input_filename
    CALL open_file
    ;JP C,quit_to_main
    JP C,could_not_open_file_quit_to_main
    SET end_of_file,(IY+state_prg)  ;?
    ;RES crc,(IY+state_rx)  ;?

    LD A,1
    LD (blk),A                   ;block 1

.send_NAKs
    CALL update_retries

.send_NAK
    LD HL,retries
    DEC (HL)
    JP Z,end_of_retries_quit_to_main

    CALL purge
    LD A,'C'
    ;BIT crc,(IY+state_prg)
    BIT crc,(IY+state_rx)
    JR NZ,nak_or_c_tx
.not_C
    LD A,NAK
.nak_or_c_tx
    CALL hw_txbt
    JP C,timeout_to_main

.receive_block
    if debug
        LD A,'1'        
        CALL_OZ(os_out) 
    endif
    RES block1k,(IY+state_rx)   ;?
    LD BC,128           ;reset buffer counter
    LD A,4
    CALL hw_rxbt
    JR C,send_NAK
    CP CAN
    JP Z,file_receive_canceled
    CP EOT
    JP Z,file_received
    CP SOH
    JR Z,receive_block_number
    CP STX
    JR NZ,send_NAK
    SET block1k,(IY+state_rx)   ;?
    LD BC,1024

.receive_block_number
    ;RES end_of_file,(IY+state_prg) ;?
    if debug
        LD A,'2'        
        CALL_OZ(os_out) 
    endif
    LD A,2
    call hw_rxbt
    JR C,send_NAK
    LD D,A
    LD A,(blk)
    CP D
    JR Z,receive_block_number_complement

.if_prev_block
    INC D
    CP D
    JP Z,prev_block
    JP out_of_sync_quit_to_main
;   JP send_NAK
.prev_block
    if debug
        LD A,'3'        
        CALL_OZ(os_out) 
    endif
    LD A,2
    call hw_rxbt
    JP C,send_NAK
    DEC A
    CPL                          ;complement block number
    LD D,A
    LD A,(blk)
    CP D
    JP NZ,bad_block_number_quit_to_main
    JP send_NAK

.receive_block_number_complement
    if debug
        LD A,'4'        
        CALL_OZ(os_out) 
    endif
    LD A,2
    call hw_rxbt
    JP C,send_NAK
    CPL                          ;complement block number
    LD D,A
    LD A,(blk)
    CP D
    JP NZ,send_NAK

    if debug
        ;EX AF,AF'
        LD A,'9'
        CALL_OZ(os_out) 
        ;EX AF,AF'
    endif

.receive_chars
    LD HL,data_buf0     ;reset buffer pointer
    LD DE,0             ;reset checksum

    if debug
        LD A,'5'
        CALL_OZ(os_out)
    endif
.receive_char               ;293 min,   / 3276800   ~= 0.1 ms
    LD A,2                  ;  7
    CALL hw_rxbt            ; 17 + 181 min, get byte with timeout
    JP C,send_NAK           ; 10
    LD (HL),A               ;  7
    BIT crc,(IY+state_rx)   ; 20    ;?
    JR NZ,proc_crc          ;  7/12
    ADD A,D                 ;  4
    LD D,A                  ;  4
    JP dec                  ; 10
.proc_crc
    CALL update_crc         ; 17
.dec
    CPI                     ; 16
    JP PE,receive_char      ; 10
;.receive_checksum
    if debug
        LD A,'6'        
        CALL_OZ(os_out) 
    endif
    LD A,2
    call hw_rxbt
    JP C,send_NAK
    CP D                          ;checksum or crc high byte
    JP NZ,send_NAK
    BIT crc,(IY+state_rx)   ;?
    JP Z,not_crc16
    if debug
        LD A,'7'        
        CALL_OZ(os_out) 
    endif
    LD A,2
    call hw_rxbt
    JP C,not_crc        ;?
    CP E                          ;crc low byte
    JP NZ,send_NAK
.not_crc16
    BIT file_open,(IY+state_prg)
    JP Z,ack_block      ;Ymodem header received
.buf_to_file
    LD BC,128
    LD DE,1
    BIT block1k,(IY+state_rx)   ;?
    JR Z,short_block_received
    LD BC,1024
    LD DE,8
.short_block_received
    LD HL,(blocks)
    OR A
    SBC HL,DE
    JP P,store_block
.partial_block
    LD HL,(blocks)
    LD H,L
    LD L,0
    SRL H
    RR L
    OR A
    LD BC,(bytes)
    ADC HL,BC
    PUSH HL
    POP BC
.store_block
    LD (blocks),HL
    LD DE,0
    LD HL,data_buf0
    CALL_OZ(os_mv)
    ;JP C,quit_to_main
    JP C,no_room_quit_to_main
.ack_block
    LD A,ACK
    call hw_txbt
    JP C,timeout_to_main
    BIT file_open,(IY+state_prg)    ;?
    JP Z,receive_ymodem_header
    LD A,(blk)
    INC A
    LD (blk),A
    AND 7
    CP 1
    JR NZ,rec_3
    LD A,'|'
    JP show_rec
.rec_3
    CP 3
    JR NZ,rec_5
    LD A,'\'
    JP show_rec
.rec_5
    CP 5
    JR NZ,rec_7
    LD A,'-'
    JP show_rec
.rec_7
    CP 7
    JR NZ,rec_even
    LD A,'/'
    JP show_rec
.rec_even
    LD A,BS
.show_rec
    CALL_OZ(os_out)            ;write character to standard output
    CALL update_retries

    JP receive_block

.file_received
    LD A,ACK
    CALL hw_txbt
    JP C,timeout_to_main
;   CALL_OZ(gn_nln)            ;new line (AF)
    LD HL,clear_prog_ind
    CALL_OZ(gn_sop)
    CALL file_close
    BIT ymodem,(IY+state_prg)
    ;JP NZ,receive_ymodem
    ;RET
    RET Z
    BIT date_rx,(IY+state_rx)
    JP Z,receive_ymodem

    LD HL,fname_buf1
    LD B,0
    LD DE,fname_buf1
    LD C,51
    LD A,op_dor
    CALL_OZ(gn_opf)
    JP C,receive_ymodem
    ;JP C,could_not_open_dor    ?

    LD A,dr_wr
    LD B,dt_upd
    LD C,6
    LD DE,time
    CALL_OZ(os_dor)

    LD A,dr_fre
    CALL_OZ(os_dor)

    JP receive_ymodem

.file_receive_canceled
    if debug
        LD A,'8'        
        CALL_OZ(os_out) 
    endif
    LD A,2                    ;timeout 1 second
    CALL hw_rxbt            ;get byte with timeout
    JP C,send_NAK
    CP CAN
    JP NZ,send_NAK
    JP cancel_to_main

.purge
    LD A,1
    CALL hw_rxbt 
    JR NC,purge
    if debug
        LD A,'0'        
        CALL_OZ(os_out)
    endif
    RET

.cancel
    CALL purge
    LD B,8
.can_again
    LD A,can                 
    CALL hw_txbt        ;CAN 
    RET C
    DJNZ,can_again
    ;LD A,can                 
    ;CALL hw_txbt       ;CAN 
    RET                      

.update_retries
    LD A,11
    LD (retries),A
    RET

.update_crc
    XOR D
    LD D,A
    LD A,B
    EX AF,AF'
    LD B,8
.crc_next
    SLA D
    JR C,ex_or
    SLA E
    JR NC,no_ex_or
    SET 0,D
.no_ex_or
    DJNZ crc_next
    EX AF,AF'
    LD B,A
    RET
.ex_or
    LD A,D
    XOR $10
    LD D,a
    SLA E
    JR NC,no_carry_to_H
    SET 0,D
    .no_carry_to_H
    LD a,E
    XOR $21
    LD E,a
    JP no_ex_or
.shift_carry_to_H
    ;LD A,D
    ;ADD A,1
    ;LD D,A
    ;SET 0,D
    ;RET

.calc_blocks_and_bytes
    ;   76543210 76543210 76543210 76543210
    ;                               1111111     bytes
    ;             1000000 00000000 00000000     4M
    ;   11111111 11111111 11111111 10000000     128 byte blocks
;store_bytes
    LD A,(filesize+0)
    AND 127
    LD (bytes),A
    XOR A
    LD (bytes+1),A
;store_blocks
    LD HL,filesize
    RL (HL)
    INC HL
    RL (HL)
    INC HL
    RL (HL)
    LD HL,(filesize+1)
    LD (blocks),HL
    RET

.send_file

    if debug
        LD A,'a'
        CALL_OZ(os_out) 
    endif

    LD HL,fname_buf     ;address of file name string
    ;LD D,H                ;explicit name buffer
    ;LD E,L
    LD DE,fname_buf     ;address of explicit name buffer
    LD C,51                ;size of explicit name buffer
    LD B,0                 ;HL string is local
    LD A,op_dor            ;get dor handle
    CALL_OZ(gn_opf)
    JP C,could_not_open_dor

    LD A,(fname_buf+2)
    CP 'A'
    JR Z,ok_ram_device      ;Else not :RAM.? 991215
    LD A,dr_fre            ;free DOR handle
    CALL_OZ(os_dor)
    RET
.ok_ram_device

    XOR A
    LD (DE),A               ;Terminate filename
    INC DE
    LD (next_pos),DE        ;Where to write file length
    
    if debug
        LD A,'b'
        CALL_OZ(os_out) 
    endif

    LD A,dr_rd             ;read DOR record
    LD B,dt_ext               ;read file size
    LD C,4                 ;maximum size of information to return
    LD DE,filesize        ;store returned info in filesize
    CALL_OZ(os_dor)

;   JR NC,ok_ram_device     ;991215
;   LD A,dr_fre            ;free DOR handle
;   CALL_OZ(os_dor)
;   JP quit_to_main
; 
; .ok_ram_device

    LD HL,filesize
    LD DE,(next_pos)
    ;XOR A                  ;Format
    LD A,1
    CALL_OZ(gn_pdn)         ;Write file size in buffer
    RET C
    EX DE,HL
    LD (HL),' '             ;Space delimiter before update datetime
    INC HL
    LD (next_pos),HL        ;Where to write update datetime

    if debug
        LD A,'c'
        CALL_OZ(os_out) 
    endif

    LD A,dr_rd             ;read DOR record
    LD B,dt_upd            ;read update information
    LD C,6                 ;maximum size of information to return
    LD DE,time             ;store returned info in time
    CALL_OZ(os_dor)

    if debug
        LD A,'d'
        CALL_OZ(os_out) 
    endif

    LD A,dr_fre            ;free DOR handle
    CALL_OZ(os_dor)

    if debug
        LD A,'e'
        CALL_OZ(os_out) 
    endif

    LD HL,(date+2)
    LD H,0                  ;MSB
    EXX
    LD hl,(date+0)          ;LSW
    EXX
    LD C,0                  ;Exp=0 > int

    LD DE,$0025             ;MSW
    EXX
    LD de,$3D8C             ;LSW
    EXX
    LD B,0                  ;Exp=0 > int

    FPP(fp_sub)         ;Subtract days for 1970-01-01

    if debug
        LD A,'f'
        CALL_OZ(os_out) 
    endif

    LD DE,$0001             ;MSW
    EXX
    LD de,$5180             ;LSW
    EXX
    LD B,0                  ;Exp=0 > int

    FPP(fp_mul)         ;Multiply by seconds per day

    if debug
        LD A,'g'
        CALL_OZ(os_out) 
    endif

    LD (seconds+2),HL       ;Store date
    EXX
    LD (seconds+0),hl
    EXX

    LD HL,(time+2)
    LD H,0                  ;MSB
    EXX
    LD hl,(time+0)          ;LSW
    EXX
    LD C,0                  ;Exp=0 > int

    LD DE,0                 ;MSW
    EXX
    LD de,100               ;LSW
    EXX
    LD B,0                  ;Exp=0 > int

    FPP(fp_div)         ;Divide by 10ms per second
    FPP(fp_fix)         ;Round to integer

    if debug
        LD A,'h'
        CALL_OZ(os_out) 
    endif

    LD DE,(seconds+2)
    EXX
    LD de,(seconds+0)
    EXX
    LD B,0                  ;Exp=0 > int

    FPP(fp_add)         ;Add date

    if debug
        LD A,'i'
        CALL_OZ(os_out) 
    endif

    EX DE,HL

    LD A,D                  ;Get 3 bits for every octal digit
    SRL A
    SRL A
    SRL A
    SRL A
    SRL A
    SRL A
    ;AND @00000011
    ADD A,'0'
    LD (oct+0),A

    LD A,D
    SRL A
    SRL A
    SRL A
    AND @00000111
    ADD A,'0'
    LD (oct+1),A

    LD A,D
    AND @00000111
    ADD A,'0'
    LD (oct+2),A

    LD A,E
    SRL A
    SRL A
    SRL A
    SRL A
    SRL A
    ;AND @00000111
    ADD A,'0'
    LD (oct+3),A

    LD A,E
    SRL A
    SRL A
    AND @00000111
    ADD A,'0'
    LD (oct+4),A

    LD A,E
    SLA A
    AND @00000110
    LD (oct+5),A

    EXX
    EX DE,HL

    LD A,d
    SRL A
    SRL A
    SRL A
    SRL A
    SRL A
    SRL A
    SRL A
    ;AND @00000001
    LD HL,oct+5
    ADD A,(HL)
    ADD A,'0'
    LD (oct+5),A

    LD A,d
    SRL A
    SRL A
    SRL A
    SRL A
    AND @00000111
    ADD A,'0'
    LD (oct+6),A

    LD A,d
    SRL A
    AND @00000111
    ADD A,'0'
    LD (oct+7),A

    LD A,d
    SLA A
    SLA A
    AND @00000100
    LD (oct+8),A

    LD A,e
    SRL A
    SRL A
    SRL A
    SRL A
    SRL A
    SRL A
    ;AND @00000011
    LD HL,oct+8
    ADD A,(HL)
    ADD A,'0'
    LD (oct+8),A

    LD A,e
    SRL A
    SRL A
    SRL A
    AND @00000111
    ADD A,'0'
    LD (oct+9),A

    LD A,e
    AND @00000111
    ADD A,'0'
    LD (oct+10),A

    ;EXX
    ;EX DE,HL       ;Nessesary? 

    if debug
        LD A,'j'
        CALL_OZ(os_out) 
    endif

    LD HL,oct                               
    LD DE,(next_pos)                        
    LD BC,11
    LDIR                ;Move date and time 

    if debug
        LD A,'k'
        CALL_OZ(os_out) 
    endif

    PUSH DE                                      
    POP HL                                       
    LD (HL),0           ;Zero padd rest of frame 
    INC DE                                       
    LD BC,128           ;and a little more       
    LDIR                                         

    if debug
        LD A,'l'
        CALL_OZ(os_out) 
    endif

    CALL calc_blocks_and_bytes
    LD HL,bytes
    XOR A
    ADD A,(HL)
    JR Z,only_full_blocks_to_send
    LD HL,(blocks)
    INC HL
    LD (blocks),HL
.only_full_blocks_to_send

    SET block1k,(IY+state_tx)
    BIT block1k,(IY+state_prg)
    JR NZ,block1k_tx
    RES block1k,(IY+state_tx)
.block1k_tx

    LD A,op_in
    LD HL,fname_buf            ;address of file name string
    CALL open_file               ;open file/stream for input
    ;JP C,quit_to_main
    JP C,could_not_open_file_quit_to_main
    RES end_of_file,(IY+state_prg)  ;?
    BIT ymodem,(IY+state_prg)
    JP Z,not_ymodem_header
.ymodem_header
    SET header,(IY+state_prg)   ;?
    XOR A
    LD (blk),A                   ;First block

    if debug
        LD A,'m'
        CALL_OZ(os_out) 
    endif

.wait_for_NAK0
    LD A,31                 ;timeout 60 seconds
    CALL hw_rxbt
    JP C,timeout_to_main
    RES crc_trans,(IY+state_prg)    ;?
    RES g,(IY+state_prg)    ;?
    CP NAK
    JP Z,send_128
    SET crc_trans,(IY+state_prg)    ;?
    CP 'C'
    JP Z,send_128
    CP 'G'
    SET g,(IY+state_prg)    ;?
    JP Z,send_128
    JP wait_for_NAK0

    if debug
        LD A,'n'
        CALL_OZ(os_out) 
    endif

.not_ymodem_header
    RES header,(IY+state_prg)   ;?
    LD A,1
    LD (blk),A                   ;First block

.wait_for_NAK1
    if debug
        LD A,'A'        
        CALL_OZ(os_out) 
    endif
    LD A,31                 ;timeout 60 seconds
    CALL hw_rxbt
    JP C,timeout_to_main

    CP CAN
    JR NZ,is_NAK1
    if debug
        LD A,'B'        
        CALL_OZ(os_out) 
    endif
    LD A,2                    ;timeout 1 second
    CALL hw_rxbt            ;get byte with timeout
    JR C,wait_for_NAK1
    CP CAN
    JR NZ,is_NAK1
    JP cancel_to_main

.is_NAK1
    RES crc_trans,(IY+state_prg)    ;?
    RES g,(IY+state_prg)    ;?
    CP NAK
    JP Z,send_block
    SET crc_trans,(IY+state_prg)    ;?
    CP 'C'
    JP Z,send_block
    CP 'G'
    SET g,(IY+state_prg)    ;?
    JP Z,send_block
    JP wait_for_NAK1

.wait_to_send
    if debug
        LD A,'C'        
        CALL_OZ(os_out) 
    endif
    BIT g,(IY+state_prg)            ;20
    JR Z,not_g              ;Ymodem-G
    ;LD A,0                 ;timeout 0 seconds
    ;CALL hw_rxbt            ;get byte with timeout
    CALL hw_rxb             ;get byte without timeout   991226
    JP C,send_next_block    ;? 991214
    JR is_can
.not_g
    LD A,31                 ;timeout 60 seconds
    CALL hw_rxbt            ;get byte with timeout
    JP C,timeout_to_main
.is_can
    CP CAN
    JR NZ,is_NAK
    if debug
        LD A,'D'        
        CALL_OZ(os_out) 
    endif
    LD A,2                    ;timeout 1 second
    CALL hw_rxbt            ;get byte with timeout
    JR C,wait_to_send   ;?
    CP CAN
    JR NZ,wait_to_send
    JP cancel_to_main

.is_NAK
    CP NAK
    JR NZ,is_ACK
    JP send_block

.is_ACK
    CP ACK
    JR NZ,wait_to_send
    BIT header,(IY+state_prg)           ;20 ;?
    ;JP Z,not_ymodem_header     ;991214
    JP NZ,not_ymodem_header

;   LD A,(data_buf0)                                
;   CP 0                                            
;   JP Z,quit_to_main   ;No filename - End of batch 

.send_next_block
    BIT end_of_file,(IY+state_prg)          ;20 ;?
    JP NZ,send_EOTs
    LD A,(blk)
    INC A
    LD (blk),A
    CALL indicate

.send_block
;file_to_buf
    LD BC,128               ;buffer counter
    BIT block1k,(IY+state_tx)           ;20 ;?
    JR Z,mv_to_send_buffer

    OR A                    ;991213
    LD HL,(blocks)
    LD DE,8
    SBC HL,DE
    LD (blocks),HL
    JP P,mv_1k_to_send_buffer
    RES block1k,(IY+state_tx)
    JR mv_to_send_buffer
.mv_1k_to_send_buffer

    LD BC,1024              ;buffer counter
.mv_to_send_buffer
    LD HL,0
    LD DE,data_buf0
    CALL_OZ(os_mv)
    JR NC,send_it
    CP rc_eof
    JP NZ,send_it
;padd_chars
    SET end_of_file,(IY+state_prg)  ;?
    LD HL,data_buf0
    LD A,H
    CP D
    JR NZ,padd_chars
    LD A,L
    CP E
    JR NZ,padd_chars
    JP send_EOTs
.padd_chars
    EX DE,HL
    XOR A
.padd_char
    LD (HL),A
    CPI
    JP PE,padd_char
.send_it
    LD A,stx
    LD BC,1024              ;buffer counter
    BIT block1k,(IY+state_tx)           ;20 ;?
    JR NZ,not_soh_to_send
.send_128
    LD A,soh
    LD BC,128               ;buffer counter
.not_soh_to_send
    CALL hw_txbt
    JP C,timeout_to_main
    LD A,(blk)                   ;block number
    CALL hw_txbt
    JP C,timeout_to_main
    CPL                          ;complement block number
    CALL hw_txbt
    JP C,timeout_to_main

;send_chars
    LD DE,0                 ;reset checksum/crc
    LD HL,data_buf0         ;reset buffer pointer
.send_char
    LD A,(HL)
    CALL hw_txbt
    JP C,timeout_to_main
    BIT crc_trans,(IY+state_prg)    ;?
    JR NZ,send_crc          ;  7/12
    ADD A,D                 ;  4
    LD D,A                  ;  4
    JP send_char_end        ; 10
.send_crc
    CALL update_crc         ; 17
.send_char_end
    CPI
    JP PE,send_char
;checksum
    LD A,D
    CALL hw_txbt             ;send checksum or crc high byte
    JP C,timeout_to_main
    BIT crc_trans,(IY+state_prg)    ;?
    JP Z,all_chars_sent
    LD A,E
    CALL hw_txbt             ;send crc low byte
    JP C,timeout_to_main
.all_chars_sent
    BIT header,(IY+state_prg)   ;?
    JP Z,wait_to_send
    BIT g,(IY+state_prg)            ;20
    JP Z,wait_to_send
    JP not_ymodem_header

.send_EOTs
;   CALL_OZ(gn_nln)            ;new line (AF)
;   LD HL,clear_prog_ind 
;   CALL_OZ(gn_sop)      
    LD L,10

.send_EOT
    LD A,EOT
    CALL hw_txbt             ;send EOT
    JR C,timeout_to_main
    if debug
        LD A,'E'        
        CALL_OZ(os_out) 
    endif
    LD A,4                 ;timeout 10 seconds
    CALL hw_rxbt
    JR C,send_EOT_again
    CP ACK
    JR Z,clear_prog_ind_quit_to_main
    ; JR NZ,send_EOT_again  ;991216
    ; LD HL,clear_prog_ind
    ; CALL_OZ(gn_sop)
    ; CALL file_close
    ; RET

.send_EOT_again
    DEC L
    JR NZ,send_EOT         ;max 10 times
    JR no_ack_on_eot_quit_to_main

.send_end_batch
    LD A,soh
    CALL hw_txbt
    RET C
    XOR A
    CALL hw_txbt
    RET C
    DEC A
    CALL hw_txbt
    RET C
    INC A
    LD BC,130
.more_end_batch
    CALL hw_txbt
    RET C
    CPI
    JP PE,more_end_batch
    CALL purge               
    RET


.end_of_retries_quit_to_main
    CALL cancel
    LD HL,end_of_retries_str
    JR message_out_back_to_main

.out_of_sync_quit_to_main
    CALL cancel
    LD HL,out_of_sync_str
    JR message_out_back_to_main

.bad_block_number_quit_to_main
    CALL cancel
    LD HL,bad_block_number_str
    JR message_out_back_to_main

 .clear_prog_ind_quit_to_main
    LD HL,clear_prog_ind
    JR message_out_back_to_main

.no_ack_on_eot_quit_to_main
    LD HL,no_ack_on_eot_str
    JR message_out_back_to_main

.cancel_to_main
    LD HL,can_str
    JR message_out_back_to_main

.could_not_open_dor
    LD HL,could_not_open_dor_str
    JR message_out_back_to_main

.could_not_open_file_quit_to_main
    CALL cancel
    LD HL,could_not_open_file_str
    JR message_out_back_to_main

.timeout_to_main
    ;CALL cancel    991217
    LD HL,timeout_str
    JR Z,timed_out
    SET escape,(IY+state_tx)
    LD HL,escape_str
.timed_out
    CALL cancel
    JR message_out_back_to_main

; .end_of_batch_quit_to_main
;   LD HL,end_of_batch_str
;   JR message_out_back_to_main

.no_room_quit_to_main
    CALL cancel
    JR quit_to_main

.message_out_back_to_main
    CALL_OZ(gn_sop)
    ;JR quit_to_main

.quit_to_main
;991216 CALL_OZ(gn_nln)            ;new line (AF)
;   JP main_menu
    CALL file_close
    RET

.indicate
    AND 7
    CP 1
    JR NZ,send_3
    LD A,'|'
    JP show_send
.send_3
    CP 3
    JR NZ,send_5
    LD A,'/'
    JP show_send
.send_5
    CP 5
    JR NZ,send_7
    LD A,'-'
    JP show_send
.send_7
    CP 7
    JR NZ,send_even
    LD A,'\'
    JP show_send
.send_even
    LD A,BS
.show_send
    CALL_OZ(os_out)            ;write character to standard output
    RET

.load_cfg
    XOR A
    LD (state+state_prg),A
    ld a,op_in
    CALL open_cfg
    RET C
    CALL_OZ(os_gb)
    AND 2^crc|2^block1k|2^ymodem
    LD (state+state_prg),a
    CALL_OZ(gn_cl)             ;close file
    RET

.save_cfg
    LD A,op_out
    CALL open_cfg
    RET C
    LD A,(state+state_prg)
    AND 2^crc|2^block1k|2^ymodem
    CALL_OZ(os_pb)
    CALL_OZ(gn_cl)             ;close file
    RET

.open_cfg
    LD HL,cfg_file_str
    LD DE,fname_buf             ;address of explicit file name buffer
    LD C,51                      ;size of explicit file name buffer
    LD B,0                       ;HL string is local
    CALL_OZ(gn_opf)             ;open file
    RET

.file_close
    BIT file_open,(IY+state_prg)
    RET Z
    CALL_OZ(gn_cl)             ;close file
    RES file_open,(IY+state_prg)
    RET

.open_file
    ;LD HL,fname_buf+1            ;address of file name string
    LD DE,fname_buf             ;address of explicit file name buffer
    BIT date_rx,(IY+state_rx)
    JR Z,no_date0
    LD DE,fname_buf1            ;address of explicit file name buffer
.no_date0
    LD C,51                      ;size of explicit file name buffer
    LD B,0                       ;HL string is local
    CALL_OZ(gn_opf)             ;open file
    RET C
    SET file_open,(IY+state_prg)
    CALL_OZ(gn_nln)              ;new line
    XOR A
    LD (DE),A               ;Terminate filename
    INC DE
    LD (next_pos),DE        ;Where to read/write file length
    LD HL,fname_buf                ;address of explicit file name buffer
    BIT date_rx,(IY+state_rx)
    JR Z,no_date1
    ;LD DE,fname_buf1  991216   ;address of explicit file name buffer
    LD HL,fname_buf1            ;address of explicit file name buffer
.no_date1
    CALL_OZ(gn_sop)            ;write string (HL)
    LD HL,cursor_off
    CALL_OZ(gn_sop)            ;write string (HL)
;   CALL_OZ(gn_nln)            ;new line (AF)
    OR A
    RET

;  .is_esc                                                 
;   LD C,kbd                                               
;   LD B,0                  ;@01111111          ;A15       
;   IN A,(C)                                               
;   CP @11011111            ;D5                            
;   RET NZ                                                 
;   SCF                                                    
;   RET                     ;ESC                           

.hw_open_com

    LD C,BL_INT
    LD B,BLSC_PAGE
    LD A,(bc)
    RES BB_INTUART,a
    LD (bc),a
    OUT (c),a

;   XOR    A                                                                           
;   DEC    A                                                                           
;   OUT    (TXD),A         ;Clear TDRE interrupt                                       
;                                                                                      
;   LD     A,$BD           ;SET SHTW, UART RESET, ARTS, IRTS, BAUD=9600, RES LOOP      
;       LD C,rxc                                                                       
;   CALL update_port                                                                   
;                                                                                      
;   LD     A,$15           ;SET ATX, BAUD=9600, RES UTEST, IDCD, ICTS, ITX             
;       LD C,txc                                                                       
;   CALL update_port                                                                   
;                                                                                      
;   XOR    A                                                                           
;   DEC    A                                                                           
;   OUT    (UAK),A         ;Clear DCD, CTS interrupts                                  
;                                                                                      
;   IN     A,(RXD)         ;Clear RDRF interrupt                                       
;                                                                                      
;   XOR    A               ;DI DCDI, CTSI, TDRE, RDRF                                  
;       LD C,umk                                                                       
;   CALL update_port                                                                   
;                                                                                      
;   LD     A,$9D           ;SET SHTW, ARTS, IRTS, BAUD=9600, RES LOOP, UART RESET      
;       LD C,rxc                                                                       
;   CALL update_port                                                                   

;       ld c,rxc      
;       ld b,4        
;       ld a,(bc)     
;       set arts,a    
;       ld (bc),a     
;       out (c),a     

    RET

.di_tick
;   LD C,tmk       
;   LD B,4         
;   LD A,(BC)      
;   RES tick,A     
;   RES sec,A      
;   RES min,A      
;   LD (BC),A      
;   OUT (C),A      

    LD C,BL_INT
    LD B,BLSC_PAGE
    LD A,(bc)
    RES BB_INTTIME,a
    LD (bc),a
    OUT (c),a
    RET

.ei_tick
;   LD C,tmk       
;   LD B,4         
;   LD A,(BC)      
;   SET tick,A     
;   SET sec,A      
;   SET min,A      
;   LD (BC),A      
;   OUT (C),A      

    LD C,BL_INT
    LD B,BLSC_PAGE
    LD A,(bc)
    SET BB_INTTIME,a
    LD (bc),a
    OUT (c),a
    RET

; .update_port
;   LD B,4      
;   LD (BC),A   
;   OUT (C),A   
;   RET

.hw_close_com
;   LD C,rxc    
;   LD B,4      
;   LD A,(bc)   
;   RES arts,a  
;   LD (bc),a   
;   OUT (c),a   

    LD C,BL_INT
    LD B,BLSC_PAGE
    LD A,(bc)
    SET BB_INTUART,a
    LD (bc),a
    OUT (c),a

    LD L,si_sft
    CALL_OZ(os_si)
    RET

; .hw_rxbt                                              
;   ;Receive byte with timeout using hardware directly. 
;   ;In: 1<=A<=59, timeout=A+0-1 seconds.               
;   ;Out: A=byte received, Fc=1 if unsuccesful.         
;   ;Changed: AF....../..../.fbc....                    
;   ;Min time:               64                         
;   ;Cycle                   52                         
;   EXX                     ; 4                         
;   IN A,(uit)              ;11                         
;   BIT rdrf,A              ; 8                         
;   JR NZ,rx                ;12/7                       
;   LD bc,$FFFF             ;10     Timeout             
; .check_rdrf                                           
;   IN A,(uit)              ;11                         
;   BIT rdrf,A              ; 8                         
;   JR NZ,rx                ;12/7                       
;   CPI                     ;16                         
;   JP PE,check_rdrf        ;10                         
;   EXX                     ; 4                         
;   SCF                     ; 4                         
;   RET                     ;10                         
; .rx                                                   
;   EXX                     ; 4                         
;   IN A,(rxd)              ;11                         
;   OR A                    ; 4                         
;   RET                     ;10                         

.hw_rxb
    ;Receive byte without timeout using hardware directly. 
    ;Out: A=byte received, Fc=1 if unsuccesful.         
    ;Changed: AF....../..../.fbc....                    
    ;Min time:

    EXX                     ; 4                         
    IN A,(BL_UIT)           ;11                         
    BIT BB_UITRDRF,A        ; 8                         
    JR Z,rx_fail
    JR rx                                                   

.hw_rxbt
    ;Receive byte with timeout using hardware directly. 
    ;In: 1<=A<=59, timeout=A+0-1 seconds.               
    ;Out: A=byte received, Fc=1 if unsuccesful.         
    ;Changed: AF....../..../.fbc....                    
    ;Min time:              (181) 68                    
    ;Cycle 79

    EXX                     ; 4                         
    EX AF,AF'               ; 4
    LD b,0
.rx_quick                   ;34
    IN a,(BL_UIT)           ;11                         
    BIT BB_UITRDRF,a        ; 8                         
    JR NZ,rx                ;12/7                       
    DJNZ rx_quick           ;13/8
    EX AF,AF'               ; 4
    LD b,A                  ; 4     Timeout
    CALL get_timeout_sec    ;17 + min 96                
.rx_check_timeout
    IN A,(BL_TIM1)          ;11                         
.rx_get_s_again                                          
    LD c,A                  ; 4                          
    IN A,(BL_TIM1)          ;11                          
    CP c                    ; 4                          
    JR NZ,rx_get_s_again    ;12/7                        
    CP b                    ; 4                          
;   CALL check_timeout
    JR Z,rx_fail            ;12/7                       
.rx_kbd                                                    
    LD c,BL_KBD             ; 7                              
    IN A,(c)                ;12                              
    CP $FF                  ; 7                              
    JR NZ,rx_fail           ;12/7                        
.check_rdrf                                           
    IN A,(BL_UIT)           ;11                         
    BIT BB_UITRDRF,A        ; 8                         
    JR Z,rx_check_timeout   ;12/7                       
.rx                                                   
    EXX                     ; 4                         
    IN A,(BL_RXD)           ;11                         
    OR A                    ; 4                         
    RET                     ;10                         
.rx_fail
    EXX                     ; 4                         
    SCF                     ; 4                         
    RET                     ;10                         

.hw_txbt
    ;Transmit byte with timeout=31+0-1 seconds using hardware directly.
    ;In: A=byte to send
    ;Out: Fc=1 if unsuccesful
    ;Changed: .F....../..../afbc....

    EXX                     ; 4
    EX AF,AF'               ; 4
    LD b,0
.tx_quick                   ;34
;check_tdre
    IN a,(BL_UIT)
    BIT BB_UITTDRE,a
    JR NZ,tx
    DJNZ tx_quick           ;13/8
    LD b,31
    CALL get_timeout_sec
.tx_check_timeout
    IN A,(BL_TIM1)          ;11                         
.tx_get_s_again                                          
    LD c,A                  ; 4                          
    IN A,(BL_TIM1)          ;11                          
    CP c                    ; 4                          
    JR NZ,tx_get_s_again    ;12/7                        
    CP b                    ; 4                          
;   CALL check_timeout
    JR Z,tx_fail
.tx_kbd
    LD c,BL_KBD             ; 7
    IN a,(c)                ;12
    CP $FF                  ; 7
    JR NZ,tx_fail           ;12/7                       
;check_tdre
    IN a,(BL_UIT)
    BIT BB_UITTDRE,a
    JR Z,tx_check_timeout
.tx
    EX AF,AF'               ; 4
    LD b,6
    LD c,BL_TXD
    OUT (c),A
    EXX                     ; 4
    OR A
    RET
.tx_fail
    EXX                     ; 4
    ;EX AF,AF'              ; 4 Sacrifice preservation of A for timeout detection using Fz
    SCF
    RET

; .check_timeout                ;Min 78
;   CALL get_sec            ;17 + min 47
;   CP b                    ; 4
;   RET                     ;10

.get_timeout_sec            ;Min 96
    CALL get_sec            ;17 + min 47
    ADD a,b                 ; 4
    CP 60                   ; 7
    JR NC,sec_too_big       ; 7/12
    LD b,a                  ; 4
    RET                     ;10
.sec_too_big
    SUB 60                  ; 7
    LD b,a                  ; 4
    RET                     ;10

.get_sec                    ;Min (47) 41
    IN a,(BL_TIM1)          ;11
.get_sec_again
    LD c,a                  ; 4
    IN a,(BL_TIM1)          ;11
    CP c                    ; 4
;   JR NZ,get_sec_again     ; 7/12
;   RET                     ;10
    RET Z                   ; 5,11
    JP get_sec_again        ;10

.name                    DEFM "NAME", 0
.cfg_file_str            DEFM ":RAM.0/XY-Modem.cfg", 0
.xmodem_str              DEFM "Xmodem", 0
.ymodem_str              DEFM "Ymodem", 0
.checksum_str            DEFM "/Checksum", 0
.crc_str                 DEFM "/CRC", 0
.block1k_str             DEFM "-1K", 0
;.g_str                  DEFM "-G", 0
.sending                 DEFM ", sending file:", 0
.end_batch_str           DEFM ", E)nd batch", 0
.commands_str            DEFM ", R)eceive file or S)end file? ", SOH, "2+C", 0
;.file_str               DEFM CR, "Filename? ", 0
.file_str                DEFM CR, LF, "Filename? ", 0           ;991216
.can_str                 DEFM CR, LF, "Canceled", 0
.timeout_str             DEFM CR, LF, "Timeout", 0
.end_of_retries_str      DEFM CR, LF, "End of retries", 0
.out_of_sync_str         DEFM CR, LF, "Out of sync", 0
.bad_block_number_str    DEFM CR, LF, "Bad block number", 0
.no_ack_on_eot_str       DEFM CR, LF, "No ack on eot", 0
.clear_prog_ind          DEFM BS, SOH, "2C", 253, 0     ;CR & LF & 0
.could_not_open_dor_str  DEFM CR, LF, "Dor won't open", 0
.could_not_open_file_str DEFM CR, LF, "Could not open file", 0
.end_of_batch_str        DEFM CR, LF, "End of batch", 0
.escape_str              DEFM CR, LF, "Escape", 0

.window_init
    ;Set window 1, left 1, top 0, width 80, height 8, left and right vertical bars on.
    DEFB $01,$37,$23,$31,$21,$20,$70,$28,$81
    ;DEFB SOH,'7','#','1',' '+1,' '+0,' '+80,' '+8,129  

    ;Select and clear window 1.
    DEFB $01,$32,$43,$31
    ;DEFB SOH,'2','C','1'   

    ;Vertical scrolling and cursor on.
    DEFB $01,$33,$2B,$53,$43
    ;DEFB SOH,'3','+'S','C' 

    DEFB $00
.cursor_off
    DEFM "  ", SOH, "2-C", 0

.app_end

.dor
    DEFS 9
    DEFB $83,dor_end-dor_start
.dor_start
    DEFM "@", $12
    DEFW 0
    DEFB 'Y'
    DEFB 32
    DEFW $0000,$0000,$0000,app_entry
    DEFB $00,$00,$3E
    DEFB $3F
    DEFB at_ugly|at_popd,$0
    DEFM "H", $0C
    DEFW topic
    DEFB $3F
    DEFW commands
    DEFB $3F
    DEFW help
    DEFB $3F
    DEFS 3
    DEFM "N", 9, "XY-Modem", 0, $FF
.dor_end

.topic
    DEFW 0
.commands
    DEFW 0
.help
;      |         1         2         3         4         5         6 |
;      |1234567890123456789012345678901234567890123456789012345678901|
;      |                          XY-Modem                           |
    DEFM     "Version 1.1  Copyright (C) Dennis Groning 1993-99"     , DEL, SOH, 'T'
    DEFM   "File transfer using the Xmodem and Ymodem protocols."    , DEL
    DEFM           "Key X and Y selects Xmodem or Ymodem."           , DEL
    DEFM"Key C toggles Checksum/CRC, K toggles 128b/1kb block size." , DEL
    DEFM"For best performance use baud rate 38400 and Ymodem/CRC-1K.", DEL
    DEFM "On remote, use Ymodem-1K to send and Ymodem-G to receive." , DEL
    DEFM"Get the latest version at www.algonet.se/~dennisgr/z88.htm.", SOH, 'T', NUL

;   DEFM "Note that Xmodem-1K and Ymodem often implies use of CRC."  , DEL
;DEFS  $4000 - ASMPC - $40
;DEFS  $8000 - ASMPC - $40

.app_front_dor
    DEFS 6
    DEFW dor
    DEFB $3F
    DEFB $13,$8
    DEFM 'N', $5
    DEFM "APPL", 0, $FF

DEFS $25

.card_header
    DEFW $536D  ;From McAfee validate run on card file with card id 0. Second num less eights bits
    DEFB 5      ;Sweden
    DEFB $80
    DEFB 1      ;(app_front_dor+$40-card_start)/16384
    DEFB 0
    DEFM "OZ"



;980803
;Reduced hw_rxbt min time from 181 to 68.

;980807
;Changed nak retries from 9 to 10.
;Preserve partly entered filename over suspension.
;Try with ARTS for receiving at 38400.
;Fixed bug preventing CRC mode receiving 
;introduced when implementing stepdown from CRC to checksum mode.
;Remove ARTS again. Transmission stops unreliably.
;Disabled tick interrupt on receive to handle 38400 bps.

;980808
;Eliminated sending an empty last block when the file to 
;send is an exact multiple of the current block size.
;Fixed bug regarding stepdown from CRC to checksum mode.
;Improved user interface when preserving partly entered filename over suspension.
;Disabled timer interrupt on receive to handle 38400 bps without errors.
;128 byte blocks are received at 2900 cps and 1K blocks at 3300 cps.

;980809
;More error messages

;981202
;Moved all header preparation variables inside header block.
;Doesn't crash at timeout anymore.

;981205
;Now send filepath, size and modification time in Ymodem header.

;981206
;Now waits for NAK or C after Ymodem header ACK before sending file.

;981209
;Implemented Ymodem End Batch.
;Implemented Ymoden-G send.

;990227
;Enabled cancelling tranfer by pressing escape between blocks.
;Not.

;990326
;Succeeded in making quick keyboard escape detection
;in character send and receive routines.

;990328
;Ymodem receive, first try.

;990330
;Ymodem single file receive works.

;990331
;Ymodem batch receive works.

;991113
;Hopefully Ymodem sends file attributes after file name at correct position.
;Was bugged by Ymodem receive modification.

;991115-991225
;Step down to 128
;Out of retries -> No response ?
;Send cancel characters when giving up.
;Escape batch

;To Do

;Step down to checksum

;Create dir.

;G

;r * : no esc

;Improve user interface when errors occur.
;Disable timer interrupt on receive only for 38400 bps.
;No gn_nl before error handler message ? box ?

;While reading keyboard, BLINK stops processor up to 40 us = 131 T-states.
;At 38400 bps 8N1, one character must be processed in 3276800 / 3840 = 853 T-states.

;34*256=8704


;Ymodem     Receive and send ~3000 cps
;Ymodem-1K Receive and send ~3300 cps

;115K in 22 files (devnotes 3.0 alarms.pip to dors.pip) 
;received in 1 minute and 16 seconds => 1550 cps.
;received in 1 minute and 27 seconds => 1350 cps.
;received in 1 minute and 21 seconds =>  cps.
;Sent back in 49 seconds => 2400 cps.
;444K in 141 files (devnotes 3.0 alarms.pip to ospbt.pip),
;received in 7 minutes and 30 seconds => 1000 cps.
;Ymodem/CRC 1K. Sent back in 6 minutes and 50 seconds => 1100 cps.

;CANs after end batch

;Up to 1 sec between ack and C on batch receive!