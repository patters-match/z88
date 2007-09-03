#!/bin/bash

./uninstall.sh > /dev/null 2>&1

install z88transfer.py /usr/local/bin/
chmod 755 /usr/local/bin/z88transfer.py
install -d /usr/local/share/z88transfer/
install -d /usr/local/share/doc/z88transfer
install z88_*.py /usr/local/share/z88transfer/
install other/z88.png /usr/local/share/pixmaps/
install files/* /usr/local/share/z88transfer/
install other/z88transfer.desktop /usr/share/applications/z88transfer.desktop
install docs/* /usr/local/share/doc/z88transfer/

