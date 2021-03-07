/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUISidebarViewController.h"

#import "CUICrashLogsSourcesViewController.h"

#import "CUICrashLogsListViewController.h"

#define CUICrashLogsListMinimumHeight    340.0
#define CUICrashLogsSourcesMinimumHeight    153.0

NSString * const CUIDefaultsSidebarTopHeightKey=@"sidebar.top.height";

NSString * const CUIDefaultsSidebarTopCollapsedKey=@"sidebar.top.collapsed";

@interface CUISidebarViewController () <NSSplitViewDelegate>
{
    IBOutlet NSSplitView * _splitView;
    
    IBOutlet NSView * _crashLogsSourcesContainerView;
    
    IBOutlet NSView * _crashLogsListContainerView;
    
    
    CUICrashLogsSourcesViewController * _sourcesViewController;
    
    CUICrashLogsListViewController * _listViewController;
}

- (void)_splitView:(NSSplitView *)inSplitView resizeSubviewsWithTopHeight:(CGFloat)inTopHeight;

@end

@implementation CUISidebarViewController

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _sourcesViewController=[CUICrashLogsSourcesViewController new];
        
        _listViewController=[CUICrashLogsListViewController new];
        
        [self addChildViewController:_sourcesViewController];
        
        [self addChildViewController:_listViewController];
    }
    
    return self;
}

- (NSString *)nibName
{
    return @"CUISidebarViewController";
}

#pragma mark - NSObject

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    if ([_sourcesViewController respondsToSelector:aSelector]==YES)
    {
        return _sourcesViewController;
    }
    
    if ([_listViewController respondsToSelector:aSelector]==YES)
    {
        return _listViewController;
    }
    
    return nil;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    BOOL tResponds=[super respondsToSelector:aSelector];
    
    if (tResponds==YES)
        return YES;
    
    NSString * tSelectorName=NSStringFromSelector(aSelector);
    
    if ([tSelectorName hasPrefix:@"CUI_MENUACTION_"]==NO)
        return NO;
    
    tResponds=[_sourcesViewController respondsToSelector:aSelector];
    
    if (tResponds==YES)
        return YES;
    
    return [_listViewController respondsToSelector:aSelector];
}

#pragma mark -

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _listViewController.view.frame=_crashLogsListContainerView.bounds;
    
    [_crashLogsListContainerView addSubview:_listViewController.view];
    
    _sourcesViewController.view.frame=_crashLogsSourcesContainerView.bounds;
    
    [_crashLogsSourcesContainerView addSubview:_sourcesViewController.view];
    
    
    [_sourcesViewController.lastKeyView setNextKeyView:_listViewController.firstKeyView];
}

- (void)viewDidAppear
{
    [super viewDidAppear];
    
    // Restore SplitView divider position
    
    NSUserDefaults * tUserDefaults=[NSUserDefaults standardUserDefaults];
    
    NSNumber * tNumber=[tUserDefaults objectForKey:CUIDefaultsSidebarTopCollapsedKey];
    
    if ([tNumber boolValue]==YES)
    {
        [_splitView setPosition:[_splitView minPossiblePositionOfDividerAtIndex:0] ofDividerAtIndex:0];
    }
    else
    {
        tNumber=[tUserDefaults objectForKey:CUIDefaultsSidebarTopHeightKey];
        
        if (tNumber!=nil)
            [self _splitView:_splitView resizeSubviewsWithTopHeight:[tNumber doubleValue]];
    }
    
    [self.view.window makeFirstResponder:_listViewController.firstKeyView];
}

- (void)viewWillDisappear
{
    // Save SplitView divider position
    
    NSArray * tSubviews=_splitView.subviews;
    
    NSView * tViewTop=tSubviews[0];
    
    NSUserDefaults * tUserDefaults=[NSUserDefaults standardUserDefaults];
    
    [tUserDefaults setObject:@(NSHeight(tViewTop.frame)) forKey:CUIDefaultsSidebarTopHeightKey];
    
    [tUserDefaults setBool:[_splitView isSubviewCollapsed:tViewTop] forKey:CUIDefaultsSidebarTopCollapsedKey];
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{    
    SEL tAction=inMenuItem.action;
    
    if ([_sourcesViewController respondsToSelector:tAction]==YES)
    {
        return [_sourcesViewController validateMenuItem:inMenuItem];
    }
    
    if ([_listViewController respondsToSelector:tAction]==YES)
    {
        return [_listViewController validateMenuItem:inMenuItem];
    }
    
    if ([self respondsToSelector:tAction]==NO)
        return [self.parentViewController validateMenuItem:inMenuItem];
    
    return YES;
}

- (void)_splitView:(NSSplitView *)inSplitView resizeSubviewsWithTopHeight:(CGFloat)inTopHeight
{
    NSRect tSplitViewFrame=inSplitView.frame;
    
    NSArray * tSubviews=inSplitView.subviews;
    
    NSView *tViewTop=tSubviews[0];
    
    NSRect tTopFrame=tViewTop.frame;
    
    tTopFrame.size.height=inTopHeight;
    
    NSView *tViewBottom=tSubviews[1];
    
    NSRect tBottomFrame=tViewBottom.frame;
    
    CGFloat tTopHeight=([inSplitView isSubviewCollapsed:tViewTop]==NO) ? NSHeight(tTopFrame) : 0;
    
    
    tBottomFrame.size.height=NSHeight(tSplitViewFrame)-inSplitView.dividerThickness-tTopHeight;
    
    if (NSHeight(tBottomFrame)<CUICrashLogsListMinimumHeight)
    {
        tBottomFrame.size.height=CUICrashLogsListMinimumHeight;
        
        tTopFrame.size.height=NSHeight(tSplitViewFrame)-inSplitView.dividerThickness-NSHeight(tBottomFrame);
        
        if (NSHeight(tTopFrame)<CUICrashLogsSourcesMinimumHeight)
            tTopFrame.size.height=CUICrashLogsSourcesMinimumHeight;
    }
    
    tTopFrame.origin.x=0;
    tTopFrame.origin.y=0;//NSHeight(tBottomFrame)+inSplitView.dividerThickness;
    tTopFrame.size.width=NSWidth(tSplitViewFrame);
    
    tViewTop.frame=tTopFrame;
    
    tBottomFrame.origin.y=NSHeight(tTopFrame)+inSplitView.dividerThickness;
    tBottomFrame.size.width=NSWidth(tSplitViewFrame);
    tViewBottom.frame=tBottomFrame;
}

#pragma mark - NSSplitViewDelegate

- (BOOL)splitView:(NSSplitView *)inSplitView canCollapseSubview:(NSView *)subview
{
    return NO;
}

- (void)splitView:(NSSplitView *)inSplitView resizeSubviewsWithOldSize:(NSSize)oldSize
{
    NSArray * tSubviews=inSplitView.subviews;
    
    NSView *tViewTop=tSubviews[0];
    
    NSRect tTopFrame=tViewTop.frame;
    
    [self _splitView:inSplitView resizeSubviewsWithTopHeight:NSHeight(tTopFrame)];
}

- (CGFloat)splitView:(NSSplitView *)inSplitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)inDividerIndex
{
    if (inDividerIndex==0)
        return CUICrashLogsSourcesMinimumHeight;
    
    return 0;
}

- (CGFloat)splitView:(NSSplitView *)inSplitView constrainMaxCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)inDividerIndex
{
    if (inDividerIndex==0)
    {
        return (NSHeight(inSplitView.frame)-(inSplitView.dividerThickness+CUICrashLogsListMinimumHeight));
    }
    
    return 0;
}

- (NSRect)splitView:(NSSplitView *)inSplitView effectiveRect:(NSRect)proposedEffectiveRect forDrawnRect:(NSRect)drawnRect ofDividerAtIndex:(NSInteger)inDividerIndex
{
    if (inDividerIndex==0)
    {
        return _sourcesViewController.effectiveBottonBarRect;
    }
    
    return NSZeroRect;
}

#pragma mark - CUIKeyViews

- (NSView *)firstKeyView
{
    return [_sourcesViewController firstKeyView];
}

- (NSView *)lastKeyView
{
    return [_listViewController lastKeyView];
}

@end
