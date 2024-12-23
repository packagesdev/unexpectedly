/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICollectionViewRegisterItem.h"

#import "CUIRegister.h"

#import "CUIRegisterLabel.h"

#define MACOS_BIGSUR_WIDTH_INSET   3.0

NSString * const CUIRegisterItemViewAsValueDidChangeNotification=@"CUIRegisterItemViewAsValueDidChangeNotification";

@interface CUICollectionViewRegisterItem () <CUIRegisterLabelDelegate>
{
    IBOutlet NSTextField * _registerNameLabel;
    
    IBOutlet CUIRegisterLabel * _registerValueLabel;
    
    IBOutlet NSPopUpButton* _registerValueDisplayFormatPopUpButton;
}
@end

@implementation CUICollectionViewRegisterItem

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (NSAppKitVersionNumber>0/*2022.00*/)  // A VERIFIER
    {
        // Deal with macOS Big Sur different UI metrics
    
        NSRect tFrame=_registerValueDisplayFormatPopUpButton.frame;
    
        tFrame.origin.x+=MACOS_BIGSUR_WIDTH_INSET;
        tFrame.size.width-=MACOS_BIGSUR_WIDTH_INSET;
        
        _registerValueDisplayFormatPopUpButton.frame=tFrame;
    }
}

#pragma mark -

- (NSString *)toolTipForRegisterName:(NSString *)inRegisterName
{
    if (inRegisterName==nil)
        return nil;
    
    static NSDictionary * sRegistersExpandedNamesRegistry=nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sRegistersExpandedNamesRegistry=@{
                                          @"cpsr":@"Current Program Status Register",
                                          @"cr2":@"Control Register 2",
                                          @"esr":@"Exception Syndrome Register",
                                          @"far":@"Fault Address Register",
                                          @"lr":@"Link Register",
                                          @"pc":@"Program Counter",
                                          @"rbp":@"Register Base Pointer",
                                          @"rdi":@"Register Destination Index",
                                          @"rip":@"Instruction Pointer Register",
                                          @"rsi":@"Register Source Index",
                                          @"rsp":@"Register Stack Pointer",
                                          @"sp":@"Stack Pointer",
                                          };
        
    });
    
    return sRegistersExpandedNamesRegistry[inRegisterName.lowercaseString];
}

- (void)setRepresentedObject:(id)inRepresentedObject
{
    [super setRepresentedObject:inRepresentedObject];
    
    if (inRepresentedObject==nil)
        return;
    
    NSDictionary * tRepresentation=(NSDictionary *)inRepresentedObject;
    
    CUIRegister * tRegister=(CUIRegister *)tRepresentation[@"register"];
    
    if (tRegister.name==nil)
    {
        NSLog(@"Missing register name");
        
        return;
    }
    
    _registerNameLabel.stringValue=[NSString stringWithFormat:NSLocalizedString(@"%@:",@""),tRegister.name];
    _registerNameLabel.toolTip=[self toolTipForRegisterName:tRegister.name];
    
    _registerValueLabel.delegate=self;
    _registerValueLabel.registerValue=tRegister.value;
    
    CUIRegisterViewValueAsType tType=CUIRegisterViewValueAsHex;
    
    NSNumber * tRegisterViewAs=tRepresentation[@"viewAs"];
    
    if (tRegisterViewAs!=nil)
        tType=[tRegisterViewAs unsignedIntegerValue];
    
    _registerValueLabel.viewValueAs=tType;
}

#pragma mark -

- (void)registerLabel:(CUIRegisterLabel *)inRegisterLabel viewValueAsDidChange:(CUIRegisterViewValueAsType)inType
{
    NSDictionary * tRepresentation=(NSDictionary *)self.representedObject;
    
    CUIRegister * tRegister=(CUIRegister *)tRepresentation[@"register"];
    
    if (tRegister==nil)
        return;
    
    // Post Notification
    
    [NSNotificationCenter.defaultCenter postNotificationName:CUIRegisterItemViewAsValueDidChangeNotification
                                                      object:tRegister
                                                    userInfo:@{
                                                               @"viewAs":@(inType)
                                                               }];
}

@end
