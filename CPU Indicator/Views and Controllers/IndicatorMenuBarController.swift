/*
 * IndicatorMenuBarController.swift
 * CPU Indicator
 *
 * Created by François Lamboley on 10/11/15.
 * Copyright © 2015 Frost Land. All rights reserved.
 */

import Cocoa



class IndicatorMenuBarController : NSObject, CPUUsageObserver {
	
	@IBOutlet private var menu: NSMenu!
	
	private let menuBarHeight = NSStatusBar.systemStatusBar().thickness
	
	private var statusItems = [NSStatusItem]()
	
	private var observingUDC = false
	private let observedUDCKeys = [
		"values.\(kUDK_ShowMenuIndicator)",
		"values.\(kUDK_MenuIndicatorOnePerCPU)", "values.\(kUDK_MenuIndicatorMode)",
		"values.\(kUDK_MixedImageState)"
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
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
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
				refreshStatusItemsMode()
				
			case kUDK_MixedImageState:
				(/*TODO*/)
				
			default:
				super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
			}
		} else if kp == "selectedSkinObjectID" && object === AppDelegate.sharedAppDelegate {
			(/*TODO*/)
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
			updateStatusItem(statusItem, forProcAtIndex: (oneMenuPerCPU ? i : nil))
			statusItems.append(statusItem)
		}
	}
	
	private func hideIndicatorsIfNeeded() {
		for statusItem in statusItems {
			NSStatusBar.systemStatusBar().removeStatusItem(statusItem)
		}
		statusItems.removeAll()
	}
	
	private func refreshStatusItemsMode() {
		updateStatusItems()
	}
	
	/* **************************
	   MARK: - CPU Usage Observer
	   ************************** */
	
	func cpuUsageChangedFromGetter(getter: CPUUsageGetter) {
		updateStatusItems()
	}
	
	/* ***************
	   MARK: - Private
	   *************** */
	
	private func updateStatusItems() {
		let oneMenuPerCPU = NSUserDefaults.standardUserDefaults().boolForKey(kUDK_MenuIndicatorOnePerCPU)
		for (i, statusItem) in statusItems.enumerate() {
			updateStatusItem(statusItem, forProcAtIndex: (oneMenuPerCPU ? i : nil))
		}
	}
	
	private func updateStatusItem(statusItem: NSStatusItem, forProcAtIndex procIndex: Int?) {
		let mode = NSUserDefaults.standardUserDefaults().integerForKey(kUDK_MenuIndicatorMode)
		let load = (procIndex != nil ? CPUUsageGetter.sharedCPUUsageGetter.cpuUsages[procIndex!] : CPUUsageGetter.sharedCPUUsageGetter.globalCPUUsage)
		statusItem.title = (mode == MenuIndicatorMode.Text.rawValue || mode == MenuIndicatorMode.Both.rawValue ? String(format: NSLocalizedString("%lu%%", comment: ""), Int(load*100 + 0.5)) : nil)
	}
	
}
