/*
 * PreferencesViewController.swift
 * CPU Indicator
 *
 * Created by François Lamboley on 7/18/15.
 * Copyright © 2015 Frost Land. All rights reserved.
 */

import Cocoa



class PreferencesViewController: NSTabViewController {
	
	var originalSizes = [String : NSSize]()
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillAppear() {
		super.viewWillAppear()
		
		AppDelegate.sharedAppDelegate.closeIntroWindow()
	}
	
	override func tabView(tabView: NSTabView, willSelectTabViewItem tabViewItem: NSTabViewItem?) {
		super.tabView(tabView, willSelectTabViewItem: tabViewItem)
		
		if let identifier = tabViewItem?.identifier as? String, v = tabViewItem?.view {
			if originalSizes[identifier] == nil {
				originalSizes[identifier] = v.frame.size
			}
		}
	}
	
	override func tabView(tabView: NSTabView, didSelectTabViewItem tabViewItem: NSTabViewItem?) {
		super.tabView(tabView, didSelectTabViewItem: tabViewItem)
		
		if let window = self.view.window, identifier = tabViewItem?.identifier as? String, s = self.originalSizes[identifier] {
			dispatch_after(DISPATCH_TIME_NOW, dispatch_get_main_queue()) { () -> Void in
				let destSize = window.frameRectForContentRect(NSMakeRect(0, 0, s.width, s.height)).size
				var windowFrame = window.frame
				windowFrame.origin.y += windowFrame.size.height - destSize.height
				windowFrame.size = destSize
				window.setFrame(windowFrame, display: true, animate: true)
			}
		}
	}
	
}
