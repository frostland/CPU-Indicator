/*
 * FLSkinMelter.h
 * CPU Indicator
 *
 * Created by François LAMBOLEY on 3/27/11.
 * Copyright 2011 Frost Land. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "FLSkin.h"

/* This class is used to compute the image drawn at a certain
 * CPU usage, for a given destination size (destSize).
 * A special algorithm is used during the melting to avoid alpha
 * problems (specifically, semi-alpha pixels, when superimposed
 * see their alpha grow though, for a better look, they should not).
 * By default, if not defined, the destSize is set
 * arbitrarily to NSMakeSize(15., 15.).
 *
 * The melting is done lazily: it is computed only when necessary.
 */

@interface FLSkinMelter : NSObject <NSCopying> {
@private
	FLSkin *skin;
	NSSize destSize;
	BOOL forceDestSize;
	
	CGFloat loadOfLastComutedFrame;
	NSBitmapImageRep *lastComputedFrame;
	
	NSSize finalSize;
	NSMutableArray *resizedImages;
	BOOL shouldRefreshResizedImages;
}
@property(retain) FLSkin *skin;
@property(assign) NSSize destSize;
@property(assign) BOOL forceDestSize; /* If YES, the image computed will be of size destSize. If NO, the proportions of the skin will be kept, and the image computed will never be bigger than the skin size. */

- (NSSize)finalSize;

/* Load is a float between 0 and 1. An exception is thrown if it is not the case. */
- (NSImageRep *)imageForCPULoad:(CGFloat)load;

@end
