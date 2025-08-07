/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICrashLogsSourceAll.h"

@interface CUICrashLogsSourceAll ()
{
    NSMutableSet * _allSources;
    
    NSArray * _crashLogs;
}

// Notifications

- (void)crashLogsSourceDidAddSources:(NSNotification *)inNotification;

- (void)crashLogsSourceDidUpdateSource:(NSNotification *)inNotification;

- (void)crashLogsSourceDidRemoveSources:(NSNotification *)inNotification;

@end

@implementation CUICrashLogsSourceAll

+ (CUICrashLogsSourceAll *)crashLogsSourceAll
{
    static CUICrashLogsSourceAll * sCrashLogsSourceAll=nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sCrashLogsSourceAll=[CUICrashLogsSourceAll new];
    });
    
    return sCrashLogsSourceAll;
}

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _allSources=[NSMutableSet set];
        
        _crashLogs=@[];
        
        // Register for notifications
        
        NSNotificationCenter * tNotificationCenter=NSNotificationCenter.defaultCenter;
        
        [tNotificationCenter addObserver:self selector:@selector(crashLogsSourceDidAddSources:) name:CUICrashLogsSourceDidAddSourcesNotification object:nil];
        [tNotificationCenter addObserver:self selector:@selector(crashLogsSourceDidUpdateSource:) name:CUICrashLogsSourceDidUpdateSourceNotification object:nil];
        [tNotificationCenter addObserver:self selector:@selector(crashLogsSourceDidRemoveSources:) name:CUICrashLogsSourceDidRemoveSourcesNotification object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

#pragma mark -

- (CUICrashLogsSourceType)type
{
    return CUICrashLogsSourceTypeAll;
}

- (NSString *)name
{
    return NSLocalizedString(@"All",@"");
}

- (NSString *)sourceDescription
{
    return NSLocalizedString(@"All reports from all sources", @"");
}

- (NSArray *)crashLogs
{
    if (_crashLogs==nil)
    {
        NSMutableArray * tMutableArray=[NSMutableArray array];
        
        [_allSources enumerateObjectsUsingBlock:^(CUICrashLogsSource * bSource, BOOL * bOutStop) {
            
            NSArray * tLogs=bSource.crashLogs;
            
            [tMutableArray addObjectsFromArray:tLogs];
            
        }];
        
        _crashLogs=[tMutableArray copy];
    }
    
    return _crashLogs;
}

#pragma mark -

- (void)refresh
{
    _crashLogs=nil;
    
    [NSNotificationCenter.defaultCenter postNotificationName:CUICrashLogsSourceDidUpdateSourceNotification object:self];
}



#pragma mark - Notifications

- (void)crashLogsSourceDidAddSources:(NSNotification *)inNotification
{
    NSArray * tSources=inNotification.object;
    
    if ([tSources isKindOfClass:[NSArray class]]==NO)
        return;
    
    __block NSUInteger tNewCrashLogs=0;
    
    [tSources enumerateObjectsUsingBlock:^(CUICrashLogsSource * bSource, NSUInteger bIndex, BOOL * bOutStop) {
       
        if ([bSource isKindOfClass:[CUICrashLogsSource class]]==NO)
            return;
        
        if (bSource.type==CUICrashLogsSourceTypeSmart)
            return;
        
        [self->_allSources addObject:bSource];
        
        tNewCrashLogs+=bSource.crashLogs.count;
        
    }];
    
    if (tNewCrashLogs>0)
        [self refresh];
}

- (void)crashLogsSourceDidUpdateSource:(NSNotification *)inNotification
{
    CUICrashLogsSource * tSource=(CUICrashLogsSource *)inNotification.object;
    
    switch(tSource.type)
    {
        case CUICrashLogsSourceTypeAll:
        case CUICrashLogsSourceTypeSmart:
            
            return;
            
        default:
            
            break;
    }
    
    if ([tSource isKindOfClass:[CUICrashLogsSource class]]==NO)
        return;
    
    if (tSource.type==CUICrashLogsSourceTypeSmart)
        return;
    
    if ([_allSources containsObject:tSource]==NO)
        return;
    
     [self refresh];
}

- (void)crashLogsSourceDidRemoveSources:(NSNotification *)inNotification
{
    NSArray * tSources=inNotification.object;
    
    if ([tSources isKindOfClass:[NSArray class]]==NO)
        return;
    
    __block NSUInteger tRemovedCrashLogs=0;
    
    [tSources enumerateObjectsUsingBlock:^(CUICrashLogsSource * bSource, NSUInteger bIndex, BOOL * bOutStop) {
        
        if ([bSource isKindOfClass:[CUICrashLogsSource class]]==NO)
            return;
        
        if (bSource.type==CUICrashLogsSourceTypeSmart)
            return;
        
        [self->_allSources removeObject:bSource];
        
        tRemovedCrashLogs+=bSource.crashLogs.count;
        
    }];
    
    if (tRemovedCrashLogs>0)
        [self refresh];
}

@end
