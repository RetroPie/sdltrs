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

#import <Cocoa/Cocoa.h>
#import "PrintableString.h"
#import "PrintableGraphics.h"
#import "PrinterProtocol.h"

typedef struct EPSON_PREF {
	int charSet;
    int formLength;
	int printPitch;
	int printWeight;
    int autoLinefeed;
	int printSlashedZeros;
	int autoSkip;
	int splitSkip;
} EPSON_PREF;

@interface EpsonFX80Simulator : NSObject <PrinterProtocol> {
	int state;
	int style;
	int pitch;
	NSFont *styles[64];
	float leftMargin;
	float rightMargin;
	float compressedRightMargin;
	float startHorizPosition;
	float nextHorizPosition;
	float vertPosition;
	bool autoLineFeed;
	bool slashedZeroMode;
	float lineSpacing;
	float formLength;
	bool italicMode;
	bool italicInterMode;
	bool printCtrlCodesMode;
	bool eighthBitZero;
	bool eighthBitOne;
	bool emphasizedMode;
	bool doubleStrikeMode;
	bool doubleStrikeWantedMode;
	bool eliteMode;
    bool superscriptMode;
	bool subscriptMode;
	bool expandedMode;
	bool compressedMode;
	bool expandedTempMode;
	bool underlineMode;
	bool proportionalMode;
	int  graphMode;
	int  graphCount;
	int  graphTotal;
	unsigned char graphBuffer[4096];
	int  kGraphMode;
	int  lGraphMode;
	int  yGraphMode;
	int  zGraphMode;
	float horizWidth;
	float propCharSetback;
	int  horizTabCount;
	float horizTabs[32];
	int  vertTabChan;
	int  vertTabCount[8];
	float vertTabs[8][16];
	int graphRedefCode;
	int vertTabChanSetNum;
	int countryMode;
	bool immedMode;
	int skipOverPerf;
	bool splitPerfSkip;

	PrintableString *printBuffer;
}

+ (EpsonFX80Simulator *)sharedInstance;
- (void)addChar:(unsigned short)unicharacter:(bool)italic;
- (void)idleState:(char) character;
- (void)escState:(char) character;
- (void)masterModeState:(char) character;
- (void)graphModeState:(char) character;
- (void)graphModeTypeState:(char) character;
- (void)ninePinGraphState:(char) character;
- (void)ninePinGraphTypeState:(char) character;
- (void)graphCnt1State:(char) character;
- (void)inGraphModeState:(char) character;
- (void)underModeState:(char) character;
- (void)vertTabChanState:(char) character;
- (void)superLineSpaceState:(char) character;
- (void)graphRedefState:(char) character;
- (void)grapRedefCodeState:(char) character;
- (void)lineSpaceState:(char) character;
- (void)vertTabSetState:(char) character;
- (void)formLengthLineState:(char) character;
- (void)formLengthInchState:(char) character;
- (void)horizTabSetState:(char) character;
- (void)printCtrlCodesState:(char) character;
- (void)immedLfState:(char) character;
- (void)skipOverPerfState:(char) character;
- (void)rightMarginState:(char) character;
- (void)interCharSetState:(char) character;
- (void)scriptMode:(char) character;
- (void)expandMode:(char) character;
- (void)vertTabChanSetState:(char) character;
- (void)vertTabChanNumState:(char) character;
- (void)immedModeState:(char) character;
- (void)immedRevLfState:(char) character;
- (void)leftMarginState:(char) character;
- (void)proportionalModeState:(char) character;
- (void)unimpEsc1State:(char) character;

-(void)resetHorizTabs;
-(void)setStyle;
-(void)emptyPrintBuffer:(bool)doubleStrike;
-(void)clearPrintBuffer;
-(void)executeLineFeed:(float)amount;


@end
