/*
 * IndicatorMenuBarController.swift
 * CPU Indicator
 *
 * Created by François Lamboley on 10/11/15.
 * Copyright © 2015 Frost Land. All rights reserved.
 */

import Cocoa



class IndicatorMenuBarController : NSObject {
	
	@IBOutlet private var menu: NSMenu!
	
	private let menuBarHeight = NSStatusBar.systemStatusBar().thickness
	
	private var statusItems = [NSStatusItem]()
	
	private var observingUDC = false
	private let observedUDCKeys = [
		"values.\(kUDK_ShowMenuIndicator)",
		"values.\(kUDK_MenuIndicatorOnePerCPU)", "values.\(kUDK_MenuIndicatorMode)",
//		"values.\(kUDK_SelectedSkin)", "values.\(kUDK_MixedImageState)"
	]
	
	override init() {
		super.init()
		
		let udc = NSUserDefaultsController.sharedUserDefaultsController()
		for keyPath in observedUDCKeys {
			udc.addObserver(self, forKeyPath: keyPath, options: .Initial, context: nil)
		}
		observingUDC = true
	}
	
	deinit {
		if observingUDC {
			for keyPath in observedUDCKeys {
				NSUserDefaultsController.sharedUserDefaultsController().removeObserver(self, forKeyPath: keyPath)
			}
		}
	}
	
	override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
		guard let kp = keyPath where observedUDCKeys.contains(kp) && object === NSUserDefaultsController.sharedUserDefaultsController() else {
			super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
			return
		}
		
		let prefix = "values."
		let ud = NSUserDefaults.standardUserDefaults()
		switch kp.substringFromIndex(prefix.endIndex) {
		case kUDK_ShowMenuIndicator:
			if ud.boolForKey(kUDK_ShowMenuIndicator) {showIndicatorsIfNeeded()}
			else                                     {hideIndicatorsIfNeeded()}
		case kUDK_MenuIndicatorOnePerCPU:
			if ud.boolForKey(kUDK_ShowMenuIndicator) {
				/* Let's refresh the number of status items shown by hidding/showing
				 * the indicators. */
				hideIndicatorsIfNeeded()
				showIndicatorsIfNeeded()
			}
		case kUDK_MenuIndicatorMode:
			refreshStatusItemsMode()
		default:
			fatalError("Unreachable code has been reached!")
		}
	}
	
	private func showIndicatorsIfNeeded() {
		if statusItems.count > 0 {
			/* The status items are already being shown. */
			return
		}
	}
	
	private func hideIndicatorsIfNeeded() {
		if statusItems.count == 0 {
			/* The status items are already hidden. */
			return
		}
	}
	
	private func refreshStatusItemsMode() {
		for statusItem in statusItems {
		}
	}
	
}
