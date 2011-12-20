/*
 * FLCPUIndicatorWindowController.h
 * CPU Indicator
 *
 * Created by François LAMBOLEY on 12/20/11.
 * Copyright (c) 2011 Frost Land. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

#import "FLSkinManager.h"
#import "FLCPUIndicatorView.h"

@interface FLCPUIndicatorWindowController : NSWindowController {
@private
	BOOL inObserver;
	
	BOOL animateCPUChangeTransition;
	
	FLSkinManager *skinManager;
	FLCPUIndicatorView *cpuIndicatorView;
}
@property(retain) FLSkinManager *skinManager;
@property(retain) IBOutlet FLCPUIndicatorView *cpuIndicatorView;

- (void)showWindowIfNeeded:(BOOL)firstRun;
- (IBAction)moveWindowToTopLeft:(id)sender;
- (IBAction)moveWindowToPseudoTopLeft:(id)sender;
- (IBAction)moveWindowToTopRight:(id)sender;
- (IBAction)moveWindowToPseudoTopRight:(id)sender;
- (IBAction)moveWindowToBottomLeft:(id)sender;
- (IBAction)moveWindowToPseudoBottomLeft:(id)sender;
- (IBAction)moveWindowToBottomRight:(id)sender;
- (IBAction)moveWindowToPseudoBottomRight:(id)sender;

@end
