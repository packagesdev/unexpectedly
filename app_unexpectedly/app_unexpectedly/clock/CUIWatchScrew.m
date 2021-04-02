//
//  CUIWatchScrew.m
//  IconCreator
//
//  Created by stephane on 23/03/2021.
//  Copyright © 2021 Acme, inc. All rights reserved.
//

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
