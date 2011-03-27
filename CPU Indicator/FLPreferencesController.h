//
//  FLPreferencesController.h
//  CPU Indicator
//
//  Created by François LAMBOLEY on 3/7/11.
//  Copyright 2011 Frost Land. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "FLSkinManager.h"
#import "FLBorderlessWindow.h"

@interface FLPreferencesController : NSWindowController <NSWindowDelegate, NSTableViewDelegate, NSTableViewDataSource> {
@private
	NSToolbar *toolBar;
	NSView *viewForSkinsPrefs;
	NSView *viewForGeneralPrefs;
	NSTableView *tableViewForSkins;
	
	NSSlider *sliderScale;
	
	NSButton *buttonRemoveSkin;
	NSButton *buttonSelectSkin;
	
	NSSize minSizeForSkinsPrefs;
	NSSize minSizeForGeneralPrefs;
	
	NSString *selectedPrefTab;
	FLSkinManager *skinManager;
	FLBorderlessWindow *cpuIndicatorWindow;
}
@property(assign) IBOutlet NSToolbar *toolBar;
@property(assign) IBOutlet NSView *viewForSkinsPrefs;
@property(assign) IBOutlet NSView *viewForGeneralPrefs;
@property(assign) IBOutlet NSButton *buttonRemoveSkin;
@property(assign) IBOutlet NSButton *buttonSelectSkin;
@property(assign) IBOutlet NSTableView *tableViewForSkins;
@property(assign) IBOutlet NSSlider *sliderScale;
@property(copy) NSString *selectedPrefTab;
@property(retain) FLSkinManager *skinManager;
@property(retain) FLBorderlessWindow *cpuIndicatorWindow;

- (IBAction)selectGeneralPref:(id)sender;
- (IBAction)selectSkinPref:(id)sender;

- (IBAction)moveWindowToTopLeft:(id)sender;
- (IBAction)moveWindowToPseudoTopLeft:(id)sender;
- (IBAction)moveWindowToTopRight:(id)sender;
- (IBAction)moveWindowToPseudoTopRight:(id)sender;
- (IBAction)moveWindowToBottomLeft:(id)sender;
- (IBAction)moveWindowToPseudoBottomLeft:(id)sender;
- (IBAction)moveWindowToBottomRight:(id)sender;
- (IBAction)moveWindowToPseudoBottomRight:(id)sender;

- (IBAction)updateScale:(id)sender;

- (IBAction)showSkinsOnTheNet:(id)sender;
- (IBAction)addSkin:(id)sender;
- (IBAction)removeSkin:(id)sender;
- (IBAction)selectSkin:(id)sender;

- (void)reloadSkinList;

@end
