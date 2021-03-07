/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUISymbolicationManager.h"

#import "CUISymbolicationDataCache.h"

#import "CUIdSYMBundlesManager.h"

@interface CUISymbolicationManager ()
{
    CUISymbolicationDataCache * _cache;
    
    CUIdSYMBundlesManager * _bundlesManager;
}

@end

@implementation CUISymbolicationManager

+ (CUISymbolicationManager *)sharedSymbolicationManager
{
    static CUISymbolicationManager *sSymbolicationManager=nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sSymbolicationManager=[CUISymbolicationManager new];
        
    });
    
    return sSymbolicationManager;
}

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _cache=[CUISymbolicationDataCache sharedCache];
        
        _bundlesManager=[CUIdSYMBundlesManager sharedManager];
    }
    
    return self;
}

#pragma mark -

- (void)lookUpSymbolicationDataForMachineInstructionAddress:(NSUInteger)inAddress binaryUUID:(NSString *)inBinaryUUID completionHandler:(void (^)(CUISymbolicationDataLookUpResult bLookUpResult,CUISymbolicationData * bSymbolicationData))handler;
{
    CUISymbolicationData * tData=[_cache symbolicationDataForAddress:inAddress binary:inBinaryUUID];
    
    if (tData!=nil)
    {
        if (handler!=nil)
            handler(CUISymbolicationDataLookUpResultFoundInCache,tData);
        
        return;
    }
    
    CUIdSYMBundle * tBundle=[_bundlesManager bundleForBinaryUUID:inBinaryUUID];
    
    if (tBundle==nil)
    {
        if (handler!=nil)
            handler(CUISymbolicationDataLookUpResultNotFound,tData);
        
        return;
    }
    
    [tBundle lookUpSymbolicationDataForMachineInstructionAddress:inAddress binaryUUID:inBinaryUUID completionHandler:handler];
}

@end

