; -----------------------------------------------------------------------------
; $Id$
; -----------------------------------------------------------------------------

        Module Kernel

        org     $8000


; this file is here just to give binary correct name

; to assemble:
;       mpm -bvg -IC:\z88\ozdef bank7\lowram.asm
;       mpm -bvg -IC:\z88\ozdef bank7\appdors.asm
;       mpm -bvg -IC:\z88\ozdef @kernel.prj
;
; now we tell lowram.asm real kernel addresses
;       mpm -bv -DFINAL -IC:\z88\ozdef bank7\lowram.asm
;
; and insert lowram.bin into kernel
;       mpm -bv -IC:\z88\ozdef @kernel.prj

