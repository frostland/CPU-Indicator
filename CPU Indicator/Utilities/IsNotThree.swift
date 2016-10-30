/*
 * IsNotThree.swift
 * CPU Indicator
 *
 * Created by François Lamboley on 8/29/15.
 * Copyright © 2015 Frost Land. All rights reserved.
 */

import Cocoa



/* About the @objc: In the storyboard we use this value transformer in a binding
 * which does not support Swift modules. We have to force the name of the class.
 * Another solution would have been to create an IsNotThree value transformer at
 * launch time and register it with this name. */
@objc(IsNotThree)
class IsNotThree: ValueTransformer {
	
	override class func transformedValueClass() -> AnyClass {
		return NSNumber.self
	}
	
	override class func allowsReverseTransformation() -> Bool {
		return false
	}
	
	override func transformedValue(_ value: Any?) -> Any? {
		return NSNumber(value: (value as AnyObject).intValue != 3)
	}

}
