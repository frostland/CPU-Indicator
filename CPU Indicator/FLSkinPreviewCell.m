//
//  FLSkinPreviewCell.m
//  CPU Indicator
//
//  Created by François LAMBOLEY on 3/7/11.
//  Copyright 2011 Frost Land. All rights reserved.
//

#import "FLSkinPreviewCell.h"

@interface FLSkinPreviewUpdateHeart : NSObject {
@private
	NSTimer *t;
	NSTableView *tableView;
	
	NSInteger delta;
	NSUInteger curProgress; /* This is the current frame number, 0 being the first frame, the last being NFRAMES_BETWEEN_TWO_KEY_IMAGES */
}
@property(assign) NSTableView *tableView;
@property(readonly) NSUInteger curProgress;

@end

@implementation FLSkinPreviewUpdateHeart

@synthesize tableView;
@synthesize curProgress;

- (id)init
{
	if ((self = [super init]) != nil) {
		delta = 1;
		t = [[NSTimer scheduledTimerWithTimeInterval:1/FPS_FOR_PREVIEW target:self selector:@selector(fireHeartBeat:) userInfo:NULL repeats:YES] retain];
	}
	
	return self;
}

- (void)fireHeartBeat:(NSTimer *)t
{
	if ((curProgress += delta) >= NFRAMES_BETWEEN_FIRST_AND_LAST_IMAGE)    delta *= -1;
	if (curProgress >= NFRAMES_BETWEEN_FIRST_AND_LAST_IMAGE && delta == 1) curProgress++;
	
	[tableView setNeedsDisplayInRect:[tableView rectOfColumn:2]];
}

- (void)dealloc
{
	[t invalidate]; [t release]; t = nil;
	
	[super dealloc];
}

@end

@implementation FLSkinPreviewCell

static FLSkinPreviewUpdateHeart *previewUpdateHeart = nil;

+ (FLSkinPreviewUpdateHeart *)getPreviewUpdateHeart
{
	if (previewUpdateHeart == nil) previewUpdateHeart = [FLSkinPreviewUpdateHeart new];
	return previewUpdateHeart;
}

- (void)setControlView:(NSView*)view
{
	[[FLSkinPreviewCell getPreviewUpdateHeart] setTableView:(NSTableView *)[self controlView]];
	[super setControlView:view];
}

- (FLSkinMelter *)skinMelter
{
	return [self objectValue];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	FLSkinMelter *skinMelter = [self skinMelter];
	CGFloat progressPercentage = ((CGFloat)[[FLSkinPreviewCell getPreviewUpdateHeart] curProgress])/(CGFloat)NFRAMES_BETWEEN_FIRST_AND_LAST_IMAGE;
	
	NSPoint p;
	NSSize drawnSize = [skinMelter finalSize];
	p.x = cellFrame.origin.x +  cellFrame.size.width  - drawnSize.width;
	p.y = cellFrame.origin.y + (cellFrame.size.height - drawnSize.height)/2.;
	
	NSRect drawRect;
	drawRect.origin = p;
	drawRect.size = drawnSize;
	[[skinMelter imageForCPULoad:progressPercentage] drawInRect:drawRect
																		fromRect:NSMakeRect(0., 0., drawnSize.width, drawnSize.height)
																	  operation:NSCompositeSourceOver fraction:1.
																respectFlipped:YES hints:nil];
}

- (void)dealloc
{
	[super dealloc];
}

@end
