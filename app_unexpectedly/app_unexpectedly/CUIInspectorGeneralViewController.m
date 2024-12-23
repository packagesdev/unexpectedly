/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIInspectorGeneralViewController.h"

@interface CUIInspectorGeneralViewController ()
{
    IBOutlet NSTextField * _crashDateValue;
    
    IBOutlet NSTextField * _operatingSystemVersionLabel;
    
    IBOutlet NSTextField * _operatingSystemVersionValue;
    
    IBOutlet NSTextField * _bridgeOSVersionValue;
}

// Notifications

- (void)viewFrameDidChange:(NSNotification *)inNotification;

- (void)systemClockDidChange:(NSNotification *)inNotification;

@end

@implementation CUIInspectorGeneralViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidAppear
{
    [super viewDidAppear];
 
    [self refreshDate];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(viewFrameDidChange:) name:NSViewFrameDidChangeNotification object:self.view];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(systemClockDidChange:) name:NSCurrentLocaleDidChangeNotification object:nil];
}

- (void)viewWillDisappear
{
    [super viewWillDisappear];
    
    [NSNotificationCenter.defaultCenter removeObserver:self name:NSViewFrameDidChangeNotification object:self.view];
    
    [NSNotificationCenter.defaultCenter removeObserver:self name:NSCurrentLocaleDidChangeNotification object:nil];
}

#pragma mark -

- (void)refreshDate
{
    static NSArray * sDateFormatters=nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        NSDateFormatter * tLongMediumFormatter=[NSDateFormatter new];
        
        tLongMediumFormatter.locale=[NSLocale autoupdatingCurrentLocale];
        tLongMediumFormatter.formatterBehavior=NSDateFormatterBehavior10_4;
        tLongMediumFormatter.dateStyle=NSDateFormatterLongStyle;
        tLongMediumFormatter.timeStyle=NSDateFormatterMediumStyle;
        
        NSDateFormatter * tMediumMediumFormatter=[NSDateFormatter new];
        
        tMediumMediumFormatter.formatterBehavior=NSDateFormatterBehavior10_4;
        tMediumMediumFormatter.locale=[NSLocale autoupdatingCurrentLocale];
        tMediumMediumFormatter.dateStyle=NSDateFormatterMediumStyle;
        tMediumMediumFormatter.timeStyle=NSDateFormatterMediumStyle;
        
        NSDateFormatter * tShortMediumFormatter=[NSDateFormatter new];
        
        tShortMediumFormatter.formatterBehavior=NSDateFormatterBehavior10_4;
        tShortMediumFormatter.locale=[NSLocale autoupdatingCurrentLocale];
        tShortMediumFormatter.dateStyle=NSDateFormatterShortStyle;
        tShortMediumFormatter.timeStyle=NSDateFormatterMediumStyle;
        
        sDateFormatters=@[
                          tLongMediumFormatter,
                          tMediumMediumFormatter,
                          tShortMediumFormatter
                          ];
        
    });
    
    CUICrashLog * tCrashLog=self.crashLog;
    CUICrashLogHeader * tHeader=tCrashLog.header;
    
    NSDate * tDate=tHeader.dateTime;
    
    NSRect tSavedFrame=_crashDateValue.frame;
    
    _crashDateValue.objectValue=tDate;
    
    // Try different formatters (from longest string to smallest string)
    
    for(NSDateFormatter * tDateFormatter in sDateFormatters)
    {
        _crashDateValue.formatter=tDateFormatter;
        
        [_crashDateValue sizeToFit];
        
        NSRect tFrame=_crashDateValue.frame;
        
        if (NSWidth(tFrame)<=NSWidth(tSavedFrame))
            break;
    }
    
    _crashDateValue.frame=tSavedFrame;
}

- (void)refreshUI
{
    CUICrashLog * tCrashLog=self.crashLog;
    
    CUICrashLogHeader * tHeader=tCrashLog.header;
    
    [self refreshDate];
    
    CUIOperatingSystemVersion * tOSVersion=tHeader.operatingSystemVersion;
    
    if (tOSVersion==nil)
    {
        _operatingSystemVersionValue.stringValue=@"-";
    }
    else
    {
        NSString * tDeviceOS=@"macOS";
        
        if (tOSVersion.majorVersion>10)
        {
            tDeviceOS=@"macOS";
        }
        else
        {
            if (tOSVersion.minorVersion>10)
            {
                tDeviceOS=@"macOS";
            }
            else if (tOSVersion.minorVersion>7)
            {
                tDeviceOS=@"OS X";
            }
            else
            {
                tDeviceOS=@"Mac OS X";
            }
        }
        
        _operatingSystemVersionLabel.stringValue=[NSString stringWithFormat:NSLocalizedString(@"%@:", @""),tDeviceOS];
        
        _operatingSystemVersionValue.stringValue=tOSVersion.stringValue;
    }
}

#pragma mark - Notifications

- (void)viewFrameDidChange:(NSNotification *)inNotification
{
    [self refreshDate];
}

- (void)systemClockDidChange:(NSNotification *)inNotification
{
    [self refreshDate];
}

@end
