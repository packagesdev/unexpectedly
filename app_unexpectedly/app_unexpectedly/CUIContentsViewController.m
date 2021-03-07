/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIContentsViewController.h"

#import "CUIPresentationTextNavigationViewController.h"

#import "CUICenteredLabelViewController.h"

#import "CUICrashLogContentsViewController.h"

#import "CUICrashLogsSelection.h"

@interface CUIContentsViewController ()
{
    IBOutlet NSView * _topView;
    
    IBOutlet NSView * _contentsView;
    
    CUICenteredLabelViewController * _emptySelectionViewController;
    
    CUICrashLogContentsViewController * _contentsViewController;
    
    NSViewController * _currentController;
    
    CUIPresentationTextNavigationViewController * _navigationViewController;
}

    @property (nonatomic,copy) CUICrashLogsSelection * selection;

@end

@implementation CUIContentsViewController

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _emptySelectionViewController=[CUICenteredLabelViewController new];
        _emptySelectionViewController.label=NSLocalizedString(@"No Selection",@"");
        _emptySelectionViewController.verticalOffset=24.0;
        
        _contentsViewController=[CUICrashLogContentsViewController new];
        
        // Register for notifications
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(crashLogsSelectionDidChange:) name:CUICrashLogsSelectionDidChangeNotification object:nil];
        
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
    return @"CUIContentsViewController";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _navigationViewController=[CUIPresentationTextNavigationViewController new];
    
    _navigationViewController.view.frame=_topView.bounds;
    
    [_topView addSubview:_navigationViewController.view];
    
    self.selection=[CUICrashLogsSelection new];
}

#pragma mark - NSObject

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    if (_currentController!=_contentsViewController)
        return nil;
    
    return _contentsViewController;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    BOOL tResponds=[super respondsToSelector:aSelector];
    
    if (tResponds==YES)
        return YES;
    
    if (_currentController!=_contentsViewController)
        return NO;
    
    NSString * tSelectorName=NSStringFromSelector(aSelector);
    
    if ([tSelectorName hasPrefix:@"CUI_MENUACTION_"]==NO && [tSelectorName isEqualToString:@"performTextFinderAction:"]==NO)
        return NO;
    
    tResponds=[_contentsViewController respondsToSelector:aSelector];
    
    if (tResponds==YES)
        return YES;
    
    return NO;
}

#pragma mark -

- (BOOL)isBottomViewCollapsed
{
    return _contentsViewController.isBottomViewCollapsed;
}

- (CUIPresentationMode)presentationMode
{
    if (_currentController==nil || _currentController!=_contentsViewController)
        return CUIPresentationModeUnknown;
    
    return _contentsViewController.presentationMode;
}

- (void)setPresentationMode:(CUIPresentationMode)inPresentationMode
{
    if (_currentController==nil || _currentController!=_contentsViewController)
        return;
    
    _contentsViewController.presentationMode=inPresentationMode;
    
    _navigationViewController.presentationViewController=_contentsViewController.presentationViewController;
}

- (BOOL)isEmptySelection
{
    return (_selection.crashLogs.count==0);
}

- (void)setSelection:(CUICrashLogsSelection *)inSelection
{
    if ([_selection isEqual:inSelection]==YES)
        return;
    
    /*if (_selection.crashLogs.firstObject!=nil)
        [NSObject cancelPreviousPerformRequestsWithTarget:_contentsViewController selector:@selector(setCrashLog:) object:_selection.crashLogs.firstObject];*/
    
    _selection=[inSelection copy];
    
    NSViewController * tNewController=nil;
    
    if (_selection.crashLogs.count==0)
    {
        tNewController=_emptySelectionViewController;
        
        _navigationViewController.presentationViewController=nil;
    }
    else
    {
        tNewController=_contentsViewController;
    }
    
    if (_currentController!=tNewController)
    {
        [_currentController.view removeFromSuperview];
    }
    
    tNewController.view.frame=_contentsView.bounds;
    
    [_contentsView addSubview:tNewController.view];
    
    _currentController=tNewController;
    
    
    
    if (_selection.crashLogs.count!=0)
    {
        //[_contentsViewController performSelector:@selector(setCrashLog:) withObject:_selection.crashLogs.firstObject afterDelay:0.1];
        _contentsViewController.crashLog=_selection.crashLogs.firstObject;
        
        _navigationViewController.presentationViewController=_contentsViewController.presentationViewController;
    }
}

- (IBAction)showHideBottomView:(id)sender
{
    if (_contentsViewController.presentationMode!=CUIPresentationModeOutline)
        return;
    
    [_contentsViewController showHideBottomView:sender];
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
    SEL tAction=inMenuItem.action;
    
    if (_currentController!=_contentsViewController)
        return NO;
    
    if ([super respondsToSelector:tAction]==NO)
    {
        NSString * tSelectorName=NSStringFromSelector(tAction);
        
        if ([tSelectorName hasPrefix:@"CUI_MENUACTION_"]==NO && [tSelectorName isEqualToString:@"performTextFinderAction:"]==NO)
            return NO;
        
        if ([_contentsViewController respondsToSelector:tAction]==YES)
            return [_contentsViewController validateMenuItem:inMenuItem];
        
        return NO;
    }
    
    return YES;
}

#pragma mark - CUIKeyViews

- (NSView *)firstKeyView
{
    if (_currentController==nil || _currentController==_emptySelectionViewController)
        return nil;
    
    return _contentsViewController.firstKeyView;
}

- (NSView *)lastKeyView
{
    if (_currentController==nil || _currentController==_emptySelectionViewController)
        return nil;
    
    return _contentsViewController.lastKeyView;
}

#pragma mark - Notifications

- (void)crashLogsSelectionDidChange:(NSNotification *)inNotification
{
    CUICrashLogsSelection * tSelection=inNotification.object;
    
    if (tSelection==nil)
        return;
    
    self.selection=tSelection;
}

@end
