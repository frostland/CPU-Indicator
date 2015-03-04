/*
 * FLIsNotThree.swift
 * CPU Indicator
 *
 * Created by François Lamboley on 3/4/15.
 * Copyright (c) 2015 Frost Land. All rights reserved.
 */

import Foundation



/* If the @objc(FLIsNotThree) annotation is not there, the runtime won't be able
 * to find the transformer by name. */
@objc(FLIsNotThree) class FLIsNotThree: NSValueTransformer {
	override static func transformedValueClass() -> AnyClass {
		return NSNumber.self
	}
	
	override static func allowsReverseTransformation() -> Bool {
		return false
	}
	
	override func transformedValue(value: AnyObject?) -> AnyObject? {
		return NSNumber(bool: value?.integerValue != 3)
	}
}
