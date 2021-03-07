/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "DWRFSection_debug_abbrev.h"

#include "LEB128.h"

typedef NS_ENUM(uint8_t, DW_CHILDREN)
{
    DW_CHILDREN_no = 0x00,
    DW_CHILDREN_yes = 0x01
};


@interface DWRFAttributeSpecification ()

    @property DW_AT name;
    @property DW_FORM form;

- (instancetype)initWithName:(DW_AT)inName form:(DW_FORM)inForm;

@end

@implementation DWRFAttributeSpecification

- (instancetype)initWithName:(DW_AT)inName form:(DW_FORM)inForm
{
    self=[super init];
    
    if (self!=nil)
    {
        _name=inName;
        _form=inForm;
    }
    
    return self;
}

@end


@interface DWRFAbbreviationDeclaration ()
{
    NSMutableArray<DWRFAttributeSpecification *> * _attributesSpecifications;
}

    @property uint64_t code;

    @property DW_TAG tag;

    @property BOOL hasChildren;

+ (DWRFAbbreviationDeclaration *)nilDeclaration;

@end

@implementation DWRFAbbreviationDeclaration

+ (DWRFAbbreviationDeclaration *)nilDeclaration
{
    static DWRFAbbreviationDeclaration * sNilAbbreviationDeclaration=nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sNilAbbreviationDeclaration=[DWRFAbbreviationDeclaration new];
        
        sNilAbbreviationDeclaration.code=0;
        sNilAbbreviationDeclaration.tag=0;
        
    });
    
    return sNilAbbreviationDeclaration;
}

- (instancetype)initWithBuffer:(uint8_t *)inBuffer outBuffer:(uint8_t **)outBuffer
{
    if (inBuffer==NULL)
        return nil;
    
    self=[super init];
    
    if (self!=nil)
    {
        uint8_t * tBuffer=inBuffer;
        
        _code=DWRF_readULEB128(tBuffer, &tBuffer);
        
        if (_code==0)
            return [DWRFAbbreviationDeclaration nilDeclaration];
        
        _tag=DWRF_readULEB128(tBuffer, &tBuffer);
        
        _hasChildren=((*((uint8_t *)tBuffer))==DW_CHILDREN_yes);
        tBuffer+=sizeof(uint8_t);
        
        _attributesSpecifications=[NSMutableArray array];
        
        while (1)
        {
            DW_AT tName=DWRF_readULEB128(tBuffer, &tBuffer);
            DW_FORM tForm=DWRF_readULEB128(tBuffer, &tBuffer);
            
            if (tName==0 && tForm==0)
                break;
            
            DWRFAttributeSpecification * tAttributeSpecification=[[DWRFAttributeSpecification alloc] initWithName:tName form:tForm];
            
            if (tAttributeSpecification!=nil)
                [_attributesSpecifications addObject:tAttributeSpecification];
        }
        
        if (outBuffer!=NULL)
            *outBuffer=tBuffer;
    }
    
    
    
    return self;
}

#pragma mark -

- (NSArray<DWRFAttributeSpecification *> *)allAttributesSpecifications
{
    return _attributesSpecifications;
}

@end

/*@interface DWRFAbbreviationDeclarationEntriesEnumerator : NSEnumerator
{
    NSMutableArray * _stack;
    
    DWRFAbbreviationDebugingInformationEntry * _nextEntry;
}

- (instancetype)initWithAbbreviationDeclaration:(DWRFAbbreviationDeclaration*)inDeclaration;

@end

@implementation DWRFAbbreviationDeclarationEntriesEnumerator

- (instancetype)initWithAbbreviationDeclaration:(DWRFAbbreviationDeclaration*)inDeclaration
{
    self=[super init];
    
    if (self!=nil)
    {
        _stack=[NSMutableArray array];
        
        _nextEntry=inDeclaration.firstDebugingInformationEntry;
    }
    
    return self;
}

#pragma mark -

- (id)nextObject
{
    if (_nextEntry==nil)
        return nil;
    
    DWRFAbbreviationDebugingInformationEntry * tReturnedEntry=_nextEntry;
    
    if (_nextEntry.children!=nil)
    {
        _nextEntry=_nextEntry.children.firstObject;
    }
    else
    {
        if (_nextEntry.next!=nil)
        {
            _nextEntry=_nextEntry.next;
        }
        else
        {
            while (1)
            {
                _nextEntry=_nextEntry.parent;
                
                if (_nextEntry==nil)
                    break;
                
                if (_nextEntry.next!=nil)
                {
                    _nextEntry=_nextEntry.next;
                    break;
                }
            }
            
            _nextEntry=_nextEntry.parent.next;
        }
    }
    
    return tReturnedEntry;
}

@end*/


@interface DWRFAbbreviationDeclarationsSet ()
{
    NSMutableArray<DWRFAbbreviationDeclaration *> * _abbreviationDeclarations;
}


@end

@implementation DWRFAbbreviationDeclarationsSet

- (instancetype)initWithBuffer:(uint8_t *)inBuffer
{
    if (inBuffer==NULL)
        return nil;
    
    self=[super init];
    
    if (self!=nil)
    {
        uint8_t *tBuffer=inBuffer;
        
        _abbreviationDeclarations=[NSMutableArray array];
        
        while (1)
        {
            DWRFAbbreviationDeclaration * tAbreviationDeclaration=[[DWRFAbbreviationDeclaration alloc] initWithBuffer:tBuffer outBuffer:&tBuffer];
            
            if (tAbreviationDeclaration==nil)
            {
                NSLog(@"Error when unarchiving abbreviation declaration");
                
                return nil;
            }
            
            if (tAbreviationDeclaration.code==0)
                break;
            
            [_abbreviationDeclarations addObject:tAbreviationDeclaration];
        }
    }
    
    return self;
}

#pragma mark -

 - (NSArray<DWRFAbbreviationDeclaration *> *)allAbbreviationDeclarations
{
    return _abbreviationDeclarations;
}

- (DWRFAbbreviationDeclaration *)abbreviationDeclarationForCode:(uint64_t)inCode
{
    if (inCode>_abbreviationDeclarations.count)
        return nil;
    
    return _abbreviationDeclarations[inCode];
}

#pragma mark -

/*- (NSEnumerator *)debuggingInformationEntriesEnumerator
{
    DWRFAbbreviationDeclarationEntriesEnumerator * tEnumerator=[[DWRFAbbreviationDeclarationEntriesEnumerator alloc] initWithAbbreviationDeclaration:self];
    
    return tEnumerator;
}*/

@end


@interface DWRFSection_debug_abbrev ()
{
    NSData * _cachedData;
    
    NSMutableDictionary<NSNumber *,DWRFAbbreviationDeclarationsSet *> * _cachedAbbreviationDeclarationsSets;
}

@end

@implementation DWRFSection_debug_abbrev

- (instancetype)initWithData:(NSData *)inData
{
    if (inData==nil || [inData isKindOfClass:[NSData class]]==NO)
        return nil;
    
    self=[super init];
    
    if (self!=nil)
    {
        _cachedData=inData;
        
        _cachedAbbreviationDeclarationsSets=[NSMutableDictionary dictionary];
    }
    
    return self;
}

- (instancetype)initWithBytes:(uint8_t *)inBytes length:(NSUInteger)inLength
{
    if (inBytes==NULL)
        return nil;
    
    return [self initWithData:[NSData dataWithBytesNoCopy:inBytes length:inLength]];
}

#pragma mark -

- (DWRFAbbreviationDeclarationsSet *)abbreviationDeclarationsSetAtOffset:(uint64_t)inOffset
{
    DWRFAbbreviationDeclarationsSet * tDeclaration=_cachedAbbreviationDeclarationsSets[@(inOffset)];
    
    if (tDeclaration!=nil)
        return tDeclaration;
    
    uint8_t * tBufferPtr=(uint8_t *)_cachedData.bytes;
    
    tDeclaration=[[DWRFAbbreviationDeclarationsSet alloc] initWithBuffer:tBufferPtr+inOffset];
    
    if (tDeclaration!=nil)
        _cachedAbbreviationDeclarationsSets[@(inOffset)]=tDeclaration;
    
    return tDeclaration;
}

@end
