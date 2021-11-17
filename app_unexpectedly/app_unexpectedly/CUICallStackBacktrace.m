/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICallStackBacktrace.h"

#import "NSArray+WBExtensions.h"

@interface CUICallStackBacktrace ()

	@property NSArray * stackFrames;

@end

@implementation CUICallStackBacktrace

- (instancetype)initWithTextualRepresentation:(NSArray *)inLines error:(NSError **)outError
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
		__block NSError * tError=nil;
        
        _stackFrames=[inLines WB_arrayByMappingObjectsUsingBlock:^id(NSString * bLine, NSUInteger bLineNumber) {
			
			CUIStackFrame * tCall=[[CUIStackFrame alloc] initWithString:bLine error:&tError];
			
			if (tCall==nil)
			{
                NSLog(@"Error parsing line: %@",bLine);
                
                return nil;
			}
			
			return tCall;
		}];
		
		if (_stackFrames==nil)
        {
            if (outError!=NULL)
                *outError=tError;
            
			return nil;
        }
	}
	
	return self;
}

- (instancetype)initWithFrames:(NSArray<IPSThreadFrame *> *)inFrames binaryImages:(NSArray<IPSImage *> *)inImages error:(NSError **)outError
{
    if ([inFrames isKindOfClass:[NSArray class]]==NO)
    {
        if (outError!=NULL)
            *outError=[NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:@{}];
        
        return nil;
    }
    
    self=[super init];
    
    if (self!=nil)
    {
        _stackFrames=[inFrames WB_arrayByMappingObjectsUsingBlock:^CUIStackFrame *(IPSThreadFrame * bFrame, NSUInteger bIndex) {
            
            CUIStackFrame * tStackFrame=[[CUIStackFrame alloc] initWithThreadFrame:bFrame
                                                                           atIndex:bIndex
                                                                             image:inImages[bFrame.imageIndex]
                                                                             error:NULL];
            
            if (tStackFrame==nil)
            {
                return nil;
            }
            
            return tStackFrame;
            
        }];
    }
    
    return self;
}

#pragma mark -

- (NSString *)description
{
	return self.stackFrames.description;
}

@end
