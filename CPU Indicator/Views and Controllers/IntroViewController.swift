/*
 * IntroViewController.swift
 * CPU Indicator
 *
 * Created by François Lamboley on 13/06/15.
 * Copyright © 2015 Frost Land. All rights reserved.
 */

import Cocoa



class IntroViewController: NSViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	@IBAction func okButtonTapped(sender: AnyObject?) {
		AppDelegate.sharedAppDelegate.closeIntroWindow()
	}
	
}
