//
//  CPU_IndicatorAppDelegate.h
//  CPU Indicator
//
//  Created by François LAMBOLEY on 2/27/11.
//  Copyright 2011 Frost Land. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CPU_IndicatorAppDelegate : NSObject <NSApplicationDelegate> {
@private
	NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

@end
