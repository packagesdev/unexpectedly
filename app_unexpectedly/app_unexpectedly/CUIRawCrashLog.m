/*
 Copyright (c) 2020-2022, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIRawCrashLog.h"

#import "CUICrashLogSectionsDetector.h"

#import "CUICrashLogHeader.h"

#import "NSFileManager+ExtendedAttributes.h"

@interface CUIRawCrashLog ()
{
    BOOL _isLastHopeParseDone;
    
    id _reserved1;  // processName
    id _reserved2;  // dateTime
    id _reserved3;  // header.bundleIdentifier
    id _reserved4;  // header.executablePath
    id _reserved5;  // header.executableVersion
    id _reserved6;  // header.operatingSystemVersion.stringValue
}

    @property (copy) NSString * crashLogFilePath;

    @property (copy) NSString * rawText;

    // Extended Attributes

    @property (copy) NSString * reopenFilePath;


- (instancetype)initWithString:(NSString *)inString error:(NSError **)outError;

@end

@implementation CUIRawCrashLog

- (instancetype)initWithContentsOfURL:(NSURL *)inURL error:(NSError **)outError
{
    if ([inURL isKindOfClass:[NSURL class]]==NO)
    {
        if (outError!=NULL)
            *outError=[NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:@{}];
        
        return nil;
    }
    
    NSError * tError=nil;
    
    NSData * tData=[NSData dataWithContentsOfURL:inURL options:0 error:&tError];
    
    if (tData==nil)
    {
        if (outError!=NULL)
            *outError=tError;
        
        return nil;
    }
    
    self=[self initWithData:tData error:outError];
    
    if (self!=nil)
    {
        id tResourceIdentifier=nil;
        
        if ([inURL getResourceValue:&tResourceIdentifier forKey:NSURLFileResourceIdentifierKey error:NULL]==YES)
        {
            _resourceIdentifier=tResourceIdentifier;
        }
        
        _crashLogFilePath=[inURL.path copy];
        
        
        NSDictionary * tExtendedAttributes=[[NSFileManager defaultManager] WB_extendedAttributesOfItemAtURL:inURL error:nil];
        
        NSData * tData=tExtendedAttributes[@"ReopenPath"];
        
        if (tData!=nil)
        {
            _reopenFilePath=[[NSString alloc] initWithData:tData encoding:NSUTF8StringEncoding];
            
            if ([_reopenFilePath hasPrefix:@"/Users/"]==YES)
            {
                NSArray * tComponents=[_reopenFilePath componentsSeparatedByString:@"/"];
                
                if (tComponents.count>2)
                    _USERPathComponent=[tComponents[2] copy];
            }
        }
    }
    
    return self;
}

- (instancetype)initWithContentsOfFile:(NSString *)inPath error:(NSError **)outError
{
    if ([inPath isKindOfClass:[NSString class]]==NO)
    {
        if (outError!=NULL)
            *outError=[NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:@{}];
        
        return nil;
    }
    
    return [self initWithContentsOfURL:[NSURL fileURLWithPath:inPath] error:outError];
}

- (instancetype)initWithData:(NSData *)inData error:(NSError **)outError
{
    if ([inData isKindOfClass:[NSData class]]==NO)
    {
        if (outError!=NULL)
            *outError=[NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:@{}];
        
        return nil;
    }
    
    NSString * tString=[[NSString alloc] initWithData:inData encoding:NSUTF8StringEncoding];
    
    if (tString==nil)
        tString=[[NSString alloc] initWithData:inData encoding:NSASCIIStringEncoding];
    
    if (tString==nil)
    {
        if (outError!=NULL)
            *outError=[NSError errorWithDomain:NSPOSIXErrorDomain code:ENOMEM userInfo:@{}];
        
        return nil;
    }
    
    return [self initWithString:tString error:outError];
}

- (instancetype)initWithString:(NSString *)inString error:(NSError **)outError
{
    if ([inString isKindOfClass:[NSString class]]==NO)
    {
        if (outError!=NULL)
            *outError=[NSError errorWithDomain:NSCocoaErrorDomain code:EINVAL userInfo:@{}];
        
        return nil;
    }
    
    if ([inString hasPrefix:@"Process:"]==YES)
    {
        self=[super init];
        
        if (self!=nil)
        {
            _rawText=[inString copy];
            
            _resourceIdentifier=[NSUUID UUID];
        }
    }
    else if ([inString hasPrefix:@"{"]==YES)
    {
        self=[super init];
        
        if (self!=nil)
        {
            NSError * tError=nil;
            
            _ipsReport=[[IPSReport alloc] initWithString:inString error:&tError];
            
            if (_ipsReport==nil)
            {
                if (outError!=NULL)
                    *outError=tError;
                
                return nil;
            }
            
            _rawText=nil;
            
            _resourceIdentifier=[NSUUID UUID];
        }
    }
    else
    {
        if (outError!=NULL)
        {
            if (inString.length==0)
            {
                *outError=[NSError errorWithDomain:CUICrashLogDomain code:CUICrashLogEmptyFileError userInfo:@{}];
            }
            else
            {
                *outError=[NSError errorWithDomain:CUICrashLogDomain code:CUICrashLogInvalidFormatFileError userInfo:@{}];
            }
        }
        
        return nil;
    }
    
    return self;
}

#pragma mark -

- (BOOL)isHeaderAvailable
{
    return (self.ipsReport.incident.header!=nil);
}

- (BOOL)isExceptionInformationAvailable
{
    return (self.ipsReport.incident.exceptionInformation!=nil);
}

- (BOOL)isDiagnosticMessageAvailable
{
    return (self.ipsReport.incident.diagnosticMessage!=nil);
}

- (BOOL)isBacktracesAvailable
{
    return (self.ipsReport.incident.threads!=nil);
}

- (BOOL)isThreadStateAvailable
{
    NSUInteger tFaultingThreadIndex=self.ipsReport.incident.exceptionInformation.faultingThread;
    
    NSArray<IPSThread *> * tThreadsArray=self.ipsReport.incident.threads;
    
    if (tFaultingThreadIndex>=tThreadsArray.count)
        return NO;
    
    IPSThread * tThread=tThreadsArray[tFaultingThreadIndex];
    
    return (tThread.threadState!=nil);
}

- (BOOL)isBinaryImagesAvailable
{
    return (self.ipsReport.incident.binaryImages!=nil);
}

- (id)valueForUndefinedKey:(NSString *)inKey
{
    NSLog(@"Undefined key '%@'",inKey);
    
    return @"";
}

- (id)valueForKeyPath:(NSString *)inKeyPath
{
    if ([inKeyPath isEqualToString:@"header.bundleIdentifier"]==YES)
        return (_reserved3==nil) ? @"" : _reserved3;
    
    if ([inKeyPath isEqualToString:@"header.executablePath"]==YES)
        return (_reserved4==nil) ? @"" : _reserved4;
    
    if ([inKeyPath isEqualToString:@"header.executableVersion"]==YES)
        return (_reserved5==nil) ? @"" : _reserved5;
    
    if ([inKeyPath isEqualToString:@"header.operatingSystemVersion.stringValue"]==YES)
        return (_reserved6==nil) ? @"" : _reserved6;
    
    if ([inKeyPath isEqualToString:@"exceptionInformation.crashedThreadName"]==YES)
        return @"";
    
    id tValue=nil;
    
    @try
    {
        tValue=[super valueForKeyPath:inKeyPath];
    }
    
    @catch(NSException * bException)
    {
        tValue=@"";
    }
    
    return tValue;
}

- (NSString *)processName
{
    if (_isLastHopeParseDone==NO)
        [self finalizeParsing];
    
    return (_reserved1!=nil) ? _reserved1 : @"";
}

- (NSDate *)dateTime
{
    if (_isLastHopeParseDone==NO)
        [self finalizeParsing];
    
    return (_reserved2!=nil) ? _reserved2 : nil;
}

- (NSUInteger)reportVersion
{
    return NSNotFound;
}

- (NSNumber *)numberOfHoursSinceCrash
{
    if (_reserved2==nil)
        return @(NSUIntegerMax);
    
    NSDate * tDate=[NSDate date];
    
    NSTimeInterval tTimeInterval=[tDate timeIntervalSinceDate:_reserved2];
    
    NSInteger tNumberOfHours=round(tTimeInterval/3600);
    
    return @(tNumberOfHours);
}

- (CUICrashLogReportSourceType)reportSourceType
{
    static NSString * sSystemReportsDirectoryPath=nil;
    static NSString * sSystemUsersDirectoryPath=nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        NSArray * tArray=NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSLocalDomainMask, YES);
        
        sSystemReportsDirectoryPath=[tArray.firstObject stringByAppendingPathComponent:@"Logs/DiagnosticReports"];
        
        tArray=NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        
        sSystemUsersDirectoryPath=[tArray.firstObject stringByAppendingPathComponent:@"Logs/DiagnosticReports"];
        
    });
    
    NSString * tParentDirectory=[self.crashLogFilePath stringByDeletingLastPathComponent];
    
    if ([sSystemReportsDirectoryPath isEqualToString:tParentDirectory]==YES)
        return CUICrashLogReportSourceTypeSystem;
    
    if ([sSystemUsersDirectoryPath isEqualToString:tParentDirectory]==YES)
        return CUICrashLogReportSourceTypeUser;
    
    return CUICrashLogReportSourceTypeOther;
}

#pragma mark -

- (BOOL)isFullyParsed
{
    return _isLastHopeParseDone;
}

- (BOOL)finalizeParsing
{
    _isLastHopeParseDone=YES;
    
    NSRange tRange;
    
    NSMutableArray * tLines=[NSMutableArray array];
    
    [self.rawText enumerateLinesUsingBlock:^(NSString * bLine, BOOL * bOutStop) {
        
        [tLines addObject:bLine];
    }];

    NSUInteger tFirstLine=0;
    
    // Try to parse at least the header
    
    tRange=[CUICrashLogSectionsDetector detectHeaderSectionRangeInTextualRepresentation:tLines atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(tFirstLine,tLines.count-tFirstLine)]];
    
    if (tRange.location==NSNotFound)
    {
        /*if (outError!=NULL)
            *outError=[NSError errorWithDomain:CUIParsingErrorDomain code:CUIParsingSectionDetectionFailedError userInfo:@{CUIParsingErrorSectionNameKey:@"Header"}];*/
        
        return NO;
    }
    
    CUICrashLogHeader * tHeader=[[CUICrashLogHeader alloc] initWithTextualRepresentation:[tLines subarrayWithRange:tRange] error:NULL];
    
    if (tHeader!=nil)
    {
        _reserved1=[tHeader.processName copy];
        
        _reserved2=[tHeader.dateTime copy];
        
        _reserved3=[tHeader.bundleIdentifier copy];
        
        _reserved4=[tHeader.executablePath copy];
        
        _reserved5=[tHeader.executableVersion copy];
        
        _reserved6=[tHeader.operatingSystemVersion.stringValue copy];
    }
    
    return YES;
}

#pragma mark -

- (NSString *)crashLogFileName
{
    return self.crashLogFilePath.lastPathComponent.stringByDeletingPathExtension;
}

#pragma mark -

- (NSComparisonResult)compareCrashLogFileName:(CUIRawCrashLog *)otherCrashLog
{
    return [self.crashLogFileName compare:otherCrashLog.crashLogFileName options:NSNumericSearch|NSCaseInsensitiveSearch];
}

- (NSComparisonResult)compareProcessName:(CUIRawCrashLog *)otherCrashLog
{
    NSComparisonResult tResult=[self.processName compare:otherCrashLog.processName options:NSNumericSearch|NSCaseInsensitiveSearch];
    
    if (tResult!=NSOrderedSame)
        return tResult;
    
    return [self.crashLogFilePath compare:self.crashLogFilePath];
}

- (NSComparisonResult)compareDateReverse:(CUIRawCrashLog *)otherCrashLog
{
    return -[self.dateTime compare:otherCrashLog.dateTime];
}

@end
