/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIApplicationIconView.h"

#import "CUIWatchGear.h"
#import "CUIWatchBridge.h"
#import "CUIWatchJewel.h"
#import "CUIWatchScrew.h"
#import "CUIWatchAxis.h"

static void CGPathToBezierPathApplierFunction(void *info, const CGPathElement *element) {
    NSBezierPath *bezierPath = (__bridge NSBezierPath *)info;
    CGPoint *points = element->points;
    switch(element->type) {
        case kCGPathElementMoveToPoint: [bezierPath moveToPoint:points[0]]; break;
        case kCGPathElementAddLineToPoint: [bezierPath lineToPoint:points[0]]; break;
        case kCGPathElementAddQuadCurveToPoint: {
            NSPoint qp0 = bezierPath.currentPoint, qp1 = points[0], qp2 = points[1], cp1, cp2;
            CGFloat m = (2.0 / 3.0);
            cp1.x = (qp0.x + ((qp1.x - qp0.x) * m));
            cp1.y = (qp0.y + ((qp1.y - qp0.y) * m));
            cp2.x = (qp2.x + ((qp1.x - qp2.x) * m));
            cp2.y = (qp2.y + ((qp1.y - qp2.y) * m));
            [bezierPath curveToPoint:qp2 controlPoint1:cp1 controlPoint2:cp2];
            break;
        }
        case kCGPathElementAddCurveToPoint: [bezierPath curveToPoint:points[2] controlPoint1:points[0] controlPoint2:points[1]]; break;
        case kCGPathElementCloseSubpath: [bezierPath closePath]; break;
    }
}

@interface NSBezierPath (BezierPathWithCGPath)
+ (NSBezierPath *)JNS_bezierPathWithCGPath:(CGPathRef)cgPath; //prefixed as Apple may add bezierPathWithCGPath: method someday
@end

@implementation NSBezierPath (BezierPathWithCGPath)
+ (NSBezierPath *)JNS_bezierPathWithCGPath:(CGPathRef)cgPath {
    NSBezierPath *bezierPath = [NSBezierPath bezierPath];
    CGPathApply(cgPath, (__bridge void *)bezierPath, CGPathToBezierPathApplierFunction);
    return bezierPath;
}
@end

@interface CUIApplicationIconView ()
{
    CGFloat _ratio;
    
    NSTimer * _timer;
    
    CGFloat _rotation;
    
    NSMutableArray<CUIWatchPart *> * _parts;
}

@end

@implementation CUIApplicationIconView

- (void)awakeFromNib
{
    
    
}

#pragma mark -


- (NSBezierPath *)centerBridgePath
{
    NSRect tBounds=self.bounds;
    
    NSPoint tCenter=NSMakePoint(NSMidX(tBounds),(0.6*NSHeight(tBounds)));
    
    NSBezierPath * tBezierPath=[NSBezierPath bezierPath];
    
    [tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(tCenter.x-_ratio*102, tCenter.y-_ratio*8)
                                            radius:_ratio*90
                                        startAngle:10
                                          endAngle:65
                                         clockwise:NO];
    
    [tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(tCenter.x-_ratio*57, tCenter.y+_ratio*98)
                                            radius:_ratio*25
                                        startAngle:250
                                          endAngle:200
                                         clockwise:YES];
    
    [tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(tCenter.x-_ratio*95, tCenter.y+_ratio*85)
                                            radius:_ratio*15
                                        startAngle:12
                                          endAngle:246
                                         clockwise:NO];
    
    [tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(tCenter.x-_ratio*105, tCenter.y+_ratio*56)
                                            radius:_ratio*15
                                        startAngle:70
                                          endAngle:-43
                                         clockwise:YES];
    
    [tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(tCenter.x-_ratio*62, tCenter.y+_ratio*25)
                                            radius:_ratio*38
                                        startAngle:149
                                          endAngle:180
                                         clockwise:NO];
    
    
    [tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(tCenter.x-_ratio*136, tCenter.y+_ratio*25)
                                            radius:_ratio*36
                                        startAngle:0
                                          endAngle:-120
                                         clockwise:YES];
    
    [tBezierPath lineToPoint:NSMakePoint(tCenter.x-_ratio*166, tCenter.y-_ratio*30)];
    
    [tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(tCenter.x-_ratio*156, tCenter.y-_ratio*75)
                                            radius:_ratio*36
                                        startAngle:65
                                          endAngle:-20
                                         clockwise:YES];
    
    [tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(tCenter.x-_ratio*144, tCenter.y+_ratio*20)
                                            radius:_ratio*120
                                        startAngle:-70
                                          endAngle:-20
                                         clockwise:NO];
    
    
    
    
    [tBezierPath closePath];
    
    NSBezierPath * tHolePath=[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(tCenter.x-_ratio*86, tCenter.y-_ratio*30,_ratio*60,_ratio*80)];
    
    [tBezierPath appendBezierPath:tHolePath];
    
    tBezierPath.windingRule=NSWindingRuleEvenOdd;
    
    return tBezierPath;
}

- (NSBezierPath *)leftBridge
{
    NSRect tBounds=self.bounds;
    
    NSPoint tCenter=NSMakePoint(NSMidX(tBounds),(0.6*NSHeight(tBounds)));
    
    NSBezierPath * tBezierPath=[NSBezierPath bezierPath];
    
    [tBezierPath moveToPoint:NSMakePoint(tCenter.x-_ratio*320,tCenter.y-_ratio*230)];
    
    [tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(tCenter.x+_ratio*53, tCenter.y-_ratio*96)
                                            radius:_ratio*210
                                        startAngle:220
                                          endAngle:150
                                         clockwise:YES];
    
    [tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(tCenter.x-_ratio*136, tCenter.y+_ratio*25)
                                            radius:_ratio*15
                                        startAngle:320
                                          endAngle:160
                                         clockwise:NO];
    
    [tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(tCenter.x-_ratio*237, tCenter.y+_ratio*80)
                                            radius:_ratio*100
                                        startAngle:-30
                                          endAngle:180
                                         clockwise:YES];
    
    
    
    [tBezierPath closePath];
    
    
    return tBezierPath;
}

- (NSBezierPath *)topBridgePath
{
    NSRect tBounds=self.bounds;
    
    NSPoint tCenter=NSMakePoint(NSMidX(tBounds),(0.6*NSHeight(tBounds)));
    
    NSBezierPath * tBezierPath=[NSBezierPath bezierPath];
    
    [tBezierPath moveToPoint:NSMakePoint(tCenter.x+_ratio*170,tCenter.y+_ratio*80)];
    [tBezierPath lineToPoint:NSMakePoint(tCenter.x+_ratio*155,tCenter.y+_ratio*45)];
    
    
    [tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(tCenter.x+_ratio*40, tCenter.y+_ratio*55)
                                            radius:_ratio*70
                                        startAngle:20
                                          endAngle:65
                                         clockwise:NO];
    
    [tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(tCenter.x, tCenter.y+_ratio*120)
                                            radius:_ratio*70
                                        startAngle:0
                                          endAngle:120
                                         clockwise:NO];
    
    [tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(tCenter.x-_ratio*78, tCenter.y+_ratio*126)
                                            radius:_ratio*70
                                        startAngle:55
                                          endAngle:120
                                         clockwise:NO];
    
    [tBezierPath lineToPoint:NSMakePoint(tCenter.x-_ratio*40,tCenter.y+_ratio*310)];
    
    [tBezierPath lineToPoint:NSMakePoint(tCenter.x+_ratio*40,tCenter.y+_ratio*310)];
    
    [tBezierPath lineToPoint:NSMakePoint(tCenter.x+_ratio*180,tCenter.y+_ratio*85)];
    
    [tBezierPath closePath];
    
    return tBezierPath;
}

- (NSBezierPath *)rightBridgePath
{
    NSRect tBounds=self.bounds;
    
    NSPoint tCenter=NSMakePoint(NSMidX(tBounds),(0.6*NSHeight(tBounds)));
    
    NSBezierPath * tBezierPath=[NSBezierPath bezierPath];
    
    [tBezierPath moveToPoint:NSMakePoint(tCenter.x+_ratio*230,tCenter.y-_ratio*50)];
    [tBezierPath lineToPoint:NSMakePoint(tCenter.x+_ratio*180,tCenter.y+_ratio*100)];
    
    [tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(tCenter.x+_ratio*165,tCenter.y)
                                          radius:_ratio*124
                                      startAngle:90
                                        endAngle:166
                                       clockwise:NO];
    
    [tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(tCenter.x+_ratio*28,tCenter.y+_ratio*38)
                                            radius:_ratio*18
                                        startAngle:340
                                          endAngle:240
                                         clockwise:YES];
    
    [tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(tCenter.x,tCenter.y)
                                            radius:_ratio*29
                                        startAngle:50
                                          endAngle:170
                                         clockwise:NO];
    
    [tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(tCenter.x-_ratio*126, tCenter.y+_ratio*25)
                                            radius:_ratio*100
                                        startAngle:350
                                          endAngle:268
                                         clockwise:YES];
    
    [tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(tCenter.x-_ratio*137, tCenter.y-_ratio*86)
                                            radius:_ratio*10
                                        startAngle:90
                                          endAngle:180
                                         clockwise:NO];
    
    [tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(tCenter.x+_ratio*53, tCenter.y-_ratio*86)
                                            radius:_ratio*200
                                        startAngle:180
                                          endAngle:280
                                         clockwise:NO];
    
    [tBezierPath closePath];
    
    
    NSBezierPath * tHolePath=[NSBezierPath bezierPath];
    
   
    
    [tHolePath moveToPoint:NSMakePoint(tCenter.x+_ratio*168,tCenter.y+_ratio*30)];
    
    [tHolePath lineToPoint:NSMakePoint(tCenter.x+_ratio*158,tCenter.y+_ratio*30)];
    
    [tHolePath appendBezierPathWithArcWithCenter:NSMakePoint(tCenter.x+_ratio*112,tCenter.y)
                                            radius:_ratio*51
                                        startAngle:60
                                          endAngle:194
                                         clockwise:NO];
    
    [tHolePath appendBezierPathWithArcWithCenter:NSMakePoint(tCenter.x+_ratio*38, tCenter.y-_ratio*110)
                                            radius:_ratio*100
                                        startAngle:77
                                          endAngle:35
                                         clockwise:NO];
    
    [tHolePath appendBezierPathWithArcWithCenter:NSMakePoint(tCenter.x+_ratio*112,tCenter.y)
                                            radius:_ratio*51
                                        startAngle:278
                                          endAngle:330
                                         clockwise:NO];
    
    [tHolePath lineToPoint:NSMakePoint(tCenter.x+_ratio*168,tCenter.y-_ratio*25)];
    
    [tHolePath closePath];
    
    [tHolePath appendBezierPathWithOvalInRect:NSMakeRect(tCenter.x-_ratio*9,tCenter.y-_ratio*8,_ratio*18.0,_ratio*18.0)];
    
    [tBezierPath appendBezierPath:tHolePath];
    
    tBezierPath.windingRule=NSWindingRuleEvenOdd;
    
    return tBezierPath;
}

- (void)viewDidMoveToWindow
{
    if (self.window==nil)
    {
        [_timer invalidate];
        _timer=nil;
        
        return;
    }
    
    NSRect tBounds=self.bounds;
    
    CGFloat tIconSize=NSWidth(tBounds);
    
    _ratio=NSWidth(tBounds)/1024.0;
    
    NSPoint tCenter=NSMakePoint(NSMidX(tBounds),(0.6*NSHeight(tBounds)));
    
    
    _parts=[NSMutableArray array];
    
    
    
    CUIWatchGear * tGear5_60_Template=[CUIWatchGear new];
    
    // 5 branches / 60 teeth
    
    tGear5_60_Template.outsideRadius=_ratio*59;
    tGear5_60_Template.axisRadius=_ratio*3;
    tGear5_60_Template.innerRadius=_ratio*20;
    tGear5_60_Template.innerBranchesCount=5;
    tGear5_60_Template.innerBranchThickness=_ratio*7.0;
    
    tGear5_60_Template.bezelRadius=_ratio*50;
    
    tGear5_60_Template.numberOfTeeth=60;
    
    tGear5_60_Template.wholeDepth=_ratio*6;
    tGear5_60_Template.addendum=_ratio*2;
    
    tGear5_60_Template.circularToothThickness=_ratio*4;
    tGear5_60_Template.toothTop=_ratio*2;
    
    tGear5_60_Template.rotation=10.0;
    
    tGear5_60_Template.gradient=[[NSGradient alloc] initWithColors:@[[NSColor colorWithDeviceRed:255/255.0 green:249/255.0 blue:231/255.0 alpha:1.0],
                                                                     [NSColor colorWithDeviceRed:245/255.0 green:242/255.0 blue:217/255.0 alpha:1.0],
                                                                     ]];
    
    tGear5_60_Template.borderColor=[NSColor colorWithDeviceWhite:0.0 alpha:0.25];
    
    // 3 branches / 0 teeth
    
    CUIWatchGear * tGear3_0=[CUIWatchGear new];
    
    tGear3_0.outsideRadius=_ratio*95;
    tGear3_0.axisRadius=_ratio*8;
    tGear3_0.innerRadius=_ratio*20;
    tGear3_0.innerBranchesCount=3;
    
    if (tIconSize>64.0)
    {
        tGear3_0.innerBranchThickness=_ratio*10.0;
    }
    else
    {
        tGear3_0.innerBranchThickness=_ratio*30.0;
    }
    
    tGear3_0.gradient=[[NSGradient alloc] initWithColors:@[[NSColor colorWithDeviceRed:227/255.0 green:173/255.0 blue:102/255.0 alpha:1.0],
                                                                     [NSColor colorWithDeviceRed:246/255.0 green:187/255.0 blue:59/255.0 alpha:1.0],
                                                                     ]];
    
    // 0 branches / 8 teeth
    
    CUIWatchGear * tGear0_8=[CUIWatchGear new];
    
    tGear0_8.outsideRadius=_ratio*10;
    tGear0_8.axisRadius=_ratio*2;
    tGear0_8.innerBranchesCount=0;
    
    tGear0_8.numberOfTeeth=8;
    
    tGear0_8.wholeDepth=_ratio*5;
    
    tGear0_8.circularToothThickness=_ratio*3;
    tGear0_8.toothTop=_ratio*2;
    
    tGear0_8.addendum=_ratio*4;
    
    tGear0_8.gradient=[[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0.8 alpha:1.0]
                                                    endingColor:[NSColor colorWithDeviceWhite:0.5 alpha:1.0]];
    
    
    tGear0_8.borderColor=[NSColor colorWithDeviceWhite:0.6 alpha:0.5];
    
    // 0 branches / 30 teeth
    
    CUIWatchGear * tGear0_30=[CUIWatchGear new];
    
    tGear0_30.outsideRadius=_ratio*46;
    tGear0_30.axisRadius=_ratio*13;
    tGear0_30.innerBranchesCount=0;
    
    if (tIconSize>128.0)
    {
        tGear0_30.bezelRadius=_ratio*32;
        tGear0_30.numberOfTeeth=30;
    }
    
    tGear0_30.wholeDepth=_ratio*9.0;
    tGear0_30.addendum=_ratio*5.0;
    tGear0_30.toothTop=_ratio*3;
    tGear0_30.circularToothThickness=_ratio*5.0;
    
    tGear0_30.gradient=[[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0.8 alpha:1.0]
                                                    endingColor:[NSColor colorWithDeviceWhite:0.5 alpha:1.0]];
    
    // 0 branches / 60 teeth
    
    CUIWatchGear * tGear0_60=[CUIWatchGear new];
    
    tGear0_60.outsideRadius=_ratio*94;
    tGear0_60.axisRadius=_ratio*13;
    tGear0_60.innerBranchesCount=0;
    
    if (tIconSize>128.0)
    {
        tGear0_60.numberOfTeeth=60;
    }
    
    tGear0_60.circularToothThickness=_ratio*5;
    tGear0_60.wholeDepth=_ratio*10;
    tGear0_60.addendum=_ratio*4;
    tGear0_60.toothTop=_ratio*3;
    
    tGear0_60.gradient=[[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0.8 alpha:1.0]
                                                     endingColor:[NSColor colorWithDeviceWhite:0.3 alpha:1.0]];
    
    // 4 branches / 0 teeth
    
    CUIWatchGear * tGear4_0=[CUIWatchGear new];
    
    tGear4_0.outsideRadius=_ratio*45;
    tGear4_0.axisRadius=_ratio*3;
    tGear4_0.innerRadius=_ratio*10;
    tGear4_0.innerBranchesCount=4;
    
    
    if (tIconSize>128.0)
    {
        tGear4_0.innerBranchThickness=7*_ratio;
    }
    else
    {
        tGear4_0.innerBranchThickness=14*_ratio;
    }
    
    tGear4_0.numberOfTeeth=0;
    
    tGear4_0.gradient=[[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0.8 alpha:1.0]
                                                     endingColor:[NSColor colorWithDeviceWhite:0.3 alpha:1.0]];
    
    
    // Screw
    
    CUIWatchScrew * tWatchScrew_Template=[CUIWatchScrew new];
    tWatchScrew_Template.radius=_ratio*14;
    
    // Place gears
    
    if (tIconSize>32.0)
    {
        tGear4_0.center=NSMakePoint(tCenter.x-_ratio*75, tCenter.y+_ratio*140);
    
        [_parts addObject:tGear4_0];
    }
    
    CUIWatchAxis * tAxis1=[CUIWatchAxis new];
    tAxis1.center=NSMakePoint(tCenter.x-_ratio*75, tCenter.y+_ratio*140);
    tAxis1.radius=_ratio*6.0;
    
    [_parts addObject:tAxis1];
    
    // Center bridge
    
    if (tIconSize>64)
    {
        CUIWatchBridge * tCenterBridge=[CUIWatchBridge new];
    
        tCenterBridge.bezierPath=[self centerBridgePath];
    
        [_parts addObject:tCenterBridge];
    
        CUIWatchScrew * tCenterBridgeScrew1=[tWatchScrew_Template copy];
        tCenterBridgeScrew1.radius=_ratio*10;
        tCenterBridgeScrew1.rotation=-40;
        tCenterBridgeScrew1.center=NSMakePoint(tCenter.x-_ratio*105, tCenter.y-_ratio*30);
    
        [_parts addObject:tCenterBridgeScrew1];
    }
    
    if (tIconSize>128.0)
    {
        CUIWatchJewel * tCenterJewel=[CUIWatchJewel new];
        tCenterJewel.center=NSMakePoint(tCenter.x-_ratio*95, tCenter.y+_ratio*85);
        tCenterJewel.radius=_ratio*4.0;
    
        [_parts addObject:tCenterJewel];
    }
    
    if (tIconSize>64.0)
    {
        CUIWatchGear * tGearYellow1=[tGear5_60_Template copy];
    
        tGearYellow1.center=NSMakePoint(tCenter.x+_ratio*28, tCenter.y+_ratio*60);
        tGearYellow1.ticker = ^CGFloat{
        
            return 1.0/60;
        
        };
    
        [_parts addObject:tGearYellow1];
    }
    
    tGear0_8.center=NSMakePoint(tCenter.x+_ratio*28, tCenter.y+_ratio*60);
    tGear0_8.ticker = ^CGFloat{
        
        return 1.0/60;
        
    };
    
    [_parts addObject:tGear0_8];
    
    
    CUIWatchGear * tGearOrange=tGear3_0;
    
    tGearOrange.center=NSMakePoint(tCenter.x-_ratio*136, tCenter.y+_ratio*25);
    tGearOrange.ticker = ^CGFloat{
        
        return 0.1;
    };
    
    [_parts addObject:tGearOrange];
    
    
    CUIWatchGear * tGearYellow2=[tGear5_60_Template copy];
    
    tGearYellow2.center=NSMakePoint(tCenter.x, tCenter.y);
    tGearYellow2.ticker = ^CGFloat{
        
        return -1.0/3600;
        
    };
    
    [_parts addObject:tGearYellow2];
    
    
    CUIWatchGear * tGearYellow3=[tGear5_60_Template copy];
    
    tGearYellow3.center=NSMakePoint(tCenter.x, tCenter.y+_ratio*120);
    tGearYellow3.ticker = ^CGFloat{
        
        return -1.0/3600;
        
    };
    
    [_parts addObject:tGearYellow3];
    
    CUIWatchAxis * tAxix3=[CUIWatchAxis new];
    tAxix3.center=NSMakePoint(tCenter.x, tCenter.y+_ratio*120);
    tAxix3.radius=_ratio*4.0;
    
    [_parts addObject:tAxix3];
    
    tGear0_8.center=NSMakePoint(tCenter.x+_ratio*28, tCenter.y+_ratio*60);
    
    [_parts addObject:tGear0_8];
    
    // Top Bridge
    
    CUIWatchBridge * tTopBridge=[CUIWatchBridge new];
    
    tTopBridge.bezierPath=[self topBridgePath];
    
    [_parts addObject:tTopBridge];
    
    CUIWatchScrew * tTopBridgeScrew1=[tWatchScrew_Template copy];
    tTopBridgeScrew1.center=NSMakePoint(tCenter.x+_ratio, tCenter.y+_ratio*230);
    tTopBridgeScrew1.rotation=12.0;
    
    [_parts addObject:tTopBridgeScrew1];
    
    // Left Bridge
    
    
    CUIWatchBridge * tLeftBridge=[CUIWatchBridge new];
    
    tLeftBridge.bezierPath=[self leftBridge];
    
    [_parts addObject:tLeftBridge];
    
    CUIWatchScrew * tLeftBridgeScrew1=[tWatchScrew_Template copy];
    tLeftBridgeScrew1.center=NSMakePoint(tCenter.x-_ratio*210, tCenter.y-_ratio*80);
    
    [_parts addObject:tLeftBridgeScrew1];
    
    
    if (tIconSize>128.0)
    {
        CUIWatchJewel * tLeftJewel=[CUIWatchJewel new];
        tLeftJewel.center=NSMakePoint(tCenter.x-_ratio*136, tCenter.y+_ratio*25);
        tLeftJewel.radius=_ratio*5.0;
        
        [_parts addObject:tLeftJewel];
    }
    
    // Right bridge
    
    CUIWatchBridge * tRightBridge=[CUIWatchBridge new];
    
    tRightBridge.bezierPath=[self rightBridgePath];
    
    [_parts addObject:tRightBridge];
    
    
    CUIWatchScrew * tRightBridgeScrew1=[tWatchScrew_Template copy];
    tRightBridgeScrew1.center=NSMakePoint(tCenter.x+_ratio*140, tCenter.y+_ratio*80);
    tRightBridgeScrew1.rotation=95;
    
    [_parts addObject:tRightBridgeScrew1];
    
    CUIWatchScrew * tRightBridgeScrew2=[tWatchScrew_Template copy];
    tRightBridgeScrew2.center=NSMakePoint(tCenter.x-_ratio*115, tCenter.y-_ratio*105);
    tRightBridgeScrew2.rotation=15;
    
    [_parts addObject:tRightBridgeScrew2];
    
    CUIWatchGear * tGearGray60=tGear0_60;
    
    tGearGray60.center=NSMakePoint(tCenter.x+_ratio*38, tCenter.y-_ratio*110);
    tGearGray60.ticker = ^CGFloat{
        
        return 0.25;
    };
    
    [_parts addObject:tGearGray60];
    
    
    CUIWatchScrew * tRightBridgeScrew3=[tWatchScrew_Template copy];
    tRightBridgeScrew3.center=NSMakePoint(tCenter.x+_ratio*38, tCenter.y-_ratio*110);
    tRightBridgeScrew3.rotation=-35;
    
    [_parts addObject:tRightBridgeScrew3];
    
    
    CUIWatchGear * tGearGray30=tGear0_30;
    
    tGearGray30.center=NSMakePoint(tCenter.x+_ratio*112, tCenter.y);
    tGearGray30.rotation=6;
    tGearGray30.ticker = ^CGFloat{
        
        return -0.5;
    };
    
    [_parts addObject:tGearGray30];
    
    CUIWatchScrew * tRightBridgeScrew4=[tWatchScrew_Template copy];
    tRightBridgeScrew4.center=NSMakePoint(tCenter.x+_ratio*112, tCenter.y);
    tRightBridgeScrew4.rotation=-35;
    
    [_parts addObject:tRightBridgeScrew4];
    
    
    CUIWatchAxis * tAxix2=[CUIWatchAxis new];
    tAxix2.center=NSMakePoint(tCenter.x, tCenter.y);
    tAxix2.radius=_ratio*6.0;
    
    [_parts addObject:tAxix2];
    
    
    
    
    
    
    
    
    
    _timer=[NSTimer scheduledTimerWithTimeInterval:0.05 repeats:YES block:^(NSTimer * _Nonnull timer) {
       
        /*_rotation+=2.0;
        
        if (_rotation>360.0)
            _rotation-=360.0;
        */
        [self setNeedsDisplay:YES];
        
    }];
    
    //self.renderingMode=CUIWatchRenderingModeWireframe;
    
}

- (NSBezierPath *)roundedTrianglePathCenteredAt:(NSPoint)inCenter withBaseLength:(CGFloat)inLength radius:(CGFloat)inRadius
{
    CGFloat width=inLength,height=0.866025*inLength;
    CGFloat tThirdOfHeight=height/3;
    
    CGPoint point1=CGPointMake(inCenter.x-width / 2, inCenter.y-tThirdOfHeight);
    CGPoint point2=CGPointMake(inCenter.x, inCenter.y+2*tThirdOfHeight);
    CGPoint point3=CGPointMake(inCenter.x+width / 2, inCenter.y-tThirdOfHeight);
    
    CGMutablePathRef tMutablePathRef=CGPathCreateMutable();
    
    CGPathMoveToPoint(tMutablePathRef, NULL, inCenter.x, inCenter.y-tThirdOfHeight);
    CGPathAddArcToPoint(tMutablePathRef,NULL, point1.x,point1.y,point2.x,point2.y,inRadius);
    CGPathAddArcToPoint(tMutablePathRef,NULL, point2.x,point2.y,point3.x,point3.y,inRadius);
    CGPathAddArcToPoint(tMutablePathRef,NULL, point3.x,point3.y,point1.x,point1.y,inRadius);
    
    CGPathCloseSubpath(tMutablePathRef);
    
    return [NSBezierPath JNS_bezierPathWithCGPath:tMutablePathRef];
}

#pragma mark -

- (void)setRenderingMode:(CUIWatchRenderingMode)inRenderingMode
{
    _renderingMode=inRenderingMode;
    
    for(CUIWatchPart * tPart in _parts)
        tPart.renderingMode=inRenderingMode;
    
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSRect tBounds=self.bounds;
    
    CGFloat tIconSize=NSWidth(tBounds);
    
    /*[[NSColor windowBackgroundColor] set];
    
    NSRectFill(tBounds);
    
    [[NSColor lightGrayColor] set];
    
    NSFrameRect(tBounds);*/
    
    NSShadow *shadow=nil;
    
    NSPoint tCenter=NSMakePoint(NSMidX(tBounds),(0.41*NSHeight(tBounds)));
    
    NSBezierPath * tBezierPath=[self roundedTrianglePathCenteredAt:tCenter withBaseLength:_ratio*1096 radius:_ratio*100];
    tBezierPath.lineWidth=1.0;
    
    if (self.renderingMode==CUIWatchRenderingModeWireframe)
    {
        [[NSColor textColor] setStroke];
        [tBezierPath stroke];
    }
    else
    {
        shadow = [NSShadow new];
        shadow.shadowOffset = NSMakeSize(0, -10*_ratio);
        shadow.shadowBlurRadius = _ratio*20;
        shadow.shadowColor = [NSColor colorWithWhite:0 alpha:0.2];
        
        [NSGraphicsContext saveGraphicsState];
        
        [shadow set];
        [[NSColor whiteColor] set];
        
        [tBezierPath fill];
        
        [NSGraphicsContext restoreGraphicsState];
    
        [[NSColor colorWithWhite:0.0 alpha:0.1] set];
    
        [tBezierPath stroke];
    }
    
    tBezierPath=[self roundedTrianglePathCenteredAt:tCenter withBaseLength:_ratio*940 radius:_ratio*54];
    
    
    NSGradient * tGradient=[[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0.35 alpha:1.0]
                                                         endingColor:[NSColor colorWithDeviceWhite:0.30 alpha:1.0]];
    
    
    if (self.renderingMode==CUIWatchRenderingModeWireframe)
    {
        [[NSColor textColor] setStroke];
        [tBezierPath stroke];
    }
    else
    {
        [tGradient drawInBezierPath:tBezierPath angle:90];
    }
    
    /*[[NSColor blackColor] set];
    
    [tBezierPath fill];*/
    
    /*tBezierPath.lineWidth=_ratio*12.0;
    
    [[NSColor colorWithWhite:0.35 alpha:0.9] set];
    
    [tBezierPath stroke];*/
    
    
    
    //[tBezierPath fill];
    
    /*shadow = [NSShadow new];
    shadow.shadowOffset = NSMakeSize(0, 10);
    shadow.shadowBlurRadius =40;
    shadow.shadowColor = [NSColor redColor];
    
    [NSGraphicsContext saveGraphicsState];
    
    [shadow set];
    
    */
    
    [NSGraphicsContext saveGraphicsState];
    
    tBezierPath=[self roundedTrianglePathCenteredAt:tCenter withBaseLength:_ratio*920 radius:_ratio*54];
    
    [tBezierPath setClip];
    
    for(CUIWatchPart * tPart in _parts)
    {
        if ([tPart isKindOfClass:CUIWatchGear.class]==YES)
        {
            [(CUIWatchGear *)tPart tick];
        }
        
        [tPart draw];
    }
    
    [NSGraphicsContext restoreGraphicsState];
    
    NSBezierPath * tClipPath=[NSBezierPath bezierPath];
    
    [tClipPath moveToPoint:NSMakePoint(NSMinX(tBounds),NSMinY(tBounds))];
    [tClipPath lineToPoint:NSMakePoint(NSMaxX(tBounds),NSMinY(tBounds))];
    [tClipPath lineToPoint:NSMakePoint(NSMaxX(tBounds),0.65*NSMaxY(tBounds))];
    [tClipPath lineToPoint:NSMakePoint(NSMinX(tBounds),0.35*NSMaxY(tBounds))];
    [tClipPath closePath];
                                       
    
    [NSGraphicsContext saveGraphicsState];
    
    [tClipPath addClip];
    
    tBezierPath=[self roundedTrianglePathCenteredAt:tCenter withBaseLength:_ratio*940 radius:_ratio*54];
    
    if (self.renderingMode==CUIWatchRenderingModeWireframe)
    {
        [NSGraphicsContext restoreGraphicsState];
        
        tBezierPath.lineWidth=_ratio*12.0;
        
        [[NSColor textColor] setStroke];
        
        [tBezierPath stroke];
        
        tBezierPath.lineWidth=_ratio*1.0;
        
        [[NSColor textColor] setStroke];
        
        [tBezierPath stroke];
    }
    else
    {
        tGradient=[[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceRed:254/255.0 green:227.0/255.0 blue:101.0/255.0 alpha:1.0]
                                                         endingColor:[NSColor colorWithDeviceRed:255.0/255.0 green:212.0/255.0 blue:59.0/255.0 alpha:1.0]];

    
        [tGradient drawInBezierPath:tBezierPath angle:270];

        [NSGraphicsContext restoreGraphicsState];
        
        
        tBezierPath.lineWidth=_ratio*12.0;
        
        [[NSColor colorWithWhite:0.35 alpha:0.9] setStroke];
        
        [tBezierPath stroke];
        
        tBezierPath.lineWidth=_ratio*1.0;
        
        [[NSColor colorWithWhite:0.0 alpha:0.1] setStroke];
        
        [tBezierPath stroke];
    }
    
    // !
    
    tBezierPath=[NSBezierPath bezierPath];
    
    [tBezierPath moveToPoint:NSMakePoint(tCenter.x-_ratio*29,tCenter.y+_ratio*83)];
    [tBezierPath lineToPoint:NSMakePoint(tCenter.x-_ratio*15,tCenter.y-_ratio*21)];
    [tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(tCenter.x,tCenter.y-_ratio*20)
                                            radius:_ratio*15
                                        startAngle:192
                                          endAngle:348
                                         clockwise:NO];
    
    [tBezierPath lineToPoint:NSMakePoint(tCenter.x+_ratio*31,tCenter.y+_ratio*101)];
    
    [tBezierPath closePath];
    
    if (self.renderingMode==CUIWatchRenderingModeWireframe)
    {
        [[NSColor textColor] setStroke];
        
        [tBezierPath stroke];
    }
    else
    {
        shadow = [NSShadow new];
        shadow.shadowOffset = NSMakeSize(0, -5*_ratio);
        shadow.shadowBlurRadius =_ratio*5;
        shadow.shadowColor = [NSColor colorWithDeviceWhite:0.2 alpha:0.6];
        
        [NSGraphicsContext saveGraphicsState];
        
        [shadow set];
        
        [[NSColor colorWithDeviceWhite:0.35 alpha:1.0] setFill];
        
        [tBezierPath fill];
        
        [NSGraphicsContext restoreGraphicsState];
        
        [[NSColor blackColor] set];
        
        [tBezierPath stroke];
        
        tGradient=[[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0.40 alpha:1.0]
                                                endingColor:[NSColor colorWithDeviceWhite:0.20 alpha:1.0]];
        
        
        [tGradient drawInBezierPath:tBezierPath angle:270];
    }
    
    CGFloat tDiskRadius=_ratio*51.0;
    
    
    
    tBezierPath=[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(tCenter.x-tDiskRadius,tCenter.y-tDiskRadius-_ratio*130,2*tDiskRadius,2*tDiskRadius)];
    
    if (self.renderingMode==CUIWatchRenderingModeWireframe)
    {
        [[NSColor textColor] setStroke];
        
        [tBezierPath stroke];
    }
    else
    {
        [NSGraphicsContext saveGraphicsState];
        
        [shadow set];
        
        [[NSColor colorWithDeviceWhite:0.35 alpha:1.0] setFill];
        
        [tBezierPath fill];
        
        [NSGraphicsContext restoreGraphicsState];
        
        tGradient=[[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0.35 alpha:1.0]
                                                endingColor:[NSColor colorWithDeviceWhite:0.15 alpha:1.0]];
        
        
        [tGradient drawInBezierPath:tBezierPath angle:270];
        
        [[NSColor colorWithDeviceWhite:0.2 alpha:0.8] setFill];
        
        [tBezierPath fill];
    }
    
    // Universal Key
    
    if (tIconSize>16.0)
    {
        NSBezierPath * tHandlePath=[NSBezierPath bezierPath];
        
        [tHandlePath moveToPoint:NSMakePoint(0, 20)];
        [tHandlePath lineToPoint:NSMakePoint(711,20)];
        [tHandlePath appendBezierPathWithArcWithCenter:NSMakePoint(711, 0)
                                                radius:20
                                            startAngle:90 endAngle:0 clockwise:YES];
        
        [tHandlePath lineToPoint:NSMakePoint(731,-120)];
        
        [tHandlePath appendBezierPathWithArcWithCenter:NSMakePoint(736, -120)
                                                radius:5
                                            startAngle:180 endAngle:270 clockwise:NO];
        
        [tHandlePath lineToPoint:NSMakePoint(786,-125)];
        
        [tHandlePath appendBezierPathWithArcWithCenter:NSMakePoint(786, -120)
                                                radius:5
                                            startAngle:270 endAngle:0 clockwise:NO];
        
        [tHandlePath lineToPoint:NSMakePoint(791,135)];
        
        [tHandlePath appendBezierPathWithArcWithCenter:NSMakePoint(786, 135)
                                                radius:5
                                            startAngle:0 endAngle:90 clockwise:NO];
        
        [tHandlePath lineToPoint:NSMakePoint(736,140)];
        
        [tHandlePath appendBezierPathWithArcWithCenter:NSMakePoint(736, 135)
                                                radius:5
                                            startAngle:90 endAngle:180 clockwise:NO];
        
        
        [tHandlePath lineToPoint:NSMakePoint(731,30)];
        
        [tHandlePath appendBezierPathWithArcWithCenter:NSMakePoint(728, 30)
                                                radius:3
                                            startAngle:0 endAngle:225 clockwise:YES];
        
        [tHandlePath lineToPoint:NSMakePoint(711,40)];
        
        [tHandlePath lineToPoint:NSMakePoint(711,140)];
        
        [tHandlePath appendBezierPathWithArcWithCenter:NSMakePoint(731, 140)
                                                radius:20
                                            startAngle:180 endAngle:90 clockwise:YES];
        
        [tHandlePath lineToPoint:NSMakePoint(791,160)];
        
        [tHandlePath appendBezierPathWithArcWithCenter:NSMakePoint(791, 140)
                                                radius:20
                                            startAngle:90 endAngle:0 clockwise:YES];
        
        [tHandlePath lineToPoint:NSMakePoint(811,-125)];
        
        [tHandlePath appendBezierPathWithArcWithCenter:NSMakePoint(791, -125)
                                                radius:20
                                            startAngle:0 endAngle:270 clockwise:YES];
        
        [tHandlePath lineToPoint:NSMakePoint(731,-145)];
        
        [tHandlePath appendBezierPathWithArcWithCenter:NSMakePoint(731, -125)
                                                radius:20
                                            startAngle:270 endAngle:180 clockwise:YES];
        
        [tHandlePath lineToPoint:NSMakePoint(711,-5)];
        
        [tHandlePath appendBezierPathWithArcWithCenter:NSMakePoint(706, -5)
                                                radius:5
                                            startAngle:0 endAngle:90 clockwise:NO];
        
        [tHandlePath lineToPoint:NSMakePoint(0,0)];
        
        [tHandlePath closePath];
        
        NSAffineTransform * tAffineTransform=[NSAffineTransform transform];
        
        
        
        
        [tAffineTransform scaleBy:_ratio];
        [tAffineTransform translateXBy:180 yBy:352];
        [tAffineTransform rotateByDegrees:17.0];
        
        [tHandlePath transformUsingAffineTransform:tAffineTransform];
        
        if (self.renderingMode==CUIWatchRenderingModeWireframe)
        {
            [[NSColor textColor] set];
            
            [tHandlePath stroke];
        }
        else
        {
        
            shadow = [NSShadow new];
            shadow.shadowOffset = NSMakeSize(0, -8*_ratio);
            shadow.shadowBlurRadius =_ratio*10;
            shadow.shadowColor = [NSColor colorWithDeviceWhite:0.3 alpha:0.65];
            
            [NSGraphicsContext saveGraphicsState];
            
            [shadow set];
            
            [[NSColor colorWithDeviceWhite:0.5 alpha:1.0] set];
            
            [tHandlePath fill];
            
            [NSGraphicsContext restoreGraphicsState];
            
            /*tGradient=[[NSGradient alloc] initWithColorsAndLocations:[NSColor colorWithDeviceWhite:0.55 alpha:0.5],0.0,
                       [NSColor colorWithDeviceWhite:0.6 alpha:1.0],0.45,
                       [NSColor colorWithDeviceWhite:0.90 alpha:1.0],0.5,
                       [NSColor colorWithDeviceWhite:0.6 alpha:1.0],0.55,
                       [NSColor colorWithDeviceWhite:0.75 alpha:1.0],1.0,nil];*/
            
            tHandlePath.lineWidth=1.0;
            [[NSColor colorWithDeviceWhite:0.40 alpha:1.0] set];
            
            [tHandlePath stroke];
            
            
             //[[NSColor colorWithDeviceWhite:0.4 alpha:1.0] setFill];
            
             //[tHandlePath fill];
            
            
            
            //[tGradient drawInBezierPath:tHandlePath angle:286.5];
        }
        
            // Metal effect
        
        if (self.renderingMode!=CUIWatchRenderingModeWireframe)
        {
            [NSGraphicsContext saveGraphicsState];
            
            [tHandlePath addClip];
            
            NSBezierPath * tWhiteGlare=[NSBezierPath bezierPath];
            
            [tWhiteGlare moveToPoint:NSMakePoint(2, 10)];
            [tWhiteGlare lineToPoint:NSMakePoint(711,10)];
            [tWhiteGlare appendBezierPathWithArcWithCenter:NSMakePoint(711, 0)
                                                    radius:10
                                                startAngle:90 endAngle:0 clockwise:YES];
            
            [tWhiteGlare lineToPoint:NSMakePoint(721,-125)];
            
            [tWhiteGlare appendBezierPathWithArcWithCenter:NSMakePoint(731, -125)
                                                    radius:10
                                                startAngle:180 endAngle:270 clockwise:NO];
            
            [tWhiteGlare lineToPoint:NSMakePoint(791,-135)];
            
            [tWhiteGlare appendBezierPathWithArcWithCenter:NSMakePoint(791, -125)
                                                    radius:10
                                                startAngle:270 endAngle:0 clockwise:NO];
            
            [tWhiteGlare lineToPoint:NSMakePoint(801,140)];
            
            [tWhiteGlare appendBezierPathWithArcWithCenter:NSMakePoint(791, 140)
                                                    radius:10
                                                startAngle:0 endAngle:90 clockwise:NO];
            
            [tWhiteGlare lineToPoint:NSMakePoint(731,150)];
            
            [tWhiteGlare appendBezierPathWithArcWithCenter:NSMakePoint(731, 140)
                                                    radius:10
                                                startAngle:90 endAngle:180 clockwise:NO];
            
            
            [tWhiteGlare lineToPoint:NSMakePoint(721,25)];
            
            
            [tWhiteGlare transformUsingAffineTransform:tAffineTransform];
            
            [tWhiteGlare setLineWidth:18*_ratio];
            
            [[NSColor colorWithDeviceWhite:0.56 alpha:1.0] set];
            
            [tWhiteGlare stroke];
            
            [tWhiteGlare setLineWidth:16*_ratio];
            
            [[NSColor colorWithDeviceWhite:0.60 alpha:1.0] set];
            
            [tWhiteGlare stroke];
            
            [tWhiteGlare setLineWidth:14*_ratio];
            
            [[NSColor colorWithDeviceWhite:0.65 alpha:1.0] set];
            
            [tWhiteGlare stroke];
            
            [tWhiteGlare setLineWidth:11*_ratio];
            
            [[NSColor colorWithDeviceWhite:0.72 alpha:1.0] set];
            
            [tWhiteGlare stroke];
            
            [tWhiteGlare setLineWidth:5*_ratio];
            
            [[NSColor colorWithDeviceWhite:0.81 alpha:1.0] set];
            
            [tWhiteGlare stroke];
            
            [tWhiteGlare setLineWidth:3*_ratio];
            
            [[NSColor colorWithDeviceWhite:0.9 alpha:1.0] set];
            
            [tWhiteGlare stroke];
            
            [tWhiteGlare setLineWidth:1];
            
            [[NSColor colorWithDeviceWhite:1.0 alpha:1.0] set];
            
            [tWhiteGlare stroke];
            
            [NSGraphicsContext restoreGraphicsState];
            
                // Encoche
            
            tBezierPath=[NSBezierPath bezierPath];
            
            [tBezierPath moveToPoint:NSMakePoint(0+_ratio*590,10)];
            
            [tBezierPath lineToPoint:NSMakePoint(0+_ratio*605,10)];
            
            [tBezierPath transformUsingAffineTransform:tAffineTransform];
            
            tBezierPath.lineWidth=4.0*_ratio;
            
            [[NSColor colorWithDeviceWhite:0.0 alpha:0.55] setStroke];
            
            [tBezierPath stroke];
        }
            
    }
    
    // Curl
    
    tBezierPath=[NSBezierPath bezierPath];
    
    [tBezierPath moveToPoint:NSMakePoint(tCenter.x-_ratio*310,tCenter.y+_ratio*1)];
    
    [tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(tCenter.x-_ratio*455,tCenter.y-_ratio*204)
                                            radius:250*_ratio
                                        startAngle:55
                                          endAngle:30.5
                                         clockwise:YES];
    
    [tBezierPath lineToPoint:NSMakePoint(tCenter.x+_ratio*240,tCenter.y+_ratio*65)];
    [tBezierPath lineToPoint:NSMakePoint(tCenter.x+_ratio*220,tCenter.y+_ratio*160)];
    [tBezierPath closePath];
    
    if (self.renderingMode==CUIWatchRenderingModeWireframe)
    {
        [[NSColor textColor] setStroke];
        [tBezierPath stroke];
    }
    else
    {
        shadow = [NSShadow new];
        shadow.shadowOffset = NSMakeSize(0, 0);
        shadow.shadowBlurRadius =_ratio*10;
        shadow.shadowColor = [NSColor colorWithDeviceWhite:0.2 alpha:1.0];
        
        [NSGraphicsContext saveGraphicsState];
        
        [shadow set];
        
        
        
        
        
        [[NSColor colorWithDeviceWhite:0.5 alpha:1.0] setFill];
        
        [tBezierPath fill];
        
        [NSGraphicsContext restoreGraphicsState];
        
        tGradient=[[NSGradient alloc] initWithColorsAndLocations:[NSColor colorWithDeviceWhite:0.25 alpha:1.0],0.0,
                   [NSColor colorWithDeviceWhite:0.5 alpha:1.0],0.25,
                   [NSColor colorWithDeviceWhite:0.90 alpha:1.0],0.5,
                   [NSColor colorWithDeviceWhite:0.5 alpha:1.0],0.75,
                   [NSColor colorWithDeviceRed:67/255.0 green:66.0/255.0 blue:11.0/255.0 alpha:1.0],1.0,nil];
        
        
        
        [tGradient drawInBezierPath:tBezierPath angle:287];
        
        [[NSColor colorWithDeviceWhite:0.0 alpha:0.2] setStroke];
        
        [tBezierPath stroke];
        
        
        [[NSColor colorWithDeviceWhite:0.2 alpha:0.08] setStroke];
    }
    
    tBezierPath=[NSBezierPath bezierPath];
    
    [tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(tCenter.x-_ratio*450,tCenter.y-_ratio*202)
                                            radius:250*_ratio
                                        startAngle:54
                                          endAngle:30.5
                                         clockwise:YES];
    
    [tBezierPath stroke];
    
    if (tIconSize>128.0)
    {
        [NSBezierPath strokeLineFromPoint:NSMakePoint(tCenter.x-_ratio*28,tCenter.y+_ratio*85) toPoint:NSMakePoint(tCenter.x-_ratio*3,tCenter.y-_ratio*8)];
    
        [NSBezierPath strokeLineFromPoint:NSMakePoint(tCenter.x+_ratio*28,tCenter.y+_ratio*101) toPoint:NSMakePoint(tCenter.x+_ratio*62,tCenter.y+_ratio*12)];
    
        [NSBezierPath strokeLineFromPoint:NSMakePoint(tCenter.x+_ratio*233,tCenter.y+_ratio*64) toPoint:NSMakePoint(tCenter.x+_ratio*215,tCenter.y+_ratio*157)];
    }
}

- (NSData *)PNGData
{
    NSBitmapImageRep * tBitmapImageRep=[self bitmapImageRepForCachingDisplayInRect:self.bounds];
    
    [self cacheDisplayInRect:self.bounds toBitmapImageRep:tBitmapImageRep];
    
    NSData * tData = [tBitmapImageRep representationUsingType:NSBitmapImageFileTypePNG
                                                   properties:@{}];
    
    return tData;
}

@end
