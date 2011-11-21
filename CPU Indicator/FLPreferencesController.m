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
- (void)invalidateCachedSkinMelters;
- (void)updateSkinUI;

@end

@implementation FLPreferencesController

@synthesize toolBar;
@synthesize skinManager, cpuIndicatorWindow;

@synthesize sliderScale, popUpButtonMixedImageState;
@synthesize viewForSkinsPrefs, viewForGeneralPrefs;
@synthesize buttonRemoveSkin, buttonSelectSkin;
@synthesize tableViewForSkins;
@synthesize selectedPrefTab;

- (id)initWithWindow:(NSWindow *)window
{
	if ((self = [super initWithWindow:window]) != nil) {
	}
	
	return self;
}

- (void)dealloc
{
	self.skinManager = nil;
	self.selectedPrefTab = nil;
	self.cpuIndicatorWindow = nil;
	
	[cachedSkinMelters release]; cachedSkinMelters = nil;
	
	[super dealloc];
}

- (void)awakeFromNib
{
	[self invalidateCachedSkinMelters];
	
	minSizeForSkinsPrefs = [viewForSkinsPrefs frame].size;
	minSizeForGeneralPrefs = [viewForGeneralPrefs frame].size;
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
		[self selectSkinPref:nil];
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

- (IBAction)selectGeneralPref:(id)sender
{
	self.selectedPrefTab = [toolBar selectedItemIdentifier];
	[[NSUserDefaults standardUserDefaults] setObject:self.selectedPrefTab forKey:FL_UDK_LAST_SELECTED_PREF_ID];
	
	[self.window setContentView:viewForGeneralPrefs];
	[self.window setContentMinSize:minSizeForGeneralPrefs];
	
	[self setWindowSizeForSelectedPrefTab];
}

- (IBAction)selectSkinPref:(id)sender
{
	self.selectedPrefTab = [toolBar selectedItemIdentifier];
	[[NSUserDefaults standardUserDefaults] setObject:self.selectedPrefTab forKey:FL_UDK_LAST_SELECTED_PREF_ID];
	
	[self.window setContentView:viewForSkinsPrefs];
	[self.window setContentMinSize:minSizeForSkinsPrefs];
	[self updateSkinUI];
	
	[self setWindowSizeForSelectedPrefTab];
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
	NSRect screenRect = [[cpuIndicatorWindow screen] frame];
	NSRect f = [cpuIndicatorWindow frame];
	f.origin.x = screenRect.origin.x;
	f.origin.y = screenRect.origin.y + screenRect.size.height - f.size.height;
	[cpuIndicatorWindow setFrame:f display:YES animate:YES];
}

- (IBAction)moveWindowToPseudoTopLeft:(id)sender
{
	NSRect screenRect = [[cpuIndicatorWindow screen] visibleFrame];
	NSRect f = [cpuIndicatorWindow frame];
	f.origin.x = screenRect.origin.x;
	f.origin.y = screenRect.origin.y + screenRect.size.height - f.size.height;
	[cpuIndicatorWindow setFrame:f display:YES animate:YES];
}

- (IBAction)moveWindowToTopRight:(id)sender
{
	NSRect screenRect = [[cpuIndicatorWindow screen] frame];
	NSRect f = [cpuIndicatorWindow frame];
	f.origin.x = screenRect.origin.x + screenRect.size.width - f.size.width;
	f.origin.y = screenRect.origin.y + screenRect.size.height - f.size.height;
	[cpuIndicatorWindow setFrame:f display:YES animate:YES];
}

- (IBAction)moveWindowToPseudoTopRight:(id)sender
{
	NSRect screenRect = [[cpuIndicatorWindow screen] visibleFrame];
	NSRect f = [cpuIndicatorWindow frame];
	f.origin.x = screenRect.origin.x + screenRect.size.width - f.size.width;
	f.origin.y = screenRect.origin.y + screenRect.size.height - f.size.height;
	[cpuIndicatorWindow setFrame:f display:YES animate:YES];
}

- (IBAction)moveWindowToBottomLeft:(id)sender
{
	NSRect screenRect = [[cpuIndicatorWindow screen] frame];
	NSRect f = [cpuIndicatorWindow frame];
	f.origin.x = screenRect.origin.x;
	f.origin.y = screenRect.origin.y;
	[cpuIndicatorWindow setFrame:f display:YES animate:YES];
}

- (IBAction)moveWindowToPseudoBottomLeft:(id)sender
{
	NSRect screenRect = [[cpuIndicatorWindow screen] visibleFrame];
	NSRect f = [cpuIndicatorWindow frame];
	f.origin.x = screenRect.origin.x;
	f.origin.y = screenRect.origin.y;
	[cpuIndicatorWindow setFrame:f display:YES animate:YES];
}

- (IBAction)moveWindowToBottomRight:(id)sender
{
	NSRect screenRect = [[cpuIndicatorWindow screen] frame];
	NSRect f = [cpuIndicatorWindow frame];
	f.origin.x = screenRect.origin.x + screenRect.size.width - f.size.width;
	f.origin.y = screenRect.origin.y;
	[cpuIndicatorWindow setFrame:f display:YES animate:YES];
}

- (IBAction)moveWindowToPseudoBottomRight:(id)sender
{
	NSRect screenRect = [[cpuIndicatorWindow screen] visibleFrame];
	NSRect f = [cpuIndicatorWindow frame];
	f.origin.x = screenRect.origin.x + screenRect.size.width - f.size.width;
	f.origin.y = screenRect.origin.y;
	[cpuIndicatorWindow setFrame:f display:YES animate:YES];
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

- (void)setWindowSizeForSelectedPrefTab
{
	if (self.selectedPrefTab == nil) return;
	
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary *sizes = [ud objectForKey:FL_UDK_PREFS_PANES_SIZES];
	
	NSRect destRect;
	NSSize destSize, curContentSize;
	if ([sizes objectForKey:self.selectedPrefTab] == nil) destSize = [self.window contentMinSize];
	else                                                  destSize = NSSizeFromString([sizes objectForKey:self.selectedPrefTab]);
	
	destRect = [self.window frame];
	curContentSize = [self.window contentRectForFrameRect:destRect].size;
	destSize.width  += destRect.size.width  - curContentSize.width;
	destSize.height += destRect.size.height - curContentSize.height;
	
	static BOOL firstPass = YES;
	if (!firstPass) destRect.origin.y += destRect.size.height - destSize.height;
	destRect.size = destSize;
	firstPass = NO;
	
	[self.window setFrame:destRect display:YES animate:YES];
}

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
