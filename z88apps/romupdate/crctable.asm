; *************************************************************************************
; RomUpdate
; (C) Gunther Strube (gbs@users.sf.net) 2005
;
; RomUpdate is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; RomUpdate is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with RomUpdate;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
; *************************************************************************************


; *************************************************************************************
; 32-Bit CRC Lookup Table
; This table starts on a 256-byte boundary for speed
;
; CRC table from UnZip, by Garry Lancaster, Copyright 1999, released as GPL.
;
                    DEFS $100-($PC%$100)            ; adjust code to position tables at xx00 address
.crctable
                    defl $00000000, $77073096, $ee0e612c, $990951ba
                    defl $076dc419, $706af48f, $e963a535, $9e6495a3
                    defl $0edb8832, $79dcb8a4, $e0d5e91e, $97d2d988
                    defl $09b64c2b, $7eb17cbd, $e7b82d07, $90bf1d91
                    defl $1db71064, $6ab020f2, $f3b97148, $84be41de
                    defl $1adad47d, $6ddde4eb, $f4d4b551, $83d385c7
                    defl $136c9856, $646ba8c0, $fd62f97a, $8a65c9ec
                    defl $14015c4f, $63066cd9, $fa0f3d63, $8d080df5
                    defl $3b6e20c8, $4c69105e, $d56041e4, $a2677172
                    defl $3c03e4d1, $4b04d447, $d20d85fd, $a50ab56b
                    defl $35b5a8fa, $42b2986c, $dbbbc9d6, $acbcf940
                    defl $32d86ce3, $45df5c75, $dcd60dcf, $abd13d59
                    defl $26d930ac, $51de003a, $c8d75180, $bfd06116
                    defl $21b4f4b5, $56b3c423, $cfba9599, $b8bda50f
                    defl $2802b89e, $5f058808, $c60cd9b2, $b10be924
                    defl $2f6f7c87, $58684c11, $c1611dab, $b6662d3d
                    defl $76dc4190, $01db7106, $98d220bc, $efd5102a
                    defl $71b18589, $06b6b51f, $9fbfe4a5, $e8b8d433
                    defl $7807c9a2, $0f00f934, $9609a88e, $e10e9818
                    defl $7f6a0dbb, $086d3d2d, $91646c97, $e6635c01
                    defl $6b6b51f4, $1c6c6162, $856530d8, $f262004e
                    defl $6c0695ed, $1b01a57b, $8208f4c1, $f50fc457
                    defl $65b0d9c6, $12b7e950, $8bbeb8ea, $fcb9887c
                    defl $62dd1ddf, $15da2d49, $8cd37cf3, $fbd44c65
                    defl $4db26158, $3ab551ce, $a3bc0074, $d4bb30e2
                    defl $4adfa541, $3dd895d7, $a4d1c46d, $d3d6f4fb
                    defl $4369e96a, $346ed9fc, $ad678846, $da60b8d0
                    defl $44042d73, $33031de5, $aa0a4c5f, $dd0d7cc9
                    defl $5005713c, $270241aa, $be0b1010, $c90c2086
                    defl $5768b525, $206f85b3, $b966d409, $ce61e49f
                    defl $5edef90e, $29d9c998, $b0d09822, $c7d7a8b4
                    defl $59b33d17, $2eb40d81, $b7bd5c3b, $c0ba6cad
                    defl $edb88320, $9abfb3b6, $03b6e20c, $74b1d29a
                    defl $ead54739, $9dd277af, $04db2615, $73dc1683
                    defl $e3630b12, $94643b84, $0d6d6a3e, $7a6a5aa8
                    defl $e40ecf0b, $9309ff9d, $0a00ae27, $7d079eb1
                    defl $f00f9344, $8708a3d2, $1e01f268, $6906c2fe
                    defl $f762575d, $806567cb, $196c3671, $6e6b06e7
                    defl $fed41b76, $89d32be0, $10da7a5a, $67dd4acc
                    defl $f9b9df6f, $8ebeeff9, $17b7be43, $60b08ed5
                    defl $d6d6a3e8, $a1d1937e, $38d8c2c4, $4fdff252
                    defl $d1bb67f1, $a6bc5767, $3fb506dd, $48b2364b
                    defl $d80d2bda, $af0a1b4c, $36034af6, $41047a60
                    defl $df60efc3, $a867df55, $316e8eef, $4669be79
                    defl $cb61b38c, $bc66831a, $256fd2a0, $5268e236
                    defl $cc0c7795, $bb0b4703, $220216b9, $5505262f
                    defl $c5ba3bbe, $b2bd0b28, $2bb45a92, $5cb36a04
                    defl $c2d7ffa7, $b5d0cf31, $2cd99e8b, $5bdeae1d
                    defl $9b64c2b0, $ec63f226, $756aa39c, $026d930a
                    defl $9c0906a9, $eb0e363f, $72076785, $05005713
                    defl $95bf4a82, $e2b87a14, $7bb12bae, $0cb61b38
                    defl $92d28e9b, $e5d5be0d, $7cdcefb7, $0bdbdf21
                    defl $86d3d2d4, $f1d4e242, $68ddb3f8, $1fda836e
                    defl $81be16cd, $f6b9265b, $6fb077e1, $18b74777
                    defl $88085ae6, $ff0f6a70, $66063bca, $11010b5c
                    defl $8f659eff, $f862ae69, $616bffd3, $166ccf45
                    defl $a00ae278, $d70dd2ee, $4e048354, $3903b3c2
                    defl $a7672661, $d06016f7, $4969474d, $3e6e77db
                    defl $aed16a4a, $d9d65adc, $40df0b66, $37d83bf0
                    defl $a9bcae53, $debb9ec5, $47b2cf7f, $30b5ffe9
                    defl $bdbdf21c, $cabac28a, $53b39330, $24b4a3a6
                    defl $bad03605, $cdd70693, $54de5729, $23d967bf
                    defl $b3667a2e, $c4614ab8, $5d681b02, $2a6f2b94
                    defl $b40bbe37, $c30c8ea1, $5a05df1b, $2d02ef8d
; *************************************************************************************


