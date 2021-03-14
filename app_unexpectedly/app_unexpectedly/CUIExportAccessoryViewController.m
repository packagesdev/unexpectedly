/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIExportAccessoryViewController.h"


@interface CUIExportAccessoryViewController ()
{
    // Format
    
    IBOutlet NSPopUpButton * _formatPopUpButton;
    
    // Exported Contents
    
    IBOutlet NSButton * _allContentsRadioButton;
    
    IBOutlet NSButton * _selectionOnlyRadioButton;
}

- (IBAction)switchExportFormat:(id)sender;

- (IBAction)switchExportedContents:(id)sender;

@end

@implementation CUIExportAccessoryViewController

- (NSString *)nibName
{
    return @"CUIExportAccessoryViewController";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Export Format
    
    [_formatPopUpButton selectItemWithTag:self.exportFormat];
    
    // Exported Contents
    
    BOOL tRadioButtonEnabled=(self.canSelectExportedContents==YES);
    
    _selectionOnlyRadioButton.enabled=tRadioButtonEnabled;
    _allContentsRadioButton.enabled=tRadioButtonEnabled;
    
    _allContentsRadioButton.state=NSOnState;
}

#pragma mark -

- (void)setExportFormat:(CUICrashLogExportFormat)inExportFormat
{
    if ([_formatPopUpButton selectItemWithTag:inExportFormat]==NO)
        return;
    
    _exportFormat=inExportFormat;
}

- (void)setCanSelectExportedContents:(BOOL)inCanSelectExportedContents
{
    _canSelectExportedContents=inCanSelectExportedContents;
    
    if (_canSelectExportedContents==YES)
    {
        _selectionOnlyRadioButton.enabled=YES;
        
    }
    else
    {
        _selectionOnlyRadioButton.enabled=NO;
        _allContentsRadioButton.state=NSOnState;
    }
}

- (CUICrashLogExportedContentsType)exportedContents
{
    if (_allContentsRadioButton.state==NSOnState)
        return CUICrashLogExportedContentsAll;
    
    return CUICrashLogExportedContentsSelection;
}

#pragma mark -

- (IBAction)switchExportFormat:(NSPopUpButton *)sender
{
    _exportFormat=sender.selectedTag;
    
    switch(_exportFormat)
    {
        case CUICrashLogExportFormatHTML:
            
            self.savePanel.allowedFileTypes=@[@"html"];
            
            break;
        
        case CUICrashLogExportFormatRTF:
            
            self.savePanel.allowedFileTypes=@[@"rtf"];
            
            break;
            
        case CUICrashLogExportFormatPDF:
            
            self.savePanel.allowedFileTypes=@[@"pdf"];
            
            break;
    }
}

- (IBAction)switchExportedContents:(id)sender
{
    // Not used at this time
}

@end
