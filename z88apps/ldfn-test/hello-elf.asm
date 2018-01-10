module HelloElf

include "hello.inc"               ; contains EXEC_ORG

include "elfhdr.inc"              ; Standard Z80 ELF header, followed by executable program

.PRG_BEGIN
        binary "hello.bin"
.PRG_END
