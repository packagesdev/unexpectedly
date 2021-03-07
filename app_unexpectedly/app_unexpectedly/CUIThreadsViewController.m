/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIThreadsViewController.h"

#import "CUIApplicationPreferences.h"

#import "CUIdSYMBundlesManager.h"

NSString * const CUIThreadsViewSelectedCallsDidChangeNotification=@"CUIThreadsViewSelectedCallsDidChangeNotification";

@interface CUIThreadsViewController ()

    @property (readwrite) CUISymbolicationDataFormatter * symbolColumnFormatter;

    @property (readwrite) CUISymbolicationDataFormatter * lineColumnFormatter;

@end

@implementation CUIThreadsViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.symbolColumnFormatter=[CUISymbolicationDataFormatter new];
    
    self.symbolColumnFormatter.pathStyle=CUISymbolicationDataFormatterNoStyle;
    
    self.lineColumnFormatter=[CUISymbolicationDataFormatter new];
    
    self.lineColumnFormatter.symbolStyle=CUISymbolicationDataFormatterNoStyle;
    self.lineColumnFormatter.pathStyle=CUISymbolicationDataFormatterShortStyle;
    self.lineColumnFormatter.coordinatesStyle=CUISymbolicationDataFormatterFullStyle;
}

- (void)viewDidAppear
{
    [super viewDidAppear];
    
    NSNotificationCenter * tNotificationCenter=[NSNotificationCenter defaultCenter];
    
    [tNotificationCenter addObserver:self selector:@selector(dSYMBundlesManagerDidAddBundles:) name:CUIdSYMBundlesManagerDidAddBundlesNotification object:nil];
    
    [tNotificationCenter addObserver:self selector:@selector(stackFrameSymbolicationDidSucceed:) name:CUIStackFrameSymbolicationDidSucceedNotification object:nil];
    
    [tNotificationCenter addObserver:self selector:@selector(symbolicateAutomaticallyDidChange:) name:CUIPreferencesSymbolicationSymbolicateAutomaticallyDidChangeNotification object:nil];
}

- (void)viewWillDisappear
{
    [super viewWillDisappear];
    
    NSNotificationCenter * tNotificationCenter=[NSNotificationCenter defaultCenter];
    
    [tNotificationCenter removeObserver:self name:CUIdSYMBundlesManagerDidAddBundlesNotification object:nil];
    
    [tNotificationCenter removeObserver:self name:CUIStackFrameSymbolicationDidSucceedNotification object:nil];
    
    [tNotificationCenter removeObserver:self name:CUIPreferencesSymbolicationSymbolicateAutomaticallyDidChangeNotification object:nil];
}

#pragma mark -

- (void)setUpSourceFileCellView:(CUISourceFileTableCellView *)inTableCellView withSymbolicationData:(CUISymbolicationData *)inSymbolicationData
{
    NSString * tSourceFilePath=inSymbolicationData.sourceFilePath;
    
    NSTextField * tLabel=inTableCellView.textField;
    
    tLabel.stringValue=[self.lineColumnFormatter stringForObjectValue:inSymbolicationData];
    tLabel.toolTip=tSourceFilePath;
    
    BOOL tHidesOpenButton=YES;
    
    NSURL * tURL=[NSURL fileURLWithPath:tSourceFilePath];
    
    if (tURL.isFileURL==YES)
    {
        NSFileManager * tFileManager=[NSFileManager defaultManager];
        
        if ([tFileManager fileExistsAtPath:tURL.path]==YES)
        {
            tHidesOpenButton=NO;
        }
    }
    
    inTableCellView.openButton.hidden=tHidesOpenButton;
    
    NSRect tFrame=tLabel.frame;
    
    if (tHidesOpenButton==YES)
    {
        tFrame.size.width=NSMaxX(inTableCellView.frame)-NSMinX(tFrame)-4;
        
        tLabel.frame=tFrame;
    }
    else
    {
        CGFloat tWidth=[tLabel.attributedStringValue size].width;
        
        tFrame.size.width=tWidth+5;
        
        tLabel.frame=tFrame;
        
        NSRect tButtonFrame=inTableCellView.openButton.frame;
        
        tButtonFrame.origin.x=NSMaxX(tLabel.frame)+2;
        
        inTableCellView.openButton.frame=tButtonFrame;
    }
}

- (IBAction)openSourceFile:(id)sender
{
}

#pragma mark - Notifications

- (void)dSYMBundlesManagerDidAddBundles:(NSNotification *)inNotification
{
}

- (void)stackFrameSymbolicationDidSucceed:(NSNotification *)inNotification
{
}

- (void)symbolicateAutomaticallyDidChange:(NSNotification *)inNotification
{
}

@end
