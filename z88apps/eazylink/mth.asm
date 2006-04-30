; *************************************************************************************
; EazyLink - Fast Client/Server Remote File Management with PCLINK II protocol
;
; (C) Gunther Strube (gbs@users.sourceforge.net) 1990-2005
;
; EazyLink is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; EazyLink is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with EazyLink;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
; *************************************************************************************


     MODULE Mth

     XDEF EazyLinkTopics
     XDEF EazyLinkCommands
     XDEF EazyLinkHelp

     include "defs.asm"


; ********************************************************************************************************************
;
; topic entries for FlashStore popdown...
;
.EazyLinkTopics     DEFB 0                                                      ; start marker of topics

; 'COMMANDS' topic
.topic_cmds         DEFB topic_cmds_end - topic_cmds                            ; length of topic definition
                    DEFM "Commands", 0                                          ; name terminated by high byte
                    DEFB 0                                                      ; high byte of rel. pointer
                    DEFB 0                                                      ; low byte of rel. pointer
                    DEFB @00000000
                    DEFB topic_cmds_end - topic_cmds
.topic_cmds_end
                    DEFB 0


; *****************************************************************************************************************************
;
.EazyLinkCommands   DEFB 0                                                      ; start of commands

; <>D Enable :COM.0 logging
.cmd_d              DEFB cmd_d_end - cmd_d                                      ; length of command definition
                    DEFB EazyLink_CC_dbgOn                                      ; command code
                    DEFM "D", 0                                                 ; keyboard sequense
                    DEFM "Enable :COM.0 logging", 0
                    DEFB (cmd_d_help - EazyLinkHelp) / 256                      ; high byte of rel. pointer
                    DEFB (cmd_d_help - EazyLinkHelp) % 256                      ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_d_end - cmd_d                                      ; length of command definition
.cmd_d_end

; <>Z Disable :COM.0 logging
.cmd_z              DEFB cmd_z_end - cmd_z                                      ; length of command definition
                    DEFB EazyLink_CC_dbgOff                                     ; command code
                    DEFM "Z", 0                                                 ; keyboard sequense
                    DEFM "Disable :COM.0 logging", 0
                    DEFB (cmd_z_help - EazyLinkHelp) / 256                      ; high byte of rel. pointer
                    DEFB (cmd_z_help - EazyLinkHelp) % 256                      ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_z_end - cmd_z                                      ; length of command definition
.cmd_z_end
                    DEFB 0                                                      ; end of commands

; *******************************************************************************************************************
;
.EazyLinkHelp
                    DEFB 12
                    DEFM "EazyLink V5.0.5 - flexible file transfer", $7F
                    DEFB $7F
                    DEFM "Copyright (C) by G.Strube (gbs@users.sf.net) 1991-2006", $7F
                    DEFB $7F
                    DEFM "This software is released as Open Source (GPL licence).", $7F
                    DEFM "Get latest news, updates for EazyLink and other Z88", $7F
                    DEFM "software at http://z88.sf.net or http://www.rakewell.com"
                    DEFB 0

.cmd_d_help
                    DEFM $7F
                    DEFM "Enabling serial port logging will create two files that", $7F
                    DEFM "contains a copy of bytes received and sent through the", $7F
                    DEFM "serial port ('/serdump.in' and '/serdump.out'). Both ", $7F
                    DEFM "files are created in the default device (Panel settings).", $7F
                    DEFM "WARNING: This is a debugging feature and can write very", $7F
                    DEFM "large files to RAM and will slow down serial port transfer."
                    DEFB 0
.cmd_z_help
                    DEFM $7F
                    DEFM "Disables serial port logging (and closes dump files).", $7F
                    DEFM "Previous dump files will be cleared when re-enabling", $7F
                    DEFM "serial port logging."
                    DEFB 0
