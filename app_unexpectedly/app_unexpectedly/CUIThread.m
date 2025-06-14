/*
 Copyright (c) 2020-2025, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIThread.h"

@interface CUIThread ()

    @property BOOL crashed;

    @property NSUInteger number;

    @property (copy) NSString * name;

    @property CUICallStackBacktrace * callStackBacktrace;

@end

@implementation CUIThread

- (instancetype)initWithTextualRepresentation:(NSArray *)inLines error:(NSError **)outError
{
	if ([inLines isKindOfClass:[NSArray class]]==NO)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:@{}];
		
		return nil;
	}
	
    if (inLines.count==0)
    {
        if (outError!=NULL)
            *outError=[NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:@{}];
        
        return nil;
    }
    
	self=[super init];
	
	if (self!=nil)
	{
		NSString * tHeaderLine=inLines.firstObject;
		
        if ([tHeaderLine hasPrefix:@"Application Specific Backtrace"]==YES)
        {
            _applicationSpecificBackTrace=YES;
            
            _name=@"Application Specific Backtrace";
        }
        else
        {
            NSArray * tComponents=[tHeaderLine componentsSeparatedByString:@"::"];
            NSString * tLeftPart;
            
            if (tComponents.count==0)
            {
                // Uh oh
                
                return nil;
            }
            
            if (tComponents.count==1)
            {
                NSRange tRange=[tHeaderLine rangeOfString:@"Dispatch queue:"];
                
                if (tRange.location!=NSNotFound)
                {
                    tComponents=@[[tHeaderLine substringToIndex:tRange.location],
                                  [tHeaderLine substringFromIndex:tRange.location]];
                }
            }
            
            tLeftPart=tComponents.firstObject;
            
            if (tComponents.count==2)
            {
                _name=[tComponents[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            }
            else
            {
                tLeftPart=[tLeftPart stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@":"]];
            }
            
            NSArray * tThreadNumberComponents=[tLeftPart componentsSeparatedByString:@" "];
            
            if (tThreadNumberComponents.count<2)
            {
                // Uh oh
                
                // A COMPLETER
            }
            
            _number=[tThreadNumberComponents[1] integerValue];
            
            if (tThreadNumberComponents.count==3)
            {
                if ([tThreadNumberComponents[2] caseInsensitiveCompare:@"Crashed"]==NSOrderedSame)
                    _crashed=YES;
            }
        }
        
		// backtrace
		
		_callStackBacktrace=[[CUICallStackBacktrace alloc] initWithTextualRepresentation:[inLines subarrayWithRange:NSMakeRange(1,inLines.count-1)] error:outError];
		
		if (_callStackBacktrace==nil)
			return nil;
		
	}
	
	return self;
}

- (instancetype)initApplicationSpecificBacktraceWithTextualRepresentation:(NSArray *)inLines error:(NSError **)outError
{
    self=[self initWithTextualRepresentation:inLines error:outError];
    
    if (self!=nil)
    {
        _crashed=NO;
        
        _applicationSpecificBackTrace=YES;
        
        _name=@"Application Specific Backtrace";
    }
    
    return self;
}

- (instancetype)initApplicationSpecificBacktraceWithThreadFrames:(NSArray<IPSThreadFrame *> *)inFrames binaryImages:(NSArray<IPSImage *> *)inImages error:(NSError **)outError
{
    self=[super init];
    
    if (self!=nil)
    {
        _crashed=NO;
        
        _applicationSpecificBackTrace=YES;
        
        _name=@"Application Specific Backtrace";
        
        _callStackBacktrace=[[CUICallStackBacktrace alloc] initWithFrames:inFrames binaryImages:inImages error:outError];
        
        if (_callStackBacktrace==nil)
        {
            return nil;
        }
    }
    
    return self;
}

- (instancetype)initWithIPSThread:(IPSThread *)inThread atIndex:(NSUInteger)inIndex binaryImages:(NSArray<IPSImage *> *)inImages error:(NSError **)outError
{
    if ([inThread isKindOfClass:[IPSThread class]]==NO)
    {
        if (outError!=NULL)
            *outError=[NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:@{}];
        
        return nil;
    }
    
    self=[super init];
    
    if (self!=nil)
    {
        _crashed=inThread.triggered;
        
        _number=inIndex;
        
        if (inThread.queue!=nil)
            _name=[NSString stringWithFormat:@"Dispatch queue: %@",inThread.queue];
        
        _callStackBacktrace=[[CUICallStackBacktrace alloc] initWithFrames:inThread.frames binaryImages:inImages error:NULL];
        
        if (_callStackBacktrace==nil)
        {
            // A COMPLETER
        }
    }
    
    return self;
}

#pragma mark -

- (NSString *)description
{
	if (_applicationSpecificBackTrace==YES)
        return [NSString stringWithFormat:@"%@ 1\n%@",self.name,self.callStackBacktrace];
    else
        return [NSString stringWithFormat:@"Thread %ld %@ :: Dispatch queue: %@\n%@",self.number,(self.isCrashed==YES) ? @"(Crashed)": @"",self.name,self.callStackBacktrace];
}

@end
