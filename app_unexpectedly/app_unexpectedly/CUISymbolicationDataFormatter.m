/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUISymbolicationDataFormatter.h"

@implementation CUISymbolicationDataFormatter

+ (NSString *)localizedStringFromSymbolicationData:(CUISymbolicationData *)inSymbolicationData symbolStyle:(CUISymbolicationDataFormatterStyle)inSymbolStyle pathStyle:(CUISymbolicationDataFormatterStyle)inPathStyle coordinatesStyle:(CUISymbolicationDataFormatterStyle)inCoordinatesStyle options:(CUISymbolicationDataFormatterOptions)inOptions
{
    CUISymbolicationDataFormatter * tFormatter=[CUISymbolicationDataFormatter new];
    
    tFormatter.symbolStyle=inSymbolStyle;
    tFormatter.pathStyle=inPathStyle;
    tFormatter.coordinatesStyle=inCoordinatesStyle;
    tFormatter.options=inOptions;
    
    return [tFormatter stringForObjectValue:inSymbolicationData];
}

#pragma mark -

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _symbolStyle=CUISymbolicationDataFormatterFullStyle;
        _pathStyle=CUISymbolicationDataFormatterShortStyle;
        _coordinatesStyle=CUISymbolicationDataFormatterShortStyle;
        
        _options=CUISymbolicationDataFormatterOptionDefaults;
    }
    
    return self;
}

- (NSString *)stringForObjectValue:(CUISymbolicationData *)inSymbolicationData
{
    if ([inSymbolicationData isKindOfClass:CUISymbolicationData.class]==NO)
        return nil;
    
    NSMutableString * tMutableString=[NSMutableString string];
    
    // stack frame symbol
    
    switch(self.symbolStyle)
    {
        case CUISymbolicationDataFormatterNoStyle:
            
            break;
            
        case CUISymbolicationDataFormatterShortStyle:
            
            [tMutableString appendFormat:@"%@",inSymbolicationData.stackFrameSymbol];
            
            break;
            
        case CUISymbolicationDataFormatterFullStyle:
            
            [tMutableString appendFormat:@"%@ + %lu",inSymbolicationData.stackFrameSymbol,inSymbolicationData.byteOffset];
            
            break;
    }
    
    // source file
    
    if (self.pathStyle==CUISymbolicationDataFormatterNoStyle)
        return [tMutableString copy];
    
    if (self.symbolStyle!=CUISymbolicationDataFormatterNoStyle)
        [tMutableString appendString:@" ("];
    
    switch(self.pathStyle)
    {
        case CUISymbolicationDataFormatterShortStyle:
            
            [tMutableString appendFormat:@"%@",inSymbolicationData.sourceFilePath.lastPathComponent];
            
            break;
            
        case CUISymbolicationDataFormatterFullStyle:
            
            [tMutableString appendFormat:@"%@",inSymbolicationData.sourceFilePath];
            
            break;
            
        default:
            
            break;
    }
    
    if (self.coordinatesStyle==CUISymbolicationDataFormatterNoStyle || inSymbolicationData.lineNumber==0)
    {
        if (self.symbolStyle!=CUISymbolicationDataFormatterNoStyle)
            [tMutableString appendString:@")"];
        
        return [tMutableString copy];
    }
    
    switch(self.coordinatesStyle)
    {
        case CUISymbolicationDataFormatterShortStyle:
            
            [tMutableString appendFormat:@":%lu",inSymbolicationData.lineNumber];
            
            break;
            
        case CUISymbolicationDataFormatterFullStyle:
            
            [tMutableString appendFormat:@" - %@ %lu",NSLocalizedString(@"line",@""),inSymbolicationData.lineNumber];
            
            break;
            
        default:
            
            break;
    }
    
    if ((self.options & CUISymbolicationDataFormatterOptionAlwaysHidesColumnNumber)==0 && inSymbolicationData.columnNumber!=0)
    {
        switch(self.coordinatesStyle)
        {
            case CUISymbolicationDataFormatterShortStyle:
                
                [tMutableString appendFormat:@"[%lu]",inSymbolicationData.columnNumber];
                
                break;
                
            case CUISymbolicationDataFormatterFullStyle:
                
                [tMutableString appendFormat:@" : %@ %lu",NSLocalizedString(@"column",@""),inSymbolicationData.columnNumber];
                
                break;
                
            default:
                
                break;
        }
    }
    
    if (self.symbolStyle!=CUISymbolicationDataFormatterNoStyle)
        [tMutableString appendString:@")"];
    
    return [tMutableString copy];
}

@end
