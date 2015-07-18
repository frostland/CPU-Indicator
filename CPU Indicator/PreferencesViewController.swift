/*
* PreferencesViewController.swift
* CPU Indicator
*
* Created by François Lamboley on 7/18/15.
* Copyright © 2015 Frost Land. All rights reserved.
*/

import Cocoa



class PreferencesViewController: NSViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillAppear() {
		super.viewWillAppear()
		
		AppDelegate.sharedAppDelegate.closeIntroWindow()
	}
	
}
