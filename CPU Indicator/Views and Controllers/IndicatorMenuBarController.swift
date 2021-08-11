/*
 * IndicatorMenuBarController.swift
 * CPU Indicator
 *
 * Created by François Lamboley on 10/11/15.
 * Copyright © 2015 Frost Land. All rights reserved.
 */

import Cocoa

import XibLoc



class IndicatorMenuBarController : NSObject, CALayerDelegate, CPUUsageObserver {
	
	@IBOutlet var menu: NSMenu!
	
	deinit {
		if observingUDC {
			CPUUsageGetter.sharedCPUUsageGetter.removeObserverForKnownUsageModification(self)
			AppDelegate.sharedAppDelegate.removeObserver(self, forKeyPath: "selectedSkinObjectID", context: nil)
			for keyPath in observedUDCKeys {
				NSUserDefaultsController.shared.removeObserver(self, forKeyPath: keyPath)
			}
		}
	}
	
	func applicationWillFinishLaunching() {
		let udc = NSUserDefaultsController.shared
		for keyPath in observedUDCKeys {
			udc.addObserver(self, forKeyPath: keyPath, options: .initial, context: nil)
		}
		AppDelegate.sharedAppDelegate.addObserver(self, forKeyPath: "selectedSkinObjectID", options: [.initial], context: nil)
		CPUUsageGetter.sharedCPUUsageGetter.addObserverForKnownUsageModification(self)
		observingUDC = true
	}
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		guard let kp = keyPath else {
			super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
			return
		}
		
		if observedUDCKeys.contains(kp) && object as? NSUserDefaultsController === NSUserDefaultsController.shared {
			let prefix = "values."
			let ud = UserDefaults.standard
			switch String(kp[prefix.endIndex...]) {
			case kUDK_ShowMenuIndicator:
				if ud.bool(forKey: kUDK_ShowMenuIndicator) {showIndicatorsIfNeeded()}
				else                                     {hideIndicatorsIfNeeded()}
				
			case kUDK_MenuIndicatorOnePerCPU:
				if ud.bool(forKey: kUDK_ShowMenuIndicator) {
					/* Let's refresh the number of status items shown by
					 * hiding/showing the indicators. */
					hideIndicatorsIfNeeded()
					showIndicatorsIfNeeded()
				}
				
			case kUDK_MenuIndicatorMode:
				updateStatusItems(allowAnimation: true)
				
			case kUDK_MixedImageState:
				updateResolvedMixedImageState()
				updateStatusItems(allowAnimation: true)
				
			default:
				super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
			}
		} else if kp == "selectedSkinObjectID" && object as? AppDelegate === AppDelegate.sharedAppDelegate {
			updateSkin()
		} else {
			super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
		}
	}
	
	private func showIndicatorsIfNeeded() {
		guard statusItems.count == 0 else {
			/* The status items are already being shown. */
			return
		}
		
		let oneMenuPerCPU = UserDefaults.standard.bool(forKey: kUDK_MenuIndicatorOnePerCPU)
		let n = oneMenuPerCPU ? CPUUsageGetter.sharedCPUUsageGetter.cpuCount : 1
		for i in 0..<n {
			let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
			statusItem.menu = (menu.copy() as! NSMenu)
			statusItem.menu?.item(withTag: 42)?.title = (oneMenuPerCPU ?
				NSLocalizedString("proc #", comment: "The processor number; shown in the menu when the indicator is clicked in the menu bar (when one menu item per CPU for the CPU Usage).").applyingCommonTokens(number: .init(i+1)) :
				NSLocalizedString("global cpu usage", comment: "Global CPU Usage. Shown in the menu when the indicator is clicked in the menu bar (when only one menu item for the CPU Usage).")
			)
			statusItem.button?.imagePosition = .imageLeft
			
			let layer = CALayer()
			layer.delegate = self /* To disable the animations */
			statusItem.button?.wantsLayer = true
			statusItem.button?.layer?.addSublayer(layer)
			if let sizedSkin = sizedSkin {updateStatusItemLayerFrame(layer, withSizedSkin: sizedSkin)}
			
			let fullItem = (item: statusItem, skinLayer: layer)
			updateStatusItem(fullItem, forProcAtIndex: (oneMenuPerCPU ? i : nil), allowAnimation: false)
			statusItems.append(fullItem)
		}
	}
	
	private func hideIndicatorsIfNeeded() {
		statusItems.forEach{ NSStatusBar.system.removeStatusItem($0.item) }
		statusItems.removeAll()
	}
	
	/* **************************
	   MARK: - CPU Usage Observer
	   ************************** */
	
	func cpuUsageChanged(getter: CPUUsageGetter) {
		updateStatusItems(allowAnimation: true)
	}
	
	/* ************************
	   MARK: - CALayer Delegate
	   ************************ */
	
	func action(for layer: CALayer, forKey event: String) -> CAAction? {
		/* Disables the animation for any property change. */
		return nil
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
	
	private let menuBarHeight = NSStatusBar.system.thickness
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
		assert(Thread.isMainThread)
		
		let defaultMixedImageState = MixedImageState(rawValue: Int16(UserDefaults.standard.integer(forKey: kUDK_MixedImageState))) ?? .useSkinDefault
		if defaultMixedImageState == .useSkinDefault {resolvedMixedImageState = sizedSkin.skin.mixedImageState}
		else                                         {resolvedMixedImageState = defaultMixedImageState}
	}
	
	private func updateSkin() {
		let appDelegate = AppDelegate.sharedAppDelegate
		let context = appDelegate?.mainManagedObjectContext
		
		emptyImageForItem = nil
		
		context?.performAndWait {
			guard let skin = (try? context?.existingObject(with: (appDelegate?.selectedSkinObjectID)!)) as? Skin else {
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
			statusItems.forEach {updateStatusItemLayerFrame($0.skinLayer, withSizedSkin: sizedSkin)}
		}
		
		/* Updating the status items if they show the image. */
		let mode = UserDefaults.standard.integer(forKey: kUDK_MenuIndicatorMode)
		if mode == MenuIndicatorMode.image.rawValue || mode == MenuIndicatorMode.both.rawValue {
			updateStatusItems(allowAnimation: false)
		}
	}
	
	private func updateStatusItemLayerFrame(_ layer: CALayer, withSizedSkin sizedSkin: SizedSkin) {
		layer.frame = CGRect(x: 3 /* Magic number (visually pleasant) */, y: vSpacing, width: sizedSkin.size.width, height: sizedSkin.size.height)
	}
	
	private func updateStatusItems(allowAnimation: Bool) {
		let oneMenuPerCPU = UserDefaults.standard.bool(forKey: kUDK_MenuIndicatorOnePerCPU)
		for (i, statusItem) in statusItems.enumerated() {
			updateStatusItem(statusItem, forProcAtIndex: (oneMenuPerCPU ? i : nil), allowAnimation: allowAnimation)
		}
	}
	
	private func updateStatusItem(_ statusItem: (item: NSStatusItem, skinLayer: CALayer), forProcAtIndex procIndex: Int?, allowAnimation: Bool) {
		let mode = UserDefaults.standard.integer(forKey: kUDK_MenuIndicatorMode)
		let load = (procIndex != nil ? CPUUsageGetter.sharedCPUUsageGetter.cpuUsages[procIndex!] : CPUUsageGetter.sharedCPUUsageGetter.globalCPUUsage)
		
		/* Updating text */
		statusItem.item.button?.title = (mode == MenuIndicatorMode.text.rawValue || mode == MenuIndicatorMode.both.rawValue ? String(format: NSLocalizedString("%lu%%", comment: ""), Int(load*100 + 0.5)) : "")
		
		/* Updating image */
		if mode == MenuIndicatorMode.image.rawValue || mode == MenuIndicatorMode.both.rawValue, let sizedSkin = sizedSkin {
			statusItem.item.button?.image = emptyImageForItem
			sizedSkin.setLayerContents(statusItem.skinLayer, forProgress: Float(load), mixedImageState: resolvedMixedImageState ?? .disallow, allowAnimation: allowAnimation)
		} else {
			statusItem.item.button?.image = nil
			statusItem.skinLayer.contents = nil
		}
	}
	
}
