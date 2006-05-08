; *************************************************************************************
; ZetriZ
; (C) Gunther Strube (gbs@users.sf.net) 1995-2006
;
; ZetriZ is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; ZetriZ is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with ZetriZ;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
; *************************************************************************************

     Module ZetriZ

; V1.0 completed 04.02.95

     lib opengraphics, cleargraphics
     lib cleararea
     lib displayblock
     lib plotpixel, invpixel, respixel
     lib drawbox, scroll_left
     lib randomize, rnd
     lib createwindow
     lib toupper
     lib release_pools

     xref positionblock                      ; blklogic.asm
     xref checkmap, checklines               ;
     xref placeblock                         ;
     xref zetrizmapaddress                   ;

     xref displaypoints                      ; points.asm
     xref displaylines                       ;
     xref displayblocks                      ;
     xref addpoints                          ;

     xref init_score, insert_score           ; score.asm
     xref load_hiscores, save_hiscores       ;
     xref display_scores                     ;
     xref merge_hiscores                     ;

     xref setspeed, displayspeed             ; setspeed.asm

     xref blocks                             ; blocks.asm
     xref block0                             ;

     xref scoretxt                           ; consts.asm
     xref linestxt                           ;
     xref speedtxt                           ;
     xref blockstxt                          ;
     xref rotatetxt, rotateleft_spr, rotateright_spr
     xref nextblocktxt                       ;

     xdef base_graphics                      ; prepare pointer for graphics library routines.
     xdef coords                             ; prepare pointer for graphics library routines.
     xdef seed                               ; prepare pointer for randomize number library routines.
     xdef errorhandler


     include "fpp.def"
     include "stdio.def"
     include "fileio.def"
     include "director.def"
     include "time.def"
     include "error.def"
     include "saverst.def"

     include "zetriz.def"


; ZetriZ is made as a ROM application. The ROM DOR has been set up for 16K EPROM.
; Top bank $3F contains ZetriZ

     org $c000


; ******************************************************************************
; Z88 application data structure for ZetriZ .
; The ROM front DOR header will point at the Appl1_DOR data structure.
;
; 'ZetriZ' data structure:
;
.appl1_DOR          DEFB 0, 0, 0                ; link to parent
                    DEFB 0, 0, 0                ; next application at start of bank $3E
                    DEFB 0, 0, 0
                    DEFB $83                    ; DOR type - application ROM
                    DEFB DOREnd1-DORStart1      ; total length of DOR
.DORStart1          DEFB '@'                    ; Key to info section
                    DEFB InfoEnd1-InfoStart1    ; length of info section
.InfoStart1         DEFW 0                      ; reserved...
                    DEFB 'Y'                    ; application key letter
                    DEFB 0                      ; contigous RAM size (0 = good appl)
                    DEFW 0                      ;
                    DEFW 0                      ; Unsafe workspace
                    DEFW Application_workspace  ; Safe workspace
                    DEFW Zetriz_entry           ; Entry point of code in seg. 3
                    DEFB 0                      ; bank binding to segment 0 (Intuition)
                    DEFB 0                      ; bank binding to segment 1
                    DEFB 0                      ; bank binding to segment 2
                    DEFB $3f                    ; bank binding to segment 3 (ZetriZ)
                    DEFB 1                      ; Good application
                    DEFB 0                      ; no caps lock on activation
.InfoEnd1           DEFB 'H'                    ; Key to help section
                    DEFB 12                     ; total length of help

                    DEFW ZetriZ_Topics
                    DEFB $3F
                    DEFW ZetriZ_Commands
                    DEFB $3F
                    DEFW ZetriZ_help
                    DEFB $3F
                    DEFB 0, 0, 0                ; No token base
                    DEFB 'N'                    ; Key to name section
                    DEFB NameEnd1-NameStart1    ; length of name
.NameStart1         DEFM "ZetriZ", 0
.NameEnd1           DEFB $FF
.DOREnd1


; ********************************************************************************************************************
;
; topic entries for Z80asm application...
;
.ZetriZ_Topics      DEFB 0                                                      ; start marker of topics

; 'INFO' topic
.zetriz_info_topic  DEFB zetriz_info_topic_end - zetriz_info_topic    ; length of topic definition
                    DEFM "INFO"
                    DEFW 0
                    DEFB @00000010
                    DEFB zetriz_info_topic_end - zetriz_info_topic
.zetriz_info_topic_end

                    DEFB 0

; ********************************************************************************************************************


; ********************************************************************************************************************
;
.ZetriZ_commands    DEFB 0                                                      ; start of commands

.ZetriZ_info1       DEFB Zetriz_info1_end - ZetriZ_info1
                    DEFW 0                                                      ; command code & keyboard sequense
                    DEFM "ZetriZ keys"
                    DEFB (inf_cmd1_help - ZetriZ_help) / 256                    ; high byte of rel. pointer
                    DEFB (inf_cmd1_help - ZetriZ_help) % 256                    ; low byte of rel. pointer
                    DEFB $10
                    DEFB ZetriZ_info1_end - ZetriZ_info1
.ZetriZ_info1_end

.ZetriZ_info2       DEFB Zetriz_info2_end - ZetriZ_info2
                    DEFW 0                                                      ; command code & keyboard sequense
                    DEFM "ZetriZ game information"
                    DEFB (inf_cmd2_help - ZetriZ_help) / 256                    ; high byte of rel. pointer
                    DEFB (inf_cmd2_help - ZetriZ_help) % 256                    ; low byte of rel. pointer
                    DEFB $10
                    DEFB ZetriZ_info2_end - ZetriZ_info2
.ZetriZ_info2_end

                    DEFB 0

; ********************************************************************************************************************


.ZetriZ_help        defm $7F
                    defm "ZetriZ is based enterily on graphical routines", $7F
                    defm "available in the standard library.", $7F, $7F
.copyright          defm 1, "BZetriZ V1.0, (c) Gunther Strube, 1995", 1, 'B', 0

.inf_cmd1_help      defm 12
                    defm "To pause the game, press ", 1, SD_ESC, ". To resume, press any key.", $7F
                    defm "To abort the game, press ", 1, SD_ESC, " again during pause.", $7F
                    defm "The key auto repeat speed can be altered in the Panel.", $7F
                    defm "You can redefine the block movement keys in menu item <2>.", $7F
                    defm "Switch-tasking is allowed during playing of ZetriZ. For", $7F
                    defm "convenience, pause the game with ", 1, SD_ESC, " before", $7F
                    defm "activating other resident applications.", $7F
                    defm 0

.inf_cmd2_help      defm 12
                    defm "The falling blocks must be assembled into filled horisontal", $7F
                    defm "lines. Each filled line is then removed and the above blocks", $7F
                    defm "are automatically positioned into the empty space. When a new", $7F
                    defm "block cannot be inserted (due to collision) the game ends.", $7F
                    defm "The falling speed increases in modulus 10000 points.", $7F
                    defm "1 line: 100 points. 2 lines: 300 points. 3 lines: 700 points.", $7F
                    defm "4 lines: 1500 points. 5 lines: 3300 points.", $7F
                    defm "Each new inserted block into the game gives 10 points.", 0


; ******************************************************************************
;
; Entry of ZetriZ program when the application is created by OZ:
;
.ZetriZ_entry
                    call zetrizgamesetup

.newgame            call zetrizmenu          ; game menu to begin a new game
                    call resetgamevars
                    call redraw_zetrizscr

                    call getblock
                    ld   (nextblock),ix      ; initialise first zetriz block...
.newblock
                    ld   de,sourcedate       ; current source date in days at (de) which
                    call_oz(gn_gmd)          ; is used for block movement timeout calculation
                    call_oz(os_pur)          ; purge keyboard buffer

                    ld   hl, blockflags
                    res  blockplaced,(hl)    ; a new block is about to move
                    ld   hl,removedlines
                    ld   (hl),0              ; removedlines = 0

                    ld   hl,(gamepoints)
                    ld   de,10
                    add  hl,de
                    ld   (gamepoints),hl
                    jr   nc, display_score
                    ld   de,(gamepoints+2)
                    adc  hl,de
                    ld   (gamepoints+2),hl   ; gamepoints = gamepoints + 10
.display_score      call setspeed            ; set speed according points, and display if changed
                    call displaypoints

                    ld   hl,(totalblocks)
                    inc  hl
                    ld   (totalblocks),hl    ; totalblocks = totalblocks + 1
                    call displayblocks       ; display totalblocks

                    call getnewblock         ; get next block, then a new for next block...
                    ld   bc,(mapxy)
                    call checkmap
                    jr   nc,dispblock
                         ld   hl,(blockxy)                  ; block collision at top position
                         call displayblock                  ; display block
                         ld   a,7
                         call_oz(os_out)                    ; make a beep
                         call inv_zetriz_gamewindow         ; first inverse zetriz window
                         call inv_zetriz_gamewindow         ; then restore...
                         call insert_score                  ; update score list, if necessary...
                    jr   newgame                            ; begin a new game

.dispblock               ld   hl,(blockxy)
                         call displayblock
                         call blockwait
                         ld   a,(blockflags)
                         bit  gameaborted,a
                         push af
                         call nz, insert_score              ; update score list, if necessary...
                         pop  af
                         jr   nz, newgame                   ; game aborted with <ESC>...
                         bit  blockplaced,a
                         jr   nz, getnextblock
                              ld   bc,(mapxy)
                              dec  b
                              call checkmap
                              jr   nc,movedown_timeout
                                   call placeblock
                                   ld   bc,(mapxy)
                                   call checklines          ; check if current line is complete...
                                   call addpoints           ; update game score if line are removed
                                   call setspeed            ; set speed according to game points and user parameter
.getnextblock
                                   ld   hl, blockflags
                                   bit  viewnextblock,(hl)
                                   jp   z, newblock
                                   ld   ix,(nextblock)
                                   ld   hl,$9320
                                   call displayblock        ; remove current 'next block' from window
                                   jp   newblock
.movedown_timeout   call moveblock_down
                    jr   dispblock



; ******************************************************************************
;
.getnewblock        ld   ix,(nextblock)      ; get block to be used now
                    push ix
                    call getblock            ; get a new pointer to a random zetriz block
                    ld   (nextblock),ix      ; which is the next zetriz block to be used
                    call displaynextblock    ; display next block, if feature enabled...
                    pop  ix
                    call positionblock       ; position current block at top of map
                    ret

.displaynextblock   ld   hl, blockflags
                    bit  viewnextblock,(hl)
                    ret  z
                    ld   hl,$9320
                    call displayblock        ; display next zetriz block above zetriz map
                    ret


; ******************************************************************************
;
; return pointer in IX, IY to a new random zetriz block
;
.getblock           push af
                    push bc
                    push de
                    push hl

                    call rnd            ; get a random number (5 byte fltp. number)
                    ld   b,0
                    ld   de,0
                    exx
                    ld   a,(blockrange)
                    ld   d,0
                    ld   e,a
                    exx
                    fpp(fp_mul)         ; rnd * blockrange
                    fpp(fp_int)         ; index = int(rnd * blockrange)
                    exx
                    ld   a,(blockrange_start)
                    ld   h,0            ; (index range is 0 - 255)
                    add  a,l
                    ld   l,a            ; index = blockrange_start + index
                    add  hl,hl
                    add  hl,hl          ; index = index * 4
                    ex   de,hl
                    ld   hl, blocks
                    add  hl,de          ; blockindex = blocks + index
                    ld   e,(hl)
                    inc  hl
                    ld   d,(hl)         ; pointer to block = (blockindex)
                    inc  hl
                    push de
                    pop  ix             ; pointer to zetriz block in ix
                    ld   e,(hl)
                    inc  hl
                    ld   d,(hl)
                    push de
                    pop  iy             ; pointer to shadow block in iy.

                    pop  hl
                    pop  de
                    pop  bc
                    pop  af
                    ret



; ******************************************************************************
;
;    On timeout, block is automatically moved one step downwards...
;
.moveblock_down     ld   hl,(mapxy)
                    dec  h
                    ld   (mapxy),hl
                    ld   hl,(blockxy)
                    call displayblock             ; remove block from current position
                    ld   a,h
                    sub  6
                    ld   h,a
                    ld   (blockxy),hl
                    ret


; ******************************************************************************
;
.blockwait          push bc
                    push de
                    push hl
                    ld   c,0
                    ld   de,sourcetime
                    call_oz(gn_gmt)               ; get current machine time in 1/100 seconds
                    ld   hl,(timeout)             ; current time in abc
                    ld   bc,(sourcetime)
                    add  hl,bc                    ; add zetriz block movement timout in 1/100 sec.
                    ld   (sourcetime),hl
                    ld   c,0
                    ld   a,(sourcetime+2)
                    adc  a,c                      ; add overflow, if any
                    ld   (sourcetime+2),a         ; (source_time) = current time + 10 minutes...

.timeout_loop       call read_zetrizkeys          ; read keyboard to perform block rotation
                    ld   a,(sourcedate+2)
                    ld   b,a
                    ld   hl,(sourcedate)          ; source time days (current day)
                    ld   a,(sourcetime+2)
                    ld   c,a
                    ld   de,(sourcetime)          ; cde = time to elapse (in 1/100 sec.)
                    xor  a
                    call_oz(gn_msc)               ; has current time elapsed source time?
                    jr   nc, timeout_loop

                    pop  hl
                    pop  de
                    pop  bc
                    ret                           ; timeout, move block 1 entity downwards



; ******************************************************************************
;
;    Read keyboard for movement keys and perform corresponding action
;
.read_zetrizkeys    ld   bc,0
                    call_oz(os_tin)
                    call c, errorhandler

.check_keys         call toupper                  ; all keys are upper case...
                    ld   iy,keymap
                    cp   (iy+0)
                    jp   z, block_rotate
                    cp   (iy+1)
                    jr   z, block_drop
                    cp   (iy+2)
                    jr   z, moveblock_left
                    cp   (iy+3)
                    jr   z, moveblock_right
                    cp   (iy+4)
                    jr   z, moveblock_downward
                    cp   IN_ESC
                    jp   z, pause_game
                    cp   0
                    jr   z, read_zetrizkeys       ; get extended key...
                    ret

.moveblock_left     ld   bc,(mapxy)
                    dec  c
                    call checkmap
                    ret  c
                    ld   hl,(mapxy)
                    dec  l
                    ld   (mapxy),hl
                    ld   hl,(blockxy)
                    call displayblock
                    ld   a,l
                    sub  6
                    ld   l,a
                    ld   (blockxy),hl
                    call displayblock
                    ret

.moveblock_right    ld   bc,(mapxy)
                    inc  c
                    call checkmap
                    ret  c
                    ld   hl,(mapxy)
                    inc  l
                    ld   (mapxy),hl
                    ld   hl,(blockxy)
                    call displayblock
                    ld   a,l
                    add  a,6
                    ld   l,a
                    ld   (blockxy),hl
                    call displayblock
                    ret

.block_drop         ld   bc,(mapxy)
                    dec  b
                    call checkmap
                    jr   nc, drop
                    call placeblock               ; block reached bottom or collided
                    ld   bc,(mapxy)
                    call checklines               ; check if current line is complete...
                    call addpoints                ; update game score if line are removed
                    call setspeed                 ; set speed according to game points and user parameter
                    ret
.drop               call moveblock_down           ; drop block as long a key is pressed...
                    ld   hl,(blockxy)
                    call displayblock             ; display block at new position
                    ld   bc,2
                    call_oz(os_dly)               ; a small pause between each
                    jr   block_drop

.moveblock_downward ld   bc,(mapxy)
                    dec  b
                    call checkmap
                    jr   nc, movedown
                    call placeblock               ; block reached bottom or collided
                    ld   bc,(mapxy)
                    call checklines               ; check if current line is complete...
                    call addpoints                ; update game score if line are removed
                    call setspeed                 ; set speed according to game points and user parameter
                    ret
.movedown           call moveblock_down           ; drop block as long a key is pressed...
                    ld   hl,(blockxy)
                    call displayblock             ; display block at new position
                    ld   bc,0
                    call_oz(os_tin)               ; read keyboard between each drop
                    jp   c, errorhandler          ; timeout or other system errors occurred...
                    jr   moveblock_downward

.block_rotate       push ix
                    ld   bc,(rotation)
                    add  ix,bc                    ; point at next rotation block pointer
                    ld   c,(ix+0)
                    ld   b,(ix+1                  ; read pointer to next block
                    push bc
                    pop  ix                       ; pointer to next block installed
                    ld   bc,(mapxy)
                    call checkmap
                    jr   c, rotation_collision
                    ex   (sp),ix
                    ld   hl,(blockxy)
                    call displayblock             ; remove current block
                    pop  ix
                    call displayblock             ; display new rotated block
                    ret
.rotation_collision pop  ix                       ; restore original pointer to current block
                    ret                           ; and continue block movement

.pause_game
.pause_loop         ld   a, sr_pwt
                    call_oz(os_sr)                ; Page Wait for a key...
                    push af
                    call c, errorhandler
                    ex   af,af'
                    pop  af
                    ret  nc                       ; a key was pressed, continue game...
                    ex   af,af'
                    cp   in_esc
                    jr   z, abort_game            ; game aborted with <ESC>
                    jr   pause_loop               ; system error, re-read keyboard

.abort_game         ld   hl, blockflags
                    set  gameaborted,(hl)         ; flag to abort game
                    ret


; ******************************************************************************
;
;    Redraw ZetriZ graphics window.
;
.redraw_zetrizscr   call zetrizwindow        ; Open Zetriz Graphics window.
                    ld   hl,256
                    call cleargraphics
                    call drawborder

                    call redrawblocks
                    ld   hl,(blockxy)
                    call displayblock        ; redraw current moving zetriz block

.draw_nextblock     ld   hl, blockflags
                    bit  viewnextblock,(hl)
                    jr   z, game_info        ; if viewnextblock
                         push ix
                         ld   hl,$9500
                         ld   ix, nextblocktxt
                         call displayblock
                         pop  ix
                         call draw_nextblockbox
                         push ix
                         ld   ix,(nextblock)
                         ld   hl,$9320
                         call displayblock        ; re-display next zetriz block
                         pop  ix

.game_info          call displaytxt          ; re-display key words
                    call displaypoints       ; re-display current score
                    call displaylines        ; re-display current number of removed lines
                    call displayspeed        ; re-display current block movement speed parameter
                    call displayblocks       ; re-display current number of blocks
                    ret


; ******************************************************************************
;
; Redraw ZetriZ blocks map array using the block0 entity.
;
.redrawblocks       push ix
                    ld   ix,block0
                    ld   l,2
                    ld   c, zetrizmap_width
                    ld   de,zetrizmap
.redraw_col_loop
                    ld   b, zetrizmap_height
                    ld   h,2
.redraw_row_loop
                    ld   a,(de)
                    cp   1
                    push bc
                    push de
                    call z,displayblock
                    pop  de
                    pop  bc
                    inc  de
                    ld   a,h
                    add  a,6
                    ld   h,a
                    dec  b
                    jr   nz, redraw_row_loop
                    ld   a,l
                    add  a,6
                    ld   l,a
                    dec  c
                    jr   nz, redraw_col_loop
                    pop  ix
                    ret


; ******************************************************************************
;
; draw zetriz game area border
;
.drawborder         push ix
                    ld   ix, plotpixel  ; use 'plotpixel' routine.
                    ld   hl,$003f       ; (x,y) = (0,63)
                    ld   b, 6 * zetrizmap_height + 2 + 2
                    ld   c, 6 * zetrizmap_width + 2 + 2
                    call drawbox
                    ld   hl,$013e       ; (x,y) = (1,62)
                    ld   b, 6 * zetrizmap_height + 2
                    ld   c, 6 * zetrizmap_width + 2
                    call drawbox
                    pop  ix
                    ret


; ******************************************************************************
;
; draw next block border
;
.draw_nextblockbox  push ix
                    ld   hl,$9121
                    ld   bc,$2222
                    ld   ix, plotpixel
                    call drawbox        ; box surrounding next block
                    pop  ix
                    ret


; ******************************************************************************
;
.zetrizwindow       ld   a,'3'
                    ld   b, $80         ; open graphics in window '3',
                    ld   hl,256         ; open complete map (256 pixels)...
                    call opengraphics   ; identifying segment 2 as graphics memory.
                    ret


; ******************************************************************************
;
.displaytxt         push ix
                    ld   hl,$f200
                    ld   ix, scoretxt
                    call displayblock
                    ld   hl,$e300
                    ld   ix, linestxt
                    call displayblock
                    ld   hl,$d400
                    ld   ix, blockstxt
                    call displayblock
                    ld   hl,$c500
                    ld   ix, speedtxt
                    call displayblock
                    ld   hl,$b600
                    ld   ix, rotatetxt
                    call displayblock
                    ld   hl,$b632
                    ld   ix, (gamerotation)
                    call displayblock
                    pop  ix
                    ret


; ******************************************************************************
;
; Invert the graphic pixels in the ZetriZ block window
;
.inv_zetriz_gamewindow
                    ld   h,$02
                    ld   b, 6 * zetrizmap_height
.inv_pixcol_loop    push bc
                    ld   b, 6 * zetrizmap_width
                    ld   l,$02
.inv_pixrow_loop    push hl
                    call invpixel
                    pop  hl
                    inc  l
                    djnz inv_pixrow_loop
                    inc  h
                    pop  bc
                    djnz inv_pixcol_loop
                    ret


; ******************************************************************************
;
.menuwindow         ld   a, 128 | '2'             ; draw bottom line & display banner...
                    ld   hl,copyright             ; banner text
                    ld   bc,$0000
                    ld   de,$0831                 ; window at (0,0), width 49, height 8
                    call createwindow
                    ld   hl, centrejustify
                    call_oz(gn_sop)
                    ret
.centrejustify      defm 1, "2JC", 1, "2-C", 0


; ******************************************************************************
;
;    ZetriZ main game menu.
;
.zetrizmenu
.key_loop           call menuwindow
                    ld   hl, menutxt
                    ld   (menutextptr),hl
                    call_oz(gn_sop)

                    call readkeyboard
                    cp   '1'
                    jr   z, gamechoice            ; play 1 of 3 games...
                    cp   '2'
                    call  z, changekeys           ; configure block movement keys
                    cp   '3'
                    call z, gameparameters        ; configure speed, map size, next block view
                    ld   hl, blockflags
                    bit  disphiscore,(hl)         ; flag is only inverted after each 15 seconds...
                    push af
                    call nz, display_scores       ; display hiscore table
                    pop  af                       ; and
                    call z, redraw_zetrizscr      ; ZetriZ graphics simultaneously
                    call change_hiscoreflag
                    jr   key_loop

.gamechoice         ld   hl,choicetxt
                    ld   (menutextptr),hl
                    call_oz(gn_sop)
                    call readkeyboard
                    cp   '1'
                    jr   z, std_zetriz
                    cp   '2'
                    jr   z, ext_zetriz
                    cp   '3'
                    jr   z, adv_zetriz
                    jr   key_loop

.std_zetriz         ld   hl,$1300                 ; standard blocks from 0, total of 19 blocks
                    ld   de, applname_std
                    ld   bc, std_hiscore          ; local pointer to standard hiscore table
                    jr   start_game

.ext_zetriz         ld   hl,$4500                 ; all blocks from 0, total of 69 blocks
                    ld   de, applname_ext
                    ld   bc, ext_hiscore          ; local pointer to extended hiscore table
                    jr   start_game

.adv_zetriz         ld   hl,$3213                 ; extended blocks from 19, range 50
                    ld   de, applname_adv
                    ld   bc, adv_hiscore          ; local pointer to extended hiscore table

.start_game         ld   (hiscoretable),bc        ; local pointer to current hiscore table...
                    ld   (hiscoreheader),de
                    ld   (blockrange_start),hl
                    ex   de,hl
                    call_oz(dc_nam)
                    ld   hl,0
                    ld   (menutextptr),hl
                    call gametext
                    ret                           ; play the game...

.menutxt            defb 12,13,10
                    defm "<1> Start ZetriZ Game.", 13, 10
                    defm "<2> Change ZetriZ Keys.", 13, 10
                    defm "<3> Change Game Parameters.", 13, 10
                    defb 0

.choicetxt          defb 12,13,10
                    defm "<1> Standard ZetriZ.", 13, 10
                    defm "<2> Extended ZetriZ.", 13, 10
                    defm "<3> Advanced Zetriz.", 13, 10
                    defb 0

.applname_std       defm "Standard Game", 0
.applname_ext       defm "Extended Game", 0
.applname_adv       defm "Advanced Game", 0


; ******************************************************************************
;
.change_hiscoreflag ld   hl, blockflags      ; timeout is only used in ZetriZ menu...
                    ld   a,(hl)
                    xor  2^disphiscore
                    ld   (hl),a              ; invert flag to display highscore...
                    ret


; ******************************************************************************
;
.gametext           ld   iy, keymap
                    ld   a,12
                    call_oz(os_out)          ; clear text window
                    ld   hl, esckeytxt
                    call_oz(gn_sop)
                    call_oz(gn_nln)
                    ld   hl, rotatekeytxt
                    call_oz(gn_sop)
                    ld   a,(iy+0)
                    call displaykey
                    call_oz(gn_nln)
                    ld   hl,dropkeytxt
                    call_oz(gn_sop)
                    ld   a,(iy+1)
                    call displaykey
                    ld   hl, commatxt
                    call_oz(gn_sop)
                    ld   hl, downkeytxt
                    call_oz(gn_sop)
                    ld   a,(iy+4)
                    call displaykey
                    call_oz(gn_nln)
                    ld   hl,leftkeytxt
                    call_oz(gn_sop)
                    ld   a,(iy+2)
                    call displaykey
                    ld   hl, commatxt
                    call_oz(gn_sop)
                    ld   hl,rightkeytxt
                    call_oz(gn_sop)
                    ld   a,(iy+3)
                    call displaykey
                    call_oz(Gn_nln)
                    ret

; ******************************************************************************
.displaykey         cp   IN_ESC
                    jr   z, display_escsymbol
                    cp   IN_TAB
                    jr   z, display_tabsymbol
                    cp   IN_ENT
                    jr   z, display_entersymbol
                    cp   IN_DEL
                    jr   z, display_delsymbol
                    cp   IN_SPC
                    jr   z, display_spcsymbol
                    call_oz(os_out)               ; normal key, display...
                    ret
.display_escsymbol  ld   b,SD_ESC
                    jr   displaysymbol

.display_tabsymbol  ld   b,SD_TAB
                    jr   displaysymbol

.display_delsymbol  ld   b,SD_DEL
                    jr   displaysymbol

.display_entersymbol ld   b, SD_ENT
                    jr   displaysymbol

.display_spcsymbol  ld   b,SD_SPC
.displaysymbol      ld   a,1
                    call_oz(os_out)
                    ld   a,b
                    call_oz(os_out)               ; display special symbol
                    ret

.esckeytxt          defm 13, 10, "Pause/Abort Game: ", 1, SD_ESC, 0
.rotatekeytxt       defm "Rotate Block: ", 0
.dropkeytxt         defm "Drop Block: ", 0
.downkeytxt         defm "Move Block Down: ", 0
.leftkeytxt         defm "Move Block Left: ", 0
.rightkeytxt        defm "Move Block Right: ", 0
.commatxt           defm ", ", 0



; ******************************************************************************
;
; Configuration of various game parameters
;
.gameparameters     ld   hl, parametertxt
                    ld   (menutextptr),hl
                    call_oz(gn_sop)
                    call readkeyboard
                    cp   '1'
                    jp   z, changerotation
                    cp   '2'
                    jp   z, changemapsize
                    cp   '3'
                    jp   z, changespeed
                    cp   '4'
                    jp   z, togglenextblock
                    ret

.parametertxt       defb 12,13,10
                    defm "<1> Change Block Rotation Direction.", 13, 10
                    defm "<2> Change ZetriZ Map Size.", 13, 10
                    defm "<3> Change Initial Block Movement Speed.", 13, 10
                    defm "<4> Toggle Next Block Feature.", 13, 10
                    defb 0


; ******************************************************************************
;
; Change block rotation.
;
.changerotation     ld   hl, rotationtxt
                    call_oz(gn_sop)

                    ld   a,(rotation)
                    cp   3
                    jr   z, change_to_right
                    ld   a,3
                    ld   de,rotateleft_spr
                    ld   hl,msg_left
                    jr   set_rotation

.change_to_right    ld   a,5
                    ld   de,rotateright_spr
                    ld   hl,msg_right

.set_rotation       push ix
                    ld   (rotation),a
                    ld   ix, (gamerotation)       ; get pointer to current rotation sprite
                    ld   (gamerotation),de        ; store pointer new rotation sprite
                    call_oz(gn_sop)               ; rotation message
                    ld   hl,$b632
                    call displayblock             ; remove old rotation sprite
                    ld   ix, (gamerotation)
                    call displayblock             ; display new rotation sprite
                    ld   bc,250
                    call_oz(os_dly)               ; small pause then return...
                    pop  ix
                    xor  a                        ; dummy key value for main menu loop
                    ret

.msg_left           defm "anti-"
.msg_right          defm "clockwise", 13, 10, 0
.rotationtxt        defm 12, 13, 10, "Block rotation changed to: ", 0



; ******************************************************************************
;
.changemapsize      call resetgamevars            ; clear game variables
                    call redraw_zetrizscr         ; and remove last game from graphics window
                    ld   hl, changemaptxt
                    ld   (menutextptr),hl
                    call_oz(gn_sop)
                    ld   iy, linefill
.fillmap_loop       call readkeyboard
                    call toupper
                    cp   IN_ENT
                    ret  z                        ; return to main menu...
                    cp   'O'
                    call z, decreasemapsize
                    cp   'P'
                    call z, increasemapsize
                    ld   a,(iy+0)
                    and  @00001111                ; filled lines in range 0 to 15...
                    ld   (iy+0),a

                    call clearzetrizmap           ; reset zetriz map array
                    call fillzetrizmap            ; then fill it with lines
                    ld   hl,$0202
                    ld   b, 6 * zetrizmap_height
                    ld   c, 6 * zetrizmap_width
                    call cleararea                ; clear ZetriZ graphics map area
                    call redrawblocks             ; then display filled lines
                    jr   fillmap_loop

.decreasemapsize    dec  (iy+0)
                    ret
.increasemapsize    inc  (iy+0)
                    ret

.changemaptxt       defb 12,13,10
                    defm "Change the number of filled lines", 13, 10
                    defm "with <O> and <P> to decrease and increase.", 13, 10
                    defm "Press <", 1, SD_ENT, "> to finish.", 13, 10, 0



; ******************************************************************************
;
.changespeed        call resetgamevars
                    call redraw_zetrizscr
                    ld   hl, changespeedtxt
                    ld   (menutextptr),hl
                    call_oz(gn_sop)
.getspeed_loop      call readkeyboard
                    cp   '8'
                    jr   nc, getspeed_loop        ; ascii value > '7'
                    cp   '0'
                    jr   c, getspeed_loop         ; ascii value < '0'
                    sub  '0'
                    ld   (speed),a                ; initial speed defined
                    call setspeed
                    xor  a
                    ret

.changespeedtxt     defb 12,13,10
                    defm "Change the initial block movement speed", 13, 10
                    defm "from 0 up to 7 (7=fastest).", 13, 10, 0



; ******************************************************************************
;
.togglenextblock    call resetgamevars
                    xor  a
                    ld   hl, viewnextblocktxt
                    call_oz(gn_sop)
                    ld   hl, blockflags
                    ld   a,(hl)
                    xor  @00000010                ; invert 'view next block' feature
                    ld   (hl),a
                    bit  viewnextblock,(hl)
                    ld   hl, on_msg
                    jr   nz, write_msg
                    ld   hl, off_msg
.write_msg          call_oz(gn_sop)
                    call redraw_zetrizscr
                    ld   bc,150
                    call_oz(os_dly)
                    xor  a
                    ret

.viewnextblocktxt   defb 12,13,10
                    defm "Display Next Block Feature: ", 0
.on_msg             defm "ON", 13, 10, 0
.off_msg            defm "OFF", 13, 10, 0



; ******************************************************************************
;
; Change block movement keys.
;
.changekeys         ld   iy, keymap
                    ld   de, rotatekeytxt
                    call changekey
                    inc  iy
                    ld   de, dropkeytxt
                    call changekey
                    inc  iy
                    ld   de, leftkeytxt
                    call changekey
                    inc  iy
                    ld   de, rightkeytxt
                    call changekey
                    inc  iy
                    ld   de, downkeytxt
                    call changekey
                    xor  a
                    ret

.changekey          ld   a,12
                    call_oz(os_out)          ; clear text window
                    call_oz(gn_nln)
                    ld   (menutextptr),de
                    ex   de,hl
                    call_oz(gn_sop)
                    call readkeyboard        ; get a key...
                    call c, usecurrent       ; no key selected, use current definition
                    call toupper             ; convert key to upper case, if possible
                    ld   (iy+0),a            ; key press stored in key map
                    call displaykey
                    call_oz(gn_nln)
                    ld   bc, 100
                    call_oz(os_dly)          ; make a small pause
                    ret

.usecurrent         ld   a,(iy+0)            ; use current key definition
                    ret


; ******************************************************************************
;
.readkeyboard
.read_extkey        ld   bc,1000
                    call_oz(os_tin)          ; then get a key press (timeout 10 sec.)...
                    call c,errorhandler
                    ret


; ******************************************************************************
;
.errorhandler       cp   rc_esc
                    jr   z, esc_pressed
                    cp   rc_draw
                    jr   nz, suicide_appl
                         ld   a,(blockflags)
                         bit  gameaborted,a
                         call z, redraw_zetrizscr ; redraw map only during game
                         call menuwindow
                         ld   hl,(menutextptr)
                         ld   a,h
                         or   l
                         ret  z                   ; no pointer...
                         call_oz(gn_sop)
                         xor  a
                         ret

.esc_pressed        call_oz(os_esc)          ; acknowledge <ESC>
                    ld   a, IN_ESC           ; return ESC key value
                    cp   a
                    ret

.suicide_appl       cp   rc_quit             ; Kill request?
                    jr   z, quit_zetriz
                    cp   rc_room
                    jr   z, no_room
                         scf                 ; return other error codes...
                         ret

.no_room            call_oz(gn_err)          ; display standard error box
                                             ; then abort ZetriZ...
.quit_zetriz
                    call save_zetrizfile     ; save key definitions into 'ZetriZ.dat'
                    call release_pools       ; release allocated memory...
                    xor  a                   ; then terminate ZetriZ...
                    call_oz(os_bye)          ; and back to INDEX



; ******************************************************************************
;
.resetgamevars      ld   hl,0
                    ld   ix,0                ; pointer to current zetriz block = NULL
                    ld   (totallines),hl     ; lines = 0, number of deleted lines in game
                    ld   (gamepoints),hl
                    ld   (gamepoints+2),hl   ; gamepoints = 0, score in game
                    ld   (totalblocks),hl
                    ld   (nextblock),hl      ; null pointer (to next block)
                    ld   a,(speed)
                    ld   (gamespeed),a       ; reset displayed speed to initial user parameter
                    ld   hl, blockflags
                    res  blockplaced,(hl)
                    res  gameaborted,(hl)
                    call clearzetrizmap      ; remove all blocks from zetriz map
                    call fillzetrizmap       ; then fill with specified lines
                    ld   bc,0
                    call randomize           ; initialize random number sequense...
                    ret


; ******************************************************************************
;
; clear ZetriZ game array (10*24 elements)
;
.clearzetrizmap     ld   hl,zetrizmap
                    ld   de,zetrizmap+1
                    ld   bc, zetrizmap_width * zetrizmap_height - 1
                    ld   (hl),0
                    ldir                     ; clear map array
                    ret


; ******************************************************************************
;
; fill ZetriZ game map with specified lines in (linefill)
;
.fillzetrizmap      ld   a,(linefill)
                    cp   0                   ; if linefill = 0 then return
                    ret  z                   ; for a=1 to linefill
                    push iy
                    ld   de, zetrizmap_height
                    ld   b,0                      ; y = 0
.next_line_loop     ld   c,0                      ; x = 0
                    call zetrizmapaddress         ; (x,y)
                    ld   h, zetrizmap_width       ; for h = 0 to zetrizmap_width-1
.fill_line_loop     ld   (iy+0),1                      ; (x+h,y) = 1
                    add  iy,de                         ; point at next byte in line
                    dec  h
                    jr   nz, fill_line_loop       ; endfor h
                    inc  b                        ; y = y + 1
                    dec  a
                    jr   nz, next_line_loop  ; endfor a
                    pop  iy
                    ret


; ******************************************************************************
;
;    Game setup - the initial run of Zetriz.
;
.zetrizgamesetup    ld   ix, -1
                    ld   a, FA_EOF
                    call_oz(os_frm)
                    jr   z, continue_zetriz       ; Z88 is expanded, continue...
                         call menuwindow
                         ld   hl,errmessage
                         call_oz(gn_sop)
                         ld   bc,500
                         call_oz(os_dly)
                         xor  a
                         call_oz(os_bye)
.errmessage         defm 13, 10, "Sorry, ZetriZ cannot run on unexpanded Z88.", 0

.continue_zetriz    ld   hl, applname             ; "InterLogic" for Zetriz application
                    call_oz(Dc_Nam)

                    ld   a, SC_ENA
                    call_oz(os_esc)               ; enable ESC detection

                    ld   hl,$0000
                    ld   (speed),hl               ; reset (speed) and (gamespeed)
                    ld   hl,32
                    ld   (timeout),hl             ; preset default block movement 32/100 sec. timeout
                    ld   hl,3
                    ld   (rotation),hl            ; default rotation is LEFT
                    ld   hl,rotateleft_spr        ; display 'rotate left' symbol
                    ld   (gamerotation),hl
                    ld   hl,$1300                 ; standard blocks from 0, total of blocks 19
                    ld   (blockrange_start),hl    ; default set to extended blocks...
                    ld   a,0
                    ld   (linefill),a             ; fill 0 lines giving 24 lines for playing area
                    ld   hl,blockflags
                    set  viewnextblock,(hl)       ; view next block
                    set  disphiscore,(hl)         ; display hiscore after first game, keyboard timeout
                    set  gameaborted,(hl)         ; no game is in progress
                    call init_score               ; allocate NULL pointers to high score tables
                    ld   hl, std_hiscore
                    ld   (hiscoretable),hl
                    ld   hl, applname_std
                    ld   (hiscoreheader),hl       ; display standard hiscore initially...

                    call installkeys              ; install default keys
                    call read_zetrizfile          ; use keys from file, if possible
                    call resetgamevars
                    call redraw_zetrizscr
                    ret

.applname           defm "InterLogic", 0         ; application name when Zetriz have just started


; ******************************************************************************
;
.define_rotation    ld   hl, rotateleft_spr
                    cp   3
                    jr   z, def_rotation
                    ld   hl, rotateright_spr
.def_rotation       ld   (rotation),a             ; define offset pointer in data structure
                    ld   (gamerotation),hl        ; define pointer to left/right rotate sprite
                    ret


; ******************************************************************************
;
;    Read the following information in the 'ZetriZ.dat' file:
;         Keys for Rotate, Drop, Down, Left & Right.
;         Preset filled lines in zetriz map (0 to 16)
;
.read_zetrizfile    ld   a, op_in
                    ld   bc,64                    ; local filename ptr, buffer = 64 bytes...
                    ld   hl, zetrizfile
                    ld   de, zetrizmap            ; filename buffer for OZ
                    call_oz(gn_opf)
                    ret  c                        ; couldn't be opened...
                    ld   bc,5
                    ld   hl,0
                    ld   de, keymap
                    call_oz(os_mv)                ; read key definitions into key map
                    call_oz(os_gb)                ; number of filled lines.
                    ld   (linefill),a
                    call_oz(os_gb)
                    ld   (speed),a                ; get initial block movement speed
                    call_oz(os_gb)
                    ld   (blockflags),a           ; get status flags
                    call_oz(os_gb)
                    call define_rotation          ; define default block rotation
                    call load_hiscores            ; load std., ext. and adv. hiscore tables...
                    call_oz(gn_cl)                ; close file
                    ret


; ******************************************************************************
;
.save_zetrizfile    ld   a, op_in
                    ld   bc,64                    ; local filename ptr, buffer = 64 bytes...
                    ld   hl, zetrizfile
                    ld   de, zetrizmap            ; filename buffer for OZ
                    call_oz(gn_opf)               ; fp = fopen(":ram.0/ZetriZ.dat")
                    jr   c, create_zetrizfile     ; if fp != null
                         call merge_hiscores           ; merge_hiscores()
                         call_oz(gn_cl)                ; fclose(fp)

.create_zetrizfile  ld   a, op_out
                    ld   bc,64                    ; local filename ptr, buffer = 64 bytes...
                    ld   hl, zetrizfile
                    ld   de, zetrizmap            ; filename buffer for OZ
                    call_oz(gn_opf)
                    ret  c                        ; couldn't be created...
                    ld   bc,5
                    ld   de,0
                    ld   hl, keymap
                    call_oz(os_mv)                ; save key definitions from key map
                    ld   a,(linefill)
                    call_oz(os_pb)                ; save number of filled lines.
                    ld   a,(speed)
                    call_oz(os_pb)                ; save initial block movement speed
                    ld   a,(blockflags)
                    call_oz(os_pb)                ; save zetriz status flags
                    ld   a,(rotation)
                    call_oz(os_pb)                ; save current rotation direction
                    call save_hiscores            ; store the three hiscore tables...
                    call_oz(gn_cl)                ; close file
                    ret
.zetrizfile         defm ":RAM.0/ZetriZ.dat", 0


; ******************************************************************************
;
;    Default ZetriZ keys for Pause, Rotate, Drop, Left & Right
;
.installkeys
                    ld   hl, defaultkeys
                    ld   de, keymap
                    ld   bc, 5
                    ldir                          ; install default zetriz keys
                    ret
;                             Rotate    Drop      Left      Right     Down
.defaultkeys        defb      'S',      IN_TAB,   'Q',      'Z',      'A'
