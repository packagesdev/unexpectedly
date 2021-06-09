/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIWatchGear.h"


@implementation CUIWatchGear

- (CGFloat)rootRadius
{
    return self.outsideRadius-self.wholeDepth;
}

- (CGFloat)dedendum
{
    return self.wholeDepth-self.addendum;
}

- (NSBezierPath *)bezierPath
{
#define RADTODEG(a) (((a)*180.0)/M_PI)
#define DEGTORAD(a) (((a)*M_PI)/180.0)
    
    CGFloat tNumberOfTeeth=self.numberOfTeeth;
    CGFloat tRotationRad=DEGTORAD(self.rotation);
    CGFloat tOutsideRadius=self.outsideRadius;
    CGFloat tToothWidth=self.circularToothThickness;
    CGFloat tWholeDepth=self.wholeDepth;
    
    NSRect tOuterRect=NSMakeRect(self.center.x-tOutsideRadius,self.center.y-tOutsideRadius,2*tOutsideRadius,2*tOutsideRadius);
    
    NSBezierPath * tBezierPath=nil;
    
    if (self.numberOfTeeth==0)
    {
        tBezierPath=[NSBezierPath bezierPathWithOvalInRect:tOuterRect];
    }
    else
    {
        if (self.toothTop>self.circularToothThickness)
            self.toothTop=self.circularToothThickness;
        
        if (self.toothTop<0)
            self.toothTop=0;
        
        CGFloat tRootRadius=self.rootRadius;
        
        CGFloat tBottomToothAngle=2.0*asin(tToothWidth*0.5/(tOutsideRadius-tWholeDepth));
        
        CGFloat tTopToothAngle=2.0*asin((tToothWidth*0.5-self.toothTop*0.5)/(tOutsideRadius));
        
        CGFloat tTopInterTeethAngle=(2.0*M_PI-tNumberOfTeeth*tTopToothAngle)/tNumberOfTeeth;
        
        CGFloat tBottomInterTeethAngle=(2.0*M_PI-tNumberOfTeeth*tBottomToothAngle)/tNumberOfTeeth;
        
        
        
        CGFloat tInvoluteAngle=atan(tToothWidth*0.5/(tOutsideRadius-self.addendum));
        
        CGFloat tInvoluteInterTeethAngle=(2.0*M_PI-tNumberOfTeeth*2.0*tInvoluteAngle)/tNumberOfTeeth;
        
        CGFloat tInvoluteRadius=sqrt((tOutsideRadius-self.addendum)*(tOutsideRadius-self.addendum)-(tToothWidth*tToothWidth*0.25));
        
        tBezierPath=[NSBezierPath bezierPath];
        
        
        
        
        
        [tBezierPath moveToPoint:NSMakePoint(self.center.x+tOutsideRadius*cos(tRotationRad-tTopToothAngle*0.5),self.center.y+tOutsideRadius*sin(tRotationRad-tTopToothAngle*0.5))];
        
        for(NSUInteger tIndex=0;tIndex<tNumberOfTeeth;tIndex++)
        {
            [tBezierPath lineToPoint:NSMakePoint(self.center.x+tOutsideRadius*cos(tRotationRad+tTopToothAngle*0.5),self.center.y+tOutsideRadius*sin(tRotationRad+tTopToothAngle*0.5))];
            
            [tBezierPath lineToPoint:NSMakePoint(self.center.x+tInvoluteRadius*cos(tRotationRad+tInvoluteAngle),self.center.y+tInvoluteRadius*sin(tRotationRad+tInvoluteAngle))];
            
            //break;
            //[tBezierPath lineToPoint:NSMakePoint(self.center.x+tRootRadius*cos(tRotationRad+tBottomToothAngle*0.5),self.center.y+tRootRadius*sin(tRotationRad+tBottomToothAngle*0.5))];
            
            [tBezierPath appendBezierPathWithArcWithCenter:self.center
                                                    radius:tRootRadius
                                                startAngle:RADTODEG(tRotationRad+tBottomToothAngle*0.5)
                                                  endAngle:RADTODEG(tRotationRad+tBottomToothAngle*0.5+tBottomInterTeethAngle)];
            
            
            [tBezierPath lineToPoint:NSMakePoint(self.center.x+tInvoluteRadius*cos(tRotationRad+tInvoluteAngle+tInvoluteInterTeethAngle),self.center.y+tInvoluteRadius*sin(tRotationRad+tInvoluteAngle+tInvoluteInterTeethAngle))];
            
            
            [tBezierPath lineToPoint:NSMakePoint(self.center.x+tOutsideRadius*cos(tRotationRad+tTopInterTeethAngle+tTopToothAngle*0.5),self.center.y+tOutsideRadius*sin(tRotationRad+tTopInterTeethAngle+tTopToothAngle*0.5))];
            
            tRotationRad+=(tTopToothAngle+tTopInterTeethAngle);
        }
        
        
        
        /**/
        
        
    }
    
    /*[tBezierPath moveToPoint:NSMakePoint(self.center.x+tOutsideRadius*cos(tRotationRad-tTopToothAngle*0.5),self.center.y+tOutsideRadius*sin(tRotationRad-tTopToothAngle*0.5))];
     
     for(NSUInteger tIndex=0;tIndex<tNumberOfTeeth;tIndex++)
     {
     //[tBezierPath lineToPoint:NSMakePoint(self.center.x+tOutsideRadius*cos(tRotationRad-tTopToothAngle*0.5),self.center.y+tOutsideRadius*sin(tRotationRad-tTopToothAngle*0.5))];
     
     [tBezierPath lineToPoint:NSMakePoint(self.center.x+tOutsideRadius*cos(tRotationRad+tTopToothAngle*0.5),self.center.y+tOutsideRadius*sin(tRotationRad+tTopToothAngle*0.5))];
     
     [tBezierPath lineToPoint:NSMakePoint(self.center.x+tRootRadius*cos(tRotationRad+tBottomToothAngle*0.5),self.center.y+tRootRadius*sin(tRotationRad+tBottomToothAngle*0.5))];
     
     [tBezierPath appendBezierPathWithArcWithCenter:self.center
     radius:tRootRadius
     startAngle:RADTODEG(tRotationRad+tBottomToothAngle*0.5)
     endAngle:RADTODEG(tRotationRad+tBottomToothAngle*0.5+tBottomInterTeethAngle)];
     
     [tBezierPath lineToPoint:NSMakePoint(self.center.x+tOutsideRadius*cos(tRotationRad+tTopInterTeethAngle+tTopToothAngle*0.5),self.center.y+tOutsideRadius*sin(tRotationRad+tTopInterTeethAngle+tTopToothAngle*0.5))];
     
     tRotationRad+=(tTopToothAngle+tTopInterTeethAngle);
     }*/
    
    /*[[NSColor redColor] set];
     
     [tBezierPath fill];
     
     return nil;*/
    
    [tBezierPath closePath];
    
    NSRect tInnerRect=NSMakeRect(self.center.x-self.axisRadius,self.center.y-self.axisRadius,2*self.axisRadius,2*self.axisRadius);
    
    NSBezierPath * tBezierPath2=[NSBezierPath bezierPathWithOvalInRect:tInnerRect];
    
    
    NSUInteger tNumberOfHoles=self.innerBranchesCount;
    CGFloat tBranchWidth=self.innerBranchThickness;
    
    CGFloat tRadius1=self.innerRadius;
    CGFloat tRadius2=tOutsideRadius-(((tNumberOfTeeth==0) ? 0.0 : tWholeDepth)+tBranchWidth);
    
    CGFloat tAngle1=asin(tBranchWidth/(2.0*tRadius1));
    CGFloat tAngle2=asin(tBranchWidth/(2.0*tRadius2));
    
    CGFloat tHoleAngle1=(2*M_PI-2.0*tNumberOfHoles*tAngle1)/tNumberOfHoles;
    CGFloat tHoleAngle2=(2*M_PI-2.0*tNumberOfHoles*tAngle2)/tNumberOfHoles;
    
    for(NSUInteger tIndex=0;tIndex<tNumberOfHoles;tIndex++)
    {
        NSBezierPath * tHolePath=[NSBezierPath bezierPath];
        
        [tHolePath moveToPoint:NSMakePoint(self.center.x+tRadius1*cos(tRotationRad+tAngle1),self.center.y+tRadius1*sin(tRotationRad+tAngle1))];
        [tHolePath lineToPoint:NSMakePoint(self.center.x+tRadius2*cos(tRotationRad+tAngle2),self.center.y+tRadius2*sin(tRotationRad+tAngle2))];
        
        [tHolePath appendBezierPathWithArcWithCenter:self.center
                                              radius:tRadius2
                                          startAngle:RADTODEG(tRotationRad+tAngle2)
                                            endAngle:RADTODEG(tRotationRad+tAngle2+tHoleAngle2)];
        
        [tHolePath lineToPoint:NSMakePoint(self.center.x+tRadius1*cos(tRotationRad+tAngle1+tHoleAngle1),self.center.y+tRadius1*sin(tRotationRad+tAngle1+tHoleAngle1))];
        [tHolePath appendBezierPathWithArcWithCenter:self.center
                                              radius:tRadius1
                                          startAngle:RADTODEG(tRotationRad+tAngle1+tHoleAngle1)
                                            endAngle:RADTODEG(tRotationRad+tAngle1)
                                           clockwise:YES];
        
        [tHolePath closePath];
        
        tRotationRad+=(2*M_PI)/tNumberOfHoles;
        
        
        [tBezierPath2 appendBezierPath:tHolePath];
    }
    
    [tBezierPath appendBezierPath:tBezierPath2];
    
    //[tBezierPath addClip];
    tBezierPath.windingRule=NSWindingRuleEvenOdd;
    
    
    return tBezierPath;
}

#pragma mark -

- (void)draw
{
    NSBezierPath * tBezierPath=self.bezierPath;
    
    if (tBezierPath==nil)
        return;
    
    if (self.renderingMode==CUIWatchRenderingModeWireframe)
    {
        [[NSColor blackColor] setStroke];
        
        [tBezierPath stroke];
        
        if (self.bezelRadius>0.1)
        {
            tBezierPath=[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(self.center.x-self.bezelRadius,self.center.y-self.bezelRadius,2.0*self.bezelRadius,2.0*self.bezelRadius)];
        
            [tBezierPath stroke];
        }
        
        return;
    }
    
    [self.gradient drawInBezierPath:tBezierPath angle:270];
    
    tBezierPath.lineWidth=1.0;
    
    if (self.borderColor!=nil)
    {
        [self.borderColor setStroke];
        
        [tBezierPath stroke];
    }
    
    if (self.bezelRadius>0.1)
    {
        [[NSColor colorWithDeviceWhite:0.1 alpha:0.2] setStroke];
        
        tBezierPath=[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(self.center.x-self.bezelRadius,self.center.y-self.bezelRadius,2.0*self.bezelRadius,2.0*self.bezelRadius)];
    
        [tBezierPath stroke];
    }
}

#pragma mark - NSCopying

- (id)copyWithZone:(nullable NSZone *)zone
{
    CUIWatchGear * nGear=[CUIWatchGear new];
    
    nGear.center=self.center;
    
    nGear.outsideRadius=self.outsideRadius;
    
    nGear.axisRadius=self.axisRadius;
    
    nGear.innerRadius=self.innerRadius;
    
    nGear.bezelRadius=self.bezelRadius;
    
    nGear.innerBranchesCount=self.innerBranchesCount;
    
    nGear.innerBranchThickness=self.innerBranchThickness;
    
    nGear.numberOfTeeth=self.numberOfTeeth;
    
    nGear.circularToothThickness=self.circularToothThickness;
    nGear.toothTop=self.toothTop;
    
    nGear.wholeDepth=self.wholeDepth;
    nGear.addendum=self.addendum;
    
    
    
    nGear.rotation=self.rotation;
    
    nGear.borderColor=self.borderColor;
    
    nGear.gradient=self.gradient;
    
    nGear.ticker=self.ticker;
    
    return nGear;
}

#pragma mark -

- (void)tick
{
    if (self.ticker==nil)
    {
        self.rotation+=1.0;
        return;
    }
    
    self.rotation+=self.ticker();
}

@end
