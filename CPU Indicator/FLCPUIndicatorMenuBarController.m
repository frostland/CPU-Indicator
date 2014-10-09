/*
 * FLCPUIndicatorMenuBarController.m
 * CPU Indicator
 *
 * Created by François LAMBOLEY on 12/21/11.
 * Copyright (c) 2011 Frost Land. All rights reserved.
 */

#import "FLCPUIndicatorMenuBarController.h"

#import "FLGlobals.h"
#import "FLConstants.h"
#import "FLMenuIndicatorView.h"

@implementation FLCPUIndicatorMenuBarController

static CGFloat menuHeight = 0.;
/* Replaced by [NSFont menuBarFontOfSize:0] */
//static NSFont *menuTitleFont = nil;

@synthesize menu;
@synthesize skinManager;

+ (void)initialize
{
	menuHeight = [[NSStatusBar systemStatusBar] thickness];
	
	/* Dirty hack to get the font of the title of a status item */
/*	NSStatusItem *statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:0.];
	
	statusItem.view = [[NSView new] autorelease];
	NSView *parent = [statusItem.view superview];
	statusItem.view = nil;
	
	statusItem.title = @"paozieur";
	for (NSButton *curView in parent.subviews) {
		if ([curView isKindOfClass:[NSButton class]]) {
			if (menuTitleFont != nil) NSLog(@"*** Warning: will set menuTitleFont but menuTitleFont is not nil!");
			menuTitleFont = [curView font];
		}
	}
	
	[[NSStatusBar systemStatusBar] removeStatusItem:statusItem];*/
}

- (id)init
{
	if ((self = [super init]) != nil) {
		[[NSBundle mainBundle] loadNibFile:@"FLCPUIndicatorMenuBar" externalNameTable:[NSDictionary dictionaryWithObject:self forKey:NSNibOwner] withZone:nil];
		
		NSUserDefaultsController *udc = [NSUserDefaultsController sharedUserDefaultsController];
		[udc addObserver:self forKeyPath:@"values."FL_UDK_ONE_MENU_PER_CPU  options:0 context:@selector(updateShowMultipleMenusFromUserDefaults)];
		[udc addObserver:self forKeyPath:@"values."FL_UDK_MENU_MODE         options:0 context:@selector(updateMenuModeFromUserDefaults)];
		[udc addObserver:self forKeyPath:@"values."FL_UDK_SELECTED_SKIN     options:0 context:@selector(updateSkinFromUserDefaults)];
		[udc addObserver:self forKeyPath:@"values."FL_UDK_MIXED_IMAGE_STATE options:0 context:@selector(updateMixedImageStateFromUserDefaults)];
		[udc addObserver:self forKeyPath:@"values."FL_UDK_SHOW_MENU         options:0 context:@selector(updateShowMenuFromUserDefaults)];
		
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(cpuUsageUpdated:) name:FL_NTF_CPU_USAGE_UPDATED object:nil];
	}
	
	return self;
}

- (void)dealloc
{
	self.menu = nil;
	self.skinManager = nil;
	[statusItems release]; statusItems = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	for (NSString *keyPath in @[@"values."FL_UDK_ONE_MENU_PER_CPU, @"values."FL_UDK_MENU_MODE, @"values."FL_UDK_SELECTED_SKIN,
										 @"values."FL_UDK_MIXED_IMAGE_STATE, @"values."FL_UDK_SHOW_MENU]) {
		[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:keyPath];
	}
	
	[super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	[self performSelector:context];
}

- (void)updateShowMenuFromUserDefaults
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	if ([ud boolForKey:FL_UDK_SHOW_MENU]) [self showStatusItem];
	else                                  [self hideStatusItem];
}

- (void)updateMixedImageStateFromUserDefaults
{
	BOOL stick;
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	FLSkin *curSkin = [skinManager skinAtIndex:[ud integerForKey:FL_UDK_SELECTED_SKIN]];
	NSInteger state = [ud integerForKey:FL_UDK_MIXED_IMAGE_STATE];
	
	if (state == FLMixedImageStateFromSkin) state = [curSkin mixedImageState];
	stick = (state != FLMixedImageStateAllow);
	for (NSUInteger i = 0; i < statusItems.count; ++i) {
		NSStatusItem *statusItem = [statusItems objectAtIndex:i];
		FLMenuIndicatorView *curView = (FLMenuIndicatorView *)statusItem.view;
		NSAssert([curView isKindOfClass:[FLMenuIndicatorView class]], @"The view of status item is not correct");
		[curView.cpuIndicatorView setSkin:curSkin];
		[curView.cpuIndicatorView setStickToImages:stick];
		[curView refreshSize];
	}
	
	animateCPUChangeTransition = (state != FLMixedImageStateDisallow);
}

- (void)updateSkinFromUserDefaults
{
	[self updateMixedImageStateFromUserDefaults];
}

- (void)updateMenuModeFromUserDefaults
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	NSInteger mode = [ud integerForKey:FL_UDK_MENU_MODE];
	for (NSUInteger i = 0; i < statusItems.count; ++i) {
		NSStatusItem *statusItem = [statusItems objectAtIndex:i];
		FLMenuIndicatorView *curView = (FLMenuIndicatorView *)statusItem.view;
		NSAssert([curView isKindOfClass:[FLMenuIndicatorView class]], @"The view of status item is not correct");
		[curView setShowsText:(mode == FLMenuModeTagText || mode == FLMenuModeTagBoth)];
		[curView setShowsImage:(mode == FLMenuModeTagImage || mode == FLMenuModeTagBoth)];
	}
}

- (void)updateShowMultipleMenusFromUserDefaults
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	if ([ud boolForKey:FL_UDK_SHOW_MENU]) [self showStatusItem];
}

- (void)cpuUsageUpdated:(NSNotification *)n
{
	BOOL oneMenu = ![[NSUserDefaults standardUserDefaults] boolForKey:FL_UDK_ONE_MENU_PER_CPU];
	for (NSUInteger i = 0; i < MIN(oneMenu? 1: nCPUs, statusItems.count); ++i) {
		NSStatusItem *statusItem = [statusItems objectAtIndex:i];
		FLMenuIndicatorView *curView = (FLMenuIndicatorView *)statusItem.view;
		NSAssert([curView isKindOfClass:[FLMenuIndicatorView class]], @"The view of status item is not correct");
		[curView setCurCPULoad:(oneMenu? globalCPUUsage: CPUUsages[i]) animated:animateCPUChangeTransition];
	}
}

- (void)showStatusItem
{
	NSUInteger n = ([[NSUserDefaults standardUserDefaults] boolForKey:FL_UDK_ONE_MENU_PER_CPU]? nCPUs: 1);
	if (statusItems.count == n) return;
	[self hideStatusItem];
	
	statusItems = [[NSMutableArray alloc] initWithCapacity:nCPUs];
	for (NSUInteger i = 0; i < n; ++i) {
		NSStatusItem *statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
		statusItem.highlightMode = YES;
		statusItem.menu = [[menu copy] autorelease];
		[statusItem.menu itemWithTag:42].title = [NSString stringWithFormat:NSLocalizedString(@"proc %lu", nil), (unsigned long)(i+1)];
		statusItem.view = [FLMenuIndicatorView menuIndicatorViewWithFont:[NSFont menuBarFontOfSize:0.] statusItem:statusItem andHeight:menuHeight];
		[statusItems addObject:statusItem];
	}
	
	[self updateMenuModeFromUserDefaults];
	[self updateSkinFromUserDefaults];
	[self cpuUsageUpdated:nil];
}

- (void)hideStatusItem
{
	for (NSStatusItem *curItem in statusItems) [[NSStatusBar systemStatusBar] removeStatusItem:curItem];
	[statusItems release];
	statusItems = nil;
}

- (void)showStatusItemIfNeeded
{
	[self updateShowMenuFromUserDefaults];
}

@end
