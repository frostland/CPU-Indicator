//
//  FLCPUIndicatorView.m
//  CPU Indicator
//
//  Created by François LAMBOLEY on 3/6/11.
//  Copyright 2011 Frost Land. All rights reserved.
//

#import "FLCPUIndicatorView.h"

@interface FLCPUIndicatorView (Private)

- (NSArray *)deepCopyOfImageArray:(NSArray *)original;

@end

@implementation FLCPUIndicatorView

@synthesize parentWindow;

- (id)initWithFrame:(NSRect)frame
{
	frame.size = CGSizeZero;
	self = [super initWithFrame:frame];
	if (self) {
		baseSize = CGSizeZero;
		
		stickToImages = NO;
		
		animating = NO;
		curCPULoad = 0.;
		destCPULoad = 0.;
		curFrameNumber = 0;
		animTimer = nil;
	}
	
	return self;
}

- (void)dealloc
{
	[animTimer invalidate];
	[animTimer release];
	
	[super dealloc];
}

- (NSArray *)images
{
	return [[self deepCopyOfImageArray:images] autorelease];
}

- (void)setImages:(NSArray *)newImages
{
	if (newImages == images) return;
	
	[images release];
	images = [self deepCopyOfImageArray:newImages];
	
	[parentWindow setContentSize:baseSize];
	[parentWindow invalidateShadow];
	
	CGRect f = self.frame;
	f.size = baseSize;
	self.frame = f;
	
	[self setNeedsDisplay:YES];
}

- (CGFloat)curCPULoad
{
	return curCPULoad;
}

- (void)setCurCPULoad:(CGFloat)CPULoad
{
	curCPULoad = CPULoad;
	[self setNeedsDisplay:YES];
}

- (void)setCurCPULoad:(CGFloat)CPULoad animated:(BOOL)flag
{
	if (!flag) {
		animating = NO;
		[animTimer invalidate]; [animTimer release]; animTimer = nil;
		[self setCurCPULoad:CPULoad];
		
		return;
	}
	
	curFrameNumber = 0;
	destCPULoad = CPULoad;
	if (stickToImages) {
		CGFloat f = CPULoad * ((CGFloat)[images count]-1.);
		NSUInteger imageIdx = f;
		destCPULoad = ((CGFloat)imageIdx) / ((CGFloat)[images count]-1.) + .001;
	}
	CPULoadIncrement = (destCPULoad - curCPULoad)/NFRAME;
	if (!animating)
		animTimer = [[NSTimer scheduledTimerWithTimeInterval:1./FPS target:self selector:@selector(goToNextFrame:) userInfo:NULL repeats:YES] retain];
	
	animating = YES;
}

- (void)goToNextFrame:(NSTimer *)t
{
	if (curFrameNumber++ >= NFRAME) {
		animating = NO;
		[animTimer invalidate]; [animTimer release]; animTimer = nil;
		[self setCurCPULoad:destCPULoad];
		
		return;
	}
	
	[self setCurCPULoad:curCPULoad + CPULoadIncrement];
}

- (void)drawRect:(NSRect)dirtyRect
{
	CGFloat f = curCPULoad * ((CGFloat)[images count]-1.);
	NSUInteger imageIdx = f + 1;
	
	if (imageIdx < [images count]) {
		[[images objectAtIndex:imageIdx] dissolveToPoint:NSZeroPoint fraction:1.];
		if (imageIdx - 1 < [images count])
			[[images objectAtIndex:imageIdx - 1] dissolveToPoint:NSZeroPoint fraction:imageIdx - f];
	} else [[images lastObject] dissolveToPoint:NSZeroPoint fraction:1.];
	
	[parentWindow invalidateShadow];
}

@end

@implementation FLCPUIndicatorView (Private)

- (NSArray *)deepCopyOfImageArray:(NSArray *)original
{
	if ([original count] == 0)
		[NSException raise:@"Invalid image array" format:@"Trying to copy an empty image array"];
	
	baseSize = CGSizeZero;
	NSUInteger i = 0, n = [original count];
	NSMutableArray *copy = [NSMutableArray arrayWithCapacity:n];
	
	do {
		NSImage *curImage = [original objectAtIndex:i];
		if (![curImage isKindOfClass:[NSImage class]])
			[NSException raise:@"Invalid image array" format:@"Trying to copy an image array whose element #%d is not kind of class NSImage (it is: %@)", i, NSStringFromClass([curImage class])];
		
		if (i == 0) baseSize = [curImage size];
		if (CGSizeEqualToSize(baseSize, CGSizeZero))
			[NSException raise:@"Invalid image array" format:@"Trying to copy an image array whose first element is of size zero"];
		if (!CGSizeEqualToSize([curImage size], baseSize))
			[NSException raise:@"Invalid image array" format:@"Trying to copy an image array whose element #%d is not the same size of the previous elements", i];
		
		[copy addObject:[curImage copy]];
	} while (++i < n);
	
	return [copy copy];
}

@end
