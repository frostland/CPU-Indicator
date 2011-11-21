/*
 * FLCPUIndicatorView.h
 * CPU Indicator
 *
 * Created by François LAMBOLEY on 3/6/11.
 * Copyright 2011 Frost Land. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

#import "FLSkin.h"
#import "FLSkinMelter.h"

#define ANIM_DURATION (1.5)
#define FPS (21)
#define NFRAME ((NSUInteger)(ANIM_DURATION * FPS))

@interface FLCPUIndicatorView : NSView {
@private
	NSWindow *parentWindow;
	
	FLSkin *skin;
	BOOL stickToImages;
	CGSize scaleFactor;
	
	CGFloat curCPULoad;
	CGFloat destCPULoad;
	CGFloat CPULoadIncrement;
	
	BOOL animating;
	NSTimer *animTimer;
	NSUInteger curFrameNumber;
	
	FLSkinMelter *skinMelter;
}
@property(assign) IBOutlet NSWindow *parentWindow;

@property(retain) FLSkin *skin;
@property(assign) BOOL stickToImages;
@property(assign) CGSize scaleFactor;

@property(assign) CGFloat curCPULoad;
- (void)setCurCPULoad:(CGFloat)CPULoad animated:(BOOL)flag;

@end
