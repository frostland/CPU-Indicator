/*
 * FLCPUIndicatorMenuBarController.h
 * CPU Indicator
 *
 * Created by François LAMBOLEY on 12/21/11.
 * Copyright (c) 2011 Frost Land. All rights reserved.
 */

#import <Foundation/Foundation.h>

#import "FLSkinManager.h"

@interface FLCPUIndicatorMenuBarController : NSObject {
	NSMenu *menu;
	
	NSMutableArray *statusItems;
	
	FLSkinManager *skinManager;
	BOOL animateCPUChangeTransition;
}
@property(retain) FLSkinManager *skinManager;
@property(retain) IBOutlet NSMenu *menu;

- (void)showStatusItem;
- (void)hideStatusItem;

- (void)showStatusItemIfNeeded;

@end
