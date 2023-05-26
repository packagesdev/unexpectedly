/*
 Copyright (c) 2020-2023, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIPresentationTextNavigationViewController.h"

#import "CUICrashLogsSource+UI.h"

#import "CUIRawCrashLog+UI.h"
#import "CUICrashLog+UI.h"

#import "CUICrashLogsSourcesManager.h"

#import "CUICrashLogsSourcesSelection.h"

#import "CUICrashLogsSelection.h"

#import "CUIApplicationPreferences.h"

#import "CUICrashLogPresentationTextViewController.h"

#import "CUICrashLogContentsViewController.h"

#define GROSSE_CHIURE_APPKIT_VERSION_NUMBER     1894
#define GROSSE_CHIURE_EXTRA_WIDTH   5

@interface CUIPresentationTextNavigationViewController ()
{
    IBOutlet NSPopUpButton * _sourcesPopUpButton;
    
    IBOutlet NSView * _sourcesChevronView;
    
    IBOutlet NSPopUpButton * _crashLogsPopUpButton;
    
    IBOutlet NSView * _crashLogsChevronView;
    
    IBOutlet NSPopUpButton * _sectionsPopUpButton;
    
    
    CUICrashLogsSourcesManager * _sourcesManager;
    
    CUICrashLogsSourcesSelection * _sourcesSelection;
    
    CUICrashLogsSelection * _crashLogsSelection;
    
    NSDateFormatter * _crashLogDateFormatter;
}

- (void)refreshSourcesMenu;

- (void)refreshCrashLogsMenu;

- (void)refreshSectionsMenu;

- (void)updateLayout;

- (IBAction)switchSourceCrashLog:(id)sender;

- (IBAction)switchCrashLog:(id)sender;

- (IBAction)switchSection:(id)sender;

// Notifications

- (void)viewFrameDidChange:(NSNotification *)inNotification;

- (void)sourcesManagerSourcesDidChange:(NSNotification *)inNotification;

- (void)sourceDidUpdateSource:(NSNotification *)inNotification;

- (void)sourcesSelectionDidChange:(NSNotification *)inNotification;

- (void)crashLogsSelectionDidChange:(NSNotification *)inNotification;

- (void)crashLogsSortTypeDidChange:(NSNotification *)inNotification;


- (void)presentationModeDidChange:(NSNotification *)inNotification;


- (void)displayedSectionsDidChange:(NSNotification *)inNotification;

- (void)visibleSectionsDidChange:(NSNotification *)inNotification;

@end

@implementation CUIPresentationTextNavigationViewController

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _sourcesManager=[CUICrashLogsSourcesManager sharedManager];
        
        _sourcesSelection=[CUICrashLogsSourcesSelection sharedSourcesSelection];
        
        _crashLogsSelection=[CUICrashLogsSelection sharedSelection];
        
        _crashLogDateFormatter=[NSDateFormatter new];
        _crashLogDateFormatter.formatterBehavior=NSDateFormatterBehavior10_4;
        _crashLogDateFormatter.dateStyle=NSDateFormatterMediumStyle;
        _crashLogDateFormatter.timeStyle=NSDateFormatterShortStyle;
    }
    
    return self;
}

- (NSString *)nibName
{
    return @"CUIPresentationTextNavigationViewController";
}

#pragma mark -

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Set the autoresizing masks based on the layout direction
    
    if (self.view.userInterfaceLayoutDirection==NSUserInterfaceLayoutDirectionLeftToRight)
    {
        _sourcesPopUpButton.autoresizingMask=NSViewMaxXMargin|NSViewMinYMargin;
        _sourcesPopUpButton.imagePosition=NSImageLeading;
        
        _sourcesChevronView.autoresizingMask=NSViewMaxXMargin|NSViewMinYMargin;
        
        _crashLogsPopUpButton.autoresizingMask=NSViewMaxXMargin|NSViewMinYMargin;
        _crashLogsPopUpButton.imagePosition=NSImageLeading;
        
        _crashLogsChevronView.autoresizingMask=NSViewMaxXMargin|NSViewMinYMargin;
        
        _sectionsPopUpButton.autoresizingMask=NSViewMaxXMargin|NSViewMinYMargin;
        _sectionsPopUpButton.imagePosition=NSImageLeading;
    }
    else
    {
        _sourcesPopUpButton.autoresizingMask=NSViewMinXMargin|NSViewMinYMargin;
        _sourcesPopUpButton.imagePosition=NSImageTrailing;
        
        _sourcesChevronView.autoresizingMask=NSViewMinXMargin|NSViewMinYMargin;
        
        _crashLogsPopUpButton.autoresizingMask=NSViewMinXMargin|NSViewMinYMargin;
        _crashLogsPopUpButton.imagePosition=NSImageTrailing;
        
        _crashLogsChevronView.autoresizingMask=NSViewMinXMargin|NSViewMinYMargin;
        
        _sectionsPopUpButton.autoresizingMask=NSViewMinXMargin|NSViewMinYMargin;
        _sectionsPopUpButton.imagePosition=NSImageTrailing;
    }
    
}

- (void)viewDidAppear
{
    [super viewDidAppear];
    
    [self refreshSourcesMenu];
    
    [self refreshCrashLogsMenu];
    
    [self refreshSectionsMenu];
    
    [self updateLayout];
    
    // Register for Notifications
    
    NSNotificationCenter * tNotificationCenter=[NSNotificationCenter defaultCenter];
    
    [tNotificationCenter addObserver:self selector:@selector(viewFrameDidChange:) name:NSViewFrameDidChangeNotification object:self.view];
    
    
    [tNotificationCenter addObserver:self selector:@selector(sourcesManagerSourcesDidChange:) name:CUICrashLogsSourcesManagerSourcesDidChangeNotification object:_sourcesManager];
    
    [tNotificationCenter addObserver:self selector:@selector(sourceDidUpdateSource:) name:CUICrashLogsSourceDidUpdateSourceNotification object:nil];
    
    [tNotificationCenter addObserver:self selector:@selector(sourcesSelectionDidChange:) name:CUICrashLogsSourcesSelectionDidChangeNotification object:_sourcesSelection];
    
    [tNotificationCenter addObserver:self selector:@selector(crashLogsSelectionDidChange:) name:CUICrashLogsSelectionDidChangeNotification object:[CUICrashLogsSelection sharedSelection]];
    
    [tNotificationCenter addObserver:self selector:@selector(crashLogsSortTypeDidChange:) name:CUIPreferencesCrashLogsSortTypeDidChangeNotification object:nil];

    
    [tNotificationCenter addObserver:self selector:@selector(presentationModeDidChange:) name:CUICrashLogContentsViewPresentationModeDidChangeNotification object:nil];
    
    
    
    [tNotificationCenter addObserver:self selector:@selector(displayedSectionsDidChange:) name:CUICrashLogPresentationDisplayedSectionsDidChangeNotification object:nil];
    
    [tNotificationCenter addObserver:self selector:@selector(visibleSectionsDidChange:) name:CUICrashLogPresentationVisibleSectionsDidChangeNotification object:nil];
}

- (void)viewWillDisappear
{
    [super viewWillDisappear];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -

- (void)setPresentationViewController:(CUICrashLogPresentationViewController *)inPresentationViewController
{
    if (_presentationViewController==inPresentationViewController)
        return;
    
    _presentationViewController=inPresentationViewController;
    
    [self refreshSectionsMenu];
    
    [self updateLayout];
}

#pragma mark -

- (void)refreshSourcesMenu
{
    NSString * tTitleFormatString=NSLocalizedString(@"%@ - %@", @"");
    
    [_sourcesPopUpButton removeAllItems];
    
    _sourcesPopUpButton.action=@selector(switchSourceCrashLog:);
    _sourcesPopUpButton.target=self;
    
    [_sourcesManager.allSources enumerateObjectsUsingBlock:^(CUICrashLogsSource * bSource, NSUInteger bIndex, BOOL * bOutStop) {
        
        switch(bSource.type)
        {
            case CUICrashLogsSourceTypeUnknown:
                
                return;
                
            case CUICrashLogsSourceTypeSeparator:
            
                [self->_sourcesPopUpButton.menu addItem:[NSMenuItem separatorItem]];
                
                return;
                
            default:
                
                break;
        }
        
        NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:bSource.name action:nil keyEquivalent:@""];
        
        NSImage * tImage=[NSImage imageWithSize:NSMakeSize(16.0,16.0)
                                        flipped:NO
                                 drawingHandler:^BOOL(NSRect dstRect) {
                                     
                                     [bSource.icon drawInRect:dstRect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
                                     
                                     return YES;
                                 
                                 }];
        
        tImage.template=YES;
        
        tMenuItem.image=tImage;
        
        if (bSource.type==CUICrashLogsSourceTypeFile)
        {
            tMenuItem.action=@selector(switchSourceCrashLog:);
            tMenuItem.target=self;
        }
        else
        {
            NSMenu * tMenu=[[NSMenu alloc] initWithTitle:bSource.name];
            
            NSMutableArray * tMutableCrashLogs=[bSource.crashLogs mutableCopy];
            
            switch([CUIApplicationPreferences sharedPreferences].crashLogsSortType)
            {
                case CUICrashLogsSortDateDescending:
                    
                    [tMutableCrashLogs sortUsingSelector:@selector(compareDateReverse:)];
                    
                    break;
                    
                case CUICrashLogsSortProcessNameAscending:
                    
                    [tMutableCrashLogs sortUsingSelector:@selector(compareProcessName:)];
                    
                    break;
            }
            
            for(CUIRawCrashLog * tCrashLog in tMutableCrashLogs)
            {
                NSString * tTitle=[NSString localizedStringWithFormat:tTitleFormatString,tCrashLog.processName,[self->_crashLogDateFormatter stringFromDate:tCrashLog.dateTime]];
                
                NSMenuItem * tSubMenuItem=[[NSMenuItem alloc] initWithTitle:tTitle action:@selector(switchSourceCrashLog:) keyEquivalent:@""];
                
                NSImage * tImage=[NSImage imageWithSize:NSMakeSize(16.0,16.0)
                                                flipped:NO
                                         drawingHandler:^BOOL(NSRect dstRect) {
                                             
                                             NSImage * tProcessIcon=tCrashLog.processIcon;
                                             
                                             [tProcessIcon drawInRect:dstRect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
                                             
                                             return YES;
                                             
                                         }];
                
                tSubMenuItem.image=tImage;
                
                tSubMenuItem.target=self;
                
                tSubMenuItem.representedObject=tCrashLog;
                
                [tMenu addItem:tSubMenuItem];
            }
            
            tMenuItem.submenu=tMenu;
        }
        
        tMenuItem.representedObject=bSource;
        
        [self->_sourcesPopUpButton.menu addItem:tMenuItem];
    }];
}

- (void)refreshCrashLogsMenu
{
    NSString * tTitleFormatString=NSLocalizedString(@"%@ - %@", @"");
    
    [_crashLogsPopUpButton removeAllItems];
    
    NSMutableArray * tMutableCrashLogs=[_sourcesSelection.crashLogs mutableCopy];
    
    switch([CUIApplicationPreferences sharedPreferences].crashLogsSortType)
    {
        case CUICrashLogsSortDateDescending:
            
            [tMutableCrashLogs sortUsingSelector:@selector(compareDateReverse:)];
            
            break;
            
        case CUICrashLogsSortProcessNameAscending:
            
            [tMutableCrashLogs sortUsingSelector:@selector(compareProcessName:)];
            
            break;
    }
    
    
    if (tMutableCrashLogs.count==0)
    {
        _sourcesChevronView.hidden=YES;
        
        _crashLogsPopUpButton.hidden=YES;
        
        _crashLogsChevronView.hidden=YES;
        
        _sectionsPopUpButton.hidden=YES;
        
        return;
    }

    NSMenu * tMenu=_crashLogsPopUpButton.menu;
    
    for(CUIRawCrashLog * tCrashLog in tMutableCrashLogs)
    {
        NSString * tTitle=[NSString localizedStringWithFormat:tTitleFormatString,tCrashLog.processName,[_crashLogDateFormatter stringFromDate:tCrashLog.dateTime]];
        
        NSMenuItem * tSubMenuItem=[[NSMenuItem alloc] initWithTitle:tTitle action:@selector(switchCrashLog:) keyEquivalent:@""];
        
        NSImage * tImage=[NSImage imageWithSize:NSMakeSize(16.0,16.0)
                                        flipped:NO
                                 drawingHandler:^BOOL(NSRect dstRect) {
                                     
                                     NSImage * tProcessIcon=tCrashLog.processIcon;
                                     
                                     [tProcessIcon drawInRect:dstRect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
                                     
                                     return YES;
                                     
                                 }];
        
        tSubMenuItem.image=tImage;
        
        tSubMenuItem.target=self;
        
        tSubMenuItem.representedObject=tCrashLog;
        
        [tMenu addItem:tSubMenuItem];
    }
    
    NSArray * tSelectedCrashLogs=_crashLogsSelection.crashLogs;
    
    if (tSelectedCrashLogs.count==0)
    {
        // A VOIR (Maybe add a - menu item)
    }
    else if (tSelectedCrashLogs.count!=1)
    {
        NSLog(@"Multiple selection of crash logs is not supported");
    }
    else
    {
        NSInteger tIndex=[tMenu indexOfItemWithRepresentedObject:tSelectedCrashLogs.firstObject];
        
        if (tIndex==-1)
        {
            NSLog(@"Menu index not found for item: %@",tSelectedCrashLogs.firstObject);
        }
        else
        {
            [_crashLogsPopUpButton selectItemAtIndex:tIndex];
        }
    }
    
    _sourcesChevronView.hidden=NO;
    
    _crashLogsPopUpButton.hidden=NO;
}

- (void)refreshSectionsMenu
{
    if (self.presentationViewController==nil)
    {
        _crashLogsChevronView.hidden=YES;
        _sectionsPopUpButton.hidden=YES;
        
        return;
    }
    
    CUICrashLogPresentationTextViewController * tPresentationTextViewController=(CUICrashLogPresentationTextViewController *)self.presentationViewController;
    
    if ([tPresentationTextViewController isKindOfClass:[CUICrashLogPresentationTextViewController class]]==NO)
    {
        _crashLogsChevronView.hidden=YES;
        _sectionsPopUpButton.hidden=YES;
        
        return;
    }
    
    CUIDocumentSections tDocumentSections=tPresentationTextViewController.displaySettings.visibleSections;
    
    [_sectionsPopUpButton removeAllItems];
    
    NSArray * tSelectedCrashLogs=_crashLogsSelection.crashLogs;
    
    if (tSelectedCrashLogs.count!=1)
    {
        NSLog(@"Multiple selection of crash logs is not supported");
        
        return;
    }
    
    NSMenu * tMenu=_sectionsPopUpButton.menu;
    
    NSMenuItem * tMenuItem=nil;
    
    CUICrashLog * tCrashLog=tSelectedCrashLogs.firstObject;
    
    if ([tCrashLog isKindOfClass:[CUICrashLog class]]==NO)
    {
        _crashLogsChevronView.hidden=YES;
        
        _sectionsPopUpButton.hidden=YES;
        
        return;
    }
    
    
    NSArray * tArray=@[
                       @{
                           @"title":NSLocalizedString(@"Header",@""),
                           @"available":@(tCrashLog.isHeaderAvailable),
                           @"tag":@"section:Header",
                           @"visible":@(tDocumentSections&CUIDocumentHeaderSection),
                           @"icon":@"menuHeader",
                        },
                       @{
                           @"title":NSLocalizedString(@"Exception Information",@""),
                           @"available":@(tCrashLog.isExceptionInformationAvailable),
                           @"tag":@"section:Exception Information",
                           @"visible":@(tDocumentSections&CUIDocumentExceptionInformationSection),
                           @"icon":@"menuException",
                           },
                       @{
                           @"title":NSLocalizedString(@"Diagnostic Messages",@""),
                           @"available":@(tCrashLog.isDiagnosticMessageAvailable),
                           @"tag":@"section:Diagnostic Messages",
                           @"visible":@(tDocumentSections&CUIDocumentDiagnosticMessagesSection),
                           @"icon":@"menuDiagnostic",
                           },
                       ];
    
    for(NSDictionary * tDictionary in tArray)
    {
        NSUInteger tVisibleFlag=[tDictionary[@"visible"] unsignedIntegerValue];
        
        if (tVisibleFlag==0)
            continue;
        
        if ([tDictionary[@"available"] boolValue]==YES)
        {
            tMenuItem=[[NSMenuItem alloc] initWithTitle:tDictionary[@"title"] action:@selector(switchSection:) keyEquivalent:@""];
            
            NSString * tIconName=tDictionary[@"icon"];
            
            if (tIconName==nil)
                tIconName=@"templateBlue";
            
            tMenuItem.image=[NSImage imageNamed:tIconName];
            
            tMenuItem.target=self;
            
            
            
            tMenuItem.representedObject=tDictionary[@"tag"];
            
            [tMenu addItem:tMenuItem];
        }
    }
    
    CUICrashLogBacktraces * tBacktraces=tCrashLog.backtraces;
    
    if (tBacktraces.threads.count>0 && (tDocumentSections & CUIDocumentBacktracesSection)!=0)
    {
        // Separator
        
        tMenuItem=[NSMenuItem separatorItem];
        
        [tMenu addItem:tMenuItem];
        
        // Backtraces
        
        
        
        tMenuItem=[[NSMenuItem alloc] initWithTitle:@"" action:@selector(switchSection:) keyEquivalent:@""];
        
        NSAttributedString * tAttributedString=[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Backtraces",@"")
                                                                               attributes:@{
                                                                                            NSFontAttributeName:[NSFont boldSystemFontOfSize:10.0]
                                                                                            }];
        
        tMenuItem.image=[NSImage imageNamed:@"menuBacktraces"];
        
        tMenuItem.attributedTitle=tAttributedString;
        
        tMenuItem.target=self;
        
        tMenuItem.representedObject=@"section:Backtraces";
        
        [tMenu addItem:tMenuItem];
    


        for(CUIThread * tThread in tBacktraces.threads)
        {
            NSString * tName=nil;
            
            if (tThread.isApplicationSpecificBacktrace==YES)
            {
                tName=tThread.name;
            }
            else
            {
                tName=[NSString stringWithFormat:@"Thread %lu",tThread.number];
                
                if (tThread.name!=nil)
                    tName=[tName stringByAppendingFormat:@" :: %@",tThread.name];
            }
            
            tMenuItem=[[NSMenuItem alloc] initWithTitle:tName action:@selector(switchSection:) keyEquivalent:@""];
            
            tMenuItem.image=(tThread.isCrashed==YES) ? [NSImage imageNamed:@"menuThreadCrashed"] : [NSImage imageNamed:@"menuThread"];
            
            tMenuItem.indentationLevel=1;
            
            tMenuItem.target=self;
            
            tMenuItem.representedObject=(tThread.isApplicationSpecificBacktrace==YES) ? @"thread:Application Specific Backtrace" : [NSString stringWithFormat:@"thread:%lu",tThread.number];
            
            [tMenu addItem:tMenuItem];
        }
    
        // Separator
        
        tMenuItem=[NSMenuItem separatorItem];
        
        [tMenu addItem:tMenuItem];
    }

    tArray=@[
             @{
                 @"title":NSLocalizedString(@"Thread State",@""),
                 @"available":@(tCrashLog.isThreadStateAvailable),
                 @"tag":@"section:Thread State",
                 @"visible":@(tDocumentSections&CUIDocumentThreadStateSection),
                 @"icon":@"menuThreadState",
                 },
             @{
                 @"title":NSLocalizedString(@"Binary Images",@""),
                 @"available":@(tCrashLog.isBinaryImagesAvailable),
                 @"tag":@"section:Binary Images",
                 @"visible":@(tDocumentSections&CUIDocumentBinaryImagesSection),
                 @"icon":@"menuBinaryImage",
                 }
             ];
    
    for(NSDictionary * tDictionary in tArray)
    {
        NSUInteger tVisibleFlag=[tDictionary[@"visible"] unsignedIntegerValue];
        
        if (tVisibleFlag==0)
            continue;
        
        if ([tDictionary[@"available"] boolValue]==YES)
        {
            tMenuItem=[[NSMenuItem alloc] initWithTitle:tDictionary[@"title"] action:@selector(switchSection:) keyEquivalent:@""];
            
            NSString * tIconName=tDictionary[@"icon"];
            
            if (tIconName==nil)
                tIconName=@"templateBlue";
            
            tMenuItem.image=[NSImage imageNamed:tIconName];
            
            tMenuItem.target=self;
            
            tMenuItem.representedObject=tDictionary[@"tag"];
            
            [tMenu addItem:tMenuItem];
        }
    }
    
    _crashLogsChevronView.hidden=NO;
    
    _sectionsPopUpButton.hidden=NO;
}

- (void)updateLayout
{
#define MIN_WIDTH   30.0
    
#define MARGIN  0.0

#define BEGIN_PADDING   3.0

#define END_PADDING   10.0
    
    NSRect tBounds=self.view.bounds;
    
    NSRect tRect=_sourcesPopUpButton.frame;
    
    tRect.size.width=[_sourcesPopUpButton sizeThatFits:tRect.size].width;
    
    if (NSAppKitVersionNumber>GROSSE_CHIURE_APPKIT_VERSION_NUMBER)
    {
        tRect.size.width+=GROSSE_CHIURE_EXTRA_WIDTH;
    }
    
    NSMutableArray * tMutableArray=[NSMutableArray arrayWithObject:[NSValue valueWithRect:tRect]];
    
    if (_crashLogsPopUpButton.hidden==NO)
    {
        tRect=_crashLogsPopUpButton.frame;
        
        tRect.size.width=[_crashLogsPopUpButton sizeThatFits:tRect.size].width;
        
        if (NSAppKitVersionNumber>GROSSE_CHIURE_APPKIT_VERSION_NUMBER)
        {
            tRect.size.width+=GROSSE_CHIURE_EXTRA_WIDTH;
        }
        
        [tMutableArray addObject:[NSValue valueWithRect:tRect]];
    }
    
    if (_sectionsPopUpButton.hidden==NO)
    {
        tRect=_sectionsPopUpButton.frame;
        
        tRect.size.width=[_sectionsPopUpButton sizeThatFits:tRect.size].width;
        
        if (NSAppKitVersionNumber>GROSSE_CHIURE_APPKIT_VERSION_NUMBER)
        {
            tRect.size.width+=GROSSE_CHIURE_EXTRA_WIDTH;
        }
        
        [tMutableArray addObject:[NSValue valueWithRect:tRect]];
    }
    
    __block CGFloat tTotalWidth=0.0;
    
    [tMutableArray enumerateObjectsUsingBlock:^(NSValue * bValue, NSUInteger bIndex, BOOL * outStop) {
       
        NSRect tRect=[bValue rectValue];
        
        tTotalWidth+=NSWidth(tRect);
        
    }];
    
    NSRect tChevronFrame=_sourcesChevronView.frame;
    
    
    tTotalWidth+=BEGIN_PADDING+(tMutableArray.count-1)*(NSWidth(tChevronFrame)+2.0*MARGIN)+END_PADDING;
    
    CGFloat tDifference=tTotalWidth-NSWidth(tBounds);
    
    if (tDifference<0)
        tDifference=0;
    
    NSUInteger tPopupsCount=tMutableArray.count;
    
    tRect=_sourcesPopUpButton.frame;
    
    NSSize tSize=[_sourcesPopUpButton sizeThatFits:tRect.size];
    
    if (NSAppKitVersionNumber>GROSSE_CHIURE_APPKIT_VERSION_NUMBER)
    {
        tSize.width+=GROSSE_CHIURE_EXTRA_WIDTH;
    }
    
    if (tPopupsCount==1)
    {
        // Only the sources popup button is displayed so resize it to fit the parent view width
        
        if (tDifference>0)
        {
            tSize.width=NSMaxX(tBounds)-NSMinX(tRect);
        }
        
        tRect.size.width=tSize.width;
        
        if (self.view.userInterfaceLayoutDirection==NSUserInterfaceLayoutDirectionRightToLeft)
        {
            tRect.origin.x=NSMaxX(tBounds)-NSWidth(tRect)-BEGIN_PADDING;
        }
        
        _sourcesPopUpButton.frame=tRect;
        
        return;
    }
    
    if (tPopupsCount==2)
    {
        // Only the sources and the crashlogs popup buttons are displayed
        
        if (tDifference>0.0)
        {
            if (tDifference>(tSize.width-MIN_WIDTH))
            {
                tDifference-=(tSize.width-MIN_WIDTH);
                
                tSize.width=MIN_WIDTH;
            }
            else
            {
                tSize.width-=tDifference;
                
                tDifference=0.0;
            }
        }
        
        tRect.size.width=tSize.width;
        
        if (self.view.userInterfaceLayoutDirection==NSUserInterfaceLayoutDirectionRightToLeft)
        {
            tRect.origin.x=NSMaxX(tBounds)-NSWidth(tRect)-BEGIN_PADDING;
        }
        
        _sourcesPopUpButton.frame=tRect;
        
        
        NSRect tFrame=_sourcesChevronView.frame;
        
        if (self.view.userInterfaceLayoutDirection==NSUserInterfaceLayoutDirectionLeftToRight)
        {
            tFrame.origin.x=NSMaxX(tRect)+MARGIN;
        }
        else
        {
            tFrame.origin.x=NSMinX(tRect)-MARGIN-NSWidth(tFrame);
        }
        
        _sourcesChevronView.frame=tFrame;
        
        
        tRect=_crashLogsPopUpButton.frame;
        
        tSize=[_crashLogsPopUpButton sizeThatFits:tRect.size];
        
        if (NSAppKitVersionNumber>GROSSE_CHIURE_APPKIT_VERSION_NUMBER)
        {
            tSize.width+=GROSSE_CHIURE_EXTRA_WIDTH;
        }
        
        if (self.view.userInterfaceLayoutDirection==NSUserInterfaceLayoutDirectionLeftToRight)
        {
            tRect.origin.x=NSMaxX(_sourcesChevronView.frame)+MARGIN;
            
            if (tDifference>0.0)
            {
                tSize.width=NSMaxX(tBounds)-NSMinX(tRect);
            }
        }
        else
        {
            tRect.origin.x=NSMinX(_sourcesChevronView.frame)-MARGIN-tSize.width;
            
            if (tDifference>0.0)
            {
                tSize.width=NSMaxX(tRect)-NSMinX(tBounds);
                
                tRect.origin.x=NSMinX(tBounds);
            }
        }
        
        tRect.size.width=tSize.width;
        
        _crashLogsPopUpButton.frame=tRect;
        
        return;
    }
    
    if (tPopupsCount==3)
    {
        if (tDifference>0.0)
        {
            if (tDifference>(tSize.width-MIN_WIDTH))
            {
                tDifference-=(tSize.width-MIN_WIDTH);
                
                tSize.width=MIN_WIDTH;
            }
            else
            {
                tSize.width-=tDifference;
                
                tDifference=0.0;
            }
        }
        
        tRect.size.width=tSize.width;
        
        if (self.view.userInterfaceLayoutDirection==NSUserInterfaceLayoutDirectionRightToLeft)
        {
            tRect.origin.x=NSMaxX(tBounds)-NSWidth(tRect)-BEGIN_PADDING;
        }
        
        _sourcesPopUpButton.frame=tRect;
        
        
        NSRect tFrame=_sourcesChevronView.frame;
        
        if (self.view.userInterfaceLayoutDirection==NSUserInterfaceLayoutDirectionLeftToRight)
        {
            tFrame.origin.x=NSMaxX(tRect)+MARGIN;
        }
        else
        {
            tFrame.origin.x=NSMinX(tRect)-MARGIN-NSWidth(tFrame);
        }
        
        _sourcesChevronView.frame=tFrame;
        
        
        tRect=_crashLogsPopUpButton.frame;
        
        tRect.origin.x=NSMaxX(_sourcesChevronView.frame)+MARGIN;
        
        tSize=[_crashLogsPopUpButton sizeThatFits:tRect.size];
        
        if (NSAppKitVersionNumber>GROSSE_CHIURE_APPKIT_VERSION_NUMBER)
        {
            tSize.width+=GROSSE_CHIURE_EXTRA_WIDTH;
        }
        
        if (tDifference>(tSize.width-MIN_WIDTH))
        {
            tDifference-=(tSize.width-MIN_WIDTH);
            
            tSize.width=MIN_WIDTH;
        }
        else
        {
            tSize.width-=tDifference;
            
            tDifference=0.0;
        }
        
        tRect.size.width=tSize.width;
        
        if (self.view.userInterfaceLayoutDirection==NSUserInterfaceLayoutDirectionLeftToRight)
        {
            tRect.origin.x=NSMaxX(_sourcesChevronView.frame)+MARGIN;
        }
        else
        {
            tRect.origin.x=NSMinX(_sourcesChevronView.frame)-MARGIN-tSize.width;
        }
        
        _crashLogsPopUpButton.frame=tRect;
        
        
        tFrame=_crashLogsChevronView.frame;
        
        if (self.view.userInterfaceLayoutDirection==NSUserInterfaceLayoutDirectionLeftToRight)
        {
            tFrame.origin.x=NSMaxX(tRect)+MARGIN;
        }
        else
        {
            tFrame.origin.x=NSMinX(tRect)-MARGIN-NSWidth(tFrame);
        }
        
        _crashLogsChevronView.frame=tFrame;
        
        
        tRect=_sectionsPopUpButton.frame;
        
        tSize=[_sectionsPopUpButton sizeThatFits:tRect.size];
        
        if (NSAppKitVersionNumber>GROSSE_CHIURE_APPKIT_VERSION_NUMBER)
        {
            tSize.width+=GROSSE_CHIURE_EXTRA_WIDTH;
        }
        
        if (tDifference>0.0)
        {
            tSize.width=NSMaxX(tBounds)-NSMinX(tRect);
        }
        
        if (self.view.userInterfaceLayoutDirection==NSUserInterfaceLayoutDirectionLeftToRight)
        {
            tRect.origin.x=NSMaxX(_crashLogsChevronView.frame)+MARGIN;
        }
        else
        {
            tRect.origin.x=NSMinX(_crashLogsChevronView.frame)-MARGIN-tSize.width;
        }
        
        tRect.size.width=tSize.width;
        
        _sectionsPopUpButton.frame=tRect;
    }
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    return YES;
}

- (IBAction)switchSourceCrashLog:(NSMenuItem *)sender
{
    id tRepresentedObject=sender.representedObject;
    
    if ([tRepresentedObject isKindOfClass:[CUICrashLogsSource class]]==YES)
    {
        CUICrashLogsSource * tSource=(CUICrashLogsSource *)tRepresentedObject;
        
        if (tSource.type!=CUICrashLogsSourceTypeFile)
        {
            return;
        }
        
        if ([_sourcesSelection.sources containsObject:tSource]==NO)
        {
            _sourcesSelection.sources=[NSSet setWithObject:tSource];
        }
        
        [_crashLogsSelection setSource:tSource crashLogs:@[tSource.crashLogs.firstObject]];
        
        [self updateLayout];
        
        return;
    }
    
    if ([tRepresentedObject isKindOfClass:[CUIRawCrashLog class]]==NO)
    {
        NSLog(@"switchCrashLog: Represented object for the menu item is not a crash log object");
        
        return;
    }
    
    id tCrashLog=tRepresentedObject;
        
    NSMenuItem * tParentMenuItem=sender.parentItem;
    
    id tParentRepresentedItem=tParentMenuItem.representedObject;
    
    if ([tParentRepresentedItem isKindOfClass:[CUICrashLogsSource class]]==NO)
    {
        return;
    }
    
    CUICrashLogsSource * tSource=(CUICrashLogsSource *)tParentRepresentedItem;
    
    if ([_sourcesSelection.sources containsObject:tSource]==NO)
    {
        _sourcesSelection.sources=[NSSet setWithObject:tSource];
    }
    
    [_crashLogsSelection setSource:tSource crashLogs:@[tCrashLog]];
    
    [self updateLayout];
}

- (IBAction)switchCrashLog:(NSMenuItem *)sender
{
    id tRepresentedObject=sender.representedObject;
    
    if ([tRepresentedObject isKindOfClass:[CUIRawCrashLog class]]==NO)
    {
        NSLog(@"switchCrashLog: Represented object for the menu item is not a crash log object");
        
        return;
    }
    
    [_crashLogsSelection setSource:_crashLogsSelection.source crashLogs:@[tRepresentedObject]];
    
    [self updateLayout];
}

- (IBAction)switchSection:(NSMenuItem *)sender
{
    id tRepresentedObject=sender.representedObject;
    
    if ([tRepresentedObject isKindOfClass:[NSString class]]==NO)
    {
        NSLog(@"switchSection: Represented object for the menu item is not a NSString");
        
        return;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"jumpToSectionNotification" object:tRepresentedObject userInfo:@{}];
    
    [self updateLayout];
}

#pragma mark - Notifications

- (void)viewFrameDidChange:(NSNotification *)inNotification
{
    [self updateLayout];
}

- (void)sourcesManagerSourcesDidChange:(NSNotification *)inNotification
{
    [self refreshSourcesMenu];
}

- (void)sourceDidUpdateSource:(NSNotification *)inNotification
{
    // A COMPLETER
}

- (void)sourcesSelectionDidChange:(NSNotification *)inNotification
{
    NSSet * tSet=_sourcesSelection.sources;
    
    CUICrashLogsSource * tCrashLogsSource=[tSet anyObject];
    
    if (tCrashLogsSource==nil)
        return;
    
    switch(tCrashLogsSource.type)
    {
        case CUICrashLogsSourceTypeUnknown:
        case CUICrashLogsSourceTypeSeparator:
            
            return;
            
        default:
            
            break;
    }
    
    // Select the appropriate menu item
    
    NSInteger tIndex=[_sourcesPopUpButton.menu indexOfItemWithRepresentedObject:tCrashLogsSource];
    
    if (tIndex==-1)
    {
        NSLog(@"Menu index not found for source %@",tCrashLogsSource);
        
        return;
    }
    
    [_sourcesPopUpButton selectItemAtIndex:tIndex];
    
    // Refresh the CrashLogs menu if needed
    
    [self refreshCrashLogsMenu];
    
    [self updateLayout];
}

- (void)crashLogsSelectionDidChange:(NSNotification *)inNotification
{
    // Refresh Selection
    
    NSMenu * tMenu=_crashLogsPopUpButton.menu;
    
    NSArray * tSelectedCrashLogs=_crashLogsSelection.crashLogs;
    
    if (tSelectedCrashLogs.count!=1)
    {
        if (tSelectedCrashLogs.count>0)
            NSLog(@"Multiple selection of crash logs is not supported");
    }
    else
    {
        NSInteger tIndex=[tMenu indexOfItemWithRepresentedObject:tSelectedCrashLogs.firstObject];
        
        if (tIndex==-1)
        {
            // This can happen if we actually did change the source and then log selection automatically changed
            
            return;
        }
        else
        {
            [_crashLogsPopUpButton selectItemAtIndex:tIndex];
            
            [self refreshSectionsMenu];
        }
    }
    
    [self updateLayout];
}

- (void)crashLogsSortTypeDidChange:(NSNotification *)inNotification
{
    [self refreshCrashLogsMenu];
}


- (void)presentationModeDidChange:(NSNotification *)inNotification
{
    CUICrashLogContentsViewController * tContentsViewController=inNotification.object;
    
    self.presentationViewController=tContentsViewController.presentationViewController;
}


- (void)displayedSectionsDidChange:(NSNotification *)inNotification
{
    [self refreshSectionsMenu];
        
    [self updateLayout];
}

- (void)visibleSectionsDidChange:(NSNotification *)inNotification
{
    NSArray * tVisibleSections=inNotification.object;
    
    NSInteger tIndex=[_sectionsPopUpButton indexOfItemWithRepresentedObject:tVisibleSections.firstObject];
    
    if (tIndex==-1)
        return;
    
    [_sectionsPopUpButton selectItemAtIndex:tIndex];
    
    [self updateLayout];
}

@end
