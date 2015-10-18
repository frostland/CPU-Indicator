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
				
				kUDK_MixedImageState: NSNumber(integer: Int(MixedImageState.UseSkinDefault.rawValue))
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
	
	lazy var applicationDocumentsDirectory: NSURL = {
		/* The directory the application uses to store the Core Data store file */
		let urls = NSFileManager.defaultManager().URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)
		let appSupportURL = urls.last!
		return appSupportURL.URLByAppendingPathComponent("fr.frostland.cpu-indicator")
	}()
	
	lazy var managedObjectModel: NSManagedObjectModel = {
		/* The managed object model for the application */
		let modelURL = NSBundle.mainBundle().URLForResource("Model", withExtension: "momd")!
		return NSManagedObjectModel(contentsOfURL: modelURL)!
	}()
	
	lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
		/* The persistent store coordinator for the application. This
		 * implementation creates and return a coordinator, having added the store
		 * for the application to it. (The directory for the store is created, if
		 * necessary.) */
		let fileManager = NSFileManager.defaultManager()
		let defaultError = NSError(domain: kAppErrorDomainName, code: kErr_CoreDataSetup, userInfo: [NSLocalizedDescriptionKey: "There was an error creating or loading the application’s saved data."])
		
		do {
			/* Make sure the application files directory is there */
			do {
				let properties = try self.applicationDocumentsDirectory.resourceValuesForKeys([NSURLIsDirectoryKey])
				if !properties[NSURLIsDirectoryKey]!.boolValue {
					throw NSError(domain: kAppErrorDomainName, code: kErr_CoreDataSetup, userInfo: [NSLocalizedDescriptionKey: "Expected a folder to store application data, found a file \(self.applicationDocumentsDirectory.path)."])
				}
			} catch  {
				if (error as NSError).code == NSFileReadNoSuchFileError {
					guard let _ = try? fileManager.createDirectoryAtPath(self.applicationDocumentsDirectory.path!, withIntermediateDirectories: true, attributes: nil) else {
						throw defaultError
					}
				}
			}
			
			/* Create the coordinator and store */
			let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
			let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("CPUIndicator.storedata")
			try coordinator.addPersistentStoreWithType(NSXMLStoreType, configuration: nil, URL: url, options: nil)
			return coordinator
		} catch {
			NSApplication.sharedApplication().presentError(error as NSError)
			abort()
		}
	}()
	
	lazy var mainManagedObjectContext: NSManagedObjectContext = {
		/* Returns the managed object context for the application (which is
		 * already bound to the persistent store coordinator for the application.) */
		let coordinator = self.persistentStoreCoordinator
		var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
		managedObjectContext.persistentStoreCoordinator = coordinator
		return managedObjectContext
	}()
	
	func applicationWillFinishLaunching(notification: NSNotification) {
		/* Show the Dock icon if needed */
		if NSUserDefaults.standardUserDefaults().boolForKey(kUDK_ShowDockIcon) {
			var psn = ProcessSerialNumber(highLongOfPSN: UInt32(0), lowLongOfPSN: UInt32(kCurrentProcess))
			let returnCode = TransformProcessType(&psn, ProcessApplicationTransformState(kProcessTransformToForegroundApplication))
			dockIconShown = (returnCode == 0)
		}
		
		/* To create a skin. */
		#if false
		if #available(OSX 10.11, *) {
			let openPanel = NSOpenPanel()
			openPanel.canChooseDirectories = true
			openPanel.canChooseFiles = false
			openPanel.beginWithCompletionHandler { r in
				guard let imagesBaseURL = openPanel.URL else {
					return
				}
				
				var images = [(NSImage, Int32, Int32)]()
				var maxWidth = Int32(0), maxHeight = Int32(0)
				let imagesRelativePaths = ["babe0.png", "babe1.png", "babe2.png", "babe3.png", "babe4.png"]
				for relativePath in imagesRelativePaths {
					let url = NSURL(fileURLWithPath: relativePath, relativeToURL: imagesBaseURL)
					guard let image = NSImage(contentsOfURL: url) else {
						print("*** Warning: Cannot load image at url \(url). Skipping.")
						continue
					}
					let w = Int32(ceil(image.size.width)), h = Int32(ceil(image.size.height))
					if maxWidth  < w {maxWidth = w}
					if maxHeight < h {maxHeight = h}
					images.append((image, w, h))
				}
				self.mainManagedObjectContext.performBlockAndWait {
					let skin = NSEntityDescription.insertNewObjectForEntityForName("Skin", inManagedObjectContext: self.mainManagedObjectContext) as! Skin
					skin.name = "Hot Babe"
					skin.selected = true
					skin.sortPosition = 0
					skin.width = maxWidth
					skin.height = maxHeight
					skin.source = "Bruno Bellamy"
					skin.uid = "fr.frostland.cpu-indicator.babes"
					skin.mixedImageState = MixedImageState.AllowTransitions
					let mutableFrames = skin.mutableOrderedSetValueForKey("frames")
					for (image, w, h) in images {
						let frame = NSEntityDescription.insertNewObjectForEntityForName("SkinFrame", inManagedObjectContext: self.mainManagedObjectContext) as! SkinFrame
						frame.width = w
						frame.height = h
						frame.xPos = (maxWidth  - w)/2
						frame.yPos = (maxHeight - h)/2
						frame.imageData = image.TIFFRepresentationUsingCompression(NSTIFFCompression.LZW, factor: 0)
						mutableFrames.addObject(frame)
					}
					do {
						try self.mainManagedObjectContext.save()
					} catch {
						print("*** Warning: Cannot save managed object context, got error \(error). Rollbacking.")
						self.mainManagedObjectContext.rollback()
					}
				}
			}
		}
		#endif
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
