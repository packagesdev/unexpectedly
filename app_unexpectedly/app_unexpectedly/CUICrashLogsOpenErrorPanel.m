/*
 Copyright (c) 2021-2024, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICrashLogsOpenErrorPanel.h"

#import "CUICrashLogsOpenErrorRecord+UI.h"

#import "NSTableView+Selection.h"

@interface CUICrashLogsOpenErrorWindowController : NSWindowController <NSMenuItemValidation,NSTableViewDataSource,NSTableViewDelegate>
{
    IBOutlet NSTextField * _messageLabel;
    
    IBOutlet NSTextField * _informativeLabel;
    
    IBOutlet NSTableView * _tableView;
    
    IBOutlet NSButton * _defaultButton;
}

@property (nonatomic) NSArray<CUICrashLogsOpenErrorRecord *> * errors;

- (void)updateUI;

- (IBAction)showInFinder:(id)sender;

- (IBAction)endDialog:(id)sender;

@end

@implementation CUICrashLogsOpenErrorWindowController

- (NSString *)windowNibName
{
    return @"CUICrashLogsOpenErrorWindowController";
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    NSTableColumn * tTableColumn=[_tableView tableColumnWithIdentifier:@"file"];
    tTableColumn.headerCell.title=NSLocalizedString(@"Name",@"");
    
    tTableColumn=[_tableView tableColumnWithIdentifier:@"reason"];
    tTableColumn.headerCell.title=NSLocalizedString(@"Reason",@"");
    
    NSRect tButtonFrame=_defaultButton.frame;
    
    _defaultButton.title=NSLocalizedString(@"OK",@"");
    
    [_defaultButton sizeToFit];
    
    CGFloat tWidth=NSWidth(_defaultButton.frame);
    
    if (tWidth<CUIAppkitMinimumPushButtonWidth)
        tWidth=CUIAppkitMinimumPushButtonWidth;
    
    tButtonFrame.origin.x=NSMaxX(tButtonFrame)-tWidth;
    tButtonFrame.size.width=tWidth;
    
    _defaultButton.frame=tButtonFrame;
    
    [self updateUI];
}

#pragma mark -

- (void)setErrors:(NSArray<CUICrashLogsOpenErrorRecord *> *)inErrors
{
    if (_errors==inErrors)
        return;
    
    _errors=inErrors;
    
    if (_tableView!=nil)
        [self updateUI];
}

#pragma mark -

- (void)updateUI
{
    NSString * tMessageString=@"";
    NSString * tInformativeString=@"";
    
    switch (_errors.count)
    {
        case 0:
            
            break;
            
        case 1:
            
            tMessageString=NSLocalizedString(@"An error occurred while opening the file.", @"");
            tInformativeString=NSLocalizedString(@"The file can't be opened for the following reason:", @"");
            
            break;
            
        default:
            
            tMessageString=NSLocalizedString(@"An error occurred while opening some files.", @"");
            tInformativeString=NSLocalizedString(@"These files can't be opened for the following reasons:", @"");
            
            break;
    }
    
    _messageLabel.stringValue=tMessageString;
    _informativeLabel.stringValue=tInformativeString;
    
    [_tableView reloadData];
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
    SEL tAction=inMenuItem.action;
    
    if (tAction==@selector(showInFinder:))
    {
        return YES;
    }
    
    return YES;
}

- (IBAction)showInFinder:(id)sender
{
    NSIndexSet * tSelectedRows=[_tableView WB_selectedOrClickedRowIndexes];
    
    [self.errors enumerateObjectsAtIndexes:tSelectedRows options:0 usingBlock:^(CUICrashLogsOpenErrorRecord * bRecord, NSUInteger bIndex, BOOL * bOutStop) {
        
        [[NSWorkspace sharedWorkspace] selectFile:bRecord.sourceURL.path inFileViewerRootedAtPath:@""];
        
    }];
}

- (IBAction)endDialog:(NSButton *)sender
{
    [NSApp stopModalWithCode:NSModalResponseOK];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return _errors.count;
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)inTableView viewForTableColumn:(NSTableColumn *)inTableColumn row:(NSInteger)inRow
{
    CUICrashLogsOpenErrorRecord * tRecord=_errors[inRow];
    
    NSString * tTableColumnIdentifier=inTableColumn.identifier;
    NSTableCellView * tTableCellView=[inTableView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
    
    if ([tTableColumnIdentifier isEqualToString:@"file"]==YES)
    {
        NSImage * tIcon=[[NSWorkspace sharedWorkspace] iconForFile:tRecord.sourceURL.path];
        
        tTableCellView.imageView.image=tIcon;
        
        tTableCellView.textField.stringValue=tRecord.sourceURL.path.lastPathComponent;
    }
    else if ([tTableColumnIdentifier isEqualToString:@"reason"]==YES)
    {
        tTableCellView.textField.stringValue=tRecord.localizedDescription;
    }
    
    return tTableCellView;
}

@end

@interface CUICrashLogsOpenErrorPanel ()
{
    CUICrashLogsOpenErrorWindowController * retainedWindowController;
}

- (void)_sheetDidEndSelector:(NSWindow *)inWindow returnCode:(NSInteger)inReturnCode contextInfo:(void *)contextInfo;

@end

@implementation CUICrashLogsOpenErrorPanel

+ (CUICrashLogsOpenErrorPanel *)crashLogsOpenErrorPanel
{
    CUICrashLogsOpenErrorWindowController * tWindowController=[CUICrashLogsOpenErrorWindowController new];
    
    CUICrashLogsOpenErrorPanel * tPanel=(CUICrashLogsOpenErrorPanel *)tWindowController.window;
    tPanel->retainedWindowController=tWindowController;
    
    return tPanel;
}

#pragma mark -

- (NSArray<CUICrashLogsOpenErrorRecord *> *)errors
{
    return retainedWindowController.errors;
}

- (void)setErrors:(NSArray<CUICrashLogsOpenErrorRecord *> *)inErrors
{
    retainedWindowController.errors=inErrors;
}

#pragma mark -

- (void)_sheetDidEndSelector:(CUICrashLogsOpenErrorPanel *)inPanel returnCode:(NSInteger)inReturnCode contextInfo:(void *)contextInfo
{
    void(^handler)(NSInteger) = (__bridge_transfer void(^)(NSInteger)) contextInfo;
    
    if (handler!=nil)
        handler(inReturnCode);
    
    inPanel->retainedWindowController=nil;
    
    [inPanel orderOut:self];
}

- (void)beginSheetModalForWindow:(NSWindow *)inWindow completionHandler:(void (^)(NSModalResponse))handler
{
    [inWindow beginSheet:self completionHandler:^(NSModalResponse bResponse) {
        
        if (handler!=nil)
            handler(bResponse);
        
        self->retainedWindowController=nil;
    }];
}

- (NSModalResponse)runModal
{
    NSModalResponse tModalResponse=[NSApp runModalForWindow:self];
    
    retainedWindowController=nil;
    
    [self orderOut:self];
    
    return tModalResponse;
}

@end

