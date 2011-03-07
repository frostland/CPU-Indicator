//
//  CPU_IndicatorAppDelegate.h
//  CPU Indicator
//
//  Created by François LAMBOLEY on 2/27/11.
//  Copyright 2011 Frost Land. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "FLCPUIndicatorView.h"

@interface CPU_IndicatorAppDelegate : NSObject <NSApplicationDelegate> {
@private
	NSWindow *window;
	FLCPUIndicatorView *cpuIndicatorView;
	
	CGFloat knownCPUUsage;
}
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet FLCPUIndicatorView *cpuIndicatorView;

@end
