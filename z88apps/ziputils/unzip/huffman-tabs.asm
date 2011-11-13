; *************************************************************************************
;
; UnZip - File extraction utility for ZIP files, (c) Garry Lancaster, 1999-2006
; This file is part of UnZip.
;
; UnZip is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; UnZip is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with UnZip;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
;
; *************************************************************************************

; Tables required for Huffman decoding

        module  huffmantabs

        xdef    clorder,lenextra,dstextra

; Codelength order table

.clorder
        defb    16*5    ; order to read codelengths (as offsets
        defb    17*5    ; to a code table)
        defb    18*5
        defb    0*5
        defb    8*5
        defb    7*5
        defb    9*5
        defb    6*5
        defb    10*5
        defb    5*5
        defb    11*5
        defb    4*5
        defb    12*5
        defb    3*5
        defb    13*5
        defb    2*5
        defb    14*5
        defb    1*5
        defb    15*5

; Extra bits for length values

.lenextra
        defb    0       ; Table of extra bits for length values - 257
        defw    3
        defb    0       ; 258
        defw    4
        defb    0       ; 259
        defw    5
        defb    0       ; 260
        defw    6
        defb    0       ; 261
        defw    7
        defb    0       ; 262
        defw    8
        defb    0       ; 263
        defw    9
        defb    0       ; 264
        defw    10
        defb    1       ; 265
        defw    11
        defb    1       ; 266
        defw    13
        defb    1       ; 267
        defw    15
        defb    1       ; 268
        defw    17
        defb    2       ; 269
        defw    19
        defb    2       ; 270
        defw    23
        defb    2       ; 271
        defw    27
        defb    2       ; 272
        defw    31
        defb    3       ; 273
        defw    35
        defb    3       ; 274
        defw    43
        defb    3       ; 275
        defw    51
        defb    3       ; 276
        defw    59
        defb    4       ; 277
        defw    67
        defb    4       ; 278
        defw    83
        defb    4       ; 279
        defw    99
        defb    4       ; 280
        defw    115
        defb    5       ; 281
        defw    131
        defb    5       ; 282
        defw    163
        defb    5       ; 283
        defw    195
        defb    5       ; 284
        defw    227
        defb    0       ; 285
        defw    258

; Extra bits for distance values

.dstextra
        defb    0       ; 0
        defw    1
        defb    0       ; 1
        defw    2
        defb    0       ; 2
        defw    3
        defb    0       ; 3
        defw    4
        defb    1       ; 4
        defw    5
        defb    1       ; 5
        defw    7
        defb    2       ; 6
        defw    9
        defb    2       ; 7
        defw    13
        defb    3       ; 8
        defw    17
        defb    3       ; 9
        defw    25
        defb    4       ; 10
        defw    33
        defb    4       ; 11
        defw    49
        defb    5       ; 12
        defw    65
        defb    5       ; 13
        defw    97
        defb    6       ; 14
        defw    129
        defb    6       ; 15
        defw    193
        defb    7       ; 16
        defw    257
        defb    7       ; 17
        defw    385
        defb    8       ; 18
        defw    513
        defb    8       ; 19
        defw    769
        defb    9       ; 20
        defw    1025
        defb    9       ; 21
        defw    1537
        defb    10      ; 22
        defw    2049
        defb    10      ; 23
        defw    3073
        defb    11      ; 24
        defw    4097
        defb    11      ; 25
        defw    6145
        defb    12      ; 26
        defw    8193
        defb    12      ; 27
        defw    12289
        defb    13      ; 28
        defw    16385
        defb    13      ; 29
        defw    24577

