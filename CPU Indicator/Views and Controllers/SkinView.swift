/*
 * SkinView.swift
 * CPU Indicator
 *
 * Created by François Lamboley on 29/11/15.
 * Copyright © 2015 Frost Land. All rights reserved.
 */

import Cocoa



class SkinView : NSView {
	
	/* The three methods below are not useful on Xcode > 3 as the support for
	 * displaying custom bindings in the Interface Editor (aka. Interface Builder
	 * on Xcode 3) has been removed...
	 * In the meantime, we have cheated in the storyboard to have a binding with
	 * the sizedSkin property anyway by editing the storyboard XML manually... */
	/*
	override static func initialize() {
		if self == SkinCell.self {
			self.exposeBinding("sizedSkin")
		}
		
		super.initialize()
	}
	
	override func valueClassForBinding(binding: String) -> AnyClass? {
		switch binding {
		case "sizedSkin":
			return SizedSkin.self
		default:
			return super.valueClassForBinding(binding)
		}
	}
	
	override func optionDescriptionsForBinding(binding: String) -> [NSAttributeDescription] {
		switch binding {
		case "sizedSkin":
			/* Not sure about what should be in the returned array... but I can't
			 * test! */
			let attr1 = NSAttributeDescription()
			attr1.name = NSAllowsNullArgumentBindingOption
			attr1.attributeType = .BooleanAttributeType
			attr1.defaultValue = true
			let attr2 = NSAttributeDescription()
			attr2.name = NSRaisesForNotApplicableKeysBindingOption
			attr2.attributeType = .BooleanAttributeType
			attr2.defaultValue = false
			return [attr1, attr2]
		default:
			return super.optionDescriptionsForBinding(binding)
		}
	}*/
	
	var sizedSkin: SizedSkin?
	
	/**
  If non-nil, the progress will be static, else, the shared "preview" progress
	will be used. */
	@IBInspectable var progress: Float?
	
	override func drawRect(dirtyRect: NSRect) {
		guard let sizedSkin = sizedSkin else {
			return
		}
		
		let myFrame = self.frame
		
		let drawnSize = sizedSkin.size
		let p = NSPoint(
			x: myFrame.origin.x +  myFrame.size.width  - drawnSize.width,
			y: myFrame.origin.y + (myFrame.size.height - drawnSize.height)/2.0
		)
		
		let drawRect = NSRect(origin: p, size: drawnSize)
		sizedSkin.imageForProgress(0.0).drawInRect(
			drawRect,
			fromRect: NSRect(origin: CGPointZero, size: drawnSize),
			operation: .CompositeSourceOver,
			fraction: 1,
			respectFlipped: true,
			hints: nil
		)
	}
	
}
