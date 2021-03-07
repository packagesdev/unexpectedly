/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUITheme.h"

#import "NSDictionary+WBExtensions.h"

NSString * const CUIThemeNameKey=@"name";

NSString * const CUIThemeUUIDKey=@"UUID";

NSString * const CUIThemeMonochromeKey=@"monochrome";

NSString * const CUIThemeGroupsKey=@"groups";

@interface CUITheme ()

    @property NSDictionary * itemsGroupsRegistry;

    @property (copy) NSString * UUID;

- (instancetype)initWithRepresentation:(NSDictionary *)inRepresentation newUUID:(BOOL)inNewUUID;

@end

@implementation CUITheme

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _name=@"";
        
        _UUID=[NSUUID UUID].UUIDString;
        
        _monochrome=NO;
        
        _itemsGroupsRegistry=@{};
    }
    
    return self;
}

- (instancetype)initWithRepresentation:(NSDictionary *)inRepresentation
{
    return [self initWithRepresentation:inRepresentation newUUID:NO];
}

- (instancetype)initWithRepresentation:(NSDictionary *)inRepresentation newUUID:(BOOL)inNewUUID
{
    if ([inRepresentation isKindOfClass:[NSDictionary class]]==NO)
        return nil;
    
    self=[super init];
    
    if (self!=nil)
    {
        NSString * tString=inRepresentation[CUIThemeNameKey];
        
        if ([tString isKindOfClass:[NSString class]]==NO)
            return nil;
        
        _name=[tString copy];
        
        
        if (inNewUUID==NO)
        {
            tString=inRepresentation[CUIThemeUUIDKey];
        
            if ([tString isKindOfClass:[NSString class]]==NO)
                return nil;
        
            _UUID=[tString copy];
        }
        else
        {
            _UUID=[NSUUID UUID].UUIDString;
        }
        
        NSNumber * tNumber=inRepresentation[CUIThemeMonochromeKey];
        
        if (tNumber!=nil)
        {
            if ([tNumber isKindOfClass:[NSNumber class]]==NO)
                return nil;
        
            _monochrome=tNumber.boolValue;
        }
        else
        {
            _monochrome=NO;
        }
        
        NSArray * tArray=inRepresentation[CUIThemeGroupsKey];

        if ([tArray isKindOfClass:[NSArray class]]==NO)
            return nil;
        
        NSMutableDictionary * tMutableDictionary=[NSMutableDictionary dictionary];
        
        for(NSDictionary * bGroupRepresentation in tArray)
        {
            if ([bGroupRepresentation isKindOfClass:[NSDictionary class]]==NO)
                return nil;
            
            CUIThemeItemsGroup * tItemsGroup=[[CUIThemeItemsGroup alloc] initWithRepresentation:bGroupRepresentation];
            
            if (tItemsGroup==nil)
                return nil;
            
            tMutableDictionary[tItemsGroup.identifier]=tItemsGroup;
        }
        
        self.itemsGroupsRegistry=[tMutableDictionary copy];
    }
    
    return self;
}

#pragma mark -

- (NSDictionary *)representation
{
    NSMutableArray * tMutableArray=[NSMutableArray array];
    
    [self.itemsGroupsRegistry enumerateKeysAndObjectsUsingBlock:^(id bKey, CUIThemeItemsGroup * bItemsGroup, BOOL * bOutStop) {
        
        NSDictionary * tRepresentation=[bItemsGroup representation];
        
        [tMutableArray addObject:tRepresentation];
    }];
    
    return @{
             CUIThemeNameKey:self.name,
             CUIThemeUUIDKey:self.UUID,
             CUIThemeMonochromeKey:@(self.monochrome),
             
             CUIThemeGroupsKey:[tMutableArray copy]
             };
}

- (NSDictionary *)exportedRepresentation
{
    // We don't want exported Themes to have the same UUID as the listed ones
    
    NSMutableDictionary * tMutableDictionary=[[self representation] mutableCopy];
    
    tMutableDictionary[CUIThemeUUIDKey]=[NSUUID UUID].UUIDString;
    
    return [tMutableDictionary copy];
}

#pragma mark -

- (NSArray *)allItemsGroups
{
    return [_itemsGroupsRegistry allValues];
}

- (CUIThemeItemsGroup *)itemsGroupWithIdentifier:(NSString *)inIdentifier
{
    if (inIdentifier==nil)
        return nil;
    
    return _itemsGroupsRegistry[inIdentifier];
}

#pragma mark - NSCopying

- (id)copyWithZone:(nullable NSZone *)zone
{
    CUITheme * nTheme=[CUITheme new];
    
    nTheme.name=self.name;
    
    // We don't copy the monochrone key
    
    nTheme.itemsGroupsRegistry=[self.itemsGroupsRegistry WB_dictionaryByMappingObjectsUsingBlock:^id(id bKey, CUIThemeItemsGroup * bItemsGroup) {
        
        return [bItemsGroup copy];
        
    }];
    
    return nTheme;
}

@end
