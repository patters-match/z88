; -----------------------------------------------------------------------------
; Bank 2 @ S3           ROM offset $bf6f
;
; $Id$
; -----------------------------------------------------------------------------

        Module B2DORs

        include "director.def"
        include "..\bank7\appdors.def"

        org     $ff6f

        defs    43 ($ff)                ; !! to be removed when using makeapp

.PrEdDOR
        defp    0,0                     ; parent
        defp    PanelDOR,2              ; brother
        defp    0,0                     ; son
        defb    $83, PrEdDORe-$PC       ; DOR type, sizeof

        defb    '@',18,0,0              ; info, info sizeof, 2xreserved
        defb    'E',0                   ; application key letter, bad app RAM
        defw    $26c,0,$20              ; env. size, unsafe and safe workspace
        defw    $c000                   ; entry point !! absolute
        defb    3,0,0,6                 ; bindings
        defb    AT_Good|AT_Ones         ; appl type
        defb    0                       ; appl type 2

        defb    'H',12                  ; help, sizeof
        defp    PrinterEdTopics&$3fff,7 ; topics
        defp    PrinterEdCommands&$3fff,7        ; commands
        defp    PrinterEdHelp&$3fff,7    ; help
        defp    $8000,7                 ; token base

        defb    'N',PrEdDORe-$PC-1  ; name, length
        defm    "PrinterEd",0
.PrEdDORe
        defb    $ff

.PanelDOR
        defp    0,0                     ; parent
        defp    $ff1d,7                 ; brother !! absolute
        defp    0,0                     ; son
        defb    $83, PanelDORe-$PC      ; DOR type, sizeof

        defb    '@',18,0,0              ; info, info sizeof, 2xreserved
        defb    'S',0                   ; application key letter, bad app RAM
        defw    0,0,$20                 ; env. size, unsafe and safe workspace
        defw    $c00a                   ; entry point !! absolute
        defb    0,0,0,6                 ; bindings
        defb    AT_Good|AT_Popd         ; appl type
        defb    0                       ; appl type 2

        defb    'H',12                  ; help, sizeof
        defp    PanelTopics&$3fff,7     ; topics
        defp    PanelCommands&$3fff,7   ; commands
        defp    PanelHelp&$3fff,7       ; help
        defp    $8000,7                 ; token base

        defb    'N',PanelDORe-$PC-1  ; name, length
        defm    "Panel",0
.PanelDORe
        defb    $ff

