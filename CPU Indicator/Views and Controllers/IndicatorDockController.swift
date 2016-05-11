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
				dockTileIndicatorView?.defaultMixedImageState = defaultMixedImageState
				
			default:
				super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
			}
		} else if kp == "selectedSkinObjectID" && object === AppDelegate.sharedAppDelegate {
			if let skin = skin {dockTileIndicatorView?.skin = skin}
			else               {NSLog("Weird... Cannot get current skin.")}
			
		} else {
			super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
		}
	}
	
	/* ************************
	   MARK: CPU Usage Observer
	   ************************ */
	
	func cpuUsageChangedFromGetter(getter: CPUUsageGetter) {
		dockTileIndicatorView?.progress = Float(getter.globalCPUUsage)
	}
	
	/* ***************
	   MARK: - Private
	   *************** */
	
	private var observingUDC = false
	private let observedUDCKeys = [
		"values.\(kUDK_DockIconIsCPUIndicator)",
		"values.\(kUDK_MixedImageState)"
	]
	
	private var skin: Skin? {
		let appDelegate = AppDelegate.sharedAppDelegate
		let context = appDelegate.mainManagedObjectContext
		assert(context.concurrencyType == .MainQueueConcurrencyType)
		
		return (try? context.existingObjectWithID(appDelegate.selectedSkinObjectID)) as? Skin
	}
	
	private var defaultMixedImageState: MixedImageState {
		return MixedImageState(rawValue: Int16(NSUserDefaults.standardUserDefaults().integerForKey(kUDK_MixedImageState))) ?? .UseSkinDefault
	}
	
	private var dockTileIndicatorView: DockTileIndicatorView?
	
	private func showIndicatorIfNeeded() {
		guard let skin = skin else {return}
		
		dockTileIndicatorView = DockTileIndicatorView(dockTile: NSApp.dockTile, skin: skin, defaultMixedImageState: defaultMixedImageState)
		NSApp.dockTile.contentView = dockTileIndicatorView
		NSApp.dockTile.display()
	}
	
	private func hideIndicatorIfNeeded() {
		NSApp.dockTile.contentView = nil
	}
	
	/** Expects to be the content view of a dock tile. Uses dockTile.display when
	redraw is needed. */
	private class DockTileIndicatorView : NSView {
		
		let dockTile: NSDockTile
		
		init(dockTile dt: NSDockTile, skin s: Skin, defaultMixedImageState dmis: MixedImageState) {
			skin = s
			dockTile = dt
			defaultMixedImageState = dmis
			super.init(frame: CGRect(origin: CGPointZero, size: dt.size))
			
			updateResolvedMixedImageState(forceImageUpdate: true)
		}
		
		required init?(coder: NSCoder) {
			fatalError("Cannot init this class with a coder")
		}
		
		var skin: Skin {
			didSet {
				assert(skin.managedObjectContext?.concurrencyType == nil || skin.managedObjectContext?.concurrencyType == .MainQueueConcurrencyType)
				updateResolvedMixedImageState(forceImageUpdate: true)
			}
		}
		
		var defaultMixedImageState: MixedImageState {
			didSet {
				guard oldValue != defaultMixedImageState else {return}
				updateResolvedMixedImageState(forceImageUpdate: false)
			}
		}
		
		var progress: Float = 0 {
			didSet {
				assert(NSThread.isMainThread())
				updateImageFromCurrentProgress(allowAnimation: true)
			}
		}
		
		private var resolvedMixedImageState: MixedImageState?
		private var sizedSkin: SizedSkin?
		
		private func updateResolvedMixedImageState(forceImageUpdate forceImageUpdate: Bool) {
			assert(NSThread.isMainThread()) /* Must be on main thread because we're accessing the skin, which is on a main queue managed object context */
			let currentResolvedMixedImageState = resolvedMixedImageState
			if defaultMixedImageState == .UseSkinDefault {resolvedMixedImageState = skin.mixedImageState ?? .Disallow}
			else                                         {resolvedMixedImageState = defaultMixedImageState}
			if forceImageUpdate || resolvedMixedImageState != currentResolvedMixedImageState {
				displayedProgress = nil
				updateImageFromCurrentProgress(allowAnimation: !forceImageUpdate)
			}
		}
		
		private func updateImageFromCurrentProgress(allowAnimation allowAnimation: Bool) {
			/* TODO: The (manual) animation... */
			let animate = (allowAnimation && resolvedMixedImageState != .Disallow)
			
			if resolvedMixedImageState == .Allow {displayedProgress = progress}
			else {
				/* We must stick to the reference frames. */
				let n = skin.frames?.count ?? 1
				guard n > 1 else {displayedProgress = 0; return}
				
				let imageIdx = Int(progress * Float(n-1))
				displayedProgress = (Float(imageIdx) / Float(n-1));
			}
		}
		
		/* If set to nil, nothing is done. */
		private var displayedProgress: Float? {
			didSet {
				guard let displayedProgress = displayedProgress else {return}
				
				assert(displayedProgress >= 0 && displayedProgress <= 1)
				guard abs(displayedProgress - (oldValue ?? -1)) > 0.01 else {return}
				
				setNeedsDisplayInRect(bounds)
				dockTile.display()
			}
		}
		
		private override func drawRect(dirtyRect: NSRect) {
			guard let displayedProgress = displayedProgress else {return}
			
			let finalSizedSkin: SizedSkin
			if let sizedSkin = sizedSkin where
				sizedSkin.skin.objectID == skin.objectID &&
				(abs(sizedSkin.originalSize.width  - dockTile.size.width)  < 0.5 &&
				 abs(sizedSkin.originalSize.height - dockTile.size.height) < 0.5)
			{
				finalSizedSkin = sizedSkin
			} else {
				finalSizedSkin = SizedSkin(skin: skin, size: dockTile.size, allowDistortion: false)
			}
			
			let myFrame = self.frame
			
			let drawnSize = finalSizedSkin.size
			let p = NSPoint(
				x: myFrame.origin.x + (myFrame.size.width  - drawnSize.width)/2,
				y: myFrame.origin.y + (myFrame.size.height - drawnSize.height)/2
			)
			
			let drawRect = NSRect(origin: p, size: drawnSize)
			finalSizedSkin.imageForProgress(displayedProgress).drawInRect(
				drawRect,
				fromRect: NSRect(origin: CGPointZero, size: drawnSize),
				operation: .CompositeSourceOver,
				fraction: 1,
				respectFlipped: true,
				hints: nil
			)
			
			finalSizedSkin.imageForProgress(displayedProgress)
		}
		
	}
	
}
