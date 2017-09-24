/*
 * CheckImageFromSkinObjectID.swift
 * CPU Indicator
 *
 * Created by François Lamboley on 10/31/15.
 * Copyright © 2015 Frost Land. All rights reserved.
 */

import Cocoa



@objc(CheckImageFromSkinObjectID)
class CheckImageFromSkinObjectID: ValueTransformer {
	
	override class func transformedValueClass() -> AnyClass {
		return NSImage.self
	}
	
	override class func allowsReverseTransformation() -> Bool {
		return false
	}
	
	override func transformedValue(_ value: Any?) -> Any? {
		if let id = value as? NSManagedObjectID, id == AppDelegate.sharedAppDelegate.selectedSkinObjectID {
			return #imageLiteral(resourceName: "check_mark")
		}
		return nil
	}
	
}
