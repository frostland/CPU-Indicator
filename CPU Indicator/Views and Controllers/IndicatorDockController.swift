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
	
	/* ********************
	   MARK: - KVO Handling
	   ******************** */
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		guard let kp = keyPath else {
			super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
			return
		}
		
		if observedUDCKeys.contains(kp) && object as? NSUserDefaultsController === NSUserDefaultsController.shared {
			let prefix = "values."
			let ud = UserDefaults.standard
			switch String(kp[prefix.endIndex...]) {
			case kUDK_DockIconIsCPUIndicator:
				if ud.bool(forKey: kUDK_DockIconIsCPUIndicator) {showIndicatorIfNeeded()}
				else                                          {hideIndicatorIfNeeded()}
				
			case kUDK_MixedImageState:
				dockTileIndicatorView?.defaultMixedImageState = defaultMixedImageState
				
			default:
				super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
			}
		} else if kp == "selectedSkinObjectID" && object as? AppDelegate === AppDelegate.sharedAppDelegate {
			if let skin = skin {dockTileIndicatorView?.skin = skin}
			else               {NSLog("Weird... Cannot get current skin.")}
			
		} else {
			super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
		}
	}
	
	/* ************************
	   MARK: CPU Usage Observer
	   ************************ */
	
	func cpuUsageChanged(getter: CPUUsageGetter) {
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
		let appDelegate = AppDelegate.sharedAppDelegate!
		let context = appDelegate.mainManagedObjectContext
		assert(context.concurrencyType == .mainQueueConcurrencyType)
		
		return (try? context.existingObject(with: appDelegate.selectedSkinObjectID)) as? Skin
	}
	
	private var defaultMixedImageState: MixedImageState {
		return MixedImageState(rawValue: Int16(UserDefaults.standard.integer(forKey: kUDK_MixedImageState))) ?? .useSkinDefault
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
			super.init(frame: CGRect(origin: CGPoint.zero, size: dt.size))
			
			updateResolvedMixedImageState(forceImageUpdate: true)
		}
		
		required init?(coder: NSCoder) {
			fatalError("Cannot init this class with a coder")
		}
		
		var skin: Skin {
			didSet {
				assert(skin.managedObjectContext?.concurrencyType == nil || skin.managedObjectContext?.concurrencyType == .mainQueueConcurrencyType)
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
				assert(Thread.isMainThread)
				updateImageFromCurrentProgress(allowAnimation: true)
			}
		}
		
		private var resolvedMixedImageState: MixedImageState?
		private var sizedSkin: SizedSkin?
		
		private var currentAnimation: ProgressAnimation?
		
		private func updateResolvedMixedImageState(forceImageUpdate: Bool) {
			assert(Thread.isMainThread) /* Must be on main thread because we're accessing the skin, which is on a main queue managed object context */
			let currentResolvedMixedImageState = resolvedMixedImageState
			if defaultMixedImageState == .useSkinDefault {resolvedMixedImageState = skin.mixedImageState}
			else                                         {resolvedMixedImageState = defaultMixedImageState}
			if forceImageUpdate || resolvedMixedImageState != currentResolvedMixedImageState {
				displayedProgress = nil
				updateImageFromCurrentProgress(allowAnimation: !forceImageUpdate)
			}
		}
		
		private func updateImageFromCurrentProgress(allowAnimation: Bool) {
			let destinationProgress: Float
			defer {
				if !allowAnimation || resolvedMixedImageState == .disallow {
					displayedProgress = destinationProgress
				} else {
					/* Let's setup an animation from current progress to destination
					 * progress. */
					currentAnimation?.stop()
					
					if abs(destinationProgress - (displayedProgress ?? -1)) > 0.01 {
						/* Destination progress is sufficiently than current displayed
						 * progress: the animation is worth it. */
						currentAnimation = ProgressAnimation(linkedView: self, startIndicatorProgress: displayedProgress ?? 0, endIndicatorProgress: destinationProgress, duration: 0.5, animationCurve: .linear)
						currentAnimation?.start()
					}
				}
			}
			
			if resolvedMixedImageState == .allow {destinationProgress = progress}
			else {
				/* We must stick to the reference frames. */
				let n = skin.frames?.count ?? 1
				guard n > 1 else {destinationProgress = 0; return}
				
				let imageIdx = Int(progress * Float(n-1))
				destinationProgress = (Float(imageIdx) / Float(n-1));
			}
		}
		
		/* If set to nil, nothing is done. */
		private var displayedProgress: Float? {
			didSet {
				guard let displayedProgress = displayedProgress else {return}
				
				assert(displayedProgress >= 0 && displayedProgress <= 1)
				guard abs(displayedProgress - (oldValue ?? -1)) > 0.01 else {return}
				
				setNeedsDisplay(bounds)
				dockTile.display()
			}
		}
		
		override func draw(_ dirtyRect: NSRect) {
			guard let displayedProgress = displayedProgress else {return}
			
			let finalSizedSkin: SizedSkin
			if let sizedSkin = sizedSkin,
				sizedSkin.skin.objectID == skin.objectID &&
				(abs(sizedSkin.originalSize.width  - dockTile.size.width)  < 0.5 &&
				 abs(sizedSkin.originalSize.height - dockTile.size.height) < 0.5)
			{
				finalSizedSkin = sizedSkin
			} else {
				finalSizedSkin = SizedSkin(skin: skin, size: dockTile.size, allowDistortion: false)
			}
			
			let myFrame = frame
			
			let drawnSize = finalSizedSkin.size
			let p = NSPoint(
				x: myFrame.origin.x + (myFrame.size.width  - drawnSize.width)/2,
				y: myFrame.origin.y + (myFrame.size.height - drawnSize.height)/2
			)
			
			let drawRect = NSRect(origin: p, size: drawnSize)
			finalSizedSkin.imageForProgress(displayedProgress).draw(
				in: drawRect,
				from: NSRect(origin: CGPoint.zero, size: drawnSize),
				operation: .sourceOver,
				fraction: 1,
				respectFlipped: true,
				hints: nil
			)
		}
		
		private class ProgressAnimation : NSAnimation {
			
			private let endIndicatorProgress: Float
			private let startIndicatorProgress: Float
			private weak var linkedView: DockTileIndicatorView?
			
			init(linkedView v: DockTileIndicatorView, startIndicatorProgress sip: Float, endIndicatorProgress eip: Float, duration: TimeInterval, animationCurve: NSAnimation.Curve) {
				linkedView = v
				endIndicatorProgress = eip
				startIndicatorProgress = sip
				super.init(duration: duration, animationCurve: animationCurve)
			}
			
			required init?(coder aDecoder: NSCoder) {
				fatalError("Cannot init this class with a coder")
			}
			
			override var currentProgress: NSAnimation.Progress {
				get {return super.currentProgress}
				set {
					super.currentProgress = newValue
					let p = currentProgress
					
					linkedView?.displayedProgress = startIndicatorProgress + (endIndicatorProgress - startIndicatorProgress)*p
				}
			}
			
		}
		
	}
	
}
