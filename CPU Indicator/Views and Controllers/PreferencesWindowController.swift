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
	private var timerNotUsingMyself: Timer?
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		windowFrameAutosaveName = "PrefsWindow"
	}
	
	override var window: NSWindow? {
		didSet {
			assert(window?.delegate == nil)
			window?.delegate = self
		}
	}
	
	override func windowDidLoad() {
		timerNotUsingMyself?.invalidate()
		timerNotUsingMyself = nil
		iUseMyself = self
	}
	
	func windowDidBecomeKey(_ notification: Notification) {
		timerNotUsingMyself?.invalidate()
		timerNotUsingMyself = nil
		iUseMyself = self
	}
	
	func windowWillClose(_ notification: Notification) {
		assert(timerNotUsingMyself == nil)
		timerNotUsingMyself = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(PreferencesWindowController.myselfNotNeededAnymore(_:)), userInfo: nil, repeats: false)
	}
	
	@objc /* Used by a timer. */
	private func myselfNotNeededAnymore(_ timer: Timer) {
		timerNotUsingMyself?.invalidate()
		timerNotUsingMyself = nil
		iUseMyself = nil
	}
	
}
