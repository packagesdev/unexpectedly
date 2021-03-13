//
//  CUIRawCrashLog+Path.h
//  Unexpectedly
//
//  Created by stephane on 13/03/2021.
//  Copyright © 2021 Acme, Inc. All rights reserved.
//

#import "CUIRawCrashLog.h"

@interface CUIRawCrashLog (Path)

- (NSString *)stringByResolvingUSERInPath:(NSString *)inPath;

@end
