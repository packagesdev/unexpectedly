/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICrashLogHeader.h"

#import "CUIParsingErrors.h"

@interface CUICrashLogHeader ()
{
    NSDateFormatter * _dateFormatter;
}
    @property NSUInteger reportVersion;


    @property NSDate * dateTime;

    @property CUIOperatingSystemVersion * operatingSystemVersion;

    @property BOOL systemIntegrityProtectionEnabled;

    @property (copy) NSString * bridgeOSVersion;


    @property (copy) NSString * anonymousUUID;


    @property CUICodeType codeType;

    @property BOOL native;


    @property (copy) NSString * executablePath;

    @property (copy) NSString * bundleIdentifier;

    @property (copy) NSString * executableVersion;


    @property (copy) NSString * responsibleProcessName;

    @property pid_t responsibleProcessIdentifier;

    @property (copy) NSString * processName;

    @property pid_t processIdentifier;

    @property (copy) NSString * parentProcessName;

    @property pid_t parentProcessIdentifier;



    @property uid_t userIdentifier;

    
+ (NSDateFormatter *)crashDateFormatter;

+ (BOOL)parseString:(NSString *)inString processName:(NSString **)outProcessName identifier:(pid_t *)outProcessIdentifier;
+ (BOOL)parseString:(NSString *)inString integerValue:(NSInteger *)outIntegerValue;

+ (BOOL)parseString:(NSString *)inString codeType:(CUICodeType *)outCodeType native:(BOOL *)outNative;

- (BOOL)parseTextualRepresentation:(NSArray *)inLines outError:(NSError **)outError;

@end

@implementation CUICrashLogHeader

+ (NSDateFormatter *)crashDateFormatter
{
    static NSDateFormatter * sCrashDateFormatter=nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sCrashDateFormatter = [NSDateFormatter new];
        sCrashDateFormatter.locale=[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];    // Technical Q&A QA1480
        sCrashDateFormatter.dateFormat=@"yyyy-MM-dd HH:mm:ss.SSS z";
    });
    
    return sCrashDateFormatter;
}

+ (BOOL)parseString:(NSString *)inString processName:(NSString **)outProcessName identifier:(pid_t *)outProcessIdentifier
{
    NSScanner * tScanner=[NSScanner scannerWithString:inString];
    
    NSString * tString;
    
    if ([tScanner scanUpToString:@" [" intoString:&tString]==NO)
    {
        // A COMPLETER
        
        return NO;
    }
    
    if (outProcessName!=NULL)
        *outProcessName=[tString copy];
    
    NSString * tSubString=[inString substringWithRange:NSMakeRange(tScanner.scanLocation+2,inString.length-2-(tScanner.scanLocation+2)+1)];
    
    if (outProcessIdentifier!=NULL)
        *outProcessIdentifier=(pid_t)[tSubString integerValue];
    
    return YES;
}

+ (BOOL)parseString:(NSString *)inString integerValue:(NSInteger *)outIntegerValue
{
    if (outIntegerValue!=NULL)
        *outIntegerValue=[inString integerValue];
    
    return YES;
}



+ (BOOL)parseString:(NSString *)inString codeType:(CUICodeType *)outCodeType native:(BOOL *)outNative
{
    NSArray * tComponents=[inString componentsSeparatedByString:@" "];
    
    switch(tComponents.count)
    {
        case 2:
            
            if (outNative!=NULL)
                *outNative=([tComponents[1] caseInsensitiveCompare:@"(Native)"]==NSOrderedSame);
            
        case 1:
            
            if (outCodeType!=NULL)
            {
                *outCodeType=CUICodeTypeUnknown;
                
                NSString * tString=tComponents.firstObject;
                
                if ([tString isEqualToString:@"X86"]==YES)
                {
                    *outCodeType=CUICodeTypeX86;
                }
                else if ([tString isEqualToString:@"X86-64"]==YES)
                {
                    *outCodeType=CUICodeTypeX86_64;
                }
                else if ([tString isEqualToString:@"ARM-64"]==YES)
                {
                    *outCodeType=CUICodeTypeARM_64;
                }
            }
            
            break;
    }
    
    return YES;
}

#pragma mark -

- (instancetype)initWithTextualRepresentation:(NSArray *)inLines error:(NSError **)outError
{
    if ([inLines isKindOfClass:NSArray.class]==NO)
    {
        if (outError!=NULL)
            *outError=[NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:@{}];
        
        return nil;
    }
    
    self=[super init];
    
    if (self!=nil)
    {
        _systemIntegrityProtectionEnabled=YES;
        
        if ([self parseTextualRepresentation:inLines outError:outError]==NO)
        {
            return nil;
        }
    }
    
    return self;
}

- (instancetype)initWithIPSIncident:(IPSIncident *)inIncident error:(NSError **)outError
{
    if ([inIncident isKindOfClass:IPSIncident.class]==NO)
    {
        if (outError!=NULL)
            *outError=[NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:@{}];
        
        return nil;
    }
    
    self=[super init];
    
    if (self!=nil)
    {
        IPSIncidentHeader * tIPSHeader=inIncident.header;
        
        _reportVersion=12;
        
        _dateTime=tIPSHeader.captureTime;
        
        NSString * tSystemVersionTrain=tIPSHeader.operatingSystemVersion.train;
        
        NSString * tPrefix=@"Mac OS X ";
        
        // A COMPLETER (Think iOS)
        
        if ([tSystemVersionTrain hasPrefix:tPrefix]==NO)
        {
            tPrefix=@"macOS ";
            
            if ([tSystemVersionTrain hasPrefix:tPrefix]==NO)
            {
                tPrefix=@"";
            }
        }
        
        _operatingSystemVersion=[[CUIOperatingSystemVersion alloc] initWithString:[tSystemVersionTrain substringFromIndex:tPrefix.length]];
        
        _systemIntegrityProtectionEnabled=tIPSHeader.systemIntegrityProtectionEnable;
        
        _bridgeOSVersion=nil;
        
        if ([tIPSHeader.crashReporterKey isKindOfClass:NSUUID.class]==YES)
			_anonymousUUID=[tIPSHeader.crashReporterKey UUIDString];
		else
			_anonymousUUID=tIPSHeader.crashReporterKey;
        
        
        _codeType=CUICodeTypeARM_64;
        
        if ([tIPSHeader.cpuType isEqualToString:@"X86-64"]==YES)
        {
            _codeType=CUICodeTypeX86_64;
        }
        else if ([tIPSHeader.cpuType isEqualToString:@"ARM-64"]==YES)
        {
            _codeType=CUICodeTypeARM_64;
        }
        
        _native=(tIPSHeader.translated==NO);
        
        
        _executablePath=tIPSHeader.processPath;
        
        _bundleIdentifier=tIPSHeader.bundleInfo.bundleIdentifier;
        
        _executableVersion=tIPSHeader.bundleInfo.bundleShortVersionString;
        
        
        _responsibleProcessName=tIPSHeader.responsibleProcessName;
        _responsibleProcessIdentifier=tIPSHeader.responsibleProcessID;
        
        _processName=tIPSHeader.processName;
        _processIdentifier=tIPSHeader.processID;
        
        _parentProcessName=tIPSHeader.parentProcessName;
        _parentProcessIdentifier=tIPSHeader.parentProcessID;
        
        
        _userIdentifier=tIPSHeader.userID;
    }
    
    return self;
}

#pragma mark -

- (BOOL)parseTextualRepresentation:(NSArray *)inLines outError:(NSError **)outError
{
    __block NSError * tError=nil;
    
    [inLines enumerateObjectsUsingBlock:^(NSString * bLine, NSUInteger bLineNumber, BOOL *bOutStop) {
        
        NSUInteger tLineLength=bLine.length;
        
        // Skip Blank lines
        
        if (tLineLength==0)
            return;
        
        // Find Key and Value
        
        NSScanner * tScanner=[NSScanner scannerWithString:bLine];
        
        NSString * tKey;
        
        if ([tScanner scanUpToString:@":" intoString:&tKey]==NO)
        {
            tError=[NSError errorWithDomain:CUIParsingErrorDomain code:CUIParsingUnknownError userInfo:@{CUIParsingErrorLineKey:@(bLineNumber)}];
            
            *bOutStop=YES;
            return;
        }
        
        NSUInteger tIndex=tScanner.scanLocation+1;
        
        if (tIndex>=(tLineLength-1))
        {
            tError=[NSError errorWithDomain:CUIParsingErrorDomain code:CUIParsingUnknownError userInfo:@{CUIParsingErrorLineKey:@(bLineNumber)}];
            
            *bOutStop=YES;
            return;
        }
        
        NSString * tValue=[[bLine substringFromIndex:tIndex] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if (tValue.length==0)
        {
            tError=[NSError errorWithDomain:CUIParsingErrorDomain code:CUIParsingUnknownError userInfo:@{CUIParsingErrorLineKey:@(bLineNumber)}];
            
            *bOutStop=YES;
            return;
        }
        
        // Retrieve values
        
        NSString * tString;
        pid_t tProcessIdentifier;
        
        if ([tKey isEqualToString:@"Process"]==YES)
        {
            if ([CUICrashLogHeader parseString:tValue processName:&tString identifier:&tProcessIdentifier]==NO)
            {
                tError=[NSError errorWithDomain:CUIParsingErrorDomain code:CUIParsingUnknownError userInfo:@{CUIParsingErrorLineKey:@(bLineNumber)}];
                
                *bOutStop=YES;
                return;
            }
            
            self.processName=tString;
            self.processIdentifier=tProcessIdentifier;
            
            return;
        }
        
        if ([tKey isEqualToString:@"Parent Process"]==YES)
        {
            if ([CUICrashLogHeader parseString:tValue processName:&tString identifier:&tProcessIdentifier]==NO)
            {
                tError=[NSError errorWithDomain:CUIParsingErrorDomain code:CUIParsingUnknownError userInfo:@{CUIParsingErrorLineKey:@(bLineNumber)}];
                
                *bOutStop=YES;
                return;
            }
            
            self.parentProcessName=tString;
            self.parentProcessIdentifier=tProcessIdentifier;
            
            return;
        }
        
        if ([tKey isEqualToString:@"Responsible"]==YES)
        {
            if ([CUICrashLogHeader parseString:tValue processName:&tString identifier:&tProcessIdentifier]==NO)
            {
                tError=[NSError errorWithDomain:CUIParsingErrorDomain code:CUIParsingUnknownError userInfo:@{CUIParsingErrorLineKey:@(bLineNumber)}];
                
                *bOutStop=YES;
                return;
            }
            
            self.responsibleProcessName=tString;
            self.responsibleProcessIdentifier=tProcessIdentifier;
            
            return;
        }
        
        if ([tKey isEqualToString:@"Date/Time"]==YES)
        {
            NSDate * tDate = [[CUICrashLogHeader crashDateFormatter] dateFromString:tValue];
            
            if (tDate==nil)
            {
                tError=[NSError errorWithDomain:CUIParsingErrorDomain code:CUIParsingDateTimeParsingError userInfo:@{CUIParsingErrorLineKey:@(bLineNumber)}];
                
                *bOutStop=YES;
                return;
            }
            
            self.dateTime=tDate;
            
            return;
        }
        
        NSInteger tInteger=0;
        
        if ([tKey isEqualToString:@"Report Version"]==YES)
        {
            if ([CUICrashLogHeader parseString:tValue integerValue:&tInteger]==NO)
            {
                tError=[NSError errorWithDomain:CUIParsingErrorDomain code:CUIParsingUnknownError userInfo:@{CUIParsingErrorLineKey:@(bLineNumber)}];
                
                *bOutStop=YES;
                return;
            }
            
            self.reportVersion=tInteger;
            
            return;
        }
        
        if ([tKey isEqualToString:@"User ID"]==YES)
        {
            if ([CUICrashLogHeader parseString:tValue integerValue:&tInteger]==NO)
            {
                tError=[NSError errorWithDomain:CUIParsingErrorDomain code:CUIParsingUnknownError userInfo:@{CUIParsingErrorLineKey:@(bLineNumber)}];
                
                *bOutStop=YES;
                return;
            }
            
            self.userIdentifier=(uid_t)tInteger;
            
            return;
        }
        
        if ([tKey isEqualToString:@"Path"]==YES)
        {
            self.executablePath=tValue;
            
            return;
        }
        
        if ([tKey isEqualToString:@"Identifier"]==YES)
        {
            self.bundleIdentifier=tValue;
            
            return;
        }
        
        if ([tKey isEqualToString:@"Version"]==YES)
        {
            self.executableVersion=tValue;
            
            return;
        }
        
        if ([tKey isEqualToString:@"Bridge OS Version"]==YES)
        {
            self.bridgeOSVersion=tValue;
            
            return;
        }
        
        if ([tKey isEqualToString:@"Anonymous UUID"]==YES)
        {
            self.anonymousUUID=tValue;
            
            return;
        }
        
        if ([tKey isEqualToString:@"OS Version"]==YES)
        {
            NSString * tPrefix=@"Mac OS X ";
            
            
            // A COMPLETER (Think iOS)
            
            if ([tValue hasPrefix:tPrefix]==NO)
            {
                tPrefix=@"macOS ";
                
                if ([tValue hasPrefix:tPrefix]==NO)
                {
                    tError=[NSError errorWithDomain:CUIParsingErrorDomain code:CUIParsingUnknownError userInfo:@{CUIParsingErrorLineKey:@(bLineNumber)}];
                    
                    *bOutStop=YES;
                    return;
                }
            }
            
            NSString * tVersion=[tValue substringFromIndex:tPrefix.length];
            
            CUIOperatingSystemVersion * tOperatingSystemVersion=[[CUIOperatingSystemVersion alloc] initWithString:tVersion];
            
            if (tOperatingSystemVersion==nil)
            {
                tError=[NSError errorWithDomain:CUIParsingErrorDomain code:CUIParsingUnknownError userInfo:@{CUIParsingErrorLineKey:@(bLineNumber)}];
                
                *bOutStop=YES;
                return;
            }
            
            self.operatingSystemVersion=tOperatingSystemVersion;
            
            return;
        }
        
        
        
        if ([tKey isEqualToString:@"Code Type"]==YES)
        {
            CUICodeType tCodeType;
            BOOL tNative;
            
            // X86-64 (Native)
            // X86 (Native)
            
            if ([CUICrashLogHeader parseString:tValue codeType:&tCodeType native:&tNative]==NO)
            {
                tError=[NSError errorWithDomain:CUIParsingErrorDomain code:CUIParsingUnknownError userInfo:@{CUIParsingErrorLineKey:@(bLineNumber)}];
                
                *bOutStop=YES;
                return;
            }
            
            self.codeType=tCodeType;
            self.native=tNative;
            
            return;
        }
        
        if ([tKey isEqualToString:@"System Integrity Protection"]==YES)
        {
            // A COMPLETER
            
            if ([tValue caseInsensitiveCompare:@"enabled"]==YES)
            {
                self.systemIntegrityProtectionEnabled=NO;
            }
            else if ([tValue caseInsensitiveCompare:@"disabled"]==YES)
            {
                self.systemIntegrityProtectionEnabled=NO;
            }
            
            return;
        }
    }];
    
    if (outError!=NULL && tError!=nil)
        *outError=tError;
    
    return YES;
}

@end
