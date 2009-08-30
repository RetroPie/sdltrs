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

#import "PrintableGraphics.h"

@implementation PrintableGraphics

- (id)initWithBytes:(const void *)bytes length:(unsigned)length width:(float)width height:(float) height bits:(unsigned)bits
{
	graphLength = length;
	graphBytes = (unsigned char *) NSZoneMalloc(NSDefaultMallocZone(), length);
	bcopy(bytes, graphBytes, length);
	pixelWidth = width;
	pixelHeight = height;
	columnBits = bits;
	return(self);
}

- (void)dealloc
{
	NSZoneFree(NSDefaultMallocZone(), graphBytes);
	[super dealloc];
}

-(void) setLocation:(NSPoint)location
{
   printLocation = location;
}

-(void)print:(NSRect)rect:(float)offset
{
	NSRect r;
	unsigned length = graphLength;
	unsigned i,j;
	unsigned char *bytes = (unsigned char *) graphBytes;
	static unsigned char mask[8] = {128,64,32,16,8,4,2,1};
	
	if ((printLocation.y < rect.origin.y-12.0) ||
		(printLocation.y > (rect.origin.y + rect.size.height +12.0)))
		return;
	
	r.origin.x = printLocation.x;
	r.size.width = pixelWidth;
	r.size.height = pixelHeight;
    NSColor *color = [NSColor blackColor];
	[color set];
	
	if (columnBits>8)
		length /= 2;

	for (i=0;i<length;i++)
		{
		r.origin.y = printLocation.y;
		for (j=0;j<8;j++)
			{
			if (*bytes & mask[j])
				NSRectFill(r);
			r.origin.y += pixelHeight;
			}
		if (columnBits > 8)
			{
			bytes++;
			if (*bytes & 128)
				NSRectFill(r);
			}
		r.origin.x += pixelWidth;
		bytes++;
		}
}

-(float)getYLocation
{
	return printLocation.y;
}

-(float)getMinYLocation
{
	return printLocation.y;
}

@end
