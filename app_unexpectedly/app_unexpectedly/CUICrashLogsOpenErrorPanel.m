//
//  CUICrashLogsReadErrorPanel.m
//  Unexpectedly
//
//  Created by stephane on 10/06/2021.
//  Copyright © 2021 Acme, Inc. All rights reserved.
//

#import "CUICrashLogsOpenErrorPanel.h"

#import "CUICrashLogsOpenErrorRecord+UI.h"

#import "NSTableView+Selection.h"

@interface CUICrashLogsOpenErrorWindowController : NSWindowController <NSTableViewDataSource,NSTableViewDelegate>
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
            
            tMessageString=NSLocalizedString(@"An error occurred when opening the file.", @"");
            tInformativeString=NSLocalizedString(@"The file can't be opened for the following reason:", @"");
            
            break;
            
        default:
            
            tMessageString=NSLocalizedString(@"An error occurred when opening some files.", @"");
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

- (void)beginSheetModalForWindow:(NSWindow *)inWindow completionHandler:(void (^)(NSModalResponse response))handler
{
    [NSApp beginSheet:self
       modalForWindow:inWindow
        modalDelegate:self
       didEndSelector:@selector(_sheetDidEndSelector:returnCode:contextInfo:)
          contextInfo:(__bridge_retained void*)[handler copy]];
}

- (NSModalResponse)runModal
{
    NSModalResponse tModalResponse=[NSApp runModalForWindow:self];
    
    retainedWindowController=nil;
    
    [self orderOut:self];
    
    return tModalResponse;
}

@end

