/*
 * IndicatorDockController.swift
 * CPU Indicator
 *
 * Created by François Lamboley on 10/11/15.
 * Copyright © 2015 Frost Land. All rights reserved.
 */

import Cocoa



class IndicatorDockController : NSObject {
	
	private var observingUDC = false
	private let observedUDCKeys = [
		"values.\(kUDK_DockIconIsCPUIndicator)",
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
		case kUDK_DockIconIsCPUIndicator:
			if ud.boolForKey(kUDK_DockIconIsCPUIndicator) {showIndicatorIfNeeded()}
			else                                          {hideIndicatorIfNeeded()}
		default:
			fatalError("Unreachable code has been reached!")
		}
	}
	
	private func showIndicatorIfNeeded() {
	}
	
	private func hideIndicatorIfNeeded() {
	}
	
}
