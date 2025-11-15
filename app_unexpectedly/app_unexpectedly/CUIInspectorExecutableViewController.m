/*
 Copyright (c) 2020-2025, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIInspectorExecutableViewController.h"

#import "CUICodeSigningInformationViewController.h"

#import "CUICrashLog+UI.h"

#import "CUIRawCrashLog+Path.h"

@interface CUIInspectorExecutableViewController () <NSPopoverDelegate>
{
    IBOutlet NSImageView * _executableIconView;
    
    IBOutlet NSTextField * _executableNameValue;
    
    IBOutlet NSButton * _codeSigningButton;
    
    IBOutlet NSTextField * _executableVersionValue;
    
    IBOutlet NSTextField * _executableArchitectureValue;
    
    IBOutlet NSTextField * _executablePathValue;
    
    IBOutlet NSButton * _executablePathShowButton;
}

- (void)layoutView;

- (IBAction)showCodeSigningInformation:(id)sender;

- (IBAction)showExecutableInFinder:(id)sender;

@end

@implementation CUIInspectorExecutableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (_executablePathShowButton.userInterfaceLayoutDirection==NSUserInterfaceLayoutDirectionRightToLeft)
    {
        // Mirror image.
        NSImage * tOriginalImage=_executablePathShowButton.image;
        
        NSImage * newTemplate=[NSImage imageWithSize:_executablePathShowButton.bounds.size
                                             flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
                                                 
                                                 NSAffineTransform * tTransform = [NSAffineTransform transform];
                                                 
                                                 [tTransform translateXBy:NSWidth(self->_executablePathShowButton.bounds) yBy:0];
                                                 [tTransform scaleXBy:-1.0 yBy:1.0];
                                                 [tTransform concat];
                                                 
                                                 [tOriginalImage drawInRect:dstRect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
                                                 
                                                 return YES;
                                             }];
        
        newTemplate.template=YES;
        
        _executablePathShowButton.image=newTemplate;
    }
}

#pragma mark -

- (void)refreshUI
{
    CUICrashLog * tCrashLog=self.crashLog;
    
    CUICrashLogHeader * tHeader=tCrashLog.header;
    
    _executableIconView.image=tCrashLog.processIcon;
    
    _executableNameValue.stringValue=tHeader.processName;
    
	_codeSigningButton.hidden=(tCrashLog.ipsReport.incident.header.codeSigningInfo==nil);
    
	IPSIncidentHeader * tIncidentHeader=tCrashLog.ipsReport.incident.header;
	
	if (tIncidentHeader!=nil)
	{
		NSString * tShorttVersionString=tIncidentHeader.bundleInfo.bundleShortVersionString;
		
		if (tShorttVersionString==nil || [tShorttVersionString isEqualToString:@"???"]==YES)
		{
			_executableVersionValue.stringValue=NSLocalizedString(@"Unknown version",@"");
		}
		else
		{
			NSString * tBundleVersion=tIncidentHeader.bundleInfo.bundleVersion;
			
			if (tBundleVersion!=nil)
			{
				_executableVersionValue.stringValue=[NSString stringWithFormat:NSLocalizedString(@"Version %@ (%@)",@""),tShorttVersionString, tBundleVersion];
			}
			else
			{
				_executableVersionValue.stringValue=[NSString stringWithFormat:NSLocalizedString(@"Version %@",@""),tShorttVersionString];
			}
		}
	}
	else
	{
		NSString * tVersion=tHeader.executableVersion;
		
		if (tVersion==nil || [tVersion isEqualToString:@"???"]==YES)
		{
			_executableVersionValue.stringValue=NSLocalizedString(@"Unknown version",@"");
		}
		else
		{
			_executableVersionValue.stringValue=[NSString stringWithFormat:NSLocalizedString(@"Version %@",@""),tVersion];
		}
	}
    
    NSString * tArchitectureValue=@"-";
    
    switch(tHeader.codeType)
    {
        case CUICodeTypeX86:
            
            tArchitectureValue=@"i386";
            break;
            
        case CUICodeTypeX86_64:
            
            tArchitectureValue=@"x86-64";
            break;
            
        case CUICodeTypeARM_64:
            
            tArchitectureValue=@"ARM-64";
            break;
            
        default:
            
            tArchitectureValue=@"TBD";
            break;
    }
    
    
    _executableArchitectureValue.stringValue=tArchitectureValue;
    
    NSString * tExecutablePath=[tCrashLog stringByResolvingUSERInPath:tHeader.executablePath];
    
    if (tExecutablePath==nil)
        tExecutablePath=tCrashLog.reopenFilePath;
    
    if (tExecutablePath==nil)
    {
        _executablePathValue.stringValue=@"";
        _executablePathShowButton.enabled=NO;
    }
    else
    {
        _executablePathValue.stringValue=tExecutablePath;
        
        _executablePathShowButton.enabled=[[NSFileManager defaultManager] fileExistsAtPath:tExecutablePath];
    }
    
    // Optimize Layout
    
    [self layoutView];
}

- (CGFloat)heightForMaxWidth:(CGFloat)inMaxWidth
{
    NSTextContainer * tTextContainer= [[NSTextContainer alloc] initWithContainerSize: NSMakeSize(inMaxWidth, FLT_MAX)];
    
    tTextContainer.lineFragmentPadding=0.0;
    
    NSLayoutManager * tLayoutManager = [NSLayoutManager new];
    
    tLayoutManager.typesetterBehavior=NSTypesetterBehavior_10_2_WithCompatibility;
    
    [tLayoutManager addTextContainer:tTextContainer];
    
    NSTextStorage * tTextStorage=[[NSTextStorage alloc] initWithAttributedString:_executablePathValue.attributedStringValue];
    
    [tTextStorage addLayoutManager:tLayoutManager];
    
    [tLayoutManager glyphRangeForTextContainer:tTextContainer];
    
    CGFloat tHeight=NSHeight([tLayoutManager usedRectForTextContainer:tTextContainer]);
    
    if (tHeight<14.0)
    {
        // Min Value
        
        return 14.0;
    }
    
    return tHeight;
}

- (void)layoutView
{
    NSRect tFrame=_executablePathValue.frame;
    
    CGFloat tOldHeight=NSHeight(tFrame);
    CGFloat tFittingHeight = [self heightForMaxWidth:tFrame.size.width];

    
    _executablePathValue.frame=tFrame;
    
    NSRect tViewFrame=self.view.frame;
    
    tViewFrame.origin.y-=(tFittingHeight-tOldHeight);
    
    tViewFrame.size.height+=(tFittingHeight-tOldHeight);

    self.view.frame=tViewFrame;
}

#pragma mark -

- (IBAction)showCodeSigningInformation:(id)sender
{
	NSPopover * tCodeSigningInformationPopOver = [NSPopover new];
	tCodeSigningInformationPopOver.contentSize=NSMakeSize(500.0, 20.0);
	tCodeSigningInformationPopOver.behavior=NSPopoverBehaviorTransient;
	tCodeSigningInformationPopOver.animates=NO;
	tCodeSigningInformationPopOver.delegate=self;
	
	NSAppearanceName tAppearanceName = ([self.view WB_isEffectiveAppearanceDarkAqua] == NO) ? WB_NSAppearanceNameAqua : WB_NSAppearanceNameDarkAqua;
	
	tCodeSigningInformationPopOver.appearance = [NSAppearance appearanceNamed:tAppearanceName];
	
	NSViewController * tPopUpViewController=[[CUICodeSigningInformationViewController alloc] initWithCodeSigningInfo:self.crashLog.ipsReport.incident.header.codeSigningInfo];
	
	tCodeSigningInformationPopOver.contentViewController=tPopUpViewController;
	
	tCodeSigningInformationPopOver.contentSize=tPopUpViewController.view.bounds.size;
	
	NSView * tTrick=tPopUpViewController.view;  // This is used to trigger the viewDidLoad method of the contentViewController.
	
	(void)tTrick;
	
	[tCodeSigningInformationPopOver showRelativeToRect:_codeSigningButton.bounds
												ofView:_codeSigningButton
										 preferredEdge:NSMaxXEdge];
}

- (IBAction)showExecutableInFinder:(id)sender
{
    NSWorkspace * tSharedWorkspace=[NSWorkspace sharedWorkspace];
    
    NSString * tExecutablePath=self.crashLog.reopenFilePath;
    
    if (tExecutablePath==nil)
        tExecutablePath=self.crashLog.header.executablePath;
    
    [tSharedWorkspace selectFile:tExecutablePath inFileViewerRootedAtPath:@""];
}

#pragma mark - NSPopoverDelegate

- (void)popoverDidClose:(NSNotification *)inNotification
{
	NSWindow * tWindow=self.view.window;
	
	if (tWindow.firstResponder==tWindow.contentView)
		[tWindow makeFirstResponder:self];
}

@end
