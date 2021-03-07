/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUISwiftDemangler.h"

#include <dlfcn.h>

/*size_t (*swift_demangle_getDemangledName)(const char *MangledName,
                                       char *OutputBuffer, size_t Length);*/

size_t (*swift_demangle_getSimplifiedDemangledName)(const char *MangledName,
                                                 char *OutputBuffer,
                                                 size_t Length);

/*size_t (*swift_demangle_getModuleName)(const char *MangledName,
                                    char *OutputBuffer,
                                    size_t Length);*/

/*int (*swift_demangle_hasSwiftCallingConvention)(const char *MangledName);*/

@implementation CUISwiftDemangler

+ (NSString *)demangle:(NSString *)inMangledName
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        void * tFileHandle= dlopen("/usr/lib/swift/libswiftDemangle.dylib", RTLD_LAZY);
        
        if (tFileHandle==NULL)
        {
            tFileHandle= dlopen("/System/Library/PrivateFrameworks/Swift/libswiftDemangle.dylib", RTLD_LAZY);
            
            if (tFileHandle==NULL)
            {
            }
        }
        
        swift_demangle_getSimplifiedDemangledName=dlsym(tFileHandle,"swift_demangle_getSimplifiedDemangledName");
    });
    
    char tBuffer[2048];
    
    if (swift_demangle_getSimplifiedDemangledName(inMangledName.UTF8String,tBuffer,2048)==0)
        return nil;
    
    NSString * tDemangledName=[NSString stringWithUTF8String:tBuffer];
    
    return tDemangledName;
}

@end
