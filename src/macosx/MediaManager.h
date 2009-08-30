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

@interface MediaManager : NSObject
{
    // Disk Management Window
    IBOutlet id d1DiskField;
    IBOutlet id d1DriveStatusPulldown;
    IBOutlet id d2DiskField;
    IBOutlet id d2DriveStatusPulldown;
    IBOutlet id d3DiskField;
    IBOutlet id d3DriveStatusPulldown;
    IBOutlet id d4DiskField;
    IBOutlet id d4DriveStatusPulldown;
    IBOutlet id d5DiskField;
    IBOutlet id d5DriveStatusPulldown;
    IBOutlet id d6DiskField;
    IBOutlet id d6DriveStatusPulldown;
    IBOutlet id d7DiskField;
    IBOutlet id d7DriveStatusPulldown;
    IBOutlet id d8DiskField;
    IBOutlet id d8DriveStatusPulldown;
    // Hard Management Window
    IBOutlet id h1DiskField;
    IBOutlet id h1DriveStatusPulldown;
    IBOutlet id h2DiskField;
    IBOutlet id h2DriveStatusPulldown;
    IBOutlet id h3DiskField;
    IBOutlet id h3DriveStatusPulldown;
    IBOutlet id h4DiskField;
    IBOutlet id h4DriveStatusPulldown;
    // Cassette Management Window
    IBOutlet id cassetteField;
    IBOutlet id cassetteCurrPosField;
    IBOutlet id cassetteMaxPosField;
	IBOutlet id cassetteImageInsertButton1;
    // Disk Creation Window
    IBOutlet id diskFmtMatrix;
    IBOutlet id diskFmtDmkNumSidesPulldown;
    IBOutlet id diskFmtDmkDensityPulldown;
    IBOutlet id diskFmtDmkPhysicalSizePulldown;
    IBOutlet id diskFmtDmkIgnoreDensityPulldown;
    IBOutlet id diskFmtInsertDrivePulldown;
    IBOutlet id diskFmtInsertNewButton;
    // Hard Creation Window
    IBOutlet id hardFmtCylinderCountField;
    IBOutlet id hardFmtSectorCountField;
    IBOutlet id hardFmtGranularityField;
    IBOutlet id hardFmtDirectorySectorField;
    IBOutlet id hardFmtInsertDrivePulldown;
    IBOutlet id hardFmtInsertNewButton;
    // Cassette Creation Window
    IBOutlet id cassFmtPulldown;
    IBOutlet id cassFmtInsertNewButton;
    // Floppy Menus
    IBOutlet id removeMenu;
    IBOutlet id removeD1Item;
    IBOutlet id removeD2Item;
    IBOutlet id removeD3Item;
    IBOutlet id removeD4Item;
    IBOutlet id removeD5Item;
    IBOutlet id removeD6Item;
    IBOutlet id removeD7Item;
    IBOutlet id removeD8Item;
    IBOutlet id removeCartItem;
    IBOutlet id removeCassItem;
    IBOutlet id rewindCassItem;
	IBOutlet id selectPrinterPulldown;
	IBOutlet id selectPrinterMenu;
	IBOutlet id resetPrinterItem;
	IBOutlet id resetPrinterMenuItem;
    IBOutlet id errorButton;
    IBOutlet id errorField;
    IBOutlet id error2Button;
    IBOutlet id error2Field1;
    IBOutlet id error2Field2;
    // Media Status Window
	IBOutlet id d1DiskImageInsertButton;
	IBOutlet id d1DiskImageNameField;
	IBOutlet id d1DiskImageNumberField;
	IBOutlet id d1DiskImageProtectButton;
	IBOutlet id d1DiskImageView;
	IBOutlet id d1DiskImageLockView;
	IBOutlet id d2DiskImageInsertButton;
	IBOutlet id d2DiskImageNameField;
	IBOutlet id d2DiskImageNumberField;
	IBOutlet id d2DiskImageProtectButton;
	IBOutlet id d2DiskImageView;
	IBOutlet id d2DiskImageLockView;
	IBOutlet id d3DiskImageInsertButton;
	IBOutlet id d3DiskImageNameField;
	IBOutlet id d3DiskImageNumberField;
	IBOutlet id d3DiskImageProtectButton;
	IBOutlet id d3DiskImageView;
	IBOutlet id d3DiskImageLockView;
	IBOutlet id d4DiskImageInsertButton;
	IBOutlet id d4DiskImageNameField;
	IBOutlet id d4DiskImageNumberField;
	IBOutlet id d4DiskImageProtectButton;
	IBOutlet id d4DiskImageView;
	IBOutlet id d4DiskImageLockView;
	IBOutlet id driveSelectMatrix;
	IBOutlet id cassImageManageButton;
	IBOutlet id cassImageNameField;
	IBOutlet id cassImageView;
	IBOutlet id cassetteImageInsertButton2;
	IBOutlet id printerImageView;
	IBOutlet id printerImageNameField;
	IBOutlet id printerPreviewButton;
	IBOutlet id printerPreviewItem;
	IBOutlet id modelPulldown;
	IBOutlet id graphicsPulldown;
	
}
+ (MediaManager *)sharedInstance;
- (void)pushUserEvent:(int)code:(void *)data;
- (void)displayError:(NSString *)errorMsg;
- (void)updateInfo;
- (void)updateDiskInfo;
- (void)updateHardInfo;
- (void)updateCassInfo;
- (NSString *) browseFileInDirectory:(NSString *)directory;
- (NSString *) browseFileTypeInDirectory:(NSString *)directory:(NSArray *) filetypes;
- (NSString *) saveFileInDirectory:(NSString *)directory:(NSString *)type;
- (IBAction)cancelDisk:(id)sender;
- (IBAction)cancelHard:(id)sender;
- (IBAction)cancelCass:(id)sender;
- (IBAction)cassInsert:(id)sender;
- (void)cassInsertFile:(NSString *)filename;
- (IBAction)cassRemove:(id)sender;
- (IBAction)createDisk:(id)sender;
- (IBAction)createHard:(id)sender;
- (IBAction)createCassette:(id)sender;
- (IBAction)diskInsert:(id)sender;
- (void)diskInsertFile:(NSString *)filename;
- (void)diskNoInsertFile:(NSString *)filename:(int) driveNo;
- (IBAction)diskRemove:(id)sender;
- (IBAction)diskInsertKey:(int)diskNum;
- (IBAction)diskSetSave:(id)sender;
- (IBAction)diskSetLoad:(id)sender;
- (IBAction)diskSetLoadFile:(NSString *)filename;
- (IBAction)diskRemoveKey:(int)diskNum;
- (IBAction)diskRemoveAll:(id)sender;
- (IBAction)hardRemoveAll:(id)sender;
- (IBAction)driveStatusChange:(id)sender;
- (IBAction)hardStatusChange:(id)sender;
- (IBAction)diskMiscUpdate:(id)sender;
- (IBAction)hardMiscUpdate:(id)sender;
- (IBAction)okDisk:(id)sender;
- (IBAction)okHard:(id)sender;
- (IBAction)okCass:(id)sender;
- (IBAction)showDiskCreatePanel:(id)sender;
- (IBAction)showHardCreatePanel:(id)sender;
- (IBAction)showCassCreatePanel:(id)sender;
- (IBAction)showDiskManagementPanel:(id)sender;
- (IBAction)showHardManagementPanel:(id)sender;
- (IBAction)showCassManagementPanel:(id)sender;
- (IBAction)errorOK:(id)sender;
- (IBAction)error2OK:(id)sender;
- (void) mediaStatusWindowShow:(id)sender;
- (NSPoint)mediaStatusOriginSave;
- (IBAction)cassPositionChange:(id)sender;
- (IBAction)diskDisplayChange:(id)sender;
- (IBAction)diskStatusChange:(id)sender;
- (IBAction)diskStatusProtect:(id)sender;
- (void) updateMediaStatusWindow;
- (void) statusLed:(int)diskNo:(int)on;
- (NSImageView *) getDiskImageView:(int)tag;
- (IBAction)coldStart:(id)sender;
- (IBAction)warmStart:(id)sender;
- (IBAction)changeGraphics:(id)sender;
- (IBAction)changeModel:(id)sender;
-(void)closeKeyWindow:(id)sender;
@end
