/*
 * FLMenuIndicatorView.m
 * CPU Indicator
 *
 * Created by François LAMBOLEY on 12/21/11.
 * Copyright (c) 2011 Frost Land. All rights reserved.
 */

#import "FLMenuIndicatorView.h"

#define SPACING (4.)
#define SMALL_SPACING (1.)

@interface FLLabel : NSTextField {
}

@end

@implementation FLLabel

- (NSView *)hitTest:(NSPoint)aPoint
{
	NSView *hitView = [super hitTest:aPoint];
	return (hitView == self)? nil: hitView;
}

@end

@implementation FLMenuIndicatorView

@synthesize statusItem;
@synthesize cpuIndicatorView;

+ (instancetype)menuIndicatorViewWithFont:(NSFont *)font statusItem:(NSStatusItem *)si andHeight:(CGFloat)height
{
	FLMenuIndicatorView *miv = [[self alloc] initWithFrame:NSMakeRect(0., 0., 0., height) andFont:font];
	miv.statusItem = si;
	return [miv autorelease];
}

- (instancetype)initWithFrame:(NSRect)frameRect
{
	return [self initWithFrame:frameRect andFont:nil];
}

- (instancetype)initWithFrame:(NSRect)frame andFont:(NSFont *)font
{
	if ((self = [super initWithFrame:frame]) != nil) {
		if (font == nil) font = [NSFont systemFontOfSize:frame.size.height - SPACING*2.];
		cpuIndicatorView = [[FLCPUIndicatorView alloc] initWithFrame:NSMakeRect(SPACING, SMALL_SPACING, 0., frame.size.height - SMALL_SPACING*2.)];
		cpuIndicatorView.ignoreClicks = YES;
		
		labelForText = [[FLLabel alloc] initWithFrame:NSMakeRect(0., (frame.size.height - font.pointSize + font.descender) / 2. + 1. /* Mostly manual alignment */, 0., font.pointSize)];
		labelForText.font = font;
		[labelForText setBordered:NO];
		[labelForText setDrawsBackground:NO];
		
		textShown = imageShown = NO;
		curCPULoad = 0.;
	}
	
	return self;
}

- (void)dealloc
{
	[statusItem release];
	[labelForText release];
	[cpuIndicatorView release];
	
	[super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect
{
	[statusItem drawStatusBarBackgroundInRect:[self bounds] withHighlight:mouseDown];
	[super drawRect:dirtyRect];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	[statusItem.menu setDelegate:self];
   [statusItem popUpStatusItemMenu:statusItem.menu];
   [self setNeedsDisplay:YES];
}

- (void)menuWillOpen:(NSMenu *)menu
{
	mouseDown = YES;
	[labelForText setTextColor:[NSColor whiteColor]];
	[self setNeedsDisplay:YES];
}

- (void)menuDidClose:(NSMenu *)menu
{
	mouseDown = NO;
	[labelForText setTextColor:[NSColor blackColor]];
	[statusItem.menu setDelegate:nil];    
	[self setNeedsDisplay:YES];
}

- (void)refreshSelfSizeAndSubviewsPositions
{
	CGFloat curX = SPACING;
	if (imageShown) curX += cpuIndicatorView.frame.size.width;
	if (imageShown && textShown) curX += 2.*SMALL_SPACING;
	NSRect f = labelForText.frame;
	f.origin.x = curX;
	labelForText.frame = f;
	if (textShown) curX += labelForText.frame.size.width;
	curX += SPACING;
	
	f = self.frame;
	f.size.width = curX;
	self.frame = f;
}

- (void)refreshSize
{
	NSRect f = cpuIndicatorView.frame;
	FLSkin *skin = cpuIndicatorView.skin;
	CGFloat factor = f.size.height / skin.imagesSize.height;
	f.size.width = skin.imagesSize.width * factor;
	cpuIndicatorView.frame = f;
	
	[self refreshSelfSizeAndSubviewsPositions];
}

- (void)refreshTextLoad
{
	labelForText.stringValue = [NSString stringWithFormat:@"%u%%", (unsigned int)(curCPULoad*100 + .5)];
	[labelForText sizeToFit];
	[self refreshSelfSizeAndSubviewsPositions];
}

- (void)setCurCPULoad:(CGFloat)load animated:(BOOL)animate
{
	curCPULoad = load;
	
	if (textShown) [self refreshTextLoad];
	if (imageShown) [cpuIndicatorView setCurCPULoad:load animated:animate];
}

- (void)setShowsText:(BOOL)show
{
	if (textShown == show) return;
	textShown = show;
	if (show) {
		NSAssert(labelForText.superview == nil, @"labelForText.superview != nil but label should not be shown.");
		[self refreshTextLoad];
		[self addSubview:labelForText];
	} else {
		NSAssert(labelForText.superview != nil, @"labelForText.superview == nil but label should be shown.");
		[labelForText removeFromSuperview];
	}
	[self refreshSelfSizeAndSubviewsPositions];
}

- (void)setShowsImage:(BOOL)show
{
	if (imageShown == show) return;
	imageShown = show;
	if (show) {
		NSAssert(cpuIndicatorView.superview == nil, @"cpuIndicatorView.superview != nil but the view should not be shown.");
		[cpuIndicatorView setCurCPULoad:curCPULoad animated:NO];
		[self addSubview:cpuIndicatorView];
		[self refreshSize];
	} else {
		NSAssert(cpuIndicatorView.superview != nil, @"cpuIndicatorView.superview == nil but the view should be shown.");
		[cpuIndicatorView removeFromSuperview];
	}
	[self refreshSelfSizeAndSubviewsPositions];
}

@end
