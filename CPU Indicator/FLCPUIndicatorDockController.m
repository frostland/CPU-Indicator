/*
 * FLCPUIndicatorDockController.m
 * CPU Indicator
 *
 * Created by François LAMBOLEY on 12/23/11.
 * Copyright (c) 2011 Frost Land. All rights reserved.
 */

#import "FLCPUIndicatorDockController.h"

#import "FLGlobals.h"
#import "FLConstants.h"

@implementation FLCPUIndicatorDockController

@synthesize skinManager;

- (id)init
{
	if ((self = [super init]) != nil) {
		cpuIndicatorView = [[FLCPUIndicatorView alloc] initWithFrame:NSMakeRect(0., 0., 512., 512.)];
		cpuIndicatorView.delegate = self;
		
		NSUserDefaultsController *udc = [NSUserDefaultsController sharedUserDefaultsController];
		[udc addObserver:self forKeyPath:@"values."FL_UDK_SHOW_INDICATOR_IN_DOCK options:0 context:@selector(updateShowIndicatorInDockFromUserDefaults)];
		[udc addObserver:self forKeyPath:@"values."FL_UDK_SELECTED_SKIN          options:0 context:@selector(updateSkinFromUserDefaults)];
		[udc addObserver:self forKeyPath:@"values."FL_UDK_MIXED_IMAGE_STATE      options:0 context:@selector(updateMixedImageStateFromUserDefaults)];
		
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(cpuUsageUpdated:) name:FL_NTF_CPU_USAGE_UPDATED object:nil];
	}
	
	return self;
}

- (void)dealloc
{
	[cpuIndicatorView release]; cpuIndicatorView = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self];
	
	[super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	[self performSelector:context];
}

- (void)updateMixedImageStateFromUserDefaults
{
	BOOL stick;
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	FLSkin *curSkin = [skinManager skinAtIndex:[ud integerForKey:FL_UDK_SELECTED_SKIN]];
	NSInteger state = [ud integerForKey:FL_UDK_MIXED_IMAGE_STATE];
	
	if (state == FLMixedImageStateFromSkin) state = [curSkin mixedImageState];
	stick = (state != FLMixedImageStateAllow);
	[cpuIndicatorView setSkin:curSkin];
	[cpuIndicatorView setStickToImages:stick];
	
	animateCPUChangeTransition = (state != FLMixedImageStateDisallow);
}

- (void)updateSkinFromUserDefaults
{
	[self updateMixedImageStateFromUserDefaults];
}

- (void)cpuUsageUpdated:(NSNotification *)notif
{
	[cpuIndicatorView setCurCPULoad:globalCPUUsage animated:animateCPUChangeTransition];
}

- (void)updateShowIndicatorInDockFromUserDefaults
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	[[NSApp dockTile] setContentView:[ud boolForKey:FL_UDK_SHOW_INDICATOR_IN_DOCK]? cpuIndicatorView: nil];
	[self updateSkinFromUserDefaults];
	[self cpuUsageUpdated:nil];
}

- (void)showDockStatusIfNeeded
{
	[self updateShowIndicatorInDockFromUserDefaults];
}

- (void)cpuIndicatorViewDidDraw:(FLCPUIndicatorView *)v
{
}

- (void)cpuIndicatorViewDidSetNeedDisplay:(FLCPUIndicatorView *)v
{
	[[NSApp dockTile] display];
}

@end
