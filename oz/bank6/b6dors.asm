; -----------------------------------------------------------------------------
; Bank 6 @ S3           ROM offset $bf6f
;
; $Id$
; -----------------------------------------------------------------------------

        Module B6DORs

	include	"director.def"

	org	$ff90


	defb	$ff

.CalendarDOR
	defp	0,0			; parent
	defp	ClockDOR,6		; brother
.CalendarTopics
.CalendarCommands
.CalendarHelp
	defp	0,0			; son
	defb	$83, CalendarDORe-$PC	; DOR type, sizeof

        defb    '@',18,0,0              ; info, info sizeof, 2xreserved
        defb    'C',0                   ; application key letter, bad app RAM
        defw    0,40,0                  ; env. size, unsafe and safe workspace
        defw    $e7f1                   ; entry point !! absolute
        defb    0,0,0,1                 ; bindings
        defb    AT_Good|AT_Popd         ; appl type
        defb    AT2_Ie                  ; appl type 2

        defb    'H',12                  ; help, sizeof
        defp    CalendarTopics,6 ; topics
        defp    CalendarCommands,6        ; commands
        defp    CalendarHelp,6    ; help
        defp    $8000,7                 ; token base

        defb    'N',CalendarDORe-$PC-1  ; name, length
        defm    "Calendar",0
.CalendarDORe
	defb	$ff

.ClockDOR
	defp	0,0			; parent
	defp	$fd9a,7			; brother !! absolute
.ClockTopics
.ClockCommands
.ClockHelp
	defp	0,0			; son
	defb	$83, ClockDORe-$PC	; DOR type, sizeof

        defb    '@',18,0,0              ; info, info sizeof, 2xreserved
        defb    'T',0                   ; application key letter, bad app RAM
        defw    0,0,0                   ; env. size, unsafe and safe workspace
        defw    $e7ee                   ; entry point !! absolute
        defb    0,0,0,1                 ; bindings
        defb    AT_Good|AT_Popd         ; appl type
        defb    AT2_Ie                  ; appl type 2

        defb    'H',12                  ; help, sizeof
        defp    ClockTopics,6 	; topics
        defp    ClockCommands,6   ; commands
        defp    ClockHelp,6    	; help
        defp    $8000,7                 ; token base

        defb    'N',ClockDORe-$PC-1  ; name, length
        defm    "Clock",0
.ClockDORe
	defb	$ff

