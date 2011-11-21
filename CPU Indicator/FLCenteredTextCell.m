/*
 * FLCenteredTextCell.m
 * CPU Indicator
 *
 * Created by François LAMBOLEY on 3/8/11.
 * Copyright 2011 Frost Land. All rights reserved.
 */

#import "FLCenteredTextCell.h"

@implementation FLCenteredTextCell

- (NSRect)drawingRectForBounds:(NSRect)bounds
{
	NSRect r = [super drawingRectForBounds:bounds];
	NSSize cellSize = [self cellSizeForBounds:bounds];
	
	r.origin.y += (r.size.height - cellSize.height)/2.;
	r.size.height = cellSize.height;
	
	return r;
}

@end
