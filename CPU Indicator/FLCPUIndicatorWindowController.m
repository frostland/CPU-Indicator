/*
 * FLCPUIndicatorWindowController.m
 * CPU Indicator
 *
 * Created by François LAMBOLEY on 12/20/11.
 * Copyright (c) 2011 Frost Land. All rights reserved.
 */

#import "FLCPUIndicatorWindowController.h"

#import "FLGlobals.h"
#import "FLConstants.h"

@implementation FLCPUIndicatorWindowController

@synthesize cpuIndicatorView, skinManager;

- (instancetype)initWithWindow:(NSWindow *)window
{
	if ((self = [super initWithWindow:window]) != nil) {
		NSUserDefaultsController *udc = [NSUserDefaultsController sharedUserDefaultsController];
		[udc addObserver:self forKeyPath:@"values."FL_UDK_WINDOW_LEVEL             options:0 context:@selector(updateWindowLevelFromUserDefaults)];
		[udc addObserver:self forKeyPath:@"values."FL_UDK_WINDOW_TRANSPARENCY      options:0 context:@selector(updateAlphaFromUserDefaults)];
		[udc addObserver:self forKeyPath:@"values."FL_UDK_IGNORE_MOUSE_CLICKS      options:0 context:@selector(updateIgnoreMouseEventsFromUserDefaults)];
		[udc addObserver:self forKeyPath:@"values."FL_UDK_ALLOW_WINDOW_DRAG_N_DROP options:0 context:@selector(updateAllowDragNDropFromUserDefaults)];
		[udc addObserver:self forKeyPath:@"values."FL_UDK_SKIN_X_SCALE             options:0 context:@selector(updateScaleFromUserDefaults)];
		/* Currently the X and Y scales are the same and updated at the same time. To avoid a double call to udpateScale* we only register the modification of the x scale */
/*		[udc addObserver:self forKeyPath:@"values."FL_UDK_SKIN_Y_SCALE             options:0 context:@selector(updateScaleFromUserDefaults)]; */
		[udc addObserver:self forKeyPath:@"values."FL_UDK_SELECTED_SKIN            options:0 context:@selector(updateSkinFromUserDefaults)];
		[udc addObserver:self forKeyPath:@"values."FL_UDK_MIXED_IMAGE_STATE        options:0 context:@selector(updateMixedImageStateFromUserDefaults)];
		[udc addObserver:self forKeyPath:@"values."FL_UDK_DISALLOW_SHADOW          options:0 context:@selector(updateWindowShadowFromUserDefaults)];
		[udc addObserver:self forKeyPath:@"values."FL_UDK_SHOW_WINDOW              options:0 context:@selector(showOrHideWindowFromUserDefaults)];
		
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(cpuUsageUpdated:) name:FL_NTF_CPU_USAGE_UPDATED object:nil];
	}
	
	return self;
}

- (void)dealloc
{
	self.skinManager = nil;
	self.cpuIndicatorView = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	for (NSString *keyPath in @[@"values."FL_UDK_WINDOW_LEVEL, @"values."FL_UDK_WINDOW_TRANSPARENCY, @"values."FL_UDK_IGNORE_MOUSE_CLICKS,
										 @"values."FL_UDK_ALLOW_WINDOW_DRAG_N_DROP, @"values."FL_UDK_SKIN_X_SCALE, @"values."FL_UDK_SELECTED_SKIN,
										 @"values."FL_UDK_MIXED_IMAGE_STATE, @"values."FL_UDK_DISALLOW_SHADOW, @"values."FL_UDK_SHOW_WINDOW]) {
		[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:keyPath];
	}
	
	[super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	[self performSelector:context];
}

- (void)showOrHideWindowFromUserDefaults
{
	if ([[NSUserDefaults standardUserDefaults] boolForKey:FL_UDK_SHOW_WINDOW]) [self showWindow:self];
	else                                                                       [self close];
}

- (void)updateIgnoreMouseEventsFromUserDefaults
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	[self.window setIgnoresMouseEvents:[ud boolForKey:FL_UDK_IGNORE_MOUSE_CLICKS]];
}

- (void)updateAllowDragNDropFromUserDefaults
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	[self.window setMovable:[ud boolForKey:FL_UDK_ALLOW_WINDOW_DRAG_N_DROP]];
}

- (void)updateAlphaFromUserDefaults
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	[self.window setAlphaValue:[ud floatForKey:FL_UDK_WINDOW_TRANSPARENCY]];
}

- (void)updateWindowShadowFromUserDefaults
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	[self.window setHasShadow:![ud boolForKey:FL_UDK_DISALLOW_SHADOW]];
}

- (void)updateScaleFromUserDefaults
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	FLSkin *curSkin = [skinManager skinAtIndex:[ud integerForKey:FL_UDK_SELECTED_SKIN]];
	NSSize s = NSMakeSize(curSkin.imagesSize.width  * [ud floatForKey:FL_UDK_SKIN_X_SCALE],
								 curSkin.imagesSize.height * [ud floatForKey:FL_UDK_SKIN_Y_SCALE]);
	CGFloat f = curSkin.imagesSize.width / curSkin.imagesSize.height;
	if (s.width  <  9.) {s.width  =  9.; s.height = s.width  / f;}
	if (s.height < 19.) {s.height = 19.; s.width  = s.height * f;}
	[self.window setContentSize:s];
}

- (void)updateMixedImageStateFromUserDefaults
{
	BOOL stick;
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	FLSkin *curSkin = [skinManager skinAtIndex:[ud integerForKey:FL_UDK_SELECTED_SKIN]];
	NSInteger state = [ud integerForKey:FL_UDK_MIXED_IMAGE_STATE];
	
	if (state == FLMixedImageStateFromSkin) state = [curSkin mixedImageState];
	stick = (state != FLMixedImageStateAllow);
	[cpuIndicatorView setStickToImages:stick];
	
	animateCPUChangeTransition = (state != FLMixedImageStateDisallow);
}

- (void)updateSkinFromUserDefaults
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	FLSkin *curSkin = [skinManager skinAtIndex:[ud integerForKey:FL_UDK_SELECTED_SKIN]];
	[cpuIndicatorView setSkin:curSkin];
	
	[self updateScaleFromUserDefaults];
	[self updateMixedImageStateFromUserDefaults];
}

- (void)updateWindowLevelFromUserDefaults
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	switch ([ud integerForKey:FL_UDK_WINDOW_LEVEL]) {
		case FLWindowLevelMenuIndexBehindAll:
			[ud setBool:YES forKey:FL_UDK_IGNORE_MOUSE_CLICKS];
			[ud setBool:NO forKey:FL_UDK_ALLOW_WINDOW_DRAG_N_DROP];
			[self.window setLevel:kCGDesktopWindowLevel];
			[self.window setCollectionBehavior:NSWindowCollectionBehaviorTransient|NSWindowCollectionBehaviorCanJoinAllSpaces];
			break;
		case FLWindowLevelMenuIndexNormal:
			[self.window setLevel:NSNormalWindowLevel];
			[self.window setCollectionBehavior:NSWindowCollectionBehaviorManaged|NSWindowCollectionBehaviorCanJoinAllSpaces];
			break;
		default:
			[self.window setLevel:NSStatusWindowLevel];
			[self.window setCollectionBehavior:NSWindowCollectionBehaviorStationary|NSWindowCollectionBehaviorCanJoinAllSpaces];
	}
}

- (void)cpuUsageUpdated:(NSNotification *)n
{
	[cpuIndicatorView setCurCPULoad:globalCPUUsage animated:animateCPUChangeTransition];
}

- (void)showWindowIfNeeded:(BOOL)firstRun
{
	if (firstRun) {
		NSRect screenRect = [[self.window screen] visibleFrame];
		NSRect f = [self.window frame];
		f.origin.x = screenRect.origin.x + screenRect.size.width - f.size.width;
		f.origin.y = screenRect.origin.y + screenRect.size.height - f.size.height;
		[self.window setFrame:f display:YES animate:NO];
	}
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:FL_UDK_SHOW_WINDOW])
		[self showWindow:self];
}

- (void)windowDidLoad
{
	cpuIndicatorView.delegate = self;
	
	[self.window setOpaque:NO];
	[self.window setBackgroundColor:[NSColor clearColor]];
	[self.window setMovableByWindowBackground:YES];
	
	[super windowDidLoad];
	
	[self updateAlphaFromUserDefaults];
	[self updateWindowLevelFromUserDefaults];
	[self updateWindowShadowFromUserDefaults];
	[self updateAllowDragNDropFromUserDefaults];
	[self updateIgnoreMouseEventsFromUserDefaults];
	
	[self updateSkinFromUserDefaults];
}

- (void)cpuIndicatorViewDidDraw:(FLCPUIndicatorView *)v
{
	[self.window invalidateShadow];
}

- (void)cpuIndicatorViewDidSetNeedDisplay:(FLCPUIndicatorView *)v
{
}

- (IBAction)moveWindowToTopLeft:(id)sender
{
	NSRect screenRect = [[self.window screen] frame];
	NSRect f = [self.window frame];
	f.origin.x = screenRect.origin.x;
	f.origin.y = screenRect.origin.y + screenRect.size.height - f.size.height;
	[self.window setFrame:f display:YES animate:YES];
}

- (IBAction)moveWindowToPseudoTopLeft:(id)sender
{
	NSRect screenRect = [[self.window screen] visibleFrame];
	NSRect f = [self.window frame];
	f.origin.x = screenRect.origin.x;
	f.origin.y = screenRect.origin.y + screenRect.size.height - f.size.height;
	[self.window setFrame:f display:YES animate:YES];
}

- (IBAction)moveWindowToTopRight:(id)sender
{
	NSRect screenRect = [[self.window screen] frame];
	NSRect f = [self.window frame];
	f.origin.x = screenRect.origin.x + screenRect.size.width - f.size.width;
	f.origin.y = screenRect.origin.y + screenRect.size.height - f.size.height;
	[self.window setFrame:f display:YES animate:YES];
}

- (IBAction)moveWindowToPseudoTopRight:(id)sender
{
	NSRect screenRect = [[self.window screen] visibleFrame];
	NSRect f = [self.window frame];
	f.origin.x = screenRect.origin.x + screenRect.size.width - f.size.width;
	f.origin.y = screenRect.origin.y + screenRect.size.height - f.size.height;
	[self.window setFrame:f display:YES animate:YES];
}

- (IBAction)moveWindowToBottomLeft:(id)sender
{
	NSRect screenRect = [[self.window screen] frame];
	NSRect f = [self.window frame];
	f.origin.x = screenRect.origin.x;
	f.origin.y = screenRect.origin.y;
	[self.window setFrame:f display:YES animate:YES];
}

- (IBAction)moveWindowToPseudoBottomLeft:(id)sender
{
	NSRect screenRect = [[self.window screen] visibleFrame];
	NSRect f = [self.window frame];
	f.origin.x = screenRect.origin.x;
	f.origin.y = screenRect.origin.y;
	[self.window setFrame:f display:YES animate:YES];
}

- (IBAction)moveWindowToBottomRight:(id)sender
{
	NSRect screenRect = [[self.window screen] frame];
	NSRect f = [self.window frame];
	f.origin.x = screenRect.origin.x + screenRect.size.width - f.size.width;
	f.origin.y = screenRect.origin.y;
	[self.window setFrame:f display:YES animate:YES];
}

- (IBAction)moveWindowToPseudoBottomRight:(id)sender
{
	NSRect screenRect = [[self.window screen] visibleFrame];
	NSRect f = [self.window frame];
	f.origin.x = screenRect.origin.x + screenRect.size.width - f.size.width;
	f.origin.y = screenRect.origin.y;
	[self.window setFrame:f display:YES animate:YES];
}

@end
