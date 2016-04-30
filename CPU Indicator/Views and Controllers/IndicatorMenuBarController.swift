/*
 * IndicatorMenuBarController.swift
 * CPU Indicator
 *
 * Created by François Lamboley on 10/11/15.
 * Copyright © 2015 Frost Land. All rights reserved.
 */

import Cocoa



class IndicatorMenuBarController : NSObject, CPUUsageObserver {
	
	@IBOutlet var menu: NSMenu!
	
	deinit {
		if observingUDC {
			CPUUsageGetter.sharedCPUUsageGetter.removeObserverForKnownUsageModification(self)
			AppDelegate.sharedAppDelegate.removeObserver(self, forKeyPath: "selectedSkinObjectID", context: nil)
			for keyPath in observedUDCKeys {
				NSUserDefaultsController.sharedUserDefaultsController().removeObserver(self, forKeyPath: keyPath)
			}
		}
	}
	
	func applicationWillFinishLaunching() {
		let udc = NSUserDefaultsController.sharedUserDefaultsController()
		for keyPath in observedUDCKeys {
			udc.addObserver(self, forKeyPath: keyPath, options: .Initial, context: nil)
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
			case kUDK_ShowMenuIndicator:
				if ud.boolForKey(kUDK_ShowMenuIndicator) {showIndicatorsIfNeeded()}
				else                                     {hideIndicatorsIfNeeded()}
				
			case kUDK_MenuIndicatorOnePerCPU:
				if ud.boolForKey(kUDK_ShowMenuIndicator) {
					/* Let's refresh the number of status items shown by hiding/showing
				 * the indicators. */
					hideIndicatorsIfNeeded()
					showIndicatorsIfNeeded()
				}
				
			case kUDK_MenuIndicatorMode:
				updateStatusItems(allowAnimation: true)
				
			case kUDK_MixedImageState:
				updateResolvedMixedImageState()
				updateStatusItems(allowAnimation: true)
				
			default:
				super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
			}
		} else if kp == "selectedSkinObjectID" && object === AppDelegate.sharedAppDelegate {
			updateSkin()
		} else {
			super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
		}
	}
	
	private func showIndicatorsIfNeeded() {
		guard statusItems.count == 0 else {
			/* The status items are already being shown. */
			return
		}
		
		let oneMenuPerCPU = NSUserDefaults.standardUserDefaults().boolForKey(kUDK_MenuIndicatorOnePerCPU)
		let n = oneMenuPerCPU ? CPUUsageGetter.sharedCPUUsageGetter.cpuCount : 1
		for i in 0..<n {
			let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)
			statusItem.menu = (menu.copy() as! NSMenu)
			statusItem.menu?.itemWithTag(42)?.title = (oneMenuPerCPU ? String(format: NSLocalizedString("proc %lu", comment: ""), i+1) : NSLocalizedString("global cpu usage", comment: ""))
			statusItem.button?.imagePosition = .ImageLeft
			
			let layer = CALayer()
			layer.delegate = self /* To disable the animations */
			statusItem.button?.wantsLayer = true
			statusItem.button?.layer?.addSublayer(layer)
			
			let fullItem = (item: statusItem, skinLayer: layer)
			updateStatusItem(fullItem, forProcAtIndex: (oneMenuPerCPU ? i : nil), allowAnimation: false)
			statusItems.append(fullItem)
		}
	}
	
	private func hideIndicatorsIfNeeded() {
		for (statusItem, _) in statusItems {
			NSStatusBar.systemStatusBar().removeStatusItem(statusItem)
		}
		statusItems.removeAll()
	}
	
	/* **************************
	   MARK: - CPU Usage Observer
	   ************************** */
	
	func cpuUsageChangedFromGetter(getter: CPUUsageGetter) {
		updateStatusItems(allowAnimation: true)
	}
	
	/* ************************
	   MARK: - CALayer Delegate
	   ************************ */
	
	override func actionForLayer(layer: CALayer, forKey event: String) -> CAAction? {
		/* Disables the animation for any property change. */
		return NSNull()
		
		/* We must override the method or the Swift compiler is unhappy, BUT the
		 * method is actually not implemented by super... If it were, here is the
		 * code we would have used: */
		/*if statusItems.indexOf({$0.skinLayer === layer}) != nil {
			return NSNull()
		}
		return super.actionForLayer(layer, forKey: event) */
	}
	
	/* ***************
	   MARK: - Private
	   *************** */
	
	private var observingUDC = false
	private let observedUDCKeys = [
		"values.\(kUDK_ShowMenuIndicator)",
		"values.\(kUDK_MenuIndicatorOnePerCPU)", "values.\(kUDK_MenuIndicatorMode)",
		"values.\(kUDK_MixedImageState)"
	]
	
	private let menuBarHeight = NSStatusBar.systemStatusBar().thickness
	private let vSpacing = CGFloat(1)
	
	private var statusItems = [(item: NSStatusItem, skinLayer: CALayer)]()
	
	private var sizedSkin: SizedSkin?
	private var emptyImageForItem: NSImage?
	private var resolvedMixedImageState: MixedImageState?
	
	private func updateResolvedMixedImageState() {
		guard let sizedSkin = sizedSkin else {
			resolvedMixedImageState = nil
			return
		}
		
		/* Must be on main thread to be able to access properties of the managed object. */
		assert(NSThread.isMainThread())
		
		let defaultMixedImageState = MixedImageState(rawValue: Int16(NSUserDefaults.standardUserDefaults().integerForKey(kUDK_MixedImageState))) ?? .UseSkinDefault
		if defaultMixedImageState == .UseSkinDefault {resolvedMixedImageState = sizedSkin.skin.mixedImageState ?? .Disallow}
		else                                         {resolvedMixedImageState = defaultMixedImageState}
	}
	
	private func updateSkin() {
		let appDelegate = AppDelegate.sharedAppDelegate
		let context = appDelegate.mainManagedObjectContext
		
		emptyImageForItem = nil
		
		context.performBlockAndWait {
			guard let skin = (try? context.existingObjectWithID(appDelegate.selectedSkinObjectID)) as? Skin else {
				return
			}
			
			let r = CGFloat(skin.width) / CGFloat(skin.height)
			let h = self.menuBarHeight - 2*self.vSpacing
			let w = h * r
			self.sizedSkin = SizedSkin(skin: skin, size: NSSize(width: w, height: h), allowDistortion: false)
		}
		
		updateResolvedMixedImageState()
		
		if let sizedSkin = sizedSkin {
			emptyImageForItem = NSImage(size: sizedSkin.size)
			for (_, layer) in statusItems {
				layer.frame = CGRect(x: 3 /* Magic number (visually pleasant) */, y: self.vSpacing, width: sizedSkin.size.width, height: sizedSkin.size.height)
			}
		}
		
		/* Updating the status items if they show the image. */
		let mode = NSUserDefaults.standardUserDefaults().integerForKey(kUDK_MenuIndicatorMode)
		if mode == MenuIndicatorMode.Image.rawValue || mode == MenuIndicatorMode.Both.rawValue {
			updateStatusItems(allowAnimation: false)
		}
	}
	
	private func updateStatusItems(allowAnimation allowAnimation: Bool) {
		let oneMenuPerCPU = NSUserDefaults.standardUserDefaults().boolForKey(kUDK_MenuIndicatorOnePerCPU)
		for (i, statusItem) in statusItems.enumerate() {
			updateStatusItem(statusItem, forProcAtIndex: (oneMenuPerCPU ? i : nil), allowAnimation: allowAnimation)
		}
	}
	
	private func updateStatusItem(statusItem: (item: NSStatusItem, skinLayer: CALayer), forProcAtIndex procIndex: Int?, allowAnimation: Bool) {
		let mode = NSUserDefaults.standardUserDefaults().integerForKey(kUDK_MenuIndicatorMode)
		let load = (procIndex != nil ? CPUUsageGetter.sharedCPUUsageGetter.cpuUsages[procIndex!] : CPUUsageGetter.sharedCPUUsageGetter.globalCPUUsage)
		
		/* Updating text */
		statusItem.item.button?.title = (mode == MenuIndicatorMode.Text.rawValue || mode == MenuIndicatorMode.Both.rawValue ? String(format: NSLocalizedString("%lu%%", comment: ""), Int(load*100 + 0.5)) : "")
		
		/* Updating image */
		if mode == MenuIndicatorMode.Image.rawValue || mode == MenuIndicatorMode.Both.rawValue, let sizedSkin = sizedSkin {
			statusItem.item.button?.image = emptyImageForItem
			sizedSkin.setLayerContents(statusItem.skinLayer, forProgress: Float(load), mixedImageState: resolvedMixedImageState ?? .Disallow, allowAnimation: allowAnimation)
		} else {
			statusItem.item.button?.image = nil
			statusItem.skinLayer.contents = nil
		}
	}
	
}
