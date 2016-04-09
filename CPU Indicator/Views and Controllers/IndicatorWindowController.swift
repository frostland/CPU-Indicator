/*
 * IndicatorWindowController.swift
 * CPU Indicator
 *
 * Created by François Lamboley on 9/23/15.
 * Copyright © 2015 Frost Land. All rights reserved.
 */

import Cocoa



class IndicatorWindowController: NSWindowController, CPUUsageObserver {
	
	private var skinView: SkinView! {
		return (self.contentViewController as? IndicatorWindowContentViewController)?.skinView
	}
	
	private var observingUDC = false
	private let observedUDCKeys = [
		"values.\(kUDK_ShowWindowIndicator)",
		"values.\(kUDK_WindowIndicatorLevel)", "values.\(kUDK_WindowIndicatorOpacity)",
		"values.\(kUDK_WindowIndicatorClickless)", "values.\(kUDK_WindowIndicatorLocked)",
		"values.\(kUDK_WindowIndicatorScale)", "values.\(kUDK_WindowIndicatorDisableShadow)"
	]
	
	deinit {
		if observingUDC {
			CPUUsageGetter.sharedCPUUsageGetter.removeObserverForKnownUsageModification(self)
			AppDelegate.sharedAppDelegate.removeObserver(self, forKeyPath: "selectedSkinObjectID", context: nil)
			for keyPath in observedUDCKeys {
				NSUserDefaultsController.sharedUserDefaultsController().removeObserver(self, forKeyPath: keyPath)
			}
		}
	}
	
	override func windowDidLoad() {
		super.windowDidLoad()
		
		self.window?.opaque = false
		self.window?.movableByWindowBackground = true
		self.window?.backgroundColor = NSColor.clearColor()
		
		super.windowDidLoad()
		
		let udc = NSUserDefaultsController.sharedUserDefaultsController()
		for keyPath in observedUDCKeys {
			udc.addObserver(self, forKeyPath: keyPath, options: [.Initial], context: nil)
		}
		AppDelegate.sharedAppDelegate.addObserver(self, forKeyPath: "selectedSkinObjectID", options: [.Initial], context: nil)
		CPUUsageGetter.sharedCPUUsageGetter.addObserverForKnownUsageModification(self)
		observingUDC = true
	}
	
	override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
		guard let kp = keyPath else {
			super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
			return
		}
		
		if observedUDCKeys.contains(kp) && object === NSUserDefaultsController.sharedUserDefaultsController() {
			let prefix = "values."
			let ud = NSUserDefaults.standardUserDefaults()
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
				self.updateSkinAndScale()
				
			case kUDK_WindowIndicatorDisableShadow:
				self.window?.hasShadow = !ud.boolForKey(kUDK_WindowIndicatorDisableShadow)
				
			case kUDK_WindowIndicatorDecreaseOpacityOnHover:
				(/*TODO*/)
				
			default:
				fatalError("Unreachable code has been reached!")
			}
		} else if kp == "selectedSkinObjectID" && object === AppDelegate.sharedAppDelegate {
			self.updateSkinAndScale()
		} else {
			super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
		}
	}
	
	@IBAction func moveWindowToTopLeft(sender: AnyObject!) {
		guard let screenRect = self.window?.screen?.frame, var f = self.window?.frame else {
			return
		}
		f.origin.x = screenRect.origin.x
		f.origin.y = screenRect.origin.y + screenRect.size.height - f.size.height
		self.window?.setFrame(f, display: true, animate: true)
	}
	
	@IBAction func moveWindowToPseudoTopLeft(sender: AnyObject!) {
		guard let screenRect = self.window?.screen?.visibleFrame, var f = self.window?.frame else {
			return
		}
		f.origin.x = screenRect.origin.x
		f.origin.y = screenRect.origin.y + screenRect.size.height - f.size.height
		self.window?.setFrame(f, display: true, animate: true)
	}
	
	@IBAction func moveWindowToTopRight(sender: AnyObject!) {
		guard let screenRect = self.window?.screen?.frame, var f = self.window?.frame else {
			return
		}
		f.origin.x = screenRect.origin.x + screenRect.size.width - f.size.width
		f.origin.y = screenRect.origin.y + screenRect.size.height - f.size.height
		self.window?.setFrame(f, display: true, animate: true)
	}
	
	@IBAction func moveWindowToPseudoTopRight(sender: AnyObject!) {
		guard let screenRect = self.window?.screen?.visibleFrame, var f = self.window?.frame else {
			return
		}
		f.origin.x = screenRect.origin.x + screenRect.size.width - f.size.width
		f.origin.y = screenRect.origin.y + screenRect.size.height - f.size.height
		self.window?.setFrame(f, display: true, animate: true)
	}
	
	@IBAction func moveWindowToBottomLeft(sender: AnyObject!) {
		guard let screenRect = self.window?.screen?.frame, var f = self.window?.frame else {
			return
		}
		f.origin.x = screenRect.origin.x
		f.origin.y = screenRect.origin.y
		self.window?.setFrame(f, display: true, animate: true)
	}
	
	@IBAction func moveWindowToPseudoBottomLeft(sender: AnyObject!) {
		guard let screenRect = self.window?.screen?.visibleFrame, var f = self.window?.frame else {
			return
		}
		f.origin.x = screenRect.origin.x
		f.origin.y = screenRect.origin.y
		self.window?.setFrame(f, display: true, animate: true)
	}
	
	@IBAction func moveWindowToBottomRight(sender: AnyObject!) {
		guard let screenRect = self.window?.screen?.frame, var f = self.window?.frame else {
			return
		}
		f.origin.x = screenRect.origin.x + screenRect.size.width - f.size.width
		f.origin.y = screenRect.origin.y
		self.window?.setFrame(f, display: true, animate: true)
	}
	
	@IBAction func moveWindowToPseudoBottomRight(sender: AnyObject!) {
		guard let screenRect = self.window?.screen?.visibleFrame, var f = self.window?.frame else {
			return
		}
		f.origin.x = screenRect.origin.x + screenRect.size.width - f.size.width
		f.origin.y = screenRect.origin.y
		self.window?.setFrame(f, display: true, animate: true)
	}
	
	/* **************************
	   MARK: - CPU Usage Observer
	   ************************** */
	
	func cpuUsageChangedFromGetter(getter: CPUUsageGetter) {
		self.skinView.progress = Float(getter.globalCPUUsage)
	}
	
	/* ***************
	   MARK: - Private
	   *************** */
	
	private func updateSkinAndScale() {
		let appDelegate = AppDelegate.sharedAppDelegate
		let context = appDelegate.mainManagedObjectContext
		let scale = CGFloat(NSUserDefaults.standardUserDefaults().doubleForKey(kUDK_WindowIndicatorScale))
		
		var sizedSkinO: SizedSkin?
		context.performBlockAndWait {
			guard let skin = (try? context.existingObjectWithID(appDelegate.selectedSkinObjectID)) as? Skin else {
				return
			}
			
			let w = CGFloat(skin.width), h = CGFloat(skin.height)
			var size = NSMakeSize(w * scale, h * scale)
			let f = w / h
			if size.width  <  9 {size.width  =  9; size.height = size.width  / f}
			if size.height < 19 {size.height = 19; size.width  = size.height * f}
			sizedSkinO = SizedSkin(skin: skin, size: size, allowDistortion: false)
		}
		guard let sizedSkin = sizedSkinO else {return}
		self.skinView.sizedSkin = sizedSkin
		self.window?.setContentSize(sizedSkin.size)
		self.window?.invalidateShadow()
	}
	
}
