/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIRegistersMainViewController.h"

#import "CUICenteredLabelViewController.h"
#import "CUIRegistersViewController.h"

#import "CUICrashLogsSelection.h"

#import "CUICrashLogBrowsingStateRegistry.h"

#import "CUICrashLogThreadState+UI.h"

NSString * const CUIRegistersMainViewContentsViewDidChangeNotificaton=@"CUIRegistersMainViewContentsViewDidChangeNotificaton";

@interface CUIRegistersMainViewController ()
{
    CUICenteredLabelViewController * _noRegistersViewController;
    
    CUIRegistersViewController * _registersViewController;
    
    cpu_type_t _currentCPUType;
    
    NSViewController * _currentViewController;
}

    @property (nonatomic,copy) CUICrashLogsSelection * selection;

// Notifications

- (void)crashLogsSelectionDidChange:(NSNotification *)inNotification;

@end

@implementation CUIRegistersMainViewController

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _noRegistersViewController=[CUICenteredLabelViewController new];
        _noRegistersViewController.label=NSLocalizedString(@"Registers state not available",@"");
        
        
        
        _registersViewController=[CUIRegistersViewController new];
        
        _selection=[CUICrashLogsSelection new];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -

- (NSString *)nibName
{
    return @"CUIRegistersMainViewController";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Register for Notifications
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(crashLogsSelectionDidChange:) name:CUICrashLogsSelectionDidChangeNotification object:nil];
}

- (void)viewWillAppear
{
    CUICrashLogsSelection * tSelection=[CUICrashLogsSelection sharedSelection];
    
    self.selection=tSelection;
    
    // Post Notification
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CUIRegistersMainViewContentsViewDidChangeNotificaton object:self];
}


#pragma mark -

- (void)setSelection:(CUICrashLogsSelection *)inSelection
{
    if ([_selection isEqual:inSelection]==YES)
        return;
    
    _selection=[inSelection copy];
    
    CUICrashLogThreadState * tThreadState=nil;
    
    if (_selection.crashLogs.count==0)
    {
        tThreadState=nil;
    }
    else
    {
        CUICrashLog * tCrashLog=_selection.crashLogs.firstObject;
        
        if ([tCrashLog isMemberOfClass:[CUIRawCrashLog class]]==YES)
        {
            tThreadState=nil;
        }
        else
        {
            tThreadState=tCrashLog.threadState;
        }
    }
    
    // Update Window title
    
    NSString * tCPUTypeLabel=tThreadState.displayedCPUType;
    
    if (tCPUTypeLabel==nil)
    {
        self.view.window.title=NSLocalizedString(@"Registers",@"");
    }
    else
    {
        self.view.window.title=[NSString stringWithFormat:NSLocalizedString(@"Registers - %@",@""),tCPUTypeLabel];
    }
    
    if (tThreadState==nil)
    {
        if (_currentViewController==_noRegistersViewController)
            return;
        
        [_currentViewController.view removeFromSuperview];
        
        NSRect tFrame=self.view.bounds;
        
        _noRegistersViewController.view.frame=tFrame;
        
        [self.view addSubview:_noRegistersViewController.view];
        
        _currentViewController=_noRegistersViewController;
        
        _currentCPUType=0;
    }
    else
    {
        CUICrashLogBrowsingStateRegistry * tRegistry=[CUICrashLogBrowsingStateRegistry sharedRegistry];
        
        _registersViewController.browsingState=[tRegistry browsingStateForCrashLog:_selection.crashLogs.firstObject windowNumber:self.view.window.windowNumber];
        
        _registersViewController.threadState=tThreadState;
        
        if (_currentViewController!=_registersViewController)
        {
            [_currentViewController.view removeFromSuperview];
    
            NSRect tFrame=self.view.bounds;
        
            _registersViewController.view.frame=tFrame;
        
            [self.view addSubview:_registersViewController.view];
        
            _currentViewController=_registersViewController;
        }
        
        if (tThreadState.CPUType==_currentCPUType)
            return;
        
        _currentCPUType=tThreadState.CPUType;
    }
    
    // Post Notification
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CUIRegistersMainViewContentsViewDidChangeNotificaton object:self];
}

- (NSSize)idealSizeForNumberOfColumns:(NSUInteger)inColumnsNumber
{
    static NSSize sLastIdealSize={.width=300, .height=200};
    
    if (_currentViewController==_registersViewController)
    {
        sLastIdealSize=[_registersViewController idealSizeForNumberOfColumns:inColumnsNumber];
    }
    else
    {
        return NSZeroSize;
    }
    
    return sLastIdealSize;
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
