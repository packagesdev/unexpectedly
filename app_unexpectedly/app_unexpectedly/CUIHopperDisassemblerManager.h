//
//  CUIHopperDisassemblerManager.h
//  Unexpectedly
//
//  Created by stephane on 09/03/2021.
//  Copyright © 2021 Acme, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CUIApplicationItemAttributes.h"

#include "CUICodeType.h"

@protocol CUIHopperDisassemblerActions

- (IBAction)openWithHopperDisassembler:(id)sender;

@end

@interface CUIHopperDisassemblerManager : NSObject

+ (CUIHopperDisassemblerManager *)sharedManager;

- (NSMenu *)availableApplicationsMenuWithTarget:(id<CUIHopperDisassemblerActions>)inTarget;

- (BOOL)openBinaryImage:(NSString *)inPath withApplicationAttributes:(CUIApplicationItemAttributes *)inApplicationAttributes codeType:(CUICodeType)inCodeType fileOffSet:(void *)inOffset;

@end
