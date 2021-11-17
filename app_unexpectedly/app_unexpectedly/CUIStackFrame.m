/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIStackFrame.h"

NSString * const CUIStackFrameSymbolicationDidSucceedNotification=@"CUIStackFrameSymbolicationDidSucceedNotification";

@interface CUIStackFrame ()

    @property NSUInteger index;

    @property (copy) NSString * binaryImageIdentifier;

    @property NSUInteger machineInstructionAddress;

    @property (copy) NSString * symbol;

    @property NSUInteger byteOffset;

    @property (copy) NSString * sourceFile;

    @property NSUInteger lineNumber;

@end

@implementation CUIStackFrame

- (instancetype)initWithString:(NSString *)inString error:(NSError **)outError
{
    if ([inString isKindOfClass:[NSString class]]==NO)
    {
        if (outError!=NULL)
            *outError=[NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:@{}];
        
        return nil;
    }
    
    self=[super init];
    
    if (self!=nil)
    {
        NSUInteger tLength=inString.length;
        NSCharacterSet * tWhitespaceCharacterSet=[NSCharacterSet whitespaceCharacterSet];
        
        NSScanner * tScanner=[NSScanner scannerWithString:inString];
        
        tScanner.charactersToBeSkipped=tWhitespaceCharacterSet;
        
        NSInteger tInteger=-1;
        
        if ([tScanner scanInteger:&tInteger]==NO)
            return nil;
        
        _index=tInteger;
        
        tScanner.charactersToBeSkipped=[NSCharacterSet characterSetWithCharactersInString:@"\t"];
        
        NSString * tString=nil;
        
        NSUInteger tCurrentScanLocation=tScanner.scanLocation;
        
        if ([tScanner scanUpToString:@"0x" intoString:&tString]==NO)
            return nil;
        
        if (tScanner.scanLocation==tLength)
        {
            // try to find a \t
            
            tScanner.scanLocation=tCurrentScanLocation;
            
            if ([tScanner scanUpToString:@"\t" intoString:&tString]==NO)
                return nil;
        }
        
        _binaryImageIdentifier=[tString stringByTrimmingCharactersInSet:tWhitespaceCharacterSet];
        
        tScanner.charactersToBeSkipped=tWhitespaceCharacterSet;
        
        unsigned long long tHexaValue=0;
        
        if ([tScanner scanHexLongLong:&tHexaValue]==NO)
            return nil;
        
        _machineInstructionAddress=tHexaValue;
        
        if ([tScanner scanUpToString:@" +" intoString:&tString]==NO)
            return nil;
        
        _symbol=[tString copy];
        
        if ([tScanner scanInteger:&tInteger]==NO)
        {
            if ([_symbol isEqualToString:@"???"]==NO)
                return nil;
            
            tInteger=0;
        }
        
        _byteOffset=tInteger;
        
        if (tScanner.scanLocation<(tLength-3))
        {
            tScanner.charactersToBeSkipped=nil;
            
            if ([tScanner scanUpToString:@"(" intoString:NULL]==YES)
            {
                tScanner.scanLocation+=1;
                
                NSString * tFileReference=nil;
                
                if ([tScanner scanUpToString:@")" intoString:&tFileReference]==YES)
                {
                    NSRange tRange=[tFileReference rangeOfString:@":" options:NSBackwardsSearch];
                    
                    if (tRange.location==NSNotFound)
                    {
                        _sourceFile=[tFileReference copy];
                    }
                    else
                    {
                        _sourceFile=[tFileReference substringToIndex:tRange.location];
                        
                        _lineNumber=[[tFileReference substringFromIndex:tRange.location+1] integerValue];
                    }
                }
            }
        }
        
    }
    
    return self;
}

- (instancetype)initWithThreadFrame:(IPSThreadFrame *)inFrame atIndex:(NSUInteger)inIndex image:(IPSImage *)inImage error:(NSError **)outError
{
    if ([inFrame isKindOfClass:[IPSThreadFrame class]]==NO ||
        [inImage isKindOfClass:[IPSImage class]]==NO)
    {
        if (outError!=NULL)
            *outError=[NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:@{}];
        
        return nil;
    }
    
    self=[super init];
    
    if (self!=nil)
    {
        _index=inIndex;
        
        _binaryImageIdentifier=[(inImage.bundleIdentifier!=nil) ? inImage.bundleIdentifier : inImage.name copy];
        
        _machineInstructionAddress=inImage.loadAddress+inFrame.imageOffset;
        
        if (inFrame.symbol!=nil)
        {
            _symbol=[inFrame.symbol copy];
            _byteOffset=inFrame.symbolLocation;
        }
        else
        {
            _symbol=[NSString stringWithFormat:@"0x%lx",(unsigned long)inImage.loadAddress];
            
            _byteOffset=_machineInstructionAddress-inImage.loadAddress;
        }
        
        _sourceFile=[inFrame.sourceFile copy];
        
        _lineNumber=inFrame.sourceLine;
    }
    
    return self;
}

#pragma mark -

- (CUIStackFrame *)stackFrameCloneWithBinaryImageIdentifier:(NSString *)inBinaryImageIdentifier
{
    CUIStackFrame * tStackFrameClone=[self copy];
    
    tStackFrameClone.binaryImageIdentifier=inBinaryImageIdentifier;
    
    return tStackFrameClone;
}


#pragma mark -

- (NSString *)description
{
    return [NSString stringWithFormat:@"%lu %@ 0x%lx %@ + %lu",self.index,self.binaryImageIdentifier,(unsigned long)self.machineInstructionAddress,self.symbol,self.byteOffset];
}

#pragma mark - NSCopying

- (id)copyWithZone:(nullable NSZone *)zone
{
    CUIStackFrame * nStackFrame=[CUIStackFrame new];
    
    nStackFrame.index=self.index;
    
    nStackFrame.binaryImageIdentifier=[self.binaryImageIdentifier copy];
    
    nStackFrame.machineInstructionAddress=self.machineInstructionAddress;
    
    nStackFrame.symbol=[self.symbol copy];
    
    nStackFrame.byteOffset=self.byteOffset;
    
    nStackFrame.sourceFile=[self.sourceFile copy];
    
    nStackFrame.lineNumber=self.lineNumber;
    
    return nStackFrame;
}

@end
