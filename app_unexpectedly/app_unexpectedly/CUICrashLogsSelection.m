/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICrashLogsSelection.h"

NSString * const CUICrashLogsSelectionDidChangeNotification=@"CUICrashLogsSelectionDidChangeNotification";

@interface CUICrashLogsSelection ()

@property CUICrashLogsSource * source;

@property NSArray * crashLogs;

@end

@implementation CUICrashLogsSelection

+ (CUICrashLogsSelection *)sharedSelection
{
    static CUICrashLogsSelection * sSharedSelection=nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sSharedSelection=[CUICrashLogsSelection new];
    });
    
    return sSharedSelection;
}

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _crashLogs=@[];
    }
    
    return self;
}

#pragma mark - NSObject

- (NSUInteger)hash
{
    return self.source.name.hash;
}

- (BOOL)isEqual:(CUICrashLogsSelection *)inOtherSelection
{
    return (self.source==inOtherSelection.source && [self.crashLogs isEqualToArray:inOtherSelection.crashLogs]==YES);
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    CUICrashLogsSelection * nSelection=[CUICrashLogsSelection new];
    
    nSelection.source=self.source;
    
    nSelection.crashLogs=[self.crashLogs copy];
    
    return nSelection;
}

#pragma mark -

- (void)setSource:(CUICrashLogsSource *)inSource crashLogs:(NSArray *)inCrashLogs
{
    if (_source==inSource && _crashLogs==inCrashLogs)
        return;
    
    _source=inSource;
    _crashLogs=inCrashLogs;
    
    [NSNotificationCenter.defaultCenter postNotificationName:CUICrashLogsSelectionDidChangeNotification object:self];
}

@end
