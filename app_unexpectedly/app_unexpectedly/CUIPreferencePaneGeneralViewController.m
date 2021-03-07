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

@interface CUIApplicationItemAttributes : NSObject

    @property (readonly) NSURL * applicationURL;

    @property NSString * displayName;

    @property NSString * bundleIdentifier;

    @property NSImage * icon;

    @property NSString * version;

    @property (nonatomic,readonly) NSMenuItem * applicationMenuItem;

    @property BOOL showsVersion;

    @property BOOL duplicate;

- (instancetype)initWithURL:(NSURL *)inApplicationURL;

- (NSComparisonResult)compare:(CUIApplicationItemAttributes *)inOther;

@end

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
    
    // Filter the array
    
    tApplicationsAttributes=[tApplicationsAttributes WB_filteredArrayUsingBlock:^BOOL(CUIApplicationItemAttributes * bAttributes, NSUInteger bIndex) {
       
        return (bAttributes.duplicate==NO);
        
    }];
    
    // Sort the array
    
    [tApplicationsAttributes sortUsingSelector:@selector(compare:)];
    
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
    {
        _sourceEditorsPopUpButton.menu=tMenu;
    }
    else
    {
        _sourceEditorsPopUpButton.enabled=NO;
    }
    
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
        {
            tPreferences.preferedSourceCodeEditorURL=tPreferedApplicationURL;
        }
    }
    
    if (tIndex!=NSNotFound)
    {
        [_sourceEditorsPopUpButton selectItemAtIndex:tIndex];
    }
    else
    {
        NSLog(@"Ouille ouille ouille!");
    }
    
    // Default reports viewer
    
    NSString * tBundleIdentifier=(__bridge_transfer NSString *)LSCopyDefaultRoleHandlerForContentType(CFSTR("com.apple.crashreport"),kLSRolesViewer);
    
    tIndex=[_reportViewersPopUpButton.menu.itemArray indexOfObjectPassingTest:^BOOL(NSMenuItem * bMenuItem, NSUInteger bIndex, BOOL * bOutStop) {
        
        CUIApplicationItemAttributes * tAttributes=bMenuItem.representedObject;
        
        return [tAttributes.bundleIdentifier isEqualToString:tBundleIdentifier];
        
    }];
    
    if (tIndex!=NSNotFound)
        [_reportViewersPopUpButton selectItemAtIndex:tIndex];
}

/*
+ (BOOL) setMyselfAsDefaultApplicationForFileExtension:(NSString *) fileExtension {
 
}
 */

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
        
    }
}

@end
