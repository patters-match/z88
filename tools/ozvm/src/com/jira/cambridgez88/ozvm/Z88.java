/*
 * Z88.java
 * This file is part of OZvm.
 *
 * OZvm is free software; you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation;
 * either version 2, or (at your option) any later version.
 * OZvm is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 * without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * You should have received a copy of the GNU General Public License along with OZvm;
 * see the file COPYING. If not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *
 * @author <A HREF="mailto:gstrube@gmail.com">Gunther Strube</A>
 */
package com.jira.cambridgez88.ozvm;

import com.jira.cambridgez88.ozvm.screen.Z88display;

/**
 * The Z88 class defines the Z88 virtual machine (Processor, Blink, Memory,
 * Display & Keyboard).
 */
public class Z88 {

    private Blink blink;
    private Memory memory;
    private Z88Keyboard keyboard;
    private Z88display display;
    private Z80Processor z80;
    /**
     * Reference to the current executing Z80 processor.
     */
    private Thread z80Thread;

    /**
     * Z88 class default constructor.
     */
    private Z88() {
    }

    private static final class singletonContainer {

        static final Z88 singleton = new Z88();
    }

    public static Z88 getInstance() {
        return singletonContainer.singleton;
    }

    public Blink getBlink() {
        if (blink == null) {
            blink = new Blink();
        }

        return blink;
    }

    public Memory getMemory() {
        if (memory == null) {
            memory = new Memory();
        }

        return memory;
    }

    public Z88display getDisplay() {
        if (display == null) {
            display = new Z88display();
        }

        return display;
    }

    public Z88Keyboard getKeyboard() {
        if (keyboard == null) {
            keyboard = new Z88Keyboard();
        }

        return keyboard;
    }

    /**
     * 'Press' the reset button on the left side of the Z88 (hidden in the small
     * crack next to the power plug)
     */
    public void pressResetButton() {
        blink.awakeFromComa();
        blink.awakeFromSnooze();                // reset button always awake from coma or snooze...

        int comReg = blink.getBlinkCom();
        comReg &= ~Blink.BM_COMRAMS;          // COM.RAMS = 0 (lower 8K = Bank 0)
        blink.setBlinkCom(comReg);

        z80.PC(0x0000);                          // execute (soft/hard) reset in bank 0
    }

    public void pressHardReset() {
        blink.signalFlapOpened();

        memory.setByte(0x210000, 0);    // remove RAM filing system tag 5A A5
        memory.setByte(0x210001, 0);

        // press reset button while flap is opened
        pressResetButton();
        
        blink.signalFlapClosed();

        pressResetButton();
    }

    public Z80Processor getProcessor() {
        if (z80 == null) {
            z80 = new Z80Processor();
        }

        return z80;
    }

    public Thread getProcessorThread() {
        if (z80Thread != null && z80Thread.isAlive() == true) {
            return z80Thread;
        } else {
            return null;
        }
    }

    /**
     * Execute a Z80 thread until breakpoint is encountered (or F5 is pressed)
     *
     * @param oneStopBreakpoint
     *
     * @return true if thread was successfully started.
     */
    public boolean runZ80Engine() {
        if (z80Thread != null && z80Thread.isAlive() == true) {
            return false;
        }

        OZvm.displayRtmMessage("Z88 virtual machine was started.");

        z80Thread = new Thread(z80);
        z80Thread.start();

        return true;
    }

    /**
     * Execute a Z80 thread until temporary breakpoint is encountered (or F5 is
     * pressed)
     *
     * @param oneStopBreakpoint
     *
     * @return true if thread was successfully started.
     */
    public boolean runZ80Engine(final int oneStopBreakpoint) {
        if (z80Thread != null && z80Thread.isAlive() == true) {
            return false;
        }

        z80.setOneStopBreakpoint(oneStopBreakpoint);

        OZvm.displayRtmMessage("Z88 virtual machine was started.");

        z80Thread = new Thread(z80);
        z80Thread.start();

        return true;
    }
}
