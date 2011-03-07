//
//  FLCPUIndicatorView.h
//  CPU Indicator
//
//  Created by François LAMBOLEY on 3/6/11.
//  Copyright 2011 Frost Land. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define ANIM_DURATION (1.5)
#define FPS (25)
#define NFRAME ((NSUInteger)(ANIM_DURATION * FPS))

@interface FLCPUIndicatorView : NSView {
@private
	NSWindow *parentWindow;
	
	NSArray *images;
	CGSize baseSize;
	BOOL stickToImages;
	
	CGFloat curCPULoad;
	CGFloat destCPULoad;
	CGFloat CPULoadIncrement;
	
	BOOL animating;
	NSTimer *animTimer;
	NSUInteger curFrameNumber;
}
@property(assign) IBOutlet NSWindow *parentWindow;

/* Contains the images to display the cpu load. All images in this array
 * must have the same size. The first image is the image used when CPU
 * load is zero.
 * At the assignement, the array given is copied deeply: the images are
 * copied too.
 *
 * An exception is thrown at the assignement of this property if the
 * size of the array given is 0, if one image is not the same size
 * of the other, if the size of the images is zero, or if one element
 * of the array is not of type NSImage.
 *
 * The array of images returned when retreiving the value of this
 * property is a deep copy of the array known by the FLCPUIndicatorView.
 * This prevent the modification of the array known by the view.
 */
@property(copy) NSArray *images;
@property(assign) CGFloat curCPULoad;
- (void)setCurCPULoad:(CGFloat)CPULoad animated:(BOOL)flag;

@end
