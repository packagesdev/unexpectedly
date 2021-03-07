/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "LEB128.h"

uint64_t DWRF_readULEB128(uint8_t * inBufferPtr,uint8_t ** outBufferPtr)
{
    uint64_t tResult=0;
    int64_t tShift=0;
    
    while(1)
    {
        uint8_t tByte=*inBufferPtr;
        inBufferPtr++;
        
        if (tByte < 0x80)
        {
            tResult += (uint64_t)tByte << tShift;
            break;
        }
        
        tResult += (tByte & 0x7f) << tShift;
        tShift += 7;
    }
    
    if (outBufferPtr!=NULL)
        *outBufferPtr=inBufferPtr;
    
    return tResult;
}

int64_t DWRF_readLEB128(uint8_t * inBufferPtr,uint8_t ** outBufferPtr)
{
    int64_t tResult=0;
    int64_t tShift=0;
    
    while(1)
    {
        uint8_t tByte=*inBufferPtr;
        inBufferPtr++;
        
        if (tByte < 0x80)
        {
            if (tByte & 0x40)
                tResult -= (0x80 - tByte) << tShift;
            else
                tResult += (tByte & 0x3f) << tShift;

            break;
        }
    
        tResult += (tByte & 0x7f) << tShift;
        tShift += 7;
    }
    
    if (outBufferPtr!=NULL)
        *outBufferPtr=inBufferPtr;
    
    return tResult;
}
