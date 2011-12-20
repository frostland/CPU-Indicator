/*
 * FLSkinMelter.m
 * CPU Indicator
 *
 * Created by François LAMBOLEY on 3/27/11.
 * Copyright 2011 Frost Land. All rights reserved.
 */

#import "FLSkinMelter.h"

@interface FLSkinMelter (Private)

- (void)refreshResizedImages;

@end

@implementation FLSkinMelter

- (id)init
{
	if ((self = [super init]) != nil) {
		loadOfLastComutedFrame = -1;
		destSize = NSMakeSize(15., 15.);
		shouldRefreshResizedImages = YES;
		resizedImages = [NSMutableArray new];
	}
	
	return self;
}

- (void)dealloc
{
	[skin release];
	[resizedImages release];
	[lastComputedFrame release];
	
	[super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
	FLSkinMelter *copy = [[FLSkinMelter allocWithZone:zone] init];
	
	copy->destSize = self->destSize;
	copy->finalSize = self->finalSize;
	copy->forceDestSize = self->forceDestSize;
	copy->resizedImages = [self->resizedImages mutableCopy];
	copy->lastComputedFrame = [self->lastComputedFrame copy];
	copy->loadOfLastComutedFrame = self->loadOfLastComutedFrame;
	copy->shouldRefreshResizedImages = self->shouldRefreshResizedImages;
	copy->skin = [self->skin retain];
	
	return copy;
}

- (FLSkin *)skin
{
	return skin;
}

- (void)setSkin:(FLSkin *)s
{
	if (skin == s) return;
	[skin release];
	skin = [s retain];
	
	shouldRefreshResizedImages = YES;
}

- (NSSize)destSize
{
	return destSize;
}

- (void)setDestSize:(NSSize)sze
{
	if (NSEqualSizes(sze, destSize)) return;
	destSize = sze;
	destSize.width = (NSUInteger)destSize.width;
	destSize.height = (NSUInteger)destSize.height;
	
	shouldRefreshResizedImages = YES;
}

- (BOOL)forceDestSize
{
	return forceDestSize;
}

- (void)setForceDestSize:(BOOL)flag
{
	if ((flag && forceDestSize) || (!flag && !forceDestSize)) return;
	
	forceDestSize = flag;
	shouldRefreshResizedImages = YES;
}

- (NSSize)finalSize
{
	if (!shouldRefreshResizedImages) return finalSize;
	
	if (forceDestSize) finalSize = destSize;
	else {
		NSSize skinSize = skin.imagesSize;
		
		finalSize = skinSize;
		if (finalSize.width > destSize.width) {
			finalSize.width = (NSUInteger)destSize.width;
			finalSize.height = (NSUInteger)(destSize.width * (skinSize.height / skinSize.width));
		}
		if (finalSize.height > destSize.height) {
			finalSize.height = (NSUInteger)destSize.height;
			finalSize.width = (NSUInteger)(destSize.height * (skinSize.width / skinSize.height));
		}
	}
	if (finalSize.width <= 0.5)  finalSize.width = 1.;
	if (finalSize.height <= 0.5) finalSize.height = 1.;
	finalSize.width  = (NSUInteger)finalSize.width;
	finalSize.height = (NSUInteger)finalSize.height;
	
	return finalSize;
}

- (NSImageRep *)imageForCPULoad:(CGFloat)load
{
	if (load < -0.00001 || load > 1.00001)
		[[NSException exceptionWithName:@"Bad CPU Load" reason:@"Cannot return image for a CPU load greater than 1 or lower than 0" userInfo:nil] raise];
	
	if (loadOfLastComutedFrame == load && !shouldRefreshResizedImages)
		return lastComputedFrame;
	
	if (shouldRefreshResizedImages) [self refreshResizedImages];
	
	NSUInteger nImages = skin.nImages;
	NSAssert(nImages == [resizedImages count], nil);
	
	unsigned char *meltedPixels[5];
	[lastComputedFrame getBitmapDataPlanes:meltedPixels];
	
	NSUInteger w = [lastComputedFrame size].width;
	NSUInteger h = [lastComputedFrame size].height;
	memset(meltedPixels[0], 0, 4 * w * h * sizeof(unsigned char));
	
	NSRect drawRect = NSMakeRect(0., 0., w, h);
	
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:lastComputedFrame]];
	
	CGFloat f = load * ((CGFloat)nImages-1.);
	NSUInteger imageIdx = f + 1;
	
	if (imageIdx < nImages) {
		[(NSImageRep *)[resizedImages objectAtIndex:imageIdx] drawAtPoint:NSZeroPoint];
		if (imageIdx != 0)
			[(NSImageRep *)[resizedImages objectAtIndex:imageIdx - 1] drawInRect:drawRect fromRect:drawRect operation:NSCompositeSourceOver fraction:(imageIdx - f) respectFlipped:YES hints:nil];
	} else [(NSImageRep *)[resizedImages lastObject] drawAtPoint:NSZeroPoint];
	
	[NSGraphicsContext restoreGraphicsState];
	
	if (imageIdx < nImages && imageIdx != 0) {
		unsigned char *img1Pixels[5], *img2Pixels[5];
		[[resizedImages objectAtIndex:imageIdx]     getBitmapDataPlanes:img1Pixels];
		[[resizedImages objectAtIndex:imageIdx - 1] getBitmapDataPlanes:img2Pixels];
		for (NSUInteger y = 0; y < h; ++y) {
			for (NSUInteger x = 0; x < w; ++x) {
				*(meltedPixels[0] + 4*(y * w  +  x) + 3) = MAX(*(img1Pixels[0] + 4*(y * w  +  x) + 3), (imageIdx - f) * (*(img2Pixels[0] + 4*(y * w  +  x) + 3)));
			}
		}
	}
	
	return lastComputedFrame;
}

@end

@implementation FLSkinMelter (Private)

- (void)refreshResizedImages
{
	[self finalSize]; /* Refreshes the finalSize */
	
	loadOfLastComutedFrame = -1;
	[lastComputedFrame release];
	lastComputedFrame = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
																					pixelsWide:finalSize.width
																					pixelsHigh:finalSize.height
																				bitsPerSample:8 samplesPerPixel:4
																					  hasAlpha:YES isPlanar:NO
																			  colorSpaceName:NSCalibratedRGBColorSpace
																				  bytesPerRow:4 * finalSize.width
																				 bitsPerPixel:32];
	
	[resizedImages removeAllObjects];
	for (NSImage *curImg in skin.images) {
		NSBitmapImageRep *curImageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
																										pixelsWide:finalSize.width
																										pixelsHigh:finalSize.height
																									bitsPerSample:8 samplesPerPixel:4
																										  hasAlpha:YES isPlanar:NO
																								  colorSpaceName:NSCalibratedRGBColorSpace
																									  bytesPerRow:4 * finalSize.width
																									 bitsPerPixel:32];
		
		[NSGraphicsContext saveGraphicsState];
		[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:curImageRep]];
		
		[curImg drawInRect:NSMakeRect(0., 0., finalSize.width, finalSize.height)
					 fromRect:NSMakeRect(0., 0., [curImg size].width, [curImg size].height)
					operation:NSCompositeCopy fraction:1.];
		
		[NSGraphicsContext restoreGraphicsState];
		
		[resizedImages addObject:curImageRep];

		[curImageRep release];
	}
	
	shouldRefreshResizedImages = NO;
}

@end
