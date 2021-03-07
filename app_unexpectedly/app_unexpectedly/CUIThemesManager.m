/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIThemesManager.h"

#import "CUIApplicationPreferences.h"

#import "NSArray+WBExtensions.h"

#import "NSArray+UniqueName.h"

NSString * const CUIThemesCurrentThemeUUIDKey=@"themes.current.UUID";

NSString * const CUIThemesListKey=@"themes.list";


NSString * const CUIThemesManagerCurrentThemeDidChangeNotification=@"CUIThemesManagerCurrentThemeDidChangeNotification";

NSString * const CUIThemesManagerThemesListDidChangeNotification=@"CUIThemesManagerThemesListDidChangeNotification";

@interface CUIThemesManager ()
{
    NSUserDefaults * _defaults;
    
    NSMutableArray * _themes;
    
    NSMutableDictionary * _cachedThemeUUIDsRegistry;
}

// Notifications

- (void)itemAttributesDidChange:(NSNotification *)inNotification;

- (void)themesListDidChange:(NSNotification *)inNotification;

@end

@implementation CUIThemesManager

+ (void)initialize
{
    NSArray * tThemesArray=[NSArray arrayWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"default_themes" withExtension:@"plist"]];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
                                                              CUIThemesListKey:tThemesArray,
                                                              CUIThemesCurrentThemeUUIDKey:@"UUID2"
  
                                                              }];
}

+ (CUIThemesManager *)sharedManager
{
    static CUIThemesManager * sSharedManager=nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sSharedManager=[CUIThemesManager new];
        
    });
    
    return sSharedManager;
}

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _defaults=[NSUserDefaults standardUserDefaults];
        
        _cachedThemeUUIDsRegistry=[NSMutableDictionary dictionary];
        
        _themes=[[[_defaults objectForKey:CUIThemesListKey] WB_arrayByMappingObjectsLenientlyUsingBlock:^id(NSDictionary * bThemeRepresentation, NSUInteger bIndex) {
           
            CUITheme * tTheme=[[CUITheme alloc] initWithRepresentation:bThemeRepresentation];
            
            if (tTheme==nil)
            {
                NSLog(@"Archive representation of theme could not be loaded");
                
                return nil;
            }
            
            self->_cachedThemeUUIDsRegistry[tTheme.UUID]=tTheme;
            
            return tTheme;
            
        }] mutableCopy];
        
        if (_themes==nil)
        {
            // A COMPLETER
            
            return nil;
        }
        
        NSString * tUUID=[_defaults objectForKey:CUIThemesCurrentThemeUUIDKey];
        
        if (tUUID!=nil)
            _currentTheme=_cachedThemeUUIDsRegistry[tUUID];
        
        if (_currentTheme==nil)
            _currentTheme=_themes.firstObject;
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemAttributesDidChange:) name:CUIThemeItemAttributesDidChangeNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(themesListDidChange:) name:CUIThemesManagerThemesListDidChangeNotification object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -

- (NSArray *)allThemes
{
    return [_themes copy];
}

- (void)setCurrentTheme:(CUITheme *)inTheme
{
    if (inTheme==nil)
        return;
    
    if ([_themes containsObject:inTheme]==NO)
        return;
    
    if (_currentTheme!=inTheme)
    {
        _currentTheme=inTheme;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:CUIThemesManagerCurrentThemeDidChangeNotification object:nil];
        
        [_defaults setObject:_currentTheme.UUID forKey:CUIThemesCurrentThemeUUIDKey];
    }
}

- (CUITheme *)themeWithUUID:(NSString *)inUUID
{
    if (inUUID==nil)
        return nil;
    
    return _cachedThemeUUIDsRegistry[inUUID];
}

#pragma mark -

- (BOOL)renameTheme:(CUITheme *)inTheme withName:(NSString *)inNewName
{
    if (inTheme==nil || inNewName==nil)
        return NO;
    
    inTheme.name=inNewName;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CUIThemesManagerThemesListDidChangeNotification object:nil];
    
    return YES;
}

- (void)addTheme:(CUITheme *)inTheme
{
    if (inTheme==nil)
        return;
    
    if (_cachedThemeUUIDsRegistry[inTheme.UUID]!=nil)
        return;
    
    _cachedThemeUUIDsRegistry[inTheme.UUID]=inTheme;
    
    [_themes addObject:inTheme];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CUIThemesManagerThemesListDidChangeNotification object:nil];
}

- (CUITheme *)duplicateTheme:(CUITheme *)inTheme
{
    if (inTheme==nil)
        return nil;
    
    CUITheme * nTheme=[inTheme copy];
    
    // Find a unique name
    
    NSString * tNewName=[self.allThemes uniqueNameWithBaseName:[nTheme.name stringByAppendingString:NSLocalizedString(@" copy", @"")]
                                            usingNameExtractor:^NSString *(CUITheme * bThene, NSUInteger bIndex) {
                                                return bThene.name;
                                            }];
    
    if (tNewName!=nil)
        nTheme.name=tNewName;
    
    _cachedThemeUUIDsRegistry[nTheme.UUID]=nTheme;
    
    [_themes addObject:nTheme];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CUIThemesManagerThemesListDidChangeNotification object:nil];
    
    return nTheme;
}

- (void)removeTheme:(CUITheme *)inTheme
{
    if (_themes.count<2)
        return;
    
    if (inTheme==self.currentTheme)
    {
        NSUInteger tIndex=[_themes indexOfObjectPassingTest:^BOOL(CUITheme * bTheme, NSUInteger idx, BOOL * _Nonnull stop) {
            
            return (bTheme!=inTheme);
        }];
        
        if (tIndex==NSNotFound)
            return;
        
        self.currentTheme=_themes[tIndex];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:CUIThemesManagerCurrentThemeDidChangeNotification object:nil];
    }
    
    [_cachedThemeUUIDsRegistry removeObjectForKey:inTheme.UUID];
    
    [_themes removeObject:inTheme];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CUIThemesManagerThemesListDidChangeNotification object:nil];
}

- (void)reset
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CUIThemeItemAttributesDidChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CUIThemesManagerThemesListDidChangeNotification object:nil];
    
    [_defaults removeObjectForKey:CUIThemesCurrentThemeUUIDKey];
    
    [_defaults removeObjectForKey:CUIThemesCurrentThemeUUIDKey];
    
    NSArray * tThemesArray=[NSArray arrayWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"default_themes" withExtension:@"plist"]];
    
    _cachedThemeUUIDsRegistry=[NSMutableDictionary dictionary];
    
    _themes=[[tThemesArray WB_arrayByMappingObjectsLenientlyUsingBlock:^id(NSDictionary * bThemeRepresentation, NSUInteger bIndex) {
        
        CUITheme * tTheme=[[CUITheme alloc] initWithRepresentation:bThemeRepresentation];
        
        if (tTheme==nil)
        {
            NSLog(@"Archive representation of theme could not be loaded");
            
            return nil;
        }
        
        self->_cachedThemeUUIDsRegistry[tTheme.UUID]=tTheme;
        
        return tTheme;
        
    }] mutableCopy];
    
    if (_themes==nil)
    {
        // A COMPLETER
        
        return;
    }
    
    _currentTheme=_themes.firstObject;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CUIThemesManagerThemesListDidChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemAttributesDidChange:) name:CUIThemeItemAttributesDidChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(themesListDidChange:) name:CUIThemesManagerThemesListDidChangeNotification object:nil];
    
    // Save defaults
    
    NSArray * tRepresentation=[_themes WB_arrayByMappingObjectsUsingBlock:^id(CUITheme * bTheme, NSUInteger bIndex) {
        
        return [bTheme representation];
        
    }];
    
    [_defaults setObject:tRepresentation forKey:CUIThemesListKey];
}

#pragma mark - Notifications

- (void)itemAttributesDidChange:(NSNotification *)inNotification
{
    // Save defaults
    
    NSArray * tRepresentation=[_themes WB_arrayByMappingObjectsUsingBlock:^id(CUITheme * bTheme, NSUInteger bIndex) {
        
        return [bTheme representation];
        
    }];
    
    [_defaults setObject:tRepresentation forKey:CUIThemesListKey];
}

- (void)themesListDidChange:(NSNotification *)inNotification
{
    // Save defaults
    
    NSArray * tRepresentation=[_themes WB_arrayByMappingObjectsUsingBlock:^id(CUITheme * bTheme, NSUInteger bIndex) {
        
        return [bTheme representation];
        
    }];
    
    [_defaults setObject:tRepresentation forKey:CUIThemesListKey];
}

@end
