/*
 * SkinCell.swift
 * CPU Indicator
 *
 * Created by François Lamboley on 10/11/15.
 * Copyright © 2015 Frost Land. All rights reserved.
 */

import Cocoa



class SkinCellValue : NSObject, NSCopying {
	
	let skin: Skin
	let size: CGSize

	/* x and y represent resp. the ratio between the skin size and the given skin
	 * cell value size. */
	private let scale: CGPoint
	
	lazy var resizedSkinImages: [NSImage] = {
		var res = [NSImage]()
		
		var infos = [(NSData, CGRect)]()
		self.skin.managedObjectContext!.performBlockAndWait {
			for f in self.skin.frames {
				let frame = f as! SkinFrame
				infos.append((
					frame.imageData,
					CGRectMake(
						CGFloat(frame.xPos)  * self.scale.x, CGFloat(frame.yPos)   * self.scale.y,
						CGFloat(frame.width) * self.scale.x, CGFloat(frame.height) * self.scale.y)
				))
			}
		}
		
		for (imageData, frameRect) in infos {
			guard let image = NSImage(data: imageData) else {
				print("Got corrupted frame with invalid image data")
				continue
			}
			guard let curImageRep = NSBitmapImageRep(
				bitmapDataPlanes: nil, pixelsWide: Int(self.size.width), pixelsHigh: Int(self.size.height),
				bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
				colorSpaceName: NSCalibratedRGBColorSpace, bytesPerRow: 4 * Int(self.size.width), bitsPerPixel: 32
				) else {
					print("Cannot create image rep to create resized image for frame")
					continue
			}
			
			NSGraphicsContext.saveGraphicsState()
			NSGraphicsContext.setCurrentContext(NSGraphicsContext(bitmapImageRep: curImageRep))
			
			image.drawInRect(
				frameRect, fromRect: NSMakeRect(0, 0, image.size.width, image.size.height),
				operation: NSCompositingOperation.CompositeCopy,
				fraction: 1
			)
			
			NSGraphicsContext.restoreGraphicsState()
		}
		return res
	}()
	
	init(skin s: Skin, size destSize: CGSize, allowDistortion forceDestinationSize: Bool) {
		skin = s
		var skinSize: CGSize!
		s.managedObjectContext!.performBlockAndWait {
			skinSize = CGSizeMake(CGFloat(s.width), CGFloat(s.height))
		}
		
		var finalSize = destSize
		if !forceDestinationSize {
			/* Let's compute the constrained size. */
			finalSize = skinSize
			if finalSize.width  > destSize.width  {finalSize.width  = destSize.width;  finalSize.height = (destSize.width  * (CGFloat(s.height) / CGFloat(s.width)))}
			if finalSize.height > destSize.height {finalSize.height = destSize.height; finalSize.width  = (destSize.height * (CGFloat(s.width)  / CGFloat(s.height)))}
		}
		if finalSize.width  <= 0.5 {finalSize.width  = 1}
		if finalSize.height <= 0.5 {finalSize.height = 1}
		finalSize.width  = round(finalSize.width)
		finalSize.height = round(finalSize.height)
		
		size = finalSize
		
		scale = CGPointMake(finalSize.width / skinSize.width, finalSize.height / skinSize.height)
	}
	
	func copyWithZone(zone: NSZone) -> AnyObject {
		return SkinCellValue(skin: skin, size: size, allowDistortion: true)
	}
	
}



class SkinCell : NSCell {
	
	override var representedObject: AnyObject? {
		didSet {
			assert(representedObject is SkinCellValue?)
//			self.objectValue = imageForSkinCellValue
		}
	}
	
}
