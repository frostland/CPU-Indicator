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
/*			[defaultValues setValue:@YES forKey:FL_UDK_FIRST_RUN];
			
			[defaultValues setValue:[NSMutableDictionary dictionary] forKey:FL_UDK_PREFS_PANES_SIZES];
			[defaultValues setValue:@"Skins"                         forKey:FL_UDK_LAST_SELECTED_PREF_ID];
			
			[defaultValues setValue:@YES                              forKey:FL_UDK_SHOW_WINDOW];
			[defaultValues setValue:@(FLWindowLevelMenuIndexAboveAll) forKey:FL_UDK_WINDOW_LEVEL];
			[defaultValues setValue:@1.f                              forKey:FL_UDK_WINDOW_TRANSPARENCY];
			[defaultValues setValue:@NO                               forKey:FL_UDK_DISALLOW_SHADOW];
			[defaultValues setValue:@YES                              forKey:FL_UDK_ALLOW_WINDOW_DRAG_N_DROP];
			[defaultValues setValue:@NO                               forKey:FL_UDK_IGNORE_MOUSE_CLICKS];
			
			[defaultValues setValue:@NO                  forKey:FL_UDK_SHOW_MENU];
			[defaultValues setValue:@(FLMenuModeTagText) forKey:FL_UDK_MENU_MODE];
			[defaultValues setValue:@NO                  forKey:FL_UDK_ONE_MENU_PER_CPU];
			
			[defaultValues setValue:@YES forKey:FL_UDK_SHOW_DOCK];
			[defaultValues setValue:@NO  forKey:FL_UDK_SHOW_INDICATOR_IN_DOCK];
			
			[defaultValues setValue:@0                           forKey:FL_UDK_SELECTED_SKIN];
			[defaultValues setValue:@(FLMixedImageStateFromSkin) forKey:FL_UDK_MIXED_IMAGE_STATE];
			[defaultValues setValue:@1.f                         forKey:FL_UDK_SKIN_X_SCALE];
			[defaultValues setValue:@1.f                         forKey:FL_UDK_SKIN_Y_SCALE];*/
			let defaults = [
				kUDK_FirstRun: true,
				
				kUDK_PrefsPanesSizes: [:],
				kUDK_LatestSelectedPrefPaneId: "skins",
				
				"FLShowDock": false
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
