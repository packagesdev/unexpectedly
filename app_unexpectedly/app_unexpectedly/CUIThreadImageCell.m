/*
 Copyright (c) 2020-2022, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIThreadImageCell.h"

@implementation CUIThreadImageCell

+ (NSImage *)crashedThreadImage
{
    static NSImage * sCrahsedThreadImage=nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sCrahsedThreadImage=[[NSImage imageNamed:@"crashedThread_Template"] copy];
        
        [sCrahsedThreadImage lockFocus];
        
        [[NSColor colorWithDeviceRed:203.0/255.0 green:49.0/255.0 blue:34.0/255.0 alpha:1.0 ] set];
        
        NSRectFillUsingOperation(NSMakeRect(0,0,20,23), NSCompositingOperationSourceIn);
        
        [sCrahsedThreadImage unlockFocus];
        
        sCrahsedThreadImage.template=NO;
        
    });
    
    return sCrahsedThreadImage;
}

- (instancetype)initWithCoder:(NSCoder *)inCoder
{
    self=[super initWithCoder:inCoder];
    
    if (self!=nil)
    {
        self.image=[NSImage imageNamed:@"thread_Template"];
    }
    
    return self;
}

#pragma mark -

- (void)setCrashed:(BOOL)inCrashed
{
    if (_crashed==inCrashed)
        return;
    
    _crashed=inCrashed;
    
    [self.controlView setNeedsDisplay:YES];
}

- (NSImage *)image
{
    if (self.isCrashed==NO)
        return [super image];
    
    if (self.backgroundStyle==NSBackgroundStyleEmphasized || [self.controlView WB_isEffectiveAppearanceDarkAqua]==YES)
        return [NSImage imageNamed:@"crashedThread_Template"];

    return [CUIThreadImageCell crashedThreadImage];
}

@end
