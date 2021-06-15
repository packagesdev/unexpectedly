/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIWatchScrew.h"

@implementation CUIWatchScrew

- (NSBezierPath *)bezierPath
{
    NSRect tRect=NSMakeRect(self.center.x-self.radius,self.center.y-self.radius,2*self.radius,2*self.radius);
    
    NSBezierPath * tBezierPath=[NSBezierPath bezierPathWithOvalInRect:tRect];
    
    return tBezierPath;
}

#pragma mark -

- (NSGradient *)gradient
{
    return [[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0.8 alpha:1.0]
                                         endingColor:[NSColor colorWithDeviceWhite:0.7 alpha:1.0]];
}

#pragma mark -

- (void)draw
{
    NSAffineTransform * tAffineTransform=[NSAffineTransform transform];
    
    [tAffineTransform translateXBy:self.center.x yBy:self.center.y];
    
    
    NSRect tRect=NSMakeRect(-self.radius,-self.radius,2*self.radius,2*self.radius);
    
    NSBezierPath * tBezierPath=[NSBezierPath bezierPathWithOvalInRect:tRect];
    
    [tBezierPath transformUsingAffineTransform:tAffineTransform];
    
    if (self.renderingMode==CUIWatchRenderingModeWireframe)
    {
        [[NSColor blackColor] setStroke];
        
        [tBezierPath stroke];
        
        
        [tAffineTransform rotateByDegrees:self.rotation];
        
        tBezierPath=[NSBezierPath bezierPath];
        
        tBezierPath.lineWidth=1.5;
        [tBezierPath moveToPoint:NSMakePoint(-self.radius+1,0)];
        
        [tBezierPath lineToPoint:NSMakePoint(self.radius,0)];
        
        [tBezierPath transformUsingAffineTransform:tAffineTransform];
        
        [tBezierPath stroke];
        
        return;
    }
    
    
    [self.gradient drawInBezierPath:tBezierPath angle:270];
    
    tBezierPath=[NSBezierPath bezierPath];
    
    [tBezierPath moveToPoint:NSMakePoint(-self.radius,0)];
    [tBezierPath appendBezierPathWithArcWithCenter:NSZeroPoint
                                            radius:self.radius-1
                                        startAngle:180
                                          endAngle:360
                                         clockwise:NO];
    
    tBezierPath.lineWidth=1.0;
    
    [[NSColor colorWithWhite:1.0 alpha:0.4] setStroke];
    
    [tBezierPath transformUsingAffineTransform:tAffineTransform];
    
    [tBezierPath stroke];
    
    tBezierPath=[NSBezierPath bezierPath];
    
    [tBezierPath moveToPoint:NSMakePoint(self.radius,0)];
    [tBezierPath appendBezierPathWithArcWithCenter:NSZeroPoint
                                            radius:self.radius
                                        startAngle:0
                                          endAngle:180
                                         clockwise:NO];
    
    
    
    tBezierPath.lineWidth=1.0;
    
    [[NSColor colorWithWhite:0.3 alpha:0.4] setStroke];
    
    //[[NSColor redColor] set];
    
    [tBezierPath transformUsingAffineTransform:tAffineTransform];
    
    [tBezierPath stroke];
    
    [tAffineTransform rotateByDegrees:self.rotation];
    
    
    tBezierPath=[NSBezierPath bezierPath];
    
    tBezierPath.lineWidth=1.5;
    [tBezierPath moveToPoint:NSMakePoint(-self.radius+1,0)];
    
    [tBezierPath lineToPoint:NSMakePoint(self.radius,0)];
    
    [tBezierPath transformUsingAffineTransform:tAffineTransform];
    
    [tBezierPath stroke];
}


#pragma mark - NSCopying

- (id)copyWithZone:(nullable NSZone *)zone
{
    CUIWatchScrew * nScrew=[CUIWatchScrew new];
    
    nScrew.center=self.center;
    
    nScrew.radius=self.radius;
    
    return nScrew;
}

@end
