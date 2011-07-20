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
		scaleFactor = CGSizeMake(1., 1.);
		
		animating = NO;
		curCPULoad = 0.;
		destCPULoad = 0.;
		curFrameNumber = 0;
		animTimer = nil;
		
		skinMelter = [FLSkinMelter new];
	}
	
	return self;
}

- (void)dealloc
{
	[animTimer invalidate];
	[animTimer release];
	
	[skin release];
	[skinMelter release];
	
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
	
	[skinMelter setSkin:skin];
	[self setScaleFactor:scaleFactor]; /* Will refresh the skin melter and the self size */
	
	if (animating) {
		animating = NO;
		[animTimer invalidate]; [animTimer release]; animTimer = nil;
		[self setCurCPULoad:destCPULoad];
	}
	
	[self setNeedsDisplay:YES];
}

- (CGSize)scaleFactor
{
	return scaleFactor;
}

- (void)setScaleFactor:(CGSize)scale
{
	scaleFactor = scale;
	
	NSSize newSize = NSMakeSize(skin.imagesSize.width * scaleFactor.width, skin.imagesSize.height * scaleFactor.height);
	if (newSize.width < 3.) {
		CGFloat s = 3./skin.imagesSize.width;
		newSize.width = 3.;
		newSize.height = skin.imagesSize.height * s;
	}
	if (newSize.height < 19.) {
		CGFloat s = 19./skin.imagesSize.height;
		newSize.height = 19.;
		newSize.width = skin.imagesSize.width * s;
	}
	[skinMelter setDestSize:newSize];
	
	[parentWindow setContentSize:newSize];
	[parentWindow invalidateShadow];
	
	NSRect f = self.frame;
	f.size = newSize;
	self.frame = f;
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
	CGFloat newCPULoad = CPULoad;
	if (stickToImages) {
		CGFloat f = CPULoad * ((CGFloat)skin.nImages-1.);
		NSUInteger imageIdx = f;
		newCPULoad = ((CGFloat)imageIdx) / ((CGFloat)skin.nImages-1.);
	}
	
	if (!flag) {
		animating = NO;
		[animTimer invalidate]; [animTimer release]; animTimer = nil;
		[self setCurCPULoad:newCPULoad];
		
		return;
	}
	
	CGFloat prevDestCPULoad = destCPULoad;
	destCPULoad = newCPULoad;
	
	if (destCPULoad == prevDestCPULoad) return;
	
	curFrameNumber = 0;
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
	[[skinMelter imageForCPULoad:curCPULoad] drawAtPoint:NSZeroPoint];
	[parentWindow invalidateShadow];
}

@end
