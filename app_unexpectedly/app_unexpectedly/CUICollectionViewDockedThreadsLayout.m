/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICollectionViewDockedThreadsLayout.h"

#define CUIColumnInterGapWidth  16.0

#define CUICardMinimumWidth     150.0
#define CUICardMaximumWidth     300.0

#define CUICardHeight           32.0

#define CUICardVerticalMargin   5.0

@interface CUICollectionViewDockedThreadsLayout ()
{
    NSEdgeInsets _cachedEdgeInsets;
    NSSize _cachedContentSize;
    
    CGFloat _cardWidth;
}

@end

@implementation CUICollectionViewDockedThreadsLayout

- (NSSize)itemSize
{
    NSSize tSize;
    
    tSize.width=_cardWidth;
    tSize.height=CUICardHeight;
    
    return tSize;
}

- (NSCollectionViewScrollDirection)scrollDirection
{
    return NSCollectionViewScrollDirectionHorizontal;
}

- (void) prepareLayout
{
    if (self.collectionView==nil)
        return;
    
    [super prepareLayout];
    
    NSView * tSuperView=self.collectionView.superview;
    
    NSRect tReferenceBounds=NSZeroRect;
    
    if ([tSuperView isKindOfClass:[NSClipView class]]==YES)
    {
        tReferenceBounds=tSuperView.bounds;
    }
    else
    {
        tReferenceBounds=self.collectionView.bounds;
    }
    
    NSInteger tNumberOfItems = [self.collectionView numberOfItemsInSection:0];
    
    CGFloat tVisibleWidth=NSWidth(tReferenceBounds);
    
    _cardWidth=(tVisibleWidth-((tNumberOfItems+1) * CUIColumnInterGapWidth))/tNumberOfItems;
    
    if (_cardWidth<CUICardMinimumWidth)
        _cardWidth=CUICardMinimumWidth;
    else if (_cardWidth>CUICardMaximumWidth)
        _cardWidth=CUICardMaximumWidth;
    
    //NSSize tSize=NSMakeSize((tNumberOfItems * _cardWidth) + ((tNumberOfItems+1) * CUIColumnInterGapWidth), NSHeight(self.collectionView.frame));
    
    //NSRect tBounds=tReferenceBounds;
    
    _cachedEdgeInsets.top=_cachedEdgeInsets.bottom=0.0;
    _cachedEdgeInsets.left=5.0;
    _cachedEdgeInsets.right=5.0;
}

- (NSSize)collectionViewContentSize
{
    NSView * tSuperView=self.collectionView.superview;
    
    NSRect tReferenceBounds=NSZeroRect;
    
    if ([tSuperView isKindOfClass:[NSClipView class]]==YES)
    {
        tReferenceBounds=tSuperView.bounds;
    }
    else
    {
        tReferenceBounds=self.collectionView.bounds;
    }
    
    NSInteger tNumberOfItems = [self.collectionView numberOfItemsInSection:0];
    
    CGFloat tVisibleWidth=NSWidth(tReferenceBounds);
    
    CGFloat tTotalWidth=(tNumberOfItems * _cardWidth) + ((tNumberOfItems+1) * CUIColumnInterGapWidth);
    
    if (tTotalWidth<tVisibleWidth)
        tTotalWidth=tVisibleWidth;
    
    _cachedContentSize=NSMakeSize(tTotalWidth, NSHeight(tReferenceBounds));
    
    
    //NSLog(@"%@ %@ %@",NSStringFromSize(_cachedContentSize), NSStringFromRect(clipBounds),NSStringFromRect(self.collectionView.frame));
    
    return _cachedContentSize;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(NSRect)newBounds
{
    return YES;
}

- (nullable NSCollectionViewLayoutAttributes *)layoutAttributesForDropTargetAtPoint:(NSPoint)inPoint
{
    CGFloat tX=inPoint.x;
    
    NSUInteger tIndex=0;
    
    if (tX>(_cachedEdgeInsets.left+CUIColumnInterGapWidth+_cardWidth*0.5))
        tIndex=(tX-_cachedEdgeInsets.left-CUIColumnInterGapWidth-_cardWidth*0.5)/(CUIColumnInterGapWidth+_cardWidth)+1;
    
    NSCollectionViewLayoutAttributes* tAttributes = [NSCollectionViewLayoutAttributes layoutAttributesForInterItemGapBeforeIndexPath:[NSIndexPath indexPathForItem:tIndex inSection:0]];
    
    NSRect tFrame;
    
    tFrame.origin.x=_cachedEdgeInsets.left+CUIColumnInterGapWidth*0.5+tIndex * CUIColumnInterGapWidth + (tIndex * _cardWidth)-1;
    tFrame.size.width=2;
    
    tFrame.origin.y=5;
    tFrame.size.height=_cachedContentSize.height-10;
    
    tAttributes.frame=tFrame;
    
    return tAttributes;
}

- (NSArray<__kindof NSCollectionViewLayoutAttributes *> *) layoutAttributesForElementsInRect:(NSRect)rect
{
    NSInteger tNumberOfItems = [self.collectionView numberOfItemsInSection:0];
    
    NSMutableArray* tAttributesArray = [NSMutableArray arrayWithCapacity:tNumberOfItems];
    
    for (NSInteger tIndex=0; tIndex<tNumberOfItems; tIndex++)
    {
        NSCollectionViewLayoutAttributes * tAttribute=[self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:tIndex inSection:0]];
        
        //if (NSIntersectsRect(tAttribute.frame, rect)==YES)
        [tAttributesArray addObject:tAttribute];
    }
    
    return tAttributesArray;
}

-(NSCollectionViewLayoutAttributes*) layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSRect tItemFrame;
    
    tItemFrame.origin.x = (indexPath.item+1) * CUIColumnInterGapWidth + (indexPath.item * _cardWidth)+_cachedEdgeInsets.left;
    tItemFrame.origin.y = CUICardVerticalMargin;
    tItemFrame.size = NSMakeSize(_cardWidth,CUICardHeight);
    
    NSCollectionViewLayoutAttributes * tAttributes = [NSCollectionViewLayoutAttributes layoutAttributesForItemWithIndexPath:indexPath];
    tAttributes.frame = tItemFrame;
    
    return tAttributes;
}

@end
