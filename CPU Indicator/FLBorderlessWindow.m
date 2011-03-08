#import "FLBorderlessWindow.h"

@implementation FLBorderlessWindow

@synthesize allowDragNDrop;

- (id)initWithContentRect:(NSRect)contentRect
					 styleMask:(NSUInteger)aStyle
						backing:(NSBackingStoreType)bufferingType
						  defer:(BOOL)flag
{
	// Change the style mask to NSBorderlessWindowMask. So, the window will not have title-bar.
	NSWindow* result = [super initWithContentRect:contentRect
													styleMask:NSBorderlessWindowMask
													  backing:bufferingType
														 defer:NO];
	
	[result setOpaque:NO];
	[result setBackgroundColor:[NSColor clearColor]];
	/* Put the window above any other window */
	[result setLevel:NSStatusWindowLevel];
	/* The window is shown on all spaces */
	[result setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
	
	return result;
}

- (BOOL)canBecomeKeyWindow
{
	return NO;
}

- (BOOL)canBecomeMainWindow
{
	return NO;
}

// Once the user starts dragging the mouse, we move the window with it. We do this because the window has no title
// bar for the user to drag (so we have to implement dragging ourselves)
- (void)mouseDragged:(NSEvent *)theEvent
{
	if (!allowDragNDrop) return;
	
   NSPoint currentLocation;
   NSPoint newOrigin;
   NSRect  screenFrame = [[NSScreen mainScreen] frame];
   NSRect  windowFrame = [self frame];
	
	// grab the current global mouse location; we could just as easily get the mouse location 
	// in the same way as we do in -mouseDown:
	currentLocation = [self convertBaseToScreen:[self mouseLocationOutsideOfEventStream]];
	newOrigin.x = currentLocation.x - initialLocation.x;
	newOrigin.y = currentLocation.y - initialLocation.y;
	
	// Don't let window get dragged up under the menu bar
	if ((newOrigin.y+windowFrame.size.height) > (screenFrame.origin.y+screenFrame.size.height)) {
		newOrigin.y=screenFrame.origin.y + (screenFrame.size.height-windowFrame.size.height);
	}
	
	//go ahead and move the window to the new location
	[self setFrameOrigin:newOrigin];
}

// We start tracking the a drag operation here when the user first clicks the mouse,
// to establish the initial location.
- (void)mouseDown:(NSEvent *)theEvent
{
	if (!allowDragNDrop) return;
	
	NSRect windowFrame = [self frame];
	
	//grab the mouse location in global coordinates
   initialLocation = [self convertBaseToScreen:[theEvent locationInWindow]];
   initialLocation.x -= windowFrame.origin.x;
   initialLocation.y -= windowFrame.origin.y;
}

@end
