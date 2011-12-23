/*
 * CPU_IndicatorAppDelegate.h
 * CPU Indicator
 *
 * Created by François LAMBOLEY on 2/27/11.
 * Copyright 2011 Frost Land. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

#import "FLSkinManager.h"
#import "FLCPUIndicatorView.h"
#import "FLPreferencesController.h"
#import "FLCPUIndicatorDockController.h"
#import "FLCPUIndicatorWindowController.h"
#import "FLCPUIndicatorMenuBarController.h"

@interface CPU_IndicatorAppDelegate : NSObject <NSApplicationDelegate> {
@private
	BOOL justLaunched;
	BOOL dockIconShown;
	NSWindow *welcomeWindow;
	FLCPUIndicatorWindowController *mainWindowController;
	FLCPUIndicatorMenuBarController *menuBarController;
	FLCPUIndicatorDockController *dockController;
	FLPreferencesController *preferencesController;
	
	FLSkinManager *skinManager;
	
	BOOL animateTransition;
}
@property (assign) IBOutlet NSWindow *welcomeWindow;

- (IBAction)showPreferences:(id)sender;
- (IBAction)closeWelcomeWindow:(id)sender;
- (IBAction)closeWelcomeWindowAndShowPrefs:(id)sender;

@end
