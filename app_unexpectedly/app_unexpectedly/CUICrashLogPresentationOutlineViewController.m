/*
 Copyright (c) 2020-2024, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICrashLogPresentationOutlineViewController.h"

#import "CUIThreadNamedTableCellView.h"

#import "CUICrashLog+UI.h"

#import "CUIStackFrame+UI.h"

#import "CUIThreadsListViewController.h"
#import "CUIThreadsColumnViewController.h"

#import "CUICenteredLabelViewController.h"

#import "CUIBinaryImagesViewController.h"

#import "CUIExceptionTypePopUpViewController.h"

#import "CUICrashLogBrowsingStateRegistry.h"

#import "CUIApplicationPreferences.h"

NSString * const CUIDefaultsThreadsModeViewKey=@"ui.threadView";

NSString * const CUIDefaultsTopViewHeightKey=@"topView.height";

NSString * const CUIDefaultsTopViewCollapsedKey=@"topView.collapsed";

NSString * const CUIDefaultsBottomViewHeightKey=@"bottomView.height";

NSString * const CUIDefaultsBottomViewCollapsedKey=@"bottomView.collapsed";

NSString  * const CUIBottomViewCollapseStateDidChangeNotification=@"CUIBottomViewCollapseStateDidChangeNotification";

typedef NS_ENUM(NSUInteger, CUIThreadsModeView)
{
	CUIThreadsModeViewUnknown=0,
    CUIThreadsModeViewList=1,
	CUIThreadsModeViewColumn=2,
    CUIThreadsModeViewLightTable=3
};

#define CUIThreadsBottomBarHeight   16.0

#define CUIDiagnosticsViewMinimumHeight    60.0
#define CUIThreadsViewMinimumHeight    200.0
#define CUIBinaryImagesViewMinimumHeight    190.0

@interface CUICrashLogPresentationOutlineViewController () <CUIQuickHelpPopUpViewControllerDelegate,NSMenuItemValidation, NSOutlineViewDataSource,NSOutlineViewDelegate,NSPopoverDelegate,NSSplitViewDelegate>
{
	IBOutlet NSTextField * _exceptionTypeValue;
	
    IBOutlet NSButton * _exceptionTypeMoreInfoButton;
    
    IBOutlet NSSplitView * _splitView;
    
    IBOutlet NSView * _topView;
    
    IBOutlet NSTextView * _diagnosticMessageTextView;
    
    IBOutlet NSView * _middleView;
    
    IBOutlet NSView * _threadsContainerView;
    
    // Bottom bar
    
    IBOutlet NSButton * _showBinaryImagesButton;
    
    
    IBOutlet NSButton * _listModeButton;
    IBOutlet NSButton * _columnModeButton;
    IBOutlet NSButton * _lightTableModeButton;
    
    
    IBOutlet NSButton * _showOnlyCrashedThreadButton;
    
    
    IBOutlet NSView * _bottomView;

	
	CUIThreadsModeView _threadsViewMode;
	
    CUICenteredLabelViewController * _noThreadsViewController;
	CUIThreadsViewController * _threadsViewController;
    
    CUIBinaryImagesViewController * _binaryImagesViewController;
    
    NSAttributedString * _diagnosticHeader;
}

@property CUIOutlineModeDisplaySettings * displaySettings;

- (void)refresh;

- (IBAction)showMoreExceptionInfo:(id)sender;

- (IBAction)showInFinder:(id)sender;

- (IBAction)switchViewMode:(id)sender;





- (void)showThreadsViewForMode:(CUIThreadsModeView)inMode;

@end

@implementation CUICrashLogPresentationOutlineViewController

+ (void)initialize
{
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
                                                              CUIDefaultsThreadsModeViewKey:@(CUIThreadsModeViewList),
                                                              
                                                              CUIDefaultsTopViewCollapsedKey:@(NO),
                                                              CUIDefaultsTopViewHeightKey:@(92.0),
                                                              
                                                              CUIDefaultsBottomViewCollapsedKey:@(YES),
                                                              CUIDefaultsBottomViewHeightKey:@(CUIBinaryImagesViewMinimumHeight)
                                                              }];
}

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
        _diagnosticHeader=[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Diagnostics\n\n",@"")
                                                          attributes:@{
                                                                       NSForegroundColorAttributeName:[NSColor secondaryLabelColor],
                                                                       NSFontAttributeName:[NSFont systemFontOfSize:13.0 weight:NSFontWeightBold]
                                                                       
                                                                       }];
        
        
        self.visibleStackFrameComponents=CUIStackFrameByteOffsetComponent;

        
        _threadsViewMode=[[NSUserDefaults standardUserDefaults] integerForKey:CUIDefaultsThreadsModeViewKey];
	}
	
	return self;
}

#pragma mark -

- (NSString *)nibName
{
	return @"CUICrashLogPresentationOutlineViewController";
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _diagnosticMessageTextView.textContainerInset=NSMakeSize(8.0, 8.0);
    
    _listModeButton.state=NSControlStateValueOff;
    _columnModeButton.state=NSControlStateValueOff;
    _lightTableModeButton.state=NSControlStateValueOff;
    
	switch(_threadsViewMode)
    {
        case CUIThreadsModeViewList:
            
            _listModeButton.state=NSControlStateValueOn;
            
            break;
            
        case CUIThreadsModeViewColumn:
            
            _columnModeButton.state=NSControlStateValueOn;
            
            break;
            
        case CUIThreadsModeViewLightTable:
            
            _lightTableModeButton.state=NSControlStateValueOn;
            
            break;
            
        default:
            
            break;
    }
	
	
	_showOnlyCrashedThreadButton.state=(self.showOnlyCrashedThread==YES) ? NSControlStateValueOn : NSControlStateValueOff;
    
    _showByteOffsetButton.state=((self.visibleStackFrameComponents & CUIStackFrameByteOffsetComponent)!=0) ? NSControlStateValueOn : NSControlStateValueOff;
    
    _showMachineInstructionAddressButton.state=((self.visibleStackFrameComponents & CUIStackFrameMachineInstructionAddressComponent)!=0) ? NSControlStateValueOn : NSControlStateValueOff;
    
    _showBinaryNameButton.state=((self.visibleStackFrameComponents & CUIStackFrameBinaryNameComponent)!=0) ? NSControlStateValueOn : NSControlStateValueOff;
	
    
	[self showThreadsViewForMode:_threadsViewMode];
    
    _binaryImagesViewController=[CUIBinaryImagesViewController new];
    
    _binaryImagesViewController.view.frame=_bottomView.bounds;
    
    [_bottomView addSubview:_binaryImagesViewController.view];
}

- (void)viewDidAppear
{
    [super viewDidAppear];
    
    // Restore SplitView divider position
    
    NSUserDefaults * tUserDefaults=[NSUserDefaults standardUserDefaults];
    
    CGFloat tTopViewHeight=CUIDiagnosticsViewMinimumHeight;
    
    NSNumber * tNumber=[tUserDefaults objectForKey:CUIDefaultsTopViewCollapsedKey];
    
    if (tNumber==nil || [tNumber boolValue]==YES)
        [_splitView setPosition:[_splitView maxPossiblePositionOfDividerAtIndex:0] ofDividerAtIndex:0];
    
    tNumber=[tUserDefaults objectForKey:CUIDefaultsTopViewHeightKey];
    
    if (tNumber!=nil)
        tTopViewHeight=[tNumber doubleValue];
    
    

    
    tNumber=[tUserDefaults objectForKey:CUIDefaultsBottomViewCollapsedKey];
    
    if (tNumber==nil || [tNumber boolValue]==YES)
        [_splitView setPosition:[_splitView maxPossiblePositionOfDividerAtIndex:1] ofDividerAtIndex:1];
    
    CGFloat tBottomViewWHeight=CUIBinaryImagesViewMinimumHeight;
    
    tNumber=[tUserDefaults objectForKey:CUIDefaultsBottomViewHeightKey];
    
    if (tNumber!=nil)
        tBottomViewWHeight=[tNumber doubleValue];
    
    [self _splitView:_splitView resizeSubviewsWithTopViewHeight:tTopViewHeight bottomViewHeight:tBottomViewWHeight];
}

- (void)viewWillDisappear
{
    [super viewWillDisappear];
    
    // Save browsing state
    
    [self saveBrowsingState];
    
    // Save SplitView divider position
    
    NSUserDefaults * tUserDefaults=[NSUserDefaults standardUserDefaults];
    
    NSArray * tSubviews=_splitView.subviews;
    
    NSView * tTopView=tSubviews[0];
    
    [tUserDefaults setObject:@(NSHeight(tTopView.frame)) forKey:CUIDefaultsTopViewHeightKey];
    
    [tUserDefaults setBool:[_splitView isSubviewCollapsed:tTopView] forKey:CUIDefaultsTopViewCollapsedKey];
    
    NSView * tBottomView=tSubviews[2];
    
    [tUserDefaults setObject:@(NSHeight(tBottomView.frame)) forKey:CUIDefaultsBottomViewHeightKey];
    
    [tUserDefaults setBool:[_splitView isSubviewCollapsed:tBottomView] forKey:CUIDefaultsBottomViewCollapsedKey];
}

- (void)saveBrowsingState
{
    CUICrashLogBrowsingStateRegistry * tRegistry=[CUICrashLogBrowsingStateRegistry sharedRegistry];
    
    if (self.crashLog!=nil)
    {
        CUICrashLogBrowsingState * tBrowsingState=[tRegistry browsingStateForCrashLog:self.crashLog windowNumber:self.view.window.windowNumber];
        
        tBrowsingState.outlineModeDisplaySettings=[self.displaySettings copy];
    }
}

#pragma mark -

- (void)setCrashLog:(CUICrashLog *)inCrashLog
{
    [self saveBrowsingState];
    
    [super setCrashLog:inCrashLog];
	
    CUICrashLogBrowsingStateRegistry * tRegistry=[CUICrashLogBrowsingStateRegistry sharedRegistry];
    
    CUICrashLogBrowsingState * tBrowsingState=[tRegistry browsingStateForCrashLog:inCrashLog windowNumber:self.view.window.windowNumber];
    
    _displaySettings=[tBrowsingState.outlineModeDisplaySettings copy];
    
    if (self.displaySettings==nil)
    {
        // A COMPLETER
        
        self.displaySettings=[[CUIApplicationPreferences sharedPreferences].defaultOutlineModeDisplaySettings copy];
    }
    
    BOOL tIsRawCrashLog=[self.crashLog isMemberOfClass:[CUIRawCrashLog class]];
    
    _exceptionTypeMoreInfoButton.enabled=(tIsRawCrashLog==NO);
    
    NSUInteger tThreadsCount=0;
    
    if (tIsRawCrashLog==NO)
    {
        tThreadsCount=self.crashLog.backtraces.threads.count;
    }
    
    BOOL tAreBacktracesAvailable=(tThreadsCount>0);
    
    if (_noThreadsViewController!=nil)
    {
        if (tThreadsCount>0)
        {
            [self showThreadsViewForMode:_threadsViewMode];
        }
    }
    else
    {
        if (tThreadsCount==0)
        {
            [self showThreadsViewForMode:_threadsViewMode];
        }
    }
    
    _threadsViewController.crashLog=inCrashLog;
	
    _threadsViewController.showOnlyCrashedThread=self.displaySettings.showOnlyCrashedThread;
    
    _threadsViewController.visibleStackFrameComponents=self.displaySettings.visibleStackFrameComponents;
    
    
    
    _showOnlyCrashedThreadButton.enabled=(tIsRawCrashLog==NO && tAreBacktracesAvailable==YES);
    _showByteOffsetButton.enabled=(tIsRawCrashLog==NO && tAreBacktracesAvailable==YES);
    _showMachineInstructionAddressButton.enabled=(tIsRawCrashLog==NO && tAreBacktracesAvailable==YES);
    _showBinaryNameButton.enabled=(tIsRawCrashLog==NO && tAreBacktracesAvailable==YES);
    
    if (tIsRawCrashLog==NO && tAreBacktracesAvailable==YES)
    {
        _showOnlyCrashedThreadButton.state=(self.displaySettings.showOnlyCrashedThread==YES) ? NSControlStateValueOn : NSControlStateValueOff;
        
        _showByteOffsetButton.state=((self.displaySettings.visibleStackFrameComponents & CUIStackFrameByteOffsetComponent)==CUIStackFrameByteOffsetComponent) ? NSControlStateValueOn : NSControlStateValueOff;
        
        _showMachineInstructionAddressButton.state=((self.displaySettings.visibleStackFrameComponents & CUIStackFrameMachineInstructionAddressComponent)==CUIStackFrameMachineInstructionAddressComponent) ? NSControlStateValueOn : NSControlStateValueOff;
        
        _showBinaryNameButton.state=(((self.displaySettings.visibleStackFrameComponents & CUIStackFrameBinaryNameComponent)==CUIStackFrameBinaryNameComponent)!=0) ? NSControlStateValueOn : NSControlStateValueOff;
    }
    else
    {
        _showOnlyCrashedThreadButton.state=NSControlStateValueOff;
        
        _showByteOffsetButton.state=NSControlStateValueOff;
        
        _showMachineInstructionAddressButton.state=NSControlStateValueOff;
        
        _showBinaryNameButton.state=NSControlStateValueOff;
    }
    
    _binaryImagesViewController.crashLog=(tIsRawCrashLog==NO) ? inCrashLog : nil;
    
    [self refresh];
}

- (void)showThreadsViewForMode:(CUIThreadsModeView)inMode
{
	if ([self.crashLog isMemberOfClass:[CUIRawCrashLog class]]==YES ||
        self.crashLog.backtraces.threads.count==0)
    {
        if (_noThreadsViewController!=nil)
            return;
        
        [_threadsViewController.view removeFromSuperview];
        _threadsViewController=nil;
        
        _noThreadsViewController=[CUICenteredLabelViewController new];
        _noThreadsViewController.label=NSLocalizedString(@"No backtraces available", @"");
        _noThreadsViewController.labelSize=CUILabelSizeBig;
        
        NSRect tBounds=_threadsContainerView.bounds;
        
        _noThreadsViewController.view.frame=tBounds;
        
        
        [_threadsContainerView addSubview:_noThreadsViewController.view];
        
        NSWindow * tWindow=self.view.window;
        
        if (tWindow.firstResponder==tWindow)
            [tWindow makeFirstResponder:self];
        
        return;
    }

    [_noThreadsViewController.view removeFromSuperview];
    _noThreadsViewController=nil;
    
    [_threadsViewController.view removeFromSuperview];

    switch(inMode)
    {
        case CUIThreadsModeViewList:
            
            _threadsViewController=[CUIThreadsListViewController new];
            break;
            
        case CUIThreadsModeViewColumn:
            
            _threadsViewController=[CUIThreadsColumnViewController new];
            break;
            
        default:
            
            break;
    }
    
	NSRect tBounds=_threadsContainerView.bounds;
	
	_threadsViewController.view.frame=tBounds;
	
	
	[_threadsContainerView addSubview:_threadsViewController.view];
    
	_threadsViewController.crashLog=self.crashLog;
	
	_threadsViewController.showOnlyCrashedThread=self.showOnlyCrashedThread;
	
    _threadsViewController.visibleStackFrameComponents=self.visibleStackFrameComponents;
}

- (BOOL)isBinaryImagesViewCollapsed
{
    return ([_splitView isSubviewCollapsed:_bottomView]==YES);
}

- (BOOL)showOnlyCrashedThread
{
    return self.displaySettings.showOnlyCrashedThread;
}

- (void)setShowOnlyCrashedThread:(BOOL)inShowOnlyCrashedThread
{
    self.displaySettings.showOnlyCrashedThread=inShowOnlyCrashedThread;
    
    _threadsViewController.showOnlyCrashedThread=inShowOnlyCrashedThread;
}

- (void)setVisibleStackFrameComponents:(CUIStackFrameComponents)inVisibleStackFrameComponents
{
    [super setVisibleStackFrameComponents:inVisibleStackFrameComponents];
    
    self.displaySettings.visibleStackFrameComponents=inVisibleStackFrameComponents;
    
    _threadsViewController.visibleStackFrameComponents=inVisibleStackFrameComponents;
}

#pragma mark -

- (void)refresh
{
    CUICrashLog * tCrashLog=self.crashLog;

    NSMutableParagraphStyle * tMutableParagraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    
    tMutableParagraphStyle.tabStops=@[];
    
    tMutableParagraphStyle.lineSpacing=2.0;
    
    NSMutableAttributedString * tMutableAttributedString=[_diagnosticHeader mutableCopy];
    
    if ([tCrashLog isKindOfClass:[CUICrashLog class]]==NO)
    {
        _exceptionTypeValue.stringValue=@"";
        
        [tMutableAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"N/A", @"")
                                                                                         attributes:@{NSParagraphStyleAttributeName:tMutableParagraphStyle,
                                                                                                      NSForegroundColorAttributeName:[NSColor textColor]
                                                                                                      }]];
        
        _diagnosticMessageTextView.textStorage.attributedString=tMutableAttributedString;
    
        return;
    }
    
    NSString * tString=[tCrashLog.exceptionInformation displayedExceptionType];
    
    _exceptionTypeValue.stringValue=(tString!=nil) ? tString : @"";
    
    tString=tCrashLog.diagnosticMessages.messages;
    
    if (tString.length==0)
        tString=NSLocalizedString(@"N/A", @"");
    
    [tMutableAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:tString
                                                                                     attributes:@{NSParagraphStyleAttributeName:tMutableParagraphStyle,
                                                                                                  NSForegroundColorAttributeName:[NSColor textColor]
                                                                                                  }]];
    
    _diagnosticMessageTextView.textStorage.attributedString=tMutableAttributedString;
    
    [_diagnosticMessageTextView scrollPoint:NSZeroPoint];
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	return [super validateMenuItem:inMenuItem];
}

- (IBAction)showMoreExceptionInfo:(id)sender
{
    if ([self.crashLog isMemberOfClass:[CUIRawCrashLog class]]==YES)
        return;
    
    NSPopover * tExceptionTypeLookUpPopOver = [NSPopover new];
    tExceptionTypeLookUpPopOver.contentSize=NSMakeSize(500.0, 20.0);
    tExceptionTypeLookUpPopOver.behavior=NSPopoverBehaviorTransient;
    tExceptionTypeLookUpPopOver.animates=NO;
    tExceptionTypeLookUpPopOver.delegate=self;
    
    CUIExceptionTypePopUpViewController * tPopUpViewController=[CUIExceptionTypePopUpViewController new];
    tPopUpViewController.popover=tExceptionTypeLookUpPopOver;
    tPopUpViewController.delegate=self;
    [tPopUpViewController setExceptionType:self.crashLog.exceptionType signal:self.crashLog.exceptionSignal];
    
    tExceptionTypeLookUpPopOver.contentViewController=tPopUpViewController;
    
    NSView * tTrick=tPopUpViewController.view;  // This is used to trigger the viewDidLoad method of the contentViewController.
}

- (IBAction)showInFinder:(id)sender
{
	[[NSWorkspace sharedWorkspace] selectFile:self.crashLog.header.executablePath inFileViewerRootedAtPath:@""];
}

- (IBAction)showHideBottomView:(id)sender
{
    if ([_splitView isSubviewCollapsed:_bottomView]==YES)
    {
        CGFloat tPosition=NSHeight(_splitView.frame)-_splitView.dividerThickness-NSHeight(_bottomView.frame);
        
        [_splitView setPosition:tPosition ofDividerAtIndex:1];
    }
    else
    {
        [_splitView setPosition:[_splitView maxPossiblePositionOfDividerAtIndex:1] ofDividerAtIndex:1];
    }
}

- (IBAction)switchViewMode:(NSButton *)sender
{
    if (sender.tag==_threadsViewMode)
        return;
    
    switch(_threadsViewMode)
    {
        case CUIThreadsModeViewList:
            
            _listModeButton.state=NSControlStateValueOff;
            
            break;
            
        case CUIThreadsModeViewColumn:
            
            _columnModeButton.state=NSControlStateValueOff;
            
            break;
            
        case CUIThreadsModeViewLightTable:
            
            _lightTableModeButton.state=NSControlStateValueOff;
            
            break;
            
        default:
            
            break;
    }
    
    _threadsViewMode=sender.tag;
    
    [self showThreadsViewForMode:_threadsViewMode];
    
    [[NSUserDefaults standardUserDefaults] setInteger:_threadsViewMode forKey:CUIDefaultsThreadsModeViewKey];
}

- (IBAction)CUI_MENUACTION_switchShowOnlyCrashedThread:(NSButton *)sender
{
    BOOL tShow=(sender.state==NSControlStateValueOn);
    
    self.showOnlyCrashedThread=tShow;
	
	_threadsViewController.showOnlyCrashedThread=tShow;
}

#pragma mark - CUIQuickHelpPopUpViewControllerDelegate

- (void)quickHelpPopUpViewController:(CUIQuickHelpPopUpViewController *)inController didComputeSizeOfPopover:(NSPopover *)inPopover
{
    // Compute the coordinates for the popover
    
    NSRect tRect=_exceptionTypeMoreInfoButton.bounds;
    
    [inPopover showRelativeToRect:tRect
                           ofView:_exceptionTypeMoreInfoButton
                    preferredEdge:NSMaxYEdge];
}

#pragma mark - NSPopoverDelegate

- (void)popoverDidClose:(NSNotification *)inNotification
{
    NSWindow * tWindow=self.view.window;
    
    if (tWindow.firstResponder==tWindow.contentView)
        [tWindow makeFirstResponder:self];
}

#pragma mark - NSSplitViewDelegate

- (BOOL)splitView:(NSSplitView *)inSplitView canCollapseSubview:(NSView *)subview
{
    if (subview==_bottomView /*|| subview==_topView*/)
        return YES;
    
    return NO;
}

- (void)_splitView:(NSSplitView *)inSplitView resizeSubviewsWithTopViewHeight:(CGFloat)inTopViewHeight bottomViewHeight:(CGFloat)inBottomViewHeight
{
    NSRect tSplitViewFrame=inSplitView.frame;
    
    NSRect tTopFrame=_topView.frame;
    
    
    tTopFrame.size.height=inTopViewHeight;
    
    NSRect tMiddleFrame=_middleView.frame;
    NSRect tBottomFrame=_bottomView.frame;
    
    tBottomFrame.size.height=inBottomViewHeight;
    
    CGFloat tTopHeight=([inSplitView isSubviewCollapsed:_topView]==NO) ? NSHeight(tTopFrame) : 0.0;
    CGFloat tBottomHeight=([inSplitView isSubviewCollapsed:_bottomView]==NO) ? NSHeight(tBottomFrame) : 0.0;
    
    tMiddleFrame.size.height=NSHeight(tSplitViewFrame)-tTopHeight-tBottomHeight-2*inSplitView.dividerThickness;
    
    if (tMiddleFrame.size.height<CUIThreadsViewMinimumHeight)
    {
        tMiddleFrame.size.height=CUIThreadsViewMinimumHeight;
        
        tBottomHeight=NSHeight(tSplitViewFrame)-CUIThreadsViewMinimumHeight-tTopHeight-2*inSplitView.dividerThickness;
        
        if (tBottomHeight<CUIBinaryImagesViewMinimumHeight)
        {
            tBottomHeight=CUIBinaryImagesViewMinimumHeight;
            
            tTopHeight=NSHeight(tSplitViewFrame)-CUIThreadsViewMinimumHeight-CUIBinaryImagesViewMinimumHeight-2*inSplitView.dividerThickness;
        }
    }
    
    if ([inSplitView isSubviewCollapsed:_topView]==NO)
    {
        tTopFrame.origin.y=0;
        tTopFrame.size.height=tTopHeight;
        tTopFrame.origin.x=0;
        tTopFrame.size.width=NSWidth(tSplitViewFrame);
        
        _topView.frame=tTopFrame;
    }
    
    tMiddleFrame.origin.y=tTopHeight+inSplitView.dividerThickness;
    tMiddleFrame.origin.x=0;
    tMiddleFrame.size.width=NSWidth(tSplitViewFrame);
    
    _middleView.frame=tMiddleFrame;
    
    if ([inSplitView isSubviewCollapsed:_bottomView]==NO)
    {
        tBottomFrame.origin.y=NSHeight(tSplitViewFrame)-tBottomHeight;
        tBottomFrame.size.height=tBottomHeight;
        tBottomFrame.origin.x=0;
        tBottomFrame.size.width=NSWidth(tSplitViewFrame);
        
        _bottomView.frame=tBottomFrame;
    }
}

- (void)splitView:(NSSplitView *)inSplitView resizeSubviewsWithOldSize:(NSSize)oldSize
{
    NSArray * tSubviews=inSplitView.subviews;
    
    NSView *tTopView=tSubviews[0];
    NSView *tBottomView=tSubviews[2];
    
    [self _splitView:(NSSplitView *)inSplitView resizeSubviewsWithTopViewHeight:NSHeight(tTopView.frame) bottomViewHeight:NSHeight(tBottomView.frame)];
}

- (CGFloat)splitView:(NSSplitView *)inSplitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)inDividerIndex
{
    switch(inDividerIndex)
    {
        case 0:
            
            return CUIThreadsBottomBarHeight+inSplitView.dividerThickness+3;
            
        case 1:
        {
            CGFloat tTopHeight=([inSplitView isSubviewCollapsed:_topView]==NO) ? NSHeight(_topView.frame) : 0.0;
            
            return tTopHeight+inSplitView.dividerThickness+CUIThreadsViewMinimumHeight;
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
            
            return NSHeight(inSplitView.frame)-NSHeight(_bottomView.frame)-inSplitView.dividerThickness-CUIThreadsViewMinimumHeight-inSplitView.dividerThickness;
            
        case 1:
            
            return NSHeight(inSplitView.frame)-CUIBinaryImagesViewMinimumHeight-inSplitView.dividerThickness;
            
        default:
            
            break;
    }
    
    return 0;
}

- (NSRect)splitView:(NSSplitView *)inSplitView effectiveRect:(NSRect)proposedEffectiveRect forDrawnRect:(NSRect)drawnRect ofDividerAtIndex:(NSInteger)inDividerIndex
{
    if (inDividerIndex==0)
    {
        proposedEffectiveRect.size.height=CUIThreadsBottomBarHeight+inSplitView.dividerThickness+4.0;
        proposedEffectiveRect.origin.y-=CUIThreadsBottomBarHeight;
        
        return proposedEffectiveRect;
    }
    
    if (inDividerIndex==1)
    {
        proposedEffectiveRect.size.height=CUIThreadsBottomBarHeight+inSplitView.dividerThickness+4.0;
        proposedEffectiveRect.origin.y-=CUIThreadsBottomBarHeight;
        
        proposedEffectiveRect.origin.x=NSMaxX(_columnModeButton.frame);
        proposedEffectiveRect.size.width=NSMinX(_showOnlyCrashedThreadButton.frame)-proposedEffectiveRect.origin.x;

        return proposedEffectiveRect;
    }
    
    return NSZeroRect;
}

- (void)splitViewDidResizeSubviews:(NSNotification *)inNotification
{
    BOOL tIsCollapsed=self.isBinaryImagesViewCollapsed;
    
    _showBinaryImagesButton.state=(tIsCollapsed==NO) ? NSControlStateValueOn : NSControlStateValueOff;
    
    [NSNotificationCenter.defaultCenter postNotificationName:CUIBottomViewCollapseStateDidChangeNotification
                                                      object:self.view.window
                                                    userInfo:@{@"Collapsed":@(tIsCollapsed)}];
}

/* Given a divider index, return an additional rectangular area (in the coordinate system established by the split view's bounds) in which mouse clicks should also initiate divider dragging, or NSZeroRect to not add one. If a split view has no delegate, or if its delegate does not respond to this message, only mouse clicks within the effective frame of a divider initiate divider dragging.
 */
//- (NSRect)splitView:(NSSplitView *)splitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex


@end
