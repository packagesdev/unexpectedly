/*
 Copyright (c) 2022, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIExceptionTypePopUpViewController.h"

@interface CUIExceptionTypePopUpViewController ()

@property (copy) NSString * exceptionType;

@property (copy) NSString * exceptionSignal;

@end

@implementation CUIExceptionTypePopUpViewController

- (void)setExceptionType:(NSString *)inType signal:(NSString *)inSignal
{
    NSURL * tURL=nil;
    
    if (inType!=nil && inSignal!=nil)
    {
        tURL=[self.bundle URLForResource:[NSString stringWithFormat:@"%@_%@",inType,inSignal] withExtension:@"html"];
    }
    
    if (tURL==nil)
    {
        // Use no documentation file
        
        tURL=[self.bundle URLForResource:@"unknown_exception_type" withExtension:@"html"];
    }
    
    self.contentsFileURL=tURL;
}

@end
