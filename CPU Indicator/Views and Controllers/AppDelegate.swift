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
	
	override class func initialize() {
		if self === AppDelegate.self {
/*			[defaultValues setValue:@0                           forKey:FL_UDK_SELECTED_SKIN];
			[defaultValues setValue:@(FLMixedImageStateFromSkin) forKey:FL_UDK_MIXED_IMAGE_STATE];
			[defaultValues setValue:@1.f                         forKey:FL_UDK_SKIN_X_SCALE];
			[defaultValues setValue:@1.f                         forKey:FL_UDK_SKIN_Y_SCALE];*/
			let defaults = [
				kUDK_FirstRun: true,
				
				kUDK_PrefsPanesSizes: [:],
				kUDK_LatestSelectedPrefPaneId: "skins",
				
				kUDK_ShowWindowIndicator: true,
				kUDK_WindowIndicatorLevel: NSNumber(integer: WindowIndicatorLevel.AboveAll.rawValue),
				kUDK_WindowIndicatorSize: 1.0,
				kUDK_WindowIndicatorOpacity: 1.0,
				kUDK_WindowIndicatorDisableShadow: false,
				kUDK_WindowIndicatorLocked: false,
				kUDK_WindowIndicatorClickless: false,
				kUDK_WindowIndicatorDecreaseOpacityOnHover: false,
				
				kUDK_ShowMenuIndicator: false,
				kUDK_MenuIndicatorMode: NSNumber(integer: MenuIndicatorMode.Text.rawValue),
				kUDK_MenuIndicatorOnePerCPU: false,
				
				kUDK_ShowDockIcon: true,
				kUDK_DockIconIsCPUIndicator: false
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
	
	func applicationDidFinishLaunching(aNotification: NSNotification) {
		introWindowController = Storyboards.Main.instantiateIntroWindowController()
		introWindowController!.showWindow(self)
	}
	
	func applicationWillTerminate(aNotification: NSNotification) {
		// Insert code here to tear down your application
	}
	
	func closeIntroWindow() {
		introWindowController?.close()
		introWindowController = nil /* No need to keep a reference to a class we'll never use again. */
	}

}
