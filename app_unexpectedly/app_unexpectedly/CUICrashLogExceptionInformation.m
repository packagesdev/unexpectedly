/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICrashLogExceptionInformation.h"

#import "CUIParsingErrors.h"

@interface CUICrashLogExceptionInformation ()

    @property NSInteger crashedThreadIndex;     // -1 -> Unknown

    @property (copy) NSString * crashedThreadName;

    @property (copy) NSString * exceptionType;

    @property (copy) NSString * exceptionSignal;

    @property (copy) NSString * exceptionSubtype;

    @property NSArray * exceptionCodes;

    @property (copy) NSString * exceptionNote;

+ (BOOL)parseString:(NSString *)inString threadIndex:(NSInteger *)outThreadIndex threadName:(NSString **)outThreadName;

+ (BOOL)parseString:(NSString *)inString exceptionType:(NSString **)outExceptionType signal:(NSString **)outExceptionSignal;

+ (BOOL)parseString:(NSString *)inString exceptionCodes:(NSArray **)outExceptionCodes;

- (BOOL)parseTextualRepresentation:(NSArray *)inLines outError:(NSError **)outError;

@end

@implementation CUICrashLogExceptionInformation

+ (BOOL)parseString:(NSString *)inString threadIndex:(NSInteger *)outThreadIndex threadName:(NSString **)outThreadName
{
    if ([inString isEqualToString:@"Unknown"]==YES)
    {
        if (outThreadIndex!=NULL)
            *outThreadIndex=-1;
        
        if (outThreadName!=NULL)
            *outThreadName=nil;
        
        return YES;
    }
    
    NSScanner * tScanner=[NSScanner scannerWithString:inString];
    
    NSInteger tInteger;
    
    if ([tScanner scanInteger:&tInteger]==NO)
    {
        // A COMPLETER
        
        return NO;
    }
    
    if (outThreadIndex!=NULL)
        *outThreadIndex=tInteger;
    
    NSString * tString=[[inString substringFromIndex:tScanner.scanLocation] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (outThreadName!=NULL)
        *outThreadName=tString;
    
    return YES;
}

+ (BOOL)parseString:(NSString *)inString exceptionType:(NSString **)outExceptionType signal:(NSString **)outExceptionSignal
{
    NSScanner * tScanner=[NSScanner scannerWithString:inString];
    
    NSString * tString;
    
    if ([tScanner scanUpToString:@" (" intoString:&tString]==NO || tString.length==inString.length)
    {
        if (outExceptionType!=NULL)
            *outExceptionType=[inString copy];
        
        return YES;
    }
    
    if (outExceptionType!=NULL)
        *outExceptionType=[tString copy];
    
    NSString * tSubString=[inString substringWithRange:NSMakeRange(tScanner.scanLocation+2,inString.length-2-(tScanner.scanLocation+2)+1)];
    
    if (outExceptionSignal!=NULL)
        *outExceptionSignal=tSubString;
    
    return YES;
}

+ (BOOL)parseString:(NSString *)inString exceptionCodes:(NSArray **)outExceptionCodes
{
    NSArray * tComponents=[inString componentsSeparatedByString:@","];
    
    NSMutableArray * tMutableArray=[NSMutableArray array];
    
    for(NSString * tCodeString in tComponents)
    {
        NSScanner * tScanner=[NSScanner scannerWithString:tCodeString];
        
        unsigned long long tHexaValue;
        
        if ([tScanner scanHexLongLong:&tHexaValue]==NO)
        {
            return NO;
        }
        
        [tMutableArray addObject:@(tHexaValue)];
    }
    
    if (outExceptionCodes!=NULL)
        *outExceptionCodes=[tMutableArray copy];
    
    return YES;
}

#pragma mark -

- (instancetype)initWithTextualRepresentation:(NSArray *)inLines reportVersion:(NSUInteger)inReportVersion error:(NSError **)outError
{
    if ([inLines isKindOfClass:[NSArray class]]==NO)
    {
        if (outError!=NULL)
            *outError=[NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:@{}];
        
        return nil;
    }
    
    self=[super init];
    
    if (self!=nil)
    {
        _crashedThreadIndex=-1;
        
        if ([self parseTextualRepresentation:inLines outError:outError]==NO)
        {
            return nil;
        }
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
        
        if ([tKey isEqualToString:@"Crashed Thread"]==YES)
        {
            NSInteger tInteger;
            NSString * tString;
            
            if ([CUICrashLogExceptionInformation parseString:tValue threadIndex:&tInteger threadName:&tString]==NO)
            {
                tError=[NSError errorWithDomain:CUIParsingErrorDomain code:CUIParsingUnknownError userInfo:@{CUIParsingErrorLineKey:@(bLineNumber)}];
                
                *bOutStop=YES;
                return;
            }
            
            self.crashedThreadIndex=tInteger;
            self.crashedThreadName=tString;
            
            return;
        }
        
        if ([tKey isEqualToString:@"Exception Type"]==YES)
        {
            NSString * tExceptionType=nil;
            NSString * tExceptionSignal=nil;
            
            if ([CUICrashLogExceptionInformation parseString:tValue exceptionType:&tExceptionType signal:&tExceptionSignal]==NO)
            {
                tError=[NSError errorWithDomain:CUIParsingErrorDomain code:CUIParsingUnknownError userInfo:@{CUIParsingErrorLineKey:@(bLineNumber)}];
                
                *bOutStop=YES;
                
                return;
            }
            
            self.exceptionType=tExceptionType;
            self.exceptionSignal=tExceptionSignal;
            
            return;
        }
        
        if ([tKey isEqualToString:@"Exception Subtype"]==YES)
        {
            self.exceptionSubtype=tValue;
            
            return;
        }
        
        if ([tKey isEqualToString:@"Exception Codes"]==YES)
        {
            NSArray * tExceptionCodes=nil;
            
            if ([CUICrashLogExceptionInformation parseString:tValue exceptionCodes:&tExceptionCodes]==NO)
            {
                tError=[NSError errorWithDomain:CUIParsingErrorDomain code:CUIParsingUnknownError userInfo:@{CUIParsingErrorLineKey:@(bLineNumber)}];
                
                *bOutStop=YES;
                
                return;
            }
            
            self.exceptionCodes=tExceptionCodes;
            
            return;
        }
        
        if ([tKey isEqualToString:@"Exception Note"]==YES)
        {
            self.exceptionNote=tValue;
            
            return;
        }
    }];
    
    if (outError!=NULL && tError!=nil)
        *outError=tError;
    
    return YES;
}

            //Exception Type:        EXC_CRASH (Code Signature Invalid)
            //Exception Codes:       0x0000000000000000, 0x0000000000000000
            //Exception Note:        EXC_CORPSE_NOTIFY

#pragma mark -

- (NSString *)displayedExceptionType
{
    if (self.exceptionSignal==nil)
        return self.exceptionType;
    
    return [NSString stringWithFormat:@"%@ (%@)",self.exceptionType,self.exceptionSignal];
}

@end
