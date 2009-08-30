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

#import "AboutBox.h";


@implementation AboutBox

static AboutBox *sharedInstance = nil;

+ (AboutBox *)sharedInstance
{
    return sharedInstance ? sharedInstance : [[self alloc] init];
}

- (id)init 
{
    if (sharedInstance) {
        [self dealloc];
    } else {
        sharedInstance = [super init];
    }
    
    return sharedInstance;
}

/*------------------------------------------------------------------------------
*  showPanel - Display the About Box.
*-----------------------------------------------------------------------------*/
- (IBAction)showPanel:(id)sender
{
    NSRect creditsBounds;
	
    if (!appNameField)
    {
        NSWindow *theWindow;
        NSString *creditsPath;
        NSAttributedString *creditsString;
        NSString *appName;
        NSString *versionString;
        NSDictionary *infoDictionary;
        CFBundleRef localInfoBundle;
        NSDictionary *localInfoDict;

        if (![NSBundle loadNibNamed:@"AboutBox" owner:self])
        {
            NSLog( @"Failed to load AboutBox.nib" );
            NSBeep();
            return;
        }
        theWindow = [appNameField window];

        // Get the info dictionary (Info.plist)
        infoDictionary = [[NSBundle mainBundle] infoDictionary];

		        
        // Get the localized info dictionary (InfoPlist.strings)
        localInfoBundle = CFBundleGetMainBundle();
        localInfoDict = (NSDictionary *)
                        CFBundleGetLocalInfoDictionary( localInfoBundle );

        // Setup the app name field
        appName = @"sdltrs";
        [appNameField setStringValue:appName];

        // Set the about box window title
        [theWindow setTitle:[NSString stringWithFormat:@"About %@", appName]];

        // Setup the version field
        versionString = [infoDictionary objectForKey:@"CFBundleVersion"];
        [versionField setStringValue:[NSString stringWithFormat:@"Version %@", 
                                                          versionString]];

        // Setup our credits
        creditsPath = [[NSBundle mainBundle] pathForResource:@"Credits" 
                                             ofType:@"html"];

        creditsString = [[NSAttributedString alloc] initWithPath:creditsPath 
                                                    documentAttributes:nil];

        [creditsField replaceCharactersInRange:NSMakeRange( 0, 0 ) 
                      withRTF:[creditsString RTFFromRange:
                               NSMakeRange( 0, [creditsString length] ) 
                                             documentAttributes:nil]];

        // Prepare some scroll info
		creditsBounds = [creditsField bounds];
        maxScrollHeight = creditsBounds.size.height*2.75;

        // Setup the window
        [theWindow setExcludedFromWindowsMenu:YES];
        [theWindow setMenu:nil];
        [theWindow center];
		
    }
    
    if (![[appNameField window] isVisible])
    {
        currentPosition = 0;
        restartAtTop = NO;
        [creditsField scrollPoint:NSMakePoint( 0, 0 )];
    }
    
    // Show the window
	[NSApp runModalForWindow:[appNameField window]];
    [[appNameField window] close];
	
}

- (void)OK:(id)sender
{
	[NSApp stopModal];
}

@end

