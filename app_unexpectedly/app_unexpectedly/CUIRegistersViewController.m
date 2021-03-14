/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIRegistersViewController.h"

#import "CUIRegister.h"

#import "CUIRegisterLabel.h"

#import "CUICollectionViewRegisterItem.h"

@interface CUIRegistersViewController () <NSCollectionViewDataSource,NSCollectionViewDelegate>
{
    IBOutlet NSCollectionView * _collectionView;
}

// Notifications

- (void)registerItemValueAsDidChange:(NSNotification *)inNotification;

@end

@implementation CUIRegistersViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)nibName
{
    return @"CUIRegistersViewController";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _collectionView.dataSource=self;
    _collectionView.delegate=self;
    
    _collectionView.backgroundColors=@[[NSColor clearColor]];
    
    NSNib * tNib=[[NSNib alloc] initWithNibNamed:@"CUICollectionViewRegisterItem" bundle:[NSBundle mainBundle]];
    
    [_collectionView registerNib:tNib forItemWithIdentifier:@"register"];
    
    // Register for notifications
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(registerItemValueAsDidChange:) name:CUIRegisterItemViewAsValueDidChangeNotification object:nil];
}

#pragma mark -

- (void)setBrowsingState:(CUICrashLogBrowsingState *)inBrowsingState
{
    _browsingState=inBrowsingState;
    
    [self refreshUI];
}

- (void)setThreadState:(CUICrashLogThreadState *)inThreadState
{
    _threadState=inThreadState;
    
    [self refreshUI];
}

- (NSSize)idealSizeForNumberOfColumns:(NSUInteger)inColumnsNumber
{
    if (inColumnsNumber==0)
        return NSZeroSize;
    
    NSCollectionViewFlowLayout * tFlowLayout=(NSCollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    
    NSEdgeInsets tMarginInsets=tFlowLayout.sectionInset;
    
    NSSize tItemSize=tFlowLayout.itemSize;
    
    CGFloat tHorizontalPadding=tFlowLayout.minimumInteritemSpacing;
    
    CGFloat tIdealWidth=tMarginInsets.left+inColumnsNumber*tItemSize.width+(inColumnsNumber-1)*tHorizontalPadding+tMarginInsets.right+22;
    
    
    
    NSUInteger tNumberOfSections=[self numberOfSectionsInCollectionView:_collectionView];
    
    NSUInteger tNumberOfItems=0;
    
    for(NSUInteger tSectionIndex=0;tSectionIndex<tNumberOfSections;tSectionIndex++)
        tNumberOfItems+=[self collectionView:_collectionView numberOfItemsInSection:tSectionIndex];
    
    NSUInteger tNumberOfRows=(tNumberOfItems/inColumnsNumber)+(((tNumberOfItems%inColumnsNumber)==0) ? 0 : 1);
    
    CGFloat tIdealHeight=tFlowLayout.headerReferenceSize.height+tNumberOfRows*tItemSize.height+(tNumberOfRows-1)*tFlowLayout.minimumLineSpacing+tFlowLayout.footerReferenceSize.height;
    
    return NSMakeSize(tIdealWidth, tIdealHeight);
}

#pragma mark -

- (void)refreshUI
{
    [_collectionView reloadData];
}

#pragma mark - NSCollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(NSCollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(NSCollectionView *)inCollectionView numberOfItemsInSection:(NSInteger)inSection
{
    if (inCollectionView==_collectionView)
        return _threadState.registers.count;
    
    return 0;
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)inCollectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)inIndexPath
{
    if (inCollectionView==_collectionView)
    {
        CUICollectionViewRegisterItem * tCollectionViewItem=(CUICollectionViewRegisterItem *)[inCollectionView makeItemWithIdentifier:@"register" forIndexPath:inIndexPath];
        
        CUIRegister * tRegister=_threadState.registers[inIndexPath.item];
        
        NSMutableDictionary * tRepresentedObject=[NSMutableDictionary dictionaryWithObject:tRegister forKey:@"register"];
        
        NSNumber * tNumber=self.browsingState.registersViewValues[tRegister.name];
        
        if (tNumber!=nil)
            tRepresentedObject[@"viewAs"]=tNumber;
        
        tCollectionViewItem.representedObject=tRepresentedObject;
        
        return tCollectionViewItem;
    }
    
    return nil;
}

#pragma mark - Notifications

- (void)registerItemValueAsDidChange:(NSNotification *)inNotification
{
    CUIRegister * tRegister=inNotification.object;
    
    NSNumber * tViewAsValueNumber=inNotification.userInfo[@"viewAs"];
    
    self.browsingState.registersViewValues[tRegister.name]=tViewAsValueNumber;
}

@end
