/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIRightViewController.h"

#import "CUIInspectorViewController.h"

#import "CUICenteredLabelViewController.h"

#import "CUICrashLogsSelection.h"

@interface CUIRightViewController ()
{
    CUIInspectorViewController * _inspectorViewController;
    
    CUICenteredLabelViewController * _emptySelectionViewController;
    
    CUICenteredLabelViewController * _unavailableViewController;
    
    NSViewController * _currentController;
}

@property (nonatomic,copy) CUICrashLogsSelection * selection;

// Notifications

- (void)crashLogsSelectionDidChange:(NSNotification *)inNotification;

@end

@implementation CUIRightViewController

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _inspectorViewController=[CUIInspectorViewController new];
        
        _emptySelectionViewController=[CUICenteredLabelViewController new];
        _emptySelectionViewController.label=NSLocalizedString(@"No Selection",@"");
        
        _unavailableViewController=[CUICenteredLabelViewController new];
        _unavailableViewController.label=NSLocalizedString(@"Not Available",@"");
    }
    
    return self;
}
    
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.selection=[CUICrashLogsSelection new];
    
    // Register for Notifications
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(crashLogsSelectionDidChange:) name:CUICrashLogsSelectionDidChangeNotification object:nil];
}

#pragma mark -

- (void)setSelection:(CUICrashLogsSelection *)inSelection
{
    if ([_selection isEqual:inSelection]==YES)
        return;
    
    _selection=[inSelection copy];
    
    [_currentController.view removeFromSuperview];
    
    if (_selection.crashLogs.count==0)
    {
        _emptySelectionViewController.view.frame=self.view.bounds;
        
        [self.view addSubview:_emptySelectionViewController.view];
        
        _currentController=_emptySelectionViewController;
    }
    else
    {
        CUICrashLog * tCrashLog=_selection.crashLogs.firstObject;
        
        if ([tCrashLog isMemberOfClass:[CUIRawCrashLog class]]==YES)
        {
            _unavailableViewController.view.frame=self.view.bounds;
            
            [self.view addSubview:_unavailableViewController.view];
            
            _currentController=_unavailableViewController;
        }
        else
        {
            _inspectorViewController.view.frame=self.view.bounds;
            
            [self.view addSubview:_inspectorViewController.view];
            
            _currentController=_inspectorViewController;
            
            _inspectorViewController.crashLog=tCrashLog;
        }
    }
}

#pragma mark - Notifications

- (void)crashLogsSelectionDidChange:(NSNotification *)inNotification
{
    CUICrashLogsSelection * tSelection=inNotification.object;
    
    if ([tSelection isKindOfClass:[CUICrashLogsSelection class]]==NO)
        return;
    
    self.selection=tSelection;
}

@end
