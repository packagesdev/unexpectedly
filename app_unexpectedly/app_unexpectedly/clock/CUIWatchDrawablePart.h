//
//  CUIWatchDrawablePart.h
//  IconCreator
//
//  Created by stephane on 22/03/2021.
//  Copyright © 2021 Acme, inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol CUIWatchDrawablePart <NSObject>

- (NSBezierPath *)bezierPath;

- (NSGradient *)gradient;

@optional

- (void)draw;

@end
