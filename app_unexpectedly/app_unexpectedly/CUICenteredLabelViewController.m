/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICenteredLabelViewController.h"

#define H_MARGIN_REGULAR  15.0
#define H_MARGIN_BIG  20.0

#define MARGIN_REGULAR_TOP  10.0
#define MARGIN_REGULAR_BOTTOM  12.0
#define MARGIN_BIG_TOP  14.0
#define MARGIN_BIG_BOTTOM  16.0

@interface CUICenteredLabelViewController ()
{
    IBOutlet NSView * _frameView;
    
    IBOutlet NSTextField * _labelTextField;
}

- (void)viewFrameDidChange:(NSNotification *)inNotification;

@end

@implementation CUICenteredLabelViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)nibName
{
    return @"CUICenteredLabelViewController";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.label!=nil)
    {
        _labelTextField.stringValue=self.label;
    }
}

- (void)viewWillAppear
{
    [super viewWillAppear];
    
    // Center view
    
    [self resizeLabel];
    
    [self layout];
    
    // Register for notifications
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewFrameDidChange:) name:NSViewFrameDidChangeNotification object:self.view];
}


- (void)viewWillDisappear
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:self.view];
}

#pragma mark -

- (void)setLabelSize:(CUILabelSize)inLabelSize
{
    if (_labelSize==inLabelSize)
        return;
    
    _labelSize=inLabelSize;
    
    [self resizeLabel];
}

- (void)setLabel:(NSString *)inLabel
{
    if (inLabel==nil)
        return;
    
    if (_label==inLabel)
        return;
    
    _label=[inLabel copy];
    
    _labelTextField.stringValue=inLabel;
    
    [self resizeLabel];
}

#pragma mark -

- (void)setVerticalOffset:(CGFloat)inVerticalOffset
{
    if (_verticalOffset==inVerticalOffset)
        return;
    
    _verticalOffset=inVerticalOffset;
    
    [self layout];
}

CGFloat verticalOffset;

- (void)resizeLabel
{
    CGFloat tFontSize=13.0;
    
    switch(self.labelSize)
    {
        case CUILabelSizeBig:
            
            tFontSize=30.0f;
            break;
            
        case CUILabelSizeRegular:
            
            tFontSize=14.0f;
            break;
    }
    
    _labelTextField.font=[NSFont systemFontOfSize:tFontSize weight:NSFontWeightLight];
    
    [_labelTextField sizeToFit];
    
    NSRect tLabelFrame=_labelTextField.frame;
    
    NSRect tFrameFrame=_frameView.frame;
    
    CGFloat tMargin=H_MARGIN_REGULAR;
    CGFloat tMarginTop=MARGIN_REGULAR_TOP;
    CGFloat tMarginBottom=MARGIN_REGULAR_BOTTOM;
    
    switch(self.labelSize)
    {
        case CUILabelSizeBig:
            
            tMargin=H_MARGIN_BIG;
            tMarginTop=MARGIN_BIG_TOP;
            tMarginBottom=MARGIN_BIG_BOTTOM;
            break;
            
        case CUILabelSizeRegular:
            
            tMargin=H_MARGIN_REGULAR;
            tMarginTop=MARGIN_REGULAR_TOP;
            tMarginBottom=MARGIN_REGULAR_BOTTOM;
            break;
    }
    
    tFrameFrame.size.width=NSWidth(tLabelFrame)+2*tMargin;
    tFrameFrame.size.height=NSHeight(tLabelFrame)+tMarginTop+tMarginBottom;
    
    _frameView.frame=tFrameFrame;
    
    tLabelFrame.origin.x=tMargin;
    tLabelFrame.origin.y=tMarginBottom;
    
    _labelTextField.frame=tLabelFrame;
}

- (void)layout
{
    NSRect tBounds=self.view.bounds;
    
    NSRect tFrame=_frameView.frame;
    
    tFrame.origin.x=round(NSMidX(tBounds)-NSWidth(tFrame)*0.5);
    tFrame.origin.y=round(NSMidY(tBounds)+(self.verticalOffset-NSHeight(tFrame))*0.5);
    
    _frameView.frame=tFrame;
}

#pragma mark - Notifications

- (void)viewFrameDidChange:(NSNotification *)inNotification
{
    [self layout];
}

@end
