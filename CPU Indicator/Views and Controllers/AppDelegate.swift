/*
 * AppDelegate.swift
 * CPU Indicator
 *
 * Created by François Lamboley on 13/06/15.
 * Copyright © 2015 Frost Land. All rights reserved.
 */

import Cocoa

import KVObserver



private extension NSStoryboard.Name {
	
	static let main = "Main"
	
}


private extension NSStoryboard.SceneIdentifier {
	
	static let introWindowController = "IntroWindowController"
	static let indicatorWindowController = "IndicatorWindowController"
	static let preferencesWindowController = "PreferencesWindowController"
	
}


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	static private(set) var sharedAppDelegate: AppDelegate!
	
	@objc dynamic var selectedSkinObjectID: NSManagedObjectID! {
		didSet {
			mainManagedObjectContext.perform {
				if let uid = ((try? self.mainManagedObjectContext.existingObject(with: self.selectedSkinObjectID)) as? Skin)?.uid {
					UserDefaults.standard.set(uid, forKey: kUDK_SelectedSkinUID)
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
	
	override init() {
		super.init()
		
		let defaults: [String: Any] = [
			kUDK_FirstRun: true,
			
			kUDK_PrefsPanesSizes: [:],
			kUDK_LatestSelectedPrefPaneId: "skins",
			
			kUDK_ShowWindowIndicator: true,
			kUDK_WindowIndicatorLevel: NSNumber(value: WindowIndicatorLevel.aboveAll.rawValue),
			kUDK_WindowIndicatorScale: 1.0,
			kUDK_WindowIndicatorOpacity: 1.0,
			kUDK_WindowIndicatorDisableShadow: false,
			kUDK_WindowIndicatorLocked: false,
			kUDK_WindowIndicatorClickless: false,
			kUDK_WindowIndicatorDecreaseOpacityOnHover: false,
			
			kUDK_ShowMenuIndicator: false,
			kUDK_MenuIndicatorMode: NSNumber(value: MenuIndicatorMode.text.rawValue),
			kUDK_MenuIndicatorOnePerCPU: false,
			
			kUDK_ShowDockIcon: true,
			kUDK_DockIconIsCPUIndicator: false,
			
			kUDK_SelectedSkinUID: "fr.frostland.cpu-indicator.built-in",
			kUDK_MixedImageState: NSNumber(value: Int(MixedImageState.useSkinDefault.rawValue))
		]
		UserDefaults.standard.register(defaults: defaults)
		
		let skinPreviewTransformer = SkinToSizedSkinTransformer(destSize: CGSize(width: 141, height: 141), allowDistortion: false)
		ValueTransformer.setValueTransformer(skinPreviewTransformer, forName: NSValueTransformerName(rawValue: "SkinPreviewTransformer"))
		
		if type(of: self).sharedAppDelegate == nil {
			type(of: self).sharedAppDelegate = self
		}
	}
	
	lazy var applicationDocumentsDirectory: URL = {
		/* The directory the application uses to store the Core Data store file */
		let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
		let appSupportURL = urls.last!
		return appSupportURL.appendingPathComponent("fr.frostland.cpu-indicator")
	}()
	
	lazy var managedObjectModel: NSManagedObjectModel = {
		/* The managed object model for the application */
		let modelURL = Bundle.main.url(forResource: "Model", withExtension: "momd")!
		return NSManagedObjectModel(contentsOf: modelURL)!
	}()
	
	lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
		/* The persistent store coordinator for the application. This
		 * implementation creates and return a coordinator, having added the store
		 * for the application to it. (The directory for the store is created, if
		 * necessary.) */
		let fileManager = FileManager.default
		let defaultError = NSError(domain: kAppErrorDomainName, code: kErr_CoreDataSetup, userInfo: [NSLocalizedDescriptionKey: "There was an error creating or loading the application’s saved data."])
		
		do {
			/* Make sure the application files directory is there */
			do {
				let properties = try self.applicationDocumentsDirectory.resourceValues(forKeys: [URLResourceKey.isDirectoryKey])
				if !properties.isDirectory! {
					throw NSError(domain: kAppErrorDomainName, code: kErr_CoreDataSetup, userInfo: [NSLocalizedDescriptionKey: "Expected a folder to store application data, found a file \(self.applicationDocumentsDirectory.path)."])
				}
			} catch  {
				if (error as NSError).code == NSFileReadNoSuchFileError {
					guard let _ = try? fileManager.createDirectory(atPath: self.applicationDocumentsDirectory.path, withIntermediateDirectories: true, attributes: nil) else {
						throw defaultError
					}
				}
			}
			
			/* Create the coordinator and store */
			let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
			let url = self.applicationDocumentsDirectory.appendingPathComponent("CPUIndicator.storedata")
			try coordinator.addPersistentStore(ofType: NSXMLStoreType, configurationName: nil, at: url, options: [
				NSMigratePersistentStoresAutomaticallyOption: true,
				NSInferMappingModelAutomaticallyOption: true
			])
			return coordinator
		} catch {
			NSApplication.shared.presentError(error as NSError)
			exit(0)
		}
	}()
	
	/** The main managed object context is on the main queue. */
	lazy var mainManagedObjectContext: NSManagedObjectContext = {
		/* Returns the managed object context for the application (which is
		 * already bound to the persistent store coordinator for the application.) */
		let coordinator = self.persistentStoreCoordinator
		var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		managedObjectContext.persistentStoreCoordinator = coordinator
		return managedObjectContext
	}()
	
	func applicationWillFinishLaunching(_ notification: Notification) {
		/* Show the Dock icon if needed */
		if UserDefaults.standard.bool(forKey: kUDK_ShowDockIcon) {
			var psn = ProcessSerialNumber(highLongOfPSN: UInt32(0), lowLongOfPSN: UInt32(kCurrentProcess))
			let returnCode = TransformProcessType(&psn, ProcessApplicationTransformState(kProcessTransformToForegroundApplication))
			dockIconShown = (returnCode == 0)
		}
		
		/* Let's initialize and start the shared CPU Usage Getter. */
		_ = CPUUsageGetter.sharedCPUUsageGetter
		
		/* Let's check the selected skin is indeed in the database. */
		mainManagedObjectContext.performAndWait {
			do {
				let selectedSkinUID = UserDefaults.standard.string(forKey: kUDK_SelectedSkinUID)!
				let fRequest: NSFetchRequest<Skin> = Skin.fetchRequest()
				fRequest.predicate = NSPredicate(format: "%K == %@", "uid", selectedSkinUID)
				fRequest.sortDescriptors = [NSSortDescriptor(key: "sortPosition", ascending: true)]
				let results = try self.mainManagedObjectContext.fetch(fRequest)
				if results.count > 1 {print("*** Warning: Got more than one skin for UID \(selectedSkinUID). Taking the first one.")}
				if let result = results.first {
					self.selectedSkinObjectID = result.objectID
				} else {
					let fRequest: NSFetchRequest<Skin> = Skin.fetchRequest()
					fRequest.fetchLimit = 1
					fRequest.sortDescriptors = [NSSortDescriptor(key: "sortPosition", ascending: true)]
					let results = try self.mainManagedObjectContext.fetch(fRequest)
					if let result = results.first {
						/* The UID of the selected skin from the prefs was not found.
						 * we take the first skin and make it the selected one. */
						UserDefaults.standard.set(result.uid, forKey: kUDK_SelectedSkinUID)
						self.selectedSkinObjectID = result.objectID
					} else {
						/* There are no skins in the db. We create the default one! */
						let images = [#imageLiteral(resourceName: "green"), #imageLiteral(resourceName: "orange"), #imageLiteral(resourceName: "red")]
						var maxWidth = Int32(0), maxHeight = Int32(0)
						let imagesInfo = self.imagesInfoFromImages(images, maxWidth: &maxWidth, maxHeight: &maxHeight)
						let skin = NSEntityDescription.insertNewObject(forEntityName: "Skin", into: self.mainManagedObjectContext) as! Skin
						skin.name = "Default"
						skin.sortPosition = 0
						skin.width = maxWidth
						skin.height = maxHeight
						skin.source = "Frost Land"
						skin.uid = "fr.frostland.cpu-indicator.built-in"
						skin.mixedImageState = MixedImageState.allowTransitions
						self.importSkinFramesFromImagesInfo(imagesInfo, inSkin: skin)
						try self.mainManagedObjectContext.save()
						self.selectedSkinObjectID = skin.objectID
					}
				}
			} catch {
				self.mainManagedObjectContext.rollback()
				NSApplication.shared.presentError(error as NSError)
				exit(0)
			}
		}
		
		/* Adding observer of "Window Locked" user defaults to set clickless to
		 * false if locked is false. Ne need to keep a reference to the observing
		 * Id as we unobserve all in terminate and don’t need more fine grained
		 * control. */
		_ = kvObserver.observe(object: NSUserDefaultsController.shared, keyPath: "values.\(kUDK_WindowIndicatorLocked)", kvoOptions: .initial, dispatchType: .directOrAsyncOnMainQueue, handler: { _ in
			let ud = UserDefaults.standard
			if !ud.bool(forKey: kUDK_WindowIndicatorLocked) {ud.set(false, forKey: kUDK_WindowIndicatorClickless)}
		})
		
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
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		let ud = UserDefaults.standard
		let firstRun = ud.bool(forKey: kUDK_FirstRun)
		
		mainWindowController = (NSStoryboard(name: .main, bundle: nil).instantiateController(withIdentifier: .indicatorWindowController) as! IndicatorWindowController)
		
		if firstRun {
			ud.set(false, forKey: kUDK_FirstRun)
			
			introWindowController = (NSStoryboard(name: .main, bundle: nil).instantiateController(withIdentifier: .introWindowController) as! NSWindowController)
			introWindowController!.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.statusWindow)))
			introWindowController!.showWindow(self)
		}
	}
	
	func applicationDidBecomeActive(_ notification: Notification) {
		if appDidBecomeActive && !dockIconShown {showPrefs(nil)}
		appDidBecomeActive = true
	}
	
	func applicationWillTerminate(_ aNotification: Notification) {
		kvObserver.stopObservingEverything()
	}
	
	
	/* ***************
	   MARK: - Actions
	   *************** */
	
	@IBAction func showPrefs(_ sender: AnyObject?) {
		let controller: PreferencesWindowController
		if let pc = preferencesWindowController {controller = pc}
		else                                    {controller = NSStoryboard(name: .main, bundle: nil).instantiateController(withIdentifier: .preferencesWindowController) as! PreferencesWindowController}
		preferencesWindowController = controller
		controller.showWindow(sender)
	}
	
	func closeIntroWindow() {
		introWindowController?.close()
		introWindowController = nil /* No need to keep a reference to a class we'll never use again. */
	}
	
	
	/* ***************
	   MARK: - Private
	   *************** */
	
	private let kvObserver = KVObserver()
	
	private func imagesInfoFromImages(_ images: [NSImage], maxWidth: inout Int32, maxHeight: inout Int32) -> [(NSImage, Int32, Int32, Int32, Int32)] {
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
	private func importSkinFramesFromImagesInfo(_ images: [(NSImage, Int32, Int32, Int32, Int32)], inSkin skin: Skin) {
		let mutableFrames = skin.mutableOrderedSetValue(forKey: "frames")
		for (image, x, y, w, h) in images {
			let frame = NSEntityDescription.insertNewObject(forEntityName: "SkinFrame", into: mainManagedObjectContext) as! SkinFrame
			frame.width  = (w > 0 ? w : skin.width)
			frame.height = (h > 0 ? h : skin.height)
			frame.xPos = (x > 0 ? x : (skin.width  - frame.width)/2)
			frame.yPos = (y > 0 ? y : (skin.height - frame.height)/2)
			frame.imageData = image.tiffRepresentation(using: .lzw, factor: 0)
			mutableFrames.add(frame)
		}
	}
	
}
