/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICrashLogsSource.h"

NSString * const CUICrashLogsSourceTypeKey=@"type";

NSString * const CUICrashLogsSourceNameKey=@"name";

NSString * const CUICrashLogsSourceDescription=@"description";


NSString * const CUICrashLogsSourceDidAddSourcesNotification=@"CUICrashLogsSourcesDidAddSourcesNotification";

NSString * const CUICrashLogsSourceDidUpdateSourceNotification=@"CUICrashLogsSourceDidUpdateSourceNotification";

NSString * const CUICrashLogsSourceDidRemoveSourcesNotification=@"CUICrashLogsSourceDidRemoveSourcesNotification";

@implementation CUICrashLogsSource

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _name=@"";
        
        _sourceDescription=@"";
    }
    
    return self;
}

- (instancetype)initWithRepresentation:(NSDictionary *)inRepresentation
{
    if ([inRepresentation isKindOfClass:[NSDictionary class]]==NO)
        return nil;
    
    self=[super init];
    
    if (self!=nil)
    {
        NSString * tString=inRepresentation[CUICrashLogsSourceNameKey];
        
        if (tString!=nil && [tString isKindOfClass:[NSString class]]==NO)
            return nil;
        
        _name=(tString!=nil) ? [tString copy] : @"";
        
        tString=inRepresentation[CUICrashLogsSourceDescription];
        
        if (tString!=nil && [tString isKindOfClass:[NSString class]]==NO)
            return nil;
        
        _sourceDescription=(tString!=nil) ? [tString copy] : @"";
    }
    
    return self;
}

#pragma mark -

- (CUICrashLogsSourceType)type
{
    return CUICrashLogsSourceTypeUnknown;
}

- (NSArray *)crashLogs
{
    return nil;
}

- (NSDictionary *)representation
{
    return @{
             CUICrashLogsSourceTypeKey:@(self.type),
             CUICrashLogsSourceNameKey:self.name,
             CUICrashLogsSourceDescription:self.sourceDescription
             };
}

#pragma mark -

- (BOOL)containsCrashLogForFileAtPath:(NSString *)inPath
{
    return ([self crashLogForFileAtPath:inPath]!=nil);
}

- (id)crashLogForFileAtPath:(NSString *)inPath
{
    for(CUIRawCrashLog * tCrashLog in self.crashLogs)
    {
        NSString * tCrashLogFilePath=tCrashLog.crashLogFilePath;
        
        if (tCrashLogFilePath==nil)
            continue;
        
        if ([tCrashLogFilePath isEqualToString:inPath]==YES)
            return tCrashLog;
    }
    
    return nil;
}

@end
