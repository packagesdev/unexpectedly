/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICrashLogSectionsDetector.h"

@implementation CUICrashLogSectionsDetector

+ (NSRange)detectHeaderSectionRangeInTextualRepresentation:(NSArray *)inLines atIndexes:(NSIndexSet *)inIndexes
{
    __block NSRange tRange={.location=NSNotFound,.length=0};
    
    // Find the "Exception Information" section start
    
    [inLines enumerateObjectsAtIndexes:inIndexes options:0 usingBlock:^(NSString * bLine , NSUInteger bLineNumber, BOOL * bOutStop) {
        
        if ([bLine hasPrefix:@"Crashed Thread:"]==YES ||
            [bLine hasPrefix:@"Exception Type:"]==YES)
        {
            NSUInteger tFirstLine=inIndexes.firstIndex;
            NSUInteger tLastLine=bLineNumber-1;
            
            tRange=NSMakeRange(tFirstLine, tLastLine-tFirstLine+1);
            
            *bOutStop=YES;
            
            return;
        }
    }];
    
    return tRange;
}

+ (NSRange)detectExceptionInformationSectionRangeInTextualRepresentation:(NSArray *)inLines atIndexes:(NSIndexSet *)inIndexes
{
    __block NSRange tRange={.location=NSNotFound,.length=0};
    
    // Find the "Diagnostic Message" or "Backtrace" section start
    
    [inLines enumerateObjectsAtIndexes:inIndexes options:0 usingBlock:^(NSString * bLine , NSUInteger bLineNumber, BOOL * bOutStop) {
        
        if ([bLine hasPrefix:@"Application Specific Information:"]==YES ||
            [bLine hasPrefix:@"VM Regions Near"]==YES ||
            
            [bLine isEqualToString:@"Backtrace not available"]==YES ||
            
            [bLine hasPrefix:@"Application Specific Backtrace"]==YES ||
            [bLine hasPrefix:@"Thread 0"]==YES)
        {
            NSUInteger tFirstLine=inIndexes.firstIndex;
            NSUInteger tLastLine=bLineNumber-1;
            
            tRange=NSMakeRange(tFirstLine, tLastLine-tFirstLine+1);
            
            *bOutStop=YES;
            
            return;
        }
    }];
    
    return tRange;
}

+ (NSRange)detectDiagnosticMessageSectionRangeInTextualRepresentation:(NSArray *)inLines atIndexes:(NSIndexSet *)inIndexes
{
    __block NSRange tRange={.location=NSNotFound,.length=0};
    
    // Find the "Backtrace" or "Thread State" or "Binary Images" section start
    
    [inLines enumerateObjectsAtIndexes:inIndexes options:0 usingBlock:^(NSString * bLine , NSUInteger bLineNumber, BOOL * bOutStop) {
        
        if ([bLine hasPrefix:@"Application Specific Backtrace"]==YES ||
            [bLine hasPrefix:@"Thread 0"]==YES ||
            
            ([bLine hasPrefix:@"Thread"]==YES && [bLine rangeOfString:@"crashed with"].location !=NSNotFound) ||
            
            [bLine rangeOfString:@"Binary Images" options:NSCaseInsensitiveSearch].location==0
            )
        {
            NSUInteger tFirstLine=inIndexes.firstIndex;
            NSUInteger tLastLine=bLineNumber-1;
            
            tRange=NSMakeRange(tFirstLine, tLastLine-tFirstLine+1);
            
            *bOutStop=YES;
            
            return;
        }
    }];
    
    return tRange;
}

+ (NSRange)detectBacktracesSectionRangeInTextualRepresentation:(NSArray *)inLines atIndexes:(NSIndexSet *)inIndexes
{
    __block NSRange tRange={.location=NSNotFound,.length=0};
    
    // Find the "Thread State" or "Binary Images" section start
    
    [inLines enumerateObjectsAtIndexes:inIndexes options:0 usingBlock:^(NSString * bLine , NSUInteger bLineNumber, BOOL * bOutStop) {
        
        if ((([bLine hasPrefix:@"Thread"]==YES || [bLine hasPrefix:@"Unknown"]==YES) && [bLine rangeOfString:@"crashed with"].location !=NSNotFound) ||
            
            [bLine rangeOfString:@"Binary Images" options:NSCaseInsensitiveSearch].location==0
            )
        {
            NSUInteger tFirstLine=inIndexes.firstIndex;
            NSUInteger tLastLine=bLineNumber-1;
            
            tRange=NSMakeRange(tFirstLine, tLastLine-tFirstLine+1);
            
            *bOutStop=YES;
            
            return;
        }
    }];
    
    return tRange;
}

+ (NSRange)detectThreadStateSectionRangeInTextualRepresentation:(NSArray *)inLines atIndexes:(NSIndexSet *)inIndexes
{
    __block NSRange tRange={.location=NSNotFound,.length=0};
    
    // Find the "Thread State" or "Binary Images" section start
    
    [inLines enumerateObjectsAtIndexes:inIndexes options:0 usingBlock:^(NSString * bLine , NSUInteger bLineNumber, BOOL * bOutStop) {
        
        if ([bLine rangeOfString:@"Binary Images" options:NSCaseInsensitiveSearch].location==0)
        {
            NSUInteger tFirstLine=inIndexes.firstIndex;
            NSUInteger tLastLine=bLineNumber-1;
            
            tRange=NSMakeRange(tFirstLine, tLastLine-tFirstLine+1);
            
            *bOutStop=YES;
            
            return;
        }
    }];
    
    return tRange;
}

+ (NSRange)detectBinaryImagesSectionRangeInTextualRepresentation:(NSArray *)inLines atIndexes:(NSIndexSet *)inIndexes
{
    NSUInteger tFirstLine=inIndexes.firstIndex;
    NSUInteger tLastLine=inIndexes.lastIndex;
    
    NSRange tRange=NSMakeRange(tFirstLine, tLastLine-tFirstLine+1);
    
    return tRange;
}

@end
