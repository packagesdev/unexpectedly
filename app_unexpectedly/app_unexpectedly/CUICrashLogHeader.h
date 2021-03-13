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

#import "CUIOperatingSystemVersion.h"

#include "CUICodeType.h"

@interface CUICrashLogHeader : NSObject

    @property (readonly) NSUInteger reportVersion;

    @property (readonly) NSDate * dateTime;

    @property (readonly) CUIOperatingSystemVersion * operatingSystemVersion;

    @property (readonly) BOOL systemIntegrityProtectionEnabled;

    @property (readonly,copy) NSString * bridgeOSVersion;       // T2 Embedded OS Version (can be nil)



    @property (readonly,copy) NSString * anonymousUUID;





    @property (readonly) CUICodeType codeType;

    @property (readonly) BOOL native;


    @property (readonly,copy) NSString * executablePath;

    @property (readonly,copy) NSString * bundleIdentifier;

    @property (readonly,copy) NSString * executableVersion;



    @property (readonly,copy) NSString * responsibleProcessName;

    @property (readonly) pid_t responsibleProcessIdentifier;

    @property (readonly,copy) NSString * processName;

    @property (readonly) pid_t processIdentifier;

    @property (readonly,copy) NSString * parentProcessName;

    @property (readonly) pid_t parentProcessIdentifier;



    @property (readonly) uid_t userIdentifier;


- (instancetype)initWithTextualRepresentation:(NSArray *)inLines error:(NSError **)outError;

@end
