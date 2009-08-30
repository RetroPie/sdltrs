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
#import "SDL/SDL.h"
#import "ControlManager.h"
#import "MediaManager.h"
#import "Preferences.h"
#import "PrintOutputController.h"
#import "KeyMapper.h"
#import "trs.h"
#import "trs_disk.h"
#import "trs_hard.h"
#import "trs_cassette.h"
#import "trs_mkdisk.h"
#import "trs_mac_interface.h"
#import "trs_sdl_gui.h"

/* Definition of Mac native keycodes for characters used as menu shortcuts the 
	bring up a window. */
#define QZ_c			0x08
#define QZ_d			0x02
#define QZ_e			0x0E
#define QZ_o			0x1F
#define QZ_r			0x0F
#define QZ_1			0x12
#define QZ_n			0x2D
#define QZ_h			0x04

extern int fullscreen;
int mediaStatusWindowOpen = 1;
int showUpperDrives = 0;

/* Functions which provide an interface for C code to call this object's shared Instance functions */
void UpdateMediaManagerInfo() {
    [[MediaManager sharedInstance] updateInfo];
}

void MediaManagerRunDiskManagement() {
    [[MediaManager sharedInstance] showDiskManagementPanel:nil];
}

void MediaManagerRunHardManagement() {
    [[MediaManager sharedInstance] showHardManagementPanel:nil];
}

void MediaManagerRunCassManagement() {
    [[MediaManager sharedInstance] showCassManagementPanel:nil];
}

void MediaManagerInsertDisk(int diskNum) {
    [[MediaManager sharedInstance] diskInsertKey:diskNum];
}

void MediaManagerRemoveDisk(int diskNum) {
    if (diskNum == 0)
        [[MediaManager sharedInstance] diskRemoveAll:nil];
    else
        [[MediaManager sharedInstance] diskRemoveKey:diskNum];
}

void MediaManagerStatusLed(int diskNo, int on) {
    char *filename;
    
    if (diskNo >= 0 && diskNo < 8) { 
		[[MediaManager sharedInstance] statusLed:diskNo:on];
        }
            
    if (diskNo >= 8 && diskNo < 12) {
        filename = trs_hard_getfilename(diskNo-8); 
		if (filename[0] != 0)
			[[MediaManager sharedInstance] statusLed:diskNo:on];
        }
}

void MediaManagerStatusWindowShow(void) {
 [[MediaManager sharedInstance] mediaStatusWindowShow:nil];
}

@implementation MediaManager

static MediaManager *sharedInstance = nil;

static NSImage *closedFloppyImage;
static NSImage *writeFloppyImage;
static NSImage *writeEmptyFloppyImage;
static NSImage *emptyFloppyImage;
static NSImage *attachedHardImage;
static NSImage *emptyHardImage;
static NSImage *writeHardImage;
static NSImage *on410Image;
static NSImage *off410Image;
static NSImage *lockImage;
static NSImage *lockoffImage;
static NSImage *epsonImage;
static NSImage *textImage;
NSImage *disketteImage;

+ (MediaManager *)sharedInstance {
    return sharedInstance ? sharedInstance : [[self alloc] init];
}

- (id)init {
	char filename[FILENAME_MAX];
	
    if (sharedInstance) {
	[self dealloc];
    } else {
        [super init];
		[Preferences sharedInstance];
        sharedInstance = self;
        /* load the nib and all the windows */
        if (!d1DiskField) {
			if (![NSBundle loadNibNamed:@"MediaManager" owner:self])  {
				NSLog(@"Failed to load MediaManager.nib");
				NSBeep();
				return nil;
                }
            }
	[[diskFmtMatrix window] setExcludedFromWindowsMenu:YES];
	[[diskFmtMatrix window] setMenu:nil];
	[[d1DiskField window] setExcludedFromWindowsMenu:YES];
	[[d1DiskField window] setMenu:nil];
	[[hardFmtCylinderCountField window] setExcludedFromWindowsMenu:YES];
	[[hardFmtCylinderCountField window] setMenu:nil];
	[[h1DiskField window] setExcludedFromWindowsMenu:YES];
	[[h1DiskField window] setMenu:nil];
	[[cassFmtPulldown window] setExcludedFromWindowsMenu:YES];
	[[cassFmtPulldown window] setMenu:nil];
	[[cassetteField window] setExcludedFromWindowsMenu:YES];
	[[cassetteField window] setMenu:nil];
	[[errorButton window] setExcludedFromWindowsMenu:YES];
	[[errorButton window] setMenu:nil];
	[[d1DiskImageView window] setExcludedFromWindowsMenu:NO];
	
	emptyFloppyImage = [[NSImage alloc] retain];
    strcpy(filename, "sdltrs.app/Contents/Resources/floppyEmpty.tiff");    
	[emptyFloppyImage initWithContentsOfFile:[NSString stringWithCString:filename]];

	closedFloppyImage = [[NSImage alloc] retain];
    strcpy(filename, "sdltrs.app/Contents/Resources/floppyClosed.tiff");    
	[closedFloppyImage initWithContentsOfFile:[NSString stringWithCString:filename]];

	writeFloppyImage = [[NSImage alloc] retain];
    strcpy(filename, "sdltrs.app/Contents/Resources/floppyWrite.tiff");    
	[writeFloppyImage initWithContentsOfFile:[NSString stringWithCString:filename]];

	writeEmptyFloppyImage = [[NSImage alloc] retain];
    strcpy(filename, "sdltrs.app/Contents/Resources/floppyEmptyWrite.tiff");    
	[writeEmptyFloppyImage initWithContentsOfFile:[NSString stringWithCString:filename]];

	emptyHardImage = [[NSImage alloc] retain];
    strcpy(filename, "sdltrs.app/Contents/Resources/hardEmpty.tiff");    
	[emptyHardImage initWithContentsOfFile:[NSString stringWithCString:filename]];

	attachedHardImage = [[NSImage alloc] retain];
    strcpy(filename, "sdltrs.app/Contents/Resources/hardAttached.tiff");    
	[attachedHardImage initWithContentsOfFile:[NSString stringWithCString:filename]];

	writeHardImage = [[NSImage alloc] retain];
    strcpy(filename, "sdltrs.app/Contents/Resources/hardWrite.tiff");    
	[writeHardImage initWithContentsOfFile:[NSString stringWithCString:filename]];

	on410Image = [[NSImage alloc] retain];
    strcpy(filename, "sdltrs.app/Contents/Resources/cassetteon.tiff");    
	[on410Image initWithContentsOfFile:[NSString stringWithCString:filename]];
	
	off410Image = [[NSImage alloc] retain];
    strcpy(filename, "sdltrs.app/Contents/Resources/cassetteoff.tiff");    
	[off410Image initWithContentsOfFile:[NSString stringWithCString:filename]];
	
	lockImage = [[NSImage alloc] retain];
    strcpy(filename, "sdltrs.app/Contents/Resources/lock.tiff");    
	[lockImage initWithContentsOfFile:[NSString stringWithCString:filename]];
	
	lockoffImage = [[NSImage alloc] retain];
    strcpy(filename, "sdltrs.app/Contents/Resources/lockoff.tiff");    
	[lockoffImage initWithContentsOfFile:[NSString stringWithCString:filename]];
	
	epsonImage = [[NSImage alloc] retain];
    strcpy(filename, "sdltrs.app/Contents/Resources/epson.tiff");    
	[epsonImage initWithContentsOfFile:[NSString stringWithCString:filename]];
		
	textImage = [[NSImage alloc] retain];
    strcpy(filename, "sdltrs.app/Contents/Resources/text.tiff");    
	[textImage initWithContentsOfFile:[NSString stringWithCString:filename]];

	disketteImage = [NSImage alloc];
    strcpy(filename, "sdltrs.app/Contents/Resources/diskette.tiff");    
	[disketteImage initWithContentsOfFile:[NSString stringWithCString:filename]];				
	}
	
    return sharedInstance;
}

- (void)dealloc {
	[super dealloc];
}

- (void)pushUserEvent:(int)code:(void *)data
{
	SDL_Event theEvent;
    
    theEvent.type = SDL_USEREVENT;
    theEvent.user.code = code;
    theEvent.user.data1 = data;

	SDL_PushEvent(&theEvent);
}

/*------------------------------------------------------------------------------
*  mediaStatusWindowShow - This method makes the media status window visable
*-----------------------------------------------------------------------------*/
- (void)mediaStatusWindowShow:(id)sender
{
	static int firstTime = 1;

	if (firstTime && !fullscreen) {
		[[d1DiskImageView window] setFrameOrigin:[[Preferences sharedInstance] mediaStatusOrigin]];
		firstTime = 0;
		}
	
    [[d1DiskImageView window] makeKeyAndOrderFront:self];
	[[d1DiskImageView window] setTitle:@"TRS80 Media"];
	mediaStatusWindowOpen = TRUE;
}

/*------------------------------------------------------------------------------
*  mediaStatusOriginSave - This method saves the position of the media status
*    window
*-----------------------------------------------------------------------------*/
- (NSPoint)mediaStatusOriginSave
{
	NSRect frame;
	
	frame = [[d1DiskImageView window] frame];
	return(frame.origin);
}

/*------------------------------------------------------------------------------
*  displayError - This method displays an error dialog box with the passed in
*     error message.
*-----------------------------------------------------------------------------*/
- (void)displayError:(NSString *)errorMsg {
    [errorField setStringValue:errorMsg];
    [NSApp runModalForWindow:[errorButton window]];
}

/*------------------------------------------------------------------------------
*  displayError2 - This method displays an error dialog box with the passed in
*     error messages.
*-----------------------------------------------------------------------------*/
- (void)displayError2:(NSString *)errorMsg1:(NSString *)errorMsg2 {
    [error2Field1 setStringValue:errorMsg1];
    [error2Field2 setStringValue:errorMsg2];
    [NSApp runModalForWindow:[error2Button window]];
}

/*------------------------------------------------------------------------------
*  updateInfo - This method is used to update the disk management window GUI.
*-----------------------------------------------------------------------------*/
- (void)updateInfo {
    [self updateDiskInfo];
    [self updateHardInfo];
    [self updateCassInfo];
	[self updateMediaStatusWindow];
}

/*------------------------------------------------------------------------------
*  updateDiskInfo - This method is used to update the disk management window GUI.
*-----------------------------------------------------------------------------*/
- (void)updateDiskInfo {
    int i;
    int noDisks = TRUE;
    char *diskFilename;
    int diskStatus;

    for (i=0;i<8;i++) {
        diskFilename = trs_disk_getfilename(i);
        if (diskFilename[0] == 0)
            diskStatus = 0;
        else if (trs_disk_getwriteprotect(i))
            diskStatus = 1;
        else
            diskStatus = 2;
        
        switch(i) {
            case 0:
                [d1DiskField setStringValue:[NSString stringWithCString:diskFilename]];
                [d1DriveStatusPulldown selectItemAtIndex:diskStatus];
                if (diskStatus == 0)
                    [removeD1Item setTarget:nil];
                else {
                    [removeD1Item setTarget:self];
                    noDisks = FALSE;
                    }
                break;
            case 1:
                [d2DiskField setStringValue:[NSString stringWithCString:diskFilename]];
                [d2DriveStatusPulldown selectItemAtIndex:diskStatus];
                if (diskStatus == 0)
                    [removeD2Item setTarget:nil];
                else {
                    [removeD2Item setTarget:self];
                    noDisks = FALSE;
                    }
            case 2:
                [d3DiskField setStringValue:[NSString stringWithCString:diskFilename]];
                [d3DriveStatusPulldown selectItemAtIndex:diskStatus];
                if (diskStatus == 0)
                    [removeD3Item setTarget:nil];
                else {
                    [removeD3Item setTarget:self];
                    noDisks = FALSE;
                    }
                break;
            case 3:
                [d4DiskField setStringValue:[NSString stringWithCString:diskFilename]];
                [d4DriveStatusPulldown selectItemAtIndex:diskStatus];
                if (diskStatus == 0)
                    [removeD4Item setTarget:nil];
                else {
                    [removeD4Item setTarget:self];
                    noDisks = FALSE;
                    }
                break;
            case 4:
                [d5DiskField setStringValue:[NSString stringWithCString:diskFilename]];
                [d5DriveStatusPulldown selectItemAtIndex:diskStatus];
                if (diskStatus == 0)
                    [removeD5Item setTarget:nil];
                else {
                    [removeD5Item setTarget:self];
                    noDisks = FALSE;
                    }
                break;
            case 5:
                [d6DiskField setStringValue:[NSString stringWithCString:diskFilename]];
                [d6DriveStatusPulldown selectItemAtIndex:diskStatus];
                if (diskStatus == 0)
                    [removeD6Item setTarget:nil];
                else {
                    [removeD6Item setTarget:self];
                    noDisks = FALSE;
                    }
                break;
            case 6:
                [d7DiskField setStringValue:[NSString stringWithCString:diskFilename]];
                [d7DriveStatusPulldown selectItemAtIndex:diskStatus];
                if (diskStatus == 0)
                    [removeD7Item setTarget:nil];
                else {
                    [removeD7Item setTarget:self];
                    noDisks = FALSE;
                    }
                break;
            case 7:
                [d8DiskField setStringValue:[NSString stringWithCString:diskFilename]];
                [d8DriveStatusPulldown selectItemAtIndex:diskStatus];
                if (diskStatus == 0)
                    [removeD8Item setTarget:nil];
                else {
                    [removeD8Item setTarget:self];
                    noDisks = FALSE;
                    }
                break;
            }
        }
        if (noDisks) 
            [removeMenu setTarget:nil];
        else 
            [removeMenu setTarget:self];
}

/*------------------------------------------------------------------------------
*  updateHardInfo - This method is used to update the hard management window GUI.
*-----------------------------------------------------------------------------*/
- (void)updateHardInfo {
    int i;
    char *diskFilename;
    int diskStatus;

    for (i=0;i<4;i++) {
        diskFilename = trs_hard_getfilename(i);
        if (diskFilename[0] == 0)
            diskStatus = 0;
        else if (trs_hard_getwriteprotect(i))
            diskStatus = 1;
        else
            diskStatus = 2;
        
        switch(i) {
            case 0:
                [h1DiskField setStringValue:[NSString stringWithCString:diskFilename]];
                [h1DriveStatusPulldown selectItemAtIndex:diskStatus];
                break;
            case 1:
                [h2DiskField setStringValue:[NSString stringWithCString:diskFilename]];
                [h2DriveStatusPulldown selectItemAtIndex:diskStatus];
            case 2:
                [h3DiskField setStringValue:[NSString stringWithCString:diskFilename]];
                [h3DriveStatusPulldown selectItemAtIndex:diskStatus];
            case 3:
                [h4DiskField setStringValue:[NSString stringWithCString:diskFilename]];
                [h4DriveStatusPulldown selectItemAtIndex:diskStatus];
            }
        }
}

/*------------------------------------------------------------------------------
*  updateCassInfo - This method is used to update the cass management window GUI.
*-----------------------------------------------------------------------------*/
- (void)updateCassInfo {
    char *cassFilename;

    cassFilename = trs_cassette_getfilename();
    [cassetteField setStringValue:[NSString stringWithCString:cassFilename]];
    [cassetteCurrPosField setIntValue:trs_get_cassette_position()];
    [cassetteMaxPosField setIntValue:trs_get_cassette_length()];
    if (cassFilename[0] == 0) {
        [cassetteImageInsertButton1 setTitle:@"Insert"];
        [cassetteImageInsertButton2 setTitle:@"Insert"];
        }
    else {
        [cassetteImageInsertButton1 setTitle:@"Eject"];
        [cassetteImageInsertButton2 setTitle:@"Eject"];
        }
}

/*------------------------------------------------------------------------------
*  browseFileInDirectory - This allows the user to chose a file to read in from
*     the specified directory.
*-----------------------------------------------------------------------------*/
- (NSString *) browseFileInDirectory:(NSString *)directory {
    NSOpenPanel *openPanel = nil;

    openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    
    if ([openPanel runModalForDirectory:directory file:nil types:nil] == NSOKButton)
        return([[openPanel filenames] objectAtIndex:0]);
    else
        return nil;
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
*  cancelDisk - This method handles the cancel button from the disk image
*     creation window.
*-----------------------------------------------------------------------------*/
- (IBAction)cancelDisk:(id)sender
{
    [NSApp stopModal];
    [[diskFmtMatrix window] close];
}

/*------------------------------------------------------------------------------
*  cancelHard - This method handles the cancel button from the hard image
*     creation window.
*-----------------------------------------------------------------------------*/
- (IBAction)cancelHard:(id)sender
{
    [NSApp stopModal];
    [[hardFmtCylinderCountField window] close];
}

/*------------------------------------------------------------------------------
*  cancelDisk - This method handles the cancel button from the cassette image
*     creation window.
*-----------------------------------------------------------------------------*/
- (IBAction)cancelCass:(id)sender
{
    [NSApp stopModal];
    [[cassFmtPulldown window] close];
}

/*------------------------------------------------------------------------------
*  cassInsert - This method inserts a cassette image into the emulator
*-----------------------------------------------------------------------------*/
- (IBAction)cassInsert:(id)sender
{
    NSString *filename;
    char tapename[FILENAME_MAX+1];
    char browseDir[FILENAME_MAX];
    char *currTapename;
    
    currTapename = trs_cassette_getfilename();
    if (currTapename[0] != 0) {
       [self cassRemove:sender];
       return;
       }

    trs_pause_audio(1);
    trs_expand_dir(trs_cass_dir, browseDir);
    filename = [self browseFileTypeInDirectory:
                  [NSString stringWithCString:browseDir]:
                   [NSArray arrayWithObjects:@"cpt",@"CPT", @"cas",@"CAS",@"wav",@"wav",nil]];
    if (filename != nil) {
        [filename getCString:tapename];
        trs_cassette_insert(tapename);
        }
    trs_pause_audio(0);
    [self updateInfo];
}

/*------------------------------------------------------------------------------
*  cassInsertFile - This method inserts a cassette image into the emulator, 
*     given it's filename
*-----------------------------------------------------------------------------*/
- (void)cassInsertFile:(NSString *)filename
{
    char tapename[FILENAME_MAX+1];
    
    if (filename != nil) {
        [filename getCString:tapename];
        trs_cassette_insert(tapename);
        }
    [self updateInfo];
}

/*------------------------------------------------------------------------------
*  cassRemove - This method removes the inserted cassette.
*-----------------------------------------------------------------------------*/
- (IBAction)cassRemove:(id)sender
{
    trs_cassette_remove();
    [self updateInfo];
}

/*------------------------------------------------------------------------------
*  createHard - This method responds to the create hard button push in the hard
*     creation window, and actually creates the hard disk image.
*-----------------------------------------------------------------------------*/
- (IBAction)createHard:(id)sender
{
    int sector_count;
    int granularity;
    int cylinder_count;
    int dir_sector;
    int ret;
    NSString *filename;
    char cfilename[FILENAME_MAX];
    char browseDir[FILENAME_MAX];
    
    sector_count = [hardFmtSectorCountField intValue];
    cylinder_count = [hardFmtCylinderCountField intValue];
    granularity = [hardFmtGranularityField intValue];
    dir_sector = [hardFmtDirectorySectorField intValue];
    
    if (sector_count < granularity) {
        [self displayError:@"Sector Count must be >= Granularity"];
        }
    else if ((sector_count % granularity) != 0) {
        [self displayError:@"Sector Count must be multiple of Granularity"];
        }
    else if ((sector_count / granularity) > 32) {
        [self displayError:@"Sector Count / Granularity must be <= 32"];
        }
    else {
        trs_expand_dir(trs_hard_dir, browseDir);
        filename = [self saveFileInDirectory:[NSString stringWithCString:browseDir]:nil];
        if (filename != nil) {
            [filename getCString:cfilename];
            ret = trs_create_blank_hard(cfilename, cylinder_count, sector_count, 
                                     granularity, dir_sector);
            if (ret) { 
                [self displayError:@"Error creating Hard Disk Image"];
                }
            else if ([hardFmtInsertNewButton state] == NSOnState) {
                trs_hard_attach([hardFmtInsertDrivePulldown indexOfSelectedItem], cfilename);
                }
            [NSApp stopModal];
            [self updateInfo];
            [[hardFmtCylinderCountField window] close];
        }
    }
    
}
// fixme - need to handle enabling disabling option pulldowns based on type
/*------------------------------------------------------------------------------
*  createDisk - This method responds to the create disk button push in the disk
*     creation window, and actually creates the disk image.
*-----------------------------------------------------------------------------*/
- (IBAction)createDisk:(id)sender
{
    int num_sides;
    int density;
    int ignore;
    int eight;
    int image_type;
    int ret;
    NSString *filename;
    char cfilename[FILENAME_MAX];
    char browseDir[FILENAME_MAX];
    
    image_type = [[diskFmtMatrix selectedCell] tag];
    num_sides = [diskFmtDmkNumSidesPulldown indexOfSelectedItem];
    density = [diskFmtDmkDensityPulldown indexOfSelectedItem];
    eight = [diskFmtDmkPhysicalSizePulldown indexOfSelectedItem];
    ignore = [diskFmtDmkIgnoreDensityPulldown indexOfSelectedItem];
    
    trs_expand_dir(trs_disk_dir, browseDir);
    filename = [self saveFileInDirectory:[NSString stringWithCString:browseDir]:nil];
    if (filename != nil) {
        [filename getCString:cfilename];
         if (image_type == 0)
           ret = trs_create_blank_jv1(cfilename);
         else if (image_type == 1)
           ret = trs_create_blank_jv3(cfilename);
         else
           ret = trs_create_blank_dmk(cfilename, num_sides, density, eight, ignore);
        if (ret) { 
           [self displayError:@"Error creating Disk Image"];
           }
        else if ([diskFmtInsertNewButton state] == NSOnState) {
           trs_disk_insert([diskFmtInsertDrivePulldown indexOfSelectedItem], cfilename);
           }
        [NSApp stopModal];
        [self updateInfo];
        [[diskFmtMatrix window] close];
        }
    
}

/*------------------------------------------------------------------------------
*  createCassette - This method responds to the new cassette button in the 
*     media status window, or the new cassette menu item.
*-----------------------------------------------------------------------------*/
- (IBAction)createCassette:(id)sender
{
    FILE *image = NULL;
    NSString *filename;
    char cfilename[FILENAME_MAX];
    int image_type;
    int ret;
    char browseDir[FILENAME_MAX];
    
    image_type = [cassFmtPulldown indexOfSelectedItem];
    trs_expand_dir(trs_cass_dir, browseDir);
    
    if (image_type == 0) {
      filename = [self saveFileInDirectory:[NSString stringWithCString:browseDir]:@"cas"];
      if (filename != nil) {
        [filename getCString:cfilename];
        image = fopen(cfilename, "wb");
        if (image == NULL) {
            [self displayError:@"Unable to Create Cassette Image!"];
            return;
            }
        else {
            fclose(image);
            }
        }
    }
    else if (image_type == 1) {
      filename = [self saveFileInDirectory:[NSString stringWithCString:browseDir]:@"cpt"];
      if (filename != nil) {
        [filename getCString:cfilename];
        image = fopen(cfilename, "wb");
        if (image == NULL) {
            [self displayError:@"Unable to Create Cassette Image!"];
            return;
            }
        else {
            fclose(image);
            }
        }
    }
    else {
      filename = [self saveFileInDirectory:[NSString stringWithCString:browseDir]:@"wav"];
      if (filename != nil) {
        [filename getCString:cfilename];
        image = fopen(cfilename, "wb");
        if (image == NULL) {
            [self displayError:@"Unable to Create Cassette Image!"];
            return;
            }
        else {
            ret = create_wav_header(image);
            fclose(image);
            if (ret) {
                [self displayError:@"Unable to Create Cassette Image!"];
                return;
                }
            }
        }
    }
    if ([cassFmtInsertNewButton state] == NSOnState) {
        trs_cassette_insert(cfilename);
        [self updateInfo];
        }
    [NSApp stopModal];
    [[cassFmtInsertNewButton window] close];
}

/*------------------------------------------------------------------------------
*  diskInsert - This method inserts a floppy disk in the specified drive in
*     response to a menu.
*-----------------------------------------------------------------------------*/
- (IBAction)diskInsert:(id)sender
{
    int diskNum = [sender tag] - 1;
    NSString *filename;
    char cfilename[FILENAME_MAX];
    char browseDir[FILENAME_MAX];
    
    trs_pause_audio(1);
    
    trs_expand_dir(trs_disk_dir, browseDir);
    filename = [self browseFileInDirectory:
                [NSString stringWithCString:browseDir]];
    if (filename != nil) {
        [filename getCString:cfilename];
        if (diskNum < 8)
            trs_disk_insert(diskNum,cfilename);
        else
            trs_hard_attach(diskNum-8,cfilename);
        [self updateInfo];
        }
    trs_pause_audio(0);
}

/*------------------------------------------------------------------------------
*  diskInsertFile - This method inserts a floppy disk into drive 1, given its
*     filename.
*-----------------------------------------------------------------------------*/
- (void)diskInsertFile:(NSString *)filename
{
    char cfilename[FILENAME_MAX];
    
    if (filename != nil) {
        [filename getCString:cfilename];
        trs_disk_insert(0,cfilename);
        [self updateInfo];
        }
}

/*------------------------------------------------------------------------------
*  diskNoInsertFile - This method inserts a floppy disk into a drive, given its
*     filename and the drives number.
*-----------------------------------------------------------------------------*/
- (void)diskNoInsertFile:(NSString *)filename:(int) driveNo
{
    char cfilename[FILENAME_MAX];
    
    if (filename != nil) {
        [filename getCString:cfilename];
        if (driveNo < 8)
            trs_disk_insert(driveNo,cfilename);
        else
            trs_hard_attach(driveNo-8,cfilename);
        [self updateInfo];
        }
}

/*------------------------------------------------------------------------------
*  diskInsertKey - This method inserts a floppy disk in the specified drive in
*     response to a keyboard shortcut.
*-----------------------------------------------------------------------------*/
- (IBAction)diskInsertKey:(int)diskNum
{
    NSString *filename;
    char cfilename[FILENAME_MAX];
    char browseDir[FILENAME_MAX];
	static NSString *num[8] = {@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8"};
    
    trs_pause_audio(1);
    trs_expand_dir(trs_disk_dir, browseDir);
    filename = [self browseFileInDirectory:
                [NSString stringWithCString:browseDir]];
    if (filename != nil) {
        [filename getCString:cfilename];
        if (diskNum < 8)
            trs_disk_insert(diskNum,cfilename);
        else
            trs_hard_attach(diskNum-8,cfilename);
        [self updateInfo];
        }
    trs_pause_audio(0);
	if (diskNum<8)
		[[KeyMapper sharedInstance] releaseCmdKeys:num[diskNum]];
}

/*------------------------------------------------------------------------------
*  diskRemove - This method removes a floppy disk in the specified drive in
*     response to a menu.
*-----------------------------------------------------------------------------*/
- (IBAction)diskRemove:(id)sender
{
    int diskNum = [sender tag] - 1;

    if (diskNum < 8)
        trs_disk_remove(diskNum);
    else
        trs_hard_remove(diskNum-8);
    [self updateInfo];
}

/*------------------------------------------------------------------------------
*  diskRemoveKey - This method removes a floppy disk in the specified drive in
*     response to a keyboard shortcut.
*-----------------------------------------------------------------------------*/
- (IBAction)diskRemoveKey:(int)diskNum
{
    if (diskNum < 8)
        trs_disk_remove(diskNum);
    else
        trs_hard_remove(diskNum-8);
    [self updateInfo];
}

/*------------------------------------------------------------------------------
*  diskRemoveAll - This method removes disks from all of the floppy drives.
*-----------------------------------------------------------------------------*/
- (IBAction)diskRemoveAll:(id)sender
{
    int i;

    for (i=0;i<8;i++)
      trs_disk_remove(i);
    [self updateInfo];
}

/*------------------------------------------------------------------------------
*  hardRemoveAll - This method removes disks from all of the hard drives.
*-----------------------------------------------------------------------------*/
- (IBAction)hardRemoveAll:(id)sender
{
    int i;

    for (i=0;i<4;i++)
      trs_hard_remove(i);
    [self updateInfo];
}

/*------------------------------------------------------------------------------
*  Save - This method saves the names of the mounted disks to a file
*      chosen by the user.
*-----------------------------------------------------------------------------*/
- (IBAction)diskSetSave:(id)sender
{
    NSString *filename;
    char cfilename[FILENAME_MAX+1];
    char browseDir[FILENAME_MAX];

    trs_pause_audio(1);
    trs_expand_dir(trs_disk_set_dir, browseDir);
    filename = [self saveFileInDirectory:[NSString stringWithCString:browseDir]:@"set"];
    
    if (filename == nil) {
        trs_pause_audio(0);
        return;
        }
                    
    [filename getCString:cfilename];

    trs_diskset_save(cfilename);
    trs_pause_audio(0);
}

/*------------------------------------------------------------------------------
*  diskSetLoad - This method mounts the set of disk images from a file
*      chosen by the user.
*-----------------------------------------------------------------------------*/
- (IBAction)diskSetLoad:(id)sender
{
    NSString *filename;
    char cfilename[FILENAME_MAX+1];
    char browseDir[FILENAME_MAX];

    trs_pause_audio(1);
    trs_expand_dir(trs_disk_set_dir, browseDir);
    filename = [self browseFileTypeInDirectory:
                  [NSString stringWithCString:browseDir]:[NSArray arrayWithObjects:@"set",@"SET", nil]];
    
    if (filename == nil) {
        trs_pause_audio(0);
        return;
        }
    
    [filename getCString:cfilename];
    trs_diskset_load(cfilename);
    [self updateInfo];
    trs_pause_audio(0);
}

/*------------------------------------------------------------------------------
*  diskSetLoad - This method mounts the set of disk images from a file
*      specified by the filename parameter.
*-----------------------------------------------------------------------------*/
- (IBAction)diskSetLoadFile:(NSString *)filename
{
    char cfilename[FILENAME_MAX+1];
    
    [filename getCString:cfilename];
    trs_diskset_load(cfilename);
    [self updateInfo];
}

/*------------------------------------------------------------------------------
*  driveStatusChange - This method handles changes in the drive status controls 
*     in the disk management window.
*-----------------------------------------------------------------------------*/
- (IBAction)driveStatusChange:(id)sender
{
    int diskNum = [sender tag] - 1;
    
    switch([sender indexOfSelectedItem]) {
        case 0:
            trs_disk_remove(diskNum);
            break;
        case 1:
            if (trs_disk_getwriteprotect(diskNum) == 0)
                trs_protect_disk(diskNum, 1);
            break;
        case 2:
            if (trs_disk_getwriteprotect(diskNum) == 1)
                trs_protect_disk(diskNum, 0);
            break;
        }
    [self updateInfo];
}

/*------------------------------------------------------------------------------
*  hardStatusChange - This method handles changes in the drive status controls 
*     in the disk management window.
*-----------------------------------------------------------------------------*/
- (IBAction)hardStatusChange:(id)sender
{
    int diskNum = [sender tag] - 1;
    
    switch([sender indexOfSelectedItem]) {
        case 0:
            trs_hard_remove(diskNum);
            break;
        case 1:
            if (trs_hard_getwriteprotect(diskNum) == 0)
                trs_protect_hard(diskNum, 1);
            break;
        case 2:
            if (trs_hard_getwriteprotect(diskNum) == 1)
                trs_protect_hard(diskNum, 0);
            break;
        }
    [self updateInfo];
}

/*------------------------------------------------------------------------------
*  diskMiscUpdate - This method handles control updates in the disk image creation
*     window.
*-----------------------------------------------------------------------------*/
- (IBAction)diskMiscUpdate:(id)sender
{
    if (sender == diskFmtMatrix) {
        switch([[diskFmtMatrix selectedCell] tag]) {
            case 0:
                [diskFmtDmkNumSidesPulldown setEnabled:NO];
                [diskFmtDmkDensityPulldown setEnabled:NO];
                [diskFmtDmkPhysicalSizePulldown setEnabled:NO];
                [diskFmtDmkIgnoreDensityPulldown setEnabled:NO];
                break;
            case 1:
                [diskFmtDmkNumSidesPulldown setEnabled:NO];
                [diskFmtDmkDensityPulldown setEnabled:NO];
                [diskFmtDmkPhysicalSizePulldown setEnabled:NO];
                [diskFmtDmkIgnoreDensityPulldown setEnabled:NO];
                break;
            case 2:
                [diskFmtDmkNumSidesPulldown setEnabled:YES];
                [diskFmtDmkDensityPulldown setEnabled:YES];
                [diskFmtDmkPhysicalSizePulldown setEnabled:YES];
                [diskFmtDmkIgnoreDensityPulldown setEnabled:YES];
                break;
            }
        }
    else if (sender == diskFmtInsertNewButton) {
        if ([diskFmtInsertNewButton state] == NSOnState)
            [diskFmtInsertDrivePulldown setEnabled:YES];
        else
            [diskFmtInsertDrivePulldown setEnabled:NO];        
        }
}

/*------------------------------------------------------------------------------
*  hardMiscUpdate - This method handles control updates in the disk image creation
*     window.
*-----------------------------------------------------------------------------*/
- (IBAction)hardMiscUpdate:(id)sender
{
    if (sender == hardFmtInsertNewButton) {
        if ([hardFmtInsertNewButton state] == NSOnState)
            [hardFmtInsertDrivePulldown setEnabled:YES];
        else
            [hardFmtInsertDrivePulldown setEnabled:NO];        
        }
}

/*------------------------------------------------------------------------------
*  okDisk - This method handles the OK button press from the disk managment window.
*-----------------------------------------------------------------------------*/
- (IBAction)okDisk:(id)sender
{
    [NSApp stopModal];
    [[d1DiskField window] close];
    trs_pause_audio(0);
}

/*------------------------------------------------------------------------------
*  okHard - This method handles the OK button press from the hard managment window.
*-----------------------------------------------------------------------------*/
- (IBAction)okHard:(id)sender
{
    [NSApp stopModal];
    [[h1DiskField window] close];
    trs_pause_audio(0);
}

/*------------------------------------------------------------------------------
*  okHard - This method handles the OK button press from the hard managment window.
*-----------------------------------------------------------------------------*/
- (IBAction)okCass:(id)sender
{
    [NSApp stopModal];
    [[cassetteField window] close];
    trs_pause_audio(0);
}

/*------------------------------------------------------------------------------
*  errorOK - This method handles the OK button press from the error window.
*-----------------------------------------------------------------------------*/
- (IBAction)errorOK:(id)sender;
{
    [NSApp stopModal];
    [[errorButton window] close];
}

/*------------------------------------------------------------------------------
*  error2OK - This method handles the OK button press from the error2 window.
*-----------------------------------------------------------------------------*/
- (IBAction)error2OK:(id)sender;
{
    [NSApp stopModal];
    [[error2Button window] close];
}

/*------------------------------------------------------------------------------
*  showDiskCreatePanel - This method displays a window which allows the creation of
*     blank floppy images.
*-----------------------------------------------------------------------------*/
- (IBAction)showDiskCreatePanel:(id)sender
{
	int driveNo;
    char *diskname;
	
	for (driveNo=0;driveNo<8;driveNo++) {
        diskname = trs_disk_getfilename(driveNo);
		if (diskname[0] == 0) 
			break;
		}
	if (driveNo == 8)
		driveNo = 0;
    [diskFmtInsertDrivePulldown selectItemAtIndex:driveNo];
    [diskFmtInsertDrivePulldown setEnabled:NO];
    [diskFmtInsertNewButton setState:NSOffState];
    [NSApp runModalForWindow:[diskFmtInsertNewButton window]];
    [[KeyMapper sharedInstance] releaseCmdKeys:@"n"];
}

/*------------------------------------------------------------------------------
*  showHardCreatePanel - This method displays a window which allows the creation of
*     blank floppy images.
*-----------------------------------------------------------------------------*/
- (IBAction)showHardCreatePanel:(id)sender
{
	int driveNo;
    char *diskname;
	
	for (driveNo=0;driveNo<4;driveNo++) {
        diskname = trs_hard_getfilename(driveNo);
		if (diskname[0] == 0) 
			break;
		}
	if (driveNo == 4)
		driveNo = 0;
    [hardFmtInsertDrivePulldown selectItemAtIndex:driveNo];
    [hardFmtInsertDrivePulldown setEnabled:NO];
    [hardFmtInsertNewButton setState:NSOffState];
    [NSApp runModalForWindow:[hardFmtInsertNewButton window]];
    [[KeyMapper sharedInstance] releaseCmdKeys:@"b"];
}

/*------------------------------------------------------------------------------
*  showCassCreatePanel - This method displays a window which allows the creation of
*     blank floppy images.
*-----------------------------------------------------------------------------*/
- (IBAction)showCassCreatePanel:(id)sender
{
    [cassFmtInsertNewButton setState:NSOffState];
    [NSApp runModalForWindow:[cassFmtInsertNewButton window]];
}

/*------------------------------------------------------------------------------
*  showDiskManagementPanel - This method displays the disk management window for
*     managing the Atari floppy drives.
*-----------------------------------------------------------------------------*/
- (IBAction)showDiskManagementPanel:(id)sender
{
    [self updateInfo];
    trs_pause_audio(1);
    [NSApp runModalForWindow:[d1DiskField window]];
    [[KeyMapper sharedInstance] releaseCmdKeys:@"d"];
}

/*------------------------------------------------------------------------------
*  showHardManagementPanel - This method displays the disk management window for
*     managing the Atari floppy drives.
*-----------------------------------------------------------------------------*/
- (IBAction)showHardManagementPanel:(id)sender
{
    [self updateInfo];
    trs_pause_audio(1);
    [NSApp runModalForWindow:[h1DiskField window]];
    [[KeyMapper sharedInstance] releaseCmdKeys:@"h"];
}

/*------------------------------------------------------------------------------
*  showCassManagementPanel - This method displays the disk management window for
*     managing the Atari floppy drives.
*-----------------------------------------------------------------------------*/
- (IBAction)showCassManagementPanel:(id)sender
{
    [self updateInfo];
    [self updateCassInfo];
    trs_pause_audio(1);
    [NSApp runModalForWindow:[cassetteField window]];
}

/*------------------------------------------------------------------------------
*  diskStatusChange - This is called when a drive Insert/Eject is pressed.
*-----------------------------------------------------------------------------*/
- (IBAction)diskStatusChange:(id)sender
{
    char *filename;
	int driveNo = [sender tag];
	
	if (showUpperDrives==1)
		driveNo += 4;
	else if (showUpperDrives==2)
		driveNo += 8;
	
    if (driveNo < 8) 
        filename = trs_disk_getfilename(driveNo);
    else
        filename = trs_hard_getfilename(driveNo-8);

	if (filename[0] == 0) {
		[self diskInsertKey:(driveNo)];
		}
	else {
		[self diskRemoveKey:(driveNo)];
		}
}

/*------------------------------------------------------------------------------
*  diskDisplayChange - This is called when the 1-4 or 5-8 buttons are pressed.
*-----------------------------------------------------------------------------*/
- (IBAction)diskDisplayChange:(id)sender
{
	showUpperDrives = [[driveSelectMatrix selectedCell] tag];
	[self updateInfo];
}

/*------------------------------------------------------------------------------
*  diskStatusProtect - This is called when a drive Lock/Unlock is pressed.
*-----------------------------------------------------------------------------*/
- (IBAction)diskStatusProtect:(id)sender
{
	int driveNo = [sender tag];
	
	if (showUpperDrives == 1)
		driveNo += 4;
	else if (showUpperDrives==2)
		driveNo += 8;

    if (driveNo < 8) {
        if (trs_disk_getwriteprotect(driveNo) == 0)
            trs_protect_disk(driveNo, 1);
        else
            trs_protect_disk(driveNo, 0);
        }
    else {
        if (trs_hard_getwriteprotect(driveNo-8) == 0)
            trs_protect_hard(driveNo-8, 1);
        else
            trs_protect_hard(driveNo-8, 0);
        }
	[self updateInfo];
}

/*------------------------------------------------------------------------------
*  updateMediaStatusWindow - Update the media status window when something
*      changes.
*-----------------------------------------------------------------------------*/
- (void) updateMediaStatusWindow
{
	char *ptr;
	int driveOffset;
    char *filename1, *filename2, *filename3, *filename4, *cassette_filename;
    int writeprot1, writeprot2, writeprot3, writeprot4;

    cassette_filename = trs_cassette_getfilename();

	[selectPrinterPulldown setEnabled:YES];
	switch(trs_printer)
		{
		case NO_PRINTER:
			[printerImageNameField setStringValue:@"No Printer"];
            [printerImageView setImage:nil];
			[printerPreviewItem setTarget:nil];
			[printerPreviewButton setEnabled:NO];
			[resetPrinterItem setTarget:nil];
			[resetPrinterMenuItem setTarget:nil];
			break;
		case TEXT_PRINTER:
			[printerImageNameField setStringValue:@"Text"];
			[printerImageView setImage:textImage];
			[printerPreviewItem setTarget:nil];
			[printerPreviewButton setEnabled:NO];
			[resetPrinterItem setTarget:[PrintOutputController sharedInstance]];
			[resetPrinterMenuItem setTarget:[PrintOutputController sharedInstance]];
			break;
		case EPSON_PRINTER:
			[printerImageNameField setStringValue:@"Epson FX80"];
			[printerImageView setImage:epsonImage];
			[printerPreviewItem setTarget:[PrintOutputController sharedInstance]];
			[printerPreviewButton setEnabled:YES];
			[resetPrinterItem setTarget:[PrintOutputController sharedInstance]];
			[resetPrinterMenuItem setTarget:[PrintOutputController sharedInstance]];
			break;
		}

	
	if (showUpperDrives==1) { 
	    driveOffset = 4;
		[d1DiskImageNumberField setStringValue:@"5"];
		[d2DiskImageNumberField setStringValue:@"6"];
		[d3DiskImageNumberField setStringValue:@"7"];
		[d4DiskImageNumberField setStringValue:@"8"];
        filename1 = trs_disk_getfilename(4);
        filename2 = trs_disk_getfilename(5);
        filename3 = trs_disk_getfilename(6);
        filename4 = trs_disk_getfilename(7);
        writeprot1 = trs_disk_getwriteprotect(4);
        writeprot2 = trs_disk_getwriteprotect(5);
        writeprot3 = trs_disk_getwriteprotect(6);
        writeprot4 = trs_disk_getwriteprotect(7);
		}
	else if (showUpperDrives==2) { 
	    driveOffset = 8;
		[d1DiskImageNumberField setStringValue:@"H1"];
		[d2DiskImageNumberField setStringValue:@"H2"];
		[d3DiskImageNumberField setStringValue:@"H3"];
		[d4DiskImageNumberField setStringValue:@"H4"];
        filename1 = trs_hard_getfilename(0);
        filename2 = trs_hard_getfilename(1);
        filename3 = trs_hard_getfilename(2);
        filename4 = trs_hard_getfilename(3);
        writeprot1 = trs_hard_getwriteprotect(0);
        writeprot2 = trs_hard_getwriteprotect(1);
        writeprot3 = trs_hard_getwriteprotect(2);
        writeprot4 = trs_hard_getwriteprotect(3);
		}
	else {
	    driveOffset = 0;
		[d1DiskImageNumberField setStringValue:@"1"];
		[d2DiskImageNumberField setStringValue:@"2"];
		[d3DiskImageNumberField setStringValue:@"3"];
		[d4DiskImageNumberField setStringValue:@"4"];
        filename1 = trs_disk_getfilename(0);
        filename2 = trs_disk_getfilename(1);
        filename3 = trs_disk_getfilename(2);
        filename4 = trs_disk_getfilename(3);
        writeprot1 = trs_disk_getwriteprotect(0);
        writeprot2 = trs_disk_getwriteprotect(1);
        writeprot3 = trs_disk_getwriteprotect(2);
        writeprot4 = trs_disk_getwriteprotect(3);
		}
	
	if (filename1[0] == 0) {
        [d1DiskImageNameField setStringValue:@"Empty"];
		[d1DiskImageInsertButton setTitle:@"Insert"];
		[d1DiskImageInsertButton setEnabled:YES];
		[d1DiskImageProtectButton setTitle:@"Lock"];
		[d1DiskImageProtectButton setEnabled:NO];
		if (showUpperDrives==2)
			[d1DiskImageView setImage:emptyHardImage];
		else
			[d1DiskImageView setImage:emptyFloppyImage];
		[d1DiskImageLockView setImage:lockoffImage];
        }
    else {
		ptr = filename1 + strlen(filename1) - 1;
		while (ptr > filename1) {
			if (*ptr == '/') {
				ptr++;
				break;
				}
			ptr--;
			}
		[d1DiskImageNameField setStringValue:[NSString stringWithCString:ptr]];
		[d1DiskImageInsertButton setTitle:@"Eject"];
		[d1DiskImageInsertButton setEnabled:YES];
		if (!writeprot1) {
			[d1DiskImageProtectButton setTitle:@"Lock"];
			[d1DiskImageLockView setImage:lockoffImage];
			}
		else {
			[d1DiskImageProtectButton setTitle:@"Unlk"];
			[d1DiskImageLockView setImage:lockImage];
			}
		[d1DiskImageProtectButton setEnabled:YES];
		if (showUpperDrives==2)
			[d1DiskImageView setImage:attachedHardImage];
		else
			[d1DiskImageView setImage:closedFloppyImage];
		}
	if (filename2[0] == 0) {
        [d2DiskImageNameField setStringValue:@"Empty"];
		[d2DiskImageInsertButton setTitle:@"Insert"];
		[d2DiskImageInsertButton setEnabled:YES];
		[d2DiskImageProtectButton setTitle:@"Lock"];
		[d2DiskImageProtectButton setEnabled:NO];
		if (showUpperDrives==2)
			[d2DiskImageView setImage:emptyHardImage];
		else
			[d2DiskImageView setImage:emptyFloppyImage];
		[d2DiskImageLockView setImage:lockoffImage];
        }
    else {
		ptr = filename2 + strlen(filename2) - 1;
		while (ptr > filename2) {
			if (*ptr == '/') {
				ptr++;
				break;
				}
			ptr--;
			}
		[d2DiskImageNameField setStringValue:[NSString stringWithCString:ptr]];
		[d2DiskImageInsertButton setTitle:@"Eject"];
		[d2DiskImageInsertButton setEnabled:YES];
		if (!writeprot2) {
			[d2DiskImageProtectButton setTitle:@"Lock"];
			[d2DiskImageLockView setImage:lockoffImage];
			}
		else {
			[d2DiskImageProtectButton setTitle:@"Unlk"];
			[d2DiskImageLockView setImage:lockImage];
			}
		[d2DiskImageProtectButton setEnabled:YES];
		if (showUpperDrives==2)
			[d2DiskImageView setImage:attachedHardImage];
		else
			[d2DiskImageView setImage:closedFloppyImage];
		}
	if (filename3[0] == 0) {
        [d3DiskImageNameField setStringValue:@"Empty"];
		[d3DiskImageInsertButton setTitle:@"Insert"];
		[d3DiskImageInsertButton setEnabled:YES];
		[d3DiskImageProtectButton setTitle:@"Lock"];
		[d3DiskImageProtectButton setEnabled:NO];
		if (showUpperDrives==2)
			[d3DiskImageView setImage:emptyHardImage];
		else
			[d3DiskImageView setImage:emptyFloppyImage];
		[d3DiskImageLockView setImage:lockoffImage];
        }
    else {
		ptr = filename3 + strlen(filename3) - 1;
		while (ptr > filename3) {
			if (*ptr == '/') {
				ptr++;
				break;
				}
			ptr--;
			}
		[d3DiskImageNameField setStringValue:[NSString stringWithCString:ptr]];
		[d3DiskImageInsertButton setTitle:@"Eject"];
		[d3DiskImageInsertButton setEnabled:YES];
		if (!writeprot3) {
			[d3DiskImageProtectButton setTitle:@"Lock"];
			[d3DiskImageLockView setImage:lockoffImage];
			}
		else {
			[d3DiskImageProtectButton setTitle:@"Unlk"];
			[d3DiskImageLockView setImage:lockImage];
			}
		[d3DiskImageProtectButton setEnabled:YES];
		if (showUpperDrives==2)
			[d3DiskImageView setImage:attachedHardImage];
		else
			[d3DiskImageView setImage:closedFloppyImage];
		}
	if (filename4[0] == 0) {
        [d4DiskImageNameField setStringValue:@"Empty"];
		[d4DiskImageInsertButton setTitle:@"Insert"];
		[d4DiskImageInsertButton setEnabled:YES];
		[d4DiskImageProtectButton setTitle:@"Lock"];
		[d4DiskImageProtectButton setEnabled:NO];
		if (showUpperDrives==2)
			[d4DiskImageView setImage:emptyHardImage];
		else
			[d4DiskImageView setImage:emptyFloppyImage];
		[d4DiskImageLockView setImage:lockoffImage];
        }
    else {
		ptr = filename4 + strlen(filename4) - 1;
		while (ptr > filename4) {
			if (*ptr == '/') {
				ptr++;
				break;
				}
			ptr--;
			}
		[d4DiskImageNameField setStringValue:[NSString stringWithCString:ptr]];
		[d4DiskImageInsertButton setTitle:@"Eject"];
		[d4DiskImageInsertButton setEnabled:YES];
		if (!writeprot4) {
			[d4DiskImageProtectButton setTitle:@"Lock"];
			[d4DiskImageLockView setImage:lockoffImage];
			}
		else {
			[d4DiskImageProtectButton setTitle:@"Unlk"];
			[d4DiskImageLockView setImage:lockImage];
			}
		[d4DiskImageProtectButton setEnabled:YES];
		if (showUpperDrives==2)
			[d4DiskImageView setImage:attachedHardImage];
		else
			[d4DiskImageView setImage:closedFloppyImage];
		}

    if (cassette_filename[0] == 0) {
		[cassImageNameField setStringValue:@"Empty"];
		[cassImageView setImage:off410Image];
		}
	else {
		ptr = cassette_filename + strlen(cassette_filename) - 1;
		while (ptr > cassette_filename) {
			if (*ptr == '/') {
				ptr++;
				break;
				}
			ptr--;
			}
		[cassImageNameField setStringValue:[NSString stringWithCString:ptr]];
		[cassImageView setImage:on410Image];
		}
        
    if (trs_model == 1)
       [modelPulldown selectItemAtIndex:0];
    else if (trs_model == 5)
       [modelPulldown selectItemAtIndex:3];
    else 
       [modelPulldown selectItemAtIndex:trs_model - 2];

    [graphicsPulldown selectItemAtIndex:grafyx_get_microlabs()];
}

/*------------------------------------------------------------------------------
*  statusLed - Turn the status LED on or off on a drive
*-----------------------------------------------------------------------------*/
- (void) statusLed:(int)diskNo:(int)on
{
    int diskIndex = diskNo;
	char *filename;
	int diskEmpty = TRUE;;

	if (showUpperDrives == 2) {
		if (diskNo < 8)
			return;
		diskIndex = diskNo - 8;
		}
	else if (showUpperDrives == 1) {
		if ((diskNo < 4) || (diskNo >= 8))
			return;
		filename = trs_disk_getfilename(diskNo);
		diskEmpty =  (filename[0] == 0);
		diskIndex = diskNo - 4;
		}
	else {
		if (diskNo > 3)
			return;
		filename = trs_disk_getfilename(diskNo);
		diskEmpty =  (filename[0] == 0);
		diskIndex = diskNo;
		}

	if (on) {
	    switch(diskIndex) {
			case 0:
				if (showUpperDrives==2) 
					[d1DiskImageView setImage:writeHardImage];
				else if (diskEmpty)
					[d1DiskImageView setImage:writeEmptyFloppyImage];
				else
					[d1DiskImageView setImage:writeFloppyImage];
				break;
			case 1:
				if (showUpperDrives==2) 
					[d2DiskImageView setImage:writeHardImage];
				else if (diskEmpty)
					[d2DiskImageView setImage:writeEmptyFloppyImage];
				else
					[d2DiskImageView setImage:writeFloppyImage];
				break;
			case 2:
				if (showUpperDrives==2) 
					[d3DiskImageView setImage:writeHardImage];
				else if (diskEmpty)
					[d3DiskImageView setImage:writeEmptyFloppyImage];
				else
					[d3DiskImageView setImage:writeFloppyImage];
				break;
			case 3:
				if (showUpperDrives==2) 
					[d4DiskImageView setImage:writeHardImage];
				else if (diskEmpty)
					[d4DiskImageView setImage:writeEmptyFloppyImage];
				else
					[d4DiskImageView setImage:writeFloppyImage];
				break;
			}
		}
	else {
	    switch(diskIndex) {
			case 0:
				if (showUpperDrives==2) 
					[d1DiskImageView setImage:attachedHardImage];
				else if (diskEmpty)
					[d1DiskImageView setImage:emptyFloppyImage];
				else
					[d1DiskImageView setImage:closedFloppyImage];
				break;
			case 1:
				if (showUpperDrives==2) 
					[d2DiskImageView setImage:attachedHardImage];
				else if (diskEmpty)
					[d2DiskImageView setImage:emptyFloppyImage];
				else
					[d2DiskImageView setImage:closedFloppyImage];
				break;
			case 2:
				if (showUpperDrives==2) 
					[d3DiskImageView setImage:attachedHardImage];
				else if (diskEmpty)
					[d3DiskImageView setImage:emptyFloppyImage];
				else
					[d3DiskImageView setImage:closedFloppyImage];
				break;
			case 3:
				if (showUpperDrives==2) 
					[d4DiskImageView setImage:attachedHardImage];
				else if (diskEmpty)
					[d4DiskImageView setImage:emptyFloppyImage];
				else
					[d4DiskImageView setImage:closedFloppyImage];
				break;
			}
		}
}

/*------------------------------------------------------------------------------
*  getDiskImageView - Return the image view for a particular drive.
*-----------------------------------------------------------------------------*/
- (NSImageView *) getDiskImageView:(int)tag
{
	switch(tag)
	{
		case 0:
		default:
			return(d1DiskImageView);
		case 1:
			return(d2DiskImageView);
		case 2:
			return(d3DiskImageView);
		case 3:
			return(d4DiskImageView);
	}
}

/*------------------------------------------------------------------------------
*  cassPositionChange - Called when the cassette position field in the
*   cassette management window is done editing.
*-----------------------------------------------------------------------------*/
- (IBAction)cassPositionChange:(id)sender
{
    int newPosition = [cassetteCurrPosField intValue];
    
    if (newPosition >= 0 && newPosition <= trs_get_cassette_length())
        trs_set_cassette_position(newPosition);
    [self updateCassInfo];
}

/*------------------------------------------------------------------------------
*  coldStart - Called when the cold start button in the media status window
*   is pressed.
*-----------------------------------------------------------------------------*/
- (IBAction)coldStart:(id)sender
{
	[[ControlManager sharedInstance] coldReset:sender];
}

/*------------------------------------------------------------------------------
*  warmStart - Called when the warm start button in the media status window
*   is pressed.
*-----------------------------------------------------------------------------*/
- (IBAction)warmStart:(id)sender;
{
	[[ControlManager sharedInstance] warmReset:sender];
}

/*------------------------------------------------------------------------------
*  changeModel - Called when the model pulldown in the media status window
*   is pressed.
*-----------------------------------------------------------------------------*/
- (IBAction)changeModel:(id)sender;
{
    [self pushUserEvent:MAC_CHANGE_MODEL_EVENT:(void*)[sender indexOfSelectedItem]];
}

/*------------------------------------------------------------------------------
*  changeGraphics - Called when the graphics pulldown in the media status window
*   is pressed.
*-----------------------------------------------------------------------------*/
- (IBAction)changeGraphics:(id)sender;
{
    [self pushUserEvent:MAC_CHANGE_GRAPHICS_EVENT:(void*)[sender indexOfSelectedItem]];
}

/*------------------------------------------------------------------------------
*  closeKeyWindow - Called to close the front window in the application.  
*      Placed in this class for lack of a better place. :)
*-----------------------------------------------------------------------------*/
-(void)closeKeyWindow:(id)sender
{
	[[NSApp keyWindow] performClose:NSApp];
}


@end
