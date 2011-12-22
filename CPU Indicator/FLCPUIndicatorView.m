/*
 * FLCPUIndicatorView.m
 * CPU Indicator
 *
 * Created by François LAMBOLEY on 3/6/11.
 * Copyright 2011 Frost Land. All rights reserved.
 */

#import "FLCPUIndicatorView.h"

@implementation FLCPUIndicatorView

@synthesize stickToImages, ignoreClicks;

- (id)initWithFrame:(NSRect)frame
{
	if ((self = [super initWithFrame:frame]) != nil) {
		stickToImages = NO;
		
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
	[skinMelter setDestSize:self.bounds.size];
	
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

- (void)setFrame:(NSRect)frameRect
{
	[super setFrame:frameRect];
	[skinMelter setDestSize:self.bounds.size];
}

- (void)setBounds:(NSRect)aRect
{
	[super setBounds:aRect];
	[skinMelter setDestSize:self.bounds.size];
}

- (NSView *)hitTest:(NSPoint)aPoint
{
	NSView *hitView = [super hitTest:aPoint];
	return (ignoreClicks && hitView == self)? nil: hitView;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[[skinMelter imageForCPULoad:curCPULoad] drawInRect:self.bounds fromRect:self.bounds
															operation:NSCompositeSourceOver fraction:1.
													 respectFlipped:YES hints:nil];
	[self.window invalidateShadow];
}

@end
