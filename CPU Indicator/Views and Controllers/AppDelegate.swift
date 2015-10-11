/*
 * AppDelegate.swift
 * CPU Indicator
 *
 * Created by François Lamboley on 13/06/15.
 * Copyright © 2015 Frost Land. All rights reserved.
 */

import Cocoa



@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	static private(set) var sharedAppDelegate: AppDelegate!
	
	private var introWindowController: NSWindowController?
	/* The preferences window controller keeps a reference to itself while it
	 * needs itself. */
	private weak var preferencesWindowController: PreferencesWindowController?
	
	private var mainWindowController: IndicatorWindowController!
	@IBOutlet private var menuBarController: IndicatorMenuBarController!
	
	private var dockIconShown = false
	private var appDidBecomeActive = false
	
	override class func initialize() {
		if self === AppDelegate.self {
/*			[defaultValues setValue:@0 forKey:FL_UDK_SELECTED_SKIN];*/
			let defaults = [
				kUDK_FirstRun: true,
				
				kUDK_PrefsPanesSizes: [:],
				kUDK_LatestSelectedPrefPaneId: "skins",
				
				kUDK_ShowWindowIndicator: true,
				kUDK_WindowIndicatorLevel: NSNumber(integer: WindowIndicatorLevel.AboveAll.rawValue),
				kUDK_WindowIndicatorScale: 1.0,
				kUDK_WindowIndicatorOpacity: 1.0,
				kUDK_WindowIndicatorDisableShadow: false,
				kUDK_WindowIndicatorLocked: false,
				kUDK_WindowIndicatorClickless: false,
				kUDK_WindowIndicatorDecreaseOpacityOnHover: false,
				
				kUDK_ShowMenuIndicator: false,
				kUDK_MenuIndicatorMode: NSNumber(integer: MenuIndicatorMode.Text.rawValue),
				kUDK_MenuIndicatorOnePerCPU: false,
				
				kUDK_ShowDockIcon: true,
				kUDK_DockIconIsCPUIndicator: false,
				
				kUDK_MixedImageState: NSNumber(integer: MixedImageState.UseSkinDefault.rawValue)
			]
			NSUserDefaults.standardUserDefaults().registerDefaults(defaults)
		}
	}
	
	override init() {
		super.init()
		
		if self.dynamicType.sharedAppDelegate == nil {
			self.dynamicType.sharedAppDelegate = self
		}
	}
	
	func applicationWillFinishLaunching(notification: NSNotification) {
		if NSUserDefaults.standardUserDefaults().boolForKey(kUDK_ShowDockIcon) {
			var psn = ProcessSerialNumber(highLongOfPSN: UInt32(0), lowLongOfPSN: UInt32(kCurrentProcess))
			let returnCode = TransformProcessType(&psn, ProcessApplicationTransformState(kProcessTransformToForegroundApplication))
			dockIconShown = (returnCode == 0)
		}
	}
	
	func applicationDidFinishLaunching(aNotification: NSNotification) {
		let ud = NSUserDefaults.standardUserDefaults()
		let firstRun = ud.boolForKey(kUDK_FirstRun)
		
		mainWindowController = Storyboards.Main.instantiateIndicatorWindowController()
		
		if firstRun {
			ud.setBool(false, forKey: kUDK_FirstRun)
			
			introWindowController = Storyboards.Main.instantiateIntroWindowController()
			introWindowController?.window?.level = Int(CGWindowLevelForKey(CGWindowLevelKey.StatusWindowLevelKey))
			introWindowController!.showWindow(self)
		}
	}
	
	func applicationDidBecomeActive(notification: NSNotification) {
		if appDidBecomeActive && !dockIconShown {showPrefs(nil)}
		appDidBecomeActive = true
	}
	
	func applicationWillTerminate(aNotification: NSNotification) {
		// Insert code here to tear down your application
	}
	
	@IBAction func showPrefs(sender: AnyObject?) {
		let controller: PreferencesWindowController
		if let pc = preferencesWindowController {controller = pc}
		else                                    {controller = Storyboards.Main.instantiatePreferencesWindowController()}
		preferencesWindowController = controller
		controller.showWindow(sender)
	}
	
	func closeIntroWindow() {
		introWindowController?.close()
		introWindowController = nil /* No need to keep a reference to a class we'll never use again. */
	}

}
