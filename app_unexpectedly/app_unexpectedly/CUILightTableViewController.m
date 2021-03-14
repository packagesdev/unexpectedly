/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUILightTableViewController.h"

#import "CUICollectionViewVisibleThreadsLayout.h"
#import "CUICollectionViewDockedThreadsLayout.h"

#import "CUICollectionViewVisibleThreadItem.h"
#import "CUICollectionViewDockedThreadItem.h"

#import "CUILightTableVisibleThreadView.h"

#import "CUILightTableVisibleInterGapView.h"





@interface CUILightTableViewController () <NSCollectionViewDataSource,NSCollectionViewDelegate>
{
    IBOutlet NSCollectionView * _visiblethreadsCollectionView;
    
    IBOutlet NSCollectionView * _dockedThreadsCollectionView;
    
    NSMutableArray<CUIThread *> * _visibleThreads;
    
    NSMutableArray<CUIThread *> * _dockedThreads;
    
    NSSet * _indexPathOfVisibleThreadsBeingDragged;
}

- (void)minimizeThread:(CUIThread *)inThread;

@end

@implementation CUILightTableViewController

- (NSString *)nibName
{
    return @"CUILightTableViewController";
}

- (void)awakeFromNib
{
    // Table Collection View
    
    _visiblethreadsCollectionView.collectionViewLayout=[CUICollectionViewVisibleThreadsLayout new];
    _visiblethreadsCollectionView.dataSource=self;
    _visiblethreadsCollectionView.delegate=self;
    
    NSNib * tNib=[[NSNib alloc] initWithNibNamed:@"CUICollectionViewVisibleThreadItem" bundle:[NSBundle mainBundle]];
    
    [_visiblethreadsCollectionView registerNib:tNib forItemWithIdentifier:@"visibleThread"];
    
    [_visiblethreadsCollectionView registerForDraggedTypes:@[NSPasteboardTypeString]];
    
    [_visiblethreadsCollectionView setDraggingSourceOperationMask:NSDragOperationMove forLocal:YES];
    
    
    // Dock Collection View
    
    _dockedThreadsCollectionView.collectionViewLayout=[CUICollectionViewDockedThreadsLayout new];
    _dockedThreadsCollectionView.dataSource=self;
    _dockedThreadsCollectionView.delegate=self;
    
    tNib=[[NSNib alloc] initWithNibNamed:@"CUICollectionViewDockedThreadItem" bundle:[NSBundle mainBundle]];
    
    [_dockedThreadsCollectionView registerNib:tNib forItemWithIdentifier:@"dockedThread"];
    
    [_dockedThreadsCollectionView registerForDraggedTypes:@[NSPasteboardTypeString]];
    
    [_dockedThreadsCollectionView setDraggingSourceOperationMask:NSDragOperationMove forLocal:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
}

#pragma mark -

- (void)setCrashLog:(CUICrashLog *)inCrashLog
{
    [super setCrashLog:inCrashLog];
    
    _visibleThreads=[inCrashLog.backtraces.threads mutableCopy];
    
    _dockedThreads=[NSMutableArray array];
    
    [_visiblethreadsCollectionView reloadData];
    
    [_dockedThreadsCollectionView reloadData];
}

- (void)setVisibleStackFrameComponents:(CUIStackFrameComponents)inVisibleStackFrameComponents
{
    [super setVisibleStackFrameComponents:inVisibleStackFrameComponents];
    
    [_visiblethreadsCollectionView reloadData];
}

#pragma mark -

- (void)minimizeThread:(CUIThread *)inThread
{
    NSUInteger tIndex=[_visibleThreads indexOfObject:inThread];
    
    if (tIndex==NSNotFound)
        return;
    
    [_visibleThreads removeObjectAtIndex:tIndex];
    
    __block NSUInteger tInsertionIndex=0;
    NSUInteger tThreadNumber=inThread.number;
    
    
    [_dockedThreads enumerateObjectsUsingBlock:^(CUIThread * bThread, NSUInteger bIndex, BOOL * bOutStop) {
        
        if (tThreadNumber<bThread.number)
        {
            *bOutStop=YES;
            return;
        }
        
        tInsertionIndex++;
    }];
    
    
    [_dockedThreads insertObject:inThread atIndex:tInsertionIndex];
    
    [_visiblethreadsCollectionView.animator deleteItemsAtIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:tIndex inSection:0]]];
    
    [_dockedThreadsCollectionView.animator insertItemsAtIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:tInsertionIndex inSection:0]]];
}

- (void)openThread:(CUIThread *)inThread
{
    CUIThread * tThread=inThread;
    
    NSUInteger tIndex=[_dockedThreads indexOfObject:tThread];
    
    if (tIndex==NSNotFound)
        return;
    
    [_dockedThreads removeObjectAtIndex:tIndex];
    
    __block NSUInteger tInsertionIndex=0;
    NSUInteger tThreadNumber=inThread.number;
    
    
    [_visibleThreads enumerateObjectsUsingBlock:^(CUIThread * bThread, NSUInteger bIndex, BOOL * bOutStop) {
        
        if (tThreadNumber<bThread.number)
        {
            *bOutStop=YES;
            return;
        }
        
        tInsertionIndex++;
    }];
    
    
    [_visibleThreads insertObject:inThread atIndex:tInsertionIndex];
    
    [_dockedThreadsCollectionView.animator deleteItemsAtIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:tIndex inSection:0]]];
    
    //NSShowAnimationEffect(NSAnimationEffectDisappearingItemDefault, NSMakePoint(300,300), NSZeroSize,nil,nil,NULL);
    
    [_visiblethreadsCollectionView.animator insertItemsAtIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:tInsertionIndex inSection:0]]];
}

#pragma mark - NSCollectionViewDataSource

- (NSInteger)collectionView:(NSCollectionView *)inCollectionView numberOfItemsInSection:(NSInteger)inSection
{
    if (inCollectionView==_visiblethreadsCollectionView)
        return _visibleThreads.count;
    
    if (inCollectionView==_dockedThreadsCollectionView)
        return _dockedThreads.count;
    
    return 0;
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)inCollectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)inIndexPath
{
    if (inCollectionView==_visiblethreadsCollectionView)
    {
        CUICollectionViewVisibleThreadItem * tCollectionViewItem=(CUICollectionViewVisibleThreadItem *)[inCollectionView makeItemWithIdentifier:@"visibleThread" forIndexPath:inIndexPath];
        
        tCollectionViewItem.representedObject=_visibleThreads[inIndexPath.item];
        
        tCollectionViewItem.showsOffset=((self.visibleStackFrameComponents & CUIStackFrameByteOffsetComponent)!=0);
        tCollectionViewItem.showsMemoryAddress=((self.visibleStackFrameComponents & CUIStackFrameMachineInstructionAddressComponent)!=0);
        tCollectionViewItem.showsBinaryImageIdentifier=((self.visibleStackFrameComponents & CUIStackFrameBinaryNameComponent)!=0);
        
        tCollectionViewItem.crashLog=self.crashLog;
        
        return tCollectionViewItem;
    }
    
    if (inCollectionView==_dockedThreadsCollectionView)
    {
        CUICollectionViewDockedThreadItem * tCollectionViewItem=(CUICollectionViewDockedThreadItem *)[inCollectionView makeItemWithIdentifier:@"dockedThread" forIndexPath:inIndexPath];
        
        tCollectionViewItem.representedObject=_dockedThreads[inIndexPath.item];
        
        return tCollectionViewItem;
    }
    
    return nil;
}

- (NSView *)collectionView:(NSCollectionView *)inCollectionView viewForSupplementaryElementOfKind:(NSCollectionViewSupplementaryElementKind)kind atIndexPath:(NSIndexPath *)indexPath
{
    return [[CUILightTableVisibleInterGapView alloc] initWithFrame:NSZeroRect];
}

#pragma  mark - NSCollectionViewDelegate

- (void)collectionView:(NSCollectionView *)inCollectionView didSelectItemsAtIndexPaths:(nonnull NSSet<NSIndexPath *> *)inIndexPaths
{
    // A COMPLETER
}

#pragma  mark - NSCollectionViewDelegate - Drag and Drop

- (BOOL)collectionView:(NSCollectionView *)inCollectionView canDragItemsAtIndexPaths:(NSSet<NSIndexPath *> *)inIndexPaths withEvent:(NSEvent *)inEvent
{
    return YES;
}

- (nullable id <NSPasteboardWriting>)collectionView:(NSCollectionView *)inCollectionView pasteboardWriterForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSPasteboardItem * tPasteboardItem=[NSPasteboardItem new];
    
    [tPasteboardItem setString:@"something" forType:NSPasteboardTypeString];
    
    return tPasteboardItem;
}

- (void)collectionView:(NSCollectionView *)inCollectionView draggingSession:(nonnull NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forItemsAtIndexPaths:(nonnull NSSet<NSIndexPath *> *)indexPaths
{
    _indexPathOfVisibleThreadsBeingDragged=indexPaths;
}

- (NSDragOperation)collectionView:(NSCollectionView *)inCollectionView validateDrop:(nonnull id<NSDraggingInfo>)draggingInfo proposedIndexPath:(NSIndexPath *__autoreleasing  _Nonnull * _Nonnull)proposedDropIndexPath dropOperation:(nonnull NSCollectionViewDropOperation *)proposedDropOperation
{
    if (*proposedDropOperation==NSCollectionViewDropOn)
        return NSDragOperationNone;
    
    if (_indexPathOfVisibleThreadsBeingDragged==nil)
        return NSDragOperationCopy;
    
    NSIndexPath * tIndexPathOfFirstItem = [_indexPathOfVisibleThreadsBeingDragged anyObject];
    
    if ((*proposedDropIndexPath).item==tIndexPathOfFirstItem.item || (*proposedDropIndexPath).item==(tIndexPathOfFirstItem.item+1))
        return NO;
    
    return NSDragOperationMove;
}

- (BOOL)collectionView:(NSCollectionView *)inCollectionView acceptDrop:(nonnull id<NSDraggingInfo>)draggingInfo indexPath:(nonnull NSIndexPath *)indexPath dropOperation:(NSCollectionViewDropOperation)dropOperation
{
    if (_indexPathOfVisibleThreadsBeingDragged != nil)
    {
        // 2
        NSIndexPath * tIndexPathOfFirstItem = [_indexPathOfVisibleThreadsBeingDragged anyObject];
        NSIndexPath * toIndexPath;
        
        
        
        
        if ([tIndexPathOfFirstItem compare:indexPath] == NSOrderedAscending)
        {
            toIndexPath = [NSIndexPath indexPathForItem:indexPath.item-1 inSection:indexPath.section];
        }
        else
        {
            toIndexPath = [NSIndexPath indexPathForItem:indexPath.item inSection:indexPath.section];
        }
        // 3
        
        // 4
        
        id tObject=_visibleThreads[tIndexPathOfFirstItem.item];
        
        [_visibleThreads removeObjectAtIndex:tIndexPathOfFirstItem.item];
        
        [_visibleThreads insertObject:tObject atIndex:toIndexPath.item];
        
        [inCollectionView.animator moveItemAtIndexPath:tIndexPathOfFirstItem toIndexPath:toIndexPath];
    }
    
    return YES;
}

- (void)collectionView:(NSCollectionView *)inCollectionView draggingSession:(nonnull NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint dragOperation:(NSDragOperation)operation
{
    _indexPathOfVisibleThreadsBeingDragged=nil;
}

@end
