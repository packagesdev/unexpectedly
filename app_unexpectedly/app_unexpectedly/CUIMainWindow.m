/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIMainWindow.h"

#import "CUICrashLogsSelection.h"

NSString * const CUIDefaultsWindowToolbarVisibleKey=@"window.toolbar.visible";

@implementation CUIMainWindow

+ (void)initialize
{
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
                                                              CUIDefaultsWindowToolbarVisibleKey:@(YES)
                                                              }];
}

- (void)awakeFromNib
{
    NSUserDefaults * tDefaults=[NSUserDefaults standardUserDefaults];
    
    if ([tDefaults boolForKey:CUIDefaultsWindowToolbarVisibleKey]==NO)
    {
        self.toolbar.visible=NO;
        
        self.titleVisibility=NSWindowTitleVisible;
        
        self.representedFilename=@"";
        
        self.title=@"Unexpectedly";
    }
    else
    {
        self.titleVisibility=NSWindowTitleHidden;
    }
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
    SEL tAction=inMenuItem.action;
    
    if (tAction==@selector(toggleToolbarShown:))
    {
        if (self.toolbar.isVisible==YES)
            inMenuItem.title=NSLocalizedString(@"Hide Toolbar",@"");
        else
            inMenuItem.title=NSLocalizedString(@"Show Toolbar",@"");
    }
    
    return [super validateMenuItem:inMenuItem];
}

- (void)toggleToolbarShown:(id)sender
{
    [super toggleToolbarShown:sender];
    
    self.titleVisibility=(self.toolbar.isVisible==YES) ? NSWindowTitleHidden : NSWindowTitleVisible;
    
    if (self.titleVisibility==NSWindowTitleVisible)
    {
        self.representedFilename=@"";   // Set to @"" so that the next call to setRepresentedFileName shows the proxy icon and enables the menu (if the value does not change, the API does not do its job)
        
        CUICrashLogsSelection * tSelection=[CUICrashLogsSelection sharedSelection];
        
        CUIRawCrashLog * tCrashLog=tSelection.crashLogs.firstObject;
        
        if (tCrashLog==nil)
        {
            self.title=@"Unexpectedly";
            
            return;
        }
        
        NSString * tCrashLogFilePath=tCrashLog.crashLogFilePath;
        
        self.title=[tCrashLogFilePath lastPathComponent];
        
        self.representedFilename=tCrashLogFilePath;
    }
    
    // Remember whether the toolbar is shown or not
    
    [[NSUserDefaults standardUserDefaults] setBool:(self.toolbar.isVisible==YES) forKey:CUIDefaultsWindowToolbarVisibleKey];
}

@end
