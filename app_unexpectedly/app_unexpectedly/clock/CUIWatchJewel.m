//
//  CUIWatchJewel.m
//  IconCreator
//
//  Created by stephane on 22/03/2021.
//  Copyright © 2021 Acme, inc. All rights reserved.
//

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
