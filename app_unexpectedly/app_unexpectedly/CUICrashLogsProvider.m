/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICrashLogsProvider.h"

#import "NSArray+WBExtensions.h"

@implementation CUICrashLogsProvider

+ (CUICrashLogsProvider *)defaultProvider
{
	static CUICrashLogsProvider * sDefaultProvider=nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sDefaultProvider=[CUICrashLogsProvider new];
	});
	
	return sDefaultProvider;
}

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
	}
	
	return self;
}

#pragma mark -

- (NSArray *)currentUserCrashLogs
{
	NSString * tDirectoryPath=[@"~/Library/Logs/DiagnosticReports/" stringByExpandingTildeInPath];
	
	return [self crashLogsForDirectory:tDirectoryPath error:NULL];
}

- (NSArray *)systemCrashLogs
{
	NSString * tDirectoryPath=@"/Library/Logs/DiagnosticReports/";
	
	return [self crashLogsForDirectory:tDirectoryPath error:NULL];
}

- (id)crashLogWithContentsOfFile:(NSString *)inPath error:(NSError **)outError
{
	if ([inPath isKindOfClass:[NSString class]]==NO)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:@{}];
		
		return nil;
	}
	
    if ([inPath.pathExtension caseInsensitiveCompare:@"crash"]!=NSOrderedSame)
        return nil;
    
    id tCrashLog=[[CUICrashLog alloc] initWithContentsOfFile:inPath error:outError];
    
    if (tCrashLog==nil)
    {
        NSLog(@"Error when parsing report file \"%@\", will try to parse it as raw report",inPath);
        
        tCrashLog=[[CUIRawCrashLog alloc] initWithContentsOfFile:inPath error:outError];
    }
    
	return tCrashLog;
}

- (NSArray *)crashLogsForDirectory:(NSString *)inDirectoryPath error:(NSError **)outError
{
	if ([inDirectoryPath isKindOfClass:[NSString class]]==NO)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:@{}];
		
		return nil;
	}
	
	NSArray * tArray=[[NSFileManager defaultManager] contentsOfDirectoryAtPath:inDirectoryPath error:outError];
	
	NSArray * tCrashLogsArray=[tArray WB_arrayByMappingObjectsLenientlyUsingBlock:^id(NSString * bComponent, NSUInteger bIndex) {
		
		if ([bComponent.pathExtension caseInsensitiveCompare:@"crash"]!=NSOrderedSame)
			return nil;
		
		NSString * tFilePath=[inDirectoryPath stringByAppendingPathComponent:bComponent];
		
		NSError * tError=nil;
		
		id tCrashLog=[[CUICrashLog alloc] initWithContentsOfFile:tFilePath error:&tError];
		
        if (tCrashLog==nil)
        {
            // A COMPLETER
            
            tCrashLog=[[CUIRawCrashLog alloc] initWithContentsOfFile:tFilePath error:&tError];
        }
        
        return tCrashLog;
		
	}];
	
	return tCrashLogsArray;
}

@end
