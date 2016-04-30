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
	
	dynamic var selectedSkinObjectID: NSManagedObjectID! {
		didSet {
			self.mainManagedObjectContext.performBlock {
				if let uid = ((try? self.mainManagedObjectContext.existingObjectWithID(self.selectedSkinObjectID)) as? Skin)?.uid {
					NSUserDefaults.standardUserDefaults().setObject(uid, forKey: kUDK_SelectedSkinUID)
				}
			}
		}
	}
	
	private var introWindowController: NSWindowController?
	/* The preferences window controller keeps a reference to itself while it
	 * needs itself. */
	private weak var preferencesWindowController: PreferencesWindowController?
	
	private(set) var mainWindowController: IndicatorWindowController!
	@IBOutlet var menuBarController: IndicatorMenuBarController!
	@IBOutlet var dockIndicatorController: IndicatorDockController!
	
	private var dockIconShown = false
	private var appDidBecomeActive = false
	
	override class func initialize() {
		if self === AppDelegate.self {
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
				
				kUDK_SelectedSkinUID: "fr.frostland.cpu-indicator.built-in",
				kUDK_MixedImageState: NSNumber(integer: Int(MixedImageState.UseSkinDefault.rawValue))
			]
			NSUserDefaults.standardUserDefaults().registerDefaults(defaults)
			
			let skinPreviewTransformer = SkinToSizedSkinTransformer(destSize: CGSizeMake(141, 141), allowDistortion: false)
			NSValueTransformer.setValueTransformer(skinPreviewTransformer, forName: "SkinPreviewTransformer")
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
			try coordinator.addPersistentStoreWithType(NSXMLStoreType, configuration: nil, URL: url, options: [
				NSMigratePersistentStoresAutomaticallyOption: true,
				NSInferMappingModelAutomaticallyOption: true
			])
			return coordinator
		} catch {
			NSApplication.sharedApplication().presentError(error as NSError)
			exit(0)
		}
	}()
	
	/** The main managed object context is on the main queue. */
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
		
		/* Let's initialize and start the shared CPU Usage Getter. */
		let _ = CPUUsageGetter.sharedCPUUsageGetter
		
		/* Let's check the selected skin is indeed in the database. */
		self.mainManagedObjectContext.performBlockAndWait {
			do {
				let selectedSkinUID = NSUserDefaults.standardUserDefaults().stringForKey(kUDK_SelectedSkinUID)!
				let fRequest = NSFetchRequest(entityName: "Skin")
				fRequest.predicate = NSPredicate(format: "%K == %@", "uid", selectedSkinUID)
				fRequest.sortDescriptors = [NSSortDescriptor(key: "sortPosition", ascending: true)]
				let results = try self.mainManagedObjectContext.executeFetchRequest(fRequest) as! [Skin]
				if results.count > 1 {print("*** Warning: Got more than one skin for UID \(selectedSkinUID). Taking the first one.")}
				if results.count > 0 {
					self.selectedSkinObjectID = results[0].objectID
				} else {
					let fRequest = NSFetchRequest(entityName: "Skin")
					fRequest.fetchLimit = 1
					fRequest.sortDescriptors = [NSSortDescriptor(key: "sortPosition", ascending: true)]
					let results = try self.mainManagedObjectContext.executeFetchRequest(fRequest) as! [Skin]
					if results.count > 0 {
						/* The UID of the selected skin from the prefs was not found.
						 * we take the first skin and make it the selected one. */
						NSUserDefaults.standardUserDefaults().setObject(results[0].uid, forKey: kUDK_SelectedSkinUID)
						self.selectedSkinObjectID = results[0].objectID
					} else {
						/* There are no skins in the db. We create the default one! */
						let images = [
							NSImage(named: "green.png")!,
							NSImage(named: "orange.png")!,
							NSImage(named: "red.png")!
						]
						var maxWidth = Int32(0), maxHeight = Int32(0)
						let imagesInfo = self.imagesInfoFromImages(images, maxWidth: &maxWidth, maxHeight: &maxHeight)
						let skin = NSEntityDescription.insertNewObjectForEntityForName("Skin", inManagedObjectContext: self.mainManagedObjectContext) as! Skin
						skin.name = "Default"
						skin.sortPosition = 0
						skin.isBuiltIn = true
						skin.width = maxWidth
						skin.height = maxHeight
						skin.source = "Frost Land"
						skin.uid = "fr.frostland.cpu-indicator.built-in"
						skin.mixedImageState = MixedImageState.AllowTransitions
						self.importSkinFramesFromImagesInfo(imagesInfo, inSkin: skin)
						try self.mainManagedObjectContext.save()
						self.selectedSkinObjectID = skin.objectID
					}
				}
			} catch {
				self.mainManagedObjectContext.rollback()
				NSApplication.sharedApplication().presentError(error as NSError)
				exit(0)
			}
		}
		
		menuBarController.applicationWillFinishLaunching()
		dockIndicatorController.applicationWillFinishLaunching()
		
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
				
				var images = [NSImage]()
				let imagesRelativePaths = ["babe0.png", "babe1.png", "babe2.png", "babe3.png", "babe4.png"]
				for relativePath in imagesRelativePaths {
					let url = NSURL(fileURLWithPath: relativePath, relativeToURL: imagesBaseURL)
					if let image = NSImage(contentsOfURL: url) {images.append(image)}
					else                                       {print("*** Warning: Cannot load image at url \(url). Skipping.")}
				}
				var maxWidth = Int32(0), maxHeight = Int32(0)
				let imagesInfo = self.imagesInfoFromImages(images, maxWidth: &maxWidth, maxHeight: &maxHeight)
				self.mainManagedObjectContext.performBlockAndWait {
					let skin = NSEntityDescription.insertNewObjectForEntityForName("Skin", inManagedObjectContext: self.mainManagedObjectContext) as! Skin
					skin.name = "Hot Babe"
					skin.sortPosition = 0
					skin.width = maxWidth
					skin.height = maxHeight
					skin.source = "Bruno Bellamy"
					skin.uid = "fr.frostland.cpu-indicator.hot-babe"
					skin.mixedImageState = MixedImageState.AllowTransitions
					self.importSkinFramesFromImagesInfo(imagesInfo, inSkin: skin)
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
	
	private func imagesInfoFromImages(images: [NSImage], inout maxWidth: Int32, inout maxHeight: Int32) -> [(NSImage, Int32, Int32, Int32, Int32)] {
		var imagesInfo = [(NSImage, Int32, Int32, Int32, Int32)]()
		for image in images {
			let w = Int32(ceil(image.size.width)), h = Int32(ceil(image.size.height))
			if maxWidth  < w {maxWidth = w}
			if maxHeight < h {maxHeight = h}
			imagesInfo.append((image, -1, -1, w, h))
		}
		return imagesInfo
	}
	
	/* Expects to be called on the given context's queue.
	 * The images array contains a quintuplet of the image, and in that order,
	 * the x, y position of the image and the width and height.
	 * These values can individually be negative or zero, in which case the value
	 * is inferred from the skin width and height. */
	private func importSkinFramesFromImagesInfo(images: [(NSImage, Int32, Int32, Int32, Int32)], inSkin skin: Skin) {
		let mutableFrames = skin.mutableOrderedSetValueForKey("frames")
		for (image, x, y, w, h) in images {
			let frame = NSEntityDescription.insertNewObjectForEntityForName("SkinFrame", inManagedObjectContext: self.mainManagedObjectContext) as! SkinFrame
			frame.width  = (w > 0 ? w : skin.width)
			frame.height = (h > 0 ? h : skin.height)
			frame.xPos = (x > 0 ? x : (skin.width  - frame.width)/2)
			frame.yPos = (y > 0 ? y : (skin.height - frame.height)/2)
			frame.imageData = image.TIFFRepresentationUsingCompression(NSTIFFCompression.LZW, factor: 0)
			mutableFrames.addObject(frame)
		}
	}

}
