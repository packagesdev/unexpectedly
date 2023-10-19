/*
 Copyright (c) 2020-2023, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "MCHSection.h"

#import "MCHObjectFile.h"

#include <mach-o/loader.h>

@implementation MCHSection

- (id)initWithBytes:(const char *)inBytes length:(NSUInteger)inLength swap:(BOOL)inSwap architecture:(MCHArchitecture)inArchitecture objectFile:( MCHObjectFile *)inObjectFile;
{
	if (inBytes==NULL)
        return nil;

    NSString * tSectionName=nil;
    NSString * tSegmentName=nil;
    uint32_t tOffset=0;
    uint64_t tSize=0;
    uint32_t tFlags=0;
    uint64_t tAddress=0;
    
    if (inArchitecture==MCHArchitecture32)
    {
        struct section * tSection32Ptr=(struct section *)inBytes;
        char cStringBuffer[17];
        
        memset(cStringBuffer,0,17);
        memcpy(cStringBuffer,tSection32Ptr->sectname,16);
        
        tSectionName=[[NSString alloc] initWithCString:cStringBuffer
                                              encoding:NSASCIIStringEncoding];
        
        memset(cStringBuffer,0,17);
        memcpy(cStringBuffer,tSection32Ptr->segname,16);
        
        tSegmentName=[[NSString alloc] initWithCString:cStringBuffer
                                            encoding:NSASCIIStringEncoding];
        
        uint32_t tAddress32=tSection32Ptr->addr;
        
        if (inSwap==YES)
            tAddress32=OSSwapBigToHostInt32(tAddress32);
        
        tAddress=tAddress32;
        
        uint32_t tSize32=tSection32Ptr->size;
        
        if (inSwap==YES)
            tSize32=OSSwapBigToHostInt32(tSize32);
        
        tSize=tSize32;
        
        tOffset=tSection32Ptr->offset;
        
        if (inSwap==YES)
            tOffset=OSSwapBigToHostInt32(tOffset);
        
        tFlags=tSection32Ptr->flags;
        
        if (inSwap==YES)
            tFlags=OSSwapBigToHostInt32(tFlags);
    }
    else if (inArchitecture==MCHArchitecture64)
    {
        struct section_64 * tSection64Ptr=(struct section_64 *)inBytes;
        
        char cStringBuffer[17];
        
        memset(cStringBuffer,0,17);
        memcpy(cStringBuffer,tSection64Ptr->sectname,16);
        
        tSectionName=[[NSString alloc] initWithCString:cStringBuffer
                                              encoding:NSASCIIStringEncoding];
        
        memset(cStringBuffer,0,17);
        memcpy(cStringBuffer,tSection64Ptr->segname,16);
        
        tSegmentName=[[NSString alloc] initWithCString:cStringBuffer
                                              encoding:NSASCIIStringEncoding];
        
        uint64_t tAddress64=tSection64Ptr->addr;
        
        if (inSwap==YES)
            tAddress64=OSSwapBigToHostInt64(tAddress64);
        
        tAddress=tAddress64;
        
        uint64_t tSize64=tSection64Ptr->size;
        
        if (inSwap==YES)
            tSize64=OSSwapBigToHostInt64(tSize64);
        
        tSize=tSize64;
        
        tOffset=tSection64Ptr->offset;
        
        if (inSwap==YES)
            tOffset=OSSwapBigToHostInt32(tOffset);
        
        tFlags=tSection64Ptr->flags;
        
        if (inSwap==YES)
            tFlags=OSSwapBigToHostInt32(tFlags);
    }
    else
    {
        // Unknown architecture
        
        return nil;
    }
    
    uint32_t tType=tFlags&SECTION_TYPE;
    
    id tSection=nil;
    
    switch (tType)
    {
        case S_CSTRING_LITERALS:
            
            break;
            
        case S_ZEROFILL:
            
            break;
    
        default:
            
            if (tSection==nil)
                tSection=[super initWithBytes:inObjectFile.buffer+tOffset length:(NSUInteger)tSize swap:inSwap architecture:inArchitecture];
            
            break;
    }
    
    self=tSection;
    
    if (self!=nil)
    {
        _objectFile=inObjectFile;
        
        _name=tSectionName;
        _segmentName=tSegmentName;
        _address=tAddress;
    }
    
    return self;
}

- (void)dealloc
{
	_objectFile=nil;
}

#pragma mark -

- (NSUInteger)hash
{
    return self.name.hash;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"    <0x%08llx> (%@,%@)\n",_address,_segmentName,_name];
}

#pragma mark -

- (const char *)bytesAtAddress:(uint64_t)inAddress
{
	return self.buffer+(inAddress-self.address);
}

@end
