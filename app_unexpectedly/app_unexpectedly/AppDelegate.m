/*
 Copyright (c) 2020-2024, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "AppDelegate.h"

#import "CUIBinaryImage.h"

#import "CUIMainWindowController.h"

#import "CUICrashLogsSourcesManager.h"

#import "CUICrashLogsSourceAll.h"

#import "CUICrashLogsSourceFile.h"

#import "CUICrashLogsSourcesSelection.h"

#import "CUICrashLogsSelection.h"

#import "CUICallStackBacktrace.h"

#import "CUIApplicationPreferences.h"

#import "CUIThemesManager.h"

#import "CUIPreferencesWindowController.h"
#import "CUIPreferencesWindowController+Convenience.h"

#import "CUIRegistersWindowController.h"

#import "CUIdSYMBundlesManager.h"

#import "CUIAboutBoxWindowController.h"

#import "CUICrashReporterDefaults.h"

#import "CUICrashLogsOpenErrorRecord.h"

#import "CUICrashLogsOpenErrorPanel.h"

#import "WBRemoteVersionChecker.h"

NSString * const CUIApplicationShowDebugMenuKey=@"ui.menu.debug.show";

NSString * const CUIApplicationShowDebugDidChangeNotification=@"CUIApplicationShowDebugDidChangeNotification";

@interface AppDelegate () <NSApplicationDelegate,NSMenuItemValidation>
{
    IBOutlet NSMenu * _themesMenu;
    
    IBOutlet NSMenuItem * _debugMenuBarItem;
    
	CUIMainWindowController * _mainWindowController;
}

- (IBAction)showAboutBox:(id)sender;

- (IBAction)showPreferences:(id)sender;

- (IBAction)editThemes:(id)sender;

// Help Menu

- (IBAction)showUserGuide:(id)sender;

- (IBAction)sendFeedback:(id)sender;

- (IBAction)showUnexpectedlyWebSite:(id)sender;

// Notifications

- (void)themesListDidChange:(NSNotification *)inNotification;

- (void)showDebugMenuDidChange:(NSNotification *)inNotification;

@end

@implementation AppDelegate

+ (void)initialize
{
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
                                                              CUIApplicationShowDebugMenuKey:@(NO),
                                                              @"NSScrollViewShouldFlipRulerForRTL":@(NO)
                                                              }];
}

- (void)awakeFromNib
{
    [self refreshThemesMenu];
    
    NSUserDefaults * tUserDefaults=[NSUserDefaults standardUserDefaults];
    
    if ([tUserDefaults boolForKey:CUIApplicationShowDebugMenuKey]==YES)
        _debugMenuBarItem.hidden=NO;
    
    // Register for notifications
    
    NSNotificationCenter * tNotificationCenter=NSNotificationCenter.defaultCenter;
    
    [tNotificationCenter addObserver:self selector:@selector(themesListDidChange:) name:CUIThemesManagerThemesListDidChangeNotification object:nil];
    
    [tNotificationCenter addObserver:self selector:@selector(showDebugMenuDidChange:) name:CUIApplicationShowDebugDidChangeNotification object:nil];
}

#pragma mark -

- (void)refreshThemesMenu
{
    // Cleanup menu
    
    NSUInteger tMenuItemsCount=_themesMenu.numberOfItems;
    
    if (tMenuItemsCount>2)
    {
        for(NSUInteger tIndex=tMenuItemsCount-2;tIndex>0;tIndex--)
        {
            [_themesMenu removeItemAtIndex:tIndex-1];
        }
    }
    
    // Populate menu
    
    CUIThemesManager * tThemesManager=[CUIThemesManager sharedManager];
    
    NSArray * tThemes=[tThemesManager allThemes];
    
    [tThemes enumerateObjectsWithOptions:NSEnumerationReverse  usingBlock:^(CUITheme * bTheme, NSUInteger bIndex, BOOL * bOutStop) {
        
        NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:bTheme.name action:@selector(CUI_MENUACTION_switchTheme:) keyEquivalent:@""];
        
        tMenuItem.representedObject=bTheme.UUID;
        
        [self->_themesMenu insertItem:tMenuItem atIndex:0];
        
    }];
}



#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
    SEL tAction=inMenuItem.action;
    
    if (tAction==@selector(switchCrashReporterDialogType:))
    {
        CUICrashReporterDefaults * tDefaults=[CUICrashReporterDefaults standardCrashReporterDefaults];
        
        inMenuItem.state=(tDefaults.dialogType==inMenuItem.tag) ? NSControlStateValueOn : NSControlStateValueOff;
        
        return YES;
    }
    
    if (tAction==@selector(switchCrashReporterNotificationMode:))
    {
        CUICrashReporterDefaults * tDefaults=[CUICrashReporterDefaults standardCrashReporterDefaults];
        
        inMenuItem.state=(tDefaults.notificationMode==inMenuItem.tag) ? NSControlStateValueOn : NSControlStateValueOff;
        
        return YES;
    }
    
    if (tAction==@selector(switchReportUncaughtException:))
    {
        CUICrashReporterDefaults * tDefaults=[CUICrashReporterDefaults standardCrashReporterDefaults];
        
        inMenuItem.state=(tDefaults.reportUncaughtExceptions==YES) ? NSControlStateValueOn : NSControlStateValueOff;
    }
    
    return YES;
}

// Application Menu

- (IBAction)showAboutBox:(id)sender
{
    [CUIAboutBoxWindowController showAbouxBox];
}

- (IBAction)showPreferences:(id)sender
{
    CUIPreferencesWindowController * tPreferencesWindowController=[CUIPreferencesWindowController sharedPreferencesWindowController];
    
    [tPreferencesWindowController showWindow:nil];
}

- (IBAction)editThemes:(id)sender
{
    CUIPreferencesWindowController * tPreferencesWindowController=[CUIPreferencesWindowController sharedPreferencesWindowController];
    
    [tPreferencesWindowController showFontsAndColorsPrefPane];
}

// Windows Menu

// Help Menu

- (IBAction)showUserGuide:(id)sender
{
    NSURL * tURL=[NSURL URLWithString:NSLocalizedString(@"http://s.sudre.free.fr/Software/documentation/Unexpectedly/index.html",@"No comment")];
    
    if (tURL!=nil)
        [[NSWorkspace sharedWorkspace] openURL:tURL];
}

- (IBAction)sendFeedback:(id)sender
{
    NSDictionary * tDictionary=[NSBundle mainBundle].infoDictionary;
    
    NSString * tString=[NSString stringWithFormat:NSLocalizedString(@"mailto:dev.unexpectedly@gmail.com?subject=[Unexpectedly%%20%@]%%20Feedback%%20(build%%20%@)",@"No comment"),tDictionary[@"CFBundleShortVersionString"],
                        tDictionary[@"CFBundleVersion"]];
    NSURL * tURL=[NSURL URLWithString:tString];
    
    if (tURL!=nil)
        [[NSWorkspace sharedWorkspace] openURL:tURL];
}

- (IBAction)showUnexpectedlyWebSite:(id)sender
{
    NSURL * tURL=[NSURL URLWithString:NSLocalizedString(@"http://s.sudre.free.fr/Software/Unexpectedly/about.html",@"No comment")];
    
    if (tURL!=nil)
        [[NSWorkspace sharedWorkspace] openURL:tURL];
}

// Debug Menu

- (IBAction)switchCrashReporterDialogType:(NSMenuItem *)sender
{
    CUICrashReporterDefaults * tDefaults=[CUICrashReporterDefaults standardCrashReporterDefaults];
    
    tDefaults.dialogType=sender.tag;
}

- (IBAction)switchCrashReporterNotificationMode:(NSMenuItem *)sender
{
    CUICrashReporterDefaults * tDefaults=[CUICrashReporterDefaults standardCrashReporterDefaults];
    
    tDefaults.notificationMode=sender.tag;
}

- (IBAction)switchReportUncaughtException:(NSMenuItem *)sender
{
    CUICrashReporterDefaults * tDefaults=[CUICrashReporterDefaults standardCrashReporterDefaults];
    
    tDefaults.reportUncaughtExceptions=!(tDefaults.reportUncaughtExceptions);
}

#pragma mark - NSApplicationDelegate

- (void)application:(NSApplication *)sender openFiles:(NSArray<NSString *> *)inFilePaths
{
    NSMutableArray<CUICrashLogsOpenErrorRecord *> * tOpenErrorsArray=[NSMutableArray array];
    
    for(NSString * tFilePath in inFilePaths)
    {
        BOOL tIsDirectory=NO;
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:tFilePath isDirectory:&tIsDirectory]==NO)
        {
            continue;
        }
        
        if (tIsDirectory==NO)
        {
            CUICrashLogsSourcesManager * tSourcesManager=[CUICrashLogsSourcesManager sharedManager];
            CUICrashLogsSourcesSelection * tSharedSourcesSelection=[CUICrashLogsSourcesSelection sharedSourcesSelection];
            
            CUICrashLogsSourceAll * tSourcesAll=[CUICrashLogsSourceAll crashLogsSourceAll];
            
            if ([tSourcesAll containsCrashLogForFileAtPath:tFilePath]==YES)
            {
                NSArray * tCrashLogSources=[tSourcesManager sourcesOfTypes:[NSSet setWithObjects:@(CUICrashLogsSourceTypeStandardDirectory),@(CUICrashLogsSourceTypeDirectory),@(CUICrashLogsSourceTypeFile),nil]];
                
                for(CUICrashLogsSource * tSource in tCrashLogSources)
                {
                    CUIRawCrashLog * tCrashLog=[tSource crashLogForFileAtPath:tFilePath];
                    
                    if (tCrashLog!=nil)
                    {
                        tSharedSourcesSelection.sources=[NSSet setWithObject:tSource];
                        
                        [[CUICrashLogsSelection sharedSelection] setSource:tSource crashLogs:@[tCrashLog]];
                        
                        break;
                    }
                }
               
                continue;
            }
            
            NSError * tError;
            
            CUICrashLogsSourceFile * tSource=[[CUICrashLogsSourceFile alloc] initWithContentsOfFileSystemItemAtPath:tFilePath error:&tError];
            
            if (tSource==nil)
            {
                if (tError!=nil)
                {
                    if ([tError.domain isEqualToString:IPSErrorDomain]==YES)
                    {
                        switch(tError.code)
                        {
                            case IPSUnsupportedBugTypeError:
                                
                                // Open file in Console.app
                                
                                if ([[NSWorkspace sharedWorkspace] openFile:tFilePath withApplication:@"/Applications/Utilities/Console.app"]==YES)
                                {
                                    return;
                                }
                                
                                break;
                        }
                    }
                }
                
                CUICrashLogsOpenErrorRecord * tRecord=[CUICrashLogsOpenErrorRecord new];
                tRecord.sourceURL=[NSURL fileURLWithPath:tFilePath];
                tRecord.openError=tError;
                
                [tOpenErrorsArray addObject:tRecord];
                
                continue;
            }
            
            [tSourcesManager addSources:@[tSource]];
            
            tSharedSourcesSelection.sources=[NSSet setWithObject:tSource];
            
            [[CUICrashLogsSelection sharedSelection] setSource:tSource crashLogs:tSource.crashLogs];
        }
        else
        {
            CUIdSYMBundle * tBundle=[[CUIdSYMBundle alloc] initWithPath:tFilePath];
        
            if (tBundle.isDSYMBundle==NO)
                continue;
            
            [[CUIdSYMBundlesManager sharedManager] addBundle:tBundle];
        }
    }
    
    if (tOpenErrorsArray.count>0)
    {
        CUICrashLogsOpenErrorPanel * tErrorPanel=[CUICrashLogsOpenErrorPanel crashLogsOpenErrorPanel];
        
        tErrorPanel.errors=tOpenErrorsArray;
        
        [tErrorPanel runModal];
    }
    
    [NSApp replyToOpenOrPrint:NSApplicationDelegateReplySuccess];
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)inFilePath
{
    BOOL tIsDirectory=NO;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:inFilePath isDirectory:&tIsDirectory]==NO)
    {
        return NO;
    }
    
    if (tIsDirectory==NO)
    {
        CUICrashLogsSourcesManager * tSourcesManager=[CUICrashLogsSourcesManager sharedManager];
        CUICrashLogsSourcesSelection * tSharedSourcesSelection=[CUICrashLogsSourcesSelection sharedSourcesSelection];
        
        CUICrashLogsSourceAll * tSourcesAll=[CUICrashLogsSourceAll crashLogsSourceAll];
        
        if ([tSourcesAll containsCrashLogForFileAtPath:inFilePath]==YES)
        {
            NSArray * tCrashLogSources=[tSourcesManager sourcesOfTypes:[NSSet setWithObjects:@(CUICrashLogsSourceTypeStandardDirectory),@(CUICrashLogsSourceTypeDirectory),@(CUICrashLogsSourceTypeFile),nil]];
            
            for(CUICrashLogsSource * tSource in tCrashLogSources)
            {
                CUIRawCrashLog * tCrashLog=[tSource crashLogForFileAtPath:inFilePath];
                
                if (tCrashLog!=nil)
                {
                    tSharedSourcesSelection.sources=[NSSet setWithObject:tSource];
                    
                    [[CUICrashLogsSelection sharedSelection] setSource:tSource crashLogs:@[tCrashLog]];
                    
                    break;
                }
            }
            return YES;
        }
        
        NSError * tError;
        
        CUICrashLogsSourceFile * tSource=[[CUICrashLogsSourceFile alloc] initWithContentsOfFileSystemItemAtPath:inFilePath error:&tError];
        
        if (tSource==nil)
        {
            NSLog(@"Unable to create Source from file at \"%@\"",inFilePath);
            
            return NO;
        }
        
        [tSourcesManager addSources:@[tSource]];
        
        tSharedSourcesSelection.sources=[NSSet setWithObject:tSource];
        
        [[CUICrashLogsSelection sharedSelection] setSource:tSource crashLogs:tSource.crashLogs];
    }
    else
    {
        CUIdSYMBundle * tBundle=[[CUIdSYMBundle alloc] initWithPath:inFilePath];
        
        if (tBundle.isDSYMBundle==NO)
            return NO;
        
        [[CUIdSYMBundlesManager sharedManager] addBundle:tBundle];
    }
    
    return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [WBRemoteVersionChecker sharedChecker];
    
    _mainWindowController=[CUIMainWindowController new];
    
    //NSLog(@"%@",_mainWindowController.window.frameAutosaveName);
	
	[_mainWindowController showWindow:self];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	// Insert code here to tear down your application
}

#pragma mark - Notifications

- (void)themesListDidChange:(NSNotification *)inNotification
{
    [self refreshThemesMenu];
}

- (void)showDebugMenuDidChange:(NSNotification *)inNotification
{
    NSUserDefaults * tUserDefaults=[NSUserDefaults standardUserDefaults];
    
    _debugMenuBarItem.hidden=([tUserDefaults boolForKey:CUIApplicationShowDebugMenuKey]==NO);
}

@end
