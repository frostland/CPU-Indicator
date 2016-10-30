/*
 * Skin.swift
 * CPU Indicator
 *
 * Created by François Lamboley on 10/11/15.
 * Copyright © 2015 Frost Land. All rights reserved.
 */

import Foundation
import CoreData



@objc(Skin)
public class Skin : NSManagedObject {
	
	var mixedImageState: MixedImageState {
		get {
			guard let state = MixedImageState(rawValue: rawMixedImageState) else {return .useSkinDefault}
			return state
		}
		set {
			rawMixedImageState = newValue.rawValue
		}
	}
	
}
