/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "DWRFSection_debug_str_offsets.h"

@interface DWRFSection_debug_str_offsets ()
{
    NSData * _cachedData;
}

@end

@implementation DWRFSection_debug_str_offsets

- (instancetype)initWithData:(NSData *)inData
{
    self=[super init];
    
    if (self!=nil)
    {
        _cachedData=inData;
    }
    
    return self;
}

#pragma mark -

- (uint64_t)offsetAtIndex:(uint64_t)inIndex base:(uint64_t)inBase format:(DWRFFormat)inFormat
{
    uint8_t * tBytes=(uint8_t *)_cachedData.bytes;
    
    tBytes+=inBase;
    
    uint64_t tOffset=0;
    
    if (inFormat==DWRF64Format)
    {
        tBytes+=(inIndex*sizeof(uint64_t));
        
        tOffset=*((uint64_t *)tBytes);
    }
    else
    {
        tBytes+=(inIndex*sizeof(uint32_t));
        
         tOffset=*((uint32_t *)tBytes);
    }
    
    return tOffset;
}

@end
