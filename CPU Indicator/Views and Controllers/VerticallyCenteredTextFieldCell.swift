/*
 * VerticallyCenteredTextFieldCell.swift
 * CPU Indicator
 *
 * Created by François Lamboley on 10/18/15.
 * Copyright © 2015 Frost Land. All rights reserved.
 */

import Cocoa



class VerticallyCenteredTextFieldCell: NSTextFieldCell {
	
	override func drawingRectForBounds(theRect: NSRect) -> NSRect {
		var r = super.drawingRectForBounds(theRect)
		let s = self.cellSizeForBounds(theRect)
		
		r.origin.y += (r.size.height - s.height)/2;
		r.size.height = cellSize.height;
		
		return r;
	}

}
