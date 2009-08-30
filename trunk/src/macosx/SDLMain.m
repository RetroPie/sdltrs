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

/*
   Modified by Mark Grebe, 2006
   Last modified on Wed May 07 09:12:00 MST 2006 by markgrebe
*/

#import "SDL.h"
#import "SDLMain.h"
#import <sys/param.h> /* for MAXPATHLEN */
#import <unistd.h>
#import <stdlib.h>
#import "ControlManager.h"
#import "Preferences.h"
#import "trs_mac_interface.h"
#import "trs_cassette.h"

/* Use this flag to determine whether we use SDLMain.nib or not */
#define		SDL_USE_NIB_FILE	1

extern int SDLmain(int argc, char *argv[]);

static int    gArgc;
static char  **gArgv;
static BOOL   started=NO;
static BOOL   gFinderLaunch;
int fileToLoad = FALSE;
static char startupFile[FILENAME_MAX];

NSWindow *appWindow;

void SDLMainSelectAll() {
	[[[NSApp keyWindow] firstResponder] selectAll:NSApp];
}

void SDLMainCopy() {
	[[[NSApp keyWindow] firstResponder] copy:NSApp];
}

void SDLMainPaste() {
	[[[NSApp keyWindow] firstResponder] paste:NSApp];
}

#if SDL_USE_NIB_FILE
/* A helper category for NSString */
@interface NSString (ReplaceSubString)
- (NSString *)stringByReplacingRange:(NSRange)aRange with:(NSString *)aString;
@end
#else
/* An internal Apple class used to setup Apple menus */
@interface NSAppleMenuController:NSObject {}
- (void)controlMenu:(NSMenu *)aMenu;
@end
#endif

@interface SDLApplication : NSApplication
@end

@implementation SDLApplication
/* Invoked from the Quit menu item */
- (void)terminate:(id)sender
{
    /* Post a SDL_QUIT event */
    SDL_Event event;
    event.type = SDL_QUIT;
    SDL_PushEvent(&event);
}
@end


/* The main class of the application, the application's delegate */
@implementation SDLMain

#if SDL_USE_NIB_FILE

/* Fix menu to contain the real app name instead of "SDL App" */
- (void)fixMenu:(NSMenu *)aMenu withAppName:(NSString *)appName
{
    NSRange aRange;
    NSEnumerator *enumerator;
    NSMenuItem *menuItem;

    aRange = [[aMenu title] rangeOfString:@"SDL App"];
    if (aRange.length != 0)
        [aMenu setTitle: [[aMenu title] stringByReplacingRange:aRange with:appName]];

    enumerator = [[aMenu itemArray] objectEnumerator];
    while ((menuItem = [enumerator nextObject]))
    {
        aRange = [[menuItem title] rangeOfString:@"SDL App"];
        if (aRange.length != 0)
            [menuItem setTitle: [[menuItem title] stringByReplacingRange:aRange with:appName]];
        if ([menuItem hasSubmenu])
            [self fixMenu:[menuItem submenu] withAppName:appName];
    }
    [ aMenu sizeToFit ];
}

#else

void setupAppleMenu(void)
{
    /* warning: this code is very odd */
    NSAppleMenuController *appleMenuController;
    NSMenu *appleMenu;
    NSMenuItem *appleMenuItem;

    appleMenuController = [[NSAppleMenuController alloc] init];
    appleMenu = [[NSMenu alloc] initWithTitle:@""];
    appleMenuItem = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
    
    [appleMenuItem setSubmenu:appleMenu];

    /* yes, we do need to add it and then remove it --
       if you don't add it, it doesn't get displayed
       if you don't remove it, you have an extra, titleless item in the menubar
       when you remove it, it appears to stick around
       very, very odd */
    [[NSApp mainMenu] addItem:appleMenuItem];
    [appleMenuController controlMenu:appleMenu];
    [[NSApp mainMenu] removeItem:appleMenuItem];
    [appleMenu release];
    [appleMenuItem release];
}

/* Create a window menu */
void setupWindowMenu(void)
{
    NSMenu		*windowMenu;
    NSMenuItem	*windowMenuItem;
    NSMenuItem	*menuItem;


    windowMenu = [[NSMenu alloc] initWithTitle:@"Window"];
    
    /* "Minimize" item */
    menuItem = [[NSMenuItem alloc] initWithTitle:@"Minimize" action:@selector(performMiniaturize:) keyEquivalent:@"m"];
    [windowMenu addItem:menuItem];
    [menuItem release];
    
    /* Put menu into the menubar */
    windowMenuItem = [[NSMenuItem alloc] initWithTitle:@"Window" action:nil keyEquivalent:@""];
    [windowMenuItem setSubmenu:windowMenu];
    [[NSApp mainMenu] addItem:windowMenuItem];
    
    /* Tell the application object that this is now the window menu */
    [NSApp setWindowsMenu:windowMenu];

    /* Finally give up our references to the objects */
    [windowMenu release];
    [windowMenuItem release];
}

/* Replacement for NSApplicationMain */
void CustomApplicationMain (argc, argv)
{
    NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
    SDLMain				*sdlMain;

    /* Ensure the application object is initialised */
    [SDLApplication sharedApplication];
    
    /* Set up the menubar */
    [NSApp setMainMenu:[[NSMenu alloc] init]];
    setupAppleMenu();
    setupWindowMenu();
    
    /* Create SDLMain and make it the app delegate */
    sdlMain = [[SDLMain alloc] init];
    [NSApp setDelegate:sdlMain];
    
    /* Start the main event loop */
    [NSApp run];
    
    [sdlMain release];
    [pool release];
}

#endif

/* Called when the internal event loop has just started running */
- (void) applicationDidFinishLaunching: (NSNotification *) note
{
    int status;
    
	started = YES;
    
#if SDL_USE_NIB_FILE
    /* Set the main menu to contain the real app name instead of "SDL App" */
    [self fixMenu:[NSApp mainMenu] withAppName:[[NSProcessInfo processInfo] processName]];
#endif

	if (fileToLoad) {
		gArgv[gArgc++] = startupFile;
		}
		
    /* Hand off to main application code */
    status = SDLmain (gArgc, gArgv);

    /* We're done, thank you for playing */
    exit(status);
}

/*------------------------------------------------------------------------------
*  application openFile - Open a file dragged to the application.
*-----------------------------------------------------------------------------*/
- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
    NSString *suffix;
    char *cfilename;
    
    suffix = [filename pathExtension];
	
	if (started) {
		if ([suffix isEqualToString:@"t8s"] || [suffix isEqualToString:@"T8S"]) {
			cfilename = malloc(FILENAME_MAX);
			[filename getCString:cfilename];
			[[ControlManager sharedInstance] pushUserEvent:MAC_LOAD_STATE_EVENT:cfilename];
			}
		else if ([suffix isEqualToString:@"t8c"] || [suffix isEqualToString:@"T8C"]) {
			cfilename = malloc(FILENAME_MAX);
			[filename getCString:cfilename];
			[[ControlManager sharedInstance] pushUserEvent:MAC_READ_CONFIG_EVENT:cfilename];
			}
		}
	else {
		if ([suffix isEqualToString:@"t8s"] || [suffix isEqualToString:@"T8S"] ||
			[suffix isEqualToString:@"t8c"] || [suffix isEqualToString:@"T8C"]) 
			fileToLoad = TRUE;
        [filename getCString:startupFile];
		}
    return(FALSE);
}

/*------------------------------------------------------------------------------
*  applicationDidBecomeActive - Called when we are no longer hidden.
*-----------------------------------------------------------------------------*/
- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
	trs_pause_audio(0);
}


/*------------------------------------------------------------------------------
*  applicationDidResignActive - Called when we are hidden.
*-----------------------------------------------------------------------------*/
- (void)applicationDidResignActive:(NSNotification *)aNotificatio
{
	trs_pause_audio(1);
}

@end


@implementation NSString (ReplaceSubString)

- (NSString *)stringByReplacingRange:(NSRange)aRange with:(NSString *)aString
{
    unsigned int bufferSize;
    unsigned int selfLen = [self length];
    unsigned int aStringLen = [aString length];
    unichar *buffer;
    NSRange localRange;
    NSString *result;

    bufferSize = selfLen + aStringLen - aRange.length;
    buffer = NSAllocateMemoryPages(bufferSize*sizeof(unichar));
    
    /* Get first part into buffer */
    localRange.location = 0;
    localRange.length = aRange.location;
    [self getCharacters:buffer range:localRange];
    
    /* Get middle part into buffer */
    localRange.location = 0;
    localRange.length = aStringLen;
    [aString getCharacters:(buffer+aRange.location) range:localRange];
     
    /* Get last part into buffer */
    localRange.location = aRange.location + aRange.length;
    localRange.length = selfLen - localRange.location;
    [self getCharacters:(buffer+aRange.location+aStringLen) range:localRange];
    
    /* Build output string */
    result = [NSString stringWithCharacters:buffer length:bufferSize];
    
    NSDeallocateMemoryPages(buffer, bufferSize);
    
    return result;
}

@end

/* Routine to center the application window */
void centerAppWindow(void)
{
    NSArray *windows;
    NSString *title;
    int numWindows;
    int i;
	static int firstTime = 1;

	windows = [[SDLApplication sharedApplication] windows];
    numWindows = [windows count];

    if (numWindows == 1)
        appWindow = [windows objectAtIndex:0];
    else {
        for (i=0;i<numWindows;i++) {
          title = [[windows objectAtIndex:i] title];
          if ([title length] > 11) {
            if ([[title substringToIndex:11] isEqualTo:@"TRS80 Model"])
              break;
          }
        }
        if (i==numWindows)
            i=0;
        appWindow = [windows objectAtIndex:i];
    }
    
	if (firstTime) {
		NSPoint origin;
		
		origin = [[Preferences sharedInstance] applicationWindowOrigin];

		if (origin.x != 59999.0)
			[appWindow setFrameOrigin:origin];
		else
			[appWindow center];
		firstTime = 0;
	}
	else
		[appWindow center];
}


#ifdef main
#  undef main
#endif

/* Set the working directory to the .app's parent directory */
void setupWorkingDirectory()
{
    char parentdir[MAXPATHLEN];
    char *c;

    strncpy ( parentdir, gArgv[0], sizeof(parentdir) );
    c = (char*) parentdir;

    while (*c != '\0')     /* go to end */
        c++;
    
    while (*c != '/')      /* back up to parent */
        c--;
    
    *c++ = '\0';             /* cut off last part (binary name) */

    if (chdir (parentdir) != 0) printf("Error changing to '%s'\n",parentdir);
    chdir ("../../../");
}


/* Main entry point to executable - should *not* be SDL_main! */
int main (int argc, char **argv)
{

    /* Copy the arguments into a global variable */
    int i;
    
    /* This is passed if we are launched by double-clicking */
    if ( argc >= 2 && strncmp (argv[1], "-psn", 4) == 0 ) {
        gArgc = 1;
	gFinderLaunch = YES;
    } else {
        gArgc = argc;
	gFinderLaunch = NO;
    }
    gArgv = (char**) malloc (sizeof(*gArgv) * (gArgc+1));
    assert (gArgv != NULL);
    for (i = 0; i < gArgc; i++)
        gArgv[i] = argv[i];
    gArgv[i] = NULL;

    /* Set the working directory to the .app's parent directory */
    setupWorkingDirectory();
	
    /* Set the working directory for preferences, so defaults for 
       directories are set correctly */
    [Preferences setWorkingDirectory:gArgv[0]];

#if SDL_USE_NIB_FILE
    [SDLApplication poseAsClass:[NSApplication class]];
    NSApplicationMain (argc, (const char **) argv);
#else
    CustomApplicationMain (argc, argv);
#endif
    return 0;
}
