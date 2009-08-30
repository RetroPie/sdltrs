/* Copyright (c): 2006, Mark Grebe */

/* Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */
#import "TrsWindow.h"
#import "SDLMain.h"
#import "SDL.h"
#import "Preferences.h"
#import "PasteManager.h"

/* Variables in the C program which are set to request services from Objective-C */
extern int requestRedraw;
extern int requestQuit;
extern int copyStatus;

/* Static window variables.  This class supports only a single window object */
static TrsWindow *our_window = nil;
static TrsWindowView *our_window_view = nil;
static NSPoint windowOrigin;
static int windowWidth = 0;;
static int windowHeight = 0;

/* Functions which provide an interface for C code to call this object's shared Instance functions */
void TrsWindowCreate(int width, int height) {
    [TrsWindow createApplicationWindow:width:height];
	windowWidth = width;
	windowHeight = height;
}

void TrsOriginSet() {
    [TrsWindow applicationWindowOriginSetPrefs];
}

void TrsOriginSave() {
    windowOrigin = [TrsWindow applicationWindowOriginSave];
}

void TrsOriginRestore() {
    [TrsWindow applicationWindowOriginSet:windowOrigin];
}

void TrsWindowResize(int width, int height) {
    if (our_window)
        [our_window resizeApplicationWindow:width:height];
	else
		[TrsWindow createApplicationWindow:width:height];
	windowWidth = width;
	windowHeight = height;
}

void TrsWindowCenter(void) {
    if (our_window)
        [our_window center];
}

void TrsWindowDisplay(void) {
    if (our_window)
        [our_window display];
}

int TrsIsKeyWindow(void) {
    if (!our_window)
		return FALSE;
	else if ([our_window isKeyWindow] == YES)
        return TRUE;
	else
		return FALSE;
}

void TrsMakeKeyWindow(void) {  // TBD MDG add a call to this at startup.
	[our_window makeKeyWindow];
}

int TrsWindowMouseInside() {
	NSPoint mouse;
	
	mouse = [our_window mouseLocationOutsideOfEventStream];
	if (mouse.x < 0 || mouse.x > windowWidth || 
		mouse.y < 0 || mouse.y > windowHeight)
		return FALSE;
	else
		return TRUE;
}

/* Subclass of NSWindow to allow for drag and drop and other specific functions  */

@implementation TrsWindow
/*------------------------------------------------------------------------------
*  createApplicationWindow - Creates the emulator window of the given size. 
*-----------------------------------------------------------------------------*/
+ (void)createApplicationWindow:(int)width:(int)height
{
     unsigned int style;
     NSRect contentRect;
     char tempStr[40];
    
     /* Release the old window */
     if (our_window) {
        [our_window release];
        our_window = nil;
        our_window_view = nil;
        }

     /* Create the new window */
     contentRect = NSMakeRect (0, 0, width, height);
     style = NSTitledWindowMask;
     style |= (NSMiniaturizableWindowMask | NSClosableWindowMask);
     our_window = [ [ TrsWindow alloc ] 
                     initWithContentRect:contentRect
                     styleMask:style 
                     backing:NSBackingStoreBuffered
                     defer:NO ];

     [ our_window setAcceptsMouseMovedEvents:YES ];
     [ our_window setViewsNeedDisplay:NO ];
     [ our_window setTitle:@"SDLTRS" ];
     [ our_window setDelegate:
            [ [ [ TrsWindowDelegate alloc ] init ] autorelease ] ];
     [ our_window registerForDraggedTypes:[NSArray arrayWithObjects:
            NSFilenamesPboardType, nil]]; // Register for Drag and Drop
        
     /* Create thw window view and display it */
     our_window_view = [ [ TrsWindowView alloc ] initWithFrame:contentRect ];
     [ our_window_view setAutoresizingMask: NSViewMinYMargin ];
     [ [ our_window contentView ] addSubview:our_window_view ];
     [ our_window_view release ];
     [ our_window makeKeyAndOrderFront:nil ];

     /* Pass the window pointers to libSDL through environment variables */
     sprintf(tempStr,"%d",(int)our_window);
     setenv("SDL_NSWindowPointer",tempStr,1);
     sprintf(tempStr,"%d",(int)our_window_view);
     setenv("SDL_NSQuickDrawViewPointer",tempStr,1);     
}

/*------------------------------------------------------------------------------
*  applicationWindowOriginSave - This method saves the position of the media status
*    window
*-----------------------------------------------------------------------------*/
+ (NSPoint)applicationWindowOriginSave
{
	NSRect frame = NSMakeRect(0,0,0,0);
	
	if (our_window)
		frame = [our_window frame];
	return(frame.origin);
}
 
/*------------------------------------------------------------------------------
*  applicationWindowOriginSetPrefs - This method sets the position of the application
*    window from the values stored in the preferences object.
*-----------------------------------------------------------------------------*/
+ (void)applicationWindowOriginSetPrefs
{
	windowOrigin = [[Preferences sharedInstance] applicationWindowOrigin];
	
	if (our_window) {
		if (windowOrigin.x != 59999.0)
			[our_window setFrameOrigin:windowOrigin];
		else
			[our_window center];
		}
}
   
/*------------------------------------------------------------------------------
*  applicationWindowOriginSet - This method sets the position of the application
*    window to the value specified.
*-----------------------------------------------------------------------------*/
+ (void)applicationWindowOriginSet:(NSPoint)origin
{
	if (our_window) {
		[our_window setFrameOrigin:origin];
		}
}
   
/*------------------------------------------------------------------------------
*  resizeApplicationWindow - Resizes the emulator window to the given size. 
*-----------------------------------------------------------------------------*/
- (void)resizeApplicationWindow:(int)width:(int)height
{
     NSRect contentRect;
     
     /* Resize the window and the view */
     contentRect = NSMakeRect (0, 0, width, height);
     [ self setContentSize:contentRect.size ];
     [ our_window_view setFrame:contentRect ];
}
#if 0 // TBD MDG
/*------------------------------------------------------------------------------
*  draggingEntered - Checks for a valid drag and drop to this window. 
*-----------------------------------------------------------------------------*/
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    int i, filecount;
    NSString *suffix;

    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
    
    /* Check for filenames type drag */
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        /* Check for copy being valid */
        if (sourceDragMask & NSDragOperationCopy) {
            /* Check here for valid file types */
            NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
            
            filecount = [files count];
            for (i=0;i<filecount;i++) {
                suffix = [[files objectAtIndex:0] pathExtension];
            
                if (!([suffix isEqualToString:@"t8s"] ||
                      [suffix isEqualToString:@"t8c"] ||
                      [suffix isEqualToString:@"T8S"] ||
                      [suffix isEqualToString:@"T8C"]))
                    return NSDragOperationNone;
                }
            return NSDragOperationCopy; 
        }
    }
    return NSDragOperationNone;
}

/*------------------------------------------------------------------------------
*  performDragOperation - Executes the actual drap and drop of a filename. 
*-----------------------------------------------------------------------------*/
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    int i, filecount;

    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];

    /* Check for filenames type drag */
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
       NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
       
       /* For each file in the drag, load it into the emulator */
       filecount = [files count];
       for (i=0;i<filecount;i++)
            [SDLMain loadFile:[files objectAtIndex:i]];  
    }
    return YES;
}
#endif
/*------------------------------------------------------------------------------
*  display - displays the window. Overridden to fix the minimize effect
*-----------------------------------------------------------------------------*/
- (void)display
{
    /* save current visible SDL surface */
    [ self cacheImageInRect:[ our_window_view frame ] ];
    
    /* let the window manager redraw controls, border, etc */
    [ super display ];
    
    /* restore visible SDL surface */
    [ self restoreCachedImage ];
    
}

/*------------------------------------------------------------------------------
*  superDisplay - displays the window. Called after reverting from full screen
*    as window title bar was not being properly redrawn.
*-----------------------------------------------------------------------------*/
- (void)superDisplay
{
    /* let the window manager redraw controls, border, etc */
    [ super display ];    
}

+ (NSWindow *)ourWindow
{
	return(our_window);
}

@end

/* Delegate for our NSWindow to send SDLQuit() on close */
@implementation TrsWindowDelegate
-(void)pushKeyEvent:(int)key:(bool)shift:(bool)cmd
{
	SDL_Event theEvent;
	
	theEvent.key.type = SDL_KEYDOWN;
	theEvent.key.state = SDL_PRESSED;
	theEvent.key.keysym.scancode = 0;
	theEvent.key.keysym.sym = key;
	theEvent.key.keysym.mod = 0;
	if (cmd)
		theEvent.key.keysym.mod = KMOD_LMETA;
	if (shift)
		theEvent.key.keysym.mod |= KMOD_LSHIFT;
	theEvent.key.keysym.unicode = 0;
	SDL_PushEvent(&theEvent);
}

- (BOOL)windowShouldClose:(id)sender
{
	[self pushKeyEvent:SDLK_q:NO:YES];
    return NO;
}

@end

@implementation TrsWindowView
@end
