//
//  CUIAboutBoxWindowController.m
//  Unexpectedly
//
//  Created by stephane on 15/11/2020.
//  Copyright © 2020 Stephane Sudre. All rights reserved.
//

#import "CUIAboutBoxWindowController.h"

#import "CUIAboutBoxWindow.h"
#import "CUIApplicationIconView.h"

@interface CUIAboutBoxWindowController ()
{
    IBOutlet CUIApplicationIconView * _applicationIconView;

    IBOutlet NSTextField * _versionLabel;
}

- (IBAction)showLicenseAgreement:(id)sender;

- (IBAction)showAcknowledgments:(id)sender;

// Notifications

- (void)optionKeyStateDidChange:(NSNotification *)inNotification;

@end

@implementation CUIAboutBoxWindowController

+ (void)showAbouxBox
{
    static dispatch_once_t onceToken;
    static CUIAboutBoxWindowController * sAbouxBoxWindowController=nil;
    
    dispatch_once(&onceToken, ^{
        
        sAbouxBoxWindowController=[CUIAboutBoxWindowController new];
    });
    
    [sAbouxBoxWindowController showWindow:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -

- (NSString *)windowNibName
{
    return @"CUIAboutBoxWindowController";
}

#pragma mark -

- (void)windowDidLoad
{
    NSDictionary * tDictionary=[NSBundle mainBundle].infoDictionary;
    
    _versionLabel.stringValue=[NSString stringWithFormat:NSLocalizedString(@"version %@ (%@)",@""),tDictionary[@"CFBundleShortVersionString"],tDictionary[@"CFBundleVersion"]];
    
    // Register for notifications
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(optionKeyStateDidChange:) name:CUIOptionKeyStateDidChangeNotification object:self.window];
    
    [self.window center];
}

#pragma mark -

- (IBAction)showLicenseAgreement:(id)sender
{
    NSString * tPath=[[NSBundle mainBundle] pathForResource:@"Unexpectedly_License" ofType:@"pdf"];
    
    if (tPath==nil)
    {
        NSLog(@"[CUIAboutBoxWindowController showLicenseAgreement:] Missing License file");
        return;
    }
    
    [[NSWorkspace sharedWorkspace] openFile:tPath];
}

- (IBAction)showAcknowledgments:(id)sender
{
    NSString * tPath=[[NSBundle mainBundle] pathForResource:@"Unexpectedly_Acknowledgments" ofType:@"pdf"];
    
    if (tPath==nil)
    {
        NSLog(@"[CUIAboutBoxWindowController showAcknowledgments:] Missing Acknowledgements file");
        return;
    }
    
    [[NSWorkspace sharedWorkspace] openFile:tPath];
}

#pragma mark - Notifications

- (void)optionKeyStateDidChange:(NSNotification *)inNotification
{
    BOOL tPressed=[inNotification.userInfo[CUIOptionKeyState] boolValue];
    
    _applicationIconView.renderingMode=(tPressed==YES) ? CUIWatchRenderingModeWireframe : CUIWatchRenderingModeFull; 
}

@end
