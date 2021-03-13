//
//  CUIApplicationItemAttributes.m
//  Unexpectedly
//
//  Created by stephane on 08/03/2021.
//  Copyright © 2021 Acme, Inc. All rights reserved.
//

#import "CUIApplicationItemAttributes.h"

@implementation CUIApplicationItemAttributes

- (instancetype)initWithURL:(NSURL *)inApplicationURL
{
    if (inApplicationURL.isFileURL==NO)
        return nil;
    
    self=[super init];
    
    if (self!=nil)
    {
        _applicationURL=inApplicationURL;
        
        _icon=[[NSWorkspace sharedWorkspace] iconForFile:inApplicationURL.path];
        
        if (_icon!=nil)
            _icon.size=NSMakeSize(16.0f,16.0f);
        
        _displayName=[[NSFileManager defaultManager] displayNameAtPath:inApplicationURL.path];
        
        // Get Version
        
        NSBundle * tBundle=[NSBundle bundleWithURL:inApplicationURL];
        NSString * tVersion=@"1.0";
        
        if (tBundle!=nil)
        {
            _bundleIdentifier=tBundle.bundleIdentifier;
            
            NSDictionary * tInfoDictionary;
            
            tInfoDictionary=[tBundle infoDictionary];
            
            if (tInfoDictionary!=nil)
            {
                tVersion=[tInfoDictionary objectForKey:@"CFBundleShortVersionString"];
                
                if (tVersion==nil)
                {
                    tVersion=@"1.0";
                }
            }
        }
        
        _version=tVersion;
    }
    
    return self;
}

#pragma mark -

- (NSMenuItem *)applicationMenuItem
{
    NSString * tTitle=(self.showsVersion==YES) ? [NSString stringWithFormat:@"%@ (%@)",self.displayName,self.version] : self.displayName;
    
    NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:tTitle
                                                      action:nil
                                               keyEquivalent:@""];
    
    tMenuItem.image=self.icon;
    tMenuItem.representedObject=self;
    
    return tMenuItem;
}

#pragma mark -

- (NSComparisonResult)compare:(CUIApplicationItemAttributes *)inOther
{
    NSComparisonResult tResult=NSOrderedSame;
    
    if ([self.bundleIdentifier isEqualToString:inOther.bundleIdentifier]==YES)
    {
        self.showsVersion=YES;
        inOther.showsVersion=YES;
    }
    else
    {
        tResult=[self.displayName caseInsensitiveCompare:inOther.displayName];
    }
    
    if (tResult!=NSOrderedSame)
        return tResult;
    
    // Compare version
    
    tResult=[self.version caseInsensitiveCompare:inOther.version];
    
    if (tResult==NSOrderedSame)
    {
        if ([self.applicationURL.path hasPrefix:@"/Volumes/"]==YES)
            self.duplicate=YES;
        else
            inOther.duplicate=YES;
    }
    
    return -tResult;
}

@end
