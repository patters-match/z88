
include "elf.def"

; ELF header for an executable program
; PRG_BEGIN and PRG_END are defined by specific application that performs final linking

.ELFHDR_START
        defm    $7F, "ELF"
        defb    ELFCLASS32                      ; 32-bit objects        e_ident[EI_CLASS]
        defb    ELFDATA2LSB                     ; little endian         e_ident[EI_DATA]
        defb    EV_CURRENT                      ; always                e_ident[EI_VERSION]
        defb    ELFOSABI_OZ                     ; OZ                    e_ident[EI_OSABI]
        defb    ELFABIVERSION                   ; unspecified
        defs    7 (0)

        defw    ET_EXEC                         ; elf type
        defw    EM_Z80                          ; machine architecture
        defl    EV_CURRENT                      ; always CURRENT
        defl    EXEC_ORG                        ; entry address
        defl    PHT_START - ELFHDR_START        ; program header offset
        defl    0                               ; section header offset
        defl    0                               ; processor specific flags
        defw    EH_SIZEOF                       ; elf header size in bytes (52)
        defw    PHT_SIZEOF                      ; program header entry size (32)
        defw    1                               ; number of program header entries
        defw    SHT_SIZEOF                      ; section header entry size (40)
        defw    0                               ; number of section header entries
        defw    0                               ; section name string index

;   PHT
.PHT_START
        defl    PT_LOAD                         ; type
        defl    PRG_BEGIN - ELFHDR_START        ; p_offset
        defl    EXEC_ORG                        ; virtual address
        defl    0                               ; physical address
        defl    PRG_END - PRG_BEGIN                     ; file size
        defl    PRG_END - PRG_BEGIN + SIZEOF_Workspace  ; memory size requested
        defl    PF_X | PF_R                     ; executable
        defl    $4000                           ; bank alignement
