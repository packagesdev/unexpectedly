/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIBinaryImagesViewController.h"

#import "CUIBinaryImage.h"

#import "CUIBinaryImage+UI.h"

#import "CUICallsSelection.h"

#import "CUIApplicationItemAttributes.h"

#import "NSArray+WBExtensions.h"

#import "NSTableView+Selection.h"

#import "NSSet+WBExtensions.h"

#import "CUIRawCrashLog+Path.h"

#import "CUIHopperDisassemblerManager.h"

@interface CUIBinaryImagesViewController () <NSTableViewDataSource,NSTableViewDelegate,CUIHopperDisassemblerActions>
{
    IBOutlet NSTableView * _tableView;
    
    IBOutlet NSMenuItem * _openWithMenuItem;
    
    IBOutlet NSSearchField * _filterField;
    
    NSMutableArray * _sortedAndFilteredBinaryImagesArray;
    
    NSString * _filterPattern;
    
    NSSet * _highlightedBinaryImagesSet;
}

    @property (nonatomic,copy) NSString * userCodeBinaryImageIdentifier;

    @property (nonatomic) NSArray * binaryImages;

- (void)refreshList;

- (IBAction)showInFinder:(id)sender;

- (IBAction)takeFilterPatternFrom:(id)sender;

// Notifications

- (void)callsSelectionDidChange:(NSNotification *)inNotification;

@end

@implementation CUIBinaryImagesViewController

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _filterPattern=@"";
    }
    
    return self;
}

#pragma mark -

- (NSString *)nibName
{
    return @"CUIBinaryImagesViewController";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Table
    
    NSSortDescriptor *buildETASortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"addressesRange" ascending:YES];
    
    _tableView.sortDescriptors=@[buildETASortDescriptor];
    
    // Open With menu
    
    NSMenu * tHopperMenu=[[CUIHopperDisassemblerManager sharedManager] availableApplicationsMenuWithTarget:self];
    
    _openWithMenuItem.submenu=tHopperMenu;
    _openWithMenuItem.hidden=(tHopperMenu==nil);
    
    // Filter Field
    
    _filterField.centersPlaceholder=NO;
    
    NSSearchFieldCell * tSearchFieldCell=_filterField.cell;
    NSButtonCell * tButtonCell=tSearchFieldCell.searchButtonCell;
    
    tButtonCell.image=[NSImage imageNamed:@"filter_Template"];
    tButtonCell.alternateImage=tButtonCell.image;
    
    // Notifications
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callsSelectionDidChange:) name:CUICallsSelectionDidChangeNotification object:[CUICallsSelection sharedCallsSelection]];
}

#pragma mark -

- (void)setCrashLog:(CUICrashLog *)inCrashLog
{
    if (_crashLog==inCrashLog)
        return;
    
    _crashLog=inCrashLog;
    
    _binaryImages=_crashLog.binaryImages.binaryImages;
    _userCodeBinaryImageIdentifier=_crashLog.header.bundleIdentifier;
    
    [_tableView sizeLastColumnToFit];
    
    [self refreshList];
}

#pragma mark -

- (void)refreshList
{
    NSIndexSet * tIndexSet=_tableView.selectedRowIndexes;
    
    NSArray * tSelectedItems=[_sortedAndFilteredBinaryImagesArray objectsAtIndexes:tIndexSet];
    
    NSArray * tSelectedPaths=[tSelectedItems WB_arrayByMappingObjectsUsingBlock:^id(CUIBinaryImage * bBinaryImage, NSUInteger bIndex) {
        
        return bBinaryImage.path;
        
    }];
    
    NSArray * tArray=_binaryImages;
    
    if (_filterPattern.length>0)
    {
        _sortedAndFilteredBinaryImagesArray=[NSMutableArray array];
        
        [tArray enumerateObjectsUsingBlock:^(CUIBinaryImage * bBinaryImage, NSUInteger bIndex, BOOL * bOutStop) {
            
            if ([bBinaryImage.identifier rangeOfString:self->_filterPattern options:NSCaseInsensitiveSearch].location!=NSNotFound ||
                [bBinaryImage.addressesRange.stringValue rangeOfString:self->_filterPattern options:NSCaseInsensitiveSearch].location!=NSNotFound ||
                [bBinaryImage.path rangeOfString:self->_filterPattern options:NSCaseInsensitiveSearch].location!=NSNotFound)
            {
                [self->_sortedAndFilteredBinaryImagesArray addObject:bBinaryImage];
            }
        }];
    }
    else
    {
        _sortedAndFilteredBinaryImagesArray=[tArray mutableCopy];
    }
    
    [_sortedAndFilteredBinaryImagesArray sortUsingDescriptors: _tableView.sortDescriptors];
    
    [_tableView reloadData];
    
    NSMutableIndexSet * tNewSelectionIndexSet=[NSMutableIndexSet indexSet];
    
    [_sortedAndFilteredBinaryImagesArray enumerateObjectsUsingBlock:^(CUIBinaryImage * bBinaryImage, NSUInteger bIndex,BOOL * bOutStop) {
        
        if ([tSelectedPaths containsObject:bBinaryImage.path]==YES)
            [tNewSelectionIndexSet addIndex:bIndex];
        
    }];
    
    if (tNewSelectionIndexSet.count>0)
        [_tableView selectRowIndexes:tNewSelectionIndexSet byExtendingSelection:NO];
    
    NSMutableIndexSet * tMutableIndexSet=[NSMutableIndexSet indexSet];
    
    [_sortedAndFilteredBinaryImagesArray enumerateObjectsUsingBlock:^(CUIBinaryImage * bBinaryImage, NSUInteger bIndex, BOOL * bOutStop) {
        
        if ([self->_highlightedBinaryImagesSet containsObject:bBinaryImage.identifier]==YES)
            [tMutableIndexSet addIndex:bIndex];
    }];
    
    if (tMutableIndexSet.count>0)
        [_tableView scrollRowToVisible:tMutableIndexSet.firstIndex];
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
    SEL tAction=inMenuItem.action;
    
    NSIndexSet * tSelectedRows=[_tableView WB_selectedOrClickedRowIndexes];
    
    if (tAction==@selector(showInFinder:) ||
        tAction==@selector(openWithHopperDisassembler:))
    {
        if (tSelectedRows.count==0)
            return NO;
        
        NSArray<CUIBinaryImage *> * tArray=[_sortedAndFilteredBinaryImagesArray objectsAtIndexes:tSelectedRows];
        
        NSFileManager * tFileManager=[NSFileManager defaultManager];
        
        for(CUIBinaryImage * tBinaryImage in tArray)
        {
            NSString * tPath=tBinaryImage.path;
            
            if (tPath.length==0)
                return NO;
            
            if ([tFileManager fileExistsAtPath:tPath]==NO)
                return NO;
        }
        
        return (tSelectedRows.count>0);
    }
    
    return YES;
}

- (IBAction)showInFinder:(id)sender
{
    NSIndexSet * tSelectionIndexSet=_tableView.WB_selectedOrClickedRowIndexes;
    
    NSWorkspace * tSharedWorkspace=[NSWorkspace sharedWorkspace];
    
    [_sortedAndFilteredBinaryImagesArray enumerateObjectsAtIndexes:tSelectionIndexSet options:0 usingBlock:^(CUIBinaryImage * bBinaryImage, NSUInteger bIndex, BOOL * bOutStop) {
        
        if (bBinaryImage.path.length>0)
            [tSharedWorkspace selectFile:bBinaryImage.path inFileViewerRootedAtPath:@""];
    }];
}

- (IBAction)openWithHopperDisassembler:(NSMenuItem *)sender
{
    NSIndexSet * tSelectionIndexSet=_tableView.WB_selectedOrClickedRowIndexes;
    
    CUIApplicationItemAttributes * tApplicationItemAttributes=sender.representedObject;
    
    [_sortedAndFilteredBinaryImagesArray enumerateObjectsAtIndexes:tSelectionIndexSet options:0 usingBlock:^(CUIBinaryImage * bBinaryImage, NSUInteger bIndex, BOOL * bOutStop) {
        
        if (bBinaryImage.path.length>0)
        {
            [[CUIHopperDisassemblerManager sharedManager] openBinaryImage:bBinaryImage.path
                                                withApplicationAttributes:tApplicationItemAttributes
                                                                 codeType:self.crashLog.header.codeType
                                                               fileOffSet:NULL];
        }
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
    return _sortedAndFilteredBinaryImagesArray.count;
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)inTableView viewForTableColumn:(NSTableColumn *)inTableColumn row:(NSInteger)inRow
{
    NSString * tTableColumnIdentifier=inTableColumn.identifier;
    NSTableCellView * tTableCellView=[inTableView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
    
    CUIBinaryImage * tBinaryImage=_sortedAndFilteredBinaryImagesArray[inRow];
    
    if (_highlightedBinaryImagesSet.count>0)
        tTableCellView.textField.textColor=[NSColor secondaryLabelColor];
    
    if ([_highlightedBinaryImagesSet containsObject:tBinaryImage.identifier]==YES)
    {
        tTableCellView.textField.textColor=[NSColor labelColor];
        
        tTableCellView.textField.font=[[NSFontManager sharedFontManager] convertFont:tTableCellView.textField.font
                                                                         toHaveTrait:NSBoldFontMask];
    }
    else
    {
        tTableCellView.textField.font=[[NSFontManager sharedFontManager] convertFont:tTableCellView.textField.font
                                                                         toHaveTrait:NSUnboldFontMask];
    }
    
    if ([tTableColumnIdentifier isEqualToString:@"identifier"]==YES)
    {
        tTableCellView.textField.stringValue=tBinaryImage.identifier;
        
        if (tBinaryImage.isUserCode==YES)
        {
            tTableCellView.imageView.image=[NSImage imageNamed:@"call-usercode"];
        }
        else
        {
            tTableCellView.imageView.image=[CUIBinaryImage iconForIdentifier:tBinaryImage.identifier];
        }
        
        
    }
    else if ([tTableColumnIdentifier isEqualToString:@"version"]==YES)
    {
        if (tBinaryImage.buildNumber==nil)
        {
            tTableCellView.textField.stringValue=tBinaryImage.version;
        }
        else
        {
            tTableCellView.textField.stringValue=[NSString stringWithFormat:@"%@ (%@)",tBinaryImage.version,tBinaryImage.buildNumber];
        }
    }
    else if ([tTableColumnIdentifier isEqualToString:@"addresses"]==YES)
    {
        //tTableCellView.textField.font=[NSFont monospacedDigitSystemFontOfSize:18.0 weight:NSFontWeightRegular];
        tTableCellView.textField.stringValue=tBinaryImage.addressesRange.stringValue;
    }
    else if ([tTableColumnIdentifier isEqualToString:@"path"]==YES)
    {
        tTableCellView.textField.stringValue=[self.crashLog stringByResolvingUSERInPath:tBinaryImage.path];
    }
    
    return tTableCellView;
}

- (void)tableView:(NSTableView *)inTableView sortDescriptorsDidChange:(NSArray *)inOldDescriptors
{
    [self refreshList];
}

#pragma mark - Notifications

- (void)callsSelectionDidChange:(NSNotification *)inNotification
{
    CUICallsSelection * tCallSelection=inNotification.object;
    
    if ([tCallSelection isKindOfClass:[CUICallsSelection class]]==NO)
        return;
    
    _highlightedBinaryImagesSet=tCallSelection.binaryImageIdentifiers;
    
    NSMutableIndexSet * tMutableIndexSet=[NSMutableIndexSet indexSet];
    
    
    [_sortedAndFilteredBinaryImagesArray enumerateObjectsUsingBlock:^(CUIBinaryImage * bBinaryImage, NSUInteger bIndex, BOOL * bOutStop) {
        
        if ([self->_highlightedBinaryImagesSet containsObject:bBinaryImage.identifier]==YES)
        {
            [tMutableIndexSet addIndex:bIndex];
        }
    }];
    
    [_tableView reloadData];
    
    if (tMutableIndexSet.count>0)
        [_tableView scrollRectToVisible:[_tableView rectOfRow:tMutableIndexSet.firstIndex]];
}

@end
