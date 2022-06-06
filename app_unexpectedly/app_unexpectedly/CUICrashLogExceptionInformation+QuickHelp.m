/*
 Copyright (c) 2022, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICrashLogExceptionInformation+QuickHelp.h"

NSString * const CUITerminationReasonSignalNamespace=@"SIGNAL";                         // OS_REASON_SIGNAL
NSString * const CUITerminationReasonCodesigningNamespace=@"CODESIGNING";               // OS_REASON_CODESIGNING
NSString * const CUITerminationReasonDyldNamespace=@"DYLD";                             // OS_REASON_DYLD
NSString * const CUITerminationReasonLibXPCNamespace=@"LIBXPC";                         // OS_REASON_LIBXPC
NSString * const CUITerminationReasonLibSystemNamespace=@"LIBSYSTEM";                   // OS_REASON_LIBSYSTEM
NSString * const CUITerminationReasonWatchdogNamespace=@"WATCHDOG";                     // OS_REASON_WATCHDOG
NSString * const CUITerminationReasonEndpointSecurityNamespace=@"ENDPOINTSECURITY";     // OS_REASON_ENDPOINTSECURITY

typedef NS_ENUM(NSUInteger, CUITerminationReasonEndpointSecurityCode)
{
    CUITerminationReasonEndpointSecurityProcessBlockedByESClient = 1,
    CUITerminationReasonEndpointSecurityESClientRequestTimedOut = 2
};

@implementation CUICrashLogExceptionInformation (QuickHelp)

- (BOOL)isQuickHelpAvailableForTerminationReason
{
    if ([self.terminationNamespace isEqualToString:CUITerminationReasonEndpointSecurityNamespace]==YES)
    {
        switch(self.terminationCode)
        {
            case 2:
                return YES;
                
            default:
                
                break;
        }
        
        return NO;
    }
    
    if ([self.terminationNamespace isEqualToString:CUITerminationReasonLibSystemNamespace]==YES)   // libkern/os/reason_private.h
    {
        switch(self.terminationCode)
        {
            case 2: // OS_REASON_LIBSYSTEM_CODE_FAULT
                return NO;  // A COMPLETER
                
            default:
                
                break;
        }
        
        return NO;
    }
    
    if ([self.terminationNamespace isEqualToString:CUITerminationReasonWatchdogNamespace]==YES)
    {
        switch(self.terminationCode)
        {
            case 1:
                return NO;  // A COMPLETER
                
            default:
                
                break;
        }
        
        return NO;
    }
    
    if ([self.terminationNamespace isEqualToString:CUITerminationReasonCodesigningNamespace]==YES)     // bsd/sys/reason.h
    {
        switch(self.terminationCode)
        {
            case 1: // CODESIGNING_EXIT_REASON_TASKGATED_INVALID_SIG
                return NO;  // A COMPLETER
                
            case 2: // CODESIGNING_EXIT_REASON_INVALID_PAGE
                return NO;  // A COMPLETER
            
            default:
                
                break;
        }
        
        return NO;
    }
    
    if ([self.terminationNamespace isEqualToString:CUITerminationReasonDyldNamespace]==YES)   // dyld/include/mach-o/dyld_priv.h
    {
        switch(self.terminationCode)
        {
            case 1: // DYLD_EXIT_REASON_DYLIB_MISSING
                return NO;  // A COMPLETER
            
            case 2: // DYLD_EXIT_REASON_DYLIB_WRONG_ARCH
                return NO;  // A COMPLETER
                
            default:
                
                break;
        }
        
        return NO;
    }
    
    if ([self.terminationNamespace isEqualToString:CUITerminationReasonLibXPCNamespace]==YES)   // dyld/include/mach-o/dyld_priv.h
    {
        switch(self.terminationCode)
        {
            case 4:
                return NO;  // A COMPLETER
                
            default:
                
                break;
        }
        
        return NO;
    }
    
    return NO;
}

@end
