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

#import "ControlManager.h"
#import "Preferences.h"
#import "MediaManager.h"
#import "AboutBox.h"
#import "KeyMapper.h"
#import "SDL.h"
#import "trs.h"
#import "trs_cassette.h"
#import "trs_mac_interface.h"
#import "trs_sdl_gui.h"


/* Definition of Mac native keycodes for characters used as menu shortcuts the bring up a windo. */
#define QZ_a			0x00
#define QZ_l			0x25
#define QZ_m			0x2E
#define QZ_s			0x01
#define QZ_h			0x04
#define QZ_SLASH		0x2C
#define QZ_F8			0x64
#define QZ_r			0x0F
#define QZ_w			0x0D


extern int FULLSCREEN;


/* Functions which provide an interface for C code to call this object's shared Instance functions */
void SetControlManagerModel(int model, int micrographyx) {
    [[ControlManager sharedInstance] setModelMenu:(model):(micrographyx)];
}

void SetControlManagerTurboMode(int turbo) {
    [[ControlManager sharedInstance] setTurboMenu:(turbo)];
}

void ControlManagerSaveState() {
    [[ControlManager sharedInstance] saveState:nil];
}

void ControlManagerLoadState() {
    [[ControlManager sharedInstance] loadState:nil];
}

void ControlManagerWriteConfig() {
    [[ControlManager sharedInstance] writeConfig:nil];
}

void ControlManagerReadConfig() {
    [[ControlManager sharedInstance] readConfig:nil];
}

void ControlManagerPauseEmulator() {
    [[ControlManager sharedInstance] pause:nil];
}

void ControlManagerHideApp() {
    [NSApp hide:[ControlManager sharedInstance]];
    [[KeyMapper sharedInstance] releaseCmdKeys:@"h"];
}

void ControlManagerAboutApp() {
    [NSApp orderFrontStandardAboutPanel:[ControlManager sharedInstance]];
    [[KeyMapper sharedInstance] releaseCmdKeys:@"a"];
}

void ControlManagerShowHelp() {
    [NSApp showHelp:[ControlManager sharedInstance]];
    [[KeyMapper sharedInstance] releaseCmdKeys:@"?"];
}

void ControlManagerMiniturize() {
    [[NSApp keyWindow] performMiniaturize:[ControlManager sharedInstance]];
    [[KeyMapper sharedInstance] releaseCmdKeys:@"m"];
}

@implementation ControlManager
static ControlManager *sharedInstance = nil;

+ (ControlManager *)sharedInstance {
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

-(void)pushUserEvent:(int)code:(void *)data
{
	SDL_Event theEvent;
    
    theEvent.type = SDL_USEREVENT;
    theEvent.user.code = code;
    theEvent.user.data1 = data;

	SDL_PushEvent(&theEvent);
}

/*------------------------------------------------------------------------------
*  setModelMenu - This method is used to set the menu check state for the 
*     Model Type menu items.
*-----------------------------------------------------------------------------*/
- (void)setModelMenu:(int)model:(int)micrographyx;
{
	int i, modelIndex;
    
    if (model == 1)
        modelIndex = 0;
    else if (model == 5)
        modelIndex = 3;
    else
        modelIndex = model-2;
    
	for (i=0;i<4;i++) {
		if (i==modelIndex)
			[[modelMenu itemAtIndex:i] setState:NSOnState];
		else
			[[modelMenu itemAtIndex:i] setState:NSOffState];
		}
	for (i=0;i<2;i++) {
		if (i==micrographyx)
			[[graphicsMenu itemAtIndex:i] setState:NSOnState];
		else
			[[graphicsMenu itemAtIndex:i] setState:NSOffState];
		}
}

- (void)setTurboMenu:(int)turbo
{
	if (turbo)
		[turboItem setState:NSOnState];
	else 
		[turboItem setState:NSOffState];
}


- (IBAction)changeModel:(id)sender 
{
    [self pushUserEvent:MAC_CHANGE_MODEL_EVENT:(void*)[sender tag]];
}

- (IBAction)changeGraphics:(id)sender 
{
    [self pushUserEvent:MAC_CHANGE_GRAPHICS_EVENT:(void*)[sender tag]];
}


/*------------------------------------------------------------------------------
*  browseFileTypeInDirectory - This allows the user to chose a file of a 
*     specified typeto read in from the specified directory.
*-----------------------------------------------------------------------------*/
- (NSString *) browseFileTypeInDirectory:(NSString *)directory:(NSArray *) filetypes {
    NSOpenPanel *openPanel = nil;
	
    openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    
    if ([openPanel runModalForDirectory:directory file:nil 
            types:filetypes] == NSOKButton)
        return([[openPanel filenames] objectAtIndex:0]);
    else
        return nil;
    }

/*------------------------------------------------------------------------------
*  saveFileInDirectory - This allows the user to chose a filename to save in from
*     the specified directory.
*-----------------------------------------------------------------------------*/
- (NSString *) saveFileInDirectory:(NSString *)directory:(NSString *)type {
    NSSavePanel *savePanel = nil;
    
    savePanel = [NSSavePanel savePanel];
    
    [savePanel setRequiredFileType:type];
    
    if ([savePanel runModalForDirectory:directory file:nil] == NSOKButton)
        return([savePanel filename]);
    else
        return nil;
    }

/*------------------------------------------------------------------------------
*  coldReset - This method handles the cold reset menu selection.
*-----------------------------------------------------------------------------*/
- (IBAction)coldReset:(id)sender
{
	[self pushKeyEvent:SDLK_F10:YES:NO];
}

/*------------------------------------------------------------------------------
*  warmReset - This method handles the warm reset menu selection.
*-----------------------------------------------------------------------------*/
- (IBAction)warmReset:(id)sender
{
	[self pushKeyEvent:SDLK_F10:NO:NO];
}

/*------------------------------------------------------------------------------
 *  debugger - This method handles the debugger menu selection.
 *-----------------------------------------------------------------------------*/
- (IBAction)debugger:(id)sender
{
	[self pushKeyEvent:SDLK_F9:NO:NO];
}

/*------------------------------------------------------------------------------
 *  turbo - This method handles the turbo mode menu selection.
 *-----------------------------------------------------------------------------*/
- (IBAction)turbo:(id)sender
{
	[self pushKeyEvent:SDLK_F11:NO:NO];
}

/*------------------------------------------------------------------------------
*  loadState - This method handles the load state file menu selection.
*-----------------------------------------------------------------------------*/
- (IBAction)loadState:(id)sender
{
    NSString *filename;
    char *cfilename;
    char browseDir[FILENAME_MAX];
    
    trs_pause_audio(1);
    trs_expand_dir(trs_state_dir, browseDir);
    filename = [self browseFileTypeInDirectory:[NSString stringWithCString:browseDir]:
                [NSArray arrayWithObjects:@"t8s",@"T8S",nil]];
    if (filename != nil) {
        cfilename = malloc(FILENAME_MAX);
        [filename getCString:cfilename];
        [self pushUserEvent:MAC_LOAD_STATE_EVENT:cfilename];
    }
    [[KeyMapper sharedInstance] releaseCmdKeys:@"l"];
    trs_pause_audio(0);
}

/*------------------------------------------------------------------------------
*  saveState - This method handles the save state file menu selection.
*-----------------------------------------------------------------------------*/
- (IBAction)saveState:(id)sender
{
    NSString *filename;
    char *cfilename;
    char browseDir[FILENAME_MAX];
    
    trs_pause_audio(1);
    trs_expand_dir(trs_state_dir, browseDir);
    filename = [self saveFileInDirectory:[NSString stringWithCString:browseDir]:@"t8s"];
    if (filename != nil) {
        cfilename = malloc(FILENAME_MAX);
        [filename getCString:cfilename];
        [self pushUserEvent:MAC_SAVE_STATE_EVENT:cfilename];
    }
    [[KeyMapper sharedInstance] releaseCmdKeys:@"s"];
    trs_pause_audio(0);
}

/*------------------------------------------------------------------------------
*  readConfig - This method handles the read config file menu selection.
*-----------------------------------------------------------------------------*/
- (IBAction)readConfig:(id)sender
{
    NSString *filename;
    char *cfilename;
    char browseDir[FILENAME_MAX];
    
    trs_pause_audio(1);
    trs_expand_dir(".", browseDir);
    filename = [self browseFileTypeInDirectory:[NSString stringWithCString:browseDir]:
                [NSArray arrayWithObjects:@"t8c",@"T8C",nil]];
    if (filename != nil) {
        cfilename = malloc(FILENAME_MAX);
        [filename getCString:cfilename];
        [self pushUserEvent:MAC_READ_CONFIG_EVENT:cfilename];
    }
    [[KeyMapper sharedInstance] releaseCmdKeys:@"r"];
    trs_pause_audio(0);
}

/*------------------------------------------------------------------------------
*  writeConfig - This method handles the write config file menu selection.
*-----------------------------------------------------------------------------*/
- (IBAction)writeConfig:(id)sender
{
    NSString *filename;
    char *cfilename;
    char browseDir[FILENAME_MAX];
    
    trs_pause_audio(1);
    trs_expand_dir(".", browseDir);
    filename = [self saveFileInDirectory:[NSString stringWithCString:browseDir]:@"t8c"];
    if (filename != nil) {
        cfilename = malloc(FILENAME_MAX);
        [filename getCString:cfilename];
        [self pushUserEvent:MAC_WRITE_CONFIG_EVENT:cfilename];
    }
    [[KeyMapper sharedInstance] releaseCmdKeys:@"w"];
    trs_pause_audio(0);
}

/*------------------------------------------------------------------------------
*  pause - This method handles the pause emulator menu selection.
*-----------------------------------------------------------------------------*/
- (IBAction)pause:(id)sender
{
    if (!trs_paused)
        [pauseItem setState:NSOnState];
    else
        [pauseItem setState:NSOffState];
	[self pushKeyEvent:SDLK_p:NO:YES];
}

/*------------------------------------------------------------------------------
*  showAboutBox - Show the about box
*-----------------------------------------------------------------------------*/
- (IBAction)showAboutBox:(id)sender
{
	[[AboutBox sharedInstance] showPanel:sender];
}

/*------------------------------------------------------------------------------
*  showDonation - Show the donation page in the web browser.
*-----------------------------------------------------------------------------*/
- (IBAction)showDonation:(id)sender;
{
	[[NSWorkspace  sharedWorkspace] openURL:
		[NSURL URLWithString:@"http://order.kagi.com/?6FBTU&lang=en"]];
}

@end
