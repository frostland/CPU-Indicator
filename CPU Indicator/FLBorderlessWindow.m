#import "FLBorderlessWindow.h"

@implementation FLBorderlessWindow

@synthesize allowDragNDrop;

- (id)initWithContentRect:(NSRect)contentRect
					 styleMask:(NSUInteger)aStyle
						backing:(NSBackingStoreType)bufferingType
						  defer:(BOOL)flag
{
	// Change the style mask to NSBorderlessWindowMask. So, the window will not have title-bar.
	FLBorderlessWindow *result = [super initWithContentRect:contentRect
																 styleMask:NSBorderlessWindowMask
																	backing:bufferingType
																	  defer:NO];
	
	[result setOpaque:NO];
	[result setBackgroundColor:[NSColor clearColor]];
	/* Put the window above any other window */
	[result setLevel:NSStatusWindowLevel];
	
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

- (void)setContentSize:(NSSize)aSize
{
	[super setContentSize:aSize];
	
	/* Checking that the window is not going out of the screen */
	NSRect windowFrame = [self frame];
	NSRect screenFrame = [[self screen] frame];
	if (windowFrame.origin.x + windowFrame.size.width > screenFrame.origin.x + screenFrame.size.width)
		windowFrame.origin.x -= (windowFrame.origin.x + windowFrame.size.width - (screenFrame.origin.x + screenFrame.size.width));
	if (windowFrame.origin.y + windowFrame.size.height > screenFrame.origin.y + screenFrame.size.height)
		windowFrame.origin.y -= (windowFrame.origin.y + windowFrame.size.height - (screenFrame.origin.y + screenFrame.size.height));
	if (windowFrame.origin.x < 0.) windowFrame.origin.x = 0.;
	if (windowFrame.origin.y < 0.) windowFrame.origin.y = 0.;
	[self setFrame:windowFrame display:NO];
}

/* Once the user starts dragging the mouse, we move the window with it. We do this because the window has no title
 * bar for the user to drag (so we have to implement dragging ourselves). */
- (void)mouseDragged:(NSEvent *)theEvent
{
	if (!allowDragNDrop) return;
	
   NSPoint currentLocation;
   NSPoint newOrigin;
   NSRect  screenFrame = [[self screen] frame];
   NSRect  windowFrame = [self frame];
	
	/* Grab the current global mouse location; we could just as easily get the mouse location 
	 * in the same way as we do in -mouseDown: */
	currentLocation = [self convertBaseToScreen:[self mouseLocationOutsideOfEventStream]];
	newOrigin.x = currentLocation.x - initialLocation.x;
	newOrigin.y = currentLocation.y - initialLocation.y;
	
	// Don't let window get dragged up under the menu bar
	if (newOrigin.x + windowFrame.size.width > screenFrame.origin.x + screenFrame.size.width)
		newOrigin.x = screenFrame.origin.x + (screenFrame.size.width-windowFrame.size.width);
	if (newOrigin.y + windowFrame.size.height > screenFrame.origin.y + screenFrame.size.height)
		newOrigin.y = screenFrame.origin.y + (screenFrame.size.height-windowFrame.size.height);
	if (newOrigin.x < 0.) newOrigin.x = 0.;
	if (newOrigin.y < 0.) newOrigin.y = 0.;
	
	/* Go ahead and move the window to the new location */
	[self setFrameOrigin:newOrigin];
}

/* We start tracking the a drag operation here when the user first clicks the mouse,
 * to establish the initial location. */
- (void)mouseDown:(NSEvent *)theEvent
{
	if (!allowDragNDrop) return;
	
	NSRect windowFrame = [self frame];
	
	/* Grab the mouse location in global coordinates */
   initialLocation = [self convertBaseToScreen:[theEvent locationInWindow]];
   initialLocation.x -= windowFrame.origin.x;
   initialLocation.y -= windowFrame.origin.y;
}

@end
