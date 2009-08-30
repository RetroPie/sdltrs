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

#import "DebuggerManager.h"
#import "Preferences.h"
#import "SDL.h"
#import <stdarg.h>

extern void PauseAudio(int pause);
extern int debuggerCmd(char *input);

/* Functions which provide an interface for C code to call this object's shared Instance functions */

void MessagePrint(char *string)
{
	[[DebuggerManager sharedInstance] messagePrint:string];
}

void DebuggerPrintf(const char *format,...)
{
	static char string[4096];
	va_list arguments;             
    va_start(arguments, format);  
    
	vsprintf(string, format, arguments);
    [[DebuggerManager sharedInstance] debuggerPrint:string];
}

char *DebuggerInput()
{
    return([[DebuggerManager sharedInstance] debuggerInput]);
}


@implementation DebuggerManager
static DebuggerManager *sharedInstance = nil;
#define MAX_MONITOR_OUTPUT 4096
static char debuggerOutput[MAX_MONITOR_OUTPUT];
static int debuggerCharCount = 0;
static char debuggerInput[256];

+ (DebuggerManager *)sharedInstance {
    return sharedInstance ? sharedInstance : [[self alloc] init];
}

- (id)init {
    NSDictionary *attribs;
	int i;

    if (sharedInstance) {
	[self dealloc];
    } else {
        [super init];
        sharedInstance = self;
        if (!debuggerInputField) {
			if (![NSBundle loadNibNamed:@"DebuggerManager" owner:self])  {
				NSLog(@"Failed to load DebuggerManager.nib");
				NSBeep();
				return nil;
			}
        }
	[[debuggerInputField window] setExcludedFromWindowsMenu:YES];
	[[debuggerInputField window] setMenu:nil];
	[[messageOutputView window] setExcludedFromWindowsMenu:NO];

	attribs = [[NSDictionary alloc] initWithObjectsAndKeys:
                   [NSFont fontWithName:@"Monaco" size:10.0], NSFontAttributeName,
                   nil]; 
    [debuggerOutputView setTypingAttributes:attribs];
    [messageOutputView setTypingAttributes:attribs];
    [debuggerOutputView setString:@"sdltrs Debugger\nType '?' for help, 'CONT' to exit\n"];
    [attribs release];
	
	// Init Monitor Command History
    historyIndex = 0;
    historyLine = 0;
    historySize = 0;
    for (i = 0; i < kHistorySize; i++)
       history[i] = nil;
    }
    
    return sharedInstance;
}

/*------------------------------------------------------------------------------
*  debuggerExecute - This method handles the execute button (or return key) from
*     the debugger window.
*-----------------------------------------------------------------------------*/
- (IBAction)debuggerExecute:(id)sender
{
	NSString *line;
   
    line = [debuggerInputField stringValue];
	[self addToHistory:line];
    [line getCString:debuggerInput];
    
    debuggerCharCount = 0;
    [self debuggerPrint:debuggerInput];
    [self debuggerPrint:"\n"];

    [NSApp stopModalWithCode:0];
}

/*------------------------------------------------------------------------------
*  messageWindowShow - This method makes the emulator message window visable
*-----------------------------------------------------------------------------*/
- (void)messageWindowShow:(id)sender
{
 	static int firstTime = 1;
	
	if (firstTime) {
		[[messageOutputView window] setFrameOrigin:[[Preferences sharedInstance] messagesOrigin]];
		firstTime = 0;
		}

    [[messageOutputView window] makeKeyAndOrderFront:self];
	[[messageOutputView window] setTitle:@"Emulator Messages"];
	
}


/*------------------------------------------------------------------------------
*  messagePrint - This method handles the printing of information to the
*     message window.  It replaces printf.
*-----------------------------------------------------------------------------*/
- (void)messagePrint:(char *)printString
{
    NSRange theEnd;
    NSString *stringObj;

    theEnd=NSMakeRange([[messageOutputView string] length],0);
    stringObj = [[NSString alloc] initWithCString:printString];
    [messageOutputView replaceCharactersInRange:theEnd withString:stringObj]; // append new string to the end
    theEnd.location += strlen(printString); // the end has moved
	[stringObj autorelease];
    [messageOutputView scrollRangeToVisible:theEnd];
}

/*------------------------------------------------------------------------------
*  debuggerPrint - This method handles the printing of information from the
*     debugger routines.  It replaces printf.
*-----------------------------------------------------------------------------*/
- (void)debuggerPrint:(char *)string
{
    strncpy(&debuggerOutput[debuggerCharCount], string, MAX_MONITOR_OUTPUT - debuggerCharCount);
    debuggerCharCount += strlen(string);
}

/*------------------------------------------------------------------------------
*  debuggerRun - This method displays the debugger output and gets the next 
*     command from the debugger window.
*-----------------------------------------------------------------------------*/
-(char *)debuggerInput
{
    int retValue = 0;
    NSRange theEnd;
    NSString *stringObj;
	static int firstTime = 1;
	
	if (firstTime) {
		[[debuggerOutputView window] setFrameOrigin:[[Preferences sharedInstance] debuggerOrigin]];
		firstTime = 0;
		}

    [self debuggerPrint:"> "];
    theEnd=NSMakeRange([[debuggerOutputView string] length],0);
    stringObj = [[NSString alloc] initWithCString:debuggerOutput];
    [debuggerOutputView replaceCharactersInRange:theEnd withString:stringObj]; // append new string to the end
    theEnd.location += debuggerCharCount; // the end has moved
    [debuggerOutputView scrollRangeToVisible:theEnd];
    
    [[debuggerOutputView window] makeKeyAndOrderFront:self];
    retValue = [NSApp runModalForWindow:[debuggerOutputView window]];
    theEnd=NSMakeRange([[debuggerOutputView string] length],0);
    [stringObj release];
    stringObj = [[NSString alloc] initWithCString:debuggerOutput];
    [debuggerOutputView replaceCharactersInRange:theEnd withString:stringObj]; // append new string to the end
    theEnd.location += debuggerCharCount; // the end has moved
    [debuggerOutputView scrollRangeToVisible:theEnd];
	[debuggerInputField setStringValue:@""];
	[[debuggerInputField window] makeFirstResponder:debuggerInputField];
	    
    debuggerCharCount = 0;
    [[debuggerInputField window] close];

    return(debuggerInput);
}

/*------------------------------------------------------------------------------
*  debuggerUpArrow - Handle the user pressing the up arrow in the debugger window
*-----------------------------------------------------------------------------*/
- (void)debuggerUpArrow
{
	[self historyScroll:1];
}

/*------------------------------------------------------------------------------
*  debuggerDownArrow - Handle the user pressing the down arrow in the debugger 
*      window
*-----------------------------------------------------------------------------*/
- (void)debuggerDownArrow
{
	[self historyScroll:-1];
}

/*------------------------------------------------------------------------------
*  addToHistory - Add the current command to the history list
*-----------------------------------------------------------------------------*/
- (void)addToHistory:(NSString *)str
{
	[str retain];
	[history[historyIndex] release];
	history[historyIndex] = str;
    historyIndex = (historyIndex + 1) % kHistorySize;
	historyLine = 0;
	
	if (historySize < kHistorySize)
		historySize++;
}

/*------------------------------------------------------------------------------
*  historyScroll - Scroll through the commands in the history in the specified
*     direction.
*-----------------------------------------------------------------------------*/
- (void)historyScroll:(int)direction
{
	NSString *historyString;
	
	historyString = [self getHistoryString:direction];
	
	if (historyString == nil)
		return;
		
	[debuggerInputField setStringValue:historyString];
}

/*------------------------------------------------------------------------------
*  getHistoryString - Get the next histroy string in the specified direction
*    from the current one.
*-----------------------------------------------------------------------------*/
- (NSString *)getHistoryString:(int)direction
{
	int line;
	int index;
	
	if (historySize == 0)
		return nil;

	// Advance to the next line in the history
	line = historyLine + direction;
	if ((direction < 0 && line <= 0) || (direction > 0 && line > historySize))
		return nil;
	historyLine = line;
	
	if (historyLine > 0)
		index = (historyIndex - historyLine + historySize) % historySize;
	else
		index = historyIndex;
	
	return(history[index]);
}

/*------------------------------------------------------------------------------
*  messagesOriginSave - This method saves the position of the messages
*    window
*-----------------------------------------------------------------------------*/
- (NSPoint)messagesOriginSave
{
	NSRect frame;
	
	frame = [[messageOutputView window] frame];
	return(frame.origin);
}

/*------------------------------------------------------------------------------
*  debuggerOriginSave - This method saves the position of the monitor
*    window
*-----------------------------------------------------------------------------*/
- (NSPoint)debuggerOriginSave
{
	NSRect frame;
	
	frame = [[debuggerOutputView window] frame];
	return(frame.origin);
}



@end
