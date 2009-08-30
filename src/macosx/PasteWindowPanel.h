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

#import "SDL.h"
extern void trs_end_copy();
extern void trs_select_all();
extern char *trs_get_copy_data();

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
 *  validateUserInterfaceItem - Verifies there is text in the clipboard to paste
 *-----------------------------------------------------------------------------*/
- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
    SEL theAction = [anItem action];
	NSPasteboard *pb = [NSPasteboard generalPasteboard];
	NSArray *pasteTypes = [NSArray arrayWithObjects: NSStringPboardType, nil];
	NSString *bestType = [pb availableTypeFromArray:pasteTypes];
	
    if (theAction == @selector(paste:))
    {
        if (bestType != nil)
        {
            return YES;
        }
        return NO;
    } 
    else if (theAction == @selector(copy:))
    {
		return YES;
    } 
    else if (theAction == @selector(selectAll:))
    {
		return YES;
    } 
	else
		return NO;
}

/*------------------------------------------------------------------------------
 *  paste - Starts Paste from Mac to TRS
 *-----------------------------------------------------------------------------*/
- (void) paste:(id) sender
{
	[[PasteManager sharedInstance] startPaste];
}

/*------------------------------------------------------------------------------
 *  copy - Starts copy from TRS to Mac
 *-----------------------------------------------------------------------------*/
- (void) copy:(id) sender
{
	char *string;
	
	string = trs_get_copy_data();
	[[PasteManager sharedInstance] startCopy:string];
	trs_end_copy();
}

/*------------------------------------------------------------------------------
 *  select all - Starts Select All from Mac to TRS
 *-----------------------------------------------------------------------------*/
- (void) selectAll:(id) sender
{
	trs_select_all();
}


