/*
 Copyright (c) 2020-2025, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "DWRFSection_debug_aranges.h"

#import "DWRFObject.h"


@interface DWRFCompilationUnitAddressSpaceHeader : DWRFObject

    @property uint64_t unitLength;

    @property uint16_t version;

    @property uint64_t debugInfoOffset;

    @property uint8_t addressSize;
    @property uint8_t segmentSize;

    @property (nonatomic,readonly) size_t headerSize;

    @property (nonatomic,readonly) size_t addressRangeDescriptorSize;

    @property (nonatomic,readonly) size_t paddingSize;

- (instancetype)initWithBuffer:(uint8_t *)inBuffer outBuffer:(uint8_t **)outBuffer;

@end

@implementation DWRFCompilationUnitAddressSpaceHeader

- (instancetype)initWithBuffer:(uint8_t *)inBuffer outBuffer:(uint8_t **)outBuffer
{
    if (inBuffer==NULL)
        return nil;
    
    self=[super init];
                        
    if (self!=nil)
    {
        uint8_t * tBufferPtr=inBuffer;
        
        uint32_t tUnsignedInteger=*((uint32_t *)tBufferPtr);
        
        tBufferPtr+=sizeof(uint32_t);
        
        if (tUnsignedInteger==0xffffffff)
        {
            self.dwarfFormat=DWRF64Format;
            
            _unitLength=*((uint64_t *)tBufferPtr);
            
            tBufferPtr+=sizeof(uint64_t);
        }
        else
        {
            self.dwarfFormat=DWRF32Format;
            
            _unitLength=tUnsignedInteger;
        }
        
        _version=*((uint16_t *)tBufferPtr);
        tBufferPtr+=sizeof(uint16_t);
        
        if (self.dwarfFormat==DWRF64Format)
        {
            _debugInfoOffset=*((uint64_t *)tBufferPtr);
            tBufferPtr+=sizeof(uint64_t);
        }
        else
        {
            _debugInfoOffset=*((uint32_t *)tBufferPtr);
            tBufferPtr+=sizeof(uint32_t);
        }
        
        _addressSize=*((uint8_t *)tBufferPtr);
        tBufferPtr+=sizeof(uint8_t);
        
        _segmentSize=*((uint8_t *)tBufferPtr);
        tBufferPtr+=sizeof(uint8_t);
        
        if (outBuffer!=NULL)
            *outBuffer=tBufferPtr;
    }
    
    return self;
}

#pragma mark -

- (size_t)headerSize
{
    switch(self.dwarfFormat)
    {
        case DWRF32Format:
            
            return 12*sizeof(uint8_t);
            
        case DWRF64Format:
            
            return 24*sizeof(uint8_t);
            
        default:
            
            return -1;
    }
}

- (size_t)addressRangeDescriptorSize
{
    return _segmentSize+2*_addressSize;
}

- (size_t)paddingSize
{
    size_t tDescriptorSize=self.addressRangeDescriptorSize;
    size_t tHeaderSize=self.headerSize;
    
    while (tHeaderSize>tDescriptorSize)
        tHeaderSize-=tDescriptorSize;
    
    return (tDescriptorSize-tHeaderSize);
}

@end

@interface DWRFAddressRangeDescriptor : NSObject
{
    uint64_t _segmentSelector;
}

    @property uint64_t location;
    @property uint64_t length;

+ (DWRFAddressRangeDescriptor *)addressRangeDescriptionWithLocation:(uint64_t)inLocation length:(uint64_t)inLength;

- (instancetype)initWithLocation:(uint64_t)inLocation length:(uint64_t)inLength;

- (BOOL)containsAddress:(uint64_t)inAddress;

@end

@implementation DWRFAddressRangeDescriptor

+ (DWRFAddressRangeDescriptor *)addressRangeDescriptionWithLocation:(uint64_t)inLocation length:(uint64_t)inLength
{
    return [[DWRFAddressRangeDescriptor alloc] initWithLocation:inLocation length:inLength];
}

- (instancetype)initWithLocation:(uint64_t)inLocation length:(uint64_t)inLength
{
    self=[super init];
    
    if (self!=nil)
    {
        _location=inLocation;
        _length=inLength;
    }
    
    return self;
}

#pragma mark -

- (NSUInteger)hash
{
    return self.location;
}

#pragma mark -

- (BOOL)containsAddress:(uint64_t)inAddress
{
    return (inAddress>=self.location && inAddress<(self.location+self.length));
}

#pragma mark -

- (NSString *)description
{
    return [NSString stringWithFormat:@"0x%lx - 0x%lx",(long)self.location,(long)(self.location+self.length-1)];
}

@end


@interface DWRFCompilationUnitAddressSpace ()
{
    DWRFCompilationUnitAddressSpaceHeader * _header;
    
    NSMutableArray<DWRFAddressRangeDescriptor *> * _addressRangeDescriptors;
}

- (instancetype)initWithBuffer:(uint8_t *)inBuffer outBuffer:(uint8_t **)outBuffer;

@end

@implementation DWRFCompilationUnitAddressSpace

- (instancetype)initWithBuffer:(uint8_t *)inBuffer outBuffer:(uint8_t **)outBuffer
{
    if (inBuffer==NULL)
        return nil;
    
    self=[super init];
    
    if (self==nil)
        return nil;
    
    uint8_t * tBufferPtr=inBuffer;
    
    _header=[[DWRFCompilationUnitAddressSpaceHeader alloc] initWithBuffer:tBufferPtr outBuffer:NULL];
    
    _addressRangeDescriptors=[NSMutableArray array];
    
    tBufferPtr+=_header.addressRangeDescriptorSize*sizeof(uint8_t);
    
    while(1)
    {
        uint64_t tSegmentSelector=0;
        
        if (_header.segmentSize!=0)
        {
            // A COMPLETER
        }
        
        uint64_t tLocation;
        uint64_t tLength;
        
        if (_header.addressSize==4)
        {
            tLocation=*((uint32_t *)tBufferPtr);
            tBufferPtr+=sizeof(uint32_t);
            
            tLength=*((uint32_t *)tBufferPtr);
            tBufferPtr+=sizeof(uint32_t);
        }
        else
        {
            tLocation=*((uint64_t *)tBufferPtr);
            tBufferPtr+=sizeof(uint64_t);
            
            tLength=*((uint64_t *)tBufferPtr);
            tBufferPtr+=sizeof(uint64_t);
        }
        
        if (tSegmentSelector==0 && tLocation==0 && tLength==0)
            break;
        
        DWRFAddressRangeDescriptor * tDescription=[DWRFAddressRangeDescriptor addressRangeDescriptionWithLocation:tLocation length:tLength];
        
        [_addressRangeDescriptors addObject:tDescription];
        
        //printf("0x%llX-0x%llX\n",tLocation,tLocation+tLength-1);
    }
    
    if (outBuffer!=NULL)
        *outBuffer=tBufferPtr;
    
    return self;
}

#pragma mark -

- (uint64_t)debugInfoOffset
{
    return _header.debugInfoOffset;
}

- (BOOL)containsAddress:(uint64_t)inAddress
{
    for(DWRFAddressRangeDescriptor * tAddressRangeDescription in _addressRangeDescriptors)
    {
        if ([tAddressRangeDescription containsAddress:inAddress]==YES)
            return YES;
    }
    
    return NO;
}

#pragma mark -

- (NSString *)description
{
    NSMutableString * tMutableString=[NSMutableString string];
    
    [tMutableString appendFormat:@"unit_length: %llu\n",_header.unitLength];
    [tMutableString appendFormat:@"version: %hu\n",_header.version];
    [tMutableString appendFormat:@"debug_info_offset: %llu\n",_header.debugInfoOffset];
    
    for(DWRFAddressRangeDescriptor * tDescriptor in _addressRangeDescriptors)
        [tMutableString appendFormat:@"%@\n",[tDescriptor description]];
    
    return tMutableString;
}

@end


@interface DWRFSection_debug_aranges ()
{
    NSMutableArray * _compilationUnitsAddressSpaces;
    
}

@end

@implementation DWRFSection_debug_aranges

- (instancetype)initWithData:(NSData *)inData
{
    if (inData==nil || [inData isKindOfClass:NSData.class]==NO)
        return nil;
    
    self=[super init];
    
    if (self!=nil)
    {
        _compilationUnitsAddressSpaces=[NSMutableArray array];
        
        uint8_t * tBufferPtr=(uint8_t *)inData.bytes;
        uint8_t * tEndBufferPtr=tBufferPtr+inData.length;
        
        while(tBufferPtr<tEndBufferPtr)
        {
            DWRFCompilationUnitAddressSpace * tAddressSpace=[[DWRFCompilationUnitAddressSpace alloc] initWithBuffer:tBufferPtr outBuffer:&tBufferPtr];
            
            if (tAddressSpace!=nil)
                [_compilationUnitsAddressSpaces addObject:tAddressSpace];
        }
    }
    
    return self;
}

#pragma mark -

- (NSArray<DWRFCompilationUnitAddressSpace *> *)allCompilationUnitsAddressSpaces
{
    return _compilationUnitsAddressSpaces;
}

- (DWRFCompilationUnitAddressSpace *)compilationUnitAddressSpaceForAddress:(uint64_t)inAddress
{
    for(DWRFCompilationUnitAddressSpace * tAddressSpace in _compilationUnitsAddressSpaces)
    {
        if ([tAddressSpace containsAddress:inAddress]==YES)
            return tAddressSpace;
    }
    
    return nil;
}

- (uint64_t)debugInfoOffsetForAddress:(uint64_t)inAddress
{
    for(DWRFCompilationUnitAddressSpace * tAddressSpace in _compilationUnitsAddressSpaces)
    {
        if ([tAddressSpace containsAddress:inAddress]==YES)
        {
            return tAddressSpace.debugInfoOffset;
        }
    }

    return UINT64_MAX;
}

@end
