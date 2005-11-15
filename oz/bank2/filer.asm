; -----------------------------------------------------------------------------
; Bank 2 @ S3           ROM offset $aab1-$bf6e
;
; $Id$
; -----------------------------------------------------------------------------

        Module Filer


        org $eab1               ; eab1-ff6e, 5310 bytes



        include "blink.def"
        include "char.def"
        include "director.def"
        include "dor.def"
        include "error.def"
        include "fileio.def"
        include "integer.def"
        include "memory.def"
        include "saverst.def"
        include "stdio.def"
        include "syspar.def"
        include "time.def"
        include "sysvar.def"

defc    f_Vars          = $1dce
defc    NBUFSIZE        = 240

DEFVARS f_Vars
{
     f_Confirm               ds.b    1
     f_Flags1                ds.b    1
     f_OutLnCnt              ds.b    1       ; $1dd0
     f_ParseFlags            ds.b    1
     f_nSrcSegments          ds.b    1
     f_SourceHandle          ds.w    1
     f_DestHandle            ds.w    1
                                     ; above variables get cleared every time a new command is executed
     f_ActiveWd              ds.b    1
     f_SelectorPos           ds.b    1       ; $1dd8
     f_SelectedCmd           ds.b    1
     f_LastCmdRow            ds.b    1       ; !! not used
     f_NumDirEntries         ds.b    1       ; visible entries
     f_Flags2                ds.b    1
     f_SavedCmdPos           ds.b    1
     f_SourceType            ds.b    1
     f_NumSelected           ds.b    1
     f_CmdFlags              ds.b    1       ; $1de0
     f_TopDirEntry           ds.w    1
     f_MemPool               ds.w    1
     f_WildcardHandle        ds.w    1
     f_SourceNameEnd         ds.w    1
     f_DestNameEnd           ds.w    1       ; $1de9
     f_SelectedList          ds.w    1
     f_unk1ded               ds.b    1
     f_StrBuffer             ds.b    17
     f_MatchString           ds.b    17
     f_SourceName            ds.b    NBUFSIZE
     f_DestName              ds.b    NBUFSIZE
}


.Filer
        xor     a                               ; clear variables up to and including two bytes of StrBuffer
        ld      hl, f_Vars
        ld      b, 34
.f_1
        ld      (hl), a
        inc     hl
        djnz    f_1

        ld      a, 5
        OZ      OS_Esc                          ; enable ESC
        xor     a
        ld      hl, FilerErrHandler
        OZ      OS_Erh                          ; set error handler
        call    PrntDotClose                    ; SOH,"2.]"
        ld      a, $60
        ld      bc, 0
        OZ      OS_Mop                          ; allocate memory pool, A=mask
        jr      nc, f_2
        OZ      GN_Err                          ; Display an interactive error box
        jr      ExitFiler

.f_2
        ld      (f_MemPool), ix
        call    ZeroIX

.f_3
        call    InitDisplay

.MainLoop
        OZ      OS_In                           ; read a byte from std. input
        jr      nc, loc_EAFF

.loc_EAE4
        cp      RC_Quit                         ; Request application to quit
        jr      z, ExitFiler
        cp      RC_Draw                         ; Application pre-empted and screen corrupted
        jr      z, f_3
        cp      RC_Susp                         ; Suspicion of pre-emption
        jr      nz, loc_EAF5
        call    PrntDotClose
        jr      MainLoop

.loc_EAF5
        cp      RC_Esc
        jr      nz, MainLoop
        ld      a, SC_ACK                       ; !! SC_ACK=RC_Esc, this ld is unnecessary
        OZ      OS_Esc                          ; Examine special condition
        jr      ExitFiler

.loc_EAFF
        or      a                               ; ignore one-byte codes
        jr      nz, MainLoop

        OZ      OS_In
        jr      c, loc_EAE4

        cp      IN_ENT
        jp      z, Enter
        cp      IN_RGT
        jp      z, CrsrRight
        cp      IN_LFT
        jp      z, CrsrLeft
        cp      IN_UP
        jp      z, CrsrUp
        cp      IN_DWN
        jp      z, CrsrDown
        sub     $20
        jr      z, ShEnter
        dec     a
        cp      $0D
        jp      z, ChDirUp
        cp      $0E
        jp      z, ChDirDown
        cp      $0D
        jr      nc, MainLoop
        jp      DoCmd

.ExitFiler
        call    FreeDOR
        call    GetNextSelected
        jr      c, loc_EB49
        ld      de, Mailbox                     ; "NAME"
        ld      b, 0
        ld      hl, f_SourceName
        ld      a, 3
        OZ      OS_Sr                           ; Write mailbox

.loc_EB49
        ld      ix, (f_WildcardHandle)
        call    TstIX
        jr      z, loc_EB55
        OZ      GN_Wcl                          ; close wildcard handler

.loc_EB55
        ld      ix, (f_MemPool)
        call    TstIX
        jr      z, loc_EB60
        OZ      OS_Mcl                          ; Close memory (free memory pool)

.loc_EB60
        xor     a
        OZ      OS_Bye                          ; Application exit

.Mailbox
        defm    "NAME",0


.TstIX
        push    ix
        pop     de
        ld      a, d
        or      e
        ret

.FilerErrHandler
        cp      RC_Quit                         ; Request application to quit *
        jr      z, ExitFiler
        cp      a
        ret

.ShEnter
        ld      a, (f_ActiveWd)                 ; if we're in command window or there are
        or      a                               ; no selected entries, act like key was enter
        jr      z, Enter
        ld      a, (f_NumSelected)
        or      a
        jr      z, Enter

        call    GetSelectedDirEntry
        call    FindNodeByName
        jr      c, loc_EBA5                     ; current not selected, go select it

        ld      iy, f_SelectedList
        call    FreeSelNode
        ld      a, (f_SelectorPos)
        call    RemoveSelMark
        call    ApplyReverse
        ld      a, (f_NumSelected)
        dec     a
        ld      (f_NumSelected), a
        call    z, EmptySelectedList

.loc_EBA2
        jp      MainLoop

.loc_EBA5
        call    AddSelNode
        jr      nc, loc_EBA2
        cp      RC_Quit
        jp      z, ExitFiler
        jp      loc_EE1A

.Enter
        ld      a, (f_ActiveWd)
        or      a
        jr      z, loc_EBD9                     ; command window

        call    GetSelectedDirEntry
        call    FindNodeByName
        push    af
        call    EmptySelectedList
        call    RemoveSelMarks
        pop     af
        call    c, AddSelNode
        jp      nc, MainLoop

        push    af
        call    EmptySelectedList
        pop     af
        cp      RC_Quit
        jp      z, ExitFiler
        jp      loc_EE1A

.loc_EBD9
        ld      a, (f_SelectedCmd)
        ld      c, a
        ld      a, (f_SelectorPos)
        add     a, c

.DoCmd
        call    GetCmdData
        ld      a, (hl)
        ld      (f_CmdFlags), a
        inc     hl
        push    hl

        ld      hl, Wd43def_txt                 ; init window
        OZ      GN_Sop
        ld      hl, JustifyC_txt
        OZ      GN_Sop

        pop     hl
        push    hl

        inc     hl                              ; command name into title bar
        inc     hl
        call    PrntTinyCaps
        OZ      GN_Sop
        call    PrntTinyCaps
        ld      hl, JustifyN_txt
        OZ      GN_Sop

        ld      bc, 0                           ; reverse & underline  title
        call    Move_XY_BC
        call    PrntUndrlnRvrs
        ld      a, $20+80
        call    ApplyA
        call    PrntUndrlnRvrs

        ld      hl, Init3_txt                   ; select wd3
        OZ      GN_Sop

        call    FreeDOR                         ; pre-command cleanup
        call    ZeroIX
        call    ResetSrcDestName
        ld      hl, f_Vars
        ld      b, 9
.loc_EC2E
        ld      (hl), a
        inc     hl
        djnz    loc_EC2E

        ld      a, (f_Flags2)
        res     0, a
        ld      (f_Flags2), a

        ld      a, (f_CmdFlags)
        bit     2, a
        jp      nz, loc_ED87

.loc_EC42
        ld      hl, AskName_txt
        OZ      GN_Sop                          ; write string to std. output

        ld      a, (f_NumSelected)
        or      a
        jr      z, loc_EC60                     ; no selected entries
        dec     a
        jr      z, loc_EC58                     ; only one selected

        ld      a, (f_CmdFlags)
        bit     3, a                            ; ignore selected?
        jr      nz, loc_EC60

.loc_EC58
        ld      hl, Selected_txt                ; use selected files as source
        OZ      GN_Sop
        jr      loc_EC76

.loc_EC60
        call    InputSrcName
        jp      c, loc_ED92
        ld      a, c
        ld      (f_Flags1), a
        and     $80
        jr      nz, loc_EC76
        ld      a, (f_Flags2)
        set     0, a
        ld      (f_Flags2), a

.loc_EC76
        ld      a, (f_CmdFlags)
        bit     0, a                            ; destination filename?
        jr      z, loc_EC99

        ld      hl, AskNewName_txt
        OZ      GN_Sop                          ; write string to std. output
        ld      de, f_DestName
        ld      bc, $1503
        call    InputLine
        jp      c, loc_ED92
        push    af
        ld      a, c
        ld      (f_ParseFlags), a
        pop     af
        cp      $FF
        jr      z, loc_EC42

.loc_EC99
        call    CmpSrcDest                      ; fail if src=dest
        jr      nc, loc_ECA4
        ld      a, 7
        OZ      OS_Out
        jr      loc_EC60                        ; ask src & dest again

.loc_ECA4
        ld      a, (f_CmdFlags)
        bit     1, a                            ; display each file?
        jr      z, loc_ECCB

        ld      a, (f_NumSelected)
        dec     a
        jr      z, loc_ECCB                     ; no "confirm each" for single file
        inc     a
        jr      nz, loc_ECBB
        ld      a, (f_Flags1)
        bit     7, a
        jr      z, loc_ECCB

.loc_ECBB
        ld      hl, Confirm_txt
        OZ      GN_Sop                          ; write string to std. output
        xor     a
        call    GetYesNo
        jp      c, loc_ED92
        ld      (f_Confirm), a

.loc_ECCB
        ld      a, (f_Flags1)
        and     $80
        jr      z, loc_ECE8
        ld      de, f_SourceName
        call    ExpandFname
        xor     a
        ld      b, a
        inc     a
        ld      hl, f_SourceName
        OZ      GN_Opw                          ; open wildcard handler
        ld      (f_WildcardHandle), ix
        jp      c, loc_ED92
.loc_ECE8
        call    ClrWindow
        call    PrntDotOpen

.loc_ECEE
        call    GetNextSelected
        jr      nc, loc_ECFC
        cp      RC_Eof
        scf
        jr      nz, loc_ECF9
        xor     a

.loc_ECF9
        jp      loc_EDB2

.loc_ECFC
        call    CmpSrcDest
        jr      c, loc_ECEE
        call    OpenSource
        jp      c, loc_ED92
        ld      a, (f_SourceType)
        cp      Dm_Dev
        jp      z, loc_ED92

        ld      a, (f_CmdFlags)
        bit     1, a                            ; display each file?
        jr      z, loc_ED68

        OZ      GN_Nln                          ; send newline (CR/LF) to std. output
        pop     hl
        push    hl
        inc     hl
        inc     hl
        OZ      GN_Sop                          ; write string to std. output
        ld      a, ' '
        OZ      OS_Out                          ; write a byte to std. output
        ld      bc, NQ_Out
        OZ      OS_Nq                           ; get std. output
        ld      hl, f_SourceName
        ld      bc, $3A
        ld      e, b
        ld      d, b
        OZ      GN_Fcm                          ; compress a filename

        ld      a, (f_CmdFlags)
        bit     0, a                            ; destination filename?
        jr      z, loc_ED51

        ld      hl, to_txt                      ; " to "
        OZ      GN_Sop                          ; write string to std. output
        ld      bc, NQ_Out
        OZ      OS_Nq
        ld      hl, f_DestName
        ld      bc, $11
        ld      e, b
        ld      d, b
        OZ      GN_Fcm                          ; compress filename to stdout

.loc_ED51
        ld      a, (f_Confirm)
        or      a
        jr      nz, loc_ED68
        call    CloseSource
        xor     a
        call    GetYesNo
        jr      c, loc_ED92
        or      a
        jr      nz, loc_ECEE
        call    OpenSource
        jr      c, loc_ED92
.loc_ED68
        ld      a, (f_CmdFlags)
        bit     0, a                            ; destination filename?
        jr      z, loc_ED87

        ld      ix, (f_DestHandle)
        call    TstIX
        jr      nz, loc_ED87
        ld      hl, f_DestName
        ld      a, 2                            ; write
        call    OpenFile
        ld      (f_DestHandle), ix
        jp      c, loc_ED92

.loc_ED87
        pop     hl
        push    hl
        ld      a, (hl)
        inc     hl
        ld      h, (hl)
        ld      l, a
        ld      de, loc_ED92
        push    de
        jp      (hl)

.loc_ED92
        push    af
        call    CloseSource
        pop     af
        jr      c, loc_EDA3
        ld      a, (f_CmdFlags)
        and     8                               ; ignore selected?
        jp      z, loc_ECEE
        jr      loc_EDB2

.loc_EDA3
        push    af
        call    CloseDest
        jr      z, loc_EDB1
        ld      b, 0
        ld      hl, f_DestName
        OZ      GN_Del                          ; delete file
.loc_EDB1
        pop     af

.loc_EDB2
        pop     hl
        push    af
        ld      hl, DotClose_txt
        OZ      GN_Sop                          ; write string to std. output
        call    CloseDest
        ld      ix, (f_WildcardHandle)
        call    TstIX
        jr      z, loc_EDC9
        OZ      GN_Wcl                          ; close wildcard handler

.loc_EDC9
        ld      a, (f_CmdFlags)
        bit     7, a
        call    nz, EmptySelectedList
        pop     af
        jr      nc, loc_EDEE
        cp      RC_Esc
        scf
        jr      nz, loc_EDDF
        ld      a, 1
        OZ      OS_Esc                          ; Examine special condition
        jr      loc_EE11
.loc_EDDF
        push    af
        call    EmptySelectedList
        pop     af

.loc_EDE4
        OZ      GN_Err                          ; Display an interactive error box
        cp      RC_Quit
        jp      z, ExitFiler
        jr      loc_EE11

.loc_EDEE
        xor     a                               ; Fc=0

        ld      a, (f_CmdFlags)
        bit     6, a                            ; beep when done?
        jr      z, loc_EDFC

        push    af
        ld      a, 7
        OZ      OS_Out                          ; write a byte to std. output
        pop     af

.loc_EDFC
        bit     5, a                            ; page wait enable?
        jr      z, loc_EE11

        ld      a, (f_OutLnCnt)
        or      a
        call    nz, MayPageWait
        jr      nc, loc_EE11
        cp      RC_Esc
        jr      nz, loc_EDE4
        ld      a, 1
        OZ      OS_Esc                          ; Examine special condition

.loc_EE11
        call    ZeroIX
        ld      a, (f_ActiveWd)
        or      a
        jr      z, loc_EE24                     ; command window

.loc_EE1A
        xor     a                               ; command window
        ld      (f_ActiveWd), a
        ld      a, (f_SavedCmdPos)
        ld      (f_SelectorPos), a
.loc_EE24
        call    InitDisplay
        jp      MainLoop
;----
.CloseSource
        ld      ix, (f_SourceHandle)
        call    TstIX
        ret     z

        ld      a, (f_CmdFlags)
        bit     4, a                            ; DOR or file
        jr      z, clsrc_1

        ld      a, DR_Fre
        OZ      OS_Dor                          ; free DOR
        jr      clsrc_2

.clsrc_1
        xor     a
        OZ      GN_Cl                           ; close file/stream

.clsrc_2
        ld      (f_SourceHandle), ix
        ret
;----

.CloseDest
        ld      ix, (f_DestHandle)
        call    TstIX
        ret     z
        xor     a
        OZ      GN_Cl                           ; close file/stream
        ld      (f_DestHandle), ix
        xor     a
        inc     a                               ;Fz=0
        ret
;----

;       check that source and destination filenames are different

.CmpSrcDest
        or      a                               ; Fc=0
        ld      a, (f_CmdFlags)
        bit     0, a                            ; destination filename?
        ret     z
        ld      b, 0
        ld      hl, f_SourceName
        ld      de, f_DestName
        OZ      GN_Cme                          ; compare filenames
        ret     nz
        scf
        ret
;----

.FreeDOR
        call    TstIX
        ret     z
        ld      a, DR_FRE
        OZ      OS_Dor                          ; free DOR
        ret

;----

.OpenSource
        ld      hl, f_SourceName
        ld      a, (f_CmdFlags)
        bit     4, a                            ; source is DOR?
        ld      a, OP_DOR                       ; DOR info
        jr      nz, ops_1
        ld      a, OP_IN                        ; read
.ops_1
        call    OpenFile
        ld      (f_SourceHandle), ix
        ld      (f_SourceType), a
        ret
;----

.InputSrcName
        ld      de, f_SourceName
        ld      bc, $1501

.InputLine
        push    bc
        call    PrntCrsr
        pop     hl

.inp_1
        ld      c, 0

.inp_2
        push    bc
        ld      b, h
        ld      c, l
        call    Move_XY_BC                      ; original BC in
        pop     bc

        ld      b, NBUFSIZE
        ld      a, 1                            ; buffer contains data
        OZ      GN_Sip                          ; system input line routine
        jr      nc, inp_3

        cp      RC_Susp                         ; Suspicion of pre-emption
        scf
        jr      nz, inp_5
        call    PrntDotClose
        jr      inp_2

.inp_3
        ld      c, a                            ; remember end char

        push    bc
        push    hl
        ld      h, d                            ; buffer to HL
        ld      l, e
        ld      b, 0
        OZ      GN_Prs                          ; parse filename
        pop     hl
        pop     bc
        jr      nc, inp_4
        OZ      GN_Err                          ; Display an interactive error box
        cp      RC_Susp                         ; Suspicion of pre-emption
        jr      z, inp_1
        scf
        jr      inp_5

.inp_4
        ld      b, a
        ld      a, c                            ; input end char
        ld      c, b                            ; parse flags

.inp_5
                                                ; drop thru to turn cursor off

.ToggleCrsr
        push    af
        call    PrntCrsr
        pop     af
        ret

.CrsrRight
        call    RemoveHighlight

        ld      a, (f_ActiveWd)
        or      a
        jr      nz, right_2

;               command window

        ld      a, (f_NumDirEntries)
        or      a
        jr      z, right_6                      ; no dir entries, exit

;               selector position = min(ypos*3,numdirentries-1)

        ld      b, a
        ld      a, (f_SelectorPos)
        ld      c, a
        add     a, a
        add     a, c                            ; *3
        cp      b
        jr      c, right_1
        ld      a, (f_NumDirEntries)            ; !! ld a,b
        dec     a

.right_1
        push    af

        ld      hl, Init2_txt                   ; activate dir window
        OZ      GN_Sop
        ld      a, 1
        ld      (f_ActiveWd), a

        pop     af
        jr      right_5

;               directory window

.right_2
        ld      a, (f_NumDirEntries)
        ld      c, a
        ld      a, (f_SelectorPos)
        inc     a
        cp      c
        jr      nc, right_4                     ; past the last one, activate cmd window
        ld      c, a

.right_3
        sub     3                               ; check if mod(A,3)=0, if so activate cmd window
        jr      z, right_4
        jr      nc, right_3
        ld      a, c
        jr      right_5

.right_4
        ld      hl, Init1_txt
        OZ      GN_Sop                          ; write string to std. output

        xor     a                               ; command window
        ld      (f_ActiveWd), a

        ld      a, (f_SavedCmdPos)

.right_5
        ld      (f_SelectorPos), a

.right_6
        call    ApplyReverse
        jp      MainLoop

.CrsrLeft
        call    RemoveHighlight
        ld      a, (f_ActiveWd)
        or      a
        jr      nz, left_2

;               command window

        ld      a, (f_NumDirEntries)
        or      a
        jr      z, left_6                       ; no dir entries, exit

;               selector position = min(ypos*3+2,numdirentries-1)

        ld      b, a
        ld      a, (f_SelectorPos)
        ld      c, a
        add     a, a
        add     a, c                            ; *3
        add     a, 2
        cp      b
        jr      c, left_1
        ld      a, (f_NumDirEntries)            ; !! ld a,b
        dec     a

.left_1
        push    af

        ld      hl, Init2_txt
        OZ      GN_Sop                          ; write string to std. output
        ld      a, 1                            ; dir window
        ld      (f_ActiveWd), a

        pop     af
        jr      left_5

;               directory window

.left_2
        ld      a, (f_SelectorPos)
        ld      c, a
        or      a
        jr      z, left_4                       ; pos=0, activate cmd window

.left_3
        sub     3
        jr      z, left_4                       ; Mod(pos,3)=0, activate cmd window
        jr      nc, left_3
        ld      a, c                            ; otherwise just move left
        dec     a
        jr      left_5

.left_4
        ld      hl, Init1_txt                   ; activate cmd window
        OZ      GN_Sop
        xor     a                               ; command window
        ld      (f_ActiveWd), a

        ld      a, (f_SavedCmdPos)

.left_5
        ld      (f_SelectorPos), a

.left_6
        call    ApplyReverse
        jp      MainLoop

.CrsrUp
        call    RemoveHighlight
        ld      a, (f_ActiveWd)
        or      a
        jr      nz, up_6

;               command window

        ld      a, (f_SelectorPos)
        or      a
        jr      z, up_1                         ; top, need scrolling

        ld      a, (f_SelectorPos)              ; !! remove
        dec     a
        ld      (f_SavedCmdPos), a
        jr      up_4

.up_1
        ld      a, (f_SelectedCmd)
        or      a
        jr      z, up_2                         ; first command, redraw

        call    ScrollDown
        ld      a, (f_SelectedCmd)              ; !! push/pop would save one byte
        dec     a
        ld      (f_SelectedCmd), a
        call    GetCmdData
        call    PrntCmdString
        jr      up_5

.up_2
        ld      a, 12                           ; max_cmd
        sub     6                               ; window height
        jr      z, up_3                         ; !! eh?
        jr      c, up_3                         ; !! eh?
        ld      (f_SelectedCmd), a
        call    DrawCmdWindow

.up_3
        ld      a, 6
        ld      (f_SavedCmdPos), a

.up_4
        ld      (f_SelectorPos), a

.up_5
        call    ApplyReverse
        jp      MainLoop

;               directory window

.up_6
        ld      a, (f_SelectorPos)
        cp      3
        jr      c, up_7                         ; top, need scrolling
        sub     3
        jr      up_4                            ; otherwise move highlight up

.up_7
        ld      hl, (f_TopDirEntry)
        ld      a, h
        or      l
        jr      z, up_9                         ; first row, redraw
        ld      a, (f_NumDirEntries)
        cp      21
        jr      nc, up_8
        add     a, 3
        ld      (f_NumDirEntries), a

.up_8
        ld      bc, 3                           ; HL-=3
        or      a
        sbc     hl, bc
        ld      (f_TopDirEntry), hl
        push    hl
        call    ScrollDown
        pop     bc
        push    ix
        call    SkipBCMatches
        call    Print3Matches
        call    SaveFreeDOR
        pop     ix
        jr      up_5

.up_9
        ld      bc, 0
        push    ix
        call    SkipBCMatches

.up_10
        inc     bc
        call    FindMatch
        jr      nc, up_10
        pop     ix
        ld      h, b
        ld      l, c
        ld      de, 21
        OZ      GN_D16                          ; Unsigned 16bit division
        ld      a, d
        or      e
        jr      nz, up_11
        dec     hl

.up_11
        ld      de, 21
        OZ      GN_M16                          ; Unsigned 16bit multiplication
        ex      de, hl
        ld      hl, (f_TopDirEntry)
        or      a                               ; Fc=0
        sbc     hl, de
        ex      de, hl
        jr      z, up_12
        ld      (f_TopDirEntry), hl
        call    DrawDirWindow

.up_12
        ld      a, (f_NumDirEntries)
        dec     a
        ld      (f_SelectorPos), a
        jr      up_5
.CrsrDown
        call    RemoveHighlight
        ld      a, (f_ActiveWd)
        or      a
        jr      nz, down_5

;               command window

        ld      a, (f_SelectorPos)
        cp      6
        jr      nc, down_1
        inc     a
        ld      (f_SavedCmdPos), a
        jr      down_3

.down_1
        ld      a, (f_SelectedCmd)
        ld      c, a
        add     a, 6                            ; !! change these two into
        cp      12                              ; !! cp 6
        jr      nc, down_2
        call    ScrollUp
        ld      a, c
        inc     a
        ld      (f_SelectedCmd), a
        add     a, 6
        call    GetCmdData
        call    PrntCmdString
        jr      down_4

.down_2
        xor     a
        ld      (f_SelectedCmd), a
        ld      a, 13
        cp      8
        call    nc, DrawCmdWindow               ; !! nc?
        xor     a
        ld      (f_SavedCmdPos), a

.down_3
        ld      (f_SelectorPos), a

.down_4
        call    ApplyReverse
        jp      MainLoop

;               directory window

.down_5
        push    ix
        ld      a, (f_SelectorPos)
        cp      18
        jr      c, down_6
        ld      hl, (f_TopDirEntry)
        ld      bc, 21
        add     hl, bc
        ld      b, h
        ld      c, l
        call    SkipBCMatches
        jr      c, down_8
        call    ScrollUp
        ld      hl, (f_TopDirEntry)
        inc     hl
        inc     hl
        inc     hl
        ld      (f_TopDirEntry), hl
        call    Print3Matches
        call    SaveFreeDOR
        ld      a, (f_NumDirEntries)
        sub     3
        add     a, b
        ld      (f_NumDirEntries), a
        ld      a, (f_SelectorPos)
        sub     3
        ld      (f_SelectorPos), a

.down_6
        ld      a, (f_NumDirEntries)
        ld      c, a
        ld      a, (f_SelectorPos)
        add     a, 3
        cp      c
        jr      c, down_7
        ld      l, a
        ld      h, 0
        ld      e, 3
        ld      d, h
        OZ      GN_D16                          ; Unsigned 16bit division
        ld      a, (f_NumDirEntries)
        ld      c, a
        ld      a, 3
        sub     e
        ld      e, a
        ld      a, (f_SelectorPos)
        add     a, e
        cp      c
        jr      nc, down_8
        ld      a, c
        dec     a

.down_7
        pop     ix
        jr      down_3

.down_8
        pop     ix
        ld      bc, (f_TopDirEntry)
        ld      a, b
        or      c
        jr      z, down_9
        ld      bc, 0
        ld      (f_TopDirEntry), bc
        call    DrawDirWindow

.down_9
        xor     a
        jp      down_3

;----

;       scroll window down and clear the first line

.ScrollDown
        ld      hl, ScrollDown_txt
        OZ      GN_Sop                          ; write string to std. output
        ld      bc, 0
        call    Move_XY_BC
        ld      hl, ClearEOL_txt
        OZ      GN_Sop                          ; write string to std. output
        ret

;       scroll window up and move to the last line
.ScrollUp
        push    bc
        ld      hl, ScrollUp_txt
        OZ      GN_Sop                          ; write string to std. output
        ld      bc, 6
        call    Move_XY_BC
        pop     bc
        ret
;----
.InitDisplay
        call    GetMatchString
        xor     a
        ld      (f_NumDirEntries), a

        ld      hl, Wd41def_txt
        OZ      GN_Sop
        ld      hl, Wd42def_txt
        OZ      GN_Sop
        ld      bc, 0
        call    Move_XY_BC
        call    PrntTinyCaps

        ld      hl, f_MatchString               ; if match string is not "*" display "NM"
        ld      a, (hl)                         ; in left corner of dir window
        cp      '*'
        jr      nz, loc_F15B
        inc     hl
        ld      a, (hl)
        cp      $21
        jr      c, loc_F163

.loc_F15B
        ld      a, 'N'
        OZ      OS_Out
        ld      a, 'M'
        OZ      OS_Out

.loc_F163
        ld      hl, JustifyC_txt
        OZ      GN_Sop
        ld      hl, Directory_txt               ; "DIRECTORY "
        OZ      GN_Sop

        ld      hl, CurrentDir_txt              ; "."
        ld      bc, NBUFSIZE
        ld      de, f_SourceName
        OZ      GN_Fex

        push    ix
        ld      bc, NQ_Out
        OZ      OS_Nq                           ; get std. output
        ld      hl, f_SourceName
        ld      bc, 41
        ld      d, b
        ld      e, b
        OZ      GN_Fcm                          ; compress to stdout
        pop     ix

        ld      hl, JustifyN_txt                ; reverse title
        OZ      GN_Sop
        ld      bc, 0
        call    Move_XY_BC
        call    PrntUndrlnRvrs
        ld      a, $20+54
        call    ApplyA
        call    PrntUndrlnRvrs
        call    PrntTinyCaps

        call    TstIX
        jr      nz, loc_F1C6

        ld      a, OP_DOR
        ld      hl, f_SourceName
        call    OpenFile
        jr      c, loc_F1C9
        cp      Dm_Dev
        jr      z, loc_F1C6
        cp      Dn_Dir
        jr      z, loc_F1C6
        ld      a, DR_Fre
        OZ      OS_Dor
        jr      loc_F1C9

.loc_F1C6
        call    DrawDirWindow

.loc_F1C9
        call    DrawCmdWindow
        jp      ApplyReverse

; End of function InitDisplay
.ParentDir_txt
        defb    '.'
.CurrentDir_txt
        defb    '.'
        defb       0
;----
.DrawCmdWindow
        ld      hl, Init1_txt
        OZ      GN_Sop                          ; write string to std. output
        call    ClrWindow

        ld      b, 7
        ld      a, (f_SelectedCmd)
.loc_F1E0
        push    af
        call    GetCmdData
        call    PrntCmdString
        OZ      GN_Nln                          ; send newline (CR/LF) to std. output
        pop     af
        inc     a
        cp      13
        jr      z, loc_F1F2
        djnz    loc_F1E0

.loc_F1F2
        ld      a, 7
        sub     b
        ld      (f_LastCmdRow), a
        ret
; End of function DrawCmdWindow
;----

.DrawDirWindow
        push    ix
        ld      hl, Init2_txt                   ; init and clear wd2
        OZ      GN_Sop
        call    ClrWindow

.loc_F204
        ld      bc, (f_TopDirEntry)
        push    bc
        call    SkipBCMatches
        pop     de
        ld      bc, 7
        jr      nc, loc_F223
        ld      a, d
        or      e
        jr      z, loc_F23B                     ; TopDirEntry=0

        ld      de, 0
        ld      (f_TopDirEntry), de
        pop     ix
        push    ix
        jr      loc_F204

.loc_F223
        push    bc
        call    Print3Matches
        ld      a, b
        pop     bc
        ld      b, a
        jr      c, loc_F23B
        ld      b, 0
        dec     c
        jr      nz, loc_F236
        call    SaveFreeDOR
        jr      loc_F23B

.loc_F236
        call    FindMatch
        jr      nc, loc_F223

.loc_F23B
        ld      a, 7                            ; NumDirEntries=3*(7-C)+B
        sub     c
        ld      c, a
        add     a, a
        add     a, c
        add     a, b
        ld      (f_NumDirEntries), a
        pop     ix
        ret
;----

.Print3Matches
        ld      b, 3
        push    bc
        jr      p3m_2

.p3m_1
        push    bc
        call    FindMatch
        jr      nc, p3m_2
        pop     bc
        jr      p3m_4

.p3m_2
        call    FindNodeByName                  ; Print selection marker if needed
        ld      a, ' '
        jr      c, p3m_3
        ld      a, 1
        OZ      OS_Out                          ; write a byte to std. output
        ld      a, $F5                          ; bullet arrow right

.p3m_3
        OZ      OS_Out                          ; write a byte to std. output

        ld      a, (f_SourceType)               ; print files normally,
        cp      Dn_Fil                          ; dirs in tiny caps
        push    af
        call    nz, PrntTinyCaps
        ld      hl, f_StrBuffer
        call    PrntStr16
        pop     af
        call    nz, PrntTinyCaps
        ld      a, ' '
        OZ      OS_Out                          ; write a byte to std. output
        pop     bc
        djnz    p3m_1
        or      a

.p3m_4
        push    af                              ; return 3-mod(B,3) in B
        ld      a, 3
        sub     b
        ld      b, a
        pop     af
        ret
;----

;               Print until ctrl char, max 16 bytes, fill rest with blanks


.PrntStr16
        ld      b, 16

.pr16_1
        ld      a, (hl)
        inc     hl
        cp      $21
        jr      c, pr16_2
        OZ      OS_Out                          ; write a byte to std. output
        djnz    pr16_1
        ret
.pr16_2
        ld      a, ' '
.pr16_3
        OZ      OS_Out                          ; write a byte to std. output
        djnz    pr16_3
        ret

;----

.SkipBCMatches
        push    bc
        call    TstIX
        jr      z, loc_F2B5

        ld      a, DR_Dup
        OZ      OS_Dor
        jr      c, loc_F2CF
        push    bc
        pop     ix                              ; new DOR
        ld      a, DR_Son                       ; get child DOR
        OZ      OS_Dor
        jr      c, loc_F2CF
        ld      (f_SourceType), a
        jr      loc_F2BA

.loc_F2B5
        scf
        ld      a, RC_Eof                       ; End Of File
        jr      loc_F2CF

.loc_F2BA
        pop     bc
        push    bc
        inc     bc
        ld      a, (f_Flags2)
        or      2
        ld      (f_Flags2), a

.loc_F2C5
        call    FindMatch
        jr      c, loc_F2CF
        dec     bc
        ld      a, b
        or      c
        jr      nz, loc_F2C5

.loc_F2CF
        pop     bc
        ret
;----

.SaveFreeDOR
        push    af
        call    FreeDOR
        pop     af
        ret
;----

.FindMatch
        push    bc
        ld      a, (f_Flags2)
        bit     1, a
        jr      z, loc_F2E6                     ; continue from brother

        res     1, a
        ld      (f_Flags2), a
        jr      loc_F2EF                        ; continue with this DOR

.loc_F2E6
        ld      a, DR_SIB
        OZ      OS_Dor                          ; get brother DOR
        jr      c, loc_F305
        ld      (f_SourceType), a               ; minor type

.loc_F2EF
        ld      de, f_StrBuffer
        push    de
        ld      a, DR_RD
        ld      bc, $4E11
        OZ      OS_Dor                          ; get DOR name record
        pop     de
        jr      c, loc_F305

        ld      hl, f_MatchString
        OZ      GN_Wsm                          ; match filename segment to wildcard string
        jr      nz, loc_F2E6                    ; not match, loop back

.loc_F305
        pop     bc
        ret

;----

.GetMatchString
        ld      bc, NQ_Fnm
        OZ      OS_Nq                           ; get current filename match string
        ld      de, f_MatchString
        jp      CopyExtended

;----
.GetCmdData
        ld      hl, CmdTable                    ; CmdTable+2A
        add     a, a
        add     a, l
        ld      l, a
        jr      nc, loc_F31B                    ; !! removable if table doesn't cross page boundary
        inc     h
.loc_F31B
        ld      a, (hl)
        inc     hl
        ld      h, (hl)
        ld      l, a
        ret
;----
.PrntCmdString
        ld      a, ' '
        OZ      OS_Out                          ; write a byte to std. output
        call    PrntTinyCaps
        inc     hl
        inc     hl
        inc     hl
        OZ      GN_Sop                          ; write string to std. output
        jp      PrntTinyCaps
.ApplyReverse
        call    PrntReverse
        call    RemoveHighlight
        jp      PrntReverse
; End of function PrntCmdString
;----
.RemoveHighlight
        ld      a, (f_ActiveWd)
        or      a
        jr      nz, loc_F34C

;               command window

        ld      a, (f_SelectorPos)
        ld      c, a
        ld      b, 0
        call    Move_XY_BC
        ld      a, $20+24
        jr      loc_F354

.loc_F34C
        ld      a, (f_SelectorPos)
        call    CrsrToPosA
        ld      a, $20+18

.loc_F354
        jp      ApplyA

;----
.CrsrToPosA
        ld      l, a
        ld      h, 0
        ld      d, h
        ld      e, 3
        OZ      GN_D16                          ; HL/DE -> HL (DE=rem)
        ld      c, l
        inc     e
        xor     a
.loc_F363
        dec     e
        jr      z, loc_F36A
        add     a, $12
        jr      loc_F363
.loc_F36A
        ld      b, a
        jp      Move_XY_BC
; End of function CrsrToPosA

.GetYesNo
        ld      c, a
        call    PrntCrsr

        ld      hl, Questionmark_txt            ; " ? "
        OZ      GN_Sop                          ; write string to std. output

.yn_1
        ld      a, c
        ld      hl, Yes_txt                     ; "Yes"
        or      a
        jr      z, yn_2
        ld      hl, No_txt                      ; "No "
.yn_2
        OZ      GN_Sop                          ; write string to std. output

        ld      a, 8                            ; move to first char
        OZ      OS_Out
        OZ      OS_Out
        OZ      OS_Out

        OZ      OS_Pur                          ; purge keyboard buffer

.yn_3
        OZ      OS_In                           ; read a byte from std. input
        jr      c, yn_5
        or      a
        jr      z, yn_3

        cp      $0D
        jr      z, yn_5
        and     $DF
        cp      'N'
        jr      z, yn_4
        cp      'Y'
        jr      nz, yn_3

        ld      c, 0
        jr      yn_1

.yn_4
        ld      c, 1
        jr      yn_1


.yn_5
        jr      c, yn_6
        ld      a, c
.yn_6
        jp      ToggleCrsr

;----
.AddSelNode
        push    ix
        ld      a, (f_NumSelected)
        cp      255                             ; !! use inc
        jr      c, asn_1
        ld      a, RC_Room
        jr      asn_2

.asn_1
        or      a                               ; !! then dec
        call    z, GetPath
        jr      c, asn_4

        call    GetSelectedDirEntry

        ld      ix, (f_MemPool)
        ld      bc, 22
        xor     a
        OZ      OS_Mal                          ; Allocate memory
        jr      nc, asn_3

.asn_2
        OZ      GN_Err                          ; Display an interactive error box
        jr      asn_4

.asn_3
        ld      c, MS_S1
        rst     OZ_MPB                          ; Bind memory into S1

        push    bc
        ex      de, hl
        ld      hl, f_StrBuffer
        push    de

        xor     a                               ; zero link
        ld      (de), a
        inc     de
        ld      (de), a
        inc     de
        ld      (de), a
        inc     de

        ld      a, 22                           ; alloc length?
        ld      (de), a
        inc     de
        ld      a, 0
        ld      (de), a
        inc     de
        call    CopyFName                       ; from (HL)

        pop     hl
        pop     bc
        rst     OZ_MPB                          ; restore S1 binding

        call    QueueSelected

        ld      a, (f_SelectorPos)
        call    CrsrToPosA
        ld      a, 1                            ; 1,$F5 - Bullet arrow Right
        OZ      OS_Out
        ld      a, $F5
        OZ      OS_Out

        ld      a, (f_NumSelected)
        inc     a
        ld      (f_NumSelected), a

        call    ApplyReverse
        or      a                               ; Fc=0

.asn_4
        pop     ix
        ret
;----

;       Get path, copy it into SelectedList node

.GetPath
        push    ix
        call    GetDevDir
        ex      de, hl
        ld      de, f_SourceName
        sbc     hl, de
        inc     l
        ld      a, l                            ; device name length
        cp      NBUFSIZE
        jr      nc, loc_F460
        add     a, 5                            ; struct overhead

        ld      c, a
        ld      ix, (f_MemPool)
        xor     a
        ld      b, a
        OZ      OS_Mal                          ; Allocate memory
        jr      nc, loc_F43B
        OZ      GN_Err                          ; Display an interactive error box
        jr      loc_F460

.loc_F43B
        ld      c, MS_S1
        rst     OZ_MPB                          ; bind mem in S1
        push    bc
        ex      de, hl
        xor     a
        push    de
        ld      (de), a                         ; zero link
        inc     de
        ld      (de), a
        inc     de
        ld      (de), a
        inc     de
        push    de
        inc     de
        inc     a
        ld      (de), a                         ; type=path
        inc     de
        call    CopyFName                       ; from SourceName
        pop     de
        ld      a, c
        add     a, 5
        ld      (de), a                         ; allocation length
        pop     de
        pop     bc
        rst     OZ_MPB                          ; restore S1 binding
        ld      h, d
        ld      l, e
        call    QueueSelected
        or      a                               ; Fc=0

.loc_F460
        pop     ix
        ret
; End of function GetPath
;----

.QueueSelected
        push    iy
        ld      iy, f_SelectedList

.loc_F469
        call    TestLink
        jr      z, loc_F47D
        push    bc
        call    GetLinkCDE
        ld      b, c
        ld      c, MS_S1
        push    de
        pop     iy
        rst     OZ_MPB                          ; Bind bank B in slot C
        pop     bc
        jr      loc_F469

.loc_F47D
        ld      (iy+2), b
        ld      (iy+1), h
        ld      (iy+0), l
        pop     iy
        ret

;----
.EmptySelectedList
        push    iy

.esl_1
        ld      iy, f_SelectedList
        call    TestLink
        jr      z, esl_2
        call    GetLinkBHL
        call    FreeSelNode
        jr      esl_1
.esl_2
        xor     a
        ld      (f_NumSelected), a

        pop     iy
        ret
;----

;       Remove all selection marks, also remove highlight

.RemoveSelMarks
        ld      a, (f_NumDirEntries)
        ld      b, a
        or      a
        jr      z, rsm_2                        ; none selected, exit
        ld      a, b                            ; !! remove
.rsm_1
        push    bc
        ld      a, b
        dec     a
        call    RemoveSelMark
        pop     bc
        djnz    rsm_1
.rsm_2
        jp      ApplyReverse

; End of function RemoveSelMarks
;----

.RemoveSelMark
        call    CrsrToPosA
        ld      a, ' '
        OZ      OS_Out                          ; write a byte to std. output
        ret
;----

;       Remove node BHL from list IY

.FreeSelNode
        push    ix

.free_1
        call    GetLinkCDE
        ld      a, c
        or      e
        or      d
        jr      z, loc_F50D                     ; no more entries

        ld      a, b                            ; compare nodes
        cp      c
        jr      nz, free_2
        ld      a, h
        cp      d
        jr      nz, free_2
        ld      a, l
        cp      e
        jr      z, free_3

.free_2
        push    bc                              ; not same node, try next
        ld      b, c
        push    de
        pop     iy
        ld      c, MS_S1
        rst     OZ_MPB
        pop     bc
        jr      free_1

.free_3
        ld      c, MS_S2                        ; found, bind it into S2
        rst     OZ_MPB                          ; for list removal
        push    bc
        ld      a, d                            ; fix high byte for S2
        and     $3F
        or      $80
        ld      d, a
        push    iy
        ex      (sp), hl
        ex      de, hl                          ; DE=current, HL=node to remove
        ld      bc, 3                           ; copy link to remove from list
        ldir
        pop     hl
        pop     bc
        rst     OZ_MPB                          ; restore S2

        ld      c, MS_S1                        ; bind node into S1 to free memory
        ld      e, b
        rst     OZ_MPB
        push    hl
        pop     iy
        ld      a, e
        ld      c, (iy+3)                       ; allocation size
        ld      b, 0
        ld      ix, (f_MemPool)
        OZ      OS_Mfr                          ; Free memory

.loc_F50D
        pop     ix
        ret
;----

.GetLinkCDE
        ld      c, (iy+2)
        ld      d, (iy+1)
        ld      e, (iy+0)
        ret
; End of function GetLinkCDE
;----

.FindNodeByName
        ld      a, (f_NumSelected)              ; return with Fc=1 if no files in list
        or      a
        ccf
        ret     z

        push    ix
        call    GetDevDir
        ld      iy, f_SelectedList

.loc_F529
        call    GetNext
        jr      c, loc_F57F
        ld      a, (iy+4)
        cp      1
        jr      nz, loc_F529

.loc_F535
        push    iy                              ; compare entry name with SourceName,
        pop     hl                              ; loop back if not same
        ld      de, 5
        add     hl, de                          ; name buffer
        ld      de, f_SourceName
        ld      a, (iy+3)
        sub     5
        ld      c, a                            ; name length

.loc_F545
        ld      a, (de)
        cp      (hl)
        inc     hl
        inc     de
        jr      nz, loc_F529
        cp      $21
        jr      c, loc_F554                     ; ctrl char, matched
        dec     c
        jr      nz, loc_F545
        jr      loc_F529

.loc_F554
        call    GetNext
        jr      c, loc_F57F

        ld      a, (iy+4)
        cp      0
        jr      nz, loc_F535
        push    iy
        pop     hl
        ld      de, 5
        add     hl, de                          ; name buffer
        ld      de, f_StrBuffer

        ld      c, 17                           ; compare max 17 bytes for match
.loc_F56C
        ld      a, (de)
        cp      (hl)
        inc     hl
        inc     de
        jr      nz, loc_F554
        cp      $21
        jr      c, loc_F57B                     ; ctrl char, return match
        dec     c
        jr      nz, loc_F56C
        jr      loc_F554

.loc_F57B
        push    iy
        pop     hl
        or      a                               ; Fc=0

.loc_F57F
        pop     ix
        ret
; End of function FindNodeByName
;----

;       Follow IY to next node

.GetNext
        push    de
        call    GetLinkCDE
        ld      a, c
        or      d
        or      e
        ccf
        jr      z, gn_1                         ; no next, ret with Cf=1

        ld      b, c
        push    de
        pop     iy                              ; next into IY
        ld      e, b
        ld      c, MS_S1
        rst     OZ_MPB                          ; bind entry into S1

        ld      b, e                            ; ret wit Fc=0, B=bank, IY=new
        or      a

.gn_1
        pop     de
        ret
;----

.GetSelectedDirEntry
        ld      a, (f_SelectorPos)
        call    CrsrToPosA
        ld      a, 9                            ; cursor right
        OZ      OS_Out                          ; write a byte to std. output

        ld      de, f_StrBuffer
        ld      hl, $10                         ; #bytes
        ld      bc, NQ_Rds
        OZ      OS_Nq                           ; read text from the screen

        ld      de, f_StrBuffer                 ; remove spaces from strbuffer
        ld      h, d
        ld      l, e
        ld      b, 16
.loc_F5B5
        ld      a, (hl)
        inc     hl
        cp      ' '
        jr      z, loc_F5BD
        ld      (de), a
        inc     de
.loc_F5BD
        djnz    loc_F5B5
        xor     a
        ld      (de), a
        ret


; Clear current window and reset line count

.ClrWindow
        ld      hl, Cls_txt
        OZ      GN_Sop
        xor     a
        ld      (f_OutLnCnt), a
        ret

.PrntDotClose
        push    hl
        ld      hl, DotClose_txt
        jr      PrintStr

.PrntDotOpen
        push    hl
        ld      hl, DotOpen_txt
        jr      PrintStr

.PrntCrsr
        push    hl
        ld      hl, Cursor_txt
        jr      PrintStr

.PrntTinyCaps
        push    hl
        ld      hl, Tiny_txt
        OZ      GN_Sop                          ; write string to std. output
        ld      hl, Caps_txt
        jr      PrintStr

.PrntUndrlnRvrs
        push    hl
        ld      hl, Underline_txt
        OZ      GN_Sop                          ; write string to std. output
        pop     hl

.PrntReverse
        push    hl
        ld      hl, Reverse_txt

.PrintStr
        OZ      GN_Sop                          ; write string to std. output
        pop     hl
        ret
;----
.Move_XY_BC
        push    hl
        ld      hl, MoveXY_txt
        OZ      GN_Sop                          ; write string to std. output
        ld      a, b
        add     a, $20 ; ' '
        OZ      OS_Out                          ; write a byte to std. output
        ld      a, c
        add     a, $20 ; ' '
        OZ      OS_Out                          ; write a byte to std. output
        pop     hl
        ret
; End of function Move_XY_BC
;----

;       Apply screen changes to next A-32 bytes

.ApplyA
        push    af
        ld      hl, Apply_txt
        OZ      GN_Sop                          ; write string to std. output
        pop     af
        OZ      OS_Out                          ; write a byte to std. output
        ret

.AskName_txt
        defm    1,"3@",$20+13,$20+1
        defm    "Name :",0

.AskNewName_txt
        defm    1,"3@",$20+9,$20+3
        defm    "New name :",0

.Confirm_txt
        defm    1,"3@",$20+0,$20+5
        defm    "Confirm each file",0

.AskSource_txt
        defm    1,"3@",$20+11,$20+1
        defm    "Source :",0

.AskDest_txt
        defm    1,"3@",$20+6,$20+3
        defm    "Destination :",0

.Yes_txt
        defm    "Yes",0
.No_txt
        defm    "No ",0
.to_txt
        defm    " to ",0
.Questionmark_txt defm  " ? ",0

.Selected_txt
        defm    1,"3@",$20+21,$20+1
        defm    1,"T"
        defm    1,"R"
        defm    " SELECTED FILES "
        defm    1,"T"
        defm    1,"R"
        defb    0

.Wd41def_txt
        defm    1,"7#4",$20+1,$20+0,$20+24,$20+8,$83
        defm    1,"2C4"
        defm    1,"2JC"
        defm    1,"T"
        defm    "COMMANDS"
        defm    1,"2JN"
        defm    1,"3@",$20+0,$20+0
        defm    1,"R"
        defm    1,"U"
        defm    1,"2A",$20+24
        defm    1,"R"
        defm    1,"U"
        defm    1,"T"
        defm    1,"6#1",$20+1,$20+1,$20+24,$20+7
        defm    1,"2C1"
        defb    0

.Wd42def_txt
        defm    1,"7#4",$20+27,$20+0,$20+54,$20+8,$83
        defm    1,"6#2",$20+27,$20+1,$20+54,$20+7
        defm    1,"2C2"
        defm    1,"2C4"
        defb    0

.Wd43def_txt
        defm    1,"7#4",$20+1,$20+0,$20+80,$20+8,$83
        defm    1,"6#3",$20+1,$20+1,$20+80,$20+7
        defm    1,"2C3"
        defm    1,"2-C"
        defm    1,"2+S"
        defm    1,"2C4"
        defb    0

.Init1_txt
        defm    1,"2I1",0
.Init2_txt
        defm    1,"2I2",0
.Init3_txt
        defm    1,"2I3",0
.Directory_txt
        defm    "DIRECTORY ",0
.DotClose_txt
        defm    1,"2.]",0
.DotOpen_txt
        defm    1,"2.[",0
.ScrollUp_txt
        defm    1,$FF,0
.ScrollDown_txt
        defm    1,$FE,0
.Tiny_txt
        defm    1,"T",0
.Caps_txt
        defm    1,"L",0
.Underline_txt
        defm    1,"U",0
.MoveXY_txt
        defm    1,"3@",0
        defm    1,"2X",0                        ; !! unused $f74f
.ClearEOL_txt
        defm    1,"2C",$FD,0
.Cls_txt
        defm    1,"3@",$20+0,$20+0
        defm    1,"2C",$FE
        defb    0
.Cursor_txt
        defm    1,"C",0
.JustifyN_txt
        defm    1,"2JN",0
.JustifyC_txt
        defm    1,"2JC",0
.Reverse_txt
        defm    1,"R",0
.Apply_txt
        defm    1,"2A",0

.CmdTable
        defw    c_catf
        defw    c_catE
        defw    c_save
        defw    c_fetch
        defw    c_copy
        defw    c_rename
        defw    c_erase
        defw    c_seldir
        defw    c_seldev
        defw    c_exec
        defw    c_crdir
        defw    c_tcopy
        defw    c_nmatch

;       flags in first byte
;       bit     mask                                    tcp cpy del cat sve ftc exe sdi mtc ren sde mkd EPR

;       0       01      ask destination filename             X               X
;       1       02      display each file                    X   X           X
;       2       04                                       X           X       X        X   X       X   X   X
;       3       08      ignore selected                  X                   X   X    X   X       X   X   X
;       4       10      source is DOR                            X                            X
;       5       20      page wait enable                             X                                    X
;       6       40      beep when done                                   X
;       7       80                                       X   X   X   X   X                    X           X

.c_tcopy
        defb    $8C
        defw    TreeCopy
        defm    "Tree copy",0

.c_copy
        defb    $83
        defw    Copy
.aCopy
        defm    "Copy ",0

.c_erase
        defb    $92
        defw    Erase
        defm    "Erase ",0

.c_catf
        defb    $A4
        defw    CatalogueFiles
        defm    "Catalogue files",0

.c_save
        defb    $C0
        defw    Save
        defm    "Save to EPROM",0

.c_fetch
        defb    $0D
        defw    Fetch
        defm    "Fetch from EPROM",0

.c_exec
        defb    $08
        defw    Execute
        defm    "Execute ",0

.c_seldir
        defb     $0C
        defw    SelectDir
        defm    "Select Directory",0

.c_nmatch
        defb    $0C
        defw    NameMatch
        defm    "Name match",0

.c_rename
        defb    $90
        defw    Rename
        defm    "Rename ",0

.c_seldev
        defb    $0C
        defw    SelectDevice
        defm    "Select Device",0

.c_crdir
        defb    $0C
        defw    CreateDir
        defm    "Create Directory",0

.c_catE
        defb    $2C
        defw    CatalogueEPROM
        defm    "Catalogue EPROM",0
;----
.Copy

        ld      ix, (f_SourceHandle)
        OZ      OS_Gb                           ; get byte from file or device
        jr      c, copy_err
        ld      ix, (f_DestHandle)
        OZ      OS_Pb                           ; write byte A to handle IX
        jr      nc, Copy
        jr      copy_x
.copy_err
        cp      RC_Eof                          ; End Of File
        jr      z, copy_x
        scf
.copy_x
        ret
; End of function Copy
;----
.SelectDevice
        ld      hl, AskName_txt
        OZ      GN_Sop                          ; write string to std. output
.sdev_1
        call    GetDev
.sdev_2
        call    InputSrcName
        jr      nc, s_dev3
        cp      1
        scf
        jr      z, sdev_7
        jr      sdev_6
.s_dev3
        ld      hl, f_SourceName
        ld      b, 0
        OZ      GN_Pfs                          ; parse filename segment
        jr      nc, sdev_4
        cp      9
        scf
        jr      nz, sdev_6
        ld      hl, f_SourceName
        ld      bc, SP_Dev
        OZ      OS_Sp                           ; specify (set) parameter
        jr      sdev_1
.sdev_4
        bit     6, a
        jr      z, sdev_5
        bit     0, a
        jr      z, sdev_5
        and     $BE
        jr      nz, sdev_5
        ld      hl, f_SourceName
        ld      b, 0
        ld      de, 3
        ld      a, OP_DOR
        OZ      GN_Opf                          ; open - BHL=name, A=mode, DE=exp. name buffer, C=buflen
        jr      c, sdev_6
        call    SaveFreeDOR
        cp      Dm_Dev
        jr      nz, sdev_5
        ld      hl, f_SourceName
        ld      bc, SP_Dev
        OZ      OS_Sp                           ; specify (set) parameter
        xor     a
        ld      (f_SourceName), a
        call    ChgDir
        jr      sdev_7

.sdev_5
        ld      a, RC_Ivf                       ; Invalid filename
.sdev_6
        OZ      GN_Err                          ; Display an interactive error box
        cp      RC_Susp                         ; Suspicion of pre-emption
        jr      z, sdev_2
        scf
.sdev_7
        jp      ToggleCrsr
; End of function SelectDevice
;----
.Erase
        call    CloseSource
        ld      hl, f_SourceName
        ld      b, 0
        OZ      GN_Del                          ; delete file
        ld      (f_SourceHandle), ix
        ret
; End of function Erase
;----
.CatalogueEPROM
        call    ZeroIX
        call    PrntDotOpen
        xor     a
        ld      h, a
        ld      l, a
        OZ      OS_Erh                          ; Set (install) Error Handler
.cate_1
        ld      b, $20 ; ' '
        ld      hl, f_SourceName
        ld      a, $0F
        OZ      OS_Epr                          ; File Eprom Manipulation Interface
        jr      c, cate_3
        ld      hl, f_SourceName
        OZ      GN_Sop                          ; write string to std. output
        call    PntLF_pagewait
        jr      nc, cate_1
        push    af
.cate_2
        ld      b, $20 ; ' '
        ld      hl, f_SourceName
        ld      a, $0F
        OZ      OS_Epr                          ; File Eprom Manipulation Interface
        jr      nc, cate_2
        pop     af
.cate_3
        push    af
        xor     a
        ld      hl, FilerErrHandler
        OZ      OS_Erh                          ; Set (install) Error Handler
        pop     af
        cp      9
        scf
        ret     nz
        ld      hl, aEnd                        ; "*END*"
        OZ      GN_Sop                          ; write string to std. output
        jp      PntLF_pagewait
.aEnd
        defm    "*END*",0
; End of function CatalogueEPROM
;----
.Save
        call    CloseSource
        jr      c, save_x
        ld      b, 0
        ld      hl, f_SourceName
        ld      de, 3
        ld      a, OP_DOR
        OZ      GN_Opf                          ; get DOR information
        jr      c, save_x
        push    af
        call    FreeDOR
        pop     af
        cp      $11
        scf
        ld      a, RC_Ftm                       ; File Type Mismatch
        jr      nz, save_x
        ld      b, 0
        ld      hl, f_SourceName
        ld      a, 0
        OZ      OS_Epr                          ; blow RAM file to Eprom
.save_x
        ret
; End of function Save
;----
.Fetch
        call    PrntSrcDest
        call    InputSrcName
        jr      c, fetch_x
        ld      hl, f_SourceName                ; copy src to dest
        ld      de, f_DestName
        push    de
        call    CopyFName
        pop     de
        ld      bc, $1503
        call    InputLine
        jr      c, fetch_x
        ld      de, f_SourceName
        call    ExpandFname
        jr      c, fetch_x
        ld      a, 2
        ld      hl, f_DestName
        call    OpenFile                        ; write
        ld      (f_DestHandle), ix
        jr      c, fetch_x
        ld      b, 0
        ld      hl, f_SourceName
        ld      a, 3
        OZ      OS_Epr                          ; read file from Eprom into RAM file
.fetch_x
        ret
; End of function Fetch
;----
.Rename
        ld      hl, AskName_txt
        OZ      GN_Sop                          ; write string to std. output
        ld      hl, AskNewName_txt
        OZ      GN_Sop                          ; write string to std. output

        xor     a
        ld      (f_StrBuffer), a

        ld      bc, $1501
        call    Move_XY_BC
        ld      hl, ClearEOL_txt
        OZ      GN_Sop                          ; write string to std. output
        call    PrntCrsr

        ld      bc, NQ_Out
        OZ      OS_Nq
        ld      bc, $32                         ; local, buffer=50 bytes
        ld      hl, f_SourceName
        ld      de, 0
        OZ      GN_Fex                          ; expand a filename to stdout

        call    CloseSource

        ld      bc, $1503
        call    Move_XY_BC
        ld      hl, ClearEOL_txt
        OZ      GN_Sop                          ; write string to std. output

.ren_1
        ld      de, f_StrBuffer
        ld      c, 0

.ren_2
        push    bc
        ld      bc, $1503
        call    Move_XY_BC
        pop     bc

        ld      b, 17
        ld      a, 1
        OZ      GN_Sip                          ; system input line routine
        jr      nc, ren_3
        cp      RC_Susp
        scf
        jr      nz, ren_6
        call    PrntDotClose
        jr      ren_2

.ren_3
        ld      h, d
        ld      l, e
        ld      b, 0
        OZ      GN_Pfs                          ; parse filename segment
        jr      nc, ren_5

        cp      RC_Eof
        jr      nz, ren_4
        ld      a, RC_Ivf
.ren_4
        OZ      GN_Err                          ; Display an interactive error box
        cp      RC_Susp
        jr      z, ren_1
        scf
        jr      ren_6

.ren_5
        and     $DC                             ; wildcards used|device specified|.. used|. used|explicit directory used
        ld      a, RC_Ivf
        jr      nz, ren_4                       ; !! jump to ld a,RC_Ivf to save 2 bytes

        ld      b, 0
        ld      hl, f_SourceName
        ld      de, f_StrBuffer
        OZ      GN_Ren                          ; rename filename
        jr      c, ren_4

.ren_6
        jp      ToggleCrsr

; End of function Rename
;----
.Execute
        ld      ix, (f_SourceHandle)
        ld      b, 0
        ld      h, b
        ld      l, b
        OZ      DC_Icl                          ; Invoke new CLI
        ret     c
        call    ZeroIX
        ld      (f_SourceHandle), ix
        ret
; End of function Execute
;----
.TreeCopy
        call    PrntSrcDest
.tcopy_1
        ld      de, f_SourceName
        ld      bc, $1501
        call    VerifiedInput
        jr      c, tcopy_2
        ld      bc, $1503
        ld      de, f_DestName
        call    VerifiedInput
.tcopy_2
        jp      c, tcopy_11
        ld      hl, f_DestName
        ld      de, f_SourceName
.tcopy_3
        ld      a, (de)
        cp      $21
        jr      nc, tcopy_4
        ld      a, 7                            ; bell
        OZ      OS_Out                          ; write a byte to std. output
        jr      tcopy_1
.tcopy_4
        cp      (hl)                            ; check that src<>dest
        inc     hl
        inc     de
        jr      z, tcopy_3
        ld      hl, f_SourceName
        call    FindFilenameEnd
        ld      (f_SourceNameEnd), hl
        ld      (hl), '/'       ; append '//*',0
        inc     hl
        ld      (hl), '/'
        inc     hl
        ld      (hl), '*'
        inc     hl
        ld      (hl), 0
        ld      hl, f_DestName
        call    FindFilenameEnd
        ld      (f_DestNameEnd), hl
        ld      hl, f_SourceName
        ld      b, 0
        ld      a, 2                            ; forward scan, full path
        OZ      GN_Opw                          ; open wildcard handler
        jp      c, tcopy_11
        ld      (f_WildcardHandle), ix
        call    ClrWindow
        call    PrntDotOpen
.tcopy_5
        ld      de, f_SourceName
        ld      c, NBUFSIZE
        ld      ix, (f_WildcardHandle)
        OZ      GN_Wfn                          ; get next filename match from wc.handler
        jp      c, tcopy_9
        cp      Dm_Dev
        jr      z, tcopy_5
        ex      af, af'
        ld      hl, (f_SourceNameEnd)
        ex      de, hl
        or      a
        sbc     hl, de
        jr      z, tcopy_5
        jr      c, tcopy_5
        ex      af, af'
        push    af
        ld      hl, (f_SourceNameEnd)
        ld      de, (f_DestNameEnd)
        call    CopyFName
        pop     af
        cp      Dn_Dir                          ; dir?
        jr      nz, tcopy_7
        ld      a, 5                            ; create directory
        ld      hl, f_DestName
        call    OpenFile
        jr      c, tcopy_6
        call    FreeDOR
        jr      tcopy_5

.tcopy_6
        cp      $19
        jr      z, tcopy_5
        scf
        jr      tcopy_9
.tcopy_7
        ld      hl, aCopy                       ; "Copy "
        OZ      GN_Sop                          ; write string to std. output
        ld      hl, f_SourceName
        OZ      GN_Sop                          ; write string to std. output
        ld      hl, to_txt                      ; " to "
        OZ      GN_Sop                          ; write string to std. output
        ld      hl, f_DestName
        OZ      GN_Sop                          ; write string to std. output
        ld      hl, f_SourceName
        ld      a, 1                            ; read
        call    OpenFile
        ld      (f_SourceHandle), ix
        jr      c, tcopy_9
        ld      hl, f_DestName
        ld      a, 2                            ; write
        call    OpenFile
        ld      (f_DestHandle), ix
        jr      nc, tcopy_8
        push    af
        ld      ix, (f_SourceHandle)
        OZ      GN_Cls                          ; !! BUG: shouldn't this be GN_Cl?
        ld      (f_SourceHandle), ix
        pop     af
        jr      tcopy_9

.tcopy_8
        call    Copy
        jr      c, tcopy_9
        call    CloseSource
        call    CloseDest
        call    PntLF_pagewait
        jp      nc, tcopy_5

.tcopy_9
        push    af
        ld      ix, (f_WildcardHandle)
        call    TstIX
        jr      z, tcopy_10
        OZ      GN_Wcl                          ; close wildcard handler
        ld      (f_WildcardHandle), ix

.tcopy_10
        pop     af

.tcopy_11
        jr      nc, tcopy_12
        cp      RC_Eof                          ; End Of File
        jr      z, tcopy_12
        scf

.tcopy_12
        ret
;----

.VerifiedInput
        push    de
        push    bc

        call    InputLine
        jr      c, vi_1
        call    ExpandFname
        jr      c, vi_1
        ld      a, OP_DOR                       ; DOR information
        call    OpenFile
        jr      c, vi_1
        call    SaveFreeDOR
        cp      Dm_Dev
        jr      z, vi_2
        cp      Dn_Dir
        jr      z, vi_2
        ld      a, RC_Ftm                       ; File Type Mismatch

.vi_1
        cp      RC_Esc
        scf
        jr      z, vi_2
        OZ      GN_Err                          ; Display an interactive error box

.vi_2
        pop     bc
        pop     de
        ret     nc
        cp      RC_Susp                         ; Suspicion of pre-emption
        scf
        ret     nz
        call    PrntDotClose
        jr      VerifiedInput
        defb    $C9                             ; !! ret, not used
;----

.FindFilenameEnd
        ld      a, (hl)
        cp      $21                             ; loop unti ctrl char found
        ret     c
        inc     hl
        jr      FindFilenameEnd
;----

.CreateDir
        ld      hl, AskName_txt
        OZ      GN_Sop                          ; write string to std. output
        xor     a
        ld      (f_SourceName), a

.cdir_1
        call    InputSrcName
        jr      nc, cdir_3
        cp      RC_Esc                          ; Escape condition (e.g. ESC pressed)
        scf
        jr      z, cdir_4

.cdir_2
        OZ      GN_Err                          ; Display an interactive error box
        cp      RC_Susp                         ; Suspicion of pre-emption
        jr      z, cdir_1
        scf
        jr      cdir_4

.cdir_3
        ld      hl, f_SourceName
        ld      a, OP_DIR
        call    OpenFile
        jr      c, cdir_2
        call    FreeDOR

.cdir_4
        jp      ToggleCrsr
;----

.CatalogueFiles
        ld      a, (f_NumSelected)
        or      a
        jr      nz, cf_8

        ld      hl, AskName_txt
        OZ      GN_Sop                          ; write string to std. output
        call    PrntCrsr

.cf_1
        ld      de, f_SourceName
        ld      c, 0

.cf_2
        ld      b, NBUFSIZE

        push    bc
        ld      bc, $1501
        call    Move_XY_BC
        pop     bc

        ld      a, 1
        OZ      GN_Sip                          ; system input line routine
        jr      nc, cf_3

        cp      RC_Susp                         ; Suspicion of pre-emption
        jr      nz, cf_6
        call    PrntDotClose
        jr      cf_2

.cf_3
        ld      h, d                            ; if buffer is empty, use "*"
        ld      l, e
        ld      a, (hl)
        or      a
        jr      nz, cf_4
        ld      (hl), '*'
        inc     hl
        ld      (hl), 0                         ; !! ld (hl),a
        dec     hl

.cf_4
        call    ExpandFname
        jr      nc, cf_7

.cf_5
        OZ      GN_Err                          ; Display an interactive error box
        cp      RC_Susp                         ; Suspicion of pre-emption
        jr      z, cf_1

.cf_6
        scf

.cf_7
        call    ToggleCrsr
        jp      c, cf_18

        ld      b, 0
        ld      a, 2                            ; forward scan, full path
        ld      hl, f_SourceName
        OZ      GN_Opw                          ; open wildcard handler
        jr      c, cf_5

        ld      (f_WildcardHandle), ix

.cf_8
        call    ClrWindow
        call    PrntDotOpen

.cf_9
        ld      ix, (f_WildcardHandle)
        call    TstIX
        jr      nz, cf_10

        call    GetNextSelected
        ccf
        jr      nc, cf_18
        jr      cf_13

.cf_10
        ld      de, f_SourceName
        ld      c, NBUFSIZE
        OZ      GN_Wfn                          ; get next filename match from wc.handler
        jr      nc, cf_13

.cf_11
        push    af
        ld      ix, (f_WildcardHandle)
        call    TstIX
        jr      z, cf_12
        OZ      GN_Wcl                          ; close wildcard handler

.cf_12
        ld      (f_WildcardHandle), ix
        pop     af
        cp      RC_Eof
        jr      z, cf_18
        cp      RC_Esc
        scf
        jr      z, cf_18
        jr      cf_5

.cf_13
        ld      b, 0
        ld      hl, f_SourceName
        OZ      GN_Prs                          ; parse filename
        ld      a, b                            ; #segments
        dec     a
        ld      (f_nSrcSegments), a

        ld      a, OP_DOR
        call    OpenFile                        ; get DOR info
        jr      c, cf_11
        push    af
        ld      a, (f_nSrcSegments)
        or      a
        jr      z, cf_15
        ld      b, a

.cf_14
        ld      a, ' '
        OZ      OS_Out                          ; write a byte to std. output
        djnz    cf_14

.cf_15
        pop     af
        ld      (f_SourceHandle), ix
        cp      Dn_Fil
        jr      z, cf_16
        ld      hl, f_SourceName
        OZ      GN_Sop                          ; write string to std. output
        jr      cf_17

.cf_16
        call    CatFile

.cf_17
        ld      ix, (f_SourceHandle)
        call    SaveFreeDOR
        ld      (f_SourceHandle), ix
        call    PntLF_pagewait
        jr      nc, cf_9
        jr      cf_11

.cf_18
        ret
;----
.CatFile
        ld      hl, -17
        add     hl, sp
        ld      sp, hl
        ld      bc, 'N'*256+17
        call    ReadSrcRecord                   ; get N record
        call    PrntStr16
        ld      a, ' '
        OZ      OS_Out                          ; write a byte to std. output
        ld      bc, 'C'*256|6
        call    ReadSrcRecord                   ; get C record
        OZ      GN_Sdo                          ; convert real time to time to elapse
        ld      a, ' '
        OZ      OS_Out                          ; write a byte to std. output
        ld      bc, 'U'*256+6
        call    ReadSrcRecord                   ; get U record
        OZ      GN_Sdo                          ; convert real time to time to elapse
        ld      a, ' '
        OZ      OS_Out                          ; write a byte to std. output
        ld      bc, 'X'*256+4
        call    ReadSrcRecord                   ; get X record
        jr      c, loc_FCEA
        ld      bc, $8C0F
        OZ      OS_Nq                           ; enquire (fetch) parameter
        ld      de, 0
        ld      a, $A0
        OZ      GN_Pdn                          ; Integer to ASCII conversion

.loc_FCEA
        ld      hl, 17
        add     hl, sp
        ld      sp, hl
        ret
;----

;       Read source DOR record into stack buffer
;       Set BC before calling

.ReadSrcRecord
        ld      hl, 2
        add     hl, sp
        ld      d, h
        ld      e, l
        ld      ix, (f_SourceHandle)
        ld      a, DR_RD
        OZ      OS_Dor                          ; read DOR record
        ret

.ChDirDown
        push    ix
        ld      a, (f_ActiveWd)
        or      a
        jr      z, chd_2                        ; command window, exit

        call    GetSelectedDirEntry
        ld      hl, f_StrBuffer
        jr      ChDir

.ChDirUp
        push    ix
        ld      hl, ParentDir_txt

.ChDir
        ld      bc, NBUFSIZE
        ld      de, f_SourceName
        OZ      GN_Fex                          ; expand a filename
        jr      c, chd_2
        ld      a, OP_DOR
        ld      hl, f_SourceName
        call    OpenFile                        ; DOR info
        jr      c, chd_2
        call    SaveFreeDOR
        cp      Dn_Dir                          ; dir
        jr      z, chd_1
        cp      Dm_Dev
        jr      nz, chd_2

.chd_1
        call    VerifiedChDir
        jr      c, chd_2
        ex      (sp), ix
        call    SaveFreeDOR
        xor     a                               ; command window
        ld      (f_ActiveWd), a
        ld      (f_SelectorPos), a
        pop     ix
        call    InitDisplay
        jr      chd_3

.chd_2
        pop     ix

.chd_3
        jp      MainLoop
;----
.SelectDir
        ld      hl, AskName_txt
        OZ      GN_Sop                          ; write string to std. output
        call    GetDir
.sdir_1
        ld      de, f_SourceName
        ld      c, 0
.sdir_2
        ld      b, NBUFSIZE
        push    bc
        ld      bc, $1501
        call    Move_XY_BC
        call    PrntCrsr
        pop     bc
        ld      a, 1
        OZ      GN_Sip                          ; system input line routine
        call    ToggleCrsr
        jr      nc, sdir_3
        cp      RC_Susp                         ; Suspicion of pre-emption
        scf
        jr      nz, locret_FDDC
        call    PrntDotClose
        jr      sdir_2
.sdir_3
        ex      de, hl


;       Check that (HL) is directory or device

.ChgDir
        ld      a, (hl)
        cp      $21
        jr      c, loc_FDAC
        ld      a, OP_DOR
        call    OpenFile                        ; DOR info
        jr      c, loc_FD9A
        call    SaveFreeDOR
        cp      Dn_Dir
        jr      z, VerifiedChDir
        cp      Dm_Dev
        jr      z, VerifiedChDir

        ld      a, RC_Ftm
.loc_FD9A
        OZ      GN_Err                          ; Display an interactive error box
        cp      RC_Susp                         ; Suspicion of pre-emption
        jr      z, sdir_1
        scf
        jr      locret_FDDC

.VerifiedChDir
        ld      b, 0                            ; !! what is this trying to do?
        ld      hl, f_SourceName                ; !! probable bug
        OZ      GN_Pfs                          ; !! should check for some A flags?

.loc_FDAC
        ld      bc, SP_Dir
        OZ      OS_Sp                           ; Set current directory

        ld      a, (f_NumSelected)              ; exit if none selected
        or      a
        jr      z, locret_FDDC

        ld      iy, f_SelectedList              ; count entries in list
        ld      e, -1
.loc_FDBD
        call    GetNext
        inc     e
        jr      nc, loc_FDBD

        ld      a, e
        or      a
        jr      z, loc_FDD8

        ld      a, (iy+4)
        cp      1
        jr      nz, loc_FDD8                    ; type not 1

        push    iy
        pop     hl
        ld      iy, f_SelectedList
        call    FreeSelNode

.loc_FDD8
        call    GetPath
        or      a

.locret_FDDC
        ret

;----
.NameMatch
        ld      hl, AskName_txt
        OZ      GN_Sop                          ; write string to std. output
        ld      bc, NQ_Fnm
        OZ      OS_Nq                           ; enquire (fetch) parameter
        ld      de, f_SourceName
        call    CopyExtended
.nm_1
        call    InputSrcName
        jr      nc, nm_3
        cp      RC_Esc                          ; Escape condition (e.g. ESC pressed)
        scf
        jr      z, nm_4
.nm_2
        OZ      GN_Err                          ; Display an interactive error box
        cp      RC_Susp                         ; Suspicion of pre-emption
        jr      z, nm_1
        scf
        jr      nm_4
.nm_3
        ld      hl, f_SourceName
        ld      b, 0
        OZ      GN_Pfs                          ; parse filename segment
        jr      c, nm_2
        and     $7C
        ld      a, RC_Ivf                       ; Invalid filename
        jr      nz, nm_2
        ld      hl, f_SourceName
        ld      bc, SP_Fnm
        OZ      OS_Sp                           ; specify (set) parameter
        or      a
.nm_4
        jp      ToggleCrsr
; End of function NameMatch
;----
.ZeroIX
        ld      ix, 0
        ret

.PntLF_pagewait
        ld      a, (f_OutLnCnt)
        inc     a
        ld      (f_OutLnCnt), a
        cp      7
        ccf
        call    c, MayPageWait
        ret     c
        OZ      GN_Nln                          ; send newline (CR/LF) to std. output
        ret
;----
.MayPageWait
        push    hl
        push    ix
        xor     a
        ld      (f_OutLnCnt), a
        ld      bc, NQ_Tot
        OZ      OS_Nq                           ; get output-T handle
        ex      (sp), ix
        pop     bc
        ld      a, b
        or      c
        jr      nz, mpw_2                       ; output redirected, no page wait
        ld      a, (f_CmdFlags)
        bit     5, a                            ; page wait enable?
        jr      z, mpw_2                        ; no pw for this command

.mpw_1
        ld      a, 8
        OZ      OS_Sr                           ; Page wait
        jr      nc, mpw_2
        cp      RC_Susp                         ; Suspicion of pre-emption
        jr      z, mpw_1
        scf

.mpw_2
        pop     hl
        ret
; End of function MayPageWait
;----

.GetNextSelected
        ld      a, (f_NumSelected)
        or      a
        jr      z, loc_FED1

        ld      iy, f_SelectedList
.loc_FE66
        call    GetNext
        ret     c

        ld      a, (iy+4)                       ; type=1?
        cp      1
        jr      nz, loc_FE96

        ld      a, (iy+3)                       ; copy node name to SourceName
        sub     5
        ld      c, a
        ld      b, 0
        push    iy
        pop     hl
        ld      de, 5
        add     hl, de
        ld      de, f_SourceName
        ldir

        dec     hl                              ; add '/ into Sourcename if it doesn't
        dec     hl                              ; end with that yet
        dec     de
        ld      a, '/'
        cp      (hl)
        jr      z, loc_FE91
        ld      (de), a
        inc     de
        xor     a
        ld      (de), a

.loc_FE91
        call    FreeFirstSelNode
        jr      loc_FE66

.loc_FE96
        push    iy
        pop     hl
        ld      de, 5
        add     hl, de

        ld      de, f_SourceName                ; find end of SourceName
.loc_FEA0
        ld      a, (de)
        cp      $21
        jr      c, loc_FEA8
        inc     de
        jr      loc_FEA0

.loc_FEA8
        dec     de                              ; point DE after last '/'
        ld      a, (de)
        cp      '/'
        jr      nz, loc_FEA8
        inc     de

        ld      bc, 16                          ; append name from node
        ldir
        xor     a
        ld      (de), a

        ld      a, (f_NumSelected)
        dec     a
        ld      (f_NumSelected), a
        call    FreeFirstSelNode
        jr      loc_FEFB

.FreeFirstSelNode
        ld      iy, f_SelectedList
        push    iy
        call    GetLinkBHL
        call    FreeSelNode
        pop     iy
        ret

.loc_FED1
        ld      a, (f_Flags1)
        and     $80
        jr      z, loc_FEEB

        ld      ix, (f_WildcardHandle)
        ld      c, NBUFSIZE
        ld      de, f_SourceName
        OZ      GN_Wfn                          ; get next filename match from wc.handler
        ret     c
        cp      Dm_Dev
        jr      z, loc_FED1
        or      a
        ret

.loc_FEEB
        ld      a, (f_Flags2)
        bit     0, a
        jr      nz, loc_FEF6
        ld      a, 9
        scf
        ret

.loc_FEF6
        res     0, a
        ld      (f_Flags2), a

.loc_FEFB
        ld      de, f_SourceName
        jr      ExpandFname

.PrntSrcDest
        ld      hl, AskSource_txt
        OZ      GN_Sop
        ld      hl, AskDest_txt
        OZ      GN_Sop

.ResetSrcDestName
        xor     a
        ld      (f_SourceName), a
        ld      (f_DestName), a
        ret
;----

.TestLink
        ld      a, (iy+0)
        or      (iy+1)
        or      (iy+2)
        ret
;----

.GetLinkBHL
        ld      b, (iy+2)
        ld      h, (iy+1)
        ld      l, (iy+0)
        ret
;----
;       DE=name

.ExpandFname
        ld      h, d                            ; re-use name as expanded name buffer
        ld      l, e
        ld      bc, NBUFSIZE
        OZ      GN_Fex                          ; expand a filename
        ret
;----

;       HL=name, A=mode

.OpenFile
        ld      d, h                            ; re-use name as expanded name buffer
        ld      e, l
        ld      bc, NBUFSIZE
        OZ      GN_Opf
        ret

;       GetDevDir can be made shorter by moving ld de,... first in GetDir and
;       reusing code there

.GetDevDir
        call    GetDev
        ld      bc, NQ_Dir
        OZ      OS_Nq                           ; current directory
        jr      CopyExtended

.GetDev
        ld      bc, NQ_Dev
        OZ      OS_Nq                           ; get current device
        ld      de, f_SourceName
        jr      CopyExtended

.GetDir
        ld      bc, NQ_Dir
        OZ      OS_Nq                           ; get current directory
        ld      de, f_SourceName

;       copy data from (BHL) to (DE) until control char

.CopyExtended
        OZ      GN_Rbe                          ; Read byte at extended address
        ld      (de), a
        cp      $21
        ccf
        ret     nc
        inc     hl
        inc     de
        jr      CopyExtended
;----

;       copy (HL) into (DE) until control char, return # bytes copied

.CopyFName
        ld      c, 0
.cfn_1
        ld      a, (hl)
        ld      (de), a
        inc     c
        cp      $21
        ccf
        ret     nc
        inc     hl
        inc     de
        jr      cfn_1
