/*
 * IndicatorWindowController.swift
 * CPU Indicator
 *
 * Created by François Lamboley on 9/23/15.
 * Copyright © 2015 Frost Land. All rights reserved.
 */

import Cocoa



private extension NSWindow.FrameAutosaveName {
	
	static let indicatorWindow = NSWindow.FrameAutosaveName(rawValue: "IndicatorWindow")
	
}


class IndicatorWindowController: NSWindowController, CPUUsageObserver {
	
	private var skinView: SkinView! {
		return (contentViewController as? IndicatorWindowContentViewController)?.skinView
	}
	
	private var observingUDC = false
	private let observedUDCKeys = [
		"values.\(kUDK_ShowWindowIndicator)",
		"values.\(kUDK_WindowIndicatorLevel)", "values.\(kUDK_WindowIndicatorOpacity)",
		"values.\(kUDK_WindowIndicatorClickless)", "values.\(kUDK_WindowIndicatorLocked)",
		"values.\(kUDK_WindowIndicatorScale)", "values.\(kUDK_WindowIndicatorDisableShadow)",
		"values.\(kUDK_MixedImageState)"
	]
	
	deinit {
		if observingUDC {
			CPUUsageGetter.sharedCPUUsageGetter.removeObserverForKnownUsageModification(self)
			AppDelegate.sharedAppDelegate.removeObserver(self, forKeyPath: "selectedSkinObjectID", context: nil)
			for keyPath in observedUDCKeys {
				NSUserDefaultsController.shared.removeObserver(self, forKeyPath: keyPath)
			}
		}
	}
	
	override func windowDidLoad() {
		window?.isOpaque = false
		window?.isMovableByWindowBackground = true
		window?.backgroundColor = NSColor.clear
		
		windowFrameAutosaveName = .indicatorWindow
		
		super.windowDidLoad()
		
		let udc = NSUserDefaultsController.shared
		for keyPath in observedUDCKeys {
			udc.addObserver(self, forKeyPath: keyPath, options: [.initial], context: nil)
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
			case kUDK_ShowWindowIndicator:
				if ud.bool(forKey: kUDK_FirstRun) {
					if let window = window {
						let screenRect = window.screen?.visibleFrame ?? CGRect(x: 0, y: 0, width: 640, height: 480)
						var f = window.frame
						f.origin.x = screenRect.origin.x + screenRect.size.width  - f.size.width
						f.origin.y = screenRect.origin.y + screenRect.size.height - f.size.height
						window.setFrame(f, display: true, animate: false)
					}
				}
				if ud.bool(forKey: kUDK_ShowWindowIndicator) {showWindow(self)}
				else                                         {close()}
				
			case kUDK_WindowIndicatorLevel:
				switch WindowIndicatorLevel(rawValue: ud.integer(forKey: kUDK_WindowIndicatorLevel)) ?? WindowIndicatorLevel.aboveAll {
				case .behindAll:
					ud.set(true, forKey: kUDK_WindowIndicatorClickless)
					ud.set(true, forKey: kUDK_WindowIndicatorLocked)
					window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.desktopWindow)))
					window?.collectionBehavior = [NSWindow.CollectionBehavior.canJoinAllSpaces, NSWindow.CollectionBehavior.transient]
					
				case .normal:
					window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.normalWindow))) /* Probably same as .normal */
					window?.collectionBehavior = [NSWindow.CollectionBehavior.canJoinAllSpaces, NSWindow.CollectionBehavior.managed]
					
				case .aboveAll:
					window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.statusWindow)))
					window?.collectionBehavior = [NSWindow.CollectionBehavior.canJoinAllSpaces, NSWindow.CollectionBehavior.stationary]
				}
				
			case kUDK_WindowIndicatorOpacity:
				window?.alphaValue = CGFloat(ud.float(forKey: kUDK_WindowIndicatorOpacity))
				
			case kUDK_WindowIndicatorClickless:
				window?.ignoresMouseEvents = ud.bool(forKey: kUDK_WindowIndicatorClickless)
				
			case kUDK_WindowIndicatorLocked:
				window?.isMovable = !ud.bool(forKey: kUDK_WindowIndicatorLocked)
				
			case kUDK_WindowIndicatorScale:
				updateSkinAndScale()
				
			case kUDK_WindowIndicatorDisableShadow:
				window?.hasShadow = !ud.bool(forKey: kUDK_WindowIndicatorDisableShadow)
				
			case kUDK_WindowIndicatorDecreaseOpacityOnHover:
				(/*TODO*/)
				
			case kUDK_MixedImageState:
				skinView.defaultMixedImageState = MixedImageState(rawValue: Int16(ud.integer(forKey: kUDK_MixedImageState))) ?? .useSkinDefault
				
			default:
				super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
			}
		} else if kp == "selectedSkinObjectID" && object as? AppDelegate === AppDelegate.sharedAppDelegate {
			updateSkinAndScale()
		} else {
			super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
		}
	}
	
	@IBAction func moveWindowToTopLeft(_ sender: AnyObject!) {
		guard let screenRect = window?.screen?.frame, var f = window?.frame else {
			return
		}
		f.origin.x = screenRect.origin.x
		f.origin.y = screenRect.origin.y + screenRect.size.height - f.size.height
		window?.setFrame(f, display: true, animate: true)
	}
	
	@IBAction func moveWindowToPseudoTopLeft(_ sender: AnyObject!) {
		guard let screenRect = window?.screen?.visibleFrame, var f = window?.frame else {
			return
		}
		f.origin.x = screenRect.origin.x
		f.origin.y = screenRect.origin.y + screenRect.size.height - f.size.height
		window?.setFrame(f, display: true, animate: true)
	}
	
	@IBAction func moveWindowToTopRight(_ sender: AnyObject!) {
		guard let screenRect = window?.screen?.frame, var f = window?.frame else {
			return
		}
		f.origin.x = screenRect.origin.x + screenRect.size.width - f.size.width
		f.origin.y = screenRect.origin.y + screenRect.size.height - f.size.height
		window?.setFrame(f, display: true, animate: true)
	}
	
	@IBAction func moveWindowToPseudoTopRight(_ sender: AnyObject!) {
		guard let screenRect = window?.screen?.visibleFrame, var f = window?.frame else {
			return
		}
		f.origin.x = screenRect.origin.x + screenRect.size.width - f.size.width
		f.origin.y = screenRect.origin.y + screenRect.size.height - f.size.height
		window?.setFrame(f, display: true, animate: true)
	}
	
	@IBAction func moveWindowToBottomLeft(_ sender: AnyObject!) {
		guard let screenRect = window?.screen?.frame, var f = window?.frame else {
			return
		}
		f.origin.x = screenRect.origin.x
		f.origin.y = screenRect.origin.y
		window?.setFrame(f, display: true, animate: true)
	}
	
	@IBAction func moveWindowToPseudoBottomLeft(_ sender: AnyObject!) {
		guard let screenRect = window?.screen?.visibleFrame, var f = window?.frame else {
			return
		}
		f.origin.x = screenRect.origin.x
		f.origin.y = screenRect.origin.y
		window?.setFrame(f, display: true, animate: true)
	}
	
	@IBAction func moveWindowToBottomRight(_ sender: AnyObject!) {
		guard let screenRect = window?.screen?.frame, var f = window?.frame else {
			return
		}
		f.origin.x = screenRect.origin.x + screenRect.size.width - f.size.width
		f.origin.y = screenRect.origin.y
		window?.setFrame(f, display: true, animate: true)
	}
	
	@IBAction func moveWindowToPseudoBottomRight(_ sender: AnyObject!) {
		guard let screenRect = window?.screen?.visibleFrame, var f = window?.frame else {
			return
		}
		f.origin.x = screenRect.origin.x + screenRect.size.width - f.size.width
		f.origin.y = screenRect.origin.y
		window?.setFrame(f, display: true, animate: true)
	}
	
	/* **************************
	   MARK: - CPU Usage Observer
	   ************************** */
	
	func cpuUsageChanged(getter: CPUUsageGetter) {
		skinView.progress = Float(getter.globalCPUUsage)
	}
	
	/* ***************
	   MARK: - Private
	   *************** */
	
	private func updateSkinAndScale() {
		let appDelegate = AppDelegate.sharedAppDelegate
		let context = appDelegate?.mainManagedObjectContext
		let scale = CGFloat(UserDefaults.standard.double(forKey: kUDK_WindowIndicatorScale))
		
		var sizedSkinO: SizedSkin?
		context?.performAndWait {
			guard let skin = (try? context?.existingObject(with: (appDelegate?.selectedSkinObjectID)!)) as? Skin else {
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
		skinView.sizedSkin = sizedSkin
		window?.setContentSize(sizedSkin.size)
		window?.invalidateShadow()
	}
	
}
