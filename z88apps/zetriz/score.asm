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

     module score_manipulation

     lib init_malloc, malloc, mfree
     lib bind_bank_s1
     lib getpointer, getvarpointer, allocvarpointer
     lib read_long, read_pointer, read_word
     lib set_word, set_long, set_pointer
     lib findmin, insert, delete, find
     lib avlcount, descorder

     xref errorhandler                       ; zetriz_asm

     xdef pool_index, pool_handles           ; data structures for pool handles
     xdef allocated_mem                      ; long integer of currently allocated memory
     xdef MAX_POOLS                          ; max. number of allowed open pools

     xdef init_score
     xdef insert_score
     xdef display_scores
     xdef load_hiscores, merge_hiscores, save_hiscores


     include "time.def"
     include "stdio.def"
     include "fpp.def"
     include "syspar.def"
     include "integer.def"
     include "fileio.def"

     include "zetriz.def"


; ******************************************************************************
;
;    Load hiscore tables from 'ZetriZ.dat' file
;
;    IN:  IX = input file handle of 'ZetriZ.dat' file.
;         The file pointer points at the header byte for the first high score
;         table. The file format of the three high score tables is as follows:
;
;         <Score_table_std>
;         <Score_table_ext>
;         <Score_table_adv>
;
;         <Score_table>:
;              <no_of_highscores>  : if 0 then the score table is empty (max 6).
;              <Score_element>:
;                   <length_name>  : length byte for name string (max. 12 bytes)
;                   <sc_name>      : the name string (incl. null)
;                   <sc_date>      : 3 byte integer: date integer
;                   <sc_score>     : 4 byte integer: score value
;                   <sc_lines>     : 2 byte integer: total lines played
;                   <sc_blocks>    : 2 byte integer: total blocks played
;
;         There is <no_of_highscores> elements of <Score_element> for a <Score_table>.
;
;
;
.load_hiscores      ld   hl, std_hiscore
                    call getpointer
                    call load_scoretable          ; load_scoretable(&std_hiscore)
                    ld   hl, ext_hiscore
                    call getpointer
                    call load_scoretable          ; load_scoretable(&ext_hiscore)
                    ld   hl, adv_hiscore
                    call getpointer
                    call load_scoretable          ; load_scoretable(&adv_hiscore)
                    ret


; ******************************************************************************
;
;    Load score table (into an AVL-tree).
;
;    IN:  BHL = pointer to pointer to root of AVL-tree
;         IX  = input file handle of 'ZetriZ.dat' file (beginning of a score table)
;
;    OUT: None.
;
.load_scoretable    call_oz(os_gb)                ; no_of_highscores = Os_Gb(IX)
                    cp   0
                    ret  z                        ; if ( no_of_highscores <> 0 )
.load_score_elements     push af                       ; do
                         push bc
                         push hl
                         call alloc_sc                      ; newnode = alloc_sc()
                         jr   c, exit_loadelements          ; if ( newnode == NULL ) break;
                         call_oz(os_gb)                     ; size_name = Os_Gb(IX)
                         push af
                         ld   c,b
                         ex   de,hl                         ; CDE = newnode
                         call malloc                        ; name = malloc(size_name)
                         ex   af,af'
                         pop  af
                         ex   af,af'
                         jr   c, exit_loadelements          ; if ( name == NULL ) break;

                         ex   af,af'
                         push bc
                         push de
                         push hl
                         ld   b,0
                         ld   c,a                           ; length of string (incl. null)
                         ex   de,hl
                         ld   hl,0
                         call_oz(os_mv)                     ; Os_Mv(name, length)
                         pop  hl
                         pop  de
                         pop  bc
                         ld   a,b
                         ld   b,c
                         ld   c,a
                         ex   de,hl                         ; BHL = newnode
                         ld   a,sc_name                     ; CDE = name
                         call set_pointer                   ; newnode->sc_name = namenode

                         ld   a,b
                         call bind_Bank_s1                  ; make sure that node is paged in...
                         push af
                         push bc
                         push hl
                         inc  hl
                         inc  hl
                         inc  hl                            ; newnode+3
                         ld   bc, SIZEOF_sc - 3             ; lenght of score node - name pointer
                         ex   de,hl
                         ld   hl,0
                         call_oz(os_mv)                     ; load rest of score record at (newnode+3)
                         pop  hl
                         pop  bc
                         pop  af
                         call bind_bank_s1

                         pop  de
                         pop  af
                         ld   iy,-5
                         add  iy,sp
                         ld   sp,iy                         ; iy points at 5 byte parameter block
                         ld   (iy+0),l
                         ld   (iy+1),h
                         ld   (iy+2),b                      ; newnode ...
                         ld   (iy+3), compare_sc % 256
                         ld   (iy+4), compare_sc / 256      ; pointer to compare routine
                         ld   b,a
                         ex   de,hl                         ; &root of high score table
                         push bc
                         push hl
                         call insert                        ; insert node into high score table
                         pop  hl
                         pop  bc
                         ld   de,5
                         add  iy,de
                         ld   sp,iy                         ; remove parameter block from stack...
                         push bc
                         push hl

.exit_loadelements       pop  hl
                         pop  bc
.next_element            pop  af
                         dec  a
                         jr   nz, load_score_elements  ; while ( --no_of_highscores <> 0)
.exit_loadsctable   ret



; ******************************************************************************
;
;    Save the updated, merged score tables, into a new 'ZetriZ.dat' file.
;
;    IN:  IX = output file handle for 'ZetriZ.dat' file
;
.save_hiscores      ld   hl, std_hiscore
                    call getvarpointer
                    call save_scoretree
                    ld   hl, ext_hiscore
                    call getvarpointer
                    call save_scoretree
                    ld   hl, adv_hiscore
                    call getvarpointer
                    call save_scoretree
                    ret


; ******************************************************************************
;
;    Save the contents of the scoretable into the 'ZetriZ.dat' file.
;
;    IN:  BHL = pointer to root of AVL-tree to save...
;    OUT: None.
;
.save_scoretree     push bc
                    push hl
                    call avlcount                 ; totalelements = avlcount(root)
                    ld   a,e
                    call_oz(os_pb)                ; header of score table: totalelements
                    xor  a
                    cp   e
                    pop  hl
                    pop  bc
                    ret  z                        ; totalelements = 0, no score table...

                    ld   iy, write_score          ; IY = pointer to routine that writes the score info.
                    call descorder                ; descorder(BHL, IY)
                    ret


; ******************************************************************************
;
;    IN:  BHL = pointer to current (sub)record of AVL-tree node.
;         IX  = output file handle of 'ZetriZ.dat' file.
;
.write_score        push bc
                    push hl
                    ld   a, sc_name
                    call read_pointer             ; node->sc_name
                    ld   a,b
                    call bind_bank_s1             ; make sure that sc_name is paged in...
                    push af
                    push hl
                    xor  a
                    ld   bc,12
                    cpir                          ; search for null-terminator
                    pop  de
                    sbc  hl,de
                    ld   a,l
                    call_oz(os_pb)                ; fputc(strlen(node->sc_name)) (incl. null)
                    ld   b,0
                    ld   c,l
                    ex   de,hl
                    ld   de,0
                    call_oz(os_mv)                ; fputs(node->sc_name)
                    pop  af
                    call bind_bank_s1             ; restore previous binding...

                    pop  hl
                    pop  bc
                    ld   a,b
                    call bind_bank_s1             ; make sure that node is paged in...
                    push af
                    inc  hl
                    inc  hl
                    inc  hl                       ; (HL) is sc_date...
                    ld   bc, SIZEOF_sc - 3
                    ld   de,0
                    call_oz(os_mv)                ; store rest of score record to file
                    pop  af
                    call bind_bank_s1             ; restore previous binding...
                    ret



; ******************************************************************************
;
;    Merge hiscores from 'ZetriZ.dat' file with resident scores in memory
;
;    IN:  IX = input file handle of 'ZetriZ.dat' file...
;         (the file pointer is at the beginning of the file)
;
;    Register affected on return:
;         ......../IX..  same
;         AFBCDEHL/..IY  different
;
.merge_hiscores     ld   hl, 9
                    ld   (zetrizmap),hl
                    ld   hl, 0
                    ld   (zetrizmap+2),hl
                    ld   a, fa_ptr
                    ld   hl, zetrizmap
                    call_oz(os_fwm)               ; file pointer at 10. position in 'ZetriZ.dat'
                    ld   hl, hiscore0
                    call getpointer
                    call load_scoretable          ; load_scoretable(&hiscore0)
                    ld   hl, std_hiscore
                    call getvarpointer
                    call mergetrees               ; mergetrees(std_hiscore, hiscore0)
                    ld   hl, hiscore0
                    call getvarpointer
                    ex   de,hl
                    ld   c,b
                    ld   hl, std_hiscore
                    call getpointer
                    xor  a
                    call set_pointer              ; std_hiscore = hiscore0
                    call adjustscores             ; adjustscores(&std_hiscore)
                    ld   hl, hiscore0
                    call getpointer
                    ld   c,0
                    ld   d,c
                    ld   e,c
                    xor  a
                    call set_pointer              ; hiscore0 = NULL

                    call load_scoretable          ; load_scoretable(&hiscore0)
                    ld   hl, ext_hiscore
                    call getvarpointer
                    call mergetrees               ; mergetrees(ext_hiscore, hiscore0)
                    ld   hl, hiscore0
                    call getvarpointer
                    ex   de,hl
                    ld   c,b
                    ld   hl, ext_hiscore
                    call getpointer
                    xor  a
                    call set_pointer              ; ext_hiscore = hiscore0
                    call adjustscores             ; adjustscores(&ext_hiscore)
                    ld   hl, hiscore0
                    call getpointer
                    ld   c,0
                    ld   d,c
                    ld   e,c
                    xor  a
                    call set_pointer              ; hiscore0 = NULL

                    call load_scoretable          ; load_scoretable(&hiscore0)
                    ld   hl, adv_hiscore
                    call getvarpointer
                    call mergetrees               ; mergetrees(adv_hiscore, hiscore0)
                    ld   hl, hiscore0
                    call getvarpointer
                    ex   de,hl
                    ld   c,b
                    ld   hl, adv_hiscore
                    call getpointer
                    xor  a
                    call set_pointer              ; adv_hiscore = hiscore0
                    call adjustscores             ; adjustscores(&adv_hiscore)
                    ld   hl, hiscore0
                    call getpointer
                    ld   c,0
                    ld   d,c
                    ld   e,c
                    xor  a
                    call set_pointer              ; hiscore0 = NULL
                    ret


; ******************************************************************************
;
;    Merge the current score AVL-tree into the hiscore0 tree (just loaded from
;    the 'ZetriZ.dat' file). If any scores from the current tree exists, they will
;    be ignored. Only new scores (relative to the hiscore0) will be merged.
;
;    IN: BHL = pointer to root of AVL-tree to be merged into hiscore0 tree.
;
;    Register affected on return:
;         ......../IXIY  same
;         AFBCDEHL/....  different
;
.mergetrees         push iy
                    ld   iy, merge_score          ; try to merge (insert) all
                    call descorder                ; scores into the hiscore0 tree
                    pop  iy
                    ret


; ******************************************************************************
;
;    Try to merge the current score (sub)record into the hiscore0 AVL-tree.
;    If the score already exists in hiscore0, it is not inserted.
;
;    IN:  BHL = pointer to current (sub)record of AVL-tree
;
;    Register affected on return:
;         ......../IXIY  same
;         AFBCDEHL/....  different
;
.merge_score        push iy
                    ld   c,b
                    ex   de,hl
                    ld   hl, hiscore0
                    call getvarpointer
                    push bc
                    push de
                    ld   iy, compare_sc
                    call find
                    pop  de
                    pop  bc                       ; n
                    jr   nc, exit_merge_score     ; if (not find(n, hiscore0))
                         ld   iy,-5
                         add  iy,sp
                         ld   sp,iy
                         ld   (iy+0),e
                         ld   (iy+1),d
                         ld   (iy+2),c                 ; n
                         ld   (iy+3), compare_sc % 256
                         ld   (iy+4), compare_sc / 256 ; pointer to compare routine
                         ld   hl, hiscore0
                         call getpointer
                         call insert                   ; insert( n, &hiscore0, compare_sc)
                         ld   bc,5
                         add  iy,bc
                         ld   sp,iy                    ; remove parameter block from stack...
.exit_merge_score   pop  iy
                    ret


; ******************************************************************************
;
;    Adjust score tree to contain max. 6 elements. If larger then the smallest
;    scores are deleted until the tree contains 6 score items.
;
;    IN:  BHL = pointer to pointer to root of score tree.
;    OUT: None.
;
;    Register affected on return:
;         ..BC..HL/IXIY  same
;         AF..DE../....  different
;
.adjustscores       push bc                       ; repeat
                    push hl
                    xor  a
                    call read_pointer                  ; *root
                    call avlcount
                    ld   a,6
                    cp   e
                    jr   nc, exit_adjustscores         ; if avlcount(*root) >= 6
                         call findmin                       ; minp = findmin(*root)
                         ld   a,b
                         ex   de,hl
                         pop  hl
                         pop  bc                            ; BHL = root
                         ld   c,a                           ; CDE = minp
                         push ix
                         push iy
                         ld   ix, compare_sc
                         ld   iy, delete_sc
                         call delete                        ; delete(minp, root)
                         pop  iy
                         pop  ix                       ; else
                         jr   adjustscores                  ; return
.exit_adjustscores  pop  hl                       ; end repeat
                    pop  bc
                    ret



; ******************************************************************************
;
;    Allocate room for the 3 game high score tables (standard, extended & advanced)
;
.init_score         call init_malloc              ; initialize a memory pool for score tables
                    call c, errorhandler          ; Ups - allocation problems...
                    ld   hl, hiscore0
                    call allocvarpointer          ; hiscore0 = NULL
                    ld   hl, std_hiscore
                    call allocvarpointer          ; std_hiscore = NULL
                    ld   hl, ext_hiscore
                    call allocvarpointer          ; ext_hiscore = NULL
                    ld   hl, adv_hiscore
                    call allocvarpointer          ; adv_hiscore = NULL
                    ret



; ******************************************************************************
;
;    Insert score information into AVL tree (the game was finished, aborted).
;
;    The player is first prompted to enter his name.
;    An insertion of the global game data is then put into the AVL-tree:
;    name, score, lines, blocks and date of game.
;
;    If the AVL-tree is larger then 6 items, the bottom entry (the smallest score)
;    of the tree is deleted automatically, thereby maintaining a max. of 6 entries
;    per high score table).
;
.insert_score       ld   hl, (hiscoretable)
                    call getvarpointer
                    ld   iy, find_cmp
                    call find                     ; find(hiscoretable,gamepoints)
                    ret  nc                       ; score already exists, ignore...

                    call alloc_sc                 ; newscore = alloc_sc(SIZEOF_sc)
                    jp   c, errorhandler          ; Ups - no room

                    ld   c, 0
                    ld   d, c
                    ld   e, c
                    ld   a, sc_name
                    call set_pointer              ; newscore->sc_name = null
                    push bc
                    push hl
                    ld   de,sc_date
                    add  hl,de
                    ex   de,hl                    ; DE points at memory for Date
                    call_oz(gn_gmd)               ; newscore->sc_date = OZ(Gn_Gmd)
                    pop  hl
                    pop  bc                       ; BHL = newscore
                    ld   de,(totallines)
                    ld   a, sc_lines
                    call set_word                 ; newscore->sc_lines = totallines
                    ld   de,(totalblocks)
                    ld   a, sc_blocks
                    call set_word                 ; newscore->sc_blocks = totalblocks
                    exx
                    ld   bc,(gamepoints)
                    ld   de,(gamepoints+2)
                    exx
                    ld   a, sc_score
                    call set_long                 ; newscore->sc_score = gamepoints

                    push bc
                    push hl
                    ex   de,hl
                    ld   c,b                      ; newscore = CDE
                    ld   hl, (hiscoretable)
                    call getvarpointer
                    call findmin                  ; min = findmin(hiscoretable)
                    jr   nc, cmp_sc               ; if min <> NULL
                         pop  hl
                         pop  bc
                         jr   insert_sc
.cmp_sc                  call compare_sc
                         pop  hl
                         pop  bc                       ; if min->sc_score > newscore->sc_score
                         ret  nc                            ; return, new score at 7. position...

.insert_sc          call inputname                ; newname = inputname()
                    jp   c, errorhandler          ; Ups - no room

                    ld   iy,-5
                    add  iy,sp
                    ld   sp,iy                    ; IY points at 5 byte parameter block
                    ld   (iy+0),l
                    ld   (iy+1),h
                    ld   (iy+2),b                 ; pointer to new node ...
                    ld   (iy+3), compare_sc % 256
                    ld   (iy+4), compare_sc / 256 ; pointer to compare routine
                    ld   hl,(hiscoretable)
                    call getpointer               ; BHL = **pointer to root of cur. hiscore
                    call insert                   ; insert node into high score table
                    ld   bc,5
                    add  iy,bc
                    ld   sp,iy                    ; remove parameter block from stack...

                    ld   hl,(hiscoretable)
                    call getvarpointer
                    call avlcount                 ; totalelements = avlcount(*hiscoretable)
                    ld   a,6
                    cp   e
                    ret  nc                       ; if totalelements > 6
                         ld   hl,(hiscoretable)
                         call getvarpointer
                         call findmin                  ; smallestscore = findmin(*hiscoretable)
                         ld   c,b
                         ex   de,hl
                         ld   hl,(hiscoretable)
                         call getpointer
                         push ix
                         ld   ix, compare_sc
                         ld   iy, delete_sc
                         call delete                   ; delete(smallestscore, hiscoretable)
                         pop  ix
                    ret



; ******************************************************************************
;
;    Display current game scores
;
.display_scores     ld   hl, hiscorewindow
                    call_oz(gn_sop)               ; create hiscore window
                    ld   hl, header_msg
                    call_oz(gn_sop)
                    ld   hl, (hiscoreheader)      ; pointer to header text
                    call_oz(gn_sop)
                    ld   hl, header_end
                    call_oz(gn_sop)
                    call_oz(gn_nln)

                    ld   hl,(hiscoretable)
                    call getvarpointer            ; BHL = pointer to root of current hiscore table
                    push bc
                    push hl
                    call avlcount                 ; totalelements = avlcount(*hiscoretable)
                    pop  hl
                    pop  bc
                    xor  a
                    or   e
                    jr   z, no_scores             ; if totalelements <> 0
                         push hl
                         ld   hl, scoretxt
                         call_oz(gn_sop)
                         pop  hl
                         ld   iy, display_score        ; IY = pointer to routine that displays the score info
                         call descorder                ; display table with largest score first...
                         ret                      ; else
.no_scores               ld   hl,noscore_msg
                         call_oz(gn_sop)               ; print "None."
                    ret

.hiscorewindow      defm 1, "7#3", 32+52, 32+0, 32+41, 32+8, @10000001, 1, "2C3", 0
.header_msg         defm 1, "2JC", 1, "3+BF", "High Scores, ", 0
.header_end         defm 1, "3-BF", 0
.scoretxt           defm 1, "2JN", 1, "T"
                    defm "NAME"
                    defm 1, "2X", 32+12, "POINTS"
                    defm 1, "2X", 32+19, "LINES"
                    defm 1, "2X", 32+25, "BLOCKS"
                    defm 1, "2X", 32+32, "DATE"
                    defm 1, "T", 13, 10, 0
.noscore_msg        defm 13, 10, 1, "2JCNone.", 0



; ******************************************************************************
;
;    Display score information of current AVL-tree (sub)record
;
;    IN: BHL = pointer to current AVL-tree (sub)record of score information
;    OUT: None.
;
.display_score      push ix

                    push bc
                    push hl
                    ld   bc, nq_ohn               ; get handle for standard output
                    call_oz(os_nq)                ; in IX...
                    pop  hl
                    pop  bc

                    push bc
                    push hl
                    ld   a,sc_name
                    call read_pointer
                    call_oz(gn_soe)               ; print node->sc_name;
                    ld   hl, tab_score
                    call_oz(gn_sop)               ; print tab(12);
                    pop  hl
                    pop  bc

                    push bc
                    push hl
                    ld   de, sc_score
                    add  hl,de                    ; HL points at score
                    ld   a,b
                    call bind_bank_s1             ; page in memory of score integer
                    push af                       ; remember old bank binding
                    ld   de,0                     ; ASCII points to std. output
                    xor  a
                    call_oz(gn_pdn)               ; display node->sc_score
                    pop  af
                    call bind_bank_s1
                    ld   hl, tab_lines
                    call_oz(gn_sop)               ; print tab(19);
                    pop  hl
                    pop  bc

                    push bc
                    push hl
                    ld   a,sc_lines
                    call read_word
                    push de
                    pop  bc
                    ld   hl,2                     ; BC contains no. of lines
                    ld   de,0                     ; display ASCII version to std. output
                    xor  a                        ; general display format...
                    call_oz(gn_pdn)               ; display node->sc_lines
                    ld   hl, tab_blocks
                    call_oz(gn_sop)               ; print tab(25);
                    pop  hl
                    pop  bc

                    push bc
                    push hl
                    ld   a,sc_blocks
                    call read_word
                    push de
                    pop  bc
                    ld   hl,2                     ; BC contains no. of lines
                    ld   de,0                     ; display ASCII version to std. output
                    xor  a                        ; general display format...
                    call_oz(gn_pdn)               ; display node->sc_blocks
                    ld   hl, tab_date
                    call_oz(gn_sop)               ; print tab(32);
                    pop  hl
                    pop  bc

                    ld   de, sc_date
                    add  hl,de                    ; HL points at internal date
                    ld   a,b
                    call bind_bank_s1             ; page in memory of date information
                    push af                       ; remember old bank binding
                    ld   de,0                     ; write ASCII date to std. output
                    ld   a,@00110000
                    ld   bc,'.'                   ; write date as dd.mm.yy
                    call_oz(gn_pdt)               ; display node->sc_date
                    pop  af
                    call bind_bank_s1             ; restore prev. bank binding

                    call_oz(gn_nln)               ; putc('\n')
                    pop  ix
                    ret
.tab_score          defm 1, "2X", 32+12, 0
.tab_lines          defm 1, "2X", 32+19, 0
.tab_blocks         defm 1, "2X", 32+25, 0
.tab_date           defm 1, "2X", 32+32, 0


; ******************************************************************************
;
;    Input Player name.
;    12 bytes are allocated for the name, then a name is entered.
;    Finally the name is linked to the score node.
;
;    IN:  BHL = pointer to new score node.
;    OUT: Fc = 1, no room...
;
;    Register affected on return:
;         ..B...HL/IXIY  same
;         AF.CDE../....  different
;
.inputname          push bc
                    push hl
                    call alloc_name
                    jr   c, exit_inputname
                         push bc
                         ld   (hl),0              ; null-terminate string
                         ex   de,hl               ; DE points at start of string
.inputname_loop          ld   hl, inputnametxt
                         ld   (menutextptr),hl
                         call_oz(gn_sop)
                         ld   bc,$0c00
                         ld   a, @00100001        ; single line lock, buffer contents
                         ld   l, 12               ; 12 character input (incl. null)
                         call_oz(gn_sip)          ; OZ input line with contents
                         push bc
                         push de
                         call c,errorhandler      ; evaluate OZ error...
                         pop  de
                         pop  bc
                         cp   in_ent
                         jr   z, input_finished   ; <ENTER> pressed, input finished
                         jr   inputname_loop
.input_finished     pop  bc
.exit_inputname     pop  hl
                    ld   a,b
                    pop  bc
                    ld   c,a                      ; CDE = pointer to name
                    ld   a, sc_name
                    call set_pointer              ; newscore->sc_name = newname
                    ret

.inputnametxt       defm 12, 13, 10, 1, "2JN", 1, "2+C"
                    defm "The score is among the 6 best!", 13, 10
                    defm "Enter your name: ", 0



; ******************************************************************************
;
;    Compare two score nodes
;
;    IN:  BHL = pointer to current AVL-tree (sub)record of score node
;               (supplied by library routine)
;         CDE = pointer to node of search key
;
;    OUT: Flags Fc & Fz set according to .Insert/.Delete library routines
;
;    Register affected on return:
;         ..BCDE../IXIY  same
;         AF....HL/....  different
;
.compare_sc         push bc
                    push de
                    ld   a, sc_score
                    call read_long                ; avltree->data->sc_score in DEBC
                    exx
                    push bc
                    push de                       ; preserve score...
                    exx
                    ex   de,hl
                    ld   b,c
                    ld   a, sc_score              ; newnode->sc_score in DEBC
                    call read_long
                    exx
                    cp   a
                    pop  hl
                    sbc  hl,de
                    pop  hl
                    jr   c, exit_cmp_sc           ; newnode->sc_score > avltree->data->sc_score
                    jr   nz, exit_cmp_sc          ; newnode->sc_score < avltree->data->sc_score
                    sbc  hl,bc
.exit_cmp_sc        pop  de
                    pop  bc
                    ret                           ; return flags for low word comparison...


; ******************************************************************************
;
.find_cmp           ld   a,sc_score
                    call read_long                ; curnode->sc_score
                    exx
                    cp   a
                    ex   de,hl
                    ld   de,(gamepoints+2)
                    sbc  hl,de
                    ret  c                        ; curnode->sc_score < score
                    ret  nz                       ; curnode->sc_score > score
                    ld   h,b
                    ld   l,c
                    ld   bc,(gamepoints)
                    sbc  hl,bc
                    ret


; ******************************************************************************
;
;    .Delete service routine.
;    This routine is called to delete the contents of the AVL (sub)record
;
.delete_sc          push bc
                    push hl
                    ld   a, sc_name
                    call read_pointer
                    call mfree                    ; free(node->sc_name)
                    pop  hl
                    pop  bc
                    call mfree                    ; free(node)
                    ret


; ******************************************************************************
;
;    Allocate room for a node for the player's name.
;
;    IN: None.
;    OUT: BHL = pointer to allocated memory
;
.alloc_name         LD   A, 12                    ; max 12 characters for a name (incl. null)
                    CALL malloc
                    RET


; ******************************************************************************
;
;    Allocate room for a node of score information
;
;    IN: None.
;    OUT: BHL = pointer to allocated memory
;
.alloc_sc           LD   A, SIZEOF_sc
                    CALL malloc
                    RET
