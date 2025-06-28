/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>

#import "CUICrashLogErrors.h"

#import "IPSReport.h"

typedef NS_ENUM(NSUInteger, CUICrashLogReportSourceType)
{
    CUICrashLogReportSourceTypeSystem=0,
    CUICrashLogReportSourceTypeUser,
    CUICrashLogReportSourceTypeOther
};

@interface CUIRawCrashLog : NSObject

    @property (readonly) id resourceIdentifier;

    @property (readonly) IPSReport * ipsReport;     // Can be nil

    @property (readonly,copy) NSString * rawText;   // Can be nil

    @property (readonly,copy) NSString * crashLogFilePath;

    @property (nonatomic,readonly) CUICrashLogReportSourceType reportSourceType;

    @property (nonatomic,readonly) BOOL isFullyParsed;


    @property (nonatomic,readonly,getter=isHeaderAvailable) BOOL headerAvailable;

    @property (nonatomic,readonly,getter=isExceptionInformationAvailable) BOOL exceptionInformationAvailable;

    @property (nonatomic,readonly,getter=isDiagnosticMessageAvailable) BOOL diagnosticMessageAvailable;

    @property (nonatomic,readonly,getter=isBacktracesAvailable) BOOL backtracesAvailable;

    @property (nonatomic,readonly,getter=isThreadStateAvailable) BOOL threadStateAvailable;

    @property (nonatomic,readonly,getter=isBinaryImagesAvailable) BOOL binaryImagesAvailable;



    @property (nonatomic,readonly,copy) NSString * processName;

    @property (nonatomic,readonly) NSDate * dateTime;


    @property (nonatomic,readonly) NSUInteger reportVersion;

    @property (nonatomic,readonly) NSNumber * numberOfHoursSinceCrash;

    // Extended Attributes

    @property (readonly,copy) NSString * reopenFilePath;

    @property (readonly,copy) NSString * USERPathComponent;


- (instancetype)initWithContentsOfURL:(NSURL *)inURL error:(NSError **)outError;

- (instancetype)initWithContentsOfFile:(NSString *)inPath error:(NSError **)outError;

- (instancetype)initWithData:(NSData *)inData error:(NSError **)outError;

- (instancetype)initWithString:(NSString *)inString error:(NSError **)outError;

- (BOOL)finalizeParsing;


@property (nonatomic,readonly,copy) NSString * crashLogFileName;


- (NSComparisonResult)compareCrashLogFileName:(CUIRawCrashLog *)otherCrashLog;

- (NSComparisonResult)compareProcessName:(CUIRawCrashLog *)otherCrashLog;

- (NSComparisonResult)compareDateReverse:(CUIRawCrashLog *)otherCrashLog;

@end
