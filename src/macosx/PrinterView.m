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

#import "PrintableString.h"
#import "PrinterView.h"


@implementation PrinterView

- (id)initWithFrame:(NSRect)frame:(PrintOutputController *)owner:(float)pageLen:(float)vert {
    self = [super initWithFrame:frame];
    if (self) {
	    controller = owner;
		pageLength = pageLen;
		vertPosition = vert;
    }
    return self;
}

- (void)updateVerticlePosition:(float)vert
{
	vertPosition = vert;
}

- (void)drawRect:(NSRect)rect {
	int i;
	NSArray *array = [controller getPrintArray];
	int count = [array count];
	PrintableString *element;
    NSBezierPath *path;
	NSColor *purple = [NSColor purpleColor];
	NSColor *black = [NSColor blackColor];
	NSColor *grey = [NSColor grayColor];
	float offset = [controller getPrintOffset];
	
	// Draw each of the elements in the print array 
	[black set];
	for (i=0;i<count;i++)
		{
		element = [array objectAtIndex:i]; 
		[element print:rect:offset];
		}
	
	// If this is only the preview, then print the current line position
	//   and page break markers.
	if ([controller isPreview])
		{
		float width = [self frame].size.width;
		NSPoint point1 = NSMakePoint(0.0,vertPosition+offset-5.0);
		NSPoint point2 = NSMakePoint(10.0,vertPosition+offset);
		NSPoint point3 = NSMakePoint(0.0,vertPosition+offset+5.0);
		NSPoint point4 = NSMakePoint(width,vertPosition+offset-5.0);
		NSPoint point5 = NSMakePoint(width - 10.0,vertPosition+offset);
		NSPoint point6 = NSMakePoint(width,vertPosition+5.0+offset);
		float pageBreak;
		float array[2] = {5.0,2.0};
		
		// Print the current line position markers
		path = [NSBezierPath bezierPath];
		[path moveToPoint:point1];
		[path lineToPoint:point2];
		[path lineToPoint:point3];
		[path lineToPoint:point1];
	    [purple set];
		[path fill];
		path = [NSBezierPath bezierPath];
		[path moveToPoint:point4];
		[path lineToPoint:point5];
		[path lineToPoint:point6];
		[path lineToPoint:point4];
		[path fill];
		
		// Print the page break markers.
		[grey set];
		pageBreak = pageLength;
		do 	{
			NSPoint start = NSMakePoint(0.0, pageBreak);
			NSPoint end = NSMakePoint([self frame].size.width, pageBreak);
			path = [NSBezierPath bezierPath];
			[path setLineDash: array count: 2 phase: 0.0];
			[path moveToPoint:start];
			[path lineToPoint:end];
			[path stroke];
			pageBreak += pageLength;
			} while (pageBreak <= ([self frame].origin.y + [self frame].size.height));
		}
}

- (BOOL)isFlipped
{
	return YES;
}

@end
