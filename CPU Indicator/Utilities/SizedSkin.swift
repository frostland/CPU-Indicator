/*
 * SizedSkin.swift
 * CPU Indicator
 *
 * Created by François Lamboley on 11/22/15.
 * Copyright © 2015 Frost Land. All rights reserved.
 */

import Cocoa



class SizedSkin : NSObject {
	
	let skin: Skin
	let size: CGSize
	/** The size given at init time, before retrictions were applied. */
	let originalSize: CGSize
	
	/* x and y represent resp. the ratio between the skin size and the given skin
	* cell value size. */
	private let scale: CGPoint
	
	private let imageConstruction: NSBitmapImageRep
	private var cachedImagesByProgress = [Float: NSBitmapImageRep]()
	
	private(set) lazy var resizedSkinImages: [NSBitmapImageRep] = {
		var res = [NSBitmapImageRep]()
		
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
			
			res.append(curImageRep)
		}
		return res
	}()
	
	init(skin s: Skin, size destSize: CGSize, allowDistortion forceDestinationSize: Bool) {
		skin = s
		originalSize = destSize
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
		
		imageConstruction = NSBitmapImageRep(
			bitmapDataPlanes: nil, pixelsWide: Int(size.width), pixelsHigh: Int(size.height),
			bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
			colorSpaceName: NSCalibratedRGBColorSpace, bytesPerRow: 4 * Int(finalSize.width), bitsPerPixel: 32
		)!
	}
	
	func imageForProgress(p: Float) -> NSImageRep {
		precondition(p > -0.000001 && p < 1.000001, "Progress must be greater than 0, lower than 1")
		
		/* We round the progress so that only roundPrecision+1 values are possible
		 * in order to have a meaningful caching system which won't eat up all of
		 * the RAM. */
		let roundPrecision = Float(500.0)
		let p = round(p * roundPrecision)/roundPrecision
		
		if let img = cachedImagesByProgress[p] {
			return img
		}
		
		let nImages = resizedSkinImages.count
		
		let meltedPixels = UnsafeMutablePointer<UnsafeMutablePointer<UInt8>>.alloc(5)
		defer {meltedPixels.dealloc(5)}
		
		imageConstruction.getBitmapDataPlanes(meltedPixels)
		
		let w = Int(imageConstruction.size.width)
		let h = Int(imageConstruction.size.height)
		memset(meltedPixels.memory, 0, 4 * w * h * sizeof(UInt8.self))
		
		let drawRect = NSMakeRect(0, 0, CGFloat(w), CGFloat(h))
		
		NSGraphicsContext.saveGraphicsState()
		NSGraphicsContext.setCurrentContext(NSGraphicsContext(bitmapImageRep: imageConstruction))
		
		let f = p * Float(nImages - 1)
		let imageIdx = Int(f + 1)
		if imageIdx < nImages {
			resizedSkinImages[imageIdx].drawAtPoint(NSZeroPoint)
			if imageIdx != 0 {
				resizedSkinImages[imageIdx - 1].drawInRect(drawRect, fromRect: drawRect, operation: .CompositeSourceOver, fraction: (CGFloat(imageIdx) - CGFloat(f)), respectFlipped: true, hints: nil)
			}
		} else {
			resizedSkinImages.last!.drawAtPoint(NSZeroPoint)
		}
		
		NSGraphicsContext.restoreGraphicsState()
		
		if imageIdx < nImages && imageIdx != 0 {
			let img1Pixels = UnsafeMutablePointer<UnsafeMutablePointer<UInt8>>.alloc(5); defer {img1Pixels.dealloc(5)}
			let img2Pixels = UnsafeMutablePointer<UnsafeMutablePointer<UInt8>>.alloc(5); defer {img2Pixels.dealloc(5)}
			resizedSkinImages[imageIdx  ].getBitmapDataPlanes(img1Pixels)
			resizedSkinImages[imageIdx-1].getBitmapDataPlanes(img2Pixels)
			for y in 0..<h {
				for x in 0..<w {
					let val1 = img1Pixels.memory.advancedBy(4*(y * w  +  x) + 3).memory
					let val2 = img2Pixels.memory.advancedBy(4*(y * w  +  x) + 3).memory
					meltedPixels.memory.advancedBy(4*(y * w  +  x) + 3).memory = max(val1, UInt8((Float(imageIdx) - f) * Float(val2)))
				}
			}
		}
		
		cachedImagesByProgress[p] = (imageConstruction.copy() as! NSBitmapImageRep)
		
		return imageConstruction
	}
	
	func setLayerContents(layer: CALayer, forProgress progress: Float, mixedImageState: MixedImageState, allowAnimation: Bool) {
		layer.removeAnimationForKey("contents")
		
		let animate = (allowAnimation && mixedImageState != .Disallow)
		let image = imageForProgress(progress).CGImageForProposedRect(nil, context: nil, hints: nil)
		
		if !animate {layer.contents = image}
		else {
			let anim = CABasicAnimation(keyPath: "contents")
			anim.fromValue = layer.contents
			anim.duration = 0.5
			layer.contents = image
			layer.addAnimation(anim, forKey: "contents")
		}
	}
	
}



/**
Transforms a given skin to a sized skin, for a given destination size, allowing
distortion or not. */
class SkinToSizedSkinTransformer: NSValueTransformer {
	
	let destSize: CGSize
	let allowDistortion: Bool
	
	init(destSize s: CGSize, allowDistortion d: Bool) {
		destSize = s
		allowDistortion = d
	}
	
	override class func transformedValueClass() -> AnyClass {
		return SizedSkin.self
	}
	
	override class func allowsReverseTransformation() -> Bool {
		return false
	}
	
	override func transformedValue(value: AnyObject?) -> AnyObject? {
		guard let value = value as? Skin else {
			return nil
		}
		return SizedSkin(skin: value, size: destSize, allowDistortion: allowDistortion)
	}
	
}
