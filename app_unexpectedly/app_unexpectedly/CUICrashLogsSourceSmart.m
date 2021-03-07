/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICrashLogsSourceSmart.h"

#import "CUICrashLogsSourceAll.h"

#define SMARTSOURCE_VERSION_1       1

NSString * const CUICrashLogsSourcesSmartVersionKey=@"version";

NSString * const CUICrashLogsSourcesSmartPredicateKey=@"predicate";

@interface CUICrashLogsSourceSmart ()
{
    NSArray * _filteredCrashLogs;
}

    @property NSUInteger version;

- (void)sourceAllDidUpdateSource:(NSNotification *)inNotification;

@end

@implementation CUICrashLogsSourceSmart

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sourceAllDidUpdateSource:) name:CUICrashLogsSourceDidUpdateSourceNotification object:[CUICrashLogsSourceAll crashLogsSourceAll]];
        
        self.name=NSLocalizedString(@"Untitled source", @"");
        
        _version=SMARTSOURCE_VERSION_1;
        
        _predicate=[NSPredicate predicateWithFormat:@"processName = \"MyApplication\""];
    }
    
    return self;
}

- (instancetype)initWithRepresentation:(NSDictionary *)inRepresentation
{
    self=[super initWithRepresentation:inRepresentation];
    
    if (self!=nil)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sourceAllDidUpdateSource:) name:CUICrashLogsSourceDidUpdateSourceNotification object:[CUICrashLogsSourceAll crashLogsSourceAll]];
        
        NSNumber * tNumber=inRepresentation[CUICrashLogsSourcesSmartVersionKey];
        
        if (tNumber!=nil)
        {
            if ([tNumber isKindOfClass:[NSNumber class]]==NO)
                return nil;
            
            _version=tNumber.unsignedIntegerValue;
        }
        else
        {
            _version=SMARTSOURCE_VERSION_1;
        }
        
        NSString * tString=inRepresentation[CUICrashLogsSourcesSmartPredicateKey];
        
        if ([tString isKindOfClass:[NSString class]]==NO)
            return nil;
        
        _predicate=[NSPredicate predicateWithFormat:tString];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -

- (CUICrashLogsSourceType)type
{
    return CUICrashLogsSourceTypeSmart;
}

- (NSArray *)crashLogs
{
    return _filteredCrashLogs;
}

- (void)setPredicate:(NSPredicate *)inPredicate
{
    if (_predicate==inPredicate)
        return;
    
    _predicate=inPredicate;
    
    [self sourceAllDidUpdateSource:[NSNotification notificationWithName:CUICrashLogsSourceDidUpdateSourceNotification object:[CUICrashLogsSourceAll crashLogsSourceAll]]];
}

- (NSDictionary *)representation
{
    NSMutableDictionary * tMutableDictionary=[[super representation] mutableCopy];
    
    tMutableDictionary[CUICrashLogsSourcesSmartVersionKey]=@(self.version);
    
    tMutableDictionary[CUICrashLogsSourcesSmartPredicateKey]=self.predicate.predicateFormat;
    
    return [tMutableDictionary copy];
}


#pragma mark - Notifications

- (void)sourceAllDidUpdateSource:(NSNotification *)inNotification
{
    _filteredCrashLogs=[[CUICrashLogsSourceAll crashLogsSourceAll].crashLogs filteredArrayUsingPredicate:self.predicate];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CUICrashLogsSourceDidUpdateSourceNotification object:self];
}

@end
