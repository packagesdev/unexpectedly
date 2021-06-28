/*
 Copyright (c) 2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIPreferencePaneAdvancedViewController.h"

#import "WBRemoteVersionChecker.h"

extern NSString * const CUIApplicationShowDebugMenuKey;

extern NSString * const CUIApplicationShowDebugDidChangeNotification;

@interface CUIPreferencePaneAdvancedViewController ()
{
    IBOutlet NSButton * _remoteVersionCheckerCheckbox;
    
    IBOutlet NSButton * _showDebugMenuCheckbox;
}

- (IBAction)switchRemoteVersionCheck:(id)sender;

- (IBAction)switchShowDebugMenu:(id)sender;

@end

@implementation CUIPreferencePaneAdvancedViewController

- (NSString *)nibName
{
    return @"CUIPreferencePaneAdvancedViewController";
}

#pragma mark -

- (void)viewWillAppear
{
    [super viewWillAppear];
    
    // Remote Version Check
    
    _remoteVersionCheckerCheckbox.state=([WBRemoteVersionChecker sharedChecker].isCheckEnabled==YES) ? NSOnState: NSOffState;
    
    // Show Debug Menu
    
    NSUserDefaults * tDefaults=[NSUserDefaults standardUserDefaults];
    
    _showDebugMenuCheckbox.state=([tDefaults boolForKey:CUIApplicationShowDebugMenuKey]==YES) ? NSOnState: NSOffState;
}

#pragma mark -

- (IBAction)switchRemoteVersionCheck:(NSButton *)sender
{
    [WBRemoteVersionChecker sharedChecker].checkEnabled=(sender.state==NSOnState);
}

- (IBAction)switchShowDebugMenu:(NSButton *)sender
{
    NSUserDefaults * tDefaults=[NSUserDefaults standardUserDefaults];
    
    [tDefaults setBool:(sender.state==NSOnState) forKey:CUIApplicationShowDebugMenuKey];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CUIApplicationShowDebugDidChangeNotification object:nil];
}

@end
