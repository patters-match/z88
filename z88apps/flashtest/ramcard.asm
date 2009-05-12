module ramcardtest

xdef ramtest


.ramtest
                    di
                    ld      a,($04d3)      ; get the bank currently in segment 3
                    ex      af,af'         ;
                    exx                    ; want to return 0 or address in hl'
                    xor     a              ; pass 0
                    ld      c,$d3          ; segment register 3
.nxtpass
                    ld      e,a            ; save the pass number in e
                    exx                    ; get the
                    ld      a,b            ; number of
                    exx                    ; banks to
                    ld      b,a            ; test (b%)...
                    ld      a,e            ; restore pass number
                    ld      d,$40          ; first bank in slot 1
.nxtbank
                    out     (c),d          ; get the bank into segment 3
                    ld      hl,$c000       ; going to use segment 3
.nxtbyte
                    ld      a,e            ; restore the pass number
                    cp      $00            ; on pass 0?
                    jr      nz,ntpass0     ; jump if not
                    ld      a,$55          ; do a quick $55-and-$aa test...
.quickie
                    ld      (hl),a         ; store the pattern
                    cp      (hl)           ; stored ok?
                    jr      nz,failed      ; failed if not
                    rlca                   ; next pattern
                    jr      nc,quickie     ; back to check using $aa
                    ld      a,$00          ; ...finally set contents to $00 on pass 0
                    jr      setconts
.ntpass0
                    cp      $01            ; on pass 1?
                    jr      nz,ntpass1     ; jump if not
                    ld      a,(hl)         ; get the contents
                    cp      $00            ; still the same as previous pass?
                    jr      nz,failed      ; jump if not
                    ld      a,$55          ; set contents to $55 on pass 1
                    jr      setconts       ;
.ntpass1
                    cp      $02            ; on pass 2?
                    jr      nz,ntpass2     ; jump if not
                    ld      a,(hl)         ; get the contents
                    cp      $55            ; still the same as previous pass?
                    jr      nz,failed      ; jump if not
                    ld      a,$aa          ; set contents to $aa on pass 2
                    jr      setconts       ;
.ntpass2
                    ld      a,(hl)         ; pass 3 - get the contents
                    cp      $aa            ; still the same as the previous pass?
                    jr      nz,failed      ; jump if not
                    xor     a              ; set contents to $00 on pass 3
.setconts
                    ld      (hl),a         ; set the contents
                    inc     hl             ; next location in the bank
                    xor     a              ; clear a
                    cp      l              ; done all
                    jr      nz,nxtbyte     ; of the bank
                    cp      h              ; when
                    jr      nz,nxtbyte     ; hl=0
                    ld      a,e            ; restore the pass number
                    inc     d              ; next bank to test
                    djnz    nxtbank        ; back to do the test?
                    inc     a              ; next pass
                    cp      $04            ; done them all yet?
                    jr      nz,nxtpass     ; do another if not
                    xor     a              ;
                    ld      d,a            ; passed - return 0 in h & l
                    jr      setretrn       ;
.failed
                    ld      a,e            ; restore the pass number
.setretrn
                    exx                    ; last address->hl'
                    ld      h,a            ; pass = $00, fail = pass number
                    exx
                    ld      a,d
                    exx
                    ld      l,a            ; pass = $00, fail = bank number
                    ex      af,af'         ; get the original bank for segment 3
                    ld      c,$d3          ; segment register 3 again...
                    out     (c),a          ; restore the original bank to segment 3
                    ei
                    ret
