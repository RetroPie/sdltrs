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

#import "PasteManager.h"
extern int trs_paste_started();

int PasteManagerStartPaste(void)
{
	return([[PasteManager sharedInstance] startPaste]);
}

int PasteManagerGetChar(unsigned short *character)
{
	return([[PasteManager sharedInstance] getChar:character]);
}

void PasteManagerStartCopy(char *string)
{
	[[PasteManager sharedInstance] startCopy:string];
}

@implementation PasteManager
static PasteManager *sharedInstance = nil;

+ (PasteManager *)sharedInstance {
    return sharedInstance ? sharedInstance : [[self alloc] init];
}

- (id)init {	
    if (sharedInstance) {
		[self dealloc];
    } else {
        [super init];
        sharedInstance = self;
		charCount = 0;
    }
    return sharedInstance;
}

- (int)getChar:(unsigned short *) character
{
	if (charCount) {
		*character = [pasteString characterAtIndex:([pasteString length] - charCount)];
		charCount--;
		if (charCount)
			return(TRUE);
		else {
			[pasteString release];
			return(FALSE);
			}
		}
	else {
		return(FALSE);
		}
}

- (int)startPaste {
	NSPasteboard *pb = [NSPasteboard generalPasteboard];
	NSArray *pasteTypes = [NSArray arrayWithObjects: NSStringPboardType, nil];
	NSString *bestType = [pb availableTypeFromArray:pasteTypes];

	if (bestType != nil) {
		pasteString = [pb stringForType:bestType];
		charCount = [pasteString length];
		[pasteString retain];
		trs_paste_started();
		return TRUE;
		}
	else {
		pasteString = nil;
		charCount = 0;
		return FALSE;
		}
	}

- (void)startCopy:(char *)string
{
	NSPasteboard *pb = [NSPasteboard generalPasteboard];
	NSArray *types = [NSArray arrayWithObjects:
					  NSStringPboardType, nil];
	[pb declareTypes:types owner:self];
	[pb setString:[NSString stringWithCString:string] forType:NSStringPboardType];
}

@end
