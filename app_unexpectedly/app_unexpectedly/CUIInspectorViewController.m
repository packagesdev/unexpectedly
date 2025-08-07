/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIInspectorViewController.h"

#import "CUICrashLog+UI.h"

#import "CUIInspectorGeneralViewController.h"

#import "CUIInspectorUserViewController.h"

#import "CUIInspectorExecutableViewController.h"

#import "CUIInspectorProcessesViewController.h"

@interface CUIInspectorViewController () <NSTableViewDataSource,NSTabViewDelegate>
{
    NSMutableArray * _stackableViewControllers;
}

- (void)refreshLayout;

// Notifications

- (void)viewFrameDidChange:(NSNotification *)inNotification;

@end

@implementation CUIInspectorViewController

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _stackableViewControllers=[NSMutableArray array];
        
        CUIInspectorGeneralViewController * tGeneralViewController=[CUIInspectorGeneralViewController new];
        
        [_stackableViewControllers addObject:tGeneralViewController];
        
        CUIInspectorUserViewController * tUserViewController=[CUIInspectorUserViewController new];
        
        [_stackableViewControllers addObject:tUserViewController];
        
        CUIInspectorExecutableViewController * tExecutableViewController=[CUIInspectorExecutableViewController new];
        
        [_stackableViewControllers addObject:tExecutableViewController];
        
        CUIInspectorProcessesViewController * tProcessesViewController=[CUIInspectorProcessesViewController new];
        
        [_stackableViewControllers addObject:tProcessesViewController];
    }
    
    return self;
}

- (NSString *)nibName
{
    return @"CUIInspectorViewController";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    for(CUIInspectorStackableViewController * tViewController in _stackableViewControllers)
    {
        tViewController.crashLog=self.crashLog;
        
        [self.view addSubview:tViewController.view];
    }
    
    [self refreshLayout];

    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(viewFrameDidChange:) name:NSViewFrameDidChangeNotification object:self.view];
}

#pragma mark -

- (void)setCrashLog:(CUICrashLog *)inCrashLog
{
    if (_crashLog==inCrashLog)
        return;
    
    _crashLog=inCrashLog;

    for(CUIInspectorStackableViewController * tViewController in _stackableViewControllers)
    {
        tViewController.crashLog=inCrashLog;
    }
    
    [self refreshLayout];
}

#pragma mark -

- (void)refreshLayout
{
    NSRect tFrame=self.view.frame;
    
    CGFloat tMaxY=NSMaxY(tFrame);
    
    for(CUIInspectorStackableViewController * tViewController in _stackableViewControllers)
    {
        [tViewController layoutView];
        
        NSRect tInspectorViewFrame=tViewController.view.bounds;
        
        tInspectorViewFrame.origin.y=tMaxY-NSHeight(tInspectorViewFrame);
        
        tViewController.view.frame=tInspectorViewFrame;
        
        tMaxY=tInspectorViewFrame.origin.y;
    }
}

#pragma mark - Notifications

- (void)viewFrameDidChange:(NSNotification *)inNotification
{
    [self refreshLayout];
}

@end
