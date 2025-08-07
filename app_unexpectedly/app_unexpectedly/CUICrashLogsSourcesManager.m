/*
 Copyright (c) 2020-2022, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICrashLogsSourcesManager.h"

#import "NSArray+WBExtensions.h"

#import "CUICrashLogsSourceSeparator.h"
#import "CUICrashLogsSourceFile.h"
#import "CUICrashLogsSourceDirectory.h"
#import "CUICrashLogsSourceStandardDirectory.h"
#import "CUICrashLogsSourceSmart.h"
#import "CUICrashLogsSourceAll.h"
#import "CUICrashLogsSourceToday.h"

NSString * const CUIDefaultsSourcesManagerCustomSourcesListKey=@"sources.custom";


NSString * const CUICrashLogsSourcesManagerSourcesDidChangeNotification=@"CUICrashLogsSourcesManagerSourcesDidChangeNotification";

@interface CUICrashLogsSourcesManager ()
{
    NSMutableArray<CUICrashLogsSource *> * _sources;
    
    NSUInteger _customSourcesCount;
}

@end

@implementation CUICrashLogsSourcesManager

+ (CUICrashLogsSourcesManager *)sharedManager
{
    static CUICrashLogsSourcesManager * sSourcesManager=nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{CUIDefaultsSourcesManagerCustomSourcesListKey:@[]}];
        
        sSourcesManager=[CUICrashLogsSourcesManager new];
    });
    
    return sSourcesManager;
}

#pragma mark -

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _sources=[NSMutableArray array];
        
        CUICrashLogsSourceAll * tSourceAll=[CUICrashLogsSourceAll crashLogsSourceAll];
        
        if (tSourceAll==nil)
        {
        }
        else
        {
            [_sources addObject:tSourceAll];
        }
        
        CUICrashLogsSourceToday * tSourceToday=[CUICrashLogsSourceToday new];
        
        if (tSourceToday==nil)
        {
        }
        else
        {
            [_sources addObject:tSourceToday];
        }
        
        
        NSError * tError=nil;
        
        // Current User Crash Logs
        
        CUICrashLogsSourceStandardDirectory * tUserCrashLogsSource=[CUICrashLogsSourceStandardDirectory sourceDiagnosticReportsInDomain:NSUserDomainMask error:&tError];
        
        if (tUserCrashLogsSource==nil)
        {
        }
        else
        {
            [_sources addObject:tUserCrashLogsSource];
        }
        
        // System User Crash Logs
        
        CUICrashLogsSourceStandardDirectory * tSystemCrashLogsSource=[CUICrashLogsSourceStandardDirectory sourceDiagnosticReportsInDomain:NSLocalDomainMask error:&tError];
        
        if (tSystemCrashLogsSource==nil)
        {
        }
        else
        {
            [_sources addObject:tSystemCrashLogsSource];
        }
        
        // Custom Sources
        
        NSArray * tCustomSourcesRepresentations=[[NSUserDefaults standardUserDefaults] objectForKey:CUIDefaultsSourcesManagerCustomSourcesListKey];
        
        NSArray * tCustomSources=[tCustomSourcesRepresentations WB_arrayByMappingObjectsLenientlyUsingBlock:^id(NSDictionary * bRepresentation, NSUInteger bIndex) {
           
            NSNumber * tNumber=bRepresentation[CUICrashLogsSourceTypeKey];
            
            if ([tNumber isKindOfClass:NSNumber.class]==NO)
                return nil;
            
            CUICrashLogsSourceType tType=[tNumber unsignedIntegerValue];
            
            switch(tType)
            {
                case CUICrashLogsSourceTypeDirectory:
                    
                    return [[CUICrashLogsSourceDirectory alloc] initWithRepresentation:bRepresentation];
                    
                case CUICrashLogsSourceTypeFile:
                    
                    return [[CUICrashLogsSourceFile alloc] initWithRepresentation:bRepresentation];
                    
                case CUICrashLogsSourceTypeSmart:
                    
                    return [[CUICrashLogsSourceSmart alloc] initWithRepresentation:bRepresentation];
                    
                default:
                    
                    return nil;
            }
        }];
        
        _customSourcesCount=tCustomSources.count;
        
        NSMutableArray * tMutableArray=[NSMutableArray arrayWithObjects:tUserCrashLogsSource,tSystemCrashLogsSource, nil];
        
        if (_customSourcesCount>0)
        {
            [_sources addObject:[CUICrashLogsSourceSeparator separator]];
            
            [_sources addObjectsFromArray:tCustomSources];
            
            [tMutableArray addObjectsFromArray:tCustomSources];
        }
        
        [NSNotificationCenter.defaultCenter postNotificationName:CUICrashLogsSourceDidAddSourcesNotification object:tMutableArray];
    }
    
    return self;
}

#pragma mark -

- (NSArray *)allSources
{
    return _sources;
}

#pragma mark -

- (NSArray *)sourcesOfType:(CUICrashLogsSourceType)inType
{
    return [_sources WB_filteredArrayUsingBlock:^BOOL(CUICrashLogsSource * bSource, NSUInteger bIndex) {
        
        return (bSource.type==inType);
    }];
}

- (NSArray *)sourcesOfTypes:(NSSet *)inTypes
{
    return [_sources WB_filteredArrayUsingBlock:^BOOL(CUICrashLogsSource * bSource, NSUInteger bIndex) {
        
        return [inTypes containsObject:@(bSource.type)];
    }];
}

#pragma mark -

- (void)synchronizeDefaults
{
    NSArray * tCustomSourcesRepresentations=@[];
    
    if (_customSourcesCount>0)
    {
        NSArray * tCustomSources=[_sources subarrayWithRange:NSMakeRange(_sources.count-_customSourcesCount, _customSourcesCount)];
    
            tCustomSourcesRepresentations=[tCustomSources WB_arrayByMappingObjectsLenientlyUsingBlock:^id(CUICrashLogsSource * bSource, NSUInteger bIndex) {
        
            return [bSource representation];
            }];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:tCustomSourcesRepresentations forKey:CUIDefaultsSourcesManagerCustomSourcesListKey];
}

- (void)addSources:(NSArray *)inSources
{
    NSArray * tPossibleSources=[inSources WB_filteredArrayUsingBlock:^BOOL(CUICrashLogsSource * bSource, NSUInteger bIndex) {
        
        switch(bSource.type)
        {
            case CUICrashLogsSourceTypeDirectory:
            case CUICrashLogsSourceTypeFile:
            case CUICrashLogsSourceTypeSmart:
                
                return YES;
                
            default:
                
                return NO;
        }
        
    }];
    
    if (tPossibleSources.count>0)
    {
        if (_customSourcesCount==0)
            [_sources addObject:[CUICrashLogsSourceSeparator separator]];

        
        [_sources addObjectsFromArray:tPossibleSources];
        
        _customSourcesCount+=tPossibleSources.count;
        
        NSNotificationCenter * tNotificationCenter=NSNotificationCenter.defaultCenter;
        
        [tNotificationCenter postNotificationName:CUICrashLogsSourceDidAddSourcesNotification object:tPossibleSources];
        
        [tNotificationCenter postNotificationName:CUICrashLogsSourcesManagerSourcesDidChangeNotification object:self];
        
        [self synchronizeDefaults];
    }
}

- (void)moveSourcesAtIndexes:(NSIndexSet *)inOldIndexes toIndexes:(NSIndexSet *)inNewIndexes
{
    NSArray * tObjects=[_sources objectsAtIndexes:inOldIndexes];
    
    [_sources removeObjectsAtIndexes:inOldIndexes];
    
    [_sources insertObjects:tObjects atIndexes:inNewIndexes];
}

- (void)removeSources:(NSArray *)inSources
{
    NSArray * tPossibleSources=[inSources WB_filteredArrayUsingBlock:^BOOL(CUICrashLogsSource * bSource, NSUInteger bIndex) {
        
        switch(bSource.type)
        {
            case CUICrashLogsSourceTypeDirectory:
            case CUICrashLogsSourceTypeFile:
            case CUICrashLogsSourceTypeSmart:
                
                return YES;
                
            default:
                
                return NO;
        }
        
    }];
    
    if (tPossibleSources.count>0)
    {
        [_sources removeObjectsInArray:tPossibleSources];
        
        _customSourcesCount-=tPossibleSources.count;
        
        if (_customSourcesCount==0)
            [_sources removeObjectIdenticalTo:[CUICrashLogsSourceSeparator separator]];
        
        NSNotificationCenter * tNotificationCenter=NSNotificationCenter.defaultCenter;
        
        [tNotificationCenter postNotificationName:CUICrashLogsSourceDidRemoveSourcesNotification object:tPossibleSources];
        
        [tNotificationCenter postNotificationName:CUICrashLogsSourcesManagerSourcesDidChangeNotification object:self];
        
        [self synchronizeDefaults];
    }
}

- (void)sortCustomSourcesByName
{
    NSRange tCustomSourcesRange=NSMakeRange(5, _customSourcesCount);
    
    NSMutableArray * tSortableArray=[[_sources objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:tCustomSourcesRange]] mutableCopy];
    
    [tSortableArray sortUsingComparator:^NSComparisonResult(CUICrashLogsSource * bSource1, CUICrashLogsSource * bSource2) {
        
        return [bSource1.name caseInsensitiveCompare:bSource2.name];
    }];
    
    [_sources removeObjectsInRange:tCustomSourcesRange];
    
    [_sources addObjectsFromArray:tSortableArray];
    
    NSNotificationCenter * tNotificationCenter=NSNotificationCenter.defaultCenter;
    
    [tNotificationCenter postNotificationName:CUICrashLogsSourcesManagerSourcesDidChangeNotification object:self];
    
    [self synchronizeDefaults];
}

@end
