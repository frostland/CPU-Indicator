//
//  FLSkinPreviewCell.h
//  CPU Indicator
//
//  Created by François LAMBOLEY on 3/7/11.
//  Copyright 2011 Frost Land. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FLSkinMelter.h"

#define FPS_FOR_PREVIEW (15.)
#define TIME_BETWEEN_FIRST_AND_LAST_IMAGE (5.)
#define NFRAMES_BETWEEN_FIRST_AND_LAST_IMAGE ((NSUInteger)(FPS_FOR_PREVIEW * TIME_BETWEEN_FIRST_AND_LAST_IMAGE))

@interface FLSkinPreviewCell : NSCell {
@private
}

@end
