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
	
	func applicationDidFinishLaunching(aNotification: NSNotification) {
		let wc = NSStoryboard(name: "Main", bundle: nil).instantiateControllerWithIdentifier("IntroWindow") as! NSWindowController
		wc.showWindow(self)
	}
	
	func applicationWillTerminate(aNotification: NSNotification) {
		// Insert code here to tear down your application
	}

}
