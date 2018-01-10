# ensure that we have an up-to-date standard library
cd ../../stdlib; ./makelib.sh; cd ../z88apps/ldfn-test

rm -f *.err *.bin *.elf

mpm -b -rz80 -I../../oz/def -l../../stdlib/standard.lib hello.asm
if test $? -eq 0; then
    # program compiled successfully, apply leading Z80 ELF header
    mpm -b -nMap -I../../oz/def -ohello hello-elf.asm
fi

# compile the relocatable function code
mpm -b -nMap -rz80 -I../../oz/def world.asm
