/*
 * FLCPUIndicatorView.m
 * CPU Indicator
 *
 * Created by François LAMBOLEY on 3/6/11.
 * Copyright 2011 Frost Land. All rights reserved.
 */

#import "FLCPUIndicatorView.h"

@implementation FLCPUIndicatorView

@synthesize delegate;
@synthesize stickToImages, ignoreClicks;

- (instancetype)initWithFrame:(NSRect)frame
{
	if ((self = [super initWithFrame:frame]) != nil) {
		destDrawRect = self.bounds;
		
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
	self.delegate = nil;
	
	[animTimer invalidate];
	[animTimer release];
	
	[skin release];
	[skinMelter release];
	
	[super dealloc];
}

- (void)updateSkinMelterDestSizeAndSelfDestDrawRect
{
	[skinMelter setDestSize:self.bounds.size];
	
	destDrawRect = self.bounds;
	destDrawRect.origin.x += (self.bounds.size.width  - skinMelter.finalSize.width)/2.;
	destDrawRect.origin.y += (self.bounds.size.height - skinMelter.finalSize.height)/2.;
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
	[self updateSkinMelterDestSizeAndSelfDestDrawRect];
	
	if (animating) {
		animating = NO;
		[animTimer invalidate]; [animTimer release]; animTimer = nil;
		[self setCurCPULoad:destCPULoad];
	}
	
	[self setNeedsDisplay:YES];
	[self.delegate cpuIndicatorViewDidSetNeedDisplay:self];
}

- (CGFloat)curCPULoad
{
	return curCPULoad;
}

- (void)setCurCPULoad:(CGFloat)CPULoad
{
	curCPULoad = CPULoad;
	
	[self setNeedsDisplay:YES];
	[self.delegate cpuIndicatorViewDidSetNeedDisplay:self];
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
	[self updateSkinMelterDestSizeAndSelfDestDrawRect];
}

- (void)setBounds:(NSRect)aRect
{
	[super setBounds:aRect];
	[self updateSkinMelterDestSizeAndSelfDestDrawRect];
}

- (NSView *)hitTest:(NSPoint)aPoint
{
	NSView *hitView = [super hitTest:aPoint];
	return (ignoreClicks && hitView == self)? nil: hitView;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[[skinMelter imageForCPULoad:curCPULoad] drawInRect:destDrawRect fromRect:self.bounds
															operation:NSCompositeSourceOver fraction:1.
													 respectFlipped:YES hints:nil];
	[self.delegate cpuIndicatorViewDidDraw:self];
}

@end
