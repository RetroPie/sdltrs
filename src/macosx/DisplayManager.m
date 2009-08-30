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

#import "DisplayManager.h"
#import "SDL.h"

/* Functions which provide an interface for C code to call this object's shared Instance functions */
@implementation DisplayManager

static DisplayManager *sharedInstance = nil;

+ (DisplayManager *)sharedInstance {
    return sharedInstance ? sharedInstance : [[self alloc] init];
}

- (id)init {
    if (sharedInstance) {
	[self dealloc];
    } else {
        [super init];
        sharedInstance = self;
    }
    return sharedInstance;
}

- (void)dealloc {
	[super dealloc];
}

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

/*------------------------------------------------------------------------------
*  fullScreen - This method handles the windowed/fullscreen menu selection.
*-----------------------------------------------------------------------------*/
- (IBAction)fullScreen:(id)sender
{
	[self pushKeyEvent:SDLK_RETURN:NO:YES];
}

/*------------------------------------------------------------------------------
*  screenBigger - This method handles the windowed/fullscreen menu selection.
*-----------------------------------------------------------------------------*/
- (IBAction)screenBigger:(id)sender
{
	[self pushKeyEvent:SDLK_EQUALS:NO:YES];
}

/*------------------------------------------------------------------------------
*  fullScreen - This method handles the windowed/fullscreen menu selection.
*-----------------------------------------------------------------------------*/
- (IBAction)screenSmaller:(id)sender
{
	[self pushKeyEvent:SDLK_MINUS:NO:YES];
}


@end
