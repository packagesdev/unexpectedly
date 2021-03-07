/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIPreferencePanePresentationOutlineViewController.h"

#import "CUIApplicationPreferences.h"

#import "CUIOutlineModeDisplaySettings.h"

@interface CUIPreferencePanePresentationOutlineViewController ()
{
    // Strack Frame
    
    IBOutlet NSButton * _showBinaryNameCheckbox;
    
    IBOutlet NSButton * _showMachineInstructionAddressCheckbox;
    
    IBOutlet NSButton * _showByteOffsetCheckbox;
    
    
    CUIApplicationPreferences * _applicationPreferences;
    
    CUIOutlineModeDisplaySettings * _displaySettings;
}

- (void)_setStackFrameComponent:(CUIStackFrameComponents)inComponent visible:(BOOL)inVisible;

- (IBAction)switchShowBinaryName:(id)sender;

- (IBAction)switchShowMachineInstructionAddress:(id)sender;

- (IBAction)switchShowByteOffset:(id)sender;

@end

@implementation CUIPreferencePanePresentationOutlineViewController

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _applicationPreferences=[CUIApplicationPreferences sharedPreferences];
        
        _displaySettings=[_applicationPreferences.defaultOutlineModeDisplaySettings copy];
    }
    
    return self;
}

- (NSString *)nibName
{
    return @"CUIPreferencePanePresentationOutlineViewController";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear
{
    [super viewWillAppear];
    
    // Stack Frame
    
    _showBinaryNameCheckbox.state=((_displaySettings.visibleStackFrameComponents & CUIStackFrameBinaryNameComponent)!=0) ? NSOnState : NSOffState;
    
    _showMachineInstructionAddressCheckbox.state=((_displaySettings.visibleStackFrameComponents & CUIStackFrameMachineInstructionAddressComponent)!=0) ? NSOnState : NSOffState;
    
    _showByteOffsetCheckbox.state=((_displaySettings.visibleStackFrameComponents & CUIStackFrameByteOffsetComponent)!=0) ? NSOnState : NSOffState;
}

#pragma mark -

- (void)_setStackFrameComponent:(CUIStackFrameComponents)inComponent visible:(BOOL)inVisible
{
    if (inVisible==YES)
    {
        _displaySettings.visibleStackFrameComponents|=inComponent;
    }
    else
    {
        _displaySettings.visibleStackFrameComponents&=~inComponent;
    }
    
    _applicationPreferences.defaultOutlineModeDisplaySettings=_displaySettings;
}

#pragma mark -

- (IBAction)switchShowBinaryName:(NSButton *)sender
{
    [self _setStackFrameComponent:CUIStackFrameBinaryNameComponent visible:(sender.state==NSOnState)];
}

- (IBAction)switchShowMachineInstructionAddress:(NSButton *)sender
{
    [self _setStackFrameComponent:CUIStackFrameMachineInstructionAddressComponent visible:(sender.state==NSOnState)];
}

- (IBAction)switchShowByteOffset:(NSButton *)sender
{
    [self _setStackFrameComponent:CUIStackFrameByteOffsetComponent visible:(sender.state==NSOnState)];
}

@end
