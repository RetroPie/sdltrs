//
//  NSPrintableString.h
//  Atari800MacX
//
//  Created by Mark Grebe on Sat Mar 19 2005.
//  Copyright (c) 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PrintProtocol.h"

@interface PrintablePath : NSBezierPath <PrintProtocol> {
   NSColor *color;
}

-(void) setColor:(NSColor *)pathColor;

@end
