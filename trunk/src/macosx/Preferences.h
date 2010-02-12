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
#import "Atari1020Simulator.h"
#import "EpsonFx80Simulator.h"

/* Keys in the dictionary... */
// Display Items
#define FullScreen @"FullScreen"
#define ScaleFactor @"ScaleFactor"
#define BorderWidth @"BorderWidth"
#define Resize3 @"Resize3"
#define Resize4 @"Resize4"
#define ForeRed @"ForeRed"
#define ForeBlue @"ForeBlue"
#define ForeGreen @"ForeGreen"
#define ForeAlpha @"ForeAlpha"
#define BackRed @"BackRed"
#define BackBlue @"BackBlue"
#define BackGreen @"BackGreen"
#define BackAlpha @"BackAlpha"
#define GuiForeRed @"GuiForeRed"
#define GuiForeBlue @"GuiForeBlue"
#define GuiForeGreen @"GuiForeGreen"
#define GuiForeAlpha @"GuiForeAlpha"
#define GuiBackRed @"GuiBackRed"
#define GuiBackBlue @"GuiBackBlue"
#define GuiBackGreen @"GuiBackGreen"
#define GuiBackAlpha @"GuiBackAlpha"
#define LedStatus @"LedStatus"
#define Model1Font @"Model1Font"
#define Model3Font @"Model3Font"
#define Model4Font @"Model4Font"
// TRS Items
#define TrsModel @"TrsModel"
#define GraphicsModel @"GraphicsModel"
#define ShiftBracket @"ShiftBracket"
#define Keystretch @"Keystretch"
#define Turbo @"Turbo"
#define TurboRate @"TurboRate"
#define SerialSwitches @"SerialSwitches"
#define SerialPort @"SerialPort"
#define Disk1Size @"Disk1Size"
#define Disk2Size @"Disk2Size"
#define Disk3Size @"Disk3Size"
#define Disk4Size @"Disk4Size"
#define Disk5Size @"Disk5Size"
#define Disk6Size @"Disk6Size"
#define Disk7Size @"Disk7Size"
#define Disk8Size @"Disk8Size"
#define DoublerType @"DoublerType"
#define TrueDam @"TrueDam"
#define EmtSafe @"EmtSafe"
// Printer Items
#define PrintCommand @"PrintCommand"
#define PrinterType @"PrinterType"
#define Atari1020PrintWidth @"Atari1020PrintWidth"
#define Atari1020FormLength @"Atari1020FormLength"
#define Atari1020AutoLinefeed @"Atari825AutoLinefeed"
#define Atari1020AutoPageAdjust @"Atari1020AutoPageAdjust"
#define Atari1020Pen1Red @"Atari1020Pen1Red"
#define Atari1020Pen1Blue @"Atari1020Pen1Blue"
#define Atari1020Pen1Green @"Atari1020Pen1Green"
#define Atari1020Pen1Alpha @"Atari1020Pen1Alpha"
#define Atari1020Pen2Red @"Atari1020Pen2Red"
#define Atari1020Pen2Blue @"Atari1020Pen2Blue"
#define Atari1020Pen2Green @"Atari1020Pen2Green"
#define Atari1020Pen2Alpha @"Atari1020Pen2Alpha"
#define Atari1020Pen3Red @"Atari1020Pen3Red"
#define Atari1020Pen3Blue @"Atari1020Pen3Blue"
#define Atari1020Pen3Green @"Atari1020Pen3Green"
#define Atari1020Pen3Alpha @"Atari1020Pen3Alpha"
#define Atari1020Pen4Red @"Atari1020Pen4Red"
#define Atari1020Pen4Blue @"Atari1020Pen4Blue"
#define Atari1020Pen4Green @"Atari1020Pen4Green"
#define Atari1020Pen4Alpha @"Atari1020Pen4Alpha"
#define EpsonCharSet @"EpsonCharSet"
#define EpsonPrintPitch @"EpsonPrintPitch"
#define EpsonPrintWeight @"EpsonPrintWeight"
#define EpsonFormLength @"EpsonFormLength"
#define EpsonAutoLinefeed @"EpsonAutoLinefeed"
#define EpsonPrintSlashedZeros @"EpsonPrintSlashedZeros"
#define EpsonAutoSkip @"EpsonAutoSkip"
#define EpsonSplitSkip @"EpsonSplitSkip"
// ROM Items
#define Model1RomFile @"Model1RomFile"
#define Model3RomFile @"Model3RomFile"
#define Model4pRomFile @"Model4pRomFile"
// Dir items
#define DiskImageDir @"DiskImageDir"
#define HardImageDir @"HardImageDir"
#define CassImageDir @"CassImageDir"
#define DiskSetDir @"DiskSetDir"
#define SavedStateDir @"SavedStateDir"
#define PrintDir @"PrintDir"
// Joystick Items
#define KeypadJoystick @"KeypadJoystick"
#define JoystickNumber @"JoystickNumber"
// Display Position items
#define MediaStatusDisplayed @"MediaStatusDisplayed"
#define MediaStatusX @"MediaStatusX"
#define MediaStatusY @"MediaStatusY"
#define MessagesX @"MessagesX"
#define MessagesY @"MessagesY"
#define DebuggerX @"DebuggerX"
#define DebuggerY @"DebuggerY"
#define FunctionKeysX @"FunctionKeysX"
#define FunctionKeysY @"FunctionKeysY"
#define ApplicationWindowX @"ApplicationWindowX"
#define ApplicationWindowY @"ApplicationWindowY"

@interface Preferences : NSObject {
    IBOutlet id prefTabView;
    // Display items
    IBOutlet id fullScreenMatrix;
    IBOutlet id scaleFactorMatrix;
    IBOutlet id windowBorderWidthField;
    IBOutlet id resize3Button;
    IBOutlet id resize4Button;
	IBOutlet id foregroundPot;
	IBOutlet id backgroundPot;
	IBOutlet id guiForegroundPot;
	IBOutlet id guiBackgroundPot;
    IBOutlet id model1FontPulldown;
    IBOutlet id model3FontPulldown;
    IBOutlet id model4FontPulldown;
	IBOutlet id ledStatusButton;
    // TRS80 items
    IBOutlet id trsModelPulldown;
    IBOutlet id trsGraphicsPulldown;
    IBOutlet id shiftBracketButton;
    IBOutlet id keyboardStretchField;
	IBOutlet id turboButton;
	IBOutlet id turboRateField;
    IBOutlet id serialSwitchesField;
    IBOutlet id serialPortField;
	IBOutlet id disk1SizeMatrix;
	IBOutlet id disk2SizeMatrix;
	IBOutlet id disk3SizeMatrix;
	IBOutlet id disk4SizeMatrix;
	IBOutlet id disk5SizeMatrix;
	IBOutlet id disk6SizeMatrix;
	IBOutlet id disk7SizeMatrix;
	IBOutlet id disk8SizeMatrix;
	IBOutlet id doublerTypePulldown;
	IBOutlet id trueDamButton;
	IBOutlet id emtSafeButton;
    // Printer Items
    IBOutlet id printCommandField;
	IBOutlet id printerTypePulldown;
	IBOutlet id atari1020PrintWidthPulldown;
	IBOutlet id atari1020FormLengthField;
	IBOutlet id atari1020FormLengthStepper;
	IBOutlet id atari1020AutoLinefeedButton;
	IBOutlet id atari1020AutoPageAdjustButton;
	IBOutlet id atari1020Pen1Pot;
	IBOutlet id atari1020Pen2Pot;
	IBOutlet id atari1020Pen3Pot;
	IBOutlet id atari1020Pen4Pot;
	IBOutlet id epsonCharSetPulldown;
	IBOutlet id epsonPrintPitchPulldown;
	IBOutlet id epsonPrintWeightPulldown;
	IBOutlet id epsonFormLengthField;
	IBOutlet id epsonFormLengthStepper;
	IBOutlet id epsonAutoLinefeedButton;
	IBOutlet id epsonPrintSlashedZerosButton;
	IBOutlet id epsonAutoSkipButton;
	IBOutlet id epsonSplitSkipButton;
    // Roms Items
    IBOutlet id model1RomFileField;
    IBOutlet id model3RomFileField;
    IBOutlet id model4pRomFileField;
    // Dir Items
    IBOutlet id diskImageDirField;
    IBOutlet id hardImageDirField;
    IBOutlet id cassImageDirField;
    IBOutlet id diskSetDirField;
    IBOutlet id savedStateDirField;
    IBOutlet id printDirField;
    // Joystick Items
    IBOutlet id keyboardJoystickButton;
    IBOutlet id usbJoystickPulldown;
    
    int numJoysticks;
    
    NSMutableDictionary *curValues;	// Current, confirmed values for the preferences
    NSDictionary *origValues;	// Values read from preferences at startup
    NSMutableDictionary *displayedValues;	// Values displayed in the UI
}

+ (id)objectForKey:(id)key;	/* Convenience for getting global preferences */
+ (void)saveDefaults;		/* Convenience for saving global preferences */
- (void)saveDefaults;		/* Save the current preferences */

+ (Preferences *)sharedInstance;

+ (void)setWorkingDirectory:(char *)dir;  /* Save the base directory of the application */
+ (char *)getWorkingDirectory;  /* Get the base directory of the application */

- (NSDictionary *)preferences;	/* The current preferences; contains values for the documented keys */

- (void)showPanel:(id)sender;	/* Shows the panel */

- (void)updateUI;		/* Updates the displayed values in the UI */
- (void)commitDisplayedValues;	/* The displayed values are made current */
- (void)discardDisplayedValues;	/* The displayed values are replaced with current prefs and updateUI is called */

- (void)revert:(id)sender;	/* Reverts the displayed values to the current preferences */
- (void)ok:(id)sender;		/* Calls commitUI to commit the displayed values as current */
- (void)revertToDefault:(id)sender;    

- (void)miscChanged:(id)sender;	/* Action message for most of the misc items in the UI to get displayedValues  */
- (void)browseModel1Rom:(id)sender; 
- (void)browseModel3Rom:(id)sender; 
- (void)browseModel4pRom:(id)sender; 
- (void)browseDiskDir:(id)sender; 
- (void)browseHardDir:(id)sender; 
- (void)browseDiskSetDir:(id)sender; 
- (void)browseCassDir:(id)sender; 
- (void)browseStateDir:(id)sender; 
- (void)browsePrintDir:(id)sender; 
- (void)transferValuesToEmulator;
- (void)transferValuesFromEmulator;
- (void)transferValuesToEpson;
- (void)transferValuesToAtari1020;
- (NSPoint)mediaStatusOrigin;
- (NSPoint)messagesOrigin;
- (NSPoint)debuggerOrigin;
- (NSPoint)applicationWindowOrigin;
- (void)windowWillClose:(NSNotification *)notification;
- (NSPoint)applicationWindowOriginSave;

+ (NSDictionary *)preferencesFromDefaults;
+ (void)savePreferencesToDefaults:(NSDictionary *)dict;

@end
