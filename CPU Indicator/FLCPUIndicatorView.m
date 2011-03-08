//
//  FLCPUIndicatorView.m
//  CPU Indicator
//
//  Created by François LAMBOLEY on 3/6/11.
//  Copyright 2011 Frost Land. All rights reserved.
//

#import "FLCPUIndicatorView.h"

@implementation FLCPUIndicatorView

@synthesize parentWindow;
@synthesize stickToImages;

- (id)initWithFrame:(NSRect)frame
{
	frame.size = NSZeroSize;
	if ((self = [super initWithFrame:frame]) != nil) {
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

- (FLSkin *)skin
{
	return skin;
}

- (void)setSkin:(FLSkin *)newSkin
{
	if (newSkin == skin) return;
	
	[skin release];
	skin = [newSkin retain];
	
	[parentWindow setContentSize:skin.imagesSize];
	[parentWindow invalidateShadow];
	
	NSRect f = self.frame;
	f.size = skin.imagesSize;
	self.frame = f;
	
	if (animating) {
		animating = NO;
		[animTimer invalidate]; [animTimer release]; animTimer = nil;
		[self setCurCPULoad:destCPULoad];
	}
	
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
		CGFloat f = CPULoad * ((CGFloat)skin.nImages-1.);
		NSUInteger imageIdx = f;
		destCPULoad = ((CGFloat)imageIdx) / ((CGFloat)skin.nImages-1.) + .001;
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
	CGFloat f = curCPULoad * ((CGFloat)skin.nImages-1.);
	NSUInteger imageIdx = f + 1;
	
	if (imageIdx < skin.nImages) {
		[[skin.images objectAtIndex:imageIdx] dissolveToPoint:NSZeroPoint fraction:1.];
		if (imageIdx - 1 < [skin.images count])
			[[skin.images objectAtIndex:imageIdx - 1] dissolveToPoint:NSZeroPoint fraction:imageIdx - f];
	} else [[skin.images lastObject] dissolveToPoint:NSZeroPoint fraction:1.];
	
	[parentWindow invalidateShadow];
}

@end
