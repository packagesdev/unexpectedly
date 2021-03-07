/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIThemeItemAttributes.h"

#import "NSColor+String.h"

NSString * const CUIThemeAttributeColorKey=@"color";

NSString * const CUIThemeAttributeFontKey=@"font";


NSString * const CUIThemeItemAttributesDidChangeNotification=@"CUIThemeItemAttributesDidChangeNotification";


@implementation CUIThemeItemAttributes

- (instancetype)initWithRepresentation:(NSDictionary *)inRepresentation
{
    if ([inRepresentation isKindOfClass:[NSDictionary class]]==NO)
        return nil;
    
    self=[super init];
    
    if (self!=nil)
    {
        NSString * tString=inRepresentation[CUIThemeAttributeColorKey];
        
        if ([tString isKindOfClass:[NSString class]]==NO)
            return nil;
        
        _color=[NSColor colorFromString:tString];
        
        tString=inRepresentation[CUIThemeAttributeFontKey];
        
        if (tString!=nil)
        {
            if ([tString isKindOfClass:[NSString class]]==NO)
                return nil;
            
        
            NSArray * tComponents=[tString componentsSeparatedByString:@"::"];
            
            _font=[NSFont fontWithName:tComponents[0] size:[tComponents[1] floatValue]];
            
            if (_font==nil)
                _font=[NSFont systemFontOfSize:11.0];
        }
    }
    
    return self;
}

#pragma mark -

- (NSDictionary *)representation
{
    return @{
             CUIThemeAttributeColorKey:self.color.stringValue,
             
             CUIThemeAttributeFontKey:[NSString stringWithFormat:@"%@::%0.1f",self.font.fontName,self.font.pointSize]
            };
}

#pragma mark -

- (void)setFont:(NSFont *)inFont
{
    if (_font!=inFont)
    {
        _font=inFont;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:CUIThemeItemAttributesDidChangeNotification object:self];
    }
}

- (void)setColor:(NSColor *)inColor
{
    if (_color!=inColor)
    {
        _color=inColor;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:CUIThemeItemAttributesDidChangeNotification object:self];
    }
}

#pragma mark - NSCopying

- (id)copyWithZone:(nullable NSZone *)zone
{
    CUIThemeItemAttributes * nThemeItemAttributes=[CUIThemeItemAttributes new];
    
    nThemeItemAttributes.color=[self.color copy];
    
    nThemeItemAttributes.font=[self.font copy];
    
    return nThemeItemAttributes;
}

@end
