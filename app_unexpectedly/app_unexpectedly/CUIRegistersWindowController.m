/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIRegistersWindowController.h"

#import "CUIRegistersMainViewController.h"

#define REGISTERS_LAYOUT_1_COLUMN   1
#define REGISTERS_LAYOUT_4_COLUMNS  4

@interface CUIRegistersWindowController () <NSWindowDelegate>
{
    CUIRegistersMainViewController * _mainViewController;
    
    NSUInteger _columnsCount;
}

- (NSRect)windowFrameForNumberOfColumns:(NSUInteger)inNumberOfColumns;

// Notifications

- (void)registersMainViewContentsViewDidChange:(NSNotification *)inNotification;

@end

@implementation CUIRegistersWindowController

+ (void)initialize
{
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
                                                              @"registers.columnsCount":@(REGISTERS_LAYOUT_4_COLUMNS)
                                                              }];
}

+ (CUIRegistersWindowController *)sharedRegistersWindowController
{
    static dispatch_once_t onceToken;
    static CUIRegistersWindowController * sRegistersWindowController=nil;
    
    dispatch_once(&onceToken, ^{
        
        sRegistersWindowController=[CUIRegistersWindowController new];
    });
    
    return sRegistersWindowController;
}

#pragma mark -

- (NSString *)windowNibName
{
    return @"CUIRegistersWindowController";
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    _columnsCount=[[NSUserDefaults standardUserDefaults] integerForKey:@"registers.columnsCount"];
    
    _mainViewController=[CUIRegistersMainViewController new];
    
    // Register for notifications
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(registersMainViewContentsViewDidChange:) name:CUIRegistersMainViewContentsViewDidChangeNotificaton object:_mainViewController];
    
    NSRect tContentsBounds=self.window.contentView.bounds;
    
    _mainViewController.view.frame=tContentsBounds;
    
    [self.window.contentView addSubview:_mainViewController.view];
}

#pragma mark -

- (IBAction)showWindow:(id)sender
{
    // Make sure the window is visible on screen
    
    // A COMPLETER
    
    [super showWindow:sender];
}

#pragma mark -

- (NSRect)windowFrameForNumberOfColumns:(NSUInteger)inNumberOfColumns
{
    NSSize tSize=[_mainViewController idealSizeForNumberOfColumns:inNumberOfColumns];
    
    if (NSEqualSizes(tSize,NSZeroSize)==YES)
        return NSZeroRect;
    
    NSRect tWindowFrame=self.window.frame;
    
    NSRect tOldContentBounds=self.window.contentView.bounds;
    
    if (NSEqualSizes(tSize, tOldContentBounds.size)==YES)
        return NSZeroRect;
    
    NSRect tContentRect;
    
    tContentRect.origin=NSZeroPoint;
    tContentRect.size=tSize;
    
    NSRect tNewFrame=[self.window frameRectForContentRect:tContentRect];
    
    tNewFrame.origin.x=tWindowFrame.origin.x;
    tNewFrame.origin.y=tWindowFrame.origin.y+NSHeight(tWindowFrame)-NSHeight(tNewFrame);
    
    return tNewFrame;
}

#pragma mark - NSWindowDelegate

- (NSRect)windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)newFrame
{
    NSUInteger tNewColumnCount=(_columnsCount==REGISTERS_LAYOUT_4_COLUMNS) ? REGISTERS_LAYOUT_1_COLUMN : REGISTERS_LAYOUT_4_COLUMNS;
    
    NSRect tWindowFrame=[self windowFrameForNumberOfColumns:tNewColumnCount];
    
    if (NSIsEmptyRect(tWindowFrame)==YES)
        return self.window.frame;
    
    _columnsCount=tNewColumnCount;
    
    [[NSUserDefaults standardUserDefaults] setInteger:_columnsCount forKey:@"registers.columnsCount"];
    
    return tWindowFrame;
}

- (BOOL)windowShouldZoom:(NSWindow *)window toFrame:(NSRect)newFrame
{
    /*NSRect tWindowFrame=[self windowFrameForNumberOfColumns:REGISTERS_LAYOUT_1_COLUMN];
    
    if (NSIsEmptyRect(tWindowFrame)==YES)
        return NO;*/
    
    if (_columnsCount==REGISTERS_LAYOUT_1_COLUMN)
        window.minSize=NSMakeSize(NSWidth(newFrame), 310);
    else
        window.minSize=newFrame.size;
    
    window.maxSize=newFrame.size;
    
    return YES;
}

- (void)registersMainViewContentsViewDidChange:(NSNotification *)inNotification
{
    NSRect tWindowFrame=[self windowFrameForNumberOfColumns:_columnsCount];
    
    if (NSIsEmptyRect(tWindowFrame)==YES)
        return;
    
    // Make sure the window is fully visible on screen
    
    NSScreen * tScreen=self.window.screen;
    
    if (tScreen!=nil)
    {
        NSRect tScreenVisibleRect=tScreen.visibleFrame;
        
        if (NSMaxX(tWindowFrame)>NSMaxX(tScreenVisibleRect))
        {
            tWindowFrame.origin.x=NSMaxX(tScreenVisibleRect)-NSWidth(tWindowFrame);
        }
        else if (NSMinX(tWindowFrame)<NSMinX(tScreenVisibleRect))
        {
            tWindowFrame.origin.x=NSMinX(tScreenVisibleRect);
        }
        
        if (NSMaxY(tWindowFrame)>NSMaxY(tScreenVisibleRect))
        {
            tWindowFrame.origin.y=NSMaxY(tScreenVisibleRect)-NSHeight(tWindowFrame);
        }
        else if (NSMinY(tWindowFrame)<NSMinY(tScreenVisibleRect))
        {
            tWindowFrame.origin.y=NSMinY(tScreenVisibleRect);
        }
    }
    
    [self.window setFrame:tWindowFrame display:NO animate:NO];
    
    if (_columnsCount==REGISTERS_LAYOUT_1_COLUMN)
        self.window.minSize=NSMakeSize(NSWidth(tWindowFrame), 310);
    else
        self.window.minSize=tWindowFrame.size;
    
    self.window.maxSize=tWindowFrame.size;
}

@end
