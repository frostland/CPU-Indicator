/*
 * SkinsPrefsViewController.swift
 * CPU Indicator
 *
 * Created by François Lamboley on 10/17/15.
 * Copyright © 2015 Frost Land. All rights reserved.
 */

import Cocoa



private extension NSUserInterfaceItemIdentifier {
	
	static let isSelectedColumn = NSUserInterfaceItemIdentifier(rawValue: "isSelected")
	
}


class SkinsPrefsViewController: NSViewController, NSTableViewDelegate {
	
	@objc dynamic let managedObjectContext = AppDelegate.sharedAppDelegate.mainManagedObjectContext
	@objc dynamic let sortDescriptors = [NSSortDescriptor(key: "sortPosition", ascending: true)]
	
	private var observingUDC = false
	@IBOutlet private var arrayController: NSArrayController!
	@IBOutlet private var tableView: NSTableView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		AppDelegate.sharedAppDelegate.addObserver(self, forKeyPath: "selectedSkinObjectID", options: [], context: nil)
		observingUDC = true
	}
	
	deinit {
		if observingUDC {
			AppDelegate.sharedAppDelegate.removeObserver(self, forKeyPath: "selectedSkinObjectID", context: nil)
		}
	}
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		do {
			let e = NSError(domain: "fr.frostland.cpu-indicator.SkinsPrefsViewController.KVOHandling", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot handle observation change."])
			guard let keyPath = keyPath else {
				throw e
			}
			switch (object, keyPath) {
			case (let o, "selectedSkinObjectID") where o as? AppDelegate === AppDelegate.sharedAppDelegate:
				tableView.reloadData(
					forRowIndexes: IndexSet(integersIn: 0..<tableView.numberOfRows /* Too lazy to compute exactly which row should be reloaded right now... */),
					columnIndexes: IndexSet(integer: tableView.column(withIdentifier: .isSelectedColumn))
				)
			default:
				throw e
			}
		} catch {
			super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
		}
	}
	
	@IBAction func useSelectedSkin(_ sender: AnyObject) {
		/* About arrayController.selection: it's a proxy object which can be used
		 * to KVC (and KVO?) on the selection, but not much more... */
		// print(arrayController.selection.valueForKey("objectID"))
		
		guard let selectedObjects = arrayController.selectedObjects as? [Skin], selectedObjects.count == 1 else {
			return
		}
		
		let selectedSkin = selectedObjects[0]
		AppDelegate.sharedAppDelegate.selectedSkinObjectID = selectedSkin.objectID
	}
	
}
