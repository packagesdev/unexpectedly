/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICrashLogsMainViewController.h"

#import "CUISidebarViewController.h"

#import "CUIContentsViewController.h"

#import "CUIRightViewController.h"

#import "CUICrashLogsSelection.h"

#define CUISidebarMinimumWidth 250

#define CUIContentsMinimumWidth 700

#define CUIInspectorMinimumWidth 250

typedef NS_ENUM(NSUInteger, CUISplitViewSubViewTag)
{
    CUISplitViewSidebarViewTag=0,
    CUISplitViewMiddleViewTag=1,
    CUISplitViewInspectorViewTag=2,
};


NSString * const CUIDefaultsSidebarWidthKey=@"sidebar.width";

NSString * const CUIDefaultsSidebarCollapsedKey=@"sidebar.collapsed";


NSString * const CUIDefaultsInspectorViewWidthKey=@"rightView.width";

NSString * const CUIDefaultsInspectorViewCollapsedKey=@"rightView.collapsed";


@interface CUICrashLogsMainViewController () <NSSplitViewDelegate>
{
    IBOutlet NSSplitView * _splitView;
    
    IBOutlet NSView * _leftView;
    
    IBOutlet NSView * _middleView;
    
    IBOutlet NSView * _rightView;
    
    CUISidebarViewController * _sidebarViewController;
    
    CUIContentsViewController * _contentsViewController;
    
    CUIRightViewController * _inspectorViewController;
    
}

- (void)updateNextKeyViews;

- (IBAction)showHideViews:(id)sender;

//- (IBAction)switchPresentationMode:(NSMenuItem *)sender;

- (void)_splitView:(NSSplitView *)inSplitView resizeSubviewsWithSidebarWidth:(CGFloat)inSidebarWidth inspectorViewWidth:(CGFloat)inInspectorViewWidth;

@end

@implementation CUICrashLogsMainViewController

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _sidebarViewController=[CUISidebarViewController new];
        
        _contentsViewController=[CUIContentsViewController new];
        
        _inspectorViewController=[CUIRightViewController new];
        
        [self addChildViewController:_sidebarViewController];
        
        [self addChildViewController:_contentsViewController];
        
        [self addChildViewController:_inspectorViewController];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - NSObject

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    if ([_contentsViewController respondsToSelector:aSelector]==YES)
    {
        return _contentsViewController;
    }
    
    if ([_sidebarViewController respondsToSelector:aSelector]==YES)
    {
        return _sidebarViewController;
    }
    
    return nil;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    BOOL tResponds=[super respondsToSelector:aSelector];
    
    if (tResponds==YES)
        return YES;
    
    NSString * tSelectorName=NSStringFromSelector(aSelector);
    
    if ([tSelectorName hasPrefix:@"CUI_MENUACTION_"]==NO && [tSelectorName isEqualToString:@"performTextFinderAction:"]==NO)
        return NO;
    
    tResponds=[_contentsViewController respondsToSelector:aSelector];

    if (tResponds==YES)
        return YES;

    return [_sidebarViewController respondsToSelector:aSelector];
}

#pragma mark -

- (NSString *)nibName
{
    return @"CUICrashLogsMainViewController";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    BOOL tIsLeftToRightLayout=(_splitView.userInterfaceLayoutDirection==NSUserInterfaceLayoutDirectionLeftToRight);
    
    NSView *tSidebarView;
    NSView *tInspectorView;
    
    if (tIsLeftToRightLayout==YES)
    {
        tSidebarView=_leftView;
        tInspectorView=_rightView;
    }
    else
    {
        tSidebarView=_rightView;
        tInspectorView=_leftView;
    }
    
    _inspectorViewController.view.frame=tInspectorView.bounds;
    
    [tInspectorView addSubview:_inspectorViewController.view];
    
    _contentsViewController.view.frame=_middleView.bounds;
    
    [_middleView addSubview:_contentsViewController.view];
    
    _sidebarViewController.view.frame=tSidebarView.bounds;
    
    [tSidebarView addSubview:_sidebarViewController.view];
    
    [self updateNextKeyViews];
}

- (void)viewDidAppear
{
    [super viewDidAppear];
    
    // Restore SplitView divider position
    
    BOOL tIsLeftToRightLayout=(_splitView.userInterfaceLayoutDirection==NSUserInterfaceLayoutDirectionLeftToRight);
    NSUserDefaults * tUserDefaults=[NSUserDefaults standardUserDefaults];
    
    NSNumber * tNumber=[tUserDefaults objectForKey:CUIDefaultsSidebarCollapsedKey];
    
    if ([tNumber boolValue]==YES)
    {
        if (tIsLeftToRightLayout==YES)
            [_splitView setPosition:[_splitView minPossiblePositionOfDividerAtIndex:0] ofDividerAtIndex:0];
        else
             [_splitView setPosition:[_splitView maxPossiblePositionOfDividerAtIndex:1] ofDividerAtIndex:1];
    }
    
    tNumber=[tUserDefaults objectForKey:CUIDefaultsInspectorViewCollapsedKey];
    
    if ([tNumber boolValue]==YES)
    {
        if (tIsLeftToRightLayout==NO)
            [_splitView setPosition:[_splitView minPossiblePositionOfDividerAtIndex:0] ofDividerAtIndex:0];
        else
            [_splitView setPosition:[_splitView maxPossiblePositionOfDividerAtIndex:1] ofDividerAtIndex:1];
    }
    
    CGFloat tSidebarWidth=CUISidebarMinimumWidth;
    
    tNumber=[tUserDefaults objectForKey:CUIDefaultsSidebarWidthKey];
    
    if (tNumber!=nil)
        tSidebarWidth=[tNumber doubleValue];
    
    CGFloat tInspectorViewWidth=CUIInspectorMinimumWidth;
    
    tNumber=[tUserDefaults objectForKey:CUIDefaultsInspectorViewWidthKey];
    
    if (tNumber!=nil)
        tInspectorViewWidth=[tNumber doubleValue];
    
    [self _splitView:_splitView resizeSubviewsWithSidebarWidth:tSidebarWidth inspectorViewWidth:tInspectorViewWidth];
}

- (void)viewWillDisappear
{
    // Save SplitView divider position
    
    NSView * tSidebarView=nil;
    NSView * tInspectorView=nil;
    
    if (_splitView.userInterfaceLayoutDirection==NSUserInterfaceLayoutDirectionLeftToRight)
    {
        tSidebarView=_leftView;
        tInspectorView=_rightView;
    }
    else
    {
        tSidebarView=_rightView;
        tInspectorView=_leftView;
    }
    
    NSUserDefaults * tUserDefaults=[NSUserDefaults standardUserDefaults];
    
    [tUserDefaults setObject:@(NSWidth(tSidebarView.frame)) forKey:CUIDefaultsSidebarWidthKey];
    
    [tUserDefaults setBool:[_splitView isSubviewCollapsed:tSidebarView] forKey:CUIDefaultsSidebarCollapsedKey];
    
    [tUserDefaults setObject:@(NSWidth(tInspectorView.frame)) forKey:CUIDefaultsInspectorViewWidthKey];
    
    [tUserDefaults setBool:[_splitView isSubviewCollapsed:tInspectorView] forKey:CUIDefaultsInspectorViewCollapsedKey];
}

#pragma mark -

- (void)updateNextKeyViews
{
    NSView * tContentsFirstKeyView=_contentsViewController.firstKeyView;
    
    if (tContentsFirstKeyView==nil)
    {
        [_sidebarViewController.lastKeyView setNextKeyView:_sidebarViewController.firstKeyView];
    }
    else
    {
        [_sidebarViewController.lastKeyView setNextKeyView:_contentsViewController.firstKeyView];
    
        [_contentsViewController.lastKeyView setNextKeyView:_sidebarViewController.firstKeyView];
    }
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
    SEL tAction=inMenuItem.action;
    
    if ([super respondsToSelector:tAction]==NO)
    {
        NSString * tSelectorName=NSStringFromSelector(tAction);
        
        if ([tSelectorName hasPrefix:@"CUI_MENUACTION_"]==NO && [tSelectorName isEqualToString:@"performTextFinderAction:"]==NO)
            return NO;
        
        if ([_contentsViewController respondsToSelector:tAction]==YES)
            return [_contentsViewController validateMenuItem:inMenuItem];
            
        if ([_sidebarViewController respondsToSelector:tAction]==YES)
            return [_sidebarViewController validateMenuItem:inMenuItem];
        
        return NO;
    }
    
    if (tAction==@selector(showHideViews:)==YES)
    {
        NSView * sidebarView=nil;
        NSView * inspectorView=nil;
        
        if (_splitView.userInterfaceLayoutDirection==NSUserInterfaceLayoutDirectionLeftToRight)
        {
            sidebarView=_leftView;
            inspectorView=_rightView;
        }
        else
        {
            sidebarView=_rightView;
            inspectorView=_leftView;
        }
        
        switch(inMenuItem.tag)
        {
            case CUISplitViewSidebarViewTag:
                
                inMenuItem.title=([_splitView isSubviewCollapsed:sidebarView]==YES) ? NSLocalizedString(@"Show Sidebar", @"") : NSLocalizedString(@"Hide Sidebar", @"");
                
                break;
                
            case CUISplitViewMiddleViewTag:
                
                inMenuItem.title=(_contentsViewController.isBottomViewCollapsed==YES) ? NSLocalizedString(@"Show Binary Images", @"") : NSLocalizedString(@"Hide Binary Images", @"");
                
                if ([CUICrashLogsSelection sharedSelection].crashLogs.count==0)
                    return NO;
                
                if (_contentsViewController.presentationMode!=CUIPresentationModeOutline)
                    return NO;
                
                break;
                
            case CUISplitViewInspectorViewTag:
                
                inMenuItem.title=([_splitView isSubviewCollapsed:inspectorView]==YES) ? NSLocalizedString(@"Show Inspector", @"") : NSLocalizedString(@"Hide Inspector", @"");
                
                break;
        }
    }
    
    return YES;
}

- (IBAction)showHideViews:(id)sender
{
    BOOL tIsLeftViewCollapsed=[_splitView isSubviewCollapsed:_leftView];
    BOOL tIsRightViewCollapsed=[_splitView isSubviewCollapsed:_rightView];
    
    CUISplitViewSubViewTag tSwitchTag=-1;
    
    if ([sender isKindOfClass:[NSSegmentedControl class]]==YES)
    {
        tSwitchTag=1;
        
        NSSegmentedControl * tSegmentedControl=(NSSegmentedControl *)sender;
        
        if ([tSegmentedControl isSelectedForSegment:0]==tIsLeftViewCollapsed)
            tSwitchTag=0;
        
        if ([tSegmentedControl isSelectedForSegment:2]==tIsRightViewCollapsed)
            tSwitchTag=2;
    }
    else if ([sender isKindOfClass:[NSMenuItem class]]==YES)
    {
        tSwitchTag=((NSMenuItem *) sender).tag;
    }
    
    NSWindow * tWindow=self.view.window;
    
    switch(tSwitchTag)
    {
        case 0:
            
            if (tIsLeftViewCollapsed==NO)
            {
                [_splitView setPosition:[_splitView minPossiblePositionOfDividerAtIndex:0] ofDividerAtIndex:0];
                
                if (tWindow.firstResponder==tWindow)
                    [tWindow makeFirstResponder:self];
            }
            else
            {
                CGFloat tPosition=NSWidth(_leftView.frame);
                
                [_splitView setPosition:tPosition ofDividerAtIndex:0];
                
                [self splitView:_splitView resizeSubviewsWithOldSize:_splitView.frame.size];
            }
            
            break;
        
        case 1:
            
            [_contentsViewController showHideBottomView:self];
            
            break;
            
        case 2:
            
            if (tIsRightViewCollapsed==NO)
            {
                [_splitView setPosition:[_splitView maxPossiblePositionOfDividerAtIndex:1] ofDividerAtIndex:1];
                
                if (tWindow.firstResponder==tWindow)
                {
                    [tWindow makeFirstResponder:self];
                }
            }
            else
            {
                CGFloat tPosition=NSWidth(_splitView.frame)-_splitView.dividerThickness-NSWidth(_rightView.frame);
                
                [_splitView setPosition:tPosition ofDividerAtIndex:1];
                
                [self splitView:_splitView resizeSubviewsWithOldSize:_splitView.frame.size];
            }
            
            break;
    }
    
    if (self.view.window.firstResponder==nil)
    {
        [self.view.window makeFirstResponder:_middleView];
    }
}

#pragma mark - NSSplitViewDelegate

- (void)_splitView:(NSSplitView *)inSplitView resizeSubviewsWithSidebarWidth:(CGFloat)inSidebarWidth inspectorViewWidth:(CGFloat)inInspectorViewWidth
{
    BOOL tIsLeftToRightLayout=(_splitView.userInterfaceLayoutDirection==NSUserInterfaceLayoutDirectionLeftToRight);
    
    NSView * tSidebarView=nil;
    NSView * tInspectorView=nil;
    
    if (tIsLeftToRightLayout==YES)
    {
        tSidebarView=_leftView;
        tInspectorView=_rightView;
    }
    else
    {
        tSidebarView=_rightView;
        tInspectorView=_leftView;
    }
    
    NSRect tSplitViewFrame=inSplitView.frame;
    
    NSRect tSidebarFrame=tSidebarView.frame;
    
    tSidebarFrame.size.width=inSidebarWidth;
    
    NSRect tContentsFrame=_middleView.frame;
    NSRect tInspectorFrame=tInspectorView.frame;
    
    tInspectorFrame.size.width=inInspectorViewWidth;
    
    
    CGFloat tSidebarWidth=([inSplitView isSubviewCollapsed:tSidebarView]==NO) ? NSWidth(tSidebarFrame) : 0.0;
    CGFloat tInspectorWidth=([inSplitView isSubviewCollapsed:tInspectorView]==NO) ? NSWidth(tInspectorFrame) : 0.0;
    
    tContentsFrame.size.width=NSWidth(tSplitViewFrame)-tSidebarWidth-tInspectorWidth-2*inSplitView.dividerThickness;
    
    if (tContentsFrame.size.width<CUIContentsMinimumWidth)
    {
        tContentsFrame.size.width=CUIContentsMinimumWidth;
        
        tInspectorWidth=NSWidth(tSplitViewFrame)-CUIContentsMinimumWidth-tSidebarWidth-2*inSplitView.dividerThickness;
        
        if (tInspectorWidth<CUIInspectorMinimumWidth)
        {
            tInspectorWidth=CUIInspectorMinimumWidth;
            tSidebarWidth=NSWidth(tSplitViewFrame)-CUIContentsMinimumWidth-CUIInspectorMinimumWidth-2*inSplitView.dividerThickness;
        }
    }
    
    if (inSplitView.userInterfaceLayoutDirection==NSUserInterfaceLayoutDirectionLeftToRight)
    {
        if ([inSplitView isSubviewCollapsed:tSidebarView]==NO)
        {
            tSidebarFrame.origin.x=0;
            tSidebarFrame.size.width=tSidebarWidth;
            tSidebarFrame.origin.y=0;
            tSidebarFrame.size.height=NSHeight(tSplitViewFrame);
            
            tSidebarView.frame=tSidebarFrame;
        }
        
        tContentsFrame.origin.x=tSidebarWidth+inSplitView.dividerThickness;
        tContentsFrame.origin.y=0;
        tContentsFrame.size.height=NSHeight(tSplitViewFrame);
        
        _middleView.frame=tContentsFrame;
        
        if ([inSplitView isSubviewCollapsed:tInspectorView]==NO)
        {
            tInspectorFrame.origin.x=NSWidth(tSplitViewFrame)-tInspectorWidth;
            tInspectorFrame.size.width=tInspectorWidth;
            tInspectorFrame.origin.y=0;
            tInspectorFrame.size.height=NSHeight(tSplitViewFrame);
            
            tInspectorView.frame=tInspectorFrame;
        }
    }
    else
    {
        if ([inSplitView isSubviewCollapsed:tSidebarView]==NO)
        {
            tSidebarFrame.origin.x=NSMaxX(tSplitViewFrame)-tSidebarWidth;
            tSidebarFrame.size.width=tSidebarWidth;
            tSidebarFrame.origin.y=0;
            tSidebarFrame.size.height=NSHeight(tSplitViewFrame);
            
            tSidebarView.frame=tSidebarFrame;
        }
        
        tContentsFrame.origin.x=tInspectorWidth+inSplitView.dividerThickness;
        tContentsFrame.origin.y=0;
        tContentsFrame.size.height=NSHeight(tSplitViewFrame);
        
        _middleView.frame=tContentsFrame;
        
        if ([inSplitView isSubviewCollapsed:tInspectorView]==NO)
        {
            tInspectorFrame.origin.x=0;
            tInspectorFrame.size.width=tInspectorWidth;
            tInspectorFrame.origin.y=0;
            tInspectorFrame.size.height=NSHeight(tSplitViewFrame);
            
            tInspectorView.frame=tInspectorFrame;
        }
    }
}

- (BOOL)splitView:(NSSplitView *)inSplitView canCollapseSubview:(NSView *)inSubview
{
    if (inSubview==_leftView ||
        inSubview==_rightView)
        return YES;
    
    return NO;
}

- (void)splitView:(NSSplitView *)inSplitView resizeSubviewsWithOldSize:(NSSize)oldSize
{
    BOOL tIsLeftToRightLayout=(_splitView.userInterfaceLayoutDirection==NSUserInterfaceLayoutDirectionLeftToRight);
    
    NSView * tSidebarView=nil;
    NSView * tInspectorView=nil;
    
    if (tIsLeftToRightLayout==YES)
    {
        tSidebarView=_leftView;
        tInspectorView=_rightView;
    }
    else
    {
        tSidebarView=_rightView;
        tInspectorView=_leftView;
    }
    
    [self _splitView:(NSSplitView *)inSplitView resizeSubviewsWithSidebarWidth:NSWidth(tSidebarView.frame) inspectorViewWidth:NSWidth(tInspectorView.frame)];
}

- (CGFloat)splitView:(NSSplitView *)inSplitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)inDividerIndex
{
    BOOL tIsLeftToRightLayout=(_splitView.userInterfaceLayoutDirection==NSUserInterfaceLayoutDirectionLeftToRight);
    
    switch(inDividerIndex)
    {
        case 0:
            
            if (tIsLeftToRightLayout==YES)
                return CUISidebarMinimumWidth;
            else
                return CUIInspectorMinimumWidth;
            
            break;
            
        case 1:
        {
            CGFloat tLeftWidth=([inSplitView isSubviewCollapsed:_leftView]==NO) ? NSWidth(_leftView.frame) : 0.0;
            
            return tLeftWidth+inSplitView.dividerThickness+CUIContentsMinimumWidth;
        }
            
        default:
            
            break;
    }
    
    return 0;
}

- (CGFloat)splitView:(NSSplitView *)inSplitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)inDividerIndex
{
    BOOL tIsLeftToRightLayout=(_splitView.userInterfaceLayoutDirection==NSUserInterfaceLayoutDirectionLeftToRight);
        
    switch(inDividerIndex)
    {
        case 0:
            
            return NSWidth(inSplitView.frame)-NSWidth(_rightView.frame)-inSplitView.dividerThickness-CUIContentsMinimumWidth-inSplitView.dividerThickness;
            
        case 1:
            
            if (tIsLeftToRightLayout==YES)
                return NSWidth(inSplitView.frame)-CUIInspectorMinimumWidth-inSplitView.dividerThickness;
            else
                return NSWidth(inSplitView.frame)-CUISidebarMinimumWidth-inSplitView.dividerThickness;
            
        default:
            
            break;
    }
    
    return 0;
}

@end
