//
//  IPSImage+Offset.m
//  crashreport
//
//  Created by stephane on 21/02/2022.
//  Copyright © 2022 Whitebox. All rights reserved.
//

#import "IPSImage+Offset.h"

@implementation IPSImage (Offset)

- (NSUInteger)binaryImageOffset
{
    NSUInteger tLoadAddress=self.loadAddress;
    
    if (tLoadAddress>0x7fff00000000/* || self.mainImage==NO*/)
        return tLoadAddress;
    
    return (tLoadAddress-0x100000000);
}

@end
