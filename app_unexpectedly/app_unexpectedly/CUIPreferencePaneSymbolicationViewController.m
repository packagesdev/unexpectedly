/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIPreferencePaneSymbolicationViewController.h"

#import "CUIApplicationPreferences.h"

#import "CUISymbolsFilesLibraryViewController.h"

@interface CUIPreferencePaneSymbolicationViewController ()
{
    IBOutlet NSButton * _symbolicateButton;
    
    IBOutlet NSButton * _searchForSymbolsFilesButton;
    
    IBOutlet NSView * _dSYMLibraryPlaceHolderView;
    
    CUISymbolsFilesLibraryViewController * _symbolFilesLibraryViewController;
}

- (IBAction)switchSymbolicate:(id)sender;

- (IBAction)switchSearchForSymbolFiles:(id)sender;

@end

@implementation CUIPreferencePaneSymbolicationViewController

- (NSString *)nibName
{
    return @"CUIPreferencePaneSymbolicationViewController";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _symbolFilesLibraryViewController=[CUISymbolsFilesLibraryViewController new];
    
    _symbolFilesLibraryViewController.view.frame=_dSYMLibraryPlaceHolderView.bounds;
    
    [_dSYMLibraryPlaceHolderView addSubview:_symbolFilesLibraryViewController.view];
}

- (void)viewWillAppear
{
    [super viewWillAppear];
    
    CUIApplicationPreferences * tPreferences=[CUIApplicationPreferences sharedPreferences];
    
    _symbolicateButton.state=(tPreferences.symbolicateAutomatically==YES) ? NSControlStateValueOn : NSControlStateValueOff;
    
    _searchForSymbolsFilesButton.state=(tPreferences.searchForSymbolsFilesAutomatically==YES) ? NSControlStateValueOn : NSControlStateValueOff;
}

#pragma mark -

- (CGFloat)minimumHeight
{
    return 350;
}

- (CGFloat)maximumHeight
{
    return 800;
}

#pragma mark -

- (IBAction)switchSymbolicate:(NSButton *)sender
{
    [CUIApplicationPreferences sharedPreferences].symbolicateAutomatically=(sender.state==NSControlStateValueOn);
}

- (IBAction)switchSearchForSymbolFiles:(NSButton *)sender
{
    [CUIApplicationPreferences sharedPreferences].searchForSymbolsFilesAutomatically=(sender.state==NSControlStateValueOn);
}

@end
