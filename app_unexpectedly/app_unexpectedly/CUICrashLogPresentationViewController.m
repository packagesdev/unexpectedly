/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICrashLogPresentationViewController.h"

#import "CUIThemesManager.h"

#import "CUIPreferencesWindowController.h"

NSString * const CUICrashLogPresentationDisplayedSectionsDidChangeNotification=@"CUICrashLogPresentationDisplayedSectionsDidChangeNotification";

NSString * const CUICrashLogPresentationVisibleSectionsDidChangeNotification=@"CUICrashLogPresentationVisibleSectionsDidChangeNotification";

@implementation CUICrashLogPresentationViewController

#pragma mark -

- (void)viewDidLoad
{
    [super viewDidLoad];
}

#pragma mark -

- (void)setCrashLog:(CUICrashLog *)inCrashLog
{
    _crashLog=inCrashLog;
    
    if (_crashLog.isFullyParsed==NO)
    {
        [_crashLog finalizeParsing];
    }
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
    SEL tAction=inMenuItem.action;
    
    if (tAction==@selector(CUI_MENUACTION_switchTheme:))
    {
        if ([inMenuItem.title isEqualToString:[CUIThemesManager sharedManager].currentTheme.name]==YES)
        {
            inMenuItem.state=NSOnState;
        }
        else
        {
            inMenuItem.state=NSOffState;
        }
    
        return YES;
    }
    
    if (tAction==@selector(CUI_MENUACTION_switchShowOffset:))
    {
        inMenuItem.state=((self.visibleStackFrameComponents & CUIStackFrameByteOffsetComponent)!=0) ? NSOnState : NSOffState;
    }
    else if (tAction==@selector(CUI_MENUACTION_switchShowMemoryAddress:))
    {
        inMenuItem.state=((self.visibleStackFrameComponents & CUIStackFrameMachineInstructionAddressComponent)!=0) ? NSOnState : NSOffState;
    }
    else if (tAction==@selector(CUI_MENUACTION_switchShowBinaryImageIdentifier:))
    {
        inMenuItem.state=((self.visibleStackFrameComponents & CUIStackFrameBinaryNameComponent)!=0) ? NSOnState : NSOffState;
    }
    
    return YES;
}

- (IBAction)CUI_MENUACTION_switchTheme:(NSMenuItem *)sender
{
    CUIThemesManager * tThemesManager=[CUIThemesManager sharedManager];
    
    tThemesManager.currentTheme=[tThemesManager themeWithUUID:sender.representedObject];
}


- (IBAction)CUI_MENUACTION_switchShowOffset:(id)sender
{
    self.visibleStackFrameComponents^=CUIStackFrameByteOffsetComponent;
}

- (IBAction)CUI_MENUACTION_switchShowMemoryAddress:(id)sender
{
    self.visibleStackFrameComponents^=CUIStackFrameMachineInstructionAddressComponent;
}

- (IBAction)CUI_MENUACTION_switchShowBinaryImageIdentifier:(id)sender
{
    self.visibleStackFrameComponents^=CUIStackFrameBinaryNameComponent;
}

#pragma mark - CUIKeyViews

- (NSView *)firstKeyView
{
    return nil;
}

- (NSView *)lastKeyView
{
    return nil;
}

@end
