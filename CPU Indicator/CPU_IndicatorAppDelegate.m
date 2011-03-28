//
//  CPU_IndicatorAppDelegate.m
//  CPU Indicator
//
//  Created by François LAMBOLEY on 2/27/11.
//  Copyright 2011 Frost Land. All rights reserved.
//

#import "CPU_IndicatorAppDelegate.h"

#import "FLConstants.h"
#include <mach/mach.h>

#define FL_CPU_COMPUTE_INTERVAL (1.5)

@interface CPU_IndicatorAppDelegate (Private)

- (void)userDefaultsChanged:(NSNotification *)n;

@end

@implementation CPU_IndicatorAppDelegate

@synthesize welcomeWindow, window, cpuIndicatorView;

+ (void)initialize
{
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	
	[defaultValues setValue:@"" forKey:FL_UDK_LAST_SELECTED_PREF_ID];
	[defaultValues setValue:[NSNumber numberWithBool:YES]    forKey:FL_UDK_FIRST_RUN];
	[defaultValues setValue:[NSNumber numberWithBool:NO]     forKey:FL_UDK_DISALLOW_SHADOW];
	[defaultValues setValue:[NSNumber numberWithBool:YES]    forKey:FL_UDK_STICK_TO_IMAGES];
	[defaultValues setValue:[NSNumber numberWithBool:YES]    forKey:FL_UDK_ALLOW_WINDOW_DRAG_N_DROP];
	[defaultValues setValue:[NSNumber numberWithFloat:1.]    forKey:FL_UDK_WINDOW_TRANSPARENCY];
	[defaultValues setValue:[NSNumber numberWithFloat:1.]    forKey:FL_UDK_SKIN_X_SCALE];
	[defaultValues setValue:[NSNumber numberWithFloat:1.]    forKey:FL_UDK_SKIN_Y_SCALE];
	[defaultValues setValue:[NSNumber numberWithInteger:0]   forKey:FL_UDK_SELECTED_SKIN];
	[defaultValues setValue:[NSMutableDictionary dictionary] forKey:FL_UDK_PREFS_PANES_SIZES];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	if (skinManager == nil) skinManager = [FLSkinManager new];
/*	[NSArchiver archiveRootObject:
	 [[[FLSkin alloc] initWithImages:[NSArray arrayWithObjects:
												 [[[NSImage alloc] initWithContentsOfFile:@"/Users/frizlab/Desktop/Babes/babe0.png"] autorelease],
												 [[[NSImage alloc] initWithContentsOfFile:@"/Users/frizlab/Desktop/Babes/babe1.png"] autorelease],
												 [[[NSImage alloc] initWithContentsOfFile:@"/Users/frizlab/Desktop/Babes/babe2.png"] autorelease],
												 [[[NSImage alloc] initWithContentsOfFile:@"/Users/frizlab/Desktop/Babes/babe3.png"] autorelease],
												 [[[NSImage alloc] initWithContentsOfFile:@"/Users/frizlab/Desktop/Babes/babe4.png"] autorelease],
												 nil]] autorelease]
								  toFile:@"/Users/frizlab/Desktop/tt.cpuIndicatorSkin"];*/
	
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	if ([ud boolForKey:FL_UDK_FIRST_RUN]) {
		[ud setBool:NO forKey:FL_UDK_FIRST_RUN];
		
		NSRect screenRect = [[window screen] visibleFrame];
		NSRect f = [window frame];
		f.origin.x = screenRect.origin.x + screenRect.size.width - f.size.width;
		f.origin.y = screenRect.origin.y + screenRect.size.height - f.size.height;
		[window setFrame:f display:YES animate:NO];
		[welcomeWindow setLevel:NSStatusWindowLevel];
		[welcomeWindow setBackgroundColor:[NSColor whiteColor]];
		[welcomeWindow makeKeyAndOrderFront:nil];
	}
	
	[window orderFront:nil];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(userDefaultsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];
	
	[[NSTimer scheduledTimerWithTimeInterval:FL_CPU_COMPUTE_INTERVAL target:self selector:@selector(refreshKnownCPUUsage:) userInfo:NULL repeats:YES] fire];
	
	[self userDefaultsChanged:nil];
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

- (void)userDefaultsChanged:(NSNotification *)n
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	
	[window setHasShadow:![ud boolForKey:FL_UDK_DISALLOW_SHADOW]];
	[window setAllowDragNDrop:[ud boolForKey:FL_UDK_ALLOW_WINDOW_DRAG_N_DROP]];
	[window setAlphaValue:[ud floatForKey:FL_UDK_WINDOW_TRANSPARENCY]];
	[cpuIndicatorView setStickToImages:[ud boolForKey:FL_UDK_STICK_TO_IMAGES]];
	[cpuIndicatorView setSkin:[skinManager skinAtIndex:[ud integerForKey:FL_UDK_SELECTED_SKIN]]];
	[cpuIndicatorView setScaleFactor:CGSizeMake([ud floatForKey:FL_UDK_SKIN_X_SCALE], [ud floatForKey:FL_UDK_SKIN_Y_SCALE])];
}

- (IBAction)showPreferences:(id)sender
{
	if (preferencesController == nil) {
		preferencesController = [[FLPreferencesController alloc] initWithWindowNibName:@"FLPreferences"];
		preferencesController.skinManager = skinManager;
		preferencesController.cpuIndicatorWindow = window;
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
	[preferencesController release];
	
	[super dealloc];
}

- (void)refreshKnownCPUUsage:(NSTimer *)t
{
	natural_t cpuCount;
	processor_info_array_t infoArray;
	mach_msg_type_number_t infoCount;
	
	/* The total ticks are integer, but we will use them in division,
	 * so we need floats. We do not need ticks numbers as integers */
	CGFloat totalTicks, totalTicksNoIdle;
	static CGFloat previousTotalTicks = 0, previousTotalTicksNoIdle = 0;
	kern_return_t error = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &cpuCount, &infoArray, &infoCount);
	if (error) {
		mach_error("host_processor_info error:", error);
		return;
	}
	
	totalTicks = totalTicksNoIdle = 0.;
	processor_cpu_load_info_data_t *cpuLoadInfo = (processor_cpu_load_info_data_t *)infoArray;
	for (natural_t cpu = 0; cpu < cpuCount; ++cpu) {
		for (NSUInteger state = 0; state < CPU_STATE_MAX; ++state) {
			/* Ticks states are, in that order: "user", "system", "idle", "nice" */
			unsigned long ticks = cpuLoadInfo[cpu].cpu_ticks[state];
			totalTicks += ticks;
			if (state != 2) totalTicksNoIdle += ticks;
		}
	}
	
	knownCPUUsage = (totalTicksNoIdle - previousTotalTicksNoIdle)/(totalTicks - previousTotalTicks);
//	NSLog(@"Current CPU Usage: %g", knownCPUUsage);
	
	previousTotalTicks = totalTicks;
	previousTotalTicksNoIdle = totalTicksNoIdle;
	vm_deallocate(mach_task_self(), (vm_address_t)infoArray, infoCount);
	
	[cpuIndicatorView setCurCPULoad:knownCPUUsage animated:YES];
}

@end
