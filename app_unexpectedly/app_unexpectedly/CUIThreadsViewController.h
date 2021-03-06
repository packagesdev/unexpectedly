/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Cocoa/Cocoa.h>

#import "CUICrashLog.h"

#import "CUIStackFrame+UI.h"

#import "CUIStackFrameComponents.h"

#import "CUISourceFileTableCellView.h"

#import "CUISymbolicationDataFormatter.h"

#import "CUIHopperDisassemblerManager.h"

@interface CUIThreadsViewController : NSViewController <CUIHopperDisassemblerActions>
{
    IBOutlet NSMenuItem * _showWithMenuItem;
}

    @property (nonatomic) CUICrashLog * crashLog;

    @property (nonatomic) BOOL showOnlyCrashedThread;

    @property (nonatomic) CUIStackFrameComponents visibleStackFrameComponents;

    @property (readonly) CUISymbolicationDataFormatter * symbolColumnFormatter;

    @property (readonly) CUISymbolicationDataFormatter * lineColumnFormatter;


    @property (nonatomic) NSUInteger numberOfSelectedStackFrames;

    @property (nonatomic) NSArray<CUIStackFrame *> * selectedStackFrames;

- (NSMenu *)createFrameContextualMenu;;

- (IBAction)copyMachineInstructionAddress:(id)sender;
    
- (IBAction)copyBinaryImageOffset:(id)sender;
    
- (IBAction)openSourceFile:(id)sender;

- (void)setUpSourceFileCellView:(CUISourceFileTableCellView *)inTableCellView withSymbolicationData:(CUISymbolicationData *)inSymbolicationData;

// Notifications

- (void)dSYMBundlesManagerDidAddBundles:(NSNotification *)inNotification;

- (void)stackFrameSymbolicationDidSucceed:(NSNotification *)inNotification;

- (void)symbolicateAutomaticallyDidChange:(NSNotification *)inNotification;

@end
