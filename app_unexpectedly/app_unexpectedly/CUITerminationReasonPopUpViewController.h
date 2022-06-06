//
//  CUITerminationReasonPopUpViewController.h
//  Unexpectedly
//
//  Created by stephane on 02/06/2022.
//  Copyright © 2022 Acme, Inc. All rights reserved.
//

#import "CUIQuickHelpPopUpViewController.h"

@interface CUITerminationReasonPopUpViewController : CUIQuickHelpPopUpViewController

@property (readonly,copy) NSString * namespace;

@property (readonly) NSUInteger code;

- (void)setNamespace:(NSString *)inNameSpace code:(NSUInteger)inCode;

@end
