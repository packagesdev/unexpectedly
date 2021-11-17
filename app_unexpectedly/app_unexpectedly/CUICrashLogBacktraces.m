/*
 Copyright (c) 2020-2021, Stephane Sudre
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

- (BOOL)parseTextualRepresentation:(NSArray *)inLines outError:(NSError **)outError;

@end

@implementation CUICrashLogBacktraces

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
    if ([inIncident isKindOfClass:[IPSIncident class]]==NO)
    {
        if (outError!=NULL)
            *outError=[NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:@{}];
        
        return nil;
    }
    
    self=[super init];
    
    if (self!=nil)
    {
        NSArray * tThreads=inIncident.threads;
        
        if (tThreads==nil)
        {
            // A COMPLETER
            
            return nil;
        }
        
        //_hasApplicationSpecificBacktrace=;
        
        _threads=[[tThreads WB_arrayByMappingObjectsUsingBlock:^CUIThread *(IPSThread * bThread, NSUInteger bIndex) {
            
            CUIThread * tThread=[[CUIThread alloc] initWithIPSThread:bThread atIndex:bIndex binaryImages:inIncident.binaryImages error:NULL];
            
            if (tThread==nil)
            {
                // A COMPLETER
            }
            
            return tThread;
        }] mutableCopy];
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

- (BOOL)parseTextualRepresentation:(NSArray *)inLines outError:(NSError **)outError
{
    if ([inLines.firstObject isEqualToString:@"Backtrace not available"]==YES)
        return YES;
    
    __block NSError * tError=nil;
    
    __block NSInteger tThreadEntityLineStart=0;
    __block NSInteger tThreadEntityLineEnd=0;
    
    [inLines enumerateObjectsUsingBlock:^(NSString * bLine, NSUInteger bLineNumber, BOOL *bOutStop) {
        
        // Retrieve thread number, crashed status and dispatch queue name
        
        if (bLine.length!=0)
            return;
        
        tThreadEntityLineEnd=bLineNumber-1;
        
        CUIThread * tThread=[[CUIThread alloc] initWithTextualRepresentation:[inLines subarrayWithRange:NSMakeRange(tThreadEntityLineStart, tThreadEntityLineEnd-tThreadEntityLineStart+1)]
                                                                       error:&tError];
        
        if (tThread==nil)
        {
            *bOutStop=YES;
            
            return;
        }
        
        if (tThread.isApplicationSpecificBacktrace==YES)
            self.hasApplicationSpecificBacktrace=YES;
        
        [self->_threads addObject:tThread];

        
        tThreadEntityLineStart=bLineNumber+1;
    }];
    
    if (tError!=nil)
    {
        if (outError!=NULL)
            *outError=tError;
    
        return NO;
    }
        
    return YES;
}

@end
