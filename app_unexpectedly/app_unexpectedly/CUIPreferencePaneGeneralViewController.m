/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIPreferencePaneGeneralViewController.h"

#import "CUIApplicationPreferences.h"

#import "CUIApplicationItemAttributes.h"


@interface CUIPreferencePaneGeneralViewController ()
{
    IBOutlet NSButton * _showsRegistersWindowAtLaunchCheckbox;
    
    IBOutlet NSPopUpButton * _sourceEditorsPopUpButton;
    
    IBOutlet NSPopUpButton * _reportViewersPopUpButton;
}

+ (NSMenu *)reportViewersMenu;

- (IBAction)switchShowsRegisterWindowAtLaunch:(id)sender;

- (IBAction)switchPreferedSourceCodeEditor:(id)sender;

- (IBAction)switchDefaultReportsViewer:(id)sender;

@end

@implementation CUIPreferencePaneGeneralViewController

+ (NSMenu *)reportViewersMenu
{
    NSArray * tBundleIdentifiers=(__bridge_transfer NSArray *)LSCopyAllRoleHandlersForContentType(CFSTR("com.apple.crashreport"),kLSRolesViewer);
    
    NSMutableArray * tMutableApplicationsURLs=[NSMutableArray array];
    
    for(NSString * tBundleIdentifier in tBundleIdentifiers)
    {
        NSArray * tApplicationsURLs=(__bridge_transfer NSArray *)LSCopyApplicationURLsForBundleIdentifier((__bridge CFStringRef)tBundleIdentifier,NULL);
        
        if (tApplicationsURLs.count>0)
            [tMutableApplicationsURLs addObject:tApplicationsURLs.firstObject];
    }
    
    NSMenu * tMenu=[[NSMenu alloc] initWithTitle:@""];
    
    if (tMenu==nil)
        return nil;
    
    NSMutableArray * tApplicationsAttributes=[[tMutableApplicationsURLs WB_arrayByMappingObjectsUsingBlock:^CUIApplicationItemAttributes *(NSURL * bApplicationURL, NSUInteger bIndex) {
        
        return [[CUIApplicationItemAttributes alloc] initWithURL:bApplicationURL];
    }] mutableCopy];
    
    // Filter the array
    
    tApplicationsAttributes=[tApplicationsAttributes WB_filteredArrayUsingBlock:^BOOL(CUIApplicationItemAttributes * bAttributes, NSUInteger bIndex) {
        
        return (bAttributes.duplicate==NO);
        
    }];
    
    // Sort the array
    
    [tApplicationsAttributes sortUsingSelector:@selector(compare:)];
    
    for(CUIApplicationItemAttributes * tAttributes in tApplicationsAttributes)
    {
        tAttributes.showsVersion=NO;
        
        NSMenuItem * tMenuItem=tAttributes.applicationMenuItem;
        
        [tMenu addItem:tMenuItem];
    }
    
    return tMenu;
}

+ (NSMenu *)sourceEditorsMenu
{
    NSURL * tCSourceFileURL=[[NSBundle mainBundle] URLForResource:@"template" withExtension:@"c"];
    
    NSArray * tApplicationsURLs=(__bridge_transfer NSArray *)LSCopyApplicationURLsForURL((__bridge CFURLRef)tCSourceFileURL,kLSRolesEditor);
    
    NSMenu * tMenu=[[NSMenu alloc] initWithTitle:@""];
    
    if (tMenu==nil)
        return nil;
    
    NSMutableArray * tApplicationsAttributes=[[tApplicationsURLs WB_arrayByMappingObjectsUsingBlock:^CUIApplicationItemAttributes *(NSURL * bApplicationURL, NSUInteger bIndex) {
        
        return [[CUIApplicationItemAttributes alloc] initWithURL:bApplicationURL];
    }] mutableCopy];
    
    // Sort the array
    
    [tApplicationsAttributes sortUsingSelector:@selector(compare:)];
    
    // Filter the array
    
    tApplicationsAttributes=[tApplicationsAttributes WB_filteredArrayUsingBlock:^BOOL(CUIApplicationItemAttributes * bAttributes, NSUInteger bIndex) {
       
        return (bAttributes.duplicate==NO);
        
    }];
    
    for(CUIApplicationItemAttributes * tAttributes in tApplicationsAttributes)
    {
        NSMenuItem * tMenuItem=tAttributes.applicationMenuItem;
        
        [tMenu addItem:tMenuItem];
    }
    
    return tMenu;
}

- (NSString *)nibName
{
    return @"CUIPreferencePaneGeneralViewController";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSMenu * tMenu=[CUIPreferencePaneGeneralViewController sourceEditorsMenu];
    
    if (tMenu.numberOfItems>0)
        _sourceEditorsPopUpButton.menu=tMenu;
    else
        _sourceEditorsPopUpButton.enabled=NO;
    
    // Default reports viewer
    
    tMenu=[CUIPreferencePaneGeneralViewController reportViewersMenu];
    
    _reportViewersPopUpButton.menu=tMenu;
}

#pragma mark -

- (void)viewWillAppear
{
    [super viewWillAppear];
    
    CUIApplicationPreferences * tPreferences=[CUIApplicationPreferences sharedPreferences];
    
    _showsRegistersWindowAtLaunchCheckbox.state=(tPreferences.showsRegistersWindowAutomaticallyAtLaunch==YES) ? NSOnState : NSOffState;
    
    NSURL * tPreferedApplicationURL=tPreferences.preferedSourceCodeEditorURL;
    
    
    NSUInteger tIndex=[_sourceEditorsPopUpButton.menu.itemArray indexOfObjectPassingTest:^BOOL(NSMenuItem * bMenuItem, NSUInteger bIndex, BOOL * bOutStop) {
        
        CUIApplicationItemAttributes * tAttributes=bMenuItem.representedObject;
        
        return [tAttributes.applicationURL isEqualTo:tPreferedApplicationURL];
        
    }];
    
    if (tIndex==NSNotFound)
    {
        tPreferedApplicationURL=[CUIApplicationPreferences defaultSourceCodeEditorURL];
        
        tIndex=[_sourceEditorsPopUpButton.menu.itemArray indexOfObjectPassingTest:^BOOL(NSMenuItem * bMenuItem, NSUInteger bIndex, BOOL * bOutStop) {
            
            CUIApplicationItemAttributes * tAttributes=bMenuItem.representedObject;
            
            return [tAttributes.applicationURL isEqualTo:tPreferedApplicationURL];
            
        }];
        
        if (tIndex!=NSNotFound)
            tPreferences.preferedSourceCodeEditorURL=tPreferedApplicationURL;
    }
    
    if (tIndex!=NSNotFound)
        [_sourceEditorsPopUpButton selectItemAtIndex:tIndex];
    else
        NSLog(@"Ouille ouille ouille!");
    
    // Default reports viewer
    
    NSString * tBundleIdentifier=(__bridge_transfer NSString *)LSCopyDefaultRoleHandlerForContentType(CFSTR("com.apple.crashreport"),kLSRolesViewer);
    
    tIndex=[_reportViewersPopUpButton.menu.itemArray indexOfObjectPassingTest:^BOOL(NSMenuItem * bMenuItem, NSUInteger bIndex, BOOL * bOutStop) {
        
        CUIApplicationItemAttributes * tAttributes=bMenuItem.representedObject;
        
        return [tAttributes.bundleIdentifier isEqualToString:tBundleIdentifier];
        
    }];
    
    if (tIndex!=NSNotFound)
        [_reportViewersPopUpButton selectItemAtIndex:tIndex];
}

#pragma mark -

- (IBAction)switchShowsRegisterWindowAtLaunch:(NSButton *)sender
{
    [CUIApplicationPreferences sharedPreferences].showsRegistersWindowAutomaticallyAtLaunch=(sender.state==NSOnState);
}

- (IBAction)switchPreferedSourceCodeEditor:(NSPopUpButton *)sender
{
    CUIApplicationItemAttributes * tAttributes=sender.selectedItem.representedObject;
    
    [CUIApplicationPreferences sharedPreferences].preferedSourceCodeEditorURL=tAttributes.applicationURL;
}

- (IBAction)switchDefaultReportsViewer:(NSPopUpButton *)sender
{
    CUIApplicationItemAttributes * tAttributes=sender.selectedItem.representedObject;
    
    OSStatus tResult=LSSetDefaultRoleHandlerForContentType(CFSTR("com.apple.crashreport"),kLSRolesViewer,(__bridge CFStringRef) tAttributes.bundleIdentifier);
    
    if (tResult != noErr)
    {
        // A VOIR (report error if we can figure out which error values this method can return)
    }
}

@end
