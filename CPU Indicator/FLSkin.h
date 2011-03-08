//
//  FLSkin.h
//  CPU Indicator
//
//  Created by François LAMBOLEY on 3/8/11.
//  Copyright 2011 Frost Land. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FLSkin : NSObject <NSCoding> {
@private
	NSString *name;
	
	NSArray *images;
	CGSize imagesSize;
}
@property(retain) NSString *name;
@property(readonly) CGSize imagesSize;
@property(readonly) NSArray *images;
@property(readonly) NSUInteger nImages;

/* All images in the given array must have the same size. The first image
 * is the image used when CPU load is zero.
 * At the assignement, the array given is copied deeply: the images are
 * copied too.
 *
 * The skin object is not inited if the size of the array given is 0,
 * if one image is not the same size of the other, if the size of the
 * images is zero, or if one element of the array is not of type NSImage.
 */
- (id)initWithImages:(NSArray *)imgs;

@end
