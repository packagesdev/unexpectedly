//
//  CUIApplicationItemAttributes.h
//  Unexpectedly
//
//  Created by stephane on 08/03/2021.
//  Copyright © 2021 Acme, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CUIApplicationItemAttributes : NSObject

    @property (readonly) NSURL * applicationURL;

    @property NSString * displayName;

    @property NSString * bundleIdentifier;

    @property NSImage * icon;

    @property NSString * version;

    @property (nonatomic,readonly) NSMenuItem * applicationMenuItem;

    @property BOOL showsVersion;

    @property BOOL duplicate;

- (instancetype)initWithURL:(NSURL *)inApplicationURL;

- (NSComparisonResult)compare:(CUIApplicationItemAttributes *)inOther;

@end
