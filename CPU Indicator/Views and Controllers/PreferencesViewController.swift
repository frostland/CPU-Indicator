/*
 * PreferencesViewController.swift
 * CPU Indicator
 *
 * Created by François Lamboley on 7/18/15.
 * Copyright © 2015 Frost Land. All rights reserved.
 */

import Cocoa



class PreferencesViewController: NSTabViewController {
	
	var delayedWindowSizeChange = false
	var childSizes = [String : NSSize]()
	var constraintsToChange = [String : [NSLayoutConstraint]]()
	var addedConstraints = [String : (NSLayoutConstraint /* width */, NSLayoutConstraint /* height */)]()
	
	override func viewDidLoad() {
		let idToSelect = UserDefaults.standard.object(forKey: kUDK_LatestSelectedPrefPaneId)
		childSizes = readSizesDictionaryFromKey(kUDK_PrefsPanesSizes)
		
		super.viewDidLoad()
		
		for i in 0..<tabViewItems.count {
			if let id = tabViewItems[i].identifier, let idToSelect = idToSelect, (id as AnyObject).isEqual(idToSelect as AnyObject) {
				selectedTabViewItemIndex = i
			}
		}
	}
	
	override func viewWillAppear() {
		super.viewWillAppear()
		
		tabView(tabView, didSelect: tabViewItems[selectedTabViewItemIndex])
		delayedWindowSizeChange = true
		
		AppDelegate.sharedAppDelegate.closeIntroWindow()
	}
	
	override func viewWillDisappear() {
		super.viewWillDisappear()
		
		if let identifier = tabView.selectedTabViewItem?.identifier as? String, let v = tabView.selectedTabViewItem?.view {
			childSizes[identifier] = v.frame.size
		}
		
		saveSizesDictionary(childSizes, inKey: kUDK_PrefsPanesSizes)
	}
	
	override func tabView(_ tabView: NSTabView, willSelect tabViewItem: NSTabViewItem?) {
		super.tabView(tabView, willSelect: tabViewItem)
		
		if let identifier = tabViewItem?.identifier as? String, let v = tabViewItem?.view {
			if childSizes[identifier] == nil {
				childSizes[identifier] = v.frame.size
			}
		}
		
		if let identifier = tabView.selectedTabViewItem?.identifier as? String, let v = tabView.selectedTabViewItem?.view {
			childSizes[identifier] = v.frame.size
		}
		
		saveSizesDictionary(childSizes, inKey: kUDK_PrefsPanesSizes)
		
		for item in [tabViewItem, tabView.selectedTabViewItem] {
			guard let identifier = item?.identifier as? String, let v = item?.view else {
				continue
			}
			
			assert(v.subviews.count == 1, "ERROR: Unexpected subview count \(v.subviews.count). Expected 1.")
			let sv = v.subviews[0]
			
			if constraintsToChange[identifier] == nil {
				var constraints = [NSLayoutConstraint]()
				
				func swapOrErasePair<T>(_ pair: (T, T), withCheck check: (_ firstItem: T, _ secondItem: T) -> Bool) -> (T, T)? {
					if check(pair.0, pair.1) {return pair}
					if check(pair.1, pair.0) {return (pair.1, pair.0)}
					return nil
				}
				
				for constraint in v.constraints {
					if let _ = swapOrErasePair((
						(constraint.firstItem, constraint.firstAttribute),
						(constraint.secondItem, constraint.secondAttribute)
					), withCheck: { (firstItem: (AnyObject?, NSLayoutConstraint.Attribute), secondItem: (AnyObject?, NSLayoutConstraint.Attribute)) -> Bool in
						return (
							/* The constraint links the item's view and its subview
							 * and they link the same attribute, which can either be
							 * bottom or tailing. */
							firstItem.0 === sv && secondItem.0 === v &&
							(firstItem.1 == .bottom || firstItem.1 == .trailing) &&
							secondItem.1 == firstItem.1
						)
					}) {
						constraints.append(constraint)
					}
				}
				
				constraintsToChange[identifier] = constraints
			}
			constraintsToChange[identifier]!.forEach {$0.isActive = false}
			
			
			if let (constraintWidth, constraintHeight) = addedConstraints[identifier] {
				constraintWidth.constant  = sv.frame.size.width
				constraintHeight.constant = sv.frame.size.height
			} else {
				let cw = NSLayoutConstraint(item: sv, attribute: .width,  relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: sv.frame.size.width)
				let ch = NSLayoutConstraint(item: sv, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: sv.frame.size.height)
				addedConstraints[identifier] = (cw, ch)
			}
			
			let (cw, ch) = addedConstraints[identifier]!
			cw.isActive = true
			ch.isActive = true
		}
	}
	
	override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
		super.tabView(tabView, didSelect: tabViewItem)
		
		guard let identifier = tabViewItem?.identifier as? String else {
			return
		}
		
		if let window = view.window, let s = childSizes[identifier] {
			let b = { () -> Void in
				let destSize = window.frameRect(forContentRect: NSMakeRect(0, 0, s.width, s.height)).size
				var windowFrame = window.frame
				windowFrame.origin.y += windowFrame.size.height - destSize.height
				windowFrame.size = destSize
				window.setFrame(windowFrame, display: true, animate: true)
			}
			if delayedWindowSizeChange {DispatchQueue.main.asyncAfter(deadline: DispatchTime.now(), execute: b)}
			else                       {b()}
		}
		
		if let constraints = addedConstraints[identifier] {
			let b = { () -> Void in
				constraints.0.isActive = false
				constraints.1.isActive = false
			}
			if delayedWindowSizeChange {DispatchQueue.main.asyncAfter(deadline: DispatchTime.now(), execute: b)}
			else                       {b()}
		}
		
		if let constraints = constraintsToChange[identifier] {
			let b = { () -> Void in
				constraints.forEach {$0.isActive = true}
			}
			if delayedWindowSizeChange {DispatchQueue.main.asyncAfter(deadline: DispatchTime.now(), execute: b)}
			else                       {b()}
		}
	}
	
	/* Writes the childSizes dictionary to the user defaults. */
	private func saveSizesDictionary(_ sizes: [String: NSSize], inKey k: String) {
		var serializableSizes = [String: String]()
		for (key, val) in sizes {serializableSizes[key] = NSStringFromSize(val)}
		UserDefaults.standard.set(serializableSizes, forKey: k)
	}
	
	private func readSizesDictionaryFromKey(_ k: String) -> [String: NSSize] {
		guard let sizes = UserDefaults.standard.object(forKey: k) as? [String: String] else {
			return [:]
		}
		
		var ret = [String: NSSize]()
		for (key, val) in sizes {ret[key] = NSSizeFromString(val)}
		return ret
	}
	
}
