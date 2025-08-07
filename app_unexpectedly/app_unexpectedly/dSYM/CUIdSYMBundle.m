/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIdSYMBundle.h"

#import "MCHMachBinary.h"

#import "MCHUUIDLoadCommand.h"

#import "MCHSegmentLoadCommand.h"

#include <mach-o/loader.h>
#include <mach-o/fat.h>

#import "DWRFFileObject.h"

#import "CUISymbolicationDataCache.h"



@interface CUIdSYMBundle ()
{
    NSArray * _cachedBinaryUUIDs;
    
    NSDictionary<NSString *,MCHObjectFile *> * _machObjectFilesRegistry;
    
    NSMutableDictionary<NSString *,DWRFFileObject *> * _cachedWARFFileObjectsRegistry;
}

@property (nonatomic) NSString * displayName;

@property (nonatomic) NSString * displayVersion;

@property (nonatomic) MCHMachBinary * machBinary;

@property (nonatomic,copy) NSString * symbolsFilePath;

- (void)lookUpSymbolicationDataForMachineInstructionAddress:(NSUInteger)inAddress binaryUUID:(NSString *)inBinaryUUID queue:(dispatch_queue_t)inQueue completionHandler:(void (^)(CUISymbolicationDataLookUpResult bLookUpResult,CUISymbolicationData * bSymbolicationData))handler;

@end

@implementation CUIdSYMBundle

- (NSString *)displayName
{
    if (_displayName==nil)
    {
        _displayName=self.bundlePath.lastPathComponent;
    }
    
    return _displayName;
}

- (NSString *)displayVersion
{
    if (_displayVersion==nil)
    {
        NSString * tBundleShortVersionString=[self objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        
        if (tBundleShortVersionString==nil)
            tBundleShortVersionString=@"-";
        
        NSString * tBundleVersionString=[self objectForInfoDictionaryKey:@"CFBundleVersion"];
        if (tBundleVersionString==nil)
            tBundleVersionString=@"-";
        
         _displayVersion=[NSString stringWithFormat:NSLocalizedString(@"%@ (%@)",@""), tBundleShortVersionString, tBundleVersionString ];
    }
    
    return _displayVersion;
}

#pragma mark -

- (NSString *)symbolsFilePath
{
    NSString * tDWARFFolderPath=[self pathForResource:@"DWARF" ofType:nil];
    
    if (tDWARFFolderPath==nil)
        return nil;
    
    NSArray * tArray=[[NSFileManager defaultManager] contentsOfDirectoryAtPath:tDWARFFolderPath error:NULL];
    
    if (tArray.count!=1)
        return nil;
    
    return [tDWARFFolderPath stringByAppendingPathComponent:tArray.firstObject];
}

#pragma mark -

- (MCHMachBinary *)machBinary
{
    if (_machBinary==nil)
    {
        NSString * tPath=[self symbolsFilePath];
        
        _machBinary=[[MCHMachBinary alloc] initWithContentsOfFile:tPath];
        
        if (_machBinary==nil)
        {
            NSLog(@"Error unarchiving mach-o file at path: %@",tPath);
        }
    }
    
    return _machBinary;
}

- (BOOL)isDSYMBundle
{
    NSString * tPath=self.bundlePath;
    
    if ([tPath.pathExtension isEqualToString:@"dSYM"]==NO)
        return NO;
    
    NSString * tPackageType=[self objectForInfoDictionaryKey:@"CFBundlePackageType"];
    
    if ([tPackageType isKindOfClass:NSString.class]==NO)
        return NO;
    
    if ([tPackageType isEqualToString:@"dSYM"]==NO)
        return NO;
    
    NSString * tDWARFFilePath=[self symbolsFilePath];
    
    if (tDWARFFilePath==nil)
        return NO;
    
    // Check that this is a mach-o file
    
    NSFileHandle * tFileHandle= [NSFileHandle fileHandleForReadingAtPath:tDWARFFilePath];
    NSData * tData = [tFileHandle readDataOfLength:sizeof(uint32_t)];
    [tFileHandle closeFile];
    
    uint32_t tMagicHeader=0;
    
    [tData getBytes:&tMagicHeader length:sizeof(uint32_t)];
    
    switch(tMagicHeader)
    {
        case MH_MAGIC:
        case MH_CIGAM:
        case MH_MAGIC_64:
        case MH_CIGAM_64:
            
            return YES;
            
        case FAT_MAGIC:
        case FAT_CIGAM:
            
            return YES;
            
        default:
            
            break;
    }
    
    return NO;
}

- (NSArray *)binaryUUIDs
{
    if (_cachedBinaryUUIDs!=nil)
        return _cachedBinaryUUIDs;
    
    NSMutableArray * tMutableArray=[NSMutableArray array];
    NSMutableDictionary * tMutableDictionary=[NSMutableDictionary dictionary];
    
    MCHMachBinary * tBinary=self.machBinary;
    
    if (tBinary==nil)
        return nil;
    
    [[tBinary allObjectFiles] enumerateObjectsUsingBlock:^(MCHObjectFile * bObjectFile, NSUInteger bIndex, BOOL * bOutStop) {
        
        if (bObjectFile.fileType!=MH_DSYM)
            return;
        
        NSArray * tUUIDLoadCommands=[bObjectFile loadCommandsOfType:LC_UUID];
        
        MCHUUIDLoadCommand * tUUIDLoadCommand=tUUIDLoadCommands.firstObject;
        
        NSString * tUUIDString=tUUIDLoadCommand.uuid.UUIDString;
        
        if (tUUIDString!=nil)
        {
            [tMutableArray addObject:tUUIDString];
            
            tMutableDictionary[tUUIDString]=bObjectFile;
        }
    }];
    
    _cachedBinaryUUIDs=[tMutableArray copy];
    
    _machObjectFilesRegistry=[tMutableDictionary copy];
    
    return _cachedBinaryUUIDs;
}

#pragma mark -



- (void)lookUpSymbolicationDataForMachineInstructionAddress:(NSUInteger)inAddress binaryUUID:(NSString *)inBinaryUUID completionHandler:(void (^)(CUISymbolicationDataLookUpResult bLookUpResult,CUISymbolicationData * bSymbolicationData))handler;
{
    [self lookUpSymbolicationDataForMachineInstructionAddress:inAddress binaryUUID:inBinaryUUID queue:dispatch_get_main_queue() completionHandler:handler];
}

- (void)lookUpSymbolicationDataForMachineInstructionAddress:(NSUInteger)inAddress binaryUUID:(NSString *)inBinaryUUID queue:(dispatch_queue_t)inQueue completionHandler:(void (^)(CUISymbolicationDataLookUpResult bLookUpResult,CUISymbolicationData * bSymbolicationData))handler;
{
    if (handler==nil)
    {
        // A COMPLETER
        
        return;
    }
    
    if (inBinaryUUID==nil)
    {
        handler(CUISymbolicationDataLookUpResultError,nil);
        
        return;
    }

    // Try to find it as it was the first time
    
    if (_machObjectFilesRegistry==nil)
    {
        [self binaryUUIDs];
        
        if (_machObjectFilesRegistry.count==0)
        {
            handler(CUISymbolicationDataLookUpResultError,nil);
            
            return;
        }
    }
    
    DWRFFileObject * tFileObject=_cachedWARFFileObjectsRegistry[inBinaryUUID];
    
    if (tFileObject==nil)
    {
        MCHObjectFile * tMachObjectFile=_machObjectFilesRegistry[inBinaryUUID];
        
        if (tMachObjectFile==nil)
        {
            handler(CUISymbolicationDataLookUpResultError,nil);
            
            return;
        }
        
        if (_cachedWARFFileObjectsRegistry==nil)
            _cachedWARFFileObjectsRegistry=[NSMutableDictionary dictionary];
        
        tFileObject=[[DWRFFileObject alloc] initWithMachObjectFile:tMachObjectFile];
        
        if (tFileObject==nil)
        {
            handler(CUISymbolicationDataLookUpResultError,nil);
            
            return;
        }
        
        _cachedWARFFileObjectsRegistry[inBinaryUUID]=tFileObject;
    }
    
    static dispatch_queue_t sSearchSerialQueue=nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sSearchSerialQueue=dispatch_queue_create("fr.whitebox.unexpectedly.searchqueue", DISPATCH_QUEUE_SERIAL);
        
    });
    
    dispatch_async(sSearchSerialQueue, ^{
        
        [tFileObject lookUpSymbolicationDataForMachineInstructionAddress:inAddress completionHandler:^(BOOL bFound, CUISymbolicationData * bSymbolicationData) {
            
            dispatch_async(inQueue, ^{
                
                if (bFound==NO)
                {
                    handler(CUISymbolicationDataLookUpResultNotFound,nil);
                    
                    return;
                }
                
                // Update Cache
                
                [[CUISymbolicationDataCache sharedCache] setSymbolicationData:bSymbolicationData forAddress:inAddress binary:inBinaryUUID];
                
                handler(CUISymbolicationDataLookUpResultFound,bSymbolicationData);
            });
        }];
    });
}

@end
