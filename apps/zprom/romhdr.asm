    MODULE RomHeader

    ORG $3FC0

; Application front DOR, in top bank of EPROM, starting at $3FC0

     INCLUDE "applic.def"


.appl_front_dor     DEFB 0, 0, 0                ; link to parent...
                    DEFB 0, 0, 0                ; no help DOR
                    DEFW Zprom_DOR              ; offset of code
                    DEFB Zprom_bank             ; in bank
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
                    DEFB $02                    ; $3FFC size of EPROM (2 banks of 16K = 32K)
                    DEFB 0                      ; $3FFD subtype of card ...
.eprom_adr_3FFE     DEFM "OZ"                   ; $3FFE card is an application EPROM
.EpromTop
