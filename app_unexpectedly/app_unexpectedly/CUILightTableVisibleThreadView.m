/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUILightTableVisibleThreadView.h"

@implementation CUILightTableVisibleThreadView

- (void)drawRect:(NSRect)dirtyRect
{
    [NSGraphicsContext saveGraphicsState];
    
    // Background
    
    NSShadow *shadow = [NSShadow new];
    shadow.shadowBlurRadius=5.0;
    shadow.shadowOffset=NSMakeSize(0.0, -2.0);
    shadow.shadowColor=[NSColor colorWithCalibratedWhite:0.0 alpha:0.5];
    [shadow set];
    
    NSRect tRect=NSInsetRect(self.bounds,5,0);
    tRect.origin.y+=5;
    tRect.size.height-=5;
    
    NSBezierPath * tBackgroundBezierPath=[NSBezierPath bezierPathWithRoundedRect:tRect xRadius:8 yRadius:8];
    
    [[NSColor colorWithDeviceWhite:0.95 alpha:1.0] set];
    
    [tBackgroundBezierPath fill];
    
    [NSGraphicsContext restoreGraphicsState];
    
    // Header
    
    tRect.origin.y=NSMaxY(tRect)-32.0;
    tRect.size.height=32.0;
    
    NSBezierPath * tHeaderBezierPath=[NSBezierPath bezierPath];
    
    [tHeaderBezierPath moveToPoint:tRect.origin];
    
    [tHeaderBezierPath lineToPoint:NSMakePoint(NSMaxX(tRect),NSMinY(tRect))];
    [tHeaderBezierPath lineToPoint:NSMakePoint(NSMaxX(tRect),NSMaxY(tRect)-8.0)];
    
    [tHeaderBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(tRect)-8.0,NSMaxY(tRect)-8.0) radius:8.0 startAngle:0 endAngle:90 clockwise:NO];
    
    [tHeaderBezierPath lineToPoint:NSMakePoint(NSMinX(tRect)+8.0,NSMaxY(tRect))];
    
    [tHeaderBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(tRect)+8.0,NSMaxY(tRect)-8.0) radius:8.0 startAngle:90 endAngle:180 clockwise:NO];
    
    [tHeaderBezierPath closePath];
    
    if (self.crashed==YES)
        [[NSColor colorWithDeviceRed:203.0/255.0 green:49.0/255.0 blue:34.0/255.0 alpha:1.0 ] set];
    else
    {
        if (self.applicationSpecificBacktrace==YES)
            [[NSColor orangeColor] set];
        else
            [[NSColor colorWithDeviceWhite:0.60 alpha:1.0] set];
    }
    
    [tHeaderBezierPath fill];
}

@end
