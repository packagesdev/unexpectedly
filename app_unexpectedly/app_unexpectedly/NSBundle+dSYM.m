/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "NSBundle+dSYM.h"

#import "MCHMachBinary.h"

#import "MCHUUIDLoadCommand.h"

#import "MCHSegmentLoadCommand.h"

#include <mach-o/loader.h>
#include <mach-o/fat.h>



@interface NSBundle (dSYM_Private)

- (NSString *)symbolsFilePath;

@end

@implementation NSBundle (dSYM)

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
    NSMutableArray * tMutableArray=[NSMutableArray array];
    
    NSString * tPath=[self symbolsFilePath];
    
    MCHMachBinary * tMachBinary=[[MCHMachBinary alloc] initWithContentsOfFile:tPath];
    
    //NSLog(@"%@",[tMachBinary description]);
    
    [[tMachBinary allObjectFiles] enumerateObjectsUsingBlock:^(MCHObjectFile * bObjectFile, NSUInteger bIndex, BOOL * bOutStop) {
        
        if (bObjectFile.fileType!=MH_DSYM)
            return;
        
        NSArray * tUUIDLoadCommands=[bObjectFile loadCommandsOfType:LC_UUID];
        
        MCHUUIDLoadCommand * tUUIDLoadCommand=tUUIDLoadCommands.firstObject;
        
        NSString * tUUIDString=tUUIDLoadCommand.uuid.UUIDString;
        
        if (tUUIDString!=nil)
            [tMutableArray addObject:tUUIDString];
    }];
    
    
    return [tMutableArray copy];
}

@end
