/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICaptionView.h"

#define CUICaptionMinWidth  40.0

@implementation CUICaptionView

- (NSSize)badgeSizeForString:(NSString*)string
{
    NSSize tSize = [self.attributedStringValue size];
    
    // Paddings
    
    tSize.width += 12.0;
    
    if (tSize.width<CUICaptionMinWidth)
        tSize.width=CUICaptionMinWidth;
    
    return tSize;
}

- (void)drawRect:(NSRect)inRect
{
    NSRect tFrame=self.bounds;
    
    NSSize tBadgeSize = [self badgeSizeForString:self.stringValue];
    
    tBadgeSize.height=NSHeight(tFrame);
    
    NSRect tBadgeRect;
    
    tBadgeRect.origin.x=round(NSMaxX(tFrame)-tBadgeSize.width);
    tBadgeRect.origin.y=round(NSMidY(tFrame)-tBadgeSize.height*0.5);
    tBadgeRect.size=tBadgeSize;
    
    // Draw badge
    
    NSBezierPath* path = [NSBezierPath bezierPathWithRoundedRect:tBadgeRect xRadius:4.0 yRadius:4.0];
    
    if (self.cell.backgroundStyle==NSBackgroundStyleEmphasized)
    {
        [[NSColor colorWithDeviceWhite:0.95 alpha:1.0] setFill];
    }
    else
    {
        [[NSColor tertiaryLabelColor] setFill];
    }
    
    [path fill];
    
    // Draw text
    
    NSMutableParagraphStyle* paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.alignment=NSTextAlignmentCenter;
    
    NSColor * tTextColor=nil;
    
    if (self.cell.backgroundStyle==NSBackgroundStyleEmphasized)
    {
        tTextColor=[NSColor colorWithDeviceWhite:0.25 alpha:1.0];
    }
    else
    {
        tTextColor=[NSColor whiteColor];
    }
    
    NSDictionary* textAttributes = @{NSForegroundColorAttributeName:tTextColor, NSParagraphStyleAttributeName:paragraphStyle};
    
    tBadgeRect.origin.y+=1;
    
    [self.stringValue drawInRect:tBadgeRect withAttributes:textAttributes];
}

@end
