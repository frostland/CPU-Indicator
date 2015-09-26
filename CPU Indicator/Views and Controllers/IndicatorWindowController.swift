/*
 * IndicatorWindowController.swift
 * CPU Indicator
 *
 * Created by François Lamboley on 9/23/15.
 * Copyright © 2015 Frost Land. All rights reserved.
 */

import Cocoa



class IndicatorWindowController: NSWindowController {
	private var observingUDC = false
	private let observedUDCKeys = [
		"values.\(kUDK_ShowWindowIndicator)",
		"values.\(kUDK_WindowIndicatorLevel)", "values.\(kUDK_WindowIndicatorOpacity)",
		"values.\(kUDK_WindowIndicatorClickless)", "values.\(kUDK_WindowIndicatorLocked)",
		"values.\(kUDK_WindowIndicatorScale)", "values.\(kUDK_WindowIndicatorDisableShadow)",
//		"values.\(kUDK_SelectedSkin)", "values.\(kUDK_MixedImageState)"
	]
	
	deinit {
		if observingUDC {
			for keyPath in observedUDCKeys {
				NSUserDefaultsController.sharedUserDefaultsController().removeObserver(self, forKeyPath: keyPath)
			}
		}
	}
	
	override func windowDidLoad() {
		super.windowDidLoad()
		
		let udc = NSUserDefaultsController.sharedUserDefaultsController()
		for keyPath in observedUDCKeys {
			udc.addObserver(self, forKeyPath: keyPath, options: .Initial, context: nil)
		}
		observingUDC = true
	}
	
	override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
		let prefix = "values."
		let ud = NSUserDefaults.standardUserDefaults()
		guard let kp = keyPath where kp.hasPrefix(prefix) && object === NSUserDefaultsController.sharedUserDefaultsController() else {
			super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
			return
		}
		
		switch kp.substringFromIndex(prefix.endIndex) {
		case kUDK_ShowWindowIndicator:
			if ud.boolForKey(kUDK_FirstRun) {
				if let window = window {
					let screenRect = window.screen?.visibleFrame ?? CGRectMake(0, 0, 640, 480)
					var f = window.frame
					f.origin.x = screenRect.origin.x + screenRect.size.width  - f.size.width
					f.origin.y = screenRect.origin.y + screenRect.size.height - f.size.height
					window.setFrame(f, display: true, animate: false)
				}
			}
			if ud.boolForKey(kUDK_ShowWindowIndicator) {self.showWindow(self)}
			else                                       {self.close()}
		case kUDK_WindowIndicatorLevel:
			switch WindowIndicatorLevel(rawValue: ud.integerForKey(kUDK_WindowIndicatorLevel)) ?? WindowIndicatorLevel.AboveAll {
			case .BehindAll:
				ud.setBool(true, forKey: kUDK_WindowIndicatorClickless)
				ud.setBool(true, forKey: kUDK_WindowIndicatorLocked)
				self.window?.level = Int(CGWindowLevelForKey(CGWindowLevelKey.DesktopWindowLevelKey))
				self.window?.collectionBehavior = [.CanJoinAllSpaces, .Transient]
			case .Normal:
				self.window?.level = Int(CGWindowLevelForKey(CGWindowLevelKey.NormalWindowLevelKey))
				self.window?.collectionBehavior = [.CanJoinAllSpaces, .Managed]
			case .AboveAll:
				self.window?.level = Int(CGWindowLevelForKey(CGWindowLevelKey.StatusWindowLevelKey))
				self.window?.collectionBehavior = [.CanJoinAllSpaces, .Stationary]
			}
		case kUDK_WindowIndicatorOpacity:
			self.window?.alphaValue = CGFloat(ud.floatForKey(kUDK_WindowIndicatorOpacity))
		case kUDK_WindowIndicatorClickless:
			self.window?.ignoresMouseEvents = ud.boolForKey(kUDK_WindowIndicatorClickless)
		case kUDK_WindowIndicatorLocked:
			self.window?.movable = !ud.boolForKey(kUDK_WindowIndicatorLocked)
		case kUDK_WindowIndicatorScale:
			(/*TODO*/)
		case kUDK_WindowIndicatorDisableShadow:
			self.window?.hasShadow = !ud.boolForKey(kUDK_WindowIndicatorDisableShadow)
		case kUDK_WindowIndicatorDecreaseOpacityOnHover:
			(/*TODO*/)
		default:
			super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
		}
	}
}
