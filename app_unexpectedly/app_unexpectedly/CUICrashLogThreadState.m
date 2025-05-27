/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICrashLogThreadState.h"

#import "CUIParsingErrors.h"

#import "IPSThreadState+RegisterDisplayName.h"

#import "NSArray+WBExtensions.h"

#import "NSString+CPU.h"

@interface CUICrashLogThreadState ()

    @property NSUInteger threadIndex;

    @property cpu_type_t CPUType;

    @property NSArray * registers;

    @property NSUInteger logicalCPU;

    @property NSUInteger errorCode;

    @property NSUInteger trapNumber;

- (BOOL)parseTextualRepresentation:(NSArray *)inLines outError:(NSError **)outError;

@end

@implementation CUICrashLogThreadState

- (instancetype)initWithTextualRepresentation:(NSArray *)inLines reportVersion:(NSUInteger)inReportVersion error:(NSError **)outError
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
        _registers=@[];
        
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
        IPSThreadState * tThreadState=inIncident.threadState;
        
        if (tThreadState==nil)
        {
            if (outError!=NULL)
                *outError=nil;
            
            return nil;
        }
        
        _threadIndex=inIncident.exceptionInformation.faultingThread;
        
        IPSIncidentHeader * tHeader=inIncident.header;
        
        _CPUType=[tHeader.cpuType CUI_CPUType];
        
        NSArray * tRegistersOrder;
        
        if ([tThreadState.flavor isEqualToString:@"x86_THREAD_STATE"]==YES)
        {
            tRegistersOrder=@[@"rax",@"rbx",@"rcx",@"rdx",
                              @"rdi",@"rsi",@"rbp",@"rsp",
                              @"r8",@"r9",@"r10",@"r11",
                              @"r12",@"r13",@"r14",@"r15",
                              @"rip",@"rflags",@"cr2"
                              ];
        }
        else
        {
            tRegistersOrder=@[@"x0",@"x1",@"x2",@"x3",
                              @"x4",@"x5",@"x6",@"x7",
                              @"x8",@"x9",@"x10",@"x11",
                              @"x12",@"x13",@"x14",@"x15",
                              @"x16",@"x17",@"x18",@"x19",
                              @"x20",@"x21",@"x22",@"x23",
                              @"x24",@"x25",@"x26",@"x27",
                              @"x28",@"fp",@"lr",
                              @"sp",@"pc",@"cpsr",
                              @"far",@"esr"
                              ];
        }
        
        _registers=[tRegistersOrder WB_arrayByMappingObjectsUsingBlock:^id(NSString * bRegisterName, NSUInteger bIndex) {
            
            IPSRegisterState * tRegisterState=tThreadState.registersStates[bRegisterName];
            
            if (tRegisterState!=nil)
            {
                CUIRegister * tRegister=[CUIRegister new];
                tRegister.name=[IPSThreadState displayNameForRegisterName:bRegisterName];
                tRegister.value=tRegisterState.value;
                
                return tRegister;
            }
            
            return nil;
            
        }];
        
        // A COMPLETER
        
        /*_logicalCPU=;
        
        _errorCode=;
        
        _trapNumber=;*/
    }
    
    return self;
}

- (BOOL)parseTextualRepresentation:(NSArray *)inLines outError:(NSError **)outError
{
    __block NSError * tError=nil;
    
    // Scan the first line
    
    NSCharacterSet * tWhitespaceCharacterSet=[NSCharacterSet whitespaceCharacterSet];
    
    NSScanner * tScanner=[NSScanner scannerWithString:inLines.firstObject];

    tScanner.charactersToBeSkipped=tWhitespaceCharacterSet;

    if ([tScanner scanString:@"Thread " intoString:NULL]==NO)
        return NO;

    // Thread Index

    NSInteger tInteger=-1;

    if ([tScanner scanInteger:&tInteger]==YES)
    {
        self.threadIndex=tInteger;
    
        if ([tScanner scanString:@"crashed with " intoString:NULL]==NO)
            return NO;

        // Architecture

        NSString * tString;

        if ([tScanner scanUpToString:@"Thread State" intoString:&tString]==NO)
            return NO;
        
        tString=[tString stringByTrimmingCharactersInSet:tWhitespaceCharacterSet];
        
        if ([tString isEqualToString:@"ARM"]==YES)
        {
            self.CPUType=CPU_TYPE_ARM;
        }
        else if ([tString isEqualToString:@"X86"]==YES)
        {
            self.CPUType=CPU_TYPE_X86;
        }
        
        tScanner.scanLocation+=[@"Thread State" length];
        
        if ([tScanner scanUpToString:@":" intoString:&tString]==NO)
            return NO;
        
        tString=[tString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"()"]];
        
        if ([tString isEqualToString:@"64-bit"]==YES)
            self.CPUType|=CPU_ARCH_ABI64;
    }
    else
    {
        if ([inLines.firstObject hasPrefix:@"Thread State"]==NO)
            return NO;
        
        self.threadIndex=NSNotFound;
        
        self.CPUType=CPU_TYPE_ANY;
    }
    
    // Registers values

    NSMutableArray * tMutableArray=[NSMutableArray array];

    __block NSUInteger tEndOfRegisterValues=NSNotFound;
    
    [inLines enumerateObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1,inLines.count-1)]
                               options:0
                            usingBlock:^(NSString * bLine, NSUInteger bLineNumber, BOOL * bOutStop) {
                                
                                if (bLine.length<4)
                                {
                                    tEndOfRegisterValues=bLineNumber+1;
                                    
                                    *bOutStop=YES;
                                    return;
                                }
                                
                                NSScanner * tRegistersScanner=[NSScanner scannerWithString:bLine];
                                
                                tRegistersScanner.charactersToBeSkipped=tWhitespaceCharacterSet;
                                
                                while (tRegistersScanner.isAtEnd==NO)
                                {
                                    NSString * tRegisterName;
                                    
                                    if ([tRegistersScanner scanUpToString:@":" intoString:&tRegisterName]==NO)
                                        return;
                                    
                                    if ([tRegistersScanner scanString:@": " intoString:NULL]==NO)
                                        return;
                                    
                                    unsigned long long tRegisterValue;
                                    
                                    if ([tRegistersScanner scanHexLongLong:&tRegisterValue]==NO)
                                        return;
                                    
                                    
                                    CUIRegister * tRegister=[CUIRegister new];
                                    
                                    tRegister.name=tRegisterName;
                                    tRegister.value=tRegisterValue;
                                    
                                    [tMutableArray addObject:tRegister];
                                }
                            }];

    self.registers=[tMutableArray copy];

    if (tEndOfRegisterValues==NSNotFound || (tEndOfRegisterValues==(inLines.count-1)))
        return YES;
    
    // Other keys-values
    
    [inLines enumerateObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(tEndOfRegisterValues+1,inLines.count-1-(tEndOfRegisterValues+1)+1)]
                               options:0
                            usingBlock:^(NSString * bLine, NSUInteger bLineNumber, BOOL * bOutStop) {
                                
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
                                
                                NSString * tValue=[[bLine substringFromIndex:tIndex] stringByTrimmingCharactersInSet:tWhitespaceCharacterSet];
                                
                                if (tValue.length==0)
                                {
                                    tError=[NSError errorWithDomain:CUIParsingErrorDomain code:CUIParsingUnknownError userInfo:@{CUIParsingErrorLineKey:@(bLineNumber)}];
                                    
                                    *bOutStop=YES;
                                    return;
                                }
                                
                                if ([tKey isEqualToString:@"Logical CPU"]==YES)
                                {
                                    NSScanner * tScanner=[NSScanner scannerWithString:tValue];
                                    
                                    unsigned long long tValue;
                                    
                                    if ([tScanner scanUnsignedLongLong:&tValue]==NO)
                                    {
                                        tError=[NSError errorWithDomain:CUIParsingErrorDomain code:CUIParsingUnknownError userInfo:@{CUIParsingErrorLineKey:@(bLineNumber)}];
                                        
                                        *bOutStop=YES;
                                        
                                        return;
                                    }
                                    
                                    self.logicalCPU=tValue;
                                    
                                    return;
                                }
                                else if ([tKey isEqualToString:@"Error Code"]==YES)
                                {
                                    NSScanner * tScanner=[NSScanner scannerWithString:tValue];
                                    
                                    unsigned long long tHexaValue;
                                    
                                    if ([tScanner scanHexLongLong:&tHexaValue]==NO)
                                    {
                                        tError=[NSError errorWithDomain:CUIParsingErrorDomain code:CUIParsingUnknownError userInfo:@{CUIParsingErrorLineKey:@(bLineNumber)}];
                                        
                                        *bOutStop=YES;
                                        
                                        return;
                                    }
                                    
                                    self.errorCode=tHexaValue;
                                    
                                    return;
                                }
                                else if ([tKey isEqualToString:@"Trap Number"]==YES)
                                {
                                    NSScanner * tScanner=[NSScanner scannerWithString:tValue];
                                    
                                    unsigned long long tValue;
                                    
                                    if ([tScanner scanUnsignedLongLong:&tValue]==NO)
                                    {
                                        tError=[NSError errorWithDomain:CUIParsingErrorDomain code:CUIParsingUnknownError userInfo:@{CUIParsingErrorLineKey:@(bLineNumber)}];
                                        
                                        *bOutStop=YES;
                                        
                                        return;
                                    }
                                    
                                    self.trapNumber=tValue;
                                    
                                    return;
                                }
                            }];
    
    if (outError!=NULL && tError!=nil)
        *outError=tError;
    
    return YES;
}

@end
