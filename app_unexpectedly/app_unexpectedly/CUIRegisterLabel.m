/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIRegisterLabel.h"

NSString * const CUIRegisterLabelViewAsValueDidChangeNotification=@"CUIRegisterLabelViewAsValueDidChangeNotification";

@interface CUIRegisterLabel ()
{
    IBOutlet NSTextField * _textField;
    
    IBOutlet NSPopUpButton * _popUpButton;
}

- (IBAction)switchDisplayFormat:(id)sender;

@end

@implementation CUIRegisterLabel

- (instancetype)initWithFrame:(NSRect)inFrame
{
    self=[super initWithFrame:inFrame];
    
    if (self!=nil)
    {
        _viewValueAs=CUIRegisterViewValueAsHex;
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)inCoder
{
    self=[super initWithCoder:inCoder];
    
    if (self!=nil)
    {
        _viewValueAs=CUIRegisterViewValueAsHex;
    }
    
    return self;
}

- (void)awakeFromNib
{
    [_popUpButton selectItemWithTag:self.viewValueAs];
}

#pragma mark -

- (void)setRegisterValue:(NSUInteger)inRegisterValue
{
    _registerValue=inRegisterValue;
    
    [self refreshUI];
}

- (void)setViewValueAs:(CUIRegisterViewValueAsType)inViewAs
{
    _viewValueAs=inViewAs;
    
    [self refreshUI];
}

#pragma mark -

- (void)refreshUI
{
    static NSArray<NSString *> * sFormats=nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sFormats=@[
                   @"N/A", // CUIRegisterViewValueAsBinary
                   @"N/A",  // CUIRegisterViewValueAsBoolean
                   @"%g",  // CUIRegisterViewValueAsFloat
                   @"%ld", // CUIRegisterViewValueAsDecimal
                   @"0x%016lx", // CUIRegisterViewValueAsHex
                   @"0%o", // CUIRegisterViewAValuesOctal
                   @"%lu", // CUIRegisterViewValueAsUnsignedDecimal
                   ];
        
    });
    
    switch(self.viewValueAs)
    {
        case CUIRegisterViewValueAsBinary:
            
            break;
            
        case CUIRegisterViewValueAsBoolean:
            
            _textField.stringValue=(self.registerValue==0) ? @"false" : @"true";
            
            break;
        
        case CUIRegisterViewValueAsFloat:
        {
            double tDouble=*((double *)&_registerValue);
            
            _textField.stringValue=[NSString stringWithFormat:@"%g",tDouble];
            
            break;
        }
        
        default:
            
            _textField.stringValue=[NSString stringWithFormat:sFormats[self.viewValueAs],self.registerValue];
            
            break;
    }
}

#pragma mark -

- (IBAction)switchDisplayFormat:(NSPopUpButton *)sender
{
    CUIRegisterViewValueAsType tViewValueAs=sender.selectedTag;
    
    if (self.viewValueAs==tViewValueAs)
        return;
    
    self.viewValueAs=tViewValueAs;
    
    if (self.delegate!=nil)
        [self.delegate registerLabel:self viewValueAsDidChange:tViewValueAs];
    
    // Post notification
    
    [NSNotificationCenter.defaultCenter postNotificationName:CUIRegisterLabelViewAsValueDidChangeNotification
                                                      object:self
                                                    userInfo:@{
                                                               @"viewAs":@(tViewValueAs)
                                                               }];
}

#pragma mark -

- (void)drawRect:(NSRect)dirtyRect
{
    // Draw the rounded rect
    
    NSRect tRect=NSInsetRect(self.bounds, 0.5, 0.5);
    
    NSBezierPath * tPath=[NSBezierPath bezierPathWithRoundedRect:tRect xRadius:4 yRadius:4];
    
    if ([self WB_isEffectiveAppearanceDarkAqua]==YES)
    {
        [[NSColor colorWithWhite:1.0 alpha:0.07] set];
    }
    else
    {
        [[NSColor colorWithWhite:1.0 alpha:0.9] set];
    }
    
    [tPath fill];
    
    [[NSColor quaternaryLabelColor] set];
    
    [tPath stroke];
}

@end
