/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIMainWindowController.h"

#import "CUICrashLogsMainViewController.h"

#import "CUICrashLogsSelection.h"

#import "CUIRegistersWindowController.h"

#import "CUIApplicationPreferences.h"

extern NSString * const CUICrashLogContentsViewPresentationModeDidChangeNotification;

extern NSString * const CUIBottomViewCollapseStateDidChangeNotification;

@interface CUIMainWindowController () <NSToolbarDelegate,NSWindowDelegate>
{
    CUICrashLogsMainViewController * _mainViewController;
    
    IBOutlet NSButton * _registersWindowButton;
    
    IBOutlet NSSegmentedControl * _presentationModeSegmentedControl;
    
    IBOutlet NSSegmentedControl * _mainLayoutSegmentedControl;
}

- (IBAction)CUIMENUACTION_showHideRegisters:(id)sender;

// Notifications

- (void)splitViewDidResizeSubviews:(NSNotification *)inNotification;

- (void)bottomViewCollapseStateDidChange:(NSNotification *)inNotification;

- (void)crashLogsSelectionDidChange:(NSNotification *)inNotification;

- (void)contentsViewPresentationModeDidChange:(NSNotification *)inNotification;

@end

@implementation CUIMainWindowController

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

#pragma mark -

- (NSString *)windowNibName
{
	return @"CUIMainWindowController";
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Register for notifications
    
    NSNotificationCenter * tNotificationCenter=NSNotificationCenter.defaultCenter;
    
    [tNotificationCenter addObserver:self selector:@selector(crashLogsSelectionDidChange:) name:CUICrashLogsSelectionDidChangeNotification object:nil];
    
    [tNotificationCenter addObserver:self selector:@selector(contentsViewPresentationModeDidChange:) name:CUICrashLogContentsViewPresentationModeDidChangeNotification object:nil];
    
    [tNotificationCenter addObserver:self selector:@selector(splitViewDidResizeSubviews:) name:NSSplitViewDidResizeSubviewsNotification object:_mainViewController.splitView];
    
    
    [tNotificationCenter addObserver:self selector:@selector(bottomViewCollapseStateDidChange:) name:CUIBottomViewCollapseStateDidChangeNotification object:self.window];
    
    [tNotificationCenter addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:nil];
    
    // Add main view
    
    _mainViewController=[CUICrashLogsMainViewController new];
    
    _mainViewController.view.frame=self.window.contentView.bounds;
    
    [self.window.contentView addSubview:_mainViewController.view];
    
    [self.window makeFirstResponder:_mainViewController];
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
    SEL tAction=inMenuItem.action;
    
    if (tAction==@selector(CUIMENUACTION_showHideRegisters:))
    {
        CUIRegistersWindowController * tRegistersWindowController=[CUIRegistersWindowController sharedRegistersWindowController];
        
        if ([tRegistersWindowController.window isVisible]==YES)
        {
            inMenuItem.title=NSLocalizedString(@"Hide Registers", @"");
        }
        else
        {
            inMenuItem.title=NSLocalizedString(@"Show Registers", @"");
        }
    }
    
    return YES;
}

- (void)noResponderFor:(SEL)inEventSelector
{
    if (inEventSelector!=@selector(keyDown:))
        return;

    [NSNotificationCenter.defaultCenter postNotificationName:@"windowDidNotHandleKeyEventNotification" object:self.window userInfo:@{@"Event":[NSApp currentEvent]}];
}

- (IBAction)CUIMENUACTION_showHideRegisters:(id)sender
{
    CUIRegistersWindowController * tRegistersWindowController=[CUIRegistersWindowController sharedRegistersWindowController];
    
    if ([tRegistersWindowController.window isVisible]==YES)
    {
        [tRegistersWindowController.window close];
    }
    else
    {
        [tRegistersWindowController showWindow:nil];
        
        _registersWindowButton.state=NSControlStateValueOn;
    }
}

- (void)showWindow:(id)sender
{
    [super showWindow:sender];
    
    // Show Registers window?
    
    if ([CUIApplicationPreferences sharedPreferences].showsRegistersWindowAutomaticallyAtLaunch==YES)
        [self CUIMENUACTION_showHideRegisters:self];
}

#pragma mark - Notifications

- (void)splitViewDidResizeSubviews:(NSNotification *)inNotification
{
    [_mainLayoutSegmentedControl setSelected:([_mainViewController.splitView isSubviewCollapsed:_mainViewController.splitView.subviews[0]]==NO) forSegment:0];
    
    [_mainLayoutSegmentedControl setSelected:([_mainViewController.splitView isSubviewCollapsed:_mainViewController.splitView.subviews[2]]==NO) forSegment:2];
}

- (void)bottomViewCollapseStateDidChange:(NSNotification *)inNotification
{
    BOOL tIsCollapsed=[inNotification.userInfo[@"Collapsed"] boolValue];
    
    [_mainLayoutSegmentedControl setSelected:(tIsCollapsed==NO) forSegment:1];
}

- (void)contentsViewPresentationModeDidChange:(NSNotification *)inNotification
{
    NSNumber * tNumber=inNotification.userInfo[@"mode"];
    
    if (tNumber==nil)
        return;
    
    NSUInteger tMode=tNumber.integerValue;
    
    [_presentationModeSegmentedControl selectSegmentWithTag:tMode];
    
    [_mainLayoutSegmentedControl setEnabled:(tMode==1) forSegment:1];
}

- (void)crashLogsSelectionDidChange:(NSNotification *)inNotification
{
    CUICrashLogsSelection * tSelection=inNotification.object;
    
    if ([tSelection isKindOfClass:[CUICrashLogsSelection class]]==NO)
        return;
    
    _presentationModeSegmentedControl.enabled=(tSelection.crashLogs.count>0);
    
    if ([_presentationModeSegmentedControl tagForSegment:_presentationModeSegmentedControl.selectedSegment]==1)
    {
        [_mainLayoutSegmentedControl setEnabled:(tSelection.crashLogs.count>0) forSegment:1];
    }
    
    CUIRawCrashLog * tCrashLog=tSelection.crashLogs.firstObject;
    
    if (tCrashLog==nil)
    {
        self.window.title=@"Unexpectedly";
        self.window.representedFilename=@"";
        
        return;
    }
    
    NSString * tCrashLogFilePath=tCrashLog.crashLogFilePath;
    
    self.window.title=tCrashLogFilePath.lastPathComponent;
    
    self.window.representedFilename=tCrashLogFilePath;
}

- (void)windowWillClose:(NSNotification *)inNotification
{
    NSWindow * tWindow=inNotification.object;
    
    if (tWindow==self.window)
    {
        [NSApp terminate:self];
        
        return;
    }
    
    if ([tWindow.windowController isKindOfClass:[CUIRegistersWindowController class]]==YES)
    {
        _registersWindowButton.state=NSControlStateValueOff;
    }
}

@end
