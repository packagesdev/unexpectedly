//
//  CUITerminationReasonPopUpViewController.m
//  Unexpectedly
//
//  Created by stephane on 02/06/2022.
//  Copyright © 2022 Acme, Inc. All rights reserved.
//

#import "CUITerminationReasonPopUpViewController.h"

@interface CUITerminationReasonPopUpViewController ()

@property (copy) NSString * namespace;

@property NSUInteger code;

@end

@implementation CUITerminationReasonPopUpViewController

- (void)setNamespace:(NSString *)inNameSpace code:(NSUInteger)inCode;
{
    NSURL * tURL=nil;
    
    inNameSpace=@"ENDPOINTSECURITY";
    inCode=2;
    
    if (inNameSpace!=nil && inCode!=NSNotFound)
    {
        tURL=[self.bundle URLForResource:[NSString stringWithFormat:@"%@_%lu",inNameSpace,(unsigned long)inCode] withExtension:@"html"];
    }
    
    if (tURL==nil)
    {
        // Use no documentation file
        
        tURL=[self.bundle URLForResource:@"unknown_termination_reason" withExtension:@"html"];
    }
    
    self.contentsFileURL=tURL;
}

@end
