/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIWatchJewel.h"

@implementation CUIWatchJewel

- (NSGradient *)gradient
{
    return [[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceRed:49.0/255.0 green:28.0/255.0 blue:44.0/255.0 alpha:1.0]
                                         endingColor:[NSColor colorWithDeviceRed:49.0/255.0 green:28.0/255.0 blue:44.0/255.0 alpha:1.0]];
}

- (void)draw
{
    NSBezierPath * tBezierPath=[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(self.center.x-self.radius, self.center.y-self.radius, self.radius*2.0, self.radius*2.0)];
    
    if (self.renderingMode==CUIWatchRenderingModeWireframe)
    {
        [[NSColor blackColor] setStroke];
        
        [tBezierPath stroke];
        
        return;
    }
    
    [self.gradient drawInBezierPath:tBezierPath relativeCenterPosition:NSMakePoint(0.0,-1.0)];
    
    tBezierPath=[NSBezierPath bezierPath];
    
    [tBezierPath appendBezierPathWithArcWithCenter:self.center
                                            radius:self.radius
                                        startAngle:180.0 endAngle:0.0 clockwise:NO];
    
    [[NSColor colorWithDeviceRed:253.0/255.0 green:56.0/255.0 blue:212.0/255.0 alpha:0.8] setStroke];
    
    [tBezierPath stroke];
}

@end
