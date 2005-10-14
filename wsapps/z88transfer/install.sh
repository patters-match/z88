#!/bin/bash

/usr/bin/install z88transfer.py /usr/bin/
chmod 755 /usr/bin/z88transfer.py
/usr/bin/install -d /usr/share/z88transfer/
/usr/bin/install -d /usr/share/doc/z88transfer
/usr/bin/install z88transfer.glade /usr/share/z88transfer/z88transfer.glade
/usr/bin/install z88.png /usr/share/pixmaps/
/usr/bin/install pseudotranslation /usr/share/z88transfer/pseudotranslation
/usr/bin/install z88transfer.desktop /usr/share/applications/z88transfer.desktop
/usr/bin/install docs/* /usr/share/doc/z88transfer/
/usr/bin/install pixmaps/* /usr/share/z88transfer/
./setup.py install
rm -rf build
rm *.pyc
