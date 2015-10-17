/*
 * SkinsPrefsViewController.swift
 * CPU Indicator
 *
 * Created by François Lamboley on 10/17/15.
 * Copyright © 2015 Frost Land. All rights reserved.
 */

import Cocoa



class SkinsPrefsViewController: NSViewController {
	
	dynamic let managedObjectContext = AppDelegate.sharedAppDelegate.mainManagedObjectContext
	dynamic let sortDescriptors = [NSSortDescriptor(key: "sortPosition", ascending: true)]
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do view setup here.
	}
	
}
