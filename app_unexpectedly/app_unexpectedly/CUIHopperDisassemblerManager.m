/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "CUIHopperDisassemblerManager.h"

NSString * const CUIHopperDisassembler4BundleIdentifier=@"com.cryptic-apps.hopper-web-4";

@implementation CUIHopperDisassemblerManager

+ ()sharedManager
{
    static CUIHopperDisassemblerManager * sManager=nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sManager=[CUIHopperDisassemblerManager new];
        
    });
    
    return sManager;
}

#pragma mark -

- (NSMenu *)availableApplicationsMenuWithTarget:(id<CUIHopperDisassemblerActions>)inTarget
{
    NSArray * tArray=(__bridge_transfer NSArray *)LSCopyApplicationURLsForBundleIdentifier((__bridge CFStringRef)CUIHopperDisassembler4BundleIdentifier,NULL);
    
    // Remove the demo versions and the versions that do not include the hopper command line tool
    
    NSArray * tFilteredVersions=[tArray WB_filteredArrayUsingBlock:^BOOL(NSURL * bURL, NSUInteger bIndex) {
        
        NSURL * tHopperToolURL=[bURL URLByAppendingPathComponent:@"/Contents/MacOS/hopper"];
        
        if ([tHopperToolURL checkResourceIsReachableAndReturnError:NULL] == NO)
            return NO;
        
        NSBundle * tBundle=[NSBundle bundleWithURL:bURL];
        NSString * tBundleVersionString=[tBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        
        return ([tBundleVersionString hasSuffix:@"-demo"]==NO);
        
    }];
    
    if (tFilteredVersions.count==0)
        return nil;
    
    NSMutableArray * tApplicationsAttributes=[[tFilteredVersions WB_arrayByMappingObjectsUsingBlock:^CUIApplicationItemAttributes *(NSURL * bApplicationURL, NSUInteger bIndex) {
        
        return [[CUIApplicationItemAttributes alloc] initWithURL:bApplicationURL];
        
    }] mutableCopy];
    
    // Sort the array
    
    [tApplicationsAttributes sortUsingSelector:@selector(compare:)];
    
    // Filter the array
    
    tApplicationsAttributes=[tApplicationsAttributes WB_filteredArrayUsingBlock:^BOOL(CUIApplicationItemAttributes * bAttributes, NSUInteger bIndex) {
        
        return (bAttributes.duplicate==NO);
        
    }];
    
    NSMenu * tMenu=[[NSMenu alloc] initWithTitle:@""];
    
    if (tMenu==nil)
        return nil;
    
    for(CUIApplicationItemAttributes * tAttributes in tApplicationsAttributes)
    {
        NSMenuItem * tMenuItem=tAttributes.applicationMenuItem;
        
        tMenuItem.action=@selector(openWithHopperDisassembler:);
        tMenuItem.target=inTarget;
        
        [tMenu addItem:tMenuItem];
    }
    
    return tMenu;
}

- (void)openBinaryImage:(NSString *)inPath withApplicationAttributes:(CUIApplicationItemAttributes *)inApplicationAttributes codeType:(CUICodeType)inCodeType fileOffSet:(void *)inOffset
{
    if (inPath==nil)
    {
        NSLog(@"Binary image path should not be nil");
        return;
    }
    
	__auto_type postLaunchActions = ^(NSRunningApplication * runningApplication)
	{
		// Convert the codeType
		
		NSString * tCPUSelection=nil;
		
		switch(inCodeType)
		{
			case CUICodeTypeX86:
				
				tCPUSelection=@"--intel-32";
				break;
				
			case CUICodeTypeX86_64:
				
				tCPUSelection=@"--intel-64";
				break;
				
			case CUICodeTypeARM_64:
				
				tCPUSelection=@"--aarch64";
				break;
		
			case CUICodeTypePPC:
				
				tCPUSelection=@"--ppc";
				break;
				
			default:
				
				break;
		}
		
		NSURL * tCommandLineToolURL=[inApplicationAttributes.applicationURL URLByAppendingPathComponent:@"/Contents/MacOS/hopper"];
		
		NSTask * tTask=[NSTask new];
		tTask.executableURL=tCommandLineToolURL;
		
		NSMutableArray * tArguments=[NSMutableArray array];
		
		[tArguments addObjectsFromArray:@[
										  @"-a",
										  @"-l",
										  @"FAT",
										  @"-l",
										  @"Mach-O",
										  @"-e",
										  inPath]];
		
		if (tCPUSelection!=nil)
			[tArguments addObject:tCPUSelection];
		
		if (inOffset!=NULL)
		{
			[tArguments addObjectsFromArray:@[
											  @"--python-command",
											  [NSString stringWithFormat:@"doc = Document.getCurrentDocument();doc.setCurrentAddress(0x%lx)",(unsigned long)inOffset]
											  ]];
		}
		
		tTask.arguments=tArguments;
		
		tTask.terminationHandler=^(NSTask * bTask){
		
			dispatch_async(dispatch_get_main_queue(), ^{
				
				if (bTask.terminationStatus!=0)
				{
					NSLog(@"hopper tool returned with status %d",bTask.terminationStatus);
				}
			});
		};
		
		NSError * tError=nil;
		
		[tTask launchAndReturnError:&tError];
	};
	
	// Launch the Hopper Disassembler application if it's not already running (workaround for a limitation of the hopper command line tool)
    
#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 101600
	if (@available(*, macOS 11.0))
	{
		[[NSWorkspace sharedWorkspace] openApplicationAtURL:inApplicationAttributes.applicationURL
											  configuration:[NSWorkspaceOpenConfiguration configuration] completionHandler:^(NSRunningApplication * _Nullable bRunningApplication, NSError * _Nullable error) {
			if (bRunningApplication==nil)
			{
				NSLog(@"No running instances of Hopper Disassembler and not able to launch one: %@",error);
				
				return;
			}
			
			postLaunchActions(bRunningApplication);
		}];
	}
	else
#endif
	{
		NSRunningApplication * tRunningApplication=[[NSWorkspace sharedWorkspace] launchApplicationAtURL:inApplicationAttributes.applicationURL
																								 options:0
																						   configuration:@{}
																								   error:NULL];
		
		if (tRunningApplication==nil)
		{
			NSLog(@"No running instances of Hopper Disassembler and not able to launch one.");
			
			return;
		}
		
		postLaunchActions(tRunningApplication);
	}
}

@end
