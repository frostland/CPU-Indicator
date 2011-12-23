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

@class FLCPUIndicatorView;

@protocol FLCPUIndicatorViewDelegate <NSObject>
@required

- (void)cpuIndicatorViewDidDraw:(FLCPUIndicatorView *)v;
- (void)cpuIndicatorViewDidSetNeedDisplay:(FLCPUIndicatorView *)v;

@end

@interface FLCPUIndicatorView : NSView {
@private
	BOOL ignoreClicks;
	
	FLSkin *skin;
	BOOL stickToImages;
	
	CGFloat curCPULoad;
	CGFloat destCPULoad;
	CGFloat CPULoadIncrement;
	
	BOOL animating;
	NSTimer *animTimer;
	NSUInteger curFrameNumber;
	
	FLSkinMelter *skinMelter;
	
	id <FLCPUIndicatorViewDelegate> delegate;
}
@property(assign) id <FLCPUIndicatorViewDelegate> delegate;

@property(retain) FLSkin *skin;
@property(assign) BOOL stickToImages;

@property(assign) BOOL ignoreClicks;

@property(assign) CGFloat curCPULoad;
- (void)setCurCPULoad:(CGFloat)CPULoad animated:(BOOL)flag;

@end
