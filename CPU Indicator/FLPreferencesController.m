/*
 * FLPreferencesController.m
 * CPU Indicator
 *
 * Created by François LAMBOLEY on 3/7/11.
 * Copyright 2011 Frost Land. All rights reserved.
 */

#import "FLPreferencesController.h"

#import "FLConstants.h"
#import "FLDefaultPaths.h"
#import "FLSkinPreviewCell.h"

@interface FLPreferencesController (Private)

- (void)setMixedStateUserDefault:(FLSkinMixedImageState)state;

- (NSToolbarItem *)toolbarItemForIdentifier:(NSString *)identifier;
- (void)setWindowSizeForSelectedPrefTab;
//- (void)constrainWindowToMinSize;

- (void)invalidateCachedSkinMelters;
- (void)updateSkinUI;

@end

@implementation FLPreferencesController

@synthesize toolBar;
@synthesize skinManager, cpuIndicatorWindowController;

@synthesize sliderScale, popUpButtonMixedImageState;
@synthesize viewForDockPrefs, viewForSkinsPrefs, viewForWindowPrefs, viewForMenuBarPrefs;
@synthesize buttonRemoveSkin, buttonSelectSkin;
@synthesize tableViewForSkins;
@synthesize selectedPrefTab;

- (id)initWithWindow:(NSWindow *)window
{
	if ((self = [super initWithWindow:window]) != nil) {
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
																					 forKeyPath:@"values."FL_UDK_ALLOW_WINDOW_DRAG_N_DROP
																						 options:0
																						 context:NULL];
	}
	
	return self;
}

- (void)dealloc
{
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self];
	
	self.skinManager = nil;
	self.selectedPrefTab = nil;
	self.cpuIndicatorWindowController = nil;
	
	[cachedSkinMelters release]; cachedSkinMelters = nil;
	
	[super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	NSUserDefaults *sd = [NSUserDefaults standardUserDefaults];
	if ([sd boolForKey:FL_UDK_ALLOW_WINDOW_DRAG_N_DROP])
		[sd setBool:NO forKey:FL_UDK_IGNORE_MOUSE_CLICKS];
}

- (void)awakeFromNib
{
	[self invalidateCachedSkinMelters];
	
	[self.window setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
	
	minSizeForDockPrefs = [viewForDockPrefs frame].size;
	minSizeForSkinsPrefs = [viewForSkinsPrefs frame].size;
	minSizeForWindowPrefs = [viewForWindowPrefs frame].size;
	minSizeForMenuBarPrefs = [viewForMenuBarPrefs frame].size;
}

- (void)windowDidLoad
{
	[super windowDidLoad];
	
	/* Init the UI from user defaults */
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	
	[sliderScale setFloatValue:[ud floatForKey:FL_UDK_SKIN_X_SCALE]];
	[popUpButtonMixedImageState selectItemWithTag:[ud integerForKey:FL_UDK_MIXED_IMAGE_STATE]];
	
	[toolBar setSelectedItemIdentifier:[ud objectForKey:FL_UDK_LAST_SELECTED_PREF_ID]];
	
	self.selectedPrefTab = [toolBar selectedItemIdentifier];
	NSToolbarItem *selectedToolbarItem = [self toolbarItemForIdentifier:self.selectedPrefTab];
	if (selectedToolbarItem != nil) [self performSelector:[selectedToolbarItem action] withObject:self];
	else {
		[toolBar setSelectedItemIdentifier:[[[toolBar items] objectAtIndex:1] itemIdentifier]];
		[self selectSkinsPref:nil];
	}
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [skinManager nSkins];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if ([[tableColumn identifier] isEqualToString:@"check"]) {
		return row == [skinManager selectedSkinIndex]? [NSImage imageNamed:@"check_mark"] : nil;
	} else if ([[tableColumn identifier] isEqualToString:@"skin_name"]) {
		return [[skinManager skinAtIndex:row] name];
	} else if ([[tableColumn identifier] isEqualToString:@"skin_preview"]) {
		NSAssert([cachedSkinMelters count] == [skinManager nSkins], @"Invalid cached skin melters count. Got %d, but I have %d skins.", [cachedSkinMelters count], [skinManager nSkins]);
		
		FLSkinMelter *skinMelter = [cachedSkinMelters objectAtIndex:row];
		if ([skinMelter isEqual:[NSNull null]]) {
			skinMelter = [[FLSkinMelter new] autorelease];
			[skinMelter setSkin:[skinManager skinAtIndex:row]];
			[skinMelter setDestSize:NSMakeSize([tableColumn width], [tableView rowHeight])];
			[skinMelter imageForCPULoad:0]; /* Refreshes intern caches of the skin melter. Useful because the skin melter will be copied multiple times and the cache should be computed before it is copied */
			
			[cachedSkinMelters replaceObjectAtIndex:row withObject:skinMelter];
		}
		
		return skinMelter;
	} else {
		NSLog(@"*** Warning: unknown table column identifier %@ in table view datasource", [tableColumn identifier]);
	}
	
	return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	[self updateSkinUI];
}

- (IBAction)selectDockPref:(id)sender
{
	self.selectedPrefTab = [toolBar selectedItemIdentifier];
	[[NSUserDefaults standardUserDefaults] setObject:self.selectedPrefTab forKey:FL_UDK_LAST_SELECTED_PREF_ID];
	
	/* This panel is not resizable */
	[self.window setContentMaxSize:minSizeForDockPrefs];
	[self.window setContentMinSize:minSizeForDockPrefs];
	
	/* The two following lines are ordered correctly */
	[self.window setContentView:viewForDockPrefs];
	[self setWindowSizeForSelectedPrefTab];
}

- (IBAction)selectMenuBarPref:(id)sender
{
	self.selectedPrefTab = [toolBar selectedItemIdentifier];
	[[NSUserDefaults standardUserDefaults] setObject:self.selectedPrefTab forKey:FL_UDK_LAST_SELECTED_PREF_ID];
	
	/* This panel is not resizable */
	[self.window setContentMaxSize:minSizeForMenuBarPrefs];
	[self.window setContentMinSize:minSizeForMenuBarPrefs];
	
	/* The two following lines are ordered correctly */
	[self.window setContentView:viewForMenuBarPrefs];
	[self setWindowSizeForSelectedPrefTab];
}

- (IBAction)selectWindowPref:(id)sender
{
	self.selectedPrefTab = [toolBar selectedItemIdentifier];
	[[NSUserDefaults standardUserDefaults] setObject:self.selectedPrefTab forKey:FL_UDK_LAST_SELECTED_PREF_ID];
	
	/* This panel is not resizable in height */
	[self.window setContentMaxSize:NSMakeSize(CGFLOAT_MAX, minSizeForWindowPrefs.height)];
	[self.window setContentMinSize:minSizeForWindowPrefs];
	
	/* The two following lines are ordered correctly */
	[self.window setContentView:viewForWindowPrefs];
	[self setWindowSizeForSelectedPrefTab];
}

- (IBAction)selectSkinsPref:(id)sender
{
	self.selectedPrefTab = [toolBar selectedItemIdentifier];
	[[NSUserDefaults standardUserDefaults] setObject:self.selectedPrefTab forKey:FL_UDK_LAST_SELECTED_PREF_ID];
	
	[self.window setContentMinSize:minSizeForSkinsPrefs];
	[self.window setContentMaxSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
	
	/* The two following lines are ordered correctly */
	[self setWindowSizeForSelectedPrefTab];
	[self.window setContentView:viewForSkinsPrefs];
	
	[self updateSkinUI];
}

- (void)windowDidResize:(NSNotification *)notification
{
	if (self.selectedPrefTab == nil) return;
	
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary *sizes = [[[ud objectForKey:FL_UDK_PREFS_PANES_SIZES] mutableCopy] autorelease];
	
	if (sizes == nil) sizes = [NSMutableDictionary dictionary];
	[sizes setObject:NSStringFromSize([self.window contentRectForFrameRect:[self.window frame]].size) forKey:self.selectedPrefTab];
	[ud setObject:sizes forKey:FL_UDK_PREFS_PANES_SIZES];
}

- (IBAction)moveWindowToTopLeft:(id)sender
{
	[cpuIndicatorWindowController moveWindowToTopLeft:sender];
}

- (IBAction)moveWindowToPseudoTopLeft:(id)sender
{
	[cpuIndicatorWindowController moveWindowToPseudoTopLeft:sender];
}

- (IBAction)moveWindowToTopRight:(id)sender
{
	[cpuIndicatorWindowController moveWindowToTopRight:sender];
}

- (IBAction)moveWindowToPseudoTopRight:(id)sender
{
	[cpuIndicatorWindowController moveWindowToPseudoTopRight:sender];
}

- (IBAction)moveWindowToBottomLeft:(id)sender
{
	[cpuIndicatorWindowController moveWindowToBottomLeft:sender];
}

- (IBAction)moveWindowToPseudoBottomLeft:(id)sender
{
	[cpuIndicatorWindowController moveWindowToPseudoBottomLeft:sender];
}

- (IBAction)moveWindowToBottomRight:(id)sender
{
	[cpuIndicatorWindowController moveWindowToBottomRight:sender];
}

- (IBAction)moveWindowToPseudoBottomRight:(id)sender
{
	[cpuIndicatorWindowController moveWindowToPseudoBottomRight:sender];
}

- (IBAction)updateScale:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setFloat:[sliderScale floatValue] forKey:FL_UDK_SKIN_X_SCALE];
	[[NSUserDefaults standardUserDefaults] setFloat:[sliderScale floatValue] forKey:FL_UDK_SKIN_Y_SCALE];
}

- (IBAction)showSkinsOnTheNet:(id)sender
{
	[self close];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:FL_SKINS_ADDRESS]];
}

- (IBAction)addSkin:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setAllowedFileTypes:[NSArray arrayWithObject:@"cpuIndicatorSkin"]];
	[openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
		if (result != NSFileHandlingPanelOKButton) return;
		
		if (![skinManager installSkinAtPath:[[openPanel URL] path] useIt:NO]) {
			[[NSAlert alertWithMessageText:NSLocalizedString(@"cannot import skin", nil)
								  defaultButton:NSLocalizedString(@"ok maj", nil) alternateButton:nil
									 otherButton:nil
				  informativeTextWithFormat:NSLocalizedString(@"cannot import skin. unknown error.", nil)] runModal];
		}
		[self invalidateCachedSkinMelters];
		[tableViewForSkins reloadData];
	}];
}

- (IBAction)removeSkin:(id)sender
{
	[skinManager removeSkinAtIndex:[tableViewForSkins selectedRow]];
	[self invalidateCachedSkinMelters];
	[tableViewForSkins reloadData];
}

- (IBAction)selectSkin:(id)sender
{
	[skinManager selectSkinAtIndex:[tableViewForSkins selectedRow]];
	[tableViewForSkins reloadData];
}

- (IBAction)setMixedStateFromSkin:(id)sender
{
	[self setMixedStateUserDefault:FLMixedImageStateFromSkin];
}

- (IBAction)setMixedStateAllow:(id)sender
{
	[self setMixedStateUserDefault:FLMixedImageStateAllow];
}

- (IBAction)setMixedStateTransitions:(id)sender
{
	[self setMixedStateUserDefault:FLMixedImageStateTransitionsOnly];
}

- (IBAction)setMixedStateDisallow:(id)sender
{
	[self setMixedStateUserDefault:FLMixedImageStateDisallow];
}

- (void)reloadSkinList
{
	[self invalidateCachedSkinMelters];
	[tableViewForSkins reloadData];
}

@end

@implementation FLPreferencesController (Private)

- (void)setMixedStateUserDefault:(FLSkinMixedImageState)state
{
	[[NSUserDefaults standardUserDefaults] setInteger:state forKey:FL_UDK_MIXED_IMAGE_STATE];
}

- (NSToolbarItem *)toolbarItemForIdentifier:(NSString *)identifier
{
	for (NSToolbarItem *curItem in [toolBar items])
		if ([[curItem itemIdentifier] isEqualToString:identifier])
			return curItem;
	
	return nil;
}

- (void)setWindowContentSizeNoCheck:(NSSize)newSize animated:(BOOL)animate
{
	NSRect destRect = [self.window frame];
	NSSize curContentSize = [self.window contentRectForFrameRect:destRect].size;
	newSize.width  += destRect.size.width  - curContentSize.width;
	newSize.height += destRect.size.height - curContentSize.height;
	
	static BOOL firstPass = YES;
	if (!firstPass) destRect.origin.y += destRect.size.height - newSize.height;
	destRect.size = newSize;
	firstPass = NO;
	
	[self.window setFrame:destRect display:YES animate:YES];
}

- (void)setWindowSizeForSelectedPrefTab
{
	if (self.selectedPrefTab == nil) return;
	
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary *sizes = [ud objectForKey:FL_UDK_PREFS_PANES_SIZES];
	
	NSSize destSize;
	NSSize minSize = [self.window contentMinSize];
	NSSize maxSize = [self.window contentMaxSize];
	if ([sizes objectForKey:self.selectedPrefTab] == nil) destSize = minSize;
	else                                                  destSize = NSSizeFromString([sizes objectForKey:self.selectedPrefTab]);
	destSize.width  = MAX(destSize.width,  minSize.width);
	destSize.height = MAX(destSize.height, minSize.height);
	destSize.width  = MIN(destSize.width,  maxSize.width);
	destSize.height = MIN(destSize.height, maxSize.height);
	
	[self setWindowContentSizeNoCheck:destSize animated:YES];
}

/* Unused
- (void)constrainWindowToMinSize
{
	NSRect destRect = [self.window frame];
	NSSize curSize = [self.window contentRectForFrameRect:destRect].size;
	NSSize minSize = [self.window contentMinSize];
	NSSize destSize = NSMakeSize(MAX(curSize.width,  minSize.width),
										  MAX(curSize.height, minSize.height));
	
	[self setWindowContentSizeNoCheck:destSize animated:NO];
}*/

- (void)invalidateCachedSkinMelters
{
	[cachedSkinMelters release];
	cachedSkinMelters = [[NSMutableArray arrayWithCapacity:[skinManager nSkins]] retain];
	for (NSUInteger i = 0; i < [skinManager nSkins]; ++i) [cachedSkinMelters addObject:[NSNull null]];
}

- (void)updateSkinUI
{
	BOOL enabled = YES;
	NSInteger selectedIdx = [tableViewForSkins selectedRow];
	
	if (selectedIdx == -1) enabled = NO;
	
	[buttonRemoveSkin setEnabled:enabled && [skinManager canRemoveSkinAtIndex:selectedIdx]];
	[buttonSelectSkin setEnabled:enabled];
}

@end
