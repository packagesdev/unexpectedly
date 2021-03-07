/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIOperatingSystemVersion.h"

@interface CUIOperatingSystemVersion ()

    @property NSInteger majorVersion;

    @property NSInteger minorVersion;

    @property NSInteger patchVersion;

    @property (copy) NSString * buildNumber;

@end

@implementation CUIOperatingSystemVersion

- (instancetype)initWithString:(NSString *)inString
{
    if ([inString isKindOfClass:[NSString class]]==NO)
        return nil;
    
    self=[super init];
    
    if (self!=nil)
    {
        NSArray * tComponents=[inString componentsSeparatedByString:@" "];
        
        if (tComponents.count==0 || [tComponents.firstObject length]==0)
            return nil;
        
        NSString * tNumericVersion=tComponents.firstObject;
        
        NSArray * tVersionComponents=[tNumericVersion componentsSeparatedByString:@"."];
        NSUInteger tComponentsCount=tVersionComponents.count;
        
        _majorVersion=[tVersionComponents[0] integerValue];
        
        if (tComponentsCount>1)
            _minorVersion=[tVersionComponents[1] integerValue];
        
        if (tComponentsCount>2)
            _patchVersion=[tVersionComponents[2] integerValue];
        
        if (tComponents.count>1)
            _buildNumber=[tComponents[1] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"()"]];
    }
    
    return self;
}

#pragma mark -

- (NSString *)stringValue
{
    return [NSString stringWithFormat:@"%ld.%ld.%ld",self.majorVersion,self.minorVersion,self.patchVersion];
}

@end
