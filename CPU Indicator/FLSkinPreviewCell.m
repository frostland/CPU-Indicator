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

- (void)dealloc {
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

- (NSArray *)images
{
	return [self objectValue];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSArray *images = [self images];
	CGFloat progressPercentage = ((CGFloat)[[FLSkinPreviewCell getPreviewUpdateHeart] curProgress])/(CGFloat)NFRAMES_BETWEEN_FIRST_AND_LAST_IMAGE;
	CGFloat f = progressPercentage * ((CGFloat)[images count]-1.);
	NSUInteger imageIdx = f + 1;
	
	NSSize imageSize = [[images objectAtIndex:0] size];
	NSRect imageRect = NSMakeRect(0., 0., imageSize.width, imageSize.height);
	NSRect destRect;
	destRect.size.width = imageRect.size.width;
	destRect.size.height = imageRect.size.height;
	if (destRect.size.width > cellFrame.size.width) {
		destRect.size.width = cellFrame.size.width;
		destRect.size.height = cellFrame.size.width * (imageRect.size.height / imageRect.size.width);
	}
	if (destRect.size.height > cellFrame.size.height) {
		destRect.size.height = cellFrame.size.height;
		destRect.size.width = cellFrame.size.height * (imageRect.size.width / imageRect.size.height);
	}
	destRect.origin.x = cellFrame.origin.x + cellFrame.size.width  - destRect.size.width;
	destRect.origin.y = cellFrame.origin.y + cellFrame.size.height - destRect.size.height;

//	NSDictionary *drawHints = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:NSImageInterpolationNone], NSImageHintInterpolation, nil];
	if (imageIdx < [images count]) {
		[((NSImage *)[images objectAtIndex:imageIdx]) drawInRect:destRect fromRect:imageRect operation:NSCompositeSourceOver fraction:1. respectFlipped:YES hints:nil];
		if (imageIdx - 1 < [images count])
			[((NSImage *)[images objectAtIndex:imageIdx - 1]) drawInRect:destRect fromRect:imageRect operation:NSCompositeSourceOver fraction:imageIdx - f respectFlipped:YES hints:nil];
	} else [((NSImage *)[images lastObject]) drawInRect:destRect fromRect:imageRect operation:NSCompositeSourceOver fraction:1. respectFlipped:YES hints:nil];
}

- (void)dealloc
{
	[super dealloc];
}

@end
