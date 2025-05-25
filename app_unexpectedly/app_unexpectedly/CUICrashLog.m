/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICrashLog.h"

#import "CUIParsingErrors.h"

#import "CUICrashLogSectionsDetector.h"

@interface CUICrashLog ()

    @property NSError * parsingError;

    // Sections ranges

    @property NSRange headerRange;

    @property NSRange exceptionInformationRange;
    @property NSRange diagnosticMessagesRange;

    @property NSRange backtracesRange;

    @property NSRange threadStateRange;

    @property NSRange binaryImagesRange;

    @property BOOL fullyParsed;


    @property CUICrashLogHeader * header;

    @property CUICrashLogExceptionInformation * exceptionInformation;

    @property CUICrashLogDianosticMessages * diagnosticMessages;

    @property CUICrashLogBacktraces * backtraces;

    @property CUICrashLogThreadState * threadState;

    @property CUICrashLogBinaryImages * binaryImages;

@end

@implementation CUICrashLog

- (instancetype)initWithString:(NSString *)inString error:(NSError **)outError
{
    if ([inString isKindOfClass:NSString.class]==NO)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:@{}];
		
		return nil;
	}
	
	self=[super initWithString:inString error:outError];
	
	if (self!=nil)
	{
        _headerRange.location=NSNotFound;
        
        _exceptionInformationRange.location=NSNotFound;
        _diagnosticMessagesRange.location=NSNotFound;
        
        _backtracesRange.location=NSNotFound;
        
        _threadStateRange.location=NSNotFound;
        
        _binaryImagesRange.location=NSNotFound;
        
        NSError * tError=nil;
        
        if (self.ipsReport!=nil)
        {
            IPSIncident * tIncident=self.ipsReport.incident;
            
            _header=[[CUICrashLogHeader alloc] initWithIPSIncident:tIncident error:&tError];
            
            if (_header==nil)
            {
                // A COMPLETER
                
                return nil;
            }
            
            _exceptionInformation=[[CUICrashLogExceptionInformation alloc] initWithIPSIncident:tIncident error:&tError];
            
            if (_exceptionInformation==nil)
            {
                // A COMPLETER
                
                return nil;
            }
            
            _diagnosticMessages=[[CUICrashLogDianosticMessages alloc] initWithIPSIncident:tIncident error:&tError];
            
            if (_diagnosticMessages==nil)
            {
                // A COMPLETER
                
                return nil;
            }
        }
        else
        {
            NSMutableArray * tLines=[NSMutableArray array];
            
            [self.rawText enumerateLinesUsingBlock:^(NSString * bLine, BOOL * bOutStop) {
                
                [tLines addObject:bLine];
            }];

            @try
            {
                BOOL tResult=[self detectSectionsOfTextualRepresentation:tLines error:&tError];
                
                if (tResult==NO)
                {
                    NSLog(@"Error detecting section : %@",tError.userInfo[CUIParsingErrorSectionNameKey]);
                    
                    _parsingError=tError;
                    
                    // Raw Text Mode only
                    
                    // A COMPLETER
                    
                    return nil;
                }
                
                _header=[[CUICrashLogHeader alloc] initWithTextualRepresentation:[tLines subarrayWithRange:_headerRange] error:&tError];
                
                if (_header==nil)
                {
                    if (tError!=nil)
                    {
                        NSUInteger tAbsoluteLineNumber=[tError.userInfo[CUIParsingErrorLineKey] unsignedIntegerValue]+_headerRange.location;
                        
                        NSLog(@"Error parsing line : %lu",tAbsoluteLineNumber);
                        
                        _parsingError=[NSError errorWithDomain:CUIParsingErrorDomain code:tError.code userInfo:@{CUIParsingErrorLineKey:@(tAbsoluteLineNumber)}];
                    }
                    
                    // A COMPLETER
                    
                    return nil;
                }
                
                _exceptionInformation=[[CUICrashLogExceptionInformation alloc] initWithTextualRepresentation:[tLines subarrayWithRange:_exceptionInformationRange] reportVersion:_header.reportVersion error:&tError];
                
                if (_exceptionInformation==nil)
                {
                    if (tError!=nil)
                    {
                        NSUInteger tAbsoluteLineNumber=[tError.userInfo[CUIParsingErrorLineKey] unsignedIntegerValue]+_headerRange.location;
                        
                        NSLog(@"Error parsing line : %lu",tAbsoluteLineNumber);
                        
                        _parsingError=[NSError errorWithDomain:CUIParsingErrorDomain code:tError.code userInfo:@{CUIParsingErrorLineKey:@(tAbsoluteLineNumber)}];
                    }
                    
                    // A COMPLETER
                    
                    return nil;
                }
                
                if (_diagnosticMessagesRange.location!=NSNotFound)
                {
                    _diagnosticMessages=[[CUICrashLogDianosticMessages alloc] initWithTextualRepresentation:[tLines subarrayWithRange:_diagnosticMessagesRange] reportVersion:_header.reportVersion error:&tError];
                    
                    if (_diagnosticMessages==nil)
                    {
                        if (tError!=nil)
                        {
                            NSUInteger tAbsoluteLineNumber=[tError.userInfo[CUIParsingErrorLineKey] unsignedIntegerValue]+_headerRange.location;
                            
                            NSLog(@"Error parsing line : %lu",tAbsoluteLineNumber);
                            
                            _parsingError=[NSError errorWithDomain:CUIParsingErrorDomain code:tError.code userInfo:@{CUIParsingErrorLineKey:@(tAbsoluteLineNumber)}];
                        }
                        
                        // A COMPLETER
                        
                        return nil;
                    }
                }
                
                // The other sections will be parsed when the log is displayed for real
            }
            
            @catch (NSException *exception)
            {
                NSLog(@"Exception raised while parsing \"%@\"",self.rawText);
                
                return nil;
            }
            
            @finally
            {
            }
        }
	}
    
	return self;
}

#pragma mark -

- (BOOL)isHeaderAvailable
{
    if ([super isHeaderAvailable]==YES)
        return YES;
    
    return (self.headerRange.location!=NSNotFound);
}

- (BOOL)isExceptionInformationAvailable
{
    if ([super isExceptionInformationAvailable]==YES)
        return YES;
    
    return (self.exceptionInformationRange.location!=NSNotFound);
}

- (BOOL)isDiagnosticMessageAvailable
{
    if ([super isDiagnosticMessageAvailable]==YES)
        return YES;
    
    return (self.diagnosticMessagesRange.location!=NSNotFound);
}

- (BOOL)isBacktracesAvailable
{
    if ([super isBacktracesAvailable]==YES)
        return YES;
    
    return (self.backtracesRange.location!=NSNotFound);
}

- (BOOL)isThreadStateAvailable
{
    if ([super isThreadStateAvailable]==YES)
        return YES;
    
    return (self.threadStateRange.location!=NSNotFound);
}

- (BOOL)isBinaryImagesAvailable
{
    if ([super isBinaryImagesAvailable]==YES)
        return YES;
    
    return (self.binaryImagesRange.location!=NSNotFound);
}

- (id)valueForKeyPath:(NSString *)inKeyPath
{
    if ([inKeyPath isEqualToString:@"header.bundleIdentifier"]==YES)
        return self.header.bundleIdentifier;
    
    if ([inKeyPath isEqualToString:@"header.executablePath"]==YES)
        return self.header.executablePath;
    
    if ([inKeyPath isEqualToString:@"header.executableVersion"]==YES)
        return self.header.executableVersion;
    
    if ([inKeyPath isEqualToString:@"header.operatingSystemVersion.stringValue"]==YES)
        return self.header.operatingSystemVersion.stringValue;
    
    if ([inKeyPath isEqualToString:@"exceptionInformation.crashedThreadName"]==YES)
        return self.exceptionInformation.crashedThreadName;
    
    return [super valueForKeyPath:inKeyPath];
}


- (NSString *)processName
{
    return self.header.processName;
}

- (NSDate *)dateTime
{
    return self.header.dateTime;
}

- (NSUInteger)reportVersion
{
    return self.header.reportVersion;
}

- (NSNumber *)numberOfHoursSinceCrash
{
    NSDate * tDate=[NSDate date];
    
    NSTimeInterval tTimeInterval=[tDate timeIntervalSinceDate:self.dateTime];
    
    NSInteger tNumberOfHours=round(tTimeInterval/3600);
    
    return @(tNumberOfHours);
}

#pragma mark -

- (BOOL)detectSectionsOfTextualRepresentation:(NSArray *)inLines error:(NSError **)outError
{
    NSRange tRange;
    NSUInteger tFirstLine=0;
    
    // Header Section (Required)
    
    tRange=[CUICrashLogSectionsDetector detectHeaderSectionRangeInTextualRepresentation:inLines atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(tFirstLine,inLines.count-tFirstLine)]];
    
    if (tRange.location==NSNotFound)
    {
        if (outError!=NULL)
            *outError=[NSError errorWithDomain:CUIParsingErrorDomain code:CUIParsingSectionDetectionFailedError userInfo:@{CUIParsingErrorSectionNameKey:@"Header"}];
        
        return NO;
    }
    
    self.headerRange=tRange;
    
    // Exception Information Section (Required)
    
    tFirstLine=NSMaxRange(tRange);
    
    tRange=[CUICrashLogSectionsDetector detectExceptionInformationSectionRangeInTextualRepresentation:inLines atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(tFirstLine,inLines.count-tFirstLine)]];
    
    if (tRange.location==NSNotFound)
    {
        if (outError!=NULL)
            *outError=[NSError errorWithDomain:CUIParsingErrorDomain code:CUIParsingSectionDetectionFailedError userInfo:@{CUIParsingErrorSectionNameKey:@"Exception Information"}];
        
        return NO;
    }
    
    self.exceptionInformationRange=tRange;
    
    // Diagnostic Messages (Optional)
    
    tFirstLine=NSMaxRange(tRange);
    
    NSString * tString=inLines[tFirstLine];
    
    if ([tString hasPrefix:@"Application Specific Information:"]==YES ||
        [tString hasPrefix:@"VM Regions Near"]==YES ||
        [tString hasPrefix:@"VM Region Info:"]==YES)
    {
        tRange=[CUICrashLogSectionsDetector detectDiagnosticMessageSectionRangeInTextualRepresentation:inLines atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(tFirstLine,inLines.count-tFirstLine)]];
        
        if (tRange.location==NSNotFound)
        {
            if (outError!=NULL)
                *outError=[NSError errorWithDomain:CUIParsingErrorDomain code:CUIParsingSectionDetectionFailedError userInfo:@{CUIParsingErrorSectionNameKey:@"Diagnostic Messages"}];
            
            return NO;
        }
        
        self.diagnosticMessagesRange=tRange;
        
        tFirstLine=NSMaxRange(tRange);
        
        tString=inLines[tFirstLine];
    }
    
    // Backtraces
    
    if ([tString isEqualToString:@"Backtrace not available"]==YES ||
        [tString hasPrefix:@"Application Specific Backtrace"]==YES ||
        [tString hasPrefix:@"Thread 0"]==YES)
    {
        tRange=[CUICrashLogSectionsDetector detectBacktracesSectionRangeInTextualRepresentation:inLines atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(tFirstLine,inLines.count-tFirstLine)]];
        
        if (tRange.location==NSNotFound)
        {
            if (outError!=NULL)
                *outError=[NSError errorWithDomain:CUIParsingErrorDomain code:CUIParsingSectionDetectionFailedError userInfo:@{CUIParsingErrorSectionNameKey:@"Backtraces"}];
            
            return NO;
        }
        
        self.backtracesRange=tRange;
        
        tFirstLine=NSMaxRange(tRange);
        
        tString=inLines[tFirstLine];
    }
    
    // Thread State
    
    if ((([tString hasPrefix:@"Thread"]==YES || [tString hasPrefix:@"Unknown thread"]==YES) && [tString rangeOfString:@"crashed with"].location!=NSNotFound) ||
        ([tString rangeOfString:@"Thread State" options:NSCaseInsensitiveSearch].location==0))
    {
        tRange=[CUICrashLogSectionsDetector detectThreadStateSectionRangeInTextualRepresentation:inLines atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(tFirstLine,inLines.count-tFirstLine)]];
        
        if (tRange.location==NSNotFound)
        {
            if (outError!=NULL)
                *outError=[NSError errorWithDomain:CUIParsingErrorDomain code:CUIParsingSectionDetectionFailedError userInfo:@{CUIParsingErrorSectionNameKey:@"Thread State"}];
            
            return NO;
        }
        
        self.threadStateRange=tRange;
        
        tFirstLine=NSMaxRange(tRange);
        
        tString=inLines[tFirstLine];
    }
    
    // Binary Images
    
    if ([tString rangeOfString:@"Binary Images" options:NSCaseInsensitiveSearch].location==0)
    {
        tRange=[CUICrashLogSectionsDetector detectBinaryImagesSectionRangeInTextualRepresentation:inLines atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(tFirstLine,inLines.count-tFirstLine)]];
        
        if (tRange.location==NSNotFound)
        {
            if (outError!=NULL)
                *outError=[NSError errorWithDomain:CUIParsingErrorDomain code:CUIParsingSectionDetectionFailedError userInfo:@{CUIParsingErrorSectionNameKey:@"Binary Images"}];
            
            return NO;
        }
        
        self.binaryImagesRange=tRange;
    }
    
    return YES;
}

#pragma mark -

- (BOOL)isFullyParsed
{
    return self.fullyParsed;
}

- (BOOL)finalizeParsing
{
    NSError * tError=nil;
    IPSReport * tIPSReport=self.ipsReport;
    
    if (tIPSReport!=nil)
    {
        if (tIPSReport.incident.threads!=nil)
        {
            _backtraces=[[CUICrashLogBacktraces alloc] initWithIPSIncident:tIPSReport.incident error:&tError];
        
            if (_backtraces==nil)
            {
                // A COMPLETER
                
                return NO;
            }
        }
        
        {
            _threadState=[[CUICrashLogThreadState alloc] initWithIPSIncident:tIPSReport.incident error:&tError];
        
            if (_threadState==nil && tError!=nil)
            {
                // A COMPLETER
            
                return NO;
            }
        }
        
        if (tIPSReport.incident.binaryImages!=nil)
        {
            _binaryImages=[[CUICrashLogBinaryImages alloc] initWithIPSIncident:tIPSReport.incident error:&tError];
            
            if (_binaryImages==nil)
            {
                // A COMPLETER
                
                return NO;
            }
        }
        
        self.fullyParsed=YES;
        
        return YES;
    }
    
    NSMutableArray * tLines=[NSMutableArray array];
    
    [self.rawText enumerateLinesUsingBlock:^(NSString * bLine, BOOL * bOutStop) {
        
        [tLines addObject:bLine];
    }];
    
    if (self.backtracesRange.location!=NSNotFound)
    {
        _backtraces=[[CUICrashLogBacktraces alloc] initWithTextualRepresentation:[tLines subarrayWithRange:self.backtracesRange] reportVersion:_header.reportVersion error:&tError];
        
        if (_backtraces==nil)
        {
            if (tError!=nil)
            {
                NSUInteger tAbsoluteLineNumber=[tError.userInfo[CUIParsingErrorLineKey] unsignedIntegerValue]+_headerRange.location;
                
                NSLog(@"Error parsing line : %lu",tAbsoluteLineNumber);
                
                _parsingError=[NSError errorWithDomain:CUIParsingErrorDomain code:tError.code userInfo:@{CUIParsingErrorLineKey:@(tAbsoluteLineNumber)}];
            }
            
            // A COMPLETER
            
            return NO;
        }
    }
    
    if (self.threadStateRange.location!=NSNotFound)
    {
        _threadState=[[CUICrashLogThreadState alloc] initWithTextualRepresentation:[tLines subarrayWithRange:self.threadStateRange] reportVersion:_header.reportVersion error:&tError];
        
        if (_threadState==nil)
        {
            if (tError!=nil)
            {
                NSUInteger tAbsoluteLineNumber=[tError.userInfo[CUIParsingErrorLineKey] unsignedIntegerValue]+_headerRange.location;
                
                NSLog(@"Error parsing line : %lu",tAbsoluteLineNumber);
                
                _parsingError=[NSError errorWithDomain:CUIParsingErrorDomain code:tError.code userInfo:@{CUIParsingErrorLineKey:@(tAbsoluteLineNumber)}];
            }
            
            // A COMPLETER
            
            return NO;
        }
    }
    
    if (self.binaryImagesRange.location!=NSNotFound)
    {
        _binaryImages=[[CUICrashLogBinaryImages alloc] initWithTextualRepresentation:[tLines subarrayWithRange:self.binaryImagesRange] reportVersion:self.reportVersion error:&tError];
        
        if (_binaryImages==nil)
        {
            if (tError!=nil)
            {
                NSUInteger tAbsoluteLineNumber=[tError.userInfo[CUIParsingErrorLineKey] unsignedIntegerValue]+_headerRange.location;
                
                NSLog(@"Error parsing line : %lu",tAbsoluteLineNumber);
                
                _parsingError=[NSError errorWithDomain:CUIParsingErrorDomain code:tError.code userInfo:@{CUIParsingErrorLineKey:@(tAbsoluteLineNumber)}];
            }
            
            // A COMPLETER
            
            return NO;
        }
    }
    
    self.fullyParsed=YES;
    
    return YES;
}

#pragma mark -

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ %@",self.processName,self.dateTime.description];
}

@end
