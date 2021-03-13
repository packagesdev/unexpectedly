//
//  CUIHopperDisassemblerManager.m
//  Unexpectedly
//
//  Created by stephane on 09/03/2021.
//  Copyright © 2021 Acme, Inc. All rights reserved.
//

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

- (BOOL)openBinaryImage:(NSString *)inPath withApplicationAttributes:(CUIApplicationItemAttributes *)inApplicationAttributes codeType:(CUICodeType)inCodeType fileOffSet:(void *)inOffset
{
    if (inPath==nil)
    {
        NSLog(@"Binary image path should not be nil");
        
        return NO;
    }
    
    // Launch the Hopper Disassembler application if it's not already running (workaround for a limitation of the hopper command line tool)
    
    NSRunningApplication * tRunningApplication=[[NSWorkspace sharedWorkspace] launchApplicationAtURL:inApplicationAttributes.applicationURL
                                                                                             options:0
                                                                                       configuration:@{}
                                                                                               error:NULL];
    
    if (tRunningApplication==nil)
    {
        NSLog(@"No running instances of Hopper Disassembler and not able to launch one.");
        
        return NO;
    }
    
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
    
    return [tTask launchAndReturnError:&tError];
}

@end
