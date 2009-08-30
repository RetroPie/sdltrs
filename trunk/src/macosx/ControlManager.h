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

#import <Cocoa/Cocoa.h>

@interface ControlManager : NSObject
{
    IBOutlet id coldResetItem;
    IBOutlet id warmResetItem;
    IBOutlet id loadStateItem;
    IBOutlet id saveStateItem;
    IBOutlet id pauseItem;
	IBOutlet id modelMenu;
	IBOutlet id graphicsMenu;
	IBOutlet id startButton;
}
+ (ControlManager *)sharedInstance;
-(void)pushKeyEvent:(int)key:(bool)shift:(bool)cmd;
-(void)pushUserEvent:(int)code:(void *)data;
- (NSString *) browseFileTypeInDirectory:(NSString *)directory:(NSArray *) filetypes;
- (NSString *) saveFileInDirectory:(NSString *)directory:(NSString *)type;
- (IBAction)coldReset:(id)sender;
- (IBAction)warmReset:(id)sender;
- (IBAction)debugger:(id)sender;
- (IBAction)loadState:(id)sender;
- (IBAction)saveState:(id)sender;
- (IBAction)readConfig:(id)sender;
- (IBAction)writeConfig:(id)sender;
- (IBAction)pause:(id)sender;
- (IBAction)changeModel:(id)sender;
- (IBAction)changeGraphics:(id)sender;
- (void)setModelMenu:(int)model:(int)micrographyx;
- (IBAction)showAboutBox:(id)sender;
- (IBAction)showDonation:(id)sender;
@end
