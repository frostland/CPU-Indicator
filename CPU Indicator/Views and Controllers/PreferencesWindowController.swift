/*
 * PreferencesWindowController.swift
 * CPU Indicator
 *
 * Created by François Lamboley on 9/13/15.
 * Copyright © 2015 Frost Land. All rights reserved.
 */

import Cocoa



class PreferencesWindowController : NSWindowController, NSWindowDelegate {
	private var iUseMyself: PreferencesWindowController?
	private var timerNotUsingMyself: NSTimer?
	
	override var window: NSWindow? {
		didSet {
			assert(window?.delegate ==  nil)
			window?.delegate = self
		}
	}
	
	func windowDidBecomeKey(notification: NSNotification) {
		timerNotUsingMyself?.invalidate()
		timerNotUsingMyself = nil
		iUseMyself = self
	}
	
	func windowWillClose(notification: NSNotification) {
		assert(timerNotUsingMyself == nil)
		timerNotUsingMyself = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: Selector("myselfNotNeededAnymore:"), userInfo: nil, repeats: false)
	}
	
	/* Can't be private because used by a timer. */
	func myselfNotNeededAnymore(timer: NSTimer) {
		timerNotUsingMyself?.invalidate()
		timerNotUsingMyself = nil
		iUseMyself = nil
	}
}
