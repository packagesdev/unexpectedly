//
//  CUIWatchAxis.m
//  IconCreator
//
//  Created by stephane on 29/03/2021.
//  Copyright © 2021 Acme, inc. All rights reserved.
//

#import "CUIWatchAxis.h"

@implementation CUIWatchAxis

- (NSGradient *)gradient
{
    return [[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:1.0 alpha:1.0]
                                         endingColor:[NSColor colorWithDeviceWhite:0.2 alpha:1.0]];
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
    
    [self.gradient drawInBezierPath:tBezierPath relativeCenterPosition:NSMakePoint(0.0,0.75)];
}

@end
