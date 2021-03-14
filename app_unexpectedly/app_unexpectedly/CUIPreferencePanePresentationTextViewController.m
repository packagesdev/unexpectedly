/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIPreferencePanePresentationTextViewController.h"

#import "CUIApplicationPreferences.h"

@interface CUIPreferencePanePresentationTextViewController ()
{
    // Document
    
    IBOutlet NSButton * _showsLineNumbersCheckbox;
    
    IBOutlet NSButton * _lineWrappingCheckbox;
    
    // Sections
    
    IBOutlet NSButton * _showHeaderCheckbox;
    
    IBOutlet NSButton * _showExceptionInformationCheckbox;
    
    IBOutlet NSButton * _showDiagnosticMessagesCheckbox;
    
    IBOutlet NSButton * _showBacktracesCheckbox;
    
    IBOutlet NSButton * _showThreadStateCheckbox;
    
    IBOutlet NSButton * _showBinaryImagesCheckbox;
    
    // Strack Frame
    
    IBOutlet NSButton * _showBinaryNameCheckbox;
    
    IBOutlet NSButton * _showMachineInstructionAddressCheckbox;
    
    IBOutlet NSButton * _showByteOffsetCheckbox;
    
    
    CUIApplicationPreferences * _applicationPreferences;
    
    CUITextModeDisplaySettings * _displaySettings;
}

- (IBAction)switchLineWrapping:(id)sender;

- (IBAction)switchShowHeader:(id)sender;

- (IBAction)switchShowExceptionInformation:(id)sender;

- (IBAction)switchShowDiagnosticMessages:(id)sender;

- (IBAction)switchShowBacktraces:(id)sender;

- (IBAction)switchShowThreadState:(id)sender;

- (IBAction)switchShowBinaryImages:(id)sender;


- (IBAction)switchShowBinaryName:(id)sender;

- (IBAction)switchShowMachineInstructionAddress:(id)sender;

- (IBAction)switchShowByteOffset:(id)sender;

@end

@implementation CUIPreferencePanePresentationTextViewController

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _applicationPreferences=[CUIApplicationPreferences sharedPreferences];
        
        _displaySettings=[_applicationPreferences.defaultTextModeDisplaySettings copy];
    }
    
    return self;
}

#pragma mark -

- (NSString *)nibName
{
    return @"CUIPreferencePanePresentationTextViewController";
}

- (void)viewWillAppear
{
    [super viewWillAppear];
    
    // Document
    
    _showsLineNumbersCheckbox.state=(_applicationPreferences.showsLineNumbers==YES) ? NSOnState : NSOffState;
    
    _lineWrappingCheckbox.state=(_applicationPreferences.lineWrapping==YES) ? NSOnState : NSOffState;
    
    // Sections
    
    _showHeaderCheckbox.state=((_displaySettings.visibleSections & CUIDocumentHeaderSection)!=0) ? NSOnState : NSOffState;
    
    _showExceptionInformationCheckbox.state=((_displaySettings.visibleSections & CUIDocumentExceptionInformationSection)!=0) ? NSOnState : NSOffState;
    
    _showDiagnosticMessagesCheckbox.state=((_displaySettings.visibleSections & CUIDocumentDiagnosticMessagesSection)!=0) ? NSOnState : NSOffState;
    
    _showBacktracesCheckbox.state=((_displaySettings.visibleSections & CUIDocumentBacktracesSection)!=0) ? NSOnState : NSOffState;
    
    _showThreadStateCheckbox.state=((_displaySettings.visibleSections & CUIDocumentThreadStateSection)!=0) ? NSOnState : NSOffState;
    
    _showBinaryImagesCheckbox.state=((_displaySettings.visibleSections & CUIDocumentBinaryImagesSection)!=0) ? NSOnState : NSOffState;
    
    // Stack Frame
    
    _showBinaryNameCheckbox.state=((_displaySettings.visibleStackFrameComponents & CUIStackFrameBinaryNameComponent)!=0) ? NSOnState : NSOffState;
    
    _showMachineInstructionAddressCheckbox.state=((_displaySettings.visibleStackFrameComponents & CUIStackFrameMachineInstructionAddressComponent)!=0) ? NSOnState : NSOffState;
    
    _showByteOffsetCheckbox.state=((_displaySettings.visibleStackFrameComponents & CUIStackFrameByteOffsetComponent)!=0) ? NSOnState : NSOffState;
}

#pragma mark -

- (void)_setSection:(CUIDocumentSections)inSection visible:(BOOL)inVisible
{
    if (inVisible==YES)
        _displaySettings.visibleSections|=inSection;
    else
        _displaySettings.visibleSections&=~inSection;
    
    _applicationPreferences.defaultTextModeDisplaySettings=_displaySettings;
}

- (void)_setStackFrameComponent:(CUIStackFrameComponents)inComponent visible:(BOOL)inVisible
{
    if (inVisible==YES)
        _displaySettings.visibleStackFrameComponents|=inComponent;
    else
        _displaySettings.visibleStackFrameComponents&=~inComponent;
    
    _applicationPreferences.defaultTextModeDisplaySettings=_displaySettings;
}



- (IBAction)switchShowsLineNumbers:(NSButton *)sender
{
    _applicationPreferences.showsLineNumbers=(sender.state==NSOnState);
}

- (IBAction)switchLineWrapping:(NSButton *)sender
{
    _applicationPreferences.lineWrapping=(sender.state==NSOnState);
}

- (IBAction)switchShowHeader:(NSButton *)sender
{
    [self _setSection:CUIDocumentHeaderSection visible:(sender.state==NSOnState)];
}

- (IBAction)switchShowExceptionInformation:(NSButton *)sender
{
    [self _setSection:CUIDocumentExceptionInformationSection visible:(sender.state==NSOnState)];
}

- (IBAction)switchShowDiagnosticMessages:(NSButton *)sender
{
    [self _setSection:CUIDocumentDiagnosticMessagesSection visible:(sender.state==NSOnState)];
}

- (IBAction)switchShowBacktraces:(NSButton *)sender
{
    [self _setSection:CUIDocumentBacktracesSection visible:(sender.state==NSOnState)];
}

- (IBAction)switchShowThreadState:(NSButton *)sender
{
    [self _setSection:CUIDocumentThreadStateSection visible:(sender.state==NSOnState)];
}

- (IBAction)switchShowBinaryImages:(NSButton *)sender
{
    [self _setSection:CUIDocumentBinaryImagesSection visible:(sender.state==NSOnState)];
}

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
