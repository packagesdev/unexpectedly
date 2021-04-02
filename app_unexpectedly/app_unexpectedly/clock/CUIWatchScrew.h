//
//  CUIwatchScrew.h
//  IconCreator
//
//  Created by stephane on 23/03/2021.
//  Copyright © 2021 Acme, inc. All rights reserved.
//

#import "CUIWatchPart.h"

@interface CUIWatchScrew : CUIWatchPart <NSCopying>

    @property NSPoint center;

    @property CGFloat radius;

    @property CGFloat rotation;

@end
