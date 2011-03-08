//
//  FLPreferencesController.m
//  CPU Indicator
//
//  Created by François LAMBOLEY on 3/7/11.
//  Copyright 2011 Frost Land. All rights reserved.
//

#import "FLPreferencesController.h"

#import "FLConstants.h"
#import "FLDefaultPaths.h"
#import "FLSkinPreviewCell.h"

@interface FLPreferencesController (Private)

- (NSToolbarItem *)toolbarItemForIdentifier:(NSString *)identifier;
- (void)updateSkinUI;

@end

@implementation FLPreferencesController

@synthesize toolBar;
@synthesize skinManager, cpuIndicatorWindow;

@synthesize viewForSkinsPrefs, viewForGeneralPrefs;
@synthesize buttonRemoveSkin, buttonSelectSkin;
@synthesize tableViewForSkins;

- (id)initWithWindow:(NSWindow *)window
{
	if ((self = [super initWithWindow:window]) != nil) {
	}
	
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (void)windowDidLoad
{
	[super windowDidLoad];
	
	/* Init the UI from user defaults */
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	
	[toolBar setSelectedItemIdentifier:[ud objectForKey:FL_UDK_LAST_SELECTED_PREF_ID]];
	NSToolbarItem *selectedToolbarItem = [self toolbarItemForIdentifier:[toolBar selectedItemIdentifier]];
	if (selectedToolbarItem != nil) [self performSelector:[selectedToolbarItem action] withObject:self];
	else {
		[self selectGeneralPref:nil];
		[toolBar setSelectedItemIdentifier:[[[toolBar items] objectAtIndex:1] itemIdentifier]];
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
		return [[skinManager skinAtIndex:row] images];
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
	[[NSUserDefaults standardUserDefaults] setObject:[toolBar selectedItemIdentifier] forKey:FL_UDK_LAST_SELECTED_PREF_ID];
	
	[self.window setContentView:viewForGeneralPrefs];
}

- (IBAction)selectSkinPref:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setObject:[toolBar selectedItemIdentifier] forKey:FL_UDK_LAST_SELECTED_PREF_ID];
	
	[self.window setContentView:viewForSkinsPrefs];
	[self updateSkinUI];
}

- (IBAction)moveWindowToTopLeft:(id)sender
{
	NSRect screenRect = [[cpuIndicatorWindow screen] visibleFrame];
	NSRect f = [cpuIndicatorWindow frame];
	f.origin.x = screenRect.origin.x;
	f.origin.y = screenRect.origin.y + screenRect.size.height - f.size.height;
	[cpuIndicatorWindow setFrame:f display:YES animate:YES];
}

- (IBAction)moveWindowToTopRight:(id)sender
{
	NSRect screenRect = [[cpuIndicatorWindow screen] visibleFrame];
	NSRect f = [cpuIndicatorWindow frame];
	f.origin.x = screenRect.origin.x + screenRect.size.width - f.size.width;
	f.origin.y = screenRect.origin.y + screenRect.size.height - f.size.height;
	[cpuIndicatorWindow setFrame:f display:YES animate:YES];
}

- (IBAction)moveWindowToBottomLeft:(id)sender
{
	NSRect screenRect = [[cpuIndicatorWindow screen] visibleFrame];
	NSRect f = [cpuIndicatorWindow frame];
	f.origin.x = screenRect.origin.x;
	f.origin.y = screenRect.origin.y;
	[cpuIndicatorWindow setFrame:f display:YES animate:YES];
}

- (IBAction)moveWindowToBottomRight:(id)sender
{
	NSRect screenRect = [[cpuIndicatorWindow screen] visibleFrame];
	NSRect f = [cpuIndicatorWindow frame];
	f.origin.x = screenRect.origin.x + screenRect.size.width - f.size.width;
	f.origin.y = screenRect.origin.y;
	[cpuIndicatorWindow setFrame:f display:YES animate:YES];
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
		
		[skinManager installSkinAtPath:[[openPanel URL] path] useIt:NO];
		[tableViewForSkins reloadData];
	}];
}

- (IBAction)removeSkin:(id)sender
{
	[skinManager removeSkinAtIndex:[tableViewForSkins selectedRow]];
	[tableViewForSkins reloadData];
}

- (IBAction)selectSkin:(id)sender
{
	[skinManager selectSkinAtIndex:[tableViewForSkins selectedRow]];
	[tableViewForSkins reloadData];
}

- (void)reloadSkinList
{
	[tableViewForSkins reloadData];
}

@end

@implementation FLPreferencesController (Private)

- (NSToolbarItem *)toolbarItemForIdentifier:(NSString *)identifier
{
	for (NSToolbarItem *curItem in [toolBar items])
		if ([[curItem itemIdentifier] isEqualToString:identifier])
			return curItem;
	
	return nil;
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
