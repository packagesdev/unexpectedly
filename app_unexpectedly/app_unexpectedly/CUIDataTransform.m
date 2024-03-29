/*
 Copyright (c) 2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIDataTransform.h"

NSString * const CUIDataTransformErrorDomain=@"fr.whitebox.data-tranform.error";


NSString * const CUIGenericAnchorAttributeName=@"CUIGenericAnchorAttributeName";

NSString * const CUISectionAnchorAttributeName=@"CUISectionAnchorAttributeName";

NSString * const CUIThreadAnchorAttributeName=@"CUIThreadAnchorAttributeName";

NSString * const CUIBinaryAnchorAttributeName=@"CUIBinaryAnchorAttributeName";

@interface CUIDataTransform ()

    @property (nonatomic,readwrite) NSAttributedString * output;

    @property (readwrite) NSError * error;

- (void)setOutput:(NSAttributedString *)inOutput;

@end

@implementation CUIDataTransform

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _symbolicationMode=CUISymbolicationModeSymbolicate;
        
        _hyperlinksStyle=CUIHyperlinksInternal;
    }
    
    return self;
}

#pragma mark -

- (void)setHyperlinksStyle:(CUIHyperlinksStyle)inHyperlinksStyle
{
    _output=nil;
    
    _hyperlinksStyle=inHyperlinksStyle;
}

- (void)setDisplaySettings:(CUITextModeDisplaySettings *)inDisplaySettings
{
    _output=nil;
    
    _displaySettings=inDisplaySettings;
}

- (void)setFontSizeDelta:(CGFloat)inFontSizeDelta
{
    _output=nil;
    
    _fontSizeDelta=inFontSizeDelta;
}

- (void)setInput:(id)inInput
{
    _output=nil;
    
    _input=inInput;
}

- (void)setOutput:(NSAttributedString *)inOutput
{
    _output=inOutput;
}

#pragma mark -

- (BOOL)transform
{
    self.output=nil;
    
    return YES;
}

@end
