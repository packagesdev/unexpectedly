/*
 Copyright (c) 2020-2022, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICrashLogsProvider.h"

#import "NSArray+WBExtensions.h"

NSString * const CUIRetiredPathComponent=@"Retired";

@interface CUICrashLogsProvider ()

- (NSArray *)crashLogsForDirectory:(NSString *)inDirectoryPath options:(CUICrashLogsProviderCollectOptions)options error:(NSError **)outError;

@end

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

#pragma mark -

- (NSArray *)currentUserCrashLogs
{
	NSString * tDirectoryPath=[@"~/Library/Logs/DiagnosticReports/" stringByExpandingTildeInPath];
	
    return [self crashLogsForDirectory:tDirectoryPath options:CUICrashLogsProviderCollectRetired error:NULL];
}

- (NSArray *)systemCrashLogs
{
	NSString * tDirectoryPath=@"/Library/Logs/DiagnosticReports/";
	
	return [self crashLogsForDirectory:tDirectoryPath options:CUICrashLogsProviderCollectRetired error:NULL];
}

- (id)crashLogWithContentsOfFile:(NSString *)inPath error:(NSError **)outError
{
	if ([inPath isKindOfClass:NSString.class]==NO)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:@{}];
		
		return nil;
	}
	
    NSString * tExtension=inPath.pathExtension;
    
    if ([tExtension caseInsensitiveCompare:@"crash"]!=NSOrderedSame &&
        [tExtension caseInsensitiveCompare:@"ips"]!=NSOrderedSame)
        return nil;
    
    NSError * tError=nil;
    
    id tCrashLog=[[CUICrashLog alloc] initWithContentsOfFile:inPath error:&tError];
    
    if (tCrashLog==nil)
    {
		BOOL tryAgainIfRawSucceed=NO;
		
        if ([tError.domain isEqualToString:NSCocoaErrorDomain]==YES)
        {
            switch(tError.code)
            {
                case NSFileReadNoSuchFileError:     // File is missing, no point in trying to read it
                case NSFileReadNoPermissionError:   // Not enough privileges to read file, no point in trying to read it
                            
                    if (outError!=nil)
                        *outError=tError;
                    
                    return nil;
                    
				case NSFileReadUnknownError:
				{
					NSError * tUnderlyingError=tError.userInfo[NSUnderlyingErrorKey];
					
					if ([tUnderlyingError.domain isEqualToString:NSPOSIXErrorDomain]==YES &&
						tUnderlyingError.code==EINTR)
					{
						tryAgainIfRawSucceed=YES;
					}
				}
					
				case NSPropertyListReadCorruptError:	// Invalid json file.
					if (outError!=nil)
						*outError=tError;
					
					return nil;
					
				default:
                    
                    break;
            }
        }
        else if ([tError.domain isEqualToString:CUICrashLogDomain]==YES)
        {
            switch(tError.code)
            {
                case CUICrashLogEmptyFileError:
                case CUICrashLogInvalidFormatFileError:
                    
                    // Not worth retrying as a raw file
                    
                    if (outError!=nil)
                        *outError=tError;
                    
                    NSLog(@"Error when parsing report file \"%@\": Empty file or not a crash log report.",inPath);
                    
                    return nil;
            }
        }
        
        NSLog(@"Error when parsing report file \"%@\", will try to parse it as raw report: %@",inPath,tError.description);
        
        tCrashLog=[[CUIRawCrashLog alloc] initWithContentsOfFile:inPath error:&tError];
        
		if (tCrashLog!=nil)
		{
			id newCrashLogAttempt=[[CUICrashLog alloc] initWithContentsOfFile:inPath error:&tError];
			
			if (newCrashLogAttempt!=nil)
				tCrashLog=newCrashLogAttempt;
		}
    }
    
	return tCrashLog;
}

- (NSArray *)crashLogsForDirectory:(NSString *)inDirectoryPath error:(NSError **)outError
{
    return [self crashLogsForDirectory:inDirectoryPath options:0 error:outError];
}

- (NSArray *)crashLogsForDirectory:(NSString *)inDirectoryPath options:(CUICrashLogsProviderCollectOptions)inOptions error:(NSError **)outError
{
	if ([inDirectoryPath isKindOfClass:NSString.class]==NO)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:@{}];
		
		return nil;
	}
	
	NSArray * tArray=[[NSFileManager defaultManager] contentsOfDirectoryAtPath:inDirectoryPath error:outError];
    
    if ((inOptions & CUICrashLogsProviderCollectRetired) == CUICrashLogsProviderCollectRetired && [tArray containsObject:CUIRetiredPathComponent]==YES)
    {
        NSArray * tRetiredArray=[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[inDirectoryPath stringByAppendingPathComponent:CUIRetiredPathComponent] error:NULL];
        
        if (tRetiredArray.count>0)
            tArray = [tArray arrayByAddingObjectsFromArray:tRetiredArray];
    }
	
	NSArray * tCrashLogsArray=[tArray WB_arrayByMappingObjectsLenientlyUsingBlock:^id(NSString * bComponent, NSUInteger bIndex) {
		
        NSString * tComponentExtension=bComponent.pathExtension;
        
		if ([tComponentExtension caseInsensitiveCompare:@"crash"]!=NSOrderedSame &&
            [tComponentExtension caseInsensitiveCompare:@"ips"]!=NSOrderedSame)
			return nil;
		
		NSString * tFilePath=[inDirectoryPath stringByAppendingPathComponent:bComponent];
		
		NSError * tError=nil;
		
		id tCrashLog=[[CUICrashLog alloc] initWithContentsOfFile:tFilePath error:&tError];
		
        if (tCrashLog==nil)
        {
            if ([tError.domain isEqualToString:NSCocoaErrorDomain]==YES)
            {
                switch(tError.code)
                {
                    case NSFileReadNoSuchFileError:     // File is missing, no point in trying to read it
                    case NSFileReadNoPermissionError:   // Not enough privileges to read file, no point in trying to read it
                        
                        return nil;
                        
                    default:
                        
                        break;
                }
            }
            else if ([tError.domain isEqualToString:CUICrashLogDomain]==YES)
            {
                switch(tError.code)
                {
                    case CUICrashLogEmptyFileError:
                    case CUICrashLogInvalidFormatFileError:
                        
                        // Not worth retrying as a raw file
                        
                        return nil;
                }
            }
            
            tCrashLog=[[CUIRawCrashLog alloc] initWithContentsOfFile:tFilePath error:&tError];
        }
        
        return tCrashLog;
		
	}];
	
	return tCrashLogsArray;
}

@end
