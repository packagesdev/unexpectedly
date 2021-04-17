/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUISymbolsFilesLibraryViewController.h"

#import "CUIdSYMBundlesManager.h"

#import "CUIdSYMBundle.h"
#import "CUIdSYMBundle+UI.h"

#import "NSArray+WBExtensions.h"
#import "NSTableView+Selection.h"

@interface CUISymbolsFilesLibraryViewController () <NSTableViewDataSource,NSTableViewDelegate>
{
    IBOutlet NSTableView * _tableView;
    
    IBOutlet NSButton * _removeButton;
    
    IBOutlet NSSearchField * _filterField;
    
    NSImage * _cachedBundleIcon;
    
    CUIdSYMBundlesManager * _dSYMBundlesManager;
    
    NSMutableArray<CUIdSYMBundle *> * _filteredAndSortedBundlesArray;
    
    NSString * _filterPattern;
}

- (IBAction)addDebuggingSymbolsFile:(id)sender;

- (IBAction)delete:(id)sender;

- (IBAction)showInFinder:(id)sender;

- (IBAction)takeFilterPatternFrom:(NSSearchField *)sender;

// Notifications

- (void)dSYMBundlesManagerDidAddBundles:(NSNotification *)inNotification;

- (void)dSYMBundlesManagerDidRemoveBundles:(NSNotification *)inNotification;

@end

@implementation CUISymbolsFilesLibraryViewController

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _dSYMBundlesManager=[CUIdSYMBundlesManager sharedManager];
        
        _filterPattern=@"";
    }
    
    return self;
}

#pragma mark -

- (NSString *)nibName
{
    return @"CUISymbolsFilesLibraryViewController";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _cachedBundleIcon=[[NSWorkspace sharedWorkspace] iconForFileType:@"com.apple.xcode.dsym"];
    
    [_tableView registerForDraggedTypes:@[NSFilenamesPboardType]];
    
    NSSortDescriptor *buildETASortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"self" ascending:YES selector:@selector(compareNameAndVersion:)];
    
    _tableView.sortDescriptors=@[buildETASortDescriptor];
    
    
    _filterField.centersPlaceholder=NO;
    
    NSSearchFieldCell * tSearchFieldCell=_filterField.cell;
    NSButtonCell * tButtonCell=tSearchFieldCell.searchButtonCell;
    
    tButtonCell.image=[NSImage imageNamed:@"filter_Template"];
    tButtonCell.alternateImage=tButtonCell.image;
    
    
    _filteredAndSortedBundlesArray=[_dSYMBundlesManager.bundlesSet.allObjects mutableCopy];
}

- (void)viewWillAppear
{
    [super viewWillAppear];
    
    [self refreshList];
}

- (void)viewDidAppear
{
    [super viewDidAppear];
    
    // Register for notifications
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dSYMBundlesManagerDidAddBundles:) name:CUIdSYMBundlesManagerDidAddBundlesNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dSYMBundlesManagerDidRemoveBundles:) name:CUIdSYMBundlesManagerDidRemoveBundlesNotification object:nil];
}

- (void)viewWillDisappear
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CUIdSYMBundlesManagerDidAddBundlesNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CUIdSYMBundlesManagerDidRemoveBundlesNotification object:nil];
}

#pragma mark -

- (void)refreshList
{
    NSIndexSet * tIndexSet=_tableView.selectedRowIndexes;
    
    NSArray * tSelectedItems=[_filteredAndSortedBundlesArray objectsAtIndexes:tIndexSet];
    
    NSArray * tSelectedPaths=[tSelectedItems WB_arrayByMappingObjectsUsingBlock:^id(CUIdSYMBundle * bBundle, NSUInteger bIndex) {
        
        return bBundle.bundlePath;
        
    }];
    
    NSSet * tSet=_dSYMBundlesManager.bundlesSet;
    
    if (_filterPattern.length>0)
    {
        _filteredAndSortedBundlesArray=[NSMutableArray array];
        
        [tSet enumerateObjectsUsingBlock:^(CUIdSYMBundle * bBundle, BOOL * bOutStop) {
            
            if ([bBundle.bundlePath.lastPathComponent rangeOfString:self->_filterPattern options:NSCaseInsensitiveSearch].location!=NSNotFound)
            {
                [self->_filteredAndSortedBundlesArray addObject:bBundle];
                return;
            }
            
            for(NSString * tUUID in bBundle.binaryUUIDs)
            {
                if ([tUUID rangeOfString:self->_filterPattern options:NSCaseInsensitiveSearch].location!=NSNotFound)
                {
                    [self->_filteredAndSortedBundlesArray addObject:bBundle];
                    return;
                }
            }
        }];
    }
    else
    {
        _filteredAndSortedBundlesArray=[tSet.allObjects mutableCopy];
    }
    
    [_filteredAndSortedBundlesArray sortUsingDescriptors: _tableView.sortDescriptors];
    
    [_tableView deselectAll:self];
    
    [_tableView reloadData];
    
    NSMutableIndexSet * tNewSelectionIndexSet=[NSMutableIndexSet indexSet];
    
    [_filteredAndSortedBundlesArray enumerateObjectsUsingBlock:^(CUIdSYMBundle * bBundle, NSUInteger bIndex,BOOL * bOutStop) {
        
        if ([tSelectedPaths containsObject:bBundle.bundlePath]==YES)
            [tNewSelectionIndexSet addIndex:bIndex];
        
    }];
    
    if (tNewSelectionIndexSet.count>0)
    {
        [_tableView selectRowIndexes:tNewSelectionIndexSet byExtendingSelection:NO];
    }
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
    SEL tAction=inMenuItem.action;
    
    if (tAction==@selector(delete:))
    {
        NSIndexSet * tIndexSet=[_tableView WB_selectedOrClickedRowIndexes];
        
        return (tIndexSet.count>=1);
    }
    
    if (tAction==@selector(selectAll:))
        return (_filteredAndSortedBundlesArray.count>0);
    
    if (tAction==@selector(showInFinder:))
    {
        NSIndexSet * tSelectionIndexSet=_tableView.WB_selectedOrClickedRowIndexes;
        
        if (tSelectionIndexSet.count==0)
            return NO;
        
        NSArray * tBundles=_filteredAndSortedBundlesArray;
        
        __block BOOL tResult=YES;
        
        [tSelectionIndexSet enumerateIndexesUsingBlock:^(NSUInteger bIndex,BOOL * bOutStop){
            
            CUIdSYMBundle * tBundle=tBundles[bIndex];
            
            NSString * tPath=tBundle.bundlePath;
            
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
    
    return YES;
}

- (IBAction)addDebuggingSymbolsFile:(id)sender
{
    NSOpenPanel * tOpenPanel=[NSOpenPanel openPanel];
    tOpenPanel.prompt=NSLocalizedString(@"Add",@"");
    tOpenPanel.canChooseFiles=YES;
    tOpenPanel.canChooseDirectories=NO;
    tOpenPanel.allowsMultipleSelection=YES;
    tOpenPanel.allowedFileTypes=@[@"dSYM"];
    
    [tOpenPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse bReturnCode) {
        
        if (bReturnCode==NSModalResponseCancel)
            return;
    
        CUIdSYMBundlesManager * tBundlesManager=[CUIdSYMBundlesManager sharedManager];
        
        NSArray * tFilteredBundles=[tOpenPanel.URLs WB_arrayByMappingObjectsLenientlyUsingBlock:^CUIdSYMBundle *(NSURL * bURL, NSUInteger bIndex) {
            
            CUIdSYMBundle * tBundle=[CUIdSYMBundle bundleWithURL:bURL];
            
            if (tBundle.isDSYMBundle==NO)
                return nil;
            
            if ([tBundlesManager containsBundle:tBundle]==YES)
                return nil;
            
            return tBundle;
        }];
        
        
        if (tFilteredBundles.count==0)
        {
            NSBeep();
            
            return;
        }
    
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [tBundlesManager addBundles:tFilteredBundles];
    
            // Select new bundles
        
            NSIndexSet * tIndexSet=[self->_filteredAndSortedBundlesArray indexesOfObjectsPassingTest:^BOOL(CUIdSYMBundle * bBundle, NSUInteger bIndex, BOOL * bOutStop) {
                
                return [tFilteredBundles containsObject:bBundle];
            }];
            
            [self->_tableView selectRowIndexes:tIndexSet byExtendingSelection:NO];
        });
    }];
}

- (IBAction)delete:(id)sender
{
    NSIndexSet * tIndexSet=[_tableView WB_selectedOrClickedRowIndexes];
    
    if (tIndexSet.count==0)
        return;
    
    NSArray * tSelectedBundles=[_filteredAndSortedBundlesArray objectsAtIndexes:tIndexSet];
    
    [_tableView deselectAll:nil];
    
    [_dSYMBundlesManager removeBundles:tSelectedBundles];
}

- (IBAction)showInFinder:(id)sender
{
    NSIndexSet * tSelectionIndexSet=_tableView.WB_selectedOrClickedRowIndexes;
    
    NSWorkspace * tSharedWorkspace=[NSWorkspace sharedWorkspace];
    
    [_filteredAndSortedBundlesArray enumerateObjectsAtIndexes:tSelectionIndexSet options:0 usingBlock:^(CUIdSYMBundle * bBundle, NSUInteger bIndex, BOOL * bOutStop) {
        
        NSString * tPath=bBundle.bundlePath;
        
        if (tPath.length>0)
            [tSharedWorkspace selectFile:tPath inFileViewerRootedAtPath:@""];
        
    }];
}

- (IBAction)takeFilterPatternFrom:(NSSearchField *)sender
{
    _filterPattern=sender.stringValue;
    
    [self refreshList];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)inTableView
{
    if (inTableView==_tableView)
        return _filteredAndSortedBundlesArray.count;
    
    return 0;
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)inTableView viewForTableColumn:(NSTableColumn *)inTableColumn row:(NSInteger)inRow
{
    NSString * tTableColumnIdentifier=inTableColumn.identifier;
    NSTableCellView * tTableCellView=[inTableView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
    
    CUIdSYMBundle * tBundle=_filteredAndSortedBundlesArray[inRow];
    
    if (inTableView==_tableView)
    {
        if ([tTableColumnIdentifier isEqualToString:@"name"]==YES)
        {
            tTableCellView.imageView.image=_cachedBundleIcon;
            
            tTableCellView.textField.stringValue=tBundle.displayName;
            tTableCellView.textField.toolTip=tBundle.bundlePath;
        }
        else if ([tTableColumnIdentifier isEqualToString:@"version"]==YES)
        {
            tTableCellView.textField.stringValue=tBundle.displayVersion;
        }
        else if ([tTableColumnIdentifier isEqualToString:@"uuids"]==YES)
        {
            NSArray * tUUIDs=[tBundle binaryUUIDs];
            
            tTableCellView.textField.stringValue=[tUUIDs componentsJoinedByString:@". "];
        }
        
        tTableCellView.textField.editable=NO;
        
        return tTableCellView;
    }
    
    return nil;
}

- (void)tableView:(NSTableView *)inTableView sortDescriptorsDidChange:(NSArray *)inOldDescriptors
{
    [self refreshList];
}


#pragma mark - Drag and Drop support

- (NSDragOperation)tableView:(NSTableView *)inTableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)inRow proposedDropOperation:(NSTableViewDropOperation)inDropOperation
{
    if (inDropOperation==NSTableViewDropOn)
        return NSDragOperationNone;
    
    NSPasteboard * tPasteBoard=[info draggingPasteboard];
    
    if ([tPasteBoard availableTypeFromArray:@[NSFilenamesPboardType]]==nil)
        return NSDragOperationNone;
    
    NSArray * tArray=(NSArray *) [tPasteBoard propertyListForType:NSFilenamesPboardType];
    
    if (tArray==nil || [tArray isKindOfClass:NSArray.class]==NO)
    {
        // We were provided invalid data
        
        NSLog(@"Unable to validate drop. Unexpected type of data");
        
        return NSDragOperationNone;
    }
    
    if (tArray.count!=1)
        return NSDragOperationNone;
    
    NSFileManager * tFileManager=[NSFileManager defaultManager];
    
    
    for(NSString * tPath in tArray)
    {
        BOOL tIsDirectory;
        
        if ([tFileManager fileExistsAtPath:tPath isDirectory:&tIsDirectory]==NO)
            return NSDragOperationNone;
        
        if (tIsDirectory==NO)
            return NSDragOperationNone;

        // Should have .crash extension
        
        if ([tPath.pathExtension caseInsensitiveCompare:@"dSYM"]!=NSOrderedSame)
            return NSDragOperationNone;
        
        // Do not have the same dSYM twice
        
        for(CUIdSYMBundle * tBundle in _filteredAndSortedBundlesArray)
        {
            if ([tBundle.bundlePath isEqualToString:tPath]==YES)
                return NSDragOperationNone;
        }
    }
    
    // Check that these are dSYM bundles and that the UUIDs are not already listed
    
    CUIdSYMBundlesManager * tBundlesManager=[CUIdSYMBundlesManager sharedManager];
    
    for(NSString * tPath in tArray)
    {
        CUIdSYMBundle * tBundle=[[CUIdSYMBundle alloc] initWithPath:tPath];
        
        if (tBundle.isDSYMBundle==NO)
            return NSDragOperationNone;
        
        if ([tBundlesManager containsBundle:tBundle]==YES)
            return NSDragOperationNone;
    }
    
    [_tableView setDropRow:-1 dropOperation:NSTableViewDropOn];
    
    return NSDragOperationCopy;
}

- (BOOL)tableView:(NSTableView *)inTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)inRow dropOperation:(NSTableViewDropOperation)inDropOperation
{
    if (inTableView!=_tableView)
        return NO;
    
    NSPasteboard * tPasteBoard=[info draggingPasteboard];
    
    if ([tPasteBoard availableTypeFromArray:@[NSFilenamesPboardType]]==nil)
        return NO;
    
    NSArray * tArray=(NSArray *) [tPasteBoard propertyListForType:NSFilenamesPboardType];
    
    NSArray * tNewBundles=[tArray WB_arrayByMappingObjectsUsingBlock:^id(NSString * bPath, NSUInteger bIndex) {
        
        return [[CUIdSYMBundle alloc] initWithPath:bPath];
    }];
    
    if (tNewBundles==nil)
        return NO;
    
    [_tableView deselectAll:nil];
    
    CUIdSYMBundlesManager * tBundlesManager=[CUIdSYMBundlesManager sharedManager];
    
    [tBundlesManager addBundles:tNewBundles];
    
    return YES;
}

#pragma mark - Notifications

- (void)tableViewSelectionDidChange:(NSNotification *)inNotification
{
    NSIndexSet * tIndexSet=_tableView.selectedRowIndexes;
    
    if (tIndexSet.count==0)
    {
        _removeButton.enabled=NO;
        
        return;
    }
    
    _removeButton.enabled=YES;
}

- (void)dSYMBundlesManagerDidAddBundles:(NSNotification *)inNotification
{
    [self refreshList];
}

- (void)dSYMBundlesManagerDidRemoveBundles:(NSNotification *)inNotification
{
    [self refreshList];
}

@end
