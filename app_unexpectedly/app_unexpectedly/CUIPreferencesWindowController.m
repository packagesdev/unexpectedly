/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIPreferencesWindowController.h"

#import "CUIPreferencePaneViewController.h"

#import "NSToolbar+Packages.h"

NSString * const CUIPreferencesWindowSelectedPaneIdentifierKey=@"preferences.ui.selected.identifier";


@interface CUIPreferencesWindowController () <NSToolbarDelegate>
{
    IBOutlet NSToolbar * _toolBar;
    
    NSMutableDictionary * _paneControllersDictionary;
    
    CUIPreferencePaneViewController * _currentViewController;
}

- (void)showPaneWithIdentifier:(NSString *)inIdentifier;

- (IBAction)showPane:(id)sender;

@end

@implementation CUIPreferencesWindowController

+ (CUIPreferencesWindowController *)sharedPreferencesWindowController
{
    static dispatch_once_t onceToken;
    static CUIPreferencesWindowController * sPreferencesWindowController=nil;
    
    dispatch_once(&onceToken, ^{
        
        sPreferencesWindowController=[CUIPreferencesWindowController new];
    });
    
    return sPreferencesWindowController;
}

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _paneControllersDictionary=[NSMutableDictionary dictionary];
    }
    
    return self;
}

#pragma mark -

- (NSString *)windowNibName
{
    return @"CUIPreferencesWindowController";
}

- (void)windowDidLoad
{
    [self.window center];
    
    // Set the toolbar style to deal with macOS BS
    
#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 101600
    if (@available(*, macOS 11))
    {
        self.window.toolbarStyle=NSWindowToolbarStylePreference;
    }
#endif
    
    self.window.showsToolbarButton=NO;
    self.window.collectionBehavior^=NSWindowCollectionBehaviorFullScreenAuxiliary;
    
    // Set the icon for Fonts & Colors
    
    NSToolbarItem * tFontsAndColorsToolbarItem=[self.window.toolbar PKG_toolBarItemWithIdentifier:@"toolbarItem.fontscolors"];
    
    tFontsAndColorsToolbarItem.image=[NSImage imageWithSize:NSMakeSize(48, 48) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
        
        NSImage * tColorsImage=[NSImage imageNamed:@"NSToolbarShowColorsItemImage"];
        
        [tColorsImage drawInRect:NSMakeRect(6,0,48,48) fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:0.6];
        
        NSImage * tFontsImage=[NSImage imageNamed:@"NSToolbarShowFontsItemImage"];
        
        [tFontsImage drawInRect:NSMakeRect(-6,0,48,48) fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
        
        return YES;
    }];
    
    // Show the first pane if not found in defaults
    
    NSString * tSelectedIdentifier=[[NSUserDefaults standardUserDefaults] objectForKey:CUIPreferencesWindowSelectedPaneIdentifierKey];
    
    if (tSelectedIdentifier==nil)
        tSelectedIdentifier=((NSToolbarItem *)[_toolBar items][0]).itemIdentifier;
    
    _toolBar.selectedItemIdentifier=tSelectedIdentifier;
    
    [self showPaneWithIdentifier:tSelectedIdentifier];
}

#pragma mark -

- (void)showPaneWithIdentifier:(NSString *)inIdentifier
{    
    if (inIdentifier==nil)
        return;
    
    CUIPreferencePaneViewController * tViewController=_paneControllersDictionary[inIdentifier];
    
    if (tViewController==nil)
    {
        NSArray * tArray=[inIdentifier componentsSeparatedByString:@"."];
        
        if ([tArray count]!=2)
            return;
        
        Class tClass=NSClassFromString([NSString stringWithFormat:@"CUIPreferencePane%@ViewController",[tArray[1] capitalizedString]]);
        
        if (tClass==nil)
            return;
        
        tViewController=[tClass new];
        
        if (tViewController==nil)
            return;
        
        _paneControllersDictionary[inIdentifier]=tViewController;
    }
    
    if (_currentViewController!=nil)
        [_currentViewController.view removeFromSuperview];
    
    _currentViewController=tViewController;
    
    NSRect tOldWindowFrame=self.window.frame;
    
    NSRect tNewContentRect=[[self.window contentView] bounds];
    
    tNewContentRect.size=_currentViewController.view.frame.size;
    
    NSRect tWindowFrame=[self.window frameRectForContentRect:tNewContentRect];
    
    tWindowFrame.origin.x=NSMinX(tOldWindowFrame);
    
    tWindowFrame.origin.y=NSMaxY(tOldWindowFrame)-NSHeight(tWindowFrame);
    
    
    self.window.title=[_toolBar PKG_toolBarItemWithIdentifier:inIdentifier].label;
    
    [self.window setFrame:tWindowFrame display:YES animate:NO];
    
    // Set Minimum and Maximum Height
    
    NSSize tSize=self.window.contentMinSize;
    tSize.height=_currentViewController.minimumHeight;
    self.window.contentMinSize=tSize;
    
    tSize.height=_currentViewController.maximumHeight;
    self.window.contentMaxSize=tSize;
    
    
    
    
    [[self.window contentView] addSubview:_currentViewController.view];
    
    [[NSUserDefaults standardUserDefaults] setObject:inIdentifier forKey:CUIPreferencesWindowSelectedPaneIdentifierKey];
}

#pragma mark -

- (IBAction)showPane:(id)sender
{
    [self showPaneWithIdentifier:[sender itemIdentifier]];
}

@end
