/*
 * MonitorZ80.java
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
 * @author <A HREF="mailto:gstrube@users.sourceforge.net">Gunther Strube</A>
 * $Id$  
 *
 */

package net.sourceforge.z88;

import java.util.Timer;
import java.util.TimerTask;

/**
 * Z80 instruction speed monitor.
 * Polls each second for the execution speed and displays it to std out.
 */
public class MonitorZ80 {

    private Timer timer = null;
    private TimerTask monitor = null;
    private long oldTimeMs = 0;
    Blink blink;

    public MonitorZ80(Blink b) {
        blink = b;
        timer = new Timer(true);
    }

    private class SpeedPoll extends TimerTask {
        /**
         * Request poll each second, or try to hit the 1 sec time frame...
         *
         * @see java.lang.Runnable#run()
         */
        public void run() {
            float realMs = System.currentTimeMillis() - oldTimeMs;
            int ips = (int) (blink.getInstructionCounter() * realMs/1000);
            int tps = blink.getTstatesCounter();

            // System.out.println( "IPS=" + ips + ",TPS=" + tps);

            oldTimeMs = System.currentTimeMillis();
        }
    }


    /**
     * Stop the Z80 Speed Monitor.
     */
    public void stop() {
        if (timer != null)
            monitor.cancel();
    }

    /**
     * Speed polling monitor asks each second for Z80 speed status.
     */
    public void start() {
        monitor = new SpeedPoll();
        oldTimeMs = 0;
        timer.scheduleAtFixedRate(monitor, 0, 1000);
    }
}
