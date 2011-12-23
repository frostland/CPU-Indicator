/*
 * CPU_IndicatorAppDelegate.m
 * CPU Indicator
 *
 * Created by François LAMBOLEY on 2/27/11.
 * Copyright 2011 Frost Land. All rights reserved.
 */

#import "CPU_IndicatorAppDelegate.h"

#import "FLUtils.h"
#import "FLConstants.h"
/*	[NSArchiver archiveRootObject:
	 [[[FLSkin alloc] initWithImages:[NSArray arrayWithObjects:
												 [[[NSImage alloc] initWithContentsOfFile:@"/Users/frizlab/Desktop/Babes/babe0.png"] autorelease],
												 [[[NSImage alloc] initWithContentsOfFile:@"/Users/frizlab/Desktop/Babes/babe1.png"] autorelease],
												 [[[NSImage alloc] initWithContentsOfFile:@"/Users/frizlab/Desktop/Babes/babe2.png"] autorelease],
												 [[[NSImage alloc] initWithContentsOfFile:@"/Users/frizlab/Desktop/Babes/babe3.png"] autorelease],
												 [[[NSImage alloc] initWithContentsOfFile:@"/Users/frizlab/Desktop/Babes/babe4.png"] autorelease],
												 nil]
						  mixedImageState:FLMixedImageStateTransitionsOnly] autorelease]
								  toFile:@"/Users/frizlab/Desktop/tt.cpuIndicatorSkin"];*/

#define FL_CPU_COMPUTE_INTERVAL (1.5)

@interface CPU_IndicatorAppDelegate (Private)

@end

@implementation CPU_IndicatorAppDelegate

@synthesize welcomeWindow, cpuIndicatorView;

+ (void)initialize
{
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	
	[defaultValues setValue:[NSNumber numberWithBool:YES] forKey:FL_UDK_FIRST_RUN];
	
	[defaultValues setValue:[NSMutableDictionary dictionary] forKey:FL_UDK_PREFS_PANES_SIZES];
	[defaultValues setValue:@""                              forKey:FL_UDK_LAST_SELECTED_PREF_ID];
	
	[defaultValues setValue:[NSNumber numberWithBool:YES]                               forKey:FL_UDK_SHOW_WINDOW];
	[defaultValues setValue:[NSNumber numberWithInteger:FLWindowLevelMenuIndexAboveAll] forKey:FL_UDK_WINDOW_LEVEL];
	[defaultValues setValue:[NSNumber numberWithFloat:1.]                               forKey:FL_UDK_WINDOW_TRANSPARENCY];
	[defaultValues setValue:[NSNumber numberWithBool:NO]                                forKey:FL_UDK_DISALLOW_SHADOW];
	[defaultValues setValue:[NSNumber numberWithBool:YES]                               forKey:FL_UDK_ALLOW_WINDOW_DRAG_N_DROP];
	[defaultValues setValue:[NSNumber numberWithBool:NO]                                forKey:FL_UDK_IGNORE_MOUSE_CLICKS];
	
	[defaultValues setValue:[NSNumber numberWithBool:NO]                   forKey:FL_UDK_SHOW_MENU];
	[defaultValues setValue:[NSNumber numberWithInteger:FLMenuModeTagText] forKey:FL_UDK_MENU_MODE];
	[defaultValues setValue:[NSNumber numberWithBool:NO]                   forKey:FL_UDK_ONE_MENU_PER_CPU];
	
	[defaultValues setValue:[NSNumber numberWithBool:YES] forKey:FL_UDK_SHOW_DOCK];
	[defaultValues setValue:[NSNumber numberWithBool:NO]  forKey:FL_UDK_SHOW_INDICATOR_IN_DOCK];
	
	[defaultValues setValue:[NSNumber numberWithInteger:0]                         forKey:FL_UDK_SELECTED_SKIN];
	[defaultValues setValue:[NSNumber numberWithInteger:FLMixedImageStateFromSkin] forKey:FL_UDK_MIXED_IMAGE_STATE];
	[defaultValues setValue:[NSNumber numberWithFloat:1.]                          forKey:FL_UDK_SKIN_X_SCALE];
	[defaultValues setValue:[NSNumber numberWithFloat:1.]                          forKey:FL_UDK_SKIN_Y_SCALE];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
	[[NSTimer scheduledTimerWithTimeInterval:FL_CPU_COMPUTE_INTERVAL target:self selector:@selector(refreshKnownCPUUsage:) userInfo:NULL repeats:YES] fire];
	
	justLaunched = YES;
	dockIconShown = NO;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:FL_UDK_SHOW_DOCK]) {
		dockIconShown = YES;
		ProcessSerialNumber psn = {0, kCurrentProcess};
		OSStatus returnCode = TransformProcessType(&psn, kProcessTransformToForegroundApplication);
		if	(returnCode != 0) {} // Output error
	}
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	BOOL firstRun = [ud boolForKey:FL_UDK_FIRST_RUN];
	if (skinManager == nil) skinManager = [FLSkinManager new];
	
	NSAssert(mainWindowController == nil, @"Non-nil mainWindowController");
	mainWindowController = [[FLCPUIndicatorWindowController alloc] initWithWindowNibName:@"FLCPUIndicatorWindow"];
	mainWindowController.skinManager = skinManager;
	[mainWindowController showWindowIfNeeded:firstRun];
	
	NSAssert(menuBarController == nil, @"Non-nil mainWindowController");
	menuBarController = [FLCPUIndicatorMenuBarController new];
	menuBarController.skinManager = skinManager;
	[menuBarController showStatusItemIfNeeded];
	
	NSAssert(dockController == nil, @"Non-nil dockController");
	dockController = [FLCPUIndicatorDockController new];
	dockController.skinManager = skinManager;
	[dockController showDockStatusIfNeeded];
	
	if (firstRun) {
		[ud setBool:NO forKey:FL_UDK_FIRST_RUN];
		
		[welcomeWindow setLevel:NSStatusWindowLevel];
		[welcomeWindow makeKeyAndOrderFront:nil];
	}
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
	if (!dockIconShown && !justLaunched) [self showPreferences:self];
	justLaunched = NO;
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename
{
	if (skinManager == nil) skinManager = [FLSkinManager new];
	if (![skinManager installSkinAtPath:filename useIt:YES]) {
		[[NSAlert alertWithMessageText:NSLocalizedString(@"cannot import skin", nil)
							  defaultButton:NSLocalizedString(@"ok maj", nil) alternateButton:nil
								 otherButton:nil
			  informativeTextWithFormat:NSLocalizedString(@"cannot import skin. unknown error.", nil)] runModal];
	}
	
	[preferencesController reloadSkinList];
	return YES;
}

- (IBAction)showPreferences:(id)sender
{
	if (preferencesController == nil) {
		preferencesController = [[FLPreferencesController alloc] initWithWindowNibName:@"FLPreferences"];
		preferencesController.skinManager = skinManager;
		preferencesController.cpuIndicatorWindowController = mainWindowController;
	}
	
	[preferencesController showWindow:nil];
}

- (IBAction)closeWelcomeWindow:(id)sender
{
	[welcomeWindow close];
}

- (IBAction)closeWelcomeWindowAndShowPrefs:(id)sender
{
	[self closeWelcomeWindow:sender];
	[self showPreferences:sender];
}

- (void)dealloc
{
	[skinManager release];
	[menuBarController release];
	[mainWindowController release];
	[preferencesController release];
	
	[super dealloc];
}

- (void)refreshKnownCPUUsage:(NSTimer *)t
{
	FLRefreshKnownCPUUsage();
}

@end
