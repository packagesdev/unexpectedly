//
//  CUIWatchBridge.m
//  IconCreator
//
//  Created by stephane on 22/03/2021.
//  Copyright © 2021 Acme, inc. All rights reserved.
//

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
        [[NSColor blackColor] setStroke];
        
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
    
    //[tImage drawInRect:tBezierPath.bounds];
    
    [NSGraphicsContext restoreGraphicsState];
    
    
    tBezierPath.lineWidth=1.0;
    
    [[NSColor colorWithDeviceWhite:0.0 alpha:0.3] setStroke];
    
    [tBezierPath stroke];
    
    return;
    
    if (self.borderColor!=nil)
    {
        [self.borderColor setStroke];
        
        [tBezierPath stroke];
    }
}

@end
