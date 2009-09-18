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
#import <SDL.h>
#import "Preferences.h"
#import "MediaManager.h"
#import "DebuggerManager.h"
#import "KeyMapper.h"
#import "trs.h"
#import "trs_mac_interface.h"

#define QZ_COMMA		0x2B

extern void trs_pause_audio(int pause);
extern ATARI1020_PREF prefs1020;
extern EPSON_PREF prefsEpson;
extern NSWindow *appWindow;

static char workingDirectory[FILENAME_MAX];
static char model1RomFileStr[FILENAME_MAX], model3RomFileStr[FILENAME_MAX], model4pRomFileStr[FILENAME_MAX];
static char diskImageDirStr[FILENAME_MAX],diskSetDirStr[FILENAME_MAX], cassImageDirStr[FILENAME_MAX];
static char hardImageDirStr[FILENAME_MAX], savedStateDirStr[FILENAME_MAX],printDirStr[FILENAME_MAX];

void RunPreferences() {
    [[Preferences sharedInstance] showPanel:[Preferences sharedInstance]];
    [[KeyMapper sharedInstance] releaseCmdKeys:@","];
}

void ReturnPreferences(MAC_PREFS *mac_prefs) {
    [[Preferences sharedInstance] transferValuesFromEmulator];
} 

void GetPreferences() {
    [[Preferences sharedInstance] transferValuesToEmulator];
} 

void PreferencesSaveDefaults(void) {
    [[Preferences sharedInstance] saveDefaults];
} 

/*------------------------------------------------------------------------------
*  defaultValues - This method sets up the default values for the preferences
*-----------------------------------------------------------------------------*/
static NSDictionary *defaultValues() {
    static NSDictionary *dict = nil;
    
    strcpy(printDirStr, workingDirectory);
    strcpy(model1RomFileStr, workingDirectory);
    strcat(model1RomFileStr, "/level2.rom");
    strcpy(model3RomFileStr, workingDirectory);
    strcat(model3RomFileStr, "/model3.rom");
    strcpy(model4pRomFileStr, workingDirectory);
    strcat(model4pRomFileStr, "/model4p.rom");
    strcpy(diskImageDirStr, workingDirectory);
    strcat(diskImageDirStr, "/disks");
    strcpy(diskSetDirStr, workingDirectory);
    strcat(diskSetDirStr, "/disksets");
    strcpy(hardImageDirStr, workingDirectory);
    strcat(hardImageDirStr, "/harddisks");
    strcpy(cassImageDirStr, workingDirectory);
    strcat(cassImageDirStr, "/cassettes");
    strcpy(savedStateDirStr, workingDirectory);
    strcat(savedStateDirStr, "/savedstates");
    strcpy(printDirStr, workingDirectory);
    strcat(printDirStr, "/printer");
    
    if (!dict) {
        dict = [[NSDictionary alloc] initWithObjectsAndKeys:
                // Display Items
                [NSNumber numberWithBool:NO], FullScreen, 
                [NSNumber numberWithInt:1], ScaleFactor, 
                [NSNumber numberWithInt:2], BorderWidth, 
                [NSNumber numberWithBool:YES], Resize3, 
                [NSNumber numberWithBool:NO], Resize4, 
				[NSNumber numberWithFloat:1.0],ForeRed,
				[NSNumber numberWithFloat:1.0],ForeBlue,
				[NSNumber numberWithFloat:1.0],ForeGreen,
				[NSNumber numberWithFloat:1.0],ForeAlpha,
				[NSNumber numberWithFloat:0.0],BackRed,
				[NSNumber numberWithFloat:0.0],BackBlue,
				[NSNumber numberWithFloat:0.0],BackGreen,
				[NSNumber numberWithFloat:1.0],BackAlpha,
				[NSNumber numberWithFloat:1.0],GuiForeRed,
				[NSNumber numberWithFloat:1.0],GuiForeBlue,
				[NSNumber numberWithFloat:1.0],GuiForeGreen,
				[NSNumber numberWithFloat:1.0],GuiForeAlpha,
				[NSNumber numberWithFloat:0.0],GuiBackRed,
				[NSNumber numberWithFloat:0.0625],GuiBackBlue,
				[NSNumber numberWithFloat:0.5],GuiBackGreen,
				[NSNumber numberWithFloat:1.0],GuiBackAlpha,
				[NSNumber numberWithBool:YES], LedStatus,
                [NSNumber numberWithInt:3],Model1Font, 
                [NSNumber numberWithInt:0],Model3Font, 
                [NSNumber numberWithInt:1],Model4Font,
                // TRS Items 
                [NSNumber numberWithInt:0],TrsModel,
                [NSNumber numberWithInt:0],GraphicsModel,
                [NSNumber numberWithInt:0],ShiftBracket,
                [NSNumber numberWithInt:4000],Keystretch,
                [NSNumber numberWithInt:0x6F],SerialSwitches,
                [NSString stringWithString:@""],SerialPort,
                [NSNumber numberWithInt:0], Disk1Size,
                [NSNumber numberWithInt:0], Disk2Size,
                [NSNumber numberWithInt:0], Disk3Size,
                [NSNumber numberWithInt:0], Disk4Size,
                [NSNumber numberWithInt:1], Disk5Size,
                [NSNumber numberWithInt:1], Disk6Size,
                [NSNumber numberWithInt:1], Disk7Size,
                [NSNumber numberWithInt:1], Disk8Size,
                [NSNumber numberWithInt:3], DoublerType,
                [NSNumber numberWithBool:NO], TrueDam,
                [NSNumber numberWithInt:0],EmtSafe,
                // Printer Items 
                [NSString stringWithString:@"open %s"],PrintCommand,
				[NSNumber numberWithInt:0],PrinterType,
				[NSNumber numberWithInt:0],Atari1020PrintWidth,
				[NSNumber numberWithInt:11],Atari1020FormLength,
				[NSNumber numberWithBool:YES],Atari1020AutoLinefeed,
				[NSNumber numberWithBool:YES],Atari1020AutoPageAdjust,
				[NSNumber numberWithFloat:0.0],Atari1020Pen1Red,
				[NSNumber numberWithFloat:0.0],Atari1020Pen1Blue,
				[NSNumber numberWithFloat:0.0],Atari1020Pen1Green,
				[NSNumber numberWithFloat:1.0],Atari1020Pen1Alpha,
				[NSNumber numberWithFloat:0.0],Atari1020Pen2Red,
				[NSNumber numberWithFloat:1.0],Atari1020Pen2Blue,
				[NSNumber numberWithFloat:0.0],Atari1020Pen2Green,
				[NSNumber numberWithFloat:1.0],Atari1020Pen2Alpha,
				[NSNumber numberWithFloat:0.0],Atari1020Pen3Red,
				[NSNumber numberWithFloat:0.0],Atari1020Pen3Blue,
				[NSNumber numberWithFloat:1.0],Atari1020Pen3Green,
				[NSNumber numberWithFloat:1.0],Atari1020Pen3Alpha,
				[NSNumber numberWithFloat:1.0],Atari1020Pen4Red,
				[NSNumber numberWithFloat:0.0],Atari1020Pen4Blue,
				[NSNumber numberWithFloat:0.0],Atari1020Pen4Green,
				[NSNumber numberWithFloat:1.0],Atari1020Pen4Alpha,
				[NSNumber numberWithInt:0],EpsonCharSet,
				[NSNumber numberWithInt:0],EpsonPrintPitch,
				[NSNumber numberWithInt:0],EpsonPrintWeight,
				[NSNumber numberWithInt:11],EpsonFormLength,
				[NSNumber numberWithBool:YES],EpsonAutoLinefeed,
				[NSNumber numberWithBool:NO],EpsonPrintSlashedZeros,
				[NSNumber numberWithBool:NO],EpsonAutoSkip,
				[NSNumber numberWithBool:NO],EpsonSplitSkip,
                // ROM Items
                [NSString stringWithCString:model1RomFileStr], Model1RomFile, 
                [NSString stringWithCString:model3RomFileStr], Model3RomFile, 
                [NSString stringWithCString:model4pRomFileStr], Model4pRomFile,
                // Dir Items 
                [NSString stringWithCString:diskImageDirStr], DiskImageDir, 
                [NSString stringWithCString:hardImageDirStr], HardImageDir, 
                [NSString stringWithCString:cassImageDirStr], CassImageDir, 
                [NSString stringWithCString:diskSetDirStr], DiskSetDir, 
                [NSString stringWithCString:savedStateDirStr], SavedStateDir, 
                [NSString stringWithCString:printDirStr], PrintDir,
                // Joystick Items
				[NSNumber numberWithBool:YES],KeypadJoystick,
                [NSNumber numberWithInt:0],JoystickNumber,
                // Display Position Items 
                [NSNumber numberWithBool:YES], MediaStatusDisplayed, 
				[NSNumber numberWithInt:0], MediaStatusX,
				[NSNumber numberWithInt:0], MediaStatusY,
				[NSNumber numberWithInt:0], MessagesX,
				[NSNumber numberWithInt:0], MessagesY,
				[NSNumber numberWithInt:0], DebuggerX,
				[NSNumber numberWithInt:0], DebuggerY,
				[NSNumber numberWithInt:0], FunctionKeysX,
				[NSNumber numberWithInt:0], FunctionKeysY,
				[NSNumber numberWithInt:59999], ApplicationWindowX,
				[NSNumber numberWithInt:59999], ApplicationWindowY,
		nil];
    }
    return dict;
}

@implementation Preferences

static Preferences *sharedInstance = nil;

+ (Preferences *)sharedInstance {
    return sharedInstance ? sharedInstance : [[self alloc] init];
}

/* The next few factory methods are conveniences, working on the shared instance
*/
+ (id)objectForKey:(id)key {
    return [[[self sharedInstance] preferences] objectForKey:key];
}

+ (void)saveDefaults {
    [[self sharedInstance] saveDefaults];
}

/*------------------------------------------------------------------------------
*  setWorkingDirectory - Sets the working directory to the folder containing the
*     app.
*-----------------------------------------------------------------------------*/
+ (void)setWorkingDirectory:(char *)dir {
    char *c = workingDirectory;

    strncpy ( workingDirectory, dir, sizeof(workingDirectory) );
    
    while (*c != '\0')     /* go to end */
        c++;
    
    while (*c != '/')      /* back up to parent */
        c--;
    c--;
    while (*c != '/')      /* And three more times... */
        c--;
    c--;
    while (*c != '/')      
        c--;
    c--;
    while (*c != '/')      
        c--;
        
    *c = '\0';             /* cut off last part  */
    
    }

/*------------------------------------------------------------------------------
*  getWorkingDirectory - Gets the working directory which is the folder 
*     containing the app.
*-----------------------------------------------------------------------------*/
+ (char *)getWorkingDirectory {
	return(workingDirectory);
    }
        
/*------------------------------------------------------------------------------
*  saveDefaults - Called by the main app class to save the preferences when the
*     program exits.
*-----------------------------------------------------------------------------*/
- (void)saveDefaults {
    NSDictionary *prefs;
	NSPoint origin;

	// Save the window frames 
	origin = [[MediaManager sharedInstance] mediaStatusOriginSave];
	[displayedValues setObject:[NSNumber numberWithFloat:origin.x] forKey:MediaStatusX];
	[displayedValues setObject:[NSNumber numberWithFloat:origin.y] forKey:MediaStatusY];
	origin = [[DebuggerManager sharedInstance] messagesOriginSave];
	[displayedValues setObject:[NSNumber numberWithFloat:origin.x] forKey:MessagesX];
	[displayedValues setObject:[NSNumber numberWithFloat:origin.y] forKey:MessagesY];
	origin = [[DebuggerManager sharedInstance] debuggerOriginSave];
	[displayedValues setObject:[NSNumber numberWithFloat:origin.x] forKey:DebuggerX];
	[displayedValues setObject:[NSNumber numberWithFloat:origin.y] forKey:DebuggerY];
	origin = [self applicationWindowOriginSave];
	[displayedValues setObject:[NSNumber numberWithFloat:origin.x] forKey:ApplicationWindowX];
	[displayedValues setObject:[NSNumber numberWithFloat:origin.y] forKey:ApplicationWindowY];


	// Get the changed prefs back from emulator
	[self transferValuesFromEmulator];
	[self commitDisplayedValues];
	prefs = [self preferences];
	
    if (![origValues isEqual:prefs]) [Preferences savePreferencesToDefaults:prefs];
}

/*------------------------------------------------------------------------------
*  Constructor
*-----------------------------------------------------------------------------*/
- (id)init {
    if (sharedInstance) {
	[self dealloc];
    } else {
        [super init];
        curValues = [[[self class] preferencesFromDefaults] copyWithZone:[self zone]];
        origValues = [curValues retain];
        [self transferValuesToEmulator];
        [self transferValuesToAtari1020];
        [self transferValuesToEpson];
        [self discardDisplayedValues];
        sharedInstance = self;
    }
    return sharedInstance;
}

/*------------------------------------------------------------------------------
*  Destructor
*-----------------------------------------------------------------------------*/
- (void)dealloc {
	[super dealloc];
}

/*------------------------------------------------------------------------------
* preferences - Method to return pointer to current preferences.
*-----------------------------------------------------------------------------*/
- (NSDictionary *)preferences {
    return curValues;
}

/*------------------------------------------------------------------------------
* showPanel - Method to display the preferences window.
*-----------------------------------------------------------------------------*/
- (void)showPanel:(id)sender {
    static int firstTime = 1;
    int i;
    char joystickString[64];
    
    trs_pause_audio(1);

    if (!prefTabView) {
		if (![NSBundle loadNibNamed:@"Preferences" owner:self])  {
			NSLog(@"Failed to load Preferences.nib");
			NSBeep();
			return;
		}
    }
    
    if (firstTime) {
        numJoysticks = SDL_NumJoysticks();
        if (numJoysticks > MAX_JOYSTICKS)
           numJoysticks = MAX_JOYSTICKS;
        [usbJoystickPulldown removeAllItems];  
        [usbJoystickPulldown addItemWithTitle:@"None"];
        for (i=0;i<numJoysticks;i++) {
            sprintf(joystickString,"Joystick %1d - %-47s",i,SDL_JoystickName(i));
            [usbJoystickPulldown addItemWithTitle:
                [NSString stringWithCString:joystickString]];
            }          
        firstTime = 0;
        }

	/* Transfer the changed prefs values back from emulator */
	[self transferValuesFromEmulator];
	[self commitDisplayedValues];
    
	[[prefTabView window] setExcludedFromWindowsMenu:YES];
	[[prefTabView window] setMenu:nil];
    [self updateUI];
    [self miscChanged:self];
    [[prefTabView window] center];
	 
    [NSApp runModalForWindow:[prefTabView window]];
}


/*------------------------------------------------------------------------------
* updateUI - Method to update the display, based on the stored values.
*-----------------------------------------------------------------------------*/
- (void)updateUI {
    char tempStr[10];
	NSColor *pen1, *pen2, *pen3, *pen4, *fore, *back;

    if (!prefTabView) return;	/* UI hasn't been loaded... */

    // Display Items
    [fullScreenMatrix selectCellWithTag:[[displayedValues objectForKey:FullScreen] boolValue] ? 1 : 0];
    [scaleFactorMatrix  selectCellWithTag:[[displayedValues objectForKey:ScaleFactor] intValue]];
    [resize3Button setState:[[displayedValues objectForKey:Resize3] boolValue] ? NSOnState : NSOffState];
    [resize4Button setState:[[displayedValues objectForKey:Resize4] boolValue] ? NSOnState : NSOffState];
	[windowBorderWidthField setIntValue:[[displayedValues objectForKey:BorderWidth] intValue]];
	fore = [NSColor colorWithCalibratedRed:[[displayedValues objectForKey:ForeRed] floatValue] 
						green:[[displayedValues objectForKey:ForeGreen] floatValue] 
						blue:[[displayedValues objectForKey:ForeBlue] floatValue]
						alpha:[[displayedValues objectForKey:ForeAlpha] floatValue]];
	[foregroundPot setColor:fore];
	back = [NSColor colorWithCalibratedRed:[[displayedValues objectForKey:BackRed] floatValue] 
						green:[[displayedValues objectForKey:BackGreen] floatValue] 
						blue:[[displayedValues objectForKey:BackBlue] floatValue]
						alpha:[[displayedValues objectForKey:BackAlpha] floatValue]];
	[backgroundPot setColor:back];
	fore = [NSColor colorWithCalibratedRed:[[displayedValues objectForKey:GuiForeRed] floatValue] 
						green:[[displayedValues objectForKey:GuiForeGreen] floatValue] 
						blue:[[displayedValues objectForKey:GuiForeBlue] floatValue]
						alpha:[[displayedValues objectForKey:GuiForeAlpha] floatValue]];
	[guiForegroundPot setColor:fore];
	back = [NSColor colorWithCalibratedRed:[[displayedValues objectForKey:GuiBackRed] floatValue] 
						green:[[displayedValues objectForKey:GuiBackGreen] floatValue] 
						blue:[[displayedValues objectForKey:GuiBackBlue] floatValue]
						alpha:[[displayedValues objectForKey:GuiBackAlpha] floatValue]];
	[guiBackgroundPot setColor:back];
    [model1FontPulldown  selectItemAtIndex:[[displayedValues objectForKey:Model1Font] intValue]];
    [model3FontPulldown  selectItemAtIndex:[[displayedValues objectForKey:Model3Font] intValue]];
    [model4FontPulldown  selectItemAtIndex:[[displayedValues objectForKey:Model4Font] intValue]];
    [ledStatusButton setState:[[displayedValues objectForKey:LedStatus] boolValue] ? NSOnState : NSOffState];
    
    //TRS Items
    [trsModelPulldown  selectItemAtIndex:[[displayedValues objectForKey:TrsModel] intValue]];
    [trsGraphicsPulldown  selectItemAtIndex:[[displayedValues objectForKey:GraphicsModel] intValue]];
    [shiftBracketButton setState:[[displayedValues objectForKey:ShiftBracket] boolValue] ? NSOnState : NSOffState];
    [keyboardStretchField setIntValue:[[displayedValues objectForKey:Keystretch] intValue]];
    sprintf(tempStr,"%8X",[[displayedValues objectForKey:SerialSwitches] intValue]);
    [serialSwitchesField setStringValue:[NSString stringWithCString:tempStr]];
    [serialPortField setStringValue:[displayedValues objectForKey:SerialPort]];
    [disk1SizeMatrix selectCellWithTag:[[displayedValues objectForKey:Disk1Size] intValue]];
    [disk2SizeMatrix selectCellWithTag:[[displayedValues objectForKey:Disk2Size] intValue]];
    [disk3SizeMatrix selectCellWithTag:[[displayedValues objectForKey:Disk3Size] intValue]];
    [disk4SizeMatrix selectCellWithTag:[[displayedValues objectForKey:Disk4Size] intValue]];
    [disk5SizeMatrix selectCellWithTag:[[displayedValues objectForKey:Disk5Size] intValue]];
    [disk6SizeMatrix selectCellWithTag:[[displayedValues objectForKey:Disk6Size] intValue]];
    [disk7SizeMatrix selectCellWithTag:[[displayedValues objectForKey:Disk7Size] intValue]];
    [disk8SizeMatrix selectCellWithTag:[[displayedValues objectForKey:Disk8Size] intValue]];
    [doublerTypePulldown  selectItemAtIndex:[[displayedValues objectForKey:DoublerType] intValue]];
    [trueDamButton setState:[[displayedValues objectForKey:TrueDam] boolValue] ? NSOnState : NSOffState];
    [emtSafeButton setState:[[displayedValues objectForKey:EmtSafe] boolValue] ? NSOnState : NSOffState];
    // Printer Items   
	[printerTypePulldown selectItemAtIndex:[[displayedValues objectForKey:PrinterType] intValue]];
	[printCommandField setStringValue:[displayedValues objectForKey:PrintCommand]];
	[atari1020PrintWidthPulldown selectItemAtIndex:[[displayedValues objectForKey:Atari1020PrintWidth] intValue]];
	[atari1020FormLengthField setIntValue:[[displayedValues objectForKey:Atari1020FormLength] intValue]];
	[atari1020FormLengthStepper setIntValue:[[displayedValues objectForKey:Atari1020FormLength] intValue]];
	[atari1020AutoLinefeedButton setState:[[displayedValues objectForKey:Atari1020AutoLinefeed] boolValue] ? NSOnState : NSOffState];
	[atari1020AutoPageAdjustButton setState:[[displayedValues objectForKey:Atari1020AutoPageAdjust] boolValue] ? NSOnState : NSOffState];
	pen1 = [NSColor colorWithCalibratedRed:[[displayedValues objectForKey:Atari1020Pen1Red] floatValue] 
									 green:[[displayedValues objectForKey:Atari1020Pen1Green] floatValue] 
									  blue:[[displayedValues objectForKey:Atari1020Pen1Blue] floatValue]
									 alpha:[[displayedValues objectForKey:Atari1020Pen1Alpha] floatValue]];
	[atari1020Pen1Pot setColor:pen1];
	pen2 = [NSColor colorWithCalibratedRed:[[displayedValues objectForKey:Atari1020Pen2Red] floatValue] 
									 green:[[displayedValues objectForKey:Atari1020Pen2Green] floatValue] 
									  blue:[[displayedValues objectForKey:Atari1020Pen2Blue] floatValue]
									 alpha:[[displayedValues objectForKey:Atari1020Pen2Alpha] floatValue]];
	[atari1020Pen2Pot setColor:pen2];
	pen3 = [NSColor colorWithCalibratedRed:[[displayedValues objectForKey:Atari1020Pen3Red] floatValue] 
									 green:[[displayedValues objectForKey:Atari1020Pen3Green] floatValue] 
									  blue:[[displayedValues objectForKey:Atari1020Pen3Blue] floatValue]
									 alpha:[[displayedValues objectForKey:Atari1020Pen3Alpha] floatValue]];
	[atari1020Pen3Pot setColor:pen3];
	pen4 = [NSColor colorWithCalibratedRed:[[displayedValues objectForKey:Atari1020Pen4Red] floatValue] 
									 green:[[displayedValues objectForKey:Atari1020Pen4Green] floatValue] 
									  blue:[[displayedValues objectForKey:Atari1020Pen4Blue] floatValue]
									 alpha:[[displayedValues objectForKey:Atari1020Pen4Alpha] floatValue]];
	[atari1020Pen4Pot setColor:pen4];
	[epsonCharSetPulldown selectItemAtIndex:[[displayedValues objectForKey:EpsonCharSet] intValue]];
	[epsonPrintPitchPulldown selectItemAtIndex:[[displayedValues objectForKey:EpsonPrintPitch] intValue]];
	[epsonPrintWeightPulldown selectItemAtIndex:[[displayedValues objectForKey:EpsonPrintWeight] intValue]];
	[epsonFormLengthField setIntValue:[[displayedValues objectForKey:EpsonFormLength] intValue]];
	[epsonFormLengthStepper setIntValue:[[displayedValues objectForKey:EpsonFormLength] intValue]];
	[epsonAutoLinefeedButton setState:[[displayedValues objectForKey:EpsonAutoLinefeed] boolValue] ? NSOnState : NSOffState];
	[epsonPrintSlashedZerosButton setState:[[displayedValues objectForKey:EpsonPrintSlashedZeros] boolValue] ? NSOnState : NSOffState];
	[epsonAutoSkipButton setState:[[displayedValues objectForKey:EpsonAutoSkip] boolValue] ? NSOnState : NSOffState];
	[epsonSplitSkipButton setState:[[displayedValues objectForKey:EpsonSplitSkip] boolValue] ? NSOnState : NSOffState];
    
    // Rom Items
    [model1RomFileField setStringValue:[displayedValues objectForKey:Model1RomFile]];
    [model3RomFileField setStringValue:[displayedValues objectForKey:Model3RomFile]];
    [model4pRomFileField setStringValue:[displayedValues objectForKey:Model4pRomFile]];

    // Dir Items
    [diskImageDirField setStringValue:[displayedValues objectForKey:DiskImageDir]];
    [hardImageDirField setStringValue:[displayedValues objectForKey:HardImageDir]];
    [cassImageDirField setStringValue:[displayedValues objectForKey:CassImageDir]];
    [diskSetDirField setStringValue:[displayedValues objectForKey:DiskSetDir]];
    [savedStateDirField setStringValue:[displayedValues objectForKey:SavedStateDir]];
    [printDirField setStringValue:[displayedValues objectForKey:PrintDir]];
    
    // Joy Items
    [keyboardJoystickButton setState:[[displayedValues objectForKey:KeypadJoystick] boolValue] ? NSOnState : NSOffState];
    if ([[displayedValues objectForKey:JoystickNumber] intValue] > numJoysticks) 
        [usbJoystickPulldown selectItemAtIndex:0];
    else
        [usbJoystickPulldown selectItemAtIndex:[[displayedValues objectForKey:JoystickNumber] intValue]];
}

/*------------------------------------------------------------------------------
* miscChanged - Method to get everything from User Interface when an event 
*        occurs.  Should probably be broke up by tab, since it is so huge.
*-----------------------------------------------------------------------------*/
- (void)miscChanged:(id)sender {
    int anInt;
    char tempStr[80];
	NSColor *penColor;
	float penRed, penBlue, penGreen, penAlpha;
	NSColor *screenColor;
	float screenRed, screenBlue, screenGreen, screenAlpha;
    
    static NSNumber *yes = nil;
    static NSNumber *no = nil;
    static NSNumber *zero = nil;
    static NSNumber *one = nil;
    static NSNumber *two = nil;
    static NSNumber *three = nil;
    static NSNumber *four = nil;
    static NSNumber *five = nil;
    static NSNumber *six = nil;
    static NSNumber *seven = nil;
    static NSNumber *eight = nil;
    static NSNumber *nine = nil;
    static NSNumber *ten = nil;
   
    if (!yes) {
        yes = [[NSNumber alloc] initWithBool:YES];
        no = [[NSNumber alloc] initWithBool:NO];
        zero = [[NSNumber alloc] initWithInt:0];
        one = [[NSNumber alloc] initWithInt:1];
        two = [[NSNumber alloc] initWithInt:2];
        three = [[NSNumber alloc] initWithInt:3];
        four = [[NSNumber alloc] initWithInt:4];
        five = [[NSNumber alloc] initWithInt:5];
        six = [[NSNumber alloc] initWithInt:6];
        seven = [[NSNumber alloc] initWithInt:7];
        eight = [[NSNumber alloc] initWithInt:8];
        nine = [[NSNumber alloc] initWithInt:9];
        ten = [[NSNumber alloc] initWithInt:10];
    }

    // Display Items
    [displayedValues setObject:[[fullScreenMatrix selectedCell] tag] ? yes : no forKey:FullScreen];
    switch([[scaleFactorMatrix selectedCell] tag]) {
        case 1:
		default:
            [displayedValues setObject:one forKey:ScaleFactor];
            break;
        case 2:
            [displayedValues setObject:two forKey:ScaleFactor];
            break;
        case 3:
            [displayedValues setObject:three forKey:ScaleFactor];
            break;
    }
	anInt = [windowBorderWidthField intValue];
    [displayedValues setObject:[NSNumber numberWithInt:anInt] forKey:BorderWidth];
    if ([resize3Button state] == NSOnState)
        [displayedValues setObject:yes forKey:Resize3];
    else
        [displayedValues setObject:no forKey:Resize3];
    if ([resize4Button state] == NSOnState)
        [displayedValues setObject:yes forKey:Resize4];
    else
        [displayedValues setObject:no forKey:Resize4];
	screenColor = [foregroundPot color];
	[screenColor getRed:&screenRed green:&screenGreen blue:&screenBlue alpha:&screenAlpha];
	[displayedValues setObject:[NSNumber numberWithFloat:screenRed] forKey:ForeRed];
	[displayedValues setObject:[NSNumber numberWithFloat:screenBlue] forKey:ForeBlue];
	[displayedValues setObject:[NSNumber numberWithFloat:screenGreen] forKey:ForeGreen];
	[displayedValues setObject:[NSNumber numberWithFloat:screenAlpha] forKey:ForeAlpha];
	screenColor = [backgroundPot color];
	[screenColor getRed:&screenRed green:&screenGreen blue:&screenBlue alpha:&screenAlpha];
	[displayedValues setObject:[NSNumber numberWithFloat:screenRed] forKey:BackRed];
	[displayedValues setObject:[NSNumber numberWithFloat:screenBlue] forKey:BackBlue];
	[displayedValues setObject:[NSNumber numberWithFloat:screenGreen] forKey:BackGreen];
	[displayedValues setObject:[NSNumber numberWithFloat:screenAlpha] forKey:BackAlpha];
	screenColor = [guiForegroundPot color];
	[screenColor getRed:&screenRed green:&screenGreen blue:&screenBlue alpha:&screenAlpha];
	[displayedValues setObject:[NSNumber numberWithFloat:screenRed] forKey:GuiForeRed];
	[displayedValues setObject:[NSNumber numberWithFloat:screenBlue] forKey:GuiForeBlue];
	[displayedValues setObject:[NSNumber numberWithFloat:screenGreen] forKey:GuiForeGreen];
	[displayedValues setObject:[NSNumber numberWithFloat:screenAlpha] forKey:GuiForeAlpha];
	screenColor = [guiBackgroundPot color];
	[screenColor getRed:&screenRed green:&screenGreen blue:&screenBlue alpha:&screenAlpha];
	[displayedValues setObject:[NSNumber numberWithFloat:screenRed] forKey:GuiBackRed];
	[displayedValues setObject:[NSNumber numberWithFloat:screenBlue] forKey:GuiBackBlue];
	[displayedValues setObject:[NSNumber numberWithFloat:screenGreen] forKey:GuiBackGreen];
	[displayedValues setObject:[NSNumber numberWithFloat:screenAlpha] forKey:GuiBackAlpha];
    switch([model1FontPulldown indexOfSelectedItem]) {
        case 0:
		default:
            [displayedValues setObject:zero forKey:Model1Font];
            break;
        case 1:
            [displayedValues setObject:one forKey:Model1Font];
            break;
        case 2:
            [displayedValues setObject:two forKey:Model1Font];
            break;
        case 3:
            [displayedValues setObject:three forKey:Model1Font];
            break;
        case 4:
            [displayedValues setObject:four forKey:Model1Font];
            break;
		}
    switch([model3FontPulldown indexOfSelectedItem]) {
        case 0:
		default:
            [displayedValues setObject:zero forKey:Model3Font];
            break;
        case 1:
            [displayedValues setObject:one forKey:Model3Font];
            break;
        case 2:
            [displayedValues setObject:two forKey:Model3Font];
            break;
		}
    switch([model4FontPulldown indexOfSelectedItem]) {
        case 0:
		default:
            [displayedValues setObject:zero forKey:Model4Font];
            break;
        case 1:
            [displayedValues setObject:one forKey:Model4Font];
            break;
        case 2:
            [displayedValues setObject:two forKey:Model4Font];
            break;
		}	
    if ([ledStatusButton state] == NSOnState) {
        [displayedValues setObject:yes forKey:LedStatus];
		}
    else {
        [displayedValues setObject:no forKey:LedStatus];
		}
    // TRS Items
    switch([trsModelPulldown indexOfSelectedItem]) {
        case 0:
		default:
            [displayedValues setObject:zero forKey:TrsModel];
            break;
        case 1:
            [displayedValues setObject:one forKey:TrsModel];
            break;
        case 2:
            [displayedValues setObject:two forKey:TrsModel];
            break;
        case 3:
            [displayedValues setObject:three forKey:TrsModel];
            break;
    }    
    switch([trsGraphicsPulldown indexOfSelectedItem]) {
        case 0:
		default:
            [displayedValues setObject:zero forKey:GraphicsModel];
            break;
        case 1:
            [displayedValues setObject:one forKey:GraphicsModel];
            break;
    }    
    if ([shiftBracketButton state] == NSOnState)
        [displayedValues setObject:yes forKey:ShiftBracket];
    else
        [displayedValues setObject:no forKey:ShiftBracket];
	anInt = [keyboardStretchField intValue];
    [displayedValues setObject:[NSNumber numberWithInt:anInt] forKey:Keystretch];
    [[serialSwitchesField stringValue] getCString:tempStr];
    anInt = strtol(tempStr, NULL, 16);
    [displayedValues setObject:[NSNumber numberWithInt:anInt] forKey:SerialSwitches];
    [displayedValues setObject:[serialPortField stringValue] forKey:SerialPort];
    switch([[disk1SizeMatrix selectedCell] tag]) {
        case 0:
	default:
            [displayedValues setObject:zero forKey:Disk1Size];
            break;
        case 1:
            [displayedValues setObject:one forKey:Disk1Size];
            break;
    }
    switch([[disk2SizeMatrix selectedCell] tag]) {
        case 0:
	default:
            [displayedValues setObject:zero forKey:Disk2Size];
            break;
        case 1:
            [displayedValues setObject:one forKey:Disk2Size];
            break;
    }
    switch([[disk3SizeMatrix selectedCell] tag]) {
        case 0:
	default:
            [displayedValues setObject:zero forKey:Disk3Size];
            break;
        case 1:
            [displayedValues setObject:one forKey:Disk3Size];
            break;
    }
    switch([[disk4SizeMatrix selectedCell] tag]) {
        case 0:
	default:
            [displayedValues setObject:zero forKey:Disk4Size];
            break;
        case 1:
            [displayedValues setObject:one forKey:Disk4Size];
            break;
    }
    switch([[disk5SizeMatrix selectedCell] tag]) {
        case 0:
	default:
            [displayedValues setObject:zero forKey:Disk5Size];
            break;
        case 1:
            [displayedValues setObject:one forKey:Disk5Size];
            break;
    }
    switch([[disk6SizeMatrix selectedCell] tag]) {
        case 0:
	default:
            [displayedValues setObject:zero forKey:Disk6Size];
            break;
        case 1:
            [displayedValues setObject:one forKey:Disk6Size];
            break;
    }
    switch([[disk7SizeMatrix selectedCell] tag]) {
        case 0:
	default:
            [displayedValues setObject:zero forKey:Disk7Size];
            break;
        case 1:
            [displayedValues setObject:one forKey:Disk7Size];
            break;
    }
    switch([[disk8SizeMatrix selectedCell] tag]) {
        case 0:
	default:
            [displayedValues setObject:zero forKey:Disk8Size];
            break;
        case 1:
            [displayedValues setObject:one forKey:Disk8Size];
            break;
    }
    switch([doublerTypePulldown indexOfSelectedItem]) {
        case 0:
		default:
            [displayedValues setObject:zero forKey:DoublerType];
            break;
        case 1:
            [displayedValues setObject:one forKey:DoublerType];
            break;
        case 2:
            [displayedValues setObject:two forKey:DoublerType];
            break;
        case 3:
            [displayedValues setObject:three forKey:DoublerType];
            break;
    }    
    if ([trueDamButton state] == NSOnState)
        [displayedValues setObject:yes forKey:TrueDam];
    else
        [displayedValues setObject:no forKey:TrueDam];
    if ([emtSafeButton state] == NSOnState)
        [displayedValues setObject:yes forKey:EmtSafe];
    else
        [displayedValues setObject:no forKey:EmtSafe];
    // Printer Items
    switch([printerTypePulldown indexOfSelectedItem]) {
        case 0:
		default:
            [displayedValues setObject:zero forKey:PrinterType];
            break;
        case 1:
            [displayedValues setObject:one forKey:PrinterType];
            break;
        case 2:
            [displayedValues setObject:two forKey:PrinterType];
            break;
        case 3:
            [displayedValues setObject:three forKey:PrinterType];
            break;
	}
    [displayedValues setObject:[printCommandField stringValue] forKey:PrintCommand];
    anInt = [atari1020FormLengthStepper intValue];
    [displayedValues setObject:[NSNumber numberWithInt:anInt] forKey:Atari1020FormLength];
	[atari1020FormLengthField setIntValue:anInt];
    if ([atari1020AutoLinefeedButton state] == NSOnState)
        [displayedValues setObject:yes forKey:Atari1020AutoLinefeed];
    else
        [displayedValues setObject:no forKey:Atari1020AutoLinefeed];
    if ([atari1020AutoPageAdjustButton state] == NSOnState)
        [displayedValues setObject:yes forKey:Atari1020AutoPageAdjust];
    else
        [displayedValues setObject:no forKey:Atari1020AutoPageAdjust];
    switch([atari1020PrintWidthPulldown indexOfSelectedItem]) {
        case 0:
            [displayedValues setObject:zero forKey:Atari1020PrintWidth];
            break;
        case 1:
            [displayedValues setObject:one forKey:Atari1020PrintWidth];
            break;
	}
	penColor = [atari1020Pen1Pot color];
	[penColor getRed:&penRed green:&penGreen blue:&penBlue alpha:&penAlpha];
	[displayedValues setObject:[NSNumber numberWithFloat:penRed] forKey:Atari1020Pen1Red];
	[displayedValues setObject:[NSNumber numberWithFloat:penBlue] forKey:Atari1020Pen1Blue];
	[displayedValues setObject:[NSNumber numberWithFloat:penGreen] forKey:Atari1020Pen1Green];
	[displayedValues setObject:[NSNumber numberWithFloat:penAlpha] forKey:Atari1020Pen1Alpha];
	penColor = [atari1020Pen2Pot color];
	[penColor getRed:&penRed green:&penGreen blue:&penBlue alpha:&penAlpha];
	[displayedValues setObject:[NSNumber numberWithFloat:penRed] forKey:Atari1020Pen2Red];
	[displayedValues setObject:[NSNumber numberWithFloat:penBlue] forKey:Atari1020Pen2Blue];
	[displayedValues setObject:[NSNumber numberWithFloat:penGreen] forKey:Atari1020Pen2Green];
	[displayedValues setObject:[NSNumber numberWithFloat:penAlpha] forKey:Atari1020Pen2Alpha];
	penColor = [atari1020Pen3Pot color];
	[penColor getRed:&penRed green:&penGreen blue:&penBlue alpha:&penAlpha];
	[displayedValues setObject:[NSNumber numberWithFloat:penRed] forKey:Atari1020Pen3Red];
	[displayedValues setObject:[NSNumber numberWithFloat:penBlue] forKey:Atari1020Pen3Blue];
	[displayedValues setObject:[NSNumber numberWithFloat:penGreen] forKey:Atari1020Pen3Green];
	[displayedValues setObject:[NSNumber numberWithFloat:penAlpha] forKey:Atari1020Pen3Alpha];
	penColor = [atari1020Pen4Pot color];
	[penColor getRed:&penRed green:&penGreen blue:&penBlue alpha:&penAlpha];
	[displayedValues setObject:[NSNumber numberWithFloat:penRed] forKey:Atari1020Pen4Red];
	[displayedValues setObject:[NSNumber numberWithFloat:penBlue] forKey:Atari1020Pen4Blue];
	[displayedValues setObject:[NSNumber numberWithFloat:penGreen] forKey:Atari1020Pen4Green];
	[displayedValues setObject:[NSNumber numberWithFloat:penAlpha] forKey:Atari1020Pen4Alpha];
	
    switch([epsonCharSetPulldown indexOfSelectedItem]) {
        case 0:
		default:
            [displayedValues setObject:zero forKey:EpsonCharSet];
            break;
        case 1:
            [displayedValues setObject:one forKey:EpsonCharSet];
            break;
        case 2:
            [displayedValues setObject:two forKey:EpsonCharSet];
            break;
        case 3:
            [displayedValues setObject:three forKey:EpsonCharSet];
            break;
        case 4:
            [displayedValues setObject:four forKey:EpsonCharSet];
            break;
        case 5:
            [displayedValues setObject:five forKey:EpsonCharSet];
            break;
        case 6:
            [displayedValues setObject:six forKey:EpsonCharSet];
            break;
        case 7:
            [displayedValues setObject:seven forKey:EpsonCharSet];
            break;
        case 8:
            [displayedValues setObject:eight forKey:EpsonCharSet];
            break;
		}	
	anInt = [epsonFormLengthStepper intValue];
    [displayedValues setObject:[NSNumber numberWithInt:anInt] forKey:EpsonFormLength];
	[epsonFormLengthField setIntValue:anInt];
    if ([epsonAutoLinefeedButton state] == NSOnState)
        [displayedValues setObject:yes forKey:EpsonAutoLinefeed];
    else
        [displayedValues setObject:no forKey:EpsonAutoLinefeed];
    switch([epsonPrintPitchPulldown indexOfSelectedItem]) {
        case 0:
		default:
            [displayedValues setObject:zero forKey:EpsonPrintPitch];
            break;
        case 1:
            [displayedValues setObject:one forKey:EpsonPrintPitch];
            break;
		}
    switch([epsonPrintWeightPulldown indexOfSelectedItem]) {
        case 0:
		default:
            [displayedValues setObject:zero forKey:EpsonPrintWeight];
            break;
        case 1:
            [displayedValues setObject:one forKey:EpsonPrintWeight];
            break;
		}
    if ([epsonAutoLinefeedButton state] == NSOnState)
        [displayedValues setObject:yes forKey:EpsonAutoLinefeed];
    else
        [displayedValues setObject:no forKey:EpsonAutoLinefeed];
    if ([epsonPrintSlashedZerosButton state] == NSOnState)
        [displayedValues setObject:yes forKey:EpsonPrintSlashedZeros];
    else
        [displayedValues setObject:no forKey:EpsonPrintSlashedZeros];
    if ([epsonAutoSkipButton state] == NSOnState)
		{
        [displayedValues setObject:yes forKey:EpsonAutoSkip];
		[epsonSplitSkipButton setEnabled:YES];
		}
    else
		{
        [displayedValues setObject:no forKey:EpsonAutoSkip];
		[epsonSplitSkipButton setEnabled:NO];
		}
    if ([epsonSplitSkipButton state] == NSOnState)
        [displayedValues setObject:yes forKey:EpsonSplitSkip];
    else
        [displayedValues setObject:no forKey:EpsonSplitSkip];
    // Roms Items
    [displayedValues setObject:[model1RomFileField stringValue] forKey:Model1RomFile];
    [displayedValues setObject:[model3RomFileField stringValue] forKey:Model3RomFile];
    [displayedValues setObject:[model4pRomFileField stringValue] forKey:Model4pRomFile];
    // Dir Items
    [displayedValues setObject:[diskImageDirField stringValue] forKey:DiskImageDir];
    [displayedValues setObject:[hardImageDirField stringValue] forKey:HardImageDir];
    [displayedValues setObject:[cassImageDirField stringValue] forKey:CassImageDir];
    [displayedValues setObject:[diskSetDirField stringValue] forKey:DiskSetDir];
    [displayedValues setObject:[savedStateDirField stringValue] forKey:SavedStateDir];
    [displayedValues setObject:[printDirField stringValue] forKey:PrintDir];
    // Joystick Items
    if ([keyboardJoystickButton state] == NSOnState)
        [displayedValues setObject:yes forKey:KeypadJoystick];
    else
        [displayedValues setObject:no forKey:KeypadJoystick];
    switch([usbJoystickPulldown indexOfSelectedItem]) {
        case 0:
		default:
            [displayedValues setObject:zero forKey:JoystickNumber];
            break;
        case 1:
            [displayedValues setObject:one forKey:JoystickNumber];
            break;
        case 2:
            [displayedValues setObject:two forKey:JoystickNumber];
            break;
        case 3:
            [displayedValues setObject:three forKey:JoystickNumber];
            break;
        case 4:
            [displayedValues setObject:four forKey:JoystickNumber];
            break;
        case 5:
            [displayedValues setObject:five forKey:JoystickNumber];
            break;
        case 6:
            [displayedValues setObject:six forKey:JoystickNumber];
            break;
        case 7:
            [displayedValues setObject:seven forKey:JoystickNumber];
            break;
        case 8:
            [displayedValues setObject:eight forKey:JoystickNumber];
            break;
		}	

}


/*------------------------------------------------------------------------------
* browseFileInDirectory - Method which allows user to choose a file in a 
*     specific directory.
*-----------------------------------------------------------------------------*/
- (NSString *) browseFileInDirectory:(NSString *)directory {
    NSOpenPanel *openPanel;
    
    openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    
    if ([openPanel runModalForDirectory:directory file:nil types:nil] == NSOKButton) 
        return([[openPanel filenames] objectAtIndex:0]);
    else
        return nil;
    }


/*------------------------------------------------------------------------------
* browseDir - Method which allows user to choose a directory.
*-----------------------------------------------------------------------------*/
- (NSString *) browseDir {
    NSOpenPanel *openPanel;
    NSString  *dir;
    
    dir = [[NSString alloc] initWithCString:workingDirectory];
    
    openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:NO];
    
    if ([openPanel runModalForDirectory:dir file:nil types:nil] == NSOKButton) 
        return([[openPanel filenames] objectAtIndex:0]);
    else
        return nil;
    }

/* The following methods allow the user to choose the ROM files */
   
- (void)browseModel1Rom:(id)sender {
    NSString *filename, *dir;
    
    dir = [[NSString alloc] initWithCString:workingDirectory];
    filename = [self browseFileInDirectory:dir];
    if (filename != nil) {
        [model1RomFileField setStringValue:filename];
        [self miscChanged:self];
        }
    [dir release];
    }
    
- (void)browseModel3Rom:(id)sender {
    NSString *filename, *dir;
    
    dir = [[NSString alloc] initWithCString:workingDirectory];
    filename = [self browseFileInDirectory:dir];
    if (filename != nil) {
        [model3RomFileField setStringValue:filename];
        [self miscChanged:self];
        }
    [dir release];
    }
    
- (void)browseModel4pRom:(id)sender {
    NSString *filename, *dir;
    
    dir = [[NSString alloc] initWithCString:workingDirectory];
    filename = [self browseFileInDirectory:dir];
    if (filename != nil) {
        [model4pRomFileField setStringValue:filename];
        [self miscChanged:self];
        }
    [dir release];
    }
        
/* The following methods allow the user to choose the default directories
    for files */
    
- (void)browseDiskDir:(id)sender {
    NSString *dirname;
    
    dirname = [self browseDir];
    if (dirname != nil) {
        [diskImageDirField setStringValue:dirname];
        [self miscChanged:self];
        }
    }

- (void)browseDiskSetDir:(id)sender {
    NSString *dirname;
    
    dirname = [self browseDir];
    if (dirname != nil) {
        [diskSetDirField setStringValue:dirname];
        [self miscChanged:self];
        }
    }

- (void)browseHardDir:(id)sender {
    NSString *dirname;
    
    dirname = [self browseDir];
    if (dirname != nil) {
        [hardImageDirField setStringValue:dirname];
        [self miscChanged:self];
        }
    }

- (void)browseCassDir:(id)sender {
    NSString *dirname;
    
    dirname = [self browseDir];
    if (dirname != nil) {
        [cassImageDirField setStringValue:dirname];
        [self miscChanged:self];
        }
    }

- (void)browseStateDir:(id)sender {
    NSString *dirname;
    
    dirname = [self browseDir];
    if (dirname != nil) {
        [savedStateDirField setStringValue:dirname];
        [self miscChanged:self];
        }
    }
    
- (void)browsePrintDir:(id)sender {
    NSString *dirname;
    
    dirname = [self browseDir];
    if (dirname != nil) {
        [printDirField setStringValue:dirname];
        [self miscChanged:self];
        }
    }

/**** Commit/revert etc ****/

- (void)commitDisplayedValues {
    if (curValues != displayedValues) {
        [curValues release];
        curValues = [displayedValues copyWithZone:[self zone]];
    }
}

- (void)discardDisplayedValues {
    if (curValues != displayedValues) {
        [displayedValues release];
        displayedValues = [curValues mutableCopyWithZone:[self zone]];
        [self updateUI];
    }
}

- (void)transferValuesToAtari1020
{
	prefs1020.printWidth = [[curValues objectForKey:Atari1020PrintWidth] intValue];
	prefs1020.formLength = [[curValues objectForKey:Atari1020FormLength] intValue];
	prefs1020.autoLinefeed = [[curValues objectForKey:Atari1020AutoLinefeed] intValue];
	prefs1020.autoPageAdjust = [[curValues objectForKey:Atari1020AutoPageAdjust] intValue];
	prefs1020.pen1Red = [[curValues objectForKey:Atari1020Pen1Red] floatValue];
	prefs1020.pen1Blue = [[curValues objectForKey:Atari1020Pen1Blue] floatValue];
	prefs1020.pen1Green = [[curValues objectForKey:Atari1020Pen1Green] floatValue];
	prefs1020.pen1Alpha = [[curValues objectForKey:Atari1020Pen1Alpha] floatValue];
	prefs1020.pen2Red = [[curValues objectForKey:Atari1020Pen2Red] floatValue];
	prefs1020.pen2Blue = [[curValues objectForKey:Atari1020Pen2Blue] floatValue];
	prefs1020.pen2Green = [[curValues objectForKey:Atari1020Pen2Green] floatValue];
	prefs1020.pen2Alpha = [[curValues objectForKey:Atari1020Pen2Alpha] floatValue];
	prefs1020.pen3Red = [[curValues objectForKey:Atari1020Pen3Red] floatValue];
	prefs1020.pen3Blue = [[curValues objectForKey:Atari1020Pen3Blue] floatValue];
	prefs1020.pen3Green = [[curValues objectForKey:Atari1020Pen3Green] floatValue];
	prefs1020.pen3Alpha = [[curValues objectForKey:Atari1020Pen3Alpha] floatValue];
	prefs1020.pen4Red = [[curValues objectForKey:Atari1020Pen4Red] floatValue];
	prefs1020.pen4Blue = [[curValues objectForKey:Atari1020Pen4Blue] floatValue];
	prefs1020.pen4Green = [[curValues objectForKey:Atari1020Pen4Green] floatValue];
	prefs1020.pen4Alpha = [[curValues objectForKey:Atari1020Pen4Alpha] floatValue];
}

- (void)transferValuesToEpson
	{
	prefsEpson.charSet = [[curValues objectForKey:EpsonCharSet] intValue];
	prefsEpson.formLength = [[curValues objectForKey:EpsonFormLength] intValue];
	prefsEpson.printPitch = [[curValues objectForKey:EpsonPrintPitch] intValue];
	prefsEpson.printWeight = [[curValues objectForKey:EpsonPrintWeight] intValue];
	prefsEpson.autoLinefeed = [[curValues objectForKey:EpsonAutoLinefeed] intValue];
	prefsEpson.printSlashedZeros = [[curValues objectForKey:EpsonPrintSlashedZeros] intValue];
	prefsEpson.autoSkip = [[curValues objectForKey:EpsonAutoSkip] intValue];
	prefsEpson.splitSkip = [[curValues objectForKey:EpsonSplitSkip] intValue];
	}

/*------------------------------------------------------------------------------
* transferValuesToEmulator - Method which allows preferences to be transfered
*   to the 'C' structure which is a buffer between the emulator code and this
*   Cocoa code.
*-----------------------------------------------------------------------------*/
- (void)transferValuesToEmulator {

MAC_PREFS *mac_prefs;

    mac_prefs = trs_mac_prefs_location();

	// Display Items
    mac_prefs->fullscreen = [[curValues objectForKey:FullScreen] intValue]; 
    mac_prefs->scale_x = [[curValues objectForKey:ScaleFactor] intValue]; 
	mac_prefs->border_width = [[curValues objectForKey:BorderWidth] intValue];
	mac_prefs->resize3 = [[curValues objectForKey:Resize3] intValue]; 
	mac_prefs->resize4 = [[curValues objectForKey:Resize4] intValue]; 
	mac_prefs->foreground = ((int) ([[curValues objectForKey:ForeRed] floatValue] * 255)) << 16 |
						((int) ([[curValues objectForKey:ForeGreen] floatValue] * 255)) << 8 |
						((int) ([[curValues objectForKey:ForeBlue] floatValue] * 255));
	mac_prefs->background = ((int) ([[curValues objectForKey:BackRed] floatValue] * 255)) << 16 |
						((int) ([[curValues objectForKey:BackGreen] floatValue] * 255)) << 8 |
						((int) ([[curValues objectForKey:BackBlue] floatValue] * 255));
	mac_prefs->gui_foreground = ((int) ([[curValues objectForKey:GuiForeRed] floatValue] * 255)) << 16 |
						((int) ([[curValues objectForKey:GuiForeGreen] floatValue] * 255)) << 8 |
						((int) ([[curValues objectForKey:GuiForeBlue] floatValue] * 255));
	mac_prefs->gui_background = ((int) ([[curValues objectForKey:GuiBackRed] floatValue] * 255)) << 16 |
						((int) ([[curValues objectForKey:GuiBackGreen] floatValue] * 255)) << 8 |
						((int) ([[curValues objectForKey:GuiBackBlue] floatValue] * 255));
	mac_prefs->trs_show_led = [[curValues objectForKey:LedStatus] intValue];
	if ([[curValues objectForKey:Model1Font] intValue] == 4)
		mac_prefs->trs_charset1 = 10;
	else
		mac_prefs->trs_charset1 = [[curValues objectForKey:Model1Font] intValue]; 
	mac_prefs->trs_charset3 = [[curValues objectForKey:Model3Font] intValue]+4; 
	mac_prefs->trs_charset4 = [[curValues objectForKey:Model4Font] intValue]+7; 
    mac_prefs->mediaStatusWindowOpen = [[curValues objectForKey:MediaStatusDisplayed] intValue];
	// TRS Items
	switch([[curValues objectForKey:TrsModel] intValue]) {
		case 0:
			mac_prefs->trs_model = 1;
			break;
		case 1:
			mac_prefs->trs_model = 3;
			break;
		case 2:
			mac_prefs->trs_model = 4;
			break;
		case 3:
			mac_prefs->trs_model = 5;
			break;
		}
	mac_prefs->micrographyx = [[curValues objectForKey:GraphicsModel] intValue];
	mac_prefs->stretch_amount = [[curValues objectForKey:Keystretch] intValue];
	mac_prefs->switches = [[curValues objectForKey:SerialSwitches] intValue];
    [[curValues objectForKey:SerialPort] getCString:mac_prefs->serial_port];
    mac_prefs->disk_sizes[0] = [[curValues objectForKey:Disk1Size] intValue];
    mac_prefs->disk_sizes[1] = [[curValues objectForKey:Disk2Size] intValue];
    mac_prefs->disk_sizes[2] = [[curValues objectForKey:Disk3Size] intValue];
    mac_prefs->disk_sizes[3] = [[curValues objectForKey:Disk4Size] intValue];
    mac_prefs->disk_sizes[4] = [[curValues objectForKey:Disk5Size] intValue];
    mac_prefs->disk_sizes[5] = [[curValues objectForKey:Disk6Size] intValue];
    mac_prefs->disk_sizes[6] = [[curValues objectForKey:Disk7Size] intValue];
    mac_prefs->disk_sizes[7] = [[curValues objectForKey:Disk8Size] intValue];
    mac_prefs->trs_disk_doubler = [[curValues objectForKey:DoublerType] intValue];
    mac_prefs->trs_disk_truedam = [[curValues objectForKey:TrueDam] intValue];
	mac_prefs->trs_emtsafe = [[curValues objectForKey:EmtSafe] intValue];
	// Printer Items
    [[curValues objectForKey:PrintCommand] getCString:mac_prefs->print_command];
	mac_prefs->trs_printer = [[curValues objectForKey:PrinterType] intValue];
	// ROM Items
    [[curValues objectForKey:Model1RomFile] getCString:mac_prefs->romfile];
    [[curValues objectForKey:Model3RomFile] getCString:mac_prefs->romfile3];
    [[curValues objectForKey:Model4pRomFile] getCString:mac_prefs->romfile4p];
	// Dir Items 
    [[curValues objectForKey:DiskImageDir] getCString:mac_prefs->trs_disk_dir];
    [[curValues objectForKey:HardImageDir] getCString:mac_prefs->trs_hard_dir];
    [[curValues objectForKey:CassImageDir] getCString:mac_prefs->trs_cass_dir];
    [[curValues objectForKey:DiskSetDir] getCString:mac_prefs->trs_disk_set_dir];
    [[curValues objectForKey:SavedStateDir] getCString:mac_prefs->trs_state_dir];
    [[curValues objectForKey:PrintDir] getCString:mac_prefs->trs_printer_dir];
	// Joystick Items
	if ([[curValues objectForKey:JoystickNumber] intValue] == 0)
		mac_prefs->trs_joystick_num = -1;
	else
		mac_prefs->trs_joystick_num = [[curValues objectForKey:JoystickNumber] intValue]-1;
	mac_prefs->trs_keypad_joystick = [[curValues objectForKey:KeypadJoystick] intValue];
    }

/*------------------------------------------------------------------------------
*  transferValuesFromEmulator - This method transfers preference values back
*     from the emulator that may have been changed during operation.
*-----------------------------------------------------------------------------*/
- (void) transferValuesFromEmulator {
    MAC_PREFS *mac_prefs;

    static NSNumber *yes = nil;
    static NSNumber *no = nil;
    static NSNumber *zero = nil;
    static NSNumber *one = nil;
    static NSNumber *two = nil;
    static NSNumber *three = nil;
    static NSNumber *four = nil;

    mac_prefs = trs_mac_prefs_location();
   
    if (!yes) {
        yes = [[NSNumber alloc] initWithBool:YES];
        no = [[NSNumber alloc] initWithBool:NO];
        zero = [[NSNumber alloc] initWithInt:0];
        one = [[NSNumber alloc] initWithInt:1];
        two = [[NSNumber alloc] initWithInt:2];
        three = [[NSNumber alloc] initWithInt:3];
        four = [[NSNumber alloc] initWithInt:4];
    }

    // Display Items
    [displayedValues setObject:mac_prefs->fullscreen ? yes : no forKey:FullScreen];
    switch(mac_prefs->scale_x) {
        case 1:
		default:
            [displayedValues setObject:one forKey:ScaleFactor];
            break;
        case 2:
            [displayedValues setObject:two forKey:ScaleFactor];
            break;
        case 3:
            [displayedValues setObject:three forKey:ScaleFactor];
            break;
		}
	[displayedValues setObject:[NSNumber numberWithInt:mac_prefs->border_width] forKey:BorderWidth];
    [displayedValues setObject:mac_prefs->resize3 ? yes : no forKey:Resize3];
    [displayedValues setObject:mac_prefs->resize4 ? yes : no forKey:Resize4];
	[displayedValues setObject:[NSNumber numberWithFloat:
		(((float) ((mac_prefs->foreground & 0xFF0000) >> 16)) / 255)]
		forKey:ForeRed];
	[displayedValues setObject:[NSNumber numberWithFloat:
		(((float) ((mac_prefs->foreground & 0x00FF00) >> 8)) / 255)]
		forKey:ForeGreen];
	[displayedValues setObject:[NSNumber numberWithFloat:
		(((float) ((mac_prefs->foreground & 0x0000FF))) / 255)]
		forKey:ForeBlue];
	[displayedValues setObject:[NSNumber numberWithFloat:
		(((float) ((mac_prefs->background & 0xFF0000) >> 16)) / 255)]
		forKey:BackRed];
	[displayedValues setObject:[NSNumber numberWithFloat:
		(((float) ((mac_prefs->background & 0x00FF00) >> 8)) / 255)]
		forKey:BackGreen];
	[displayedValues setObject:[NSNumber numberWithFloat:
		(((float) ((mac_prefs->background & 0x0000FF))) / 255)]
		forKey:BackBlue];
	[displayedValues setObject:[NSNumber numberWithFloat:
		(((float) ((mac_prefs->gui_foreground & 0xFF0000) >> 16)) / 255)]
		forKey:GuiForeRed];
	[displayedValues setObject:[NSNumber numberWithFloat:
		(((float) ((mac_prefs->gui_foreground & 0x00FF00) >> 8)) / 255)]
		forKey:GuiForeGreen];
	[displayedValues setObject:[NSNumber numberWithFloat:
		(((float) ((mac_prefs->gui_foreground & 0x0000FF))) / 255)]
		forKey:GuiForeBlue];
	[displayedValues setObject:[NSNumber numberWithFloat:
		(((float) ((mac_prefs->gui_background & 0xFF0000) >> 16)) / 255)]
		forKey:GuiBackRed];
	[displayedValues setObject:[NSNumber numberWithFloat:
		(((float) ((mac_prefs->gui_background & 0x00FF00) >> 8)) / 255)]
		forKey:GuiBackGreen];
	[displayedValues setObject:[NSNumber numberWithFloat:
		(((float) ((mac_prefs->gui_background & 0x0000FF))) / 255)]
		forKey:GuiBackBlue];
    [displayedValues setObject:mac_prefs->trs_show_led ? yes : no forKey:LedStatus];
    switch(mac_prefs->trs_charset1) {
        case 0:
		default:
            [displayedValues setObject:zero forKey:Model1Font];
            break;
        case 1:
            [displayedValues setObject:one forKey:Model1Font];
            break;
        case 2:
            [displayedValues setObject:two forKey:Model1Font];
            break;
        case 3:
            [displayedValues setObject:three forKey:Model1Font];
            break;
        case 10:
            [displayedValues setObject:four forKey:Model1Font];
            break;
		}
    switch(mac_prefs->trs_charset3) {
        case 4:
		default:
            [displayedValues setObject:zero forKey:Model3Font];
            break;
        case 5:
            [displayedValues setObject:one forKey:Model3Font];
            break;
        case 6:
            [displayedValues setObject:two forKey:Model3Font];
            break;
		}
    switch(mac_prefs->trs_charset4) {
        case 7:
		default:
            [displayedValues setObject:zero forKey:Model4Font];
            break;
        case 8:
            [displayedValues setObject:one forKey:Model4Font];
            break;
        case 9:
            [displayedValues setObject:two forKey:Model4Font];
            break;
		}
	// TRS Items
    switch(mac_prefs->trs_model) {
        case 1:
		default:
            [displayedValues setObject:zero forKey:TrsModel];
            break;
        case 3:
            [displayedValues setObject:one forKey:TrsModel];
            break;
        case 4:
            [displayedValues setObject:two forKey:TrsModel];
            break;
        case 5:
            [displayedValues setObject:three forKey:TrsModel];
            break;
		}
    switch(mac_prefs->micrographyx) {
        case 0:
		default:
            [displayedValues setObject:zero forKey:GraphicsModel];
            break;
        case 1:
            [displayedValues setObject:one forKey:GraphicsModel];
            break;
		}
    [displayedValues setObject:mac_prefs->shiftbracket ? yes : no forKey:ShiftBracket];
	[displayedValues setObject:[NSNumber numberWithInt:mac_prefs->stretch_amount] forKey:Keystretch];
	[displayedValues setObject:[NSNumber numberWithInt:mac_prefs->switches] forKey:SerialSwitches];
	[displayedValues setObject:[NSString stringWithCString:mac_prefs->serial_port] forKey:SerialPort];
    switch(mac_prefs->disk_sizes[0]) {
        case 0:
		default:
            [displayedValues setObject:zero forKey:Disk1Size];
            break;
        case 1:
            [displayedValues setObject:one forKey:Disk1Size];
            break;
		}
    switch(mac_prefs->disk_sizes[1]) {
        case 0:
		default:
            [displayedValues setObject:zero forKey:Disk2Size];
            break;
        case 1:
            [displayedValues setObject:one forKey:Disk2Size];
            break;
		}
    switch(mac_prefs->disk_sizes[2]) {
        case 0:
		default:
            [displayedValues setObject:zero forKey:Disk3Size];
            break;
        case 1:
            [displayedValues setObject:one forKey:Disk3Size];
            break;
		}
    switch(mac_prefs->disk_sizes[3]) {
        case 0:
		default:
            [displayedValues setObject:zero forKey:Disk4Size];
            break;
        case 1:
            [displayedValues setObject:one forKey:Disk4Size];
            break;
		}
    switch(mac_prefs->disk_sizes[4]) {
        case 0:
		default:
            [displayedValues setObject:zero forKey:Disk5Size];
            break;
        case 1:
            [displayedValues setObject:one forKey:Disk5Size];
            break;
		}
    switch(mac_prefs->disk_sizes[5]) {
        case 0:
		default:
            [displayedValues setObject:zero forKey:Disk6Size];
            break;
        case 1:
            [displayedValues setObject:one forKey:Disk6Size];
            break;
		}
    switch(mac_prefs->disk_sizes[6]) {
        case 0:
		default:
            [displayedValues setObject:zero forKey:Disk7Size];
            break;
        case 1:
            [displayedValues setObject:one forKey:Disk7Size];
            break;
		}
    switch(mac_prefs->disk_sizes[7]) {
        case 0:
		default:
            [displayedValues setObject:zero forKey:Disk8Size];
            break;
        case 1:
            [displayedValues setObject:one forKey:Disk8Size];
            break;
		}
    switch(mac_prefs->trs_disk_doubler) {
        case 0:
		default:
            [displayedValues setObject:zero forKey:DoublerType];
            break;
        case 1:
            [displayedValues setObject:one forKey:DoublerType];
            break;
        case 2:
            [displayedValues setObject:two forKey:DoublerType];
            break;
        case 3:
            [displayedValues setObject:three forKey:DoublerType];
            break;
		}
    [displayedValues setObject:mac_prefs->trs_disk_truedam ? yes : no forKey:TrueDam];
    [displayedValues setObject:mac_prefs->trs_emtsafe ? yes : no forKey:EmtSafe];
    [displayedValues setObject:mac_prefs->mediaStatusWindowOpen ? yes : no forKey:MediaStatusDisplayed];
	// Printer Items
	[displayedValues setObject:[NSString stringWithCString:mac_prefs->print_command] forKey:PrintCommand];
    switch(mac_prefs->trs_printer) {
        case 0:
		default:
            [displayedValues setObject:zero forKey:PrinterType];
            break;
        case 1:
            [displayedValues setObject:one forKey:PrinterType];
            break;
        case 2:
            [displayedValues setObject:two forKey:PrinterType];
            break;
        case 3:
            [displayedValues setObject:three forKey:PrinterType];
            break;
	}
	// ROM Itmes
	[displayedValues setObject:[NSString stringWithCString:mac_prefs->romfile] forKey:Model1RomFile];
	[displayedValues setObject:[NSString stringWithCString:mac_prefs->romfile3] forKey:Model3RomFile];
	[displayedValues setObject:[NSString stringWithCString:mac_prefs->romfile4p] forKey:Model4pRomFile];
	// Dir Items
	[displayedValues setObject:[NSString stringWithCString:mac_prefs->trs_disk_dir] forKey:DiskImageDir];
	[displayedValues setObject:[NSString stringWithCString:mac_prefs->trs_hard_dir] forKey:HardImageDir];
	[displayedValues setObject:[NSString stringWithCString:mac_prefs->trs_cass_dir] forKey:CassImageDir];
	[displayedValues setObject:[NSString stringWithCString:mac_prefs->trs_disk_set_dir] forKey:DiskSetDir];
	[displayedValues setObject:[NSString stringWithCString:mac_prefs->trs_state_dir] forKey:SavedStateDir];
	[displayedValues setObject:[NSString stringWithCString:mac_prefs->trs_printer_dir] forKey:PrintDir];
	// Joystick Items
    [displayedValues setObject:mac_prefs->trs_keypad_joystick ? yes : no forKey:KeypadJoystick];
	if (mac_prefs->trs_joystick_num == -1)
		[displayedValues setObject:zero forKey:JoystickNumber];
	else
		[displayedValues setObject:[NSNumber numberWithInt:mac_prefs->trs_joystick_num+1] forKey:JoystickNumber];
	}
		
/*------------------------------------------------------------------------------
*  Origin functions which return the origin of windows stored in the 
*     preferences.
*-----------------------------------------------------------------------------*/

- (NSPoint)mediaStatusOrigin
{
   NSPoint origin;
   
   origin.x = [[displayedValues objectForKey:MediaStatusX] floatValue];
   origin.y = [[displayedValues objectForKey:MediaStatusY] floatValue];
   
   return(origin);
}
	
- (NSPoint)messagesOrigin
{
   NSPoint origin;
   
   origin.x = [[displayedValues objectForKey:MessagesX] floatValue];
   origin.y = [[displayedValues objectForKey:MessagesY] floatValue];
   
   return(origin);
}
	
- (NSPoint)debuggerOrigin
{
   NSPoint origin;
   
   origin.x = [[displayedValues objectForKey:DebuggerX] floatValue];
   origin.y = [[displayedValues objectForKey:DebuggerY] floatValue];
   
   return(origin);
}
	
- (NSPoint)applicationWindowOrigin
{
   NSPoint origin;
   
   origin.x = [[displayedValues objectForKey:ApplicationWindowX] floatValue];
   origin.y = [[displayedValues objectForKey:ApplicationWindowY] floatValue];
   
   return(origin);
}

/* Handle the OK, cancel, and Revert buttons */

- (void)ok:(id)sender {
    [self miscChanged:self];
     [self commitDisplayedValues];
    [NSApp stopModal];
    [[prefTabView window] close];
    [self transferValuesToEmulator];
    [self transferValuesToAtari1020];
    [self transferValuesToEpson];
    trs_pause_audio(0);
}

- (void)revertToDefault:(id)sender {
    curValues = [defaultValues() mutableCopyWithZone:[self zone]];
    
    [self discardDisplayedValues];
    [NSApp stopModal];
    [[prefTabView window] close];
    [self transferValuesToEmulator];
    [self transferValuesToAtari1020];
    [self transferValuesToEpson];
    trs_pause_audio(0);
}

- (void)revert:(id)sender {
    [self discardDisplayedValues];
    [NSApp stopModal];
    [[prefTabView window] close];
    trs_pause_audio(0);
}

/**** Code to deal with defaults ****/
   
#define getBoolDefault(name) \
  {id obj = [defaults objectForKey:name]; \
      [dict setObject:obj ? [NSNumber numberWithBool:[defaults boolForKey:name]] : [defaultValues() objectForKey:name] forKey:name];}

#define getIntDefault(name) \
  {id obj = [defaults objectForKey:name]; \
      [dict setObject:obj ? [NSNumber numberWithInt:[defaults integerForKey:name]] : [defaultValues() objectForKey:name] forKey:name];}

#define getFloatDefault(name) \
  {id obj = [defaults objectForKey:name]; \
      [dict setObject:obj ? [NSNumber numberWithFloat:[defaults floatForKey:name]] : [defaultValues() objectForKey:name] forKey:name];}

#define getStringDefault(name) \
  {id obj = [defaults objectForKey:name]; \
      [dict setObject:obj ? [NSString stringWithString:[defaults stringForKey:name]] : [defaultValues() objectForKey:name] forKey:name];}
      
#define getArrayDefault(name) \
  {id obj = [defaults objectForKey:name]; \
      [dict setObject:obj ? [NSMutableArray arrayWithArray:[defaults arrayForKey:name]] : [[defaultValues() objectForKey:name] mutableCopyWithZone:[self zone]] forKey:name];}
      
/* Read prefs from system defaults */
+ (NSDictionary *)preferencesFromDefaults {    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:10];
    // Display Items
    getBoolDefault(FullScreen);
    getIntDefault(ScaleFactor);
    getIntDefault(BorderWidth);
    getBoolDefault(Resize3);
    getBoolDefault(Resize4);
	getFloatDefault(ForeRed); 
	getFloatDefault(ForeBlue); 
	getFloatDefault(ForeGreen); 
	getFloatDefault(ForeAlpha); 
	getFloatDefault(BackRed); 
	getFloatDefault(BackBlue); 
	getFloatDefault(BackGreen); 
	getFloatDefault(BackAlpha); 
	getFloatDefault(GuiForeRed); 
	getFloatDefault(GuiForeBlue); 
	getFloatDefault(GuiForeGreen); 
	getFloatDefault(GuiForeAlpha); 
	getFloatDefault(GuiBackRed); 
	getFloatDefault(GuiBackBlue); 
	getFloatDefault(GuiBackGreen); 
	getFloatDefault(GuiBackAlpha); 
    getBoolDefault(LedStatus);
    getIntDefault(Model1Font);
    getIntDefault(Model3Font);
    getIntDefault(Model4Font);
    // TRS items
    getIntDefault(TrsModel);
    getIntDefault(GraphicsModel);
    getBoolDefault(ShiftBracket);
    getIntDefault(Keystretch);
    getIntDefault(SerialSwitches);
    getStringDefault(SerialPort);
    getIntDefault(Disk1Size);
    getIntDefault(Disk2Size);
    getIntDefault(Disk3Size);
    getIntDefault(Disk4Size);
    getIntDefault(Disk5Size);
    getIntDefault(Disk6Size);
    getIntDefault(Disk7Size);
    getIntDefault(Disk8Size);
    getIntDefault(DoublerType);
    getBoolDefault(TrueDam);
    getBoolDefault(EmtSafe);
    // Printer Items
    getStringDefault(PrintCommand);
	getIntDefault(PrinterType);
	getIntDefault(Atari1020PrintWidth); 
	getIntDefault(Atari1020FormLength); 
	getBoolDefault(Atari1020AutoLinefeed); 
	getBoolDefault(Atari1020AutoPageAdjust); 
	getFloatDefault(Atari1020Pen1Red); 
	getFloatDefault(Atari1020Pen1Blue); 
	getFloatDefault(Atari1020Pen1Green); 
	getFloatDefault(Atari1020Pen1Alpha); 
	getFloatDefault(Atari1020Pen2Red); 
	getFloatDefault(Atari1020Pen2Blue); 
	getFloatDefault(Atari1020Pen2Green); 
	getFloatDefault(Atari1020Pen2Alpha); 
	getFloatDefault(Atari1020Pen3Red); 
	getFloatDefault(Atari1020Pen3Blue); 
	getFloatDefault(Atari1020Pen3Green); 
	getFloatDefault(Atari1020Pen3Alpha); 
	getFloatDefault(Atari1020Pen4Red); 
	getFloatDefault(Atari1020Pen4Blue);
	getFloatDefault(Atari1020Pen4Green); 
	getFloatDefault(Atari1020Pen4Alpha); 
	getIntDefault(EpsonCharSet); 
	getIntDefault(EpsonPrintPitch); 
	getIntDefault(EpsonPrintWeight); 
	getIntDefault(EpsonFormLength); 
	getBoolDefault(EpsonAutoLinefeed); 
	getBoolDefault(EpsonPrintSlashedZeros); 
	getBoolDefault(EpsonAutoSkip); 
	getBoolDefault(EpsonSplitSkip); 
    // Rom Items
    getStringDefault(Model1RomFile);
    getStringDefault(Model3RomFile);
    getStringDefault(Model4pRomFile);
    // Dir Items 
    getStringDefault(DiskImageDir);
    getStringDefault(HardImageDir);
    getStringDefault(CassImageDir);
    getStringDefault(DiskSetDir);
    getStringDefault(SavedStateDir);
    getStringDefault(PrintDir);
    // Joystick Items
	getBoolDefault(KeypadJoystick); 
	getIntDefault(JoystickNumber);     
    // Display Position items
	getBoolDefault(MediaStatusDisplayed);
    getIntDefault(MediaStatusX);
    getIntDefault(MediaStatusY);
    getIntDefault(MessagesX);
    getIntDefault(MessagesY);
    getIntDefault(DebuggerX);
    getIntDefault(DebuggerY);
    getIntDefault(FunctionKeysX);
    getIntDefault(FunctionKeysY);
    getIntDefault(ApplicationWindowX);
    getIntDefault(ApplicationWindowY);

    return dict;
}

#define setBoolDefault(name) \
  {if ([[defaultValues() objectForKey:name] isEqual:[dict objectForKey:name]]) [defaults removeObjectForKey:name]; else [defaults setBool:[[dict objectForKey:name] boolValue] forKey:name];}

#define setIntDefault(name) \
  {if ([[defaultValues() objectForKey:name] isEqual:[dict objectForKey:name]]) [defaults removeObjectForKey:name]; else [defaults setInteger:[[dict objectForKey:name] intValue] forKey:name];}

#define setFloatDefault(name) \
  {if ([[defaultValues() objectForKey:name] isEqual:[dict objectForKey:name]]) [defaults removeObjectForKey:name]; else [defaults setFloat:[[dict objectForKey:name] floatValue] forKey:name];}

#define setStringDefault(name) \
  {if ([[defaultValues() objectForKey:name] isEqual:[dict objectForKey:name]]) [defaults removeObjectForKey:name]; else [defaults setObject:[dict objectForKey:name] forKey:name];}

#define setArrayDefault(name) \
  {if ([[defaultValues() objectForKey:name] isEqual:[dict objectForKey:name]]) [defaults removeObjectForKey:name]; else [defaults setObject:[dict objectForKey:name] forKey:name];}

/* Save preferences to system defaults */
+ (void)savePreferencesToDefaults:(NSDictionary *)dict {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    // Display Items
    setBoolDefault(FullScreen);
    setIntDefault(ScaleFactor);
    setIntDefault(BorderWidth);
    setBoolDefault(Resize3);
    setBoolDefault(Resize4);
	setFloatDefault(ForeRed); 
	setFloatDefault(ForeBlue); 
	setFloatDefault(ForeGreen); 
	setFloatDefault(ForeAlpha); 
	setFloatDefault(BackRed); 
	setFloatDefault(BackBlue); 
	setFloatDefault(BackGreen); 
	setFloatDefault(BackAlpha); 
	setFloatDefault(GuiForeRed); 
	setFloatDefault(GuiForeBlue); 
	setFloatDefault(GuiForeGreen); 
	setFloatDefault(GuiForeAlpha); 
	setFloatDefault(GuiBackRed); 
	setFloatDefault(GuiBackBlue); 
	setFloatDefault(GuiBackGreen); 
	setFloatDefault(GuiBackAlpha); 
    setBoolDefault(LedStatus);
    setIntDefault(Model1Font);
    setIntDefault(Model3Font);
    setIntDefault(Model4Font);
    // TRS items
    setIntDefault(TrsModel);
    setIntDefault(GraphicsModel);
    setBoolDefault(ShiftBracket);
    setIntDefault(Keystretch);
    setIntDefault(SerialSwitches);
    setStringDefault(SerialPort);
    setIntDefault(Disk1Size);
    setIntDefault(Disk2Size);
    setIntDefault(Disk3Size);
    setIntDefault(Disk4Size);
    setIntDefault(Disk5Size);
    setIntDefault(Disk6Size);
    setIntDefault(Disk7Size);
    setIntDefault(Disk8Size);
    setIntDefault(DoublerType);
    setBoolDefault(TrueDam);
    setBoolDefault(EmtSafe);
    // Printer Items
    setStringDefault(PrintCommand);
	setIntDefault(PrinterType);
	setIntDefault(Atari1020PrintWidth); 
	setIntDefault(Atari1020FormLength); 
	setBoolDefault(Atari1020AutoLinefeed); 
	setBoolDefault(Atari1020AutoPageAdjust); 
	setFloatDefault(Atari1020Pen1Red); 
	setFloatDefault(Atari1020Pen1Blue); 
	setFloatDefault(Atari1020Pen1Green); 
	setFloatDefault(Atari1020Pen1Alpha); 
	setFloatDefault(Atari1020Pen2Red); 
	setFloatDefault(Atari1020Pen2Blue); 
	setFloatDefault(Atari1020Pen2Green); 
	setFloatDefault(Atari1020Pen2Alpha); 
	setFloatDefault(Atari1020Pen3Red); 
	setFloatDefault(Atari1020Pen3Blue); 
	setFloatDefault(Atari1020Pen3Green); 
	setFloatDefault(Atari1020Pen3Alpha); 
	setFloatDefault(Atari1020Pen4Red); 
	setFloatDefault(Atari1020Pen4Blue);
	setFloatDefault(Atari1020Pen4Green); 
	setFloatDefault(Atari1020Pen4Alpha); 
	setIntDefault(EpsonCharSet); 
	setIntDefault(EpsonPrintPitch); 
	setIntDefault(EpsonPrintWeight); 
	setIntDefault(EpsonFormLength); 
	setBoolDefault(EpsonAutoLinefeed); 
	setBoolDefault(EpsonPrintSlashedZeros); 
	setBoolDefault(EpsonAutoSkip); 
	setBoolDefault(EpsonSplitSkip); 
    // Rom Items
    setStringDefault(Model1RomFile);
    setStringDefault(Model3RomFile);
    setStringDefault(Model4pRomFile);
    // Dir Items 
    setStringDefault(DiskImageDir);
    setStringDefault(HardImageDir);
    setStringDefault(CassImageDir);
    setStringDefault(DiskSetDir);
    setStringDefault(SavedStateDir);
    setStringDefault(PrintDir);
    // Joystick Items
	setBoolDefault(KeypadJoystick); 
	setIntDefault(JoystickNumber);     
    // Display Position items
	setBoolDefault(MediaStatusDisplayed);
    setIntDefault(MediaStatusX);
    setIntDefault(MediaStatusY);
    setIntDefault(MessagesX);
    setIntDefault(MessagesY);
    setIntDefault(DebuggerX);
    setIntDefault(DebuggerY);
    setIntDefault(FunctionKeysX);
    setIntDefault(FunctionKeysY);
    setIntDefault(ApplicationWindowX);
    setIntDefault(ApplicationWindowY);

    [defaults synchronize];
}

/**** Window delegation ****/

// We do this to catch the case where the user enters a value into one of the text fields but closes the window without hitting enter or tab.

- (void)windowWillClose:(NSNotification *)notification {
    NSWindow *window = [notification object];
    (void)[window makeFirstResponder:window];
}

/*------------------------------------------------------------------------------
*  applicationWindowOriginSave - This method saves the position of the app
*    window
*-----------------------------------------------------------------------------*/
- (NSPoint)applicationWindowOriginSave
{
	NSRect frame;
	
	frame = [appWindow frame];
	return(frame.origin);
}



@end
