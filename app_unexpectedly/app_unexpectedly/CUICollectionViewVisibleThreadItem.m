/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICollectionViewVisibleThreadItem.h"

#import "CUILightTableVisibleThreadView.h"

#import "CUIThread.h"

#import "CUIStackFrame+UI.h"

#import "CUICallsSelection.h"

@interface CUICollectionViewVisibleThreadItem () <NSTableViewDataSource,NSTableViewDelegate>
{
    IBOutlet NSTextField * _threadNumberLabel;
    IBOutlet NSTextField * _threadNumberBigLabel;
    IBOutlet NSTextField * _threadNameLabel;
    
    IBOutlet NSTableView * _backtraceTableView;
}

- (IBAction)minimizeThreadView:(id)sender;

@end

@implementation CUICollectionViewVisibleThreadItem

#pragma mark -

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.imageView.cell.backgroundStyle=NSBackgroundStyleEmphasized;
    
    _threadNumberBigLabel.cell.backgroundStyle=NSBackgroundStyleEmphasized;
    
    _threadNumberLabel.cell.backgroundStyle=NSBackgroundStyleEmphasized;
    _threadNameLabel.cell.backgroundStyle=NSBackgroundStyleEmphasized;
    
    NSScrollView * tScrollView=_backtraceTableView.enclosingScrollView;
    
    tScrollView.wantsLayer=YES;
    tScrollView.layer.cornerRadius=8.0;
    //tScrollView.layer.maskedCorners=kCALayerMinXMinYCorner|kCALayerMaxXMinYCorner;
    
    tScrollView.contentView.wantsLayer=YES;
    tScrollView.contentView.layer.cornerRadius=8.0;
    //tScrollView.contentView.layer.maskedCorners=kCALayerMinXMinYCorner|kCALayerMaxXMinYCorner;
}

#pragma mark -

- (void)setRepresentedObject:(id)inRepresentedObject
{
    [super setRepresentedObject:inRepresentedObject];
    
    CUIThread * tThread=(CUIThread *)inRepresentedObject;
    
    CUILightTableVisibleThreadView * tView=(CUILightTableVisibleThreadView *)self.view;
    
    tView.crashed=tThread.isCrashed;
    
    tView.applicationSpecificBacktrace=tThread.isApplicationSpecificBacktrace;
    
    self.imageView.image=(tThread.isCrashed==YES) ? [NSImage imageNamed:@"crashedThread_Template"] : [NSImage imageNamed:@"thread_Template"];
    
    
    if (tThread.isApplicationSpecificBacktrace==YES)
    {
        _threadNumberBigLabel.stringValue=tThread.name;
        
        _threadNumberLabel.stringValue=@"";
        _threadNameLabel.stringValue=@"";
    }
    else
    {
        if (tThread.name==nil)
        {
            _threadNumberBigLabel.stringValue=[NSString stringWithFormat:NSLocalizedString(@"Thread %ld",@""),tThread.number];
            
            _threadNumberLabel.stringValue=@"";
            _threadNameLabel.stringValue=@"";
        }
        else
        {
            _threadNumberBigLabel.stringValue=@"";
            
            _threadNumberLabel.stringValue=[NSString stringWithFormat:NSLocalizedString(@"Thread %ld",@""),tThread.number];
            _threadNameLabel.stringValue=tThread.name;
        }
    }
    
    [_backtraceTableView reloadData];
}

- (void)setHighlightState:(NSCollectionViewItemHighlightState)newHighlightState
{
    [super setHighlightState:newHighlightState];
    
    //((MyView *)self.view).highlightState=newHighlightState;
}

- (void)setSelected:(BOOL)inSelected
{
    [super setSelected:inSelected];
    
    
    
    //((MyView *)self.view).selected=inSelected;
}

- (void)setShowsOffset:(BOOL)aBool
{
    super.showsOffset=aBool;
    
    [_backtraceTableView reloadData];
}

#pragma mark -

- (NSArray *)draggingImageComponents
{
    NSView *itemRootView = self.view;
    NSRect itemBounds = itemRootView.bounds;
    NSBitmapImageRep *bitmap = [itemRootView bitmapImageRepForCachingDisplayInRect:itemBounds];
    unsigned char *bitmapData = bitmap.bitmapData;
    if (bitmapData) {
        bzero(bitmapData, bitmap.bytesPerRow * bitmap.pixelsHigh);
    }
    
    [itemRootView cacheDisplayInRect:itemBounds toBitmapImageRep:bitmap];
    NSImage *image = [[NSImage alloc] initWithSize:[bitmap size]];
    [image addRepresentation:bitmap];
    
    NSDraggingImageComponent *component = [[NSDraggingImageComponent alloc] initWithKey:NSDraggingImageComponentIconKey];
    component.frame = itemBounds;
    component.contents = image;
    
    return [NSArray arrayWithObject:component];
}

#pragma mark -

- (IBAction)minimizeThreadView:(id)sender
{
    id tDataSource=self.collectionView.dataSource;
    
    if ([tDataSource respondsToSelector:@selector(minimizeThread:)]==YES)
        [tDataSource performSelector:@selector(minimizeThread:) withObject:self.representedObject];
    
    // A COMPLETER
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)inTableView
{
    CUIThread * tThread=(CUIThread *)self.representedObject;
    
    if (tThread==nil)
        return 0;
    
    return tThread.callStackBacktrace.stackFrames.count;
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)inTableView viewForTableColumn:(NSTableColumn *)inTableColumn row:(NSInteger)inRow
{
    if (inTableView!=_backtraceTableView)
        return nil;
    
    CUIThread * tThread=(CUIThread *)self.representedObject;
    
    CUIStackFrame * tCall=(CUIStackFrame *)tThread.callStackBacktrace.stackFrames[inRow];
    
    NSString * tTableColumnIdentifier=inTableColumn.identifier;
    NSTableCellView * tTableCellView=[inTableView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
    
    if ([tTableColumnIdentifier isEqualToString:@"symbol"]==YES)
    {
        NSMutableString * tCallLine=[NSMutableString stringWithFormat:@"%lu ",tCall.index];
        
        [tCallLine appendString:tCall.symbol];
        
        if (self.showsOffset==YES)
        {
            [tCallLine appendFormat:@" + %lu",tCall.byteOffset];
        }
        
        tTableCellView.textField.stringValue=tCallLine;
        
        NSString * tBinaryImageIdentifier=tCall.binaryImageIdentifier;
        
        BOOL tIsUserCode=NO;
        
        CUICrashLogBinaryImages * tBinaryImages=self.crashLog.binaryImages;
        
        CUIBinaryImage * tBinaryImage=[tBinaryImages binaryImageWithIdentifierOrName:tBinaryImageIdentifier identifier:&tBinaryImageIdentifier];
        
        if (tBinaryImage!=nil)
        {
            NSString * tPath=tBinaryImage.path;
            
            if ([tPath isEqualToString:self.crashLog.header.executablePath]==YES)
                tIsUserCode=YES;
        }
        
        if (tIsUserCode==NO)
            tIsUserCode=[tBinaryImages isUserCodeAtMemoryAddress:tCall.machineInstructionAddress inBinaryImage:tBinaryImageIdentifier];
        
        if (tIsUserCode==YES)
        {
            tTableCellView.imageView.image=[NSImage imageNamed:@"call-usercode"];
            tTableCellView.textField.textColor=[NSColor labelColor];
        }
        else
        {
            tTableCellView.imageView.image=tCall.binaryImageIcon;
            
            tTableCellView.textField.textColor=[NSColor secondaryLabelColor];
        }
    }
    else if ([tTableColumnIdentifier isEqualToString:@"address"]==YES)
    {
        tTableCellView.textField.stringValue=[NSString stringWithFormat:@"0x%012lx",tCall.machineInstructionAddress];
    }
    else if ([tTableColumnIdentifier isEqualToString:@"binary"]==YES)
    {
        tTableCellView.textField.stringValue=[NSString stringWithFormat:@"%@",tCall.binaryImageIdentifier];
    }
    
    /*if ([tCall.binaryImageIdentifier isEqualToString:self.crashLog.header.bundleIdentifier]==YES)
    {
        tTableCellView.textField.textColor=[NSColor labelColor];
    }
    else
    {
        tTableCellView.textField.textColor=[NSColor secondaryLabelColor];
    }*/
    
    return tTableCellView;
}

- (void)tableViewSelectionDidChange:(NSNotification *)inNotification
{
    NSIndexSet * tIndexSet=[_backtraceTableView selectedRowIndexes];
    
    NSMutableSet * tMutableSet=[NSMutableSet set];
    
    CUIThread * tThread=(CUIThread *)self.representedObject;
    
    [tIndexSet enumerateIndexesUsingBlock:^(NSUInteger bIndex, BOOL * bOutStop) {
        
        CUIStackFrame * tCall=(CUIStackFrame *)tThread.callStackBacktrace.stackFrames[bIndex];
        
        [tMutableSet addObject:tCall];
        
    }];
    
    [CUICallsSelection sharedCallsSelection].calls=tMutableSet;
}

@end
