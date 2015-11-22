/*
 * SkinsPrefsViewController.swift
 * CPU Indicator
 *
 * Created by François Lamboley on 10/17/15.
 * Copyright © 2015 Frost Land. All rights reserved.
 */

import Cocoa



class SkinsPrefsViewController: NSViewController {
	
	dynamic let managedObjectContext = AppDelegate.sharedAppDelegate.mainManagedObjectContext
	dynamic let sortDescriptors = [NSSortDescriptor(key: "sortPosition", ascending: true)]
	
	@IBOutlet private var arrayController: NSArrayController!
	@IBOutlet private var tableView: NSTableView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		AppDelegate.sharedAppDelegate.addObserver(self, forKeyPath: "selectedSkinObjectID", options: [], context: nil)
	}
	
	deinit {
		AppDelegate.sharedAppDelegate.removeObserver(self, forKeyPath: "selectedSkinObjectID", context: nil)
	}
	
	override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
		do {
			let e = NSError(domain: "fr.frostland.cpu-indicator.SkinsPrefsViewController.KVOHandling", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot handle observation change."])
			guard let keyPath = keyPath else {
				throw e
			}
			switch (object, keyPath) {
			case (let o, "selectedSkinObjectID") where o === AppDelegate.sharedAppDelegate:
				tableView.setNeedsDisplayInRect(tableView.rectOfColumn(tableView.columnWithIdentifier("isSelected")))
			default:
				throw e
			}
		} catch {
			super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
		}
	}
	
	@IBAction func useSelectedSkin(sender: AnyObject) {
		/* About arrayController.selection: it's a proxy object which can be used
		 * to KVC (and KVO?) on the selection, but not much more... */
		// print(arrayController.selection.valueForKey("objectID"))
		
		guard let selectedObjects = arrayController.selectedObjects as? [Skin] where selectedObjects.count == 1 else {
			return
		}
		
		let selectedSkin = selectedObjects[0]
		AppDelegate.sharedAppDelegate.selectedSkinObjectID = selectedSkin.objectID
	}
	
}
