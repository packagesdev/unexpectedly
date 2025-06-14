/*
 Copyright (c) 2020-2022, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICrashLogBacktraces.h"

#import "CUIParsingErrors.h"

#import "NSArray+WBExtensions.h"

@interface CUICrashLogBacktraces ()
{
    NSMutableArray * _threads;
}

@property (readwrite) BOOL hasApplicationSpecificBacktrace;

- (BOOL)parseTextualRepresentation:(NSArray<NSString *> *)inLines outError:(NSError **)outError;

@end

@implementation CUICrashLogBacktraces

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
        _threads=[NSMutableArray array];
        
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
        NSMutableArray * tApplicationBacktracesThreads=[NSMutableArray array];
        
        _hasApplicationSpecificBacktrace=NO;
        
        IPSIncidentExceptionInformation * tExceptionInformation=inIncident.exceptionInformation;
        
        if (tExceptionInformation!=nil)
        {
            NSArray<IPSThreadFrame *> * tLastExceptionBacktrace=tExceptionInformation.lastExceptionBacktrace;
            
            if (tLastExceptionBacktrace.count>0)
            {
                NSError * tError;
                
                CUIThread * tThread=[[CUIThread alloc] initApplicationSpecificBacktraceWithThreadFrames:tLastExceptionBacktrace binaryImages:inIncident.binaryImages error:&tError];
                
                if (tThread==nil)
                {
                    return nil;
                }
                
                [tApplicationBacktracesThreads addObject:tThread];
                
                _hasApplicationSpecificBacktrace=YES;
            }
        }
        
        if (_hasApplicationSpecificBacktrace==NO)
        {
            IPSIncidentDiagnosticMessage * tDiagnosticMessage=inIncident.diagnosticMessage;
            
            if (tDiagnosticMessage!=nil)
            {
                IPSApplicationSpecificInformation * tApplicationSpecificInformation=tDiagnosticMessage.asi;
                
                if (tApplicationSpecificInformation.backtraces.count>0)
                {
                    NSArray * tApplicationSpecificBacktraces=tApplicationSpecificInformation.backtraces;
                    
                    [tApplicationSpecificBacktraces enumerateObjectsUsingBlock:^(NSString * bString, NSUInteger bIndex, BOOL * bOutStop) {
                       
                        NSMutableArray * tLines=[NSMutableArray arrayWithObject:@"Application Specific Backtrace 1"];
                        
                        [bString enumerateLinesUsingBlock:^(NSString * bLine, BOOL * bOutStop) {
                            
                            [tLines addObject:bLine];
                        }];
                        
                        NSError * tError;
                        
                        CUIThread * tThread=[[CUIThread alloc] initApplicationSpecificBacktraceWithTextualRepresentation:tLines error:&tError];
                        
                        if (tThread==nil)
                        {
                            *bOutStop=YES;
                            
                            return;
                        }
                        
                        [tApplicationBacktracesThreads addObject:tThread];
                        
                    }];
                    
                    // A COMPLETER
                    
                    _hasApplicationSpecificBacktrace=YES;
                }
            }
        }
        
        
        NSArray * tThreads=inIncident.threads;
        
        if (tThreads==nil)
        {
            // A COMPLETER
            
            return nil;
        }
            
        _threads=[[tThreads WB_arrayByMappingObjectsUsingBlock:^CUIThread *(IPSThread * bThread, NSUInteger bIndex) {
            
            CUIThread * tThread=[[CUIThread alloc] initWithIPSThread:bThread atIndex:bIndex binaryImages:inIncident.binaryImages error:NULL];
            
            if (tThread==nil)
            {
                // A COMPLETER
            }
            
            return tThread;
        }] mutableCopy];
        
        if (tApplicationBacktracesThreads.count>0)
        {
            [_threads insertObjects:tApplicationBacktracesThreads atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,tApplicationBacktracesThreads.count)]];
        }
    }
    
    return self;
}

#pragma mark -

- (CUIThread *)threadNamed:(NSString *)inName
{
    if (inName==nil)
        return nil;
    
    for(CUIThread * tThread in _threads)
    {
        if ([tThread.name isEqualToString:inName]==YES)
            return tThread;
    }
    
    return nil;
}

- (CUIThread *)threadWithNumber:(NSUInteger)inThreadNumber
{
    for(CUIThread * tThread in _threads)
    {
        if (tThread.isApplicationSpecificBacktrace==NO && tThread.number==inThreadNumber)
            return tThread;
    }
    
    return nil;
}

#pragma mark -

- (BOOL)parseTextualRepresentation:(NSArray<NSString *> *)inLines outError:(NSError **)outError
{
    if ([inLines.firstObject isEqualToString:@"Backtrace not available"]==YES)
        return YES;
    
    __block NSError * tError=nil;
    
    // Probably not as fast as block enumeration but the code is easier to follow.
    NSUInteger tLinesCount=inLines.count;
    NSUInteger tIndex=0;
    
    while (tIndex<tLinesCount && inLines[tIndex].length==0)
        tIndex++;
    
    while (tIndex<tLinesCount)
    {
        NSInteger tThreadEntityLineStart=tIndex;
        
        while (tIndex<tLinesCount && inLines[tIndex].length!=0)
            tIndex++;
        
        NSInteger tThreadEntityLineEnd=tIndex-1;
        
        CUIThread * tThread=[[CUIThread alloc] initWithTextualRepresentation:[inLines subarrayWithRange:NSMakeRange(tThreadEntityLineStart, tThreadEntityLineEnd-tThreadEntityLineStart+1)]
                                                                       error:&tError];
        
        if (tThread==nil)
            break;
        
        if (tThread.isApplicationSpecificBacktrace==YES)
            self.hasApplicationSpecificBacktrace=YES;
        
        [_threads addObject:tThread];
        
        while (tIndex<tLinesCount && inLines[tIndex].length==0)
            tIndex++;
    }
    
    if (tError!=nil)
    {
        if (outError!=NULL)
            *outError=tError;
    
        return NO;
    }
        
    return YES;
}

@end
