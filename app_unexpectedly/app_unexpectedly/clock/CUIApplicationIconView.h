//
//  CUIApplicationIconView.h
//  IconCreator
//
//  Created by stephane on 17/03/2021.
//  Copyright © 2021 Acme, inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CUIWatchPart.h"

@interface CUIApplicationIconView : NSView

@property (nonatomic) CUIWatchRenderingMode renderingMode;

- (NSData *)PNGData;

@end

