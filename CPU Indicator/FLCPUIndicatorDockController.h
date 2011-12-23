/*
 * FLCPUIndicatorDockController.h
 * CPU Indicator
 *
 * Created by François LAMBOLEY on 12/23/11.
 * Copyright (c) 2011 Frost Land. All rights reserved.
 */

#import <Foundation/Foundation.h>

#import "FLSkinManager.h"
#import "FLCPUIndicatorView.h"

@interface FLCPUIndicatorDockController : NSObject <FLCPUIndicatorViewDelegate> {
	FLSkinManager *skinManager;
	BOOL animateCPUChangeTransition;
	FLCPUIndicatorView *cpuIndicatorView;
}
@property(retain) FLSkinManager *skinManager;

- (void)showDockStatusIfNeeded;

@end
