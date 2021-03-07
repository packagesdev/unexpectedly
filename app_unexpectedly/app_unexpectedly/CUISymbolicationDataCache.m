/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUISymbolicationDataCache.h"

#include <pthread.h>

@interface CUISymbolicationDataCache ()
{
    NSCache * _cache;
    
    pthread_rwlock_t _readWriteLock;
}

@end

@implementation CUISymbolicationDataCache

+ (CUISymbolicationDataCache *)sharedCache
{
    static CUISymbolicationDataCache * sSymbolsCache=nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sSymbolsCache=[CUISymbolicationDataCache new];
        
    });
    
    return sSymbolsCache;
}

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        if (pthread_rwlock_init(&_readWriteLock, NULL)!=0)
        {
            NSLog(@"Unable to initialize read-write lock");
            
            
            return nil;
        }
        
        _cache=[NSCache new];
    }
    
    return self;
}

#pragma mark -

- (CUISymbolicationData *)symbolicationDataForAddress:(uint64_t)inAddress binary:(NSString *)inBinaryUUID
{
    if (inBinaryUUID==nil)
        return nil;
    
    NSCache * tAddressesCache=[_cache objectForKey:inBinaryUUID];
    
    if (tAddressesCache==nil)
        return nil;
    
    return [tAddressesCache objectForKey:@(inAddress)];
}

- (void)setSymbolicationData:(CUISymbolicationData *)inSymbolicationData forAddress:(uint64_t)inAddress binary:(NSString *)inBinaryUUID
{
    if (inSymbolicationData==nil || inBinaryUUID==nil)
        return;
    
    NSCache * tAddressesCache=[_cache objectForKey:inBinaryUUID];
    
    if (tAddressesCache==nil)
    {
        tAddressesCache=[NSCache new];
        
        if (tAddressesCache==nil)
            return;
        
        [_cache setObject:tAddressesCache forKey:inBinaryUUID];
    }
    
    [tAddressesCache setObject:inSymbolicationData forKey:@(inAddress)];
}

@end
