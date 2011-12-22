/*
 * FLMenuIndicatorView.h
 * CPU Indicator
 *
 * Created by François LAMBOLEY on 12/21/11.
 * Copyright (c) 2011 Frost Land. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

#import "FLCPUIndicatorView.h"

@class FLLabel;

@interface FLMenuIndicatorView : NSView <NSMenuDelegate> {
	CGFloat curCPULoad;
	FLLabel *labelForText;
	FLCPUIndicatorView *cpuIndicatorView;
	
	NSStatusItem *statusItem;
	
	BOOL textShown, imageShown;
	
@private
	BOOL mouseDown;
}
@property(retain) NSStatusItem *statusItem; /* Don't rely on the delegate of the menu of the status item you give, it will be changed */
@property(readonly) FLCPUIndicatorView *cpuIndicatorView;

+ (id)menuIndicatorViewWithFont:(NSFont *)font statusItem:(NSStatusItem *)si andHeight:(CGFloat)height;

- (id)initWithFrame:(NSRect)frame andFont:(NSFont *)font;

/* Call this after changing the CPU Indicator view's skin */
- (void)refreshSize;

- (void)setCurCPULoad:(CGFloat)load animated:(BOOL)animate;

- (void)setShowsText:(BOOL)show;
- (void)setShowsImage:(BOOL)show;

@end
