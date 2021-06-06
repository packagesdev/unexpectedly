//
//  NSUserDefaults+NSUserDefaults_Unexpectedly.m
//  crashreport
//
//  Created by stephane on 03/06/2021.
//  Copyright © 2021 Whitebox. All rights reserved.
//

#import "NSUserDefaults+NSUserDefaults_Unexpectedly.h"

@implementation NSUserDefaults (NSUserDefaults_Unexpectedly)

+ (NSUserDefaults *)standardUserDefaults
{
    return [[NSUserDefaults alloc] initWithSuiteName:@"fr.whitebox.unexpectedly"];
}

@end
