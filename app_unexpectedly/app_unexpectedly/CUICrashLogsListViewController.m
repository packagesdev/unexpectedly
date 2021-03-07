/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICrashLogsListViewController.h"

#import "CUICrashLogsSourcesSelection.h"

#import "CUICrashLogsSelection.h"

#import "CUICrashLogTableCellView.h"

#import "CUICrashLog+UI.h"

#import "NSArray+WBExtensions.h"

#import "NSTableView+Selection.h"

#import "CUIApplicationPreferences.h"

#import "CUICrashLogsSourcesManager.h"

#import "CUICrashLogExceptionInformation+UI.h"

@interface CUICrashLogsListViewController () <NSSharingServiceDelegate,NSTableViewDataSource,NSTableViewDelegate>
{
    IBOutlet NSTableView * _tableView;
    
    IBOutlet NSMenu * _shareMenu;
    
    IBOutlet NSSearchField * _filterField;
    
    IBOutlet NSPopUpButton * _sortPopUpButton;
    
    
    CUICrashLogsSource * _source;
    
    NSMutableArray * _filteredAndSortedCrashLogsArray;
    
    NSString * _filterPattern;
    
    CUICrashLogsSortType _sortType;
    
    NSDateFormatter * _crashLogDateFormatter;
}

- (IBAction)share:(id)sender;

- (IBAction)showInFinder:(id)sender;

- (IBAction)CUI_MENUACTION_moveToTrash:(id)sender;

- (IBAction)CUI_MENUACTION_moveAllToTrash:(id)sender;

- (IBAction)takeFilterPatternFrom:(id)sender;

- (IBAction)switchSortType:(id)sender;

// Notification

- (void)crashLogsSourcesSelectionDidChange:(NSNotification *)inNotification;

- (void)crashLogsSelectionDidChange:(NSNotification *)inNotification;

- (void)crashLogsSortTypeDidChange:(NSNotification *)inNotification;

@end

@implementation CUICrashLogsListViewController

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _filterPattern=@"";
        
        _crashLogDateFormatter=[NSDateFormatter new];
        _crashLogDateFormatter.formatterBehavior=NSDateFormatterBehavior10_4;
        _crashLogDateFormatter.dateStyle=NSDateFormatterMediumStyle;
        _crashLogDateFormatter.timeStyle=NSDateFormatterShortStyle;
        
        _sortType=[CUIApplicationPreferences sharedPreferences].crashLogsSortType;
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
    return @"CUICrashLogsListViewController";
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [_shareMenu removeAllItems];
    
    [[NSSharingService sharingServicesForItems:@[[[NSBundle mainBundle] URLForResource:@"Localizable" withExtension:@"strings"]]] enumerateObjectsUsingBlock:^(NSSharingService * bSharingService, NSUInteger bIndex, BOOL * bOutStop) {
        
    
        NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:bSharingService.menuItemTitle
                                                          action:@selector(share:)
                                                   keyEquivalent:@""];
        tMenuItem.target=self;
        tMenuItem.image=bSharingService.image;
        tMenuItem.representedObject=bSharingService;
        
        
        [self->_shareMenu addItem:tMenuItem];
    }];
    
    _filterField.centersPlaceholder=NO;
    
    NSSearchFieldCell * tSearchFieldCell=_filterField.cell;
    NSButtonCell * tButtonCell=tSearchFieldCell.searchButtonCell;
    
    tButtonCell.image=[NSImage imageNamed:@"filter_Template"];
    tButtonCell.alternateImage=tButtonCell.image;
    
    
    
    // Register for notifications
    
    NSNotificationCenter * tNotificationCenter=[NSNotificationCenter defaultCenter];
    
    [tNotificationCenter addObserver:self selector:@selector(crashLogsSourcesSelectionDidChange:) name:CUICrashLogsSourcesSelectionDidChangeNotification object:[CUICrashLogsSourcesSelection sharedSourcesSelection]];
    
    [tNotificationCenter addObserver:self selector:@selector(crashLogsSelectionDidChange:) name:CUICrashLogsSelectionDidChangeNotification object:[CUICrashLogsSelection sharedSelection]];
    
    [tNotificationCenter addObserver:self selector:@selector(crashLogsSortTypeDidChange:) name:CUIPreferencesCrashLogsSortTypeDidChangeNotification object:nil];
}

#pragma mark -

- (void)refreshList
{
    NSIndexSet * tIndexSet=_tableView.selectedRowIndexes;
    
    NSArray * tSelectedItems=[_filteredAndSortedCrashLogsArray objectsAtIndexes:tIndexSet];
    
    NSArray * tSelectedResourceIdentifiers=[tSelectedItems WB_arrayByMappingObjectsUsingBlock:^id(CUIRawCrashLog * bCrashLog, NSUInteger bIndex) {
       
        return bCrashLog.resourceIdentifier;
        
    }];
    
    NSArray * tArray=_source.crashLogs;
    
    if (_filterPattern.length>0)
    {
        _filteredAndSortedCrashLogsArray=[NSMutableArray array];
        
        [tArray enumerateObjectsUsingBlock:^(CUICrashLog * bCrashLog, NSUInteger bIndex, BOOL * bOutStop) {
            
            if ([bCrashLog isKindOfClass:[CUICrashLog class]]==NO)
                return;
            
            if ([bCrashLog.header.responsibleProcessName rangeOfString:self->_filterPattern options:NSCaseInsensitiveSearch].location!=NSNotFound)
            {
                [self->_filteredAndSortedCrashLogsArray addObject:bCrashLog];
                
                return;
            }
            
            if ([bCrashLog.exceptionInformation.exceptionType rangeOfString:self->_filterPattern options:NSCaseInsensitiveSearch].location!=NSNotFound ||
                [bCrashLog.exceptionInformation.exceptionSignal rangeOfString:self->_filterPattern options:NSCaseInsensitiveSearch].location!=NSNotFound)
            {
                [self->_filteredAndSortedCrashLogsArray addObject:bCrashLog];
                
                return;
            }
        }];
    }
    else
    {
        _filteredAndSortedCrashLogsArray=[tArray mutableCopy];
    }
    
    switch(_sortType)
    {
        case CUICrashLogsSortDateDescending:
            
            [_filteredAndSortedCrashLogsArray sortUsingSelector:@selector(compareDateReverse:)];
            
            break;
            
        case CUICrashLogsSortProcessNameAscending:
            
            [_filteredAndSortedCrashLogsArray sortUsingSelector:@selector(compareProcessName:)];
            
            break;
    }
    
    //[_tableView deselectAll:self];
    
    NSArray * tSaveSelectionCrashLogs=nil;
    
    CUICrashLogsSelection * tSelection=[CUICrashLogsSelection sharedSelection];
    
    if (tSelection.source==_source)
    {
        tSaveSelectionCrashLogs=[tSelection.crashLogs copy];
    }
    
    [_tableView reloadData];
    
    NSMutableIndexSet * tNewSelectionIndexSet=[NSMutableIndexSet indexSet];
    
    [_filteredAndSortedCrashLogsArray enumerateObjectsUsingBlock:^(CUIRawCrashLog * bCrashLog, NSUInteger bIndex,BOOL * bOutStop) {
       
        if ([tSelectedResourceIdentifiers containsObject:bCrashLog.resourceIdentifier]==YES)
            [tNewSelectionIndexSet addIndex:bIndex];
        
    }];
    
    if (tNewSelectionIndexSet.count>0)
    {
        [_tableView selectRowIndexes:tNewSelectionIndexSet byExtendingSelection:NO];
    }
    else
    {
        if (tSaveSelectionCrashLogs!=nil)
        {
            [_filteredAndSortedCrashLogsArray enumerateObjectsUsingBlock:^(id bCrashLog, NSUInteger bIndex,BOOL * bOutStop) {
                
                if ([tSaveSelectionCrashLogs containsObject:bCrashLog]==YES)
                    [tNewSelectionIndexSet addIndex:bIndex];
                
            }];
        }
        
        if (tNewSelectionIndexSet.count>0)
        {
            [_tableView selectRowIndexes:tNewSelectionIndexSet byExtendingSelection:NO];
        }
        else
        {
            [self tableViewSelectionDidChange:[NSNotification notificationWithName:NSTableViewSelectionDidChangeNotification object:_tableView]];
        }
    }
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
    SEL tAction=inMenuItem.action;
    
    if (tAction==@selector(showInFinder:) ||
        tAction==@selector(CUI_MENUACTION_moveToTrash:))
    {
        NSIndexSet * tSelectionIndexSet=_tableView.WB_selectedOrClickedRowIndexes;
        
        if (tSelectionIndexSet.count==0)
            return NO;
        
        NSArray * tCrashLogs=_filteredAndSortedCrashLogsArray;
        
        __block BOOL tResult=YES;
        
        [tSelectionIndexSet enumerateIndexesUsingBlock:^(NSUInteger bIndex,BOOL * bOutStop){
            
            CUIRawCrashLog * tCrashLog=tCrashLogs[bIndex];
            
            NSString * tPath=tCrashLog.crashLogFilePath;
            
            if (tPath.length==0 ||
                [[NSFileManager defaultManager] fileExistsAtPath:tPath]==NO)
            {
                tResult=NO;
                
                *bOutStop=NO;
                return;
            }
        }];
        
        return tResult;
    }
    
    if (tAction==@selector(CUI_MENUACTION_moveAllToTrash:))
    {
        NSIndexSet * tSelectionIndexSet=_tableView.WB_selectedOrClickedRowIndexes;
        
        if (tSelectionIndexSet.count!=1)
            return NO;
        
        NSArray * tCrashLogs=_filteredAndSortedCrashLogsArray;
        CUIRawCrashLog * tCrashLog=tCrashLogs[tSelectionIndexSet.firstIndex];
        
        if (tCrashLog==nil)
            return NO;
        
        NSString * tPath=tCrashLog.crashLogFilePath;
        
        if (tPath.length==0 || [[NSFileManager defaultManager] fileExistsAtPath:tPath]==NO)
            return NO;
        
        inMenuItem.title=[NSString stringWithFormat:NSLocalizedString(@"Move All \"%@\" Reports to Trash",@""),tCrashLog.processName];
        
        return YES;
    }
    
    if (tAction==@selector(switchSortType:))
    {
        inMenuItem.state=(inMenuItem.tag==_sortType) ? NSOnState : NSOffState;
        
        return YES;
    }
    
    return YES;
}

- (IBAction)share:(NSMenuItem *)sender
{
    NSSharingService * tSharingService=sender.representedObject;
    
    NSIndexSet * tSelectionIndexSet=_tableView.WB_selectedOrClickedRowIndexes;
    
    NSArray * tArray=[_filteredAndSortedCrashLogsArray objectsAtIndexes:tSelectionIndexSet];
    
    NSArray * tURLs=[tArray WB_arrayByMappingObjectsUsingBlock:^id(CUIRawCrashLog * bCrashLog, NSUInteger bIndex) {
        
        return [NSURL fileURLWithPath:bCrashLog.crashLogFilePath];
        
    }];
    
    tSharingService.delegate = self;
    
    [tSharingService performWithItems:tURLs];
}

- (void)_shareSelectionWithService:(NSString *)inServiceID
{
    NSIndexSet * tSelectionIndexSet=_tableView.WB_selectedOrClickedRowIndexes;
    
    NSArray * tArray=[_filteredAndSortedCrashLogsArray objectsAtIndexes:tSelectionIndexSet];
    
    NSArray * tURLs=[tArray WB_arrayByMappingObjectsUsingBlock:^id(CUIRawCrashLog * bCrashLog, NSUInteger bIndex) {
        
        return [NSURL fileURLWithPath:bCrashLog.crashLogFilePath];
        
    }];
    
    NSSharingService * tService = [NSSharingService sharingServiceNamed:inServiceID];
    tService.delegate = self;
    
    [tService performWithItems:tURLs];
}

- (IBAction)showInFinder:(id)sender
{
    NSIndexSet * tSelectionIndexSet=_tableView.WB_selectedOrClickedRowIndexes;
    
    NSWorkspace * tSharedWorkspace=[NSWorkspace sharedWorkspace];
    
    [_filteredAndSortedCrashLogsArray enumerateObjectsAtIndexes:tSelectionIndexSet options:0 usingBlock:^(CUIRawCrashLog * bCrashLog, NSUInteger bIndex, BOOL * bOutStop) {
        
        NSString * tPath=bCrashLog.crashLogFilePath;
        
        if (tPath.length>0)
            [tSharedWorkspace selectFile:tPath inFileViewerRootedAtPath:@""];
        
    }];
}

- (IBAction)CUI_MENUACTION_moveToTrash:(id)sender
{
    NSIndexSet * tSelectionIndexSet=_tableView.WB_selectedOrClickedRowIndexes;
    
    if (tSelectionIndexSet.count==0)
        return;
    

    NSFileManager * tFileManager=[NSFileManager defaultManager];
    
    NSMutableIndexSet * tMutableIndexSet=[tSelectionIndexSet mutableCopy];
    
    [_filteredAndSortedCrashLogsArray enumerateObjectsAtIndexes:tSelectionIndexSet options:0 usingBlock:^(CUIRawCrashLog * bCrashLog, NSUInteger bIndex, BOOL * bOutStop) {
    
        NSError * tError=nil;
        
        if ([tFileManager trashItemAtURL:[NSURL fileURLWithPath:bCrashLog.crashLogFilePath] resultingItemURL:NULL error:&tError]==NO)
        {
            [tMutableIndexSet removeIndex:bIndex];
            
            NSLog(@"%@",tError);
        }
    }];
    
    if (tMutableIndexSet.count<tSelectionIndexSet.count)
    {
        // A COMPLETER
    }
    
    if (_source.type==CUICrashLogsSourceTypeFile)
    {
        [_filteredAndSortedCrashLogsArray removeObjectsAtIndexes:tMutableIndexSet];
        
        [_tableView reloadData];
        
        // We actually need to remove the source directly
        
        [[CUICrashLogsSourcesManager sharedManager] removeSources:@[_source]];
    }
}

- (IBAction)CUI_MENUACTION_moveAllToTrash:(id)sender
{
    NSIndexSet * tSelectionIndexSet=_tableView.WB_selectedOrClickedRowIndexes;
    NSUInteger tIndex=tSelectionIndexSet.firstIndex;
    
    CUIRawCrashLog * tReferenceCrashLog=_filteredAndSortedCrashLogsArray[tIndex];
    NSString * tReferenceProcessName=tReferenceCrashLog.processName;
    
    NSArray * tFilteredArray=[_source.crashLogs WB_filteredArrayUsingBlock:^BOOL(CUIRawCrashLog * bCrashLog, NSUInteger bIndex) {
        
        return ([bCrashLog.processName isEqualToString:tReferenceProcessName]==YES);
    }];
    
    NSFileManager * tFileManager=[NSFileManager defaultManager];
    
    [tFilteredArray enumerateObjectsUsingBlock:^(CUIRawCrashLog * bCrashLog, NSUInteger bIndex, BOOL * bOutStop) {
        
        [tFileManager trashItemAtURL:[NSURL fileURLWithPath:bCrashLog.crashLogFilePath] resultingItemURL:NULL error:NULL];
    }];
}

- (IBAction)takeFilterPatternFrom:(NSSearchField *)sender
{
    _filterPattern=sender.stringValue;
    
    [self refreshList];
}

- (IBAction)switchSortType:(NSPopUpButton *)sender
{
    NSInteger tTag=sender.selectedTag;
    
    if (tTag!=_sortType)
    {
        [CUIApplicationPreferences sharedPreferences].crashLogsSortType=tTag;
    }
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)inTableView
{
    return _filteredAndSortedCrashLogsArray.count;
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)inTableView viewForTableColumn:(NSTableColumn *)inTableColumn row:(NSInteger)inRow
{
    CUICrashLogTableCellView * tTableCellView=[inTableView makeViewWithIdentifier:@"crashlog cell" owner:self];
    
    CUIRawCrashLog * tCrashLog=_filteredAndSortedCrashLogsArray[inRow];
    
    tTableCellView.imageView.image=((CUICrashLog *)tCrashLog).processIcon;
    
    
    tTableCellView.textField.stringValue=tCrashLog.processName;
    
    tTableCellView.dateLabel.formatter=_crashLogDateFormatter;
    tTableCellView.dateLabel.objectValue=tCrashLog.dateTime;
    
    // Exception Type Summary
    
    NSString * tExceptionType=nil;
    CUICrashLogExceptionInformation * tExceptionInformation=nil;
    
    if ([tCrashLog isKindOfClass:[CUICrashLog class]]==YES)
    {
        tExceptionInformation=((CUICrashLog *)tCrashLog).exceptionInformation;
    
        tExceptionType=tExceptionInformation.exceptionType;
    }
    
    if (tExceptionType==nil)
    {
        tTableCellView.exceptionTypeLabel.stringValue=@"-";
        
        tTableCellView.toolTip=@"";
    }
    else
    {
        NSString * tPrefix=@"EXC_";
        NSString * tLabelValue;
        
        if (tExceptionType.length>tPrefix.length)
        {
            tLabelValue=[tExceptionType substringFromIndex:tPrefix.length];
        }
        else
        {
            tLabelValue=tExceptionType;
        }
        
        tTableCellView.exceptionTypeLabel.stringValue=tLabelValue;
        
        
        tTableCellView.exceptionTypeLabel.toolTip=[tExceptionInformation displayedExceptionType];
        
        
    }
    
    // Voice Over
    
    NSString * tDateString=[_crashLogDateFormatter stringFromDate:tCrashLog.dateTime];
    
    if (tExceptionType==nil)
    {
        NSString * tFormat=NSLocalizedString(@"Crash Report for process %@, date: %@", @"");
        
        tTableCellView.accessibilityLabel=[NSString stringWithFormat:tFormat,tCrashLog.processName,tDateString];
    }
    else
    {
        NSString * tFormat=NSLocalizedString(@"Crash Report for process %@, date: %@, exception type: %@", @"");
        
        tTableCellView.accessibilityLabel=[NSString stringWithFormat:tFormat,tCrashLog.processName,tDateString,[tExceptionInformation humanFriendlyExceptionType]];
    }
    
    return tTableCellView;
}

- (void)tableViewSelectionDidChange:(NSNotification *)inNotification
{
    NSInteger tSelectedRow=_tableView.selectedRow;
    
    NSNotificationCenter * tNotificationCenter=[NSNotificationCenter defaultCenter];
    
    // Stop observing
    
    CUICrashLogsSelection * tCrashLogsSelection=[CUICrashLogsSelection sharedSelection];
    
    [tNotificationCenter removeObserver:self name:CUICrashLogsSelectionDidChangeNotification object:tCrashLogsSelection];
    
    [tCrashLogsSelection setSource:_source crashLogs:(tSelectedRow==-1) ? @[] : @[_filteredAndSortedCrashLogsArray[tSelectedRow]]];
    
    // Restore observation
    
    [tNotificationCenter addObserver:self selector:@selector(crashLogsSelectionDidChange:) name:CUICrashLogsSelectionDidChangeNotification object:tCrashLogsSelection];
}

#pragma mark - NSSharingServiceDelegate

- (void)sharingService:(NSSharingService *)sharingService didFailToShareItems:(NSArray *)items error:(NSError *)error
{
    // A COMPLETER
    
    NSBeep();
}

#pragma mark - CUIKeyViews

- (NSView *)firstKeyView
{
    return _tableView;
}

- (NSView *)lastKeyView
{
    return _tableView;
}

#pragma mark - Notifications

- (void)crashLogsSourcesSelectionDidChange:(NSNotification *)inNotification
{
    CUICrashLogsSourcesSelection * tSelection=inNotification.object;
    
    if ([tSelection isKindOfClass:[CUICrashLogsSourcesSelection class]]==NO)
        return;
    
    CUICrashLogsSource * tFirstSource=tSelection.sources.allObjects.firstObject;
    
    if (tFirstSource==_source)
        return;
    
    NSNotificationCenter * tNotificationCenter=[NSNotificationCenter defaultCenter];
    
    [tNotificationCenter removeObserver:self name:CUICrashLogsSourceDidUpdateSourceNotification object:_source];
    
    _source=tFirstSource;
    
    [self refreshList];
    
    // Register for notification
    
    [tNotificationCenter addObserver:self
                            selector:@selector(sourceDidUpdateSource:)
                                name:CUICrashLogsSourceDidUpdateSourceNotification
                              object:_source];
}

- (void)crashLogsSelectionDidChange:(NSNotification *)inNotification
{
    CUICrashLogsSelection * tSelection=inNotification.object;
    
    // Refresh Selection
    
    NSMutableIndexSet * tIndexSet=[NSMutableIndexSet indexSet];
    
    [_filteredAndSortedCrashLogsArray enumerateObjectsUsingBlock:^(id bCrashLog, NSUInteger bIndex, BOOL * bOutStop) {
        
        if ([tSelection.crashLogs containsObject:bCrashLog]==YES)
            [tIndexSet addIndex:bIndex];
        
    }];
    
    if (tIndexSet.count==0)
    {
        [_source.crashLogs enumerateObjectsUsingBlock:^(id bCrashLog, NSUInteger bIndex, BOOL * bOutStop) {
            
            if ([tSelection.crashLogs containsObject:bCrashLog]==YES)
                [tIndexSet addIndex:bIndex];
            
        }];
        
        if (tIndexSet.count==0)
        {
            [tIndexSet addIndex:0];
        }
        else
        {
            NSArray * tSelectedCrashLogs=[tSelection.crashLogs copy];
            
            _filterField.stringValue=@"";
            _filterPattern=@"";
            
            [self refreshList];
            
            tIndexSet=[NSMutableIndexSet indexSet];
            
            [_filteredAndSortedCrashLogsArray enumerateObjectsUsingBlock:^(id bCrashLog, NSUInteger bIndex, BOOL * bOutStop) {
                
                if ([tSelectedCrashLogs containsObject:bCrashLog]==YES)
                    [tIndexSet addIndex:bIndex];
                
            }];
        }
    }
    
    [_tableView selectRowIndexes:tIndexSet byExtendingSelection:NO];
    
    [_tableView scrollRowToVisible:tIndexSet.firstIndex];
}

- (void)sourceDidUpdateSource:(NSNotification *)inNotification
{
    [self refreshList];
}

- (void)crashLogsSortTypeDidChange:(NSNotification *)inNotification
{
    _sortType=[CUIApplicationPreferences sharedPreferences].crashLogsSortType;
    
    [self refreshList];
    
}

@end
