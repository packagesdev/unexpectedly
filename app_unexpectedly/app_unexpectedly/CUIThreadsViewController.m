/*
 Copyright (c) 2020-2024, Stephane Sudre
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

#import "CUIRawCrashLog+Path.h"

NSString * const CUIThreadsViewSelectedCallsDidChangeNotification=@"CUIThreadsViewSelectedCallsDidChangeNotification";

@interface CUIThreadsViewController () <NSMenuItemValidation>

    @property (readwrite) CUISymbolicationDataFormatter * symbolColumnFormatter;

    @property (readwrite) CUISymbolicationDataFormatter * lineColumnFormatter;

@end

@implementation CUIThreadsViewController

- (instancetype)initWithUserInterfaceLayoutDirection:(NSUserInterfaceLayoutDirection)userInterfaceLayoutDirection
{
    return [super init];
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

#pragma mark -

- (NSUInteger)numberOfSelectedStackFrames
{
    return 0;
}

- (NSArray<CUIStackFrame *> *)selectedStackFrames
{
    return @[];
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
    
    NSNotificationCenter * tNotificationCenter=NSNotificationCenter.defaultCenter;
    
    [tNotificationCenter addObserver:self selector:@selector(dSYMBundlesManagerDidAddBundles:) name:CUIdSYMBundlesManagerDidAddBundlesNotification object:nil];
    
    [tNotificationCenter addObserver:self selector:@selector(stackFrameSymbolicationDidSucceed:) name:CUIStackFrameSymbolicationDidSucceedNotification object:nil];
    
    [tNotificationCenter addObserver:self selector:@selector(symbolicateAutomaticallyDidChange:) name:CUIPreferencesSymbolicationSymbolicateAutomaticallyDidChangeNotification object:nil];
}

- (void)viewWillDisappear
{
    [super viewWillDisappear];
    
    NSNotificationCenter * tNotificationCenter=NSNotificationCenter.defaultCenter;
    
    [tNotificationCenter removeObserver:self name:CUIdSYMBundlesManagerDidAddBundlesNotification object:nil];
    
    [tNotificationCenter removeObserver:self name:CUIStackFrameSymbolicationDidSucceedNotification object:nil];
    
    [tNotificationCenter removeObserver:self name:CUIPreferencesSymbolicationSymbolicateAutomaticallyDidChangeNotification object:nil];
}

#pragma mark -

- (NSMenu *)createFrameContextualMenu
{
    NSMenu * tMenu=[[NSMenu alloc] initWithTitle:@""];
    
    NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy", @"") action:@selector(copy:) keyEquivalent:@""];
    tMenuItem.target=self;
    
    [tMenu addItem:tMenuItem];
    
    tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy Machine Instruction Address", @"") action:@selector(copyMachineInstructionAddress:) keyEquivalent:@""];
    tMenuItem.target=self;
    
    [tMenu addItem:tMenuItem];
    
    tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy Binary Image Offset", @"") action:@selector(copy:) keyEquivalent:@""];
    tMenuItem.target=self;
    tMenuItem.keyEquivalentModifierMask=NSEventModifierFlagOption;
    tMenuItem.alternate=YES;
    
    [tMenu addItem:tMenuItem];
    
    // Show With menu
    
    NSMenu * tHopperMenu=[[CUIHopperDisassemblerManager sharedManager] availableApplicationsMenuWithTarget:self];
    
    if (tHopperMenu!=nil)
    {
        [tMenu addItem:[NSMenuItem separatorItem]];
        
        tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Show In", @"") action:nil keyEquivalent:@""];
        tMenuItem.submenu=tHopperMenu;
        
        [tMenu addItem:tMenuItem];
    }
    
    return tMenu;
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
        NSRect tButtonFrame=inTableCellView.openButton.frame;
        
        switch(inTableCellView.userInterfaceLayoutDirection)
        {
            case NSUserInterfaceLayoutDirectionLeftToRight:
                tFrame.size.width=tWidth+5;
                
                tLabel.frame=tFrame;
                
                tButtonFrame.origin.x=NSMaxX(tLabel.frame)+2;
                
                break;
            
            case NSUserInterfaceLayoutDirectionRightToLeft:
                
                tFrame.size.width=tWidth+5;
                
                tLabel.frame=tFrame;
                
                tButtonFrame.origin.x=NSMinX(tLabel.frame)-15;
                
                break;
        }
        
        inTableCellView.openButton.frame=tButtonFrame;
    }
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
    SEL tAction=inMenuItem.action;
    
    NSUInteger tCount=self.numberOfSelectedStackFrames;
    
    if (tAction==@selector(copy:) ||
        tAction==@selector(copyMachineInstructionAddress:) ||
        tAction==@selector(copyBinaryImageOffset:))
    {
        return (tCount>0);
    }
    
    if (tAction==@selector(openWithHopperDisassembler:))
    {
        if (tCount!=1)
            return NO;
        
        NSArray<CUIStackFrame *> * tCalls=self.selectedStackFrames;
        
        NSFileManager * tFileManager=[NSFileManager defaultManager];
        
        for(CUIStackFrame * tStackFrame in tCalls)
        {
            NSString * tBinaryImageIdentifier=tStackFrame.binaryImageIdentifier;
            
            CUIBinaryImage * tBinaryImage=[self.crashLog.binaryImages binaryImageWithIdentifier:tBinaryImageIdentifier];
            
            if (tBinaryImage==nil)
            {
                NSString * tAlternateIdentifier=[self.crashLog.binaryImages binaryImageIdentifierForName:tBinaryImageIdentifier];
                
                if (tAlternateIdentifier!=nil)
                    tBinaryImage=[self.crashLog.binaryImages binaryImageWithIdentifier:tAlternateIdentifier];
            }
            
            NSString * tPath=[self.crashLog stringByResolvingUSERInPath:tBinaryImage.path];
            
            if (tPath.length==0)
                return NO;
            
            if ([tFileManager fileExistsAtPath:tPath]==NO)
                return NO;
        }
    }
    
    return YES;
}

- (IBAction)copy:(id)sender
{
    NSArray<CUIStackFrame *> * tCalls=self.selectedStackFrames;
    
    // A VOIR : Ideally I would like to put ... between 2 non sequential calls if multiple row selection is allowed
    
    NSArray * tLines=[tCalls WB_arrayByMappingObjectsUsingBlock:^id(CUIStackFrame * bStackFrame, NSUInteger bIndex) {
        
        NSString * tLine=[bStackFrame pasteboardRepresentationWithComponents:self.visibleStackFrameComponents];
        
        return tLine;
    }];
    
    NSString * tPasteboardString=[tLines componentsJoinedByString:@"\n"];
    
    NSPasteboard * tPasteboard=[NSPasteboard  generalPasteboard];
    
    [tPasteboard declareTypes:@[WBPasteboardTypeString] owner:nil];
    [tPasteboard setString:tPasteboardString forType:WBPasteboardTypeString];
}

- (IBAction)copyMachineInstructionAddress:(id)sender
{
    NSArray<CUIStackFrame *> * tCalls=self.selectedStackFrames;
    
    NSArray * tAddresses=[tCalls WB_arrayByMappingObjectsUsingBlock:^id(CUIStackFrame * bStackFrame, NSUInteger bIndex) {
        
        NSString * tLine=[NSString stringWithFormat:@"0x%lx",bStackFrame.machineInstructionAddress];
        
        return tLine;
    }];
    
    NSString * tPasteboardString=[tAddresses componentsJoinedByString:@" "];    // Uses spaces so that the output can paste for atos(1) command line tool
    
    NSPasteboard * tPasteboard=[NSPasteboard  generalPasteboard];
    
    [tPasteboard declareTypes:@[WBPasteboardTypeString] owner:nil];
    [tPasteboard setString:tPasteboardString forType:WBPasteboardTypeString];
    
}

- (IBAction)copyBinaryImageOffset:(id)sender
{
    NSArray<CUIStackFrame *> * tCalls=self.selectedStackFrames;
    
    NSArray * tAddresses=[tCalls WB_arrayByMappingObjectsUsingBlock:^id(CUIStackFrame * bCall, NSUInteger bIndex) {
        
        NSString * tBinaryImageIdentifier=bCall.binaryImageIdentifier;
        
        CUIBinaryImage * tBinaryImage=[self.crashLog.binaryImages binaryImageWithIdentifier:tBinaryImageIdentifier];
        
        if (tBinaryImage==nil)
        {
            NSString * tAlternateIdentifier=[self.crashLog.binaryImages binaryImageIdentifierForName:tBinaryImageIdentifier];
            
            if (tAlternateIdentifier!=nil)
                tBinaryImage=[self.crashLog.binaryImages binaryImageWithIdentifier:tAlternateIdentifier];
        }
        
        NSUInteger tAddress=bCall.machineInstructionAddress-tBinaryImage.binaryImageOffset;
        
        NSString * tLine=[NSString stringWithFormat:@"0x%lx",tAddress];
        
        return tLine;
    }];
    
    NSString * tPasteboardString=[tAddresses componentsJoinedByString:@" "];
    
    NSPasteboard * tPasteboard=[NSPasteboard  generalPasteboard];
    
    [tPasteboard declareTypes:@[WBPasteboardTypeString] owner:nil];
    [tPasteboard setString:tPasteboardString forType:WBPasteboardTypeString];
}

- (IBAction)openWithHopperDisassembler:(NSMenuItem *)sender
{
    CUIApplicationItemAttributes * tApplicationItemAttributes=sender.representedObject;
    
    NSArray<CUIStackFrame *> * tCalls=self.selectedStackFrames;
    
    [tCalls enumerateObjectsUsingBlock:^(CUIStackFrame * bCall, NSUInteger bIndex, BOOL * bOutStop) {
        
        NSString * tBinaryImageIdentifier=bCall.binaryImageIdentifier;
        
        CUIBinaryImage * tBinaryImage=[self.crashLog.binaryImages binaryImageWithIdentifier:tBinaryImageIdentifier];
        
        if (tBinaryImage==nil)
        {
            NSString * tAlternateIdentifier=[self.crashLog.binaryImages binaryImageIdentifierForName:tBinaryImageIdentifier];
            
            if (tAlternateIdentifier!=nil)
                tBinaryImage=[self.crashLog.binaryImages binaryImageWithIdentifier:tAlternateIdentifier];
        }
        
        NSUInteger tAddress=bCall.machineInstructionAddress-tBinaryImage.binaryImageOffset;
        
        [[CUIHopperDisassemblerManager sharedManager] openBinaryImage:[self.crashLog stringByResolvingUSERInPath:tBinaryImage.path]
                                            withApplicationAttributes:tApplicationItemAttributes
                                                             codeType:self.crashLog.header.codeType
                                                           fileOffSet:(void *)tAddress];
    }];
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
