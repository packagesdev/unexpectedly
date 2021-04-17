/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICrashLogPresentationTextViewController.h"

#import "NSArray+WBExtensions.h"



#import "CUIBinaryImage+UI.h"

#import "CUIApplicationPreferences.h"
#import "CUIApplicationPreferences+Themes.h"

#import "CUIThemesManager.h"
#import "CUIThemeItemsGroup+UI.h"

#import "CUIRawTextTransformation.h"

#import "CUIExceptionTypePopUpViewController.h"

#import "CUICrashLogTextView.h"

#import "CUIdSYMBundlesManager.h"

#import "CUISymbolicationManager.h"

#import "CUILineJumperWindowController.h"

#import "CUIExportAccessoryViewController.h"

// Noodle

#import "NoodleLineNumberView.h"
#import "NoodleLineNumberMarker.h"


#import "CUICrashLogBrowsingStateRegistry.h"


NSString * const CUICrashLogPresentationTextViewFontSizeDelta=@"ui.text.fontSize.delta";

@interface CUICrashLogPresentationTextViewController () <NSTextViewDelegate,CUIExceptionTypePopUpViewControllerDelegate>
{
    IBOutlet CUICrashLogTextView * _textView;
    
    NoodleLineNumberView * _lineNumberView;
    
    IBOutlet NSPopUpButton * _sectionsVisibilityPopUpButton;
    
    IBOutlet NSButton * _colorsSyntaxButton;
    
    NSArray * _allLines;
    
    NSArray * _visibleLines;
    
    BOOL _wrapText;
    
    
    
    
    CGFloat _fontSizeDelta;
    
    //NSFont * _monospacedFont;
    
    CUIRawTextTransformation * _rawTextTranformation;
    
    CUIThemeItemsGroup * _textThemeItemsGroup;
    
    NSArray * _sectionsList;
    
    NSDictionary * _sectionsRanges;
}

@property CUITextModeDisplaySettings * displaySettings;

- (void)saveBrowsingState;

- (void)refreshText;

- (IBAction)CUI_MENUACTION_exportCrashLog:(id)sender;


- (IBAction)CUI_MENUACTION_jumpToCrashedThread:(id)sender;


- (IBAction)CUI_MENUACTION_increaseFontSize:(id)sender;

- (IBAction)CUI_MENUACTION_decreaseFontSize:(id)sender;

- (IBAction)CUI_MENUACTION_resetFontSize:(id)sender;

- (IBAction)CUI_MENUACTION_jumpToLine:(id)sender;

// Notifications

- (void)itemAttributesDidChange:(NSNotification *)inNotification;

- (void)currentThemeDidChange:(NSNotification *)inNotification;

- (void)jumpToSection:(NSNotification *)inNotification;

- (void)boundsDidChange:(NSNotification *)inNotification;


- (void)symbolicateAutomaticallyDidChange:(NSNotification *)inNotification;

- (void)showsLineNumbersDidChange:(NSNotification *)inNotification;

- (void)lineWrappingDidChange:(NSNotification *)inNotification;

- (void)dSYMBundlesManagerDidAddBundles:(NSNotification *)inNotification;

- (void)stackFrameSymbolicationDidSucceed:(NSNotification *)inNotification;

@end

@implementation CUICrashLogPresentationTextViewController

+ (void)initialize
{
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{CUICrashLogPresentationTextViewFontSizeDelta:@(0.0)}];
}

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _wrapText=YES;
        
        _fontSizeDelta=[[NSUserDefaults standardUserDefaults] doubleForKey:CUICrashLogPresentationTextViewFontSizeDelta];
        
        _rawTextTranformation=[CUIRawTextTransformation new];
        
        _textThemeItemsGroup=[[CUIThemesManager sharedManager].currentTheme itemsGroupWithIdentifier:[CUIApplicationPreferences groupIdentifierForPresentationMode:CUIPresentationModeText]];
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
    return @"CUICrashLogPresentationTextViewController";
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSScrollView * tScrollView=_textView.enclosingScrollView;
    
    _lineNumberView = [[NoodleLineNumberView alloc] initWithScrollView:tScrollView];
    
    tScrollView.verticalRulerView=_lineNumberView;
    tScrollView.hasHorizontalRuler=NO;
    tScrollView.hasVerticalRuler=YES;
    
    _textView.textContainerInset=NSMakeSize(8,300);
    
    _textView.delegate=self;
    
    _textView.textStorage.font=[[_textThemeItemsGroup attributesForItem:CUIThemeItemPlainText] font];
    
    _textView.displaysLinkToolTips=NO;
    
    _textView.linkTextAttributes = @{
                                     NSCursorAttributeName:[NSCursor pointingHandCursor]
                                     };
    
    [_textView setPostsBoundsChangedNotifications:YES];
    
    CUIThemeItemAttributes * tAttributes=[_textThemeItemsGroup attributesForItem:CUIThemeItemSelectionBackground];
    
    if (tAttributes!=nil)
        _textView.selectedTextAttributes=@{NSBackgroundColorAttributeName:tAttributes.color,
                                           NSForegroundColorAttributeName:[[_textThemeItemsGroup attributesForItem:CUIThemeItemSelectionText] color]
                                       };
                                       
                                       //NSBackgroundColorAttributeName:[NSColor unemphasizedSelectedTextBackgroundColor],
                                       //NSForegroundColorAttributeName:[NSColor unemphasizedSelectedTextColor],
                                       //NSBackgroundColorAttributeName:[NSColor greenColor]
    
    [self showsLineNumbers:[CUIApplicationPreferences sharedPreferences].showsLineNumbers];
    
    [self setWrapText:[CUIApplicationPreferences sharedPreferences].lineWrapping];
    
    // Register for notifications
    
    NSNotificationCenter * tNotificationCenter=[NSNotificationCenter defaultCenter];
    
    [tNotificationCenter addObserver:self selector:@selector(currentThemeDidChange:) name:CUIThemesManagerCurrentThemeDidChangeNotification object:nil];
}

- (void)viewDidAppear
{
    [super viewDidAppear];
    
    NSNotificationCenter * tNotificationCenter=[NSNotificationCenter defaultCenter];
    
    [tNotificationCenter addObserver:self selector:@selector(itemAttributesDidChange:) name:CUIThemeItemAttributesDidChangeNotification object:nil];

    
    
    [tNotificationCenter addObserver:self selector:@selector(jumpToSection:) name:@"jumpToSectionNotification" object:nil];
    
    [tNotificationCenter addObserver:self selector:@selector(boundsDidChange:) name:NSViewBoundsDidChangeNotification object:nil];
    
    
    [tNotificationCenter addObserver:self selector:@selector(symbolicateAutomaticallyDidChange:) name:CUIPreferencesSymbolicationSymbolicateAutomaticallyDidChangeNotification object:nil];
    
    
    [tNotificationCenter addObserver:self selector:@selector(showsLineNumbersDidChange:) name:CUIPreferencesTextModeShowsLineNumbersDidChangeNotification object:nil];
    
    [tNotificationCenter addObserver:self selector:@selector(lineWrappingDidChange:) name:CUIPreferencesTextModeLineWrappingDidChangeNotification object:nil];
    
    
    [tNotificationCenter addObserver:self selector:@selector(dSYMBundlesManagerDidAddBundles:) name:CUIdSYMBundlesManagerDidAddBundlesNotification object:nil];
    
    [tNotificationCenter addObserver:self selector:@selector(stackFrameSymbolicationDidSucceed:) name:CUIStackFrameSymbolicationDidSucceedNotification object:nil];
    
    [tNotificationCenter addObserver:self selector:@selector(handleKeyDown:) name:@"windowDidNotHandleKeyEventNotification" object:self.view.window];
}

- (void)viewWillDisappear
{
    [super viewWillDisappear];
    
    // Save browsing state
    
    [self saveBrowsingState];
    
    NSNotificationCenter * tNotificationCenter=[NSNotificationCenter defaultCenter];
    
    [tNotificationCenter removeObserver:self name:CUIThemeItemAttributesDidChangeNotification object:nil];
    
    //[tNotificationCenter removeObserver:self name:CUIThemesManagerCurrentThemeDidChangeNotification object:nil];
    
    [tNotificationCenter removeObserver:self name:@"jumpToSectionNotification" object:nil];
    
    [tNotificationCenter removeObserver:self name:NSViewBoundsDidChangeNotification object:nil];
    
    
    [tNotificationCenter removeObserver:self name:CUIPreferencesSymbolicationSymbolicateAutomaticallyDidChangeNotification object:nil];
    
    [tNotificationCenter removeObserver:self name:CUIPreferencesTextModeShowsLineNumbersDidChangeNotification object:nil];
    
    [tNotificationCenter removeObserver:self name:CUIPreferencesTextModeLineWrappingDidChangeNotification object:nil];
    
    
    [tNotificationCenter removeObserver:self name:CUIdSYMBundlesManagerDidAddBundlesNotification object:nil];
    
    [tNotificationCenter removeObserver:self name:CUIStackFrameSymbolicationDidSucceedNotification object:nil];
    
    [tNotificationCenter removeObserver:self name:@"windowDidNotHandleKeyEventNotification" object:nil];
}

#pragma mark -

- (void)saveBrowsingState
{
    CUICrashLogBrowsingStateRegistry * tRegistry=[CUICrashLogBrowsingStateRegistry sharedRegistry];
    
    if (self.crashLog!=nil)
    {
        CUICrashLogBrowsingState * tBrowsingState=[tRegistry browsingStateForCrashLog:self.crashLog windowNumber:self.view.window.windowNumber];
        
        tBrowsingState.textModeDisplaySettings=[self.displaySettings copy];
        
        NSRect tVisibleRect = _textView.visibleRect;
        
        NSLayoutManager * tLayoutManager = _textView.layoutManager;
        
        NSUInteger tNumberOfGlyphs = tLayoutManager.numberOfGlyphs;
        
        NSUInteger tGlyphIndex = 0;
        
        for (NSUInteger tLineNumber = 1; tGlyphIndex < tNumberOfGlyphs; tLineNumber++)
        {
            NSRange tLineRange;
            
            NSRect tLineRect=[tLayoutManager lineFragmentRectForGlyphAtIndex:tGlyphIndex effectiveRange:&tLineRange];
            
            if (NSIntersectsRect(tVisibleRect, tLineRect)==YES)
            {
                tBrowsingState.firstVisibleLineNumber=tLineNumber;
                
                NSRect tBounds=[tLayoutManager boundingRectForGlyphRange:tLineRange inTextContainer:_textView.textContainer];
                
                tBrowsingState.firstVisibleLineVerticalOffset=NSMinY(tVisibleRect)-NSMinY(tBounds);
                
                break;
            }
            
            tGlyphIndex = NSMaxRange(tLineRange);
        }
    }
}

- (BOOL)showOnlyCrashedThread
{
    return ((self.displaySettings.visibleSections & CUIDocumentBacktraceCrashedThreadSubSection)==CUIDocumentBacktraceCrashedThreadSubSection);
}

- (void)setShowOnlyCrashedThread:(BOOL)inShowOnlyCrashedThread
{
    if (inShowOnlyCrashedThread==YES)
    {
        self.displaySettings.visibleSections|=CUIDocumentBacktraceCrashedThreadSubSection;
    }
    else
    {
        self.displaySettings.visibleSections&=~CUIDocumentBacktraceCrashedThreadSubSection;
    }
}

- (void)setCrashLog:(CUICrashLog *)inCrashLog
{
    [self saveBrowsingState];
    
    [super setCrashLog:inCrashLog];
    
    CUICrashLogBrowsingStateRegistry * tRegistry=[CUICrashLogBrowsingStateRegistry sharedRegistry];
    
    CUICrashLogBrowsingState * tBrowsingState=[tRegistry browsingStateForCrashLog:inCrashLog windowNumber:self.view.window.windowNumber];
    
    self.displaySettings=[tBrowsingState.textModeDisplaySettings copy];
    
    if (self.displaySettings==nil)
    {
        self.displaySettings=[[CUIApplicationPreferences sharedPreferences].defaultTextModeDisplaySettings copy];
    }
    
    BOOL tIsRawCrashLog=[self.crashLog isMemberOfClass:[CUIRawCrashLog class]];
    
    _sectionsVisibilityPopUpButton.enabled=(tIsRawCrashLog==NO);
    
    _showOnlyCrashedThreadButton.enabled=(tIsRawCrashLog==NO);
    _showByteOffsetButton.enabled=(tIsRawCrashLog==NO);
    _showMachineInstructionAddressButton.enabled=(tIsRawCrashLog==NO);
    _showBinaryNameButton.enabled=(tIsRawCrashLog==NO);
    
    if (tIsRawCrashLog==NO)
    {
        _showOnlyCrashedThreadButton.state=((self.displaySettings.visibleSections & CUIDocumentBacktraceCrashedThreadSubSection)==CUIDocumentBacktraceCrashedThreadSubSection) ? NSOnState : NSOffState;
        
        _showByteOffsetButton.state=((self.displaySettings.visibleStackFrameComponents & CUIStackFrameByteOffsetComponent)==CUIStackFrameByteOffsetComponent) ? NSOnState : NSOffState;
        
        _showMachineInstructionAddressButton.state=((self.displaySettings.visibleStackFrameComponents & CUIStackFrameMachineInstructionAddressComponent)==CUIStackFrameMachineInstructionAddressComponent) ? NSOnState : NSOffState;
        
        _showBinaryNameButton.state=(((self.displaySettings.visibleStackFrameComponents & CUIStackFrameBinaryNameComponent)==CUIStackFrameBinaryNameComponent)!=0) ? NSOnState : NSOffState;
    }
    
    NSMutableArray * tLines=[NSMutableArray array];
    
    [inCrashLog.rawText enumerateLinesUsingBlock:^(NSString * bLine, BOOL * bOutStop) {
        
        [tLines addObject:bLine];
    }];
    
    _allLines=[tLines copy];
    
    if (tIsRawCrashLog==NO)
    {
        self.visibleStackFrameComponents=self.displaySettings.visibleStackFrameComponents;
    }
    else
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshText) object:nil];
        
        [self refreshText];
    }
    
    // Restore (vertical) scrolling position?
    
    if (tBrowsingState.firstVisibleLineNumber==NSNotFound ||
        (tBrowsingState.firstVisibleLineNumber==0 && tBrowsingState.firstVisibleLineNumber<0.01))
    {
        [_textView CUI_scrollPoint:NSZeroPoint];
        
        //[_textView scrollToBeginningOfDocument:self];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:CUICrashLogPresentationDisplayedSectionsDidChangeNotification object:nil];
        
        return;
    }
    
    NSLayoutManager * tLayoutManager = _textView.layoutManager;
            
    NSUInteger tNumberOfGlyphs = tLayoutManager.numberOfGlyphs;

    NSUInteger tGlyphIndex = 0;

    for (NSUInteger tLineNumber = 1; tGlyphIndex < tNumberOfGlyphs; tLineNumber++)
    {
        NSRange tLineRange;
        
        [tLayoutManager lineFragmentRectForGlyphAtIndex:tGlyphIndex effectiveRange:&tLineRange];
        
        if (tLineNumber == tBrowsingState.firstVisibleLineNumber)
        {
            // Scroll to line
            
            NSRect tBounds=[_textView.layoutManager boundingRectForGlyphRange:tLineRange inTextContainer:_textView.textContainer];
            
            tBounds.origin.x=0;
            
            tBounds.origin.y+=tBrowsingState.firstVisibleLineVerticalOffset;
            
            [_textView CUI_scrollPoint:tBounds.origin];
            
            break;
        }
        
        tGlyphIndex = NSMaxRange(tLineRange);
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self boundsDidChange:[NSNotification notificationWithName:NSViewBoundsDidChangeNotification object:self->_textView]];
        
    });
    
    //_textView.textStorage.font=[NSFont monospacedDigitSystemFontOfSize:11.0 weight:NSFontWeightRegular];
}

- (void)setVisibleStackFrameComponents:(CUIStackFrameComponents)inVisibleStackFrameComponents
{
    [super setVisibleStackFrameComponents:inVisibleStackFrameComponents];
    
    self.displaySettings.visibleStackFrameComponents=inVisibleStackFrameComponents;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshText) object:nil];
    
    [self refreshText];
}

- (NSRange)crashedThreadRange
{
    __block NSRange tRange=NSMakeRange(NSNotFound,0);
    
    [_textView.textStorage enumerateAttribute:CUIGenericAnchorAttributeName
                                      inRange:NSMakeRange(0,_textView.textStorage.length)
                                      options:0
                                   usingBlock:^(NSString * bValue, NSRange bRange, BOOL * bOutStop) {
                                       
                                       if (bValue==nil)
                                           return;
                                       
                                       if ([bValue isEqualToString:@"a:crashed_thread"])
                                       {
                                           tRange=bRange;
                                           *bOutStop=YES;
                                       }
                                   }];
    
    
    return tRange;
}

- (void)showsLineNumbers:(BOOL)inShowsLineNumbers
{
    NSScrollView * tScrollView=_textView.enclosingScrollView;
    
    BOOL tIsChange=(_textView.enclosingScrollView.rulersVisible!=inShowsLineNumbers);
    
    _textView.enclosingScrollView.rulersVisible=inShowsLineNumbers;
    
    [_textView.enclosingScrollView tile];
    
    if (tIsChange==YES && inShowsLineNumbers==YES)
    {
        // Offset to the right
        
        NSRect tVisibleRect=[_textView visibleRect];
        
        tVisibleRect.origin.x-=NSWidth(tScrollView.verticalRulerView.frame);
        
        [_textView scrollRectToVisible:tVisibleRect];
    }
    
    [self refreshLinesGutter];
}

- (void)setWrapText:(BOOL)inWrap
{
    if (_wrapText==inWrap)
        return;
    
    _wrapText=inWrap;
    
    NSScrollView * tScrollView=_textView.enclosingScrollView;
    
    if (_wrapText==NO)
    {
        tScrollView.hasHorizontalScroller=YES;
        tScrollView.hasVerticalScroller=YES;
        
        _textView.autoresizingMask=(NSViewWidthSizable | NSViewHeightSizable);

        NSClipView * tClipView=(NSClipView *)_textView.superview;
        NSRect tClipViewFrame=tClipView.frame;
        
        NSTextContainer * tTextContainer=[[NSTextContainer alloc] initWithContainerSize:NSMakeSize(10000000, 10000000)];
        
        [tTextContainer setWidthTracksTextView:NO];
        [tTextContainer setHeightTracksTextView:NO];
        
        [_textView replaceTextContainer:tTextContainer];
        
        _textView.minSize=tClipViewFrame.size;
        _textView.maxSize=NSMakeSize(10000000, 10000000);
        _textView.horizontallyResizable=YES;
        _textView.verticallyResizable=YES; 
    }
    else
    {
        tScrollView.hasHorizontalScroller=NO;
        tScrollView.hasVerticalScroller=YES;
        
        _textView.autoresizingMask=(NSViewWidthSizable | NSViewHeightSizable);
        
        NSClipView * tClipView=(NSClipView *)_textView.superview;
        NSRect tClipViewFrame=tClipView.frame;
        
        CGFloat tWidth=NSWidth(tClipViewFrame);
        
        NSTextContainer * tTextContainer=[[NSTextContainer alloc] initWithContainerSize:NSMakeSize(tWidth, 10000000)];
        
        [tTextContainer setWidthTracksTextView:YES];
        [tTextContainer setHeightTracksTextView:NO];
        
        [_textView replaceTextContainer:tTextContainer];
        
        _textView.minSize=tClipViewFrame.size;
        _textView.maxSize=NSMakeSize(tWidth, 10000000);
        _textView.horizontallyResizable=NO;
        _textView.verticallyResizable=YES;
    }
    
    _textView.autoresizingMask=NSViewNotSizable;
    
    tScrollView.rulersVisible=[CUIApplicationPreferences sharedPreferences].showsLineNumbers;
}

#pragma mark -

- (void)refreshLinesGutter
{
    // Update Line Numbers color
    
    CUIThemeItemAttributes * tAttributes=[_textThemeItemsGroup attributesForItem:CUIThemeItemLineNumber];
    
    _lineNumberView.textColor=tAttributes.color;
}

- (void)refreshText
{
    CUICrashLog * tCrashLog=self.crashLog;
    
    if (tCrashLog==nil)
        return;
    
    _lineNumberView.fontSizeDelta=_fontSizeDelta;
    
    _rawTextTranformation.displaySettings=self.displaySettings;
    
    _rawTextTranformation.fontSizeDelta=_fontSizeDelta;
    
    
    NSAttributedString * tAttributedString=[_rawTextTranformation transformCrashLog:tCrashLog lines:_allLines];
    
    _textView.backgroundColor=[[_textThemeItemsGroup attributesForItem:CUIThemeItemBackground] color];
    
    _lineNumberView.backgroundColor=[[_textThemeItemsGroup attributesForItem:CUIThemeItemBackground] color];
    
    _textView.selectedTextAttributes=@{
                                       NSBackgroundColorAttributeName:[[_textThemeItemsGroup attributesForItem:CUIThemeItemSelectionBackground] color],
                                       NSForegroundColorAttributeName:[[_textThemeItemsGroup attributesForItem:CUIThemeItemSelectionText] color]
                                       };
    
    _textView.textStorage.attributedString=tAttributedString;
    
    //[_textView.layoutManager ensureLayoutForTextContainer:_textView.textContainer];
    
    // Compute sections ranges
    
    __block NSString * tPreviousSection=nil;
    __block NSString * tCurrentSection=nil;
    
    NSMutableDictionary * tMutableDictionary=[NSMutableDictionary dictionary];
    
    NSMutableArray * tMutableArray=[NSMutableArray array];
    
    [tAttributedString enumerateAttributesInRange:NSMakeRange(0,tAttributedString.length)
                                          options:0
                                       usingBlock:^(NSDictionary<NSAttributedStringKey,id> * bAttributes, NSRange bRange, BOOL * bOutStop) {
                                           
                                           NSString * bValue=bAttributes[CUIThreadAnchorAttributeName];
                                           
                                           if (bValue==nil)
                                           {
                                               bValue=bAttributes[CUISectionAnchorAttributeName];
                                               
                                               if (bValue==nil)
                                                   return;
                                           }
                                           
                                           if (tMutableDictionary[bValue]!=nil)
                                               return;
                                           
                                           [tMutableArray addObject:bValue];
                                           
                                           tCurrentSection=bValue;
                                           
                                           tMutableDictionary[tCurrentSection]=[NSValue valueWithRange:bRange];
                                           
                                           if (tPreviousSection!=nil)
                                           {
                                               NSRange tPreviousRange=[tMutableDictionary[tPreviousSection] rangeValue];
                                               
                                               tPreviousRange.length=bRange.location-tPreviousRange.location;
                                               
                                               tMutableDictionary[tPreviousSection]=[NSValue valueWithRange:tPreviousRange];
                                           
                                           }
                                           
                                           tPreviousSection=tCurrentSection;
                                       }];
    
    if (tPreviousSection!=nil)
    {
        NSRange tPreviousRange=[tMutableDictionary[tPreviousSection] rangeValue];
        
        tPreviousRange.length=tAttributedString.length-tPreviousRange.location;
        
        tMutableDictionary[tPreviousSection]=[NSValue valueWithRange:tPreviousRange];
        
    }
    
    _sectionsList=[tMutableArray copy];
    
    _sectionsRanges=[tMutableDictionary copy];
}

#pragma mark - CUIExceptionTypePopUpViewControllerDelegate

- (void)exceptionTypePopUpViewController:(CUIExceptionTypePopUpViewController *)inController didComputeSizeOfPopover:(NSPopover *)inPopover
{
    __block NSRange tRange=NSMakeRange(NSNotFound,0);
    
    //:[NSURL URLWithString:@"a://exception_type"]
    
    
    [_textView.textStorage enumerateAttribute:NSLinkAttributeName
                                      inRange:NSMakeRange(0,_textView.textStorage.length)
                                      options:0
                                   usingBlock:^(NSURL * bValue, NSRange bRange, BOOL * bOutStop) {
                                       
                                       if ([bValue isKindOfClass:[NSURL class]]==NO)
                                           return;
                                       
                                       if ([bValue.absoluteString isEqualToString:@"a://exception_type"]==YES)
                                       {
                                           tRange=bRange;
                                           *bOutStop=YES;
                                       }
                                   }];
    
    if (tRange.location==NSNotFound)
        return;
    
    // Compute the coordinates for the popover
    
    NSRect tRect=[_textView.layoutManager boundingRectForGlyphRange:tRange inTextContainer:_textView.textContainer];
    
    NSPoint containerOrigin = [_textView textContainerOrigin];
    
    tRect=NSOffsetRect(tRect, containerOrigin.x, containerOrigin.y);
    
    [inPopover showRelativeToRect:tRect
                           ofView:_textView
                    preferredEdge:NSMaxYEdge];
}

#pragma mark - NSTextViewDelegate

- (BOOL)textView:(NSTextView *)inTextView clickedOnLink:(id)inLink atIndex:(NSUInteger)inCharIndex
{
    if ([inLink isKindOfClass:[NSURL class]]==YES)
    {
        NSURL * tURL=(NSURL *)inLink;
        
        if ([tURL.scheme isEqualToString:@"a"]==YES)
        {
            NSString * tHost=tURL.host;
            
            if ([tHost isEqualToString:@"crashed_thread"]==YES)
            {
                // Jump to crash thread line
                
                NSRange tCrashedThreadRange=[self crashedThreadRange];
                
                [_textView setSelectedRange:tCrashedThreadRange];
                
                [_textView scrollRangeToVisible:tCrashedThreadRange];
                
                return YES;
            }
            else if ([tHost isEqualToString:@"exception_type"]==YES)
            {
                __block NSRange tRange=NSMakeRange(NSNotFound,0);
                
                //:[NSURL URLWithString:@"a://exception_type"]
                

                [_textView.textStorage enumerateAttribute:NSLinkAttributeName
                                                  inRange:NSMakeRange(0,_textView.textStorage.length)
                                                  options:0
                                               usingBlock:^(NSURL * bValue, NSRange bRange, BOOL * bOutStop) {
                                                   
                                                   if ([bValue isKindOfClass:[NSURL class]]==NO)
                                                       return;
                                                   
                                                   if ([bValue.absoluteString isEqualToString:@"a://exception_type"]==YES)
                                                   {
                                                       tRange=bRange;
                                                       *bOutStop=YES;
                                                   }
                                               }];
                    
                if (tRange.location==NSNotFound)
                    return NO;
                
                
                
                NSPopover * tExceptionTypeLookUpPopOver = [NSPopover new];
                tExceptionTypeLookUpPopOver.contentSize=NSMakeSize(500.0, 20.0);
                tExceptionTypeLookUpPopOver.behavior=NSPopoverBehaviorTransient;
                tExceptionTypeLookUpPopOver.animates=NO;

                CUIExceptionTypePopUpViewController * tPopUpViewController=[CUIExceptionTypePopUpViewController new];
                tPopUpViewController.popover=tExceptionTypeLookUpPopOver;
                tPopUpViewController.delegate=self;
                
                
                [tPopUpViewController setExceptionType:self.crashLog.exceptionType signal:self.crashLog.exceptionSignal];
                
                tExceptionTypeLookUpPopOver.contentViewController=tPopUpViewController;
                
                NSView * tTrick=tPopUpViewController.view;  // This is used to trigger the viewDidLoad method of the contentViewController.

                
                
                return YES;
            }
        }
        else if ([tURL.scheme isEqualToString:@"bin"]==YES)
        {
            __block NSRange tRange=NSMakeRange(NSNotFound,0);
            
            NSString * tAnchorValue=[NSString stringWithFormat:@"bin:%@",tURL.host];
            
            [_textView.textStorage enumerateAttribute:CUIBinaryAnchorAttributeName
                                              inRange:NSMakeRange(0,_textView.textStorage.length)
                                              options:0
                                           usingBlock:^(NSString * bValue, NSRange bRange, BOOL * bOutStop) {
                                               
                                               if (bValue==nil)
                                                   return;
                                               
                                               if ([bValue isEqualToString:tAnchorValue])
                                               {
                                                   tRange=bRange;
                                                   *bOutStop=YES;
                                               }
                                           }];
            
            if (tRange.location!=NSNotFound)
            {
                [_textView setSelectedRange:tRange];
                
                [_textView scrollRangeToVisible:tRange];
            }
            
            return YES;
        }
        else if ([tURL.scheme hasPrefix:@"sourcecode-"]==YES)
        {
            //NSUInteger tLineNumber=[[tURL.scheme substringFromIndex:[@"sourcecode-" length]] integerValue];
            
            // BBEdit -> bbedit_tool file_path +line
            
            // Open the file in the appropriate source editor
            
            NSURL * tFileURL=[NSURL fileURLWithPath:tURL.path];
            
            [[NSWorkspace sharedWorkspace] openURLs:@[tFileURL]
                               withApplicationAtURL:[CUIApplicationPreferences sharedPreferences].preferedSourceCodeEditorURL
                                            options:NSWorkspaceLaunchDefault
                                      configuration:@{}
                                              error:NULL];
            
            return YES;
        }
    }
    
    return NO;
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
    SEL tAction=inMenuItem.action;
    CUICrashLog * tCrashLog=self.crashLog;
    
    // Text Viewer
    
    /*if (tAction==@selector(CUI_MENUACTION_switchSyntaxHighlighting:))
    {
        inMenuItem.state=(self.displaySettings.highlightSyntax==YES) ? NSOnState : NSOffState;
    }*/
    
    if (tAction==@selector(performTextFinderAction:))
    {
        return [_textView validateMenuItem:inMenuItem];
    }
    
    if (tAction==@selector(CUI_MENUACTION_resetFontSize:))
    {
        return (fabs(_fontSizeDelta)>=1);
    }
    
    if (tAction==@selector(CUI_MENUACTION_switchTheme:))
    {
        return [super validateMenuItem:inMenuItem];
    }
    
    // File Menu
    
    if (tAction==@selector(CUI_MENUACTION_print:))
    {
        return YES;
    }
    
    // Navigate Menu
    
    BOOL tIsRawCrashLog=[tCrashLog isMemberOfClass:[CUIRawCrashLog class]];
    
    if (tAction==@selector(CUI_MENUACTION_jumpToHeader:))
    {
        if (tIsRawCrashLog==YES)
            return NO;
        
        return ((self.displaySettings.visibleSections & CUIDocumentHeaderSection)==CUIDocumentHeaderSection);
    }
    
    if (tAction==@selector(CUI_MENUACTION_jumpToExceptionInformation:))
    {
        if (tIsRawCrashLog==YES)
            return NO;
        
        return ((self.displaySettings.visibleSections & CUIDocumentExceptionInformationSection)==CUIDocumentExceptionInformationSection);
    }
    
    if (tAction==@selector(CUI_MENUACTION_jumpToDiagnosticMessages:))
    {
        if (tIsRawCrashLog==YES)
            return NO;
        
        return ((self.displaySettings.visibleSections & CUIDocumentDiagnosticMessagesSection)==CUIDocumentDiagnosticMessagesSection);
    }
    
    if (tAction==@selector(CUI_MENUACTION_jumpToBacktraces:))
    {
        if (tIsRawCrashLog==YES)
            return NO;
        
        return ((self.displaySettings.visibleSections & CUIDocumentBacktracesSection)==CUIDocumentBacktracesSection);
    }
    
    if (tAction==@selector(CUI_MENUACTION_jumpToThreadState:))
    {
        if (tIsRawCrashLog==YES)
            return NO;
        
        return ((self.displaySettings.visibleSections & CUIDocumentThreadStateSection)==CUIDocumentThreadStateSection);
    }
    
    if (tAction==@selector(CUI_MENUACTION_jumpToBinaryImages:))
    {
        if (tIsRawCrashLog==YES)
            return NO;
        
        return ((self.displaySettings.visibleSections & CUIDocumentBinaryImagesSection)==CUIDocumentBinaryImagesSection);
    }
    
    if (tAction==@selector(CUI_MENUACTION_jumpToCrashedThread:))
    {
        if (tIsRawCrashLog==YES)
            return NO;
        
        return ((self.displaySettings.visibleSections & CUIDocumentBacktracesSection)==CUIDocumentBacktracesSection) &&
               ((self.displaySettings.visibleSections & CUIDocumentBacktraceCrashedThreadSubSection)==0);
    }
    
    if (tAction==@selector(CUI_MENUACTION_switchHeaderVisibility:))
    {
        if (tIsRawCrashLog==YES)
            return NO;
        
        BOOL tEnabled=(tCrashLog.headerRange.location!=NSNotFound);
        
        inMenuItem.state=(tEnabled==YES) ? ((self.displaySettings.visibleSections & CUIDocumentHeaderSection)==CUIDocumentHeaderSection) : NSOffState;
        
        return tEnabled;
    }
    
    if (tAction==@selector(CUI_MENUACTION_switchExceptionInformationVisibility:))
    {
        if (tIsRawCrashLog==YES)
            return NO;
        
        BOOL tEnabled=(tCrashLog.exceptionInformationRange.location!=NSNotFound);
        
        inMenuItem.state=(tEnabled==YES) ? ((self.displaySettings.visibleSections & CUIDocumentExceptionInformationSection)==CUIDocumentExceptionInformationSection) : NSOffState;
        
        return tEnabled;
    }
    
    if (tAction==@selector(CUI_MENUACTION_switchDiagnosticMessagesVisibility:))
    {
        if (tIsRawCrashLog==YES)
            return NO;
        
        BOOL tEnabled=(tCrashLog.diagnosticMessagesRange.location!=NSNotFound);
        
        inMenuItem.state=(tEnabled==YES) ? ((self.displaySettings.visibleSections & CUIDocumentDiagnosticMessagesSection)==CUIDocumentDiagnosticMessagesSection) : NSOffState;
        
        return tEnabled;
    }
    
    if (tAction==@selector(CUI_MENUACTION_switchBacktracesVisibility:))
    {
        if (tIsRawCrashLog==YES)
            return NO;
        
        BOOL tEnabled=(tCrashLog.backtracesRange.location!=NSNotFound);
        
        inMenuItem.state=(tEnabled==YES) ? ((self.displaySettings.visibleSections & CUIDocumentBacktracesSection)==CUIDocumentBacktracesSection) : NSOffState;
        
        return tEnabled;
    }
    
    if (tAction==@selector(CUI_MENUACTION_switchThreadStateVisibility:))
    {
        if (tIsRawCrashLog==YES)
            return NO;
        
        BOOL tEnabled=(tCrashLog.threadStateRange.location!=NSNotFound);
        
        inMenuItem.state=(tEnabled==YES) ? ((self.displaySettings.visibleSections & CUIDocumentThreadStateSection)==CUIDocumentThreadStateSection) : NSOffState;
        
        return tEnabled;
    }
    
    if (tAction==@selector(CUI_MENUACTION_switchBinaryImagesVisibility:))
    {
        if (tIsRawCrashLog==YES)
            return NO;
        
        BOOL tEnabled=(tCrashLog.binaryImagesRange.location!=NSNotFound);
        
        inMenuItem.state=(tEnabled==YES) ? ((self.displaySettings.visibleSections & CUIDocumentBinaryImagesSection)==CUIDocumentBinaryImagesSection) : NSOffState;
        
        return tEnabled;
    }

    
    return [super validateMenuItem:inMenuItem];
}

#pragma mark -

- (void)handleKeyDown:(NSNotification *)inNotification
{
    NSEvent * tEvent=inNotification.userInfo[@"Event"];
    
    NSString * tTypedText=tEvent.characters;
    
    NSUInteger tLength=tTypedText.length;
    
    for(NSUInteger tIndex=0;tIndex<tLength;tIndex++)
    {
        unichar tChar=[tTypedText characterAtIndex:tIndex];
        
        switch(tChar)
        {
            case NSHomeFunctionKey:
                
                [_textView scrollToBeginningOfDocument:self];
                return;
                
            case NSEndFunctionKey:
                
                [_textView scrollToEndOfDocument:self];
                break;
                
            case ' ':
            case NSPageDownFunctionKey:
                
                [_textView scrollPageDown:self];
                return;
                
            case 'b':
            case NSPageUpFunctionKey:
                
                [_textView scrollPageUp:self];
                return;
                
            case NSUpArrowFunctionKey:
                
                [_textView scrollLineUp:self];
                return;
                
            case NSDownArrowFunctionKey:
                
                [_textView scrollLineDown:self];
                return;
        }
    }
}

#pragma mark - File Menu

- (IBAction)CUI_MENUACTION_print:(id)sender
{
    NSPrintInfo * tPrintInfo=[NSPrintInfo sharedPrintInfo];
    
    tPrintInfo.topMargin=0;
    tPrintInfo.bottomMargin=0;
    tPrintInfo.leftMargin=0;
    tPrintInfo.rightMargin=0;
    
    tPrintInfo.verticallyCentered=NO;
    
    NSRect tFrame=NSMakeRect(0, 0, tPrintInfo.paperSize.width, tPrintInfo.paperSize.height);
    
    NSTextView * tPrintableTextView=[[NSTextView alloc] initWithFrame:tFrame];
    tPrintableTextView.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
    
    NSMutableAttributedString * tMutableAttributedString=[_textView.textStorage mutableCopy];
    
    [tMutableAttributedString setAttributes:@{NSForegroundColorAttributeName:[NSColor blackColor],
                                              NSBackgroundColorDocumentAttribute:[NSColor whiteColor]}
                                      range:NSMakeRange(0,tMutableAttributedString.length)];
    
    [tPrintableTextView.textStorage appendAttributedString:tMutableAttributedString];
    tPrintableTextView.textStorage.font=[[_textThemeItemsGroup attributesForItem:CUIThemeItemPlainText] font];
    
    NSPrintOperation * tPrintOperation=[NSPrintOperation printOperationWithView:tPrintableTextView];
    
    [tPrintOperation runOperation];
}

- (IBAction)CUI_MENUACTION_exportCrashLog:(id)sender
{
    NSSavePanel * tExportPanel=[NSSavePanel savePanel];
    
    tExportPanel.canSelectHiddenExtension=YES;
    tExportPanel.allowedFileTypes=@[@"html"];
    
    tExportPanel.nameFieldLabel=NSLocalizedString(@"Export As:", @"");
    tExportPanel.nameFieldStringValue=[self.crashLog.crashLogFilePath.lastPathComponent stringByDeletingPathExtension];
    
    tExportPanel.prompt=NSLocalizedString(@"Export", @"");
    
    CUIExportAccessoryViewController * tAccessoryViewController=[CUIExportAccessoryViewController new];
    
    tAccessoryViewController.savePanel=tExportPanel;
    tAccessoryViewController.displaySettings=[self.displaySettings copy];
    tAccessoryViewController.exportFormat=CUICrashLogExportFormatHTML;
    
    NSRange tSelectionRange=_textView.selectedRange;
    
    tAccessoryViewController.canSelectExportedContents=(tSelectionRange.length>0); // A COMPLETER (minimum length?)
    
    
    tExportPanel.accessoryView=tAccessoryViewController.view;
    
    
    [tExportPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger bResult){
        
        if (bResult!=NSModalResponseOK)
            return;
        
        CUICrashLogExportFormat tSelectedExportFormat=tAccessoryViewController.exportFormat;
        
        CUIRawTextTransformation * tRawTextTransformation=[CUIRawTextTransformation new];
        
        tRawTextTransformation.displaySettings=[tAccessoryViewController.displaySettings copy];
        tRawTextTransformation.fontSizeDelta=0;
        
        switch(tSelectedExportFormat)
        {
            case CUICrashLogExportFormatHTML:
                
                tRawTextTransformation.hyperlinksStyle=CUIHyperlinksHTML;
                
                break;
                
            default:
                
                tRawTextTransformation.hyperlinksStyle=CUIHyperlinksNone;
                
                break;
        }
        
        NSAttributedString * tAttributedString=[tRawTextTransformation transformCrashLog:self.crashLog];
        
        if (tAttributedString==nil)
        {
            NSBeep();
            return;
        }
        
        // Extract the selection if needed
        
        if (tAccessoryViewController.exportedContents==CUICrashLogExportedContentsSelection)
        {
            tAttributedString=[tAttributedString attributedSubstringFromRange:tSelectionRange];
        }
        
        //NSRTFTextDocumentType
        //NSHTMLTextDocumentType
        
        // <A NAME="Component Attributes">
        
        
        
        NSAttributedStringDocumentType tDocumenType=NSPlainTextDocumentType;
        
        switch(tSelectedExportFormat)
        {
            case CUICrashLogExportFormatRTF:
                
                tDocumenType=NSRTFTextDocumentType;
                
                break;
                
            case CUICrashLogExportFormatHTML:
                
                tDocumenType=NSHTMLTextDocumentType;
                
                break;
                
            default:
                
                break;
        }
        
        NSData * tData=nil;
        NSError * tError=nil;
        
        if (tSelectedExportFormat==CUICrashLogExportFormatPDF)
        {
            NSPrintInfo * tPrintInfo=[NSPrintInfo sharedPrintInfo];
            
            NSRect tBounds=self->_textView.bounds;
            
            if (tAccessoryViewController.exportedContents==CUICrashLogExportedContentsSelection)
            {
                NSRange tGlyphRange = [self->_textView.layoutManager glyphRangeForCharacterRange:tSelectionRange actualCharacterRange:NULL];
                
                NSRect tBoundingRect=[self->_textView.layoutManager boundingRectForGlyphRange:tGlyphRange inTextContainer:self->_textView.textContainer];
                
                tBounds.size.height=NSHeight(tBoundingRect);
            }
            else
            {
                tBounds=self->_textView.bounds;
                tBounds.size.height-=300;
            }
            
            
            
            tPrintInfo.paperSize=tBounds.size;
            
            tPrintInfo.topMargin=0;
            tPrintInfo.bottomMargin=0;
            tPrintInfo.leftMargin=0;
            tPrintInfo.rightMargin=0;
            
            tPrintInfo.verticallyCentered=NO;
            
            NSTextView * tPrintableTextView=[[NSTextView alloc] initWithFrame:tBounds];
            tPrintableTextView.backgroundColor=[[self->_textThemeItemsGroup attributesForItem:CUIThemeItemBackground] color];
            
            [tPrintableTextView.textStorage appendAttributedString:tAttributedString];
            tPrintableTextView.textStorage.font=[[self->_textThemeItemsGroup attributesForItem:CUIThemeItemPlainText] font];
            
            NSMutableData * tMutableData=[NSMutableData data];
            
            NSPrintOperation * tPrintOperation=[NSPrintOperation PDFOperationWithView:tPrintableTextView
                                                                           insideRect:tBounds
                                                                               toData:tMutableData
                                                                            printInfo:tPrintInfo];
            
            [tPrintOperation runOperation];
            
            tData=[tMutableData copy];
        }
        else
        {
            NSDictionary * tDocumentAttributes=@{
                                                 NSDocumentTypeDocumentAttribute:tDocumenType,
                                                 NSBackgroundColorDocumentAttribute:self->_textView.backgroundColor
                                                 };
            
            tData=[tAttributedString dataFromRange:NSMakeRange(0,tAttributedString.length) documentAttributes:tDocumentAttributes error:&tError];
        }
        
        if (tData==nil)
        {
            NSBeep();
            
            // A COMPLETER (Alert dialog?)
            
            return;
        }
        
        switch(tSelectedExportFormat)
        {
            case CUICrashLogExportFormatRTF:
                
                break;
                
            case CUICrashLogExportFormatHTML:
            {
                NSString * tString=[[NSString alloc] initWithData:tData encoding:NSUTF8StringEncoding];
                
                NSString * tOtherString=[tString stringByReplacingOccurrencesOfString:@"href=\"sharp://" withString:@"style=\"color:inherit;text-decoration: none\" href=\"#" options:NSCaseInsensitiveSearch range:NSMakeRange(0,tString.length)];
                
                tOtherString=[tOtherString stringByReplacingOccurrencesOfString:@"href=\"anchor://" withString:@"name=\"" options:NSCaseInsensitiveSearch range:NSMakeRange(0,tOtherString.length)];
                
                tData=[tOtherString dataUsingEncoding:NSUTF8StringEncoding];
                
                break;
            }
                
            default:
                
                break;
                
        }
        
        tError=nil;
        
        if ([tData writeToURL:tExportPanel.URL options:(NSDataWritingAtomic) error:&tError]==YES)
        {
            //[[NSWorkspace sharedWorkspace] selectFile:tExportPanel.URL.path inFileViewerRootedAtPath:@""];
            
            return;
        }
        
        // Export failed
        
        NSString * tInformativeText=nil;
        
        if (tError!=nil)
            tInformativeText=tError.localizedDescription;
        
        dispatch_async(dispatch_get_main_queue(), ^{
           
            NSBeep();
            
            NSAlert * tAlert=[NSAlert new];
            tAlert.messageText=NSLocalizedString(@"The export operation failed.", @"");
            tAlert.informativeText=tInformativeText;
            
            [tAlert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
               
                // Do nothing
                
            }];
            
        });
    }];
}

#pragma Reader Menu

- (IBAction)CUI_MENUACTION_increaseFontSize:(id)sender
{
    _fontSizeDelta+=1.0;
    
    [self refreshText];
    
    [[NSUserDefaults standardUserDefaults] setDouble:_fontSizeDelta forKey:CUICrashLogPresentationTextViewFontSizeDelta];
}

- (IBAction)CUI_MENUACTION_decreaseFontSize:(id)sender
{
    NSFont * tPlainTextFont=[[_textThemeItemsGroup attributesForItem:CUIThemeItemPlainText] font];
    
    CGFloat tNewDeltaSize=_fontSizeDelta-1.0;
    
    if (tPlainTextFont.pointSize + tNewDeltaSize>6.0)
    {
        _fontSizeDelta=tNewDeltaSize;
    
        [self refreshText];
        
        [[NSUserDefaults standardUserDefaults] setDouble:_fontSizeDelta forKey:CUICrashLogPresentationTextViewFontSizeDelta];
    }
}

- (IBAction)CUI_MENUACTION_resetFontSize:(id)sender
{
    _fontSizeDelta=0;
    
    [self refreshText];
    
    [[NSUserDefaults standardUserDefaults] setDouble:_fontSizeDelta forKey:CUICrashLogPresentationTextViewFontSizeDelta];
}


#pragma mark -

- (IBAction)performTextFinderAction:(id)sender
{
    [_textView performTextFinderAction:sender];
}

#pragma mark - Navigate Menu

- (IBAction)CUI_MENUACTION_jumpToLine:(id)sender
{
    CUILineJumperWindowController * tController=[CUILineJumperWindowController sharedLineJumperWindowController];
    
    if (tController.window.isVisible==NO)
        [tController popUpForTextView:_textView];
}

- (IBAction)CUI_MENUACTION_jumpToCrashedThread:(id)sender
{
    [self _jumpToAnchor:@"a:crashed_thread"];
}

- (void)_jumpToAnchor:(NSString *)inAnchor
{
    if (inAnchor.length==0)
        return;
    
    __block NSRange tRange=NSMakeRange(NSNotFound,0);
    
    NSArray * tAnchorsAttributesNames=@[
                                        CUIGenericAnchorAttributeName,
                                        CUISectionAnchorAttributeName,
                                        CUIThreadAnchorAttributeName,
                                        CUIBinaryAnchorAttributeName
                                        ];
    
    for(NSString * tAnchorAttributeName in tAnchorsAttributesNames)
    {
        [_textView.textStorage enumerateAttribute:tAnchorAttributeName
                                          inRange:NSMakeRange(0,_textView.textStorage.length)
                                          options:0
                                       usingBlock:^(NSString * bValue, NSRange bRange, BOOL * bOutStop) {
                                           
                                           if (bValue==nil)
                                               return;
                                           
                                           if ([bValue isEqualToString:inAnchor])
                                           {
                                               tRange=bRange;
                                               *bOutStop=YES;
                                           }
                                       }];
        
        if (tRange.location!=NSNotFound)
            break;
    }
    
    if (tRange.location!=NSNotFound)
    {
        NSRect tBounds=[_textView.layoutManager boundingRectForGlyphRange:tRange inTextContainer:_textView.textContainer];
        
        tBounds.origin.x=0;
        
        [_textView CUI_scrollPoint:tBounds.origin];
    }
}

- (IBAction)CUI_MENUACTION_jumpToHeader:(id)sender
{
    [self _jumpToAnchor:@"section:Header"];
}

- (IBAction)CUI_MENUACTION_jumpToExceptionInformation:(id)sender
{
    [self _jumpToAnchor:@"section:Exception Information"];
}

- (IBAction)CUI_MENUACTION_jumpToDiagnosticMessages:(id)sender
{
    [self _jumpToAnchor:@"section:Diagnostic Messages"];
}

- (IBAction)CUI_MENUACTION_jumpToBacktraces:(id)sender
{
    [self _jumpToAnchor:@"section:Backtraces"];
}

- (IBAction)CUI_MENUACTION_jumpToThreadState:(id)sender
{
    [self _jumpToAnchor:@"section:Thread State"];
}

- (IBAction)CUI_MENUACTION_jumpToBinaryImages:(id)sender
{
    [self _jumpToAnchor:@"section:Binary Images"];
}

#pragma mark -

- (void)_CUI_MENUACTION_switchVisibilityCommon
{
    [self refreshText];
    
    // Update the Sections menu in the navigation bar
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CUICrashLogPresentationDisplayedSectionsDidChangeNotification object:nil];
    
    // Update the selected item in the Sections menu if needed
    
    [self boundsDidChange:nil];
}

- (IBAction)CUI_MENUACTION_switchHeaderVisibility:(id)sender
{
    self.displaySettings.visibleSections^=CUIDocumentHeaderSection;
    
    [self _CUI_MENUACTION_switchVisibilityCommon];
}

- (IBAction)CUI_MENUACTION_switchExceptionInformationVisibility:(id)sender
{
    self.displaySettings.visibleSections^=CUIDocumentExceptionInformationSection;
    
    [self _CUI_MENUACTION_switchVisibilityCommon];
}

- (IBAction)CUI_MENUACTION_switchDiagnosticMessagesVisibility:(id)sender
{
    self.displaySettings.visibleSections^=CUIDocumentDiagnosticMessagesSection;
    
    [self _CUI_MENUACTION_switchVisibilityCommon];
}

- (IBAction)CUI_MENUACTION_switchBacktracesVisibility:(id)sender
{
    self.displaySettings.visibleSections^=CUIDocumentBacktracesSection;
    
    [self _CUI_MENUACTION_switchVisibilityCommon];
}

- (IBAction)CUI_MENUACTION_switchThreadStateVisibility:(id)sender
{
    self.displaySettings.visibleSections^=CUIDocumentThreadStateSection;
    
    [self _CUI_MENUACTION_switchVisibilityCommon];
}

- (IBAction)CUI_MENUACTION_switchBinaryImagesVisibility:(id)sender
{
    self.displaySettings.visibleSections^=CUIDocumentBinaryImagesSection;
    
    [self _CUI_MENUACTION_switchVisibilityCommon];
}

#pragma mark -

- (IBAction)CUI_MENUACTION_switchShowOnlyCrashedThread:(id)sender
{
    self.displaySettings.visibleSections^=CUIDocumentBacktraceCrashedThreadSubSection;
    
    [self refreshText];
}

- (IBAction)CUI_MENUACTION_switchShowOffset:(id)sender
{
    self.displaySettings.visibleStackFrameComponents^=CUIStackFrameByteOffsetComponent;
    
    [self refreshText];
}

- (IBAction)CUI_MENUACTION_switchShowMemoryAddress:(id)sender
{
    self.displaySettings.visibleStackFrameComponents^=CUIStackFrameMachineInstructionAddressComponent;
    
    [self refreshText];
}

- (IBAction)CUI_MENUACTION_switchShowBinaryImageIdentifier:(id)sender
{
    self.displaySettings.visibleStackFrameComponents^=CUIStackFrameBinaryNameComponent;
    
    [self refreshText];
}

- (NSView *)firstKeyView
{
    return _textView;
}

- (NSView *)lastKeyView
{
    return _textView;
}

#pragma mark - Notifications

- (void)itemAttributesDidChange:(NSNotification *)inNotification
{
    // Save selection
    
    NSRange tSelectionRange=_textView.selectedRange;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshText) object:nil];
    
    [self refreshText];
    
    [self refreshLinesGutter];
    
    // Restore selection
    
    if (tSelectionRange.location!=NSNotFound)
        _textView.selectedRange=tSelectionRange;
}

- (void)currentThemeDidChange:(NSNotification *)inNotification
{
    _textThemeItemsGroup=[[CUIThemesManager sharedManager].currentTheme itemsGroupWithIdentifier:[CUIApplicationPreferences groupIdentifierForPresentationMode:CUIPresentationModeText]];
    
    // Save selection
    
    NSRange tSelectionRange=_textView.selectedRange;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshText) object:nil];
    
    [self refreshText];
    
    [self refreshLinesGutter];
    
    
    
    // Restore selection
    
    if (tSelectionRange.location!=NSNotFound)
        _textView.selectedRange=tSelectionRange;
}

- (void)jumpToSection:(NSNotification *)inNotification
{
    [self _jumpToAnchor:inNotification.object];
}

- (void)boundsDidChange:(NSNotification *)inNotification
{
    if ([self.crashLog isMemberOfClass:[CUIRawCrashLog class]]==YES)
        return;
    
    NSRect tBoundingRect=[_textView.superview bounds];
    
    NSRange tVisibleRange=[_textView.layoutManager glyphRangeForBoundingRect:tBoundingRect inTextContainer:_textView.textContainer];
    
    NSMutableArray * tVisibleSections=[_sectionsList mutableCopy];
    
    NSMutableIndexSet * tMutableIndexSet=[NSMutableIndexSet indexSet];
    
    [_sectionsList enumerateObjectsUsingBlock:^(NSString * bSection, NSUInteger bIndex, BOOL * bOutStop) {
        
        NSValue * tValue=self->_sectionsRanges[bSection];
        
        if (tValue==nil)
            return;
        
        NSRange tSectionRange=[tValue rangeValue];
        
        if (NSIntersectionRange(tSectionRange,tVisibleRange).length!=0)
            return;
        
        [tMutableIndexSet addIndex:bIndex];
    }];
    
    [tVisibleSections removeObjectsAtIndexes:tMutableIndexSet];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CUICrashLogPresentationVisibleSectionsDidChangeNotification object:tVisibleSections];
    
    //NSLog(@"%@",NSStringFromRange(tVisibleRange));
    
    //NSLog(@"%@",NSStringFromRect([_textView.superview bounds]));
}

- (void)symbolicateAutomaticallyDidChange:(NSNotification *)inNotification
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshText) object:nil];
    
    [self performSelector:@selector(refreshText) withObject:nil afterDelay:0.1];
}

- (void)showsLineNumbersDidChange:(NSNotification *)inNotification
{
    [self showsLineNumbers:[CUIApplicationPreferences sharedPreferences].showsLineNumbers];
}

- (void)lineWrappingDidChange:(NSNotification *)inNotification
{
    [self setWrapText:[CUIApplicationPreferences sharedPreferences].lineWrapping];
}

- (void)dSYMBundlesManagerDidAddBundles:(NSNotification *)inNotification
{
    if ([self.crashLog isMemberOfClass:[CUIRawCrashLog class]]==YES)
        return;
    
    // Ideally we should just request to symbolicate the machineInstructionAddresses that can be
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshText) object:nil];
    
    [self performSelector:@selector(refreshText) withObject:nil afterDelay:0.1];
}

- (void)stackFrameSymbolicationDidSucceed:(NSNotification *)inNotification
{
    if (inNotification.object!=self.crashLog)
        return;
    
    if ([self.crashLog isMemberOfClass:[CUIRawCrashLog class]]==YES)
        return;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshText) object:nil];
    
    [self performSelector:@selector(refreshText) withObject:nil afterDelay:0.1];
}

@end
