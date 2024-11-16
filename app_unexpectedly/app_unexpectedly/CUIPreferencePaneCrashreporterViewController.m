/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIPreferencePaneCrashreporterViewController.h"

#import "CUICrashReporterDefaults.h"

@interface CUIPreferencePaneCrashreporterViewController ()
{
    IBOutlet NSView * _dialogTypeGroup;
    
    IBOutlet NSView * _notificationModeGroup;
    
    IBOutlet NSButton * _reportUncaughtExceptionsCheckbox;
    
    NSTimer * _refreshTimer;
}

- (IBAction)switchCrashReporterDialogType:(id)sender;

- (IBAction)switchCrashReporterNotificationMode:(id)sender;

- (IBAction)switchReportUncaughtException:(id)sender;

// Notifications

- (void)applicationDidBecomeActive:(NSNotification *)inNotification;

- (void)applicationDidResignActive:(NSNotification *)inNotification;

@end

@implementation CUIPreferencePaneCrashreporterViewController

- (NSString *)nibName
{
    return @"CUIPreferencePaneCrashreporterViewController";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear
{
    [super viewWillAppear];
    
    [self refresh];
}

- (void)viewDidAppear
{
    [super viewDidAppear];
    
    // Register for notifications
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:NSApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidResignActive:) name:NSApplicationDidResignActiveNotification object:nil];
}

- (void)viewWillDisappear
{
    [super viewWillDisappear];
    
    // Remove timer (if needed)
    
    [_refreshTimer invalidate];
    _refreshTimer=nil;
    
    // Remove observer
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidResignActiveNotification object:nil];
}

#pragma mark -

- (void)refresh
{
    CUICrashReporterDefaults * tDefaults=[CUICrashReporterDefaults standardCrashReporterDefaults];
    
    // Operation Mode
    
    NSButton * tRadioButton=[_dialogTypeGroup viewWithTag:tDefaults.dialogType];
    
    tRadioButton.state=NSControlStateValueOn;
    
    // Notification Mode
    
    tRadioButton=[_notificationModeGroup viewWithTag:tDefaults.notificationMode];
    
    tRadioButton.state=NSControlStateValueOn;
    
    // Report Uncaught Exceptions
    
    _reportUncaughtExceptionsCheckbox.state=(tDefaults.reportUncaughtExceptions==YES) ? NSControlStateValueOn : NSControlStateValueOff;
}

#pragma mark -

- (IBAction)switchCrashReporterDialogType:(NSButton *)sender
{
    CUICrashReporterDefaults * tDefaults=[CUICrashReporterDefaults standardCrashReporterDefaults];
    
    tDefaults.dialogType=sender.tag;
}

- (IBAction)switchCrashReporterNotificationMode:(NSButton *)sender
{
    CUICrashReporterDefaults * tDefaults=[CUICrashReporterDefaults standardCrashReporterDefaults];
    
    tDefaults.notificationMode=sender.tag;
}

- (IBAction)switchReportUncaughtException:(NSButton *)sender
{
    CUICrashReporterDefaults * tDefaults=[CUICrashReporterDefaults standardCrashReporterDefaults];
    
    tDefaults.reportUncaughtExceptions=(sender.state==NSControlStateValueOn);
}

#pragma mark - Notifications

- (void)applicationDidBecomeActive:(NSNotification *)inNotification
{
    // Remove refresh timer
    
    [_refreshTimer invalidate];
    _refreshTimer=nil;
    
    // Refresh
    
    [self refresh];
}

- (void)applicationDidResignActive:(NSNotification *)inNotification
{
    // Add refresh timer (Info > macOS 10.12 API)
    
    _refreshTimer=[NSTimer scheduledTimerWithTimeInterval:2.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
       
        [[CUICrashReporterDefaults standardCrashReporterDefaults] refresh];
        
        [self refresh];
        
    }];
}

@end
