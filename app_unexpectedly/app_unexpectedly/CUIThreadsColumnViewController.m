/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIThreadsColumnViewController.h"

#import "CUIApplicationSpecificBacktraceRowView.h"
#import "CUICrashedThreadRowView.h"

#import "CUIThreadNamedTableCellView.h"

#import "CUICallTableCellView.h"

#import "CUIThreadImageCell.h"

#import "CUIStackFrame+UI.h"

#import "CUICallsSelection.h"

#import "CUICrashLogBacktraces+Utilities.h"

#import "CUIdSYMBundlesManager.h"

#import "CUISymbolicationManager.h"

#import "CUIApplicationPreferences.h"

#import "CUICrashLogBrowsingStateRegistry.h"

#import "NSTableView+Selection.h"

#import "CUIRawCrashLog+Path.h"

#define CUIBinaryImageIdentifierTextFieldMaxWidth     200.0

@interface CUIThreadsColumnViewController () <NSTableViewDataSource,NSTableViewDelegate>
{
	IBOutlet NSTableView * _threadsTableView;
	
	IBOutlet NSTableView * _backtraceTableView;
    
    NSArray * _filteredThreads;
	
	CUIThread * _selectedThread;
    
    
    CGFloat _optimizedBinaryImageTextFieldWidth;
}

    @property (nonatomic) NSArray * threads;

- (void)delayedReloadSymbols;

@end

@implementation CUIThreadsColumnViewController

- (instancetype)initWithUserInterfaceLayoutDirection:(NSUserInterfaceLayoutDirection)inUserInterfaceLayoutDirection
{
    NSString *nibName=(inUserInterfaceLayoutDirection==NSUserInterfaceLayoutDirectionLeftToRight) ? @"CUIThreadsColumnViewController" : @"CUIThreadsColumnViewController_RTL";
    
    return [super initWithNibName:nibName bundle:nil];
}

#pragma mark -

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // TableView menu
    
    NSMenu * tMenu=[self createFrameContextualMenu];
    
    _backtraceTableView.menu=tMenu;
}

- (void)viewWillDisappear
{
    [super viewWillDisappear];
    
    // Save browsing state
    
    [self saveBrowsingState];
}

#pragma mark -

- (void)saveBrowsingState
{
    CUICrashLogBrowsingStateRegistry * tRegistry=[CUICrashLogBrowsingStateRegistry sharedRegistry];
    
    if (self.crashLog!=nil)
    {
        CUICrashLogBrowsingState * tBrowsingState=[tRegistry browsingStateForCrashLog:self.crashLog windowNumber:self.view.window.windowNumber];
        
        NSInteger tSelectedThread=_threadsTableView.selectedRow;
        
        if (tSelectedThread==-1)
        {
            tBrowsingState.columnSelectedThread=NSNotFound;
            tBrowsingState.columnSelectedStackFrame=NSNotFound;
        }
        else
        {
            tBrowsingState.columnSelectedThread=tSelectedThread;
            
            NSInteger tSelectedStackFrame=_backtraceTableView.selectedRow;
            
            tBrowsingState.columnSelectedStackFrame=(tSelectedStackFrame!=-1) ? tSelectedStackFrame : NSNotFound;
            
            tBrowsingState.columnSelectedStackFrame=(tSelectedStackFrame!=-1) ? tSelectedStackFrame : NSNotFound;
        }
    }
}

- (void)setCrashLog:(CUICrashLog *)inCrashLog
{
	[self saveBrowsingState];
    
    [super setCrashLog:inCrashLog];
	
    _optimizedBinaryImageTextFieldWidth=-1.0;
    
	self.threads=inCrashLog.backtraces.threads;
    
	[_threadsTableView reloadData];
	
    CUICrashLogBrowsingStateRegistry * tRegistry=[CUICrashLogBrowsingStateRegistry sharedRegistry];
    
    CUICrashLogBrowsingState * tBrowsingState=[tRegistry browsingStateForCrashLog:inCrashLog windowNumber:self.view.window.windowNumber];
    
    NSUInteger tSelectedThread=tBrowsingState.columnSelectedThread;
    
    if (tSelectedThread==NSNotFound || self.showOnlyCrashedThread==YES)
    {
        [_filteredThreads enumerateObjectsUsingBlock:^(CUIThread * bThread, NSUInteger bIndex, BOOL * bOutStop) {
		
            if (bThread.isCrashed==YES)
            {
                [self->_threadsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:bIndex] byExtendingSelection:NO];
			
                *bOutStop=YES;
            }
        }];
    }
    else
    {
        if (tSelectedThread<_threadsTableView.numberOfRows)
        {
            [_threadsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:tSelectedThread] byExtendingSelection:NO];
            
            if (tBrowsingState.columnSelectedStackFrame!=NSNotFound)
            {
                [_backtraceTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:tBrowsingState.columnSelectedStackFrame] byExtendingSelection:NO];
            }
        }
    }
}

- (void)setThreads:(NSArray *)inThreads
{
    _threads=inThreads;
    
    if (self.showOnlyCrashedThread==NO)
    {
        _filteredThreads=_threads;
        
        return;
    }
    
    NSUInteger tCrashedThreadIndex=self.crashLog.exceptionInformation.crashedThreadIndex;
    
    _filteredThreads=[_threads WB_filteredArrayUsingBlock:^BOOL(CUIThread * bThread, NSUInteger bIndex) {
       
        if (bThread.isApplicationSpecificBacktrace==YES)
            return YES;
        
        return (bThread.number==tCrashedThreadIndex);
    }];
}

- (void)setShowOnlyCrashedThread:(BOOL)aBool
{
    if (self.showOnlyCrashedThread==aBool)
        return;
    
    [super setShowOnlyCrashedThread:aBool];
    
    [self saveBrowsingState];
    
    if (self.showOnlyCrashedThread==NO)
    {
        _filteredThreads=self.threads;
    }
    else
    {
        NSUInteger tCrashedThreadIndex=self.crashLog.exceptionInformation.crashedThreadIndex;
        
        _filteredThreads=[self.threads WB_filteredArrayUsingBlock:^BOOL(CUIThread * bThread, NSUInteger bIndex) {
            
            if (bThread.isApplicationSpecificBacktrace==YES)
                return YES;
            
            return (bThread.number==tCrashedThreadIndex);
        }];
    }
    
    [_threadsTableView reloadData];
    
    CUICrashLogBrowsingStateRegistry * tRegistry=[CUICrashLogBrowsingStateRegistry sharedRegistry];
    
    CUICrashLogBrowsingState * tBrowsingState=[tRegistry browsingStateForCrashLog:self.crashLog windowNumber:self.view.window.windowNumber];
    
    NSUInteger tSelectedThread=tBrowsingState.columnSelectedThread;
    
    if (tSelectedThread==NSNotFound)
    {
        [_filteredThreads enumerateObjectsUsingBlock:^(CUIThread * bThread, NSUInteger bIndex, BOOL * bOutStop) {
            
            if (bThread.isCrashed==YES)
            {
                [self->_threadsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:bIndex] byExtendingSelection:NO];
                
                *bOutStop=YES;
            }
        }];
    }
    else
    {
        if (tSelectedThread<_threadsTableView.numberOfRows)
        {
            [_threadsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:tSelectedThread] byExtendingSelection:NO];
            
            if (tBrowsingState.columnSelectedStackFrame!=NSNotFound)
            {
                [_backtraceTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:tBrowsingState.columnSelectedStackFrame] byExtendingSelection:NO];
            }
        }
    }
}

- (void)setVisibleStackFrameComponents:(CUIStackFrameComponents)inVisibleStackFrameComponents
{
    [super setVisibleStackFrameComponents:inVisibleStackFrameComponents];
    
    // Save selection
    
    NSInteger tSelectedRow=_backtraceTableView.selectedRow;
    
    [_backtraceTableView reloadData];
    
    // Restore selection
    
    if (tSelectedRow!=-1)
        [_backtraceTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:tSelectedRow] byExtendingSelection:NO];
}

- (NSUInteger)numberOfSelectedStackFrames
{
    return [_backtraceTableView WB_selectedOrClickedRowIndexes].count;
}

- (NSArray<CUIStackFrame *> *)selectedStackFrames
{
    NSIndexSet * tSelectedRows=[_backtraceTableView WB_selectedOrClickedRowIndexes];
    
    if (tSelectedRows.count==0)
        return @[];
    
    return [_selectedThread.callStackBacktrace.stackFrames objectsAtIndexes:tSelectedRows];
}

#pragma mark -

- (IBAction)openSourceFile:(id)sender
{
    NSInteger tRow=[_backtraceTableView rowForView:sender];
    
    if (tRow==-1)
        return;
    
    CUIStackFrame * tCall=(CUIStackFrame *)_selectedThread.callStackBacktrace.stackFrames[tRow];
    
    [[NSWorkspace sharedWorkspace] openURLs:@[[NSURL fileURLWithPath:tCall.symbolicationData.sourceFilePath]]
                       withApplicationAtURL:[CUIApplicationPreferences sharedPreferences].preferedSourceCodeEditorURL
                                    options:NSWorkspaceLaunchDefault
                              configuration:@{}
                                      error:NULL];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)inTableView
{
	if (inTableView==_threadsTableView)
		return _filteredThreads.count;
    
	if (inTableView==_backtraceTableView)
		return _selectedThread.callStackBacktrace.stackFrames.count;
	
	return 0;
}

#pragma mark - NSTableViewDelegate

- (NSTableRowView *)tableView:(NSTableView *)inTableView rowViewForRow:(NSInteger)inRow
{
    if (inTableView==_threadsTableView)
    {
        CUIThread * tThread=(CUIThread *)_filteredThreads[inRow];
        
        if (tThread.isApplicationSpecificBacktrace==YES)
        {
            CUIApplicationSpecificBacktraceRowView * tTableRowView=[inTableView makeViewWithIdentifier:CUIApplicationSpecificBacktraceRowViewIdentifier owner:self];
            
            if (tTableRowView==nil)
            {
                tTableRowView=[[CUIApplicationSpecificBacktraceRowView alloc] initWithFrame:NSZeroRect];
                tTableRowView.identifier=CUIApplicationSpecificBacktraceRowViewIdentifier;
            }
            
            return tTableRowView;
        }
        
        if (tThread.isCrashed==YES)
        {
            CUICrashedThreadRowView * tTableRowView=[inTableView makeViewWithIdentifier:CUICrashedThreadRowViewIdentifier owner:self];
            
            if (tTableRowView==nil)
            {
                tTableRowView=[[CUICrashedThreadRowView alloc] initWithFrame:NSZeroRect];
                tTableRowView.identifier=CUICrashedThreadRowViewIdentifier;
            }
            
            return tTableRowView;
        }
    }
    
    return nil;
}

- (NSView *)tableView:(NSTableView *)inTableView viewForTableColumn:(NSTableColumn *)inTableColumn row:(NSInteger)inRow
{
    if (inTableView==_threadsTableView)
	{
        CUIThread * tThread=(CUIThread *)_filteredThreads[inRow];
		
		NSTableCellView * tTableCellView=nil;
		
		if (tThread.name.length==0 || tThread.isApplicationSpecificBacktrace==YES)
		{
			tTableCellView=[inTableView makeViewWithIdentifier:@"thread cell" owner:self];
		}
		else
		{
			CUIThreadNamedTableCellView * tNamedCell=[inTableView makeViewWithIdentifier:@"thread named cell" owner:self];
			
			tNamedCell.dispatchQueueNameLabel.stringValue=tThread.name;
			
			tTableCellView=tNamedCell;
		}
		
        ((CUIThreadImageCell *)tTableCellView.imageView.cell).crashed=tThread.crashed;
		
        if (tThread.isApplicationSpecificBacktrace==YES)
            tTableCellView.textField.stringValue=tThread.name;
        else
            tTableCellView.textField.stringValue=[NSString stringWithFormat:@"Thread %lu",tThread.number];
		
		return tTableCellView;
	}
	
	if (inTableView==_backtraceTableView)
	{
        CUIStackFrame * tCall=(CUIStackFrame *)_selectedThread.callStackBacktrace.stackFrames[inRow];
        
        NSString * tTableColumnIdentifier=inTableColumn.identifier;
        
        if ([tTableColumnIdentifier isEqualToString:@"source"]==YES)
        {
            CUISourceFileTableCellView * tTableCellView=(CUISourceFileTableCellView *)[inTableView makeViewWithIdentifier:@"source" owner:self];
            
            BOOL tSymbolicateAutomatically=[CUIApplicationPreferences sharedPreferences].symbolicateAutomatically;
            
            CUISymbolicationData * tSymbolicationData=nil;
            
            if (tSymbolicateAutomatically==YES)
                tSymbolicationData=tCall.symbolicationData;
            
            if (tSymbolicationData!=nil)
            {
                [self setUpSourceFileCellView:tTableCellView withSymbolicationData:tSymbolicationData];
            }
            else
            {
                // Default values
                
                if (tCall.sourceFile==nil)
                    tTableCellView.textField.stringValue=@"-";
                else
                    tTableCellView.textField.stringValue=[NSString stringWithFormat:@"%@ - line %lu",tCall.sourceFile,tCall.lineNumber];
                
                NSRect tFrame=tTableCellView.textField.frame;
                
                tFrame.size.width=NSMaxX(tTableCellView.frame)-NSMinX(tFrame)-4;
                    
                tTableCellView.textField.frame=tFrame;
                
                tTableCellView.openButton.hidden=YES;
                
                
                NSString * tBinaryImageIdentifier=tCall.binaryImageIdentifier;
                
                CUIBinaryImage * tBinaryImage=[self.crashLog.binaryImages binaryImageWithIdentifier:tBinaryImageIdentifier];
                
                if (tBinaryImage==nil)
                {
                    NSString * tAlternateIdentifier=[self.crashLog.binaryImages binaryImageIdentifierForName:tBinaryImageIdentifier];
                    
                    if (tAlternateIdentifier!=nil)
                        tBinaryImage=[self.crashLog.binaryImages binaryImageWithIdentifier:tAlternateIdentifier];
                }
                
                if (tSymbolicateAutomatically==YES)
                {
                    NSUInteger tAddress=tCall.machineInstructionAddress-tBinaryImage.binaryImageOffset;
                    
                    [[CUISymbolicationManager sharedSymbolicationManager] lookUpSymbolicationDataForMachineInstructionAddress:tAddress
                                                                                                                   binaryUUID:tBinaryImage.UUID
                                                                                                            completionHandler:^(CUISymbolicationDataLookUpResult bLookUpResult, CUISymbolicationData *bSymbolicationData) {
                                                                                                                
                                                                                                                switch(bLookUpResult)
                                                                                                                {
                                                                                                                    case CUISymbolicationDataLookUpResultError:
                                                                                                                    case CUISymbolicationDataLookUpResultNotFound:
                                                                                                                        
                                                                                                                        break;
                                                                                                                        
                                                                                                                    case CUISymbolicationDataLookUpResultFound:
                                                                                                                    {
                                                                                                                        tCall.symbolicationData=bSymbolicationData;
                                                                                                                        
                                                                                                                        [NSNotificationCenter.defaultCenter postNotificationName:CUIStackFrameSymbolicationDidSucceedNotification
                                                                                                                                                                          object:self.crashLog];
                                                                                                                        
                                                                                                                        break;
                                                                                                                    }
                                                                                                                        
                                                                                                                    case CUISymbolicationDataLookUpResultFoundInCache:
                                                                                                                    {
                                                                                                                        tCall.symbolicationData=bSymbolicationData;
                                                                                                                        
                                                                                                                        [self setUpSourceFileCellView:tTableCellView withSymbolicationData:bSymbolicationData];
                                                                                                                        
                                                                                                                        break;
                                                                                                                    }
                                                                                                                        
                                                                                                                }
                                                                                                                
                                                                                                                
                                                                                                            }];
                }
            }
            
            return tTableCellView;
        }
        
        
		BOOL isRightToLeft=(inTableView.userInterfaceLayoutDirection==NSUserInterfaceLayoutDirectionRightToLeft);
        NSString * tBinaryImageIdentifier=tCall.binaryImageIdentifier;
        
        BOOL tIsUserCode=NO;
        
        CUICrashLogBinaryImages * tBinaryImages=self.crashLog.binaryImages;
        
        CUIBinaryImage * tBinaryImage=[tBinaryImages binaryImageWithIdentifierOrName:tBinaryImageIdentifier identifier:&tBinaryImageIdentifier];
        
        if (tBinaryImage!=nil)
        {
            tIsUserCode = tBinaryImage.isUserCode;
            
            if (tIsUserCode==NO && [tBinaryImage.path isEqualToString:self.crashLog.header.executablePath]==YES)
                tIsUserCode=YES;
        }
        
        if (tIsUserCode==NO)
            tIsUserCode=[tBinaryImages isUserCodeAtMemoryAddress:tCall.machineInstructionAddress inBinaryImage:tBinaryImageIdentifier];

        
        CUICallTableCellView * tCallTableCellView=[inTableView makeViewWithIdentifier:@"call cell" owner:self];
        
        // Call Index
        
        tCallTableCellView.callIndexLabel.stringValue=[NSString stringWithFormat:@"%lu ",tCall.index];
        
        if (tIsUserCode==YES)
        {
            tCallTableCellView.callIndexLabel.textColor=[NSColor labelColor];
        }
        else
        {
            tCallTableCellView.callIndexLabel.textColor=[NSColor secondaryLabelColor];
        }
        
        NSRect tLeftFrame=tCallTableCellView.callIndexLabel.frame;
        
        // Binary Image
        
        if (((self.visibleStackFrameComponents & CUIStackFrameBinaryNameComponent)==0))
        {
            tCallTableCellView.binaryImageLabel.hidden=YES;
        }
        else
        {
            
            
            if (_optimizedBinaryImageTextFieldWidth<0)
            {
                NSArray * tBinaryImageIdentifiers=[self.crashLog.backtraces allBinaryImagesIdentifiers];
                __block CGFloat tMaxWidth=0.0;
                NSFont * tFont=tCallTableCellView.binaryImageLabel.font;
                
                [tBinaryImageIdentifiers enumerateObjectsUsingBlock:^(NSString * bString, NSUInteger bIndex, BOOL * bOutStop) {
                    
                    CGFloat tWidth=[bString sizeWithAttributes:@{NSFontAttributeName:tFont}].width;
                    
                    if (tWidth>tMaxWidth)
                        tMaxWidth=tWidth;
                    
                }];
                
                _optimizedBinaryImageTextFieldWidth=tMaxWidth+10.0;
                
                if (_optimizedBinaryImageTextFieldWidth>CUIBinaryImageIdentifierTextFieldMaxWidth)
                    _optimizedBinaryImageTextFieldWidth=CUIBinaryImageIdentifierTextFieldMaxWidth;
                
            }
            
            tCallTableCellView.binaryImageLabel.hidden=NO;
            
            NSRect tFrame=tCallTableCellView.binaryImageLabel.frame;
            
            tFrame.size.width=_optimizedBinaryImageTextFieldWidth;
            
            if (isRightToLeft==NO)
            {
                tFrame.origin.x=NSMaxX(tLeftFrame)+8;
            }
            else
            {
                tFrame.origin.x=NSMinX(tLeftFrame)-8-NSWidth(tFrame);
            }
            
            tCallTableCellView.binaryImageLabel.frame=tFrame;
            
            tLeftFrame=tFrame;
            
            tCallTableCellView.binaryImageLabel.stringValue=[NSString stringWithFormat:@"%@",tCall.binaryImageIdentifier];
            
            if (tIsUserCode==YES)
            {
                tCallTableCellView.binaryImageLabel.textColor=[NSColor labelColor];
            }
            else
            {
                tCallTableCellView.binaryImageLabel.textColor=[NSColor secondaryLabelColor];
            }
        }
        
        // Address
        
        if ((self.visibleStackFrameComponents & CUIStackFrameMachineInstructionAddressComponent)==0)
        {
            tCallTableCellView.addressLabel.hidden=YES;
        }
        else
        {
            tCallTableCellView.addressLabel.hidden=NO;
            
            NSRect tFrame=tCallTableCellView.addressLabel.frame;
            
            if (isRightToLeft==NO)
            {
                tFrame.origin.x=NSMaxX(tLeftFrame)+8;
            }
            else
            {
                tFrame.origin.x=NSMinX(tLeftFrame)-8-NSWidth(tFrame);
            }
            
            tCallTableCellView.addressLabel.frame=tFrame;
            
            tLeftFrame=tFrame;
            
            
            
            tCallTableCellView.addressLabel.stringValue=[NSString stringWithFormat:@"0x%012lx",(tCall.machineInstructionAddress)];
            
            if (tIsUserCode==YES)
            {
                tCallTableCellView.addressLabel.textColor=[NSColor labelColor];
            }
            else
            {
                tCallTableCellView.addressLabel.textColor=[NSColor secondaryLabelColor];
            }
        }
        
        // Symbol
        
        NSRect tFrame=tCallTableCellView.textField.frame;
        
        if (isRightToLeft==NO)
        {
            CGFloat tMaxX=NSMaxX(tFrame);
            
            tFrame.origin.x=NSMaxX(tLeftFrame)+8;
            
            tFrame.size.width=tMaxX-tFrame.origin.x;
        }
        else
        {
            CGFloat tMinX=NSMinX(tFrame);
            
            tFrame.origin.x=tMinX;
            
            tFrame.size.width=(NSMinX(tLeftFrame)-8-tMinX);
        }
        
        tCallTableCellView.textField.frame=tFrame;
        
        BOOL tSymbolicateAutomatically=[CUIApplicationPreferences sharedPreferences].symbolicateAutomatically;
        
        CUISymbolicationData * tData=nil;
        
        if (tSymbolicateAutomatically==YES)
            tData=tCall.symbolicationData;
        
        if (tData!=nil)
        {
            NSMutableString * tCallLine=[tData.stackFrameSymbol mutableCopy];
            
            if ((self.visibleStackFrameComponents & CUIStackFrameByteOffsetComponent)!=0)
            {
                [tCallLine appendFormat:@" + %lu",tData.byteOffset];
            }
            
            tCallTableCellView.textField.stringValue=tCallLine;
        }
        else
        {
            // Default values
            
            NSMutableString * tCallLine=[tCall.symbol mutableCopy];
            
            if ((self.visibleStackFrameComponents & CUIStackFrameByteOffsetComponent)!=0)
            {
                [tCallLine appendFormat:@" + %lu",tCall.byteOffset];
            }
            
            tCallTableCellView.textField.stringValue=tCallLine;
            
            NSString * tBinaryImageIdentifier=tCall.binaryImageIdentifier;
            
            CUIBinaryImage * tBinaryImage=[self.crashLog.binaryImages binaryImageWithIdentifier:tBinaryImageIdentifier];
            
            if (tBinaryImage==nil)
            {
                NSString * tAlternateIdentifier=[self.crashLog.binaryImages binaryImageIdentifierForName:tBinaryImageIdentifier];
                
                if (tAlternateIdentifier!=nil)
                    tBinaryImage=[self.crashLog.binaryImages binaryImageWithIdentifier:tAlternateIdentifier];
            }
            
            if (tSymbolicateAutomatically==YES)
            {
                NSUInteger tAddress=tCall.machineInstructionAddress-tBinaryImage.binaryImageOffset;
                
                [[CUISymbolicationManager sharedSymbolicationManager] lookUpSymbolicationDataForMachineInstructionAddress:tAddress
                                                                                                               binaryUUID:tBinaryImage.UUID
                                                                                                        completionHandler:^(CUISymbolicationDataLookUpResult bLookUpResult, CUISymbolicationData *bSymbolicationData) {
                                                                                                            
                                                                                                            switch(bLookUpResult)
                                                                                                            {
                                                                                                                case CUISymbolicationDataLookUpResultError:
                                                                                                                case CUISymbolicationDataLookUpResultNotFound:
                                                                                                                    
                                                                                                                    break;
                                                                                                                    
                                                                                                                case CUISymbolicationDataLookUpResultFound:
                                                                                                                {
                                                                                                                    tCall.symbolicationData=bSymbolicationData;
                                                                                                                    
                                                                                                                    [NSNotificationCenter.defaultCenter postNotificationName:CUIStackFrameSymbolicationDidSucceedNotification
                                                                                                                                                                      object:self.crashLog];
                                                                                                                    
                                                                                                                    break;
                                                                                                                }
                                                                                                                    
                                                                                                                case CUISymbolicationDataLookUpResultFoundInCache:
                                                                                                                {
                                                                                                                    tCall.symbolicationData=bSymbolicationData;
                                                                                                                    
                                                                                                                    NSMutableString * tCallLine=[bSymbolicationData.stackFrameSymbol mutableCopy];
                                                                                                                    
                                                                                                                    if ((self.visibleStackFrameComponents & CUIStackFrameByteOffsetComponent)!=0)
                                                                                                                    {
                                                                                                                        [tCallLine appendFormat:@" + %lu",bSymbolicationData.byteOffset];
                                                                                                                    }
                                                                                                                    
                                                                                                                    tCallTableCellView.textField.stringValue=tCallLine;
                                                                                                                    
                                                                                                                    break;
                                                                                                                }
                                                                                                                    
                                                                                                            }
                                                                                                            
                                                                                                            
                                                                                                        }];
            }
        }
        
        if (tIsUserCode==YES)
        {
            tCallTableCellView.imageView.image=[NSImage imageNamed:@"call-usercode"];
            tCallTableCellView.textField.textColor=[NSColor labelColor];
        }
        else
        {
            tCallTableCellView.imageView.image=tCall.binaryImageIcon;
            
            tCallTableCellView.textField.textColor=[NSColor secondaryLabelColor];
        }
        
        return tCallTableCellView;
	}
	
	return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)inNotification
{
	if (inNotification.object==_threadsTableView)
	{
		NSInteger tSelectedRow=_threadsTableView.selectedRow;
		
		[_backtraceTableView deselectAll:self];
		
		if (tSelectedRow==-1)
		{
			_selectedThread=nil;
			
			[_backtraceTableView reloadData];
		}
		else
		{
			_selectedThread=_filteredThreads[tSelectedRow];
			
			[_backtraceTableView reloadData];
		}
	}
	else if (inNotification.object==_backtraceTableView)
	{
        NSIndexSet * tIndexSet=_backtraceTableView.selectedRowIndexes;
        
        NSMutableSet * tMutableSet=[NSMutableSet set];
        
        [tIndexSet enumerateIndexesUsingBlock:^(NSUInteger bIndex, BOOL * bOutStop) {
            
            CUIStackFrame * tCall=(CUIStackFrame *)self->_selectedThread.callStackBacktrace.stackFrames[bIndex];
            
            CUIBinaryImage * tBinaryImage=[self.crashLog.binaryImages binaryImageWithIdentifier:tCall.binaryImageIdentifier];
            
            if (tBinaryImage==nil)
            {
                NSString * tIdentifier=[self.crashLog.binaryImages binaryImageIdentifierForName:tCall.binaryImageIdentifier];
                
                if (tIdentifier!=nil)
                {
                    tBinaryImage=[self.crashLog.binaryImages binaryImageWithIdentifier:tIdentifier];
                    
                    if (tBinaryImage!=nil)
                        tCall=[tCall stackFrameCloneWithBinaryImageIdentifier:tIdentifier];
                }
            }
                
            [tMutableSet addObject:tCall];
        }];
        
        [CUICallsSelection sharedCallsSelection].calls=tMutableSet;
	}
}

#pragma mark -

- (void)delayedReloadSymbols
{
    [_backtraceTableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _backtraceTableView.numberOfRows)] columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 4)]];
}

#pragma mark -

- (void)dSYMBundlesManagerDidAddBundles:(NSNotification *)inNotification
{
    // Ideally we should just request to symbolicate the machineInstructionAddresses which can be
    
    //NSArray * tBinaryUUIDs=inNotification.object;
    
    // A COMPLETER
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedReloadSymbols) object:nil];
    
    [self performSelector:@selector(delayedReloadSymbols) withObject:nil afterDelay:0.1];
}

- (void)stackFrameSymbolicationDidSucceed:(NSNotification *)inNotification
{
    if (inNotification.object!=self.crashLog)
        return;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedReloadSymbols) object:nil];
    
    [self performSelector:@selector(delayedReloadSymbols) withObject:nil afterDelay:0.1];
}

- (void)symbolicateAutomaticallyDidChange:(NSNotification *)inNotification
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedReloadSymbols) object:nil];
    
    [self performSelector:@selector(delayedReloadSymbols) withObject:nil afterDelay:0.1];
}

@end
