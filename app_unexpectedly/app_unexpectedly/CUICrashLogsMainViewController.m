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
    CUISplitViewLeftViewTag=0,
    CUISplitViewMiddleViewTag=1,
    CUISplitViewRightViewTag=2,
};


NSString * const CUIDefaultsSidebarWidthKey=@"sidebar.width";

NSString * const CUIDefaultsSidebarCollapsedKey=@"sidebar.collapsed";


NSString * const CUIDefaultsRightViewWidthKey=@"rightView.width";

NSString * const CUIDefaultsRightViewCollapsedKey=@"rightView.collapsed";


@interface CUICrashLogsMainViewController () <NSSplitViewDelegate>
{
    IBOutlet NSSplitView * _splitView;
    
    IBOutlet NSView * _leftView;
    
    IBOutlet NSView * _middleView;
    
    IBOutlet NSView * _rightView;
    
    CUISidebarViewController * _sidebarViewController;
    
    CUIContentsViewController * _contentsViewController;
    
    CUIRightViewController * _rightViewController;
    
}

- (void)updateNetKeyViews;

- (IBAction)showHideViews:(id)sender;

//- (IBAction)switchPresentationMode:(NSMenuItem *)sender;

- (void)_splitView:(NSSplitView *)inSplitView resizeSubviewsWithSidebarWidth:(CGFloat)inSidebarWidth rightViewWidth:(CGFloat)inRightViewWidth;

@end

@implementation CUICrashLogsMainViewController

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _sidebarViewController=[CUISidebarViewController new];
        
        _contentsViewController=[CUIContentsViewController new];
        
        _rightViewController=[CUIRightViewController new];
        
        [self addChildViewController:_sidebarViewController];
        
        [self addChildViewController:_contentsViewController];
        
        [self addChildViewController:_rightViewController];
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
    
    _rightViewController.view.frame=_rightView.bounds;
    
    [_rightView addSubview:_rightViewController.view];
    
    _contentsViewController.view.frame=_middleView.bounds;
    
    [_middleView addSubview:_contentsViewController.view];
    
    _sidebarViewController.view.frame=_leftView.bounds;
    
    [_leftView addSubview:_sidebarViewController.view];
    
    [self updateNetKeyViews];
}

- (void)viewDidAppear
{
    [super viewDidAppear];
    
    // Restore SplitView divider position
    
    NSUserDefaults * tUserDefaults=[NSUserDefaults standardUserDefaults];
    
    NSNumber * tNumber=[tUserDefaults objectForKey:CUIDefaultsSidebarCollapsedKey];
    
    if ([tNumber boolValue]==YES)
        [_splitView setPosition:[_splitView minPossiblePositionOfDividerAtIndex:0] ofDividerAtIndex:0];
    
    tNumber=[tUserDefaults objectForKey:CUIDefaultsRightViewCollapsedKey];
    
    if ([tNumber boolValue]==YES)
        [_splitView setPosition:[_splitView maxPossiblePositionOfDividerAtIndex:1] ofDividerAtIndex:1];
    
    CGFloat tSidebarWidth=CUISidebarMinimumWidth;
    
    tNumber=[tUserDefaults objectForKey:CUIDefaultsSidebarWidthKey];
    
    if (tNumber!=nil)
        tSidebarWidth=[tNumber doubleValue];
    
    CGFloat tRightViewWidth=CUIInspectorMinimumWidth;
    
    tNumber=[tUserDefaults objectForKey:CUIDefaultsRightViewWidthKey];
    
    if (tNumber!=nil)
        tRightViewWidth=[tNumber doubleValue];
    
    [self _splitView:_splitView resizeSubviewsWithSidebarWidth:tSidebarWidth rightViewWidth:tRightViewWidth];
}

- (void)viewWillDisappear
{
    // Save SplitView divider position
    
    NSArray * tSubviews=_splitView.subviews;
    
    NSView * tSidebarView=tSubviews[0];
    
    NSUserDefaults * tUserDefaults=[NSUserDefaults standardUserDefaults];
    
    [tUserDefaults setObject:@(NSWidth(tSidebarView.frame)) forKey:CUIDefaultsSidebarWidthKey];
    
    [tUserDefaults setBool:[_splitView isSubviewCollapsed:tSidebarView] forKey:CUIDefaultsSidebarCollapsedKey];
    
    NSView * tRightView=tSubviews[2];
    
    [tUserDefaults setObject:@(NSWidth(tRightView.frame)) forKey:CUIDefaultsRightViewWidthKey];
    
    [tUserDefaults setBool:[_splitView isSubviewCollapsed:tRightView] forKey:CUIDefaultsRightViewCollapsedKey];
}

#pragma mark -

- (void)updateNetKeyViews
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
        switch(inMenuItem.tag)
        {
            case CUISplitViewLeftViewTag:
                
                inMenuItem.title=([_splitView isSubviewCollapsed:_leftView]==YES) ? NSLocalizedString(@"Show Sidebar", @"") : NSLocalizedString(@"Hide Sidebar", @"");
                
                break;
                
            case CUISplitViewMiddleViewTag:
                
                inMenuItem.title=(_contentsViewController.isBottomViewCollapsed==YES) ? NSLocalizedString(@"Show Binary Images", @"") : NSLocalizedString(@"Hide Binary Images", @"");
                
                if ([CUICrashLogsSelection sharedSelection].crashLogs.count==0)
                    return NO;
                
                if (_contentsViewController.presentationMode!=CUIPresentationModeOutline)
                    return NO;
                
                break;
                
            case CUISplitViewRightViewTag:
                
                inMenuItem.title=([_splitView isSubviewCollapsed:_rightView]==YES) ? NSLocalizedString(@"Show Inspector", @"") : NSLocalizedString(@"Hide Inspector", @"");
                
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
        tSwitchTag=CUISplitViewMiddleViewTag;
        
        NSSegmentedControl * tSegmentedControl=(NSSegmentedControl *)sender;
        
        if ([tSegmentedControl isSelectedForSegment:CUISplitViewLeftViewTag]==tIsLeftViewCollapsed)
            tSwitchTag=CUISplitViewLeftViewTag;
        
        if ([tSegmentedControl isSelectedForSegment:CUISplitViewRightViewTag]==tIsRightViewCollapsed)
            tSwitchTag=CUISplitViewRightViewTag;
    }
    else if ([sender isKindOfClass:[NSMenuItem class]]==YES)
    {
        tSwitchTag=((NSMenuItem *) sender).tag;
    }
    
    NSWindow * tWindow=self.view.window;
    
    switch(tSwitchTag)
    {
        case CUISplitViewLeftViewTag:
            
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
        
        case CUISplitViewMiddleViewTag:
            
            [_contentsViewController showHideBottomView:self];
            
            break;
            
        case CUISplitViewRightViewTag:
            
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

- (void)_splitView:(NSSplitView *)inSplitView resizeSubviewsWithSidebarWidth:(CGFloat)inSidebarWidth rightViewWidth:(CGFloat)inRightViewWidth
{
    NSRect tSplitViewFrame=inSplitView.frame;
    
    NSRect tLeftFrame=_leftView.frame;
    
    tLeftFrame.size.width=inSidebarWidth;
    
    NSRect tMiddleFrame=_middleView.frame;
    NSRect tRightFrame=_rightView.frame;
    
    tRightFrame.size.width=inRightViewWidth;
    
    CGFloat tLeftWidth=([inSplitView isSubviewCollapsed:_leftView]==NO) ? NSWidth(tLeftFrame) : 0.0;
    CGFloat tRightWidth=([inSplitView isSubviewCollapsed:_rightView]==NO) ? NSWidth(tRightFrame) : 0.0;
    
    tMiddleFrame.size.width=NSWidth(tSplitViewFrame)-tLeftWidth-tRightWidth-2*inSplitView.dividerThickness;
    
    if (tMiddleFrame.size.width<CUIContentsMinimumWidth)
    {
        tMiddleFrame.size.width=CUIContentsMinimumWidth;
        
        tRightWidth=NSWidth(tSplitViewFrame)-CUIContentsMinimumWidth-tLeftWidth-2*inSplitView.dividerThickness;
        
        if (tRightWidth<CUIInspectorMinimumWidth)
        {
            tRightWidth=CUIInspectorMinimumWidth;
            
            tLeftWidth=NSWidth(tSplitViewFrame)-CUIContentsMinimumWidth-CUIInspectorMinimumWidth-2*inSplitView.dividerThickness;
        }
    }
    
    if ([inSplitView isSubviewCollapsed:_leftView]==NO)
    {
        tLeftFrame.origin.x=0;
        tLeftFrame.size.width=tLeftWidth;
        tLeftFrame.origin.y=0;
        tLeftFrame.size.height=NSHeight(tSplitViewFrame);
        
        _leftView.frame=tLeftFrame;
    }
    
    tMiddleFrame.origin.x=tLeftWidth+inSplitView.dividerThickness;
    tMiddleFrame.origin.y=0;
    tMiddleFrame.size.height=NSHeight(tSplitViewFrame);
    
    _middleView.frame=tMiddleFrame;
    
    if ([inSplitView isSubviewCollapsed:_rightView]==NO)
    {
        tRightFrame.origin.x=NSWidth(tSplitViewFrame)-tRightWidth;
        tRightFrame.size.width=tRightWidth;
        tRightFrame.origin.y=0;
        tRightFrame.size.height=NSHeight(tSplitViewFrame);
        
        _rightView.frame=tRightFrame;
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
    NSArray * tSubviews=inSplitView.subviews;
    
    NSView *tSidebarView=tSubviews[0];
    NSView *tRightView=tSubviews[2];
    
    [self _splitView:(NSSplitView *)inSplitView resizeSubviewsWithSidebarWidth:NSWidth(tSidebarView.frame) rightViewWidth:NSWidth(tRightView.frame)];
}

- (CGFloat)splitView:(NSSplitView *)inSplitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)inDividerIndex
{
    switch(inDividerIndex)
    {
        case 0:
            
            return CUISidebarMinimumWidth;
            
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
    switch(inDividerIndex)
    {
        case 0:
            
            return NSWidth(inSplitView.frame)-NSWidth(_rightView.frame)-inSplitView.dividerThickness-CUIContentsMinimumWidth-inSplitView.dividerThickness;
            
        case 1:
            
            return NSWidth(inSplitView.frame)-CUIInspectorMinimumWidth-inSplitView.dividerThickness;
            
        default:
            
            break;
    }
    
    return 0;
}

@end
