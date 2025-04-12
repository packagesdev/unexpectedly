/*
 Copyright (c) 2020-2024, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICrashLogContentsViewController.h"

#import "CUICrashLogPresentationTextViewController.h"

#import "CUICrashLogPresentationOutlineViewController.h"

#import "CUIdSYMDropView.h"

#import "CUIdSYMBundlesManager.h"

#import "CUIdSYMHunter.h"

NSString * const CUIDefaultsPresentationModeKey=@"ui.presentationMode";

NSString * const CUICrashLogContentsViewPresentationModeDidChangeNotification=@"CUICrashLogContentsViewPresentationModeDidChangeNotification";

@interface CUICrashLogContentsViewController () <CUIFileDeadDropViewDelegate,NSMenuItemValidation>
{
    CUICrashLogPresentationTextViewController * _textViewController;
    
    CUICrashLogPresentationOutlineViewController * _outlineViewController;
    
    
    CUICrashLogPresentationViewController * _currentPresentationViewController;
    
    CUIdSYMHunter * _shareddSYMHunter;
}

- (void)setPresentationMode:(CUIPresentationMode)inPresentationMode transferCrashLog:(BOOL)inTransferCrashLog;

- (void)symbolicate;

// Notifications

- (void)huntDidFinish:(NSNotification *)inNotification;

@end

@implementation CUICrashLogContentsViewController

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _presentationMode=CUIPresentationModeUnknown;
        
        _textViewController=[CUICrashLogPresentationTextViewController new];
        
        _outlineViewController=[CUICrashLogPresentationOutlineViewController new];
        
        _shareddSYMHunter=[CUIdSYMHunter sharedHunter];
    }
    
    return self;
}

- (NSString *)nibName
{
    return @"CUICrashLogContentsViewController";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSUserDefaults * tUserDefaults=[NSUserDefaults standardUserDefaults];
    
    [tUserDefaults registerDefaults:@{
                                      CUIDefaultsPresentationModeKey:@(CUIPresentationModeText)
                                      }];
    
    [self setPresentationMode:[tUserDefaults integerForKey:CUIDefaultsPresentationModeKey] transferCrashLog:NO];
    
    ((CUIdSYMDropView *)self.view).delegate=self;
    
    // Register for notifications
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(huntDidFinish:) name:CUIdSYMHunterHuntDidFinishNotification object:nil];
}

#pragma mark -

- (CUICrashLogPresentationViewController *)presentationViewController
{
    return _currentPresentationViewController;
}

#pragma mark - NSObject

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    return _currentPresentationViewController;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    BOOL tResponds=[super respondsToSelector:aSelector];
    
    if (tResponds==YES)
        return YES;
    
    if (_currentPresentationViewController==nil)
        return NO;
    
    NSString * tSelectorName=NSStringFromSelector(aSelector);
    
    if ([tSelectorName hasPrefix:@"CUI_MENUACTION_"]==NO && [tSelectorName isEqualToString:@"performTextFinderAction:"]==NO)
        return NO;
    
    return [_currentPresentationViewController respondsToSelector:aSelector];
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
    SEL tAction=inMenuItem.action;
    
    if ([super respondsToSelector:tAction]==NO)
    {
        NSString * tSelectorName=NSStringFromSelector(tAction);
        
        if ([tSelectorName hasPrefix:@"CUI_MENUACTION_"]==NO && [tSelectorName isEqualToString:@"performTextFinderAction:"]==NO)
            return NO;
        
        if ([_currentPresentationViewController respondsToSelector:tAction]==YES)
            return [_currentPresentationViewController validateMenuItem:inMenuItem];
        
        return NO;
    }
    
    if (tAction==@selector(CUI_MENUACTION_switchPresentationMode:))
    {
        inMenuItem.state=(inMenuItem.tag==self.presentationMode) ? NSControlStateValueOn : NSControlStateValueOff;
        
        return YES;
    }
    
    if (tAction==@selector(CUI_MENUACTION_champollion:))
    {
        NSArray * tUserCodeBinaryUUIDs=[self.crashLog.binaryImages.userCodeBinaryImages WB_arrayByMappingObjectsUsingBlock:^NSString *(CUIBinaryImage * bImage, NSUInteger bIndex) {
            
            return bImage.UUID;
            
        }];
        
        NSMutableSet * tUUIDsSet=[NSMutableSet setWithArray:tUserCodeBinaryUUIDs];
        
        // Remove the UUIDs that are already known to the dSYMBundleManager
        
        [[CUIdSYMBundlesManager sharedManager].bundlesSet enumerateObjectsUsingBlock:^(CUIdSYMBundle * bBundle, BOOL * bOutStop) {
            
            NSArray * tUUIDs=bBundle.binaryUUIDs;
            
            if (tUUIDs.count==0)
                return;
            
            [tUUIDsSet minusSet:[NSSet setWithArray:tUUIDs]];
        }];
        
        [tUUIDsSet minusSet:_shareddSYMHunter.huntingBundleUUIDs];
        
        return (tUUIDsSet.count>0);
    }
    
    return NO;
}

- (IBAction)CUI_MENUACTION_switchPresentationMode:(id)sender
{
    CUIPresentationMode tPresentationMode=CUIPresentationModeUnknown;
    
    if ([sender isKindOfClass:[NSMenuItem class]]==YES)
    {
        NSMenuItem * tMenuItem=(NSMenuItem *)sender;
        
        tPresentationMode=tMenuItem.tag;
    }
    else if ([sender isKindOfClass:[NSSegmentedControl class]]==YES)
    {
        NSSegmentedControl * tSegmentedControl=(NSSegmentedControl *)sender;
        
        tPresentationMode=[tSegmentedControl tagForSegment:tSegmentedControl.selectedSegment];
    }
    else
    {
        return;
    }
        
    self.presentationMode=tPresentationMode;
}

- (IBAction)CUI_MENUACTION_champollion:(id)sender
{
    [self symbolicate];
}

#pragma mark -

- (void)setCrashLog:(CUICrashLog *)inCrashLog
{
    if (_crashLog==inCrashLog)
        return;
    
    _crashLog=inCrashLog;
    
    CUIApplicationPreferences * tApplicationPreferences=[CUIApplicationPreferences sharedPreferences];
    
    if (inCrashLog==nil)
        return;
    
    _currentPresentationViewController.crashLog=inCrashLog;
    
    if ([inCrashLog isKindOfClass:[CUICrashLog class]]==NO)
        return;
    
    if (tApplicationPreferences.searchForSymbolsFilesAutomatically==YES)
        [self symbolicate];
}

- (BOOL)isBottomViewCollapsed
{
    switch(self.presentationMode)
    {
        case CUIPresentationModeOutline:
            
            return _outlineViewController.isBinaryImagesViewCollapsed;
            
        case CUIPresentationModeText:
        default:
            
            break;
    }
    
    return NO;
}

#pragma mark -

- (void)symbolicate
{
    NSArray * tUserCodeBinaryUUIDs=[self.crashLog.binaryImages.userCodeBinaryImages WB_arrayByMappingObjectsUsingBlock:^NSString *(CUIBinaryImage * bImage, NSUInteger bIndex) {
        
        return bImage.UUID;
        
    }];
    
    NSMutableSet * tUUIDsSet=[NSMutableSet setWithArray:tUserCodeBinaryUUIDs];
    
    // Remove the UUIDs that are already known to the dSYMBundleManager
    
    [[CUIdSYMBundlesManager sharedManager].bundlesSet enumerateObjectsUsingBlock:^(CUIdSYMBundle * bBundle, BOOL * bOutStop) {
        
        NSArray * tUUIDs=bBundle.binaryUUIDs;
        
        if (tUUIDs.count==0)
            return;
        
        [tUUIDsSet minusSet:[NSSet setWithArray:tUUIDs]];
    }];
    
    if (tUUIDsSet.count==0)
        return;
    
    [_shareddSYMHunter huntBundleWithUUIDs:tUUIDsSet];
}

- (void)setPresentationMode:(CUIPresentationMode)inPresentationMode
{
    [self setPresentationMode:inPresentationMode transferCrashLog:YES];
}

- (void)setPresentationMode:(CUIPresentationMode)inPresentationMode transferCrashLog:(BOOL)inTransferCrashLog
{
    if (inPresentationMode==CUIPresentationModeUnknown)
        return;
    
    if (_presentationMode==inPresentationMode)
        return;
    
    _presentationMode=inPresentationMode;
    
    NSWindow * tWindow=self.view.window;
    BOOL tShouldRestoreFirstController=NO;
    
    CUICrashLog * tCurrentCrashLog=nil;
    
    if (inTransferCrashLog==YES)
    {
        tCurrentCrashLog=_currentPresentationViewController.crashLog;
    }
    
    if (_currentPresentationViewController!=nil)
    {
        NSResponder * tResponder=tWindow.firstResponder;
        
        while (tResponder!=nil)
        {
            if (tResponder==_currentPresentationViewController)
            {
                tShouldRestoreFirstController=YES;
                break;
            }
            
            tResponder=tResponder.nextResponder;
        }
    }
    
    [_currentPresentationViewController.view removeFromSuperview];
    
    switch(_presentationMode)
    {
       case CUIPresentationModeText:
            
            _textViewController.view.frame=self.view.bounds;
            
            _currentPresentationViewController=_textViewController;
            
            break;
            
        case CUIPresentationModeOutline:
            
            _outlineViewController.view.frame=self.view.bounds;
            
            _currentPresentationViewController=_outlineViewController;
            
            break;
            
        default:
            
            return;
    }
    
    if (inTransferCrashLog==YES)
    {
        _currentPresentationViewController.crashLog=tCurrentCrashLog;
    }
    
    [self.view addSubview:_currentPresentationViewController.view];
    
    if (tShouldRestoreFirstController==YES)
        [tWindow makeFirstResponder:_currentPresentationViewController];
    
    // Post Notification
    
    [NSNotificationCenter.defaultCenter postNotificationName:CUICrashLogContentsViewPresentationModeDidChangeNotification object:self userInfo:@{@"mode":@(_presentationMode)}];
    
    // Save presentation mode in defaults
    
    NSUserDefaults * tUserDefaults=[NSUserDefaults standardUserDefaults];
    
    [tUserDefaults setInteger:_presentationMode forKey:CUIDefaultsPresentationModeKey];
}

#pragma mark -

- (IBAction)showHideBottomView:(id)sender
{
    if ([_currentPresentationViewController isKindOfClass:[CUICrashLogPresentationOutlineViewController class]]==NO)
        return;
    
    [_outlineViewController showHideBottomView:sender];
}

#pragma mark - CUIFileDeadDropViewDelegate

- (BOOL)fileDeadDropView:(CUIFileDeadDropView *)inView validateDropFileURLs:(NSArray<NSURL *> *)inURLArray
{
    if (inURLArray==nil)
        return NO;
    
    if ([self.crashLog isMemberOfClass:[CUICrashLog class]]==NO)
        return NO;
    
    CUIdSYMBundlesManager * tBundlesManager=[CUIdSYMBundlesManager sharedManager];
    
    NSArray * tAllUUIDs=self.crashLog.binaryImages.allUUIDs;
    
    NSArray<NSURL *> * tFilteredArray=[inURLArray WB_filteredArrayUsingBlock:^BOOL(NSURL * bURL, NSUInteger bIndex) {
        
        NSNumber *tIsDirectoryNumber;
        
        if ([bURL getResourceValue:&tIsDirectoryNumber forKey:NSURLIsDirectoryKey error:NULL]==NO)
            return NO;
        
        if (tIsDirectoryNumber.boolValue==NO)
            return NO;
        
        // Should have .crash extension
        
        if ([bURL.pathExtension caseInsensitiveCompare:@"dSYM"]!=NSOrderedSame)
            return NO;
        
        // Check that these are dSYM bundles and that the UUIDs are not already listed
        
        CUIdSYMBundle * tBundle=[[CUIdSYMBundle alloc] initWithURL:bURL];
        
        if (tBundle.isDSYMBundle==NO)
            return NO;
        
        if ([tBundlesManager containsBundle:tBundle]==YES)
            return NO;
        
        // Check that one the UUIDs is the one of a binary of the crash log
        
        
        
        NSUInteger tIndex=[tBundle.binaryUUIDs indexOfObjectPassingTest:^BOOL(NSString * bUUID, NSUInteger bIndex, BOOL * bOutStop) {
            
            return [tAllUUIDs containsObject:bUUID];
        }];
        
        return (tIndex!=NSNotFound);

    }];
    
    return (tFilteredArray.count>0);
}

- (BOOL)fileDeadDropView:(CUIFileDeadDropView *)inView acceptDropFileURLs:(NSArray<NSURL *> *)inURLArray
{
    if (inURLArray==nil)
        return NO;
    
    CUIdSYMBundlesManager * tBundlesManager=[CUIdSYMBundlesManager sharedManager];
    
    NSArray * tAllUUIDs=self.crashLog.binaryImages.allUUIDs;
    
    NSArray * tMappedArray=[inURLArray WB_arrayByMappingObjectsLenientlyUsingBlock:^CUIdSYMBundle *(NSURL * bURL, NSUInteger bIndex) {
        
        NSNumber *tIsDirectoryNumber;
        
        if ([bURL getResourceValue:&tIsDirectoryNumber forKey:NSURLIsDirectoryKey error:NULL]==NO)
            return nil;
        
        if (tIsDirectoryNumber.boolValue==NO)
            return nil;
        
        // Should have .crash extension
        
        if ([bURL.pathExtension caseInsensitiveCompare:@"dSYM"]!=NSOrderedSame)
            return nil;
        
        // Check that these are dSYM bundles and that the UUIDs are not already listed
        
        CUIdSYMBundle * tBundle=[[CUIdSYMBundle alloc] initWithURL:bURL];
        
        if (tBundle.isDSYMBundle==NO)
            return nil;
        
        if ([tBundlesManager containsBundle:tBundle]==YES)
            return nil;
        
        // Check that one the UUIDs is the one of a binary of the crash log
        
        NSUInteger tIndex=[tBundle.binaryUUIDs indexOfObjectPassingTest:^BOOL(NSString * bUUID, NSUInteger bIndex, BOOL * bOutStop) {
            
            return [tAllUUIDs containsObject:bUUID];
        }];
        
        return (tIndex!=NSNotFound) ? tBundle : nil;
    }];
    
    [tBundlesManager addBundles:tMappedArray];
    
    return (tMappedArray.count>0);
}

#pragma mark - CUIKeyViews

- (NSView *)firstKeyView
{
    return _currentPresentationViewController.firstKeyView;
}

- (NSView *)lastKeyView
{
    return _currentPresentationViewController.lastKeyView;
}

#pragma mark - Notifications

- (void)huntDidFinish:(NSNotification *)inNotification
{
    // A COMPLETER
}

@end
