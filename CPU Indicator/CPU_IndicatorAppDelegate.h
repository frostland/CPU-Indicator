/*
 * CPU_IndicatorAppDelegate.h
 * CPU Indicator
 *
 * Created by François LAMBOLEY on 2/27/11.
 * Copyright 2011 Frost Land. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

#import "FLSkinManager.h"
#import "FLBorderlessWindow.h"
#import "FLCPUIndicatorView.h"
#import "FLPreferencesController.h"

@interface CPU_IndicatorAppDelegate : NSObject <NSApplicationDelegate> {
@private
	NSWindow *welcomeWindow;
	FLBorderlessWindow *window;
	FLCPUIndicatorView *cpuIndicatorView;
	FLPreferencesController *preferencesController;
	
	FLSkinManager *skinManager;
	
	CGFloat knownCPUUsage;
	BOOL animateTransition;
}
@property (assign) IBOutlet NSWindow *welcomeWindow;
@property (assign) IBOutlet FLBorderlessWindow *window;
@property (assign) IBOutlet FLCPUIndicatorView *cpuIndicatorView;

- (IBAction)showPreferences:(id)sender;
- (IBAction)closeWelcomeWindow:(id)sender;
- (IBAction)closeWelcomeWindowAndShowPrefs:(id)sender;

@end
