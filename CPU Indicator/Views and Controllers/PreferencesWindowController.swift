/*
 * PreferencesWindowController.swift
 * CPU Indicator
 *
 * Created by François Lamboley on 9/13/15.
 * Copyright © 2015 Frost Land. All rights reserved.
 */

import Cocoa



class PreferencesWindowController: NSWindowController, NSWindowDelegate {
	
	private var iUseMyself: PreferencesWindowController?
	private var timerNotUsingMyself: NSTimer?
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		self.windowFrameAutosaveName = "PrefsWindow"
	}
	
	override var window: NSWindow? {
		didSet {
			assert(window?.delegate == nil)
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
		timerNotUsingMyself = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: #selector(PreferencesWindowController.myselfNotNeededAnymore(_:)), userInfo: nil, repeats: false)
	}
	
	@objc /* Used by a timer. */
	private func myselfNotNeededAnymore(timer: NSTimer) {
		timerNotUsingMyself?.invalidate()
		timerNotUsingMyself = nil
		iUseMyself = nil
	}
	
}
