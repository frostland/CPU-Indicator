/*
 * CheckImageFromSkinObjectID.swift
 * CPU Indicator
 *
 * Created by François Lamboley on 10/31/15.
 * Copyright © 2015 Frost Land. All rights reserved.
 */

import Cocoa



@objc(CheckImageFromSkinObjectID)
class CheckImageFromSkinObjectID: NSValueTransformer {
	
	override class func transformedValueClass() -> AnyClass {
		return NSImage.self
	}
	
	override class func allowsReverseTransformation() -> Bool {
		return false
	}
	
	override func transformedValue(value: AnyObject?) -> AnyObject? {
		if let id = value as? NSManagedObjectID where id == AppDelegate.sharedAppDelegate.selectedSkinObjectID {
			return NSImage(named: "check_mark")
		}
		return nil
	}
	
}
