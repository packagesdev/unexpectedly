/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIdSYMBundlesManager.h"

NSString * const CUIdSYMBundlesManagerDidAddBundlesNotification=@"CUIdSYMBundlesManagerDidAddBundlesNotification";

NSString * const CUIdSYMBundlesManagerDidRemoveBundlesNotification=@"CUIdSYMBundlesManagerDidRemoveBundlesNotification";

NSString * const CUIdSYMBundlesManagerContentsKey=@"dSYMLibrary.contents";

@interface CUIdSYMBundlesManager ()
{
    NSMutableSet * _bundlesSet;
    
    NSMutableDictionary * _bundlesRegistry;
}

- (BOOL)_addBundles:(NSArray *)inBundles andNotify:(BOOL)inNotify;

- (void)_synchronizeDefaults;

@end

@implementation CUIdSYMBundlesManager

+ (CUIdSYMBundlesManager *)sharedManager
{
    static CUIdSYMBundlesManager * sdSYMBundlesManager=nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sdSYMBundlesManager=[CUIdSYMBundlesManager new];
        
    });
    
    return sdSYMBundlesManager;
}

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _bundlesRegistry=[NSMutableDictionary dictionary];
        
        _bundlesSet=[NSMutableSet set];
        
        NSUserDefaults * tDefaults=[NSUserDefaults standardUserDefaults];
        
        NSArray * tArray=[tDefaults arrayForKey:CUIdSYMBundlesManagerContentsKey];
        
        if (tArray.count>0)
        {
            NSArray * tBundles=[tArray WB_arrayByMappingObjectsLenientlyUsingBlock:^CUIdSYMBundle *(NSString * bBundlePath, NSUInteger bIndex) {
                
                return [[CUIdSYMBundle alloc] initWithPath:bBundlePath];
            }];
            
            [self _addBundles:tBundles andNotify:NO];
        }
    }
    
    return self;
}

#pragma mark -

- (NSSet *)bundlesSet
{
    return _bundlesSet;
}

#pragma mark -

- (void)_synchronizeDefaults
{
    NSUserDefaults * tDefaults=[NSUserDefaults standardUserDefaults];
    
    NSMutableArray * tMutableArray=[NSMutableArray array];
    
    [_bundlesSet enumerateObjectsUsingBlock:^(CUIdSYMBundle * bBundle, BOOL * bOutStop) {
        
        [tMutableArray addObject:bBundle.bundlePath];
    }];
    
    [tDefaults setValue:tMutableArray forKey:CUIdSYMBundlesManagerContentsKey];
}

#pragma mark -

- (BOOL)containsBundle:(CUIdSYMBundle *)inBundle
{
    if (inBundle==nil)
        return NO;
    
    for(CUIdSYMBundle * tBundle in _bundlesSet)
    {
        if ([tBundle.bundlePath caseInsensitiveCompare:inBundle.bundlePath]==NSOrderedSame)
            return YES;
    }
    
    return NO;
}

- (BOOL)addBundle:(CUIdSYMBundle *)inBundle
{
    if (inBundle==nil)
        return NO;

    return [self addBundles:@[inBundle]];
}

- (BOOL)addBundles:(NSArray *)inBundles
{
    return [self _addBundles:inBundles andNotify:YES];
}

- (BOOL)_addBundles:(NSArray *)inBundles andNotify:(BOOL)inNotify
{
    if (inBundles.count==0)
        return NO;
    
    NSMutableArray * tAllBinaryUUIDs=[NSMutableArray array];
    
    for(CUIdSYMBundle * tBundle in inBundles)
    {
        NSArray * tBinaryUUIDs=[tBundle binaryUUIDs];
        
        if (tBinaryUUIDs.count==0)
            return NO;
        
        
        
        NSMutableArray * tAddedBinaryUUIds=[NSMutableArray array];
        
        for(NSString * tBinaryUUID in tBinaryUUIDs)
        {
            if (_bundlesRegistry[tBinaryUUID]!=nil)
                continue;
            
            _bundlesRegistry[tBinaryUUID]=tBundle;
            
            [tAddedBinaryUUIds addObject:tBinaryUUID];
        }
        
        if (tAddedBinaryUUIds.count>0)
        {
            [tAllBinaryUUIDs addObjectsFromArray:tAddedBinaryUUIds];
            
            [_bundlesSet addObject:tBundle];
        }
    }
    
    // Post Notification?
        
    if (inNotify==YES)
        [[NSNotificationCenter defaultCenter] postNotificationName:CUIdSYMBundlesManagerDidAddBundlesNotification object:tAllBinaryUUIDs];
    
    [self _synchronizeDefaults];
    
    return YES;
}

- (void)removeBundle:(CUIdSYMBundle *)inBundle
{
    if (inBundle==nil)
        return;
    
    [self removeBundles:@[inBundle]];
}

- (void)removeBundles:(NSArray *)inBundles
{
    if (inBundles.count==0)
        return;
    
    NSMutableArray * tAllBinaryUUIDs=[NSMutableArray array];
    
    for(CUIdSYMBundle * tBundle in inBundles)
    {
        NSArray * tBinaryUUIDs=tBundle.binaryUUIDs;
        
        [tAllBinaryUUIDs addObjectsFromArray:tBinaryUUIDs];
    }
    
    [_bundlesRegistry removeObjectsForKeys:tAllBinaryUUIDs];
    
    [_bundlesSet minusSet:[NSSet setWithArray:inBundles]];
    
    // Post Notification
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CUIdSYMBundlesManagerDidRemoveBundlesNotification object:tAllBinaryUUIDs];
    
    [self _synchronizeDefaults];
}

#pragma mark -

- (CUIdSYMBundle *)bundleForBinaryUUID:(NSString *)inBinaryUUID
{
    if (inBinaryUUID==nil)
        return nil;
    
    return _bundlesRegistry[inBinaryUUID];
}

@end
