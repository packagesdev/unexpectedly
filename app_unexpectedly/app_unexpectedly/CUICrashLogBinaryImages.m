/*
 Copyright (c) 2020-2022, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICrashLogBinaryImages.h"

#import "CUIParsingErrors.h"

#import "NSArray+WBExtensions.h"

@interface CUICrashLogBinaryImages ()
{
    NSMutableDictionary * _binaryImagesRegistry;
    
    NSMutableDictionary * _binaryNamesRegistry;
    
    NSMutableDictionary * _binaryNameToIdentifierRosettaStone;
}

@property (readwrite) NSArray<CUIBinaryImage *> * binaryImages;

- (BOOL)parseTextualRepresentation:(NSArray *)inLines reportVersion:(NSUInteger)inReportVersion outError:(NSError **)outError;

@end


@implementation CUICrashLogBinaryImages

- (instancetype)initWithTextualRepresentation:(NSArray *)inLines reportVersion:(NSUInteger)inReportVersion error:(NSError **)outError
{
    if ([inLines isKindOfClass:[NSArray class]]==NO)
    {
        if (outError!=NULL)
            *outError=[NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:@{}];
        
        return nil;
    }
    
    self=[super init];
    
    if (self!=nil)
    {
        _binaryImages=[NSArray array];
        
        _binaryImagesRegistry=[NSMutableDictionary dictionary];
        
        _binaryNamesRegistry=[NSMutableDictionary dictionary];
        
        _binaryNameToIdentifierRosettaStone=[NSMutableDictionary dictionary];
        
        if ([self parseTextualRepresentation:inLines reportVersion:inReportVersion outError:outError]==NO)
        {
            return nil;
        }
    }
    
    return self;
}

- (instancetype)initWithIPSIncident:(IPSIncident *)inIncident error:(NSError **)outError
{
    if ([inIncident isKindOfClass:[IPSIncident class]]==NO)
    {
        if (outError!=NULL)
            *outError=[NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:@{}];
        
        return nil;
    }
    
    self=[super init];
    
    if (self!=nil)
    {
        NSMutableDictionary * tBinaryImagesRegistry=[NSMutableDictionary dictionary];
        
        NSMutableDictionary * tBinaryNamesRegistry=[NSMutableDictionary dictionary];
        
        NSMutableDictionary * tBinaryNameToIdentifierRosettaStone=[NSMutableDictionary dictionary];
        
        _binaryImages=(NSArray<CUIBinaryImage *> *)[inIncident.binaryImages WB_arrayByMappingObjectsLenientlyUsingBlock:^CUIBinaryImage *(IPSImage * bImage, NSUInteger bIndex) {
            
            if ([bImage.source isEqualToString:@"A"]==YES)
                return nil;
            
            CUIBinaryImage * tBinaryImage=[[CUIBinaryImage alloc] initWithImage:bImage error:NULL];
        
            if (tBinaryImage==nil)
            {
                // A COMPLETER
            }
            else
            {
                if (bIndex==0)
                    tBinaryImage.mainImage=YES;
                
                tBinaryImagesRegistry[tBinaryImage.identifier]=tBinaryImage;
                
                NSString * tBinartName=tBinaryImage.path.lastPathComponent;
                
                tBinaryNamesRegistry[tBinartName]=tBinaryImage;
                
                tBinaryNameToIdentifierRosettaStone[tBinartName]=tBinaryImage.identifier;
            }
            
            return tBinaryImage;
            
        }];
        
        _binaryImagesRegistry=tBinaryImagesRegistry;
        
        _binaryNamesRegistry=tBinaryNamesRegistry;
        
        _binaryNameToIdentifierRosettaStone=tBinaryNameToIdentifierRosettaStone;
    }
    
    return self;
}

#pragma mark -

- (BOOL)parseTextualRepresentation:(NSArray *)inLines reportVersion:(NSUInteger)inReportVersion outError:(NSError **)outError
{
    if ([inLines.firstObject isEqualToString:@"Binary images description not available"]==YES)
        return YES;
    
    __block NSError * tError=nil;
    
    NSArray * tImagesLines=[inLines subarrayWithRange:NSMakeRange(1, inLines.count-1)];
    
    NSMutableArray * tBinaryImages=[NSMutableArray array];
    
    [tImagesLines enumerateObjectsUsingBlock:^(NSString * bLine, NSUInteger bLineNumber, BOOL *bOutStop) {
        
        NSUInteger tLineLength=bLine.length;
        
        if (tLineLength==0)
        {
            *bOutStop=YES;
            
            return;
        }
        
        CUIBinaryImage * tBinaryImage=[[CUIBinaryImage alloc] initWithString:bLine reportVersion:inReportVersion error:&tError];
        
        if (tBinaryImage==nil)
        {
            tError=[NSError errorWithDomain:CUIParsingErrorDomain code:CUIParsingUnknownError userInfo:@{CUIParsingErrorLineKey:@(bLineNumber)}];
            
            *bOutStop=YES;
            
            return;
        }
        
        if (bLineNumber==0)
            tBinaryImage.mainImage=YES;
        
        [tBinaryImages addObject:tBinaryImage];
        
        self->_binaryImagesRegistry[tBinaryImage.identifier]=tBinaryImage;
        
        NSString * tBinartName=tBinaryImage.path.lastPathComponent;
        
        self->_binaryNamesRegistry[tBinartName]=tBinaryImage;
        
        self->_binaryNameToIdentifierRosettaStone[tBinartName]=tBinaryImage.identifier;
        
    }];
    
    _binaryImages=[tBinaryImages copy];
    
    if (outError!=NULL && tError!=nil)
        *outError=tError;
    
    return YES;
}

#pragma mark -

- (NSArray *)allUUIDs
{
    return [_binaryImages WB_arrayByMappingObjectsLenientlyUsingBlock:^id(CUIBinaryImage * bBinaryImage, NSUInteger bIndex) {
        
        return bBinaryImage.UUID;   // can be nil
    }];
}

- (NSArray *)userCodeBinaryImages
{
    return [_binaryImages WB_filteredArrayUsingBlock:^BOOL(CUIBinaryImage * bBinaryImage, NSUInteger bIndex) {
       
        
        if (bBinaryImage.isUserCode==YES)
            return YES;
        
        NSString * tPath=bBinaryImage.path;
        
        return ([tPath hasPrefix:@"/System/"]==NO && [tPath hasPrefix:@"/usr/lib"]==NO);
    }];
}

- (NSString *)binaryImageIdentifierForName:(NSString *)inBinaryName
{
    if (inBinaryName==nil)
        return nil;
    
    return _binaryNameToIdentifierRosettaStone[inBinaryName];
}

- (CUIBinaryImage *)binaryImageWithIdentifier:(NSString *)inIdentifier
{
    if (inIdentifier==nil)
        return nil;
    
    return _binaryImagesRegistry[inIdentifier];
}

- (CUIBinaryImage *)binaryImageForMemoryAddress:(NSUInteger)inMemoryAddress
{
    static CUIBinaryImage * sLastFoundBinaryImage=nil;
    
    if (sLastFoundBinaryImage!=nil)
    {
        CUIAddressesRange * tRange=sLastFoundBinaryImage.addressesRange;
        
        if (inMemoryAddress>=tRange.loadAddress && inMemoryAddress<(tRange.loadAddress+tRange.length))
            return sLastFoundBinaryImage;
    }
    
    for(CUIBinaryImage * tBinaryImage in _binaryImages)
    {
        CUIAddressesRange * tRange=tBinaryImage.addressesRange;
        
        if (inMemoryAddress>=tRange.loadAddress && inMemoryAddress<(tRange.loadAddress+tRange.length))
        {
            sLastFoundBinaryImage=tBinaryImage;
            
            return tBinaryImage;
        }
    }
    
    return nil;
}

- (BOOL)isUserCodeAtMemoryAddress:(NSUInteger)inMemoryAddress inBinaryImage:(NSString *)inIdentifier
{
    CUIBinaryImage * tBinaryImage=_binaryImagesRegistry[inIdentifier];
    
    if (tBinaryImage==nil)
        return NO;
    
    if (tBinaryImage.isUserCode==NO)
        return NO;
    
    CUIAddressesRange * tRange=tBinaryImage.addressesRange;
    
    return (inMemoryAddress>=tRange.loadAddress && inMemoryAddress<(tRange.loadAddress+tRange.length));
}

- (BOOL)isUserCodeAtMemoryAddress:(NSUInteger)inMemoryAddress inBinaryName:(NSString *)inName
{
    CUIBinaryImage * tBinaryImage=_binaryNamesRegistry[inName];
    
    if (tBinaryImage==nil)
        return NO;
    
    if (tBinaryImage.isUserCode==NO)
        return NO;
    
    CUIAddressesRange * tRange=tBinaryImage.addressesRange;
    
    return (inMemoryAddress>=tRange.loadAddress && inMemoryAddress<(tRange.loadAddress+tRange.length));
}

- (CUIBinaryImage *)binaryImageWithIdentifierOrName:(NSString *)inString identifier:(NSString **)outIdentifier
{
    CUIBinaryImage * tBinaryImage=[self binaryImageWithIdentifier:inString];
    
    if (tBinaryImage==nil)
    {
        NSString * tUUID=[self binaryImageIdentifierForName:inString];
        
        if (tUUID!=nil)
        {
            tBinaryImage=[self binaryImageWithIdentifier:tUUID];
            
            if (tBinaryImage!=nil)
            {
                if (outIdentifier!=NULL)
                    *outIdentifier=tUUID;
            }
        }
    }
    else
    {
        if (outIdentifier!=NULL)
            *outIdentifier=inString;
    }
    
    return tBinaryImage;
}

@end
