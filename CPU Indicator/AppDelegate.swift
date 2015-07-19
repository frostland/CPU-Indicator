/*
 * AppDelegate.swift
 * CPU Indicator
 *
 * Created by François Lamboley on 13/06/15.
 * Copyright © 2015 Frost Land. All rights reserved.
 */

import Cocoa



@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	static private(set) var sharedAppDelegate: AppDelegate!
	
	private var introWindowController: NSWindowController?
	
	override init() {
		super.init()
		
		if self.dynamicType.sharedAppDelegate == nil {
			self.dynamicType.sharedAppDelegate = self
		}
	}
	
	func applicationDidFinishLaunching(aNotification: NSNotification) {
		introWindowController = NSStoryboard(name: "Main", bundle: nil).instantiateControllerWithIdentifier("IntroWindow") as? NSWindowController
		introWindowController!.showWindow(self)
	}
	
	func applicationWillTerminate(aNotification: NSNotification) {
		// Insert code here to tear down your application
	}
	
	func closeIntroWindow() {
		introWindowController?.close()
		introWindowController = nil /* No need to keep a reference to a class we'll never use again. */
	}

}
