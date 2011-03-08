/* FLBorderlessWindow */

#import <Cocoa/Cocoa.h>

@interface FLBorderlessWindow : NSWindow {
@private
	BOOL allowDragNDrop;
	
	// This point is used in dragging to mark the initial click location
	NSPoint initialLocation;
}
@property(assign) BOOL allowDragNDrop;

@end
