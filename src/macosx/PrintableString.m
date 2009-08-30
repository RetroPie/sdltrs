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

@implementation PrintableString
-(id)init
{
	return [self initWithAttributedSting:nil];
}

-(id)initWithAttributedSting:(NSAttributedString *)attributedString
{
	if (self = [super init]) {
		_contents = attributedString ? [attributedString mutableCopy] :
					[[NSMutableAttributedString alloc] init];
		}
	return self;
}

-(NSString *)string
{
	return [_contents string];
}

-(NSDictionary *)attributesAtIndex:(unsigned)location
				  effectiveRange:(NSRange *)range
{
	return [_contents attributesAtIndex:location effectiveRange:range];
}
				  
-(void)replaceCharactersInRange:(NSRange)range
				  withString:(NSString *)string
{
	[_contents replaceCharactersInRange:range withString:string];
}
				  
-(void)setAttributes:(NSDictionary *)attributes
				  range:(NSRange)range
{
	[_contents setAttributes:attributes range:range];
}
				  
-(void)dealloc
{
	[_contents release];
	[super dealloc];
}

-(void) setLocation:(NSPoint)location
{
   printLocation = location;
}

-(void)print:(NSRect)rect:(float)offset
{
	if ((printLocation.y >= rect.origin.y-12.0) &&
		(printLocation.y <= (rect.origin.y + rect.size.height + 12.0)))
		[self drawAtPoint:printLocation];
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