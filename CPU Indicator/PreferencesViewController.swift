/*
 * PreferencesViewController.swift
 * CPU Indicator
 *
 * Created by François Lamboley on 7/18/15.
 * Copyright © 2015 Frost Land. All rights reserved.
 */

import Cocoa



class PreferencesViewController: NSTabViewController {
	
	var originalSizes = [String : NSSize]()
	var constraintsToChange = [String : [NSLayoutConstraint]]()
	var addedConstraints = [String : (NSLayoutConstraint /* width */, NSLayoutConstraint /* height */)]()
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillAppear() {
		super.viewWillAppear()
		
		AppDelegate.sharedAppDelegate.closeIntroWindow()
	}
	
	override func tabView(tabView: NSTabView, willSelectTabViewItem tabViewItem: NSTabViewItem?) {
		super.tabView(tabView, willSelectTabViewItem: tabViewItem)
		
		if let identifier = tabViewItem?.identifier as? String, v = tabViewItem?.view {
			if originalSizes[identifier] == nil {
				originalSizes[identifier] = v.frame.size
			}
		}
		
		if let identifier = tabView.selectedTabViewItem?.identifier as? String, v = tabView.selectedTabViewItem?.view {
			assert(v.subviews.count == 1, "ERROR: Unexpected subview count \(v.subviews.count). Expected 1.")
			let sv = v.subviews[0]
			
			originalSizes[identifier] = v.frame.size
			
			if constraintsToChange[identifier] == nil {
				var constraints = [NSLayoutConstraint]()
				
				func swapOrErasePair<T>(pair: (T, T), withCheck check: (firstItem: T, secondItem: T) -> Bool) -> (T, T)? {
					if check(firstItem: pair.0, secondItem: pair.1) {return pair}
					if check(firstItem: pair.1, secondItem: pair.0) {return (pair.1, pair.0)}
					return nil
				}
				
				for constraint in v.constraints {
					if let _ = swapOrErasePair((
						(constraint.firstItem, constraint.firstAttribute),
						(constraint.secondItem, constraint.secondAttribute)
						), withCheck: { (firstItem: (AnyObject?, NSLayoutAttribute), secondItem: (AnyObject?, NSLayoutAttribute)) -> Bool in
							return (
								firstItem.0 === sv &&
									(firstItem.1 == .Bottom || firstItem.1 == .Trailing) &&
									secondItem.0 === v && secondItem.1 == firstItem.1
							)
					}) {
						constraints.append(constraint)
					}
				}
				
				constraintsToChange[identifier] = constraints
			}
			constraintsToChange[identifier]!.forEach {$0.active = false}
			
			
			if let (constraintWidth, constraintHeight) = addedConstraints[identifier] {
				constraintWidth.constant  = sv.frame.size.width
				constraintHeight.constant = sv.frame.size.height
			} else {
				let cw = NSLayoutConstraint(item: sv, attribute: .Width,  relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: sv.frame.size.width)
				let ch = NSLayoutConstraint(item: sv, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: sv.frame.size.height)
				addedConstraints[identifier] = (cw, ch)
			}
			
			let (cw, ch) = addedConstraints[identifier]!
			cw.active = true
			ch.active = true
		}
	}
	
	override func tabView(tabView: NSTabView, didSelectTabViewItem tabViewItem: NSTabViewItem?) {
		super.tabView(tabView, didSelectTabViewItem: tabViewItem)
		
		if let identifier = tabViewItem?.identifier as? String {
			if let window = self.view.window, s = self.originalSizes[identifier] {
				dispatch_after(DISPATCH_TIME_NOW, dispatch_get_main_queue()) { () -> Void in
					let destSize = window.frameRectForContentRect(NSMakeRect(0, 0, s.width, s.height)).size
					var windowFrame = window.frame
					windowFrame.origin.y += windowFrame.size.height - destSize.height
					windowFrame.size = destSize
					window.setFrame(windowFrame, display: true, animate: true)
				}
			}
			if let constraints = addedConstraints[identifier] {
				dispatch_after(DISPATCH_TIME_NOW, dispatch_get_main_queue()) { () -> Void in
					constraints.0.active = false
					constraints.1.active = false
				}
			}
			if let constraints = constraintsToChange[identifier] {
				dispatch_after(DISPATCH_TIME_NOW, dispatch_get_main_queue()) { () -> Void in
					constraints.forEach {$0.active = true}
				}
			}
		}
	}
	
}
