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
   Last modified on Sun Sep 03 20:27:00 MST 2006 by markgrebe
*/

#import "KeyMapper.h"
#import "SDL.h"


@implementation KeyMapper
static KeyMapper *sharedInstance = nil;

+ (KeyMapper *)sharedInstance {
    return sharedInstance ? sharedInstance : [[self alloc] init];
}

- (id)init {
    const void *KCHRPtr;
    Uint32 state;
    UInt32 value;
    int i;
    int world = SDLK_WORLD_0;

    if (sharedInstance) {
	    [self dealloc];
    } else {
        [super init];
        sharedInstance = self;
		
		for ( i=0; i<128; ++i )
			keymap[i] = SDLK_UNKNOWN;
		
        /* Get a pointer to the systems cached KCHR */
        KCHRPtr = (void *)GetScriptManagerVariable(smKCHRCache);
        if (KCHRPtr)
        {
            /* Loop over all 127 possible scan codes */
            for (i = 0; i < 0x7F; i++)
            {
                /* We pretend a clean start to begin with (i.e. no dead keys active */
                state = 0;

                /* Now translate the key code to a key value */
                value = KeyTranslate(KCHRPtr, i, (UInt32*)&state) & 0xff;

                /* If the state become 0, it was a dead key. We need to translate again,
                    passing in the new state, to get the actual key value */
                if (state != 0)
                    value = KeyTranslate(KCHRPtr, i,(UInt32*) &state) & 0xff;

                /* Now we should have an ascii value, or 0. Try to figure out to which SDL symbol it maps */
                if (value >= 128)     /* Some non-ASCII char, map it to SDLK_WORLD_* */
                    keymap[i] = world++;
                else if (value >= 32)     /* non-control ASCII char */
                    keymap[i] = value;
            }
		}
 	}
    return sharedInstance;
}

/*------------------------------------------------------------------------------
*  releaseCmdKeys - This method fixes an issue when modal windows are used with
*     the Mac OSX version of the SDL library.
*     As the SDL normally captures all keystrokes, but we need to type in some 
*     Mac windows, all of the control menu windows run in modal mode.  However, 
*     when this happens, the release of the command key and the shortcut key 
*     are not sent to SDL.  We have to manually cause these events to happen 
*     to keep the SDL library in a sane state, otherwise only everyother shortcut
*     keypress will work.
*-----------------------------------------------------------------------------*/
- (void) releaseCmdKeys:(NSString *)character
{
    NSEvent *event1, *event2;
    NSPoint point;
    SDL_Event event;
	int keyCode;
	unsigned int charCode;

	charCode = [character characterAtIndex:0];
	keyCode = [self getQuartzKey:charCode];

    event1 = [NSEvent keyEventWithType:NSKeyUp location:point modifierFlags:0
                    timestamp:nil windowNumber:0 context:nil characters:character
                    charactersIgnoringModifiers:character isARepeat:NO keyCode:keyCode];
    [NSApp postEvent:event1 atStart:NO];
    
    event2 = [NSEvent keyEventWithType:NSFlagsChanged location:point modifierFlags:0
                    timestamp:nil windowNumber:0 context:nil characters:nil
                    charactersIgnoringModifiers:nil isARepeat:NO keyCode:0];
    [NSApp postEvent:event2 atStart:NO];
	
	SDL_PollEvent(&event);
}

-(unsigned int)getQuartzKey:(unsigned int) character;
{
	int i;
	
	for (i=0;i<128;i++) {
		if (keymap[i] == character)
			return(i);
	}
	
	return 0;
}


@end
