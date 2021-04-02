//
//  CUIGear.h
//  IconCreator
//
//  Created by stephane on 22/03/2021.
//  Copyright © 2021 Acme, inc. All rights reserved.
//

#import "CUIWatchPart.h"

@interface CUIWatchGear : CUIWatchPart <NSCopying>

    @property NSPoint center;

    @property CGFloat outsideRadius;

    @property (nonatomic,readonly) CGFloat rootRadius;


    @property NSUInteger numberOfTeeth;

    @property CGFloat circularToothThickness;

    @property CGFloat wholeDepth;

    @property CGFloat addendum;

    @property (nonatomic,readonly) CGFloat dedendum;

    @property CGFloat toothTop;




    @property CGFloat axisRadius;

    @property CGFloat innerRadius;

    @property CGFloat bezelRadius;


    @property NSUInteger innerBranchesCount;

    @property CGFloat innerBranchThickness;


    @property CGFloat rotation;

    @property (nonatomic, copy) CGFloat (^ticker)(void);

- (void)tick;

@end
