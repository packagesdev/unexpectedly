/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIThreadsListViewController.h"

#import "CUIThreadNamedTableCellView.h"

#import "CUIApplicationSpecificBacktraceRowView.h"
#import "CUICrashedThreadRowView.h"

#import "CUICrashedThreadCallRowView.h"

#import "CUICallTableCellView.h"

#import "CUIThreadImageCell.h"

#import "CUICrashLog+UI.h"

#import "CUIStackFrame+UI.h"

#import "CUICallsSelection.h"

#import "CUICrashLogBacktraces+Utilities.h"

#import "CUIdSYMBundlesManager.h"

#import "CUISymbolicationManager.h"

#import "CUIApplicationPreferences.h"

#import "CUICrashLogBrowsingStateRegistry.h"

#import "NSTableView+Selection.h"

#define CUIBinaryImageIdentifierTextFieldMaxWidth     200.0

@interface CUIThread (CUIStringHash)

- (NSString *)stringHash;

@end

@implementation CUIThread (CUIStringHash)

- (NSString *)stringHash
{
    char tPrefix='t';
    
    if (self.isApplicationSpecificBacktrace==YES)
        tPrefix='a';
    else if (self.isCrashed==YES)
        tPrefix='c';
    
    return [NSString stringWithFormat:@"%c%lu",tPrefix,self.number];
}

@end


@interface CUIThreadsListViewController () <NSOutlineViewDataSource,NSOutlineViewDelegate>
{
	IBOutlet NSOutlineView * _outlineView;
    
    IBOutlet NSTableRowView * myRowView;
	
	NSArray * _threads;
    
    CGFloat _threadStateRowHeight;
    
    BOOL _showCrashedThreadState;
    
    CGFloat _optimizedBinaryImageTextFieldWidth;
}

- (void)delayedReloadSymbols;

@end

@implementation CUIThreadsListViewController

- (instancetype)initWithUserInterfaceLayoutDirection:(NSUserInterfaceLayoutDirection)inUserInterfaceLayoutDirection
{
    NSString *nibName=(inUserInterfaceLayoutDirection==NSUserInterfaceLayoutDirectionLeftToRight) ? @"CUIThreadsListViewController" : @"CUIThreadsListViewController_RTL";

    return [super initWithNibName:nibName bundle:nil];
}

#pragma mark -

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _threadStateRowHeight=205;
    
    // OutlineView menu
    
    NSMenu * tMenu=[self createFrameContextualMenu];
    
    _outlineView.menu=tMenu;
    
    //[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(viewFrameDidChange:) name:NSViewFrameDidChangeNotification object:_outlineView];
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
        
        tBrowsingState.listSelectedStackFrame=nil;
        
        NSInteger tSelectedRow=_outlineView.selectedRow;
        
        if (tSelectedRow!=-1)
        {
            id tItem=[_outlineView itemAtRow:tSelectedRow];
            
            if (tItem!=nil)
            {
                CUIThread * tThread=[_outlineView parentForItem:tItem];
                
                tBrowsingState.listSelectedStackFrame=[NSString stringWithFormat:@"%@:%lu",[tThread stringHash],[_outlineView childIndexForItem:tItem]];
            }
        }
    }
}

- (void)setCrashLog:(CUICrashLog *)inCrashLog
{
	[self saveBrowsingState];
    
    [super setCrashLog:inCrashLog];
	
    _optimizedBinaryImageTextFieldWidth=-1.0;
    
	_threads=inCrashLog.backtraces.threads;
	
    [_outlineView sizeLastColumnToFit];
    
    [_outlineView reloadData];
	
    
    CUICrashLogBrowsingStateRegistry * tRegistry=[CUICrashLogBrowsingStateRegistry sharedRegistry];
    
    CUICrashLogBrowsingState * tBrowsingState=[tRegistry browsingStateForCrashLog:inCrashLog windowNumber:self.view.window.windowNumber];
    
    NSDictionary * tListDiclosedThreads=tBrowsingState.listDisclosedThreads;
    
    if (tListDiclosedThreads==nil)
    {
        // Disclose the crashed thread
	
        for(CUIThread * tThread in _threads)
        {
            if (tThread.isCrashed==YES)
            {
                [_outlineView expandItem:tThread];
                
                break;
            }
        }
        
        [self outlineViewSelectionDidChange:[NSNotification notificationWithName:NSTableViewSelectionDidChangeNotification object:_outlineView]];
        
        return;
    }
    
    for(CUIThread * tThread in _threads)
    {
        if (tListDiclosedThreads[[tThread stringHash]]!=nil)
            [_outlineView expandItem:tThread];
    }
    
    NSString * tString=tBrowsingState.listSelectedStackFrame;
    
    if (tString!=nil)
    {
        NSArray * tComponents=[tString componentsSeparatedByString:@":"];
        
        if (tComponents.count!=2)
            return;
        
        NSString * tStringHash=tComponents[0];
        
        for(CUIThread * tThread in _threads)
        {
            if ([[tThread stringHash] isEqualToString:tStringHash]==YES)
            {
                if ([_outlineView isItemExpanded:tThread]==YES)
                {
                    NSUInteger tItemRow=[_outlineView rowForItem:tThread]+[tComponents[1] integerValue]+1;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        [self->_outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:tItemRow] byExtendingSelection:NO];
                    });
                    
                    return;
                }
                
                break;
            }
            
        }
    }
    
    [self outlineViewSelectionDidChange:[NSNotification notificationWithName:NSTableViewSelectionDidChangeNotification object:_outlineView]];
}

#pragma mark -

- (void)setShowOnlyCrashedThread:(BOOL)aBool
{
    [super setShowOnlyCrashedThread:aBool];
    
    [self saveBrowsingState];
    
    [_outlineView reloadData];
    
    CUICrashLogBrowsingStateRegistry * tRegistry=[CUICrashLogBrowsingStateRegistry sharedRegistry];
    
    CUICrashLogBrowsingState * tBrowsingState=[tRegistry browsingStateForCrashLog:self.crashLog windowNumber:self.view.window.windowNumber];
    
    NSDictionary * tListDiclosedThreads=tBrowsingState.listDisclosedThreads;
    
    if (tListDiclosedThreads==nil)
    {
        // Disclose the crashed thread
        
        for(CUIThread * tThread in _threads)
        {
            if (tThread.isCrashed==YES)
            {
                [_outlineView expandItem:tThread];
                
                NSString * tNodePath=[tThread stringHash];
                
                tBrowsingState.listDisclosedThreads[tNodePath]=@(YES);
                
                break;
            }
        }
        
        return;
    }
    
    for(CUIThread * tThread in _threads)
    {
        if (tListDiclosedThreads[[tThread stringHash]]!=nil)
            [_outlineView expandItem:tThread];
    }
    
    NSString * tString=tBrowsingState.listSelectedStackFrame;
    
    if (tString!=nil)
    {
        NSArray * tComponents=[tString componentsSeparatedByString:@":"];
        
        if (tComponents.count!=2)
            return;
        
        NSString * tStringHash=tComponents[0];
        
        for(CUIThread * tThread in _threads)
        {
            if ([[tThread stringHash] isEqualToString:tStringHash]==YES)
            {
                if ([_outlineView isItemExpanded:tThread]==YES)
                {
                    NSUInteger tItemRow=[_outlineView rowForItem:tThread]+[tComponents[1] integerValue]+1;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        [self->_outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:tItemRow] byExtendingSelection:NO];
                    });
                    
                    return;
                }
                
                break;
            }
            
        }
    }
    
    [self outlineViewSelectionDidChange:[NSNotification notificationWithName:NSTableViewSelectionDidChangeNotification object:_outlineView]];
}

- (void)setVisibleStackFrameComponents:(CUIStackFrameComponents)inVisibleStackFrameComponents
{
    [super setVisibleStackFrameComponents:inVisibleStackFrameComponents];
    
    [_outlineView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,_outlineView.numberOfRows)] columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,_outlineView.numberOfColumns)]];
}

- (NSUInteger)numberOfSelectedStackFrames
{
    NSIndexSet * tSelectedRows=[_outlineView WB_selectedOrClickedRowIndexes];
    
    __block BOOL tContainsThreadRows=NO;
    
    [tSelectedRows enumerateIndexesUsingBlock:^(NSUInteger bIndex, BOOL * bOutStop) {
       
        if ([[self->_outlineView itemAtRow:bIndex] class]==[CUIThread class])
        {
            tContainsThreadRows=YES;
            *bOutStop=YES;
        }
    }];
    
    return (tContainsThreadRows==NO) ? [_outlineView WB_selectedOrClickedRowIndexes].count : 0;
}

- (NSArray<CUIStackFrame *> *)selectedStackFrames
{
    NSIndexSet * tSelectedRows=[_outlineView WB_selectedOrClickedRowIndexes];
    
    if (tSelectedRows.count==0)
        return @[];
    
    NSMutableArray * tMutableArray=[NSMutableArray array];
    
    [tSelectedRows enumerateIndexesUsingBlock:^(NSUInteger bRow, BOOL * bOutStop) {
        
        CUIStackFrame * tStackFrame=[self->_outlineView itemAtRow:bRow];
        
        if ([tStackFrame isKindOfClass:CUIStackFrame.class]==NO)
            return;
        
        [tMutableArray addObject:tStackFrame];
    }];
    
    return [tMutableArray copy];
}

#pragma mark -

- (IBAction)openSourceFile:(id)sender
{
    NSInteger tRow=[_outlineView rowForView:sender];
    
    if (tRow==-1)
        return;
    
    CUIStackFrame * tCall=(CUIStackFrame *)[_outlineView itemAtRow:tRow];
    
#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 101600
	if (@available(*, macOS 11.0))
	{
		[[NSWorkspace sharedWorkspace] openURLs:@[[NSURL fileURLWithPath:tCall.symbolicationData.sourceFilePath]]
						   withApplicationAtURL:[CUIApplicationPreferences sharedPreferences].preferedSourceCodeEditorURL
								  configuration:[NSWorkspaceOpenConfiguration configuration]
							  completionHandler:^(NSRunningApplication * _Nullable app, NSError * _Nullable error) {
			
		}];
	}
	else
#endif
	{
		[[NSWorkspace sharedWorkspace] openURLs:@[[NSURL fileURLWithPath:tCall.symbolicationData.sourceFilePath]]
						   withApplicationAtURL:[CUIApplicationPreferences sharedPreferences].preferedSourceCodeEditorURL
										options:NSWorkspaceLaunchDefault
								  configuration:@{}
										  error:NULL];
	}
}

#pragma mark -

- (void)delayedReloadSymbols
{
    [_outlineView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _outlineView.numberOfRows)] columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)]];
}

#pragma mark - NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)inOutlineView numberOfChildrenOfItem:(id)inItem
{
	if (_threads==nil)
		return 0;
	
	if (inItem==nil)
	{
        if (self.showOnlyCrashedThread==YES)
        {
            if (self.crashLog.backtraces.hasApplicationSpecificBacktrace==YES)
                return 2;
            
			return 1;
        }
		
		return _threads.count;
	}
	
    CUIThread * tThread=(CUIThread *)inItem;
    
    NSInteger tNumber=tThread.callStackBacktrace.stackFrames.count;
    
    if (tThread.isCrashed==YES && _showCrashedThreadState==YES)
        tNumber+=1;
    
	return tNumber;
}

- (id)outlineView:(NSOutlineView *)inOutlineView child:(NSInteger)inIndex ofItem:(id)inItem
{
	if (inItem==nil)
	{
		if (self.showOnlyCrashedThread==YES)
        {
            if (self.crashLog.backtraces.hasApplicationSpecificBacktrace==NO)
            {
                return _threads[self.crashLog.exceptionInformation.crashedThreadIndex];
            }
                
            if (inIndex==0)
                return _threads[0];
            
			return _threads[self.crashLog.exceptionInformation.crashedThreadIndex+1];
        }
        
		return _threads[inIndex];
	}
	
    CUIThread * tThread=(CUIThread *)inItem;
    
    if (tThread.isCrashed==NO || _showCrashedThreadState==NO)
        return tThread.callStackBacktrace.stackFrames[inIndex];
    
    if (inIndex>0)
    {
        return tThread.callStackBacktrace.stackFrames[inIndex-1];
    }
    
	return self.crashLog.threadState;
}

- (BOOL)outlineView:(NSOutlineView *)inOutlineView isItemExpandable:(id)inItem
{
	return [inItem isKindOfClass:[CUIThread class]];
}

#pragma mark - NSOutlineViewDelegate

- (NSTableRowView *)outlineView:(NSOutlineView *)inOutlineView rowViewForItem:(id)inItem
{
    if (inOutlineView!=_outlineView || inItem==nil)
        return nil;
    
    if ([inItem isKindOfClass:[CUIThread class]]==YES)
    {
        CUIThread * tThread=(CUIThread *)inItem;
        
        if (tThread.isApplicationSpecificBacktrace==YES)
        {
            CUIApplicationSpecificBacktraceRowView * tTableRowView=[inOutlineView makeViewWithIdentifier:CUIApplicationSpecificBacktraceRowViewIdentifier owner:self];
            
            if (tTableRowView==nil)
            {
                tTableRowView=[[CUIApplicationSpecificBacktraceRowView alloc] initWithFrame:NSZeroRect];
                tTableRowView.identifier=CUIApplicationSpecificBacktraceRowViewIdentifier;
            }
            
            return tTableRowView;
        }
        
        if (tThread.isCrashed==YES)
        {
            CUICrashedThreadRowView * tTableRowView=[inOutlineView makeViewWithIdentifier:CUICrashedThreadRowViewIdentifier owner:self];
            
            if (tTableRowView==nil)
            {
                tTableRowView=[[CUICrashedThreadRowView alloc] initWithFrame:NSZeroRect];
                tTableRowView.identifier=CUICrashedThreadRowViewIdentifier;
            }
            
            return tTableRowView;
        }
        
        return nil;
    }
        
    if ([inItem isKindOfClass:[CUIStackFrame class]]==YES)
    {
        CUIThread * tThread=(CUIThread *)[inOutlineView parentForItem:inItem];
        
        if (tThread.isCrashed==NO)
            return nil;
        
        CUICrashedThreadCallRowView * tTableRowView=[inOutlineView makeViewWithIdentifier:CUICrashedThreadCallRowViewIdentifier owner:self];
        
        if (tTableRowView==nil)
        {
            tTableRowView=[[CUICrashedThreadCallRowView alloc] initWithFrame:NSZeroRect];
            tTableRowView.identifier=CUICrashedThreadCallRowViewIdentifier;
        }
        
        CUIStackFrame * tCall=(CUIStackFrame *)inItem;
        
        tTableRowView.rootCall=(tCall.index==(tThread.callStackBacktrace.stackFrames.count-1));
        
        return tTableRowView;
    }
    
    return nil;
}

- (NSView *)outlineView:(NSOutlineView *)inOutlineView viewForTableColumn:(NSTableColumn *)inTableColumn item:(id)inItem
{
	if (inOutlineView!=_outlineView || inItem==nil)
		return nil;
	
	NSString * tTableColumnIdentifier=inTableColumn.identifier;
	
    if ([tTableColumnIdentifier isEqualToString:@"source"]==YES)
    {
        if ([inItem isKindOfClass:[CUIStackFrame class]]==YES)
        {
            CUIStackFrame * tCall=(CUIStackFrame *)inItem;
        
            CUISourceFileTableCellView * tTableCellView=(CUISourceFileTableCellView *)[inOutlineView makeViewWithIdentifier:@"source" owner:self];
            
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
                
                NSTextField * tLabel=tTableCellView.textField;
                
                if (tCall.sourceFile==nil)
                    tLabel.stringValue=@"-";
                else
                    tLabel.stringValue=[NSString stringWithFormat:@"%@ - line %lu",tCall.sourceFile,tCall.lineNumber];
                
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
                                                                                                                    {
                                                                                                                        NSRect tFrame=tLabel.frame;
                                                                                                                        
                                                                                                                        tFrame.size.width=NSMaxX(tTableCellView.frame)-NSMinX(tFrame)-4;
                                                                                                                        
                                                                                                                        tLabel.frame=tFrame;
                                                                                                                        
                                                                                                                        break;
                                                                                                                    }
                                                                                                                    case CUISymbolicationDataLookUpResultFound:
                                                                                                                        
                                                                                                                        tCall.symbolicationData=bSymbolicationData;
                                                                                                                        
                                                                                                                        [NSNotificationCenter.defaultCenter postNotificationName:CUIStackFrameSymbolicationDidSucceedNotification
                                                                                                                                                                          object:self.crashLog];
                                                                                                                        
                                                                                                                        break;
                                                                                                                        
                                                                                                                    case CUISymbolicationDataLookUpResultFoundInCache:
                                                                                                                    {
                                                                                                                        tCall.symbolicationData=bSymbolicationData;
                                                                                                                        
                                                                                                                        [self setUpSourceFileCellView:tTableCellView withSymbolicationData:bSymbolicationData];
                                                                                                                        
                                                                                                                        break;
                                                                                                                    }
                                                                                                                }
                    }];
                }
                else
                {
                    NSRect tFrame=tLabel.frame;
                    
                    tFrame.size.width=NSMaxX(tTableCellView.frame)-NSMinX(tFrame)-4;
                        
                    tLabel.frame=tFrame;
                }
            }
            
            return tTableCellView;
        }
        
        return nil;
    }
    
    if ([tTableColumnIdentifier isEqualToString:@"symbol"]==YES)
	{
		if ([inItem isKindOfClass:[CUIThread class]]==YES)
		{
			CUIThread * tThread=(CUIThread *)inItem;
			
			NSTableCellView * tTableCellView=nil;
            
            if (tThread.name.length==0 || tThread.isApplicationSpecificBacktrace==YES)
			{
				tTableCellView=[inOutlineView makeViewWithIdentifier:@"thread cell" owner:self];
			}
			else
			{
				CUIThreadNamedTableCellView * tNamedCell=[inOutlineView makeViewWithIdentifier:@"thread named cell" owner:self];
				
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
        
		if ([inItem isKindOfClass:[CUIStackFrame class]]==YES)
		{
            BOOL isRightToLeft=(inOutlineView.userInterfaceLayoutDirection==NSUserInterfaceLayoutDirectionRightToLeft);
			CUIStackFrame * tCall=(CUIStackFrame *)inItem;
            
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
 
            
            CUICallTableCellView * tCallTableCellView=[inOutlineView makeViewWithIdentifier:@"call cell" owner:self];
			
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

	return nil;
}

- (CGFloat)outlineView:(NSOutlineView *) inOutlineView heightOfRowByItem:(id)inItem
{
	if (inOutlineView!=_outlineView)
		return 17.0;
	
    if ([inItem isKindOfClass:[CUIThread class]]==YES)
        return 32.0;
    
    if ([inItem isKindOfClass:[CUICrashLogThreadState class]]==YES)
    {
        /*if (inOutlineView.frame.size.width>800)
            return 105.0;*/
        
        return _threadStateRowHeight;
    }
	
	return 18.0;
}

- (BOOL)outlineView:(NSOutlineView *)inOutlineView shouldSelectItem:(id)inItem
{
    if (inOutlineView!=_outlineView)
        return YES;
    
    return ([inItem isKindOfClass:[CUIStackFrame class]]==YES);
}

- (void)outlineViewItemDidExpand:(NSNotification *)inNotification
{
    if (inNotification.object!=_outlineView)
        return;
    
    NSDictionary * tUserInfo=inNotification.userInfo;
    if (tUserInfo==nil)
        return;
    
    CUICrashLogBrowsingStateRegistry * tRegistry=[CUICrashLogBrowsingStateRegistry sharedRegistry];
    
    CUICrashLogBrowsingState * tBrowsingState=[tRegistry browsingStateForCrashLog:self.crashLog windowNumber:self.view.window.windowNumber];
    
    CUIThread * tThread=(CUIThread *) tUserInfo[@"NSObject"];
    if (tThread==nil)
        return;
    
    NSString * tNodePath=[tThread stringHash];
    
    if (tBrowsingState.listDisclosedThreads==nil)
        tBrowsingState.listDisclosedThreads=[NSMutableDictionary dictionary];
    
    tBrowsingState.listDisclosedThreads[tNodePath]=@(YES);
}

- (void)outlineViewItemWillCollapse:(NSNotification *)inNotification
{
    if (inNotification.object!=_outlineView)
        return;

    NSDictionary * tUserInfo=inNotification.userInfo;
    if (tUserInfo==nil)
        return;
    
    CUICrashLogBrowsingStateRegistry * tRegistry=[CUICrashLogBrowsingStateRegistry sharedRegistry];
    
    CUICrashLogBrowsingState * tBrowsingState=[tRegistry browsingStateForCrashLog:self.crashLog windowNumber:self.view.window.windowNumber];
    
    if (tBrowsingState.listDisclosedThreads==nil)
        return;
    
    CUIThread * tThread=(CUIThread *) tUserInfo[@"NSObject"];
    if (tThread==nil)
        return;
    
    NSString * tNodePath=[tThread stringHash];
    
    [tBrowsingState.listDisclosedThreads removeObjectForKey:tNodePath];
}

- (void)outlineViewSelectionDidChange:(NSNotification *)inNotification
{
    NSIndexSet * tIndexSet=_outlineView.selectedRowIndexes;
    
    NSMutableSet * tMutableSet=[NSMutableSet set];
    
    [tIndexSet enumerateIndexesUsingBlock:^(NSUInteger bIndex, BOOL * bOutStop) {
        
        CUIStackFrame * tCall=[self->_outlineView itemAtRow:bIndex];
        
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

- (void)idealHeightDidChange:(NSNotification *)inNotification
{
    if (_showCrashedThreadState==YES)
    {
        _threadStateRowHeight=[inNotification.object doubleValue];
    
        [_outlineView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:[_outlineView rowForItem:self.crashLog.threadState]]];
    }
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
