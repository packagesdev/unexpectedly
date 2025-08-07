/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIApplicationPreferences.h"

#import "NSDictionary+MutableDeepCopy.h"

#import "NSColor+String.h"

// General

NSString * const CUIPreferencesGeneralDefaultPresentationModeKey=@"general.defaultPresentationMode";

NSString * const CUIPreferencesGeneralShowsRegistersWindowAtLaunchKey=@"general.registers-window.showsAtLaunch";

NSString * const CUIPreferencesGeneralPreferedSourceCodeEditorPathKey=@"general.preferedSourceCodeEditor.path";

// Text Mode

NSString * const CUIPreferencesTextModeDefaultDisplaySettings=@"textmode.displaySettings.defaults";

NSString * const CUIPreferencesTextModeShowsLineNumbersKey=@"textmode.showsLineNumbers";

NSString * const CUIPreferencesTextModeLineWrappingKey=@"textmode.lineWrapping";


extern NSString * const CUITextModeDisplaySettingsVisibleSectionKey;

extern NSString * const CUITextModeDisplaySettingsVisibleStackFrameComponentsKey;


// Outline Mode

NSString * const CUIPreferencesOutlineModeDefaultDisplaySettings=@"outlinemode.displaySettings.defaults";

extern NSString * const CUIOutlineModeDisplaySettingsShowOnlyCrashedThreadKey;

extern NSString * const CUIOutlineModeDisplaySettingsVisibleStackFrameComponentsKey;

// Fonts & Colors


// Symbolication

NSString * const CUIPreferencesSymbolicationSearchSymbolsFilesKey=@"symbolication.searchForSymbolsFiles";

NSString * const CUIPreferencesSymbolicationSymbolicateAutomaticallyKey=@"symbolication.symbolicateAutomatically";


// Crash Logs List

NSString * const CUIPreferencesCrashLogsShowFileNamesKey=@"showFileNames";

NSString * const CUIPreferencesCrashLogsSortTypeKey=@"crashLogs.list.sort";

// Notifications



NSString * const CUIPreferencesTextModeShowsLineNumbersDidChangeNotification=@"CUIPreferencesTextModeShowsLineNumbersDidChangeNotification";

NSString * const CUIPreferencesTextModeLineWrappingDidChangeNotification=@"CUIPreferencesTextModeLineWrappingDidChangeNotification";

NSString * const CUIPreferencesSymbolicationSymbolicateAutomaticallyDidChangeNotification=@"CUIPreferencesSymbolicationSymbolicateAutomaticallyDidChangeNotification";


NSString * const CUIPreferencesCrashLogsSortTypeDidChangeNotification=@"CUIPreferencesCrashLogsSortTypeDidChangeNotification";

NSString * const CUIPreferencesCrashLogsShowFileNamesDidChangeNotification=@"CUIPreferencesCrashLogsShowFileNamesDidChangeNotification";

@interface CUIApplicationPreferences ()
{
    NSUserDefaults * _defaults;
}

@end

@implementation CUIApplicationPreferences

+ (CUIApplicationPreferences *)sharedPreferences
{
    static dispatch_once_t onceToken;
    static CUIApplicationPreferences * sPreferences=nil;
    
    dispatch_once(&onceToken, ^{
        
        sPreferences=[CUIApplicationPreferences new];
    });
    
    return sPreferences;
}

+ (NSURL *)defaultSourceCodeEditorURL
{
    return (__bridge_transfer NSURL *)LSCopyDefaultApplicationURLForContentType(CFSTR("public.c-source"),kLSRolesEditor,NULL);
}

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _defaults=[NSUserDefaults standardUserDefaults];
        
        [_defaults registerDefaults:@{
                                      // General
                                      
                                      CUIPreferencesGeneralDefaultPresentationModeKey:@(CUIPresentationModeText),
                                      
                                      CUIPreferencesGeneralShowsRegistersWindowAtLaunchKey:@(NO),
                                      
                                      CUIPreferencesSymbolicationSearchSymbolsFilesKey:@(YES),
                                      
                                      CUIPreferencesSymbolicationSymbolicateAutomaticallyKey:@(YES),
                                      
                                      // Text Mode
                                      
                                      CUIPreferencesTextModeShowsLineNumbersKey:@(NO),
                                      
                                      CUIPreferencesTextModeLineWrappingKey:@(YES),
                                      
                                      CUIPreferencesTextModeDefaultDisplaySettings:@{
                                              CUITextModeDisplaySettingsVisibleSectionKey:@(CUIDocumentAllSections),
                                              CUITextModeDisplaySettingsVisibleStackFrameComponentsKey:@(CUIStackFrameAllComponents)
                                              },
                                      
                                      // Outline Mode
                                      
                                      CUIPreferencesOutlineModeDefaultDisplaySettings:@{
                                              CUIOutlineModeDisplaySettingsShowOnlyCrashedThreadKey:@(NO),
                                              CUIOutlineModeDisplaySettingsVisibleStackFrameComponentsKey:@(CUIStackFrameByteOffsetComponent)
                                              },
                                      
                                      // Fonts & Colors
                                      
                                      // Crash Logs
                                      
                                      CUIPreferencesCrashLogsSortTypeKey:@(CUICrashLogsSortDateDescending),
                                      CUIPreferencesCrashLogsSortTypeKey:@(NO)
                                      
                                      }];
        
        // General
        
        _defaultPresentationMode=[_defaults integerForKey:CUIPreferencesGeneralDefaultPresentationModeKey];
        
        
        _showsRegistersWindowAutomaticallyAtLaunch=[_defaults boolForKey:CUIPreferencesGeneralShowsRegistersWindowAtLaunchKey];
        
        
        _searchForSymbolsFilesAutomatically=[_defaults boolForKey:CUIPreferencesSymbolicationSearchSymbolsFilesKey];
        
        NSString * tPath=[_defaults stringForKey:CUIPreferencesGeneralPreferedSourceCodeEditorPathKey];
        
        if (tPath==nil || [[NSFileManager defaultManager] fileExistsAtPath:tPath]==NO)
        {
            _preferedSourceCodeEditorURL=[CUIApplicationPreferences defaultSourceCodeEditorURL];
        }
        else
        {
            _preferedSourceCodeEditorURL=[NSURL fileURLWithPath:tPath];
        }
        
        _symbolicateAutomatically=[_defaults integerForKey:CUIPreferencesSymbolicationSymbolicateAutomaticallyKey];

        // Text Mode
        
        _showsLineNumbers=[_defaults boolForKey:CUIPreferencesTextModeShowsLineNumbersKey];
        
        _lineWrapping=[_defaults boolForKey:CUIPreferencesTextModeLineWrappingKey];
        
        
        
        
        _defaultTextModeDisplaySettings=[[CUITextModeDisplaySettings alloc] initWithRepresentation:[_defaults objectForKey:CUIPreferencesTextModeDefaultDisplaySettings]];
        
        // Outline Mode
        
        _defaultOutlineModeDisplaySettings=[[CUIOutlineModeDisplaySettings alloc] initWithRepresentation:[_defaults objectForKey:CUIPreferencesOutlineModeDefaultDisplaySettings]];
        
        // Fonts and Colors
        
        // Crash Logs
        
        _crashLogsSortType=[_defaults integerForKey:CUIPreferencesCrashLogsSortTypeKey];
        
        _crashLogsShowFileNames=[_defaults boolForKey:CUIPreferencesCrashLogsShowFileNamesKey];
        
    }
    
    return self;
}

#pragma mark -

- (void)setDefaultPresentationMode:(CUIPresentationMode)inMode
{
    _defaultPresentationMode=inMode;
    
    [_defaults setInteger:inMode forKey:CUIPreferencesGeneralDefaultPresentationModeKey];
}

- (void)setShowsRegistersWindowAutomaticallyAtLaunch:(BOOL)inShowsRegistersWindowAutomaticallyAtLaunch
{
    _showsRegistersWindowAutomaticallyAtLaunch=inShowsRegistersWindowAutomaticallyAtLaunch;
    
    [_defaults setBool:inShowsRegistersWindowAutomaticallyAtLaunch forKey:CUIPreferencesGeneralShowsRegistersWindowAtLaunchKey];
}

- (void)setSearchForSymbolsFilesAutomatically:(BOOL)inSearchForSymbolsFilesAutomatically
{
    _searchForSymbolsFilesAutomatically=inSearchForSymbolsFilesAutomatically;
    
    [_defaults setBool:inSearchForSymbolsFilesAutomatically forKey:CUIPreferencesSymbolicationSearchSymbolsFilesKey];
}

- (void)setSymbolicateAutomatically:(BOOL)inSymbolicateAutomatically
{
    _symbolicateAutomatically=inSymbolicateAutomatically;
    
    [_defaults setBool:inSymbolicateAutomatically forKey:CUIPreferencesSymbolicationSymbolicateAutomaticallyKey];
    
    [NSNotificationCenter.defaultCenter postNotificationName:CUIPreferencesSymbolicationSymbolicateAutomaticallyDidChangeNotification object:nil];
}

- (void)setPreferedSourceCodeEditorURL:(NSURL *)inURL
{
    if (inURL.isFileURL==NO)
        return;
    
    _preferedSourceCodeEditorURL=inURL;
    
    NSString * tPath=inURL.path;
    
    [_defaults setObject:tPath forKey:CUIPreferencesGeneralPreferedSourceCodeEditorPathKey];
}

- (void)setShowsLineNumbers:(BOOL)inShowsLineNumber
{
    _showsLineNumbers=inShowsLineNumber;
    
    [_defaults setBool:inShowsLineNumber forKey:CUIPreferencesTextModeShowsLineNumbersKey];
    
    [NSNotificationCenter.defaultCenter postNotificationName:CUIPreferencesTextModeShowsLineNumbersDidChangeNotification object:nil];
}

- (void)setLineWrapping:(BOOL)inLineWrapping
{
    _lineWrapping=inLineWrapping;
    
    [_defaults setBool:inLineWrapping forKey:CUIPreferencesTextModeLineWrappingKey];
    
    [NSNotificationCenter.defaultCenter postNotificationName:CUIPreferencesTextModeLineWrappingDidChangeNotification object:nil];
}

- (void)setDefaultTextModeDisplaySettings:(CUITextModeDisplaySettings *)inDisplaySettings
{
    _defaultTextModeDisplaySettings=[inDisplaySettings copy];
    
    [_defaults setObject:[_defaultTextModeDisplaySettings representation] forKey:CUIPreferencesTextModeDefaultDisplaySettings];
}

- (void)setDefaultOutlineModeDisplaySettings:(CUIOutlineModeDisplaySettings *)inDisplaySettings
{
    _defaultOutlineModeDisplaySettings=[inDisplaySettings copy];
    
    [_defaults setObject:[_defaultOutlineModeDisplaySettings representation] forKey:CUIPreferencesOutlineModeDefaultDisplaySettings];
}

#pragma mark -

- (void)setCrashLogsSortType:(CUICrashLogsSortType)inCrashLogsSortType
{
    if (_crashLogsSortType==inCrashLogsSortType)
        return;
    
    _crashLogsSortType=inCrashLogsSortType;
    
    [_defaults setObject:@(_crashLogsSortType) forKey:CUIPreferencesCrashLogsSortTypeKey];
    
    [NSNotificationCenter.defaultCenter postNotificationName:CUIPreferencesCrashLogsSortTypeDidChangeNotification object:nil];
}

- (void)setCrashLogsShowFileNames:(BOOL)inCrashLogsShowFileNames
{
    if (_crashLogsShowFileNames==inCrashLogsShowFileNames)
        return;
    
    _crashLogsShowFileNames=inCrashLogsShowFileNames;
    
    [_defaults setObject:@(_crashLogsShowFileNames) forKey:CUIPreferencesCrashLogsShowFileNamesKey];
    
    [NSNotificationCenter.defaultCenter postNotificationName:CUIPreferencesCrashLogsShowFileNamesDidChangeNotification object:nil];
}

@end
