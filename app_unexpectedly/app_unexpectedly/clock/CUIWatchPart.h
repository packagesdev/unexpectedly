//
//  CUIWatchPart.h
//  IconCreator
//
//  Created by stephane on 24/03/2021.
//  Copyright © 2021 Acme, inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSUInteger, CUIWatchRenderingMode)
{
    CUIWatchRenderingModeFull=0,    // default
    CUIWatchRenderingModeWireframe
};

@interface CUIWatchPart : NSObject

@property CUIWatchRenderingMode renderingMode;

@property NSBezierPath * bezierPath;

@property NSColor * borderColor;

@property NSGradient * gradient;

- (void)draw;

@end
