/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIThemeItemsGroup+UI.h"

NSString * const CUIThemeItemBackground=@"background";
NSString * const CUIThemeItemSelectionBackground=@"selection-background";
NSString * const CUIThemeItemSelectionText=@"selection-text";
NSString * const CUIThemeItemPlainText=@"plaintext";
NSString * const CUIThemeItemKey=@"key";
NSString * const CUIThemeItemThreadLabel=@"threadLabel";
NSString * const CUIThemeItemCrashedThreadLabel=@"crashedThreadLabel";
NSString * const CUIThemeItemExecutableCode=@"executableCode";
NSString * const CUIThemeItemOSCode=@"OSCode";
NSString * const CUIThemeItemMemoryAddress=@"memoryAddress";
NSString * const CUIThemeItemRegisterValue=@"registerValue";
NSString * const CUIThemeItemPath=@"path";
NSString * const CUIThemeItemVersion=@"version";
NSString * const CUIThemeItemUUID=@"uuid";
NSString * const CUIThemeItemLineNumber=@"lineNumber";

@implementation CUIThemeItemsGroup (UI)

+ (NSString *)displayNameForItemNamed:(NSString *)inItemName
{
    static NSDictionary * sDisplayedNames=nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sDisplayedNames=@{
                          CUIThemeItemBackground: NSLocalizedString(@"Background",@""),
                          CUIThemeItemPlainText: NSLocalizedString(@"Plain Text",@""),
                          CUIThemeItemKey: NSLocalizedString(@"Key",@""),
                          CUIThemeItemThreadLabel: NSLocalizedString(@"Thread Label",@""),
                          CUIThemeItemCrashedThreadLabel: NSLocalizedString(@"Crashed Thread Label",@""),
                          CUIThemeItemExecutableCode: NSLocalizedString(@"Executable Code",@""),
                          CUIThemeItemOSCode: NSLocalizedString(@"OS Code",@""),
                          CUIThemeItemMemoryAddress: NSLocalizedString(@"Memory Address",@""),
                          CUIThemeItemRegisterValue: NSLocalizedString(@"Register Value",@""),
                          CUIThemeItemPath: NSLocalizedString(@"File Path",@""),
                          CUIThemeItemVersion: NSLocalizedString(@"Version",@""),
                          CUIThemeItemUUID: NSLocalizedString(@"UUID",@""),
                          CUIThemeItemLineNumber: NSLocalizedString(@"Line Number",@"")
                          };
        
    });
    
    NSString * tString=sDisplayedNames[inItemName];
    
    if (tString==nil)
        tString=inItemName;
    
    return tString;
}

@end
