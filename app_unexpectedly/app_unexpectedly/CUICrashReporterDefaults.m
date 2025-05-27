/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICrashReporterDefaults.h"

NSString * const CUICrashReporterBundleIdentifier=@"com.apple.CrashReporter";

NSString * const CUICrashReporterDefaultsDialogTypeKey=@"DialogType";

NSString * const CUICrashReporterDefaultsNotificationModeKey=@"UseUNC";

NSString * const CUICrashReporterDefaultsReportUncaughtExceptionKey=@"NSApplicationShowExceptions";

@interface CUICrashReporterDefaults ()

+ (CUICrashReporterDialogType)dialogTypeFromString:(NSString *)inString;

+ (NSString *)stringFromDialogType:(CUICrashReporterDialogType)inDialogType;

- (void)refresh;

// Notifications

- (void)applicationDidBecomeActive:(NSNotification *)inNotification;

@end

@implementation CUICrashReporterDefaults

+ (CUICrashReporterDefaults *)standardCrashReporterDefaults
{
    static CUICrashReporterDefaults * sCrashReporterDefaults=nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sCrashReporterDefaults=[CUICrashReporterDefaults new];
        
    });
    
    return sCrashReporterDefaults;
}

+ (CUICrashReporterDialogType)dialogTypeFromString:(NSString *)inString
{
    if ([inString isKindOfClass:NSString.class]==NO)
        return CUICrashReporterDialogTypeBasic;
    
    static NSDictionary * sStringToEnumDictionary=nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sStringToEnumDictionary=@{
                             @"basic":@(CUICrashReporterDialogTypeBasic),
                             @"developer":@(CUICrashReporterDialogTypeDeveloper),
                             @"crashreport":@(CUICrashReporterDialogTypeBasic),
                             @"server":@(CUICrashReporterDialogTypeServer)
                             
                             };
        
    });
    
    NSNumber * tNumber=sStringToEnumDictionary[inString];
    
    if (tNumber==nil)
        return CUICrashReporterDialogTypeBasic;
    
    return [tNumber unsignedIntegerValue];
}

+ (NSString *)stringFromDialogType:(CUICrashReporterDialogType)inDialogType
{
    static NSDictionary * sEnumToStringDictionary=nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sEnumToStringDictionary=@{
                             @(CUICrashReporterDialogTypeBasic):@"basic",
                             @(CUICrashReporterDialogTypeDeveloper):@"developer",
                             @(CUICrashReporterDialogTypeServer):@"server"
                             };
        
    });
    
    return sEnumToStringDictionary[@(inDialogType)];
}

#pragma mark -

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        [self refresh];
        
        // Register for notifications
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationDidBecomeActive:) name:NSApplicationDidBecomeActiveNotification object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

#pragma mark -

- (void)refresh
{
    NSDictionary * tDictionary=(__bridge_transfer NSDictionary *)CFPreferencesCopyMultiple(NULL,(__bridge CFStringRef) CUICrashReporterBundleIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    
    if (tDictionary==nil)
        tDictionary=[NSDictionary dictionary];
    
    Boolean tBoolean=FALSE;
    
    if (CFPreferencesGetAppBooleanValue((__bridge CFStringRef)CUICrashReporterDefaultsReportUncaughtExceptionKey,kCFPreferencesAnyApplication,&tBoolean)==FALSE)
    {
        tBoolean=FALSE;
    }
    
    NSMutableDictionary * tRepresentation=[tDictionary mutableCopy];
    
    tRepresentation[CUICrashReporterDefaultsReportUncaughtExceptionKey]=@(tBoolean);
    
    // Dialog Type
    
    NSString * tDialogTypeValue=tRepresentation[CUICrashReporterDefaultsDialogTypeKey];
    
    if ([tDialogTypeValue isKindOfClass:NSString.class]==NO)
    {
        if (tDialogTypeValue!=nil)
            NSLog(@"Unexpected value type for key: %@",CUICrashReporterDefaultsDialogTypeKey);
        
        self.dialogType=CUICrashReporterDialogTypeBasic;
    }
    else
    {
        self.dialogType=[CUICrashReporterDefaults dialogTypeFromString:tDialogTypeValue];
    }
    
    // Notification Mode
    
    NSNumber * tNumber=tRepresentation[CUICrashReporterDefaultsNotificationModeKey];
    
    if ([tDialogTypeValue isKindOfClass:NSString.class]==NO)
    {
        self.notificationMode=CUICrashReporterNotificationModeDialog;
    }
    else
    {
        if ([tNumber boolValue]==YES)
        {
            self.notificationMode=CUICrashReporterNotificationModeUserNotification;
        }
        else
        {
            self.notificationMode=CUICrashReporterNotificationModeDialog;
        }
    }
    
    // Report UncaughtException
    
    self.reportUncaughtExceptions=[tRepresentation[CUICrashReporterDefaultsReportUncaughtExceptionKey] boolValue];
}

#pragma mark -

- (void)setDialogType:(CUICrashReporterDialogType)inDialogType
{
    if (_dialogType==inDialogType)
        return;
    
    _dialogType=inDialogType;
    
    NSString * tString=[CUICrashReporterDefaults stringFromDialogType:_dialogType];
    
    CFPreferencesSetValue((__bridge CFStringRef)CUICrashReporterDefaultsDialogTypeKey, (__bridge CFStringRef)tString, (__bridge CFStringRef)CUICrashReporterBundleIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    CFPreferencesSynchronize((__bridge CFStringRef)CUICrashReporterBundleIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
}

- (void)setNotificationMode:(CUICrashReporterNotificationMode)inNotificationMode
{
    if (_notificationMode==inNotificationMode)
        return;
    
    _notificationMode=inNotificationMode;
    
    NSNumber * tNumber=@(_notificationMode==CUICrashReporterNotificationModeUserNotification);
    
    CFPreferencesSetValue((__bridge CFStringRef)CUICrashReporterDefaultsNotificationModeKey, (__bridge CFNumberRef)tNumber, (__bridge CFStringRef)CUICrashReporterBundleIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    CFPreferencesSynchronize((__bridge CFStringRef)CUICrashReporterBundleIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
}

- (void)setReportUncaughtExceptions:(BOOL)inReportUncaughtExceptions
{
    if (_reportUncaughtExceptions==inReportUncaughtExceptions)
        return;
    
    _reportUncaughtExceptions=inReportUncaughtExceptions;
    
    CFPreferencesSetValue((__bridge CFStringRef)CUICrashReporterDefaultsReportUncaughtExceptionKey, (__bridge CFNumberRef)@(_reportUncaughtExceptions), kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    CFPreferencesSynchronize(kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
}

#pragma mark -

- (void)applicationDidBecomeActive:(NSNotification *)inNotification
{
    [self refresh];
}

@end
