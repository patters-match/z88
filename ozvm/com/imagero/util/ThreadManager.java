/*
 * Copyright (c) 2002-2005 imagero Andrei Kouznetsov. All Rights Reserved.
 * http://jgui.imagero.com
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

/*
 * Date: 11.09.2002
 * Time: 17:06:36
 */
package com.imagero.util;

import java.util.Vector;

/**
 * ThreadManager helps to distribute tasks to threads (runners). Runner count
 * can be changed at any time.
 * 
 * @author Andrei Kouznetsov
 */
public class ThreadManager {
	/**
	 * runner count
	 */
	int count;

	Runner[] runners;

	Runnable[] current;

	Vector keys = new Vector();

	protected Vector tasks = new Vector();

	/**
	 * create ThreadManager with one runner
	 */
	public ThreadManager() {
		this(1);
	}

	/**
	 * create ThreadManager with specified amount of runners
	 * 
	 * @param count
	 *            amount of runners
	 */
	public ThreadManager(int count) {
		if (count <= 0) {
			throw new IllegalArgumentException("" + count);
		}

		this.runners = new Runner[count];
		this.current = new Runnable[count];
		for (int i = 0; i < runners.length; i++) {
			runners[i] = new Runner();
			runners[i].start();
		}
	}

	/**
	 * remove all tasks from queue
	 */
	public void clearTasks() {
		this.tasks.clear();
	}

	/**
	 * add task to task queue
	 * 
	 * @param r
	 *            Runnable
	 */
	public void addTask(Runnable r) {
		int index = this.tasks.indexOf(r);
		if (index < 0 && !isCurrentImpl(r)) {
			this.tasks.add(r);
			wakeUp();
		}
	}

	protected boolean isCurrentImpl(Runnable r) {
		for (int i = 0; i < current.length; i++) {
			if (current[i] == r) {
				return true;
			}
		}
		return false;
	}

	/**
	 * check if specified task (job) is now running (in progress)
	 * 
	 * @param r
	 *            Runnable task to check
	 * @return true if job is in progress
	 */
	public boolean isCurrent(Runnable r) {
		return isCurrentImpl(r);
	}

	/**
	 * check if this task is already in queue
	 * 
	 * @param r
	 *            Runnable task to check
	 * @return true if specified job is already in job queue or is in progress
	 *         (running)
	 */
	public boolean hasTask(Runnable r) {
		return isCurrentImpl(r) || this.tasks.contains(r);
	}

	/**
	 * wake up all runners
	 */
	protected synchronized void wakeUp() {
		notifyAll();
	}

	protected void finalize() throws Throwable {
		for (int i = 0; i < runners.length; i++) {
			runners[i].stopMe();
			runners[i] = null;
		}
		wakeUp();
	}

	/**
	 * get next job from queue
	 * 
	 * @return next task
	 */
	protected synchronized Runnable nextTask() {
		if (this.tasks.size() > 0) {
			return (Runnable) this.tasks.remove(0);
		}
		return null;
	}

	synchronized void doWait() {
		try {
			this.wait();
		} catch (InterruptedException ex) {
		}
	}

	private class Runner extends Thread {
		protected int num;

		boolean stopped;

		public Runner() {
			num = count++;
		}

		public void stopMe() {
			stopped = true;
		}

		public void run() {
			while (!stopped) {
				current[num] = nextTask();
				if (current[num] != null) {
					try {
						current[num].run();
					} catch (Throwable t) {
						t.printStackTrace();
					}
				} else {
					doWait();
				}
			}
		}
	}
}