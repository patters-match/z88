/*
 * MonitorZ80.java
 *
 * Created on July 11, 2003, 5:56 PM
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
