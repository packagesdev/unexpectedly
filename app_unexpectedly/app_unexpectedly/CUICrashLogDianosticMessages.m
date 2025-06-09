/*
 Copyright (c) 2020-2022, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICrashLogDianosticMessages.h"

#import "IPSIncident+ApplicationSpecificInformation.h"

#import "CUIParsingErrors.h"

@interface CUICrashLogDianosticMessages ()

    @property (copy) NSString * messages;

@end

@implementation CUICrashLogDianosticMessages

- (instancetype)initWithTextualRepresentation:(NSArray *)inLines reportVersion:(NSUInteger)inReportVersion error:(NSError **)outError
{
    if ([inLines isKindOfClass:NSArray.class]==NO)
    {
        if (outError!=NULL)
            *outError=[NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:@{}];
        
        return nil;
    }
    
    self=[super init];
    
    _messages=@"";
    
    if ([self parseTextualRepresentation:inLines outError:outError]==NO)
    {
        return nil;
    }

    return self;
}

- (instancetype)initWithIPSIncident:(IPSIncident *)inIncident error:(NSError **)outError
{
    if ([inIncident isKindOfClass:IPSIncident.class]==NO)
    {
        if (outError!=NULL)
            *outError=[NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:@{}];
        
        return nil;
    }
    
    self=[super init];
    
    if (self!=nil)
    {
        IPSIncidentDiagnosticMessage * tDiagnosticMessage=inIncident.diagnosticMessage;
        
        if (tDiagnosticMessage!=nil)
        {
            NSMutableString * tMessages=[NSMutableString string];
            
            // VM Region Info
            
            if (tDiagnosticMessage.vmregioninfo!=nil)
            {
                [tMessages appendFormat:@"VM Region Info: %@\n",tDiagnosticMessage.vmregioninfo];
                
                [tMessages appendString:@"\n"];
            }
            
            // Application Specific Information
            
            NSArray<NSString *> * tApplicationSpecificInformationMessage = [inIncident applicationSpecificInformationMessage];
            
            if (tApplicationSpecificInformationMessage.count>0)
            {
                [tMessages appendString:@"Application Specific Information:\n"];
                
                [tMessages appendString:[tApplicationSpecificInformationMessage componentsJoinedByString:@"\n"]];
                
                 [tMessages appendString:@"\n"];
            }
            
            // Application Specific Signatures
            
            NSArray<NSString *> * tSignatures = tDiagnosticMessage.asi.signatures;
            
            if (tSignatures)
            {
                [tMessages appendString:@"Application Specific Signatures:\n"];
                
                for(NSString * tSignature in tSignatures)
                    [tMessages appendFormat:@"%@\n",tSignature];
            }
            
            _messages=[tMessages copy];
        }
    }
    
    return self;
}

#pragma mark -

- (BOOL)parseTextualRepresentation:(NSArray *)inLines outError:(NSError **)outError
{
    __block NSError * tError=nil;
    
    NSString * tFirstLine=inLines.firstObject;
    
    NSMutableIndexSet * tMutableIndexSet=[NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0,inLines.count)];
    
    if ([tFirstLine hasPrefix:@"Application Specific Information:"]==YES)
    {
        [tMutableIndexSet removeIndex:0];
    }
    
    _messages=[[inLines objectsAtIndexes:tMutableIndexSet] componentsJoinedByString:@"\n"];
    
    
    if (outError!=NULL && tError!=nil)
        *outError=tError;
    
    return YES;
}

@end
