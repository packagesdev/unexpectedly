/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICrashLogsSourcesViewController.h"

#import "CUICrashLogsSource.h"
#import "CUICrashLogsSourceSeparator.h"
#import "CUICrashLogsSourceAll.h"
#import "CUICrashLogsSourceFileSystemItem.h"
#import "CUICrashLogsSourceFile.h"
#import "CUICrashLogsSourceDirectory.h"

#import "CUICrashLogsSource+UI.h"

#import "CUICrashLogsSourcesManager.h"

#import "CUICrashLogsSourcesSelection.h"

#import "NSTableView+Selection.h"

#import "NSArray+WBExtensions.h"
#import "NSIndexSet+Analysis.h"

#import "CUICrashLogsSourceTableCellView.h"

#import "CUICrashLogsSourceSmartEditorPanel.h"

#import "NSArray+UniqueName.h"

NSString * const CUICrashLogsSourcesInternalPboardType=@"fr.whitebox.unexpectedly.sources.internal.array";

@interface CUICrashLogsSourcesViewController () <NSOpenSavePanelDelegate,NSTableViewDataSource,NSTableViewDelegate>
{
    IBOutlet NSTableView * _tableView;
    
    IBOutlet NSButton * _removeButton;
    
    IBOutlet NSPopUpButton * _actionPopUpButton;
    
    CUICrashLogsSourcesManager * _sourcesManager;
    
    CUICrashLogsSourcesSelection * _sourcesSelection;
    
    NSIndexSet * _internalDragData;
}

- (IBAction)tableViewDoubleAction:(id)sender;

- (IBAction)takeSourceNameFrom:(id)sender;

- (IBAction)CUI_MENUACTION_addSource:(id)sender;

- (IBAction)CUI_MENUACTION_addSmartSource:(id)sender;

- (IBAction)editSmartSource:(id)sender;

- (IBAction)CUI_MENUACTION_importSmartSource:(id)sender;

- (IBAction)CUI_MENUACTION_exportSmartSource:(id)sender;

- (IBAction)removeSources:(id)sender;

- (IBAction)showInFinder:(id)sender;

// Notifications

- (void)sourcesManagerSourcesDidChange:(NSNotification *)inNotification;

- (void)sourceDidUpdateSource:(NSNotification *)inNotification;

- (void)sourcesSelectionDidChange:(NSNotification *)inNotification;

@end

@implementation CUICrashLogsSourcesViewController

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _sourcesManager=[CUICrashLogsSourcesManager sharedManager];
        
        _sourcesSelection=[CUICrashLogsSourcesSelection sharedSourcesSelection];
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
    return @"CUICrashLogsSourcesViewController";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _tableView.doubleAction=@selector(tableViewDoubleAction:);
    
    [_tableView registerForDraggedTypes:@[NSFilenamesPboardType,CUICrashLogsSourcesInternalPboardType]];
    
    _removeButton.enabled=NO;
    
    NSUInteger tIndex=0;
    
    if (_sourcesSelection.sources.count>0)
    {
        tIndex=[_sourcesManager.allSources indexOfObject:_sourcesSelection.sources.allObjects.firstObject];
    }
    
    [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:tIndex] byExtendingSelection:NO];
    
    // Register for notifications
    
    NSNotificationCenter * tNotificationCenter=[NSNotificationCenter defaultCenter];
    
    [tNotificationCenter addObserver:self selector:@selector(sourcesManagerSourcesDidChange:) name:CUICrashLogsSourcesManagerSourcesDidChangeNotification object:_sourcesManager];
    
    [tNotificationCenter addObserver:self selector:@selector(sourceDidUpdateSource:) name:CUICrashLogsSourceDidUpdateSourceNotification object:nil];
    
    [tNotificationCenter addObserver:self selector:@selector(sourcesSelectionDidChange:) name:CUICrashLogsSourcesSelectionDidChangeNotification object:_sourcesSelection];
}

- (void)viewDidAppear
{
    [self tableViewSelectionDidChange:[NSNotification notificationWithName:NSTableViewSelectionDidChangeNotification object:_tableView userInfo:nil]];
}

#pragma mark -

- (NSRect)effectiveBottonBarRect
{
    NSRect tEffectiveRect;
    
    tEffectiveRect.origin.x=NSMaxX(_removeButton.frame);
    tEffectiveRect.size.width=NSMinX(_actionPopUpButton.frame)-tEffectiveRect.origin.x;
    
    tEffectiveRect.origin.y=NSHeight(_tableView.enclosingScrollView.frame);
    tEffectiveRect.size.height=NSMinY(_tableView.enclosingScrollView.frame);
    
    return tEffectiveRect;
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
    SEL tAction=inMenuItem.action;
    
    NSIndexSet * tSelectedRows=[_tableView WB_selectedOrClickedRowIndexes];
    
    if (tAction==@selector(delete:))
    {
        if (tSelectedRows.count==0)
            return NO;
        
        __block BOOL tSourcesCanBeDeleted=YES;
        
        NSArray * tSelectedSources=[_sourcesManager.allSources objectsAtIndexes:tSelectedRows];
        
        [tSelectedSources enumerateObjectsUsingBlock:^(CUICrashLogsSource * bSource, NSUInteger bIndex, BOOL * bOutStop) {
            
            switch(bSource.type)
            {
                case CUICrashLogsSourceTypeAll:
                case CUICrashLogsSourceTypeStandardDirectory:
                case CUICrashLogsSourceTypeToday:
                    
                    tSourcesCanBeDeleted=NO;
                    
                    break;
                    
                default:
                    
                    break;
            }
        }];
        
        return tSourcesCanBeDeleted;
    }
    
    if (tAction==@selector(editSmartSource:))
    {
        __block BOOL tCanEdit=YES;
        
        [_sourcesManager.allSources enumerateObjectsAtIndexes:tSelectedRows options:0 usingBlock:^(CUICrashLogsSource * bSource, NSUInteger bIndex, BOOL * bOutStop) {
            
            if ([bSource isMemberOfClass:[CUICrashLogsSourceSmart class]]==NO)
            {
                tCanEdit=NO;
                *bOutStop=YES;
            }
            
        }];
        
        return tCanEdit;
    }
    
    if (tAction==@selector(CUI_MENUACTION_exportSmartSource:))
    {
        __block BOOL tCanExport=YES;
        
        [_sourcesManager.allSources enumerateObjectsAtIndexes:tSelectedRows options:0 usingBlock:^(CUICrashLogsSource * bSource, NSUInteger bIndex, BOOL * bOutStop) {
            
            if ([bSource isMemberOfClass:[CUICrashLogsSourceSmart class]]==NO)
            {
                tCanExport=NO;
                *bOutStop=YES;
            }
            
        }];
        
        return tCanExport;
    }
    
    if (tAction==@selector(showInFinder:))
    {
        __block BOOL tCanShowInFinder=YES;
        
        [_sourcesManager.allSources enumerateObjectsAtIndexes:tSelectedRows options:0 usingBlock:^(CUICrashLogsSource * bSource, NSUInteger bIndex, BOOL * bOutStop) {
            
            if ([bSource isKindOfClass:[CUICrashLogsSourceFileSystemItem class]]==NO)
            {
                tCanShowInFinder=NO;
                *bOutStop=YES;
            }
            
        }];
        
        return tCanShowInFinder;
    }
    
    return YES;
}

- (IBAction)delete:(id)sender
{
    [self removeSources:sender];
}

- (IBAction)tableViewDoubleAction:(id)sender
{
    NSIndexSet * tSelectedRows=[_tableView WB_selectedOrClickedRowIndexes];
    
    NSArray * tArray=[_sourcesManager.allSources objectsAtIndexes:tSelectedRows];
    
    CUICrashLogsSourceSmart * tSmartSource=tArray.firstObject;
    
    if (tSmartSource.type!=CUICrashLogsSourceTypeSmart)
        return;
    
    [self editSmartSource:sender];
}

- (IBAction)takeSourceNameFrom:(NSTextField *)sender
{
    NSInteger tEditedRow=[_tableView rowForView:sender];
    
    if (tEditedRow==-1)
        return;
    
    NSString * tNewName=sender.stringValue;

    CUICrashLogsSourceSmart * tSourceSmart=(CUICrashLogsSourceSmart *)_sourcesManager.allSources[tEditedRow];
    
    // Avoid replacing with the same name
    
    if ([tNewName isEqualToString:tSourceSmart.name]==YES)
        return;
    
    // Avoid empty Name
    
    if (tNewName.length==0)
    {
        [_tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:tEditedRow] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
        
        return;
    }
    
    // Avoid duplicate names
    
    NSArray * tAllSmartSourcesNames=[[_sourcesManager sourcesOfType:CUICrashLogsSourceTypeSmart] WB_arrayByMappingObjectsUsingBlock:^NSString *(CUICrashLogsSourceSmart * bSmartSource, NSUInteger bIndex) {
        
        return bSmartSource.name;
    }];
    
    if ([tAllSmartSourcesNames containsObject:tNewName]==YES)
    {
        NSAlert * tAlert=[NSAlert new];
        tAlert.alertStyle=NSAlertStyleCritical;
        tAlert.messageText=[NSString stringWithFormat:NSLocalizedString(@"The name \"%@\" is already taken.",@""),tNewName];
        tAlert.informativeText=NSLocalizedString(@"Please choose a different name.",@"");
        
        [tAlert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
            
            [self->_tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:tEditedRow] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
            
            [self->_tableView editColumn:0 row:tEditedRow withEvent:nil select:YES];
            
        }];
    
        return;
    }
    
    tSourceSmart.name=tNewName;
    
    [_sourcesManager synchronizeDefaults];
}

- (IBAction)CUI_MENUACTION_addSource:(id)sender
{
    NSOpenPanel * tOpenPanel=[NSOpenPanel openPanel];
    tOpenPanel.canChooseFiles=YES;
    tOpenPanel.canChooseDirectories=YES;
    tOpenPanel.allowsMultipleSelection=NO;
    tOpenPanel.prompt=NSLocalizedString(@"Add", @"");
    //tOpenPanel.allowedFileTypes=@[@".crash"];
    
    tOpenPanel.delegate=self;
    
    [tOpenPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse bReturnCode) {
        
        if (bReturnCode==NSModalResponseCancel)
            return;
        
        NSMutableArray * tNewSources=[NSMutableArray array];
        
        for(NSURL * tURL in tOpenPanel.URLs)
        {
            if (tURL.isFileURL==NO)
                continue;
            
            BOOL tIsDirectory;
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:tURL.path isDirectory:&tIsDirectory]==NO)
                continue;
            
            CUICrashLogsSource * tSource=nil;
            
            if (tIsDirectory==NO)
            {
                tSource=[[CUICrashLogsSourceFile alloc] initWithContentsOfFileSystemItemAtPath:tURL.path error:NULL];
            }
            else
            {
                tSource=[[CUICrashLogsSourceDirectory alloc] initWithContentsOfFileSystemItemAtPath:tURL.path error:NULL];
            }
            
            if (tSource==nil)
            {
                continue;
            }
            
            if (tSource!=nil)
                [tNewSources addObject:tSource];
        }
        
        [self->_sourcesManager addSources:tNewSources];
        
        [self->_tableView reloadData];
        
        [self->_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:self->_sourcesManager.allSources.count-1] byExtendingSelection:NO];
        
    }];
}

- (IBAction)CUI_MENUACTION_addSmartSource:(id)sender
{
    CUICrashLogsSourceSmartEditorPanel * tEditorPanel=[CUICrashLogsSourceSmartEditorPanel crashLogsSourceSmartEditorPanel];
    
    tEditorPanel.source=[CUICrashLogsSourceSmart new];
    
    tEditorPanel.prompt=NSLocalizedString(@"Add",@"");
    
    [tEditorPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse bResponse) {
        
        if (bResponse==NSModalResponseCancel)
            return;
        
        [self->_sourcesManager addSources:@[tEditorPanel.source]];
        
        [self->_tableView reloadData];
        
        [self->_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:self->_sourcesManager.allSources.count-1] byExtendingSelection:NO];
    }];
}

- (IBAction)editSmartSource:(id)sender
{
    CUICrashLogsSourceSmartEditorPanel * tEditorPanel=[CUICrashLogsSourceSmartEditorPanel crashLogsSourceSmartEditorPanel];
    
    NSIndexSet * tSelectedRows=[_tableView WB_selectedOrClickedRowIndexes];
    
    NSArray * tArray=[_sourcesManager.allSources objectsAtIndexes:tSelectedRows];
    
    tEditorPanel.source=tArray.firstObject;
    
    tEditorPanel.prompt=NSLocalizedString(@"OK",@"");
    
    [tEditorPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse bResponse) {
        
        if (bResponse==NSModalResponseCancel)
            return;
        
        [self->_tableView reloadDataForRowIndexes:tSelectedRows columnIndexes:[NSIndexSet indexSetWithIndex:0]];
        
        [self->_sourcesManager synchronizeDefaults];
    }];
}

- (IBAction)CUI_MENUACTION_importSmartSource:(id)sender
{
    NSOpenPanel * tImportPanel=[NSOpenPanel openPanel];
    
    tImportPanel.resolvesAliases=YES;
    tImportPanel.canChooseFiles=YES;
    //tImportPanel.allowsMultipleSelection=YES;
    tImportPanel.canCreateDirectories=NO;
    tImportPanel.prompt=NSLocalizedString(@"Import", @"");
    
    //tImportPanel.delegate=self;
    
    [tImportPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger bResult){
        
        if (bResult!=NSModalResponseOK)
            return;
        
        NSArray * tExistingSmartSources=[self->_sourcesManager sourcesOfType:CUICrashLogsSourceTypeSmart];
        
        NSArray * tSmartSources=[tImportPanel.URLs WB_arrayByMappingObjectsLenientlyUsingBlock:^CUICrashLogsSourceSmart *(NSURL * bURL, NSUInteger bIndex) {
            
            NSDictionary * tDictionary=[NSDictionary dictionaryWithContentsOfURL:tImportPanel.URL];
            
            if (tDictionary==nil)
            {
                NSLog(@"Import Smart Source failure: the selected file is not a property list file.");
                
                return nil;
            }
            
            CUICrashLogsSourceSmart * tSmartSource=[[CUICrashLogsSourceSmart alloc] initWithRepresentation:tDictionary];
            
            if (tSmartSource==nil)
            {
                NSLog(@"Import Smart Source failure: the selected property list file is not a smart source file.");
                
                return nil;
            }
            
            NSString * tUniqueSourceName=[tExistingSmartSources uniqueNameWithBaseName:tSmartSource.name usingNameExtractor:^NSString *(CUICrashLogsSourceSmart * bSmartSource, NSUInteger bIndex) {
                
                return bSmartSource.name;
            }];
            
            if (tUniqueSourceName==nil)
            {
                NSLog(@"Import Smart Source failure: a smart source with this name already exists.");
                
                // A COMPLETER
                
                return nil;
            }
            
            tSmartSource.name=tUniqueSourceName;
            
            return tSmartSource;
            
        }];
        
        
        
        [self->_sourcesManager addSources:tSmartSources];
        
        [self->_tableView reloadData];
        
        [self->_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:self->_sourcesManager.allSources.count-1] byExtendingSelection:NO];
    }];
}

- (IBAction)CUI_MENUACTION_exportSmartSource:(id)sender
{
    NSIndexSet * tIndexSet=[_tableView WB_selectedOrClickedRowIndexes];
    
    if (tIndexSet.count!=1)
        return;
    
    CUICrashLogsSourceSmart * tSource=_sourcesManager.allSources[tIndexSet.firstIndex];
    
    NSDictionary * tRepresentation=[tSource representation];
    
    if (tRepresentation==nil)
        return;
    
    NSSavePanel * tExportPanel=[NSSavePanel savePanel];
    
    tExportPanel.canSelectHiddenExtension=YES;
    tExportPanel.allowedFileTypes=@[@"fr.whitebox.unexpectedly.smartSource"];
    
    tExportPanel.nameFieldLabel=NSLocalizedString(@"Export As:", @"");
    tExportPanel.nameFieldStringValue=tSource.name;
    
    tExportPanel.prompt=NSLocalizedString(@"Export", @"");
    
    [tExportPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger bResult){
        
        if (bResult!=NSModalResponseOK)
            return;
        
        NSError * tError=nil;
        
        if ([tRepresentation writeToURL:tExportPanel.URL error:&tError]==NO)
        {
            NSBeep();
            
            NSLog(@"%@",tError.description);
            
            // A COMPLETER
        }
    }];
}

- (IBAction)removeSources:(id)sender
{
    NSIndexSet * tSelectedRows=[_tableView WB_selectedOrClickedRowIndexes];
    
    NSArray * tArray=[_sourcesManager.allSources objectsAtIndexes:tSelectedRows];
    
    [_sourcesManager removeSources:tArray];
    
    [_tableView reloadData];
}

- (IBAction)showInFinder:(id)sender
{
    NSIndexSet * tSelectedRows=[_tableView WB_selectedOrClickedRowIndexes];
    
    [_sourcesManager.allSources enumerateObjectsAtIndexes:tSelectedRows options:0 usingBlock:^(CUICrashLogsSourceFileSystemItem * bSource, NSUInteger bIndex, BOOL * bOutStop) {
    
        [[NSWorkspace sharedWorkspace] selectFile:bSource.path inFileViewerRootedAtPath:@""];
    
    }];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)inTableView
{
    return _sourcesManager.allSources.count;
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)inTableView viewForTableColumn:(NSTableColumn *)inTableColumn row:(NSInteger)inRow
{
    CUICrashLogsSource * tSource=_sourcesManager.allSources[inRow];
    
    if (tSource.type==CUICrashLogsSourceTypeSeparator)
    {
        return [inTableView makeViewWithIdentifier:@"separator" owner:self];
    }
    
    CUICrashLogsSourceTableCellView * tTableCellView=(CUICrashLogsSourceTableCellView *)[inTableView makeViewWithIdentifier:@"regular" owner:self];
    
    tTableCellView.imageView.image=tSource.icon;

    tTableCellView.textField.editable=(tSource.type==CUICrashLogsSourceTypeSmart);
    
    tTableCellView.textField.stringValue=tSource.name;

    tTableCellView.toolTip=tSource.sourceDescription;

    tTableCellView.countTextField.stringValue=[NSString stringWithFormat:@"%lu",tSource.crashLogs.count];
    
    return tTableCellView;
}

- (CGFloat)tableView:(NSTableView *)inTableView heightOfRow:(NSInteger)inRow
{
    CUICrashLogsSource * tSource=_sourcesManager.allSources[inRow];
    
    if (tSource.type==CUICrashLogsSourceTypeSeparator)
        return 12.0;
    
    return 24.0;
}

- (BOOL)tableView:(NSTableView *)inTableView shouldSelectRow:(NSInteger)inRow
{
    CUICrashLogsSource * tSource=_sourcesManager.allSources[inRow];
    
    return (tSource.type!=CUICrashLogsSourceTypeSeparator);
}

#pragma mark - Drag and Drop support

- (BOOL)tableView:(NSTableView *)inTableView writeRowsWithIndexes:(NSIndexSet *)inRowIndexes toPasteboard:(NSPasteboard *)inPasteboard;
{
    for(CUICrashLogsSource * tSource in [_sourcesManager.allSources objectsAtIndexes:inRowIndexes])
    {
        switch(tSource.type)
        {
            case CUICrashLogsSourceTypeUnknown:
            case CUICrashLogsSourceTypeAll:
            case CUICrashLogsSourceTypeStandardDirectory:
            case CUICrashLogsSourceTypeToday:
            case CUICrashLogsSourceTypeSeparator:
                
                return NO;
                
            default:
                
                break;
        }
    }
    
    _internalDragData=inRowIndexes;
    
    [inPasteboard declareTypes:@[CUICrashLogsSourcesInternalPboardType] owner:self];
    
    [inPasteboard setData:[NSData data] forType:CUICrashLogsSourcesInternalPboardType];
    
    return YES;
}

- (NSDragOperation)tableView:(NSTableView *)inTableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)inRow proposedDropOperation:(NSTableViewDropOperation)inDropOperation
{
    if (inDropOperation==NSTableViewDropOn)
        return NSDragOperationNone;
    
    NSPasteboard * tPasteBoard=[info draggingPasteboard];
    
    // Internal Drag
    
    if ([tPasteBoard availableTypeFromArray:@[CUICrashLogsSourcesInternalPboardType]]!=nil && [info draggingSource]==inTableView)
    {
        NSUInteger tSeparatorRow=[_sourcesManager.allSources indexOfObject:[CUICrashLogsSourceSeparator separator]];
        
        if (tSeparatorRow==NSNotFound)
            return NSDragOperationNone;
        
        if (inRow<=tSeparatorRow)
            return NSDragOperationNone;
        
        if ([_internalDragData WB_containsOnlyOneRange]==YES)
        {
            NSUInteger tFirstIndex=_internalDragData.firstIndex;
            NSUInteger tLastIndex=_internalDragData.lastIndex;
            
            if (inRow>=tFirstIndex && inRow<=(tLastIndex+1))
                return NSDragOperationNone;
        }
        else
        {
            if ([_internalDragData containsIndex:(inRow-1)]==YES)
                return NSDragOperationNone;
        }
        
        return NSDragOperationMove;
    }
    
    if ([tPasteBoard availableTypeFromArray:@[NSFilenamesPboardType]]!=nil)
    {
        NSArray * tArray=(NSArray *) [tPasteBoard propertyListForType:NSFilenamesPboardType];
    
        if (tArray==nil || [tArray isKindOfClass:NSArray.class]==NO)
        {
            // We were provided invalid data
            
            // A COMPLETER
            
            return NSDragOperationNone;
        }
        
        if (tArray.count!=1)
            return NSDragOperationNone;
        
        NSFileManager * tFileManager=[NSFileManager defaultManager];
        BOOL tIsDirectory;
        
        CUICrashLogsSourceAll * tSourcesAll=[CUICrashLogsSourceAll crashLogsSourceAll];
        
        for(NSString * tPath in tArray)
        {
            if ([tFileManager fileExistsAtPath:tPath isDirectory:&tIsDirectory]==YES)
            {
                if (tIsDirectory==NO)
                {
                    // Should have .crash or .smartsource extension
                    
                    if ([tPath.pathExtension caseInsensitiveCompare:@"crash"]==NSOrderedSame)
                    {
                        // Do not have the same file twice
                    
                        for(CUIRawCrashLog * tCrashLog in tSourcesAll.crashLogs)
                        {
                            if ([tCrashLog.crashLogFilePath isEqualToString:tPath]==YES)
                                    return NSDragOperationNone;
                        }
                    }
                    else
                    {
                        if ([tPath.pathExtension caseInsensitiveCompare:@"smartsource"]!=NSOrderedSame)
                            return NSDragOperationNone;
                    }
                }
                else
                {
                    // Do not have the same directory twice
                    
                    for(CUICrashLogsSource * tSource in _sourcesManager.allSources)
                    {
                        switch(tSource.type)
                        {
                            case CUICrashLogsSourceTypeStandardDirectory:
                            case CUICrashLogsSourceTypeDirectory:
                            {
                                CUICrashLogsSourceDirectory * tSourceFile=(CUICrashLogsSourceDirectory *)tSource;
                                
                                
                                
                                if ([tSourceFile.path isEqualToString:tPath]==YES)
                                    return NSDragOperationNone;
                                
                                break;
                            }
                            default:
                                
                                break;
                        }
                    }
                }
            }
        }
        
        
        
        // A COMPLETER (Check that we don't already have the files/folder already in the list)
        
        [inTableView setDropRow:-1 dropOperation:NSTableViewDropOn];
        
        return NSDragOperationCopy;
    }
    
    return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)inTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)inRow dropOperation:(NSTableViewDropOperation)inDropOperation
{
    if (inTableView!=_tableView)
        return NO;
    
    // Internal drag and drop
    
    NSPasteboard * tPasteBoard=[info draggingPasteboard];
    
    if ([tPasteBoard availableTypeFromArray:@[CUICrashLogsSourcesInternalPboardType]]!=nil && [info draggingSource]==inTableView)
    {
        //NSArray * tObjects=[_sourcesManager.allSources objectsAtIndexes:_internalDragData];
        
        NSUInteger tIndex=[_internalDragData firstIndex];
        
        while (tIndex!=NSNotFound)
        {
            if (tIndex<inRow)
                inRow--;
            
            tIndex=[_internalDragData indexGreaterThanIndex:tIndex];
        }
        
        NSIndexSet * tNewIndexSet=[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(inRow, _internalDragData.count)];
        
        [_sourcesManager moveSourcesAtIndexes:_internalDragData toIndexes:tNewIndexSet];
        
        [inTableView deselectAll:nil];
        
        [inTableView reloadData];
        
        [inTableView selectRowIndexes:tNewIndexSet byExtendingSelection:NO];
        
        [_sourcesManager synchronizeDefaults];
        
        return YES;
    }
    
    if ([tPasteBoard availableTypeFromArray:@[NSFilenamesPboardType]]!=nil)
    {
        NSArray * tArray=(NSArray *) [tPasteBoard propertyListForType:NSFilenamesPboardType];
        
        NSFileManager * tFileManager=[NSFileManager defaultManager];
        
        NSMutableArray * tDelayedSmartSources=[NSMutableArray array];
        
        NSArray * tNewSources=[tArray WB_arrayByMappingObjectsLenientlyUsingBlock:^id(NSString * bPath, NSUInteger bIndex) {
            
            CUICrashLogsSource * tSource=nil;
            BOOL tIsDirectory;
            
            if ([tFileManager fileExistsAtPath:bPath isDirectory:&tIsDirectory]==YES)
            {
                NSError * tError;
                
                if (tIsDirectory==NO)
                {
                    if ([bPath.pathExtension caseInsensitiveCompare:@"crash"]==NSOrderedSame)
                    {
                        tSource=[[CUICrashLogsSourceFile alloc] initWithContentsOfFileSystemItemAtPath:bPath error:&tError];
                    }
                    else if ([bPath.pathExtension caseInsensitiveCompare:@"smartsource"]==NSOrderedSame)
                    {
                        NSDictionary * tRepresentation=[NSDictionary dictionaryWithContentsOfFile:bPath];
                        
                        tSource=[[CUICrashLogsSourceSmart alloc] initWithRepresentation:tRepresentation];
                        
                        // Check that the name is not already used and offer to use a unique name
                        
                        NSString * tName=tSource.name;
                        
                        if (tName.length==0)
                        {
                            // A COMPLETER
                            
                            return nil;
                        }
                        
                        NSArray * tExistingSmartSources=[[CUICrashLogsSourcesManager sharedManager] sourcesOfType:CUICrashLogsSourceTypeSmart];
                        
                        for(CUICrashLogsSourceSmart * tSmartSource in tExistingSmartSources)
                        {
                            if ([tSmartSource.name isEqualToString:tName]==YES)
                            {
                                [tDelayedSmartSources addObject:tSource];
                                return nil;
                            }
                        }
                    }
                }
                else
                {
                    tSource=[[CUICrashLogsSourceDirectory alloc] initWithContentsOfFileSystemItemAtPath:bPath error:&tError];
                }
            }
            
            return tSource;
        }];
        
        if (tNewSources.count==0 && tDelayedSmartSources.count==0)
            return NO;
        
        if (tNewSources.count>0)
        {
            [_tableView deselectAll:nil];
        
            [_sourcesManager addSources:tNewSources];
        
            [_tableView reloadData];
        
            [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:_sourcesManager.allSources.count-1] byExtendingSelection:NO];
        }
        
        if (tDelayedSmartSources.count==0)
        {
            // Handle collisions
            
            // A COMPLETER
        }
        
        return YES;
    }
    
    return NO;
}

- (void)tableView:(NSTableView *)inTableView draggingSession:(NSDraggingSession *)inDraggingSession endedAtPoint:(NSPoint)inScreenPoint operation:(NSDragOperation)inOperation
{
    _internalDragData=nil;
}

#pragma mark - NSOpenSavePanelDelegate

- (BOOL)panel:(id)sender shouldEnableURL:(NSURL *)inURL
{
    if (inURL==nil)
        return NO;
    
    if (inURL.isFileURL==NO)
        return NO;
    
    if (inURL.hasDirectoryPath==NO)
        return ([inURL.pathExtension caseInsensitiveCompare:@"crash"]==NSOrderedSame);
    
    /*NSString * tPath=inURL.path;
    
    for(CUICrashLogsSourceFileSystemItem * tSource in _sources)
    {
        if ([tSource isKindOfClass:[CUICrashLogsSourceFileSystemItem class]]==YES)
        {
            if ([tSource.path isEqualToString:tPath]==YES)
                return NO;
        }
    }*/
    
    return YES;
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

#pragma mark -

- (void)tableViewSelectionDidChange:(NSNotification *)inNotification
{
    NSIndexSet * tIndexSet=[_tableView selectedRowIndexes];
    
    if (tIndexSet.count==0)
    {
        _removeButton.enabled=NO;
        
        _sourcesSelection.sources=[NSSet set];
    }
    else
    {
        __block BOOL tSourcesCanBeDeleted=YES;
        
        NSArray * tSelectedSources=[_sourcesManager.allSources objectsAtIndexes:tIndexSet];
        
        [tSelectedSources enumerateObjectsUsingBlock:^(CUICrashLogsSource * bSource, NSUInteger bIndex, BOOL * bOutStop) {
            
            switch(bSource.type)
            {
                case CUICrashLogsSourceTypeAll:
                case CUICrashLogsSourceTypeStandardDirectory:
                case CUICrashLogsSourceTypeToday:
                    
                    tSourcesCanBeDeleted=NO;
                    
                    break;
                    
                default:
                    
                    break;
            }
        }];
        
        _removeButton.enabled=tSourcesCanBeDeleted;
        
        _sourcesSelection.sources=[[NSSet alloc] initWithArray:tSelectedSources];
    }
}

- (void)sourcesManagerSourcesDidChange:(NSNotification *)inNotification
{
    NSSet * tOldSources=_sourcesSelection.sources;
    
    [_tableView reloadData];
 
    // Refresh Selection
    
    NSMutableIndexSet * tIndexSet=[NSMutableIndexSet indexSet];
    
    [_sourcesManager.allSources enumerateObjectsUsingBlock:^(CUICrashLogsSource * bSource, NSUInteger bIndex, BOOL * bOutStop) {
        
        if ([tOldSources containsObject:bSource]==YES)
            [tIndexSet addIndex:bIndex];
        
    }];
    
    if (tIndexSet.count==0)
    {
        [tIndexSet addIndex:0];
    }
    
    _sourcesSelection.sources=[[NSSet alloc] initWithArray:[_sourcesManager.allSources objectsAtIndexes:tIndexSet]];
    
    [_tableView selectRowIndexes:tIndexSet byExtendingSelection:NO];
}

- (void)sourceDidUpdateSource:(NSNotification *)inNotification
{
    CUICrashLogsSource * tSource=(CUICrashLogsSource *)inNotification.object;
    
    if ([tSource isKindOfClass:[CUICrashLogsSource class]]==NO)
        return;
    
    NSUInteger tIndex=[_sourcesManager.allSources indexOfObject:tSource];
    
    if (tIndex==NSNotFound)
        return;
    
    [_tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:tIndex] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
}

- (void)sourcesSelectionDidChange:(NSNotification *)inNotification
{
    NSNotificationCenter * tNotificationCenter=[NSNotificationCenter defaultCenter];
    
    // Stop observing
    
    [tNotificationCenter removeObserver:self name:CUICrashLogsSourcesSelectionDidChangeNotification object:_sourcesSelection];
    
    // Refresh Selection
    
    NSMutableIndexSet * tIndexSet=[NSMutableIndexSet indexSet];
    
    [_sourcesManager.allSources enumerateObjectsUsingBlock:^(CUICrashLogsSource * bSource, NSUInteger bIndex, BOOL * bOutStop) {
        
        if ([self->_sourcesSelection.sources containsObject:bSource]==YES)
            [tIndexSet addIndex:bIndex];
        
    }];
    
    if (tIndexSet.count!=_sourcesManager.allSources.count)
    {
        if (tIndexSet.count==0)
            [tIndexSet addIndex:0];
        
        _sourcesSelection.sources=[[NSSet alloc] initWithArray:[_sourcesManager.allSources objectsAtIndexes:tIndexSet]];
    }
    
    [_tableView selectRowIndexes:tIndexSet byExtendingSelection:NO];
    
    // Restore observation
    
    [tNotificationCenter addObserver:self selector:@selector(sourcesSelectionDidChange:) name:CUICrashLogsSourcesSelectionDidChangeNotification object:_sourcesSelection];
}

@end
