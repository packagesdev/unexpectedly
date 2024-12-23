/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIdSYMHunter.h"

#import "CUIdSYMBundlesManager.h"

NSString * const CUIdSYMHunterHuntDidFinishNotification=@"CUIdSYMHunterHuntDidFinishNotification";

@interface  CUIdSYMHunter ()
{
    NSMutableSet * _runningQueries;
    
    NSMutableSet * _huntingBundleUUIDs;
    
    NSMutableDictionary * _registry;
    
    NSLock * _lock;
}

// Notifications

- (void)metadataQueryDidFinishGathering:(NSNotification *)inNotification;

@end

@implementation CUIdSYMHunter

+ (CUIdSYMHunter *)sharedHunter
{
    static CUIdSYMHunter * sHunter=nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sHunter=[CUIdSYMHunter new];
        
    });
    
    return sHunter;
}

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _runningQueries=[NSMutableSet set];
        
        _huntingBundleUUIDs=[NSMutableSet set];
        
        _registry=[NSMutableDictionary dictionary];
        
        _lock=[NSLock new];
    }
    
    return self;
}

#pragma mark -

- (NSSet *)huntingBundleUUIDs
{
    NSSet * tSet=nil;
    
    [_lock lock];
    
    tSet=[_huntingBundleUUIDs copy];
    
    [_lock unlock];
    
    return tSet;
}

#pragma mark -

- (void)huntBundleWithUUIDs:(NSSet *)inBundleUUIDs
{
    // Avoid looking for the same dSYM UUID multiple times at once
    
    NSMutableSet * tMutableSet=[inBundleUUIDs mutableCopy];

    [_lock lock];
    
    [tMutableSet minusSet:_huntingBundleUUIDs];
    
    [_lock unlock];
    
    if (tMutableSet.count==0)
        return;

    NSMetadataQuery * tMetadataQuery=[NSMetadataQuery new];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(metadataQueryDidFinishGathering:)
                                               name:NSMetadataQueryDidFinishGatheringNotification
                                             object:tMetadataQuery];
    
    // Look for dSYM with filtered UUIDs
    
    NSArray * tArray=[tMutableSet.allObjects WB_arrayByMappingObjectsUsingBlock:^NSString *(NSString * bUUID, NSUInteger bIndex) {
        
        return [NSString stringWithFormat:@"(com_apple_xcode_dsym_uuids == '%@')",bUUID];
        
    }];
    
    NSString * tPredicateString=[tArray componentsJoinedByString:@" OR "];
    
    tMetadataQuery.predicate=[NSPredicate predicateWithFormat:tPredicateString];
    tMetadataQuery.searchScopes=@[NSMetadataQueryLocalComputerScope];
    
    [_lock lock];
    
    [_runningQueries addObject:tMetadataQuery];
    
    [_huntingBundleUUIDs unionSet:tMutableSet];
    
    _registry[[NSValue valueWithNonretainedObject:tMetadataQuery]]=tMutableSet;
    
    [_lock unlock];
    
    [tMetadataQuery startQuery];
}

#pragma mark - Notifications

- (void)metadataQueryDidFinishGathering:(NSNotification *)inNotification
{
    NSMetadataQuery * tMetadataQuery=(NSMetadataQuery *)inNotification.object;
    
    [tMetadataQuery stopQuery];
    
    NSValue * tKey=[NSValue valueWithNonretainedObject:tMetadataQuery];
    
    [_lock lock];
    
    NSSet * tSet=_registry[tKey];
    
    [_huntingBundleUUIDs minusSet:tSet];
    
    [_registry removeObjectForKey:tKey];
    
    [_runningQueries removeObject:tMetadataQuery];
    
    [_lock unlock];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [tMetadataQuery enumerateResultsUsingBlock:^(id bResult, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if ([bResult isKindOfClass:[NSMetadataItem class]]==YES)
            {
                NSMetadataItem * tMetaDataItem=(NSMetadataItem *)bResult;
                
                //NSLog(@"%@",[tMetaDataItem valuesForAttributes:@[NSMetadataItemPathKey,@"com_apple_xcode_dsym_uuids",@"com_apple_xcode_dsym_paths",@"kMDItemFSName"]]);
                
                NSString * tdSYMPath=[tMetaDataItem valueForAttribute:NSMetadataItemPathKey];
                
                if (tdSYMPath!=nil)
                {
                    CUIdSYMBundlesManager * tBundlesManager=[CUIdSYMBundlesManager sharedManager];
                    
                    CUIdSYMBundle * tBundle=[[CUIdSYMBundle alloc] initWithPath:tdSYMPath];
                    
                    if (tBundle.isDSYMBundle==NO)
                        return;
                    
                    if ([tBundlesManager containsBundle:tBundle]==YES)
                        return;
                    
                    [tBundlesManager addBundles:@[tBundle]];
                }
            }
        }];
        
        // Post Notification
        
        [NSNotificationCenter.defaultCenter postNotificationName:CUIdSYMHunterHuntDidFinishNotification object:nil];
    });
}



@end
