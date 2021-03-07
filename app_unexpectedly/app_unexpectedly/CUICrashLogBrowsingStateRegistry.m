/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICrashLogBrowsingStateRegistry.h"

@interface CUICrashLogBrowsingStateRegistry ()
{
    NSMutableDictionary * _registry;
}

@end

@implementation CUICrashLogBrowsingStateRegistry

+ (CUICrashLogBrowsingStateRegistry *)sharedRegistry
{
    static CUICrashLogBrowsingStateRegistry * sRegistry=nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sRegistry=[CUICrashLogBrowsingStateRegistry new];
    });
    
    return sRegistry;
}

#pragma mark -

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _registry=[NSMutableDictionary dictionary];
    }
    
    return self;
}

#pragma mark -

- (CUICrashLogBrowsingState *)browsingStateForCrashLog:(CUICrashLog *)inCrashLog windowNumber:(NSInteger)inWindowNumber
{
    NSString * tPath=inCrashLog.crashLogFilePath;
    
    if (tPath==nil)
        return nil;
    
    NSMutableDictionary * tMutableDictionary=_registry[@(inWindowNumber)];
    
    if (tMutableDictionary==nil)
    {
        tMutableDictionary=[NSMutableDictionary dictionary];
        
        _registry[@(inWindowNumber)]=tMutableDictionary;
    }
    
    CUICrashLogBrowsingState * tBrowsingState=tMutableDictionary[tPath];
    
    if (tBrowsingState==nil)
    {
        tBrowsingState=[CUICrashLogBrowsingState new];
        
        tMutableDictionary[tPath]=tBrowsingState;
    }
    
    return tBrowsingState;
}

- (void)setBrowsingState:(CUICrashLogBrowsingState *)inBrowsingState forCrashLog:(CUICrashLog *)inCrashLog windowNumber:(NSInteger)inWindowNumber
{
    NSString * tPath=inCrashLog.crashLogFilePath;
    
    if (inBrowsingState==nil || tPath==nil)
        return;
    
    NSMutableDictionary * tMutableDictionary=_registry[@(inWindowNumber)];
    
    if (tMutableDictionary==nil)
    {
        tMutableDictionary=[NSMutableDictionary dictionary];
        
        if (tMutableDictionary==nil)
        {
            NSLog(@"Uh oh");
            return;
        }
        
        _registry[@(inWindowNumber)]=tMutableDictionary;
    }
    
    tMutableDictionary[tPath]=inBrowsingState;
}

- (void)removeBrowsingStateForCrashLog:(CUICrashLog *)inCrashLog windowNumber:(NSInteger)inWindowNumber
{
    NSString * tPath=inCrashLog.crashLogFilePath;
    
    if (tPath==nil)
        return;
    
    NSMutableDictionary * tMutableDictionary=_registry[@(inWindowNumber)];
    
    if (tMutableDictionary==nil)
        return;
    
    [tMutableDictionary removeObjectForKey:tPath];
}

@end
