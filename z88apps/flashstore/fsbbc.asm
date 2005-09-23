	MODULE flash15

; *****************************************************************************
; FlashStore for BBC BASIC
; (C) Thierry Peycru & Gunther Strube, 1997-98
;
; $Header$
;
; v1.1	Release version (TP).
;
; v1.2	Switch bug fixed (TP).
;
; v1.3a	free size, file number, quit (TP).
;
; v1.3b	overflow check, wildcard expand, card presence during catalog (TP).
;
; v1.4.0	3.12.97 (GS)
;		Save to Flash Eprom re-written (using block-write operations).
;		Directories created automatically on "Fetch File" command.
;		New std. library calls used.
;		Ext. addressing relative (bank numbers 00h-3fh, offset 0000h-3fffh).
;		New algorithm for free space implemented.
;		Battery Low condition is checked before Flash Eprom write operations.
;
; v1.4.1	5.12.97 - 9.12.97 (GS)
;		More new library calls to manipulate Flash File Eprom.
;
; v1.5.0	9.12.97 (GS)
;		"Restore" command implemented.
;		(fetch all active files to defined RAM path)
;
; v1.5.1	11.12.97 (GS)
;		"Save" command now implemented with library call to save the actual
;		file. All File (Flash) Eprom core functionality performed by
;		standard library routines. FlashStore now only contains user
;		interface.
;
; v1.5.2	12.12.97 (GS)
;		Cosmetic changes to various prompt and banner texts.
;		Saving of files now displays size of File Header too.
;
; v1.5.3	13.12.97 (GS)
;		Default path inserted at "Save" command line. Easier to identify
;		where wildcards may have affect...
;
;		"Empty Eprom" displayed when no files are available on "Catalogue".
;
;		"No files saved" when no files were found to be saved, otherwise
;		"xxx file(s) has been saved"...
;
;		During save, when a file name already exists, that file entry will
;		only be marked as deleted, when a new copy has been successfully
;		saved to the Flash Eprom.
;
; v1.5.4	25.12.97 (GS)
;		Bug fixed in <FetchFilename> library routine.
;		Restore extended with overwrite prompt logic.
;		Catalogue now displayed with or without deleted files (user prompt
;		at start).
;		Save message slightly changed; "1 file saved" / "x files saved"
;
; v1.5.5	26.12.97 (GS)
;		Formatting the Flash Eprom to File Eprom Format will not exit
;		FlashStore anymore.
;		FlashStore uses new lib. routines to Format File Eprom which
;		recognises no. of banks on Flash Eprom and blows Header accordingly.
;		Format command now only formats available blocks on the card
;		- not always 16 (might be smaller cards)!
;
; v1.5.6	28.12.97 (GS)
;		Std. File Eprom library changed to handle pseudo File Eproms.
;		FlashStore now displays the File Eprom size and a blinking message
;		if it sees a pseudo File Eprom (smaller than the physical size
;		of the actual Card).
;
; v1.5.7	7.1.98 (GS)
;		Save command: Main window cleared before battery check.
;		Re-linked with changed library routines <FlashEprWriteBlock>,
;		<FlashEprWriteByte>
;
;		9.1.98 (GS)
;		Fetch command: Input line now preset with "/" (always first char
;		of filename when searching)
;
; v1.5.9	13.1.98 (GS)
;		Filename buffers moved into I/O area (which is only used during
;		save files). The filename buffers are only temporary...
;		Proper error message if file was not blown properly to Flash Eprom.
;		Bug fixed in Fetch File:
;		RAM file NOT deleted, if user didn't want to overwrite RAM file!
;		Statistical information moved towards center of screen.
;		FlashStore aborted if user prompts No on initial format request.
;
; v1.5.10 15.1.98 (GS)
;		File is re-saved if it failed being blown to Flash Eprom.
;
; V1.5.11
;		Zero length files are ignored...
;
; $History: fs.asm $
; 
; *****************  Version 1  *****************
; User: Gbs          Date: 9-05-98    Time: 16:47
; Created in $/Z88/Applications/FlashStore/basic
;
; *****************************************************************************


if DOS | Z88
	include "#error.def"
	include "#syspar.def"
	include "#director.def"
	include "#stdio.def"
	include "#saverst.def"
	include "#memory.def"
	include "#integer.def"
	include "#fileio.def"
	include "#interrpt.def"
	include "#flashepr.def"
	include "#dor.def"
endif
if QDOS
	include "#error_def"
	include "#syspar_def"
	include "#director_def"
	include "#stdio_def"
	include "#saverst_def"
	include "#memory_def"
	include "#integer_def"
	include "#fileio_def"
	include "#interrpt_def"
	include "#flashepr_def"
	include "#dor_def"
endif



; Library references
;

lib CreateFilename			; Create file(name) (OP_OUT) with path
lib FlashEprCardId			; Return Intel Flash Eprom Device Code (if card available)
lib FlashEprBlockErase		; Format Flash Eprom Block (64K)
lib FlashEprStdFileHeader	; Write std. File Eprom Header on Flash Eprom.
lib FlashEprFileDelete		; Mark file as deleted on Flash Eprom
lib FlashEprFileSave		; Save RAM file to Flash Eprom
lib FileEprType			; Check for presence of Standard File Eprom (format)
lib FileEprFreeSpace		; Return free space on File Eprom
lib FileEprCntFiles 		; Return total of active and deleted files
lib FileEprFirstFile		; Return pointer to first File Entry on File Eprom
lib FileEprNextFile 		; Return pointer to next File Entry on File Eprom
lib FileEprFilename 		; Copy filename into buffer (null-term.) from cur. File Entry
lib FileEprFileSize 		; Return file size of current File Entry on File Eprom
lib FileEprFindFile 		; Find File Entry using search string (of null-term. filename)
lib FileEprFetchFile		; Fetch file image from File Eprom, and store it to RAM file
lib CheckBattLow			; Check Battery Low condition


; start of BBC BASIC program (PAGE)
; - the complete program is resident in segment 0 ($2000 - $3FFF).
;
ORG $2300

DEFC BufferStart = $3B00 	; buffer located after "BBC BASIC" program and below LOMEM
DEFC BufferSize = 1024		; 1024 byte buffer for file I/O


; basic lines
; 0000 *NAME FlashStore
; 0000 LOMEM=&3F00			; LOMEM just below start of segment 1...
; 0000 CALL &2330

DEFM $14 & 0 & 0 & $2A & "NAME FlashStore" & $0D
DEFM $0B & 0 & 0 & $D2 & "=&3F00" & $0D
DEFM $0B & 0 & 0 & $D6 &" &2330" & $0D & 0

;16+4+11+11+1=43 so 5 $FF
DEFM $FF & $FF & $FF & $FF & $FF


; *****************************************************************************
;
; We are at $2330
;
; Application start...
;
.app_start
				LD	SP,($1ffe)		; install safe application stack permanently
									; FlashStore will not return to BBC BASIC...
				xor	a
				ld	b,a
				ld	hl,errhan
				CALL_OZ os_erh 		; install FlashStore Error Handler
				ld	a, SC_ena
				CALL_OZ os_esc 		; enable ESC detection
				call app_main
.kill
				xor	a
				CALL_OZ(os_bye)		; perform suicide, focus to Index...



; ****************************************************************************
;
; FlashStore Error Handler
;
.errhan
				RET	Z
				CP	rc_susp
				JR	Z,dontworry
				CP	rc_esc
				JR	Z,akn_esc
				CP	rc_quit
				JR	Z,kill
				cp a
				RET
.akn_esc
				LD	A,1				; acknowledge ESC detection
				CALL_OZ os_esc
.dontworry
				CP A
				RET



; ************************************************************************
;
.app_main
				CALL greyscr
				CALL main_win
				call cls

				; Chip identification
				call FlashEprCardId
				jr	nc, disp_chip
.unkn_chip
				LD	HL, cbad_ms
				CALL DispErrMsg
				jr	kill
.disp_chip
				ld	hl,chok_ms
				call sopnln

				; Check if File Eprom is inserted in slot 3...
				ld	c,3
				call FileEprType
				jr	nc,format_good
.format_error
				call cls
				ld	hl,frmt_br
				call wbar
				ld	hl,fmt1_ms
				call sopnln
				ld	hl,fmt2_ms
				ld	de,yes_ms
				call yesno
				ret	nz					; user didn't want to format... abort application

				call z,format_main
				ret	nz					; user prompted again No to format...
				ret	c					; an error occurred during format
.format_good
				CALL FileEpromStatistics 	; parse for free space and total of files...

				call cls
				LD	HL,cmd0_br
				call wbar
				ld	hl,t704_ms
				CALL_OZ gn_sop
				ld	hl,free
				call IntAscii
				CALL_OZ gn_sop
				ld	hl,bfre_ms
				CALL_OZ gn_sop

				ld	hl,t705_ms
				CALL_OZ gn_sop
				ld	hl,file
				call IntAscii
				CALL_OZ gn_sop
				ld	hl,fisa_ms
				CALL_OZ gn_sop

				ld	hl,t706_ms
				CALL_OZ gn_sop
				ld	hl,fdel
				call IntAscii
				CALL_OZ gn_sop
				ld	hl,fdel_ms
				CALL_OZ gn_sop

				ld	hl,menu_ms
				CALL_OZ gn_sop

				CALL DisplayEpromSize

				LD	HL, app_main
				PUSH HL					; return address for functions...
.inp_main
				CALL rdch
				JR	NC,no_inp_err
				CP	A
				JR	inp_main
.no_inp_err
				OR	$20
				CP	's'
				JP	Z, save_main
				CP	'f'
				JP	Z, fetch_main
				CP	'r'
				JP	Z, restore_main
				CP	'c'
				JP	Z, catalog_main
				CP	'!'
				JP	Z, format_main
				CP	'q'
				JP	Z, kill				; exit this application deliberately...
				JR	inp_main

.frmt_br			DEFM "FILE EPROM NOT FOUND." & 0
.fmt1_ms			DEFM 1&"BUnformatted Flash Eprom."&1&"B" & 0
.fmt2_ms			DEFM 13&"Do you want to format it? " & 0
.chok_ms			defm " " & 0
.cbad_ms			defm 1&"BFlash Eprom not found in slot 3."&1&"B"&0

.menu_ms
;
; v1.3b - new display window
; zlab logo
				defm 1&"3@"&88&34&1&"2?"&"@"&1&"2?"&"A"&1&"2?"&"B"&1&"2?"&"C"&$0D&$0A
				defm 1&"3@"&88&35&1&"2?"&"D"&1&"2?"&"E"&1&"2?"&"F"&1&"2?"&"G"&$0D&$0A
				defm 1&"3@"&88&36&1&"2?"&"H"&1&"2?"&"I"&1&"2?"&"J"&1&"2?"&"K"&$0D&$0A

				; menu commands
				defm 1 & "3@" & 32 & 33
				defm 1 & "B C" & 1 & "B Catalogue"& $0D & $0A
				defm 1 & "B S" & 1 & "B Save" & $0D & $0A
				defm 1 & "B F" & 1 & "B Fetch" & $0D & $0A
				defm 1 & "B R" & 1 & "B Restore" & $0D & $0A
				defm 1 & "B !"&1&"B Format"&$0D&$0A
				defm 1 & "B Q"&1&"B Quit"
				defm 1 & "3@" & 76 & 38 & 1 & "2+TAWAITING COMMAND" & 1 & "3-TC"
				defb 0

.t701_ms			defm 1 & "3@" & 55 & 34 & 0
.t704_ms			defm 1 & "3@" & 55 & 35 & 0
.t705_ms			defm 1 & "3@" & 55 & 36 & 0
.t706_ms			defm 1 & "3@" & 55 & 37 & 0
.bfre_ms			defm " bytes free" & 0
.fisa_ms			defm " files saved" & 0
.fdel_ms			defm " files deleted" & 0


; ****************************************************************************
;
.DisplayEpromSize
				LD	HL, t701_ms
				CALL_OZ(GN_Sop)

				LD	C,3
				CALL FileEprType

				LD	H,0
				LD	L,B			; total of banks as defined by File Eprom Header
				CALL m16
				PUSH HL

				CALL FlashEprCardId
				SLA	B
				SLA	B			; blocks * 4 = total banks of card
				LD	H,0
				LD	L,B
				CALL m16			; total of banks on physical Flash Eprom

				POP	DE
				SBC	HL,DE		; physical banks = virtual banks?
				JR	Z, true_size

				LD	HL, flashvdu
				CALL_OZ(Gn_Sop)
				CALL DispEprSize
				LD	HL, ksize
				CALL_OZ(Gn_sop)
				LD	HL, pseudo
				CALL_OZ(Gn_Sop)
				LD	HL,fepr
				CALL_OZ(Gn_Sop)
				RET

.true_size		LD	HL, tinyvdu
				CALL_OZ(Gn_Sop)
				CALL DispEprSize
				LD	HL, ksize
				CALL_OZ(Gn_sop)
				LD	HL,fepr
				CALL_OZ(Gn_Sop)
				RET

.DispEprSize		LD	B,D
				LD	C,E
				LD	HL,2
				CALL IntAscii
				CALL_OZ(Gn_Sop)	; display size of File Eprom
				RET

.flashvdu 		DEFM 1 & "2+F"
.tinyvdu			DEFM 1 & "2+T" & 0
.ksize			DEFM "K " & 0
.pseudo			DEFM "PSEUDO " & 0
.fepr			DEFM "FILE EPROM" & 1 &"3-TF" & 0




; ****************************************************************************
;
; Multiply HL * 16, result in HL.
;
.m16
				LD	B,4
.multiply_loop 	ADD	HL,HL
				DJNZ multiply_loop	; banks * 16K = size of card in K
				RET



; ****************************************************************************
;
; Application routines
;
.main_win
				PUSH HL
				LD	HL,main_win_sq
				CALL_OZ gn_sop
				POP	HL
				RET
.main_win_sq
				defm 1&138&"="&64&63&32&39&39&39&38&36&32
				defm 1&138&"="&65&63&128&63&63&48&128&128&3
				defm 1&138&"="&66&63&128&63&63&3&15&60&48
				defm 1&138&"="&67&63&1&57&57&49&1&1&1
				defm 1&138&"="&68&32&32&35&39&39&32&38&38
				defm 1&138&"="&69&15&60&48&63&63&128&3&6
				defm 1&138&"="&70&128&128&3&63&63&128&35&22
				defm 1&138&"="&71&9&25&57&57&57&1&33&17
				defm 1&138&"="&72&38&38&38&38&38&39&32&63
				defm 1&138&"="&73&6&7&6&6&6&54&128&63
				defm 1&138&"="&74&22&55&22&22&22&23&128&63
				defm 1&138&"="&75&17&33&17&9&9&49&1&63

				defm 1&"7#1"&33&32&95&40&131
				defm 1&"2C1"&1&"4+TUR"&1&"2JC"
				defm 1&"3@  FLASHSTORE v1.5.11"&1&"3@  "
				defm 1&"2A"&95
				defm 1&"4-TUR"&1&"2JN"
				defm 1&"7#1"&33&33&95&39&128
				defm 1&"2C1"&1&"3+CS"
				defb 0

.cmd0_br			defm "(C) 1998 Zlab & InterLogic" & 0



; ****************************************************************************
;
; Display Window bar (below windows title) with caption text identified by HL pointer
;
.wbar
				PUSH HL
				LD	HL,bar1_sq
				CALL_OZ gn_sop
				POP	HL
				CALL_OZ gn_sop
				LD	HL,bar2_sq
				CALL_OZ gn_sop
				RET
.bar1_sq			defm 1&"4+TUR"&1&"2JC"&1&"3@  "&0
.bar2_sq			defm 1&"3@  "&1&"2A"&95&1&"4-TUR"&1&"2JN"&0



; ***************************************************************************
;
; Save Files to Flash Eprom
;
.save_main		call cls
				call CheckBatteryStatus
				ret	c

				ld	hl,0
				ld	(savedfiles),hl	; reset counter to No files saved...
.fname_sip
				call cls
				ld	hl,fsv1_br
				call wbar
				ld	hl,wcrd_ms
				call sopnln

				LD	HL,fnam_ms
				CALL_OZ gn_sop

				ld	bc,$0080
				ld	hl,curdir
				ld	de,buf3
				CALL_OZ gn_fex 		; pre-insert current path at command line...
				ld	a,'/'
				ld	(de),a
				inc	de
				xor	a
				ld	(de),a
				inc	c				; C = set cursor to char after path...

				LD	DE,buf3
				LD	A,@00100011
				LD	B,$40
				LD	L,$20
				CALL_OZ gn_sip
				jr	nc,save_mailbox
				CP	RC_SUSP
				JR	Z, fname_sip
				CP	RC_ESC
				RET	Z
				CALL ReportStdError
				RET

.fsv1_br			DEFM "SAVE FILES TO FLASH EPROM" & 0
.wcrd_ms			DEFM " Wildcards are allowed." & 0
.fnam_ms			DEFM 1 & "2+C Filename: " & 0

.save_mailbox
				call cls
				ld	hl,fsv2_br
				call wbar

				ld	bc,$0080
				ld	hl,buf3
				ld	de,buf1
				CALL_OZ gn_fex
				CALL C, ReportStdError			; illegal wild card string
				JR	C, end_save

				xor	a
				ld	b,a
				LD	HL,buf1
				CALL_OZ gn_opw
				CALL C, ReportStdError			; wild card string illegal or no names found
				JR	C, end_save				; no files to save...
				LD	(wcard_handle),IX
.next_name
				CALL CheckBatteryStatus
				JR	C, save_completed			; abort operation if batteries are low

				LD	DE,buf2
				LD	C,$80					; write found name at (buf2) using max. 128 bytes
				LD	IX,(wcard_handle)
				CALL_OZ(GN_Wfn)
				JR	C, save_completed
				CP	Dn_Fil					; file found?
				JR	NZ, next_name
.re_save
				CALL file_save 				; Yes, save to Flash File Eprom...
				JR	NC, next_name				; saved successfully, fetch next file..

				CP	RC_BWR
				JR	Z, re_save				; not saved successfully to Flash Eprom, try again...
				CALL ReportStdError 			; display all other std. errors...
.save_completed
				LD	IX,(wcard_handle)
				CALL_OZ(GN_Wcl)				; All files parsed, close Wild Card Handler
.end_save
				LD	HL,(savedfiles)
				LD	A,H
				OR	L
				CALL NZ, DispFilesSaved
				CALL Z, DispNoFiles
				CALL DispErrMsg				; wait for ESC key, then back to main menu
				RET

.DispFilesSaved	PUSH AF
				PUSH HL
				ld	hl,savedfiles				; display no of files saved...
				call IntAscii
				CALL_OZ gn_sop
				LD	HL,ends0_ms				; " file"
				CALL_OZ(GN_Sop)
				POP	HL
				LD	A,H
				XOR	L
				CP	1
				JR	Z, endsx
				LD	A, 's'
				CALL_OZ(OS_Out)
.endsx			LD	HL, ends1_ms
				POP	AF
				RET

.DispNoFiles		LD	HL, ends2_ms				; "No files saved".
				RET

.filesaved		LD	HL,(savedfiles)			; another file has been saved...
				INC	HL
				LD	(savedfiles),HL			; savedfiles++
				RET

.curdir			defm "." & 0
.fsv2_br			defm "SAVING TO FLASH EPROM ..." & 0
.ends0_ms 		defm " file" & 0
.ends1_ms 		defm " has been saved." & $0D & $0A & 0
.ends2_ms 		defm "No files saved." & $0D & $0A & 0
.savf_ms			defm $0D & $0A & "Saving " & 0

.fext0_ms 		defm "File size : (Header = " & 0
.fext1_ms 		defm " & File image = " & 0
.fext2_ms 		defm ") " & 0
.byte_ms			defm " bytes" & $0D & $0A & 0



; **************************************************************************
;
; Save file to Flash Eprom, filename at (buf2), null-terminated.
;
.file_save
				LD	BC,$0080
				LD	HL,buf2
				LD	DE,buf3					; expanded filename may have 128 byte size...
				LD	A, op_in
				CALL_OZ(GN_Opf)
				RET	C

				LD	A,C
				SUB	7
				LD	(nlen),A					; length of filename excl. device name...
				LD	A,fa_ext
				LD	DE,0
				CALL_OZ(OS_Frm)				; file size in DEBC...
				CALL_OZ(Gn_Cl) 				; close file

				LD	(flen),BC
				LD	(flen+2),DE

				XOR  A
				OR   B
				OR   C
				OR   D
				OR   E
				JP   Z, file_zero_length

				LD	A,(nlen)					; calculate size of File Entry Header
				ADD	A,4+1					; total size = length of filename + 1 + 32bit file length
				LD	H,0
				LD	L,A
				LD	(flenhdr),HL
				LD	HL,0
				LD	(flenhdr+2),HL 			; size of File Entry Header

				LD	HL,savf_ms
				CALL_OZ gn_sop
				LD	HL,buf3					; display expanded filename
				call sopnln

				LD	DE,buf3+6 				; point at filename (excl. device name), null-terminated
				CALL FindFile					; find File Entry of old file, if present

				; "File size : (header = xx & file image = xxxx) xxxxx bytes ..."

				ld	hl,fext0_ms
				CALL_OZ gn_sop
				ld	hl,flenhdr
				call IntAscii
				CALL_OZ gn_sop
				ld	hl,fext1_ms
				CALL_OZ gn_sop
				ld	hl,flen
				call IntAscii
				CALL_OZ gn_sop
				ld	hl,fext2_ms
				CALL_OZ gn_sop

				ld	hl,(flen)
				ld	bc,(flenhdr)
				add	hl,bc
				ld	(flen),hl
				ld	a,(flen+2)
				adc	a,0
				ld	(flen+2),a				; flen = flen + flenhdr

				ld	hl,flen
				call IntAscii
				CALL_OZ gn_sop

				ld	hl,byte_ms
				CALL_OZ gn_sop

				ld	bc, BufferSize
				ld	de, BufferStart
				ld	hl, buf3
				call FlashEprFileSave
				jr	c, filesave_err			; write error or no room for file...

				CALL DeleteOldFile				; mark previous file as deleted, if any...
				CALL filesaved
				LD	HL,fsok_ms
				CALL sopnln
				CP	A
				RET
.filesave_Err
				CP	RC_BWR
				JR	Z, file_wrerr				; not written properly to Flash Eprom
				CP	RC_VPL
				JR	Z, file_wrerr				; VPP not set (should not happen)
				SCF
				RET							; otherwise, return with std. OZ errors...

.file_wrerr		LD	HL, blowerrmsg
				CALL DispErrMsg
				SCF
				RET

.file_zero_length
				LD	HL,buf3					; display expanded filename
				call sopnln
				LD	HL,zerolen_msg
				call sopnln
				CP   A
				RET


.fsok_ms			DEFM " Done."& $0D & $0A & 0
.blowerrmsg		DEFM "File was not saved properly - will be re-saved." & $0D & $0A & 0
.zerolen_msg		DEFM "File has zero length - ignored." & $0D & $0A & 0


; **************************************************************************
;
; Find file on Eprom (in slot 3), identified by DE pointer string (null-terminated),
; and preserve pointer in (flentry).
;
; IN:
;		DE = pointer to search string (filename)
;
.FindFile
				LD	A,$FF
				LD	H,A
				LD	L,A
				LD	(flentry),HL
				LD	(flentry+2),A				; preset found File Entry to <None>...

				LD	C, 3
				CALL FileEprFindFile			; search for filename on File Eprom...
				RET	C						; File Eprom or File Entry was not available
				RET	NZ						; File Entry was not found...

				LD	A,B
				LD	(flentry+2),A
				LD	(flentry),HL				; preserve ptr to current File Entry...
				RET



; **************************************************************************
;
; Mark File Entry as deleted, if a valid pointer is registered in (flentry).
;
; IN:
;		BHL = (flentry)
;
.DeleteOldFile
				LD	A,(flentry+2)
				CP	$FF					; Valid pointer to File Entry?
				RET	Z

				LD	B,A
				LD	HL,(flentry)
				CALL FlashEprFileDelete		; Mark old File Entry as deleted
				RET	C					; File Eprom not found or write error...

				LD	HL, oldv_ms
				CALL sopnln
				RET

.oldv_ms			DEFM "Previous version deleted." & 0



; **************************************************************************
;
; Fetch file from File Eprom.
; User enters name of file that will be searched for, and if found,
; fetched into a specified RAM file.
;
.fetch_main
				call cls
				ld	hl,fetch_br
				call wbar
				ld	hl,exct_ms
				call sopnln
				ld	hl,fnam_ms
				CALL_OZ gn_sop

				LD	HL,buf1				; preset input line with '/'
				LD	(HL),'/'
				INC	HL
				LD	(HL),0
				DEC	HL
				EX	DE,HL

				LD	A,@00100011
				LD	BC,$4001
				LD	L,$20
				CALL_OZ gn_sip
				jr	c,sip_error
				CALL_OZ gn_nln

				call file_fetch
				JR	C, fetch_error
				RET
.sip_error
				CP	rc_susp
				JR	Z,fetch_main
				RET
.fetch_error
				PUSH AF
				LD	B,0
				LD	HL, buf3				; an error occurred, delete file...
				CALL_OZ(Gn_Del)
				POP	AF
				CALL_OZ gn_err 			; display I/O error (or related)
				RET

.fetch_br 		DEFM "FETCH FROM EPROM" & 0
.exct_ms			DEFM " Enter exact filename (no wildcard)."&0
                                        


; **************************************************************************
;
.file_fetch
				LD	C, 3
				LD	DE,buf1
				CALL FileEprFindFile	; search for <buf1> filename on File Eprom...
				ret	c				; File Eprom or File Entry was not available
				ret	nz				; File Entry was not found...

				ld	a,b				; File entry found
				ld	(fbnk),a
				ld	(fadr),hl 		; preserve pointer to found File Entry...
.get_name
				ld	hl,ffet_ms		; get destination filename from user...
				CALL_OZ gn_sop
				ld	de,buf1
				LD	A,@00100011		; buffer has filename
				LD	BC,$4000
				LD	L,$20
				CALL_OZ gn_sip
				jr	nc,open_file
				cp	rc_susp
				jr	z,get_name
				ret	c				; user aborted...
.open_file
				CALL_OZ(GN_Nln)
				ld	hl,buf1
				call PromptOverWrFile
				jr	c, create_file 	; file doesn't exist (or in use)
				jr	z, create_file 	; file exists, user acknowledged Yes...
				CP	A
				RET					; user acknowledged no, just return to main...
.create_file
				ld	bc,$80
				ld	hl,buf1
				ld	de,buf3			; generate expanded filename...
				CALL_OZ (Gn_Fex)
				ret	c				; invalid filename...

				ld	b,0				; (local pointer)
				ld	hl,buf3			; pointer to filename...
				call CreateFilename 	; create file with and path
				ret	c

				CALL_OZ gn_nln 		; IX = handle of created file...
				ld	hl,fetf_ms
				CALL_OZ gn_sop
				ld	hl,buf3
				call sopnln			; display created RAM filename (expanded)...

				LD	A,(fbnk)
				LD	B,A
				LD	HL,(fadr)
				LD	C, 3
				CALL FileEprFetchFile	; fetch file from slot 3 Eprom
				PUSH AF				; to RAM file, identified by IX handle
				CALL_OZ(Gn_Cl) 		; then, close file.
				POP	AF
				RET	C

				LD	HL, done_ms
				CALL DispErrMsg
				CP	A				; Fc = 0, File successfully fetched into RAM...
				RET

.fetf_ms			DEFM 1 & "2+C Fetching file to " & 0
.done_ms			DEFM " Completed." & $0D & $0A & 0
.ffet_ms			DEFM 13&" Fetch as : " & 0
.exis_ms			DEFM 13&" Overwrite RAM file : " & 0



; ****************************************************************************
;
; Restore ALL active files into a user defined RAM device (or path)
;
.restore_main
				CALL cls
				LD	HL,rest_banner
				CALL wbar
				LD	HL,defdst_msg
				CALL sopnln
				LD	HL,dest_msg
				CALL_OZ gn_sop
				CALL GetDefaultDevice
				LD	DE,buf1
				LD	A,@00100011
				LD	BC,$4007
				LD	L,$20
				CALL_OZ gn_sip
				jr	nc, process_path

				CP	rc_susp
				JR	Z,restore_main 	; user aborted command...
				RET
.process_path
				ld	bc,$80
				ld	hl,buf1
				ld	de,buf2			; generate expanded path, if possible...
				CALL_OZ (Gn_Fex)
				jr	c, inv_path		; invalid path

				AND	@10111000
				JR	NZ, illg_wc		; wildcards not allowed...
				JR	adjust_path

.illg_wc			LD	HL, illgwc_msg
				CALL DispErrMsg
				JR	restore_main		; syntax error in path name

.inv_path 		LD	HL, invpath_msg
				CALL DispErrMsg
				JR	restore_main
.no_files
				LD	HL, noeprfilesmsg
				CALL DispErrMsg
				RET
.adjust_path
				DEC	DE
				LD	A,(DE)			; assure that last character of path
				CP	'/'				; is not a "/"...
				JR	NZ,path_ok
				DEC	DE
.path_ok			INC	DE				; DE points at merge position,
									; ready to receive filenames from File Eprom...
				CALL_OZ GN_nln
				CALL PromptOverwrite	; prompt for all existing files to be overwritten
				CALL_OZ GN_nln

				LD	C,3
				CALL FileEprFirstFile	; get pointer to first file on Eprom
				JR	C, no_files		; Ups - the card was empty or not present...

.restore_loop		LD	C,3
				CALL FileEprFilename	; get filename at (DE)
				JR	C, restore_completed; all file entries scanned...
				JR	Z, fetch_next		; File Entry marked as deleted, get next...

				PUSH BC
				PUSH HL				; preserve pointer temporarily...

				LD	HL,fetf_ms		; "Fetching to "
				CALL_OZ gn_sop
				LD	HL,buf2
				CALL_OZ(Gn_Sop)		; display RAM filename...

				LD	HL,status
				BIT	0,(HL)
				JR	NZ, restore_file	; default - overwrite files...

				CALL_OZ(Gn_Nln)
				LD	HL, buf2
				call PromptOverWrFile
				jr	c, overwr_file 	; file doesn't exist (or in use)
				jr	z, overwr_file 	; file exists, user acknowledged Yes...

				CALL_OZ(Gn_Nln)
				POP	HL
				POP	BC
				JR	fetch_next		; user acknowledged No, get next file
.overwr_file
				LD	HL, fetch_ms
				CALL_OZ(Gn_Sop)

.restore_file		LD	B,0				; (local pointer)
				LD	HL,buf2			; pointer to filename...
				CALL CreateFilename 	; create file with implicit path...

				POP	HL				; IX = file handle...
				POP	BC				; restore pointer to current File Entry
				JR	C, filecreerr		; not possible to create file, exit restore...

				CALL FileEprFetchFile	; fetch file from slot 3 Eprom
				PUSH AF				; to RAM file, identified by IX handle
				CALL_OZ(Gn_Cl) 		; then, close file.
				POP	AF
				JR	C, filecreerr		; not possible to transfer, exit restore...

				PUSH BC
				PUSH HL
				LD	HL, fsok_ms
				CALL_OZ(GN_Sop)		; "Done"
				POP	HL
				POP	BC
.fetch_next
				CALL FileEprNextFile	; get pointer to next File Entry...
				JR	NC, restore_loop
.restore_completed
				CALL_OZ GN_nln
				LD	HL, done_ms
				CALL DispErrMsg
				RET
.filecreerr
				CALL_OZ(Gn_Err)		; report fatal error and exit to main menu...
				RET


; ****************************************************************************
;
; Prompt user to to overwrite all existing files (in RAM) when restoring
;
; IN: None
;
; OUT:
;	(status), bit 1 = 1 if all files are to be overwritten...
;
.PromptOverWrite	PUSH DE
				PUSH HL
				LD	HL,status
				SET	0,(HL)			; preset to Yes (to overwrite existing files)

				LD	HL, promptovwrite_msg
				LD	DE, no_ms
				CALL YesNo
				JR	C, exit_promptoverwr
				JR	Z, exit_promptoverwr; Yes selected...

				LD	HL,status
				RES	0,(HL)			; No selected (to overwrite existing files)
.exit_promptoverwr
				POP	HL
				POP	DE
				RET

.rest_banner		DEFM "RESTORE ALL FILES FROM EPROM" & 0
.fetch_ms 		DEFM $0D & $0A & " Fetching... " & 0
.promptovwrite_msg	DEFM " Overwrite RAM files? " & 0
.defdst_msg		DEFM " Enter Device/path." & 0
.dest_msg 		DEFM 1 & "2+C Device: " & 0
.illgwc_msg		DEFM $0D & $0A & "Wildcards not allowed." & 0
.invpath_msg		DEFM $0D & $0A & "Invalid Path" & 0



; ****************************************************************************
;
; Prompt user to to overwrite file, if it exist.
;
; IN:
;	HL = (local) ptr to filename (null-terminated)
;
; OUT:
;	Fc = 0, file exists
;		Fz = 1, Yes, user acknowledged overwrite file
;		Fz = 0, No - acknowledged preserve file
;
;	Fc = 1, file doesn't exists
;
; Registers changed after return:
;	..BCDEHL/IXIY same
;	AF....../.. different
;
.PromptOverWrFile	PUSH BC
				PUSH DE
				PUSH HL
				PUSH IX

				LD	A, OP_IN
				LD	BC,$0040			; expanded file, room for 64 bytes
				LD	D,H
				LD	E,L
				CALL_OZ (GN_Opf)
				JR	C, exit_overwrfile	; file not available
				CALL_OZ(GN_Cl)

				LD	HL, exis_ms
				LD	DE, yes_ms
				CALL yesno			; file exists, prompt "Overwrite file?"

.exit_overwrfile	POP	IX
				POP	HL
				POP	DE
				POP	BC
				RET



; ****************************************************************************
;
; Put Default Device (Panel setting) at (buf1).
;
.GetDefaultDevice
				LD	 A, 64
				LD	BC, PA_Dev				; Read default device
				LD	DE, buf1					; buffer for device name
				PUSH DE						; save pointer to buffer
				CALL_OZ (Os_Nq)
				POP	DE
				LD	B,0
				LD	C,A						; actual length of string...
				EX	DE,HL
				ADD	HL,BC
				LD	(HL),0					; null-terminate device name
				RET


; ****************************************************************************
;
; Display name and size of stored files on Flash Eprom.
;
.catalog_main
				call cls
				ld	c,3
				call FileEprFirstFile		; return BHL pointer to first File Entry

				ld	a,b
				ld	(fbnk),a
				ld	(fadr),hl
				jr	nc, init_cat

				ld	hl, noeprfilesmsg
				CALL DispErrMsg
				RET
.init_cat
				ld	iy,status
				res	0,(iy+0)				; preset to ignore del. files
				res	1,(iy+0)				; preset to no lines displayed

				xor	a
				ld	hl, linecnt
				ld	(hl),a

				ld	hl, prompt_delfiles_ms
				ld	de, no_ms
				call yesno
				jr	nz, begin_catalogue
				set	0,(iy+0)				; display all files...
.begin_catalogue
				call cls
.cat_main_loop
				ld	a,(fbnk)
				ld	b,a
				ld	hl,(fadr)
				ld	c,3
				ld	de, buf3			; write filename at (DE), null-terminated
				call FileEprFilename	; copy filename from current file entry
				jp	c, end_cat		; Ups - last file(name) has been displayed...
				jr	nz, disp_filename	; active file, display...

				ex	af,af'
				bit	0,(iy+0)
				jr	z,get_next_filename ; ignore deleted file(name)...
				ex	af,af'

.disp_filename 	set	1,(iy+0)			; indicate display of filename...
				push bc
				push hl

				push de
				call nz,norm_aff
				call z,tiny_aff
				pop	hl
				CALL_OZ(Gn_sop)		; display filename

				pop	hl
				pop	bc
				push bc
				push hl
				ld	c,3
				call FileEprFileSize	; get size of File Entry in CDE
				ld	(flen),de
				ld	b,0
				ld	(flen+2),bc

				call jrsz_aff
				ld	hl,flen
				call IntAscii
				CALL_OZ gn_sop 		; display size of current File Entry
				call jnsz_aff
				pop	hl
				pop	bc
.get_next_filename
				call FileEprNextFile	; get pointer to next File Entry in BHL...
				ld	(fadr),hl
				ld	a,b
				ld	(fbnk),a

				bit	1,(iy+0)
				jr	z, cat_main_loop	; no file were displayed, fetch new filename

				res	1,(iy+0)
				ld	hl, linecnt
				inc	(hl)
				ld	a,7
				cp	(hl)
				jr	nz,next_row
				ld	(hl),0
				call pwait
				cp	rc_esc
				jr	nz,new_page
				ld	a,1
				CALL_OZ os_esc
				ret
.new_page
				call FlashEprCardId
				jr	nc,ok_new_page
				ld	a,rc_fail
				CALL_OZ gn_err
				RET
.ok_new_page
				call cls
				jp	cat_main_loop
.next_row
				CALL_OZ gn_nln
				jp	cat_main_loop

.norm_aff 		ld	hl,norm_sq
				jr	dispsq
.tiny_aff 		ld	hl,tiny_sq
				jr	dispsq
.jrsz_aff 		ld	hl,jrsz_sq
				jr	dispsq
.jnsz_aff 		ld	hl,jnsz_sq
.dispsq			push af
				CALL_OZ gn_sop
				pop	af
				ret
.end_cat
				ld	hl,endf_ms
				CALL_OZ gn_sop
				call pwait
				ret

.noeprfilesmsg 	DEFM "Empty Eprom." & $0D & $0A & 0
.norm_sq			defm 1 & "2-G" & 1 & "4+TRUF" & 1 & "4-TRU " & 0
.tiny_sq			defm 1 & "5+TRGUd" & 1 & "3-RU " & 0
.jrsz_sq			defm 1 & "2JR" & 0
.jnsz_sq			defm 1 & "2JN" & 0
.endf_ms			defm 1 & "4+TUR END " & 1 & "4-TUR" & 0
.prompt_delfiles_ms defm "Show deleted files? " & 0


; **************************************************************************
;
; Format Flash Eprom and write "oz" File Eprom Header.
;
; Out:
;		Fc = 0,
;			Fz = 0, User prompted No to Format
;			Fz = 1, User performed format.
;		Fc = 1, Format process failed.
;
.format_main
				call cls
				ld	hl,ffm1_br
				call wbar
				ld	hl,caut_ms
				call sopnln
				ld	hl,sure_ms
				ld	de,no_ms
				call yesno
				ret	nz

				call cls
				ld	hl,ffm2_br
				call wbar
				CALL_OZ gn_nln

				call CheckBatteryStatus		; don't format Flash Eprom
				ret	c					; if Battery Low is enabled...

				CALL FlashEprCardId
				JP	C, unkn_chip			; Ups - Flash Eprom not available
				LD	A,B
				LD	(linecnt),A
				LD	C,0					; format B blocks, starting from 0...
.bera_loop
				PUSH BC
				LD	HL,eras_ms
				CALL_OZ gn_sop
				LD	B,0
				INC	C					; C = "current" block number
				LD	HL,2
				CALL IntAscii
				CALL_OZ(GN_sop)
				LD	HL,era2_ms
				CALL_OZ gn_sop
				LD	A,(linecnt)
				LD	B,0
				LD	C,A					; total blocks on Flash Eprom
				LD	HL,2
				CALL IntAscii
				CALL_OZ(GN_Sop)
				POP	BC

				LD	A,C
				CALL FlashEprBlockErase
				JR	C, formaterr
				INC	C					; ready for next block...

				DJNZ bera_loop 			; format next block

				CALL_OZ gn_nln
				LD	HL,wroz_ms
				CALL sopnln

				CALL FlashEprStdFileHeader
				JR	C, WriteHdrError

				CALL resesc
				CP	A					; Signal success (Fc = 0, Fz = 1)
				RET
.formaterr								; current block was not formatted properly...
				LD	HL, fferr_ms
				CALL DispErrMsg
				RET
.writeHdrError 							; File Eprom Header was not blown properly...
				LD	HL, hdrerr_ms
				CALL DispErrMsg
				RET

.hdrerr_ms		defm "Header not written properly!" & $0D & $0A & 0
.fferr_ms 		defm "Block not formatted properly!" & $0D & $0A & 0
.ffm1_br			defm "FORMAT FLASH EPROM" & 0
.ffm2_br			defm "Formatting Flash Eprom - please wait..." & 0
.caut_ms			defm 1 & "3+BF CAUTION! " & 1 & "3-BFAll data will be lost." & 0
.sure_ms			defm 1 & "2+C" & 13 & " Are you sure? " & 0
.eras_ms			DEFM 13 & " Erasing block " & 0
.era2_ms			DEFM " / " & 0
.wroz_ms			DEFM " Writing File Eprom Header..." & $0D & $0A & 0



; ****************************************************************************
;
; Various standard routines
;


; ****************************************************************************
;
.sopnln
				CALL_OZ gn_sop
				CALL_OZ gn_nln
				RET


; ****************************************************************************
;
.greyscr
				PUSH HL
				LD	HL,grey_ms
				CALL_OZ gn_sop
				POP	HL
				RET
.grey_ms			defm 1&"6#8  "&$7E&$28&1&"2H8"&1&"2G+"&0



; ****************************************************************************
;
.cls
				PUSH AF
				LD	A,12
				CALL_OZ os_out
				POP	AF
				RET


; ****************************************************************************
;
.rdch
				CALL_OZ os_in
				JR	NC,rd2
				CP	rc_susp
				JR	Z,rdch
				SCF
				RET
.rd2
				CP	0
				RET	NZ
				CALL_OZ os_in
				RET


; ****************************************************************************
;
.pwait
				LD	A,sr_pwt
				CALL_OZ os_sr
				JR	NC,pw2
				CP	rc_susp
				JR	Z,pwait
				SCF
				RET
.pw2
				CP	0
				RET	NZ
				CALL_OZ os_in
				RET


; ****************************************************************************
;
.yesno
				CALL_OZ gn_sop
.yesno_loop		LD	H,D
				LD	L,E
				CALL_OZ gn_sop
				CALL_OZ(OS_Pur)		; make sure no keys in sys. inp. buffer...
				CALL rdch
				RET	C
				CP	13
				JR	NZ,yn1
				LD	A,E
				CP	yes_ms % 256		; Yes, Fc = 0, Fz = 1
				RET	Z
				OR	A				; No, Fc = 0, Fz = 0
				RET
.yn1
				OR	32
				CP	'y'
				JR	NZ,yn2
				LD	DE,yes_ms
				JR	yesno_loop
.yn2
				CP	'n'
				JR	NZ,yesno
				LD	DE,no_ms
				JR	yesno_loop
.yes_ms			defm 1 & "2+CYes" & 8 & 8 & 8 & 0
.no_ms			defm 1 & "2+CNo " & 8 & 8 & 8 & 0



; ****************************************************************************
;
; Convert integer in HL (or BC) to Ascii string, which is written to (buf1) and null-terminated.
;
; HL points at Ascii string, null-terminated.
;
.IntAscii
				PUSH AF
				PUSH DE
				xor	a
				ld	de,buf1
				push de
				CALL_OZ(GN_Pdn)
				XOR	A
				LD	(DE),A
				POP	HL
				pop	de
				POP	AF
				RET


; ************************************************************************
;
; Display error code value in hex.
; User then presses ESC to continue
;
;.DispErrorCode	 PUSH AF
;				 PUSH HL

;				 LD	 HL, errcodemsg
;				 CALL_OZ(Gn_Sop)
;				 CALL hexbyte
;				 LD	 A,'h'
;				 CALL_OZ(OS_out)
;				 CALL_OZ(Gn_Nln)
;				 CALL ResEsc

;				 POP  HL
;				 POP  AF
;				 RET
;.errcodemsg		 DEFM "Error code returned: " & 0


; ************************************************************************
;
; User is prompted with "Press ESC to Resume". The keyboard is then scanned
; for the ESC key.
;
; The routine returns when the user has pressed ESC.
;
; Registers changed after return:
;	None.
;
.ResEsc
				PUSH AF
				PUSH HL
				LD	HL,resesc_ms
				CALL_OZ gn_sop
.escin
				CALL rdch
				JR	NC,escin
				CP	rc_esc
				JR	NZ,escin
				POP	HL
				POP	AF
				RET
.resesc_ms		DEFM 1 & "3+FTPRESS "&1&$E4&" TO RESUME" & 1 & "4-FTC" & $0D & $0A & 0



; ************************************************************************
;
.hexbyte
				push hl
				push de
				push af
				and 240
				rra
				rra
				rra
				rra
				call affq
				pop	af
				and	15
				call affq
				pop	de
				pop	hl
				ret
.affq
				ld	h,0
				ld	l,a
				ld	de,hexnumb_list
				add	hl,de
				ld	a,(hl)
				CALL_OZ os_out
				ret
.hexnumb_list		defm "0123456789ABCDEF"&0



; ****************************************************************************
;
; Write Error message, and wait for ESC wait to be acknowledged.
;
; Registers changed after return:
;	AFBCDE../IXIY same
;	......HL/.... different
;
.DispErrMsg
				PUSH AF				; preserve error status...
				PUSH HL
				CALL sopnln
				CALL ResEsc			; "Press ESC to resume" ...
				POP	HL
				POP	AF
				RET


; ****************************************************************************
;
.ReportStdError	PUSH AF
				CALL_OZ(Gn_Err)
				POP	AF
				RET



; ****************************************************************************
;
; Eprom Statistics. The File Eprom is assumed to be present in slot 3.
;
; Fetch the following information:
;
; (file) = number of files
; (fdel) = number of deleted files
; (free) = free space
;
; Registers changed after return:
;	......../IXIY same
;	AFBCDEHL/.... different
;
.FileEpromStatistics
				ld	c,3
				call FileEprCntFiles		; files on File Eprom in slot 3...
				add	hl,de				; total files = active + deleted
				ld	(file),hl
				ld	(fdel),de

				ld	c,3
				call FileEprFreeSpace		; free space on File Eprom in slot 3...
				ld	(free),bc
				ld	(free+2),de
				ret



; *****************************************************************************
;
; Check for Battery Low status and report to user, if enabled.
;
; IN:
;	None.
;
; Out:
;	Fc = 1, if Battery Low Status is enabled
;		A = RC_WP (Flash Eprom Write Protected)
;	Fc = 0, Battery Power is operational for Flash Eprom action
;
.CheckBatteryStatus CALL CheckBattLow
				RET	NC

				PUSH HL
				LD	HL, battlowmsg
				CALL DispErrMsg
				POP	HL

				LD	A, RC_Wp				; general failure...
				SCF
				RET

.battlowmsg		DEFM "Batteries are low." & $0D & $0A & 0



; *****************************************************************************
;
; RAM Variable definitions
;

; *****************************************************************************
; use I/O buffer for temporary filename management
DEFVARS BufferStart
{
	buf1 		ds.b $40
	buf3 		ds.b $80				; for expanded filenames
}


.linecnt			defb 0
.nlen			defb 0				; length of filename
.flen			defl 0				; length of file (32bit)
.flenhdr			defl 0				; length of File Entry Header
.delv			defl 0				; pointer to <Deleted File> mark of File Entry
.fbnk			defb 0				; Eprom Bank (relative)
.fadr			defw 0				; Eprom Bank offset address
.free			defl 0				; free bytes on Flash Eprom
.file			defl 0				; total of files on Flash Eprom (active + deleted)
.fdel			defl 0				; total of deleted files on Flash Eprom
.savedfiles		defl 0				; total of files saved in a "Save" session
.flentry			defb 0,0,0			; pointer to existing file entry
.status			defb 0				; general purpose status flag
.wcard_handle		defw 0				; Wildcard handle from GN_OPW
.buf2			defs $80				; filename buffer...


; *****************************************************************************
;
; Library calls are added here by linker...
;



