//
//  FLSkin.m
//  CPU Indicator
//
//  Created by François LAMBOLEY on 3/8/11.
//  Copyright 2011 Frost Land. All rights reserved.
//

#import "FLSkin.h"

@interface FLSkin (Private)

- (NSArray *)deepCopyOfImageArray:(NSArray *)original;

@end

@implementation FLSkin

@synthesize name;
@synthesize images, imagesSize;

+ (void)initialize
{
	[FLSkin setVersion:0];
}

- (id)init
{
	return [self initWithImages:[NSArray arrayWithObjects:[NSImage imageNamed:@"green.png"], [NSImage imageNamed:@"orange.png"], [NSImage imageNamed:@"red.png"], nil]];
}

- (id)initWithImages:(NSArray *)imgs
{
	if ((self = [super init]) != nil) {
		self.name = @"Default";
		images = [self deepCopyOfImageArray:imgs];
		if (images == nil) {
			NSLog(@"Problem while loading the images. Please check that they all have the exact same size.");
			[self release];
			return nil;
		}
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
	if ((self = [super init]) != nil) {
		if ([coder versionForClassName:@"FLSkin"] != 0) {
			NSLog(@"Cannot init the skin: unkown version number");
			[self release];
			return nil;
		}
		self.name = [coder decodeObject];
		
		NSUInteger n;
		[coder decodeValueOfObjCType:@encode(NSUInteger) at:&n];
		NSMutableArray *newImages = [NSMutableArray arrayWithCapacity:n];
		for (NSUInteger i = 0; i < n; ++i)
			[newImages addObject:[[[NSImage alloc] initWithData:[coder decodeObject]] autorelease]];
		
		images = [self deepCopyOfImageArray:newImages];
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
	
	NSUInteger n = [images count];
	[coder encodeValueOfObjCType:@encode(NSUInteger) at:&n];
	for (NSUInteger i = 0; i < n; ++i)
		[coder encodeObject:[[images objectAtIndex:i] TIFFRepresentationUsingCompression:NSTIFFCompressionLZW factor:0.]];
}

- (void)dealloc
{
	self.name = nil;
	[images release];
	
	[super dealloc];
}

- (NSUInteger)nImages
{
	return [images count];
}

@end

@implementation FLSkin (Private)

- (NSArray *)deepCopyOfImageArray:(NSArray *)original
{
	if ([original count] == 0) {
		[NSException raise:@"Invalid image array" format:@"Trying to copy an empty image array"];
		return nil;
	}
	
	imagesSize = CGSizeZero;
	NSUInteger i = 0, n = [original count];
	NSMutableArray *copy = [NSMutableArray arrayWithCapacity:n];
	
	do {
		NSImage *curImage = [original objectAtIndex:i];
		if (![curImage isKindOfClass:[NSImage class]]) {
			[NSException raise:@"Invalid image array" format:@"Trying to copy an image array whose element #%d is not kind of class NSImage (it is: %@)", i, NSStringFromClass([curImage class])];
			return nil;
		}
		
		if (i == 0) imagesSize = [curImage size];
		if (CGSizeEqualToSize(imagesSize, CGSizeZero)) {
			[NSException raise:@"Invalid image array" format:@"Trying to copy an image array whose first element is of size zero"];
			return nil;
		}
		if (!CGSizeEqualToSize([curImage size], imagesSize)) {
			[NSException raise:@"Invalid image array" format:@"Trying to copy an image array whose element #%d is not the same size of the previous elements", i];
			return nil;
		}
		
		[copy addObject:[[curImage copy] autorelease]];
	} while (++i < n);
	
	return [copy copy];
}

@end
