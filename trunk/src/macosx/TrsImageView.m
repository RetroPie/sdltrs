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

#import "TrsImageView.h"
#import "Preferences.h"
#import "MediaManager.h"
#import "trs_disk.h"
#import "trs_hard.h"

extern int showUpperDrives;

static NSImage *disketteImage;

/* Subclass of NSIMageView to allow for drag and drop and other specific functions  */

@implementation TrsImageView

/*------------------------------------------------------------------------------
*  init - Registers for a drag and drop to this window. 
*-----------------------------------------------------------------------------*/
-(id) init
{
	id me;
	char filename[FILENAME_MAX]; 

	
	me = [super init];
	
	[ self registerForDraggedTypes:[NSArray arrayWithObjects:
            NSFilenamesPboardType, nil]]; // Register for Drag and Drop
			
	disketteImage = [NSImage alloc];
	strcpy(filename, [Preferences getWorkingDirectory]);
    strcpy(filename, "sdltrs.app/Contents/Resources/diskette.bmp");    
	[disketteImage initWithContentsOfFile:[NSString stringWithCString:filename]];
	
	return(me);
}

/*------------------------------------------------------------------------------
*  mouseDown - Start a drag from one of the drives. 
*-----------------------------------------------------------------------------*/
- (void)mouseDown:(NSEvent *)theEvent
{
   int tag;
   NSImage *dragImage;
   NSPoint dragPosition;
   char *filename;
   
   tag = [self tag];

   if (tag < 4) {
		if (showUpperDrives == 1) {
            filename = trs_disk_getfilename(tag+4);
            }
        else if (showUpperDrives == 2) {
            filename = trs_hard_getfilename(tag);
            }
        else {
            filename = trs_disk_getfilename(tag);
            }

		if (filename[0] != 0) {
			// Write data to the pasteboard
			NSArray *fileList = [NSArray arrayWithObjects:[NSString stringWithCString:filename], nil];
			NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
			[pboard declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType]
				owner:nil];
			[pboard setPropertyList:fileList forType:NSFilenamesPboardType];

			// Start the drag operation
			dragImage = [[NSWorkspace sharedWorkspace] 
						iconForFile:[NSString stringWithCString:filename]];
			dragPosition = [self convertPoint:[theEvent locationInWindow]
							fromView:nil];
			dragPosition.x -= 16;
			dragPosition.y -= 16;
			[self dragImage:dragImage 
				at:dragPosition
				offset:NSZeroSize
				event:theEvent
				pasteboard:pboard
				source:self
				slideBack:YES];

			}
		}
}

/*------------------------------------------------------------------------------
*  draggingSourceOperationMaskForLocal - Only allow drags to other drives,
*     not to the finder or elsewhere. 
*-----------------------------------------------------------------------------*/
- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	if (isLocal)
		return NSDragOperationMove;
	else
		return NSDragOperationNone;
}

/*------------------------------------------------------------------------------
*  draggedImage - Runs when a image has been dropped on another disk instance. 
*-----------------------------------------------------------------------------*/
- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation
{
	int driveNo = [self tag];
	
	if (showUpperDrives == 1)
		driveNo += 4;
    else if (showUpperDrives == 2)
		driveNo += 8;

	if (operation == NSDragOperationMove)
		{
		[[MediaManager sharedInstance] diskRemoveKey:(driveNo)];
		}
}

/*------------------------------------------------------------------------------
*  draggingEntered - Checks for a valid drag and drop to this disk drive. 
*-----------------------------------------------------------------------------*/
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    int filecount;
    NSString *suffix;
    char *filename;

    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
    
    /* Check for filenames type drag */
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        /* Check for copy being valid */
        if (sourceDragMask & NSDragOperationCopy ||
		    sourceDragMask & NSDragOperationMove) {
            /* Check here for valid file types */
            NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
            
            filecount = [files count];
			
			if (filecount != 1)
				return NSDragOperationNone;
			
            suffix = [[files objectAtIndex:0] pathExtension];

			if ([self tag] < 4) {
                if (showUpperDrives == 1) {
                    filename = trs_disk_getfilename([self tag]+4);
                    }
                else if (showUpperDrives == 2) {
                    filename = trs_hard_getfilename([self tag]);
                    }
                else {
                    filename = trs_disk_getfilename([self tag]);
                    }
				if (([[files objectAtIndex:0] 
						isEqualToString:[NSString stringWithCString:filename]]))
					return NSDragOperationNone;
                }
			if ([self tag] == 8)
				if (!([suffix isEqualToString:@"cas"] ||
					[suffix isEqualToString:@"CAS"] ||
                    [suffix isEqualToString:@"cpt"] ||
					[suffix isEqualToString:@"CPT"] ||
                    [suffix isEqualToString:@"wav"] ||
					[suffix isEqualToString:@"WAV"]))
					return NSDragOperationNone;
            }
		if (sourceDragMask & NSDragOperationMove)
			return NSDragOperationMove; 
    }
    return NSDragOperationNone;
}

/*------------------------------------------------------------------------------
*  performDragOperation - Executes the actual drap and drop of a filename onto
*     a disk drive. 
*-----------------------------------------------------------------------------*/
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
	int driveNo;

    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];

    /* Check for filenames type drag */
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
       NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
       
       /* Load the first file into the emulator */
	   if ([self tag] < 4) {
			if (showUpperDrives == 1)
				driveNo = [self tag] + 4;
			else if (showUpperDrives == 2)
				driveNo = [self tag] + 8;
			else
				driveNo = [self tag];
				
			[[MediaManager sharedInstance] diskNoInsertFile:[files objectAtIndex:0]:driveNo];
			} 
	   else if ([self tag] == 8)
			[[MediaManager sharedInstance] cassInsertFile:[files objectAtIndex:0]]; 
    }
    return YES;
}

@end
