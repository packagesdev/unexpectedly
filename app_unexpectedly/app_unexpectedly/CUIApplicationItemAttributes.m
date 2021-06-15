/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


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
