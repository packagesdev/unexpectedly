//
//  CUIRawCrashLog+Path.m
//  Unexpectedly
//
//  Created by stephane on 13/03/2021.
//  Copyright © 2021 Acme, Inc. All rights reserved.
//

#import "CUIRawCrashLog+Path.h"

NSString * const CUIUSERHomeFolderPath=@"/Users/USER/";

@implementation CUIRawCrashLog (Path)

- (NSString *)stringByResolvingUSERInPath:(NSString *)inPath
{
    if (self.USERPathComponent==nil)
        return inPath;
    
    if ([inPath hasPrefix:CUIUSERHomeFolderPath]==NO)
        return inPath;
    
    return [NSString stringWithFormat:@"/Users/%@/%@",self.USERPathComponent,[inPath substringFromIndex:CUIUSERHomeFolderPath.length]];
}

@end
