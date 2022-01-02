/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIWatchBridge.h"

@implementation CUIWatchBridge

- (NSGradient *)gradient
{
    return [[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0.60 alpha:1.0]
                                         endingColor:[NSColor colorWithDeviceWhite:0.50 alpha:1.0]];
    
    return [[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0.75 alpha:1.0]
                                         endingColor:[NSColor colorWithDeviceWhite:0.65 alpha:1.0]];
}

+ (NSImage *)brushedMetalTransparentTexture
{
    return [NSImage imageNamed:@"brushed-alum"];
}


- (void)draw
{
    NSBezierPath * tBezierPath=self.bezierPath;
    
    if (self.renderingMode==CUIWatchRenderingModeWireframe)
    {
        [[NSColor textColor] setStroke];
        
        [tBezierPath stroke];
        
        return;
    }
    
    NSShadow * tShadow = [NSShadow new];
    tShadow.shadowOffset = NSMakeSize(0, 2);
    tShadow.shadowBlurRadius = 20;
    tShadow.shadowColor = [NSColor colorWithDeviceWhite:0.1 alpha:0.75];
    
    [NSGraphicsContext saveGraphicsState];
    
    [tShadow set];
    
    [[NSColor blackColor] set];
    
    [tBezierPath fill];
    
    [NSGraphicsContext restoreGraphicsState];
    
    [self.gradient drawInBezierPath:tBezierPath angle:270];
    
    [NSGraphicsContext saveGraphicsState];
    
    NSImage * tImage=[CUIWatchBridge brushedMetalTransparentTexture];
    
    
    [tBezierPath addClip];
    
    [tImage drawAtPoint:tBezierPath.bounds.origin fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
    
    [NSGraphicsContext restoreGraphicsState];
    
    
    tBezierPath.lineWidth=1.0;
    
    [[NSColor colorWithDeviceWhite:0.0 alpha:0.3] setStroke];
    
    [tBezierPath stroke];
}

@end
