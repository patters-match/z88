echo Installing Z88Transfer in folder %1\z88transfer
mkdir %1\z88transfer
mkdir %1\z88transfer\doc
copy z88transfer.py %1\z88transfer\
copy z88transfer.glade %1\z88transfer\
copy pipex.py %1\z88transfer\
copy z88access.py %1\z88transfer\
copy *.png %1\z88transfer\
copy pixmaps\* %1\z88transfer\
copy docs\* %1\z88transfer\doc\
copy pseudotranslation %1\z88transfer\
