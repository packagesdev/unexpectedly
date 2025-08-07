/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIFileDeadDropView.h"

@interface CUIFileDeadDropView ()

    @property (nonatomic,readwrite,getter=isHighlighted) BOOL highlighted;

@end

@implementation CUIFileDeadDropView

- (instancetype)initWithFrame:(NSRect)inFrame
{
    self=[super initWithFrame:inFrame];
    
    if (self!=nil)
    {
        // Register for Drop
        
        [self registerForDraggedTypes:@[NSPasteboardTypeFileURL]];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    self=[super initWithCoder:decoder];
    
    if (self!=nil)
    {
        // Register for Drop
        
        [self registerForDraggedTypes:@[NSPasteboardTypeFileURL]];
    }
    
    return self;
}

#pragma mark -

- (void)setHighlighted:(BOOL)inHighlighted
{
    if (_highlighted!=inHighlighted)
    {
        _highlighted=inHighlighted;
        
        [self setNeedsDisplay:YES];
    }
}

#pragma mark -

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
}

#pragma mark -

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    if (self.delegate==nil)
    {
#ifdef DEBUG
        NSLog(@"CUIFileDeadDropView <0x%p>: drag & drop won't work. delegate is not set",self);
#endif
        return NSDragOperationNone;
    }
    
    NSPasteboard * tPasteBoard=[sender draggingPasteboard];
    
    if ([tPasteBoard.types containsObject:NSPasteboardTypeFileURL]==NO)
        return NSDragOperationNone;
    
    NSDragOperation tSourceDragMask = [sender draggingSourceOperationMask];
    
    if ((tSourceDragMask & NSDragOperationCopy)==0)
        return NSDragOperationNone;
    
    NSArray<Class> *tClasses = @[NSURL.class];
    NSArray<NSURL*> *tURLArray = [tPasteBoard readObjectsForClasses:tClasses
                                                            options:@{NSPasteboardURLReadingFileURLsOnlyKey:@(YES)}];
    
    if (tURLArray!=nil)
    {
        if ([self.delegate fileDeadDropView:self validateDropFileURLs:tURLArray]==YES)
        {
            self.highlighted=YES;
            
            return NSDragOperationCopy;
        }
    }
    
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    if (self.delegate==nil)
    {
#ifdef DEBUG
        NSLog(@"CUIFileDeadDropView <0x%p>: drag & drop won't work. delegate is not set",self);
#endif
        return NO;
    }
    
    NSPasteboard * tPasteBoard=[sender draggingPasteboard];
    
    if ([tPasteBoard.types containsObject:NSPasteboardTypeFileURL]==YES)
    {
        NSArray<Class> *tClasses = @[NSURL.class];
        NSArray<NSURL*> *tURLArray = [tPasteBoard readObjectsForClasses:tClasses
                                                                options:@{NSPasteboardURLReadingFileURLsOnlyKey:@(YES)}];
        
       if (tURLArray!=nil)
            return [self.delegate fileDeadDropView:self acceptDropFileURLs:tURLArray];
    }
    
    return NO;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    self.highlighted=NO;
    
    return YES;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    self.highlighted=NO;
}

@end

