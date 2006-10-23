module CLITables

include "sysvar.def"

xdef    Key2MetaTable                           ; this one must be in the same page
xdef    CLI2KeyTable

;       entries in descending order
;       low limit, meta key, key table

.Key2MetaTable
        defb    $FC, QUAL_SPECIAL, <crsr
        defb    $F8, QUAL_SPECIAL|QUAL_SHIFT, <crsr
        defb    $F4, QUAL_SPECIAL|QUAL_CTRL, <crsr
        defb    $F0, QUAL_SPECIAL|QUAL_ALT, <crsr
        defb    $E9, 0, 0
        defb    $E0, QUAL_SPECIAL, <spec
        defb    $D9, 0, 0
        defb    $D0, QUAL_SPECIAL|QUAL_SHIFT, <spec
        defb    $C9, 0, 0
        defb    $C8, QUAL_SPECIAL, <c
        defb    $C0, QUAL_SPECIAL|QUAL_CTRL, <spec
        defb    $B9, 0, 0
        defb    $B8, QUAL_SPECIAL, <a
        defb    $B0, QUAL_SPECIAL|QUAL_ALT, <spec
        defb    $A0, 0, 0
        defb    $80, QUAL_ALT, <ctrl
        defb    $20, 0, 0
        defb    $00, QUAL_CTRL, <ctrl

;       length mask, character codes
;       Careful - can't cross page boundary

.crsr   defb    3                               ; cursor keys
        defm    "LRDU"

.spec   defb    7                               ; enter tab del (esc) menu index help
        defm    " ETX?MIH"

.ctrl   defb    $1F                             ; control chars
        defm    "=ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        defb    $5B,$5C,$5D,$A3,$2D             ; [\]£-

.c      defb    0                               ; ctrl
        defm    "C"

.a      defb    0                               ; alt
        defm    "A"


.CLI2keyTable
        defb    2*12                            ; table length
        defb    'D',$FE                         ; D down
        defb    'E',$E1                         ; E enter
        defb    'H',$E7                         ; H help
        defb    'I',$E6                         ; I index
        defb    'L',$FC                         ; L left
        defb    'M',$E5                         ; M menu
        defb    'R',$FD                         ; R right
        defb    'T',$E2                         ; T tab
        defb    'U',$FF                         ; U up
        defb    'X',$E3                         ; X del
        defb    'C',$C8                         ; C ctrl
        defb    'A',$B8                         ; A alt
