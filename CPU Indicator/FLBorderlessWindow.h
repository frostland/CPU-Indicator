/* FLBorderlessWindow */

#import <Cocoa/Cocoa.h>

@interface FLBorderlessWindow : NSWindow {
	//This point is used in dragging to mark the initial click location
	CGPoint initialLocation;
}

@end
