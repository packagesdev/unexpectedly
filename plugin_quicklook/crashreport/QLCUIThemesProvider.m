/*
 Copyright (c) 2021-2025, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

// Category to replace the init and currentTheme methods as defined in the main application.
// For the preview and thumbnail, use the default theme UUID.

#import "QLCUIThemesProvider.h"

static NSMutableDictionary<NSString *, CUITheme *> * sQLThemeRegistry=nil;

NSString * const QLCUIThemesQuickLookGeneratorThemeUUIDKey=@"themes.quicklook-generator.UUID";

@implementation QLCUIThemesProvider

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{
                                                                 QLCUIThemesQuickLookGeneratorThemeUUIDKey:@"UUID2"
                                                                  
                                                                  }];
        
        sQLThemeRegistry=[NSMutableDictionary dictionary];
        
        NSArray * tThemesArray=[NSArray arrayWithContentsOfURL:[[NSBundle bundleForClass:QLCUIThemesProvider.class] URLForResource:@"default_themes" withExtension:@"plist"]];
        
        for (NSDictionary * tThemeRepresentation in tThemesArray)
        {
            CUITheme * tTheme=[[CUITheme alloc] initWithRepresentation:tThemeRepresentation];
            
            if (tTheme==nil)
            {
                NSLog(@"Archive representation of theme could not be loaded");
                
                return nil;
            }
            
            sQLThemeRegistry[tTheme.UUID]=tTheme;
        }
    }
    
    return self;
}

#pragma mark -

- (NSArray<CUITheme *> *)allThemes
{
    return sQLThemeRegistry.allValues;
}

- (CUITheme *)currentTheme
{
    return sQLThemeRegistry[[[NSUserDefaults standardUserDefaults] objectForKey:QLCUIThemesQuickLookGeneratorThemeUUIDKey]];
}

@end
