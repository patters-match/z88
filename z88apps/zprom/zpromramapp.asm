; Zprom App Install File

    include "applic.def"
    include "mthzprom.def"

    defw    $5AA5                               ; APP header
    defb    2                                   ; 2 bank
    defb    0                                   ; No patch
    defw    0                                   ; DOR pointer, offset (relative in bank)
    defb    Zprom_bank                          ; DOR pointer, relative card bank (top of card)
    defb    0                                   ; no even bank required

    defw    0                                   ; AP0, Zprom application, offset of bank 3F
    defw    10706                               ; AP0, Zprom application, length of bank 3F

    defw    Zprom_MTH_START                     ; AP1, Zpropm MTH, offset of bank 3E
    defw    ZPROM_MTH_END - ZPROM_MTH_START     ; AP1, Zpropm MTH, length of bank 3E

    defl    0                                   ; bank 2, none
    defl    0                                   ; bank 3, none
    defl    0                                   ; bank 4, none
    defl    0                                   ; bank 5, none
    defl    0                                   ; bank 6, none
    defl    0                                   ; bank 7, none
