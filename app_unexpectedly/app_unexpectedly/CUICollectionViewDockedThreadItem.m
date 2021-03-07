/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICollectionViewDockedThreadItem.h"

#import "CUILightTableDockedThreadView.h"

#import "CUIThread.h"

@interface CUICollectionViewDockedThreadItem ()
{
    IBOutlet NSTextField * _threadNumberLabel;
    IBOutlet NSTextField * _threadNumberBigLabel;
    IBOutlet NSTextField * _threadNameLabel;
}

- (IBAction)openThreadView:(id)sender;

@end

@implementation CUICollectionViewDockedThreadItem

- (void)setRepresentedObject:(id)inRepresentedObject
{
    [super setRepresentedObject:inRepresentedObject];
    
    CUILightTableDockedThreadView * tView=(CUILightTableDockedThreadView *)self.view;
    
    CUIThread * tThread=(CUIThread *)inRepresentedObject;
    
    tView.crashed=tThread.isCrashed;
    
    tView.applicationSpecificBacktrace=tThread.isApplicationSpecificBacktrace;
    
    self.imageView.image=(tThread.isCrashed==YES) ? [NSImage imageNamed:@"crashedThread_Template"] : [NSImage imageNamed:@"thread_Template"];
    
    
    if (tThread.isApplicationSpecificBacktrace==YES)
    {
        _threadNumberBigLabel.stringValue=tThread.name;
        
        _threadNumberLabel.stringValue=@"";
        _threadNameLabel.stringValue=@"";
    }
    else
    {
        if (tThread.name==nil)
        {
            _threadNumberBigLabel.stringValue=[NSString stringWithFormat:NSLocalizedString(@"Thread %ld",@""),tThread.number];
            
            _threadNumberLabel.stringValue=@"";
            _threadNameLabel.stringValue=@"";
        }
        else
        {
            _threadNumberBigLabel.stringValue=@"";
            
            _threadNumberLabel.stringValue=[NSString stringWithFormat:NSLocalizedString(@"Thread %ld",@""),tThread.number];
            _threadNameLabel.stringValue=tThread.name;
        }
    }
}

- (IBAction)openThreadView:(id)sender
{
    id tDataSource=self.collectionView.dataSource;
    
    if ([tDataSource respondsToSelector:@selector(openThread:)]==YES)
        [tDataSource performSelector:@selector(openThread:) withObject:self.representedObject];
    
    // A COMPLETER
}

@end
