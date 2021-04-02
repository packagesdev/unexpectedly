//
//  CUIWatchPart.m
//  IconCreator
//
//  Created by stephane on 24/03/2021.
//  Copyright © 2021 Acme, inc. All rights reserved.
//

#import "CUIWatchPart.h"

@implementation CUIWatchPart

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _borderColor=[NSColor colorWithDeviceWhite:0.0 alpha:0.5];
    }
    
    return self;
}

#pragma mark -

- (void)draw
{
    NSBezierPath * tBezierPath=self.bezierPath;
    
    if (tBezierPath==nil)
        return;
    
    [self.gradient drawInBezierPath:tBezierPath angle:270];
    
    tBezierPath.lineWidth=1.0;
    
    //[[NSColor redColor] set];
     
     /*if ([tPart isKindOfClass:[CUIWatchGear class]]==NO)
     {
     [[NSColor greenColor] set];
     }*/
    
    if (self.borderColor!=nil)
    {
        [self.borderColor setStroke];
        
        [tBezierPath stroke];
    }
}

#pragma mark -



@end
