/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>

#import "CUIStackFrameComponents.h"

typedef NS_OPTIONS(NSUInteger, CUIDocumentSections)
{
    CUIDocumentHeaderSection = 1 << 0,
    CUIDocumentExceptionInformationSection = 1 << 1,
    CUIDocumentDiagnosticMessagesSection = 1 << 2,
    CUIDocumentBacktracesSection = 1 << 3,
    CUIDocumentThreadStateSection = 1 << 4,
    CUIDocumentBinaryImagesSection = 1 << 5,
    
    
    CUIDocumentAllSections=0x3F,
    
    // Sub-sections
    
    CUIDocumentBacktraceCrashedThreadSubSection = 1 << 24
};


@interface CUITextModeDisplaySettings : NSObject <NSCopying>

    @property CUIDocumentSections visibleSections;

    @property CUIStackFrameComponents visibleStackFrameComponents;

- (instancetype)initWithRepresentation:(NSDictionary *)inDictionary;

- (NSDictionary *)representation;

@end
