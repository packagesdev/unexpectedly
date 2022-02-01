/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIPreferencePaneFontscolorsViewController.h"

#import "CUICategoriesClipView.h"

#import "CUIApplicationPreferences.h"
#import "CUIApplicationPreferences+Themes.h"

#import "CUITableCustomSelectionColorRowView.h"
#import "CUIAATextFieldCell.h"

#import "CUIThemesManager.h"

#import "CUIThemeItemsGroup+UI.h"

#import "NSTableView+Selection.h"

#import "NSArray+UniqueName.h"

NSString * const CUICustomColorSelectionRowViewIdentifier=@"whitebox.colorSelectionRowView";

@interface CUITheme (Private)

- (instancetype)initWithRepresentation:(NSDictionary *)inRepresentation newUUID:(BOOL)inNewUUID;

@end

@interface CUIPreferencePaneFontscolorsViewController () <NSTableViewDataSource,NSTableViewDelegate>
{
    IBOutlet NSTableView * _themesTableView;
    
    IBOutlet NSButton * _duplicateThemeButton;
    
    IBOutlet NSButton * _removeThemeButton;
    
    
    IBOutlet NSView * _presentationModeTabHeaderView;
    
    IBOutlet CUICategoriesClipView * _categoriesClipView;
    
    IBOutlet NSTableView * _categoriesTableView;
    
    
    IBOutlet NSTextField * _fontLabel;
    
    IBOutlet NSButton * _fontPanelButton;
    
    IBOutlet NSColorWell * _textColorWell;
    
    
    
    IBOutlet NSColorWell * _backgroundColorWell;
    
    
    IBOutlet NSColorWell * _textSelectionBackgroundColorWell;
    
    IBOutlet NSColorWell * _selectedTextColorWell;
    
    
    CUIThemesManager * _sharedThemeManager;
    
    
    NSArray * _cachedSortedThemes;
    
    
    CUIPresentationMode _selectedPresentationMode;
    
    CUIThemeItemsGroup * _selectedThemeItemsGroup;
    
    NSArray * _cachedItemsNames;
    
    NSString * _selectedItemName;
    
    
    NSColor * _cachedBackgroundColor;
}

- (void)refreshPresentationModeUI;

- (void)refreshBottomUI;

- (IBAction)switchSelectedPresentationMode:(id)sender;

- (IBAction)showFontPanel:(id)sender;

- (IBAction)takeTextColor:(NSColorWell *)sender;

- (IBAction)takeBackgroundColor:(id)sender;

- (IBAction)takeTextSelectionBackgroundColor:(id)sender;

- (IBAction)takeSelectedTextColor:(id)sender;

- (IBAction)restoreDefaults:(id)sender;


// Notifications

- (void)currentThemeDidChange:(NSNotification *)inNotification;

- (void)themesListDidChange:(NSNotification *)inNotification;

@end

@implementation CUIPreferencePaneFontscolorsViewController

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _sharedThemeManager=[CUIThemesManager sharedManager];
    }
    
    return self;
}

- (NSString *)nibName
{
    return @"CUIPreferencePaneFontscolorsViewController";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _selectedPresentationMode=CUIPresentationModeText;
    
    [((NSButton *)[_presentationModeTabHeaderView viewWithTag:_selectedPresentationMode]) setState:NSOnState];
    
    ((NSClipView *)_categoriesTableView.superview).drawsBackground=YES;
    
    [NSColorPanel sharedColorPanel].continuous=YES;
}

#pragma mark -

- (void)viewWillAppear
{
    [super viewWillAppear];
    
    _cachedSortedThemes=[[_sharedThemeManager allThemes] sortedArrayUsingComparator:^NSComparisonResult(CUITheme * bTheme, CUITheme * bOtherTheme) {
        
        return [bTheme.name caseInsensitiveCompare:bOtherTheme.name];
    }];
    
    _removeThemeButton.enabled=(_cachedSortedThemes.count>1);
    
    _themesTableView.allowsEmptySelection=YES;
    
    [_themesTableView reloadData];
    
    NSUInteger tIndex=[_cachedSortedThemes indexOfObject:_sharedThemeManager.currentTheme];
    
    [_themesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:tIndex] byExtendingSelection:NO];
    
    _themesTableView.allowsEmptySelection=NO;
    
    [self refreshPresentationModeUI];
}

- (void)viewDidAppear
{
    [super viewDidAppear];
    
    [self.view.window makeFirstResponder:_categoriesTableView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentThemeDidChange:) name:CUIThemesManagerCurrentThemeDidChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(themesListDidChange:) name:CUIThemesManagerThemesListDidChangeNotification object:nil];
}

- (void)viewWillDisappear
{
    [super viewWillDisappear];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CUIThemesManagerCurrentThemeDidChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CUIThemesManagerThemesListDidChangeNotification object:nil];
}

#pragma mark -

- (CGFloat)minimumHeight
{
    return 350;
}

- (CGFloat)maximumHeight
{
    return 800;
}

#pragma mark -

- (void)refreshPresentationModeUI
{
    _selectedThemeItemsGroup=[_sharedThemeManager.currentTheme itemsGroupWithIdentifier:[CUIApplicationPreferences groupIdentifierForPresentationMode:_selectedPresentationMode]];
    
    if (_selectedThemeItemsGroup==nil)
    {
        NSLog(@"Error: Missing Theme Items Group: %@",[CUIApplicationPreferences groupIdentifierForPresentationMode:_selectedPresentationMode]);
        
        return;
    }
    
    NSMutableArray * tItemsNames=[_selectedThemeItemsGroup.itemsNames mutableCopy];
    
    [tItemsNames removeObject:CUIThemeItemBackground];
    [tItemsNames removeObject:CUIThemeItemLineNumber];
    [tItemsNames removeObject:CUIThemeItemSelectionBackground];
    [tItemsNames removeObject:CUIThemeItemSelectionText];
    
    _cachedItemsNames=[tItemsNames copy];
    
    _cachedBackgroundColor=[[_selectedThemeItemsGroup attributesForItem:CUIThemeItemBackground] color];
    
    
    if (floor(NSAppKitVersionNumber)<=NSAppKitVersionNumber10_13)
    {
        _categoriesTableView.backgroundColor=_cachedBackgroundColor;
    }
    
    _categoriesClipView.themeBackgroundColor=_cachedBackgroundColor;
    
    NSInteger tSelectedRow=_categoriesTableView.selectedRow;
    
    [_categoriesTableView reloadData];
    
    if (tSelectedRow!=-1)
        [_categoriesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:tSelectedRow] byExtendingSelection:NO];
    
    [self refreshBottomUI];
    
    _backgroundColorWell.color=_cachedBackgroundColor;
    
    _textSelectionBackgroundColorWell.color=[[_selectedThemeItemsGroup attributesForItem:CUIThemeItemSelectionBackground] color];
    
    _selectedTextColorWell.color=[[_selectedThemeItemsGroup attributesForItem:CUIThemeItemSelectionText] color];
    
}

- (void)refreshBottomUI
{
    CUIThemeItemAttributes * tAttributes=[_selectedThemeItemsGroup attributesForItem:_selectedItemName];
    
    NSFont * tFont=tAttributes.font;
    
    _fontLabel.stringValue=[NSString stringWithFormat:@"%@ - %.1f",tFont.displayName,tFont.pointSize];
    
    NSColor * tColor=tAttributes.color;
    
    if (tColor==nil)
        return;
    
    _textColorWell.color=tColor;
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
    SEL tAction=inMenuItem.action;
    
    if (tAction==@selector(delete:))
    {
        return (_cachedSortedThemes.count>1);  // A REVOIR
    }
    
    return YES;
}

#pragma mark - Themes actions

- (IBAction)takeThemeName:(NSTextField *)sender
{
    NSString * tNewName=sender.stringValue;
    
    if (tNewName.length==0)
    {
        NSBeep();
        
        return;
    }
    
    NSInteger tEditedRow=[_themesTableView rowForView:sender];
    
    if (tEditedRow==-1)
        return;
    
    CUITheme * tTheme=_cachedSortedThemes[tEditedRow];
    
    if ([tTheme.name isEqualToString:tNewName]==YES)
        return;
    
    NSMutableArray * tExistingThemes=[_cachedSortedThemes mutableCopy];
    [tExistingThemes removeObject:tTheme];
    
    NSArray * tAllNames=[tExistingThemes WB_arrayByMappingObjectsUsingBlock:^NSString *(CUITheme *bTheme, NSUInteger bIndex) {
        
        return bTheme.name;
        
    }];
    
    if ([tAllNames containsObject:tNewName]==YES)
    {
        NSAlert * tAlert=[NSAlert new];
        tAlert.alertStyle=NSAlertStyleCritical;
        tAlert.messageText=[NSString stringWithFormat:NSLocalizedString(@"The name \"%@\" is already taken.",@""),tNewName];
        tAlert.informativeText=NSLocalizedString(@"Please choose a different name.",@"");
        
        [tAlert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
            
            [self->_themesTableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:tEditedRow] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
            
            [self->_themesTableView editColumn:0 row:tEditedRow withEvent:nil select:YES];
            
        }];
        
        return;
    }
    
    BOOL tSuccess=[_sharedThemeManager renameTheme:_sharedThemeManager.currentTheme withName:tNewName];
    
    if (tSuccess==NO)
    {
        NSLog(@"Error when trying to rename theme %@ to name %@",_sharedThemeManager.currentTheme,tNewName);
    }
}

- (IBAction)duplicate:(id)sender
{
    NSIndexSet * tIndexSet=[_themesTableView WB_selectedOrClickedRowIndexes];
    
    if (tIndexSet.count!=1)
        return;
    
    CUITheme * tNewTheme=[_sharedThemeManager duplicateTheme:_cachedSortedThemes[tIndexSet.firstIndex]];
    
    _sharedThemeManager.currentTheme=tNewTheme;
    
    _removeThemeButton.enabled=YES;
}

- (IBAction)delete:(id)sender
{
    NSIndexSet * tIndexSet=[_themesTableView WB_selectedOrClickedRowIndexes];
    
    if (tIndexSet.count!=1)
        return;
    
    CUITheme * tTheme=_cachedSortedThemes[tIndexSet.firstIndex];
    
    NSAlert * tAlert=[NSAlert new];
    
    tAlert.messageText=[NSString stringWithFormat:NSLocalizedString(@"Do you really want to remove the \"%@\" theme?", @""),tTheme.name];
    tAlert.informativeText=NSLocalizedString(@"This cannot be undone.", @"");
    
    [tAlert addButtonWithTitle:NSLocalizedString(@"Remove",@"")];
    [tAlert addButtonWithTitle:NSLocalizedString(@"Cancel",@"")];
    
    [tAlert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse bReturnCode) {
        
        if (bReturnCode!=NSAlertFirstButtonReturn)
            return;
        
        [self->_sharedThemeManager removeTheme:tTheme];
        
        self->_removeThemeButton.enabled=(self->_sharedThemeManager.allThemes.count>1);
    }];
}

- (IBAction)exportTheme:(id)sender
{
    NSIndexSet * tIndexSet=[_themesTableView WB_selectedOrClickedRowIndexes];
    
    if (tIndexSet.count!=1)
        return;
    
    CUITheme * tTheme=_cachedSortedThemes[tIndexSet.firstIndex];
    
    if (tTheme==nil)
        return;
    
    NSDictionary * tRepresentation=[tTheme representation];
    
    if (tRepresentation==nil)
        return;
    
    NSSavePanel * tExportPanel=[NSSavePanel savePanel];
    
    tExportPanel.canSelectHiddenExtension=YES;
    tExportPanel.allowedFileTypes=@[@"fr.whitebox.unexpectedly.theme"];
    
    tExportPanel.nameFieldLabel=NSLocalizedString(@"Export As:", @"");
    tExportPanel.nameFieldStringValue=tTheme.name;
    
    tExportPanel.prompt=NSLocalizedString(@"Export", @"");
    
    [tExportPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger bResult){
        
        if (bResult!=NSModalResponseOK)
            return;
        
        if ([tRepresentation writeToURL:tExportPanel.URL atomically:NO]==NO)
        {
            NSBeep();
            
            // A COMPLETER
        }
    }];
}

- (IBAction)importTheme:(id)sender
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
        
        NSDictionary * tDictionary=[NSDictionary dictionaryWithContentsOfURL:tImportPanel.URL];
        
        if (tDictionary==nil)
        {
            // A COMPLETER
            
            return;
        }
        
        CUITheme * tTheme=[[CUITheme alloc] initWithRepresentation:tDictionary newUUID:YES];
        
        if (tTheme==nil)
        {
            // A COMPLETER
            
            return;
        }
        
        // Check that no themes exist with that name
        
        CUIThemesManager * tThemesManager=[CUIThemesManager sharedManager];
        NSArray * tAllThemes=tThemesManager.allThemes;
        
        NSUInteger tIndex=[tAllThemes indexOfObjectPassingTest:^BOOL(CUITheme * bTheme, NSUInteger bIndex, BOOL * bOutStop) {
            
            return [bTheme.name isEqualToString:tTheme.name];
            
        }];
        
        if (tIndex!=NSNotFound)
        {
            NSAlert * tAlert=[NSAlert new];
            tAlert.messageText=[NSString stringWithFormat:NSLocalizedString(@"A theme named \"%@\" already exists. Do you want to replace it with the one you're importing?", @""),tTheme.name];
            
            [tAlert addButtonWithTitle:NSLocalizedString(@"Replace", @"")];
            [tAlert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
            [tAlert addButtonWithTitle:NSLocalizedString(@"Keep Both", @"")];
            
            NSModalResponse tResponse=[tAlert runModal];
            
            switch(tResponse)
            {
                case NSAlertFirstButtonReturn:  // Replace
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        [tThemesManager removeTheme:tAllThemes[tIndex]];
                        [tThemesManager addTheme:tTheme];
                        
                    });
                    
                    return;
                }
                case NSAlertSecondButtonReturn: // Cancel
                    
                    return;
                    
                case NSAlertThirdButtonReturn:  // Keep Both
                {
                    NSString * tNewName=[tAllThemes uniqueNameWithBaseName:[tTheme.name stringByAppendingString:NSLocalizedString(@" copy", @"")]
                                                        usingNameExtractor:^NSString *(CUITheme * bThene, NSUInteger bIndex) {
                                                            return bThene.name;
                                                        }];
                    
                    if (tNewName==nil)
                    {
                        NSLog(@"Uh oh");
                        NSBeep();
                        
                        return;
                    }
                    
                    tTheme.name=tNewName;
                    
                    break;
                }
            }
        }
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [tThemesManager addTheme:tTheme];
            
        });
        
        
    }];
}

#pragma mark -

- (IBAction)switchSelectedPresentationMode:(NSButton *)sender
{
    _selectedPresentationMode=sender.tag;
    
    [self refreshPresentationModeUI];
}

- (IBAction)showFontPanel:(id)sender
{
    NSFontManager * tFontManager = [NSFontManager sharedFontManager];
    
    [tFontManager setSelectedFont:[[_selectedThemeItemsGroup attributesForItem:_selectedItemName] font]
                       isMultiple:NO];
    
    tFontManager.target=self;
    tFontManager.action=@selector(changeFont:);
    
    [[tFontManager fontPanel:YES] orderFront:self];
}

- (void)changeFont:(id)sender
{
    NSInteger tSelectedRow=_categoriesTableView.selectedRow;
    
    if (tSelectedRow==-1)
        return;
    
    NSFontManager * tFontManager = [NSFontManager sharedFontManager];
    
    CUIThemeItemAttributes * tItemAttributes=[_selectedThemeItemsGroup attributesForItem:_selectedItemName];
    
    NSFont * tOldFont=tItemAttributes.font;
    
    NSFont * tNewFont=[tFontManager convertFont:tFontManager.selectedFont];
    
    if ([tNewFont isEqual:tOldFont]==NO)
    {
        tItemAttributes.font=tNewFont;
        
        [self refreshBottomUI];
        
        NSIndexSet * tIndexSet=[NSIndexSet indexSetWithIndex:tSelectedRow];
        
        [_categoriesTableView reloadDataForRowIndexes:tIndexSet columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,1)]];
        
        [_categoriesTableView noteHeightOfRowsWithIndexesChanged:tIndexSet];
    }
}

- (IBAction)takeTextColor:(NSColorWell *)sender
{
    CUIThemeItemAttributes * tItemAttributes=[_selectedThemeItemsGroup attributesForItem:_selectedItemName];
    
    tItemAttributes.color=sender.color;
    
    [_categoriesTableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:[_categoriesTableView selectedRow]] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
}

- (IBAction)takeBackgroundColor:(NSColorWell *)sender
{
    _cachedBackgroundColor=sender.color;
    
    CUIThemeItemAttributes * tItemAttributes=[_selectedThemeItemsGroup attributesForItem:CUIThemeItemBackground];
    
    tItemAttributes.color=_cachedBackgroundColor;
    
    [self refreshPresentationModeUI];
}

- (IBAction)takeTextSelectionBackgroundColor:(NSColorWell *)sender
{
    CUIThemeItemAttributes * tItemAttributes=[_selectedThemeItemsGroup attributesForItem:CUIThemeItemSelectionBackground];
    
    tItemAttributes.color=sender.color;
    
    [self refreshPresentationModeUI];
}

- (IBAction)takeSelectedTextColor:(NSColorWell *)sender
{
    CUIThemeItemAttributes * tItemAttributes=[_selectedThemeItemsGroup attributesForItem:CUIThemeItemSelectionText];
    
    tItemAttributes.color=sender.color;
    
    [self refreshPresentationModeUI];
}

- (IBAction)restoreDefaults:(id)sender
{
    NSAlert * tAlert=[NSAlert new];
    
    tAlert.messageText=NSLocalizedString(@"Do you really want to restore the default Fonts & Colors settings?", @"");
    tAlert.informativeText=NSLocalizedString(@"You will lose all the changes you made.", @"");
    
    [tAlert addButtonWithTitle:NSLocalizedString(@"Restore",@"")];
    [tAlert addButtonWithTitle:NSLocalizedString(@"Cancel",@"")];
    
    [tAlert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse bReturnCode) {
        
        if (bReturnCode!=NSAlertFirstButtonReturn)
            return;
        
        [self->_sharedThemeManager reset];
        
        [self->_themesTableView reloadData];
    }];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)inTableView
{
    if (inTableView==_themesTableView)
        return _cachedSortedThemes.count;
    
    if (inTableView==_categoriesTableView)
        return _cachedItemsNames.count;

    return 0;
}

#pragma mark - NSTableViewDelegate

- (NSTableRowView *)tableView:(NSTableView *)inTableView rowViewForRow:(NSInteger)inRow
{
    if (inTableView==_themesTableView)
        return nil;
    
    CUITableCustomSelectionColorRowView * tTableRowView=[inTableView makeViewWithIdentifier:CUICustomColorSelectionRowViewIdentifier owner:self];
    
    if (tTableRowView==nil)
    {
        tTableRowView=[[CUITableCustomSelectionColorRowView alloc] initWithFrame:NSZeroRect];
        tTableRowView.identifier=CUICustomColorSelectionRowViewIdentifier;
    }
    
    tTableRowView.selectionColor=[[_selectedThemeItemsGroup attributesForItem:CUIThemeItemSelectionBackground] color];
    tTableRowView.backgroundColor=_cachedBackgroundColor;
    
    return tTableRowView;
}

- (NSView *)tableView:(NSTableView *)inTableView viewForTableColumn:(NSTableColumn *)inTableColumn row:(NSInteger)inRow
{
    NSString * tTableColumnIdentifier=inTableColumn.identifier;
    NSTableCellView * tTableCellView=[inTableView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
    
    if (inTableView==_themesTableView)
    {
        tTableCellView.textField.stringValue=[_cachedSortedThemes[inRow] name];
        tTableCellView.textField.editable=YES;
        
        return tTableCellView;
    }
    
    if (inTableView==_categoriesTableView)
    {
        NSString * tItemName=_cachedItemsNames[inRow];
        
        tTableCellView.textField.stringValue=[CUIThemeItemsGroup displayNameForItemNamed:tItemName];
        
        CUIThemeItemAttributes * tItemAttributes=[_selectedThemeItemsGroup attributesForItem:tItemName];
        
        tTableCellView.textField.font=tItemAttributes.font;
        
        if ([_categoriesTableView isRowSelected:inRow]==YES)
            tTableCellView.textField.backgroundColor=[[_selectedThemeItemsGroup attributesForItem:CUIThemeItemSelectionBackground] color];
        else
            tTableCellView.textField.backgroundColor=_cachedBackgroundColor;
        
        tTableCellView.textField.textColor=tItemAttributes.color;
        
        return tTableCellView;
    }
    
    return nil;
}

- (CGFloat)tableView:(NSTableView *)inTableView heightOfRow:(NSInteger)inRow
{
    if (inTableView==_themesTableView)
        return 26.0;
    
    if (inTableView==_categoriesTableView)
    {
        NSString * tItemName=_cachedItemsNames[inRow];
        CUIThemeItemAttributes * tItemAttributes=[_selectedThemeItemsGroup attributesForItem:tItemName];
        NSFont * tFont=tItemAttributes.font;
        
        return 10.0+(tFont.ascender-tFont.descender+tFont.leading);
    }
    
    return 18.0;
}

- (void)tableViewSelectionDidChange:(NSNotification *)inNotification
{
    if (inNotification.object==_themesTableView)
    {
        NSInteger tSelectedRow=_themesTableView.selectedRow;
        
        if (tSelectedRow==-1 || self.view.window==nil)
            return;
        
        _sharedThemeManager.currentTheme=_cachedSortedThemes[tSelectedRow];
        
        return;
    }
    
    if (inNotification.object==_categoriesTableView)
    {
        NSInteger tSelectedRow=_categoriesTableView.selectedRow;
        
        if (tSelectedRow==-1)
            return;
        
        _selectedItemName=_cachedItemsNames[tSelectedRow];
        
        [self refreshBottomUI];
        
        return;
    }
}

#pragma mark - Notifications

- (void)currentThemeDidChange:(NSNotification *)inNotification
{
    NSUInteger tIndex=[_cachedSortedThemes indexOfObject:_sharedThemeManager.currentTheme];
    
    [_themesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:tIndex] byExtendingSelection:NO];
    
    [self refreshPresentationModeUI];
}

- (void)themesListDidChange:(NSNotification *)inNotification
{
    _cachedSortedThemes=[[_sharedThemeManager allThemes] sortedArrayUsingComparator:^NSComparisonResult(CUITheme * bTheme, CUITheme * bOtherTheme) {
        
        return [bTheme.name caseInsensitiveCompare:bOtherTheme.name];
    }];
    
    _themesTableView.allowsEmptySelection=YES;
    
    [_themesTableView deselectAll:nil];
    
    [_themesTableView reloadData];
    
    NSUInteger tIndex=[_cachedSortedThemes indexOfObject:_sharedThemeManager.currentTheme];
    
    if (tIndex!=NSNotFound)
        [_themesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:tIndex] byExtendingSelection:NO];
    
    _themesTableView.allowsEmptySelection=NO;
}

@end
