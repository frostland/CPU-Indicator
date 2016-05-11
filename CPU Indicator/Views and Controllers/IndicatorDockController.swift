/*
 * IndicatorDockController.swift
 * CPU Indicator
 *
 * Created by François Lamboley on 10/11/15.
 * Copyright © 2015 Frost Land. All rights reserved.
 */

import Cocoa



class IndicatorDockController : NSObject, CPUUsageObserver {
	
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
	
	/* ********************
	   MARK: - KVO Handling
	   ******************** */
	
	override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
		guard let kp = keyPath else {
			super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
			return
		}
		
		if observedUDCKeys.contains(kp) && object === NSUserDefaultsController.sharedUserDefaultsController() {
			let prefix = "values."
			let ud = NSUserDefaults.standardUserDefaults()
			switch kp.substringFromIndex(prefix.endIndex) {
			case kUDK_DockIconIsCPUIndicator:
				if ud.boolForKey(kUDK_DockIconIsCPUIndicator) {showIndicatorIfNeeded()}
				else                                          {hideIndicatorIfNeeded()}
				
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
	
	/* ************************
	   MARK: CPU Usage Observer
	   ************************ */
	
	func cpuUsageChangedFromGetter(getter: CPUUsageGetter) {
		NSApp.dockTile.display()
	}
	
	/* ***************
	   MARK: - Private
	   *************** */
	
	private var observingUDC = false
	private let observedUDCKeys = [
		"values.\(kUDK_DockIconIsCPUIndicator)",
		"values.\(kUDK_MixedImageState)"
	]
	
	private func showIndicatorIfNeeded() {
		NSApp.dockTile.contentView = DockTileIndicatorView(dockTile: NSApp.dockTile)
		NSApp.dockTile.display()
	}
	
	private func hideIndicatorIfNeeded() {
		NSApp.dockTile.contentView = nil
	}
	
	/** Expects to be the content view of a dock tile. Uses dockTile.display when
	redraw is needed. */
	private class DockTileIndicatorView : NSView {
		
		let dockTile: NSDockTile
		
		init(dockTile dt: NSDockTile) {
			dockTile = dt
			super.init(frame: CGRect(origin: CGPointZero, size: dt.size))
		}
		
		required init?(coder: NSCoder) {
			fatalError("Cannot init this class with a coder")
		}
		
		private override func drawRect(dirtyRect: NSRect) {
			/* TODO */
		}
		
	}
	
}
