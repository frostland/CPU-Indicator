/*
 * FLSkin.m
 * CPU Indicator
 *
 * Created by François LAMBOLEY on 3/8/11.
 * Copyright 2011 Frost Land. All rights reserved.
 */

#import "FLSkin.h"

@interface FLSkin (Private)

- (NSArray *)copyImageArrayDeeply:(NSArray *)original;

@end

@implementation FLSkin

@synthesize name;
@synthesize images, imagesSize;
@synthesize mixedImageState;

+ (void)initialize
{
	[FLSkin setVersion:1];
}

- (instancetype)init
{
	return [self initWithImages:@[[NSImage imageNamed:@"green.png"], [NSImage imageNamed:@"orange.png"], [NSImage imageNamed:@"red.png"]] mixedImageState:FLMixedImageStateAllow];
}

- (instancetype)initWithImages:(NSArray *)imgs mixedImageState:(FLSkinMixedImageState)state
{
	return [self initWithImages:imgs mixedImageState:state name:@"Default"];
}

- (instancetype)initWithImages:(NSArray *)imgs mixedImageState:(FLSkinMixedImageState)state name:(NSString *)n
{
	if ((self = [super init]) != nil) {
		mixedImageState = state;
		
		name = [n copy];
		images = [self copyImageArrayDeeply:imgs];
		if (images == nil) {
			NSLog(@"Problem while loading the images. Please check that they all have the exact same size.");
			[self release];
			return nil;
		}
	}
	
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
	if ((self = [self init]) != nil) {
		NSInteger version = [coder versionForClassName:@"FLSkin"];
		if (version < 0 || version > 1) {
			NSLog(@"Cannot init the skin: unkown version number (%ld)", (long)version);
			[self release];
			return nil;
		}
		[name release];
		name = [[coder decodeObject] retain];
		
		mixedImageState = FLMixedImageStateTransitionsOnly;
		if (version >= 1) [coder decodeValueOfObjCType:@encode(FLSkinMixedImageState) at:&mixedImageState];
		
		NSUInteger n;
		[coder decodeValueOfObjCType:@encode(NSUInteger) at:&n];
		NSMutableArray *newImages = [NSMutableArray arrayWithCapacity:n];
		for (NSUInteger i = 0; i < n; ++i)
			[newImages addObject:[[[NSImage alloc] initWithData:[coder decodeObject]] autorelease]];
		
		images = [self copyImageArrayDeeply:newImages];
		if (images == nil) {
			NSLog(@"Cannot decode the skin: invalid images.");
			[self release];
			return nil;
		}
	}
		 
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder;
{
	[coder encodeObject:name];
	[coder encodeValueOfObjCType:@encode(FLSkinMixedImageState) at:&mixedImageState];
	
	NSUInteger n = [images count];
	[coder encodeValueOfObjCType:@encode(NSUInteger) at:&n];
	for (NSUInteger i = 0; i < n; ++i)
		[coder encodeObject:[images[i] TIFFRepresentationUsingCompression:NSTIFFCompressionLZW factor:0.]];
}

- (void)dealloc
{
	[name release];
	[images release];
	
	[super dealloc];
}

- (NSUInteger)nImages
{
	return [images count];
}

@end

@implementation FLSkin (Private)

- (NSArray *)copyImageArrayDeeply:(NSArray *)original
{
	if ([original count] == 0) {
		NSLog(@"*** Warning: Trying to copy an empty image array. Cancelling copy.");
		return nil;
	}
	
	imagesSize = NSZeroSize;
	NSUInteger i = 0, n = [original count];
	NSMutableArray *copy = [NSMutableArray arrayWithCapacity:n];
	
	do {
		NSImage *curImage = original[i];
		if (![curImage isKindOfClass:[NSImage class]]) {
			NSLog(@"*** Warning: Trying to copy an image array whose element #%lu is not kind of class NSImage (it is: %@). Cancelling copy.", (unsigned long)i, NSStringFromClass([curImage class]));
			return nil;
		}
		
		if (i == 0) imagesSize = [curImage size];
		if (NSEqualSizes(imagesSize, NSZeroSize)) {
			NSLog(@"*** Warning: Trying to copy an image array whose first element is of size zero. Cancelling copy.");
			return nil;
		}
		if (!NSEqualSizes([curImage size], imagesSize)) {
			NSLog(@"*** Warning: Trying to copy an image array whose element #%lu is not the same size of the previous elements. Cancelling copy.", (unsigned long)i);
			return nil;
		}
		
		[copy addObject:[[curImage copy] autorelease]];
	} while (++i < n);
	
	return [copy copy];
}

@end
