/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIBinaryImage.h"

@interface CUIAddressesRange ()

+ (CUIAddressesRange *)addressesRangeWithLocation:(NSUInteger)inLocation length:(NSUInteger)inLength;

- (instancetype)initWithLocation:(NSUInteger)inLocation length:(NSUInteger)inLength;

@end

@implementation CUIAddressesRange

+ (CUIAddressesRange *)addressesRangeWithLocation:(NSUInteger)inLocation length:(NSUInteger)inLength
{
    return [[CUIAddressesRange alloc] initWithLocation:inLocation length:inLength];
}

- (instancetype)initWithLocation:(NSUInteger)inLocation length:(NSUInteger)inLength
{
    self=[super init];
    
    if (self!=nil)
    {
        _loadAddress=inLocation;
        
        _length=inLength;
    }
    
    return self;
}

#pragma mark -

- (NSUInteger)max
{
    return self.loadAddress+self.length;
}

#pragma mark -

- (NSString *)stringValue
{
    return [NSString stringWithFormat:@"0x%012lx - 0x%012lx",self.loadAddress,self.max];
}

#pragma mark -

- (NSComparisonResult)compare:(CUIAddressesRange *)inOtherAddressesRange
{
    if (inOtherAddressesRange==nil)
        return NSOrderedDescending;
    
    if (self.loadAddress>inOtherAddressesRange.loadAddress)
        return NSOrderedDescending;
    
    if (self.loadAddress<inOtherAddressesRange.loadAddress)
        return NSOrderedAscending;
    
    if (self.length>inOtherAddressesRange.length)
        return NSOrderedDescending;
    
    if (self.length<inOtherAddressesRange.length)
        return NSOrderedAscending;
    
    return NSOrderedSame;
}

@end


@interface CUIBinaryImage ()

    @property (getter=isUserCode) BOOL userCode;

    @property (copy) NSString * identifier;

    @property (copy) NSString * version;

    @property (copy) NSString * buildNumber;

    @property (copy) NSString * UUID;

    @property (copy) NSString * path;

    @property CUIAddressesRange * addressesRange;

@end

// Line example:
// 0x7fff2d259000 -     0x7fff2d259fff  com.apple.Accelerate (1.11 - Accelerate 1.11) <B2A0C739-1D41-3452-9D00-8C01ADA5DD99> /System/Library/Frameworks/Accelerate.framework/Versions/A/Accelerate

@implementation CUIBinaryImage

- (instancetype)initWithString:(NSString *)inString error:(NSError **)outError
{
    if ([inString isKindOfClass:[NSString class]]==NO)
    {
        if (outError!=NULL)
            *outError=[NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:@{}];
        
        return nil;
    }
    
    self=[super init];
    
    if (self!=nil)
    {
        NSCharacterSet * tWhitespaceCharacterSet=[NSCharacterSet whitespaceCharacterSet];
        NSScanner * tScanner=[NSScanner scannerWithString:inString];
        
        tScanner.charactersToBeSkipped=tWhitespaceCharacterSet;
        
        unsigned long long tAddressRangeStart=0;
        
        if ([tScanner scanHexLongLong:&tAddressRangeStart]==NO)
            return nil;
        
        if ([tScanner scanUpToString:@"0" intoString:NULL]==NO)
            return nil;
        
        unsigned long long tAddressRangeEnd=0;
        
        if ([tScanner scanHexLongLong:&tAddressRangeEnd]==NO)
            return nil;
        
        _addressesRange=[CUIAddressesRange addressesRangeWithLocation:tAddressRangeStart length:tAddressRangeEnd-tAddressRangeStart+1];
        
        NSString * tString;
        
        if ([tScanner scanUpToString:@"(" intoString:&tString]==NO)
            return nil;
        
        if ([tString hasPrefix:@"+"]==YES && tString.length>1)
        {
            _userCode=YES;
            
            tString=[tString substringFromIndex:1];
        }
        
        _identifier=[[tString stringByTrimmingCharactersInSet:tWhitespaceCharacterSet] copy];
        
        // Version
        
        if (tScanner.scanLocation>=inString.length)
            return nil;
        
        tScanner.scanLocation+=1;
        
        if ([tScanner scanUpToString:@")" intoString:&tString]==NO)
            return nil;
        
        NSArray * tVersions=[tString componentsSeparatedByString:@" - "];
        
        switch(tVersions.count)
        {
            case 2:
                
                _buildNumber=[tVersions[1] stringByTrimmingCharactersInSet:tWhitespaceCharacterSet];
                
            case 1:
                
                _version=[tVersions.firstObject stringByTrimmingCharactersInSet:tWhitespaceCharacterSet];
                
                break;
        }
        
        // UUID
        
        tScanner.scanLocation+=2;
        
        if ([inString characterAtIndex:tScanner.scanLocation]=='<')
        {
            if ([tScanner scanUpToString:@">" intoString:&tString]==NO)
                return nil;
        
            _UUID=[tString substringFromIndex:1];
        }
        else
        {
            tScanner.scanLocation-=2;
        }
        
        if ([tScanner scanUpToString:@"/" intoString:NULL]==NO)
            return nil;
        
        _path=[[inString substringFromIndex:tScanner.scanLocation] stringByTrimmingCharactersInSet:tWhitespaceCharacterSet];
    }
    
    return self;
}

#pragma mark -

- (NSUInteger)binaryImageOffset
{
    NSUInteger tLoadAddress=self.addressesRange.loadAddress;
    
    if (tLoadAddress>0x7fff00000000 || self.mainImage==NO)
        return tLoadAddress;
    
    return (tLoadAddress-0x100000000);
}

@end
