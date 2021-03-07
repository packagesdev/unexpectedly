/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIThemeItemsGroup.h"

#import "NSDictionary+WBExtensions.h"

NSString * const CUIThemeItemsGroupIdentifierKey=@"identifier";

NSString * const CUIThemeItemsGroupItemsNamesKey=@"items";

NSString * const CUIThemeItemsGroupItemsAttributesKey=@"attributes";

@interface CUIThemeItemsGroup ()
{
    NSDictionary * _itemsRegistry;
}

    @property (copy) NSString * identifier;

    @property NSArray * itemsNames;

@end

@implementation CUIThemeItemsGroup

- (instancetype)initWithRepresentation:(NSDictionary *)inRepresentation
{
    if ([inRepresentation isKindOfClass:[NSDictionary class]]==NO)
        return nil;
    
    self=[super init];
    
    if (self!=nil)
    {
        NSString * tString=inRepresentation[CUIThemeItemsGroupIdentifierKey];
        
        if ([tString isKindOfClass:[NSString class]]==NO)
            return nil;
        
        _identifier=[tString copy];
        
        NSArray * tArray=inRepresentation[CUIThemeItemsGroupItemsNamesKey];
        
        if ([tArray isKindOfClass:[NSArray class]]==NO)
            return nil;
        
        _itemsNames=[tArray copy];
        
        NSDictionary * tDictionary=inRepresentation[CUIThemeItemsGroupItemsAttributesKey];
        
        if ([tDictionary isKindOfClass:[NSDictionary class]]==NO)
            return nil;
        
        _itemsRegistry=[tDictionary WB_dictionaryByMappingObjectsUsingBlock:^id(NSString * bItemName, NSDictionary * bItemAttributesRepresentation) {
            
            return [[CUIThemeItemAttributes alloc] initWithRepresentation:bItemAttributesRepresentation];
        }];
    }
    
    return self;
}

- (NSDictionary *)representation
{
    return @{
             CUIThemeItemsGroupIdentifierKey:self.identifier,
             CUIThemeItemsGroupItemsNamesKey:self.itemsNames,
             CUIThemeItemsGroupItemsAttributesKey:[_itemsRegistry WB_dictionaryByMappingObjectsUsingBlock:^id(id bKey, CUIThemeItemAttributes * bItemAttributes) {
                 
                 return [bItemAttributes representation];
             }]
             };
}

#pragma mark -

- (CUIThemeItemAttributes *)attributesForItem:(NSString *)inItemName
{
    if (inItemName==nil)
        return nil;
    
    return _itemsRegistry[inItemName];
}

#pragma mark - NSCopying

- (id)copyWithZone:(nullable NSZone *)zone
{
    CUIThemeItemsGroup * nThemeItemsGroup=[CUIThemeItemsGroup new];
    
    nThemeItemsGroup.identifier=[self.identifier copy];
    
    nThemeItemsGroup.itemsNames=[self.itemsNames copy];
    
    nThemeItemsGroup->_itemsRegistry=[self->_itemsRegistry WB_dictionaryByMappingObjectsUsingBlock:^id(NSString * bItemName, CUIThemeItemAttributes * bItemAttributes) {
        
        return [bItemAttributes copy];
    }];
    
    return nThemeItemsGroup;
}

@end
